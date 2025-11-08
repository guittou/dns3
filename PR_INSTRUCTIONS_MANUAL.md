# Manual PR Creation Instructions

## Branch Ready for PR
✅ Branch `copilot/migrate-domains-to-zone-files` has been pushed to origin

## How to Create the PR

### Option 1: GitHub Web UI
1. Go to: https://github.com/guittou/dns3/compare/copilot/migrate-domains-to-zone-files
2. Click "Create Pull Request"
3. Use the title and description below

### Option 2: GitHub CLI (if authenticated)
```bash
gh pr create \
  --title "DB+API+UI: migrate domain into zone_files.domain and adapt frontend/backend" \
  --body-file PR_BODY.md \
  --base main \
  --head copilot/migrate-domains-to-zone-files
```

## PR Title
```
DB+API+UI: migrate domain into zone_files.domain and adapt frontend/backend
```

## PR Description (copy below)
```markdown
## Overview
This PR implements the migration of domain data from the separate `domaine_list` table into the `zone_files.domain` column, consolidating domain management into the zone files system while maintaining full backward compatibility.

## What's Changed

### Database Migration (NEW)
- ✅ **migrations/015_add_domain_to_zone_files.sql**
  - Adds `domain` column to zone_files (idempotent with IF NOT EXISTS check)
  - Creates index on domain
  - Migrates data from domaine_list for master zones only
  - Preserves domaine_list table for safety
  - Enhanced rollback instructions (2 options)

### Code Changes (NEW)
- ✅ **admin.php** - Added HTML comment noting Domains admin deprecation

### Already Implemented (from previous PR #129)
- ✅ **api/zone_api.php** - Returns domain, accepts it for master zones, validates format
- ✅ **api/domain_api.php** - Compatibility wrapper reading from zone_files.domain
- ✅ **includes/models/ZoneFile.php** - Handles domain in create/update
- ✅ **includes/models/Domain.php** - Has deprecation comment
- ✅ **assets/js/dns-records.js** - Uses zone.domain with defensive fallbacks
- ✅ **assets/js/admin.js** - Shows domain in labels, logs deprecation warnings
- ✅ **migrations/README.md** - Full documentation for migration 015

## Key Features

### Idempotent Migration
The migration can be safely run multiple times:
- Checks if domain column exists before adding
- Checks if index exists before creating
- Only updates NULL domain values during data migration

### Defensive Implementation
All code handles missing domain gracefully:
- API returns domain as null if not set
- JavaScript checks for zone.domain before using it
- Fallbacks to previous behavior if domain is null

### Backward Compatibility
- domaine_list table **preserved** (not dropped)
- domain_api.php continues to work (reads from zone_files)
- Old API clients continue to function normally
- DNS records page works with or without domain data

## Testing Checklist

### Database Verification
After running the migration:
```sql
-- Check domain column exists
DESCRIBE zone_files;

-- Count migrated domains
SELECT COUNT(*) as migrated_domains FROM zone_files WHERE domain IS NOT NULL;

-- View sample migrated data
SELECT z.id, z.name, z.domain, z.file_type 
FROM zone_files 
WHERE domain IS NOT NULL 
LIMIT 50;
```

### API Testing
- [ ] `GET /api/zone_api.php?action=list_zones` includes `domain` field
- [ ] `GET /api/zone_api.php?action=get_zone&id=XX` includes `domain` field
- [ ] `POST /api/zone_api.php?action=create_zone` with domain works for master zones
- [ ] `POST /api/zone_api.php?action=update_zone&id=XX` with domain works
- [ ] `GET /api/domain_api.php?action=list` returns domains from zone_files
- [ ] `GET /api/domain_api.php?action=get&id=XX` returns zone mapped to domain format

### UI Testing
- [ ] DNS Management: Click record row → domain input filled from zone.domain
- [ ] DNS Management: Domain combobox filters zones correctly
- [ ] Admin → Domains: Tab shows domains from zone_files
- [ ] Admin: Domain zone select shows "domain (zone_name)" format
- [ ] Console: Deprecation warnings appear when creating/editing domains

## Rollback Instructions

### Option 1: Clear Domain Values (Safer - preserves column)
```bash
# Stop application
sudo systemctl stop apache2

# Clear domain data
mysql -u username -p dns3_db <<EOF
UPDATE zone_files SET domain = NULL WHERE domain IS NOT NULL;
EOF

# Revert code
git revert c48f04a ed3c4aa

# Restart application
sudo systemctl start apache2
```

### Option 2: Drop Column Completely
```bash
# Stop application
sudo systemctl stop apache2

# Drop column and index
mysql -u username -p dns3_db <<EOF
ALTER TABLE zone_files DROP INDEX IF EXISTS idx_domain;
ALTER TABLE zone_files DROP COLUMN IF EXISTS domain;
EOF

# Revert code
git revert c48f04a ed3c4aa

# Restart application
sudo systemctl start apache2
```

## Running the Migration

1. **Backup database:**
   ```bash
   mysqldump -u username -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Run migration:**
   ```bash
   mysql -u username -p dns3_db < migrations/015_add_domain_to_zone_files.sql
   ```

3. **Verify:**
   ```sql
   SELECT COUNT(*) FROM zone_files WHERE domain IS NOT NULL;
   ```

## Screenshots / Visual Changes

The following UI elements are affected (screenshots should be taken during testing):

1. **DNS Management Page**
   - Domain input auto-filled when clicking DNS record (uses zone.domain)
   - Zone combobox filters by domain field

2. **Admin → Domains Tab**
   - Shows domains migrated from zone_files
   - HTML comment in source noting deprecation

3. **Admin → Domain Zone Select**
   - Dropdown shows format: "example.com (zone_name)"

4. **Browser Console**
   - Deprecation warnings when creating/editing domains

## Constraints Followed
- ✅ domaine_list table NOT dropped (kept for safety)
- ✅ Domain model NOT removed (kept for backward compatibility)
- ✅ Changes are minimal and surgical
- ✅ Defensive implementation with fallbacks
- ✅ No breaking changes for existing clients

## Related PRs
- Based on PR #129 (already merged) which added initial domain column support
- This PR completes the migration with idempotent SQL and UI deprecation markers

## Labels
- database
- migration
- backward-compatible
- enhancement
- documentation

## Commits
- `c48f04a` - Make migration 015 idempotent and enhance rollback instructions
- `ed3c4aa` - Add deprecation comment to admin.php Domains tab
- `573355a` - Initial plan
```

## After Creating PR
1. Assign reviewers
2. Add labels: database, migration, backward-compatible, enhancement
3. Link to issue if one exists
4. Request testing in staging environment before merge
5. Verify all tests pass

## PR URL
After creation, the PR will be available at:
https://github.com/guittou/dns3/pull/[NUMBER]

(The exact number will be assigned by GitHub when PR is created)
