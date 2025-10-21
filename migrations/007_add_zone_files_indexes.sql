-- Migration 007: Add performance indexes for zone_files table
-- This migration adds indexes to speed up searches and filtering by type/status/name
-- It is idempotent and can be run multiple times safely.

USE dns3_db;

-- Add composite index for common search patterns (type + status + name)
-- This speeds up queries that filter by file_type and status, with partial name matching
CREATE INDEX IF NOT EXISTS idx_zone_type_status_name ON zone_files(file_type, status, name(100));

-- Add index on owner field for filtering by owner
-- Check if column exists first (it may or may not exist based on previous migrations)
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_files' 
  AND COLUMN_NAME = 'owner';

-- If owner column exists, add index for it
SET @sql = IF(@col_exists > 0, 
    'CREATE INDEX IF NOT EXISTS idx_zone_owner ON zone_files(owner)',
    'SELECT ''Column owner does not exist, skipping index'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- The existing indexes from migration 006:
-- - idx_name (already exists)
-- - idx_file_type (already exists) 
-- - idx_status (already exists)
-- - idx_created_by (already exists)

-- Note: We could add a FULLTEXT index on name and filename for better search,
-- but it's not strictly necessary for the MVP and can be added later if needed.
-- Example for future reference:
-- CREATE FULLTEXT INDEX idx_zone_fulltext ON zone_files(name, filename);

-- Migration complete
SELECT 'Migration 007 completed successfully' AS status;
