#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
QUEUE_FILE="$SCRIPT_DIR/validation_queue.json"
PROCESSING_FILE="$SCRIPT_DIR/validation_processing.json"
LOG_FILE="$SCRIPT_DIR/worker.log"
LOCK_FILE="$SCRIPT_DIR/worker.lock"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

if [ -f "$LOCK_FILE" ]; then
    log "Worker already running (lock file present). Exiting."
    exit 0
fi

touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log "Worker started"

if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
    log "No validation queue to process"
    rm -f "$LOCK_FILE"
    exit 0
fi

# Move to processing to avoid races
mv "$QUEUE_FILE" "$PROCESSING_FILE"
log "Processing queue file: $PROCESSING_FILE (moved from $QUEUE_FILE)"

# Run PHP processor
log "Calling process_validations.php to process jobs"
php "$SCRIPT_DIR/process_validations.php" "$PROCESSING_FILE"

# Remove processing file if still there
if [ -f "$PROCESSING_FILE" ]; then
    rm -f "$PROCESSING_FILE"
fi

log "Worker completed"
