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
     * List all ACL entries for a specific zone
     * 
     * @param int $zone_id Zone file ID
     * @return array Array of ACL entries with resolved subject names
     */
    public function listForZone($zone_id) {
        try {
            $sql = "SELECT zae.*, 
                           u.username as created_by_username,
                           CASE 
                               WHEN zae.subject_type = 'user' THEN (SELECT username FROM users WHERE id = CAST(zae.subject_identifier AS UNSIGNED))
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
     * @param int $zone_id Zone file ID
     * @param string $subject_type Type of subject (user, role, ad_group)
     * @param string $subject_identifier User ID, role name, or AD group DN
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

            // Validate subject_identifier based on type
            if ($subject_type === 'user') {
                // Verify user exists
                $stmt = $this->db->prepare("SELECT id FROM users WHERE id = ?");
                $stmt->execute([$subject_identifier]);
                if (!$stmt->fetch()) {
                    error_log("ZoneAcl addEntry: User not found: $subject_identifier");
                    return false;
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
            $stmt->execute([$zone_id, $subject_type, $subject_identifier]);
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
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $zone_id,
                $subject_type,
                $subject_identifier,
                $permission,
                $created_by
            ]);
            
            return $this->db->lastInsertId();
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
}
?>
