<?php
/**
 * Test for Zone Publishing functionality
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/ZoneFile.php';
require_once __DIR__ . '/../../includes/db.php';

class ZonePublishTest extends TestCase
{
    private $zoneFile;
    private $testZoneId;
    private $db;
    
    protected function setUp(): void
    {
        $this->zoneFile = new ZoneFile();
        $this->db = Database::getInstance()->getConnection();
        
        // Create a test zone for publishing
        $this->createTestZone();
    }
    
    protected function tearDown(): void
    {
        // Clean up test zone
        if ($this->testZoneId) {
            $this->cleanupTestZone();
        }
    }
    
    /**
     * Create a test zone for publishing
     */
    private function createTestZone()
    {
        // Create test user if needed
        $stmt = $this->db->prepare("SELECT id FROM users WHERE username = 'test_publish_user' LIMIT 1");
        $stmt->execute();
        $user = $stmt->fetch();
        
        if (!$user) {
            $stmt = $this->db->prepare("INSERT INTO users (username, password_hash, auth_method, is_active) VALUES ('test_publish_user', 'test', 'database', 1)");
            $stmt->execute();
            $userId = $this->db->lastInsertId();
        } else {
            $userId = $user['id'];
        }
        
        // Create a test zone
        $zoneName = 'test-publish-' . uniqid() . '.example.com';
        $data = [
            'name' => $zoneName,
            'filename' => $zoneName . '.db',
            'directory' => null,
            'file_type' => 'master',
            'domain' => $zoneName,
            'content' => '; Test zone content',
            'default_ttl' => 3600,
            'soa_refresh' => 10800,
            'soa_retry' => 900,
            'soa_expire' => 604800,
            'soa_minimum' => 3600,
            'soa_rname' => 'admin@example.com',
            'mname' => 'ns1.example.com.'
        ];
        
        $this->testZoneId = $this->zoneFile->create($data, $userId);
    }
    
    /**
     * Clean up test zone
     */
    private function cleanupTestZone()
    {
        if ($this->testZoneId) {
            // Hard delete from database
            $stmt = $this->db->prepare("DELETE FROM zone_files WHERE id = ?");
            $stmt->execute([$this->testZoneId]);
            
            $stmt = $this->db->prepare("DELETE FROM zone_file_history WHERE zone_file_id = ?");
            $stmt->execute([$this->testZoneId]);
        }
    }
    
    /**
     * Test writeZoneFileToDisk method with valid zone
     */
    public function testWriteZoneFileToDisk()
    {
        // Create temporary directory for testing
        $tmpDir = sys_get_temp_dir() . '/dns3_publish_test_' . uniqid();
        mkdir($tmpDir, 0755, true);
        
        try {
            // Write zone to disk
            $result = $this->zoneFile->writeZoneFileToDisk($this->testZoneId, $tmpDir);
            
            // Assert success
            $this->assertTrue($result['success'], 'writeZoneFileToDisk should succeed');
            $this->assertArrayHasKey('file_path', $result);
            $this->assertFileExists($result['file_path'], 'Zone file should be written to disk');
            
            // Verify file content
            $content = file_get_contents($result['file_path']);
            $this->assertStringContainsString('$TTL', $content, 'Zone file should contain $TTL directive');
            $this->assertStringContainsString('SOA', $content, 'Zone file should contain SOA record');
            $this->assertStringContainsString('Test zone content', $content, 'Zone file should contain zone content');
            
            // Verify file permissions (should be readable)
            $this->assertTrue(is_readable($result['file_path']), 'Zone file should be readable');
            
        } finally {
            // Clean up temporary directory
            if (is_dir($tmpDir)) {
                $files = scandir($tmpDir);
                foreach ($files as $file) {
                    if ($file !== '.' && $file !== '..') {
                        $filePath = $tmpDir . '/' . $file;
                        if (is_file($filePath)) {
                            unlink($filePath);
                        }
                    }
                }
                rmdir($tmpDir);
            }
        }
    }
    
    /**
     * Test writeZoneFileToDisk with directory structure
     */
    public function testWriteZoneFileToDiskWithDirectory()
    {
        // Update zone with directory
        $this->zoneFile->update($this->testZoneId, [
            'directory' => 'zones/test'
        ], 1);
        
        // Create temporary directory for testing
        $tmpDir = sys_get_temp_dir() . '/dns3_publish_test_' . uniqid();
        mkdir($tmpDir, 0755, true);
        
        try {
            // Write zone to disk
            $result = $this->zoneFile->writeZoneFileToDisk($this->testZoneId, $tmpDir);
            
            // Assert success
            $this->assertTrue($result['success'], 'writeZoneFileToDisk should succeed with directory');
            $this->assertArrayHasKey('file_path', $result);
            $this->assertFileExists($result['file_path'], 'Zone file should be written to disk in subdirectory');
            
            // Verify file is in correct directory
            $this->assertStringContainsString('/zones/test/', $result['file_path'], 'File should be in zones/test subdirectory');
            
            // Verify directory was created
            $this->assertDirectoryExists($tmpDir . '/zones/test', 'Subdirectory should be created');
            
        } finally {
            // Clean up temporary directory recursively
            if (is_dir($tmpDir)) {
                $this->rmdirRecursive($tmpDir);
            }
        }
    }
    
    /**
     * Test writeZoneFileToDisk with invalid zone ID
     */
    public function testWriteZoneFileToDiskWithInvalidZone()
    {
        $tmpDir = sys_get_temp_dir() . '/dns3_publish_test_' . uniqid();
        mkdir($tmpDir, 0755, true);
        
        try {
            // Try to write non-existent zone
            $result = $this->zoneFile->writeZoneFileToDisk(999999, $tmpDir);
            
            // Assert failure
            $this->assertFalse($result['success'], 'writeZoneFileToDisk should fail for non-existent zone');
            $this->assertArrayHasKey('error', $result);
            $this->assertStringContainsString('not found', $result['error']);
            
        } finally {
            // Clean up temporary directory
            if (is_dir($tmpDir)) {
                rmdir($tmpDir);
            }
        }
    }
    
    /**
     * Test writeZoneFileToDisk with non-writable directory
     */
    public function testWriteZoneFileToDiskWithNonWritableDirectory()
    {
        // Skip this test if running as root (can write to read-only directories)
        if (posix_getuid() === 0) {
            $this->markTestSkipped('Test cannot run as root user');
        }
        
        $tmpDir = sys_get_temp_dir() . '/dns3_publish_test_' . uniqid();
        mkdir($tmpDir, 0555, true); // Read-only directory
        
        try {
            // Try to write to read-only directory
            $result = $this->zoneFile->writeZoneFileToDisk($this->testZoneId, $tmpDir);
            
            // Assert failure
            $this->assertFalse($result['success'], 'writeZoneFileToDisk should fail for read-only directory');
            $this->assertArrayHasKey('error', $result);
            $this->assertStringContainsString('not writable', $result['error']);
            
        } finally {
            // Clean up temporary directory (change permissions first)
            if (is_dir($tmpDir)) {
                chmod($tmpDir, 0755);
                rmdir($tmpDir);
            }
        }
    }
    
    /**
     * Test collectAllIncludes method with nested includes
     */
    public function testCollectAllIncludes()
    {
        // Create test user
        $stmt = $this->db->prepare("SELECT id FROM users WHERE username = 'test_publish_user' LIMIT 1");
        $stmt->execute();
        $user = $stmt->fetch();
        $userId = $user['id'];
        
        // Create include files
        $include1Data = [
            'name' => 'test-include-1-' . uniqid(),
            'filename' => 'include1.db',
            'directory' => 'includes',
            'file_type' => 'include',
            'content' => '; Include 1 content'
        ];
        $include1Id = $this->zoneFile->create($include1Data, $userId);
        
        $include2Data = [
            'name' => 'test-include-2-' . uniqid(),
            'filename' => 'include2.db',
            'directory' => 'includes/nested',
            'file_type' => 'include',
            'content' => '; Include 2 content (nested)'
        ];
        $include2Id = $this->zoneFile->create($include2Data, $userId);
        
        try {
            // Link include1 to master zone
            $stmt = $this->db->prepare("INSERT INTO zone_file_includes (parent_id, include_id, position) VALUES (?, ?, ?)");
            $stmt->execute([$this->testZoneId, $include1Id, 1]);
            
            // Link include2 to include1 (nested)
            $stmt->execute([$include1Id, $include2Id, 1]);
            
            // Test collectAllIncludes
            $visited = [];
            $includes = $this->zoneFile->collectAllIncludes($this->testZoneId, $visited);
            
            // Should return both include1 and include2 (recursively)
            $this->assertCount(2, $includes, 'Should collect 2 includes (1 direct + 1 nested)');
            
            // Verify include IDs are present
            $includeIds = array_column($includes, 'id');
            $this->assertContains($include1Id, $includeIds, 'Should contain include1');
            $this->assertContains($include2Id, $includeIds, 'Should contain include2 (nested)');
            
        } finally {
            // Clean up test includes
            $stmt = $this->db->prepare("DELETE FROM zone_file_includes WHERE parent_id = ? OR include_id IN (?, ?)");
            $stmt->execute([$this->testZoneId, $include1Id, $include2Id]);
            
            $stmt = $this->db->prepare("DELETE FROM zone_files WHERE id IN (?, ?)");
            $stmt->execute([$include1Id, $include2Id]);
        }
    }
    
    /**
     * Test collectAllIncludes with circular dependency detection
     */
    public function testCollectAllIncludesWithCircularDependency()
    {
        // Create test user
        $stmt = $this->db->prepare("SELECT id FROM users WHERE username = 'test_publish_user' LIMIT 1");
        $stmt->execute();
        $user = $stmt->fetch();
        $userId = $user['id'];
        
        // Create two include files
        $include1Data = [
            'name' => 'test-circular-1-' . uniqid(),
            'filename' => 'circular1.db',
            'directory' => 'includes',
            'file_type' => 'include',
            'content' => '; Circular include 1'
        ];
        $include1Id = $this->zoneFile->create($include1Data, $userId);
        
        $include2Data = [
            'name' => 'test-circular-2-' . uniqid(),
            'filename' => 'circular2.db',
            'directory' => 'includes',
            'file_type' => 'include',
            'content' => '; Circular include 2'
        ];
        $include2Id = $this->zoneFile->create($include2Data, $userId);
        
        try {
            // Create circular dependency: include1 -> include2 -> include1
            $stmt = $this->db->prepare("INSERT INTO zone_file_includes (parent_id, include_id, position) VALUES (?, ?, ?)");
            $stmt->execute([$include1Id, $include2Id, 1]);
            $stmt->execute([$include2Id, $include1Id, 1]);
            
            // Test collectAllIncludes - should handle circular dependency gracefully
            $visited = [];
            $includes = $this->zoneFile->collectAllIncludes($include1Id, $visited);
            
            // Should return only include2 once (circular reference detected)
            $this->assertCount(1, $includes, 'Should collect only 1 include (circular dependency detected)');
            $this->assertEquals($include2Id, $includes[0]['id'], 'Should contain include2');
            
        } finally {
            // Clean up test includes
            $stmt = $this->db->prepare("DELETE FROM zone_file_includes WHERE include_id IN (?, ?) OR parent_id IN (?, ?)");
            $stmt->execute([$include1Id, $include2Id, $include1Id, $include2Id]);
            
            $stmt = $this->db->prepare("DELETE FROM zone_files WHERE id IN (?, ?)");
            $stmt->execute([$include1Id, $include2Id]);
        }
    }
    
    /**
     * Recursively remove directory
     */
    private function rmdirRecursive($dir)
    {
        if (!is_dir($dir)) {
            return;
        }
        
        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = $dir . '/' . $file;
            if (is_dir($path)) {
                $this->rmdirRecursive($path);
            } else {
                unlink($path);
            }
        }
        rmdir($dir);
    }
}
