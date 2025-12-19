<?php
// Authentication handler for database, Active Directory, and OpenLDAP

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/models/Acl.php';
require_once __DIR__ . '/models/ApiToken.php';

class Auth {
    private $db;
    private $acl = null;
    private $apiToken = null;
    private $lastError = null;

    /**
     * Error message constants for access control
     */
    public const ERR_ZONE_ACCESS_DENIED = 'Vous devez être administrateur ou avoir des permissions sur au moins une zone pour accéder à cette page.';
    public const ERR_ADMIN_ONLY = 'Cette page est réservée aux administrateurs.';

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
     * Get the ApiToken instance (lazy-loaded and cached)
     * 
     * @return ApiToken The API token model instance
     */
    private function getApiToken() {
        if ($this->apiToken === null) {
            $this->apiToken = new ApiToken();
        }
        return $this->apiToken;
    }

    /**
     * Get the last authentication error code
     * 
     * @return string|null Error code or null if no error
     */
    public function getLastError() {
        return $this->lastError;
    }

    /**
     * Authenticate using Bearer token from Authorization header
     * Sets up session-like state in $_SESSION for compatibility
     * 
     * Note: session_start() is called in config.php before this code runs
     * 
     * @return bool True if authenticated successfully
     */
    public function authenticateToken() {
        // Check for Authorization header
        $headers = getallheaders();
        $authHeader = null;
        
        // Case-insensitive header lookup
        foreach ($headers as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $authHeader = $value;
                break;
            }
        }
        
        if (!$authHeader) {
            return false;
        }
        
        // Parse Bearer token
        if (!preg_match('/^Bearer\s+(\S+)$/i', $authHeader, $matches)) {
            return false;
        }
        
        $token = $matches[1];
        
        // Validate token
        $userInfo = $this->getApiToken()->validate($token);
        
        if (!$userInfo) {
            return false;
        }
        
        // Create session-like state for compatibility with existing code
        // Session was already started in config.php
        $_SESSION['user_id'] = $userInfo['id'];
        $_SESSION['username'] = $userInfo['username'];
        $_SESSION['logged_in'] = true;
        $_SESSION['auth_method'] = 'api_token';
        $_SESSION['token_id'] = $userInfo['token_id'];
        $_SESSION['token_name'] = $userInfo['token_name'];
        $_SESSION['user_groups'] = []; // API tokens don't have AD/LDAP groups
        
