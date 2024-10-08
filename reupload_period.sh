#!/bin/bash

# Default values
START_DATE=""
END_DATE=""
all_continue="false"

# Parse command line arguments for start and end dates
for i in "$@"
do
case $i in
    --start=*)
    START_DATE="${i#*=}"
    shift # past argument=value
    ;;
    --end=*)
    END_DATE="${i#*=}"
    shift # past argument=value
    ;;
    *)
	    # unknown option
    ;;
esac
done

# Check if start date is provided
if [ -z "$START_DATE" ]; then
    echo "Error: No start date provided."
    echo "Usage: $0 --start=YYYY-MM-DD [--end=YYYY-MM-DD]"
    exit 1
fi

# Default end date to yesterday if not provided
if [ -z "$END_DATE" ]; then
    END_DATE=$(date -d "yesterday" '+%Y-%m-%d')
fi

# Display start and end dates and ask for confirmation
echo "This script will reupload all presences from $START_DATE to $END_DATE."
read -p "Continue with these dates? (Y/n) " response

if [[ "$response" =~ ^[Nn]$ ]]
then
    echo "Operation cancelled."
else
    # Loop from start date to end date
    current_date="$START_DATE"
    while [ "$current_date" != "$(date -I -d "$END_DATE + 1 day")" ]; do
	echo "================================================================"
	echo " - Uploading for $(date -d "$current_date" '+%A') $current_date"
	echo "================================================================"
	./upload.sh "$current_date"
	current_date=$(date -I -d "$current_date + 1 day")
	if [ "$current_date" != "$(date -I -d "$END_DATE + 1 day")" ]; then
		if [ "$all_continue" != "true" ]; then
			read -p "Continue with $current_date ? (Y=yes, a=yes to all, n=no) [Y/a/n]: " response
			case $response in
			  [Nn])
			    echo "Operation aborted."
			    exit 0
			    ;;
			  a)
			    all_continue="true"
			    ;;
			  *)
			    # Default to continue
			    ;;
			esac
		fi
	fi
    done
fi
echo "All uploads from $START_DATE to $END_DATE terminated"
