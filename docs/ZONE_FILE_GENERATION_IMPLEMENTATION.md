# Zone File Generation Implementation

## Overview
This implementation adds zone file generation capability with support for:
- Directory field for zone files (exposed in modal/popup only)
- Generation of complete zone files with $INCLUDE directives
- DNS records formatted in BIND syntax
- Removed "# Includes" column from the zone list table

## Changes Made

### 1. Database Migration
**File**: `migrations/010_add_directory_to_zone_files.sql`

- Added `directory` VARCHAR(255) NULL column to `zone_files` table
- Added index on `directory` for performance
- Idempotent migration that can be safely re-run

To apply:
```sql
mysql -u dns3_user -p dns3_db < migrations/010_add_directory_to_zone_files.sql
```

### 2. Backend Model Changes
**File**: `includes/models/ZoneFile.php`

#### Modified Methods:
- `create()`: Now accepts and stores `directory` field
- `update()`: Now accepts and updates `directory` field
- `getById()`: Ensures `directory` is included in results

#### New Methods:
- `generateZoneFile($zoneId)`: Generates complete zone file content with:
  - Zone's own content (from `zone_files.content`)
  - $INCLUDE directives for direct includes
  - DNS records formatted in BIND syntax
  
- `getDnsRecordsByZone($zoneId)`: Retrieves all active DNS records for a zone
  
- `formatDnsRecordBind($record)`: Formats a DNS record in BIND zone file syntax
  
- `getRecordValue($record)`: Extracts the correct value for each record type

#### $INCLUDE Directive Logic:
```
If directory is set:
  $INCLUDE "directory/filename"
  
If directory is NULL:
  $INCLUDE "filename"  (or "name" if filename is empty)
```

### 3. API Changes
**File**: `api/zone_api.php`

#### New Endpoint:
```
GET /api/zone_api.php?action=generate_zone_file&id={zone_id}
```

**Response**:
```json
{
  "success": true,
  "content": "... generated zone file content ...",
  "filename": "example.com.zone"
}
```

### 4. Frontend UI Changes
**File**: `zone-files.php`

#### Table View Changes:
- Removed "# Includes" column from the zone list table
- Updated colspan from 8 to 7 in loading/error states

#### Modal Changes:
- Added "Répertoire" (Directory) field in the Details tab:
  ```html
  <input type="text" id="zoneDirectory" class="form-control" placeholder="Exemple: /etc/bind/zones">
  ```
- Added "Générer le fichier de zone" button in the Editor tab
- Directory field is only visible in the edit modal, NOT in the table list view

### 5. Frontend JavaScript Changes
**File**: `assets/js/zone-files.js`

#### Modified Functions:
- `renderZonesTable()`: Removed includes_count column display
- `renderErrorState()`: Updated colspan from 8 to 7
- `openZoneModal()`: Now loads and populates `zoneDirectory` field
- `setupChangeDetection()`: Added `zoneDirectory` to change tracking
- `saveZone()`: Now saves `directory` field value

#### New Function:
- `generateZoneFileContent()`: Calls the API to generate zone file and:
  - Offers to download the generated file
  - Or displays it in the editor for preview

## Usage

### Setting the Directory Field
1. Open a zone by clicking on it in the table
2. In the modal, go to the "Détails" tab
3. Enter the directory path in the "Répertoire" field (e.g., `/etc/bind/zones`)
4. Click "Enregistrer" to save

### Generating a Zone File
1. Open a zone by clicking on it in the table
2. Go to the "Éditeur" tab
3. Click the "Générer le fichier de zone" button
4. Choose to either:
   - Download the file
   - Preview it in the editor

### Generated Zone File Format

The generated zone file contains (in order):

1. **Zone's own content** (from `zone_files.content` field)
2. **$INCLUDE directives** for each direct include:
   ```
   $INCLUDE "/etc/bind/zones/common.conf"
   $INCLUDE "special-records.conf"
   ```
3. **DNS Records** in BIND syntax:
   ```
   ; DNS Records
   www.example.com        3600 IN A      192.168.1.10
   mail.example.com       3600 IN A      192.168.1.20
   example.com            3600 IN MX     10 mail.example.com
   _service._tcp          3600 IN SRV    10 5060 sip.example.com
   ```

## BIND Record Format Examples

- **A Record**: `name TTL IN A ipv4_address`
- **AAAA Record**: `name TTL IN AAAA ipv6_address`
- **CNAME Record**: `name TTL IN CNAME target`
- **MX Record**: `name TTL IN MX priority target`
- **TXT Record**: `name TTL IN TXT "text content"`
- **NS Record**: `name TTL IN NS nameserver`
- **PTR Record**: `name TTL IN PTR hostname`
- **SRV Record**: `name TTL IN SRV priority weight port target`
- **SOA Record**: `name TTL IN SOA content`

## Compatibility

- PHP 7.4+ compatible
- Uses standard BIND zone file syntax
- Includes are NOT inlined (uses $INCLUDE directives)
- Active DNS records only (status = 'active')

## Testing Checklist

- [ ] Run migration to add directory column
- [ ] Create/update zones with directory field
- [ ] Verify directory field shows in modal but not in table
- [ ] Create includes and assign them to a parent zone
- [ ] Add DNS records to a zone
- [ ] Click "Générer le fichier de zone" button
- [ ] Verify generated file contains:
  - [ ] Zone content
  - [ ] $INCLUDE directives with correct paths
  - [ ] DNS records in BIND format
- [ ] Test with zones that have no directory set
- [ ] Test with zones that have directory set
- [ ] Verify download functionality works
- [ ] Verify preview in editor works

## Notes

- The includes are referenced by their path (not inlined)
- Only active DNS records are included in the generated file
- The directory field is optional (NULL is allowed)
- The "# Includes" column has been removed from the table view as requested
- All changes maintain backward compatibility with existing data
