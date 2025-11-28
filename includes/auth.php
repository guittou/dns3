<?php
// Authentication handler for database, Active Directory, and OpenLDAP

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/models/Acl.php';

class Auth {
    private $db;
    private $acl = null;

    /**
     * Error message constants for access control
     */
    public const ERR_ZONE_ACCESS_DENIED = 'Vous devez être administrateur ou avoir des permissions sur au moins une zone pour accéder à cette page.';

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Get the Acl instance (lazy-loaded and cached)
     * 
     * @return Acl The ACL model instance
     */
    private function getAcl() {
        if ($this->acl === null) {
            $this->acl = new Acl();
        }
        return $this->acl;
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
                $result = ldap_search($ldap, AD_BASE_DN, $filter, ['mail', 'cn', 'sAMAccountName', 'memberOf']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $email = $entries[0]['mail'][0] ?? $username . '@' . AD_DOMAIN;
                    $user_dn = $entries[0]['dn'] ?? '';
                    
                    // Determine storedUsername: prefer CN, fallback to sAMAccountName
                    // Normalize to lowercase for consistency
                    $storedUsername = mb_strtolower(
                        $entries[0]['cn'][0] ?? $entries[0]['samaccountname'][0] ?? $username
                    );
                    
                    // Get user groups
                    $groups = [];
                    if (isset($entries[0]['memberof'])) {
                        for ($i = 0; $i < $entries[0]['memberof']['count']; $i++) {
                            $groups[] = $entries[0]['memberof'][$i];
                        }
                    }
                    
                    // Get matched role IDs from auth_mappings
                    $matchedRoleIds = $this->getRoleIdsFromMappings('ad', $groups, $user_dn);
                    
                    // Check if user has any ACL entry (by username, role, or AD group)
                    require_once __DIR__ . '/models/ZoneAcl.php';
                    $zoneAcl = new ZoneAcl();
                    $hasAcl = $zoneAcl->hasAnyAclForUser($storedUsername, $matchedRoleIds, $groups);
                    
                    // Authorize if user has mappings OR has ACL entries
                    if (empty($matchedRoleIds) && !$hasAcl) {
                        // No mapping and no ACL - refuse connection and disable existing user
                        $this->findAndDisableExistingUser($storedUsername, 'ad');
                        ldap_close($ldap);
                        return false;
                    }
                    
                    // Create or update user with normalized username
                    $this->createOrUpdateUserWithMappings($storedUsername, $email, 'ad', $groups, $user_dn);
                    
                    // Get user ID and perform post-login actions
                    $user_id = $this->getUserIdByUsername($storedUsername);
                    if ($user_id) {
                        // Reactivate account (in case it was previously disabled)
                        $this->reactivateUserAccount($user_id);
                        
                        // Sync roles based on current mappings (only if mappings exist)
                        if (!empty($matchedRoleIds)) {
                            $this->syncUserRolesWithMappings($user_id, 'ad', $matchedRoleIds);
                        }
                    }
                    
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
                $result = ldap_search($ldap, LDAP_BASE_DN, $filter, ['dn', 'mail', 'cn', 'uid']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $user_dn = $entries[0]['dn'];
                    $email = $entries[0]['mail'][0] ?? $username . '@example.com';
                    
                    // Determine storedUsername: prefer UID, fallback to username
                    // Normalize to lowercase for consistency
                    $storedUsername = mb_strtolower(
                        $entries[0]['uid'][0] ?? $username
                    );

                    // Try to bind with user credentials
                    if (@ldap_bind($ldap, $user_dn, $password)) {
                        // User authenticated successfully
                        // Get matched role IDs from auth_mappings
                        $matchedRoleIds = $this->getRoleIdsFromMappings('ldap', [], $user_dn);
                        
                        // Check if user has any ACL entry (by username)
                        // LDAP typically doesn't have groups like AD, but we check anyway
                        require_once __DIR__ . '/models/ZoneAcl.php';
                        $zoneAcl = new ZoneAcl();
                        $hasAcl = $zoneAcl->hasAnyAclForUser($storedUsername, $matchedRoleIds, []);
                        
                        // Authorize if user has mappings OR has ACL entries
                        if (empty($matchedRoleIds) && !$hasAcl) {
                            // No mapping and no ACL - refuse connection and disable existing user
                            $this->findAndDisableExistingUser($storedUsername, 'ldap');
                            ldap_close($ldap);
                            return false;
                        }
                        
                        // Create or update user with normalized username
                        $this->createOrUpdateUserWithMappings($storedUsername, $email, 'ldap', [], $user_dn);
                        
                        // Get user ID and perform post-login actions
                        $user_id = $this->getUserIdByUsername($storedUsername);
                        if ($user_id) {
                            // Reactivate account (in case it was previously disabled)
                            $this->reactivateUserAccount($user_id);
                            
                            // Sync roles based on current mappings (only if mappings exist)
                            if (!empty($matchedRoleIds)) {
                                $this->syncUserRolesWithMappings($user_id, 'ldap', $matchedRoleIds);
                            }
                        }
                        
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
            // $groups contains AD/LDAP memberOf groups, stored in session for zone ACL checks
            $this->createSession($user, $groups);
            $this->updateLastLogin($user_id);
        } catch (Exception $e) {
            error_log("Create/update user with mappings error: " . $e->getMessage());
        }
    }
    
    /**
     * Apply role mappings based on AD groups or LDAP DN
     * Uses getRoleIdsFromMappings to get matched roles and applies them
     */
    private function applyRoleMappings($user_id, $auth_method, $groups = [], $user_dn = '') {
        try {
            $matchedRoleIds = $this->getRoleIdsFromMappings($auth_method, $groups, $user_dn);
            
            foreach ($matchedRoleIds as $roleId) {
                // Assign role to user (INSERT IGNORE / ON DUPLICATE KEY UPDATE)
                $stmt = $this->db->prepare(
                    "INSERT INTO user_roles (user_id, role_id, assigned_at) 
                     VALUES (?, ?, NOW()) 
                     ON DUPLICATE KEY UPDATE assigned_at = NOW()"
                );
                $stmt->execute([$user_id, $roleId]);
            }
        } catch (Exception $e) {
            error_log("Apply role mappings error: " . $e->getMessage());
        }
    }

    /**
     * Get role IDs from auth_mappings that match user's groups/DN
     * Returns array of matched role IDs
     */
    private function getRoleIdsFromMappings($auth_method, $groups = [], $user_dn = '') {
        $matchedRoleIds = [];
        try {
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
                    if ($user_dn && stripos($user_dn, $mapping['dn_or_group']) !== false) {
                        $matches = true;
                    }
                }
                
                if ($matches && !in_array($mapping['role_id'], $matchedRoleIds)) {
                    $matchedRoleIds[] = $mapping['role_id'];
                }
            }
        } catch (Exception $e) {
            error_log("Get role IDs from mappings error: " . $e->getMessage());
        }
        return $matchedRoleIds;
    }

