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
require_once __DIR__ . '/../includes/lib/DnsValidator.php';

// Constants
define('MAX_INCLUDES_RETURN', 1000); // Maximum number of includes to return in get_zone to prevent OOM

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
            // List zone files with pagination (requires authentication)
            requireAuth();

            // Pagination parameters (parsed early for use in both paths)
            $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
            $per_page = isset($_GET['per_page']) ? min(100, max(1, (int)$_GET['per_page'])) : 25;
            
            // For backwards compatibility, also support limit/offset
            if (isset($_GET['limit'])) {
                $per_page = min(100, max(1, (int)$_GET['limit']));
            }

            // Get allowed zone IDs for non-admin users (for ACL filtering)
            $allowedZoneIds = null;
            $expandedZoneIds = null;
            if (!$auth->isAdmin()) {
                $allowedZoneIds = $auth->getAllowedZoneIds('read');
                // If user has no ACL entries, they can only see zones if they have zone_editor role
                if (empty($allowedZoneIds) && !$auth->isZoneEditor()) {
                    // Return empty result - user has no access to any zones
                    echo json_encode([
                        'success' => true,
                        'data' => [],
                        'total' => 0,
                        'page' => 1,
                        'per_page' => $per_page,
                        'total_pages' => 0
                    ]);
                    break;
                }
                
                // For non-admin users with ACL entries, expand to include parent masters
                // This is needed when user has ACL on include zones but requests master zones
                $expandedZoneIds = $auth->getExpandedZoneIds('read');
            }

            // Check if this is a recursive tree request
            $master_id = isset($_GET['master_id']) ? (int)$_GET['master_id'] : 0;
            $recursive = isset($_GET['recursive']) && $_GET['recursive'] == '1';

            if ($master_id > 0 && $recursive) {
                // For recursive tree, check if user has access to the master zone
                // Use expanded zone IDs which includes parent masters
                $effectiveZoneIds = $expandedZoneIds !== null ? $expandedZoneIds : $allowedZoneIds;
                if ($effectiveZoneIds !== null && !in_array($master_id, $effectiveZoneIds)) {
                    // User doesn't have ACL access to this master zone
                    http_response_code(403);
                    echo json_encode(['error' => 'Access denied to this zone']);
                    exit;
                }
                
                // Return recursive tree: master + all its descendants
                $zones = $zoneFile->getRecursiveTree($master_id, $per_page);
                $total = count($zones);
                
                // Add include count to each zone (using COUNT query to prevent OOM)
                foreach ($zones as &$zone) {
                    $zone['includes_count'] = $zoneFile->getIncludesCount($zone['id']);
                }

                echo json_encode([
                    'success' => true,
                    'data' => $zones,
                    'total' => $total,
                    'page' => 1,  // Always page 1 for recursive tree
                    'per_page' => $per_page,
                    'total_pages' => 1  // Always 1 page for recursive tree
                ]);
            } else {
                // Standard list with filters and pagination
                $filters = [];
                
                // General search parameter 'q' searches both name and filename
                if (isset($_GET['q']) && $_GET['q'] !== '') {
                    $filters['q'] = $_GET['q'];
                }
                
                // Legacy 'name' filter support
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
                
                if (isset($_GET['owner']) && $_GET['owner'] !== '') {
                    $filters['owner'] = (int)$_GET['owner'];
                }
                
                // Add ACL filter for non-admin users
                // Use expanded zone IDs to include parent masters for users with ACL on includes
                $effectiveZoneIds = $expandedZoneIds !== null ? $expandedZoneIds : $allowedZoneIds;
                if ($effectiveZoneIds !== null && !empty($effectiveZoneIds)) {
                    $filters['zone_ids'] = $effectiveZoneIds;
                }

                $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : ($page - 1) * $per_page;

                // Get total count for pagination
                $total = $zoneFile->count($filters);
                
                // Get paginated results
                $zones = $zoneFile->search($filters, $per_page, $offset);
                
                // Add include count to each zone (using COUNT query to prevent OOM)
                foreach ($zones as &$zone) {
                    $zone['includes_count'] = $zoneFile->getIncludesCount($zone['id']);
                }

                echo json_encode([
                    'success' => true,
                    'data' => $zones,
                    'total' => $total,
                    'page' => $page,
                    'per_page' => $per_page,
                    'total_pages' => ceil($total / $per_page)
                ]);
            }
            break;

        case 'search_zones':
            // Autocomplete search for zones (requires authentication)
            // Returns minimal payload for performance
            // For non-admin users, filter to only show zones they have ACL access to
            requireAuth();

            $q = isset($_GET['q']) ? trim($_GET['q']) : '';
            $limit = isset($_GET['limit']) ? min(100, max(1, (int)$_GET['limit'])) : 20;
            $file_type = isset($_GET['file_type']) ? $_GET['file_type'] : '';

            $filters = [];
            if ($q !== '') {
                $filters['q'] = $q;
            }
            if ($file_type !== '') {
                $allowed_types = ['master', 'include'];
                if (in_array($file_type, $allowed_types)) {
                    $filters['file_type'] = $file_type;
                }
            }
            // Only search active zones for autocomplete
            $filters['status'] = 'active';
            
            // For non-admin users, add ACL filter with expanded zone IDs
            if (!$auth->isAdmin()) {
                $expandedZoneIds = $auth->getExpandedZoneIds('read');
                if (empty($expandedZoneIds) && !$auth->isZoneEditor()) {
                    echo json_encode([
                        'success' => true,
                        'data' => []
                    ]);
                    break;
                }
                
                if (!empty($expandedZoneIds)) {
                    $filters['zone_ids'] = $expandedZoneIds;
                }
            }

            $zones = $zoneFile->search($filters, $limit, 0);

            // Return minimal data for autocomplete
            $results = array_map(function($zone) {
                return [
                    'id' => $zone['id'],
                    'name' => $zone['name'],
                    'filename' => $zone['filename'],
                    'file_type' => $zone['file_type']
                ];
            }, $zones);

            echo json_encode([
                'success' => true,
                'data' => $results
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

            // For non-admin users, verify they have access to this zone
            // Use expanded zone IDs to allow access to parent masters if user has ACL on includes
            if (!$auth->isAdmin()) {
                $expandedZoneIds = $auth->getExpandedZoneIds('read');
                
                if (!in_array($id, $expandedZoneIds) && !$auth->isZoneEditor()) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Access denied to this zone']);
                    exit;
                }
            }

            // Get includes with limit to prevent OOM
            $includes_count_total = $zoneFile->getIncludesCount($id);
            $includes = $zoneFile->getIncludes($id, MAX_INCLUDES_RETURN);
            $includes_truncated = $includes_count_total > count($includes);

            // Also get history
            $history = $zoneFile->getHistory($id);

            echo json_encode([
                'success' => true,
                'data' => $zone,
                'includes' => $includes,
                'includes_count_total' => $includes_count_total,
                'includes_truncated' => $includes_truncated,
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

            // Validate directory field
            if (isset($input['directory']) && $input['directory'] !== null && $input['directory'] !== '') {
                $directory = trim($input['directory']);
                if (strlen($directory) > 255) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path too long (max 255 characters)']);
                    exit;
                }
                if (strpos($directory, '\\') !== false) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path cannot contain backslashes']);
                    exit;
                }
                if (strpos($directory, '..') !== false) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path cannot contain ".."']);
                    exit;
                }
            }

            // Validate domain field (only for master zones)
            if (isset($input['domain']) && $input['domain'] !== null && $input['domain'] !== '') {
                $fileType = $input['file_type'] ?? 'master';
                if ($fileType === 'master') {
                    $domain = trim($input['domain']);
                    if (strlen($domain) > 255) {
                        http_response_code(400);
                        echo json_encode(['error' => 'Domain name too long (max 255 characters)']);
                        exit;
                    }
                    // Basic domain validation
                    if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $domain)) {
                        http_response_code(400);
                        echo json_encode(['error' => 'Invalid domain format']);
                        exit;
                    }
                } else {
                    // Log warning if domain provided for non-master zone (but don't fail)
                    error_log("Warning: domain parameter ignored for non-master zone (file_type: {$fileType})");
                }
            }

            $user = $auth->getCurrentUser();
            
            try {
                $zone_id = $zoneFile->create($input, $user['id']);
                
                // Trigger validation after creation (non-blocking - errors are logged but don't prevent creation)
                try {
                    $zoneFile->validateZoneFile($zone_id, $user['id']);
                } catch (Exception $validationError) {
                    // Log validation error but don't fail the creation
                    error_log("Post-creation validation error for zone ID {$zone_id}: " . $validationError->getMessage());
                }
                
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'Zone file created successfully',
                    'id' => $zone_id
                ]);
            } catch (Exception $e) {
                http_response_code(400);
                echo json_encode(['error' => $e->getMessage()]);
            }
            break;

        case 'update_zone':
            // Update a zone file (admin only)
            requireAdmin();

            // Read id from querystring first
            $id = (int)($_GET['id'] ?? 0);
            
            // Get JSON input (always needed for update)
            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                $input = $_POST;
            }
            
            // Fallback: if id not in querystring, try to get it from JSON body
            if ($id <= 0 && isset($input['id'])) {
                $id = (int)$input['id'];
            }
            
            // Validate id
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid zone file ID']);
                exit;
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

            // Validate directory field
            if (isset($input['directory']) && $input['directory'] !== null && $input['directory'] !== '') {
                $directory = trim($input['directory']);
                if (strlen($directory) > 255) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path too long (max 255 characters)']);
                    exit;
                }
                if (strpos($directory, '\\') !== false) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path cannot contain backslashes']);
                    exit;
                }
                if (strpos($directory, '..') !== false) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Directory path cannot contain ".."']);
                    exit;
                }
            }

            // Validate domain field (only for master zones)
            if (isset($input['domain']) && $input['domain'] !== null && $input['domain'] !== '') {
                // Get current zone to check file_type
                $currentZone = $zoneFile->getById($id);
                if (!$currentZone) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Zone file not found']);
                    exit;
                }
                
                $fileType = $input['file_type'] ?? $currentZone['file_type'];
                if ($fileType === 'master') {
                    $domain = trim($input['domain']);
                    if (strlen($domain) > 255) {
                        http_response_code(400);
                        echo json_encode(['error' => 'Domain name too long (max 255 characters)']);
                        exit;
                    }
                    // Basic domain validation
                    if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $domain)) {
                        http_response_code(400);
                        echo json_encode(['error' => 'Invalid domain format']);
                        exit;
                    }
                } else {
                    // Log warning if domain provided for non-master zone (but don't fail)
                    error_log("Warning: domain parameter ignored for non-master zone (file_type: {$fileType})");
                }
            }

            $user = $auth->getCurrentUser();
            
            try {
                $success = $zoneFile->update($id, $input, $user['id']);
                
                // Trigger validation after update
                $zoneFile->validateZoneFile($id, $user['id']);
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Zone file updated successfully'
                ]);
            } catch (Exception $e) {
                http_response_code(400);
                echo json_encode(['error' => $e->getMessage()]);
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
            // Now supports reassignment if include already has a parent
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

            $user = $auth->getCurrentUser();
            $result = $zoneFile->assignInclude($parent_id, $include_id, $position, $user['id']);

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

        case 'create_and_assign_include':
            // Create an include and assign it to a parent in one call (admin only)
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
            if (!isset($input['parent_id']) || (int)$input['parent_id'] <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required field: parent_id']);
                exit;
            }

            $user = $auth->getCurrentUser();
            
            // Force file_type to include
            $zoneData = [
                'name' => $input['name'],
                'filename' => $input['filename'],
                'content' => $input['content'] ?? '',
                'file_type' => 'include'
            ];
            
            // Create the include
            $include_id = $zoneFile->create($zoneData, $user['id']);
            
            if (!$include_id) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to create include zone file']);
                exit;
            }

            // Assign it to the parent
            $parent_id = (int)$input['parent_id'];
            $position = isset($input['position']) ? (int)$input['position'] : 0;
            
            $result = $zoneFile->assignInclude($parent_id, $include_id, $position, $user['id']);

            if ($result === true) {
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'message' => 'Include created and assigned successfully',
                    'id' => $include_id
                ]);
            } else {
                // Include was created but assignment failed - include still exists
                http_response_code(500);
                echo json_encode([
                    'error' => 'Include created but assignment failed: ' . (is_string($result) ? $result : 'Unknown error'),
                    'id' => $include_id
                ]);
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

        case 'generate_zone_file':
            // Generate complete zone file with includes and DNS records (admin only)
            requireAdmin();

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

            $generatedContent = $zoneFile->generateZoneFile($id);
            if ($generatedContent === null) {
                http_response_code(500);
                echo json_encode(['error' => 'Failed to generate zone file']);
                exit;
            }

            echo json_encode([
                'success' => true,
                'content' => $generatedContent,
                'filename' => $zone['filename']
            ]);
            break;

        case 'zone_validate':
            // Trigger or retrieve validation result for a zone
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

            // Check if requesting new validation or just retrieving latest
            $trigger = isset($_GET['trigger']) && $_GET['trigger'] === 'true';
            
            if ($trigger && $auth->isAdmin()) {
                // Only admins can trigger validation
                $user = $auth->getCurrentUser();
                $sync = isset($_GET['sync']) && $_GET['sync'] === 'true';
                
                $result = $zoneFile->validateZoneFile($id, $user['id'], $sync);
                
                if ($result === false) {
                    http_response_code(500);
                    echo json_encode(['error' => 'Failed to queue validation']);
                    exit;
                }
                
                if (is_array($result)) {
                    // Synchronous result
                    echo json_encode([
                        'success' => true,
                        'validation' => $result
                    ]);
                } else {
                    // Queued for background processing
                    // Return the latest known validation so UI can display current state
                    $latestValidation = $zoneFile->getLatestValidation($id);
                    
                    echo json_encode([
                        'success' => true,
                        'message' => 'Validation queued for background processing',
                        'validation' => $latestValidation
                    ]);
                }
            } else {
                // Retrieve latest validation result
                $validation = $zoneFile->getLatestValidation($id);
                
                echo json_encode([
                    'success' => true,
                    'validation' => $validation
                ]);
            }
            break;

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
