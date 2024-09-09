#!/bin/bash

BASE_DIR=$(realpath "$(dirname "$0")")

MAC=$1

echo "##################################################################"
echo "# This script will find presences in the log for a given MAC     #"
echo "# address and then (re)upload all presences to ticket-backend    #"
echo "##################################################################"
# Check if the MAC variable is empty
if [ -z "$MAC" ]; then
    # Prompt the user for the MAC address
    read -p "Please enter the MAC address: " MAC
    # Check again if the MAC variable is empty after user input
    if [ -z "$MAC" ]; then
        echo "Error: No MAC address provided, halting the script."
        exit 1  # Exit with a non-zero status to indicate an error
    fi
fi

source "${BASE_DIR}/base.sh"

echo "Upload presences for MAC Address $MAC"

MAC_DIR="${TMP_DIR}/MAC"
mkdir -p "${MAC_DIR}"

cd ${PROBES_DIR}

NB_LINES=0;
for item in *; do
    # Check if the item is a directory
    if [ -d "$item" ]; then
        LOCATION="$item"
        echo "  - Looking for presences in location $LOCATION"
        
        for PROBE in $(grep -rl "${MAC}" ${PROBES_DIR}/${LOCATION}/)
        do
            DATE=$(basename "$PROBE")
            grep "${MAC}" "${PROBE}" >> "${MAC_DIR}/${DATE}"
            NB_LINES=$(($NB_LINES+1))
        done
    fi
done

if [ $NB_LINES -eq 0 ]; then
    echo "No presences found in the log for the given MAC address"
    exit 1
fi

echo "${NB_LINES} lines found in the log - Now calculating presences"
cd ${MAC_DIR}
NB_PRESENCES=0
for PROBE in *; do
    DATE=$(basename "$PROBE")
    PRESENCE=$(${BASE_DIR}/presences.sh "${MAC_DIR}/${PROBE}" "${TSV_FILE}")
    EMAIL=$(echo $PRESENCE | cut -d' ' -f1)
    AMOUNT=$(echo $PRESENCE | cut -d' ' -f2)
    if [[ -n $EMAIL ]] && [[ -n $AMOUNT ]]
    then
        PAYLOAD="email=${EMAIL}&date=${DATE}&amount=${AMOUNT}"
        STATUS=$(curl -q -s -d "key=${TICKET_BACKEND_TOKEN}&${PAYLOAD}" "${TICKET_BACKEND_URL}/api/presence")
        if [ "$STATUS" = "OK" ]; then
            echo "    - ${AMOUNT} day presence on ${DATE} for ${EMAIL} uploaded"
            NB_PRESENCES=$(($NB_PRESENCES+1))
        else
            echo "    - ERROR: Unable to upload ${AMOUNT} day presence on ${DATE} for ${EMAIL}"
        fi
    fi
    # grep "${MAC}" "${PROBE}" >> "${TMP_DIR}/MAC/${DATE}"
done
if [ $NB_PRESENCES -eq 0 ]; then
    echo "No presence where found for the given MAC address"
else
    echo "${NB_PRESENCES} presence(s) uploaded for the given MAC address"
fi
rm -rf "$MAC_DIR"
exit 0
