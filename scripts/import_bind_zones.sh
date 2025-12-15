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
#   --create-includes      Create separate zone_file entries for $INCLUDE directives
#   --allow-abs-include    Allow absolute paths in $INCLUDE directives (security: use with caution)
#   --include-search-paths PATHS  Additional search paths for $INCLUDE files (colon or comma separated)
#   --log-file PATH        Path to log file (stdout/stderr will be logged to file using tee)
#
# Examples:
#   # Dry-run mode (safe testing)
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --dry-run
#
#   # Import zones with $INCLUDE support
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --db-user root --db-pass secret --create-includes
#
#   # Import with absolute includes allowed
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --db-user root --db-pass secret --create-includes --allow-abs-include
#
#   # Import with additional search paths for includes
#   ./scripts/import_bind_zones.sh --dir /var/named/zones --db-user root --db-pass secret --create-includes --include-search-paths "/var/named/includes:/etc/bind/includes"
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
CREATE_INCLUDES=0
ALLOW_ABS_INCLUDE=0
INCLUDE_SEARCH_PATHS=""
LOG_FILE=""

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
        --create-includes)
            CREATE_INCLUDES=1
            shift
            ;;
        --allow-abs-include)
            ALLOW_ABS_INCLUDE=1
            shift
            ;;
        --include-search-paths)
            INCLUDE_SEARCH_PATHS="$2"
            shift 2
            ;;
        --log-file)
            LOG_FILE="$2"
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

# Setup logging to file if requested
if [[ -n "$LOG_FILE" ]]; then
    # Create log directory if it doesn't exist
    LOG_DIR="$(dirname "$LOG_FILE")"
    if [[ -n "$LOG_DIR" ]] && [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
    
    # Redirect stdout and stderr to both console and log file (append mode)
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Logging to file: $LOG_FILE"
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

# Initialize column tracking variables
ZONE_COLUMNS=""
RECORD_COLUMNS=""

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
else
    # In dry-run mode, assume common columns exist
    echo "==> DRY-RUN mode: Assuming standard schema"
    ZONE_COLUMNS="id,name,filename,file_type,status,created_by,domain,directory,default_ttl,mname,soa_rname,soa_serial,soa_refresh,soa_retry,soa_expire,soa_minimum,created_at"
    RECORD_COLUMNS="id,zone_file_id,record_type,name,value,ttl,status,created_by,address_ipv4,address_ipv6,cname_target,mx_target,priority,ns_target,ptrdname,txt,created_at"
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

# Track processed includes (global associative array)
# Note: Requires Bash 4.0+ for associative arrays
declare -A PROCESSED_INCLUDES

# Compute SHA256 hash of file
compute_file_hash() {
    local file="$1"
    if [[ -f "$file" ]]; then
        sha256sum "$file" | awk '{print $1}'
    else
        echo ""
    fi
}

# Convert BIND time unit to seconds
# Supports: s (seconds), m (minutes), h (hours), d (days), w (weeks)
# Also supports decimal values: 1.5h, 0.5d, 2.25m
# Example: "1h" -> 3600, "1.5h" -> 5400, "30m" -> 1800, "86400" -> 86400
convert_ttl_to_seconds() {
    local ttl="$1"
    
    # Check if TTL has a time unit suffix (supports decimal values)
    if [[ "$ttl" =~ ^([0-9]+(\.[0-9]+)?)([smhdw])$ ]]; then
        local value="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[3]}"
        
        # Use bc for decimal arithmetic if available, otherwise use integer arithmetic
        if command -v bc >/dev/null 2>&1; then
            local multiplier
            case "$unit" in
                s) multiplier=1 ;;
                m) multiplier=60 ;;
                h) multiplier=3600 ;;
                d) multiplier=86400 ;;
                w) multiplier=604800 ;;
                *) echo "$ttl"; return ;;  # Fallback
            esac
            # Use scale=0 to get integer result
            echo "scale=0; $value * $multiplier / 1" | bc
        else
            # Fallback to integer-only arithmetic if bc is not available (truncates decimals)
            local int_value="${value%.*}"  # Extract integer part
            case "$unit" in
                s) echo "$int_value" ;;
                m) echo $((int_value * 60)) ;;
                h) echo $((int_value * 3600)) ;;
                d) echo $((int_value * 86400)) ;;
                w) echo $((int_value * 604800)) ;;
                *) echo "$ttl" ;;  # Fallback
            esac
        fi
    else
        # No unit suffix, assume already in seconds (handle decimal values)
        if [[ "$ttl" =~ \. ]] && command -v bc >/dev/null 2>&1; then
            # Truncate decimal part for consistency (BIND expects integer seconds)
            echo "scale=0; $ttl / 1" | bc
        else
            # Integer or no bc available - truncate decimal part
            echo "${ttl%.*}"
        fi
    fi
}

