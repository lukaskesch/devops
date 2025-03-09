#!/bin/bash

# Expects the backup files to begin with a date in the format: 2024-05-01_00:00:00

# Default values
S3_BUCKET=""
BACKUP_PREFIX="db-backups/"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --s3-bucket=*)
        S3_BUCKET="${1#*=}"
        shift
        ;;
        --backup-prefix=*)
        BACKUP_PREFIX="${1#*=}"
        shift
        ;;
        *)
        echo "Unknown parameter: $1" >&2
        exit 1
        ;;
    esac
done

# Check if required parameters are set
if [ -z "$S3_BUCKET" ]; then
    echo "Error: --s3-bucket parameter is required." >&2
    echo "Usage: $0 --s3-bucket=<your-s3-bucket-name> [--backup-prefix=backups/]" >&2
    exit 1
fi

# Ensure BACKUP_PREFIX ends with a slash
[[ "${BACKUP_PREFIX}" != */ ]] && BACKUP_PREFIX="${BACKUP_PREFIX}/"

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Get current date in YYYY-MM-DD format
CURRENT_DATE=$(date +%Y-%m-%d)

# Function to delete a file from S3
delete_file() {
    local file="$1"
    aws s3 rm "s3://$S3_BUCKET/$file"
}

echo "Starting backup cleanup"

# List all backup files
BACKUP_FILES=$(aws s3 ls "s3://$S3_BUCKET/$BACKUP_PREFIX" --recursive | awk '{print $4}')

# Process each backup file
for file in $BACKUP_FILES; do
    # Extract filename from the full path
    filename=$(basename "$file")
    
    # Extract date from filename (format: YYYY-MM-DD_HH-mm-ss.sql.gz)
    file_date=$(echo "$filename" | grep -oP '^\d{4}-\d{2}-\d{2}')
    
    # Skip files that don't match the expected date format
    if [ -z "$file_date" ]; then
        echo "Skipping file with invalid date format: $file" 
        echo "Skipping file with invalid date format: $file" >> /dev/stderr
        continue
    fi
    
    # Calculate age in days
    age_days=$(( ($(date -d "$CURRENT_DATE" +%s) - $(date -d "$file_date" +%s)) / 86400 ))
    
    # Apply retention policy
    if [ $age_days -le 1 ]; then
        # Keep all backups for the last day
        echo "Keeping backup: $file"
        continue
    elif [ $age_days -le 7 ]; then
        # Keep daily backups for the last week
        if [ "${filename:11:2}" != "00" ]; then
            echo "Deleting backup: $file"
            delete_file "$file"
        else
            echo "Keeping backup: $file"
        fi
    elif [ $age_days -le 30 ]; then
        # Keep weekly backups for the last month
        week_number=$(date -d "$file_date" +%U)
        day_of_week=$(date -d "$file_date" +%u)
        
        # Keep only Sunday's backup (assuming Sunday is the start of the week)
        if [ "$day_of_week" != "7" ] || [ "${filename:11:2}" != "00" ]; then
            echo "Deleting backup: $file"
            delete_file "$file"
        else
            echo "Keeping backup: $file"
        fi
    else
        # Keep monthly backups for older periods
        if [ "${filename:8:2}" != "01" ] || [ "${filename:11:2}" != "00" ]; then
            echo "Deleting backup: $file"
            delete_file "$file"
        else
            echo "Keeping backup: $file"
        fi
    fi
done

echo "Backup cleanup completed."
