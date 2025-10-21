-- Migration 011: Create zone_file_validation table
-- This table stores the results of named-checkzone validation runs
-- for zone files after create/update operations.

USE dns3_db;

CREATE TABLE IF NOT EXISTS zone_file_validation (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zone_file_id INT NOT NULL,
    status ENUM('pending', 'passed', 'failed', 'error') NOT NULL DEFAULT 'pending',
    output TEXT DEFAULT NULL COMMENT 'Output from named-checkzone command',
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    run_by INT DEFAULT NULL COMMENT 'User ID who triggered the validation (NULL for background jobs)',
    FOREIGN KEY (zone_file_id) REFERENCES zone_files(id) ON DELETE CASCADE,
    FOREIGN KEY (run_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_zone_file_id (zone_file_id),
    INDEX idx_status (status),
    INDEX idx_checked_at (checked_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add index for recent validations lookup
CREATE INDEX idx_zone_file_checked ON zone_file_validation(zone_file_id, checked_at DESC);

SELECT 'Migration 011 completed: zone_file_validation table created' AS status;
