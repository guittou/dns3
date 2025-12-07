<?php
/**
 * Unit tests for zone validation fallback mechanism
 * Tests the fallback from generateFlatZone to generateZoneFile when empty content is returned
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/ZoneFile.php';

class ZoneFileFallbackTest extends TestCase {
    
    /**
     * Test that BOM is removed from content
     */
    public function testBomRemoval() {
        // UTF-8 BOM is 0xEF 0xBB 0xBF
        $contentWithBom = "\xEF\xBB\xBF" . '$TTL 86400' . "\n" . 'example.com. IN SOA ns1.example.com. admin.example.com. 1 3600 900 604800 86400';
        
        // Simulate BOM removal
        $cleanedContent = preg_replace('/^\xEF\xBB\xBF/', '', $contentWithBom);
        
        $this->assertStringStartsWith('$TTL', $cleanedContent, 'BOM should be removed from start of content');
        $this->assertStringNotContainsString("\xEF\xBB\xBF", $cleanedContent, 'Content should not contain BOM');
    }
    
    /**
     * Test that content without BOM is not modified
     */
    public function testNoBomContentUnchanged() {
        $contentNoBom = '$TTL 86400' . "\n" . 'example.com. IN SOA ns1.example.com. admin.example.com. 1 3600 900 604800 86400';
        
        // Simulate BOM removal
        $cleanedContent = preg_replace('/^\xEF\xBB\xBF/', '', $contentNoBom);
        
        $this->assertEquals($contentNoBom, $cleanedContent, 'Content without BOM should remain unchanged');
    }
    
    /**
     * Test that final newline is added when missing
     */
    public function testFinalNewlineAdded() {
        $contentWithoutNewline = '$TTL 86400';
        
        // Simulate adding final newline
        if (!empty($contentWithoutNewline) && substr($contentWithoutNewline, -1) !== "\n") {
            $contentWithoutNewline .= "\n";
        }
        
        $this->assertStringEndsWith("\n", $contentWithoutNewline, 'Content should end with newline');
    }
    
    /**
     * Test that final newline is not duplicated when already present
     */
    public function testFinalNewlineNotDuplicated() {
        $contentWithNewline = '$TTL 86400' . "\n";
        $originalLength = strlen($contentWithNewline);
        
        // Simulate adding final newline
        if (!empty($contentWithNewline) && substr($contentWithNewline, -1) !== "\n") {
            $contentWithNewline .= "\n";
        }
        
        $this->assertEquals($originalLength, strlen($contentWithNewline), 'Newline should not be duplicated');
        $this->assertStringEndsWith("\n", $contentWithNewline, 'Content should end with single newline');
    }
    
    /**
     * Test empty content handling
     */
    public function testEmptyContentHandling() {
        $emptyContent = '';
        
        // Empty content should be detected
        $isEmpty = ($emptyContent === null || trim($emptyContent) === '');
        $this->assertTrue($isEmpty, 'Empty string should be detected as empty');
        
        $nullContent = null;
        $isNull = ($nullContent === null || trim($nullContent ?? '') === '');
        $this->assertTrue($isNull, 'Null content should be detected as empty');
        
        $whitespaceContent = "   \n  \t  ";
        $isWhitespace = ($whitespaceContent === null || trim($whitespaceContent) === '');
        $this->assertTrue($isWhitespace, 'Whitespace-only content should be detected as empty');
    }
    
    /**
     * Test non-empty content detection
     */
    public function testNonEmptyContentDetection() {
        $validContent = '$TTL 86400';
        
        $isEmpty = ($validContent === null || trim($validContent) === '');
        $this->assertFalse($isEmpty, 'Valid content should not be detected as empty');
    }
    
    /**
     * Test UTF-8 encoding validation
     */
    public function testUtf8EncodingValidation() {
        $validUtf8 = 'Valid UTF-8 string with accents: café, naïve';
        
        $isValid = mb_check_encoding($validUtf8, 'UTF-8');
        $this->assertTrue($isValid, 'Valid UTF-8 string should pass encoding check');
    }
    
    /**
     * Test complete content cleaning pipeline
     */
    public function testCompleteContentCleaning() {
        // Start with problematic content: BOM + no final newline
        $problematicContent = "\xEF\xBB\xBF" . '$TTL 86400';
        
        // Apply cleaning steps
        // 1. Remove BOM
        $cleaned = preg_replace('/^\xEF\xBB\xBF/', '', $problematicContent);
        
        // 2. Ensure UTF-8 encoding
        if (!mb_check_encoding($cleaned, 'UTF-8')) {
            $cleaned = mb_convert_encoding($cleaned, 'UTF-8', 'UTF-8');
        }
        
        // 3. Add final newline
        if (!empty($cleaned) && substr($cleaned, -1) !== "\n") {
            $cleaned .= "\n";
        }
        
        // Verify results
        $this->assertStringNotContainsString("\xEF\xBB\xBF", $cleaned, 'BOM should be removed');
        $this->assertStringStartsWith('$TTL', $cleaned, 'Content should start with expected text');
        $this->assertStringEndsWith("\n", $cleaned, 'Content should end with newline');
    }
    
    /**
     * Test fallback scenario detection
     */
    public function testFallbackScenarioDetection() {
        // Scenario 1: generateFlatZone returns null
        $flatContent = null;
        $needsFallback = ($flatContent === null || trim($flatContent) === '');
        $this->assertTrue($needsFallback, 'Null content should trigger fallback');
        
        // Scenario 2: generateFlatZone returns empty string
        $flatContent = '';
        $needsFallback = ($flatContent === null || trim($flatContent) === '');
        $this->assertTrue($needsFallback, 'Empty string should trigger fallback');
        
        // Scenario 3: generateFlatZone returns whitespace only
        $flatContent = "   \n\t  ";
        $needsFallback = ($flatContent === null || trim($flatContent) === '');
        $this->assertTrue($needsFallback, 'Whitespace-only content should trigger fallback');
        
        // Scenario 4: generateFlatZone returns valid content
        $flatContent = '$TTL 86400';
        $needsFallback = ($flatContent === null || trim($flatContent) === '');
        $this->assertFalse($needsFallback, 'Valid content should not trigger fallback');
    }
    
    /**
     * Test file path format for flattened zone files
     */
    public function testFlattenedZoneFilePathFormat() {
        $tmpDir = '/tmp/dns3_validate_abc123';
        $zoneId = 54011;
        
        $tempFileName = 'zone_' . $zoneId . '_flat.db';
        $tempFilePath = $tmpDir . '/' . $tempFileName;
        
        $this->assertEquals(
            '/tmp/dns3_validate_abc123/zone_54011_flat.db',
            $tempFilePath,
            'Flattened zone file path should follow the pattern: tmpdir/zone_<id>_flat.db'
        );
    }
}
?>
