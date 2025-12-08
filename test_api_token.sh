#!/bin/bash
# Script to test API token authentication manually
# This script demonstrates how to use Bearer tokens with the API

API_URL="${API_URL:-http://localhost/dns3}"
TOKEN="${API_TOKEN:-}"

echo "=== API Token Authentication Test ==="
echo ""

if [ -z "$TOKEN" ]; then
    echo "ERROR: No API token provided."
    echo "Usage: API_TOKEN=<your-token> ./test_api_token.sh"
    echo ""
    echo "To generate a token:"
    echo "1. Login to the admin interface"
    echo "2. Navigate to Admin API"
    echo "3. Call: curl -X POST '$API_URL/api/admin_api.php?action=create_token' \\"
    echo "         -H 'Content-Type: application/json' \\"
    echo "         -H 'Cookie: PHPSESSID=<your-session-id>' \\"
    echo "         -d '{\"token_name\":\"Test Token\"}'"
    echo ""
    exit 1
fi

echo "Testing API token authentication..."
echo "API URL: $API_URL"
echo "Token prefix: ${TOKEN:0:8}..."
echo ""

# Test 1: List zones with Bearer token
echo "Test 1: List zones (GET /api/zone_api.php?action=list_zones)"
echo "Request:"
echo "  curl -s -X GET '$API_URL/api/zone_api.php?action=list_zones' \\"
echo "       -H 'Authorization: Bearer <token>'"
echo ""
echo "Response:"
curl -s -X GET "$API_URL/api/zone_api.php?action=list_zones" \
    -H "Authorization: Bearer $TOKEN" | jq '.' 2>/dev/null || echo "Response parsing failed"
echo ""
echo "---"
echo ""

# Test 2: Get zone permission
echo "Test 2: Get zone permission (GET /api/zone_api.php?action=get_zone_permission&zone_file_id=1)"
echo "Request:"
echo "  curl -s -X GET '$API_URL/api/zone_api.php?action=get_zone_permission&zone_file_id=1' \\"
echo "       -H 'Authorization: Bearer <token>'"
echo ""
echo "Response:"
curl -s -X GET "$API_URL/api/zone_api.php?action=get_zone_permission&zone_file_id=1" \
    -H "Authorization: Bearer $TOKEN" | jq '.' 2>/dev/null || echo "Response parsing failed"
echo ""
echo "---"
echo ""

# Test 3: List DNS records
echo "Test 3: List DNS records (GET /api/dns_api.php?action=list)"
echo "Request:"
echo "  curl -s -X GET '$API_URL/api/dns_api.php?action=list' \\"
echo "       -H 'Authorization: Bearer <token>'"
echo ""
echo "Response:"
curl -s -X GET "$API_URL/api/dns_api.php?action=list" \
    -H "Authorization: Bearer $TOKEN" | jq '.' 2>/dev/null || echo "Response parsing failed"
echo ""
echo "---"
echo ""

# Test 4: List API tokens (admin endpoint)
echo "Test 4: List API tokens (GET /api/admin_api.php?action=list_tokens)"
echo "Request:"
echo "  curl -s -X GET '$API_URL/api/admin_api.php?action=list_tokens' \\"
echo "       -H 'Authorization: Bearer <token>'"
echo ""
echo "Response:"
curl -s -X GET "$API_URL/api/admin_api.php?action=list_tokens" \
    -H "Authorization: Bearer $TOKEN" | jq '.' 2>/dev/null || echo "Response parsing failed"
echo ""
echo "---"
echo ""

echo "=== Test Complete ==="
