#!/bin/bash
BASE_DIR=$(realpath "$(dirname "$0")")

TSV_FILE=${2}

# Check for help flag
for i in "$@"; do
case $i in
    -h|--help)
    echo "📋 Usage: $0 <INPUT_FILE> [TSV_FILE] [options]"
    echo
    echo "Processes a log file to filter and aggregate presences based on timestamps and MAC addresses."
    echo "  Note: This script is intended to be called by other scripts that will capture its stdout to parse it."
    echo "  This script should not echo anything, and should only be used standalone for debugging purposes."
    echo
    echo "Arguments:"
    echo "  <INPUT_FILE>         The file containing raw data to process (required)."
    echo "  <TSV_FILE>           The file containing mapping of MAC addresses to names (required)."
    echo
    echo "Options:"
    echo "  -h, --help           Show this help message and exit."
    echo
    echo "Examples:"
    echo "  $0 2024-03-13"
    echo "  $0 2024-03-13 mapping.tsv"
    exit 0
    ;;
esac
done


cat $1 |
    grep "T08\|T09\|T10\|T11\|T12\|T13\|T14\|T15\|T16\|T17\|T18\|T19\|T20\|T21" | # remove early morning and evening
    cut -c 1-15,21- | #ignore below tens of minutes
    sort -k 2,2 -k 1,1 | # sort by mac address, then timestamp
    join -1 2 -2 1 -a 1 - <(sort "${TSV_FILE}") | #join id/name and timestamp on mac address
    sed 's/^\([^ ]*\) \([^ ]*\)$/\1 \2 \1 UNKNOWN/' | #use mac address as id for unknown ones
    cut -c 19- | # remove mac address
    sort -t ' ' -k 2,2 -k 1,1 | # sort by id, then timestamp
    uniq -w 15 | # squash tens of minutes
    uniq -c -s 15 | # count tens of minutes for each id
    awk '{printf "%.1f\t%s\t%s %s %s %s\n",($1/6),$3,$4,$5,$6,$7}' | # transform tens of minutes to hours
    grep -v Coworking |
    grep -v ":" |
    awk '{if ($1 < 0.5) {print $2, "0.0"} else if ($1 < 5) {print $2, "0.5"} else {print $2, "1.0"} }' |
    grep -v "0.0" |
    cat

