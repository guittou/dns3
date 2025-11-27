<?php
/**
 * Zone ACL Model
 * Handles CRUD operations for zone-specific ACL entries
 * Provides permission checking for zone file access control
 */

require_once __DIR__ . '/../db.php';

class ZoneAcl {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Permission hierarchy: admin > write > read
     */
    private const PERMISSION_HIERARCHY = [
        'admin' => 3,
        'write' => 2,
        'read' => 1
    ];

    /**
     * Normalize username to lowercase for consistent case-insensitive comparison
     * 
     * @param string $username Username to normalize
     * @return string Normalized (lowercase, trimmed) username
     */
    private function normalizeUsername($username) {
        return mb_strtolower(trim($username));
    }

    /**
     * List all ACL entries for a specific zone
     * 
     * @param int $zone_id Zone file ID
     * @return array Array of ACL entries with resolved subject names
     */
    public function listForZone($zone_id) {
        try {
            // Note: For subject_type='user', subject_identifier now contains username (not ID)
            // We check both: if it's numeric, try to find user by ID; otherwise use it as-is (username)
            $sql = "SELECT zae.*, 
                           u.username as created_by_username,
                           CASE 
                               WHEN zae.subject_type = 'user' THEN 
                                   COALESCE(
                                       (SELECT username FROM users WHERE LOWER(username) = LOWER(zae.subject_identifier) LIMIT 1),
                                       zae.subject_identifier
                                   )
                               WHEN zae.subject_type = 'role' THEN zae.subject_identifier
                               ELSE zae.subject_identifier
                           END as subject_name
                    FROM zone_acl_entries zae
                    LEFT JOIN users u ON zae.created_by = u.id
                    WHERE zae.zone_file_id = ?
                    ORDER BY zae.subject_type, zae.subject_identifier";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_id]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("ZoneAcl listForZone error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Add a new ACL entry for a zone (upsert behavior)
     * If an entry with the same zone_id, subject_type, and subject_identifier exists,
     * it will be updated with the new permission level instead of creating a duplicate.
     * 
     * For subject_type='user', the subject_identifier can be:
     * - A user ID (for existing users)
     * - A username (for pre-authorizing non-yet-created users)
     * 
     * @param int $zone_id Zone file ID
     * @param string $subject_type Type of subject (user, role, ad_group)
     * @param string $subject_identifier User ID/username, role name, or AD group DN
     * @param string $permission Permission level (read, write, admin)
     * @param int $created_by User ID who created this entry
     * @return int|bool ACL entry ID (new or existing) or false on failure
     */
    public function addEntry($zone_id, $subject_type, $subject_identifier, $permission, $created_by) {
        try {
            // Validate subject_type
            $valid_types = ['user', 'role', 'ad_group'];
            if (!in_array($subject_type, $valid_types)) {
                error_log("ZoneAcl addEntry: Invalid subject_type: $subject_type");
                return false;
            }

            // Validate permission
            $valid_permissions = ['read', 'write', 'admin'];
            if (!in_array($permission, $valid_permissions)) {
                error_log("ZoneAcl addEntry: Invalid permission: $permission");
                return false;
            }

            // Normalize subject_identifier for 'user' type
            $normalizedIdentifier = $subject_identifier;
            
            // Validate subject_identifier based on type
            if ($subject_type === 'user') {
                // For 'user' type, we accept either:
                // 1. A numeric user ID (for existing users)
                // 2. A username string (for pre-authorizing non-yet-created users)
                
                if (is_numeric($subject_identifier)) {
                    // Check if this is a valid user ID
                    $stmt = $this->db->prepare("SELECT id, username FROM users WHERE id = ?");
                    $stmt->execute([(int)$subject_identifier]);
                    $user = $stmt->fetch();
                    if ($user) {
                        // Store username instead of ID for consistency
                        $normalizedIdentifier = $this->normalizeUsername($user['username']);
                    } else {
                        // Not a valid user ID - treat as username
                        $normalizedIdentifier = $this->normalizeUsername($subject_identifier);
                    }
                } else {
                    // Non-numeric identifier - treat as username
                    $normalizedIdentifier = $this->normalizeUsername($subject_identifier);
                }
                
                // Check if this username exists in the database (optional - just for info logging)
                $stmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(username) = ?");
                $stmt->execute([$normalizedIdentifier]);
                if (!$stmt->fetch()) {
                    error_log("ZoneAcl addEntry: Pre-authorizing user (not yet in DB): $normalizedIdentifier");
                }
            } elseif ($subject_type === 'role') {
                // Verify role exists
                $stmt = $this->db->prepare("SELECT id FROM roles WHERE name = ?");
                $stmt->execute([$subject_identifier]);
                if (!$stmt->fetch()) {
                    error_log("ZoneAcl addEntry: Role not found: $subject_identifier");
                    return false;
                }
            }
            // For ad_group, we accept any string as the DN/group name

            // Check if entry already exists
            $sql = "SELECT id FROM zone_acl_entries 
                    WHERE zone_file_id = ? AND subject_type = ? AND subject_identifier = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_id, $subject_type, $normalizedIdentifier]);
            $existing = $stmt->fetch();

            if ($existing) {
                // Update existing entry with new permission
                $sql = "UPDATE zone_acl_entries 
                        SET permission = ?, created_by = ?, created_at = NOW()
                        WHERE id = ?";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$permission, $created_by, $existing['id']]);
                return $existing['id'];
            }

            // Insert new entry
            $sql = "INSERT INTO zone_acl_entries (zone_file_id, subject_type, subject_identifier, permission, created_by, created_at)
                    VALUES (?, ?, ?, ?, ?, NOW())";
            
            $params = [
                $zone_id,
                $subject_type,
                $normalizedIdentifier,
                $permission,
                $created_by
            ];
            
            try {
                $stmt = $this->db->prepare($sql);
                $stmt->execute($params);
                return $this->db->lastInsertId();
            } catch (PDOException $e) {
                error_log("ZoneAcl addEntry INSERT error: " . $e->getMessage() . 
                          " | SQLSTATE: " . $e->getCode() .
                          " | Params: zone_id=$zone_id, subject_type=$subject_type, " .
                          "subject_identifier=$normalizedIdentifier, permission=$permission, created_by=$created_by");
                throw $e; // Re-throw to be caught by outer catch block
            }
        } catch (Exception $e) {
            error_log("ZoneAcl addEntry error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Remove an ACL entry
     * 
     * @param int $id ACL entry ID
     * @return bool Success status
     */
    public function removeEntry($id) {
        try {
            $sql = "DELETE FROM zone_acl_entries WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            return $stmt->rowCount() > 0;
        } catch (Exception $e) {
            error_log("ZoneAcl removeEntry error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get an ACL entry by ID
     * 
     * @param int $id ACL entry ID
     * @return array|null ACL entry data or null if not found
     */
    public function getById($id) {
        try {
            $sql = "SELECT zae.*, u.username as created_by_username
                    FROM zone_acl_entries zae
                    LEFT JOIN users u ON zae.created_by = u.id
                    WHERE zae.id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result ?: null;
        } catch (Exception $e) {
            error_log("ZoneAcl getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Check if a user is allowed to access a zone with a specific permission level
     * 
     * @param array $userCtx User context: ['id' => int, 'roles' => array of role names]
     * @param int $zone_id Zone file ID
     * @param string $required Required permission level (read, write, admin)
     * @param array $userGroups User's AD groups (array of DNs/group names)
     * @return bool True if user has required permission or higher
     */
    public function isAllowed($userCtx, $zone_id, $required = 'read', $userGroups = []) {
        try {
            $userId = $userCtx['id'] ?? null;
            $userRoles = $userCtx['roles'] ?? [];
            $requiredLevel = self::PERMISSION_HIERARCHY[$required] ?? 1;
            
            if (!$userId || !$zone_id) {
                return false;
            }

            // Get all ACL entries for this zone
            $sql = "SELECT subject_type, subject_identifier, permission 
                    FROM zone_acl_entries 
                    WHERE zone_file_id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_id]);
            $entries = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $maxPermissionLevel = 0;

            foreach ($entries as $entry) {
                $matches = false;
                $permissionLevel = self::PERMISSION_HIERARCHY[$entry['permission']] ?? 0;

                switch ($entry['subject_type']) {
                    case 'user':
                        // Direct user match
                        if ((int)$entry['subject_identifier'] === (int)$userId) {
                            $matches = true;
                        }
                        break;

                    case 'role':
                        // Role match - check if user has this role
                        if (in_array($entry['subject_identifier'], $userRoles)) {
                            $matches = true;
                        }
                        break;

                    case 'ad_group':
                        // AD group match - check memberOf or DN substring
                        foreach ($userGroups as $group) {
                            // Case-insensitive comparison
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

                if ($matches && $permissionLevel > $maxPermissionLevel) {
                    $maxPermissionLevel = $permissionLevel;
                }
            }

            return $maxPermissionLevel >= $requiredLevel;
        } catch (Exception $e) {
            error_log("ZoneAcl isAllowed error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get the highest permission level a user has for a zone
     * 
     * @param array $userCtx User context: ['id' => int, 'roles' => array of role names]
     * @param int $zone_id Zone file ID
     * @param array $userGroups User's AD groups
     * @return string|null Permission level (read, write, admin) or null if no access
     */
    public function getPermission($userCtx, $zone_id, $userGroups = []) {
        try {
            $userId = $userCtx['id'] ?? null;
            $userRoles = $userCtx['roles'] ?? [];
            
            if (!$userId || !$zone_id) {
                return null;
            }

            // Get all ACL entries for this zone
            $sql = "SELECT subject_type, subject_identifier, permission 
                    FROM zone_acl_entries 
                    WHERE zone_file_id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_id]);
            $entries = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $maxPermissionLevel = 0;
            $maxPermission = null;

            foreach ($entries as $entry) {
                $matches = false;
                $permissionLevel = self::PERMISSION_HIERARCHY[$entry['permission']] ?? 0;

                switch ($entry['subject_type']) {
                    case 'user':
                        if ((int)$entry['subject_identifier'] === (int)$userId) {
                            $matches = true;
                        }
                        break;

                    case 'role':
                        if (in_array($entry['subject_identifier'], $userRoles)) {
                            $matches = true;
                        }
                        break;

                    case 'ad_group':
                        foreach ($userGroups as $group) {
                            if (strcasecmp($group, $entry['subject_identifier']) === 0 ||
                                stripos($group, $entry['subject_identifier']) !== false) {
                                $matches = true;
                                break;
                            }
                        }
                        break;
                }

                if ($matches && $permissionLevel > $maxPermissionLevel) {
                    $maxPermissionLevel = $permissionLevel;
                    $maxPermission = $entry['permission'];
                }
            }

            return $maxPermission;
        } catch (Exception $e) {
            error_log("ZoneAcl getPermission error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get all zone IDs that a user has access to
     * 
     * @param array $userCtx User context: ['id' => int, 'roles' => array of role names]
     * @param string $minPermission Minimum required permission (read, write, admin)
     * @param array $userGroups User's AD groups
     * @return array Array of zone file IDs
     */
    public function getAccessibleZoneIds($userCtx, $minPermission = 'read', $userGroups = []) {
        try {
            $userId = $userCtx['id'] ?? null;
            $userRoles = $userCtx['roles'] ?? [];
            $requiredLevel = self::PERMISSION_HIERARCHY[$minPermission] ?? 1;
            
            if (!$userId) {
                return [];
            }

            // Build conditions for matching user, roles, and groups
            $conditions = [];
            $params = [];

            // User match
            $conditions[] = "(subject_type = 'user' AND subject_identifier = ?)";
            $params[] = (string)$userId;

            // Role matches
            if (!empty($userRoles)) {
                $roleplaceholders = implode(',', array_fill(0, count($userRoles), '?'));
                $conditions[] = "(subject_type = 'role' AND subject_identifier IN ($roleplaceholders))";
                $params = array_merge($params, $userRoles);
            }

            // AD group matches
            if (!empty($userGroups)) {
                $groupConditions = [];
                foreach ($userGroups as $group) {
                    $groupConditions[] = "(subject_type = 'ad_group' AND (subject_identifier = ? OR ? LIKE CONCAT('%', subject_identifier, '%')))";
                    $params[] = $group;
                    $params[] = $group;
                }
                $conditions[] = "(" . implode(" OR ", $groupConditions) . ")";
            }

            $whereClause = implode(" OR ", $conditions);

            // Get zones with matching ACL entries at required permission level
            $permLevelCase = "CASE permission WHEN 'admin' THEN 3 WHEN 'write' THEN 2 WHEN 'read' THEN 1 ELSE 0 END";
            
            $sql = "SELECT DISTINCT zone_file_id 
                    FROM zone_acl_entries 
                    WHERE ($whereClause) AND $permLevelCase >= ?";
            
            $params[] = $requiredLevel;

            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            
            return array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'zone_file_id');
        } catch (Exception $e) {
            error_log("ZoneAcl getAccessibleZoneIds error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Check if a user has any ACL entry across all zones
     * Used to determine if an AD/LDAP user should be allowed to login
     * 
     * @param string $username Username to check (case-insensitive comparison)
     * @param array $roleIds Array of role IDs the user has
     * @param array $userGroups Array of AD group DNs the user belongs to
     * @return bool True if user has at least one ACL entry
     */
    public function hasAnyAclForUser($username, array $roleIds = [], array $userGroups = []) {
        try {
            // Normalize username using helper method
            $normalizedUsername = $this->normalizeUsername($username);
            
            if (empty($normalizedUsername) && empty($roleIds) && empty($userGroups)) {
                return false;
            }
            
            // Pre-fetch role names if role IDs are provided (avoid N+1)
            $roleNames = [];
            if (!empty($roleIds)) {
                $roleIdPlaceholders = implode(',', array_fill(0, count($roleIds), '?'));
                $roleStmt = $this->db->prepare("SELECT name FROM roles WHERE id IN ($roleIdPlaceholders)");
                $roleStmt->execute($roleIds);
                $roleNames = $roleStmt->fetchAll(PDO::FETCH_COLUMN);
            }
            
            // Build query to check for any matching ACL entries using EXISTS for better performance
            $conditions = [];
            $params = [];
            
            // Check for user-based ACL by username (case-insensitive)
            if (!empty($normalizedUsername)) {
                $conditions[] = "(zae.subject_type = 'user' AND LOWER(zae.subject_identifier) = ?)";
                $params[] = $normalizedUsername;
            }
            
            // Check for role-based ACL
            if (!empty($roleNames)) {
                $roleNamePlaceholders = implode(',', array_fill(0, count($roleNames), '?'));
                $conditions[] = "(zae.subject_type = 'role' AND zae.subject_identifier IN ($roleNamePlaceholders))";
                $params = array_merge($params, $roleNames);
            }
            
            // Check for AD group-based ACL
            if (!empty($userGroups)) {
                foreach ($userGroups as $group) {
                    // Case-insensitive exact match
                    $conditions[] = "(zae.subject_type = 'ad_group' AND LOWER(zae.subject_identifier) = LOWER(?))";
                    $params[] = $group;
                    
                    // Also check if group DN contains the subject_identifier (OU matching)
                    $conditions[] = "(zae.subject_type = 'ad_group' AND LOWER(?) LIKE CONCAT('%', LOWER(zae.subject_identifier), '%'))";
                    $params[] = $group;
                }
            }
            
            if (empty($conditions)) {
                return false;
            }
            
            $whereClause = implode(" OR ", $conditions);
            
            // Use EXISTS for better performance instead of COUNT(*)
            $sql = "SELECT EXISTS(SELECT 1 FROM zone_acl_entries zae WHERE $whereClause) as has_acl";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return (bool)($result['has_acl'] ?? 0);
        } catch (Exception $e) {
            error_log("ZoneAcl hasAnyAclForUser error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Check if a user has ACL access to a specific zone by username
     * Similar to isAllowed() but uses username instead of user ID
     * 
     * @param string $username Username to check (case-insensitive)
     * @param int $zone_id Zone file ID
     * @param string $required Required permission level (read, write, admin)
     * @param array $roleNames Array of role names the user has
     * @param array $userGroups User's AD groups (array of DNs/group names)
     * @return bool True if user has required permission or higher
     */
    public function isAllowedByUsername($username, $zone_id, $required = 'read', $roleNames = [], $userGroups = []) {
        try {
            $normalizedUsername = $this->normalizeUsername($username);
            $requiredLevel = self::PERMISSION_HIERARCHY[$required] ?? 1;
            
            if (empty($normalizedUsername) || !$zone_id) {
                return false;
            }

            // Get all ACL entries for this zone
            $sql = "SELECT subject_type, subject_identifier, permission 
                    FROM zone_acl_entries 
                    WHERE zone_file_id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_id]);
            $entries = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $maxPermissionLevel = 0;

            foreach ($entries as $entry) {
                $matches = false;
                $permissionLevel = self::PERMISSION_HIERARCHY[$entry['permission']] ?? 0;

                switch ($entry['subject_type']) {
                    case 'user':
                        // Username match (case-insensitive) - subject_identifier now stores username
                        if ($this->normalizeUsername($entry['subject_identifier']) === $normalizedUsername) {
                            $matches = true;
                        }
                        break;

                    case 'role':
                        // Role match - check if user has this role
                        if (in_array($entry['subject_identifier'], $roleNames)) {
                            $matches = true;
                        }
                        break;

                    case 'ad_group':
                        // AD group match - check memberOf or DN substring
                        foreach ($userGroups as $group) {
                            // Case-insensitive comparison
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

                if ($matches && $permissionLevel > $maxPermissionLevel) {
                    $maxPermissionLevel = $permissionLevel;
                }
            }

            return $maxPermissionLevel >= $requiredLevel;
        } catch (Exception $e) {
            error_log("ZoneAcl isAllowedByUsername error: " . $e->getMessage());
            return false;
        }
    }
}
?>
