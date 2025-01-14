#!/bin/bash

# Define a variable for verbose mode
VERBOSE=false

# Process -v/--verbose and -h/--help options
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -v | --verbose )
    VERBOSE=true
    ;;
  -h | --help )
    echo "📋 Usage: $0 [OPTIONS]"
    echo
    echo "  This script processes flag files in a directory, extracts information,"
    echo "  executes the appropriate commands based on the extracted data, and stores"
    echo "  the results in a log file. It ensures that only recent files are retained"
    echo "  and older files are deleted."
    echo    
    echo "Available options:"
    echo "  -v, --verbose       Enable verbose mode to display detailed steps."
    echo "  -h, --help          Display this help message."
    echo
    echo "Recognized Flag Types:"
    echo "  - presences-mac: Processes presence data based on MAC addresses."
    echo "  - presences-daterange: Processes presence data for a specified date range."
    echo "  - presences-day: Processes presence data the current day."
    echo
    echo "Examples:"
    echo "  $0                  Run the script in silent mode."
    echo "  $0 --verbose        Run the script with detailed messages."
    exit 0
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

BASE_DIR=$(realpath "$(dirname "$0")")
source "${BASE_DIR}/.env"
source "${BASE_DIR}/lib/functions.sh"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is not installed. Please install jq to run this script."
    exit 1
fi

# Retain only the 50 most recent files by date
# $VERBOSE && echo "🗑️ Deleting old flags"
find "$FLAGS_DIR" -type f | sort -r | tail -n +51 | while read OLD_FILE; do
    rm -f "$OLD_FILE"
done

# Iterate over all files in the directory
for FILE in "$FLAGS_DIR"/*; do
    # Check if it's a file
    if [ -f "$FILE" ]; then
        if [[ "$FILE" == *.* ]]; then
            continue
        fi
        STREAM_FILE="${FILE}.stream"
        RESPONSE_FILE="${FILE}.response"

        if [ -f "$STREAM_FILE" ]; then
            $VERBOSE && echo "⚡ Flag $FILE is already being processed."
            continue
        fi
        
        if [ -f "$RESPONSE_FILE" ]; then
            $VERBOSE && echo "💤 Flag $FILE has already been processed."
            continue
        fi
        
        # Remove null bytes and process the file content
        JSON_CONTENT=$(cat "$FILE")
        
        # Check if the JSON file is empty
        if [ -z "$JSON_CONTENT" ]; then
            $VERBOSE && echo "❌ File $FILE is empty or invalid."
            continue
        fi
        
        # Extract the value of content.slug
        SLUG=$(echo "$JSON_CONTENT" | jq -r '.slug' 2>/dev/null)

        if [ -z "$SLUG" ] || [ "$SLUG" == "null" ]; then
            $VERBOSE && echo "❌ The slug for file $FILE is empty or invalid."
            continue
        fi
        
        # Create a file named [filename].stream
        touch "$STREAM_FILE"
        
        if [ "$SLUG" == "presences-mac" ]; then
            CMD=$(process_presences_mac "$JSON_CONTENT")
        elif [ "$SLUG" == "presences-daterange" ]; then
            CMD=$(process_presences_daterange "$JSON_CONTENT")
        elif [ "$SLUG" == "presences-day" ]; then
            CMD=$(process_presences_day)
        else
            $VERBOSE && echo "❌ Unknown command: $SLUG."
        fi        
        if [ -z "$CMD" ]; then
            $VERBOSE && echo "❌ Unknown command: $SLUG."
        else
            echo "⏱️ Processing $SLUG"
            echo $CMD
            $CMD >> "$STREAM_FILE"
            mv "$STREAM_FILE" "$RESPONSE_FILE"

            echo "✅ Processing complete - Log stored in $RESPONSE_FILE"
        fi
    fi
done
