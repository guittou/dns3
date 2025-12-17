<?php
/**
 * Auth Model
 * Provides authentication-related helper methods for user roles and mappings.
 * Complements the main Auth class in includes/auth.php.
 * 
 * Features:
 * - Role checking by username
 * - AD/LDAP mapping application at login
 * - Case-insensitive username handling
 */

require_once __DIR__ . '/../db.php';

class AuthModel {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Normalize username to lowercase for consistent case-insensitive comparison
     * 
     * @param string $username Username to normalize
     * @return string Normalized (lowercase, trimmed) username
     */
    private function normalizeUsername($username) {
        if ($username === null || $username === '') {
            return '';
        }
        return mb_strtolower(trim($username));
    }

    /**
     * Check if a user has a specific role by role name
     * 
     * @param string $username Username to check (case-insensitive)
     * @param string $roleName Role name to check for
     * @return bool True if user has the specified role
     */
    public function userHasRole($username, $roleName) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername) || empty($roleName)) {
                return false;
            }
            
            $sql = "SELECT COUNT(*) as has_role
                    FROM users u
                    INNER JOIN user_roles ur ON u.id = ur.user_id
                    INNER JOIN roles r ON ur.role_id = r.id
                    WHERE LOWER(u.username) = ? AND r.name = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$normalizedUsername, $roleName]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return (int)($result['has_role'] ?? 0) > 0;
        } catch (Exception $e) {
            error_log("AuthModel userHasRole error: " . $e->getMessage() . 
                      " | username: $username, roleName: $roleName");
            return false;
        }
    }

    /**
     * Check if a user has a specific role by role ID
     * 
     * @param string $username Username to check (case-insensitive)
     * @param int $roleId Role ID to check for
     * @return bool True if user has the specified role
     */
    public function userHasRoleId($username, $roleId) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername) || !$roleId) {
                return false;
            }
            
            $sql = "SELECT COUNT(*) as has_role
                    FROM users u
                    INNER JOIN user_roles ur ON u.id = ur.user_id
                    WHERE LOWER(u.username) = ? AND ur.role_id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$normalizedUsername, (int)$roleId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return (int)($result['has_role'] ?? 0) > 0;
        } catch (Exception $e) {
            error_log("AuthModel userHasRoleId error: " . $e->getMessage() . 
                      " | username: $username, roleId: $roleId");
            return false;
        }
    }

    /**
     * Get all roles for a user by username
     * 
     * @param string $username Username (case-insensitive)
     * @return array Array of role data with id, name, description
     */
    public function getUserRoles($username) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername)) {
                return [];
            }
            
            $sql = "SELECT r.id, r.name, r.description
                    FROM users u
                    INNER JOIN user_roles ur ON u.id = ur.user_id
                    INNER JOIN roles r ON ur.role_id = r.id
                    WHERE LOWER(u.username) = ?
                    ORDER BY r.name ASC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$normalizedUsername]);
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("AuthModel getUserRoles error: " . $e->getMessage() . 
                      " | username: $username");
            return [];
        }
    }

    /**
     * Get user ID by username (case-insensitive)
     * 
     * @param string $username Username to look up
     * @return int|null User ID or null if not found
     */
    public function getUserIdByUsername($username) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername)) {
                return null;
            }
            
            $stmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(username) = ?");
            $stmt->execute([$normalizedUsername]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return $user ? (int)$user['id'] : null;
        } catch (Exception $e) {
            error_log("AuthModel getUserIdByUsername error: " . $e->getMessage() . 
                      " | username: $username");
            return null;
        }
    }

    /**
     * Apply AD/LDAP role mappings for a user at login
     * Creates user_roles entries based on auth_mappings table.
     * Uses INSERT IGNORE to avoid duplicates.
     * 
     * @param string $username Username (will be normalized to lowercase)
     * @param string $authMethod Authentication method ('ad' or 'ldap')
     * @param array $groups Array of AD group DNs the user belongs to
     * @param string $userDn User's full DN (for LDAP OU matching)
     * @return array Array of role IDs that were applied
     */
    public function applyAuthMappingsAtLogin($username, $authMethod, array $groups = [], $userDn = '') {
        $appliedRoleIds = [];
        
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername)) {
                return [];
            }
            
            // Get user ID
            $userId = $this->getUserIdByUsername($normalizedUsername);
            if (!$userId) {
                error_log("AuthModel applyAuthMappingsAtLogin: User not found: $normalizedUsername");
                return [];
            }
            
            // Get matching role IDs from auth_mappings
            $matchedRoleIds = $this->getRoleIdsFromMappings($authMethod, $groups, $userDn);
            
            if (empty($matchedRoleIds)) {
                return [];
            }
            
            // Insert user_roles for each matched role (using INSERT IGNORE)
            foreach ($matchedRoleIds as $roleId) {
                try {
                    $stmt = $this->db->prepare("
                        INSERT IGNORE INTO user_roles (user_id, role_id, assigned_at) 
                        VALUES (?, ?, NOW())
                    ");
                    $result = $stmt->execute([$userId, $roleId]);
                    
                    if ($result) {
                        $appliedRoleIds[] = $roleId;
                    }
                } catch (PDOException $e) {
                    // Log but continue with other roles
                    error_log("AuthModel applyAuthMappingsAtLogin: Failed to assign role $roleId to user $userId: " . $e->getMessage());
                }
            }
            
            return $appliedRoleIds;
        } catch (Exception $e) {
            error_log("AuthModel applyAuthMappingsAtLogin error: " . $e->getMessage() . 
                      " | username: $username, authMethod: $authMethod");
            return [];
        }
    }

    /**
     * Get role IDs from auth_mappings that match user's groups/DN
     * 
     * @param string $authMethod Authentication method ('ad' or 'ldap')
     * @param array $comparableValues Array of values to compare (AD groups, sAMAccountName:value, uid:value, departmentNumber:value, etc.)
     * @param string $userDn User's full DN (for LDAP OU matching)
     * @return array Array of matched role IDs
     */
    public function getRoleIdsFromMappings($authMethod, array $comparableValues = [], $userDn = '') {
        $matchedRoleIds = [];
        
        try {
            $stmt = $this->db->prepare("SELECT id, dn_or_group, role_id FROM auth_mappings WHERE source = ?");
            $stmt->execute([$authMethod]);
            $mappings = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($mappings as $mapping) {
                $matches = false;
                
                // Check for exact match (case-insensitive) against comparable values
                // This handles: AD groups (DNs), sAMAccountName:value, uid:value, departmentNumber:value
                $mappingLower = mb_strtolower($mapping['dn_or_group']);
                foreach ($comparableValues as $value) {
                    if (mb_strtolower($value) === $mappingLower) {
                        $matches = true;
                        break;
                    }
                }
                
                // For LDAP: also check if user DN contains the mapped DN/OU path
                // This is for backward compatibility with existing OU-based mappings
                if (!$matches && $authMethod === 'ldap' && $userDn) {
                    if (mb_stripos($userDn, $mapping['dn_or_group']) !== false) {
                        $matches = true;
                    }
                }
                
                if ($matches && !in_array($mapping['role_id'], $matchedRoleIds)) {
                    $matchedRoleIds[] = (int)$mapping['role_id'];
                }
            }
        } catch (Exception $e) {
            error_log("AuthModel getRoleIdsFromMappings error: " . $e->getMessage() . 
                      " | authMethod: $authMethod");
        }
        
        return $matchedRoleIds;
    }

    /**
     * Check if a user is an administrator (has 'admin' role)
     * 
     * @param string $username Username (case-insensitive)
     * @return bool True if user has admin role
     */
    public function isAdmin($username) {
        return $this->userHasRole($username, 'admin');
    }

    /**
     * Check if a user is a zone editor (has 'zone_editor' role)
     * 
     * @param string $username Username (case-insensitive)
     * @return bool True if user has zone_editor role
     */
    public function isZoneEditor($username) {
        return $this->userHasRole($username, 'zone_editor');
    }

    /**
     * Synchronize user roles with auth_mappings
     * - Adds missing mapped roles
     * - Removes roles that came from mappings but no longer match
     * - Does NOT remove manually assigned roles
     * 
     * @param string $username Username (case-insensitive)
     * @param string $authMethod Authentication method ('ad' or 'ldap')
     * @param array $matchedRoleIds Array of role IDs that should be assigned
     * @return bool True on success
     */
    public function syncUserRolesWithMappings($username, $authMethod, array $matchedRoleIds) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            $userId = $this->getUserIdByUsername($normalizedUsername);
            
            if (!$userId) {
                return false;
            }
            
            // Get all role IDs that are defined in auth_mappings for this source
            $stmt = $this->db->prepare("SELECT DISTINCT role_id FROM auth_mappings WHERE source = ?");
            $stmt->execute([$authMethod]);
            $mappingRoleIds = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'role_id');
            
            // Get current user roles
            $stmt = $this->db->prepare("SELECT role_id FROM user_roles WHERE user_id = ?");
            $stmt->execute([$userId]);
            $currentRoleIds = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'role_id');
            
            // Add missing matched roles
            foreach ($matchedRoleIds as $roleId) {
                if (!in_array($roleId, $currentRoleIds)) {
                    $stmt = $this->db->prepare(
                        "INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (?, ?, NOW())"
                    );
                    $stmt->execute([$userId, $roleId]);
                }
            }
            
            // Remove roles that come from mappings but are no longer matched
            foreach ($currentRoleIds as $roleId) {
                if (in_array($roleId, $mappingRoleIds) && !in_array($roleId, $matchedRoleIds)) {
                    $stmt = $this->db->prepare("DELETE FROM user_roles WHERE user_id = ? AND role_id = ?");
                    $stmt->execute([$userId, $roleId]);
                }
            }
            
            return true;
        } catch (Exception $e) {
            error_log("AuthModel syncUserRolesWithMappings error: " . $e->getMessage() . 
                      " | username: $username, authMethod: $authMethod");
            return false;
        }
    }
}
?>
