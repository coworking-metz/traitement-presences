#!/bin/bash

BASE_DIR=$(realpath "$(dirname "$0")")
source "${BASE_DIR}/base.sh"


DATE=$1
DATE=${DATE:=$(date -Idate)}
echo "Handling presences for $DATE"


PRESENCES_FILE="${TMP_DIR}/${DATE}"
> "${PRESENCES_FILE}"


echo " - Fetching probes from S3"
rclone copy --include "*/${DATE}" ovh:coworking-metz/presences/ ${PROBES_DIR}

echo " - Handling locations"
cd ${PROBES_DIR}
# Loop through each item in the current directory
for item in *; do
	# Check if the item is a directory
	if [ -d "$item" ]; then
		# Assign the directory name to the variable LOCATION
		LOCATION="$item"
#		echo "   - Looking for presences in location $LOCATION"
		
		PROBE_FILE_DATE="${PROBES_DIR}/${LOCATION}/${DATE}"
		if [ -f "$PROBE_FILE_DATE" ]; then
			#cat "${PROBE_FILE_DATE}" >> "${PRESENCES_FILE}"
			I=0
			# Read each line from the file
			while IFS=$'\t ' read -ra line; do
				timestamp="${line[0]:0:22}"
				mac_address="${line[1]}"
				# Check if the MAC address exists in the mac_address_list
				if [[ -z ${mac_address_list[$mac_address]} ]]; then
					# If MAC address is not found, skip the current iteration
					continue
				fi
				echo "$timestamp	$mac_address" >> "${PRESENCES_FILE}"
				I=$((I+1))
			done < "${PROBE_FILE_DATE}"
			echo "	- ${I} known presences found in $LOCATION"
	
		else
			echo "	- No known presences found in $LOCATION"
		fi
	fi
done

sort "${PRESENCES_FILE}" -o "${PRESENCES_FILE}"

echo " - Uploading presences"

${BASE_DIR}/presences.sh "${PRESENCES_FILE}" "${TSV_FILE}" |
while read email amount;
do
	PAYLOAD="email=${email}&date=${DATE}&amount=${amount}"
	STATUS=$(curl -q -s -d "key=${TICKET_BACKEND_TOKEN}&${PAYLOAD}" "${TICKET_BACKEND_URL}/api/presence")
	
	if [ "$STATUS" = "OK" ]; then
		echo "	- ${amount} day presence for ${email} uploaded"
	else
		echo "	- ERROR: Unable to upload ${amount} day presence for ${email}"
		echo "$(date '+%Y-%m-%d %H:%M:%S') - ${PAYLOAD} - $STATUS" >> "${BASE_DIR}/logs/${DATE}"
	fi
done

rm "${PRESENCES_FILE}"

exit 0
