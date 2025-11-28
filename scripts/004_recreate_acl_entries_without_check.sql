-- Migration: Recreate acl_entries table without CHECK constraint
--
-- IMPORTANT: This script is an ALTERNATIVE to 004_drop_chk_user_or_role.sql
-- Use this script ONLY if DROP CHECK fails on your MySQL version (< 8.0.16)
--
-- This script recreates the acl_entries table without the CHECK constraint
-- by creating a new table, copying data, and swapping tables.
--
-- CAUTION: 
-- 1. Create a full backup before running this script!
--    mysqldump -u root -p dns3_db > dns3_db_backup.sql
--
-- 2. This operation should be performed during a maintenance window
--    as there may be brief data unavailability during the swap.
--
-- 3. After verification, you can drop the old table with:
--    DROP TABLE acl_entries_old;
--
-- Run with: mysql -u dns3_admin -p dns3_db < scripts/004_recreate_acl_entries_without_check.sql
--
-- Rollback: RENAME TABLE acl_entries TO acl_entries_failed, acl_entries_old TO acl_entries;

-- --------------------------------------------------------
-- Step 0: Verify we're starting with the expected state
-- --------------------------------------------------------

SELECT 'Step 0: Checking current state of acl_entries table...' AS status;

-- Show current table structure
DESCRIBE acl_entries;

-- Check if CHECK constraint exists
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';

-- --------------------------------------------------------
-- Step 1: Create new table without CHECK constraint
-- --------------------------------------------------------

SELECT 'Step 1: Creating acl_entries_new table without CHECK constraint...' AS status;

-- Drop the new table if it exists from a previous failed attempt
DROP TABLE IF EXISTS acl_entries_new;

-- Create new table with same structure but NO CHECK constraint
CREATE TABLE acl_entries_new (
    id INT AUTO_INCREMENT PRIMARY KEY,
    resource_type VARCHAR(50) NULL COMMENT 'Legacy: Type of resource (zone, etc.)',
    resource_id INT NULL COMMENT 'Legacy: ID of the resource',
    zone_file_id INT NULL COMMENT 'Reference to zone_files.id for zone ACL entries',
    subject_type ENUM('user','role','ad_group') NULL COMMENT 'Type of ACL subject',
    subject_identifier VARCHAR(255) NULL COMMENT 'User ID/username, role name, or AD group DN',
    user_id INT NULL COMMENT 'Legacy: Reference to users.id',
    role_id INT NULL COMMENT 'Legacy: Reference to roles.id',
    permission ENUM('read','write','admin','delete') NOT NULL DEFAULT 'read' COMMENT 'Permission level',
    status ENUM('enabled','disabled') NOT NULL DEFAULT 'enabled' COMMENT 'ACL entry status',
    created_by INT NULL COMMENT 'User who created this entry',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation timestamp',
    
    -- Indexes for performance
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_zone_file_id (zone_file_id),
    INDEX idx_acl_subject (subject_type, subject_identifier(191)),
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id),
    
    -- Foreign key constraints (optional, depends on your setup)
    -- CONSTRAINT fk_acl_zone_file FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE CASCADE,
    -- CONSTRAINT fk_acl_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    -- CONSTRAINT fk_acl_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    -- CONSTRAINT fk_acl_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
    
    -- NOTE: No CHECK constraint! This is the key difference.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'New table created successfully.' AS status;

-- --------------------------------------------------------
-- Step 2: Copy all data from old table to new table
-- --------------------------------------------------------

SELECT 'Step 2: Copying data from acl_entries to acl_entries_new...' AS status;

INSERT INTO acl_entries_new 
    (id, resource_type, resource_id, zone_file_id, subject_type, subject_identifier,
     user_id, role_id, permission, status, created_by, created_at)
SELECT 
    id, resource_type, resource_id, zone_file_id, subject_type, subject_identifier,
    user_id, role_id, permission, status, created_by, created_at
FROM acl_entries;

-- Verify row count matches
SELECT 
    (SELECT COUNT(*) FROM acl_entries) AS old_count,
    (SELECT COUNT(*) FROM acl_entries_new) AS new_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM acl_entries) = (SELECT COUNT(*) FROM acl_entries_new) 
        THEN 'OK - Row counts match'
        ELSE 'WARNING - Row counts do NOT match!'
    END AS verification;

-- --------------------------------------------------------
-- Step 3: Swap tables (atomic operation)
-- --------------------------------------------------------

SELECT 'Step 3: Swapping tables (renaming)...' AS status;

-- Atomic rename: old -> _old, new -> current
RENAME TABLE 
    acl_entries TO acl_entries_old,
    acl_entries_new TO acl_entries;

SELECT 'Tables swapped successfully.' AS status;

-- --------------------------------------------------------
-- Step 4: Recreate the zone_acl_entries view
-- --------------------------------------------------------

SELECT 'Step 4: Recreating zone_acl_entries view...' AS status;

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

SELECT 'View recreated successfully.' AS status;

-- --------------------------------------------------------
-- Step 5: Verify the migration
-- --------------------------------------------------------

SELECT 'Step 5: Verification...' AS status;

-- Confirm no CHECK constraint exists on new table
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS: No CHECK constraint on acl_entries'
        ELSE 'ERROR: CHECK constraint still exists'
    END AS check_constraint_status
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';

-- Show new table structure
SELECT 'New table structure:' AS info;
DESCRIBE acl_entries;

-- Show indexes
SELECT 'Indexes on acl_entries:' AS info;
SHOW INDEX FROM acl_entries;

-- Sample data verification
SELECT 'Sample data from acl_entries (first 5 rows):' AS info;
SELECT * FROM acl_entries LIMIT 5;

-- Old table is preserved
SELECT 'Old table acl_entries_old row count:' AS info;
SELECT COUNT(*) AS old_table_rows FROM acl_entries_old;

-- --------------------------------------------------------
-- Step 6: Final instructions
-- --------------------------------------------------------

SELECT 'Migration completed successfully!' AS status;
SELECT 'IMPORTANT: The old table is preserved as acl_entries_old.' AS note;
SELECT 'After verifying the application works correctly, you can drop it with:' AS instruction;
SELECT '  DROP TABLE acl_entries_old;' AS command;
