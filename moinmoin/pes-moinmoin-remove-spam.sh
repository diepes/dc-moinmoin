#!/bin/bash

# MoinMoin base dir
MOIN_DIR="/var/moinmoin-vigor"
# Path to the MoinMoin data directory
# DATA_DIR="/path/to/moinmoin/data/pages"
DATA_DIR="${MOIN_DIR}/pages"
# Path to the user profile directory
USER_DIR="${MOIN_DIR}/user"

# Specify the allowed user
ALLOWED_USER="1234695118.63.29539" #"Pieter"

# Log file for actions
LOG_FILE="/root/moin_removed_pages.log"
LOG_FILE_REVERT="/root/moin_revert_pages.log"
LOG_FILE_NoUSER="/root/moin_no_user_name.log"
LOG_FILE_LOCK_ONLY="/root/moin_only_lock.log"

# Initialize variables
DELETE_MODE=false

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --delete)
            DELETE_MODE=true
            shift # Remove --delete from the arguments
            ;;
        *)
            # Handle other arguments if needed
            echo "Unknown arg, exiting"
            exit 1
            ;;
    esac
done

# Ensure the log file is empty
> "$LOG_FILE"
rm "$LOG_FILE_REVERT"
rm "$LOG_FILE_NoUSER"
rm "$LOG_FILE_LOCK_ONLY"

# Initialize the count variable
COUNT_PAGES=0
COUNT_RM=0


# Iterate through all pages
for PAGE_DIR in "$DATA_DIR"/*; do
    sleep 0.1
    if [ -d "$PAGE_DIR" ]; then
        # Increment the page count by 1
        COUNT_PAGES=$((COUNT_PAGES + 1))
        PAGE_NUM=$(printf "%04d" $COUNT_PAGES)

        # Path to the edit-log
        # EDIT_LOG="$PAGE_DIR/revisions/edit-log"
        EDIT_LOG="$PAGE_DIR/edit-log"
        EDIT_LOCK="$PAGE_DIR/edit-lock"
        
        # Check if the edit-log exists
        if [ -f "$EDIT_LOG" ]; then
            # Get the first user from the edit-log (creator)
            # 1-timestamp 2-rev 3-action 4-page 5-ip 6-dnsname 7-UserId="1234695118.63.29539"
            CREATOR=$(awk '{print $7}' "$EDIT_LOG" | head -n 1)
            # Extract the last user ID from the 7th column of the last line
            LAST_USER_ID=$(tail -n 1 "$EDIT_LOG" | awk '{print $7}')
            
            # Remove the page if both the creator and the last user ID are not the allowed user
            # if [[ "$CREATOR" != "$ALLOWED_USER" && "$LAST_USER_ID" != "$ALLOWED_USER" ]]; then
            if [[ "$CREATOR" != "$ALLOWED_USER" ]]; then
                # Full path to the user profile file

                USER_FILE="${USER_DIR}/${CREATOR}"
                # Check if the user file exists
                if [[ -f "$USER_FILE" ]]; then
                    # Extract the name value from the user profile file
                    USER_NAME=$(grep -m 1 "^name=" "$USER_FILE" | cut -d '=' -f 2)
                    # Extract the date saved from the header line
                    # DATE_SAVED=$(grep -m 1 "^#" "$USER_FILE" | sed -n "s/^# Data saved '\(.*\)' for id.*/\1/p")
                    # Extract the date yyyy-mm-dd from the header line
                    DATE_SAVED=$(grep -m 1 "^#" "$USER_FILE" | sed -n "s/^# Data saved '\([0-9-]*\).*/\1/p")
                    # echo "The editor's name is: $USER_NAME"

                    CREATOR_PADDED=$(printf "%-19s" "$CREATOR")
                    USER_NAME_PADDED=$(printf "%-12s" "$USER_NAME")
                    # Increment the deleted page count by 1
                    COUNT_RM=$((COUNT_RM + 1))
                    echo "$COUNT_RM/$PAGE_NUM ID:$CREATOR_PADDED DATE:$DATE_SAVED USER:$USER_NAME_PADDED  DEL:$PAGE_DIR" | tee -a "$LOG_FILE"
                    #
                    $DELETE_MODE && rm -rf "$PAGE_DIR" && echo "File deleted: $PAGE_DIR  [SPAM]" || echo "Delete mode not enabled or file not found. $PAGE_DIR"

                else
                    # echo "User profile file not found for ID: $CREATOR"
                    USER_NAME="unknown"
                    DATE_SAVED="N.A."
                    echo "ID:$CREATOR DATE:$DATE_SAVED USER:$USER_NAME  DEL:$PAGE_DIR" | tee -a "$LOG_FILE_NoUSER"
                    $DELETE_MODE && rm -rf "$PAGE_DIR" && echo "File deleted: $PAGE_DIR  [SPAM]" || echo "Delete mode not enabled or file not found. $PAGE_DIR"
                fi

            else
                # Record pages changes by spammer
                if [ "$LAST_USER_ID" != "$ALLOWED_USER" ]; then
                    echo "REVERT PAGE: $PAGE_DIR" | tee -a "$LOG_FILE_REVERT"
                fi
            fi
            
        else
            # No edit-log, Check if the edit-lock exists
            if [ -f "$EDIT_LOCK" ]; then
                LOCK_USER_ID=$(awk '{print $7}' "$EDIT_LOCK" | head -n 1)
                USER_FILE="${USER_DIR}/${CREATOR}"
                # Check if the user file exists
                if [[ -f "$USER_FILE" ]]; then
                    # Extract the name value from the user profile file
                    USER_NAME=$(grep -m 1 "^name=" "$USER_FILE" | cut -d '=' -f 2)
                else
                    USER_NAME="N.A"
                fi
            fi
            # Increment the deleted page count by 1
            COUNT_RM=$((COUNT_RM + 1))
            echo "$COUNT_RM/$PAGE_NUM No edit-log found for: DEL:$PAGE_DIR LOCK-USER:$USER_NAME" | tee -a "$LOG_FILE_LOCK_ONLY"
            $DELETE_MODE && rm -rf "$PAGE_DIR" && echo "File $COUNT_RM DEL:$PAGE_DIR [LOCK ONLY]" || echo "Delete mode not enabled or file not found. $PAGE_DIR"
        fi
    fi
done

# Clean moin cache
rm -rf $MOIN_DIR/cache/*
# Rebuild index
#moin --config-dir=/path/to/config --wiki-url=https://vigor.nz/ index build

echo "Page cleanup complete. Log saved to $LOG_FILE."
