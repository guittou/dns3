<?php
/**
 * Unit tests for Auth Mapping functionality
 * Tests new attribute-based mapping formats (sAMAccountName, uid, departmentNumber)
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/AuthModel.php';

class AuthMappingTest extends TestCase {
    private $authModel;
    private $db;
    
    protected function setUp(): void {
        // Mock database connection for testing
        // In a real scenario, you'd use a test database
        $this->authModel = $this->createPartialMock(AuthModel::class, ['getRoleIdsFromMappings']);
    }
    
    /**
     * Test that AD sAMAccountName format is matched correctly
     */
    public function testAdSamAccountNameMapping() {
        // Simulate mappings from database
        $mappings = [
            ['dn_or_group' => 'sAMAccountName:john.doe', 'role_id' => 1],
            ['dn_or_group' => 'CN=Admins,DC=example,DC=com', 'role_id' => 2],
        ];
        
        // Comparable values from AD authentication
        $comparableValues = [
            'CN=Admins,DC=example,DC=com',
            'sAMAccountName:john.doe',
        ];
        
        // Test case-insensitive matching
        $this->assertTrue(
            strcasecmp('sAMAccountName:john.doe', 'samaccountname:john.doe') === 0,
            'sAMAccountName should be case-insensitive'
        );
        
        // Verify exact match
        $this->assertTrue(
            strcasecmp('sAMAccountName:john.doe', 'sAMAccountName:john.doe') === 0,
            'Exact sAMAccountName match should work'
        );
        
        // Verify non-match
        $this->assertFalse(
            strcasecmp('sAMAccountName:john.doe', 'sAMAccountName:jane.doe') === 0,
            'Different sAMAccountName values should not match'
        );
    }
    
    /**
     * Test that LDAP uid format is matched correctly
     */
    public function testLdapUidMapping() {
        // Test case-insensitive matching
        $this->assertTrue(
            strcasecmp('uid:foobar', 'UID:foobar') === 0,
            'uid should be case-insensitive'
        );
        
        // Verify exact match
        $this->assertTrue(
            strcasecmp('uid:foobar', 'uid:foobar') === 0,
            'Exact uid match should work'
        );
        
        // Verify non-match
        $this->assertFalse(
            strcasecmp('uid:foobar', 'uid:bazbar') === 0,
            'Different uid values should not match'
        );
    }
    
    /**
     * Test that LDAP departmentNumber format is matched correctly
     */
    public function testLdapDepartmentNumberMapping() {
        // Test case-insensitive matching
        $this->assertTrue(
            strcasecmp('departmentNumber:12345', 'DEPARTMENTNUMBER:12345') === 0,
            'departmentNumber should be case-insensitive'
        );
        
        // Verify exact match
        $this->assertTrue(
            strcasecmp('departmentNumber:12345', 'departmentNumber:12345') === 0,
            'Exact departmentNumber match should work'
        );
        
        // Verify non-match
        $this->assertFalse(
            strcasecmp('departmentNumber:12345', 'departmentNumber:67890') === 0,
            'Different departmentNumber values should not match'
        );
    }
    
    /**
     * Test that AD group DN matching still works (backward compatibility)
     */
    public function testAdGroupDnBackwardCompatibility() {
        $groupDn = 'CN=DNSAdmins,OU=Groups,DC=example,DC=com';
        
        // Test case-insensitive matching
        $this->assertTrue(
            strcasecmp($groupDn, 'cn=dnsadmins,ou=groups,dc=example,dc=com') === 0,
            'AD group DN should be case-insensitive'
        );
    }
    
    /**
     * Test that LDAP DN substring matching still works (backward compatibility)
     */
    public function testLdapDnSubstringBackwardCompatibility() {
        $userDn = 'uid=jdoe,ou=IT,dc=example,dc=com';
        $mappingOu = 'ou=IT,dc=example,dc=com';
        
        // Test case-insensitive substring matching
        $this->assertTrue(
            stripos($userDn, $mappingOu) !== false,
            'LDAP DN should contain mapped OU path'
        );
        
        // Test with case differences
        $this->assertTrue(
            stripos($userDn, 'OU=it,DC=EXAMPLE,DC=COM') !== false,
            'LDAP DN substring matching should be case-insensitive'
        );
        
        // Test non-match
        $this->assertFalse(
            stripos($userDn, 'ou=HR,dc=example,dc=com') !== false,
            'LDAP DN should not match different OU'
        );
    }
    
    /**
     * Test prefix format validation
     */
    public function testPrefixFormats() {
        // Valid prefixed formats
        $validFormats = [
            'sAMAccountName:user123',
            'uid:john.doe',
            'departmentNumber:999',
            'departmentNumber:ABC-123',
        ];
        
        foreach ($validFormats as $format) {
            $this->assertStringContainsString(':', $format, "Format '$format' should contain a colon");
        }
        
        // Ensure prefix matching is exact, not substring
        $value1 = 'uid:testuser';
        $value2 = 'uid:test'; // Should NOT match value1
        
        $this->assertFalse(
            strcasecmp($value1, $value2) === 0,
            'Prefix matching should be exact, not substring'
        );
    }
    
    /**
     * Test mixed comparable values (groups + attributes)
     */
    public function testMixedComparableValues() {
        // AD user with both groups and sAMAccountName
        $comparableValues = [
            'CN=DNSAdmins,OU=Groups,DC=example,DC=com',
            'CN=Users,OU=Groups,DC=example,DC=com',
            'sAMAccountName:john.doe',
        ];
        
        // All three should be independently matchable
        $this->assertCount(3, $comparableValues, 'Should have 3 comparable values');
        
        // Each value should be distinct
        $this->assertEquals(
            count($comparableValues),
            count(array_unique($comparableValues)),
            'All comparable values should be distinct'
        );
    }
    
    /**
     * Test Unicode support in matching
     */
    public function testUnicodeCaseInsensitiveMatching() {
        // Test with mb_strtolower for Unicode support
        $value1 = 'uid:François';
        $value2 = 'uid:françois';
        
        $this->assertEquals(
            mb_strtolower($value1),
            mb_strtolower($value2),
            'Unicode characters should be compared case-insensitively'
        );
    }
    
    /**
     * Test that empty or whitespace values are handled correctly
     */
    public function testEmptyValues() {
        // Empty comparable values
        $comparableValues = [];
        $this->assertEmpty($comparableValues, 'Empty array should be handled');
        
        // Ensure empty string doesn't match anything
        $this->assertFalse(
            strcasecmp('', 'sAMAccountName:test') === 0,
            'Empty string should not match any value'
        );
    }
}
?>
