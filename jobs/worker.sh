#!/bin/bash
# Background worker for zone file validation
# This script processes queued validation jobs
# 
# Usage:
#   ./jobs/worker.sh
#
# Setup as cron job (runs every minute):
#   * * * * * /path/to/dns3/jobs/worker.sh >> /var/log/dns3-worker.log 2>&1

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Path to queue file
QUEUE_FILE="$SCRIPT_DIR/validation_queue.json"
PROCESSING_FILE="$SCRIPT_DIR/validation_processing.json"
LOG_FILE="$SCRIPT_DIR/worker.log"

# Lock file to prevent multiple workers running simultaneously
LOCK_FILE="$SCRIPT_DIR/worker.lock"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
    # Check if the lock is stale (older than 5 minutes)
    if [ $(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0))) -gt 300 ]; then
        log "Removing stale lock file"
        rm -f "$LOCK_FILE"
    else
        log "Worker already running, exiting"
        exit 0
    fi
fi

# Create lock file
touch "$LOCK_FILE"

# Ensure lock file is removed on exit
trap "rm -f $LOCK_FILE" EXIT

log "Worker started"

# Check if queue file exists
if [ ! -f "$QUEUE_FILE" ]; then
    log "No queue file found, exiting"
    exit 0
fi

# Check if queue is empty
if [ ! -s "$QUEUE_FILE" ]; then
    log "Queue file is empty, exiting"
    exit 0
fi

# Move queue to processing file
mv "$QUEUE_FILE" "$PROCESSING_FILE"
log "Processing queue file"

# Process each job using PHP script
php "$SCRIPT_DIR/process_validations.php" "$PROCESSING_FILE"

# Remove processing file
rm -f "$PROCESSING_FILE"

log "Worker completed"
exit 0
