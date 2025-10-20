-- Migration 003: Add/Update DNS Metadata Fields
-- This migration ensures all business metadata fields are present in dns_records table
-- with proper indexes for performance.
-- The migration is idempotent - it only adds columns if they don't exist.

USE dns3_db;

-- Add requester column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'requester';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN requester VARCHAR(255) DEFAULT NULL COMMENT ''Person or system requesting this DNS record'' AFTER priority',
    'SELECT ''Column requester already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add expires_at column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'expires_at';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN expires_at DATETIME NULL COMMENT ''Expiration date for temporary records'' AFTER updated_at',
    'SELECT ''Column expires_at already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add ticket_ref column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'ticket_ref';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN ticket_ref VARCHAR(255) DEFAULT NULL COMMENT ''Reference to ticket system (JIRA, ServiceNow, etc.)'' AFTER expires_at',
    'SELECT ''Column ticket_ref already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add comment column if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'comment';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN comment TEXT DEFAULT NULL COMMENT ''Additional notes or comments about this record'' AFTER ticket_ref',
    'SELECT ''Column comment already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add last_seen column if it doesn't exist (server-managed only)
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'last_seen';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN last_seen DATETIME NULL COMMENT ''Last time this record was viewed (server-managed)'' AFTER comment',
    'SELECT ''Column last_seen already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure created_at exists with proper default (NOT NULL DEFAULT CURRENT_TIMESTAMP)
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'created_at';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER created_by',
    'SELECT ''Column created_at already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure updated_at exists with proper default (NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'updated_at';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    'SELECT ''Column updated_at already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create index on expires_at if it doesn't exist (for finding expiring records)
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_expires_at';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_expires_at ON dns_records(expires_at)',
    'SELECT ''Index idx_expires_at already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create index on ticket_ref if it doesn't exist (for searching by ticket)
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_ticket_ref';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_ticket_ref ON dns_records(ticket_ref)',
    'SELECT ''Index idx_ticket_ref already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Notes:
-- 1. All datetime fields use DATETIME instead of TIMESTAMP for better timezone handling
-- 2. last_seen is managed exclusively by the server and should never be set by client
-- 3. expires_at can be NULL for permanent records
-- 4. requester and ticket_ref are VARCHAR(255) for reasonable length
-- 5. comment is TEXT for longer notes
-- 6. Indexes on expires_at and ticket_ref improve query performance

-- End of migration 003
