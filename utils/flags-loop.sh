#!/bin/bash
BASE_DIR=$(realpath "$(dirname "$0")/..")

end=$((SECONDS+60)); 
while [ $SECONDS -lt $end ]; do 
    "$BASE_DIR/flags.sh" $1;
    sleep 2; 
done; 
