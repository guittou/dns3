# Testing Guide: Modal UI and Single-Parent Enforcement

## Prerequisites

1. Backup your database before running migrations
2. Ensure you have admin access to the application
3. Have at least one master zone and one include zone in your database

## Database Migrations

### Step 1: Run Migration 008 (Single Parent Enforcement)

```bash
mysql -u dns3_user -p dns3_db < migrations/008_enforce_single_parent.sql
```

**Expected Output:**
- Should show "Migration 008 completed successfully!"
- Should list any includes that had multiple parents (if any)
- Creates `zone_file_includes_old` table for rollback
- Adds UNIQUE constraint on `include_id` column

**Verification:**
```sql
USE dns3_db;
DESCRIBE zone_file_includes;
-- Should show UNIQUE key on include_id column

SELECT * FROM zone_file_includes_old;
-- Should show old data if migration was run for first time
```

### Step 2: Run Migration 009 (History Actions)

```bash
mysql -u dns3_user -p dns3_db < migrations/009_add_history_actions.sql
```

**Expected Output:**
- Should show "Migration 009 completed successfully"

**Verification:**
```sql
USE dns3_db;
SHOW COLUMNS FROM zone_file_history WHERE Field = 'action';
-- Should show enum including 'assign_include' and 'reassign_include'
```

## UI Testing

### Test 1: View Zone List with Parent Column

1. Navigate to `/zone-files.php`
2. **Expected:** Table should have columns:
   - Zone
   - Type
   - Nom de fichier
   - Parent (NEW)
   - # Includes
   - Propriétaire
   - Statut
   - Modifié le
3. **Expected:** NO "Actions" column should be present
4. **Expected:** For include zones, Parent column shows the parent zone name
5. **Expected:** For master zones, Parent column shows "-"

### Test 2: Click Row to Open Modal

1. Click on any zone row in the table
2. **Expected:** Modal opens with the zone details
3. **Expected:** Modal title shows the zone name
4. **Expected:** Three tabs are visible: Détails, Éditeur, Includes

### Test 3: Create New Master Zone (via "Nouvelle zone" button)

1. Click "Nouvelle zone" button
2. **Expected:** Modal opens with form
3. **Expected:** "Type" field is set to "Master" and is disabled/read-only
4. Fill in:
   - Nom: `test-master-zone`
   - Nom de fichier: `test-master.zone`
   - Contenu: (optional)
5. Click "Créer"
6. **Expected:** Zone is created as master type
7. **Expected:** Modal closes and opens the new zone's detail modal

### Test 4: Create Include from Modal

1. Open a master zone (click on a row)
2. Go to "Includes" tab
3. Click "Créer un include" button
4. **Expected:** Form appears below the includes list
5. Fill in:
   - Nom: `test-include`
   - Nom de fichier: `test-include.conf`
   - Contenu: (optional)
6. Click "Créer et assigner"
7. **Expected:** Include is created and assigned to the parent
8. **Expected:** Include appears in the includes list

### Test 5: Reassign Include to Different Parent

1. Open an include zone (click on an include row in the table)
2. Go to "Détails" tab
3. **Expected:** "Parent" dropdown is visible and enabled
4. Select a different parent zone from dropdown
5. Click "Enregistrer"
6. **Expected:** Include is reassigned to new parent
7. **Expected:** History entry is created with action 'reassign_include'
8. Verify in database:
   ```sql
   SELECT * FROM zone_file_history 
   WHERE action = 'reassign_include' 
   ORDER BY changed_at DESC LIMIT 5;
   ```

### Test 6: Edit Zone Content

1. Open any zone
2. Go to "Éditeur" tab
3. Modify the content in the textarea
4. Click "Enregistrer"
5. **Expected:** Changes are saved
6. **Expected:** No navigation occurs, modal stays open
7. Close modal and reopen the zone
8. **Expected:** Changes are persisted

### Test 7: Soft Delete Zone

