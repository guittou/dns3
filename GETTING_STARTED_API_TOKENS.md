# Getting Started with API Token Authentication

## Quick Start Guide

This guide will help you get started with the new API token authentication feature.

## Prerequisites

1. Run the database migration:
```sql
mysql -u root -p dns3_db < migrations/20251208_add_api_tokens_table.sql
```

## Creating Your First Token

### Option 1: Via Admin API (After Login)

1. Login to the web interface to get a session
2. Use the session to create a token:

```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=create_token' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: PHPSESSID=your-session-id' \
  -d '{
    "token_name": "My First Token",
    "expires_in_days": 365
  }'
```

Response will contain your token (save it!):
```json
{
  "success": true,
  "message": "Token créé avec succès...",
  "data": {
    "id": 1,
    "token": "a1b2c3d4e5f6...64-character-token...",
    "prefix": "a1b2c3d4"
  }
}
```

### Option 2: Direct Database Insert (For Initial Setup)

Create a simple PHP script:

```php
<?php
require_once 'config.php';
require_once 'includes/models/ApiToken.php';

// Find your user ID
$db = Database::getInstance()->getConnection();
$stmt = $db->prepare("SELECT id FROM users WHERE username = ?");
$stmt->execute(['your-username']);
$user = $stmt->fetch();

if ($user) {
    $apiToken = new ApiToken();
    $result = $apiToken->generate(
        $user['id'],        // user_id
        'My First Token',   // token_name
        $user['id'],        // created_by
        null                // no expiration
    );
    
    echo "Token created successfully!\n";
    echo "Token: " . $result['token'] . "\n";
    echo "Save this token - you won't see it again!\n";
} else {
    echo "User not found\n";
}
?>
```

Run it once:
```bash
php create_token.php
```

## Using Your Token

Now you can make API requests without session cookies:

```bash
# Set your token
export API_TOKEN="your-64-character-token"

# List zones
curl -X GET 'http://your-server/dns3/api/zone_api.php?action=list_zones' \
  -H "Authorization: Bearer $API_TOKEN"

# Get zone details
curl -X GET 'http://your-server/dns3/api/zone_api.php?action=get_zone&id=1' \
  -H "Authorization: Bearer $API_TOKEN"

# Create a DNS record
curl -X POST 'http://your-server/dns3/api/dns_api.php?action=create' \
  -H "Authorization: Bearer $API_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_file_id": 1,
    "name": "test",
    "record_type": "A",
    "address_ipv4": "192.0.2.1",
    "ttl": 3600
  }'
```

## Testing Your Setup

Use the provided test script:

```bash
export API_TOKEN="your-token"
export API_URL="http://your-server/dns3"
./test_api_token.sh
```

## Token Management

### List your tokens
```bash
curl -X GET 'http://your-server/dns3/api/admin_api.php?action=list_tokens' \
  -H "Authorization: Bearer $API_TOKEN"
```

### Revoke a token
```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=revoke_token&id=1' \
  -H "Authorization: Bearer $API_TOKEN"
```

### Delete a token
```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=delete_token&id=1' \
  -H "Authorization: Bearer $API_TOKEN"
```

## Using with Scripts

### Python Example

```python
import requests

API_URL = "http://your-server/dns3"
API_TOKEN = "your-token-here"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# List zones
response = requests.get(
    f"{API_URL}/api/zone_api.php?action=list_zones",
    headers=headers
)
zones = response.json()
print(zones)

# Create a DNS record
record_data = {
    "zone_file_id": 1,
    "name": "api-test",
    "record_type": "A",
    "address_ipv4": "192.0.2.100",
    "ttl": 3600
}

response = requests.post(
    f"{API_URL}/api/dns_api.php?action=create",
    headers=headers,
    json=record_data
)
result = response.json()
print(result)
```

### Bash Script Example

```bash
#!/bin/bash

API_URL="http://your-server/dns3"
API_TOKEN="your-token-here"

# List zones
curl -X GET "${API_URL}/api/zone_api.php?action=list_zones" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -s | jq '.data[] | {id, name, file_type}'

# Create a zone
curl -X POST "${API_URL}/api/zone_api.php?action=create_zone" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "example.com",
    "filename": "example.com.zone",
    "file_type": "master"
  }'
```

## Security Tips

1. **Store tokens securely**: Use environment variables or secure vaults
2. **Never commit tokens**: Add to `.gitignore` if stored in files
3. **Use HTTPS**: Always use HTTPS in production
4. **Set expiration**: Use `expires_in_days` for limited lifetime tokens
5. **Regular rotation**: Create new tokens and revoke old ones periodically
6. **Monitor usage**: Check `last_used_at` timestamps regularly

## Troubleshooting

### Token not working?
- Check that migration was run successfully
- Verify token is correct (64 hex characters)
- Ensure user account is active
- Check token hasn't expired or been revoked

### Permission denied?
- Verify user has appropriate roles (admin for write operations)
- Check zone ACL permissions for non-admin users

### Getting 401 errors?
- Ensure `Authorization` header is properly formatted
- Check for typos in token
- Verify token exists in database

## More Information

See the full documentation in `docs/api_token_authentication.md` for:
- Detailed API endpoint documentation
- Complete examples for all operations
- Security best practices
- Advanced usage patterns
