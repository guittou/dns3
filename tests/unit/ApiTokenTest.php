<?php
/**
 * Unit tests for API Token authentication
 * Tests the ApiToken model and Bearer token authentication flow
 */

use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../includes/models/ApiToken.php';
require_once __DIR__ . '/../../includes/db.php';

class ApiTokenTest extends TestCase {
    private static $db;
    private static $apiToken;
    private static $testUserId;
    
    public static function setUpBeforeClass(): void {
        // Create a test user for token tests
        self::$db = Database::getInstance()->getConnection();
        
        // Check if api_tokens table exists
        $stmt = self::$db->query("SHOW TABLES LIKE 'api_tokens'");
        if (!$stmt->fetch()) {
            self::markTestSkipped('api_tokens table does not exist. Run migration first.');
        }
        
        // Create test user if not exists
        $stmt = self::$db->prepare("SELECT id FROM users WHERE username = 'test_token_user'");
        $stmt->execute();
        $user = $stmt->fetch();
        
        if ($user) {
            self::$testUserId = $user['id'];
        } else {
            $stmt = self::$db->prepare("
                INSERT INTO users (username, email, password, auth_method, is_active, created_at)
                VALUES ('test_token_user', 'test_token@example.com', '', 'database', 1, NOW())
            ");
            $stmt->execute();
            self::$testUserId = self::$db->lastInsertId();
        }
        
        self::$apiToken = new ApiToken();
    }
    
    public static function tearDownAfterClass(): void {
        // Clean up test tokens
        if (self::$testUserId) {
            $stmt = self::$db->prepare("DELETE FROM api_tokens WHERE user_id = ?");
            $stmt->execute([self::$testUserId]);
        }
    }
    
    /**
     * Test token generation
     */
    public function testGenerateToken() {
        $result = self::$apiToken->generate(
            self::$testUserId,
            'Test Token',
            self::$testUserId,
            null
        );
        
        $this->assertIsArray($result);
        $this->assertArrayHasKey('token', $result);
        $this->assertArrayHasKey('id', $result);
        $this->assertArrayHasKey('prefix', $result);
        
        // Token should be 64 hex characters
        $this->assertEquals(64, strlen($result['token']));
        $this->assertMatchesRegularExpression('/^[a-f0-9]{64}$/', $result['token']);
        
        // Prefix should be first 8 characters
        $this->assertEquals(8, strlen($result['prefix']));
        $this->assertEquals(substr($result['token'], 0, 8), $result['prefix']);
        
        return $result;
    }
    
    /**
     * Test token validation with valid token
     * @depends testGenerateToken
     */
    public function testValidateValidToken($tokenData) {
        $userInfo = self::$apiToken->validate($tokenData['token']);
        
        $this->assertIsArray($userInfo);
        $this->assertEquals(self::$testUserId, $userInfo['id']);
        $this->assertEquals('test_token_user', $userInfo['username']);
        $this->assertArrayHasKey('token_id', $userInfo);
        $this->assertArrayHasKey('token_name', $userInfo);
    }
    
    /**
     * Test token validation with invalid token
     */
    public function testValidateInvalidToken() {
        $invalidToken = str_repeat('a', 64);
        $userInfo = self::$apiToken->validate($invalidToken);
        
        $this->assertFalse($userInfo);
    }
    
    /**
     * Test token validation with malformed token
     */
    public function testValidateMalformedToken() {
        $malformedToken = 'not-a-valid-token';
        $userInfo = self::$apiToken->validate($malformedToken);
        
        $this->assertFalse($userInfo);
    }
    
    /**
     * Test listing tokens for user
     * @depends testGenerateToken
     */
    public function testListTokensByUser() {
        $tokens = self::$apiToken->listByUser(self::$testUserId, false);
        
        $this->assertIsArray($tokens);
        $this->assertGreaterThan(0, count($tokens));
        
        // Check token structure
        $token = $tokens[0];
        $this->assertArrayHasKey('id', $token);
        $this->assertArrayHasKey('token_name', $token);
        $this->assertArrayHasKey('token_prefix', $token);
        $this->assertArrayHasKey('created_at', $token);
        
        // Ensure token_hash is NOT returned
        $this->assertArrayNotHasKey('token_hash', $token);
    }
    
    /**
     * Test token revocation
     * @depends testGenerateToken
     */
    public function testRevokeToken($tokenData) {
        $result = self::$apiToken->revoke($tokenData['id']);
        $this->assertTrue($result);
        
        // Try to validate revoked token
        $userInfo = self::$apiToken->validate($tokenData['token']);
        $this->assertFalse($userInfo);
        
        // Check that revoked token appears when including revoked
        $tokens = self::$apiToken->listByUser(self::$testUserId, true);
        $revokedToken = null;
        foreach ($tokens as $token) {
            if ($token['id'] == $tokenData['id']) {
                $revokedToken = $token;
                break;
            }
        }
        
        $this->assertNotNull($revokedToken);
        $this->assertNotNull($revokedToken['revoked_at']);
    }
    
    /**
     * Test token expiration
     */
    public function testExpiredToken() {
        // Generate token that expires in -1 days (already expired)
        // We'll manually set the expiration in the past
        $result = self::$apiToken->generate(
            self::$testUserId,
            'Expired Token',
            self::$testUserId,
            1
        );
        
        // Manually set expiration to past
        $stmt = self::$db->prepare("UPDATE api_tokens SET expires_at = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE id = ?");
        $stmt->execute([$result['id']]);
        
        // Try to validate expired token
        $userInfo = self::$apiToken->validate($result['token']);
        $this->assertFalse($userInfo);
        
        // Clean up
        self::$apiToken->delete($result['id']);
    }
    
    /**
     * Test token deletion
     */
    public function testDeleteToken() {
        // Create a token to delete
        $result = self::$apiToken->generate(
            self::$testUserId,
            'Token to Delete',
            self::$testUserId,
            null
        );
        
        $deleteResult = self::$apiToken->delete($result['id']);
        $this->assertTrue($deleteResult);
        
        // Verify token no longer exists
        $stmt = self::$db->prepare("SELECT id FROM api_tokens WHERE id = ?");
        $stmt->execute([$result['id']]);
        $token = $stmt->fetch();
        
        $this->assertFalse($token);
    }
    
    /**
     * Test that token hash is secure (SHA-256)
     */
    public function testTokenHashIsSHA256() {
        $result = self::$apiToken->generate(
            self::$testUserId,
            'Hash Test Token',
            self::$testUserId,
            null
        );
        
        // Retrieve the hash from database
        $stmt = self::$db->prepare("SELECT token_hash FROM api_tokens WHERE id = ?");
        $stmt->execute([$result['id']]);
        $tokenData = $stmt->fetch();
        
        // SHA-256 hash should be 64 hex characters
        $this->assertEquals(64, strlen($tokenData['token_hash']));
        $this->assertMatchesRegularExpression('/^[a-f0-9]{64}$/', $tokenData['token_hash']);
        
        // Verify hash matches
        $expectedHash = hash('sha256', $result['token']);
        $this->assertEquals($expectedHash, $tokenData['token_hash']);
        
        // Clean up
        self::$apiToken->delete($result['id']);
    }
}
?>
