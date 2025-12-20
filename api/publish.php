<?php
/**
 * Publish API
 * Generates and writes all active zone files to disk
 * Admin-only endpoint
 * 
 * POST /api/publish.php - Publish all active zones
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/ZoneFile.php';
require_once __DIR__ . '/../includes/lib/Logger.php';

// Set JSON header with UTF-8 charset
header('Content-Type: application/json; charset=utf-8');

// Initialize authentication
$auth = new Auth();

// Try Bearer token authentication first (for API clients)
// If no token or invalid token, fall back to session authentication
if (!$auth->isLoggedIn()) {
    $auth->authenticateToken();
}

// Check if user is admin (required for publish endpoint)
if (!$auth->isLoggedIn()) {
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

if (!$auth->isAdmin()) {
    http_response_code(403);
    echo json_encode(['error' => 'Admin privileges required for publishing zones']);
    exit;
}

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed. Use POST.']);
    exit;
}

// Get current user
$currentUser = $auth->getCurrentUser();
$userId = $currentUser['id'] ?? null;

// Initialize ZoneFile model
$zoneFileModel = new ZoneFile();

try {
    // Get all active master zones
    $filters = [
        'status' => 'active',
        'file_type' => 'master'
    ];
    
    $activeZones = $zoneFileModel->search($filters, 1000, 0);
    
    if (empty($activeZones)) {
        echo json_encode([
            'success' => true,
            'message' => 'No active zones to publish',
            'zones' => []
        ]);
        exit;
    }
    
    Logger::info('publish', 'Starting zone publication', [
        'user_id' => $userId,
        'username' => $currentUser['username'] ?? 'unknown',
        'zone_count' => count($activeZones)
    ]);
    
    // Check BIND_BASEDIR is configured
    $bindBasedir = defined('BIND_BASEDIR') ? BIND_BASEDIR : null;
    if (empty($bindBasedir)) {
        Logger::error('publish', 'BIND_BASEDIR not configured', ['user_id' => $userId]);
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'BIND_BASEDIR is not configured. Cannot publish zones to disk.'
        ]);
        exit;
    }
    
    // Verify BIND_BASEDIR exists and is writable
    if (!is_dir($bindBasedir)) {
        Logger::error('publish', 'BIND_BASEDIR directory does not exist', [
            'user_id' => $userId,
            'bind_basedir' => $bindBasedir
        ]);
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => "BIND_BASEDIR directory does not exist: $bindBasedir"
        ]);
        exit;
    }
    
    if (!is_writable($bindBasedir)) {
        Logger::error('publish', 'BIND_BASEDIR directory is not writable', [
            'user_id' => $userId,
            'bind_basedir' => $bindBasedir
        ]);
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => "BIND_BASEDIR directory is not writable: $bindBasedir"
        ]);
        exit;
    }
    
    // Process each zone and collect all files to publish (masters + includes)
    $results = [];
    $successCount = 0;
    $failureCount = 0;
    $processedZoneIds = []; // Track processed zones to avoid duplicates
    
    foreach ($activeZones as $zone) {
        $zoneId = $zone['id'];
        $zoneName = $zone['name'];
        
        try {
            // Collect all zone files to publish: master + all its includes recursively
            $zonesToPublish = [];
            
            // Add the master zone itself
            $zonesToPublish[] = [
                'id' => $zoneId,
                'name' => $zoneName,
                'file_type' => $zone['file_type']
            ];
            
            // Collect all includes recursively
            $visited = [];
            $includes = $zoneFileModel->collectAllIncludes($zoneId, $visited);
            foreach ($includes as $include) {
                $zonesToPublish[] = [
                    'id' => $include['id'],
                    'name' => $include['name'],
                    'file_type' => $include['file_type']
                ];
            }
            
            // Process each zone file (master + includes)
            foreach ($zonesToPublish as $zoneToPublish) {
                $currentZoneId = $zoneToPublish['id'];
                $currentZoneName = $zoneToPublish['name'];
                $currentFileType = $zoneToPublish['file_type'];
                
                // Skip if already processed (avoid duplicates when includes are shared)
                if (in_array($currentZoneId, $processedZoneIds)) {
                    continue;
                }
                
                $result = [
                    'id' => $currentZoneId,
                    'name' => $currentZoneName,
                    'file_type' => $currentFileType,
                    'status' => 'pending'
                ];
                
                try {
                    // Generate zone file content
                    $content = $zoneFileModel->generateZoneFile($currentZoneId);
                    
                    if ($content === null || trim($content) === '') {
                        $result['status'] = 'failed';
                        $result['error'] = 'Failed to generate zone file content';
                        $failureCount++;
                        $results[] = $result;
                        
                        Logger::warn('publish', 'Zone content generation failed', [
                            'zone_id' => $currentZoneId,
                            'zone_name' => $currentZoneName,
                            'file_type' => $currentFileType,
                            'user_id' => $userId
                        ]);
                        continue;
                    }
                    
                    // Validate zone files before writing
                    if ($currentFileType === 'master') {
                        // Master zones: validate with named-checkzone (includes all $INCLUDE directives)
                        $validation = $zoneFileModel->validateZoneFile($currentZoneId, $userId, true);
                        
                        if (!$validation || $validation['status'] !== 'passed') {
                            $result['status'] = 'failed';
                            $result['error'] = 'Zone validation failed';
                            $result['validation_output'] = $validation['output'] ?? 'No validation output available';
                            $failureCount++;
                            $results[] = $result;
                            
                            Logger::warn('publish', 'Zone validation failed', [
                                'zone_id' => $currentZoneId,
                                'zone_name' => $currentZoneName,
                                'user_id' => $userId,
                                'validation_output' => substr($validation['output'] ?? '', 0, 500)
                            ]);
                            continue;
                        }
                    } else {
                        // Include files: perform basic sanity check (content exists and is not empty)
                        // Note: Include files cannot be validated standalone with named-checkzone
                        // as they are zone fragments. They are validated as part of the master zone.
                        if (empty(trim($content))) {
                            $result['status'] = 'failed';
                            $result['error'] = 'Include file has no content';
                            $failureCount++;
                            $results[] = $result;
                            
                            Logger::warn('publish', 'Include file validation failed: empty content', [
                                'zone_id' => $currentZoneId,
                                'zone_name' => $currentZoneName,
                                'user_id' => $userId
                            ]);
                            continue;
                        }
                    }
                    
                    // Write to disk
                    $writeResult = $zoneFileModel->writeZoneFileToDisk($currentZoneId, $bindBasedir);
                    
                    if ($writeResult['success']) {
                        $result['status'] = 'success';
                        $result['file_path'] = $writeResult['file_path'];
                        $successCount++;
                        $processedZoneIds[] = $currentZoneId;
                        
                        Logger::info('publish', 'Zone file published successfully', [
                            'zone_id' => $currentZoneId,
                            'zone_name' => $currentZoneName,
                            'file_type' => $currentFileType,
                            'file_path' => $writeResult['file_path'],
                            'user_id' => $userId
                        ]);
                    } else {
                        $result['status'] = 'failed';
                        $result['error'] = $writeResult['error'] ?? 'Failed to write zone file to disk';
                        $failureCount++;
                        
                        Logger::error('publish', 'Zone file write failed', [
                            'zone_id' => $currentZoneId,
                            'zone_name' => $currentZoneName,
                            'file_type' => $currentFileType,
                            'error' => $writeResult['error'] ?? 'unknown',
                            'user_id' => $userId
                        ]);
                    }
                    
                } catch (Exception $e) {
                    $result['status'] = 'failed';
                    $result['error'] = 'Exception: ' . $e->getMessage();
                    $failureCount++;
                    
                    Logger::error('publish', 'Zone file publication exception', [
                        'zone_id' => $currentZoneId,
                        'zone_name' => $currentZoneName,
                        'file_type' => $currentFileType,
                        'error' => $e->getMessage(),
                        'user_id' => $userId
                    ]);
                }
                
                $results[] = $result;
            }
            
        } catch (Exception $e) {
            $result = [
                'id' => $zoneId,
                'name' => $zoneName,
                'status' => 'failed',
                'error' => 'Exception while collecting includes: ' . $e->getMessage()
            ];
            $failureCount++;
            $results[] = $result;
            
            Logger::error('publish', 'Zone collection exception', [
                'zone_id' => $zoneId,
                'zone_name' => $zoneName,
                'error' => $e->getMessage(),
                'user_id' => $userId
            ]);
        }
    }
    
    // Determine overall success
    $overallSuccess = $failureCount === 0;
    
    // Count distinct masters processed
    $totalMasters = count($activeZones);
    $totalFilesPublished = count($results);
    
    Logger::info('publish', 'Zone publication completed', [
        'user_id' => $userId,
        'total_master_zones' => $totalMasters,
        'total_files_published' => $totalFilesPublished,
        'success_count' => $successCount,
        'failure_count' => $failureCount,
        'overall_success' => $overallSuccess
    ]);
    
    // Return results
    $response = [
        'success' => $overallSuccess,
        'message' => $overallSuccess 
            ? "All $successCount zone files published successfully (from $totalMasters master zones)" 
            : "$successCount zone files published, $failureCount failed (from $totalMasters master zones)",
        'total_master_zones' => $totalMasters,
        'total_files' => $totalFilesPublished,
        'success_count' => $successCount,
        'failure_count' => $failureCount,
        'zones' => $results
    ];
    
    echo json_encode($response);
    
} catch (Exception $e) {
    Logger::error('publish', 'Publication fatal error', [
        'error' => $e->getMessage(),
        'user_id' => $userId
    ]);
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Fatal error during publication: ' . $e->getMessage()
    ]);
}
?>
