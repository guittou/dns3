#!/bin/bash
# Final sanity check for zone preview modal fixes

echo "═══════════════════════════════════════════════════════"
echo "Zone Preview Modal Fix - Sanity Check"
echo "═══════════════════════════════════════════════════════"
echo ""

EXIT_CODE=0

# 1. Check PHP syntax
echo "1. Checking PHP syntax..."
php -l includes/header.php > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ includes/header.php syntax OK"
else
    echo "   ✗ includes/header.php has syntax errors"
    EXIT_CODE=1
fi

php -l zone-files.php > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ zone-files.php syntax OK"
else
    echo "   ✗ zone-files.php has syntax errors"
    EXIT_CODE=1
fi

# 2. Check JavaScript syntax
echo ""
echo "2. Checking JavaScript syntax..."
if command -v node &> /dev/null; then
    node --check assets/js/zone-files.js 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ assets/js/zone-files.js syntax OK"
    else
        echo "   ✗ assets/js/zone-files.js has syntax errors"
        EXIT_CODE=1
    fi
else
    echo "   ⚠ Node.js not available, skipping JS syntax check"
fi

# 3. Check for required elements
echo ""
echo "3. Checking required HTML elements..."

if grep -q 'id="btnGenerateZoneFile"' zone-files.php; then
    echo "   ✓ Button ID 'btnGenerateZoneFile' found"
else
    echo "   ✗ Button ID 'btnGenerateZoneFile' missing"
    EXIT_CODE=1
fi

if grep -q 'data-action="generate-zone"' zone-files.php; then
    echo "   ✓ Button data-action attribute found"
else
    echo "   ✗ Button data-action attribute missing"
    EXIT_CODE=1
fi

if grep -q 'id="zonePreviewModal"' zone-files.php; then
    echo "   ✓ Preview modal found"
else
    echo "   ✗ Preview modal missing"
    EXIT_CODE=1
fi

if grep -q 'id="zoneGeneratedPreview"' zone-files.php; then
    echo "   ✓ Preview textarea found"
else
    echo "   ✗ Preview textarea missing"
    EXIT_CODE=1
fi

if grep -q 'id="downloadZoneFile"' zone-files.php; then
    echo "   ✓ Download button found"
else
    echo "   ✗ Download button missing"
    EXIT_CODE=1
fi

# 4. Check JavaScript functions
echo ""
echo "4. Checking JavaScript functions..."

if grep -q 'function generateZoneFileContent' assets/js/zone-files.js; then
    echo "   ✓ generateZoneFileContent() function exists"
else
    echo "   ✗ generateZoneFileContent() function missing"
    EXIT_CODE=1
fi

if grep -q 'function openZonePreviewModal' assets/js/zone-files.js; then
    echo "   ✓ openZonePreviewModal() function exists"
else
    echo "   ✗ openZonePreviewModal() function missing"
    EXIT_CODE=1
fi

if grep -q 'function closeZonePreviewModal' assets/js/zone-files.js; then
    echo "   ✓ closeZonePreviewModal() function exists"
else
    echo "   ✗ closeZonePreviewModal() function missing"
    EXIT_CODE=1
fi

if grep -q 'function downloadZoneFileFromPreview' assets/js/zone-files.js; then
    echo "   ✓ downloadZoneFileFromPreview() function exists"
else
    echo "   ✗ downloadZoneFileFromPreview() function missing"
    EXIT_CODE=1
fi

# 5. Check delegated event handler
echo ""
echo "5. Checking delegated event handler..."

if grep -q "document.addEventListener('click'" assets/js/zone-files.js; then
    echo "   ✓ Delegated click event listener found"
else
    echo "   ✗ Delegated click event listener missing"
    EXIT_CODE=1
fi

if grep -q "closest('#btnGenerateZoneFile" assets/js/zone-files.js; then
    echo "   ✓ Delegated handler targets correct button"
else
    echo "   ✗ Delegated handler doesn't target button correctly"
    EXIT_CODE=1
fi

# 6. Check basePath implementation
echo ""
echo "6. Checking basePath implementation..."

if grep -q '$basePath' includes/header.php; then
    echo "   ✓ \$basePath variable used in header.php"
else
    echo "   ✗ \$basePath variable not used in header.php"
    EXIT_CODE=1
fi

if grep -q '$basePath' zone-files.php; then
    echo "   ✓ \$basePath variable used in zone-files.php"
else
    echo "   ✗ \$basePath variable not used in zone-files.php"
    EXIT_CODE=1
fi

if grep -q "if (empty(\$basePath))" includes/header.php; then
    echo "   ✓ basePath fallback logic found"
else
    echo "   ✗ basePath fallback logic missing"
    EXIT_CODE=1
fi

# 7. Check CSS
echo ""
echo "7. Checking CSS..."

if grep -q "\.modal\.preview-modal" assets/css/zone-files.css; then
    echo "   ✓ Preview modal CSS class found"
else
    echo "   ✗ Preview modal CSS class missing"
    EXIT_CODE=1
fi

if grep -q "z-index: 9999" assets/css/zone-files.css; then
    echo "   ✓ High z-index for preview modal found"
else
    echo "   ✗ High z-index for preview modal missing"
    EXIT_CODE=1
fi

if grep -q "\.modal\.open" assets/css/zone-files.css; then
    echo "   ✓ Modal open class CSS found"
else
    echo "   ✗ Modal open class CSS missing"
    EXIT_CODE=1
fi

# 8. Check credentials in fetch
echo ""
echo "8. Checking fetch credentials..."

if grep -q "credentials: 'same-origin'" assets/js/zone-files.js; then
    echo "   ✓ Fetch uses credentials: 'same-origin'"
else
    echo "   ✗ Fetch missing credentials: 'same-origin'"
    EXIT_CODE=1
fi

# 9. Check for CodeMirror removal
echo ""
echo "9. Checking CodeMirror removal..."

CODEMIRROR_COUNT=$(grep -ri "codemirror" --include="*.php" --include="*.js" --include="*.html" . 2>/dev/null | grep -v "no CodeMirror" | grep -v ".git" | wc -l)
if [ $CODEMIRROR_COUNT -eq 0 ]; then
    echo "   ✓ No CodeMirror references found (except comments)"
else
    echo "   ✗ CodeMirror references still exist"
    EXIT_CODE=1
fi

# 10. Check error handling
echo ""
echo "10. Checking error handling..."

if grep -q "console.log.*generateZoneFileContent" assets/js/zone-files.js; then
    echo "   ✓ Console logging added for debugging"
else
    echo "   ✗ Console logging missing"
    EXIT_CODE=1
fi

if grep -q "textarea.value = errorMessage" assets/js/zone-files.js; then
    echo "   ✓ Error messages displayed in textarea"
else
    echo "   ✗ Error display in textarea missing"
    EXIT_CODE=1
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All sanity checks passed!"
    echo ""
    echo "Implementation is complete and ready for manual testing."
else
    echo "✗ Some checks failed. Please review the errors above."
fi
echo "═══════════════════════════════════════════════════════"
echo ""

exit $EXIT_CODE
