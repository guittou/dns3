# Testing Guide for Zone Files Management

## Migration Testing

> **Note**: The migration has been archived to `migrations/archive/`. On production systems, this migration has already been applied. The following instructions are for setting up a new development/test environment.

To set up the database schema for testing:

1. Run the archived migration script (if not already applied):
```bash
mysql -u dns3_user -p dns3_db < migrations/archive/006_create_zone_files_and_apps_and_add_zone_to_dns_records.sql
```

2. Verify tables were created:
```sql
USE dns3_db;
SHOW TABLES LIKE 'zone%';
DESCRIBE zone_files;
DESCRIBE zone_file_includes;
DESCRIBE zone_file_history;
SHOW COLUMNS FROM dns_records LIKE 'zone_file_id';
```

## API Testing

### Zone File API

1. **List zones** (requires authentication):
```bash
curl -X GET "http://localhost/api/zone_api.php?action=list_zones" -H "Cookie: session_id=..."
```

2. **Create a zone** (requires admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=create_zone" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "name": "example.com",
    "filename": "db.example.com",
    "file_type": "master",
    "content": "; Zone file for example.com\n"
  }'
```

3. **Get a specific zone**:
```bash
curl -X GET "http://localhost/api/zone_api.php?action=get_zone&id=1" -H "Cookie: session_id=..."
```

4. **Update a zone** (requires admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=update_zone&id=1" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "content": "; Updated zone file content\n"
  }'
```

5. **Assign an include to a master zone** (requires admin):
```bash
curl -X POST "http://localhost/api/zone_api.php?action=assign_include&master_id=1&include_id=2" \
  -H "Cookie: session_id=..."
```

6. **Download zone file**:
```bash
curl -X GET "http://localhost/api/zone_api.php?action=download_zone&id=1" -H "Cookie: session_id=..." -o zone_file.txt
```

### DNS Records API (with zone_file_id)

1. **Create a DNS record** (now requires zone_file_id):
```bash
curl -X POST "http://localhost/api/dns_api.php?action=create" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "zone_file_id": 1,
    "record_type": "A",
    "name": "test.example.com",
    "address_ipv4": "192.168.1.100",
    "ttl": 3600
  }'
```

2. **List DNS records** (now includes zone_name):
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list" -H "Cookie: session_id=..."
```

3. **Update DNS record** (can change zone_file_id):
```bash
curl -X POST "http://localhost/api/dns_api.php?action=update&id=1" \
  -H "Content-Type: application/json" \
  -H "Cookie: session_id=..." \
  -d '{
    "zone_file_id": 2,
    "address_ipv4": "192.168.1.101"
  }'
```

## UI Testing

1. Open the DNS Management page: `http://localhost/dns-management.php`

2. Click "Créer un enregistrement" to open the create modal

3. Verify that:
   - The "Fichier de zone" dropdown is present as the first field
   - The dropdown loads zone files with type "master" or "include"
   - When you select a zone and fill in the form, the record is created with the zone_file_id

4. In the DNS records table, verify that:
   - The "Zone" column appears as the first column
   - Each record shows its associated zone name
   - When editing a record, the zone selector shows the current zone selected
   - You can change the zone when editing a record

## Expected Behavior

### Creating a DNS Record
- **Before**: Could create a record without selecting a zone
- **After**: Must select a zone file (zone_file_id is required)
- **Error if no zone selected**: "Missing required field: zone_file_id"

### Listing DNS Records
- **Before**: Records showed only DNS data
- **After**: Records include zone_name field showing the associated zone

### Editing a DNS Record
- **Before**: Could not change the zone
- **After**: Can update the zone_file_id to move a record to a different zone

### Zone Selector
- **Shows**: Only zone files with status='active' and file_type in ('master', 'include')
- **Format**: "zone_name (file_type)" - e.g., "example.com (master)"

## Migration Notes

- The `zone_file_id` column in `dns_records` is nullable for migration purposes
- Existing records without a zone_file_id can continue to exist
- New records MUST have a zone_file_id (enforced by API validation)
- The foreign key constraint is commented out in the migration but can be enabled if desired

## Troubleshooting

### Error: "Invalid or inactive zone_file_id"
- Ensure the zone file exists and has status='active'
- Verify the zone_file_id is correct

### Error: "zone_file_id is required"
- This is expected when trying to create a DNS record without selecting a zone
- Select a zone from the dropdown in the UI

### Zone dropdown is empty
- Check that zone files exist in the database with status='active'
- Verify that at least one zone has file_type='master' or 'include'
- Check browser console for API errors

### DNS records don't show zone names
- Verify the migration added zone_file_id column to dns_records
- Check that records have zone_file_id values
- Verify the LEFT JOIN in search() and getById() methods
