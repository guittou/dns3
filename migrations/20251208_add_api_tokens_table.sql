-- Migration to add API tokens table for Bearer token authentication
-- This enables non-browser clients to authenticate without session cookies

CREATE TABLE IF NOT EXISTS `api_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token_name` varchar(255) NOT NULL COMMENT 'Human-readable name for the token',
  `token_hash` varchar(255) NOT NULL COMMENT 'SHA-256 hash of the token',
  `token_prefix` varchar(20) NOT NULL COMMENT 'First few characters for identification',
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL COMMENT 'NULL means no expiration',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `revoked_at` timestamp NULL DEFAULT NULL COMMENT 'NULL means active, set to revoke',
  `created_by` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token_prefix` (`token_prefix`),
  KEY `idx_revoked_at` (`revoked_at`),
  KEY `idx_expires_at` (`expires_at`),
  CONSTRAINT `api_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `api_tokens_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for efficient lookups during authentication
CREATE INDEX idx_token_lookup ON api_tokens(token_hash, revoked_at, expires_at);
