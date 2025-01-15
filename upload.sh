#!/bin/bash

BASE_DIR=$(realpath "$(dirname "$0")")

PROGRESS=false
DATE=$(date -Idate)

# Check for help flag
for i in "$@"; do
case $i in
    -h|--help)
    echo "📋 Usage: $0 [OPTIONS]"
    echo
    echo "Processes presence data for a given date and uploads it to the server."
    echo
    echo "Options:"
    echo "  -p, --progress       Show progress while processing probes."
    echo "  --date=YYYY-MM-DD    Specify the date to process (defaults to today if not provided)."
    echo "  -h, --help           Show this help message and exit."
    echo
    echo "Examples:"
    echo "  $0 --date=2023-12-01"
    echo "  $0 --date=2023-12-01 -p"
    exit 0
    ;;
esac
done

source "${BASE_DIR}/lib/base.sh"

# Parse command line arguments for start and end dates
for i in "$@"; do
case $i in
    -p|--progress)
    PROGRESS=true
    shift # past argument=value
    ;;
    --date=*)
    DATE="${i#*=}"
    shift # past argument=value
    ;;
esac
done

DATE=${DATE:=$(date -Idate)}

echo "🖧 Fetching known MAC addresses from ${TICKET_BACKEND_URL} for ${DATE}"
curl -s -d "key=${TICKET_BACKEND_TOKEN}&date=${DATE}" "${TICKET_BACKEND_URL}/api/mac" | sort > "${TSV_FILE}"

declare -A mac_address_list
while IFS=$'\t' read -ra line; do
    mac="${line[0]}"
    mac_address_list["$mac"]=1
done < "${TSV_FILE}"


echo "📅 Handling presences for $DATE"
if [ -z "$PROGRESS" ]; then
    echo "💡 See progress using --progress"
fi

PRESENCES_FILE="${TMP_DIR}/${DATE}"
> "${PRESENCES_FILE}"
PROBLEME LA on n'envoi la mac mais elle n'est plus dans le rpofil en date du 12 10
UNIQUES_MAC="${TMP_DIR}/${DATE}_MAC_UNIQUES"

echo "📦 Fetching probes from S3"
rclone copy --include "*/${DATE}" ovh:coworking-metz/presences/ ${PROBES_DIR}

echo "🏢 Handling location probes"
cd ${PROBES_DIR}

# Loop through each item in the current directory
for item in *; do
    # Check if the item is a directory
    if [ -d "$item" ]; then
        LOCATION="$item"
        PROBE_FILE_DATE="${PROBES_DIR}/${LOCATION}/${DATE}"
        
        if [ -f "$PROBE_FILE_DATE" ]; then
            I=0
            CUR=0
            TOTAL_LINES=$(wc -l < "$PROBE_FILE_DATE")

            while IFS=$'\t ' read -ra line; do
                $PROGRESS && echo -ne "\r🔄 Processing $CUR/$TOTAL_LINES\033[K"
                CUR=$((CUR + 1))

                timestamp="${line[0]:0:22}"
                mac_address="${line[1]}"
                
                if [[ -z ${mac_address_list[$mac_address]} ]]; then
                    continue
                fi
                echo "$timestamp        $mac_address" >> "${PRESENCES_FILE}"
                I=$((I + 1))
            done < "${PROBE_FILE_DATE}"

            $PROGRESS && echo ""
            echo "✅ ${I} known presences found in $LOCATION"
        else
            echo "❌ No known presences found in $LOCATION"
        fi
    fi
done

# Sort and process the presence file
sort "${PRESENCES_FILE}" -o "${PRESENCES_FILE}"

# Extract unique MAC addresses and save them
awk '{print $2}' "${PRESENCES_FILE}" | sort | uniq > "${UNIQUES_MAC}"

echo "⬆️ Uploading presences"

# Read unique MAC addresses into a variable
MACS=$(tr '\n' ',' < "${UNIQUES_MAC}" | sed 's/,$//') # Join MACs with commas and remove the trailing comma

# Process presences and include MACs in the payload
${BASE_DIR}/presences.sh "${PRESENCES_FILE}" "${TSV_FILE}" |
while read email amount; do
    PAYLOAD="email=${email}&date=${DATE}&amount=${amount}"
    STATUS=$(curl -q -s -d "key=${TICKET_BACKEND_TOKEN}&${PAYLOAD}&macs=${MACS}" "${TICKET_BACKEND_URL}/api/presence")

    if [ "$STATUS" = "OK" ]; then
        echo "📤 ${amount} day presence for ${email} uploaded"
    else
        echo "⚠️ ERROR: Unable to upload ${amount} day presence for ${email}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${PAYLOAD} - $STATUS" >> "${BASE_DIR}/logs/${DATE}"
    fi
done

echo "🗑️ Cleaning up temporary files"
sudo rm "${PRESENCES_FILE}"

echo "🏁 Script execution complete"
exit 0
