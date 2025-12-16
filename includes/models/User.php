<?php
/**
 * User Model
 * Handles CRUD operations for users, roles, and role assignments
 */

require_once __DIR__ . '/../db.php';

class User {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * List all users with their roles
     * 
     * @param array $filters Optional filters (username, auth_method, is_active)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of users with their roles
     */
    public function list($filters = [], $limit = 100, $offset = 0) {
        try {
            $sql = "SELECT u.id, u.username, u.auth_method, u.is_active, 
                           u.created_at, u.last_login
                    FROM users u
                    WHERE 1=1";
            
            $params = [];
            
            if (isset($filters['username']) && $filters['username'] !== '') {
                $sql .= " AND u.username LIKE ?";
                $params[] = '%' . $filters['username'] . '%';
            }
            
            if (isset($filters['auth_method']) && $filters['auth_method'] !== '') {
                $sql .= " AND u.auth_method = ?";
                $params[] = $filters['auth_method'];
            }
            
            if (isset($filters['is_active']) && $filters['is_active'] !== '') {
                $sql .= " AND u.is_active = ?";
                $params[] = (int)$filters['is_active'];
            }
            
            $sql .= " ORDER BY u.username ASC LIMIT ? OFFSET ?";
            $params[] = $limit;
            $params[] = $offset;
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $users = $stmt->fetchAll();
            
            // Get roles for each user
            foreach ($users as &$user) {
                $user['roles'] = $this->getUserRoles($user['id']);
            }
            
            return $users;
        } catch (Exception $e) {
            error_log("User list error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a user by ID with their roles
     * 
     * @param int $id User ID
     * @return array|null User data with roles or null if not found
     */
    public function getById($id) {
        try {
            $sql = "SELECT u.id, u.username, u.auth_method, u.is_active,
                           u.created_at, u.last_login
                    FROM users u
                    WHERE u.id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $user = $stmt->fetch();
            
            if ($user) {
                $user['roles'] = $this->getUserRoles($user['id']);
            }
            
            return $user ?: null;
        } catch (Exception $e) {
            error_log("User getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new user
     * 
     * @param array $data User data (username, password, auth_method)
     * @param int $created_by User ID creating this user
     * @return int|bool New user ID or false on failure
     */
    public function create($data, $created_by = null) {
        try {
            // Validate required fields
            if (!isset($data['username'])) {
                return false;
            }
            
            // ENFORCE: Server-side auth_method validation
            // Force database authentication for all admin-created users
            $auth_method = 'database';
            
            // For database auth, password is required
            $password = '';
            if (!isset($data['password']) || $data['password'] === '') {
                return false;
            }
            $password = password_hash($data['password'], PASSWORD_DEFAULT);
            
            $sql = "INSERT INTO users (username, password, auth_method, is_active, created_at)
                    VALUES (?, ?, ?, ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['username'],
                $password,
                $auth_method,
                isset($data['is_active']) ? (int)$data['is_active'] : 1
            ]);
            
            return $this->db->lastInsertId();
        } catch (Exception $e) {
            error_log("User create error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Update an existing user
     * 
     * @param int $id User ID
     * @param array $data Updated user data
     * @param int $modified_by User ID making the modification
     * @return bool Success status
     */
    public function update($id, $data, $modified_by = null) {
        try {
            $current = $this->getById($id);
            if (!$current) {
                return false;
            }
            
            $updates = [];
            $params = [];
            
            if (isset($data['username'])) {
                $updates[] = "username = ?";
                $params[] = $data['username'];
            }
            
            if (isset($data['password']) && $data['password'] !== '') {
                $updates[] = "password = ?";
                $params[] = password_hash($data['password'], PASSWORD_DEFAULT);
            }
            
            // ENFORCE: Do not allow changing auth_method
            // auth_method is set at user creation and should not be modified
            // AD/LDAP users are managed through their authentication source
            
            if (isset($data['is_active'])) {
                $updates[] = "is_active = ?";
                $params[] = (int)$data['is_active'];
            }
            
            if (empty($updates)) {
                return true; // No changes to make
            }
            
            $params[] = $id;
            $sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute($params);
        } catch (Exception $e) {
            error_log("User update error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Assign a role to a user
     * 
     * @param int $user_id User ID
     * @param int $role_id Role ID
     * @return bool Success status
     */
    public function assignRole($user_id, $role_id) {
        try {
            $sql = "INSERT INTO user_roles (user_id, role_id, assigned_at)
                    VALUES (?, ?, NOW())
                    ON DUPLICATE KEY UPDATE assigned_at = NOW()";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([$user_id, $role_id]);
        } catch (Exception $e) {
            error_log("User assignRole error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Remove a role from a user
     * 
     * @param int $user_id User ID
     * @param int $role_id Role ID
     * @return bool Success status
     */
    public function removeRole($user_id, $role_id) {
        try {
            $sql = "DELETE FROM user_roles WHERE user_id = ? AND role_id = ?";
            
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([$user_id, $role_id]);
        } catch (Exception $e) {
            error_log("User removeRole error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get roles assigned to a user
     * 
     * @param int $user_id User ID
     * @return array Array of roles
     */
    public function getUserRoles($user_id) {
        try {
            $sql = "SELECT r.id, r.name, r.description, ur.assigned_at
                    FROM user_roles ur
                    INNER JOIN roles r ON ur.role_id = r.id
                    WHERE ur.user_id = ?
                    ORDER BY r.name ASC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$user_id]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("User getUserRoles error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * List all available roles
     * 
     * @return array Array of all roles
     */
    public function listRoles() {
        try {
            $sql = "SELECT id, name, description, created_at
                    FROM roles
                    ORDER BY name ASC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute();
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("User listRoles error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a role by ID
     * 
     * @param int $id Role ID
     * @return array|null Role data or null if not found
     */
    public function getRoleById($id) {
        try {
            $sql = "SELECT id, name, description, created_at
                    FROM roles
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("User getRoleById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get a role by name
     * 
     * @param string $name Role name
     * @return array|null Role data or null if not found
     */
    public function getRoleByName($name) {
        try {
            $sql = "SELECT id, name, description, created_at
                    FROM roles
                    WHERE name = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$name]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("User getRoleByName error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Deactivate a user (set is_active = 0)
     * 
     * @param int $id User ID to deactivate
     * @return bool Success status
     */
    public function deactivate($id) {
        try {
            $sql = "UPDATE users SET is_active = 0 WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            return $stmt->execute([$id]);
        } catch (Exception $e) {
            error_log("User deactivate error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Count active users with admin role
     * 
     * @return int Number of active admin users
     */
    public function countActiveAdmins() {
        try {
            $sql = "SELECT COUNT(DISTINCT u.id) as count
                    FROM users u
                    INNER JOIN user_roles ur ON u.id = ur.user_id
                    INNER JOIN roles r ON ur.role_id = r.id
                    WHERE u.is_active = 1 AND r.name = 'admin'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute();
            $result = $stmt->fetch();
            return (int)($result['count'] ?? 0);
        } catch (Exception $e) {
            error_log("User countActiveAdmins error: " . $e->getMessage());
            return 0;
        }
    }

    /**
     * Check if user has admin role
     * 
     * @param int $user_id User ID
     * @return bool True if user has admin role
     */
    public function hasAdminRole($user_id) {
        try {
            $sql = "SELECT COUNT(*) as count
                    FROM user_roles ur
                    INNER JOIN roles r ON ur.role_id = r.id
                    WHERE ur.user_id = ? AND r.name = 'admin'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$user_id]);
            $result = $stmt->fetch();
            return (int)($result['count'] ?? 0) > 0;
        } catch (Exception $e) {
            error_log("User hasAdminRole error: " . $e->getMessage());
            return false;
        }
    }
}
?>
