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

/**
 * Validate IPv4 address
 */
function isValidIPv4($ip) {
    return filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false;
}

/**
 * Validate IPv6 address
 */
function isValidIPv6($ip) {
    return filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) !== false;
}

/**
 * Validate DNS record data based on type
 * @param string $recordType DNS record type
 * @param array $data Record data to validate
 * @return array ['valid' => bool, 'error' => string|null]
 */
function validateRecordByType($recordType, $data) {
    // Define required fields per type (using dedicated fields)
    $requiredFields = [
        'A' => ['name', 'address_ipv4'],
        'AAAA' => ['name', 'address_ipv6'],
        'CNAME' => ['name', 'cname_target'],
        'PTR' => ['name', 'ptrdname'],
        'TXT' => ['name', 'txt']
    ];
    
    // Check if we have the dedicated field or the value alias
    $required = $requiredFields[$recordType] ?? ['name'];
    
    // Check required fields
    foreach ($required as $field) {
        // For dedicated fields, also accept 'value' as an alias
        if ($field !== 'name') {
            $hasDedicatedField = isset($data[$field]) && trim($data[$field]) !== '';
            $hasValueAlias = isset($data['value']) && trim($data['value']) !== '';
            if (!$hasDedicatedField && !$hasValueAlias) {
                return ['valid' => false, 'error' => "Missing required field: $field (or value) for type $recordType"];
            }
        } else {
            if (!isset($data[$field]) || trim($data[$field]) === '') {
                return ['valid' => false, 'error' => "Missing required field: $field for type $recordType"];
            }
        }
    }
    
    // Type-specific semantic validation
    // Use dedicated field if available, otherwise use value
    switch($recordType) {
        case 'A':
            $ipv4 = $data['address_ipv4'] ?? $data['value'] ?? '';
            if (!isValidIPv4($ipv4)) {
                return ['valid' => false, 'error' => 'Address must be a valid IPv4 address for type A'];
            }
            break;
            
        case 'AAAA':
            $ipv6 = $data['address_ipv6'] ?? $data['value'] ?? '';
            if (!isValidIPv6($ipv6)) {
                return ['valid' => false, 'error' => 'Address must be a valid IPv6 address for type AAAA'];
            }
            break;
            
        case 'CNAME':
            $target = $data['cname_target'] ?? $data['value'] ?? '';
            // CNAME should not be an IP address
            if (isValidIPv4($target) || isValidIPv6($target)) {
                return ['valid' => false, 'error' => 'CNAME target cannot be an IP address (must be a hostname)'];
            }
            // Basic FQDN validation
            if (strlen($target) > 0 && !preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})?$/', $target)) {
                return ['valid' => false, 'error' => 'CNAME target must be a valid hostname'];
            }
            break;
            
        case 'PTR':
            $ptrdname = $data['ptrdname'] ?? $data['value'] ?? '';
            // PTR requires a reverse DNS name (user must provide it in reverse format)
            // Basic validation that it looks like a hostname
            if (strlen($ptrdname) > 0 && !preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})?$/', $ptrdname)) {
                return ['valid' => false, 'error' => 'PTR target must be a valid hostname (reverse DNS name required)'];
            }
            break;
            
        case 'TXT':
            $txt = $data['txt'] ?? $data['value'] ?? '';
            // TXT records can contain any text, just ensure it's not empty
            if (strlen($txt) === 0) {
                return ['valid' => false, 'error' => 'TXT record content cannot be empty'];
            }
            break;
    }
    
    return ['valid' => true, 'error' => null];
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
            if (isset($_GET['name']) && $_GET['name'] !== '') {
                $filters['name'] = $_GET['name'];
            }
            if (isset($_GET['type']) && $_GET['type'] !== '') {
                $filters['type'] = $_GET['type'];
            }
            if (isset($_GET['status']) && $_GET['status'] !== '') {
                // only allow valid statuses
                $allowed = ['active','deleted'];
                if (in_array($_GET['status'], $allowed)) {
                    $filters['status'] = $_GET['status'];
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid status filter']);
                    exit;
                }
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
            
            // Validate zone_file_id is required
            if (!isset($input['zone_file_id']) || empty($input['zone_file_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: zone_file_id']);
                exit;
            }

            // Validate record_type field
            if (!isset($input['record_type']) || trim($input['record_type']) === '') {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: record_type']);
                exit;
            }

            // Validate record type - only A, AAAA, CNAME, PTR, TXT are supported
            $valid_types = ['A', 'AAAA', 'CNAME', 'PTR', 'TXT'];
            if (!in_array($input['record_type'], $valid_types)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid record type. Only A, AAAA, CNAME, PTR, and TXT are supported']);
                exit;
            }

            // Type-dependent validation
            $validation = validateRecordByType($input['record_type'], $input);
            if (!$validation['valid']) {
                http_response_code(400);
                echo json_encode(['error' => $validation['error']]);
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
            
            try {
                $record_id = $dnsRecord->create($input, $user['id']);
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'DNS record created successfully',
                    'id' => $record_id
                ]);
            } catch (Exception $e) {
                http_response_code(400);
                echo json_encode(['error' => $e->getMessage()]);
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

            // Validate record type if provided - only A, AAAA, CNAME, PTR, TXT are supported
            if (isset($input['record_type'])) {
                $valid_types = ['A', 'AAAA', 'CNAME', 'PTR', 'TXT'];
                if (!in_array($input['record_type'], $valid_types)) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid record type. Only A, AAAA, CNAME, PTR, and TXT are supported']);
                    exit;
                }
                
                // Type-dependent validation if record_type is being updated
                $validation = validateRecordByType($input['record_type'], $input);
                if (!$validation['valid']) {
                    http_response_code(400);
                    echo json_encode(['error' => $validation['error']]);
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
            
            try {
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
            } catch (Exception $e) {
                http_response_code(400);
                echo json_encode(['error' => $e->getMessage()]);
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
