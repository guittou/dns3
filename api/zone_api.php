<?php
/**
 * Zone Files REST API
 * Provides JSON endpoints for managing zone files
 *
 * Endpoints:
 * - GET ?action=list_zones - List zone files with optional filters
 * - GET ?action=get_zone&id=X - Get a specific zone file
 * - POST ?action=create_zone - Create a new zone file (admin only)
 * - POST ?action=update_zone&id=X - Update a zone file (admin only)
 * - POST ?action=assign_include&master_id=X&include_id=Y - Assign an include to a master zone (admin only)
 * - GET ?action=download_zone&id=X - Download zone file content
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/ZoneFile.php';

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
$zoneFile = new ZoneFile();

try {
    switch ($action) {
        case 'list_zones':
            // List zone files (requires authentication)
            requireAuth();

            $filters = [];
            if (isset($_GET['name']) && $_GET['name'] !== '') {
                $filters['name'] = $_GET['name'];
            }
            if (isset($_GET['file_type']) && $_GET['file_type'] !== '') {
                // Validate file_type
                $allowed_types = ['master', 'include'];
                if (in_array($_GET['file_type'], $allowed_types)) {
                    $filters['file_type'] = $_GET['file_type'];
                }
            }
            if (isset($_GET['status']) && $_GET['status'] !== '') {
                $allowed_statuses = ['active', 'inactive', 'deleted'];
                if (in_array($_GET['status'], $allowed_statuses)) {
                    $filters['status'] = $_GET['status'];
                }
            }

            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

            $zones = $zoneFile->search($filters, $limit, $offset);

            echo json_encode([
                'success' => true,
                'data' => $zones,
                'count' => count($zones)
            ]);
            break;

        case 'get_zone':
            // Get a specific zone file (requires authentication)
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            $zone = $zoneFile->getById($id);
            if (!$zone) {
                http_response_code(404);
                echo json_encode(['error' => 'Zone file not found']);
                exit;
            }

            // Also get includes if this zone has any (masters and includes can have includes)
            $includes = [];
            $includes = $zoneFile->getIncludes($id);

            // Also get history
            $history = $zoneFile->getHistory($id);

            echo json_encode([
                'success' => true,
                'data' => $zone,
                'includes' => $includes,
                'history' => $history
            ]);
            break;

        case 'create_zone':
            // Create a new zone file (admin only)
            requireAdmin();

            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }

            // Validate required fields
            if (!isset($input['name']) || trim($input['name']) === '') {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: name']);
                exit;
            }
            if (!isset($input['filename']) || trim($input['filename']) === '') {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: filename']);
                exit;
            }

            // Validate file_type
            $valid_types = ['master', 'include'];
            if (isset($input['file_type']) && !in_array($input['file_type'], $valid_types)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid file_type. Must be: master or include']);
                exit;
            }

            $user = $auth->getCurrentUser();
            $zone_id = $zoneFile->create($input, $user['id']);

            if ($zone_id) {
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'Zone file created successfully',
                    'id' => $zone_id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create zone file']);
            }
            break;

        case 'update_zone':
            // Update a zone file (admin only)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }

            // Validate file_type if provided
            if (isset($input['file_type'])) {
                $valid_types = ['master', 'include'];
                if (!in_array($input['file_type'], $valid_types)) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid file_type. Must be: master or include']);
                    exit;
                }
            }

            $user = $auth->getCurrentUser();
            $success = $zoneFile->update($id, $input, $user['id']);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Zone file updated successfully'
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to update zone file']);
            }
            break;

        case 'set_status_zone':
            // Change zone file status (admin only)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            $status = $_GET['status'] ?? '';

            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            $valid_statuses = ['active', 'inactive', 'deleted'];
            if (!in_array($status, $valid_statuses)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid status. Must be: active, inactive, or deleted']);
                exit;
            }

            $user = $auth->getCurrentUser();
            $success = $zoneFile->setStatus($id, $status, $user['id']);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => "Zone file status changed to $status"
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to change zone file status']);
            }
            break;

        case 'assign_include':
            // Assign an include file to a parent zone with cycle detection (admin only)
            requireAdmin();

            // Get JSON input for POST data
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }

            $parent_id = isset($input['parent_id']) ? (int)$input['parent_id'] : (isset($_GET['parent_id']) ? (int)$_GET['parent_id'] : 0);
            $include_id = isset($input['include_id']) ? (int)$input['include_id'] : (isset($_GET['include_id']) ? (int)$_GET['include_id'] : 0);
            $position = isset($input['position']) ? (int)$input['position'] : 0;

            if ($parent_id <= 0 || $include_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid parent_id or include_id']);
                exit;
            }

            $result = $zoneFile->assignInclude($parent_id, $include_id, $position);

            if ($result === true) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Include assigned to parent zone successfully'
                ]);
            } else {
                http_response_code(400);
                echo json_encode(['error' => is_string($result) ? $result : 'Failed to assign include to parent zone']);
            }
            break;

        case 'remove_include':
            // Remove an include assignment (admin only)
            requireAdmin();

            $parent_id = isset($_GET['parent_id']) ? (int)$_GET['parent_id'] : 0;
            $include_id = isset($_GET['include_id']) ? (int)$_GET['include_id'] : 0;

            if ($parent_id <= 0 || $include_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid parent_id or include_id']);
                exit;
            }

            $success = $zoneFile->removeInclude($parent_id, $include_id);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Include removed successfully'
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to remove include']);
            }
            break;

        case 'get_tree':
            // Get recursive include tree for a zone (requires authentication)
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            $tree = $zoneFile->getIncludeTree($id);
            if ($tree === null) {
                http_response_code(404);
                echo json_encode(['error' => 'Zone file not found']);
                exit;
            }

            echo json_encode([
                'success' => true,
                'data' => $tree
            ]);
            break;

        case 'render_resolved':
            // Get flattened content with all includes resolved (requires authentication)
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            $content = $zoneFile->renderResolvedContent($id);
            if ($content === null) {
                http_response_code(404);
                echo json_encode(['error' => 'Zone file not found']);
                exit;
            }

            echo json_encode([
                'success' => true,
                'content' => $content
            ]);
            break;

        case 'download_zone':
            // Download zone file content
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
            }

            $zone = $zoneFile->getById($id);
            if (!$zone) {
                http_response_code(404);
                echo json_encode(['error' => 'Zone file not found']);
                exit;
            }

            // Set headers for file download
            header('Content-Type: text/plain');
            header('Content-Disposition: attachment; filename="' . $zone['filename'] . '"');
            echo $zone['content'] ?? '';
            exit;

        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("Zone API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?>
