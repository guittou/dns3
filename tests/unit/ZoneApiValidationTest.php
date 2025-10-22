<?php
/**
 * Unit tests for zone_api.php validation
 * Tests the server-side validation using DnsValidator
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/lib/DnsValidator.php';

class ZoneApiValidationTest extends TestCase {
    
    /**
     * Test that DnsValidator is available and working
     * This ensures the validation logic we're using in the API is correct
     */
    public function testValidateNameForValidZoneName() {
        $result = DnsValidator::validateName('example.com');
        $this->assertTrue($result['valid']);
        $this->assertNull($result['error']);
    }
    
    public function testValidateNameForInvalidZoneNameWithNonAscii() {
        $result = DnsValidator::validateName('café.com');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('ASCII', $result['error']);
    }
    
    public function testValidateNameForInvalidZoneNameWithHyphenAtStart() {
        $result = DnsValidator::validateName('-example.com');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('hyphen', strtolower($result['error']));
    }
    
    public function testValidateNameForInvalidZoneNameWithHyphenAtEnd() {
        $result = DnsValidator::validateName('example-.com');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('hyphen', strtolower($result['error']));
    }
    
    public function testValidateNameForInvalidZoneNameTooLong() {
        // Create a name that exceeds 253 characters
        $longName = str_repeat('a', 63) . '.' . str_repeat('b', 63) . '.' . str_repeat('c', 63) . '.' . str_repeat('d', 63) . '.com';
        $result = DnsValidator::validateName($longName);
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('253', $result['error']);
    }
    
    public function testValidateNameForInvalidZoneNameWithSpaces() {
        $result = DnsValidator::validateName('my domain.com');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('space', strtolower($result['error']));
    }
    
    public function testValidateNameForInvalidZoneNameWithInvalidCharacters() {
        $result = DnsValidator::validateName('test_domain.com');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('invalid', strtolower($result['error']));
    }
    
    public function testValidateNameForEmptyZoneName() {
        $result = DnsValidator::validateName('');
        $this->assertFalse($result['valid']);
        $this->assertNotNull($result['error']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    /**
     * Test valid zone names with trailing dots (FQDN format)
     */
    public function testValidateNameForValidFQDN() {
        $result = DnsValidator::validateName('example.com.');
        $this->assertTrue($result['valid']);
        $this->assertNull($result['error']);
    }
    
    /**
     * Test subdomain names
     */
    public function testValidateNameForValidSubdomain() {
        $result = DnsValidator::validateName('subdomain.example.com');
        $this->assertTrue($result['valid']);
        $this->assertNull($result['error']);
    }
}
?>