    /**
     * Synchronize user roles with auth_mappings
     * - Adds missing mapped roles
     * - Removes roles that came from mappings but no longer match
     * - Does NOT remove manually assigned roles (roles not defined in any mapping for this auth source)
     */
    private function syncUserRolesWithMappings($user_id, $auth_method, array $matchedRoleIds) {
        try {
            // Get all role IDs that are defined in auth_mappings for this source
            $stmt = $this->db->prepare("SELECT DISTINCT role_id FROM auth_mappings WHERE source = ?");
            $stmt->execute([$auth_method]);
            $mappingRoleIds = array_column($stmt->fetchAll(), 'role_id');
            
            // Get current user roles
            $stmt = $this->db->prepare("SELECT role_id FROM user_roles WHERE user_id = ?");
            $stmt->execute([$user_id]);
            $currentRoleIds = array_column($stmt->fetchAll(), 'role_id');
            
            // Add missing matched roles
            foreach ($matchedRoleIds as $roleId) {
                if (!in_array($roleId, $currentRoleIds)) {
                    $stmt = $this->db->prepare(
                        "INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (?, ?, NOW())"
                    );
                    $stmt->execute([$user_id, $roleId]);
                }
            }
            
            // Remove roles that come from mappings but are no longer matched
            // Only remove roles that are defined in auth_mappings for this source
            foreach ($currentRoleIds as $roleId) {
                // If this role is defined in mappings for this auth source
                // but is NOT in the matched roles, remove it
                if (in_array($roleId, $mappingRoleIds) && !in_array($roleId, $matchedRoleIds)) {
                    $stmt = $this->db->prepare("DELETE FROM user_roles WHERE user_id = ? AND role_id = ?");
                    $stmt->execute([$user_id, $roleId]);
                }
            }
        } catch (Exception $e) {
            error_log("Sync user roles with mappings error: " . $e->getMessage());
        }
    }

    /**
     * Disable user account (set is_active = 0)
     */
    private function disableUserAccount($user_id) {
        try {
            $stmt = $this->db->prepare("UPDATE users SET is_active = 0 WHERE id = ?");
            $stmt->execute([$user_id]);
        } catch (Exception $e) {
            error_log("Disable user account error: " . $e->getMessage());
        }
    }

