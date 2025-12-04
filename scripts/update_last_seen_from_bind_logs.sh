#!/usr/bin/env bash
# =============================================================================
# update_last_seen_from_bind_logs.sh
#
# Parse BIND query logs, deduplicate FQDNs of a given query type (default A),
# and update dns_records.last_seen in batch using a single multi-statement SQL.
#
# Prerequisites:
#   - mysql CLI client
#   - MariaDB 10.2+ or MySQL 8+ (WITH RECURSIVE support)
#
# Usage:
#   ./scripts/update_last_seen_from_bind_logs.sh [OPTIONS]
#
# Options:
#   --db-host HOST      MySQL/MariaDB host (default: localhost)
#   --db-user USER      MySQL/MariaDB user (default: root)
#   --db-pass PASS      MySQL/MariaDB password (or prompt if not provided)
#   --db-name NAME      Database name (default: dns3_db)
#   --logs FILES        Comma-separated log files, or '-' for stdin
#   --batch N           Batch size for INSERT (default: 1000)
#   --qtype TYPE        Query type to filter (default: A)
#   --tmpdir DIR        Temp directory for intermediate files (default: /tmp)
#   --dry-run           Perform lookup without applying UPDATE
#   --log-file FILE     Write execution log to file
#   --help              Show this help message
#
# Example:
#   ./scripts/update_last_seen_from_bind_logs.sh \
#       --db-host db.example.com --db-user dns3_user \
#       --logs "/var/log/named/query.log,/var/log/named/query.log.1.gz" \
#       --log-file /tmp/update_last_seen.log
#
# Security Notes:
#   - Prefer using ~/.my.cnf instead of --db-pass on command line
#   - Restrict DB user privileges to SELECT on zone_files, UPDATE on dns_records
#   - Use TLS connections in production (--ssl-mode=REQUIRED)
#
# Author: DNS3 Team
# =============================================================================

set -euo pipefail

# =============================================================================
# Default configuration
# =============================================================================
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-dns3_db}"
DB_PASS="${DB_PASS:-}"

LOG_FILES=""
BATCH_SIZE=1000
QTYPE="A"
TMPDIR="${TMPDIR:-/tmp}"
DRY_RUN=0
LOG_FILE=""

# Script state
SCRIPT_NAME="$(basename "$0")"
SCRIPT_START="$(date +%Y-%m-%d\ %H:%M:%S)"
TOTAL_LINES_PARSED=0
UNIQUE_FQDNS=0
MATCHED_RECORDS=0

# =============================================================================
# Helper functions
# =============================================================================

usage() {
    # Extract header documentation (lines 2-40)
    head -n 40 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
    exit 0
}

log_msg() {
    local msg="[$(date +%Y-%m-%d\ %H:%M:%S)] $*"
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" | tee -a "$LOG_FILE"
    else
        echo "$msg"
    fi
}

log_error() {
    log_msg "ERROR: $*" >&2
}

die() {
    log_error "$*"
    exit 1
}

cleanup() {
    local exit_code=$?
    if [[ -f "${SQL_FILE:-}" ]]; then
        rm -f "$SQL_FILE"
    fi
    if [[ -f "${FQDN_FILE:-}" ]]; then
        rm -f "$FQDN_FILE"
    fi
    # Only log completion if we actually started processing (SCRIPT_RUNNING is set)
    if [[ -n "${SCRIPT_RUNNING:-}" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            log_msg "Script completed successfully."
        else
            log_msg "Script terminated with exit code $exit_code."
        fi
    fi
}

trap cleanup EXIT

# =============================================================================
# Parse command line arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-pass)
            DB_PASS="$2"
            shift 2
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --logs)
            LOG_FILES="$2"
            shift 2
            ;;
        --batch)
            BATCH_SIZE="$2"
            shift 2
            ;;
        --qtype)
            QTYPE="$2"
            shift 2
            ;;
        --tmpdir)
            TMPDIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            die "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

# =============================================================================
# Validate prerequisites
# =============================================================================

if ! command -v mysql &>/dev/null; then
    die "mysql client not found. Please install MySQL/MariaDB client."
fi

if [[ -z "$LOG_FILES" ]]; then
    die "No log files specified. Use --logs to provide comma-separated files or '-' for stdin."
fi

