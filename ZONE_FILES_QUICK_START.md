# Zone Files Quick Start Guide

## Initial Setup

### 1. Run the Migration

```bash
mysql -u dns3_user -p dns3_db < migrations/006_create_zone_files_and_apps_and_add_zone_to_dns_records.sql
```

### 2. Create Your First Zone File

Using the Zone API (requires admin login):

```bash
# Create a master zone
curl -X POST "http://localhost/api/zone_api.php?action=create_zone" \
  -H "Content-Type: application/json" \
  -H "Cookie: PHPSESSID=your_session_id" \
  -d '{
    "name": "example.com",
    "filename": "db.example.com",
    "file_type": "master",
    "content": "$ORIGIN example.com.\n$TTL 3600\n@ IN SOA ns1.example.com. admin.example.com. (\n    2024010101 ; Serial\n    3600       ; Refresh\n    1800       ; Retry\n    604800     ; Expire\n    86400 )    ; Minimum TTL\n"
  }'
```

Or insert directly into the database (easier for initial setup):

```sql
INSERT INTO zone_files (name, filename, file_type, status, created_by, created_at) 
VALUES 
  ('example.com', 'db.example.com', 'master', 'active', 1, NOW()),
  ('internal.local', 'db.internal.local', 'master', 'active', 1, NOW()),
  ('common.include', 'common.include', 'include', 'active', 1, NOW());
```

### 3. Create an Application (Optional)

```bash
curl -X POST "http://localhost/api/app_api.php?action=create_app" \
  -H "Content-Type: application/json" \
  -H "Cookie: PHPSESSID=your_session_id" \
  -d '{
    "name": "WebApp1",
    "description": "Main web application",
    "owner": "web-team",
    "zone_file_id": 1
  }'
```

Or via SQL:

```sql
INSERT INTO applications (name, description, owner, zone_file_id, status, created_at)
VALUES ('WebApp1', 'Main web application', 'web-team', 1, 'active', NOW());
```

## Using the UI

### Creating a DNS Record

1. Navigate to **DNS Management** page
2. Click **"+ Créer un enregistrement"**
3. **First**, select a zone from the "Fichier de zone" dropdown
4. Fill in the other fields:
   - Name (e.g., `www.example.com`)
   - TTL (default: 3600)
   - Type (A, AAAA, CNAME, PTR, or TXT)
   - Value (IP address, hostname, or text depending on type)
5. Click **"Enregistrer"**

### Editing a DNS Record

1. Click **"Modifier"** on any record in the table
2. You can change the zone file by selecting a different value in the dropdown
3. Update other fields as needed
4. Click **"Enregistrer"**

### Viewing Zone Information

The DNS records table now shows the zone name in the first column for each record.

## Common Workflows

### Workflow 1: Add a New Website

```bash
# 1. Create zone file for the domain
curl -X POST ".../zone_api.php?action=create_zone" -d '{"name": "newsite.com", "filename": "db.newsite.com", "file_type": "master"}'

# 2. Create application for the website
curl -X POST ".../app_api.php?action=create_app" -d '{"name": "NewSite", "owner": "dev-team", "zone_file_id": 2}'

# 3. Add DNS records via UI
# - Select "newsite.com (master)" from zone dropdown
# - Add A record: www.newsite.com -> 192.168.1.100
# - Add CNAME: mail.newsite.com -> mail.provider.com
```

### Workflow 2: Migrate Existing Records to Zones

For existing DNS records without a zone:

```sql
-- Find records without zones
SELECT id, name, record_type FROM dns_records WHERE zone_file_id IS NULL;

-- Update them to use a zone (e.g., zone_file_id = 1)
UPDATE dns_records 
SET zone_file_id = 1 
WHERE name LIKE '%example.com%' AND zone_file_id IS NULL;
```

Or update via UI by editing each record and selecting a zone.

### Workflow 3: Create Include File for Common Records

```bash
# 1. Create an include zone
curl -X POST ".../zone_api.php?action=create_zone" \
  -d '{"name": "common-mx", "filename": "common-mx.include", "file_type": "include"}'

# 2. Assign it to master zones
curl -X POST ".../zone_api.php?action=assign_include&master_id=1&include_id=3"
curl -X POST ".../zone_api.php?action=assign_include&master_id=2&include_id=3"

# 3. Add DNS records to the include zone via UI
# Select "common-mx (include)" and add MX records
```

## Best Practices

### Zone Organization

1. **Master Zones**: One per domain or subdomain
   - example.com
   - internal.example.com
   - api.example.com

2. **Include Zones**: For common record sets
   - common-mx (shared MX records)
   - common-ns (shared nameservers)
   - monitoring-hosts (standard monitoring IPs)

### Naming Conventions

- **Zone names**: Use domain format (example.com, subdomain.example.com)
- **Filenames**: Use db.* for master, *.include for includes
- **Applications**: Descriptive names (WebApp, APIService, DatabaseCluster)

### Status Management

- **active**: Zone/app is in use
- **inactive**: Temporarily disabled, can be reactivated
- **deleted**: Soft-deleted, hidden from normal views

## Troubleshooting

### "Missing required field: zone_file_id"

**Problem**: Trying to create a DNS record without selecting a zone.

**Solution**: Select a zone from the "Fichier de zone" dropdown before submitting.

### "Invalid or inactive zone_file_id"

**Problem**: The selected zone doesn't exist or isn't active.

**Solutions**:
1. Check zone exists: `SELECT * FROM zone_files WHERE id = X;`
2. Check zone is active: `UPDATE zone_files SET status = 'active' WHERE id = X;`
3. Select a different zone from the dropdown

### Zone dropdown is empty

**Problem**: No active master or include zones available.

**Solutions**:
1. Create at least one zone (see "Create Your First Zone File" above)
2. Ensure zone has status='active'
3. Check browser console for API errors
4. Verify admin is logged in

### Can't change zone for existing record

**Problem**: Not seeing the zone dropdown or it's disabled.

**Solution**: The zone dropdown is always enabled in edit mode. Make sure you're using the latest version of the code and refresh your browser.

## API Reference Summary

### Zone Files
- `GET /api/zone_api.php?action=list_zones[&file_type=master][&status=active]`
- `GET /api/zone_api.php?action=get_zone&id=X`
- `POST /api/zone_api.php?action=create_zone` (admin)
- `POST /api/zone_api.php?action=update_zone&id=X` (admin)
- `POST /api/zone_api.php?action=assign_include&master_id=X&include_id=Y` (admin)
- `GET /api/zone_api.php?action=download_zone&id=X`

### Applications
- `GET /api/app_api.php?action=list_apps[&zone_file_id=X]`
- `GET /api/app_api.php?action=get_app&id=X`
- `POST /api/app_api.php?action=create_app` (admin)
- `POST /api/app_api.php?action=update_app&id=X` (admin)
- `POST /api/app_api.php?action=set_status_app&id=X&status=active` (admin)

### DNS Records (Enhanced)
- `POST /api/dns_api.php?action=create` - Now requires `zone_file_id`
- `GET /api/dns_api.php?action=list` - Now includes `zone_name`
- `POST /api/dns_api.php?action=update&id=X` - Can update `zone_file_id`

## Support

For issues or questions:
1. Check the ZONE_FILES_TESTING_GUIDE.md
2. Check the ZONE_FILES_IMPLEMENTATION_SUMMARY.md
3. Review API error messages in browser console
4. Check server error logs
