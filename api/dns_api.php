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

// Constants
if (!defined('MAX_ZONE_TRAVERSAL_DEPTH')) {
    define('MAX_ZONE_TRAVERSAL_DEPTH', 100); // Maximum iterations for zone tree traversal to prevent infinite loops
}

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
            // For non-admin users, filter records to only show those in allowed zones
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
            if (isset($_GET['domain_id']) && $_GET['domain_id'] !== '') {
                $domainId = (int)$_GET['domain_id'];
                if ($domainId <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid domain_id: must be a positive integer']);
                    exit;
                }
                $filters['domain_id'] = $domainId;
            }
            // zone_file_id filter takes priority over domain_id
            if (isset($_GET['zone_file_id']) && $_GET['zone_file_id'] !== '') {
                $zoneFileId = (int)$_GET['zone_file_id'];
                if ($zoneFileId <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Invalid zone_file_id: must be a positive integer']);
                    exit;
                }
                $filters['zone_file_id'] = $zoneFileId;
                
                // For non-admin users, verify they have access to this zone
                if (!$auth->isAdmin() && !$auth->isAllowedForZone($zoneFileId, 'read')) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Access denied to this zone']);
                    exit;
                }
            }

            // For non-admin users, add zone filter based on ACL
            if (!$auth->isAdmin() && !isset($filters['zone_file_id'])) {
                $allowedZoneIds = $auth->getAllowedZoneIds('read');
                if (empty($allowedZoneIds) && !$auth->isZoneEditor()) {
                    // User has no zone access, return empty
                    echo json_encode([
                        'success' => true,
                        'data' => [],
                        'count' => 0
                    ]);
                    break;
                }
                if (!empty($allowedZoneIds)) {
                    $filters['zone_file_ids'] = $allowedZoneIds;
                }
            }

            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

            $records = $dnsRecord->search($filters, $limit, $offset);

            // Ensure all records have zone_file_id, zone_name, zone_file_name
            foreach ($records as &$record) {
                if (!isset($record['zone_file_id']) || $record['zone_file_id'] === null) {
                    error_log("DNS API Warning: Record {$record['id']} missing zone_file_id");
                }
                if (!isset($record['zone_name']) || $record['zone_name'] === null || $record['zone_name'] === '') {
                    error_log("DNS API Warning: Record {$record['id']} missing zone_name");
                }
            }
            unset($record); // break reference

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
                error_log("DNS API Error: Record {$id} not found");
                echo json_encode(['error' => 'Record not found']);
                exit;
            }

            // Ensure zone fields are present
            if (!isset($record['zone_file_id']) || $record['zone_file_id'] === null) {
                error_log("DNS API Warning: Record {$id} missing zone_file_id");
            }
            if (!isset($record['zone_name']) || $record['zone_name'] === null || $record['zone_name'] === '') {
                error_log("DNS API Warning: Record {$id} missing zone_name");
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

            // Normalize TTL: empty string -> null
            if (isset($input['ttl']) && $input['ttl'] === '') {
                $input['ttl'] = null;
            }
            
            // Validate TTL if provided
            if (isset($input['ttl']) && $input['ttl'] !== null) {
                if (!is_numeric($input['ttl']) || intval($input['ttl']) <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'TTL must be a positive integer or null']);
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

            // Normalize TTL: empty string -> null
            if (isset($input['ttl']) && $input['ttl'] === '') {
                $input['ttl'] = null;
            }
            
            // Validate TTL if provided
            if (isset($input['ttl']) && $input['ttl'] !== null) {
                if (!is_numeric($input['ttl']) || intval($input['ttl']) <= 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'TTL must be a positive integer or null']);
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

        case 'list_domains':
            // List domains from zone_files.domain (requires authentication)
            // COMPATIBILITY: Returns zone files with domain field set, formatted like legacy domaine_list
            // For non-admin users, filter to only show domains they have ACL access to
            // Also includes parent masters for users who have ACL on include zones
            requireAuth();

            try {
                // Optional zone_file_id filter - if provided, only return domain(s) for that specific zone
                $zoneFileIdFilter = isset($_GET['zone_file_id']) ? (int)$_GET['zone_file_id'] : 0;
                
                // Get allowed zone IDs for non-admin users
                $allowedZoneIds = null;
                $allowedMasterIds = [];
                
                if (!$auth->isAdmin()) {
                    $allowedZoneIds = $auth->getAllowedZoneIds('read');
                    // If user has no ACL entries and no zone_editor role, return empty
                    if (empty($allowedZoneIds) && !$auth->isZoneEditor()) {
                        echo json_encode([
                            'success' => true,
                            'data' => []
                        ]);
                        break;
                    }
                    
                    // If zone_file_id filter is provided, verify user has access
                    if ($zoneFileIdFilter > 0) {
                        if (!in_array($zoneFileIdFilter, $allowedZoneIds)) {
                            http_response_code(403);
                            echo json_encode(['error' => 'Access denied to this zone']);
                            exit;
                        }
                    }
                    
                    // For non-admin users with ACL entries, we need to find:
                    // 1. Master zones the user has direct ACL on
                    // 2. Parent master zones for include zones the user has ACL on
                    if (!empty($allowedZoneIds)) {
                        // Start with allowed zone IDs that are masters
                        $placeholders = implode(',', array_fill(0, count($allowedZoneIds), '?'));
                        
                        // First, get masters directly in allowedZoneIds
                        $masterSql = "SELECT id FROM zone_files 
                                      WHERE id IN ($placeholders) 
                                      AND file_type = 'master' 
                                      AND status = 'active'";
                        $stmt = $dnsRecord->getConnection()->prepare($masterSql);
                        $stmt->execute($allowedZoneIds);
                        $directMasters = $stmt->fetchAll(PDO::FETCH_COLUMN);
                        $allowedMasterIds = $directMasters;
                        
                        // Next, find parent masters for include zones in allowedZoneIds
                        // Use recursive CTE or iterative approach to traverse zone_file_includes
                        $includeSql = "SELECT DISTINCT id FROM zone_files 
                                       WHERE id IN ($placeholders) 
                                       AND file_type = 'include' 
                                       AND status = 'active'";
                        $stmt = $dnsRecord->getConnection()->prepare($includeSql);
                        $stmt->execute($allowedZoneIds);
                        $includeZoneIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
                        
                        // For each include zone, traverse upward to find the top master
                        foreach ($includeZoneIds as $includeId) {
                            $currentId = $includeId;
                            $visited = [];
                            $maxIterations = MAX_ZONE_TRAVERSAL_DEPTH;
                            $iterations = 0;
                            
                            while ($iterations < $maxIterations) {
                                $iterations++;
                                
                                // Prevent cycles
                                if (in_array($currentId, $visited)) {
                                    break;
                                }
                                $visited[] = $currentId;
                                
                                // Find parent of current zone
                                $parentSql = "SELECT zfi.parent_id, zf.file_type 
                                              FROM zone_file_includes zfi
                                              INNER JOIN zone_files zf ON zfi.parent_id = zf.id
                                              WHERE zfi.include_id = ? AND zf.status = 'active'
                                              LIMIT 1";
                                $stmt = $dnsRecord->getConnection()->prepare($parentSql);
                                $stmt->execute([$currentId]);
                                $parent = $stmt->fetch();
                                
                                if (!$parent) {
                                    // No parent found - check if current is a master
                                    $typeSql = "SELECT file_type FROM zone_files WHERE id = ? AND status = 'active'";
                                    $stmt = $dnsRecord->getConnection()->prepare($typeSql);
                                    $stmt->execute([$currentId]);
                                    $current = $stmt->fetch();
                                    if ($current && $current['file_type'] === 'master') {
                                        if (!in_array($currentId, $allowedMasterIds)) {
                                            $allowedMasterIds[] = $currentId;
                                        }
                                    }
                                    break;
                                }
                                
                                // If parent is a master, add it and stop
                                if ($parent['file_type'] === 'master') {
                                    if (!in_array($parent['parent_id'], $allowedMasterIds)) {
                                        $allowedMasterIds[] = $parent['parent_id'];
                                    }
                                    break;
                                }
                                
                                // Parent is an include, continue traversing upward
                                $currentId = $parent['parent_id'];
                            }
                        }
                    }
                }
                
                // Build domain query
                $sql = "SELECT DISTINCT zf.id, zf.domain, zf.id as zone_file_id, 
                               zf.name as zone_name,
                               zf.filename as zone_filename
                        FROM zone_files zf
                        WHERE zf.domain IS NOT NULL 
                          AND zf.domain != ''
                          AND zf.status = 'active'
                          AND zf.file_type = 'master'";
                
                $params = [];
                
                // Apply zone_file_id filter if provided
                if ($zoneFileIdFilter > 0) {
                    $sql .= " AND zf.id = ?";
                    $params[] = $zoneFileIdFilter;
                }
                // Add ACL filter for non-admin users using the expanded master list
                elseif (!$auth->isAdmin() && !empty($allowedMasterIds)) {
                    $placeholders = implode(',', array_fill(0, count($allowedMasterIds), '?'));
                    $sql .= " AND zf.id IN ($placeholders)";
                    $params = array_merge($params, $allowedMasterIds);
                } elseif (!$auth->isAdmin() && empty($allowedMasterIds) && !$auth->isZoneEditor()) {
                    // User has ACL but no masters (shouldn't happen, but safety check)
                    echo json_encode([
                        'success' => true,
                        'data' => []
                    ]);
                    break;
                }
                
                $sql .= " ORDER BY zf.domain ASC";
                
                $stmt = $dnsRecord->getConnection()->prepare($sql);
                $stmt->execute($params);
                $domains = $stmt->fetchAll();
                
                echo json_encode([
                    'success' => true,
                    'data' => $domains
                ]);
            } catch (Exception $e) {
                error_log("Error fetching domains: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Failed to fetch domains']);
            }
            break;

        case 'list_zones_by_domain':
            // List zones (master + includes descendants) for a given zone (requires authentication)
            // Uses BFS on zone_file_includes to find all descendant zones
            // Now accepts zone_id parameter (domain_id is deprecated but mapped to zone_id for compatibility)
            // For non-admin users, check ACL access to the master zone
            requireAuth();

            $domain_id = isset($_GET['domain_id']) ? (int)$_GET['domain_id'] : 0;
            $zone_id = isset($_GET['zone_id']) ? (int)$_GET['zone_id'] : 0;
            
            if ($domain_id <= 0 && $zone_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid domain_id or zone_id']);
                exit;
            }

            try {
                // Use zone_id directly, or use domain_id as zone_id for backward compatibility
                $masterZoneFileId = $zone_id > 0 ? $zone_id : $domain_id;
                
                // BFS to collect master + all descendant zone files via zone_file_includes
                $zoneFileIds = [$masterZoneFileId];
                $visited = [$masterZoneFileId => true];
                $queue = [$masterZoneFileId];
                
                while (!empty($queue)) {
                    $currentZoneFileId = array_shift($queue);
                    
                    // Find all zone files included by the current zone file
                    $sql = "SELECT include_id FROM zone_file_includes WHERE parent_id = ?";
                    $stmt = $dnsRecord->getConnection()->prepare($sql);
                    $stmt->execute([$currentZoneFileId]);
                    $includes = $stmt->fetchAll();
                    
                    foreach ($includes as $include) {
                        $includeId = $include['include_id'];
                        
                        // Avoid cycles
                        if (!isset($visited[$includeId])) {
                            $visited[$includeId] = true;
                            $zoneFileIds[] = $includeId;
                            $queue[] = $includeId;
                        }
                    }
                }
                
                // Fetch zone file details for all collected IDs
                $zones = [];
                if (!empty($zoneFileIds)) {
                    $placeholders = implode(',', array_fill(0, count($zoneFileIds), '?'));
                    $sql = "SELECT id, name, filename, file_type 
                            FROM zone_files 
                            WHERE id IN ($placeholders) AND status = 'active'
                            ORDER BY file_type DESC, name ASC"; // master first, then includes
                    $stmt = $dnsRecord->getConnection()->prepare($sql);
                    $stmt->execute($zoneFileIds);
                    $zones = $stmt->fetchAll();
                }
                
                echo json_encode([
                    'success' => true,
                    'data' => $zones
                ]);
            } catch (Exception $e) {
                error_log("Error listing zones by domain: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Failed to list zones for domain']);
            }
            break;

        case 'get_domain_for_zone':
            // Get the domain associated with the top master of a zone (requires authentication)
            // Traverses zone_file_includes upward to find the top master, then reads domain from zone_files.domain
            requireAuth();

            $zone_id = isset($_GET['zone_id']) ? (int)$_GET['zone_id'] : 0;
            if ($zone_id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone_id']);
                exit;
            }

            try {
                // Traverse upward via zone_file_includes to find the top master
                $currentZoneId = $zone_id;
                $visited = [$currentZoneId => true];
                $iteration = 0;
                
                while ($iteration < MAX_ZONE_TRAVERSAL_DEPTH) {
                    // Check if current zone has a parent
                    $sql = "SELECT parent_id FROM zone_file_includes WHERE include_id = ? LIMIT 1";
                    $stmt = $dnsRecord->getConnection()->prepare($sql);
                    $stmt->execute([$currentZoneId]);
                    $parent = $stmt->fetch();
                    
                    if (!$parent) {
                        // No parent found, currentZoneId is the top master
                        break;
                    }
                    
                    $parentId = $parent['parent_id'];
                    
                    // Avoid cycles
                    if (isset($visited[$parentId])) {
                        error_log("Cycle detected in zone_file_includes for zone_id {$zone_id}");
                        break;
                    }
                    
                    $visited[$parentId] = true;
                    $currentZoneId = $parentId;
                    $iteration++;
                }
                
                // Now currentZoneId is the top master, get the zone with domain
                $sql = "SELECT id, domain FROM zone_files WHERE id = ? AND status = 'active' LIMIT 1";
                $stmt = $dnsRecord->getConnection()->prepare($sql);
                $stmt->execute([$currentZoneId]);
                $zone = $stmt->fetch();
                
                if ($zone && !empty($zone['domain'])) {
                    // Return domain info in same format as before for compatibility
                    echo json_encode([
                        'success' => true,
                        'data' => [
                            'id' => $zone['id'], // Use zone_file_id as domain id
                            'domain' => $zone['domain']
                        ]
                    ]);
                } else {
                    echo json_encode([
                        'success' => true,
                        'data' => null
                    ]);
                }
            } catch (Exception $e) {
                error_log("Error getting domain for zone: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Failed to get domain for zone']);
            }
            break;

        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    error_log("DNS API error [action={$action}]: " . $e->getMessage() . " | Trace: " . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?>
