#!/bin/bash
# Verification script for created_at/updated_at columns

echo "==================================================="
echo "DNS3 - Created At / Updated At Column Verification"
echo "==================================================="
echo ""

# Check if mysql/mariadb is available
if ! command -v mysql &> /dev/null; then
    echo "ERROR: mysql command not found. Please install MySQL/MariaDB client."
    exit 1
fi

# Database configuration - update these as needed
DB_NAME="dns3_db"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-}"
DB_HOST="${DB_HOST:-localhost}"

echo "Checking database: $DB_NAME"
echo "Host: $DB_HOST"
echo "User: $DB_USER"
echo ""

# Function to run SQL query
run_query() {
    local query="$1"
    if [ -z "$DB_PASS" ]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" -e "$query" 2>&1
    else
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "$query" 2>&1
    fi
}

echo "1. Checking if created_at column exists in dns_records table..."
CREATED_AT_CHECK=$(run_query "SELECT COUNT(*) as count FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'created_at';" | tail -n 1)

if [ "$CREATED_AT_CHECK" = "1" ]; then
    echo "   ✓ created_at column exists"
else
    echo "   ✗ created_at column NOT FOUND!"
    echo "   Please run migration 003_add_dns_fields.sql"
    exit 1
fi

echo ""
echo "2. Checking if updated_at column exists in dns_records table..."
UPDATED_AT_CHECK=$(run_query "SELECT COUNT(*) as count FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'updated_at';" | tail -n 1)

if [ "$UPDATED_AT_CHECK" = "1" ]; then
    echo "   ✓ updated_at column exists"
else
    echo "   ✗ updated_at column NOT FOUND!"
    echo "   Please run migration 003_add_dns_fields.sql"
    exit 1
fi

echo ""
echo "3. Checking column definitions..."
run_query "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME IN ('created_at', 'updated_at') ORDER BY ORDINAL_POSITION;"

echo ""
echo "4. Checking sample records..."
RECORD_COUNT=$(run_query "SELECT COUNT(*) as count FROM dns_records;" | tail -n 1)
echo "   Total records in dns_records: $RECORD_COUNT"

if [ "$RECORD_COUNT" -gt "0" ]; then
    echo ""
    echo "   Sample of first 3 records with timestamps:"
    run_query "SELECT id, name, record_type, created_at, updated_at FROM dns_records ORDER BY id LIMIT 3;"
    
    echo ""
    echo "5. Checking for NULL timestamps..."
    NULL_CREATED=$(run_query "SELECT COUNT(*) as count FROM dns_records WHERE created_at IS NULL;" | tail -n 1)
    NULL_UPDATED=$(run_query "SELECT COUNT(*) as count FROM dns_records WHERE updated_at IS NULL;" | tail -n 1)
    
    if [ "$NULL_CREATED" = "0" ]; then
        echo "   ✓ No NULL created_at values"
    else
        echo "   ⚠ Warning: $NULL_CREATED records have NULL created_at"
    fi
    
    if [ "$NULL_UPDATED" = "0" ]; then
        echo "   ✓ No NULL updated_at values"
    else
        echo "   ⚠ Warning: $NULL_UPDATED records have NULL updated_at"
    fi
fi

echo ""
echo "==================================================="
echo "Verification Complete!"
echo "==================================================="
echo ""
echo "Summary:"
echo "  - created_at column: ✓ Exists"
echo "  - updated_at column: ✓ Exists"
echo "  - Total records: $RECORD_COUNT"
echo ""
echo "If all checks passed, the database is ready for the UI changes."
