# DNS Management Feature - Installation and Testing Guide

This document provides instructions for installing and testing the DNS management feature that has been added to the DNS3 application.

## Overview

The DNS management feature provides:
- Complete CRUD operations for DNS records
- Automatic history tracking for all changes
- Access Control Lists (ACLs) with history
- Role-based access control (Admin/User)
- REST API for DNS record management
- Modern UI for managing DNS records

## Installation

### 1. Initialize Database Schema

For new installations, import the complete schema:

```bash
mysql -u dns3_user -p dns3_db < database.sql
```

> **Note** : Les fichiers de migration ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

This will create the following tables:
- `roles` - User roles (admin, user)
- `user_roles` - User-role assignments
- `dns_records` - DNS record storage
- `dns_record_history` - DNS record change history
- `acl_entries` - Access control entries
- `acl_history` - ACL change history

### 2. Verify Admin User

The migration automatically assigns the admin role to the default admin user (ID=1). 

To verify, log in with:
- **Username**: `admin`
- **Password**: `admin123`

**Important**: Change the default password immediately after first login!

### 3. Configure Application

No additional configuration is needed. The feature uses the existing database connection from `config.php`.

## Testing the API

### Prerequisites
- User must be logged in (all endpoints require authentication)
- Admin privileges required for create, update, and set_status operations

### 1. List DNS Records

```bash
# As authenticated user
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=list'

# With filters
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=list&name=example&type=A&status=active'
```

Expected response:
```json
{
  "success": true,
  "data": [],
  "count": 0
}
```

### 2. Create DNS Record (Admin Only)

```bash
# Save session first
curl -c cookies.txt -X POST http://localhost:8000/login.php \
  -d "username=admin&password=admin123&auth_method=database"

# Create A record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "A",
    "name": "example.com",
    "address_ipv4": "192.168.1.1",
    "ttl": 3600
  }'

# Or using value alias for backward compatibility
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "A",
    "name": "example.com",
    "value": "192.168.1.1",
    "ttl": 3600
  }'

# Create CNAME record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "CNAME",
    "name": "www.example.com",
    "cname_target": "example.com",
    "ttl": 3600
  }'

# Create TXT record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{
    "record_type": "TXT",
    "name": "example.com",
    "txt": "v=spf1 include:_spf.example.com ~all",
    "ttl": 3600
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "DNS record created successfully",
  "id": 1
}
```

### 3. Get Specific Record

```bash
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=get&id=1'
```

Expected response includes record data and history:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "record_type": "A",
    "name": "example.com",
    "value": "192.168.1.1",
    "ttl": "3600",
    "status": "active",
    ...
  },
  "history": [...]
}
```

### 4. Update DNS Record (Admin Only)

```bash
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=update&id=1' \
  -H 'Content-Type: application/json' \
  -d '{
    "address_ipv4": "192.168.1.2",
    "ttl": 7200
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "DNS record updated successfully"
}
```

### 5. Change Record Status (Admin Only)

```bash
# Soft delete a record
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=set_status&id=1&status=deleted'

# Restore a deleted record
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=set_status&id=1&status=active'
```

Expected response:
```json
{
  "success": true,
  "message": "DNS record status changed to deleted"
}
```

## Testing the UI

### 1. Access DNS Management Page

1. Navigate to `http://localhost:8000/login.php`
2. Log in as admin (username: `admin`, password: `admin123`)
3. Click on the "DNS" tab in the navigation menu
4. You should see the DNS management interface

### 2. UI Features to Test

#### Create Record
1. Click the "+ Créer un enregistrement" button
2. Fill in the form:
   - Type: Select record type (A, AAAA, CNAME, etc.)
   - Nom: Enter domain name (e.g., "test.example.com")
   - Valeur: Enter value (e.g., "192.168.1.10")
   - TTL: Enter TTL in seconds (default: 3600)
   - Priorité: Optional for MX/SRV records
3. Click "Enregistrer"
4. Verify the record appears in the table

#### Search and Filter
1. Use the search box to filter by name
2. Use the type dropdown to filter by record type
3. Use the status dropdown to filter by status
4. Verify the table updates in real-time

#### Edit Record
1. Click "Modifier" button on any record
2. Update the fields
3. Click "Enregistrer"
4. Verify changes are reflected in the table

