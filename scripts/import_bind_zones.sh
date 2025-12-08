#!/usr/bin/env bash
# BIND Zone File Importer (Heuristic Bash Version)
#
# WARNING: This is a heuristic parser suitable for simple zone files only.
# For complex zones with $INCLUDE, DNSSEC, or advanced features, use the Python version.
#
# Usage: ./scripts/import_bind_zones.sh --dir /path/to/zones [OPTIONS]
#
# Options:
#   --dir PATH              Directory containing zone files (required)
#   --dry-run              Show what would be done without making changes
#   --db-host HOST         Database host (default: localhost)
#   --db-port PORT         Database port (default: 3306)
#   --db-user USER         Database user (default: root)
#   --db-pass PASS         Database password (will prompt if not provided)
#   --db-name NAME         Database name (default: dns3_db)
#   --skip-existing        Skip zones that already exist
#   --user-id ID           User ID for created_by field (default: 1)
#
# Examples:
#   # Dry-run mode (safe testing)
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --dry-run
#
#   # Import zones into database
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --db-user root --db-pass secret
#

set -euo pipefail

# Default values
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-dns3_db}"
DB_PASSWORD="${DB_PASSWORD:-}"
ZONE_DIR=""
DRY_RUN=0
SKIP_EXISTING=0
USER_ID=1

# Validate database name (security: prevent SQL injection)
validate_identifier() {
    local identifier="$1"
    local name="$2"
    if [[ ! "$identifier" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "ERROR: $name contains invalid characters. Only alphanumeric and underscore allowed." >&2
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            ZONE_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-pass)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --skip-existing)
            SKIP_EXISTING=1
            shift
            ;;
        --user-id)
            USER_ID="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ZONE_DIR" ]]; then
    echo "ERROR: --dir is required" >&2
    echo "Usage: $0 --dir /path/to/zones [OPTIONS]" >&2
    exit 1
fi

if [[ ! -d "$ZONE_DIR" ]]; then
    echo "ERROR: Directory not found: $ZONE_DIR" >&2
    exit 1
fi

# Validate DB_NAME
validate_identifier "$DB_NAME" "DB_NAME"

# Prompt for password if not provided
if [[ -z "$DB_PASSWORD" ]] && [[ $DRY_RUN -eq 0 ]]; then
    read -s -p "Database password for ${DB_USER}@${DB_HOST}: " DB_PASSWORD
    echo
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

echo "============================================"
echo "  BIND Zone File Importer (Bash/Heuristic)"
echo "============================================"
echo "WARNING: This is a heuristic parser for simple zones only."
echo "For complex zones, use: scripts/import_bind_zones.py"
echo
echo "Mode: $( [[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN" || echo "LIVE" )"
echo "Directory: $ZONE_DIR"
echo "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
echo "User ID: $USER_ID"
echo

# Detect schema
if [[ $DRY_RUN -eq 0 ]]; then
    echo "==> Detecting database schema..."
    
    # Check zone_files table columns
    ZONE_COLUMNS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
        "SELECT GROUP_CONCAT(COLUMN_NAME) FROM information_schema.COLUMNS 
         WHERE TABLE_SCHEMA='$DB_NAME' AND TABLE_NAME='zone_files'" 2>/dev/null || echo "")
    
    if [[ -z "$ZONE_COLUMNS" ]]; then
        echo "ERROR: Cannot detect zone_files table schema" >&2
        exit 1
    fi
    
    # Check dns_records table columns  
    RECORD_COLUMNS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
        "SELECT GROUP_CONCAT(COLUMN_NAME) FROM information_schema.COLUMNS 
         WHERE TABLE_SCHEMA='$DB_NAME' AND TABLE_NAME='dns_records'" 2>/dev/null || echo "")
    
    if [[ -z "$RECORD_COLUMNS" ]]; then
        echo "ERROR: Cannot detect dns_records table schema" >&2
        exit 1
    fi
    
    echo "  ✓ zone_files columns detected"
    echo "  ✓ dns_records columns detected"
    echo
fi

# Check if column exists in schema
has_column() {
    local table="$1"
    local column="$2"
    
    if [[ "$table" == "zone_files" ]]; then
        [[ ",$ZONE_COLUMNS," == *",$column,"* ]]
    else
        [[ ",$RECORD_COLUMNS," == *",$column,"* ]]
    fi
}

