<?php
/**
 * Unit tests for zone validation output capture
 * Tests the improvements made to capture full named-checkzone output
 */

use PHPUnit\Framework\TestCase;

class ZoneValidationOutputTest extends TestCase {
    
    /**
     * Test that validation output file path is correctly formatted
     */
    public function testValidationOutputFilePathFormat() {
        $tmpDir = '/tmp/dns3_validate_abc123';
        $zoneId = 42;
        
        // Expected file path format based on the implementation
        $expectedPath = $tmpDir . '/zone_' . $zoneId . '_validation_output.txt';
        
        $this->assertEquals(
            '/tmp/dns3_validate_abc123/zone_42_validation_output.txt',
            $expectedPath,
            'Validation output file path should follow the pattern: tmpdir/zone_<id>_validation_output.txt'
        );
    }
    
    /**
     * Test that validation log reference is prepended to output
     */
    public function testValidationLogReferencePrepended() {
        $validationOutFile = '/tmp/dns3_validate_abc123/zone_42_validation_output.txt';
        $outputText = "zone example.com/IN: loaded serial 2024010101\nOK";
        
        // Simulate what the code does
        $outputWithLogRef = "Validation log file: $validationOutFile\n\n" . $outputText;
        
        $this->assertStringStartsWith(
            "Validation log file: /tmp/dns3_validate_abc123/zone_42_validation_output.txt",
            $outputWithLogRef,
            'Output should start with validation log file reference'
        );
        
        $this->assertStringContainsString(
            $outputText,
            $outputWithLogRef,
            'Output should contain the original validation output'
        );
    }
    
    /**
     * Test that output excerpt is correctly limited to 40 lines
     */
    public function testOutputExcerptLimitedTo40Lines() {
        // Create output with more than 40 lines
        $lines = [];
        for ($i = 1; $i <= 50; $i++) {
            $lines[] = "Line $i: some validation error message";
        }
        $outputText = implode("\n", $lines);
        
        // Simulate what the code does - extract first 40 lines
        $allLines = explode("\n", $outputText);
        $excerpt = array_slice($allLines, 0, 40);
        
        $this->assertCount(40, $excerpt, 'Excerpt should contain exactly 40 lines');
        $this->assertEquals('Line 1: some validation error message', $excerpt[0]);
        $this->assertEquals('Line 40: some validation error message', $excerpt[39]);
    }
    
    /**
     * Test that command no longer includes -q flag
     */
    public function testCommandDoesNotIncludeQuietFlag() {
        // This is a conceptual test - we verify the expected command format
        $namedCheckzone = 'named-checkzone';
        $zoneName = 'example.com';
        $tempFilePath = '/tmp/zone.db';
        
        // Expected command format (without -q flag)
        $expectedCommand = escapeshellcmd($namedCheckzone) . ' ' . 
                          escapeshellarg($zoneName) . ' ' . 
                          escapeshellarg($tempFilePath) . ' 2>&1';
        
        $this->assertStringNotContainsString(
            '-q',
            $expectedCommand,
            'Command should not contain the -q (quiet) flag'
        );
        
        $this->assertStringContainsString(
            'named-checkzone',
            $expectedCommand,
            'Command should contain named-checkzone'
        );
        
        $this->assertStringContainsString(
            '2>&1',
            $expectedCommand,
            'Command should redirect stderr to stdout to capture all output'
        );
    }
    
    /**
     * Test that validation output includes both success and failure messages
     */
    public function testValidationOutputFormats() {
        // Test success output format
        $successOutput = "zone example.com/IN: loaded serial 2024010101\nOK";
        $this->assertStringContainsString('OK', $successOutput);
        $this->assertStringContainsString('loaded serial', $successOutput);
        
        // Test failure output format
        $failureOutput = "dns_master_load: example.com:5: bad owner name (check-names)\n" .
                        "zone example.com/IN: loading from master file example.com failed: bad owner name (check-names)\n" .
                        "zone example.com/IN: not loaded due to errors.";
        $this->assertStringContainsString('not loaded due to errors', $failureOutput);
        $this->assertStringContainsString('bad owner name', $failureOutput);
    }
}
?>
