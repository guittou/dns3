-- Migration 00AA: Cleanup duplicate foreign keys on zone_file_includes
-- This migration is idempotent and safe to run multiple times.
-- It removes duplicate foreign key constraints if they exist, keeping the standard ones:
-- - zone_file_includes_ibfk_parent (parent_id -> zone_files)
-- - zone_file_includes_ibfk_include (include_id -> zone_files)
--
-- IMPORTANT: BACKUP YOUR DATABASE BEFORE RUNNING THIS MIGRATION!

USE dns3_db;

-- Drop any duplicate or incorrectly named foreign keys
-- We keep zone_file_includes_ibfk_1 and zone_file_includes_ibfk_2 as the standard names

-- Check and drop zone_file_includes_ibfk_parent if it exists (duplicate of ibfk_1)
SET @fk_parent_exists = 0;
SELECT COUNT(*) INTO @fk_parent_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_parent';

SET @sql = IF(@fk_parent_exists > 0,
    'ALTER TABLE zone_file_includes DROP FOREIGN KEY zone_file_includes_ibfk_parent',
    'SELECT "FK zone_file_includes_ibfk_parent does not exist, skipping" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check and drop zone_file_includes_ibfk_include if it exists (duplicate of ibfk_2)
SET @fk_include_exists = 0;
SELECT COUNT(*) INTO @fk_include_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_include';

SET @sql = IF(@fk_include_exists > 0,
    'ALTER TABLE zone_file_includes DROP FOREIGN KEY zone_file_includes_ibfk_include',
    'SELECT "FK zone_file_includes_ibfk_include does not exist, skipping" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verify that the standard foreign keys exist (ibfk_1 and ibfk_2)
-- If they don't exist, create them
SET @fk_1_exists = 0;
SELECT COUNT(*) INTO @fk_1_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_1';

SET @sql = IF(@fk_1_exists = 0,
    'ALTER TABLE zone_file_includes 
     ADD CONSTRAINT zone_file_includes_ibfk_1 
     FOREIGN KEY (parent_id) REFERENCES zone_files(id) ON DELETE CASCADE',
    'SELECT "FK zone_file_includes_ibfk_1 already exists" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_2_exists = 0;
SELECT COUNT(*) INTO @fk_2_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_2';

SET @sql = IF(@fk_2_exists = 0,
    'ALTER TABLE zone_file_includes 
     ADD CONSTRAINT zone_file_includes_ibfk_2 
     FOREIGN KEY (include_id) REFERENCES zone_files(id) ON DELETE CASCADE',
    'SELECT "FK zone_file_includes_ibfk_2 already exists" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Migration 00AA completed: zone_file_includes foreign keys cleaned up' AS status;
