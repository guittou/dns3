-- Migration 013: Remove Legacy Zone Columns from dns_records
-- This migration removes legacy compatibility columns (zone, zone_name, zone_file_name, zone_file)
-- from dns_records table after backfilling zone_file_id from those columns.
-- The migration is idempotent and can be safely re-run.
--
-- Legacy columns to remove (if they exist):
--   - zone: VARCHAR - zone identifier (matched against zone_files.name or zone_files.filename)
--   - zone_name: VARCHAR - display name of zone
--   - zone_file_name: VARCHAR - filename of zone file  
--   - zone_file: TEXT - zone file content
--
-- After this migration, the application uses:
--   - dns_records.zone_file_id (foreign key to zone_files.id)
--   - API joins zone_files to return zone_name and zone_filename for display

USE dns3_db;

-- ============================================================================
-- STEP 1: Create backup table for legacy columns (if any legacy columns exist)
-- ============================================================================

SET @legacy_col_count = 0;
SELECT COUNT(*) INTO @legacy_col_count
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'dns3_db'
  AND TABLE_NAME = 'dns_records'
  AND COLUMN_NAME IN ('zone', 'zone_name', 'zone_file_name', 'zone_file');

-- Create backup table if legacy columns exist and backup table doesn't exist
SET @backup_exists = 0;
SELECT COUNT(*) INTO @backup_exists
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'dns3_db'
  AND TABLE_NAME = 'dns_records_legacy_backup';

SET @create_backup = IF(@legacy_col_count > 0 AND @backup_exists = 0, 1, 0);

