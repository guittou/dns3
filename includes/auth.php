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
                // Search for user details
                $filter = "(sAMAccountName=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
                $result = ldap_search($ldap, AD_BASE_DN, $filter, ['mail', 'cn']);
                $entries = ldap_get_entries($ldap, $result);

                if ($entries['count'] > 0) {
                    $email = $entries[0]['mail'][0] ?? $username . '@' . AD_DOMAIN;
                    $this->createOrUpdateUser($username, $email, 'ad');
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
                        $this->createOrUpdateUser($username, $email, 'ldap');
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
     */
    private function createOrUpdateUser($username, $email, $auth_method) {
        try {
            $stmt = $this->db->prepare("SELECT id, username, email FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch();

            if ($user) {
                // Update existing user
                $stmt = $this->db->prepare("UPDATE users SET email = ?, auth_method = ?, last_login = NOW() WHERE id = ?");
                $stmt->execute([$email, $auth_method, $user['id']]);
                $this->createSession($user);
            } else {
                // Create new user
                $stmt = $this->db->prepare("INSERT INTO users (username, email, password, auth_method) VALUES (?, ?, '', ?)");
                $stmt->execute([$username, $email, $auth_method]);
                $user = [
                    'id' => $this->db->lastInsertId(),
                    'username' => $username,
                    'email' => $email,
                    'auth_method' => $auth_method
                ];
                $this->createSession($user);
                $this->updateLastLogin($user['id']);
            }
        } catch (Exception $e) {
            error_log("Create/update user error: " . $e->getMessage());
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
}
?>
