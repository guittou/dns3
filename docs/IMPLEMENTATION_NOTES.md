# DNS Domain Display Fix - Implementation Notes

## Overview
Fixed DNS domain display to show master domain for include zones instead of the include filename (e.g., "test.fr" instead of "include1").

## Problem Statement
After migration from `domaine_list.domain` to `zone_files.domain`, the DNS management page was displaying:
- ❌ Include zone filename (e.g., "include1") in the "Domaine" column and combobox
- ✅ Expected: Parent master's domain (e.g., "test.fr")

## Root Cause Analysis
The domain combobox was set to read-only and wasn't loading the available domains from master zones. Users couldn't filter by domain, and the system wasn't properly displaying domain information for include zones.

## Solution Architecture

### Backend (Already Correct - No Changes Required)

#### 1. Database Schema
```sql
-- zone_files table has domain column (added in migration 015)
ALTER TABLE zone_files ADD COLUMN `domain` VARCHAR(255) DEFAULT NULL;

-- zone_file_includes table manages parent-child relationships
CREATE TABLE zone_file_includes (
  parent_id INT(11),
  include_id INT(11),
  position INT(11)
);
```

#### 2. DnsRecord Model (includes/models/DnsRecord.php)

**SQL Query with Proper JOINs:**
```php
$sql = "SELECT dr.*, 
               zf.domain as zone_domain,
               zf.file_type as zone_file_type,
               p.domain as parent_domain
        FROM dns_records dr
        LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
        LEFT JOIN zone_file_includes zfi ON zf.id = zfi.include_id
        LEFT JOIN zone_files p ON zfi.parent_id = p.id";
```

**domain_name Computation Logic:**
```php
$fileType = $record['zone_file_type'] ?? 'master';
if ($fileType === 'master') {
    // Master zone: use zone_domain (no fallback to zone_name)
    $record['domain_name'] = (!empty($record['zone_domain'])) ? 
                              $record['zone_domain'] : null;
} else {
    // Include zone: use parent_domain (no fallback)
    $record['domain_name'] = (!empty($record['parent_domain'])) ? 
                              $record['parent_domain'] : null;
}
```

#### 3. DNS API (api/dns_api.php)

**list_domains Endpoint:**
```php
// Returns only master zones with domain field set
SELECT zf.id, zf.domain, zf.name as zone_name
FROM zone_files zf
WHERE zf.domain IS NOT NULL 
  AND zf.domain != ''
  AND zf.status = 'active'
  AND zf.file_type = 'master'
ORDER BY zf.domain ASC
```

### Frontend Changes

#### 1. Domain Combobox (assets/js/dns-records.js)

**Before (Incorrect):**
```javascript
async function initDomainCombobox() {
    const input = document.getElementById('dns-domain-input');
    if (input) {
        input.readOnly = true;  // ❌ Read-only, no interaction
        input.placeholder = 'Sélectionnez d\'abord une zone';
    }
}
```

**After (Correct):**
```javascript
async function initDomainCombobox() {
    // Load all domains from master zones
    const result = await apiCall('list_domains');
    allDomains = result.data || [];
    
    const input = document.getElementById('dns-domain-input');
    const list = document.getElementById('dns-domain-list');
    
    // Make input interactive
    input.readOnly = false;
    input.placeholder = 'Rechercher un domaine...';
    
    // Input event - filter domains
    input.addEventListener('input', () => {
        const query = input.value.toLowerCase().trim();
        const filtered = allDomains.filter(d => 
            d.domain.toLowerCase().includes(query)
        );
        populateComboboxList(list, filtered, ...);
    });
    
    // Focus - show all domains
    input.addEventListener('focus', () => {
        populateComboboxList(list, allDomains, ...);
    });
    
    // Blur, Escape handlers...
}
```

#### 2. Table Rendering (Already Correct)
```javascript
// Table already uses domain_name field
const domainDisplay = escapeHtml(record.domain_name || '-');
row.innerHTML = `
    <td class="col-domain">${domainDisplay}</td>
    ...
`;
```

#### 3. Zone Modal (zone-files.js - Already Correct)
```javascript
// Domain field shown only for masters
const group = document.getElementById('zoneDomainGroup');
if (group) {
    group.style.display = ((zone.file_type || 'master') === 'master') 
                          ? 'block' : 'none';
}
```

## Data Flow

### Scenario 1: Loading DNS Records Table

```
User loads page
    ↓
initDomainCombobox() called
    ↓
apiCall('list_domains')
    ↓
dns_api.php?action=list_domains
    ↓
Returns: [
    {id: 260, domain: "test.fr"},
    {id: 261, domain: "example.com"}
]
    ↓
Domain combobox populated
    ↓
loadDnsTable() called
    ↓
apiCall('list')
    ↓
dns_api.php?action=list
    ↓
$dnsRecord->search()
    ↓
SQL with JOINs executes
    ↓
domain_name computed for each record
    ↓
Returns: [
    {
        id: 123,
        name: "www",
        zone_name: "test.fr",
        zone_file_type: "master",
        zone_domain: "test.fr",
        domain_name: "test.fr"  // ✅ Master
    },
    {
        id: 456,
        name: "mail", 
        zone_name: "include1",
        zone_file_type: "include",
        parent_domain: "test.fr",
        domain_name: "test.fr"  // ✅ Include -> parent
    }
]
    ↓
Table rendered with domain_name
```

### Scenario 2: Clicking an Include Record

