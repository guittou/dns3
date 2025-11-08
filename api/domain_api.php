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
require_once __DIR__ . '/../includes/db.php';

// Domain validation regex (same as Domain model)
define('DOMAIN_REGEX', '/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/');

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

/**
 * Parse request data from JSON or POST
 * 
 * @return array Parsed request data
 */
function parseRequestData() {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Fallback to $_POST if JSON decode fails
    if (json_last_error() !== JSON_ERROR_NONE) {
        $data = $_POST;
    }
    
    // Ensure we always return an array
    return $data ?: [];
}

/**
 * Validate domain data
 * 
 * @param array $data Domain data to validate
 * @return array|null Returns error array if validation fails, null if valid
 */
function validateDomainData($data) {
    // Validate required fields
    if (empty($data['domain'])) {
        return ['error' => 'Domain name is required', 'code' => 400];
    }
    
    if (empty($data['zone_file_id'])) {
        return ['error' => 'Zone file ID is required', 'code' => 400];
    }
    
    // Validate zone_file_id is a positive integer
    if (!is_numeric($data['zone_file_id']) || (int)$data['zone_file_id'] <= 0) {
        return ['error' => 'Zone file ID must be a positive integer', 'code' => 400];
    }
    
    // Validate domain format
    if (!preg_match(DOMAIN_REGEX, $data['domain'])) {
        return ['error' => 'Invalid domain format', 'code' => 400];
    }
    
    // Verify zone file exists and is type 'master' and active
    $db = Database::getInstance()->getConnection();
    $zoneStmt = $db->prepare("SELECT id, file_type, status FROM zone_files WHERE id = ? LIMIT 1");
    $zoneStmt->execute([(int)$data['zone_file_id']]);
    $zone = $zoneStmt->fetch();
    
    if (!$zone) {
        return ['error' => 'Zone file not found', 'code' => 400];
    }
    
    if ($zone['status'] !== 'active') {
        return ['error' => 'Zone file is not active', 'code' => 400];
    }
    
    if ($zone['file_type'] !== 'master') {
        return ['error' => 'Zone file must be of type master', 'code' => 400];
    }
    
    return null; // Validation passed
}

// Get action from request
$action = $_GET['action'] ?? '';

// Initialize models
$domain = new Domain();
require_once __DIR__ . '/../includes/models/ZoneFile.php';
$zoneFile = new ZoneFile();

try {
    switch ($action) {
        case 'list':
            // List domains with pagination (requires authentication)
            // COMPATIBILITY WRAPPER: reads from zone_files.domain instead of domaine_list
            requireAuth();

            $filters = [];
            
            // Domain name filter (search in zone_files.domain)
            if (isset($_GET['domain']) && $_GET['domain'] !== '') {
                $filters['q'] = $_GET['domain']; // Use 'q' to search in name/filename/domain
            }
            
            // Zone file filter
            if (isset($_GET['zone_file_id']) && $_GET['zone_file_id'] !== '') {
                $filters['zone_file_id'] = (int)$_GET['zone_file_id'];
            }
            
            // Only master zones with domain set
            $filters['file_type'] = 'master';
            $filters['status'] = isset($_GET['status']) && $_GET['status'] === 'deleted' ? 'deleted' : 'active';

            // Pagination parameters
            $limit = isset($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 100;
            $offset = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

            // Get zones from ZoneFile model
            $zones = $zoneFile->search($filters, $limit, $offset);
            
            // Filter to only include zones with domain set and transform to domain format
            $domains = [];
            foreach ($zones as $zone) {
                if (!empty($zone['domain'])) {
                    $domains[] = [
                        'id' => $zone['id'], // Use zone_file_id as domain id for compatibility
                        'domain' => $zone['domain'],
                        'zone_file_id' => $zone['id'],
                        'zone_name' => $zone['name'],
                        'zone_file_type' => $zone['file_type'],
                        'created_by' => $zone['created_by'],
                        'created_by_username' => $zone['created_by_username'] ?? null,
                        'updated_by' => $zone['updated_by'],
                        'updated_by_username' => $zone['updated_by_username'] ?? null,
                        'created_at' => $zone['created_at'],
                        'updated_at' => $zone['updated_at'],
                        'status' => $zone['status']
                    ];
                }
            }

            echo json_encode([
                'success' => true,
                'data' => $domains,
                'count' => count($domains)
            ]);
            break;

        case 'get':
            // Get specific domain (requires authentication)
            // COMPATIBILITY WRAPPER: reads from zone_files.domain
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain ID']);
                exit;
            }

            // Get zone by ID (zone_file_id is used as domain id)
            $zone = $zoneFile->getById($id);

            if (!$zone || $zone['file_type'] !== 'master' || empty($zone['domain'])) {
                http_response_code(404);
                echo json_encode(['error' => 'Domain not found']);
                exit;
            }
            
            // Transform zone to domain format
            $domainData = [
                'id' => $zone['id'],
                'domain' => $zone['domain'],
                'zone_file_id' => $zone['id'],
                'zone_name' => $zone['name'],
                'zone_file_type' => $zone['file_type'],
                'created_by' => $zone['created_by'],
                'created_by_username' => $zone['created_by_username'] ?? null,
                'updated_by' => $zone['updated_by'],
                'updated_by_username' => $zone['updated_by_username'] ?? null,
                'created_at' => $zone['created_at'],
                'updated_at' => $zone['updated_at'],
                'status' => $zone['status']
            ];

            echo json_encode([
                'success' => true,
                'data' => $domainData
            ]);
            break;

        case 'create':
            // Create new domain (requires admin)
            // DEPRECATED: Use zone_api.php to create master zones with domain field
            requireAdmin();
            
            error_log("DEPRECATION WARNING: domain_api.php create endpoint is deprecated. Use zone_api.php instead.");

            try {
                // Parse request data
                $data = parseRequestData();
                
                // Validate domain data
                $validationError = validateDomainData($data);
                if ($validationError) {
                    http_response_code($validationError['code']);
                    echo json_encode(['error' => $validationError['error']]);
                    exit;
                }
                
                $currentUser = $auth->getCurrentUser();
                $userId = isset($currentUser['id']) ? $currentUser['id'] : null;
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
            // DEPRECATED: Use zone_api.php to update master zones with domain field
            requireAdmin();
            
            error_log("DEPRECATION WARNING: domain_api.php update endpoint is deprecated. Use zone_api.php instead.");

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain ID']);
                exit;
            }

            try {
                // Parse request data
                $data = parseRequestData();
                
                // Validate domain data
                $validationError = validateDomainData($data);
                if ($validationError) {
                    http_response_code($validationError['code']);
                    echo json_encode(['error' => $validationError['error']]);
                    exit;
                }

                $currentUser = $auth->getCurrentUser();
                $userId = isset($currentUser['id']) ? $currentUser['id'] : null;
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
            // DEPRECATED: Use zone_api.php to manage zone status
            requireAdmin();
            
            error_log("DEPRECATION WARNING: domain_api.php set_status endpoint is deprecated. Use zone_api.php instead.");

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

            $currentUser = $auth->getCurrentUser();
            $userId = isset($currentUser['id']) ? $currentUser['id'] : null;
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
