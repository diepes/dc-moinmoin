#!/bin/bash

echo "# Not tested yet."
exit 1

# Path to the MoinMoin data directory
DATA_DIR="/path/to/moinmoin/data/pages"

# Specify the allowed user
ALLOWED_USER="PieterSmit"

# Log file for actions
LOG_FILE="removed_pages.log"

# Ensure the log file is empty
> "$LOG_FILE"

# Iterate through all pages
for PAGE_DIR in "$DATA_DIR"/*; do
    if [ -d "$PAGE_DIR" ]; then
        # Path to the edit-log
        EDIT_LOG="$PAGE_DIR/revisions/edit-log"
        
        # Check if the edit-log exists
        if [ -f "$EDIT_LOG" ]; then
            # Get the first user from the edit-log (creator)
            CREATOR=$(awk '{print $5}' "$EDIT_LOG" | head -n 1)
            
            # Remove the page if the creator is not the allowed user
            if [ "$CREATOR" != "$ALLOWED_USER" ]; then
                echo "Removing page: $PAGE_DIR (Creator: $CREATOR)" | tee -a "$LOG_FILE"
                rm -rf "$PAGE_DIR"
            fi
        else
            echo "No edit-log found for: $PAGE_DIR" >> "$LOG_FILE"
        fi
    fi
done

echo "Page cleanup complete. Log saved to $LOG_FILE."
