-- Migration 002: Auth Mappings for AD/LDAP Role Assignment
-- This migration creates the auth_mappings table to store mappings between
-- AD groups or LDAP DN/OU paths and application roles.
-- These mappings will be used during AD/LDAP authentication to automatically
-- assign roles to users based on their group membership or organizational unit.

USE dns3_db;

-- Auth mappings table for AD/LDAP group to role mapping
CREATE TABLE IF NOT EXISTS auth_mappings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source ENUM('ad', 'ldap') NOT NULL,
    dn_or_group VARCHAR(255) NOT NULL COMMENT 'AD group CN or LDAP DN/OU path',
    role_id INT NOT NULL,
    created_by INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT DEFAULT NULL COMMENT 'Optional description of this mapping',
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_source (source),
    INDEX idx_role_id (role_id),
    UNIQUE KEY uq_mapping (source, dn_or_group, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notes:
-- 1. This table enables automatic role assignment based on AD/LDAP attributes
-- 2. For AD: dn_or_group should contain the group CN, e.g., 'CN=DNSAdmins,OU=Groups,DC=example,DC=com'
-- 3. For LDAP: dn_or_group should contain the DN or OU path, e.g., 'ou=IT,dc=example,dc=com'
-- 4. The auth.php will need to be updated to query this table during authentication
--    and assign the corresponding roles to the authenticated user
-- 5. Multiple mappings can exist for different groups/OUs to the same role
-- 6. The unique constraint prevents duplicate mappings of the same source+dn_or_group+role

-- End of migration 002
