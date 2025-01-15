# Fonction pour gérer le slug presences-mac
process_presences_mac() {
    local json_content=$1
    MAC=$(echo "$json_content" | jq -r '.mac' 2>/dev/null)
    PERIOD=$(echo "$json_content" | jq -r '.period' 2>/dev/null)
    echo "$BASE_DIR/reupload.sh --mac=$MAC --period=$PERIOD --purge"
}

# Fonction pour gérer le slug presences-daterange
process_presences_daterange() {
    local json_content=$1
    DATE_START=$(echo "$json_content" | jq -r '.start' 2>/dev/null)
    DATE_END=$(echo "$json_content" | jq -r '.end' 2>/dev/null)
    echo "$BASE_DIR/reupload_period.sh --start=$DATE_START --end=$DATE_END -y"
}

# Fonction pour gérer le slug presences-day
process_presences_day() {
    echo "$BASE_DIR/upload.sh"
}
