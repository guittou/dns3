-- Migration: Migrate ACL schema for zone-specific ACL support
-- This migration modifies the existing acl_entries table to add zone ACL columns
-- and creates a view for compatibility with existing code.
--
-- Context: Production has acl_entries with resource_type/resource_id schema.
--          Code expects zone_file_id/subject_type/subject_identifier columns.
--
-- IMPORTANT: This script should be run by a DBA with CREATE/ALTER/DROP privileges.
-- RECOMMENDATION: Create a backup (mysqldump) before running this migration.
--
-- Run with: mysql -u dns3_user -p dns3_db < scripts/003_migrate_acl_schema.sql
--
-- Rollback: Old columns (user_id, role_id, resource_type, resource_id) are preserved.
--           To rollback, drop the new columns and the view.
--
-- What this migration does:
-- 1. Adds zone_file_id, subject_type, subject_identifier columns if absent
-- 2. Migrates existing zone ACL data (resource_type='zone')
-- 3. Maps 'delete' permission -> 'admin'
-- 4. Normalizes all subject_identifier values to lowercase
-- 5. Creates indexes on zone_file_id and (subject_type, subject_identifier(191))
-- 6. Drops the CHECK constraint chk_user_or_role if it exists
-- 7. Creates zone_acl_entries view for code compatibility

-- --------------------------------------------------------
-- 1. Add new columns to acl_entries table if they don't exist
-- --------------------------------------------------------

-- Add zone_file_id column (for zone-specific ACL entries)
SET @zone_file_id_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND COLUMN_NAME = 'zone_file_id'
);

SET @sql = IF(@zone_file_id_exists = 0, 
    'ALTER TABLE acl_entries ADD COLUMN zone_file_id INT NULL COMMENT ''Reference to zone_files.id for zone ACL entries'' AFTER resource_id',
    'SELECT ''Column zone_file_id already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add subject_type column (type of ACL subject)
SET @subject_type_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND COLUMN_NAME = 'subject_type'
);

SET @sql = IF(@subject_type_exists = 0, 
    'ALTER TABLE acl_entries ADD COLUMN subject_type ENUM(''user'',''role'',''ad_group'') NULL COMMENT ''Type of ACL subject'' AFTER zone_file_id',
    'SELECT ''Column subject_type already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add subject_identifier column (username, role name, or AD group DN)
SET @subject_identifier_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND COLUMN_NAME = 'subject_identifier'
);

