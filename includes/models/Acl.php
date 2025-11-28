<?php
/**
 * Acl Model
 * Provides robust ACL (Access Control List) methods for zone file permissions.
 * Supports the new schema with zone_file_id/subject_type/subject_identifier columns.
 * 
 * Features:
 * - Case-insensitive username comparison (normalized to lowercase)
 * - Permission hierarchy: admin > write > read
 * - Support for user, role, and AD group subjects
 * - Legacy compatibility with user_id/role_id columns
 */

require_once __DIR__ . '/../db.php';

class Acl {
    private $db;

    /**
     * Permission hierarchy: admin > write > read
     */
    private const PERMISSION_HIERARCHY = [
        'admin' => 3,
        'write' => 2,
        'read' => 1
    ];

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
     * Check if a user has any ACL entry across all zones
     * Used to determine if a user should have access to the application.
     * 
     * This method checks:
     * 1. Direct user ACL by subject_identifier (username, case-insensitive)
     * 2. Direct user ACL by user_id (legacy column)
     * 3. Role-based ACL via user_roles lookup
     * 4. AD group-based ACL (for AD/LDAP users)
     * 
     * @param string $username Username to check (case-insensitive comparison)
     * @param array $userGroups Optional array of AD group DNs the user belongs to
     * @return bool True if user has at least one ACL entry
     */
    public function hasAnyAclForUser($username, array $userGroups = []) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername)) {
                return false;
            }
            
            // Get user ID if exists (for legacy user_id column check)
            $userId = $this->getUserIdByUsername($normalizedUsername);
            
            // Get user's role IDs and names
            $roleIds = [];
            $roleNames = [];
            if ($userId) {
                $roleStmt = $this->db->prepare("
                    SELECT r.id, r.name 
                    FROM user_roles ur 
                    INNER JOIN roles r ON ur.role_id = r.id 
                    WHERE ur.user_id = ?
                ");
                $roleStmt->execute([$userId]);
                $roles = $roleStmt->fetchAll(PDO::FETCH_ASSOC);
                $roleIds = array_column($roles, 'id');
                $roleNames = array_column($roles, 'name');
            }
            
            // Build query conditions
            $conditions = [];
            $params = [];
            
            // Check 1: Direct user ACL by subject_identifier (username, case-insensitive)
            $conditions[] = "(ae.subject_type = 'user' AND LOWER(ae.subject_identifier) = ?)";
            $params[] = $normalizedUsername;
            
            // Check 2: Direct user ACL by user_id (legacy column)
            if ($userId) {
                $conditions[] = "(ae.user_id = ?)";
                $params[] = $userId;
            }
            
            // Check 3: Role-based ACL via user_roles
            if (!empty($roleNames)) {
                $roleNamePlaceholders = implode(',', array_fill(0, count($roleNames), '?'));
                $conditions[] = "(ae.subject_type = 'role' AND ae.subject_identifier IN ($roleNamePlaceholders))";
                $params = array_merge($params, $roleNames);
            }
            
            if (!empty($roleIds)) {
                $roleIdPlaceholders = implode(',', array_fill(0, count($roleIds), '?'));
                $conditions[] = "(ae.role_id IN ($roleIdPlaceholders))";
                $params = array_merge($params, $roleIds);
            }
            
            // Check 4: AD group-based ACL
            if (!empty($userGroups)) {
                foreach ($userGroups as $group) {
                    // Case-insensitive exact match
                    $conditions[] = "(ae.subject_type = 'ad_group' AND LOWER(ae.subject_identifier) = LOWER(?))";
                    $params[] = $group;
                    
                    // Also check if group DN contains the subject_identifier (OU matching)
                    $conditions[] = "(ae.subject_type = 'ad_group' AND LOWER(?) LIKE CONCAT('%', LOWER(ae.subject_identifier), '%'))";
                    $params[] = $group;
                }
            }
            
            if (empty($conditions)) {
                return false;
            }
            
            $whereClause = implode(" OR ", $conditions);
            
            // Use EXISTS for better performance
            $sql = "SELECT EXISTS(
                SELECT 1 FROM acl_entries ae 
                WHERE ($whereClause)
                AND (ae.zone_file_id IS NOT NULL OR ae.resource_type = 'zone')
            ) as has_acl";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return (bool)($result['has_acl'] ?? 0);
        } catch (PDOException $e) {
            $this->logSqlError('hasAnyAclForUser', $e, ['username' => $username]);
            return false;
        } catch (Exception $e) {
            error_log("Acl hasAnyAclForUser error: " . $e->getMessage() . " | username: $username");
            return false;
        }
    }

    /**
     * Check if a user is allowed to access a specific zone with a required permission level
     * 
     * This method checks:
     * 1. Direct user ACL by subject_identifier (username, case-insensitive)
     * 2. Direct user ACL by user_id (legacy column)
     * 3. Role-based ACL via user_roles lookup
     * 4. AD group-based ACL (for AD/LDAP users)
     * 
     * Permission hierarchy: admin >= write >= read
     * 
     * @param string $username Username to check (case-insensitive)
     * @param int $zone_file_id Zone file ID
     * @param string $required_permission Required permission level (read, write, admin)
     * @param array $userGroups Optional array of AD group DNs the user belongs to
     * @return bool True if user has required permission or higher
     */
    public function isAllowedForZone($username, $zone_file_id, $required_permission = 'read', array $userGroups = []) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            $requiredLevel = self::PERMISSION_HIERARCHY[$required_permission] ?? 1;
            
            if (empty($normalizedUsername) || !$zone_file_id) {
                return false;
            }
            
            // Get user ID if exists
            $userId = $this->getUserIdByUsername($normalizedUsername);
            
            // Get user's role names and IDs (pre-fetch to avoid N+1 queries)
            $roleNames = [];
            $roleIds = [];
            if ($userId) {
                $roleStmt = $this->db->prepare("
                    SELECT r.id, r.name 
                    FROM user_roles ur 
                    INNER JOIN roles r ON ur.role_id = r.id 
                    WHERE ur.user_id = ?
                ");
                $roleStmt->execute([$userId]);
                $roles = $roleStmt->fetchAll(PDO::FETCH_ASSOC);
                $roleNames = array_column($roles, 'name');
                $roleIds = array_column($roles, 'id');
            }
            
            // Get all ACL entries for this zone
            $sql = "SELECT ae.subject_type, ae.subject_identifier, ae.permission,
                           ae.user_id, ae.role_id
                    FROM acl_entries ae
                    WHERE (ae.zone_file_id = ? OR (ae.resource_type = 'zone' AND ae.resource_id = ?))";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_file_id, $zone_file_id]);
            $entries = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $maxPermissionLevel = 0;

            foreach ($entries as $entry) {
                $matches = false;
                $permissionLevel = self::PERMISSION_HIERARCHY[$entry['permission']] ?? 0;

                // Check new schema: subject_type + subject_identifier
                if ($entry['subject_type'] && $entry['subject_identifier']) {
                    switch ($entry['subject_type']) {
                        case 'user':
                            // Username match (case-insensitive)
                            if ($this->normalizeUsername($entry['subject_identifier']) === $normalizedUsername) {
                                $matches = true;
                            }
                            break;

                        case 'role':
                            // Role match
                            if (in_array($entry['subject_identifier'], $roleNames)) {
                                $matches = true;
                            }
                            break;

                        case 'ad_group':
                            // AD group match
                            foreach ($userGroups as $group) {
                                if (strcasecmp($group, $entry['subject_identifier']) === 0) {
                                    $matches = true;
                                    break;
                                }
                                // Also check if entry is a substring of group DN (for OU matching)
                                if (stripos($group, $entry['subject_identifier']) !== false) {
                                    $matches = true;
                                    break;
                                }
                            }
                            break;
                    }
                }
                
                // Check legacy schema: user_id or role_id columns
                if (!$matches && $entry['user_id'] && $userId && (int)$entry['user_id'] === (int)$userId) {
                    $matches = true;
                }
                
                // Check if user has this role (using pre-fetched role IDs to avoid N+1 queries)
                if (!$matches && $entry['role_id'] && in_array((int)$entry['role_id'], $roleIds)) {
                    $matches = true;
                }

                if ($matches && $permissionLevel > $maxPermissionLevel) {
                    $maxPermissionLevel = $permissionLevel;
                }
            }

            return $maxPermissionLevel >= $requiredLevel;
        } catch (PDOException $e) {
            $this->logSqlError('isAllowedForZone', $e, [
                'username' => $username,
                'zone_file_id' => $zone_file_id,
                'required_permission' => $required_permission
            ]);
            return false;
        } catch (Exception $e) {
            error_log("Acl isAllowedForZone error: " . $e->getMessage() . 
                      " | username: $username, zone_file_id: $zone_file_id");
            return false;
        }
    }

    /**
     * Get all zone file IDs that a user has access to with at least the minimum permission level
     * 
     * This method checks:
     * 1. Direct user ACL by subject_identifier (username, case-insensitive)
     * 2. Direct user ACL by user_id (legacy column)
     * 3. Role-based ACL via user_roles lookup
     * 4. AD group-based ACL (for AD/LDAP users)
     * 
     * @param string $username Username to check (case-insensitive)
     * @param string $minPermission Minimum required permission level (read, write, admin)
     * @param array $userGroups Optional array of AD group DNs the user belongs to
     * @return array Array of zone_file_id values the user can access
     */
    public function getAllowedZoneIds($username, $minPermission = 'read', array $userGroups = []) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            $requiredLevel = self::PERMISSION_HIERARCHY[$minPermission] ?? 1;
            
            if (empty($normalizedUsername)) {
                return [];
            }
            
            // Get user ID if exists (for legacy user_id column check)
            $userId = $this->getUserIdByUsername($normalizedUsername);
            
            // Get user's role IDs and names
            $roleIds = [];
            $roleNames = [];
            if ($userId) {
                $roleStmt = $this->db->prepare("
                    SELECT r.id, r.name 
                    FROM user_roles ur 
                    INNER JOIN roles r ON ur.role_id = r.id 
                    WHERE ur.user_id = ?
                ");
                $roleStmt->execute([$userId]);
                $roles = $roleStmt->fetchAll(PDO::FETCH_ASSOC);
                $roleIds = array_column($roles, 'id');
                $roleNames = array_column($roles, 'name');
            }
            
            // Build query conditions
            $conditions = [];
            $params = [];
            
            // Check 1: Direct user ACL by subject_identifier (username, case-insensitive)
            $conditions[] = "(ae.subject_type = 'user' AND LOWER(ae.subject_identifier) = ?)";
            $params[] = $normalizedUsername;
            
            // Check 2: Direct user ACL by user_id (legacy column)
            if ($userId) {
                $conditions[] = "(ae.user_id = ?)";
                $params[] = $userId;
            }
            
            // Check 3: Role-based ACL via user_roles
            if (!empty($roleNames)) {
                $roleNamePlaceholders = implode(',', array_fill(0, count($roleNames), '?'));
                $conditions[] = "(ae.subject_type = 'role' AND ae.subject_identifier IN ($roleNamePlaceholders))";
                $params = array_merge($params, $roleNames);
            }
            
            if (!empty($roleIds)) {
                $roleIdPlaceholders = implode(',', array_fill(0, count($roleIds), '?'));
                $conditions[] = "(ae.role_id IN ($roleIdPlaceholders))";
                $params = array_merge($params, $roleIds);
            }
            
            // Check 4: AD group-based ACL
            if (!empty($userGroups)) {
                foreach ($userGroups as $group) {
                    // Case-insensitive exact match
                    $conditions[] = "(ae.subject_type = 'ad_group' AND LOWER(ae.subject_identifier) = LOWER(?))";
                    $params[] = $group;
                    
                    // Also check if group DN contains the subject_identifier (OU matching)
                    $conditions[] = "(ae.subject_type = 'ad_group' AND LOWER(?) LIKE CONCAT('%', LOWER(ae.subject_identifier), '%'))";
                    $params[] = $group;
                }
            }
            
            if (empty($conditions)) {
                return [];
            }
            
            $whereClause = implode(" OR ", $conditions);
            
            // Permission level filter using CASE expression
            $permLevelCase = "CASE ae.permission 
                WHEN 'admin' THEN 3 
                WHEN 'write' THEN 2 
                WHEN 'read' THEN 1 
                ELSE 0 
            END";
            
            // Get distinct zone_file_ids with sufficient permission
            $sql = "SELECT DISTINCT ae.zone_file_id
                    FROM acl_entries ae
                    WHERE ($whereClause)
                    AND ae.zone_file_id IS NOT NULL
                    AND $permLevelCase >= ?";
            
            $params[] = $requiredLevel;
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            
            return array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'zone_file_id');
        } catch (PDOException $e) {
            $this->logSqlError('getAllowedZoneIds', $e, [
                'username' => $username,
                'minPermission' => $minPermission
            ]);
            return [];
        } catch (Exception $e) {
            error_log("Acl getAllowedZoneIds error: " . $e->getMessage() . 
                      " | username: $username");
            return [];
        }
    }

    /**
     * Add a new ACL entry for a zone (upsert behavior)
     * Inserts into the new schema (zone_file_id/subject_type/subject_identifier)
     * and also fills resource_type/resource_id for backward compatibility.
     * 
     * @param int $zone_file_id Zone file ID
     * @param string $subject_type Type of subject (user, role, ad_group)
     * @param string $subject_identifier User username, role name, or AD group DN
     * @param string $permission Permission level (read, write, admin)
     * @param int $created_by User ID who created this entry
     * @return int|bool ACL entry ID (new or existing) or false on failure
     */
    public function addEntry($zone_file_id, $subject_type, $subject_identifier, $permission, $created_by) {
        try {
            // Validate subject_type
            $valid_types = ['user', 'role', 'ad_group'];
            if (!in_array($subject_type, $valid_types)) {
                error_log("Acl addEntry: Invalid subject_type: $subject_type");
                return false;
            }

            // Validate permission
            $valid_permissions = ['read', 'write', 'admin'];
            if (!in_array($permission, $valid_permissions)) {
                error_log("Acl addEntry: Invalid permission: $permission");
                return false;
            }

            // Normalize subject_identifier for 'user' type
            $normalizedIdentifier = $subject_identifier;
            $resolvedUserId = null;
            $resolvedRoleId = null;
            
            if ($subject_type === 'user') {
                // If numeric, try to resolve to username
                if (is_numeric($subject_identifier)) {
                    $stmt = $this->db->prepare("SELECT id, username FROM users WHERE id = ?");
                    $stmt->execute([(int)$subject_identifier]);
                    $user = $stmt->fetch(PDO::FETCH_ASSOC);
                    if ($user) {
                        $normalizedIdentifier = $this->normalizeUsername($user['username']);
                        $resolvedUserId = $user['id'];
                    } else {
                        // Not a valid user ID - treat as username
                        $normalizedIdentifier = $this->normalizeUsername($subject_identifier);
                    }
                } else {
                    // Non-numeric identifier - treat as username
                    $normalizedIdentifier = $this->normalizeUsername($subject_identifier);
                    
                    // Try to find user ID for legacy column
                    $stmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(username) = ?");
                    $stmt->execute([$normalizedIdentifier]);
                    $user = $stmt->fetch(PDO::FETCH_ASSOC);
                    if ($user) {
                        $resolvedUserId = $user['id'];
                    }
                }
                
                // Log if pre-authorizing a user that doesn't exist yet
                if (!$resolvedUserId) {
                    error_log("Acl addEntry: Pre-authorizing user (not yet in DB): $normalizedIdentifier");
                }
            } elseif ($subject_type === 'role') {
                // Verify role exists and get ID for legacy column
                $stmt = $this->db->prepare("SELECT id FROM roles WHERE name = ?");
                $stmt->execute([$subject_identifier]);
                $role = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$role) {
                    error_log("Acl addEntry: Role not found: $subject_identifier");
                    return false;
                }
                $resolvedRoleId = $role['id'];
                $normalizedIdentifier = $subject_identifier;
            }
            // For ad_group, we accept any string as the DN/group name

            // Check if entry already exists
            $sql = "SELECT id FROM acl_entries 
                    WHERE zone_file_id = ? AND subject_type = ? AND LOWER(subject_identifier) = LOWER(?)";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_file_id, $subject_type, $normalizedIdentifier]);
            $existing = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($existing) {
                // Update existing entry with new permission
                $sql = "UPDATE acl_entries 
                        SET permission = ?, 
                            created_by = ?, 
                            created_at = NOW(),
                            user_id = COALESCE(?, user_id),
                            role_id = COALESCE(?, role_id)
                        WHERE id = ?";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$permission, $created_by, $resolvedUserId, $resolvedRoleId, $existing['id']]);
                return $existing['id'];
            }

            // Insert new entry with both new and legacy columns
            $sql = "INSERT INTO acl_entries 
                    (zone_file_id, subject_type, subject_identifier, permission, created_by, created_at,
                     resource_type, resource_id, user_id, role_id, status)
                    VALUES (?, ?, ?, ?, ?, NOW(), 'zone', ?, ?, ?, 'enabled')";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $zone_file_id,
                $subject_type,
                $normalizedIdentifier,
                $permission,
                $created_by,
                $zone_file_id,  // resource_id = zone_file_id for compatibility
                $resolvedUserId,
                $resolvedRoleId
            ]);
            
            return $this->db->lastInsertId();
        } catch (PDOException $e) {
            $this->logSqlError('addEntry', $e, [
                'zone_file_id' => $zone_file_id,
                'subject_type' => $subject_type,
                'subject_identifier' => $normalizedIdentifier ?? $subject_identifier,
                'permission' => $permission,
                'created_by' => $created_by
            ]);
            return false;
        } catch (Exception $e) {
            error_log("Acl addEntry error: " . $e->getMessage() . 
                      " | zone_file_id: $zone_file_id, subject_type: $subject_type");
            return false;
        }
    }

    /**
     * Get user ID by username (case-insensitive)
     * 
     * @param string $username Normalized username
     * @return int|null User ID or null if not found
     */
    private function getUserIdByUsername($username) {
        try {
            $stmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(username) = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            return $user ? (int)$user['id'] : null;
        } catch (Exception $e) {
            error_log("Acl getUserIdByUsername error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Log detailed SQL error for debugging
     * 
     * @param string $method Method name where error occurred
     * @param PDOException $e The exception
     * @param array $context Additional context data
     */
    private function logSqlError($method, PDOException $e, array $context = []) {
        $errorInfo = $e->errorInfo ?? [];
        $sqlState = $errorInfo[0] ?? 'HY000';
        $driverCode = $errorInfo[1] ?? 'N/A';
        $driverMsg = $errorInfo[2] ?? $e->getMessage();
        
        $contextStr = '';
        foreach ($context as $key => $value) {
            $contextStr .= "$key=$value, ";
        }
        $contextStr = rtrim($contextStr, ', ');
        
        error_log("Acl $method SQL error: " . $e->getMessage() . 
                  " | SQLSTATE: $sqlState" .
                  " | Driver code: $driverCode" .
                  " | Driver message: $driverMsg" .
                  " | Context: $contextStr");
    }
}
?>
