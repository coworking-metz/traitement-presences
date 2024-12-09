BASE_DIR=$(realpath "$(dirname "$0")")
LOG_DIR="${BASE_DIR}/logs"
TMP_DIR="${BASE_DIR}/tmp"
TSV_FILE="${TMP_DIR}/mac.tsv"
PROBES_DIR="${TMP_DIR}/probes"
MACS_PROBES_DIR="${TMP_DIR}/s3"

mkdir -p $LOG_DIR
sudo rm -rf ${TMP_DIR}
mkdir -p $TMP_DIR

# Load environment variables from .env file
source "${BASE_DIR}/.env"

sudo rm -rf ${PROBES_DIR}
mkdir -p ${PROBES_DIR}
mkdir -p ${MACS_PROBES_DIR}

echo "🖧 Fetching known MAC addresses from ${TICKET_BACKEND_URL}"
curl -s -d "key=${TICKET_BACKEND_TOKEN}" "${TICKET_BACKEND_URL}/api/mac" | sort > "${TSV_FILE}"

if [ ! -s "$TSV_FILE" ]; then
    echo "Error:Unable to fetch MAC addresses from the API."
    exit 1
fi


declare -A mac_address_list
while IFS=$'\t' read -ra line; do
    mac="${line[0]}"
    mac_address_list["$mac"]=1
done < "${TSV_FILE}"
