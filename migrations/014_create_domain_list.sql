-- Migration 014: Create Domain List Table
-- This migration creates a table to manage domains attached to zone files

USE dns3_db;

-- Create domaine_list table
CREATE TABLE IF NOT EXISTS domaine_list (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(255) NOT NULL COMMENT 'Domain name',
    zone_file_id INT NOT NULL COMMENT 'Associated zone file (must be type master)',
    created_by INT NULL COMMENT 'User who created the domain',
    updated_by INT NULL COMMENT 'User who last updated the domain',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active', 'deleted') DEFAULT 'active' COMMENT 'Domain status',
    
    -- Indexes
    UNIQUE KEY ux_domain (domain),
    INDEX idx_zone_file_id (zone_file_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    
    -- Foreign key constraints
    CONSTRAINT fk_domaine_list_zone_file 
        FOREIGN KEY (zone_file_id) 
        REFERENCES zone_files(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_domaine_list_created_by 
        FOREIGN KEY (created_by) 
        REFERENCES users(id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_domaine_list_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES users(id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
