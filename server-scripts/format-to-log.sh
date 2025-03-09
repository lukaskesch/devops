#!/bin/bash

# Usage: your_command 2> >(./format-to-log.sh --log-level=ERROR >&1) | ./format-to-log.sh --log-level=INFO

log_level="INFO"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --log-level=*)
            log_level="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
    shift
done

while IFS= read -r line; do
    datetime=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$datetime] [$log_level] $line"
done
