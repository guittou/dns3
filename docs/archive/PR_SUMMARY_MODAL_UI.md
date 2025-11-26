> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# PR Summary: Modal UI + Single-Parent Constraint + Reassign Support

## Overview

This PR implements a comprehensive overhaul of the zone files management interface with the following key changes:
- Modal-based editing instead of separate pages
- Single-parent enforcement for includes with database migration
- Support for reassigning includes between parents
- Improved UI/UX with clickable rows and no per-row action buttons

## Changes Made

### 1. Database Migrations

#### migrations/008_enforce_single_parent.sql
- **Purpose:** Enforce that each include can only have ONE parent zone
- **What it does:**
  - Detects includes with multiple parents
  - Keeps only the oldest parent relationship (by created_at)
  - Creates new table with UNIQUE(include_id) constraint
  - Preserves old table (zone_file_includes_old) for rollback
  - Re-creates foreign keys
- **Idempotent:** Can be run multiple times safely
- **⚠️ IMPORTANT:** Backup database before running!

#### migrations/009_add_history_actions.sql
- **Purpose:** Add new action types to zone_file_history
- **Adds:** 'assign_include' and 'reassign_include' to action enum
- **Idempotent:** Can be run multiple times safely

### 2. Backend Model Changes

#### includes/models/ZoneFile.php

**Modified Methods:**

1. **search()** - Now includes parent information
   - Added LEFT JOIN with zone_file_includes
   - Added LEFT JOIN with parent zone_files
   - Returns parent_id and parent_name for includes
   - Modified COUNT query to handle JOINs properly

2. **getById()** - Now includes parent information
   - Added same JOINs as search()
   - Returns parent_id and parent_name

3. **assignInclude()** - Enhanced to support reassignment
   - Added $userId parameter for history tracking
   - Wrapped in transaction for safety
   - Detects if include already has a parent
   - If reassigning: writes history with 'reassign_include' action
   - If new: writes history with 'assign_include' action
   - Updates parent_id instead of INSERT when reassigning
   - Maintains all cycle detection logic

### 3. API Changes

#### api/zone_api.php

**Modified Endpoints:**

1. **list_zones** - Now returns parent info via model (no code change needed)

2. **get_zone** - Now returns parent info via model (no code change needed)

3. **assign_include** - Enhanced
   - Now passes $user['id'] to assignInclude() method
   - Supports reassignment automatically via model

**New Endpoints:**

4. **create_and_assign_include** - Convenience endpoint
   - Creates include and assigns to parent in one call
   - Forces file_type='include'
   - Returns created include ID
   - Handles errors gracefully (include created but assignment failed)

### 4. Frontend Changes

#### zone-files.php

**List View:**
- Removed "Actions" column
- Added "Parent" column (shows parent zone name for includes, "-" for masters)
- Made table rows clickable (data-id attribute, onclick handler)
- Removed individual action buttons

**Create Zone Modal:**
- Modified to force file_type='master'
- Disabled file_type dropdown
- Added explanatory text about include creation

**New: Zone Edit Modal:**
- Large modal with three tabs:
  - **Détails:** Edit name, filename, status, parent (for includes)
  - **Éditeur:** Textarea for zone content
  - **Includes:** List of child includes + create include form
- Footer with three centered buttons:
  - Supprimer (red/danger)
  - Annuler (gray/secondary)
  - Enregistrer (blue/primary)
- Inline create include form within Includes tab

#### assets/js/zone-files.js

**New Functions:**

1. **openZoneModal(zoneId)** - Fetches zone data and opens modal
2. **closeZoneModal()** - Closes modal with unsaved changes warning
3. **switchTab(tabName)** - Switches between modal tabs
4. **loadParentOptions(currentParentId)** - Loads available parents for includes
5. **loadIncludesList(includes)** - Renders list of child includes
6. **setupChangeDetection()** - Tracks unsaved changes
7. **saveZone()** - Saves zone changes (handles status, parent reassignment, content)
8. **deleteZone()** - Soft deletes zone with confirmation
9. **openCreateIncludeForm()** - Shows inline create form in Includes tab
10. **cancelCreateInclude()** - Hides create form
11. **submitCreateInclude()** - Creates and assigns include via API
12. **removeIncludeFromZone(includeId)** - Removes include from parent

**Modified Functions:**

- **renderZonesTable()** - Added Parent column, made rows clickable, removed action buttons
- **openCreateZoneModal()** - Forces master type and disables dropdown
- **createZone()** - Opens new zone in modal instead of navigating
- **window.onclick** - Enhanced to handle both modals properly

**State Variables:**
- currentZone: Currently open zone
- currentTab: Active tab in modal
- hasUnsavedChanges: Tracks unsaved changes
- originalZoneData: For comparison

