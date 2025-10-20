-- Unified database.sql for DNS3
-- This file creates the full schema required by the application:
-- - users / sessions
-- - roles / user_roles
-- - dns_records / dns_record_history
-- - acl_entries / acl_history
-- IMPORTANT:
--  - Do NOT include a static password hash for admin here.
--  - After importing this file you MUST run the provided script to create the admin user
--      php scripts/create_admin.php --username admin --password 'your-password' --email admin@example.local
--    or create the admin user manually with password_hash().
--  - Alternatively you can create the admin user before running the migration if you want
--    user_roles to be assigned automatically.

CREATE DATABASE IF NOT EXISTS dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE dns3_db;

-----------------------------
-- Users and sessions
-----------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,            -- store bcrypt hashes from password_hash()
    auth_method ENUM('database','ad','ldap') DEFAULT 'database',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-----------------------------
-- Roles and user_roles
-----------------------------
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- user_roles: composite PK ensures no duplicate assignment
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

-----------------------------
-- DNS records + history
-----------------------------
CREATE TABLE IF NOT EXISTS dns_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    record_type ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV') NOT NULL,
    name VARCHAR(255) NOT NULL,
    zone VARCHAR(255) DEFAULT NULL,
    value TEXT NOT NULL,
    ttl INT DEFAULT 3600,
    priority INT NULL,
    requester VARCHAR(255) DEFAULT NULL,
    ticket_ref VARCHAR(255) DEFAULT NULL,
    created_by INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by INT DEFAULT NULL,
    modified_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    last_seen TIMESTAMP NULL,
    status ENUM('active', 'disabled', 'deleted') DEFAULT 'active',
    notes TEXT DEFAULT NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (modified_by) REFERENCES users(id),
    UNIQUE KEY uq_record (name, zone, record_type),
    INDEX idx_name (name),
    INDEX idx_zone (zone),
    INDEX idx_type (record_type),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dns_record_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    record_id INT NOT NULL,
    action ENUM('created','updated','deactivated','reactivated','deleted') NOT NULL,
    record_type ENUM('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV') NOT NULL,
    name VARCHAR(255) NOT NULL,
    zone VARCHAR(255) DEFAULT NULL,
    value TEXT NOT NULL,
    ttl INT DEFAULT 3600,
    priority INT NULL,
    requester VARCHAR(255) DEFAULT NULL,
    ticket_ref VARCHAR(255) DEFAULT NULL,
    created_by INT DEFAULT NULL,
    created_at TIMESTAMP NULL,
    modified_by INT DEFAULT NULL,
    modified_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    last_seen TIMESTAMP NULL,
    status ENUM('active','disabled','deleted') NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_by INT DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    FOREIGN KEY (record_id) REFERENCES dns_records(id) ON DELETE CASCADE,
    FOREIGN KEY (change_by) REFERENCES users(id),
    INDEX idx_record_id (record_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-----------------------------
-- ACL entries + history
-----------------------------
CREATE TABLE IF NOT EXISTS acl_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) DEFAULT NULL,      -- IP allowed/registered for access
    requester VARCHAR(255) DEFAULT NULL,
    ticket_ref VARCHAR(255) DEFAULT NULL,
    added_by INT DEFAULT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by INT DEFAULT NULL,
    modified_at TIMESTAMP NULL,
    status ENUM('enabled','disabled') DEFAULT 'enabled',
    notes TEXT DEFAULT NULL,
    FOREIGN KEY (added_by) REFERENCES users(id),
    FOREIGN KEY (modified_by) REFERENCES users(id),
    INDEX idx_ip (ip_address),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS acl_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    acl_entry_id INT NOT NULL,
    action ENUM('created','updated','enabled','disabled') NOT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    requester VARCHAR(255) DEFAULT NULL,
    ticket_ref VARCHAR(255) DEFAULT NULL,
    added_by INT DEFAULT NULL,
    added_at TIMESTAMP NULL,
    modified_by INT DEFAULT NULL,
    modified_at TIMESTAMP NULL,
    old_status ENUM('enabled','disabled') DEFAULT NULL,
    new_status ENUM('enabled','disabled') NOT NULL,
    changed_by INT DEFAULT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT DEFAULT NULL,
    FOREIGN KEY (acl_entry_id) REFERENCES acl_entries(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id),
    INDEX idx_acl_entry (acl_entry_id),
    INDEX idx_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-----------------------------
-- Optional / convenience tables
-----------------------------
-- You can add other tables (e.g., zones, change_requests) here as needed.

-----------------------------
-- Default data (roles)
-----------------------------
INSERT INTO roles (name, description)
VALUES 
    ('admin','Administrator - full access'),
    ('user','Regular user - read only')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Safely assign 'admin' role to 'admin' user ONLY if that user exists.
-- This avoids foreign key errors when roles are created before the admin user.
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW()
FROM users u
JOIN roles r ON r.name = 'admin'
WHERE u.username = 'admin'
ON DUPLICATE KEY UPDATE assigned_at = VALUES(assigned_at);

-----------------------------
-- Notes and post-install instructions
-----------------------------
-- 1) IMPORTANT: Do NOT include a static bcrypt hash in this file.
--    The admin password must be generated using password_hash() (bcrypt) on the host
--    and set by the installation script or manually.
--
-- 2) Create the admin user securely:
--    - Preferred: run the provided script (recommended):
--         php scripts/create_admin.php --username admin --password 'admin123' --email 'admin@example.local'
--      This will create the admin user (or update it) and will assign the 'admin' role if roles exist.
--
--    - Alternative manual SQL flow (if you prefer SQL):
--         -- generate hash in PHP:
--         php -r "echo password_hash('admin123', PASSWORD_DEFAULT).PHP_EOL;"
--         -- paste the generated hash below into the INSERT (replace <HASH>):
--         INSERT INTO users (username, email, password, auth_method, is_active, created_at)
--         VALUES ('admin', 'admin@example.local', '<HASH>', 'database', 1, NOW())
--         ON DUPLICATE KEY UPDATE password = VALUES(password), email = VALUES(email), auth_method = VALUES(auth_method), is_active = VALUES(is_active);
--
-- 3) After creating the admin user, ensure it has the admin role:
--    INSERT INTO user_roles (user_id, role_id, assigned_at)
--    SELECT u.id, r.id, NOW()
--    FROM users u JOIN roles r ON r.name='admin'
--    WHERE u.username = 'admin'
--    ON DUPLICATE KEY UPDATE assigned_at = VALUES(assigned_at);
--
-- 4) Run migrations in correct order if you split them:
--    - import database.sql (this file) should create everything in one shot.
--    - If you use separate migration files, ensure users/admin are present before inserting user_roles entries that reference them.
--
-- 5) Backups:
--    Always backup existing DB before applying schema changes on production.

-- End of database.sql
