-- ==============================================================================
-- DNS Record Types Rollback: VARCHAR(50) back to ENUM
-- Version: 001-rollback
-- Date: 2025-12-05
-- Description: Rollback migration - convert record_type from VARCHAR(50) back 
--              to original ENUM type. Use this if migration causes issues.
-- ==============================================================================

-- IMPORTANT: This rollback will LOSE any records created with new extended types
-- that were not part of the original ENUM. Back up your database first!
-- mysqldump -u user -p dns3_db > dns3_db_backup_before_rollback.sql

-- ==============================================================================
-- STEP 1: Identify records with extended types (will be lost if not handled)
-- ==============================================================================
-- These records use types not in the original ENUM and need manual handling
SELECT id, name, record_type, created_at 
FROM dns_records 
WHERE record_type NOT IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV');

-- OPTION A: Delete extended records (DESTRUCTIVE - uncomment if needed)
-- DELETE FROM dns_records WHERE record_type NOT IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV');

-- OPTION B: Convert extended records to TXT (safer - uncomment if needed)
-- UPDATE dns_records 
-- SET record_type = 'TXT', 
--     txt = CONCAT('ORIGINAL_TYPE:', record_type, ' ', COALESCE(value, ''))
-- WHERE record_type NOT IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV');

-- ==============================================================================
-- STEP 2: Convert dns_records.record_type back to ENUM
-- ==============================================================================

-- Add temporary column with original ENUM type
ALTER TABLE `dns_records` ADD COLUMN `record_type_enum` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NULL AFTER `record_type`;

-- Copy compatible values
UPDATE `dns_records` 
SET `record_type_enum` = `record_type` 
WHERE `record_type` IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV');

-- Check for any NULL values (records with extended types)
SELECT COUNT(*) AS incompatible_records FROM dns_records WHERE record_type_enum IS NULL;

-- If the above returns 0, proceed. Otherwise, handle those records first.

-- Make the enum column NOT NULL (will fail if there are NULLs)
ALTER TABLE `dns_records` MODIFY COLUMN `record_type_enum` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL;

-- Drop index on VARCHAR column
DROP INDEX `idx_type` ON `dns_records`;
DROP INDEX IF EXISTS `idx_srv_target` ON `dns_records`;
DROP INDEX IF EXISTS `idx_mx_target` ON `dns_records`;
DROP INDEX IF EXISTS `idx_ns_target` ON `dns_records`;

-- Drop VARCHAR column and rename ENUM column
ALTER TABLE `dns_records` DROP COLUMN `record_type`;
ALTER TABLE `dns_records` CHANGE COLUMN `record_type_enum` `record_type` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL;

-- Recreate index
CREATE INDEX `idx_type` ON `dns_records` (`record_type`);

-- ==============================================================================
-- STEP 3: Convert dns_record_history.record_type back to ENUM
-- ==============================================================================

-- Filter out incompatible history records
DELETE FROM `dns_record_history` 
WHERE `record_type` NOT IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV');

-- Add temporary column with original ENUM type
ALTER TABLE `dns_record_history` ADD COLUMN `record_type_enum` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NULL AFTER `record_type`;

-- Copy compatible values
UPDATE `dns_record_history` 
SET `record_type_enum` = `record_type`;

-- Make NOT NULL
ALTER TABLE `dns_record_history` MODIFY COLUMN `record_type_enum` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL;

-- Drop VARCHAR column and rename ENUM column
ALTER TABLE `dns_record_history` DROP COLUMN `record_type`;
ALTER TABLE `dns_record_history` CHANGE COLUMN `record_type_enum` `record_type` 
    ENUM('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL;

-- ==============================================================================
-- STEP 4: Drop extended columns (optional - keep if planning to re-migrate)
-- ==============================================================================
-- Uncomment the following lines to remove extended columns:

-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `port`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `weight`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `srv_target`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `tlsa_usage`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `tlsa_selector`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `tlsa_matching`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `tlsa_data`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `sshfp_algo`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `sshfp_type`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `sshfp_fingerprint`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `caa_flag`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `caa_tag`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `caa_value`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_order`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_pref`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_flags`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_service`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_regexp`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `naptr_replacement`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `svc_priority`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `svc_target`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `svc_params`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `ns_target`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `mx_target`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `dname_target`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `rp_mbox`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `rp_txt`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `loc_latitude`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `loc_longitude`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `loc_altitude`;
-- ALTER TABLE `dns_records` DROP COLUMN IF EXISTS `rdata_json`;

-- ==============================================================================
-- STEP 5: Drop record_types reference table (optional)
-- ==============================================================================
-- DROP TABLE IF EXISTS `record_types`;

-- ==============================================================================
-- VERIFICATION
-- ==============================================================================
-- SHOW COLUMNS FROM dns_records LIKE 'record_type';
-- Expected: enum('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV')

-- ==============================================================================
-- Rollback Complete!
-- ==============================================================================