#### assets/css/zone-files.css

**New Styles:**
- `.modal-footer-centered` - Centers footer buttons
- `.zone-row:hover` - Hover effect for clickable rows
- `.form-text`, `.text-muted` - Form helper text styling

**Modified Styles:**
- Removed action button styles (no longer needed)

## Key Features

### 1. Single-Parent Enforcement
- Database constraint ensures each include has max one parent
- Migration handles existing duplicates automatically
- Clear error messages if constraint is violated

### 2. Include Reassignment
- UI allows changing parent via dropdown in Details tab
- Backend creates history entry documenting the reassignment
- Transaction-safe operation

### 3. Modal-Based Editing
- No page navigation required
- All editing happens in modal
- Better UX with faster interactions
- Unsaved changes warning prevents data loss

### 4. Improved Include Management
- Create includes directly from parent zone
- View all child includes in one place
- Quick remove functionality
- Clear parent-child relationships in list view

### 5. Cycle Detection
- Prevents circular dependencies
- Checks before assigning/reassigning
- Clear error message if cycle would be created

## Breaking Changes

⚠️ **Migration Required:**
- Must run migrations 008 and 009 before using new features
- Migration 008 modifies zone_file_includes table structure
- Backup database before migrating!

⚠️ **UI Changes:**
- Actions column removed from list view
- Navigation now happens via modal instead of separate pages
- zone-file.php page still exists for direct access but not used from list

## Testing Checklist

See TESTING_MODAL_UI.md for comprehensive testing guide.

**Critical Tests:**
- ✅ Migration runs without errors
- ✅ Includes with multiple parents are handled correctly
- ✅ UI shows parent column
- ✅ Clicking row opens modal
- ✅ Create master zone works
- ✅ Create include from modal works
- ✅ Reassign include works
- ✅ History is tracked
- ✅ Cycle detection works
- ✅ Soft delete works
- ✅ Unsaved changes warning works

## Security

- All mutating endpoints require admin privileges (requireAdmin())
- All read endpoints require authentication (requireAuth())
- Database transactions ensure data consistency
- Soft delete preserves data for audit trail
- History tracking for all operations

## Performance

- Minimal additional queries (one LEFT JOIN per zone list)
- Indexed columns ensure fast lookups
- Pagination maintained for large datasets
- Modal reduces page loads

## Backwards Compatibility

- API endpoints maintain same signatures (added optional params)
- zone-file.php detail page still works if accessed directly
- Old zone_file_includes_old table preserved for rollback
- No changes to DNS record functionality

## Migration Instructions

1. **Backup database:**
   ```bash
   mysqldump -u dns3_user -p dns3_db > backup_before_migration.sql
   ```

2. **Run migrations:**
   ```bash
   mysql -u dns3_user -p dns3_db < migrations/008_enforce_single_parent.sql
   mysql -u dns3_user -p dns3_db < migrations/009_add_history_actions.sql
   ```

3. **Verify migrations:**
   ```sql
   USE dns3_db;
   DESCRIBE zone_file_includes;  -- Check for UNIQUE(include_id)
   SELECT * FROM zone_file_includes_old;  -- Verify backup exists
   SHOW COLUMNS FROM zone_file_history WHERE Field = 'action';  -- Check new actions
   ```

4. **Test UI:**
   - Navigate to /zone-files.php
   - Verify Parent column appears
   - Click a row to open modal
   - Test all modal functionality

## Rollback Instructions

If issues occur, rollback migration 008:

```sql
USE dns3_db;
RENAME TABLE zone_file_includes TO zone_file_includes_failed;
RENAME TABLE zone_file_includes_old TO zone_file_includes;
-- Optionally: DROP TABLE zone_file_includes_failed;
```

Code changes can be reverted via git:
```bash
git revert <commit-hash>
```

## Files Changed

- migrations/008_enforce_single_parent.sql (NEW)
- migrations/009_add_history_actions.sql (NEW)
- includes/models/ZoneFile.php (MODIFIED)
- api/zone_api.php (MODIFIED)
- zone-files.php (MODIFIED)
- assets/js/zone-files.js (MODIFIED)
- assets/css/zone-files.css (MODIFIED)
- TESTING_MODAL_UI.md (NEW - documentation)
- PR_SUMMARY_MODAL_UI.md (NEW - this file)

## Future Improvements

- Consider adding batch operations (assign multiple includes at once)
- Add drag-and-drop for include ordering
- Add visual tree view for complex include hierarchies
- Add include template library
- Add content diff viewer for history
- Add export/import for zone configurations

## Authors

- Implementation: GitHub Copilot Agent
- Requirements: Product Owner (from problem statement)
