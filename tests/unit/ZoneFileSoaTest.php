<?php
/**
 * Unit tests for ZoneFile SOA generation
 * Tests mname handling and SOA record generation
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/ZoneFile.php';

class ZoneFileSoaTest extends TestCase {
    
    private $zoneFile;
    
    protected function setUp(): void {
        // Mock the ZoneFile class for testing without database
        $this->zoneFile = $this->getMockBuilder(ZoneFile::class)
            ->disableOriginalConstructor()
            ->onlyMethods(['getById', 'getIncludes', 'getDnsRecordsByZone'])
            ->getMock();
    }
    
    // ========== normalizeFqdn Tests ==========
    
    public function testNormalizeFqdnWithoutTrailingDot() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('normalizeFqdn');
        $method->setAccessible(true);
        
        // Create a real ZoneFile instance without constructor
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, 'ns1.example.com');
        $this->assertEquals('ns1.example.com.', $result);
    }
    
    public function testNormalizeFqdnWithTrailingDot() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('normalizeFqdn');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, 'ns1.example.com.');
        $this->assertEquals('ns1.example.com.', $result);
    }
    
    public function testNormalizeFqdnEmpty() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('normalizeFqdn');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, '');
        $this->assertEquals('', $result);
    }
    
    public function testNormalizeFqdnWithWhitespace() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('normalizeFqdn');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, '  ns1.example.com  ');
        $this->assertEquals('ns1.example.com.', $result);
    }
    
    // ========== formatSoaRname Tests ==========
    
    public function testFormatSoaRnameWithAtSymbol() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, 'hostmaster@example.com', '');
        $this->assertEquals('hostmaster.example.com.', $result);
    }
    
    public function testFormatSoaRnameWithoutAtSymbol() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, 'hostmaster.example.com', '');
        $this->assertEquals('hostmaster.example.com.', $result);
    }
    
    public function testFormatSoaRnameEmptyWithoutZoneDomain() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        // Without zone domain, returns default hostmaster.
        $result = $method->invoke($instance, '', '');
        $this->assertEquals('hostmaster.', $result);
    }
    
    public function testFormatSoaRnameEmptyWithZoneDomain() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        // With zone domain, returns hostmaster.<zone_domain>.
        $result = $method->invoke($instance, '', 'example.com');
        $this->assertEquals('hostmaster.example.com.', $result);
    }
    
    public function testFormatSoaRnameWithTrailingDot() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $result = $method->invoke($instance, 'admin.example.com.', '');
        $this->assertEquals('admin.example.com.', $result);
    }
    
    public function testFormatSoaRnameShortFormWithZoneDomain() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        // Short form (no dot) should be completed with zone domain
        $result = $method->invoke($instance, 'hostmaster', 'example.com');
        $this->assertEquals('hostmaster.example.com.', $result);
    }
    
    public function testFormatSoaRnameShortFormWithZoneDomainTrailingDot() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        // Zone domain with trailing dot should be handled correctly
        $result = $method->invoke($instance, 'admin', 'example.com.');
        $this->assertEquals('admin.example.com.', $result);
    }
    
    public function testFormatSoaRnameShortFormWithoutZoneDomain() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('formatSoaRname');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        // Short form without zone domain - just adds trailing dot
        $result = $method->invoke($instance, 'hostmaster', '');
        $this->assertEquals('hostmaster.', $result);
    }
    
    // ========== generateSoaRecord Tests ==========
    
    public function testGenerateSoaRecordWithMname() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('generateSoaRecord');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $zone = [
            'name' => 'example.com',
            'domain' => 'example.com',
            'soa_rname' => 'admin@example.com',
            'soa_refresh' => 7200,
            'soa_retry' => 600,
            'soa_expire' => 1209600,
            'soa_minimum' => 3600
        ];
        
        $result = $method->invoke($instance, $zone, 'ns1.example.com', '2025120501');
        
        // Verify the SOA record contains expected values
        $this->assertStringContainsString('@ IN SOA', $result);
        $this->assertStringContainsString('ns1.example.com.', $result);
        $this->assertStringContainsString('admin.example.com.', $result);
        $this->assertStringContainsString('2025120501', $result);
        $this->assertStringContainsString('7200', $result);
        $this->assertStringContainsString('600', $result);
        $this->assertStringContainsString('1209600', $result);
        $this->assertStringContainsString('3600', $result);
    }
    
    public function testGenerateSoaRecordWithDefaultMname() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('generateSoaRecord');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $zone = [
            'name' => 'example.com',
            'domain' => 'example.com',
            'soa_rname' => null,
            'soa_refresh' => null,
            'soa_retry' => null,
            'soa_expire' => null,
            'soa_minimum' => null
        ];
        
        // Pass empty mname to trigger default
        $result = $method->invoke($instance, $zone, '', '2025120501');
        
        // Verify default MNAME is used (ns1.<domain>.)
        $this->assertStringContainsString('ns1.example.com.', $result);
        // Verify default RNAME is used (hostmaster.)
        $this->assertStringContainsString('hostmaster.', $result);
        // Verify default timers are used
        $this->assertStringContainsString('10800', $result); // default refresh
        $this->assertStringContainsString('900', $result);   // default retry
        $this->assertStringContainsString('604800', $result); // default expire
        $this->assertStringContainsString('3600', $result);   // default minimum
    }
    
    public function testGenerateSoaRecordWithNullSerial() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('generateSoaRecord');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $zone = [
            'name' => 'example.com',
            'domain' => 'example.com'
        ];
        
        // Pass null serial to trigger auto-generation
        $result = $method->invoke($instance, $zone, 'ns1.example.com', null);
        
        // Verify serial is auto-generated (YYYYMMDDnn format)
        $expectedSerialPrefix = date('Ymd');
        $this->assertStringContainsString($expectedSerialPrefix, $result);
    }
    
    public function testGenerateSoaRecordMnameNormalization() {
        $zoneFile = new ReflectionClass(ZoneFile::class);
        $method = $zoneFile->getMethod('generateSoaRecord');
        $method->setAccessible(true);
        
        $instance = $zoneFile->newInstanceWithoutConstructor();
        
        $zone = [
            'name' => 'example.com',
            'domain' => 'example.com'
        ];
        
        // Pass mname without trailing dot
        $result = $method->invoke($instance, $zone, 'ns1.example.com', '2025120501');
        
        // Verify trailing dot is added
        $this->assertStringContainsString('ns1.example.com.', $result);
    }
}
?>
