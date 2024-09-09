#!/bin/bash

BASE_DIR=$(realpath "$(dirname "$0")")
LOG_DIR="${BASE_DIR}/logs"
TMP_DIR="${BASE_DIR}/tmp"
TSV_FILE="${BASE_DIR}/mac.tsv"

mkdir -p $LOG_DIR
mkdir -p $TMP_DIR

# Load environment variables from .env file
source "${BASE_DIR}/.env"


echo "Fetching all known MAC addresses from ${TICKET_BACKEND_URL}"
curl -s -d "key=${TICKET_BACKEND_TOKEN}" "${TICKET_BACKEND_URL}/api/mac" | sort > "${TSV_FILE}"

if [ ! -s "$TSV_FILE" ]; then
    echo "Error:Unable to fetch MAC addresses from the API."
    exit 1
fi