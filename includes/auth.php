<?php
// Authentication handler for database, Active Directory, and OpenLDAP

require_once __DIR__ . '/db.php';

class Auth {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Authenticate user with multiple methods
     */
    public function login($username, $password, $method = 'auto') {
        // Try database authentication first if auto or database
        if ($method === 'auto' || $method === 'database') {
            if ($this->authenticateDatabase($username, $password)) {
                return true;
            }
        }

        // Try Active Directory if auto or ad
        if ($method === 'auto' || $method === 'ad') {
            if ($this->authenticateActiveDirectory($username, $password)) {
                return true;
            }
        }

        // Try OpenLDAP if auto or ldap
        if ($method === 'auto' || $method === 'ldap') {
            if ($this->authenticateLDAP($username, $password)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Database authentication
     */
    private function authenticateDatabase($username, $password) {
        try {
            $stmt = $this->db->prepare("SELECT id, username, email, password, auth_method FROM users WHERE username = ? AND is_active = 1");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user && password_verify($password, $user['password'])) {
                $this->createSession($user);
                $this->updateLastLogin($user['id']);
                return true;
            }
        } catch (Exception $e) {
            error_log("Database auth error: " . $e->getMessage());
        }
        return false;
    }

    /**
     * Active Directory authentication
     */
    private function authenticateActiveDirectory($username, $password) {
        if (!function_exists('ldap_connect')) {
            return false;
        }

        try {
            $ldap = ldap_connect(AD_SERVER, AD_PORT);
            if (!$ldap) {
                return false;
            }

            ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);

            $bind_username = AD_DOMAIN . '\\' . $username;
            if (@ldap_bind($ldap, $bind_username, $password)) {
                // Search for user details and groups
                $filter = "(sAMAccountName=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
                $result = ldap_search($ldap, AD_BASE_DN, $filter, ['mail', 'cn', 'memberOf']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $email = $entries[0]['mail'][0] ?? $username . '@' . AD_DOMAIN;
                    $user_dn = $entries[0]['dn'] ?? '';
                    
                    // Get user groups
                    $groups = [];
                    if (isset($entries[0]['memberof'])) {
                        for ($i = 0; $i < $entries[0]['memberof']['count']; $i++) {
                            $groups[] = $entries[0]['memberof'][$i];
                        }
                    }
                    
                    // Create or update user and apply role mappings
                    $this->createOrUpdateUserWithMappings($username, $email, 'ad', $groups, $user_dn);
                    ldap_close($ldap);
                    return true;
                }
            }
            ldap_close($ldap);
        } catch (Exception $e) {
            error_log("AD auth error: " . $e->getMessage());
        }
        return false;
    }

    /**
     * OpenLDAP authentication
     */
    private function authenticateLDAP($username, $password) {
        if (!function_exists('ldap_connect')) {
            return false;
        }

        try {
            $ldap = ldap_connect(LDAP_SERVER, LDAP_PORT);
            if (!$ldap) {
                return false;
            }

            ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);

            // First bind with admin credentials to search for user
            if (@ldap_bind($ldap, LDAP_BIND_DN, LDAP_BIND_PASS)) {
                $filter = "(uid=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
                $result = ldap_search($ldap, LDAP_BASE_DN, $filter, ['dn', 'mail', 'cn']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $user_dn = $entries[0]['dn'];
                    $email = $entries[0]['mail'][0] ?? $username . '@example.com';

                    // Try to bind with user credentials
                    if (@ldap_bind($ldap, $user_dn, $password)) {
                        // User authenticated successfully
                        // Create or update user and apply role mappings
                        $this->createOrUpdateUserWithMappings($username, $email, 'ldap', [], $user_dn);
                        ldap_close($ldap);
                        return true;
                    }
                }
            }
            ldap_close($ldap);
        } catch (Exception $e) {
            error_log("LDAP auth error: " . $e->getMessage());
        }
        return false;
    }