# Resolve include path (relative to absolute) using multiple strategies
# Resolution order for relative paths:
# 1. Resolve relative to base_dir (directory of master zone file)
# 2. Resolve relative to import_root (ZONE_DIR)
# 3. Resolve relative to current working directory (CWD)
# 4. Try each path in INCLUDE_SEARCH_PATHS
# 5. If include_path is a basename (no slash), do recursive search under import_root
resolve_include_path() {
    local include_path="$1"
    local base_dir="$2"
    local resolved=""
    local attempted_paths=()
    local import_root=""
    
    # Normalize import_root
    if [[ -n "$ZONE_DIR" ]]; then
        import_root="$(cd "$ZONE_DIR" && pwd)"
    fi
    
    # Check if absolute path
    if [[ "$include_path" = /* ]]; then
        if [[ $ALLOW_ABS_INCLUDE -eq 0 ]]; then
            echo "ERROR: Absolute include path not allowed: $include_path" >&2
            echo "Use --allow-abs-include to override" >&2
            return 1
        fi
        
        resolved="$include_path"
        
        # For absolute paths, still check import_root security unless explicitly allowed
        if [[ $ALLOW_ABS_INCLUDE -eq 0 ]] && [[ -n "$import_root" ]]; then
            if [[ "$resolved" != "$import_root"* ]]; then
                echo "ERROR: Absolute include path outside import root: $include_path" >&2
                return 1
            fi
        fi
        
        if [[ -f "$resolved" ]]; then
            echo "$resolved"
            return 0
        else
            echo "ERROR: Absolute include file not found: $resolved" >&2
            return 1
        fi
    fi
    
    # Relative path - try multiple strategies in order
    local candidates=()
    local strategies=()
    
    # Strategy 1: Resolve relative to base_dir (directory of current master/include file)
    if command -v realpath >/dev/null 2>&1; then
        local candidate1="$(cd "$base_dir" && realpath "$include_path" 2>/dev/null || echo "")"
    else
        local candidate1="$(cd "$base_dir" && pwd)/$include_path"
        # Normalize path
        candidate1="$(echo "$candidate1" | sed 's|/\./|/|g')"
        while [[ "$candidate1" =~ /[^/]+/\.\. ]]; do
            candidate1="$(echo "$candidate1" | sed 's|/[^/]*/\.\.|/|')"
        done
    fi
    if [[ -n "$candidate1" ]]; then
        candidates+=("$candidate1")
        strategies+=("base_dir")
        attempted_paths+=("base_dir -> $candidate1")
    fi
    
    # Strategy 2: Resolve relative to import_root (ZONE_DIR)
    if [[ -n "$import_root" ]] && [[ "$import_root" != "$(cd "$base_dir" && pwd)" ]]; then
        if command -v realpath >/dev/null 2>&1; then
            local candidate2="$(cd "$import_root" && realpath "$include_path" 2>/dev/null || echo "")"
        else
            local candidate2="$import_root/$include_path"
            # Normalize path
            candidate2="$(echo "$candidate2" | sed 's|/\./|/|g')"
            while [[ "$candidate2" =~ /[^/]+/\.\. ]]; do
                candidate2="$(echo "$candidate2" | sed 's|/[^/]*/\.\.|/|')"
            done
        fi
        if [[ -n "$candidate2" ]]; then
            candidates+=("$candidate2")
            strategies+=("import_root")
            attempted_paths+=("import_root -> $candidate2")
        fi
    fi
    
    # Strategy 3: Resolve relative to current working directory
    local cwd="$(pwd)"
    if [[ "$cwd" != "$(cd "$base_dir" && pwd)" ]] && [[ -z "$import_root" || "$cwd" != "$import_root" ]]; then
        if command -v realpath >/dev/null 2>&1; then
            local candidate3="$(realpath "$include_path" 2>/dev/null || echo "")"
        else
            local candidate3="$cwd/$include_path"
            # Normalize path
            candidate3="$(echo "$candidate3" | sed 's|/\./|/|g')"
            while [[ "$candidate3" =~ /[^/]+/\.\. ]]; do
                candidate3="$(echo "$candidate3" | sed 's|/[^/]*/\.\.|/|')"
            done
        fi
        if [[ -n "$candidate3" ]]; then
            candidates+=("$candidate3")
            strategies+=("cwd")
            attempted_paths+=("cwd -> $candidate3")
        fi
    fi
    
    # Strategy 4: Try each path in INCLUDE_SEARCH_PATHS
    if [[ -n "$INCLUDE_SEARCH_PATHS" ]]; then
        # Split by colon or comma
        local IFS
        if [[ "$INCLUDE_SEARCH_PATHS" == *:* ]]; then
            IFS=':'
        else
            IFS=','
        fi
        local search_paths_array=($INCLUDE_SEARCH_PATHS)
        
        for search_path in "${search_paths_array[@]}"; do
            # Trim whitespace
            search_path="$(echo "$search_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            if [[ -z "$search_path" ]]; then
                continue
            fi
            
            if command -v realpath >/dev/null 2>&1; then
                local candidate4="$(cd "$search_path" 2>/dev/null && realpath "$include_path" 2>/dev/null || echo "")"
            else
                local candidate4="$search_path/$include_path"
                # Normalize path
                candidate4="$(echo "$candidate4" | sed 's|/\./|/|g')"
                while [[ "$candidate4" =~ /[^/]+/\.\. ]]; do
                    candidate4="$(echo "$candidate4" | sed 's|/[^/]*/\.\.|/|')"
                done
            fi
            
            if [[ -n "$candidate4" ]]; then
                candidates+=("$candidate4")
                strategies+=("search_path:$search_path")
                attempted_paths+=("search_path:$search_path -> $candidate4")
            fi
        done
    fi
    
    # Check each candidate
    for i in "${!candidates[@]}"; do
        local candidate="${candidates[$i]}"
        local strategy="${strategies[$i]}"
        
        # Security check: ensure resolved path is within import_root (unless allow_abs_include)
        if [[ $ALLOW_ABS_INCLUDE -eq 0 ]] && [[ -n "$import_root" ]]; then
            if [[ "$candidate" != "$import_root"* ]]; then
                # Skip candidates outside import_root
                continue
            fi
        fi
        
        # Check if file exists
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    
    # Strategy 5: If include_path is a basename (no slash), do recursive search under import_root
    if [[ "$include_path" != */* ]] && [[ -n "$import_root" ]]; then
        attempted_paths+=("recursive_search under $import_root")
        
        # Use find to search recursively
        local matches=()
        while IFS= read -r -d '' match; do
            matches+=("$match")
        done < <(find "$import_root" -type f -name "$include_path" -print0 2>/dev/null)
        
        if [[ ${#matches[@]} -gt 0 ]]; then
            if [[ ${#matches[@]} -gt 1 ]]; then
                echo "WARNING: Multiple matches found for '$include_path': ${#matches[@]} files" >&2
                echo "WARNING: Using first match: ${matches[0]}" >&2
                local limit=5
                for idx in "${!matches[@]}"; do
                    if [[ $idx -lt $limit ]]; then
                        echo "  Match $((idx+1)): ${matches[$idx]}" >&2
                    fi
                done
            fi
            
            echo "${matches[0]}"
            return 0
        fi
    fi
    
    # No candidate found - log all attempted paths
    echo "ERROR: Include file not found: $include_path" >&2
    echo "Attempted paths:" >&2
    for path in "${attempted_paths[@]}"; do
        echo "  - $path" >&2
    done
    
    return 1
}

# Create zone_file_includes relationship
create_zone_file_include_relationship() {
    local parent_id="$1"
    local include_id="$2"
    local position="$3"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [DRY-RUN] Would create zone_file_includes: parent=$parent_id, include=$include_id, position=$position"
        return 0
    fi
    
    # Check if relationship already exists
    local exists=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
        "SELECT COUNT(*) FROM zone_file_includes WHERE parent_id=$parent_id AND include_id=$include_id" "$DB_NAME" 2>/dev/null)
    
    if [[ "$exists" -gt 0 ]]; then
        echo "  ℹ zone_file_includes relationship already exists"
        return 0
    fi
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e \
        "INSERT INTO zone_file_includes (parent_id, include_id, position) VALUES ($parent_id, $include_id, $position)" 2>&1 || {
        echo "  ⚠ Failed to create zone_file_includes relationship" >&2
        return 1
    }
    
    echo "  ✓ Created zone_file_includes relationship"
    return 0
}

# Process an include file
process_include_file() {
    local include_path="$1"
    local include_origin="$2"
    local base_dir="$3"
    local parent_zone_name="$4"
    local master_ttl="${5:-3600}"  # Default to 3600 if not provided
    
    # Compute hash for deduplication
    local file_hash=$(compute_file_hash "$include_path")
    
    # Check if already processed (use explicit key existence check)
    if [[ -v "PROCESSED_INCLUDES[$include_path]" ]]; then
        echo "  ℹ Include already processed (dedup by path): $(basename "$include_path") (ID: ${PROCESSED_INCLUDES[$include_path]})"
        echo "${PROCESSED_INCLUDES[$include_path]}"
        return 0
    fi
    
    if [[ -n "$file_hash" ]] && [[ -v "PROCESSED_INCLUDES[$file_hash]" ]]; then
        echo "  ℹ Include already processed (dedup by hash): $(basename "$include_path") (ID: ${PROCESSED_INCLUDES[$file_hash]})"
        echo "${PROCESSED_INCLUDES[$file_hash]}"
        return 0
    fi
    
    echo "  Processing include file: $(basename "$include_path")"
    
    # Read include content
    local include_content=$(cat "$include_path")
    local filename=$(basename "$include_path")
    local directory=$(dirname "$include_path")
    
    # Determine effective origin
    local effective_origin="$include_origin"
    if [[ -z "$effective_origin" ]]; then
        # Check for $ORIGIN in include file
        effective_origin=$(echo "$include_content" | grep -E '^\$ORIGIN' | head -1 | awk '{print $2}' | sed 's/\.$//' || echo "$parent_zone_name")
    fi
    
    # Remove trailing dot if present
    effective_origin="${effective_origin%.}"
    
    echo "    Origin: $effective_origin"
    
    # Check if include file has its own $TTL directive
    local include_ttl_raw=$(echo "$include_content" | grep -E '^\$TTL' | head -1 | awk '{print $2}' || echo "")
    local ttl_to_use
    if [[ -n "$include_ttl_raw" ]]; then
        # Convert BIND time units to seconds
        ttl_to_use=$(convert_ttl_to_seconds "$include_ttl_raw")
        echo "    Using include's own TTL: $include_ttl_raw ($ttl_to_use seconds)"
    else
        ttl_to_use="$master_ttl"
        echo "    Include has no \$TTL directive. Using master's default TTL: $ttl_to_use seconds"
    fi
    
    # Check if include zone already exists (skip-existing logic)
    local zone_id=""
    if [[ $SKIP_EXISTING -eq 1 ]]; then
        zone_id=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
            "SELECT id FROM zone_files WHERE filename='$(mysql_escape "$filename")' AND file_type='include' AND directory='$(mysql_escape "$directory")' LIMIT 1" \
            "$DB_NAME" 2>/dev/null || echo "")
        
        if [[ -n "$zone_id" ]]; then
            echo "    ℹ Include zone already exists, reusing (ID: $zone_id)"
            PROCESSED_INCLUDES[$include_path]="$zone_id"
            [[ -n "$file_hash" ]] && PROCESSED_INCLUDES[$file_hash]="$zone_id"
            echo "$zone_id"
            return 0
        fi
    fi
    
    # Build INSERT statement for include zone (content NOT stored - records in dns_records)
    # Use filename stem (without extension) as name to avoid conflicts with master zone
    local filename_stem="${filename%.*}"  # e.g., "logiciel1" from "logiciel1.db"
    local zone_insert="INSERT INTO zone_files (name, filename, file_type, status, created_by, domain"
    local zone_values="VALUES ('$(mysql_escape "$filename_stem")', '$(mysql_escape "$filename")', 'include', 'active', $USER_ID, '$(mysql_escape "$effective_origin")'"
    
    # Add optional columns (content NOT included - records will be in dns_records table)
    if has_column "zone_files" "directory"; then
        zone_insert+=", directory"
        zone_values+=", '$(mysql_escape "$directory")'"
    fi
    
    if has_column "zone_files" "default_ttl"; then
        zone_insert+=", default_ttl"
        zone_values+=", $ttl_to_use"
    fi
    
    if has_column "zone_files" "created_at"; then
        zone_insert+=", created_at"
        zone_values+=", NOW()"
    fi
    
    zone_insert+=") $zone_values);"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "    [DRY-RUN] Would create include zone: $effective_origin"
        echo "0"
        return 0
    fi
    
    # Execute zone creation
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$zone_insert" 2>&1 || {
        echo "    ✗ Failed to create include zone" >&2
        echo ""
        return 1
    }
    
    # Get zone ID
    zone_id=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
        "SELECT id FROM zone_files WHERE name='$(mysql_escape "$filename_stem")' AND file_type='include' ORDER BY id DESC LIMIT 1" "$DB_NAME")
    
    if [[ -z "$zone_id" ]]; then
        echo "    ✗ Failed to get include zone ID" >&2
        echo ""
        return 1
    fi
    
    echo "    ✓ Include zone created (ID: $zone_id)"
    
    # Store for deduplication
    PROCESSED_INCLUDES[$include_path]="$zone_id"
    [[ -n "$file_hash" ]] && PROCESSED_INCLUDES[$file_hash]="$zone_id"
    
    # Parse DNS records from include file (simplified heuristic)
    # WARNING: This is a basic parser - for complex includes use the Python script
    local record_count=0
    while IFS= read -r line; do
        # Skip empty lines, comments, directives
        [[ -z "$line" || "$line" =~ ^[[:space:]]*\; ]] && continue
        [[ "$line" =~ ^\$[A-Z]+ ]] && continue
        
        # Basic record parsing (same logic as master zone)
        local parts=($line)
        if [[ ${#parts[@]} -lt 3 ]]; then
            continue
        fi
        
        local record_name="${parts[0]}"
        local record_type=""
        local record_value=""
        local explicit_ttl=""
        local has_explicit_ttl=0
        
        # Detect if line has explicit TTL (number after name, before or with class/type)
        # Format: name [ttl] [class] type rdata
        local idx=1
        while [[ $idx -lt ${#parts[@]} ]]; do
            local part="${parts[$idx]}"
            
            # Check if this looks like a TTL (number with optional time unit)
            if [[ "$part" =~ ^[0-9]+(\.[0-9]+)?[smhdw]?$ ]]; then
                # Next part should be class or type
                if [[ $((idx + 1)) -lt ${#parts[@]} ]]; then
                    local next_part="${parts[$((idx + 1))]}"
                    case "$next_part" in
                        IN|CH|HS|NONE|ANY|A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)
                            has_explicit_ttl=1
                            explicit_ttl=$(convert_ttl_to_seconds "$part")
                            ;;
                    esac
                fi
                break
            # Check if this is a class or type (no TTL found)
            elif [[ "$part" =~ ^(IN|CH|HS|NONE|ANY|A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)$ ]]; then
                break
            fi
            ((idx++))
        done
        
        # Preserve record name as-is from zone file (do not concatenate with origin)
        # The name will be stored exactly as it appears: @ for apex, relative names stay relative
        # This matches the Python script behavior with relativize=True and name.to_text()
        
        # Detect record type
        for part in "${parts[@]}"; do
            case "$part" in
                A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)
                    record_type="$part"
                    break
                    ;;
            esac
        done
        
        [[ -z "$record_type" ]] && continue
        
        # Extract value
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
        
        [[ -z "$record_value" ]] && continue
        
        # Create record for include - only include TTL if it was explicit
        local record_insert="INSERT INTO dns_records (zone_file_id, record_type, name, value"
        local record_vals="VALUES ($zone_id, '$(mysql_escape "$record_type")', '$(mysql_escape "$record_name")', '$(mysql_escape "$record_value")'"
        
        # Only add TTL column if it was explicit in the original line
        if [[ $has_explicit_ttl -eq 1 ]]; then
            record_insert+=", ttl"
            record_vals+=", $explicit_ttl"
        fi
        
        record_insert+=", status, created_by"
        record_vals+=", 'active', $USER_ID"
        
        # Add type-specific columns (simplified)
        if [[ "$record_type" == "A" ]] && has_column "dns_records" "address_ipv4"; then
            record_insert+=", address_ipv4"
            record_vals+=", '$(mysql_escape "$record_value")'"
        elif [[ "$record_type" == "CNAME" ]] && has_column "dns_records" "cname_target"; then
            record_insert+=", cname_target"
            record_vals+=", '$(mysql_escape "$record_value")'"
        fi
        
        if has_column "dns_records" "created_at"; then
            record_insert+=", created_at"
            record_vals+=", NOW()"
        fi
        
        record_insert+=") $record_vals);"
        
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$record_insert" 2>&1 && {
            ((record_count++))
        }
        
    done <<< "$include_content"
    
    echo "    ✓ Created $record_count record(s) for include"
    echo "$zone_id"
    return 0
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
        local ttl_raw=$(echo "$ttl_line" | awk '{print $2}')
        # Convert BIND time units to seconds
        default_ttl=$(convert_ttl_to_seconds "$ttl_raw")
    fi
    
    echo "  Default TTL: $default_ttl seconds"
    
    # Parse SOA (heuristic - assumes standard multi-line format)
    # WARNING: This uses -A 6 to grab 6 lines after SOA keyword, which works for most
    # standard BIND zone files but may fail on non-standard formatting or inline SOA records.
    # For complex zones, use the Python importer which properly parses SOA records.
    local soa_mname=""
    local soa_rname=""
    local soa_serial=""
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
            soa_serial=$(echo "$nums" | sed -n '1p')
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
    
    if has_column "zone_files" "soa_serial" && [[ -n "$soa_serial" ]]; then
        zone_insert+=", soa_serial"
        zone_values+=", $soa_serial"
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
    
    # Content NOT stored - SOA/TTL in columns, records in dns_records table
    # if has_column "zone_files" "content"; then
    #     local file_content=$(cat "$file")
    #     zone_insert+=", content"
    #     zone_values+=", '$(mysql_escape "$file_content")'"
    # fi
    
    # Store directory path
    if has_column "zone_files" "directory"; then
        zone_insert+=", directory"
        zone_values+=", '$(mysql_escape "$(dirname "$file")")'"
    fi
    
    if has_column "zone_files" "created_at"; then
        zone_insert+=", created_at"
        zone_values+=", NOW()"
    fi
    
    zone_insert+=") $zone_values);"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [DRY-RUN] Would create master zone: $zone_name"
        echo "  [DRY-RUN] SQL: $zone_insert"
        
        # Process $INCLUDE directives in dry-run
        local include_count=0
        if [[ $CREATE_INCLUDES -eq 1 ]]; then
            echo "  [DRY-RUN] Checking for \$INCLUDE directives..."
            local line_num=0
            local current_origin="$origin"
            
            while IFS= read -r line; do
                ((line_num++))
                
                # Track $ORIGIN changes
                if [[ "$line" =~ ^\$ORIGIN[[:space:]]+([^[:space:]]+) ]]; then
                    current_origin="${BASH_REMATCH[1]}"
                    current_origin="${current_origin%.}"
                    continue
                fi
                
                # Find $INCLUDE directives
                if [[ "$line" =~ ^\$INCLUDE[[:space:]]+([^[:space:]]+)([[:space:]]+([^[:space:]]+))? ]]; then
                    local include_file="${BASH_REMATCH[1]}"
                    local include_origin="${BASH_REMATCH[3]:-$current_origin}"
                    
                    # Remove quotes
                    include_file="${include_file//\"/}"
                    include_file="${include_file//\'/}"
                    
                    echo "    [DRY-RUN] Found \$INCLUDE at line $line_num: $include_file (origin: $include_origin)"
                    
                    # Resolve include path (capture errors to prevent set -e from stopping)
                    local resolved_include=""
                    local resolve_exit_code=0
                    resolved_include=$(resolve_include_path "$include_file" "$(dirname "$file")") || resolve_exit_code=$?
                    
                    if [[ $resolve_exit_code -eq 0 ]] && [[ -n "$resolved_include" ]]; then
                        # Process include file with master's TTL (capture errors to prevent set -e from stopping)
                        local include_id=""
                        local process_exit_code=0
                        include_id=$(process_include_file "$resolved_include" "$include_origin" "$(dirname "$file")" "$zone_name" "$default_ttl") || process_exit_code=$?
                        
                        if [[ $process_exit_code -eq 0 ]] && [[ -n "$include_id" ]] && [[ "$include_id" != "" ]]; then
                            ((include_count++))
                        else
                            echo "    [DRY-RUN] ⚠ Failed to process include (continuing with remaining records)" >&2
                        fi
                    else
                        echo "    [DRY-RUN] ⚠ Could not resolve include (continuing with remaining records)" >&2
                    fi
                fi
            done < "$file"
            
            if [[ $include_count -gt 0 ]]; then
                echo "  [DRY-RUN] Would create $include_count zone_file_includes relationship(s)"
            fi
        fi
    else
        # Execute zone creation
        mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$zone_insert" 2>&1 || {
            echo "  ✗ Failed to create zone" >&2
            return 1
        }
        
        # Get zone ID
        local zone_id=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e \
            "SELECT id FROM zone_files WHERE name='$(mysql_escape "$zone_name")' ORDER BY id DESC LIMIT 1" "$DB_NAME")
        
        echo "  ✓ Master zone created (ID: $zone_id)"
        
        # Process $INCLUDE directives after master zone is created
        local include_zone_ids=()
        if [[ $CREATE_INCLUDES -eq 1 ]]; then
            echo "  Processing \$INCLUDE directives..."
            local include_count=0
            local line_num=0
            local current_origin="$origin"
            
            while IFS= read -r line; do
                ((line_num++))
                
                # Track $ORIGIN changes
                if [[ "$line" =~ ^\$ORIGIN[[:space:]]+([^[:space:]]+) ]]; then
                    current_origin="${BASH_REMATCH[1]}"
                    current_origin="${current_origin%.}"
                    continue
                fi
                
                # Find $INCLUDE directives
                if [[ "$line" =~ ^\$INCLUDE[[:space:]]+([^[:space:]]+)([[:space:]]+([^[:space:]]+))? ]]; then
                    local include_file="${BASH_REMATCH[1]}"
                    local include_origin="${BASH_REMATCH[3]:-$current_origin}"
                    
                    # Remove quotes
                    include_file="${include_file//\"/}"
                    include_file="${include_file//\'/}"
                    
                    echo "    Found \$INCLUDE at line $line_num: $include_file (origin: $include_origin)"
                    
                    # Resolve include path (capture errors to prevent set -e from stopping)
                    local resolved_include=""
                    local resolve_exit_code=0
                    resolved_include=$(resolve_include_path "$include_file" "$(dirname "$file")") || resolve_exit_code=$?
                    
                    if [[ $resolve_exit_code -eq 0 ]] && [[ -n "$resolved_include" ]]; then
                        # Process include file with master's TTL (capture errors to prevent set -e from stopping)
                        local include_id=""
                        local process_exit_code=0
                        include_id=$(process_include_file "$resolved_include" "$include_origin" "$(dirname "$file")" "$zone_name" "$default_ttl") || process_exit_code=$?
                        
                        if [[ $process_exit_code -eq 0 ]] && [[ -n "$include_id" ]] && [[ "$include_id" != "0" ]]; then
                            include_zone_ids+=("$include_id:$include_count")
                            ((include_count++))
                        else
                            echo "    ⚠ Failed to process include at line $line_num: $include_file (continuing with remaining records)" >&2
                        fi
                    else
                        echo "    ⚠ Could not resolve include at line $line_num: $include_file (continuing with remaining records)" >&2
                    fi
                fi
            done < "$file"
            
            if [[ ${#include_zone_ids[@]} -gt 0 ]]; then
                echo "  ✓ Processed ${#include_zone_ids[@]} include(s)"
            fi
        fi
        
        # Create zone_file_includes relationships
        if [[ ${#include_zone_ids[@]} -gt 0 ]]; then
            for include_info in "${include_zone_ids[@]}"; do
                local include_id="${include_info%%:*}"
                local position="${include_info##*:}"
                create_zone_file_include_relationship "$zone_id" "$include_id" "$position"
            done
        fi
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
        local explicit_ttl=""
        local has_explicit_ttl=0
        
        # Detect if line has explicit TTL (number after name, before or with class/type)
        local idx=1
        while [[ $idx -lt ${#parts[@]} ]]; do
            local part="${parts[$idx]}"
            
            # Check if this looks like a TTL (number with optional time unit)
            if [[ "$part" =~ ^[0-9]+(\.[0-9]+)?[smhdw]?$ ]]; then
                # Next part should be class or type
                if [[ $((idx + 1)) -lt ${#parts[@]} ]]; then
                    local next_part="${parts[$((idx + 1))]}"
                    case "$next_part" in
                        IN|CH|HS|NONE|ANY|A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)
                            has_explicit_ttl=1
                            explicit_ttl=$(convert_ttl_to_seconds "$part")
                            ;;
                    esac
                fi
                break
            # Check if this is a class or type (no TTL found)
            elif [[ "$part" =~ ^(IN|CH|HS|NONE|ANY|A|AAAA|CNAME|MX|NS|PTR|TXT|SRV|CAA)$ ]]; then
                break
            fi
            ((idx++))
        done
        
        # Preserve record name as-is from zone file (do not concatenate with origin)
        # The name will be stored exactly as it appears: @ for apex, relative names stay relative
        # This matches the Python script behavior with relativize=True and name.to_text()
        
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
            local ttl_msg=""
            if [[ $has_explicit_ttl -eq 1 ]]; then
                ttl_msg=" (explicit TTL: $explicit_ttl)"
            fi
            echo "  [DRY-RUN] Would create record: $record_name $record_type $record_value$ttl_msg"
            ((record_count++))
        else
            # Basic insert - only include TTL if it was explicit
            local record_insert="INSERT INTO dns_records (zone_file_id, record_type, name, value"
            local record_vals="VALUES ($zone_id, '$(mysql_escape "$record_type")', '$(mysql_escape "$record_name")', '$(mysql_escape "$record_value")'"
            
            # Only add TTL column if it was explicit in the original line
            if [[ $has_explicit_ttl -eq 1 ]]; then
                record_insert+=", ttl"
                record_vals+=", $explicit_ttl"
            fi
            
            record_insert+=", status, created_by"
            record_vals+=", 'active', $USER_ID"
            
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
