-- Migration 006: Create Zone Files, Applications, and Add Zone Reference to DNS Records
-- This migration creates the zone_files and applications tables and adds zone_file_id to dns_records.
-- It is idempotent and can be run multiple times safely.

USE dns3_db;

-- Create zone_files table if it doesn't exist
CREATE TABLE IF NOT EXISTS zone_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE COMMENT 'Zone name (e.g., example.com)',
    filename VARCHAR(255) NOT NULL COMMENT 'Zone file name',
    content MEDIUMTEXT NULL COMMENT 'Zone file content',
    file_type ENUM('master', 'include') NOT NULL DEFAULT 'master' COMMENT 'Type of zone file',
    status ENUM('active', 'inactive', 'deleted') DEFAULT 'active' COMMENT 'Zone status',
    created_by INT NULL,
    updated_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_file_type (file_type),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create zone_file_includes table for recursive parent/include relationships
CREATE TABLE IF NOT EXISTS zone_file_includes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL COMMENT 'ID of parent zone file (can be master or include)',
    include_id INT NOT NULL COMMENT 'ID of include zone file',
    position INT DEFAULT 0 COMMENT 'Order position for includes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_parent_include (parent_id, include_id),
    FOREIGN KEY (parent_id) REFERENCES zone_files(id) ON DELETE CASCADE,
    FOREIGN KEY (include_id) REFERENCES zone_files(id) ON DELETE CASCADE,
    INDEX idx_parent_id (parent_id),
    INDEX idx_include_id (include_id),
    INDEX idx_position (position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create applications table
CREATE TABLE IF NOT EXISTS applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE COMMENT 'Application name',
    description TEXT NULL COMMENT 'Application description',
    owner VARCHAR(255) NULL COMMENT 'Application owner',
    zone_file_id INT NOT NULL COMMENT 'Associated zone file',
    status ENUM('active', 'inactive', 'deleted') DEFAULT 'active' COMMENT 'Application status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE RESTRICT,
    INDEX idx_name (name),
    INDEX idx_zone_file_id (zone_file_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create zone_file_history table for audit trail
CREATE TABLE IF NOT EXISTS zone_file_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zone_file_id INT NOT NULL COMMENT 'ID of the zone file',
    action ENUM('created', 'updated', 'status_changed', 'content_changed') NOT NULL,
    name VARCHAR(255) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_type ENUM('master', 'include') NOT NULL,
    old_status ENUM('active', 'inactive', 'deleted') NULL,
    new_status ENUM('active', 'inactive', 'deleted') NOT NULL,
    old_content MEDIUMTEXT NULL COMMENT 'Previous zone file content',
    new_content MEDIUMTEXT NULL COMMENT 'New zone file content',
    changed_by INT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT NULL,
    FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_zone_file_id (zone_file_id),
    INDEX idx_action (action),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add zone_file_id column to dns_records if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND COLUMN_NAME = 'zone_file_id';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_records ADD COLUMN zone_file_id INT NULL COMMENT ''Associated zone file'' AFTER id',
    'SELECT ''Column zone_file_id already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index on zone_file_id
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_records' 
  AND INDEX_NAME = 'idx_zone_file_id';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_zone_file_id ON dns_records(zone_file_id)',
    'SELECT ''Index idx_zone_file_id already exists'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add foreign key constraint on dns_records.zone_file_id (commented out for flexibility)
-- Uncomment if you want to enforce referential integrity:
-- SET @fk_exists = 0;
-- SELECT COUNT(*) INTO @fk_exists 
-- FROM information_schema.TABLE_CONSTRAINTS 
-- WHERE TABLE_SCHEMA = 'dns3_db' 
--   AND TABLE_NAME = 'dns_records' 
--   AND CONSTRAINT_NAME = 'fk_dns_records_zone_file';
-- 
-- SET @sql = IF(@fk_exists = 0, 
--     'ALTER TABLE dns_records ADD CONSTRAINT fk_dns_records_zone_file FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE SET NULL',
--     'SELECT ''Foreign key fk_dns_records_zone_file already exists'' AS info');
-- PREPARE stmt FROM @sql;
-- EXECUTE stmt;
-- DEALLOCATE PREPARE stmt;

-- Add zone_file_id to dns_record_history if it doesn't exist
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'dns_record_history' 
  AND COLUMN_NAME = 'zone_file_id';

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE dns_record_history ADD COLUMN zone_file_id INT NULL AFTER record_id',
    'SELECT ''Column zone_file_id already exists in history'' AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Notes:
-- 1. zone_file_id in dns_records is NULLABLE for migration purposes
-- 2. API validation will require zone_file_id for new records
-- 3. Foreign key constraint is commented out but can be enabled if desired
-- 4. All tables include proper indexes for query performance
-- 5. Migration is idempotent - can be run multiple times safely

-- End of migration 006
