-- ==============================================================================
-- DNS Record Types Migration: ENUM to VARCHAR(50)
-- Version: 001
-- Date: 2025-12-05
-- Description: Migrate dns_records.record_type from ENUM to VARCHAR(50) and
--              add structured columns for advanced record types (SRV, TLSA,
--              SSHFP, CAA, NAPTR, SVCB/HTTPS, NS, DNAME, LOC, RP)
-- ==============================================================================

-- IMPORTANT: Backup your database before running this migration!
-- mysqldump -u user -p dns3_db > dns3_db_backup_before_migration.sql

-- ==============================================================================
-- STEP 1: Create the record_types reference table (optional but recommended)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS `record_types` (
    `name` VARCHAR(50) NOT NULL PRIMARY KEY,
    `category` VARCHAR(50) DEFAULT 'other' COMMENT 'Category for UI grouping (pointing, extended, mail)',
    `description` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert standard record types with categories
INSERT IGNORE INTO `record_types` (`name`, `category`, `description`) VALUES
-- Pointing records (Champs de pointage)
('A', 'pointing', 'IPv4 address record'),
('AAAA', 'pointing', 'IPv6 address record'),
('NS', 'pointing', 'Name server record'),
('CNAME', 'pointing', 'Canonical name (alias) record'),
('DNAME', 'pointing', 'Delegation name record'),
-- Extended records (Champs étendus)
('CAA', 'extended', 'Certification Authority Authorization'),
('TXT', 'extended', 'Text record'),
('NAPTR', 'extended', 'Naming Authority Pointer'),
('SRV', 'extended', 'Service location record'),
('LOC', 'extended', 'Location record'),
('SSHFP', 'extended', 'SSH Fingerprint record'),
('TLSA', 'extended', 'DANE TLS Association record'),
('RP', 'extended', 'Responsible Person record'),
('SVCB', 'extended', 'Service Binding record'),
('HTTPS', 'extended', 'HTTPS Service Binding record'),
-- Mail records (Champs mails)
('MX', 'mail', 'Mail exchange record'),
('SPF', 'mail', 'Sender Policy Framework (stored as TXT)'),
('DKIM', 'mail', 'DomainKeys Identified Mail (stored as TXT)'),
('DMARC', 'mail', 'Domain-based Message Authentication (stored as TXT)'),
-- Other standard types
('PTR', 'other', 'Pointer record (reverse DNS)'),
('SOA', 'other', 'Start of Authority record');

-- ==============================================================================
-- STEP 2: Add new record_type_new column as VARCHAR(50)
-- ==============================================================================
-- Check if the column already exists before adding
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'record_type_new');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `record_type_new` VARCHAR(50) NULL AFTER `record_type`',
    'SELECT "Column record_type_new already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==============================================================================
-- STEP 3: Copy data from ENUM column to new VARCHAR column
-- ==============================================================================
UPDATE `dns_records` SET `record_type_new` = `record_type` WHERE `record_type_new` IS NULL;

-- ==============================================================================
-- STEP 4: Add new structured columns for advanced record types
-- ==============================================================================

