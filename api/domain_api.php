<?php
/**
 * Domain REST API
 * Provides JSON endpoints for managing domains
 *
 * Endpoints:
 * - GET ?action=list - List domains with optional filters (requireAuth)
 * - GET ?action=get&id=X - Get a specific domain (requireAuth)
 * - POST ?action=create - Create a new domain (requireAdmin)
 * - POST ?action=update&id=X - Update a domain (requireAdmin)
 * - GET ?action=set_status&id=X&status=Y - Change domain status (requireAdmin)
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/Domain.php';

// Set JSON header
header('Content-Type: application/json');

// Initialize authentication
$auth = new Auth();

/**
 * Check if user is logged in
 */
function requireAuth() {
    global $auth;
    if (!$auth->isLoggedIn()) {
        http_response_code(401);
        echo json_encode(['error' => 'Authentication required']);
        exit;
    }
}

/**
 * Check if user is admin
 */
function requireAdmin() {
    global $auth;
    requireAuth();
    if (!$auth->isAdmin()) {
        http_response_code(403);
        echo json_encode(['error' => 'Admin privileges required']);
        exit;
    }
}

// Get action from request
$action = $_GET['action'] ?? '';

// Initialize model
$domain = new Domain();

try {
    switch ($action) {
        case 'list':
            // List domains with pagination (requires authentication)
            requireAuth();

            $filters = [];
            
            // Domain name filter
            if (isset($_GET['domain']) && $_GET['domain'] !== '') {
                $filters['domain'] = $_GET['domain'];
            }
            
            // Zone file filter
            if (isset($_GET['zone_file_id']) && $_GET['zone_file_id'] !== '') {
                $filters['zone_file_id'] = (int)$_GET['zone_file_id'];
            }
            
            // Status filter
            if (isset($_GET['status']) && $_GET['status'] !== '') {
                $allowed_statuses = ['active', 'deleted'];
                if (in_array($_GET['status'], $allowed_statuses)) {
                    $filters['status'] = $_GET['status'];
                }
            }

            // Pagination parameters
            $limit = isset($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 100;
            $offset = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

            $domains = $domain->list($filters, $limit, $offset);

            echo json_encode([
                'success' => true,
                'data' => $domains,
                'count' => count($domains)
            ]);
            break;

        case 'get':
            // Get specific domain (requires authentication)
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain ID']);
                exit;
            }

            $domainData = $domain->getById($id);

            if (!$domainData) {
                http_response_code(404);
                echo json_encode(['error' => 'Domain not found']);
                exit;
            }

            echo json_encode([
                'success' => true,
                'data' => $domainData
            ]);
            break;

        case 'create':
            // Create new domain (requires admin)
            requireAdmin();

            try {
                // Get input from JSON or POST data
                $input = file_get_contents('php://input');
                $data = json_decode($input, true);
                
                // Fallback to $_POST if JSON decode fails
                if (!$data) {
                    $data = $_POST;
                }
                
                // Validate required fields
                if (empty($data['domain'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Domain name is required']);
                    exit;
                }
                
                if (empty($data['zone_file_id'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file ID is required']);
                    exit;
                }
                
                // Validate zone_file_id is a positive integer
                if (!is_numeric($data['zone_file_id']) || (int)$data['zone_file_id'] <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file ID must be a positive integer']);
                    exit;
                }
                
                // Validate domain format
                if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $data['domain'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid domain format']);
                    exit;
                }
                
                // Verify zone file exists and is type 'master' and active
                require_once __DIR__ . '/../includes/db.php';
                $db = Database::getInstance()->getConnection();
                $zoneStmt = $db->prepare("SELECT id, file_type, status FROM zone_files WHERE id = ? LIMIT 1");
                $zoneStmt->execute([(int)$data['zone_file_id']]);
                $zone = $zoneStmt->fetch();
                
                if (!$zone) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file not found']);
                    exit;
                }
                
                if ($zone['status'] !== 'active') {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file is not active']);
                    exit;
                }
                
                if ($zone['file_type'] !== 'master') {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file must be of type master']);
                    exit;
                }
                
                $userId = $auth->getUserId();
                $result = $domain->create($data, $userId);

                if (!$result['success']) {
                    http_response_code(400);
                    echo json_encode($result);
                    exit;
                }

                http_response_code(201);
                echo json_encode($result);
            } catch (PDOException $e) {
                error_log("Domain API create error: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Database error occurred']);
            } catch (Exception $e) {
                error_log("Domain API create error: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Internal server error']);
            }
            break;

        case 'update':
            // Update domain (requires admin)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain ID']);
                exit;
            }

            try {
                // Get input from JSON or POST data
                $input = file_get_contents('php://input');
                $data = json_decode($input, true);
                
                // Fallback to $_POST if JSON decode fails
                if (!$data) {
                    $data = $_POST;
                }
                
                // Validate required fields
                if (empty($data['domain'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Domain name is required']);
                    exit;
                }
                
                if (empty($data['zone_file_id'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file ID is required']);
                    exit;
                }
                
                // Validate zone_file_id is a positive integer
                if (!is_numeric($data['zone_file_id']) || (int)$data['zone_file_id'] <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file ID must be a positive integer']);
                    exit;
                }
                
                // Validate domain format
                if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $data['domain'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid domain format']);
                    exit;
                }
                
                // Verify zone file exists and is type 'master' and active
                require_once __DIR__ . '/../includes/db.php';
                $db = Database::getInstance()->getConnection();
                $zoneStmt = $db->prepare("SELECT id, file_type, status FROM zone_files WHERE id = ? LIMIT 1");
                $zoneStmt->execute([(int)$data['zone_file_id']]);
                $zone = $zoneStmt->fetch();
                
                if (!$zone) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file not found']);
                    exit;
                }
                
                if ($zone['status'] !== 'active') {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file is not active']);
                    exit;
                }
                
                if ($zone['file_type'] !== 'master') {
                    http_response_code(400);
                    echo json_encode(['error' => 'Zone file must be of type master']);
                    exit;
                }

                $userId = $auth->getUserId();
                $result = $domain->update($id, $data, $userId);

                if (!$result['success']) {
                    http_response_code(400);
                    echo json_encode($result);
                    exit;
                }

                echo json_encode($result);
            } catch (PDOException $e) {
                error_log("Domain API update error: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Database error occurred']);
            } catch (Exception $e) {
                error_log("Domain API update error: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Internal server error']);
            }
            break;

        case 'set_status':
            // Set domain status (requires admin)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            $status = isset($_GET['status']) ? $_GET['status'] : '';
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain ID']);
                exit;
            }

            if (!in_array($status, ['active', 'deleted'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid status']);
                exit;
            }

            $userId = $auth->getUserId();
            $result = $domain->setStatus($id, $status, $userId);

            if (!$result['success']) {
                http_response_code(400);
                echo json_encode($result);
                exit;
            }

            echo json_encode($result);
            break;

        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("Domain API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
