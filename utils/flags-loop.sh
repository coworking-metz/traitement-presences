#!/bin/bash

end=$((SECONDS+60)); 
while [ $SECONDS -lt $end ]; do 
    /opt/traitement-presences/flags.sh $1;
    sleep 2; 
done; 
