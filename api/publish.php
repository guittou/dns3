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
    
    // Process each zone
    $results = [];
    $successCount = 0;
    $failureCount = 0;
    
    foreach ($activeZones as $zone) {
        $zoneId = $zone['id'];
        $zoneName = $zone['name'];
        
        $result = [
            'id' => $zoneId,
            'name' => $zoneName,
            'status' => 'pending'
        ];
        
        try {
            // Generate zone file content
            $content = $zoneFileModel->generateZoneFile($zoneId);
            
            if ($content === null || trim($content) === '') {
                $result['status'] = 'failed';
                $result['error'] = 'Failed to generate zone file content';
                $failureCount++;
                $results[] = $result;
                
                Logger::warn('publish', 'Zone content generation failed', [
                    'zone_id' => $zoneId,
                    'zone_name' => $zoneName,
                    'user_id' => $userId
                ]);
                continue;
            }
            
            // Validate with named-checkzone before writing
            $validation = $zoneFileModel->validateZoneFile($zoneId, $userId, true);
            
            if (!$validation || $validation['status'] !== 'passed') {
                $result['status'] = 'failed';
                $result['error'] = 'Zone validation failed';
                $result['validation_output'] = $validation['output'] ?? 'No validation output available';
                $failureCount++;
                $results[] = $result;
                
                Logger::warn('publish', 'Zone validation failed', [
                    'zone_id' => $zoneId,
                    'zone_name' => $zoneName,
                    'user_id' => $userId,
                    'validation_output' => substr($validation['output'] ?? '', 0, 500)
                ]);
                continue;
            }
            
            // Validation passed - write to disk
            $writeResult = $zoneFileModel->writeZoneFileToDisk($zoneId, $bindBasedir);
            
            if ($writeResult['success']) {
                $result['status'] = 'success';
                $result['file_path'] = $writeResult['file_path'];
                $successCount++;
                
                Logger::info('publish', 'Zone published successfully', [
                    'zone_id' => $zoneId,
                    'zone_name' => $zoneName,
                    'file_path' => $writeResult['file_path'],
                    'user_id' => $userId
                ]);
            } else {
                $result['status'] = 'failed';
                $result['error'] = $writeResult['error'] ?? 'Failed to write zone file to disk';
                $failureCount++;
                
                Logger::error('publish', 'Zone file write failed', [
                    'zone_id' => $zoneId,
                    'zone_name' => $zoneName,
                    'error' => $writeResult['error'] ?? 'unknown',
                    'user_id' => $userId
                ]);
            }
            
        } catch (Exception $e) {
            $result['status'] = 'failed';
            $result['error'] = 'Exception: ' . $e->getMessage();
            $failureCount++;
            
            Logger::error('publish', 'Zone publication exception', [
                'zone_id' => $zoneId,
                'zone_name' => $zoneName,
                'error' => $e->getMessage(),
                'user_id' => $userId
            ]);
        }
        
        $results[] = $result;
    }
    
    // Determine overall success
    $overallSuccess = $failureCount === 0;
    
    Logger::info('publish', 'Zone publication completed', [
        'user_id' => $userId,
        'total_zones' => count($activeZones),
        'success_count' => $successCount,
        'failure_count' => $failureCount,
        'overall_success' => $overallSuccess
    ]);
    
    // Return results
    $response = [
        'success' => $overallSuccess,
        'message' => $overallSuccess 
            ? "All $successCount zones published successfully" 
            : "$successCount zones published, $failureCount failed",
        'total' => count($activeZones),
        'success_count' => $successCount,
        'failure_count' => $failureCount,
        'zones' => $results
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
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