SET @sql = IF(@subject_identifier_exists = 0, 
    'ALTER TABLE acl_entries ADD COLUMN subject_identifier VARCHAR(255) NULL COMMENT ''User ID/username, role name, or AD group DN'' AFTER subject_type',
    'SELECT ''Column subject_identifier already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- --------------------------------------------------------
-- 2. Create indexes on new columns (if they don't exist)
-- --------------------------------------------------------

-- Index on zone_file_id
SET @idx_zone_file_id_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND INDEX_NAME = 'idx_zone_file_id'
);

SET @sql = IF(@idx_zone_file_id_exists = 0, 
    'ALTER TABLE acl_entries ADD INDEX idx_zone_file_id (zone_file_id)',
    'SELECT ''Index idx_zone_file_id already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index on subject_type and subject_identifier
SET @idx_subject_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND INDEX_NAME = 'idx_acl_subject'
);

SET @sql = IF(@idx_subject_exists = 0, 
    'ALTER TABLE acl_entries ADD INDEX idx_acl_subject (subject_type, subject_identifier(191))',
    'SELECT ''Index idx_acl_subject already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- --------------------------------------------------------
-- 3. Migrate existing zone ACL data (resource_type = 'zone')
-- --------------------------------------------------------

-- First, let's log what we're about to migrate
SELECT 'Starting data migration for zone ACL entries...' AS status;
SELECT COUNT(*) AS zone_acl_entries_to_migrate 
FROM acl_entries 
WHERE resource_type = 'zone' 
AND (zone_file_id IS NULL OR subject_type IS NULL);

-- Update zone_file_id from resource_id for zone type entries
UPDATE acl_entries 
SET zone_file_id = resource_id 
WHERE resource_type = 'zone' 
AND zone_file_id IS NULL 
AND resource_id IS NOT NULL;

-- Update subject_type and subject_identifier for user-based ACL entries
-- Join with users table to get username (stored as lowercase for consistency)
UPDATE acl_entries ae
LEFT JOIN users u ON ae.user_id = u.id
SET 
    ae.subject_type = 'user',
    ae.subject_identifier = LOWER(COALESCE(u.username, CAST(ae.user_id AS CHAR)))
WHERE ae.resource_type = 'zone' 
AND ae.user_id IS NOT NULL 
AND ae.subject_type IS NULL;

-- Update subject_type and subject_identifier for role-based ACL entries
-- Join with roles table to get role name
UPDATE acl_entries ae
LEFT JOIN roles r ON ae.role_id = r.id
SET 
    ae.subject_type = 'role',
    ae.subject_identifier = COALESCE(r.name, CAST(ae.role_id AS CHAR))
WHERE ae.resource_type = 'zone' 
AND ae.role_id IS NOT NULL 
AND ae.subject_type IS NULL;

-- Map 'delete' permission to 'admin' if needed (delete implies admin rights)
UPDATE acl_entries 
SET permission = 'admin' 
WHERE permission = 'delete' 
AND resource_type = 'zone';

-- --------------------------------------------------------
-- 4. Normalize all subject_identifier values to lowercase
-- --------------------------------------------------------
-- This ensures case-insensitive comparisons work correctly

SELECT 'Normalizing subject_identifier to lowercase...' AS status;

UPDATE acl_entries 
SET subject_identifier = LOWER(subject_identifier) 
WHERE subject_identifier IS NOT NULL 
AND subject_identifier != LOWER(subject_identifier);

SELECT 'Subject identifiers normalized.' AS status;

-- --------------------------------------------------------
-- 5. Drop CHECK constraint chk_user_or_role (if exists)
-- --------------------------------------------------------
-- The new schema allows entries without user_id or role_id
-- (using subject_type and subject_identifier instead)
-- 
-- Note: MySQL 8.0.16+ supports DROP CHECK directly.
-- For older versions, the constraint may need to be removed differently.

SELECT 'Attempting to drop CHECK constraint chk_user_or_role...' AS status;

-- Try to drop the CHECK constraint (MySQL 8.0.16+)
-- This may fail silently on older MySQL versions
SET @check_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND CONSTRAINT_NAME = 'chk_user_or_role'
    AND CONSTRAINT_TYPE = 'CHECK'
);

SET @sql = IF(@check_exists > 0, 
    'ALTER TABLE acl_entries DROP CHECK chk_user_or_role',
    'SELECT ''CHECK constraint chk_user_or_role does not exist or already removed'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verify CHECK constraint was removed
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'CHECK constraint chk_user_or_role successfully removed or not present'
        ELSE 'WARNING: CHECK constraint chk_user_or_role still exists'
    END AS constraint_status
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';

-- --------------------------------------------------------
-- 6. Create or replace zone_acl_entries view
-- --------------------------------------------------------
-- This view provides compatibility for code that references zone_acl_entries
-- It filters to only show zone-type ACL entries with the expected columns

CREATE OR REPLACE VIEW `zone_acl_entries` AS
SELECT
    `id`,
    `zone_file_id`,
    `subject_type`,
    `subject_identifier`,
    `permission`,
    `created_by`,
    `created_at`
FROM `acl_entries`
WHERE `zone_file_id` IS NOT NULL 
  AND `subject_type` IS NOT NULL 
  AND `subject_identifier` IS NOT NULL;

-- --------------------------------------------------------
-- 7. Log migration results
-- --------------------------------------------------------
SELECT 'Data migration completed.' AS status;
SELECT COUNT(*) AS migrated_entries 
FROM acl_entries 
WHERE resource_type = 'zone' 
AND zone_file_id IS NOT NULL 
AND subject_type IS NOT NULL;

-- --------------------------------------------------------
-- 8. Verify migration success
-- --------------------------------------------------------
SELECT 'Migration completed. Verification:' AS status;

-- Show view structure
SHOW CREATE VIEW zone_acl_entries;

-- Show sample data
SELECT 'Sample zone_acl_entries data:' AS info;
SELECT * FROM zone_acl_entries LIMIT 5;

-- Show column structure
SELECT 'New columns added to acl_entries:' AS info;
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND COLUMN_NAME IN ('zone_file_id', 'subject_type', 'subject_identifier')
ORDER BY ORDINAL_POSITION;

-- Show indexes
SELECT 'New indexes on acl_entries:' AS info;
SELECT INDEX_NAME, COLUMN_NAME 
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND INDEX_NAME IN ('idx_zone_file_id', 'idx_acl_subject');

-- Verify CHECK constraint status
SELECT 'CHECK constraint status:' AS info;
SELECT COUNT(*) AS check_constraint_count
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';
