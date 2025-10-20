<?php
/**
 * DNS Records REST API
 * Provides JSON endpoints for managing DNS records
 * 
 * Endpoints:
 * - GET ?action=list - List DNS records with optional filters
 * - GET ?action=get&id=X - Get a specific record
 * - POST ?action=create - Create a new record (admin only)
 * - POST ?action=update&id=X - Update a record (admin only)
 * - POST ?action=set_status&id=X&status=Y - Change record status (admin only)
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/DnsRecord.php';

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
$dnsRecord = new DnsRecord();

try {
    switch ($action) {
        // ... other actions remain unchanged ...

        case 'set_status':
            // Change record status (admin only)
            requireAdmin();
            
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            $status = $_GET['status'] ?? '';
            
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid record ID']);
                exit;
            }

            // Check record exists (include deleted so we can restore)
            $record = $dnsRecord->getById($id, true);
            if (!$record) {
                http_response_code(404);
                echo json_encode(['error' => 'Record not found']);
                exit;
            }
            
            $valid_statuses = ['active', 'deleted'];
            if (!in_array($status, $valid_statuses)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid status. Must be: active or deleted']);
                exit;
            }
            
            $user = $auth->getCurrentUser();
            $success = $dnsRecord->setStatus($id, $status, $user['id']);
            
            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => "DNS record status changed to $status"
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to change DNS record status']);
            }
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("DNS API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?>
