> **ARCHIVED DOCUMENT NOTE** : Les fichiers de migration mentionnés dans ce document ont été supprimés. Pour les nouvelles installations, utilisez `database.sql` (ou `structure_ok_dns3_db.sql`).

# Testing Guide: Zone File Improvements

This guide provides step-by-step instructions for testing the zone file improvements.

## Prerequisites

1. Database with migrations applied:
   ```bash
   mysql dns3_db < migrations/011_create_zone_file_validation.sql
   mysql dns3_db < migrations/00AA_cleanup_zone_file_includes_fks.sql
   ```

2. Two test users:
   - Admin user (has admin role)
   - Regular user (no admin role)

3. Optional: Install `named-checkzone` for validation testing:
   ```bash
   sudo apt-get install bind9-utils  # Debian/Ubuntu
   # or
   sudo yum install bind-utils        # RHEL/CentOS
   ```

## Test Cases

### 1. Admin-Only Zone File Generation

**Objective**: Verify that only admins can generate zone files

#### Test 1.1: Admin can generate zone files
1. Log in as admin user
2. Go to Zone Files page
3. Click on any zone to open the editor modal
4. Switch to "Éditeur" tab
5. Click "Générer le fichier de zone" button
6. **Expected**: Preview modal opens with generated content
7. **Expected**: Content shows zone directives, $INCLUDE statements, and DNS records
8. **Expected**: No 403 error

#### Test 1.2: Non-admin cannot generate zone files
1. Log out and log in as regular user
2. Go to Zone Files page
3. Click on any zone to open the editor modal
4. Switch to "Éditeur" tab
5. Click "Générer le fichier de zone" button
6. **Expected**: Error message "Accès refusé: seuls les administrateurs peuvent générer des fichiers de zone"
7. **Expected**: No preview modal opens

### 2. Preview Modal with CodeMirror

**Objective**: Verify preview functionality and CodeMirror integration

#### Test 2.1: Preview modal displays content
1. Log in as admin user
2. Open a zone in the editor
3. Click "Générer le fichier de zone"
4. **Expected**: Preview modal opens
5. **Expected**: Content is displayed with syntax highlighting (if CodeMirror loaded)
6. **Expected**: Content is readonly
7. **Expected**: Line numbers are visible

#### Test 2.2: Download from preview
1. With preview modal open
2. Click "Télécharger" button
3. **Expected**: File downloads with correct filename
4. **Expected**: Downloaded file contains the generated zone content
5. Verify file content matches what's shown in preview

#### Test 2.3: Close preview modal
1. Click "Fermer" button
2. **Expected**: Preview modal closes
3. **Expected**: Zone editor modal is still open in background

### 3. CodeMirror Editor Integration

**Objective**: Verify CodeMirror editor in zone content tab

#### Test 3.1: CodeMirror loads in editor
1. Open any zone in the editor modal
2. Switch to "Éditeur" tab
3. **Expected**: CodeMirror editor is loaded (not plain textarea)
4. **Expected**: Line numbers are visible
5. **Expected**: Syntax highlighting is applied
6. **Expected**: Existing zone content is displayed

#### Test 3.2: Edit and save with CodeMirror
1. In the editor tab, modify zone content
2. Make some changes to the text
3. Switch to "Détails" tab and back to "Éditeur"
4. **Expected**: Warning about unsaved changes if you try to close modal
5. Click "Enregistrer" button
6. **Expected**: Changes are saved successfully
7. Refresh the page and reopen the zone
8. **Expected**: Saved changes persist

#### Test 3.3: CodeMirror fallback
1. Disable JavaScript in browser (or simulate CodeMirror load failure)
2. Open zone editor
3. **Expected**: Plain textarea is used as fallback
4. **Expected**: Content is still editable and saveable

### 4. Zone Validation (Synchronous Mode)

**Objective**: Test named-checkzone validation in sync mode

#### Test 4.1: Configure sync validation
1. Edit `config.php`:
   ```php
   define('ZONE_VALIDATE_SYNC', true);
   ```
2. Ensure `named-checkzone` is in PATH or set full path:
   ```php
   define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');
   ```

#### Test 4.2: Create zone with validation
1. Log in as admin
2. Create a new zone with valid content:
   ```
   $TTL 86400
   @   IN  SOA ns1.example.com. admin.example.com. (
           2024010101 ; Serial
           3600       ; Refresh
           1800       ; Retry
           604800     ; Expire
           86400 )    ; Minimum TTL
   @   IN  NS  ns1.example.com.
   ```
3. **Expected**: Zone is created successfully
4. Check database: `SELECT * FROM zone_file_validation ORDER BY checked_at DESC LIMIT 1;`
5. **Expected**: Validation record exists with status 'passed' or 'failed'

#### Test 4.3: Update zone triggers validation
1. Edit an existing zone's content
2. Save the zone
3. **Expected**: New validation record is created
4. Check database again for new validation entry

### 5. Zone Validation (Async Mode)

**Objective**: Test background validation queue