# Prompt for password if not provided and not using .my.cnf
if [[ -z "$DB_PASS" && ! -f ~/.my.cnf ]]; then
    read -s -p "Enter MySQL password for ${DB_USER}@${DB_HOST}: " DB_PASS
    echo
fi

# Build mysql options
MYSQL_OPTS="-h $DB_HOST -P $DB_PORT -u $DB_USER"
if [[ -n "$DB_PASS" ]]; then
    MYSQL_OPTS="$MYSQL_OPTS -p$DB_PASS"
fi
MYSQL_OPTS="$MYSQL_OPTS $DB_NAME"

# =============================================================================
# Initialize logging
# =============================================================================

# Mark script as running (for cleanup function)
SCRIPT_RUNNING=1

if [[ -n "$LOG_FILE" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    : > "$LOG_FILE"
fi

log_msg "=========================================="
log_msg "update_last_seen_from_bind_logs.sh"
log_msg "=========================================="
log_msg "Start time: $SCRIPT_START"
log_msg "Mode: $(if [[ $DRY_RUN -eq 1 ]]; then echo 'DRY-RUN'; else echo 'LIVE'; fi)"
log_msg "Database: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
log_msg "Query type: $QTYPE"
log_msg "Batch size: $BATCH_SIZE"
log_msg "Log files: $LOG_FILES"
log_msg "------------------------------------------"

# =============================================================================
# Create temp files
# =============================================================================

FQDN_FILE="$(mktemp "$TMPDIR/fqdns_XXXXXX.txt")"
SQL_FILE="$(mktemp "$TMPDIR/update_last_seen_XXXXXX.sql")"

log_msg "Temp FQDN file: $FQDN_FILE"
log_msg "Temp SQL file: $SQL_FILE"

# =============================================================================
# Parse log files and extract FQDNs
# =============================================================================

log_msg "Parsing BIND log files for $QTYPE queries..."

# Function to process a log stream and extract FQDNs
# BIND query log format varies, but typically contains:
#   client @0x... 192.168.1.10#12345 (www.example.com): query: www.example.com IN A +E(0)D
#   or simpler: query: www.example.com IN A
parse_bind_logs() {
    local file="$1"
    
    if [[ "$file" == "-" ]]; then
        # Read from stdin
        cat
    elif [[ "$file" == *.gz ]]; then
        # Gzip compressed file
        if [[ -f "$file" ]]; then
            zcat "$file" 2>/dev/null || gzip -dc "$file" 2>/dev/null
        else
            log_error "File not found: $file"
            return 1
        fi
    else
        # Plain text file
        if [[ -f "$file" ]]; then
            cat "$file"
        else
            log_error "File not found: $file"
            return 1
        fi
    fi
}

# Extract FQDNs from log lines matching the query type
# Handles various BIND query log formats
extract_fqdns() {
    # Match patterns like:
    #   query: example.com IN A
    #   (example.com): query: example.com IN A
    # Extract the FQDN before "IN $QTYPE"
    grep -oP "query:\s+\K[^\s]+(?=\s+IN\s+${QTYPE}\b)" 2>/dev/null || \
    grep -E "query:.*IN ${QTYPE}" 2>/dev/null | sed -E "s/.*query:\s*([^ ]+)\s+IN\s+${QTYPE}.*/\1/"
}

# Normalize FQDNs: lowercase, remove trailing dots, remove invalid chars
normalize_fqdns() {
    while IFS= read -r fqdn; do
        # Skip empty lines
        [[ -z "$fqdn" ]] && continue
        
        # Lowercase
        fqdn="${fqdn,,}"
        
        # Remove trailing dot
        fqdn="${fqdn%.}"
        
        # Skip if too short or contains invalid characters
        if [[ ${#fqdn} -lt 1 || ! "$fqdn" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]]; then
            continue
        fi
        
        echo "$fqdn"
    done
}

# Process each log file
IFS=',' read -ra LOG_ARRAY <<< "$LOG_FILES"
for logfile in "${LOG_ARRAY[@]}"; do
    logfile="$(echo "$logfile" | xargs)"  # Trim whitespace
    if [[ -z "$logfile" ]]; then
        continue
    fi
    
    log_msg "Processing: $logfile"
    
    if parse_bind_logs "$logfile" | extract_fqdns | normalize_fqdns >> "$FQDN_FILE"; then
        local_count=$(wc -l < "$FQDN_FILE")
        log_msg "  Accumulated FQDNs so far: $local_count"
    else
        log_error "Failed to process: $logfile"
    fi
done

TOTAL_LINES_PARSED=$(wc -l < "$FQDN_FILE")
log_msg "Total raw FQDNs extracted: $TOTAL_LINES_PARSED"

# Deduplicate FQDNs
log_msg "Deduplicating FQDNs..."
sort -u "$FQDN_FILE" -o "$FQDN_FILE"
UNIQUE_FQDNS=$(wc -l < "$FQDN_FILE")
log_msg "Unique FQDNs after deduplication: $UNIQUE_FQDNS"

if [[ $UNIQUE_FQDNS -eq 0 ]]; then
    log_msg "No FQDNs to process. Exiting."
    exit 0
fi

# =============================================================================
# Build SQL batch file
# =============================================================================

log_msg "Building SQL batch file..."

# SQL escaping function - escape single quotes by doubling them
sql_escape() {
    local val="$1"
    echo "${val//\'/\'\'}"
}

# Generate the SQL file
cat > "$SQL_FILE" << 'SQLHEADER'
-- =============================================================================
-- update_last_seen_from_bind_logs.sh - Generated SQL
-- =============================================================================

SET @start_time = NOW();

-- Create temporary table for FQDNs
-- Using ENGINE=MEMORY for speed; switch to InnoDB for large datasets
DROP TEMPORARY TABLE IF EXISTS tmp_fqdns;
CREATE TEMPORARY TABLE tmp_fqdns (
    fqdn VARCHAR(255) NOT NULL,
    PRIMARY KEY (fqdn)
) ENGINE=MEMORY;

-- Insert unique FQDNs in batches
SQLHEADER

# Insert FQDNs in batches
batch_count=0
current_batch=""
line_num=0

log_msg "Generating INSERT statements (batch size: $BATCH_SIZE)..."

while IFS= read -r fqdn || [[ -n "$fqdn" ]]; do
    [[ -z "$fqdn" ]] && continue
    
    escaped_fqdn="$(sql_escape "$fqdn")"
    
    if [[ -z "$current_batch" ]]; then
        current_batch="INSERT IGNORE INTO tmp_fqdns (fqdn) VALUES ('$escaped_fqdn')"
    else
        current_batch="$current_batch,('$escaped_fqdn')"
    fi
    
    ((line_num++)) || true
    
    if (( line_num % BATCH_SIZE == 0 )); then
        echo "$current_batch;" >> "$SQL_FILE"
        current_batch=""
        ((batch_count++)) || true
    fi
done < "$FQDN_FILE"

# Flush remaining batch
if [[ -n "$current_batch" ]]; then
    echo "$current_batch;" >> "$SQL_FILE"
    ((batch_count++)) || true
fi

log_msg "Generated $batch_count INSERT batch statements."

# Add the main logic SQL
cat >> "$SQL_FILE" << 'SQLMAIN'

-- =============================================================================
-- Step 1: Resolve master zone for each FQDN using longest-match on zone_files.domain
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_fqdn_masters;
CREATE TEMPORARY TABLE tmp_fqdn_masters (
    fqdn VARCHAR(255) NOT NULL,
    master_id INT,
    master_domain VARCHAR(255),
    relative_label VARCHAR(255),
    PRIMARY KEY (fqdn)
) ENGINE=MEMORY;

-- Find the longest matching master zone for each FQDN
-- Master zones have file_type='master' and domain IS NOT NULL
INSERT INTO tmp_fqdn_masters (fqdn, master_id, master_domain, relative_label)
SELECT 
    t.fqdn,
    zf.id AS master_id,
    zf.domain AS master_domain,
    CASE 
        WHEN t.fqdn = zf.domain THEN '@'
        WHEN CHAR_LENGTH(t.fqdn) > CHAR_LENGTH(zf.domain) 
            THEN LEFT(t.fqdn, CHAR_LENGTH(t.fqdn) - CHAR_LENGTH(zf.domain) - 1)
        ELSE t.fqdn
    END AS relative_label
FROM tmp_fqdns t
LEFT JOIN zone_files zf ON (
    zf.file_type = 'master'
    AND zf.status = 'active'
    AND zf.domain IS NOT NULL
    AND (
        t.fqdn = zf.domain
        OR t.fqdn LIKE CONCAT('%\.', zf.domain)
    )
)
WHERE zf.id = (
    SELECT zf2.id
    FROM zone_files zf2
    WHERE zf2.file_type = 'master'
      AND zf2.status = 'active'
      AND zf2.domain IS NOT NULL
      AND (
          t.fqdn = zf2.domain
          OR t.fqdn LIKE CONCAT('%\.', zf2.domain)
      )
    ORDER BY CHAR_LENGTH(zf2.domain) DESC
    LIMIT 1
)
ON DUPLICATE KEY UPDATE 
    master_id = VALUES(master_id),
    master_domain = VALUES(master_domain),
    relative_label = VALUES(relative_label);

-- Also insert FQDNs without a master (for reporting)
INSERT IGNORE INTO tmp_fqdn_masters (fqdn, master_id, master_domain, relative_label)
SELECT t.fqdn, NULL, NULL, NULL
FROM tmp_fqdns t
WHERE NOT EXISTS (SELECT 1 FROM tmp_fqdn_masters tm WHERE tm.fqdn = t.fqdn);

-- Count FQDNs without master
SELECT COUNT(*) AS fqdns_without_master
FROM tmp_fqdn_masters
WHERE master_id IS NULL;

-- =============================================================================
-- Step 2: Expand includes recursively using WITH RECURSIVE CTE
-- Build a table of all zone_file_ids in the include tree for each master
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_master_zones;
CREATE TEMPORARY TABLE tmp_master_zones (
    master_id INT NOT NULL,
    zone_id INT NOT NULL,
    PRIMARY KEY (master_id, zone_id),
    INDEX idx_zone (zone_id)
) ENGINE=MEMORY;

-- For each distinct master, expand the full include tree
INSERT INTO tmp_master_zones (master_id, zone_id)
WITH RECURSIVE zone_tree AS (
    -- Base case: master zones themselves
    SELECT DISTINCT 
        fm.master_id AS root_master_id,
        fm.master_id AS current_zone_id
    FROM tmp_fqdn_masters fm
    WHERE fm.master_id IS NOT NULL
    
    UNION ALL
    
    -- Recursive case: includes of current zone
    SELECT 
        zt.root_master_id,
        zfi.include_id AS current_zone_id
    FROM zone_tree zt
    INNER JOIN zone_file_includes zfi ON zfi.parent_id = zt.current_zone_id
)
SELECT root_master_id, current_zone_id
FROM zone_tree
ON DUPLICATE KEY UPDATE zone_id = VALUES(zone_id);

-- =============================================================================
-- Step 3: Find matching dns_records
-- Match by: relative label in name, full FQDN in name, or apex (@) match
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_matches;
CREATE TEMPORARY TABLE tmp_matches (
    record_id INT NOT NULL PRIMARY KEY,
    fqdn VARCHAR(255),
    match_type VARCHAR(20)
) ENGINE=MEMORY;

-- Insert matching records
INSERT IGNORE INTO tmp_matches (record_id, fqdn, match_type)
SELECT DISTINCT
    dr.id AS record_id,
    fm.fqdn,
    CASE
        WHEN fm.relative_label = '@' AND dr.name IN ('@', fm.master_domain) THEN 'apex'
        WHEN dr.name = fm.relative_label THEN 'relative'
        WHEN dr.name = fm.fqdn THEN 'full_fqdn'
        ELSE 'other'
    END AS match_type
FROM tmp_fqdn_masters fm
INNER JOIN tmp_master_zones mz ON mz.master_id = fm.master_id
INNER JOIN dns_records dr ON dr.zone_file_id = mz.zone_id
WHERE fm.master_id IS NOT NULL
  AND dr.status = 'active'
  AND (
      -- Match by relative label
      dr.name = fm.relative_label
      -- Match by full FQDN stored in name
      OR dr.name = fm.fqdn
      -- Apex match: when relative_label is '@', also match name='@' or name=domain
      OR (fm.relative_label = '@' AND dr.name IN ('@', fm.master_domain))
  );

-- Report match counts
SELECT 'matched_records_count' AS metric, COUNT(*) AS value FROM tmp_matches
UNION ALL
SELECT 'unique_fqdns_matched' AS metric, COUNT(DISTINCT fqdn) AS value FROM tmp_matches;

-- Show sample of matches for verification
SELECT 'Sample matches (first 10):' AS info;
SELECT record_id, fqdn, match_type FROM tmp_matches LIMIT 10;

-- Show FQDNs without master for investigation
SELECT 'FQDNs without master zone (first 20):' AS info;
SELECT fqdn FROM tmp_fqdn_masters WHERE master_id IS NULL LIMIT 20;

SQLMAIN

# Add UPDATE or dry-run notice
if [[ $DRY_RUN -eq 1 ]]; then
    cat >> "$SQL_FILE" << 'SQLDRYRUN'

-- =============================================================================
-- DRY-RUN MODE: Showing what would be updated (no changes applied)
-- =============================================================================
SELECT 'DRY-RUN: The following records would be updated:' AS notice;
SELECT dr.id, dr.name, dr.record_type, dr.last_seen AS current_last_seen, 
       zf.name AS zone_name, zf.domain AS zone_domain
FROM tmp_matches tm
INNER JOIN dns_records dr ON dr.id = tm.record_id
INNER JOIN zone_files zf ON zf.id = dr.zone_file_id
LIMIT 20;

SELECT 'DRY-RUN: Total records that would be updated:' AS notice;
SELECT COUNT(*) AS would_update FROM tmp_matches;

SQLDRYRUN
else
    cat >> "$SQL_FILE" << 'SQLUPDATE'

-- =============================================================================
-- Step 4: Update dns_records.last_seen for all matched records
-- =============================================================================
UPDATE dns_records dr
INNER JOIN tmp_matches tm ON dr.id = tm.record_id
SET dr.last_seen = UTC_TIMESTAMP();

SELECT 'update_applied' AS status, ROW_COUNT() AS rows_updated;

SQLUPDATE
fi

# Add cleanup and summary
cat >> "$SQL_FILE" << 'SQLCLEANUP'

-- =============================================================================
-- Summary and cleanup
-- =============================================================================
SELECT 
    TIMESTAMPDIFF(SECOND, @start_time, NOW()) AS execution_seconds,
    (SELECT COUNT(*) FROM tmp_fqdns) AS total_fqdns,
    (SELECT COUNT(*) FROM tmp_fqdn_masters WHERE master_id IS NOT NULL) AS fqdns_with_master,
    (SELECT COUNT(*) FROM tmp_fqdn_masters WHERE master_id IS NULL) AS fqdns_without_master,
    (SELECT COUNT(*) FROM tmp_matches) AS matched_records;

-- Cleanup temporary tables
DROP TEMPORARY TABLE IF EXISTS tmp_fqdns;
DROP TEMPORARY TABLE IF EXISTS tmp_fqdn_masters;
DROP TEMPORARY TABLE IF EXISTS tmp_master_zones;
DROP TEMPORARY TABLE IF EXISTS tmp_matches;

SQLCLEANUP

log_msg "SQL file generated: $SQL_FILE ($(wc -c < "$SQL_FILE") bytes)"

# =============================================================================
# Execute SQL
# =============================================================================

log_msg "Executing SQL against database..."
log_msg "------------------------------------------"

# Execute and capture output
# shellcheck disable=SC2086
if output=$(mysql $MYSQL_OPTS --batch --table < "$SQL_FILE" 2>&1); then
    if [[ -n "$LOG_FILE" ]]; then
        echo "$output" | tee -a "$LOG_FILE"
    else
        echo "$output"
    fi
    log_msg "------------------------------------------"
    log_msg "SQL execution completed successfully."
else
    log_error "SQL execution failed:"
    echo "$output" >&2
    exit 1
fi

# =============================================================================
# Final summary
# =============================================================================

log_msg "=========================================="
log_msg "Summary"
log_msg "=========================================="
log_msg "Total FQDNs parsed: $TOTAL_LINES_PARSED"
log_msg "Unique FQDNs: $UNIQUE_FQDNS"
log_msg "Mode: $(if [[ $DRY_RUN -eq 1 ]]; then echo 'DRY-RUN (no changes applied)'; else echo 'LIVE (updates applied)'; fi)"
log_msg "End time: $(date +%Y-%m-%d\ %H:%M:%S)"
log_msg "=========================================="

exit 0