1. Open any zone
2. Click "Supprimer" button (red button)
3. **Expected:** Confirmation dialog appears
4. Click "OK"
5. **Expected:** Zone status is changed to "deleted"
6. **Expected:** Zone disappears from list (if filtering by active status)
7. Verify in database:
   ```sql
   SELECT * FROM zone_file_history 
   WHERE action = 'status_changed' 
   AND new_status = 'deleted'
   ORDER BY changed_at DESC LIMIT 5;
   ```

### Test 8: Unsaved Changes Warning

1. Open any zone
2. Modify the name or content
3. Try to close the modal (click X or outside modal)
4. **Expected:** Confirmation dialog appears: "Vous avez des modifications non enregistrées..."
5. Click "Cancel"
6. **Expected:** Modal stays open
7. Click "Enregistrer" to save changes

### Test 9: Cycle Detection

1. Create a structure: Master A -> Include B -> Include C
2. Try to assign Include A as a child of Include C (would create a cycle)
3. **Expected:** Error message: "Cannot create circular dependency..."
4. Verify the assignment was NOT made

### Test 10: Remove Include from Zone

1. Open a zone that has includes
2. Go to "Includes" tab
3. Click the X button on an include
4. **Expected:** Confirmation dialog appears
5. Click "OK"
6. **Expected:** Include is removed from parent
7. **Expected:** Include still exists in database (not deleted, just unassigned)

## Backend API Testing

### Test API Endpoint: list_zones (with parent info)

```bash
curl -X GET "http://your-domain/api/zone_api.php?action=list_zones" \
  -H "Cookie: your-session-cookie" \
  | jq '.data[] | {name, file_type, parent_name}'
```

**Expected:** Includes should show their parent_name

### Test API Endpoint: get_zone (with parent info)

```bash
curl -X GET "http://your-domain/api/zone_api.php?action=get_zone&id=123" \
  -H "Cookie: your-session-cookie" \
  | jq '.data | {name, file_type, parent_id, parent_name}'
```

**Expected:** Include zones show parent_id and parent_name

### Test API Endpoint: assign_include (reassignment)

```bash
curl -X POST "http://your-domain/api/zone_api.php?action=assign_include" \
  -H "Content-Type: application/json" \
  -H "Cookie: your-session-cookie" \
  -d '{"parent_id": 5, "include_id": 10, "position": 0}'
```

**Expected:** Success response, include is reassigned if already had a parent

### Test API Endpoint: create_and_assign_include

```bash
curl -X POST "http://your-domain/api/zone_api.php?action=create_and_assign_include" \
  -H "Content-Type: application/json" \
  -H "Cookie: your-session-cookie" \
  -d '{
    "name": "new-include",
    "filename": "new-include.conf",
    "content": "; include content",
    "parent_id": 5
  }'
```

**Expected:** Include is created and assigned in one transaction

## Edge Cases

1. **Include with no parent:** Should show "-" in Parent column
2. **Master zone:** Parent column always shows "-"
3. **Deleted zones:** Should not appear in parent dropdown
4. **Self-include prevention:** Cannot assign a zone as its own include
5. **Multiple reassignments:** Should work and create history for each

## Rollback Instructions

If migration 008 causes issues:

```sql
USE dns3_db;

-- Rename current table to failed
RENAME TABLE zone_file_includes TO zone_file_includes_failed;

-- Restore old table
RENAME TABLE zone_file_includes_old TO zone_file_includes;

-- Optionally drop the failed table
-- DROP TABLE zone_file_includes_failed;
```

## Success Criteria

- ✅ All migrations run without errors
- ✅ UI shows Parent column instead of Actions column
- ✅ Clicking row opens modal instead of navigating
- ✅ "Nouvelle zone" creates only master zones
- ✅ Includes can be created from modal
- ✅ Includes can be reassigned
- ✅ History is tracked for all operations
- ✅ Cycle detection prevents circular dependencies
- ✅ Soft delete works correctly
- ✅ Unsaved changes warning works