-- SRV record columns (port, weight already exist; ensure they exist)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'port');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `port` INT NULL COMMENT "Port number for SRV records"',
    'SELECT "Column port already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'weight');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `weight` INT NULL COMMENT "Weight for SRV records"',
    'SELECT "Column weight already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'srv_target');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `srv_target` VARCHAR(255) NULL COMMENT "Target hostname for SRV records"',
    'SELECT "Column srv_target already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- TLSA record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'tlsa_usage');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `tlsa_usage` TINYINT NULL COMMENT "TLSA certificate usage (0-3)"',
    'SELECT "Column tlsa_usage already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'tlsa_selector');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `tlsa_selector` TINYINT NULL COMMENT "TLSA selector (0=full cert, 1=SubjectPublicKeyInfo)"',
    'SELECT "Column tlsa_selector already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'tlsa_matching');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `tlsa_matching` TINYINT NULL COMMENT "TLSA matching type (0=exact, 1=SHA256, 2=SHA512)"',
    'SELECT "Column tlsa_matching already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'tlsa_data');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `tlsa_data` TEXT NULL COMMENT "TLSA certificate association data (hex)"',
    'SELECT "Column tlsa_data already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- SSHFP record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'sshfp_algo');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `sshfp_algo` TINYINT NULL COMMENT "SSHFP algorithm (1=RSA, 2=DSA, 3=ECDSA, 4=Ed25519)"',
    'SELECT "Column sshfp_algo already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'sshfp_type');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `sshfp_type` TINYINT NULL COMMENT "SSHFP fingerprint type (1=SHA1, 2=SHA256)"',
    'SELECT "Column sshfp_type already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'sshfp_fingerprint');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `sshfp_fingerprint` TEXT NULL COMMENT "SSHFP fingerprint (hex)"',
    'SELECT "Column sshfp_fingerprint already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- CAA record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'caa_flag');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `caa_flag` TINYINT NULL COMMENT "CAA critical flag (0 or 128)"',
    'SELECT "Column caa_flag already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'caa_tag');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `caa_tag` VARCHAR(32) NULL COMMENT "CAA tag (issue, issuewild, iodef)"',
    'SELECT "Column caa_tag already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'caa_value');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `caa_value` TEXT NULL COMMENT "CAA value (e.g., letsencrypt.org)"',
    'SELECT "Column caa_value already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- NAPTR record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_order');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_order` INT NULL COMMENT "NAPTR order (lower = higher priority)"',
    'SELECT "Column naptr_order already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_pref');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_pref` INT NULL COMMENT "NAPTR preference (lower = higher priority)"',
    'SELECT "Column naptr_pref already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_flags');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_flags` VARCHAR(16) NULL COMMENT "NAPTR flags (e.g., U, S, A)"',
    'SELECT "Column naptr_flags already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_service');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_service` VARCHAR(64) NULL COMMENT "NAPTR service (e.g., E2U+sip)"',
    'SELECT "Column naptr_service already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_regexp');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_regexp` TEXT NULL COMMENT "NAPTR regexp substitution expression"',
    'SELECT "Column naptr_regexp already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'naptr_replacement');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `naptr_replacement` VARCHAR(255) NULL COMMENT "NAPTR replacement domain"',
    'SELECT "Column naptr_replacement already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- SVCB/HTTPS record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'svc_priority');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `svc_priority` INT NULL COMMENT "SVCB/HTTPS priority (0=AliasMode)"',
    'SELECT "Column svc_priority already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'svc_target');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `svc_target` VARCHAR(255) NULL COMMENT "SVCB/HTTPS target name"',
    'SELECT "Column svc_target already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'svc_params');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `svc_params` TEXT NULL COMMENT "SVCB/HTTPS params (JSON or key=value pairs)"',
    'SELECT "Column svc_params already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- NS target column
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'ns_target');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `ns_target` VARCHAR(255) NULL COMMENT "NS record target nameserver"',
    'SELECT "Column ns_target already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- MX target column (separate from value for structured access)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'mx_target');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `mx_target` VARCHAR(255) NULL COMMENT "MX record target mail server"',
    'SELECT "Column mx_target already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- DNAME target column
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'dname_target');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `dname_target` VARCHAR(255) NULL COMMENT "DNAME record target"',
    'SELECT "Column dname_target already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- RP record columns (Responsible Person)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'rp_mbox');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `rp_mbox` VARCHAR(255) NULL COMMENT "RP mailbox (email as domain)"',
    'SELECT "Column rp_mbox already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'rp_txt');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `rp_txt` VARCHAR(255) NULL COMMENT "RP TXT domain reference"',
    'SELECT "Column rp_txt already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- LOC record columns
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'loc_latitude');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `loc_latitude` VARCHAR(50) NULL COMMENT "LOC latitude"',
    'SELECT "Column loc_latitude already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'loc_longitude');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `loc_longitude` VARCHAR(50) NULL COMMENT "LOC longitude"',
    'SELECT "Column loc_longitude already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'loc_altitude');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `loc_altitude` VARCHAR(50) NULL COMMENT "LOC altitude"',
    'SELECT "Column loc_altitude already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Generic fallback column for complex/custom data (JSON)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_records' 
                   AND COLUMN_NAME = 'rdata_json');
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_records` ADD COLUMN `rdata_json` TEXT NULL COMMENT "JSON storage for complex record data"',
    'SELECT "Column rdata_json already exists" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==============================================================================
-- STEP 5: Make record_type_new NOT NULL after data copy
-- ==============================================================================
-- Verify all records have been copied
SELECT COUNT(*) AS records_without_new_type FROM dns_records WHERE record_type_new IS NULL;

-- Only proceed if count is 0
ALTER TABLE `dns_records` MODIFY COLUMN `record_type_new` VARCHAR(50) NOT NULL;

-- ==============================================================================
-- STEP 6: Swap columns - Drop old ENUM column and rename new column
-- NOTE: This is a destructive operation. Ensure backup is complete!
-- ==============================================================================

-- Drop the old ENUM column
ALTER TABLE `dns_records` DROP COLUMN `record_type`;

-- Rename the new column
ALTER TABLE `dns_records` CHANGE COLUMN `record_type_new` `record_type` VARCHAR(50) NOT NULL;

-- Recreate the index on record_type
CREATE INDEX `idx_type` ON `dns_records` (`record_type`);

-- ==============================================================================
-- STEP 7: Update dns_record_history table to use VARCHAR as well
-- ==============================================================================
-- Add new column
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'dns_record_history' 
                   AND COLUMN_NAME = 'record_type_new');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `dns_record_history` ADD COLUMN `record_type_new` VARCHAR(50) NULL AFTER `record_type`',
    'SELECT "Column record_type_new already exists in dns_record_history" AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Copy data
UPDATE `dns_record_history` SET `record_type_new` = `record_type` WHERE `record_type_new` IS NULL;

-- Make NOT NULL
ALTER TABLE `dns_record_history` MODIFY COLUMN `record_type_new` VARCHAR(50) NOT NULL;

-- Drop old column and rename
ALTER TABLE `dns_record_history` DROP COLUMN `record_type`;
ALTER TABLE `dns_record_history` CHANGE COLUMN `record_type_new` `record_type` VARCHAR(50) NOT NULL;

-- ==============================================================================
-- STEP 8: Add indexes for new columns (for common query patterns)
-- ==============================================================================
CREATE INDEX `idx_srv_target` ON `dns_records` (`srv_target`);
CREATE INDEX `idx_mx_target` ON `dns_records` (`mx_target`);
CREATE INDEX `idx_ns_target` ON `dns_records` (`ns_target`);

-- ==============================================================================
-- VERIFICATION QUERIES (run these to verify migration success)
-- ==============================================================================
-- Check record_type is now VARCHAR
-- SHOW COLUMNS FROM dns_records LIKE 'record_type';

-- Check new columns exist
-- SHOW COLUMNS FROM dns_records;

-- Verify record_types table
-- SELECT * FROM record_types ORDER BY category, name;

-- Count records by type
-- SELECT record_type, COUNT(*) as count FROM dns_records GROUP BY record_type ORDER BY count DESC;

-- ==============================================================================
-- Migration Complete!
-- ==============================================================================
