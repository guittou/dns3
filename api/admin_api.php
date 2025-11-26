<?php
/**
 * Admin API
 * Provides JSON endpoints for administrative operations
 * All endpoints require admin privileges
 * 
 * Endpoints:
 * - GET ?action=list_users - List all users with their roles
 * - GET ?action=get_user&id=X - Get a specific user
 * - POST ?action=create_user - Create a new user (JSON body)
 * - POST ?action=update_user&id=X - Update a user (JSON body)
 * - POST ?action=deactivate_user&id=X - Deactivate a user (set is_active=0)
 * - POST ?action=assign_role&user_id=X&role_id=Y - Assign role to user
 * - POST ?action=remove_role&user_id=X&role_id=Y - Remove role from user
 * - GET ?action=list_roles - List all available roles
 * - GET ?action=list_mappings - List all auth mappings (AD/LDAP)
 * - POST ?action=create_mapping - Create auth mapping (JSON body)
 * - POST ?action=delete_mapping&id=X - Delete auth mapping
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/User.php';

// Set JSON header
header('Content-Type: application/json');

// Initialize authentication
$auth = new Auth();

/**
 * Check if user is admin (required for all endpoints)
 */
function requireAdmin() {
    global $auth;
    if (!$auth->isLoggedIn()) {
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        exit;
    }
    if (!$auth->isAdmin()) {
        http_response_code(403);
        echo json_encode(['error' => 'Admin privileges required']);
        exit;
    }
}

// All admin API calls require admin privileges
requireAdmin();

// Get action from request
$action = $_GET['action'] ?? '';

// Initialize model
$userModel = new User();
$currentUser = $auth->getCurrentUser();

