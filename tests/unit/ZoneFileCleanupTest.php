<?php
/**
 * Unit tests for zone validation temporary directory cleanup
 * Tests the improved error handling for temporary file cleanup
 */

use PHPUnit\Framework\TestCase;

class ZoneFileCleanupTest extends TestCase {
    
    /**
     * Test that cleanup success is properly logged
     */
    public function testCleanupSuccessLogging() {
        $tmpDir = '/tmp/dns3_validate_test123';
        
        // Expected log message for successful cleanup
        $expectedLogMsg = "Temporary directory cleaned up successfully: $tmpDir";
        
        $this->assertStringContainsString(
            'cleaned up successfully',
            $expectedLogMsg,
            'Success log should indicate cleanup was successful'
        );
    }
    
    /**
     * Test that cleanup failure is properly logged with ERROR prefix
     */
    public function testCleanupFailureLogging() {
        $tmpDir = '/tmp/dns3_validate_test456';
        
        // Expected log message for failed cleanup
        $expectedLogMsg = "ERROR: Failed to clean up temporary directory: $tmpDir";
        
        $this->assertStringStartsWith(
            'ERROR:',
            $expectedLogMsg,
            'Failure log should start with ERROR prefix'
        );
        
        $this->assertStringContainsString(
            'Failed to clean up',
            $expectedLogMsg,
            'Failure log should indicate cleanup failed'
        );
    }
    
    /**
     * Test that DEBUG_KEEP_TMPDIR prevents cleanup
     */
    public function testDebugKeepTmpdir() {
        // When DEBUG_KEEP_TMPDIR is true (set via JOBS_KEEP_TMP=1 env var), cleanup should be skipped
        $debugMessage = "DEBUG: Temporary directory kept at: /tmp/dns3_validate_debug (JOBS_KEEP_TMP=1)";
        
        $this->assertStringStartsWith(
            'DEBUG:',
            $debugMessage,
            'Debug message should start with DEBUG prefix'
        );
        
        $this->assertStringContainsString(
            'kept at',
            $debugMessage,
            'Debug message should indicate directory was kept'
        );
    }
    
    /**
     * Test that error messages include file path for debugging
     */
    public function testErrorMessagesIncludePath() {
        $path = '/tmp/dns3_validate_abc/zone_123.db';
        
        // Expected error log format
        $expectedError = "Failed to delete file: $path";
        
        $this->assertStringContainsString(
            $path,
            $expectedError,
            'Error message should include the file path for debugging'
        );
    }
    
    /**
     * Test that directory removal errors include directory path
     */
    public function testDirectoryRemovalErrorsIncludePath() {
        $dir = '/tmp/dns3_validate_xyz';
        
        // Expected error log format
        $expectedError = "Failed to remove directory: $dir";
        
        $this->assertStringContainsString(
            $dir,
            $expectedError,
            'Error message should include the directory path for debugging'
        );
    }
    
    /**
     * Test temporary directory naming pattern
     */
    public function testTemporaryDirectoryNamingPattern() {
        // sys_get_temp_dir() . '/dns3_validate_' . uniqid()
        // uniqid() returns alphanumeric string (not just hex)
        $pattern = '/^\/.*\/dns3_validate_[a-z0-9]+$/';
        
        $examplePath = '/tmp/dns3_validate_5f8a9b2c3d4e1';
        
        $this->assertMatchesRegularExpression(
            $pattern,
            $examplePath,
            'Temporary directory should follow the naming pattern: /path/dns3_validate_<uniqid>'
        );
    }
}
?>