#### Test 5.1: Configure async validation
1. Edit `config.php`:
   ```php
   define('ZONE_VALIDATE_SYNC', false);
   ```

#### Test 5.2: Queue validation
1. Create or update a zone
2. Check `jobs/validation_queue.json`
3. **Expected**: File exists with queued validation job
4. **Expected**: Database has validation with status 'pending'

#### Test 5.3: Process queue manually
1. Run worker manually:
   ```bash
   ./jobs/worker.sh
   ```
2. **Expected**: Queue file is processed and removed
3. Check database: validation status updated to 'passed' or 'failed'
4. Check `jobs/worker.log` for execution log

#### Test 5.4: Validation API endpoint
1. Make API call to retrieve validation:
   ```bash
   curl -X GET "http://localhost/api/zone_api.php?action=zone_validate&id=1" \
     -H "Cookie: PHPSESSID=your_session_id"
   ```
2. **Expected**: JSON response with latest validation result
3. **Expected**: Response includes status, output, checked_at, run_by

#### Test 5.5: Trigger validation via API
1. Make API call to trigger validation (admin only):
   ```bash
   curl -X GET "http://localhost/api/zone_api.php?action=zone_validate&id=1&trigger=true" \
     -H "Cookie: PHPSESSID=admin_session_id"
   ```
2. **Expected**: Validation is queued or run (depending on config)
3. **Expected**: Response confirms validation was triggered

### 6. Database Migrations

**Objective**: Verify FK cleanup migrations work correctly

#### Test 6.1: Run FK cleanup migration
1. Backup database:
   ```bash
   mysqldump dns3_db > backup_before_fk_cleanup.sql
   ```
2. Run migration:
   ```bash
   mysql dns3_db < migrations/00AA_cleanup_zone_file_includes_fks.sql
   ```
3. **Expected**: Migration completes without errors
4. Check foreign keys:
   ```sql
   SELECT CONSTRAINT_NAME 
   FROM information_schema.TABLE_CONSTRAINTS 
   WHERE TABLE_NAME = 'zone_file_includes' 
     AND CONSTRAINT_TYPE = 'FOREIGN KEY';
   ```
5. **Expected**: Only `zone_file_includes_ibfk_1` and `zone_file_includes_ibfk_2` exist

#### Test 6.2: Verify zone functionality after FK cleanup
1. Test creating includes
2. Test assigning includes to zones
3. Test removing includes
4. **Expected**: All operations work normally

#### Test 6.3: Drop old backup table (after validation)
1. After verifying everything works for several days/weeks
2. Run migration:
   ```bash
   mysql dns3_db < migrations/00AB_drop_zone_file_includes_old.sql
   ```
3. **Expected**: zone_file_includes_old table is dropped
4. Verify: `SHOW TABLES LIKE 'zone_file_includes_old';`
5. **Expected**: No results

### 7. Background Worker (Cron Setup)

**Objective**: Test cron-based validation processing

#### Test 7.1: Setup cron job
1. Make worker executable:
   ```bash
   chmod +x jobs/worker.sh
   ```
2. Add to crontab:
   ```bash
   * * * * * /path/to/dns3/jobs/worker.sh >> /var/log/dns3-worker.log 2>&1
   ```

#### Test 7.2: Verify cron execution
1. Create/update a zone to queue validation
2. Wait 1-2 minutes
3. Check worker log:
   ```bash
   tail -f /var/log/dns3-worker.log
   ```
4. **Expected**: Worker runs and processes queue
5. **Expected**: Validation status updates from 'pending' to 'passed'/'failed'

#### Test 7.3: Lock file prevents concurrent runs
1. While worker is running, try to run it again
2. **Expected**: Second instance exits immediately
3. Check logs for "Worker already running, exiting" message

## Troubleshooting

### CodeMirror not loading
- Check browser console for errors
- Verify CDN URLs are accessible
- Check for Content Security Policy restrictions

### Validation always fails
- Verify `named-checkzone` is installed
- Check NAMED_CHECKZONE_PATH in config.php
- Test manually: `named-checkzone example.com /tmp/test-zone.txt`

### Background worker not processing
- Check cron is running: `grep CRON /var/log/syslog`
- Verify worker.sh has execute permissions
- Check worker.log for errors
- Ensure web server user can write to jobs/ directory

### Preview modal not showing
- Check browser console for JavaScript errors
- Verify user is admin
- Check API response for errors

## Success Criteria

All test cases pass:
- ✅ Admin can generate and preview zone files
- ✅ Non-admin gets 403 on generate
- ✅ Preview modal shows content with CodeMirror
- ✅ Download from preview works
- ✅ CodeMirror editor works in zone modal
- ✅ Saving from CodeMirror persists changes
- ✅ Validation runs automatically on create/update
- ✅ Validation results are stored in database
- ✅ API endpoint returns validation results
- ✅ Background worker processes queue (if cron enabled)
- ✅ FK cleanup migration runs successfully
- ✅ All zone operations work after FK cleanup