try {
    switch ($action) {
        case 'list_users':
            // List all users
            $filters = [];
            if (isset($_GET['username'])) {
                $filters['username'] = $_GET['username'];
            }
            if (isset($_GET['email'])) {
                $filters['email'] = $_GET['email'];
            }
            if (isset($_GET['auth_method'])) {
                $filters['auth_method'] = $_GET['auth_method'];
            }
            if (isset($_GET['is_active'])) {
                $filters['is_active'] = $_GET['is_active'];
            }
            
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
            
            $users = $userModel->list($filters, $limit, $offset);
            
            echo json_encode([
                'success' => true,
                'data' => $users,
                'count' => count($users)
            ]);
            break;
            
        case 'get_user':
            // Get a specific user
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid user ID']);
                exit;
            }
            
            $user = $userModel->getById($id);
            if (!$user) {
                http_response_code(404);
                echo json_encode(['error' => 'User not found']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'data' => $user
            ]);
            break;
            
        case 'create_user':
            // Create a new user
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input || !isset($input['username']) || !isset($input['email'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required fields: username, email']);
                exit;
            }
            
            // ENFORCE: All user creation via admin interface must use database authentication
            // AD/LDAP users are created automatically during their first login
            $input['auth_method'] = 'database';
            
            // For database auth, password is required
            if (!isset($input['password']) || $input['password'] === '') {
                http_response_code(400);
                echo json_encode(['error' => 'Password is required for database authentication']);
                exit;
            }
            
            $user_id = $userModel->create($input, $currentUser['id']);
            
            if (!$user_id) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create user. Username or email may already exist.']);
                exit;
            }
            
            // Assign roles if provided
            if (isset($input['role_ids']) && is_array($input['role_ids'])) {
                foreach ($input['role_ids'] as $role_id) {
                    $userModel->assignRole($user_id, (int)$role_id);
                }
            }
            
            $user = $userModel->getById($user_id);
            
            echo json_encode([
                'success' => true,
                'message' => 'User created successfully',
                'data' => $user
            ]);
            break;
            
        case 'update_user':
            // Update an existing user
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid user ID']);
                exit;
            }
            
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid JSON input']);
                exit;
            }
            
            // ENFORCE: Cannot change auth_method to AD or LDAP via admin interface
            // AD/LDAP users are managed through their authentication source
            if (isset($input['auth_method']) && in_array($input['auth_method'], ['ad', 'ldap'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Cannot change auth_method to AD or LDAP. AD/LDAP users are created automatically during authentication.']);
                exit;
            }
            
            // Remove auth_method from input to prevent any changes
            // Only database auth_method is allowed and it's set during user creation
            unset($input['auth_method']);
            
            $result = $userModel->update($id, $input, $currentUser['id']);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to update user']);
                exit;
            }
            
            $user = $userModel->getById($id);
            
            echo json_encode([
                'success' => true,
                'message' => 'User updated successfully',
                'data' => $user
            ]);
            break;
            
        case 'assign_role':
            // Assign a role to a user
            $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
            $role_id = isset($_GET['role_id']) ? (int)$_GET['role_id'] : 0;
            
            if ($user_id <= 0 || $role_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid user_id or role_id']);
                exit;
            }
            
            $result = $userModel->assignRole($user_id, $role_id);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to assign role']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Role assigned successfully'
            ]);
            break;
            
        case 'remove_role':
            // Remove a role from a user
            $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
            $role_id = isset($_GET['role_id']) ? (int)$_GET['role_id'] : 0;
            
            if ($user_id <= 0 || $role_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid user_id or role_id']);
                exit;
            }
            
            $result = $userModel->removeRole($user_id, $role_id);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to remove role']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Role removed successfully'
            ]);
            break;
            
        case 'list_roles':
            // List all available roles
            $roles = $userModel->listRoles();
            
            echo json_encode([
                'success' => true,
                'data' => $roles,
                'count' => count($roles)
            ]);
            break;
            
        case 'list_mappings':
            // List all auth mappings
            $db = Database::getInstance()->getConnection();
            $sql = "SELECT am.*, r.name as role_name, u.username as created_by_username
                    FROM auth_mappings am
                    LEFT JOIN roles r ON am.role_id = r.id
                    LEFT JOIN users u ON am.created_by = u.id
                    ORDER BY am.source ASC, am.dn_or_group ASC";
            
            $stmt = $db->prepare($sql);
            $stmt->execute();
            $mappings = $stmt->fetchAll();
            
            echo json_encode([
                'success' => true,
                'data' => $mappings,
                'count' => count($mappings)
            ]);
            break;
            
        case 'create_mapping':
            // Create a new auth mapping
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input || !isset($input['source']) || !isset($input['dn_or_group']) || !isset($input['role_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required fields: source, dn_or_group, role_id']);
                exit;
            }
            
            // Validate source
            $valid_sources = ['ad', 'ldap'];
            if (!in_array($input['source'], $valid_sources)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid source. Must be: ad or ldap']);
                exit;
            }
            
            $db = Database::getInstance()->getConnection();
            $sql = "INSERT INTO auth_mappings (source, dn_or_group, role_id, created_by, notes)
                    VALUES (?, ?, ?, ?, ?)";
            
            $stmt = $db->prepare($sql);
            $result = $stmt->execute([
                $input['source'],
                $input['dn_or_group'],
                (int)$input['role_id'],
                $currentUser['id'],
                $input['notes'] ?? null
            ]);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create mapping. It may already exist.']);
                exit;
            }
            
            $mapping_id = $db->lastInsertId();
            
            echo json_encode([
                'success' => true,
                'message' => 'Mapping created successfully',
                'data' => ['id' => $mapping_id]
            ]);
            break;
            
        case 'delete_mapping':
            // Delete an auth mapping
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid mapping ID']);
                exit;
            }
            
            $db = Database::getInstance()->getConnection();
            $sql = "DELETE FROM auth_mappings WHERE id = ?";
            
            $stmt = $db->prepare($sql);
            $result = $stmt->execute([$id]);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to delete mapping']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Mapping deleted successfully'
            ]);
            break;
            
        case 'deactivate_user':
            // Deactivate a user (set is_active = 0)
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'ID utilisateur invalide']);
                exit;
            }
            
            // Check user exists
            $targetUser = $userModel->getById($id);
            if (!$targetUser) {
                http_response_code(404);
                echo json_encode(['error' => 'Utilisateur non trouvé']);
                exit;
            }
            
            // Prevent self-deactivation
            if ($id === (int)$currentUser['id']) {
                http_response_code(400);
                echo json_encode(['error' => 'Impossible de désactiver votre propre compte.']);
                exit;
            }
            
            // Prevent deactivation of last active admin
            if ($userModel->hasAdminRole($id)) {
                $activeAdminCount = $userModel->countActiveAdmins();
                if ($activeAdminCount <= 1) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Impossible de désactiver le dernier administrateur actif.']);
                    exit;
                }
            }
            
            // Deactivate user
            $result = $userModel->deactivate($id);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Échec de la désactivation de l\'utilisateur']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Utilisateur désactivé avec succès'
            ]);
            break;
            
        case 'list_acl':
            // List ACL entries for a zone
            require_once __DIR__ . '/../includes/models/ZoneAcl.php';
            
            $zone_id = isset($_GET['zone_id']) ? (int)$_GET['zone_id'] : 0;
            if ($zone_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone_id']);
                exit;
            }
            
            $zoneAcl = new ZoneAcl();
            $entries = $zoneAcl->listForZone($zone_id);
            
            echo json_encode([
                'success' => true,
                'data' => $entries,
                'count' => count($entries)
            ]);
            break;
            
        case 'create_acl':
            // Create a new ACL entry for a zone
            require_once __DIR__ . '/../includes/models/ZoneAcl.php';
            
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input || !isset($input['zone_id']) || !isset($input['subject_type']) || 
                !isset($input['subject_identifier']) || !isset($input['permission'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required fields: zone_id, subject_type, subject_identifier, permission']);
                exit;
            }
            
            $zone_id = (int)$input['zone_id'];
            if ($zone_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone_id']);
                exit;
            }
            
            // Validate subject_type
            $valid_types = ['user', 'role', 'ad_group'];
            if (!in_array($input['subject_type'], $valid_types)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid subject_type. Must be: user, role, or ad_group']);
                exit;
            }
            
            // Validate permission
            $valid_permissions = ['read', 'write', 'admin'];
            if (!in_array($input['permission'], $valid_permissions)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid permission. Must be: read, write, or admin']);
                exit;
            }
            
            $zoneAcl = new ZoneAcl();
            $acl_id = $zoneAcl->addEntry(
                $zone_id,
                $input['subject_type'],
                $input['subject_identifier'],
                $input['permission'],
                $currentUser['id']
            );
            
            if (!$acl_id) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create ACL entry. Subject may not exist.']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'ACL entry created successfully',
                'data' => ['id' => $acl_id]
            ]);
            break;
            
        case 'delete_acl':
            // Delete an ACL entry
            require_once __DIR__ . '/../includes/models/ZoneAcl.php';
            
            // Support both GET id parameter and POST body
            $acl_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($acl_id <= 0) {
                $input = json_decode(file_get_contents('php://input'), true);
                $acl_id = isset($input['id']) ? (int)$input['id'] : 0;
            }
            
            if ($acl_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid ACL entry ID']);
                exit;
            }
            
            $zoneAcl = new ZoneAcl();
            
            // Verify ACL entry exists before deletion
            $existing = $zoneAcl->getById($acl_id);
            if (!$existing) {
                http_response_code(404);
                echo json_encode(['error' => 'ACL entry not found']);
                exit;
            }
            
            $result = $zoneAcl->removeEntry($acl_id);
            
            if (!$result) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to delete ACL entry']);
                exit;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'ACL entry deleted successfully'
            ]);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("Admin API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
}
?>