    /**
     * Reactivate user account (set is_active = 1)
     */
    private function reactivateUserAccount($user_id) {
        try {
            $stmt = $this->db->prepare("UPDATE users SET is_active = 1 WHERE id = ?");
            $stmt->execute([$user_id]);
        } catch (Exception $e) {
            error_log("Reactivate user account error: " . $e->getMessage());
        }
    }

    /**
     * Find existing user by username and auth_method, and disable if found
     * Returns true if user was found and disabled, false otherwise
     */
    private function findAndDisableExistingUser($username, $auth_method) {
        try {
            $stmt = $this->db->prepare("SELECT id FROM users WHERE username = ? AND auth_method = ?");
            $stmt->execute([$username, $auth_method]);
            $existingUser = $stmt->fetch();
            
            if ($existingUser) {
                $this->disableUserAccount($existingUser['id']);
                return true;
            }
        } catch (Exception $e) {
            error_log("Find and disable existing user error: " . $e->getMessage());
        }
        return false;
    }

    /**
     * Get user ID by username
     */
    private function getUserIdByUsername($username) {
        try {
            $stmt = $this->db->prepare("SELECT id FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch();
            return $user ? $user['id'] : null;
        } catch (Exception $e) {
            error_log("Get user ID by username error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create user session
     */
    private function createSession($user, $groups = []) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['email'] = $user['email'];
        $_SESSION['logged_in'] = true;
        $_SESSION['user_groups'] = $groups;
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

    /**
     * Check if current user has the zone_editor role
     */
    public function isZoneEditor() {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        try {
            $stmt = $this->db->prepare("
                SELECT COUNT(*) as is_zone_editor
                FROM user_roles ur
                INNER JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = ? AND r.name = 'zone_editor'
            ");
            $stmt->execute([$_SESSION['user_id']]);
            $result = $stmt->fetch();
            
            return $result && $result['is_zone_editor'] > 0;
        } catch (Exception $e) {
            error_log("isZoneEditor check error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get the current user's role names
     * 
     * @return array Array of role names
     */
    public function getUserRoles() {
        if (!$this->isLoggedIn()) {
            return [];
        }
        
        try {
            $stmt = $this->db->prepare("
                SELECT r.name
                FROM user_roles ur
                INNER JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = ?
            ");
            $stmt->execute([$_SESSION['user_id']]);
            $results = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            return $results ?: [];
        } catch (Exception $e) {
            error_log("getUserRoles error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get user context for ACL checks
     * Returns an array with user ID and role names
     * 
     * @return array|null User context or null if not logged in
     */
    public function getUserContext() {
        if (!$this->isLoggedIn()) {
            return null;
        }
        
        return [
            'id' => $_SESSION['user_id'],
            'roles' => $this->getUserRoles()
        ];
    }

    /**
     * Get user's AD/LDAP groups from session
     * These are populated during AD/LDAP authentication
     * 
     * @return array Array of group DNs/names
     */
    public function getUserGroups() {
        return $_SESSION['user_groups'] ?? [];
    }

    /**
     * Check if current user has any zone ACL entry
     * This allows non-admin users with ACL to access zone/DNS management pages.
     * 
     * @return bool True if user has at least one ACL entry for any zone
     */
    public function hasZoneAcl() {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        try {
            $username = $_SESSION['username'] ?? '';
            $userGroups = $this->getUserGroups();
            
            return $this->getAcl()->hasAnyAclForUser($username, $userGroups);
        } catch (Exception $e) {
            error_log("hasZoneAcl check error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Check if the current request is an XHR (AJAX) request
     * 
     * @return bool True if the request is an XHR request
     */
    public static function isXhrRequest() {
        $xRequestedWith = isset($_SERVER['HTTP_X_REQUESTED_WITH']) 
            ? $_SERVER['HTTP_X_REQUESTED_WITH'] 
            : '';
        return $xRequestedWith !== '' && strcasecmp($xRequestedWith, 'xmlhttprequest') === 0;
    }

    /**
     * Send a JSON error response and exit
     * Used for XHR requests that need to receive JSON errors instead of HTML redirects
     * 
     * @param int $statusCode HTTP status code (e.g., 401, 403)
     * @param string $errorMessage Error message to send
     */
    public static function sendJsonError($statusCode, $errorMessage) {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($statusCode);
        $json = json_encode(['error' => $errorMessage], JSON_UNESCAPED_UNICODE);
        if ($json === false) {
            // Fallback if JSON encoding fails
            echo '{"error":"An error occurred"}';
        } else {
            echo $json;
        }
        exit;
    }
}
?>
