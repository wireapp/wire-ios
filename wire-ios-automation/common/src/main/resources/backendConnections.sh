#!/bin/bash
#
# This file generates a JSON file out of all entries in the QA automation vault of 1Password that are in the category "Server"
#

VAULT="QA automation"
JSONFILE="backendConnections.json"

# Use downloaded binary if on Jenkins
if [ -n "$WORKSPACE" ]; then
	BINARY=$WORKSPACE/op
else
	BINARY=op
fi

echo "[" > $JSONFILE

# For each entry in the server category of this vault
ENTRIES=`$BINARY item list --vault "$VAULT" --categories Server | cut -d" " -f1 | tail -n+2`
FIRSTTIME=true
for ID in $ENTRIES; do
  [ $FIRSTTIME = false ] && echo "," >> $JSONFILE
	ENTRY=`$BINARY item get --vault "$VAULT" "$ID" --reveal --format=json`
	echo $ENTRY >> $JSONFILE
	FIRSTTIME=false
done
echo "]" >> $JSONFILE
