-- Migration 015: Add domain column to zone_files
-- This migration adds a domain column to zone_files and migrates existing data from domaine_list
-- Purpose: Consolidate domain information into zone_files table for simpler data model
--          while keeping domaine_list for backward compatibility and rollback safety.
-- This migration is idempotent and can be run multiple times safely.

USE dns3_db;

-- Add domain column to zone_files if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_files' 
  AND COLUMN_NAME = 'domain';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE zone_files ADD COLUMN domain VARCHAR(255) DEFAULT NULL COMMENT ''Domain name for master zones (migrated from domaine_list)''',
    'SELECT ''Column domain already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index on domain for better query performance
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_files' 
  AND INDEX_NAME = 'idx_domain';

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX idx_domain ON zone_files(domain)',
    'SELECT ''Index idx_domain already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migrate existing domain data from domaine_list to zone_files
-- Only for master zones (file_type = 'master')
UPDATE zone_files z 
JOIN domaine_list d ON d.zone_file_id = z.id
SET z.domain = d.domain
WHERE z.file_type = 'master' AND z.domain IS NULL;

-- Verification query (run manually to verify migration)
-- SELECT COUNT(*) as migrated_domains FROM zone_files WHERE domain IS NOT NULL;
-- SELECT z.id, z.name, z.domain, z.file_type FROM zone_files WHERE domain IS NOT NULL LIMIT 10;

-- ROLLBACK INSTRUCTIONS
-- To rollback this migration, run the following steps:

-- Step 1: Stop the application
--   sudo systemctl stop apache2  # or nginx, php-fpm, etc.

-- Step 2: Clear domain values (preserves column for safety)
--   USE dns3_db;
--   UPDATE zone_files SET domain = NULL WHERE domain IS NOT NULL;

-- Step 3 (optional): Drop the domain column entirely
--   USE dns3_db;
--   ALTER TABLE zone_files DROP INDEX IF EXISTS idx_domain;
--   ALTER TABLE zone_files DROP COLUMN IF EXISTS domain;

-- Step 4: Revert code changes
--   git revert [commit-hash]

-- Step 5: Restart the application
--   sudo systemctl start apache2  # or nginx, php-fpm, etc.

-- Note: domaine_list table is NOT dropped in this migration for safety.
--       It can be dropped in a future migration after verification.
--       All domain data remains in domaine_list and can be re-migrated if needed.
