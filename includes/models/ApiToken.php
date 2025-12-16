<?php
/**
 * ApiToken Model
 * Manages API tokens for Bearer authentication
 */

require_once __DIR__ . '/../db.php';

class ApiToken {
    private $db;
    
    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }
    
    /**
     * Generate a new API token for a user
     * Returns the plain token (only time it's visible) and token info
     * 
     * @param int $userId User ID
     * @param string $tokenName Human-readable name for the token
     * @param int $createdBy User ID who created the token
     * @param int|null $expiresInDays Days until expiration (null = no expiration)
     * @return array ['token' => string, 'id' => int, 'prefix' => string] or false on failure
     */
    public function generate($userId, $tokenName, $createdBy, $expiresInDays = null) {
        try {
            // Generate a cryptographically secure random token (32 bytes = 64 hex chars)
            $token = bin2hex(random_bytes(32));
            
            // Create hash for storage (using SHA-256)
            $tokenHash = hash('sha256', $token);
            
            // Create prefix for identification (first 8 characters)
            $tokenPrefix = substr($token, 0, 8);
            
            // Calculate expiration date if specified
            $expiresAt = null;
            if ($expiresInDays !== null && is_numeric($expiresInDays) && $expiresInDays > 0) {
                // Use DateTime for safe date arithmetic
                $expiryDate = new DateTime();
                $expiryDate->modify('+' . intval($expiresInDays) . ' days');
                $expiresAt = $expiryDate->format('Y-m-d H:i:s');
            }
            
            // Insert token into database
            $stmt = $this->db->prepare("
                INSERT INTO api_tokens (user_id, token_name, token_hash, token_prefix, expires_at, created_by, created_at)
                VALUES (?, ?, ?, ?, ?, ?, NOW())
            ");
            $stmt->execute([$userId, $tokenName, $tokenHash, $tokenPrefix, $expiresAt, $createdBy]);
            
            $tokenId = $this->db->lastInsertId();
            
            return [
                'token' => $token,
                'id' => $tokenId,
                'prefix' => $tokenPrefix
            ];
        } catch (Exception $e) {
            error_log("Error generating API token: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Validate a token and return user info if valid
     * Updates last_used_at timestamp on successful validation
     * 
     * @param string $token The plain token to validate
     * @return array|false User info array or false if invalid
     */
    public function validate($token) {
        try {
            // Hash the provided token
            $tokenHash = hash('sha256', $token);
            
            // Look up token in database
            $stmt = $this->db->prepare("
                SELECT t.id, t.user_id, t.token_name, t.expires_at, t.revoked_at,
                       u.username, u.is_active
                FROM api_tokens t
                INNER JOIN users u ON t.user_id = u.id
                WHERE t.token_hash = ?
            ");
            $stmt->execute([$tokenHash]);
            $tokenData = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$tokenData) {
                return false;
            }
            
            // Check if token is revoked
            if ($tokenData['revoked_at'] !== null) {
                error_log("API token authentication failed: token revoked");
                return false;
            }
            
            // Check if token is expired (using DateTime for consistency)
            if ($tokenData['expires_at'] !== null) {
                $expiryDate = new DateTime($tokenData['expires_at']);
                $now = new DateTime();
                if ($expiryDate < $now) {
                    error_log("API token authentication failed: token expired");
                    return false;
                }
            }
            
            // Check if user is active
            if (!$tokenData['is_active']) {
                error_log("API token authentication failed: user inactive");
                return false;
            }
            
            // Update last_used_at timestamp
            $updateStmt = $this->db->prepare("UPDATE api_tokens SET last_used_at = NOW() WHERE id = ?");
            $updateStmt->execute([$tokenData['id']]);
            
            // Return user info
            return [
                'id' => $tokenData['user_id'],
                'username' => $tokenData['username'],
                'token_id' => $tokenData['id'],
                'token_name' => $tokenData['token_name']
            ];
        } catch (Exception $e) {
            error_log("Error validating API token: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Revoke a token
     * 
     * @param int $tokenId Token ID to revoke
     * @return bool Success
     */
    public function revoke($tokenId) {
        try {
            $stmt = $this->db->prepare("UPDATE api_tokens SET revoked_at = NOW() WHERE id = ?");
            $stmt->execute([$tokenId]);
            return true;
        } catch (Exception $e) {
            error_log("Error revoking API token: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * List tokens for a user
     * 
     * @param int $userId User ID
     * @param bool $includeRevoked Include revoked tokens
     * @return array List of tokens (without sensitive data)
     */
    public function listByUser($userId, $includeRevoked = false) {
        try {
            $sql = "
                SELECT id, token_name, token_prefix, last_used_at, expires_at, created_at, revoked_at
                FROM api_tokens
                WHERE user_id = ?
            ";
            
            if (!$includeRevoked) {
                $sql .= " AND revoked_at IS NULL";
            }
            
            $sql .= " ORDER BY created_at DESC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$userId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Error listing API tokens: " . $e->getMessage());
            return [];
        }
    }
    
    /**
     * Delete a token permanently
     * 
     * @param int $tokenId Token ID to delete
     * @return bool Success
     */
    public function delete($tokenId) {
        try {
            $stmt = $this->db->prepare("DELETE FROM api_tokens WHERE id = ?");
            $stmt->execute([$tokenId]);
            return true;
        } catch (Exception $e) {
            error_log("Error deleting API token: " . $e->getMessage());
            return false;
        }
    }
}
?>
