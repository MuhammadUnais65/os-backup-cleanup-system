#!/bin/bash

mkdir -p project/user1 project/user2 backup
touch -d "40 days ago" project/user1/old_archive.zip
touch -d "40 days ago" project/user2/system.log
touch -d "10 days ago" project/user1/temp_dump.tmp
touch -d "2 days ago" project/user2/active.tmp

SOURCE_DIR="./project"
BACKUP_BASE="./backup"
DATE=$(date +%Y-%m-%d)
BACKUP_PATH="$BACKUP_BASE/backup_$DATE"
LOG_FILE="cleanup.log"
REPORT_FILE="report.txt"

echo "--- Cleanup Log: $(date) ---" > "$LOG_FILE"
echo "Backup Report - $DATE" > "$REPORT_FILE"
echo "--------------------------" >> "$REPORT_FILE"

mkdir -p "$BACKUP_PATH"

TMP_DELETED=$(find "$SOURCE_DIR" -name "*.tmp" -mtime +7 -type f -print -delete 2>>"$REPORT_FILE" | wc -l)

TOTAL_SPACE_BEFORE=$(du -sb "$SOURCE_DIR" | cut -f1)

find "$SOURCE_DIR" -type f -mtime +30 \( -name ".log" -o -name ".tmp" -o -name "*.zip" \) | while read -r FILE; do
    REL_PATH="${FILE#$SOURCE_DIR/}"
    DEST_DIR=$(dirname "$BACKUP_PATH/$REL_PATH")
    
    mkdir -p "$DEST_DIR"
    
    if [ -f "$BACKUP_PATH/$REL_PATH" ]; then
        DEST_FILE="$BACKUP_PATH/${REL_PATH}_$(date +%s)"
    else
        DEST_FILE="$BACKUP_PATH/$REL_PATH"
    fi

    if mv "$FILE" "$DEST_FILE" 2>>"$REPORT_FILE"; then
        echo "[MOVED] $FILE -> $DEST_FILE" >> "$LOG_FILE"
    else
        echo "[ERROR] Failed to move $FILE" >> "$LOG_FILE"
    fi
done

TOTAL_SPACE_AFTER=$(du -sb "$SOURCE_DIR" | cut -f1)
SPACE_CLEARED=$(( (TOTAL_SPACE_BEFORE - TOTAL_SPACE_AFTER) / 1024 ))

echo "Files Deleted (.tmp): $TMP_DELETED" >> "$REPORT_FILE"
echo "Total Space Cleared: ${SPACE_CLEARED} KB" >> "$REPORT_FILE"

echo "==== REPORT CONTENT ===="
cat "$REPORT_FILE"
echo ""
echo "==== LOG CONTENT ===="
cat "$LOG_FILE"
echo ""
echo "==== BACKUP FOLDER STRUCTURE ===="
ls -R "$BACKUP_BASE"