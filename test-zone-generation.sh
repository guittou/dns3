#!/bin/bash
# Test script for zone file generation feature
# This script performs basic validation checks

echo "=== Zone File Generation Feature - Validation Tests ==="
echo ""

# Check if migration file exists
echo "1. Checking migration file..."
if [ -f "migrations/010_add_directory_to_zone_files.sql" ]; then
    echo "   ✓ Migration file exists"
else
    echo "   ✗ Migration file missing"
    exit 1
fi

# Check PHP syntax
echo ""
echo "2. Checking PHP syntax..."
php -l includes/models/ZoneFile.php > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ ZoneFile.php syntax OK"
else
    echo "   ✗ ZoneFile.php has syntax errors"
    exit 1
fi

php -l api/zone_api.php > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ zone_api.php syntax OK"
else
    echo "   ✗ zone_api.php has syntax errors"
    exit 1
fi

# Check for required methods in ZoneFile.php
echo ""
echo "3. Checking required methods in ZoneFile.php..."
if grep -q "generateZoneFile" includes/models/ZoneFile.php; then
    echo "   ✓ generateZoneFile() method exists"
else
    echo "   ✗ generateZoneFile() method missing"
    exit 1
fi

if grep -q "getDnsRecordsByZone" includes/models/ZoneFile.php; then
    echo "   ✓ getDnsRecordsByZone() method exists"
else
    echo "   ✗ getDnsRecordsByZone() method missing"
    exit 1
fi

if grep -q "formatDnsRecordBind" includes/models/ZoneFile.php; then
    echo "   ✓ formatDnsRecordBind() method exists"
else
    echo "   ✗ formatDnsRecordBind() method missing"
    exit 1
fi

# Check for API endpoint
echo ""
echo "4. Checking API endpoint..."
if grep -q "generate_zone_file" api/zone_api.php; then
    echo "   ✓ generate_zone_file API endpoint exists"
else
    echo "   ✗ generate_zone_file API endpoint missing"
    exit 1
fi

# Check UI changes
echo ""
echo "5. Checking UI changes..."
if grep -q "zoneDirectory" zone-files.php; then
    echo "   ✓ Directory field exists in UI"
else
    echo "   ✗ Directory field missing in UI"
    exit 1
fi

if ! grep -q "# Includes" zone-files.php; then
    echo "   ✓ '# Includes' column removed from table"
else
    echo "   ✗ '# Includes' column still present in table"
    exit 1
fi

if grep -q "Générer le fichier de zone" zone-files.php; then
    echo "   ✓ Generate button exists in UI"
else
    echo "   ✗ Generate button missing in UI"
    exit 1
fi

# Check JavaScript changes
echo ""
echo "6. Checking JavaScript changes..."
if grep -q "generateZoneFileContent" assets/js/zone-files.js; then
    echo "   ✓ generateZoneFileContent() function exists"
else
    echo "   ✗ generateZoneFileContent() function missing"
    exit 1
fi

if grep -q "zoneDirectory" assets/js/zone-files.js; then
    echo "   ✓ Directory field handling in JavaScript"
else
    echo "   ✗ Directory field handling missing in JavaScript"
    exit 1
fi

# Check that includes_count is removed from table rendering
echo ""
echo "7. Checking table rendering..."
if ! grep "includes_count" assets/js/zone-files.js | grep -q "td"; then
    echo "   ✓ includes_count removed from table display"
else
    echo "   ✗ includes_count still in table display"
fi

echo ""
echo "=== All validation tests passed! ==="
echo ""
echo "Next steps:"
echo "1. Run the migration: mysql -u dns3_user -p dns3_db < migrations/010_add_directory_to_zone_files.sql"
echo "2. Test the UI manually:"
echo "   - Open a zone and verify the directory field appears in the modal"
echo "   - Verify the '# Includes' column is not shown in the table"
echo "   - Click 'Générer le fichier de zone' to test generation"
echo "3. Verify generated zone files contain:"
echo "   - Zone content"
echo "   - \$INCLUDE directives"
echo "   - DNS records in BIND format"
