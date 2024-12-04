#!/bin/bash

# Définir une variable pour le mode verbose
VERBOSE=false

# Traiter les options -v ou --verbose
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -v | --verbose )
    VERBOSE=true
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

BASE_DIR=$(realpath "$(dirname "$0")")
source "${BASE_DIR}/.env"

# Vérifier si jq est installé
if ! command -v jq &> /dev/null; then
    echo "Erreur : jq n'est pas installé. Installez jq pour exécuter ce script."
    exit 1
fi

# Parcourir tous les fichiers dans le répertoire
for FILE in "$FLAGS_DIR"/*; do
    # Vérifier si c'est un fichier
    if [ -f "$FILE" ]; then
        if [[ "$FILE" == *.* ]]; then
            continue
        fi
        STREAM_FILE="${FILE}.stream"
        RESPONSE_FILE="${FILE}.response"

        # Si le fichier .stream existe, passer au fichier suivant
        if [ -f "$STREAM_FILE" ]; then
            $VERBOSE && echo "Avertissement : Le flag $FILE est déjà en cours de traitement."
            continue
        fi
        
        # Si le fichier .stream existe, passer au fichier suivant
        if [ -f "$RESPONSE_FILE" ]; then
            $VERBOSE && echo "Avertissement : Le flag $FILE a déjà été traité."
            continue
        fi
        
        # Supprimer les null bytes et traiter le contenu du fichier
        # JSON_CONTENT=$(tr -d '\000' < "$FILE")
        JSON_CONTENT=$(cat "$FILE")
        
        # Vérifier si le fichier JSON n'est pas vide
        if [ -z "$JSON_CONTENT" ]; then
            $VERBOSE && echo "Avertissement : Le fichier $FILE est vide ou invalide."
            continue
        fi
        
        # Extraire la valeur de content.slug
        SLUG=$(echo "$JSON_CONTENT" | jq -r '.slug' 2>/dev/null)

        if [ -z "$SLUG" ] || [ "$SLUG" == "null" ]; then
            $VERBOSE && echo "Avertissement : Le slug est vide ou invalide."
            continue
        fi
        
        
        # Créer un fichier nommé [nom du fichier].stream
        touch "$STREAM_FILE"
        
        if [ "$SLUG" == "presences-mac" ]; then 
            MAC=$(echo "$JSON_CONTENT" | jq -r '.mac' 2>/dev/null)
            PERIOD=$(echo "$JSON_CONTENT" | jq -r '.period' 2>/dev/null)

            CMD="$BASE_DIR/reupload.sh $MAC $PERIOD --purge" 
        fi
        
        if [ "$SLUG" == "presences-mac" ]; then 
            MAC=$(echo "$JSON_CONTENT" | jq -r '.mac' 2>/dev/null)
            PERIOD=$(echo "$JSON_CONTENT" | jq -r '.period' 2>/dev/null)

            CMD="$BASE_DIR/reupload.sh $MAC $PERIOD --purge" 
        fi
        if [ "$SLUG" == "presences-daterange" ]; then 
            DATE_START=$(echo "$JSON_CONTENT" | jq -r '.start' 2>/dev/null)
            DATE_END=$(echo "$JSON_CONTENT" | jq -r '.end' 2>/dev/null)

            CMD="$BASE_DIR/reupload_period.sh --start=$DATE_START --end=$DATE_END -y" 
            echo $CMD
        fi        
        if [ "$SLUG" == "presences-day" ]; then 
            CMD="$BASE_DIR/upload.sh -s" 
            echo $CMD
        fi        
        if [ -z "$CMD" ]; then
            $VERBOSE && echo "Erreur : Commande inconnue: $SLUG."

        else
            echo "Traitement $SLUG"
            $CMD >> $STREAM_FILE
            mv $STREAM_FILE $RESPONSE_FILE

            echo "Traitement terminé"
        fi
    fi
done
