-- Migration 005: Add Type-Specific Fields for DNS Records
-- This migration adds dedicated columns for each DNS record type (A, AAAA, CNAME, PTR, TXT)
-- instead of using the generic 'value' field. The 'value' column is kept temporarily for
-- rollback capability. The migration is idempotent.

USE dns3_db;

-- Add address_ipv4 column for A records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'address_ipv4';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN address_ipv4 VARCHAR(15) NULL COMMENT ''IPv4 address for A records'' AFTER value',
    'SELECT ''Column address_ipv4 already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add address_ipv6 column for AAAA records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'address_ipv6';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN address_ipv6 VARCHAR(45) NULL COMMENT ''IPv6 address for AAAA records'' AFTER address_ipv4',
    'SELECT ''Column address_ipv6 already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add cname_target column for CNAME records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'cname_target';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN cname_target VARCHAR(255) NULL COMMENT ''Target hostname for CNAME records'' AFTER address_ipv6',
    'SELECT ''Column cname_target already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add ptrdname column for PTR records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'ptrdname';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN ptrdname VARCHAR(255) NULL COMMENT ''Reverse DNS name for PTR records'' AFTER cname_target',
    'SELECT ''Column ptrdname already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add txt column for TXT records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'txt';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN txt TEXT NULL COMMENT ''Text content for TXT records'' AFTER ptrdname',
    'SELECT ''Column txt already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migrate existing data from value to dedicated columns
-- This is idempotent: only copies if the dedicated column is NULL

-- Migrate A records (IPv4)
UPDATE dns_records
SET address_ipv4 = value
WHERE record_type = 'A' 
  AND address_ipv4 IS NULL 
  AND value IS NOT NULL;

-- Migrate AAAA records (IPv6)
UPDATE dns_records
SET address_ipv6 = value
WHERE record_type = 'AAAA' 
  AND address_ipv6 IS NULL 
  AND value IS NOT NULL;

-- Migrate CNAME records
UPDATE dns_records
SET cname_target = value
WHERE record_type = 'CNAME' 
  AND cname_target IS NULL 
  AND value IS NOT NULL;

-- Migrate PTR records
UPDATE dns_records
SET ptrdname = value
WHERE record_type = 'PTR' 
  AND ptrdname IS NULL 
  AND value IS NOT NULL;

-- Migrate TXT records
UPDATE dns_records
SET txt = value
WHERE record_type = 'TXT' 
  AND txt IS NULL 
  AND value IS NOT NULL;

-- Add indexes for better query performance on dedicated columns
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_address_ipv4';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_address_ipv4 ON dns_records(address_ipv4)',
    'SELECT ''Index idx_address_ipv4 already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_address_ipv6';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_address_ipv6 ON dns_records(address_ipv6)',
    'SELECT ''Index idx_address_ipv6 already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_cname_target';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_cname_target ON dns_records(cname_target)',
    'SELECT ''Index idx_cname_target already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Also update dns_record_history table to include the new fields
-- Add columns to history table if they don't exist

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'address_ipv4';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN address_ipv4 VARCHAR(15) NULL AFTER value',
    'SELECT ''Column address_ipv4 already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'address_ipv6';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN address_ipv6 VARCHAR(45) NULL AFTER address_ipv4',
    'SELECT ''Column address_ipv6 already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'cname_target';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN cname_target VARCHAR(255) NULL AFTER address_ipv6',
    'SELECT ''Column cname_target already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'ptrdname';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN ptrdname VARCHAR(255) NULL AFTER cname_target',
    'SELECT ''Column ptrdname already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'txt';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN txt TEXT NULL AFTER ptrdname',
    'SELECT ''Column txt already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Notes:
-- 1. The 'value' column is KEPT for backward compatibility and rollback capability
-- 2. Migration is idempotent - columns are only added if they don't exist
-- 3. Data migration only occurs if the dedicated column is NULL
-- 4. Indexes are added for better query performance
-- 5. History table is also updated to track dedicated fields

-- End of migration 005