SET @sql = IF(@create_backup = 1,
    'CREATE TABLE dns_records_legacy_backup (
        id INT PRIMARY KEY,
        zone VARCHAR(255) NULL,
        zone_name VARCHAR(255) NULL,
        zone_file_name VARCHAR(255) NULL,
        zone_file MEDIUMTEXT NULL,
        backed_up_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_zone (zone),
        INDEX idx_zone_name (zone_name),
        INDEX idx_zone_file_name (zone_file_name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    'SELECT ''Backup table not needed or already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- STEP 2: Backup existing legacy column data (if columns exist)
-- ============================================================================

-- Check which specific columns exist and build backup INSERT dynamically
SET @has_zone = 0;
SET @has_zone_name = 0;
SET @has_zone_file_name = 0;
SET @has_zone_file = 0;

SELECT COUNT(*) INTO @has_zone
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'dns3_db' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'zone';

SELECT COUNT(*) INTO @has_zone_name
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'dns3_db' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'zone_name';

SELECT COUNT(*) INTO @has_zone_file_name
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'dns3_db' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'zone_file_name';

SELECT COUNT(*) INTO @has_zone_file
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'dns3_db' AND TABLE_NAME = 'dns_records' AND COLUMN_NAME = 'zone_file';

-- Build column list for backup (only columns that exist)
SET @backup_cols = 'id';
SET @select_cols = 'id';

SET @backup_cols = IF(@has_zone = 1, CONCAT(@backup_cols, ', zone'), @backup_cols);
SET @select_cols = IF(@has_zone = 1, CONCAT(@select_cols, ', zone'), @select_cols);

SET @backup_cols = IF(@has_zone_name = 1, CONCAT(@backup_cols, ', zone_name'), @backup_cols);
SET @select_cols = IF(@has_zone_name = 1, CONCAT(@select_cols, ', zone_name'), @select_cols);

SET @backup_cols = IF(@has_zone_file_name = 1, CONCAT(@backup_cols, ', zone_file_name'), @backup_cols);
SET @select_cols = IF(@has_zone_file_name = 1, CONCAT(@select_cols, ', zone_file_name'), @select_cols);

SET @backup_cols = IF(@has_zone_file = 1, CONCAT(@backup_cols, ', zone_file'), @backup_cols);
SET @select_cols = IF(@has_zone_file = 1, CONCAT(@select_cols, ', zone_file'), @select_cols);

-- Only backup if we have legacy columns and backup table exists
SET @do_backup = IF(@legacy_col_count > 0 AND @backup_exists = 0 AND @create_backup = 1, 1, 0);

SET @sql = IF(@do_backup = 1,
    CONCAT('INSERT INTO dns_records_legacy_backup (', @backup_cols, ') ',
           'SELECT ', @select_cols, ' FROM dns_records ',
           'WHERE id NOT IN (SELECT id FROM dns_records_legacy_backup)'),
    'SELECT ''No legacy data to backup'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- STEP 3: Backfill zone_file_id from legacy columns (if needed)
-- ============================================================================

-- Strategy:
-- 1. First try to match dns_records.zone with zone_files.name
-- 2. Then try to match dns_records.zone with zone_files.filename
-- 3. Then try to match dns_records.zone_name with zone_files.name
-- 4. Then try to match dns_records.zone_file_name with zone_files.filename

-- Backfill from zone column matching zone_files.name
SET @sql = IF(@has_zone = 1,
    'UPDATE dns_records dr
     JOIN zone_files zf ON zf.name = dr.zone
     SET dr.zone_file_id = zf.id
     WHERE (dr.zone_file_id IS NULL OR dr.zone_file_id = 0)
       AND dr.zone IS NOT NULL
       AND dr.zone != ''''',
    'SELECT ''Column zone does not exist, skipping backfill from zone->name'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill from zone column matching zone_files.filename
SET @sql = IF(@has_zone = 1,
    'UPDATE dns_records dr
     JOIN zone_files zf ON zf.filename = dr.zone
     SET dr.zone_file_id = zf.id
     WHERE (dr.zone_file_id IS NULL OR dr.zone_file_id = 0)
       AND dr.zone IS NOT NULL
       AND dr.zone != ''''',
    'SELECT ''Column zone does not exist, skipping backfill from zone->filename'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill from zone_name column matching zone_files.name
SET @sql = IF(@has_zone_name = 1,
    'UPDATE dns_records dr
     JOIN zone_files zf ON zf.name = dr.zone_name
     SET dr.zone_file_id = zf.id
     WHERE (dr.zone_file_id IS NULL OR dr.zone_file_id = 0)
       AND dr.zone_name IS NOT NULL
       AND dr.zone_name != ''''',
    'SELECT ''Column zone_name does not exist, skipping backfill from zone_name->name'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill from zone_file_name column matching zone_files.filename
SET @sql = IF(@has_zone_file_name = 1,
    'UPDATE dns_records dr
     JOIN zone_files zf ON zf.filename = dr.zone_file_name
     SET dr.zone_file_id = zf.id
     WHERE (dr.zone_file_id IS NULL OR dr.zone_file_id = 0)
       AND dr.zone_file_name IS NOT NULL
       AND dr.zone_file_name != ''''',
    'SELECT ''Column zone_file_name does not exist, skipping backfill from zone_file_name->filename'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- STEP 4: Drop legacy columns (if they exist)
-- ============================================================================

-- Drop zone column if exists
SET @sql = IF(@has_zone = 1,
    'ALTER TABLE dns_records DROP COLUMN zone',
    'SELECT ''Column zone does not exist, skipping drop'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop zone_name column if exists
SET @sql = IF(@has_zone_name = 1,
    'ALTER TABLE dns_records DROP COLUMN zone_name',
    'SELECT ''Column zone_name does not exist, skipping drop'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop zone_file_name column if exists
SET @sql = IF(@has_zone_file_name = 1,
    'ALTER TABLE dns_records DROP COLUMN zone_file_name',
    'SELECT ''Column zone_file_name does not exist, skipping drop'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop zone_file column if exists
SET @sql = IF(@has_zone_file = 1,
    'ALTER TABLE dns_records DROP COLUMN zone_file',
    'SELECT ''Column zone_file does not exist, skipping drop'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- VERIFICATION & SUMMARY
-- ============================================================================

SELECT 'Migration 013 completed successfully' AS status;

-- Show summary of what was done
SELECT 
    CASE 
        WHEN @legacy_col_count > 0 THEN CONCAT(@legacy_col_count, ' legacy columns found and processed')
        ELSE 'No legacy columns found - migration was a no-op'
    END AS summary;

-- Show any records that still don't have zone_file_id (orphaned records)
SELECT COUNT(*) AS orphaned_records_without_zone_file_id
FROM dns_records
WHERE zone_file_id IS NULL OR zone_file_id = 0;

-- ============================================================================
-- ROLLBACK INSTRUCTIONS (Manual - see migrations/README.md)
-- ============================================================================
-- To rollback this migration if needed:
-- 1. Stop the application
-- 2. Re-add the columns:
--    ALTER TABLE dns_records ADD COLUMN zone VARCHAR(255) NULL AFTER zone_file_id;
--    ALTER TABLE dns_records ADD COLUMN zone_name VARCHAR(255) NULL AFTER zone;
--    ALTER TABLE dns_records ADD COLUMN zone_file_name VARCHAR(255) NULL AFTER zone_name;
--    ALTER TABLE dns_records ADD COLUMN zone_file MEDIUMTEXT NULL AFTER zone_file_name;
-- 3. Restore data from backup:
--    UPDATE dns_records dr
--    JOIN dns_records_legacy_backup b ON dr.id = b.id
--    SET dr.zone = b.zone,
--        dr.zone_name = b.zone_name,
--        dr.zone_file_name = b.zone_file_name,
--        dr.zone_file = b.zone_file;
-- 4. Restart the application
-- 5. Note: API code changes would also need to be reverted to read from legacy columns
-- ============================================================================

-- End of migration 013
