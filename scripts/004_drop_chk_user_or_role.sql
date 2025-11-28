-- Migration: Drop CHECK constraint chk_user_or_role from acl_entries table
--
-- IMPORTANT: This script MUST be run by a DBA with ALTER TABLE privileges.
-- RECOMMENDATION: Create a backup (mysqldump) before running this migration.
--
-- Context: 
--   The acl_entries table was originally designed with a CHECK constraint
--   that required either user_id or role_id to be NOT NULL. The new schema
--   uses zone_file_id/subject_type/subject_identifier columns, which allows
--   entries where both user_id and role_id are NULL.
--
-- Run with: mysql -u dns3_admin -p dns3_db < scripts/004_drop_chk_user_or_role.sql
--
-- Rollback:
--   ALTER TABLE acl_entries ADD CONSTRAINT chk_user_or_role 
--     CHECK (user_id IS NOT NULL OR role_id IS NOT NULL);
--
-- Compatibility:
--   - MySQL 8.0.16+: Uses ALTER TABLE ... DROP CHECK directly
--   - MySQL < 8.0.16: May require table recreation (see alternative method below)
--   - MariaDB 10.2+: Uses ALTER TABLE ... DROP CONSTRAINT

-- --------------------------------------------------------
-- Check if constraint exists before attempting to drop
-- --------------------------------------------------------

SELECT 'Checking for CHECK constraint chk_user_or_role...' AS status;

SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';

-- --------------------------------------------------------
-- Method 1: Direct DROP CHECK (MySQL 8.0.16+ / MariaDB 10.2+)
-- --------------------------------------------------------

-- Try to drop the CHECK constraint
-- This may fail on older MySQL versions that don't support DROP CHECK

DELIMITER //

CREATE PROCEDURE drop_chk_user_or_role_if_exists()
BEGIN
    DECLARE constraint_exists INT DEFAULT 0;
    DECLARE drop_failed INT DEFAULT 0;
    
    -- Check if constraint exists
    SELECT COUNT(*) INTO constraint_exists 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'acl_entries' 
    AND CONSTRAINT_NAME = 'chk_user_or_role';
    
    IF constraint_exists > 0 THEN
        -- Try MySQL 8.0.16+ syntax first
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET drop_failed = 1;
            
            SET @drop_sql = 'ALTER TABLE acl_entries DROP CHECK chk_user_or_role';
            PREPARE stmt FROM @drop_sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END;
        
        -- If MySQL syntax failed, try MariaDB syntax
        IF drop_failed = 1 THEN
            SET drop_failed = 0;
            BEGIN
                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET drop_failed = 1;
                
                SET @drop_sql = 'ALTER TABLE acl_entries DROP CONSTRAINT chk_user_or_role';
                PREPARE stmt FROM @drop_sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END;
        END IF;
        
        IF drop_failed = 0 THEN
            SELECT 'CHECK constraint chk_user_or_role dropped successfully.' AS result;
        ELSE
            SELECT 'Failed to drop CHECK constraint. Manual intervention may be required.' AS result;
        END IF;
    ELSE
        SELECT 'CHECK constraint chk_user_or_role does not exist or already removed.' AS result;
    END IF;
END //

DELIMITER ;

-- Execute the procedure
CALL drop_chk_user_or_role_if_exists();

-- Clean up
DROP PROCEDURE IF EXISTS drop_chk_user_or_role_if_exists;

-- --------------------------------------------------------
-- Verify constraint removal
-- --------------------------------------------------------

SELECT 'Verification - CHECK constraint status after removal:' AS status;

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS: CHECK constraint chk_user_or_role removed'
        ELSE 'WARNING: CHECK constraint chk_user_or_role still exists'
    END AS final_status
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'acl_entries' 
AND CONSTRAINT_NAME = 'chk_user_or_role';

-- --------------------------------------------------------
-- Alternative Method (for MySQL < 8.0.16):
-- If the above fails, use this table recreation approach
-- --------------------------------------------------------
/*
-- CAUTION: This method temporarily removes all data. Ensure you have a backup!

-- Step 1: Create temporary table with same structure (without CHECK)
CREATE TABLE acl_entries_new LIKE acl_entries;
ALTER TABLE acl_entries_new DROP CHECK chk_user_or_role;

-- Step 2: Copy all data
INSERT INTO acl_entries_new SELECT * FROM acl_entries;

-- Step 3: Rename tables (atomic swap)
RENAME TABLE acl_entries TO acl_entries_old, acl_entries_new TO acl_entries;

-- Step 4: After verification, drop old table
-- DROP TABLE acl_entries_old;
*/