    /**
     * Create or update user in database for LDAP/AD users
     * Apply role mappings based on groups/DN
     */
    private function createOrUpdateUserWithMappings($username, $email, $auth_method, $groups = [], $user_dn = '') {
        try {
            $stmt = $this->db->prepare("SELECT id, username, email FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user) {
                // Update existing user
                $stmt = $this->db->prepare("UPDATE users SET email = ?, auth_method = ?, last_login = NOW() WHERE id = ?");
                $stmt->execute([$email, $auth_method, $user['id']]);
                $user_id = $user['id'];
            } else {
                // Create new user with minimal required fields
                $stmt = $this->db->prepare("INSERT INTO users (username, email, password, auth_method, is_active, created_at) VALUES (?, ?, '', ?, 1, NOW())");
                $stmt->execute([$username, $email, $auth_method]);
                $user_id = $this->db->lastInsertId();
                $user = [
                    'id' => $user_id,
                    'username' => $username,
                    'email' => $email,
                    'auth_method' => $auth_method
                ];
            }
            
            // Apply role mappings from auth_mappings table
            $this->applyRoleMappings($user_id, $auth_method, $groups, $user_dn);
            
            // Create session after user is created/updated
            $this->createSession($user);
            $this->updateLastLogin($user_id);
        } catch (Exception $e) {
            error_log("Create/update user with mappings error: " . $e->getMessage());
        }
    }
    
    /**
     * Apply role mappings based on AD groups or LDAP DN
     */
    private function applyRoleMappings($user_id, $auth_method, $groups = [], $user_dn = '') {
        try {
            // Get all mappings for this auth source
            $stmt = $this->db->prepare("SELECT id, dn_or_group, role_id FROM auth_mappings WHERE source = ?");
            $stmt->execute([$auth_method]);
            $mappings = $stmt->fetchAll();
            
            foreach ($mappings as $mapping) {
                $matches = false;
                
                if ($auth_method === 'ad') {
                    // For AD: check if user is member of the mapped group
                    foreach ($groups as $group_dn) {
                        if (strcasecmp($group_dn, $mapping['dn_or_group']) === 0) {
                            $matches = true;
                            break;
                        }
                    }
                } elseif ($auth_method === 'ldap') {
                    // For LDAP: check if user DN contains the mapped DN/OU path
                    // Case-insensitive containment check
                    if ($user_dn && stripos($user_dn, $mapping['dn_or_group']) !== false) {
                        $matches = true;
                    }
                }
                
                if ($matches) {
                    // Assign role to user (INSERT IGNORE / ON DUPLICATE KEY UPDATE)
                    $stmt = $this->db->prepare(
                        "INSERT INTO user_roles (user_id, role_id, assigned_at) 
                         VALUES (?, ?, NOW()) 
                         ON DUPLICATE KEY UPDATE assigned_at = NOW()"
                    );
                    $stmt->execute([$user_id, $mapping['role_id']]);
                }
            }
        } catch (Exception $e) {
            error_log("Apply role mappings error: " . $e->getMessage());
        }
    }

    /**
     * Create user session
     */
    private function createSession($user) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['email'] = $user['email'];
        $_SESSION['logged_in'] = true;
    }

    /**
     * Update last login timestamp
     */
    private function updateLastLogin($user_id) {
        try {
            $stmt = $this->db->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
            $stmt->execute([$user_id]);
        } catch (Exception $e) {
            error_log("Update last login error: " . $e->getMessage());
        }
    }

    /**
     * Logout user
     */
    public function logout() {
        $_SESSION = [];
        if (ini_get("session.use_cookies")) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params["path"], $params["domain"],
                $params["secure"], $params["httponly"]
            );
        }
        session_destroy();
    }

    /**
     * Check if user is logged in
     */
    public function isLoggedIn() {
        return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
    }

    /**
     * Get current user info
     */
    public function getCurrentUser() {
        if ($this->isLoggedIn()) {
            return [
                'id' => $_SESSION['user_id'],
                'username' => $_SESSION['username'],
                'email' => $_SESSION['email']
            ];
        }
        return null;
    }

    /**
     * Check if current user is an administrator
     */
    public function isAdmin() {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        try {
            $stmt = $this->db->prepare("
                SELECT COUNT(*) as is_admin
                FROM user_roles ur
                INNER JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = ? AND r.name = 'admin'
            ");
            $stmt->execute([$_SESSION['user_id']]);
            $result = $stmt->fetch();
            
            return $result && $result['is_admin'] > 0;
        } catch (Exception $e) {
            error_log("isAdmin check error: " . $e->getMessage());
            return false;
        }
    }
}
?>