# MySQL escape function (basic SQL escaping for values used in queries)
# NOTE: This provides basic escaping for single quotes. The mysql CLI will handle
# the actual parameter passing safely. For production use, consider using mysql's
# --execute with proper quoting or the Python script with parameterized queries.
# Additional protections: identifier validation prevents injection via table/column names.
mysql_escape() {
    local value="$1"
    # Escape single quotes by doubling them (SQL standard)
    # Escape backslashes to prevent escape sequence issues
    value="${value//\\/\\\\}"  # Backslash -> double backslash
    value="${value//\'/\'\'}"   # Single quote -> double single quote
    echo "$value"
}

# Parse a simple zone file (heuristic approach)
parse_zone_file() {
    local file="$1"
    local filename=$(basename "$file")
    local zone_name=""
    local default_ttl=3600
    local origin=""
    
    echo "Processing: $filename"
    
    # Try to extract $ORIGIN
    origin=$(grep -E '^\$ORIGIN' "$file" | head -1 | awk '{print $2}' | sed 's/\.$//' || echo "")
    
    if [[ -z "$origin" ]]; then
        # Use filename without extension as zone name
        zone_name="${filename%.*}"
        # Remove common zone file extensions
        zone_name="${zone_name%.zone}"
        zone_name="${zone_name%.db}"
    else
        zone_name="$origin"
    fi
    
    # Validate zone name
    if [[ -z "$zone_name" ]]; then
        echo "  ⚠ Cannot determine zone name, skipping" >&2
        return 1
    fi
    
    echo "  Zone: $zone_name"
    
    # Check if zone exists
    if [[ $SKIP_EXISTING -eq 1 ]] && [[ $DRY_RUN -eq 0 ]]; then
        local exists=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
            "SELECT COUNT(*) FROM zone_files WHERE name='$(mysql_escape "$zone_name")'" "$DB_NAME" 2>/dev/null)
        
        if [[ "$exists" -gt 0 ]]; then
            echo "  ℹ Zone already exists, skipping"
            return 0
        fi
    fi
    
    # Extract $TTL
    local ttl_line=$(grep -E '^\$TTL' "$file" | head -1 || echo "")
    if [[ -n "$ttl_line" ]]; then
        default_ttl=$(echo "$ttl_line" | awk '{print $2}')
    fi
    
    echo "  Default TTL: $default_ttl"
    
    # Parse SOA (heuristic - assumes standard multi-line format)
    # WARNING: This uses -A 6 to grab 6 lines after SOA keyword, which works for most
    # standard BIND zone files but may fail on non-standard formatting or inline SOA records.
    # For complex zones, use the Python importer which properly parses SOA records.
    local soa_mname=""
    local soa_rname=""
    local soa_refresh=10800
    local soa_retry=900
    local soa_expire=604800
    local soa_minimum=3600
    
    # Find SOA record (multi-line aware, basic approach)
    if grep -q "SOA" "$file"; then
        # Extract SOA fields (simplified - assumes typical 6-line SOA format)
        local soa_data=$(grep -A 6 "SOA" "$file" | tr '\n' ' ' | sed 's/;.*$//')
        
        soa_mname=$(echo "$soa_data" | awk '{for(i=1;i<=NF;i++) if($i=="SOA") {print $(i+1); break}}')
        soa_rname=$(echo "$soa_data" | awk '{for(i=1;i<=NF;i++) if($i=="SOA") {print $(i+2); break}}')
        
        # Try to extract numeric values (serial, refresh, retry, expire, minimum)
        local nums=$(echo "$soa_data" | grep -oE '[0-9]+' | head -5)
        if [[ -n "$nums" ]]; then
            soa_refresh=$(echo "$nums" | sed -n '2p')
            soa_retry=$(echo "$nums" | sed -n '3p')
            soa_expire=$(echo "$nums" | sed -n '4p')
            soa_minimum=$(echo "$nums" | sed -n '5p')
        fi
    fi
    
    # Build INSERT statement for zone
    local zone_insert="INSERT INTO zone_files (name, filename, file_type, status, created_by, domain"
    local zone_values="VALUES ('$(mysql_escape "$zone_name")', '$(mysql_escape "$filename")', 'master', 'active', $USER_ID, '$(mysql_escape "$zone_name")'"
    
    # Add optional columns if they exist
    if has_column "zone_files" "default_ttl"; then
        zone_insert+=", default_ttl"
        zone_values+=", $default_ttl"
    fi
    
    if has_column "zone_files" "mname" && [[ -n "$soa_mname" ]]; then
        zone_insert+=", mname"
        zone_values+=", '$(mysql_escape "$soa_mname")'"
    fi
    
    if has_column "zone_files" "soa_rname" && [[ -n "$soa_rname" ]]; then
        zone_insert+=", soa_rname"
        zone_values+=", '$(mysql_escape "$soa_rname")'"
    fi
    
    if has_column "zone_files" "soa_refresh"; then
        zone_insert+=", soa_refresh"
        zone_values+=", $soa_refresh"
    fi
    
    if has_column "zone_files" "soa_retry"; then
        zone_insert+=", soa_retry"
        zone_values+=", $soa_retry"
    fi
    
    if has_column "zone_files" "soa_expire"; then
        zone_insert+=", soa_expire"
        zone_values+=", $soa_expire"
    fi
    
    if has_column "zone_files" "soa_minimum"; then
        zone_insert+=", soa_minimum"
        zone_values+=", $soa_minimum"
    fi
    
    if has_column "zone_files" "created_at"; then
        zone_insert+=", created_at"
        zone_values+=", NOW()"
    fi
    
    zone_insert+=") $zone_values);"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [DRY-RUN] Would execute: $zone_insert"
    else
        # Execute zone creation
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$zone_insert" 2>&1 || {
            echo "  ✗ Failed to create zone" >&2
            return 1
        }
        
        # Get zone ID
        local zone_id=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
            "SELECT id FROM zone_files WHERE name='$(mysql_escape "$zone_name")' ORDER BY id DESC LIMIT 1" "$DB_NAME")
        
        echo "  ✓ Zone created (ID: $zone_id)"
    fi
    
    # Parse DNS records (heuristic - line-by-line only)
    # WARNING: This parser processes one line at a time and does NOT handle:
    # - Multi-line records (SOA, TXT with line continuations, etc.)
    # - Parenthesized expressions spanning multiple lines
    # - Complex record formats
    # For accurate parsing of such records, use the Python importer.
    local record_count=0
    
    # Skip comments, $ORIGIN, $TTL, $INCLUDE, and SOA (already processed)
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*\; ]] && continue
        
        # Skip directives
        [[ "$line" =~ ^\$[A-Z]+ ]] && continue
        
        # Skip SOA continuation lines (heuristic)
        [[ "$line" =~ ^[[:space:]]*[0-9]+[[:space:]]*\) ]] && continue
        [[ "$line" =~ ^[[:space:]]*[0-9]+[[:space:]]*\; ]] && continue
        
        # Very basic record parsing
        # Format: name [ttl] [class] type rdata
        local parts=($line)
        if [[ ${#parts[@]} -lt 3 ]]; then
            continue
        fi
        
        local record_name="${parts[0]}"
        local record_type=""
        local record_value=""
        local record_ttl=$default_ttl
        
        # Handle @ for zone apex
        if [[ "$record_name" == "@" ]]; then
            record_name="$zone_name"
        elif [[ ! "$record_name" =~ \. ]]; then
            # Relative name
            record_name="${record_name}.${zone_name}"
        fi
        
        # Detect record type (look for known types)
        for part in "${parts[@]}"; do
            case "$part" in
                A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)
                    record_type="$part"
                    break
                    ;;
            esac
        done
        
        if [[ -z "$record_type" ]]; then
            continue
        fi
        
        # Extract value (everything after record type)
        local found_type=0
        record_value=""
        for part in "${parts[@]}"; do
            if [[ $found_type -eq 1 ]]; then
                record_value+="$part "
            elif [[ "$part" == "$record_type" ]]; then
                found_type=1
            fi
        done
        record_value=$(echo "$record_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -z "$record_value" ]]; then
            continue
        fi
        
        # Build INSERT statement for record (simplified)
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  [DRY-RUN] Would create record: $record_name $record_type $record_value"
            ((record_count++))
        else
            # Basic insert (using name column as per schema)
            local record_insert="INSERT INTO dns_records (zone_file_id, record_type, name, value, ttl, status, created_by"
            local record_vals="VALUES ($zone_id, '$(mysql_escape "$record_type")', '$(mysql_escape "$record_name")', '$(mysql_escape "$record_value")', $record_ttl, 'active', $USER_ID"
            
            # Add type-specific columns if available
            if [[ "$record_type" == "A" ]] && has_column "dns_records" "address_ipv4"; then
                record_insert+=", address_ipv4"
                record_vals+=", '$(mysql_escape "$record_value")'"
            elif [[ "$record_type" == "AAAA" ]] && has_column "dns_records" "address_ipv6"; then
                record_insert+=", address_ipv6"
                record_vals+=", '$(mysql_escape "$record_value")'"
            elif [[ "$record_type" == "CNAME" ]] && has_column "dns_records" "cname_target"; then
                record_insert+=", cname_target"
                record_vals+=", '$(mysql_escape "$record_value")'"
            elif [[ "$record_type" == "MX" ]] && has_column "dns_records" "mx_target"; then
                # MX has priority and target
                local mx_parts=($record_value)
                local mx_priority="${mx_parts[0]}"
                local mx_target="${mx_parts[1]}"
                if has_column "dns_records" "priority"; then
                    record_insert+=", priority"
                    record_vals+=", $mx_priority"
                fi
                record_insert+=", mx_target"
                record_vals+=", '$(mysql_escape "$mx_target")'"
            elif [[ "$record_type" == "NS" ]] && has_column "dns_records" "ns_target"; then
                record_insert+=", ns_target"
                record_vals+=", '$(mysql_escape "$record_value")'"
            elif [[ "$record_type" == "PTR" ]] && has_column "dns_records" "ptrdname"; then
                record_insert+=", ptrdname"
                record_vals+=", '$(mysql_escape "$record_value")'"
            elif [[ "$record_type" == "TXT" ]] && has_column "dns_records" "txt"; then
                # Remove quotes from TXT
                local txt_value=$(echo "$record_value" | sed 's/^"//;s/"$//')
                record_insert+=", txt"
                record_vals+=", '$(mysql_escape "$txt_value")'"
            fi
            
            if has_column "dns_records" "created_at"; then
                record_insert+=", created_at"
                record_vals+=", NOW()"
            fi
            
            record_insert+=") $record_vals);"
            
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$record_insert" 2>&1 && {
                ((record_count++))
            } || {
                echo "  ⚠ Failed to create record: $record_name $record_type" >&2
            }
        fi
        
    done < "$file"
    
    echo "  ✓ Processed $record_count record(s)"
    return 0
}

# Main execution
echo "==> Scanning for zone files..."

# Find zone files
ZONE_FILES=()
while IFS= read -r -d '' file; do
    ZONE_FILES+=("$file")
done < <(find "$ZONE_DIR" -maxdepth 1 -type f \( -name "*.zone" -o -name "*.db" -o -name "db.*" \) -print0)

if [[ ${#ZONE_FILES[@]} -eq 0 ]]; then
    echo "WARNING: No zone files found in $ZONE_DIR" >&2
    echo "Looking for files with extensions: .zone, .db, db.*" >&2
    exit 1
fi

echo "Found ${#ZONE_FILES[@]} zone file(s)"
echo

# Process each zone file
PROCESSED=0
FAILED=0

for zone_file in "${ZONE_FILES[@]}"; do
    if parse_zone_file "$zone_file"; then
        ((PROCESSED++))
    else
        ((FAILED++))
    fi
    echo
done

# Summary
echo "============================================"
echo "Import Summary:"
echo "  Files processed: $PROCESSED"
echo "  Files failed: $FAILED"
echo "  Total files: ${#ZONE_FILES[@]}"
echo "============================================"

if [[ $DRY_RUN -eq 1 ]]; then
    echo
    echo "This was a DRY-RUN. No changes were made."
    echo "Remove --dry-run to perform actual import."
fi

exit 0
