-- Migration 00AB: Drop zone_file_includes_old backup table
-- This migration drops the zone_file_includes_old table that was created
-- by migration 008 (enforce_single_parent) as a backup.
--
-- *** WARNING: ONLY RUN THIS AFTER MANUAL VALIDATION ***
-- 
-- Before running this migration, verify that:
-- 1. Migration 008 completed successfully
-- 2. All zone file functionality is working correctly
-- 3. No rollback to the old table is needed
-- 4. You have a full database backup
--
-- This migration is idempotent and safe to run multiple times.

USE dns3_db;

-- Check if zone_file_includes_old exists
SET @table_exists = 0;
SELECT COUNT(*) INTO @table_exists 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes_old';

-- Drop the table if it exists
SET @sql = IF(@table_exists > 0,
    'DROP TABLE zone_file_includes_old',
    'SELECT "Table zone_file_includes_old does not exist, nothing to drop" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Migration 00AB completed: zone_file_includes_old dropped (if existed)' AS status;
