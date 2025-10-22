<?php
/**
 * Unit tests for DnsValidator
 * Tests strict ASCII DNS validation with no IDN support
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/lib/DnsValidator.php';

class DnsValidatorTest extends TestCase {
    
    // ========== validateLabel Tests ==========
    
    public function testValidateLabelValidCases() {
        // Valid labels
        $validLabels = [
            'example',
            'test123',
            'my-domain',
            'a',
            'A1',
            '123test',
            'very-long-label-name-that-is-still-under-63-characters-limit',
        ];
        
        foreach ($validLabels as $label) {
            $result = DnsValidator::validateLabel($label);
            $this->assertTrue($result['valid'], "Label '$label' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateLabelEmptyLabel() {
        $result = DnsValidator::validateLabel('');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateLabelTooLong() {
        // 64 characters - exceeds max of 63
        $longLabel = str_repeat('a', 64);
        $result = DnsValidator::validateLabel($longLabel);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('63', $result['error']);
    }
    
    public function testValidateLabelMaxLength() {
        // Exactly 63 characters - should be valid
        $maxLabel = str_repeat('a', 63);
        $result = DnsValidator::validateLabel($maxLabel);
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateLabelNonAsciiCharacters() {
        $nonAsciiLabels = [
            'tëst',
            'café',
            'münchen',
            '日本',
            'тест',
        ];
        
        foreach ($nonAsciiLabels as $label) {
            $result = DnsValidator::validateLabel($label);
            $this->assertFalse($result['valid'], "Label '$label' should be invalid (non-ASCII)");
            $this->assertStringContainsString('ASCII', $result['error']);
        }
    }
    
    public function testValidateLabelWithSpaces() {
        $result = DnsValidator::validateLabel('my label');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('space', strtolower($result['error']));
    }
    
    public function testValidateLabelInvalidCharacters() {
        $invalidLabels = [
            'test_domain',  // underscore
            'test.domain',  // dot
            'test@domain',  // at sign
            'test!domain',  // exclamation
            'test#domain',  // hash
        ];
        
        foreach ($invalidLabels as $label) {
            $result = DnsValidator::validateLabel($label);
            $this->assertFalse($result['valid'], "Label '$label' should be invalid");
            $this->assertStringContainsString('invalid', strtolower($result['error']));
        }
    }
    
    public function testValidateLabelStartsWithHyphen() {
        $result = DnsValidator::validateLabel('-example');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('hyphen', strtolower($result['error']));
        $this->assertStringContainsString('start', strtolower($result['error']));
    }
    
    public function testValidateLabelEndsWithHyphen() {
        $result = DnsValidator::validateLabel('example-');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('hyphen', strtolower($result['error']));
        $this->assertStringContainsString('end', strtolower($result['error']));
    }
    
    // ========== validateName Tests ==========
    
    public function testValidateNameValidCases() {
        $validNames = [
            'example.com',
            'sub.example.com',
            'my-domain.co.uk',
            'test123.example.org',
            'a.b.c.d.example.com',
            'example.com.',  // FQDN with trailing dot
        ];
        
        foreach ($validNames as $name) {
            $result = DnsValidator::validateName($name, true);
            $this->assertTrue($result['valid'], "Name '$name' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateNameEmpty() {
        $result = DnsValidator::validateName('');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateNameJustDot() {
        $result = DnsValidator::validateName('.');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('dot', strtolower($result['error']));
    }
    
    public function testValidateNameTooLong() {
        // Create a name that exceeds 253 characters
        // 63 + 1 + 63 + 1 + 63 + 1 + 63 + 1 + 4 = 260 characters
        $longName = str_repeat('a', 63) . '.' . str_repeat('b', 63) . '.' . str_repeat('c', 63) . '.' . str_repeat('d', 63) . '.com';
        $result = DnsValidator::validateName($longName, true);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('253', $result['error']);
    }
    
    public function testValidateNameInvalidLabel() {
        $invalidNames = [
            '-example.com',        // label starts with hyphen
            'example-.com',        // label ends with hyphen
            'ex ample.com',        // space in label
            'example..com',        // empty label
        ];
        
        foreach ($invalidNames as $name) {
            $result = DnsValidator::validateName($name, true);
            $this->assertFalse($result['valid'], "Name '$name' should be invalid");
        }
    }
    
    public function testValidateNameTrailingDotNotAllowed() {
        $result = DnsValidator::validateName('example.com.', false);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('dot', strtolower($result['error']));
    }
    
    // ========== validateOwner Tests ==========
    
    public function testValidateOwnerValidCases() {
        $validOwners = [
            '@',                    // zone origin
            'www',                  // relative name
            'mail.example.com',     // FQDN
            'sub.domain',
            'test123',
        ];
        
        foreach ($validOwners as $owner) {
            $result = DnsValidator::validateOwner($owner);
            $this->assertTrue($result['valid'], "Owner '$owner' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateOwnerEmpty() {
        $result = DnsValidator::validateOwner('');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateOwnerNonAscii() {
        $result = DnsValidator::validateOwner('café.example.com');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('ASCII', $result['error']);
    }
    
    public function testValidateOwnerWithSpaces() {
        $result = DnsValidator::validateOwner('my domain');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('space', strtolower($result['error']));
    }
    
    // ========== validateA Tests ==========
    
    public function testValidateAValidIPv4() {
        $validIPs = [
            '192.168.1.1',
            '10.0.0.1',
            '172.16.0.1',
            '8.8.8.8',
            '0.0.0.0',
            '255.255.255.255',
        ];
        
        foreach ($validIPs as $ip) {
            $result = DnsValidator::validateA($ip);
            $this->assertTrue($result['valid'], "IPv4 '$ip' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateAInvalidIPv4() {
        $invalidIPs = [
            '',
            '256.1.1.1',            // octet too large
            '192.168.1',            // incomplete
            '192.168.1.1.1',        // too many octets
            'not-an-ip',
            '2001:db8::1',          // IPv6 address
        ];
        
        foreach ($invalidIPs as $ip) {
            $result = DnsValidator::validateA($ip);
            $this->assertFalse($result['valid'], "IPv4 '$ip' should be invalid");
        }
    }
    
    // ========== validateAAAA Tests ==========
    
    public function testValidateAAAAValidIPv6() {
        $validIPs = [
            '2001:db8::1',
            '::1',
            '2001:0db8:0000:0000:0000:0000:0000:0001',
            'fe80::',
            '::',
        ];
        
        foreach ($validIPs as $ip) {
            $result = DnsValidator::validateAAAA($ip);
            $this->assertTrue($result['valid'], "IPv6 '$ip' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateAAAAInvalidIPv6() {
        $invalidIPs = [
            '',
            '192.168.1.1',          // IPv4 address
            'not-an-ip',
            '2001:db8::g',          // invalid character
        ];
        
        foreach ($invalidIPs as $ip) {
            $result = DnsValidator::validateAAAA($ip);
            $this->assertFalse($result['valid'], "IPv6 '$ip' should be invalid");
        }
    }
    
    // ========== validateMX Tests ==========
    
    public function testValidateMXValid() {
        $result = DnsValidator::validateMX('mail.example.com', 10);
        $this->assertTrue($result['valid']);
        $this->assertNull($result['error']);
    }
    
    public function testValidateMXValidNoPriority() {
        $result = DnsValidator::validateMX('mail.example.com', null);
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateMXEmpty() {
        $result = DnsValidator::validateMX('', 10);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateMXInvalidPriority() {
        $invalidPriorities = [-1, 65536, 'not-a-number'];
        
        foreach ($invalidPriorities as $priority) {
            $result = DnsValidator::validateMX('mail.example.com', $priority);
            $this->assertFalse($result['valid'], "Priority '$priority' should be invalid");
            $this->assertStringContainsString('priority', strtolower($result['error']));
        }
    }
    
    public function testValidateMXCannotBeIP() {
        $result = DnsValidator::validateMX('192.168.1.1', 10);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('IP', $result['error']);
    }
    
    // ========== validateCNAME Tests ==========
    
    public function testValidateCNAMEValid() {
        $result = DnsValidator::validateCNAME('target.example.com');
        $this->assertTrue($result['valid']);
        $this->assertNull($result['error']);
    }
    
    public function testValidateCNAMEEmpty() {
        $result = DnsValidator::validateCNAME('');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateCNAMECannotBeIP() {
        $invalidTargets = [
            '192.168.1.1',
            '2001:db8::1',
        ];
        
        foreach ($invalidTargets as $target) {
            $result = DnsValidator::validateCNAME($target);
            $this->assertFalse($result['valid'], "CNAME target '$target' should be invalid");
            $this->assertStringContainsString('IP', $result['error']);
        }
    }
    
    // ========== validateTXT Tests ==========
    
    public function testValidateTXTValid() {
        $validTXT = [
            'v=spf1 include:_spf.example.com ~all',
            'Simple text record',
            'key=value',
            '123456',
        ];
        
        foreach ($validTXT as $txt) {
            $result = DnsValidator::validateTXT($txt);
            $this->assertTrue($result['valid'], "TXT '$txt' should be valid");
            $this->assertNull($result['error']);
        }
    }
    
    public function testValidateTXTEmpty() {
        $result = DnsValidator::validateTXT('');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('empty', strtolower($result['error']));
    }
    
    public function testValidateTXTNonAscii() {
        $result = DnsValidator::validateTXT('café record');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('ASCII', $result['error']);
    }
    
    public function testValidateTXTTooLong() {
        // Create a very long TXT record (> 65535 characters)
        $longTXT = str_repeat('a', 65536);
        $result = DnsValidator::validateTXT($longTXT);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('length', strtolower($result['error']));
    }
    
    // ========== validateRecord Tests (Dispatcher) ==========
    
    public function testValidateRecordAType() {
        $result = DnsValidator::validateRecord('A', 'www.example.com', '192.168.1.1');
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateRecordAAAAType() {
        $result = DnsValidator::validateRecord('AAAA', 'www.example.com', '2001:db8::1');
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateRecordMXType() {
        $result = DnsValidator::validateRecord('MX', '@', 'mail.example.com', ['priority' => 10]);
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateRecordCNAMEType() {
        $result = DnsValidator::validateRecord('CNAME', 'www', 'target.example.com');
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateRecordTXTType() {
        $result = DnsValidator::validateRecord('TXT', '@', 'v=spf1 ~all');
        $this->assertTrue($result['valid']);
    }
    
    public function testValidateRecordInvalidOwner() {
        $result = DnsValidator::validateRecord('A', '-invalid', '192.168.1.1');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('hyphen', strtolower($result['error']));
    }
    
    public function testValidateRecordInvalidValue() {
        $result = DnsValidator::validateRecord('A', 'www', 'not-an-ip');
        $this->assertFalse($result['valid']);
    }
    
    public function testValidateRecordUnsupportedType() {
        $result = DnsValidator::validateRecord('NS', 'www', 'ns.example.com');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('Unsupported', $result['error']);
    }
    
    public function testValidateRecordCaseInsensitive() {
        // Record types should be case-insensitive
        $result = DnsValidator::validateRecord('a', 'www', '192.168.1.1');
        $this->assertTrue($result['valid']);
        
        $result = DnsValidator::validateRecord('aaaa', 'www', '2001:db8::1');
        $this->assertTrue($result['valid']);
    }
}
?>