#### Change Status
1. Click "Supprimer" to soft-delete a record
2. Verify the status badge changes to "deleted"
3. Use the status filter to show deleted records
4. Click "Restaurer" to restore the record
5. Verify the status badge changes back to "active"

#### Delete Record
1. Click "Supprimer" button
2. Confirm the deletion
3. Verify the record is soft-deleted (status = deleted)

## Verify History Tracking

All changes are automatically tracked in the history tables. To verify:

```sql
-- View DNS record history
SELECT * FROM dns_record_history ORDER BY changed_at DESC;

-- View ACL history (if ACLs have been created)
SELECT * FROM acl_history ORDER BY changed_at DESC;
```

## Security Notes

1. **Authentication Required**: All API endpoints require user authentication
2. **Admin Privileges**: Create, update, and status change operations require admin role
3. **No Physical Deletion**: Records are never physically deleted, only soft-deleted (status = 'deleted')
4. **Audit Trail**: All changes are recorded in history tables with user and timestamp
5. **Input Validation**: API validates all inputs before processing
6. **Server-Managed Fields**: The `last_seen` field is managed exclusively by the server and cannot be set by clients. Any attempt to set it via the API will be silently ignored.
7. **Type Restrictions**: Only A, AAAA, CNAME, PTR, and TXT record types are supported. Attempts to create other types will return a 400 error.

## Troubleshooting

### "Authentication required" error
- Ensure you're logged in before making API calls
- Check that session cookies are being sent with requests

### "Admin privileges required" error
- Verify the user has the admin role assigned
- Check `user_roles` table for role assignment

### "Table doesn't exist" error
- Ensure the migration SQL has been applied
- Verify database connection settings in `config.php`

### UI not loading records
- Check browser console for JavaScript errors
- Verify API endpoint is accessible
- Check network tab for failed requests

## Database Schema

### Tables Created

1. **roles**: User roles (admin, user)
2. **user_roles**: Junction table for user-role assignments
3. **dns_records**: Main DNS records table
4. **dns_record_history**: Audit trail for DNS records
5. **acl_entries**: Access control entries
6. **acl_history**: Audit trail for ACL changes

### Default Data

- Two roles: `admin` and `user`
- Admin role automatically assigned to user ID 1 (default admin user)

## API Reference

### Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/dns_api.php?action=list` | User | List DNS records |
| GET | `/api/dns_api.php?action=get&id=X` | User | Get specific record |
| POST | `/api/dns_api.php?action=create` | Admin | Create new record |
| POST | `/api/dns_api.php?action=update&id=X` | Admin | Update record |
| GET | `/api/dns_api.php?action=set_status&id=X&status=Y` | Admin | Change status |

### Record Types

The DNS management system supports the following record types:

- **A** - IPv4 address (uses `address_ipv4` field)
- **AAAA** - IPv6 address (uses `address_ipv6` field)
- **CNAME** - Canonical name (uses `cname_target` field)
- **PTR** - Pointer/Reverse DNS (uses `ptrdname` field, requires reverse DNS name)
- **TXT** - Text record (uses `txt` field)

**Note**: Other record types (MX, NS, SOA, SRV) are not supported in this version.

### Dedicated Fields

Each record type now uses a dedicated field instead of the generic `value` field:

- **A records**: `address_ipv4` - IPv4 address (e.g., "192.168.1.1")
- **AAAA records**: `address_ipv6` - IPv6 address (e.g., "2001:0db8:85a3:0000:0000:8a2e:0370:7334")
- **CNAME records**: `cname_target` - Target hostname (e.g., "target.example.com")
- **PTR records**: `ptrdname` - Reverse DNS name (e.g., "1.1.168.192.in-addr.arpa")
- **TXT records**: `txt` - Text content (any text)

For backward compatibility, the API continues to accept `value` as an alias for the dedicated field.
The `value` field in database is kept temporarily for rollback capability.

### Status Values

- `active` - Record is active and in use
- `deleted` - Record is soft-deleted (shown only when filtering by deleted status)

## Next Steps

1. Test all API endpoints with different user roles
2. Verify history tracking for all operations
3. Test UI responsiveness on mobile devices
4. Configure ACLs for fine-grained access control
5. Consider implementing bulk operations
6. Add export/import functionality for DNS records

## Support

For issues or questions, please open an issue on the GitHub repository.
