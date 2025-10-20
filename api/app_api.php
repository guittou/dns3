<?php
/**
 * Applications REST API
 * Provides JSON endpoints for managing applications
 *
 * Endpoints:
 * - GET ?action=list_apps - List applications with optional filters
 * - GET ?action=get_app&id=X - Get a specific application
 * - POST ?action=create_app - Create a new application (admin only)
 * - POST ?action=update_app&id=X - Update an application (admin only)
 * - POST ?action=set_status_app&id=X&status=Y - Change application status (admin only)
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/Application.php';
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

// Initialize models
$application = new Application();
$zoneFile = new ZoneFile();

try {
    switch ($action) {
        case 'list_apps':
            // List applications (requires authentication)
            requireAuth();

            $filters = [];
            if (isset($_GET['name']) && $_GET['name'] !== '') {
                $filters['name'] = $_GET['name'];
            }
            if (isset($_GET['status']) && $_GET['status'] !== '') {
                $allowed_statuses = ['active', 'inactive', 'deleted'];
                if (in_array($_GET['status'], $allowed_statuses)) {
                    $filters['status'] = $_GET['status'];
                }
            }
            if (isset($_GET['zone_file_id']) && $_GET['zone_file_id'] !== '') {
                $filters['zone_file_id'] = (int)$_GET['zone_file_id'];
            }

            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

            $apps = $application->search($filters, $limit, $offset);

            echo json_encode([
                'success' => true,
                'data' => $apps,
                'count' => count($apps)
            ]);
            break;

        case 'get_app':
            // Get a specific application (requires authentication)
            requireAuth();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid application ID']);
                exit;
            }

            $app = $application->getById($id);
            if (!$app) {
                http_response_code(404);
                echo json_encode(['error' => 'Application not found']);
                exit;
            }

            echo json_encode([
                'success' => true,
                'data' => $app
            ]);
            break;

        case 'create_app':
            // Create a new application (admin only)
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
            if (!isset($input['zone_file_id']) || empty($input['zone_file_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: zone_file_id']);
                exit;
            }

            // Validate that zone_file_id references an existing active zone
            $zone = $zoneFile->getById($input['zone_file_id']);
            if (!$zone || $zone['status'] !== 'active') {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid or inactive zone_file_id']);
                exit;
            }

            $app_id = $application->create($input);

            if ($app_id) {
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'Application created successfully',
                    'id' => $app_id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create application']);
            }
            break;

        case 'update_app':
            // Update an application (admin only)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid application ID']);
                exit;
            }

            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }

            // Validate zone_file_id if provided
            if (isset($input['zone_file_id']) && !empty($input['zone_file_id'])) {
                $zone = $zoneFile->getById($input['zone_file_id']);
                if (!$zone || $zone['status'] !== 'active') {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid or inactive zone_file_id']);
                    exit;
                }
            }

            $success = $application->update($id, $input);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Application updated successfully'
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to update application']);
            }
            break;

        case 'set_status_app':
            // Change application status (admin only)
            requireAdmin();

            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            $status = $_GET['status'] ?? '';

            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid application ID']);
                exit;
            }

            $valid_statuses = ['active', 'inactive', 'deleted'];
            if (!in_array($status, $valid_statuses)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid status. Must be: active, inactive, or deleted']);
                exit;
            }

            $success = $application->setStatus($id, $status);

            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => "Application status changed to $status"
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to change application status']);
            }
            break;

        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("Application API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?>
