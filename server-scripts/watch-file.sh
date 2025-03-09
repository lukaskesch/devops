#!/bin/bash

# Check if a log file argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Log file path is required." >> /dev/stderr
    echo "Usage: $0 /path/to/logfile" >> /dev/stderr
    exit 1
fi

LOG_FILE="$1"

# Check if the log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' does not exist." >> /dev/stderr
    exit 1
fi

LAST_POSITION_FILE="/tmp/$(basename "$LOG_FILE")_last_position"

# Initialize last position if it doesn't exist
if [ ! -f "$LAST_POSITION_FILE" ]; then
    echo "0" > "$LAST_POSITION_FILE"
fi

# Get the current file size (compatible with both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    current_size=$(stat -f %z "$LOG_FILE")
else
    current_size=$(stat -c %s "$LOG_FILE")
fi

# Read the last position
last_position=$(cat "$LAST_POSITION_FILE")

# Check if the file has grown
if [ "$current_size" -gt "$last_position" ]; then
    # Print new lines
    tail -c +$((last_position + 1)) "$LOG_FILE"
    
    # Update the last position
    echo "$current_size" > "$LAST_POSITION_FILE"
fi
