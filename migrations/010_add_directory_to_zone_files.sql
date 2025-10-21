-- Migration 010: Add directory column to zone_files table
-- This migration adds a directory field to support zone file path organization.
-- It is idempotent and can be run multiple times safely.

USE dns3_db;

-- Add directory column to zone_files if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_files' 
  AND COLUMN_NAME = 'directory';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE zone_files ADD COLUMN directory VARCHAR(255) NULL COMMENT ''Directory path for zone file'' AFTER filename',
    'SELECT ''Column directory already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index on directory for better query performance
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_files' 
  AND INDEX_NAME = 'idx_directory';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_directory ON zone_files(directory)',
    'SELECT ''Index idx_directory already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Notes:
-- 1. directory is NULLABLE to support existing records
-- 2. When directory is set, $INCLUDE directives will use: directory/filename
-- 3. When directory is NULL, $INCLUDE directives will use: filename only
-- 4. Migration is idempotent - can be run multiple times safely

-- End of migration 010
