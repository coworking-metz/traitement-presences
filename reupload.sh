#!/bin/bash

BASE_DIR=$(realpath "$(dirname "$0")")

MAC=""
PERIOD=""
PURGE=false

# Check for help flag
for i in "$@"; do
  case $i in
    -h|--help)
      echo "ℹ️ Usage: $0 [OPTIONS]"
      echo
      echo "Options:"
      echo "  --mac=MAC               Specify the MAC address (required. The script"
      echo "                          will prompt for a value if empty)."
      echo "  --period=PERIOD         Specify the period, either a year (YYYY) or a" 
      echo "                          month (YYYY-MM) (required, the script will prompt for a value if empty)."
      echo "  -p, --purge             Automatically delete temporary files after execution."
      echo "  -h, --help              Show this help message and exit."
      echo
      echo "Examples:"
      echo "  $0 --mac=AA:BB:CC:DD:EE:FF --period=2023-01"
      echo "  $0 --mac=AA:BB:CC:DD:EE:FF --period=2023 -p"
      echo "  $0 -p -h"
      exit 0
      ;;
    --mac=*)
      MAC="${i#*=}"
      shift
      ;;
    --period=*)
      PERIOD="${i#*=}"
      shift
      ;;
    -p|--purge)
      PURGE=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

echo "##################################################################"
echo "# This script will find presences in the log for a given MAC     #"
echo "# address and then (re)upload all presences to ticket-backend    #"
echo "##################################################################"

# Check if the MAC variable is empty
if [ -z "$MAC" ]; then
    read -p "💻 Please enter the MAC address: " MAC
    if [ -z "$MAC" ]; then
        echo "❌ Error: No MAC address provided, halting the script."
        exit 1
    fi
fi
echo "💻 Selected MAC is $MAC"

# Check if the PERIOD variable is empty
if [ -z "$PERIOD" ]; then
    echo "📅 Please enter the period to reupload."
    read -p "The period is either a whole year (formatted YYYY) or specific month (formatted YYYY-MM): " PERIOD
    if [ -z "$PERIOD" ]; then
        echo "❌ Error: No period provided, halting the script."
        exit 1
    fi
fi
echo "📅 Selected period is $PERIOD"

source "${BASE_DIR}/lib/base.sh"

MAC_DIR="${TMP_DIR}/MAC"
sudo rm -rf "${MAC_DIR}"
mkdir -p "${MAC_DIR}"

echo "📦 Fetching log files from s3"
rclone sync --include "*/${PERIOD}*" ovh:coworking-metz/presences/ ${MACS_PROBES_DIR} --progress --update

echo "⚙️ Handling presences for MAC Address $MAC for $PERIOD"

cd "${MACS_PROBES_DIR}"
NB_LINES=0;
for item in *; do
    if [ -d "$item" ]; then
        LOCATION="$item"
        echo "🔍 Looking for presences in location '$LOCATION'"
        for PROBE in $(grep -rl "${MAC}" ${MACS_PROBES_DIR}/${LOCATION}/ | grep "$PERIOD")
        do
            DATE=$(basename "$PROBE")
            grep "${MAC}" "${PROBE}" >> "${MAC_DIR}/${DATE}"
            NB_LINES=$(($NB_LINES+1))
        done
    fi
done

if [ $NB_LINES -eq 0 ]; then
    echo "❌ No presences found in the log for the given MAC address"
    exit 1
fi

echo "✅ - ${NB_LINES} lines found in the log - Now calculating presences..."

cd ${MAC_DIR}
NB_PRESENCES=0
for PROBE in *; do
    DATE=$(basename "$PROBE")
    
    echo "🖧 Fetching known MAC addresses from ${TICKET_BACKEND_URL} for ${DATE}"
    curl -s -d "key=${TICKET_BACKEND_TOKEN}&date=${DATE}" "${TICKET_BACKEND_URL}/api/mac" | sort > "${TSV_FILE}"

    PRESENCE=$(${BASE_DIR}/presences.sh "${MAC_DIR}/${PROBE}" "${TSV_FILE}")
    EMAIL=$(echo $PRESENCE | cut -d' ' -f1)
    AMOUNT=$(echo $PRESENCE | cut -d' ' -f2)
    if [[ -n $EMAIL ]] && [[ -n $AMOUNT ]]; then
        PAYLOAD="email=${EMAIL}&date=${DATE}&amount=${AMOUNT}"
        STATUS=$(curl -q -s -d "key=${TICKET_BACKEND_TOKEN}&${PAYLOAD}" "${TICKET_BACKEND_URL}/api/presence")
        if [ "$STATUS" = "OK" ]; then
            echo "✅ ${AMOUNT} day presence on ${DATE} for ${EMAIL} uploaded"
            NB_PRESENCES=$(($NB_PRESENCES+1))
        else
            echo "❌ ERROR: Unable to upload ${AMOUNT} day presence on ${DATE} for ${EMAIL}"
        fi
    fi
done

if [ $NB_PRESENCES -eq 0 ]; then
    echo "❌ No presences were found for the given MAC address"
else
    echo "✅ ${NB_PRESENCES} presence(s) uploaded for the given MAC address"
fi
sudo rm -rf "$MAC_DIR"

echo "🏁 The script has ended"
if [[ $PURGE == false ]]; then
    echo "🗑️ Do you want to delete the temporary log files folder?"
    echo "This folder is only used for the reupload.sh script,"
    read -p "it takes some disk space and is not used by the daily upload.sh script (y/N) " response
fi

if [[ $PURGE == true || $response == "Y" || $response == "y" ]]; then
    sudo rm -rf "$MACS_PROBES_DIR"
    echo "🗑️ Folder and contents deleted."
fi

exit 0
