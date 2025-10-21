-- Migration 009: Add new action types to zone_file_history
-- This migration adds 'assign_include' and 'reassign_include' to the action enum
-- It is idempotent and can be run multiple times safely.

USE dns3_db;

-- Modify the action column to add new enum values
ALTER TABLE zone_file_history 
MODIFY COLUMN action ENUM('created', 'updated', 'status_changed', 'content_changed', 'assign_include', 'reassign_include') NOT NULL;

SELECT 'Migration 009 completed successfully' AS status;

-- End of migration 009
