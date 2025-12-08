# API Token Authentication

This document describes how to use API tokens for authentication with the dns3 API endpoints.

## Overview

The dns3 application supports two authentication methods:

1. **Session-based authentication** (default): Uses PHP session cookies, suitable for browser-based clients
2. **Bearer token authentication** (new): Uses API tokens in the `Authorization` header, suitable for automated scripts and non-browser clients

API token authentication is completely optional and works alongside the existing session-based authentication without breaking backward compatibility.

## Features

- **Secure**: Tokens are hashed with SHA-256 before storage
- **Long-lived**: Tokens can be set to never expire or have a custom expiration
- **Revocable**: Tokens can be revoked without affecting other tokens
- **User-scoped**: Each token is associated with a user and inherits their permissions
- **Trackable**: Last usage timestamp is recorded for each token

## Creating API Tokens

### Via Admin API (Recommended)

1. First, authenticate with session cookies (login via web interface)

2. Create a token:
```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=create_token' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: PHPSESSID=your-session-id' \
  -d '{
    "token_name": "My Automation Token",
    "expires_in_days": 365
  }'
```

Response:
```json
{
  "success": true,
  "message": "Token créé avec succès. Conservez-le en lieu sûr, il ne sera plus visible.",
  "data": {
    "id": 1,
    "token": "a1b2c3d4e5f6...64-character-hex-string...",
    "prefix": "a1b2c3d4"
  }
}
```

**IMPORTANT**: Save the token immediately! It will never be displayed again.

### Via Direct Database Access

Alternatively, for initial setup, you can create a token directly:

```php
<?php
require_once 'includes/models/ApiToken.php';
$apiToken = new ApiToken();

$result = $apiToken->generate(
    $userId,           // User ID from users table
    'My Token',        // Human-readable name
    $createdBy,        // User ID who created it
    365                // Expires in 365 days (or null for no expiration)
);

echo "Token: " . $result['token'] . "\n";
echo "ID: " . $result['id'] . "\n";
?>
```

## Using API Tokens

Once you have a token, include it in the `Authorization` header with the `Bearer` scheme:

```bash
curl -X GET 'http://your-server/dns3/api/zone_api.php?action=list_zones' \
  -H 'Authorization: Bearer a1b2c3d4e5f6...your-token...'
```

### Examples

#### List zones
```bash
curl -X GET 'http://your-server/dns3/api/zone_api.php?action=list_zones' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

#### Get a specific zone
```bash
curl -X GET 'http://your-server/dns3/api/zone_api.php?action=get_zone&id=1' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

#### Create a zone (admin only)
```bash
curl -X POST 'http://your-server/dns3/api/zone_api.php?action=create_zone' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "example.com",
    "filename": "example.com.zone",
    "file_type": "master"
  }'
```

#### List DNS records
```bash
curl -X GET 'http://your-server/dns3/api/dns_api.php?action=list' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

#### Create a DNS record
```bash
curl -X POST 'http://your-server/dns3/api/dns_api.php?action=create' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "zone_file_id": 1,
    "name": "www",
    "record_type": "A",
    "address_ipv4": "192.0.2.1",
    "ttl": 3600
  }'
```

## Managing Tokens

### List your tokens
```bash
curl -X GET 'http://your-server/dns3/api/admin_api.php?action=list_tokens' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

### List tokens for a specific user (admin only)
```bash
curl -X GET 'http://your-server/dns3/api/admin_api.php?action=list_tokens&user_id=2' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

### Revoke a token
```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=revoke_token&id=1' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

### Delete a token permanently
```bash
curl -X POST 'http://your-server/dns3/api/admin_api.php?action=delete_token&id=1' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

## Security Best Practices

1. **Treat tokens like passwords**: Never commit them to version control or share them in plain text
2. **Use environment variables**: Store tokens in environment variables, not in code
3. **Set expiration dates**: Use `expires_in_days` parameter to limit token lifetime
4. **Revoke unused tokens**: Regularly audit and revoke tokens that are no longer needed
5. **Use HTTPS**: Always use HTTPS in production to protect tokens in transit
6. **Limit token scope**: Create separate tokens for different applications/purposes
7. **Rotate tokens**: Periodically generate new tokens and revoke old ones

## Token Storage

Tokens are stored in the `api_tokens` table with the following information:

- `token_hash`: SHA-256 hash of the token (never the plain token)
- `token_prefix`: First 8 characters for identification
- `user_id`: Associated user ID
- `token_name`: Human-readable name
- `last_used_at`: Last usage timestamp (updated on each successful authentication)
- `expires_at`: Expiration date (NULL = no expiration)
- `revoked_at`: Revocation timestamp (NULL = active)

## Troubleshooting

### "Authentication required" error
- Verify the token is correct and not expired
- Check that the `Authorization` header is properly formatted: `Authorization: Bearer YOUR_TOKEN`
- Ensure the user account associated with the token is active

### "Admin privileges required" error
- The endpoint requires admin privileges
- Verify the user associated with the token has the `admin` role

### Token not working after creation
- Ensure you're using the full 64-character token from the creation response
- Check that the token hasn't been revoked
- Verify the token hasn't expired

## Migration

To enable API token authentication in an existing installation:

1. Run the database migration:
```bash
mysql -u root -p dns3_db < migrations/20251208_add_api_tokens_table.sql
```

2. No code changes required - the feature is automatically available

3. Create your first token using the Admin API or direct database access

## Compatibility

- API token authentication is fully compatible with existing session-based authentication
- Existing scripts using session cookies will continue to work without modification
- The API checks for Bearer tokens first, then falls back to session authentication
- No breaking changes to existing API endpoints