        return true;
    }

    /**
     * Authenticate user with multiple methods
     */
    public function login($username, $password, $method = 'auto') {
        // Reset error at the beginning
        $this->lastError = null;
        
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

        // All authentication methods failed
        // If no error was set, default to invalid_credentials
        if ($this->lastError === null) {
            $this->lastError = 'invalid_credentials';
        }
        
        return false;
    }

    /**
     * Database authentication
     */
    private function authenticateDatabase($username, $password) {
        try {
            $stmt = $this->db->prepare("SELECT id, username, password, auth_method FROM users WHERE username = ? AND is_active = 1");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user && password_verify($password, $user['password'])) {
                $this->createSession($user);
                $this->updateLastLogin($user['id']);
                return true;
            }
            
            // User not found or invalid password
            $this->lastError = 'invalid_credentials';
        } catch (Exception $e) {
            error_log("Database auth error: " . $e->getMessage());
            $this->lastError = 'invalid_credentials';
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
                $this->lastError = 'server_unreachable';
                return false;
            }

            ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);
            
            // Set timeouts for network operations (3 seconds)
            // @ suppression is intentional - these options may not be available in all PHP/LDAP versions
            // If they fail, authentication will continue but without the timeout benefit
            @ldap_set_option($ldap, LDAP_OPT_NETWORK_TIMEOUT, 3);
            @ldap_set_option($ldap, LDAP_OPT_TIMELIMIT, 3);

            $bind_username = AD_DOMAIN . '\\' . $username;
            if (@ldap_bind($ldap, $bind_username, $password)) {
                // Search for user details and groups
                $filter = "(sAMAccountName=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
                $result = ldap_search($ldap, AD_BASE_DN, $filter, ['cn', 'sAMAccountName', 'memberOf']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $user_dn = $entries[0]['dn'] ?? '';
                    
                    // Determine storedUsername: prefer CN, fallback to sAMAccountName
                    // Normalize to lowercase for consistency
                    $storedUsername = mb_strtolower(
                        $entries[0]['samaccountname'][0] ?? $entries[0]['cn'][0] ?? $username
                    );
                    
                    // Get user groups
                    $groups = [];
                    if (isset($entries[0]['memberof'])) {
                        for ($i = 0; $i < $entries[0]['memberof']['count']; $i++) {
                            $groups[] = $entries[0]['memberof'][$i];
                        }
                    }
                    
                    // Build list of comparable values for mapping matching
                    $comparableValues = $groups; // Start with AD groups
                    
                    // Add sAMAccountName as a comparable value
                    if (isset($entries[0]['samaccountname'][0])) {
                        $comparableValues[] = 'sAMAccountName:' . $entries[0]['samaccountname'][0];
                    }
                    
                    // Get matched role IDs from auth_mappings
                    $matchedRoleIds = $this->getRoleIdsFromMappings('ad', $comparableValues, $user_dn);
                    
                    // Check if user has any ACL entry (by username, role, or AD group)
                    require_once __DIR__ . '/models/ZoneAcl.php';
                    $zoneAcl = new ZoneAcl();
                    $hasAcl = $zoneAcl->hasAnyAclForUser($storedUsername, $matchedRoleIds, $groups);
                    
                    // Authorize if user has mappings OR has ACL entries
                    if (empty($matchedRoleIds) && !$hasAcl) {
                        // No mapping and no ACL - refuse connection and disable existing user
                        $this->findAndDisableExistingUser($storedUsername, 'ad');
                        $this->lastError = 'no_access';
                        ldap_close($ldap);
                        return false;
                    }
                    
                    // Create or update user with normalized username
                    $this->createOrUpdateUserWithMappings($storedUsername, 'ad', $groups, $user_dn, $comparableValues);
                    
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
                
                // User not found in search results
                $this->lastError = 'invalid_credentials';
            } else {
                // User bind failed - invalid credentials
                $this->lastError = 'invalid_credentials';
            }
            ldap_close($ldap);
        } catch (Exception $e) {
            error_log("AD auth error: " . $e->getMessage());
            $this->lastError = 'server_unreachable';
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
                $this->lastError = 'server_unreachable';
                return false;
            }

            ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
            
            // Set timeouts for network operations (3 seconds)
            // @ suppression is intentional - these options may not be available in all PHP/LDAP versions
            // If they fail, authentication will continue but without the timeout benefit
            @ldap_set_option($ldap, LDAP_OPT_NETWORK_TIMEOUT, 3);
            @ldap_set_option($ldap, LDAP_OPT_TIMELIMIT, 3);

            // First bind with admin credentials to search for user
            if (@ldap_bind($ldap, LDAP_BIND_DN, LDAP_BIND_PASS)) {
                $filter = "(uid=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
                // Retrieve attributes for authentication and mapping
                $result = ldap_search($ldap, LDAP_BASE_DN, $filter, ['dn', 'cn', 'uid', 'departmentNumber']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $user_dn = $entries[0]['dn'];
                    
                    // Determine storedUsername: prefer UID, fallback to username
                    // Normalize to lowercase for consistency
                    $storedUsername = mb_strtolower(
                        $entries[0]['uid'][0] ?? $username
                    );

                    // Try to bind with user credentials
                    if (@ldap_bind($ldap, $user_dn, $password)) {
                        // User authenticated successfully
                        
                        // Build list of comparable values for mapping matching
                        $comparableValues = [];
                        
                        // Add uid as a comparable value
                        if (isset($entries[0]['uid'][0])) {
                            $comparableValues[] = 'uid:' . $entries[0]['uid'][0];
                        }
                        
                        // Add departmentNumber as a comparable value
                        // Note: LDAP returns attribute names in lowercase (departmentnumber)
                        if (isset($entries[0]['departmentnumber'][0])) {
                            $comparableValues[] = 'departmentNumber:' . $entries[0]['departmentnumber'][0];
                        }
                        
                        // Get matched role IDs from auth_mappings
                        $matchedRoleIds = $this->getRoleIdsFromMappings('ldap', $comparableValues, $user_dn);
                        
                        // Check if user has any ACL entry (by username)
                        // LDAP typically doesn't have groups like AD, but we check anyway
                        require_once __DIR__ . '/models/ZoneAcl.php';
                        $zoneAcl = new ZoneAcl();
                        $hasAcl = $zoneAcl->hasAnyAclForUser($storedUsername, $matchedRoleIds, []);
                        
                        // Authorize if user has mappings OR has ACL entries
                        if (empty($matchedRoleIds) && !$hasAcl) {
                            // No mapping and no ACL - refuse connection and disable existing user
                            $this->findAndDisableExistingUser($storedUsername, 'ldap');
                            $this->lastError = 'no_access';
                            ldap_close($ldap);
                            return false;
                        }
                        
                        // Create or update user with normalized username
                        $this->createOrUpdateUserWithMappings($storedUsername, 'ldap', [], $user_dn, $comparableValues);
                        
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
                    } else {
                        // User bind failed - invalid password
                        $this->lastError = 'invalid_credentials';
                    }
                } else {
                    // User not found in LDAP search
                    $this->lastError = 'invalid_credentials';
                }
            } else {
                // Service bind failed - LDAP server or credentials issue
                $this->lastError = 'ldap_bind_failed';
            }
            ldap_close($ldap);
        } catch (Exception $e) {
            error_log("LDAP auth error: " . $e->getMessage());
            $this->lastError = 'server_unreachable';
        }
        return false;
    }

    /**
     * Create or update user in database for LDAP/AD users
     * Apply role mappings based on comparable values and DN
     * 
     * @param string $username Username
     * @param string $auth_method Authentication method ('ad' or 'ldap')
     * @param array $groups AD/LDAP groups for session storage and ACL checks
     * @param string $user_dn User's full DN
     * @param array $comparableValues Values for mapping comparison (groups, sAMAccountName:value, uid:value, etc.)
     */
    private function createOrUpdateUserWithMappings($username, $auth_method, $groups = [], $user_dn = '', $comparableValues = []) {
        try {
            $stmt = $this->db->prepare("SELECT id, username FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user) {
                // Update existing user
                $stmt = $this->db->prepare("UPDATE users SET auth_method = ?, last_login = NOW() WHERE id = ?");
                $stmt->execute([$auth_method, $user['id']]);
                $user_id = $user['id'];
            } else {
                // Create new user with minimal required fields
                $stmt = $this->db->prepare("INSERT INTO users (username, password, auth_method, is_active, created_at) VALUES (?, '', ?, 1, NOW())");
                $stmt->execute([$username, $auth_method]);
                $user_id = $this->db->lastInsertId();
                $user = [
                    'id' => $user_id,
                    'username' => $username,
                    'auth_method' => $auth_method
                ];
            }
            
            // Apply role mappings from auth_mappings table
            // Use comparableValues if provided, otherwise fallback to groups for backward compatibility
            // Fallback occurs when createOrUpdateUserWithMappings is called without comparableValues parameter
            $valuesToCompare = !empty($comparableValues) ? $comparableValues : $groups;
            $this->applyRoleMappings($user_id, $auth_method, $valuesToCompare, $user_dn);
            
            // Create session after user is created/updated
            // $groups contains AD/LDAP memberOf groups, stored in session for zone ACL checks
            $this->createSession($user, $groups);
            $this->updateLastLogin($user_id);
        } catch (Exception $e) {
            error_log("Create/update user with mappings error: " . $e->getMessage());
        }
    }
    
    /**
     * Apply role mappings based on comparable values or LDAP DN
     * Uses getRoleIdsFromMappings to get matched roles and applies them
     * 
     * @param int $user_id User ID
     * @param string $auth_method Authentication method ('ad' or 'ldap')
     * @param array $comparableValues Values for comparison (groups, sAMAccountName:value, uid:value, etc.)
     * @param string $user_dn User's full DN
     */
    private function applyRoleMappings($user_id, $auth_method, $comparableValues = [], $user_dn = '') {
        try {
            $matchedRoleIds = $this->getRoleIdsFromMappings($auth_method, $comparableValues, $user_dn);
            
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
     * 
     * @param string $auth_method Authentication method ('ad' or 'ldap')
     * @param array $comparableValues Array of values to compare (AD groups, sAMAccountName:value, uid:value, departmentNumber:value, etc.)
     * @param string $user_dn User's full DN (for LDAP OU matching)
     * @return array Array of matched role IDs
     */
    private function getRoleIdsFromMappings($auth_method, $comparableValues = [], $user_dn = '') {
        $matchedRoleIds = [];
        try {
            $stmt = $this->db->prepare("SELECT id, dn_or_group, role_id FROM auth_mappings WHERE source = ?");
            $stmt->execute([$auth_method]);
            $mappings = $stmt->fetchAll();
            
            foreach ($mappings as $mapping) {
                $matches = false;
                
                // Check for exact match (case-insensitive) against comparable values
                // This handles: AD groups (DNs), sAMAccountName:value, uid:value, departmentNumber:value
                foreach ($comparableValues as $value) {
                    if (strcasecmp($value, $mapping['dn_or_group']) === 0) {
                        $matches = true;
                        break;
                    }
                }
                
                // For LDAP: also check if user DN contains the mapped DN/OU path
                // This is for backward compatibility with existing OU-based mappings
                if (!$matches && $auth_method === 'ldap' && $user_dn) {
                    if (stripos($user_dn, $mapping['dn_or_group']) !== false) {
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
        $_SESSION['logged_in'] = true;
        $_SESSION['auth_method'] = $user['auth_method'] ?? 'database';
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
                'username' => $_SESSION['username']
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
     * Get all zone file IDs that the current user has access to
     * Used to filter zone lists for non-admin users
     * 
     * @param string $minPermission Minimum required permission level (read, write, admin)
     * @return array Array of zone_file_id values the user can access
     */
    public function getAllowedZoneIds($minPermission = 'read') {
        if (!$this->isLoggedIn()) {
            return [];
        }
        
        try {
            $username = $_SESSION['username'] ?? '';
            $userGroups = $this->getUserGroups();
            
            return $this->getAcl()->getAllowedZoneIds($username, $minPermission, $userGroups);
        } catch (Exception $e) {
            error_log("getAllowedZoneIds error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get all zone file IDs that the current user has access to, expanded to include parent masters
     * For users with ACL on include zones, this also includes the parent master zones
     * 
     * @param string $minPermission Minimum required permission level (read, write, admin)
     * @return array Array of zone_file_id values the user can access (including parent masters)
     */
    public function getExpandedZoneIds($minPermission = 'read') {
        if (!$this->isLoggedIn()) {
            return [];
        }
        
        try {
            $zoneIds = $this->getAllowedZoneIds($minPermission);
            return $this->getAcl()->expandZoneIdsToMasters($zoneIds);
        } catch (Exception $e) {
            error_log("getExpandedZoneIds error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get all master zone file IDs that the current user can see
     * For users with ACL on include zones, this includes the parent master zones
     * Filters the expanded zone list to only return master zones
     * 
     * @param string $minPermission Minimum required permission level (read, write, admin)
     * @return array Array of master zone_file_id values the user can access
     */
    public function getExpandedMasterZoneIds($minPermission = 'read') {
        if (!$this->isLoggedIn()) {
            return [];
        }
        
        try {
            $expandedIds = $this->getExpandedZoneIds($minPermission);
            if (empty($expandedIds)) {
                return [];
            }
            
            // Filter to only return master zone IDs
            $db = Database::getInstance()->getConnection();
            $placeholders = implode(',', array_fill(0, count($expandedIds), '?'));
            $sql = "SELECT id FROM zone_files 
                    WHERE id IN ($placeholders) 
                    AND file_type = 'master' 
                    AND status = 'active'";
            $stmt = $db->prepare($sql);
            $stmt->execute($expandedIds);
            return $stmt->fetchAll(PDO::FETCH_COLUMN);
        } catch (Exception $e) {
            error_log("getExpandedMasterZoneIds error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Check if the current user is allowed to access a specific zone
     * 
     * @param int $zoneFileId Zone file ID
     * @param string $requiredPermission Required permission level (read, write, admin)
     * @return bool True if user has the required permission for this zone
     */
    public function isAllowedForZone($zoneFileId, $requiredPermission = 'read') {
        if (!$this->isLoggedIn()) {
            return false;
        }
        
        // Admins have access to all zones
        if ($this->isAdmin()) {
            return true;
        }
        
        try {
            $username = $_SESSION['username'] ?? '';
            $userGroups = $this->getUserGroups();
            
            return $this->getAcl()->isAllowedForZone($username, $zoneFileId, $requiredPermission, $userGroups);
        } catch (Exception $e) {
            error_log("isAllowedForZone error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Apply auth mappings for a user based on their source (AD/LDAP) and groups/DN
     * Public helper method that can be called during authentication or later
     * 
     * @param string $source Authentication source ('ad' or 'ldap')
     * @param array $dnOrGroups Array of AD group DNs or LDAP user DN (wrapped in array)
     * @param int $userId User ID to apply mappings for
     * @return array Array of role IDs that were applied
     */
    public function applyAuthMappings($source, array $dnOrGroups, $userId) {
        try {
            // Validate userId is a positive integer
            if (!is_numeric($userId) || (int)$userId <= 0 || !in_array($source, ['ad', 'ldap'])) {
                return [];
            }
            $userId = (int)$userId;
            
            // For AD, $dnOrGroups are the group memberships
            // For LDAP, $dnOrGroups typically contains a single user DN
            $groups = ($source === 'ad') ? $dnOrGroups : [];
            $userDn = ($source === 'ldap' && !empty($dnOrGroups)) ? $dnOrGroups[0] : '';
            
            $matchedRoleIds = $this->getRoleIdsFromMappings($source, $groups, $userDn);
            
            foreach ($matchedRoleIds as $roleId) {
                // Assign role to user (INSERT IGNORE / ON DUPLICATE KEY UPDATE)
                $stmt = $this->db->prepare(
                    "INSERT INTO user_roles (user_id, role_id, assigned_at) 
                     VALUES (?, ?, NOW()) 
                     ON DUPLICATE KEY UPDATE assigned_at = NOW()"
                );
                $stmt->execute([$userId, $roleId]);
            }
            
            return $matchedRoleIds;
        } catch (Exception $e) {
            error_log("applyAuthMappings error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Check if a user has a specific role by role name
     * Public helper method for checking role membership
     * 
     * @param int $userId User ID to check
     * @param string $roleName Role name to check for
     * @return bool True if user has the specified role
     */
    public function userHasRole($userId, $roleName) {
        try {
            // Validate userId is a positive integer
            if (!is_numeric($userId) || (int)$userId <= 0 || empty($roleName)) {
                return false;
            }
            
            $stmt = $this->db->prepare("
                SELECT COUNT(*) as has_role
                FROM user_roles ur
                INNER JOIN roles r ON ur.role_id = r.id
                WHERE ur.user_id = ? AND r.name = ?
            ");
            $stmt->execute([$userId, $roleName]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            return (int)($result['has_role'] ?? 0) > 0;
        } catch (Exception $e) {
            error_log("userHasRole error: " . $e->getMessage());
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