```
User clicks record row
    ↓
Row click handler
    ↓
zoneFileId = record.zone_file_id
    ↓
setDomainForZone(zoneFileId)
    ↓
zoneApiCall('get_zone', {id: zoneFileId})
    ↓
zone_api.php?action=get_zone&id=260
    ↓
ZoneFile->getById(260)
    ↓
SQL with parent_domain JOIN
    ↓
Returns: {
    id: 260,
    name: "include1",
    file_type: "include",
    parent_id: 259,
    parent_domain: "test.fr"
}
    ↓
setDomainForZone logic:
    if (zone.file_type === 'master') {
        domainName = zone.domain || '';
    } else {
        domainName = zone.parent_domain || '';  // ✅
    }
    ↓
Domain input displays "test.fr"
```

## Testing Verification

### Manual Testing Steps

1. **Domain Combobox Loads:**
   - Open DNS management page
   - Click domain input
   - Verify dropdown shows all master domains
   - Type to filter domains
   - Select a domain and verify zones filter

2. **Table Displays Correct Domain:**
   - For master zone records: Shows zone_files.domain
   - For include zone records: Shows parent master's domain
   - For masters without domain: Shows "-"

3. **Include Record Click:**
   - Click a record belonging to an include zone
   - Verify domain input shows parent's domain (e.g., "test.fr")
   - Not the include filename (e.g., "include1")

4. **Zone Modal:**
   - Open master zone modal: Domain field visible and editable
   - Open include zone modal: Domain field hidden

### API Testing

**Test 1: list_domains**
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list_domains" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Expected Response:
```json
{
  "success": true,
  "data": [
    {"id": 260, "domain": "example.com", "zone_name": "example.com"},
    {"id": 261, "domain": "test.fr", "zone_name": "test.fr"}
  ]
}
```

**Test 2: list (with include records)**
```bash
curl -X GET "http://localhost/api/dns_api.php?action=list" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Expected Response:
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "name": "www",
      "zone_name": "test.fr",
      "zone_file_type": "master",
      "zone_domain": "test.fr",
      "parent_domain": null,
      "domain_name": "test.fr"
    },
    {
      "id": 456,
      "name": "mail",
      "zone_name": "include1",
      "zone_file_type": "include",
      "zone_domain": null,
      "parent_domain": "test.fr",
      "domain_name": "test.fr"
    }
  ]
}
```

**Test 3: get_zone (include)**
```bash
curl -X GET "http://localhost/api/zone_api.php?action=get_zone&id=260" \
     -H "Cookie: PHPSESSID=..." \
     -H "Accept: application/json"
```

Expected Response:
```json
{
  "success": true,
  "data": {
    "id": 260,
    "name": "include1",
    "filename": "include1.conf",
    "file_type": "include",
    "domain": null,
    "parent_id": 259,
    "parent_name": "test.fr",
    "parent_domain": "test.fr"
  }
}
```

## Files Modified

- `assets/js/dns-records.js`: Updated initDomainCombobox() function

## Files Verified (No Changes Required)

- `includes/models/DnsRecord.php`: Already computes domain_name correctly
- `api/dns_api.php`: Already uses DnsRecord model with correct JOINs
- `includes/models/ZoneFile.php`: Already returns parent_domain
- `api/zone_api.php`: Already exposes parent info
- `assets/js/zone-files.js`: Already shows domain field only for masters

## Rollback Plan

If issues are discovered after deployment:

```bash
# Option 1: Revert the commit
git revert <commit-hash>
git push origin <branch>

# Option 2: Quick fix - make domain input read-only again
# Edit assets/js/dns-records.js:
async function initDomainCombobox() {
    const input = document.getElementById('dns-domain-input');
    if (input) {
        input.readOnly = true;
        input.placeholder = 'Sélectionnez d\'abord une zone';
    }
}
```

The change is minimal and reversible. Backend logic is unchanged, reducing risk.

## Security Considerations

- ✅ No SQL injection risks (uses PDO prepared statements)
- ✅ No XSS risks (uses escapeHtml() for all user data)
- ✅ Authentication required for all API endpoints
- ✅ No new endpoints created
- ✅ CodeQL scan passed with 0 vulnerabilities

## Performance Impact

- **Minimal**: One additional API call on page load (list_domains)
- **Optimized**: list_domains filters for masters only
- **Cached**: Domain list loaded once and cached in memory
- **No N+1**: SQL uses proper JOINs, not multiple queries

## Browser Compatibility

- ✅ Modern browsers (Chrome, Firefox, Safari, Edge)
- ✅ ES6 async/await (supported in all modern browsers)
- ✅ No polyfills required
- ✅ Graceful degradation if JavaScript disabled (read-only mode)

## Known Limitations

1. **Domain field is optional**: Masters without domain will show "-" in the table
2. **Include chains**: Only direct parent's domain is shown (not grandparent)
3. **Circular references**: Protected by MAX_ZONE_TRAVERSAL_DEPTH constant

## Future Enhancements

1. Add domain field validation in zone creation/edit modal
2. Show full parent chain for nested includes
3. Add domain field to include zones (for override scenarios)
4. Add bulk domain assignment tool for existing masters

## References

- Migration: `migrations/015_add_domain_to_zone_files.sql`
- Original Issue: GitHub Issue #XXX (if applicable)
- Related PR: #137 (previous domain migration)

---

**Author**: Copilot Agent  
**Date**: 2025-11-09  
**Status**: ✅ Implementation Complete  
**Security Scan**: ✅ Passed (0 vulnerabilities)
