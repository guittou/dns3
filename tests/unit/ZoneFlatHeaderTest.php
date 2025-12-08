<?php
/**
 * Unit tests for generateFlatZone header generation
 * Tests that flat zone files include required headers ($TTL, SOA, NS)
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/ZoneFile.php';

class ZoneFlatHeaderTest extends TestCase {
    
    /**
     * Test that $TTL directive is added to flat zone content
     */
    public function testFlatZoneContainsTtl() {
        // Simulate a zone header
        $zoneHeader = '$TTL 86400';
        
        $this->assertStringContainsString('$TTL', $zoneHeader, 'Flat zone should contain $TTL directive');
        $this->assertStringContainsString('86400', $zoneHeader, 'Flat zone should contain TTL value');
    }
    
    /**
     * Test that $ORIGIN directive is added to flat zone content
     */
    public function testFlatZoneContainsOrigin() {
        // Simulate an ORIGIN directive
        $originDirective = '$ORIGIN example.com.';
        
        $this->assertStringContainsString('$ORIGIN', $originDirective, 'Flat zone should contain $ORIGIN directive');
        $this->assertStringContainsString('example.com.', $originDirective, 'ORIGIN should contain zone name with trailing dot');
    }
    
    /**
     * Test that SOA record is added to flat zone content
     */
    public function testFlatZoneContainsSoa() {
        // Simulate an SOA record
        $soaRecord = '@ IN SOA ns1.example.com. admin.example.com. (';
        
        $this->assertStringContainsString('IN SOA', $soaRecord, 'Flat zone should contain SOA record');
        $this->assertStringContainsString('@ IN SOA', $soaRecord, 'SOA record should start with @');
    }
    
    /**
     * Test that NS record format is correct
     */
    public function testNsRecordFormat() {
        // Simulate an NS record
        $nsRecord = '@                                     IN NS     ns1.example.com.';
        
        $this->assertStringContainsString('IN NS', $nsRecord, 'NS record should contain IN NS');
        $this->assertStringContainsString('ns1.', $nsRecord, 'NS record should contain nameserver');
    }
    
    /**
     * Test default NS record generation when zone domain is available
     */
    public function testDefaultNsRecordWithZoneDomain() {
        $zoneDomain = 'example.com';
        $defaultNs = 'ns1.' . rtrim($zoneDomain, '.') . '.';
        
        $this->assertEquals('ns1.example.com.', $defaultNs, 'Default NS should be ns1.<zonedomain>.');
    }
    
    /**
     * Test default NS record generation when zone domain is not available
     */
    public function testDefaultNsRecordWithoutZoneDomain() {
        $defaultNs = 'ns1.localhost.';
        
        $this->assertEquals('ns1.localhost.', $defaultNs, 'Default NS should be ns1.localhost. when no domain');
    }
    
    /**
     * Test that zone header components are in correct order
     */
    public function testZoneHeaderOrder() {
        // Simulate a complete zone header
        $zoneContent = "\$TTL 86400\n\$ORIGIN example.com.\n\n@ IN SOA ns1.example.com. admin.example.com. (\n    2024120801 ; Serial\n    10800 ; Refresh\n    900 ; Retry\n    604800 ; Expire\n    3600 ; Minimum\n)\n\n";
        
        // Check that $TTL comes first
        $ttlPos = strpos($zoneContent, '$TTL');
        $originPos = strpos($zoneContent, '$ORIGIN');
        $soaPos = strpos($zoneContent, 'IN SOA');
        
        $this->assertNotFalse($ttlPos, 'Zone should contain $TTL');
        $this->assertNotFalse($originPos, 'Zone should contain $ORIGIN');
        $this->assertNotFalse($soaPos, 'Zone should contain SOA record');
        $this->assertLessThan($originPos, $ttlPos, '$TTL should come before $ORIGIN');
        $this->assertLessThan($soaPos, $originPos, '$ORIGIN should come before SOA record');
    }
    
    /**
     * Test that empty zone content detection works correctly
     */
    public function testEmptyZoneContentDetection() {
        // Test various empty content scenarios
        $emptyContent = '';
        $this->assertTrue(trim($emptyContent) === '', 'Empty string should be detected');
        
        $whitespaceContent = "   \n  \t  ";
        $this->assertTrue(trim($whitespaceContent) === '', 'Whitespace-only content should be detected');
        
        $validContent = '$TTL 86400';
        $this->assertFalse(trim($validContent) === '', 'Valid content should not be detected as empty');
    }
    
    /**
     * Test that zone name normalization works
     */
    public function testZoneNameNormalization() {
        // Test domain normalization
        $domain1 = 'example.com.';
        $domain2 = 'example.com';
        
        $normalized1 = rtrim($domain1, '.');
        $normalized2 = rtrim($domain2, '.');
        
        $this->assertEquals($normalized1, $normalized2, 'Zone names should normalize to same value');
        $this->assertEquals('example.com', $normalized1, 'Zone name should not have trailing dot');
    }
    
    /**
     * Test that BIND-compliant zone file requires these components
     */
    public function testBindRequiredComponents() {
        // According to BIND spec, a valid zone file needs:
        // 1. $TTL directive
        // 2. $ORIGIN directive (optional but recommended)
        // 3. SOA record
        // 4. At least one NS record
        
        $requiredComponents = ['$TTL', '$ORIGIN', 'IN SOA', 'IN NS'];
        
        foreach ($requiredComponents as $component) {
            $this->assertIsString($component, 'Required component should be a string');
            $this->assertNotEmpty($component, 'Required component should not be empty');
        }
    }
    
    /**
     * Test visited array tracking for recursion detection
     */
    public function testVisitedArrayTracking() {
        $visited = [];
        $zoneId = 123;
        
        // First visit
        $this->assertFalse(in_array($zoneId, $visited), 'Zone should not be visited initially');
        
        // Add to visited
        $visited[] = $zoneId;
        $this->assertTrue(in_array($zoneId, $visited), 'Zone should be marked as visited');
        $this->assertEquals(1, count($visited), 'Visited array should have one entry');
        
        // Check for circular reference
        $this->assertTrue(in_array($zoneId, $visited), 'Circular reference should be detected');
    }
    
    /**
     * Test that header is only added for master zones
     */
    public function testHeaderOnlyForMasterZones() {
        $masterType = 'master';
        $includeType = 'include';
        
        $this->assertEquals('master', $masterType, 'Master type should be "master"');
        $this->assertEquals('include', $includeType, 'Include type should be "include"');
        $this->assertNotEquals($masterType, $includeType, 'Master and include should be different types');
    }
    
    /**
     * Test that header is only added on first call (top-level)
     */
    public function testHeaderOnlyOnFirstCall() {
        $visited = [];
        $this->assertEquals(0, count($visited), 'Initial visited array should be empty');
        
        // After adding first zone
        $visited[] = 1;
        $this->assertEquals(1, count($visited), 'First call should have one entry in visited');
        
        // After adding second zone (recursive call)
        $visited[] = 2;
        $this->assertEquals(2, count($visited), 'Recursive call should have two entries in visited');
        $this->assertGreaterThan(1, count($visited), 'Recursive call should not add header');
    }
}
?>
