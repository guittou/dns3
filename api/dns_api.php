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
        case 'list':
            // List DNS records (requires authentication)
            requireAuth();
            
            $filters = [];
            if (isset($_GET['name'])) {
                $filters['name'] = $_GET['name'];
            }
            if (isset($_GET['type'])) {
                $filters['type'] = $_GET['type'];
            }
            if (isset($_GET['status'])) {
                $filters['status'] = $_GET['status'];
            }
            
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
            
            $records = $dnsRecord->search($filters, $limit, $offset);
            
            echo json_encode([
                'success' => true,
                'data' => $records,
                'count' => count($records)
            ]);
            break;
            
        case 'get':
            // Get a specific DNS record (requires authentication)
            requireAuth();
            
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid record ID']);
                exit;
            }
            
            $record = $dnsRecord->getById($id);
            if (!$record) {
                http_response_code(404);
                echo json_encode(['error' => 'Record not found']);
                exit;
            }
            
            // Mark record as seen (server-side only, when authenticated user views it)
            $user = $auth->getCurrentUser();
            if ($user) {
                $dnsRecord->markSeen($id, $user['id']);
                // Refresh record to get updated last_seen
                $record = $dnsRecord->getById($id);
            }
            
            // Also get history
            $history = $dnsRecord->getHistory($id);
            
            echo json_encode([
                'success' => true,
                'data' => $record,
                'history' => $history
            ]);
            break;
            
        case 'create':
            // Create a new DNS record (admin only)
            requireAdmin();
            
            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }
            
            // Explicitly remove last_seen if provided by client (security)
            unset($input['last_seen']);
            
            // Validate required fields
            $required = ['record_type', 'name', 'value'];
            foreach ($required as $field) {
                if (!isset($input[$field]) || trim($input[$field]) === '') {
                    http_response_code(400);
                    echo json_encode(['error' => "Missing required field: $field"]);
                    exit;
                }
            }
            
            // Validate record type
            $valid_types = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV'];
            if (!in_array($input['record_type'], $valid_types)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid record type']);
                exit;
            }
            
            // Validate field lengths
            if (isset($input['requester']) && strlen($input['requester']) > 255) {
                http_response_code(400);
                echo json_encode(['error' => 'Requester field too long (max 255 characters)']);
                exit;
            }
            if (isset($input['ticket_ref']) && strlen($input['ticket_ref']) > 255) {
                http_response_code(400);
                echo json_encode(['error' => 'Ticket reference too long (max 255 characters)']);
                exit;
            }
            
            // Validate expires_at date format if provided
            if (isset($input['expires_at']) && $input['expires_at'] !== '' && $input['expires_at'] !== null) {
                $date = DateTime::createFromFormat('Y-m-d H:i:s', $input['expires_at']);
                if (!$date || $date->format('Y-m-d H:i:s') !== $input['expires_at']) {
                    // Try alternative format
                    $date = DateTime::createFromFormat('Y-m-d\TH:i', $input['expires_at']);
                    if ($date) {
                        // Convert to SQL format
                        $input['expires_at'] = $date->format('Y-m-d H:i:s');
                    } else {
                        http_response_code(400);
                        echo json_encode(['error' => 'Invalid expires_at date format. Use YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM']);
                        exit;
                    }
                }
            }
            
            $user = $auth->getCurrentUser();
            $record_id = $dnsRecord->create($input, $user['id']);
            
            if ($record_id) {
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'DNS record created successfully',
                    'id' => $record_id
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create DNS record']);
            }
            break;
            
        case 'update':
            // Update a DNS record (admin only)
            requireAdmin();
            
            $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid record ID']);
                exit;
            }
            
            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }
            
            // Explicitly remove last_seen if provided by client (security)
            unset($input['last_seen']);
            
            // Validate record type if provided
            if (isset($input['record_type'])) {
                $valid_types = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SOA', 'PTR', 'SRV'];
                if (!in_array($input['record_type'], $valid_types)) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid record type']);
                    exit;
                }
            }
            
            // Validate field lengths
            if (isset($input['requester']) && strlen($input['requester']) > 255) {
                http_response_code(400);
                echo json_encode(['error' => 'Requester field too long (max 255 characters)']);
                exit;
            }
            if (isset($input['ticket_ref']) && strlen($input['ticket_ref']) > 255) {
                http_response_code(400);
                echo json_encode(['error' => 'Ticket reference too long (max 255 characters)']);
                exit;
            }
            
            // Validate expires_at date format if provided
            if (isset($input['expires_at']) && $input['expires_at'] !== '' && $input['expires_at'] !== null) {
                $date = DateTime::createFromFormat('Y-m-d H:i:s', $input['expires_at']);
                if (!$date || $date->format('Y-m-d H:i:s') !== $input['expires_at']) {
                    // Try alternative format
                    $date = DateTime::createFromFormat('Y-m-d\TH:i', $input['expires_at']);
                    if ($date) {
                        // Convert to SQL format
                        $input['expires_at'] = $date->format('Y-m-d H:i:s');
                    } else {
                        http_response_code(400);
                        echo json_encode(['error' => 'Invalid expires_at date format. Use YYYY-MM-DD HH:MM:SS or YYYY-MM-DDTHH:MM']);
                        exit;
                    }
                }
            }
            
            $user = $auth->getCurrentUser();
            $success = $dnsRecord->update($id, $input, $user['id']);
            
            if ($success) {
                echo json_encode([
                    'success' => true,
                    'message' => 'DNS record updated successfully'
                ]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to update DNS record']);
            }
            break;
            
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
            
            $valid_statuses = ['active', 'disabled', 'deleted'];
            if (!in_array($status, $valid_statuses)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid status. Must be: active, disabled, or deleted']);
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
