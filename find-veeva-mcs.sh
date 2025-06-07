#!/bin/bash

# $version: 1.1.0

# Check if the folder name argument is provided
if [ -z "$1" ]; then
    echo "\033[31mError: Expecting parameter: <Local URL>\033[0m"
    exit 1
fi

base_dir="$HOME/Library/Developer/CoreSimulator/Devices"
veeva_URL="$1"

# Extract the key message ID from the URL (it's the 4th part of the path, after the random string)
key_message_id="$(echo "$veeva_URL" | cut -d'/' -f5)"
echo "Log: Searching for folders with the key message ID '$key_message_id'"

# Search for the folder
directory=$(find "$base_dir" -type d -name "$key_message_id")

# Check if the folder was found and output the result
if [ -z "$directory" ]; then
    echo "Error: Unable to locate any folder based on the key message ID '$key_message_id'"
else
    echo "Log: found folder $directory"
    open $directory
fi
