#!/bin/bash
BASE_DIR=$(realpath "$(dirname "$0")")

TSV_FILE=${2}

if [ -z "$TSV_FILE" ]; then
    source "${BASE_DIR}/lib/base.sh"
fi

cat $1 |
    grep "T08\|T09\|T10\|T11\|T12\|T13\|T14\|T15\|T16\|T17\|T18\|T19\|T20\|T21" | # remove early morning and evening
    cut -c 1-15,21- | #ignore below tens of minutes
    sort -k 2,2 -k 1,1 | # sort by mac address, then timestamp
    join -1 2 -2 1 -a 1 - <(sort "${TSV_FILE}") | #join id/name and timestamp on mac adress
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
