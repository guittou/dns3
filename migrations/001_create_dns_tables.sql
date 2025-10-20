-- Migration 001: DNS Management Tables
-- This migration creates the necessary tables for DNS record management,
-- including roles, user roles, DNS records with history, and ACL with history.

USE dns3_db;

-- Roles table for permission management
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User roles junction table (many-to-many)
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- DNS records table with status tracking (no physical deletion)
CREATE TABLE IF NOT EXISTS dns_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    record_type ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV') NOT NULL,
    name VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    ttl INT DEFAULT 3600,
    priority INT NULL,
    status ENUM('active', 'disabled', 'deleted') DEFAULT 'active',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INT NULL,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id),
    INDEX idx_name (name),
    INDEX idx_type (record_type),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- DNS record history table (audit trail)
CREATE TABLE IF NOT EXISTS dns_record_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    record_id INT NOT NULL,
    action ENUM('created', 'updated', 'status_changed') NOT NULL,
    record_type ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV') NOT NULL,
    name VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    ttl INT,
    priority INT NULL,
    old_status ENUM('active', 'disabled', 'deleted') NULL,
    new_status ENUM('active', 'disabled', 'deleted') NOT NULL,
    changed_by INT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT NULL,
    FOREIGN KEY (record_id) REFERENCES dns_records(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id),
    INDEX idx_record_id (record_id),
    INDEX idx_action (action),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ACL entries table for access control
CREATE TABLE IF NOT EXISTS acl_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    role_id INT NULL,
    resource_type ENUM('dns_record', 'zone', 'global') NOT NULL,
    resource_id INT NULL,
    permission ENUM('read', 'write', 'delete', 'admin') NOT NULL,
    status ENUM('enabled', 'disabled') DEFAULT 'enabled',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INT NULL,
    updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id),
    INDEX idx_resource (resource_type, resource_id),
    INDEX idx_status (status),
    CONSTRAINT chk_user_or_role CHECK (user_id IS NOT NULL OR role_id IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ACL history table (audit trail)
CREATE TABLE IF NOT EXISTS acl_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    acl_id INT NOT NULL,
    action ENUM('created', 'updated', 'status_changed') NOT NULL,
    user_id INT NULL,
    role_id INT NULL,
    resource_type ENUM('dns_record', 'zone', 'global') NOT NULL,
    resource_id INT NULL,
    permission ENUM('read', 'write', 'delete', 'admin') NOT NULL,
    old_status ENUM('enabled', 'disabled') NULL,
    new_status ENUM('enabled', 'disabled') NOT NULL,
    changed_by INT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT NULL,
    FOREIGN KEY (acl_id) REFERENCES acl_entries(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id),
    INDEX idx_acl_id (acl_id),
    INDEX idx_action (action),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default roles
INSERT INTO roles (name, description) VALUES 
    ('admin', 'Administrator with full access'),
    ('user', 'Regular user with limited access')
ON DUPLICATE KEY UPDATE description=VALUES(description);

-- Assign admin role to the default admin user (id=1)
INSERT INTO user_roles (user_id, role_id)
SELECT 1, id FROM roles WHERE name = 'admin'
ON DUPLICATE KEY UPDATE user_id=user_id;
