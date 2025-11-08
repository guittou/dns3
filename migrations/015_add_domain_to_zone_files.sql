-- Migration 015: Add domain column to zone_files
-- This migration adds a domain column to zone_files and migrates existing data from domaine_list
-- Purpose: Consolidate domain information into zone_files table for simpler data model
--          while keeping domaine_list for backward compatibility and rollback safety.

USE dns3_db;

-- Add domain column to zone_files table
ALTER TABLE zone_files 
ADD COLUMN `domain` VARCHAR(255) DEFAULT NULL COMMENT 'Domain name for master zones (migrated from domaine_list)';

-- Add index on domain for performance
CREATE INDEX idx_domain ON zone_files(domain);

-- Migrate existing domain data from domaine_list to zone_files
-- Only for master zones (file_type = 'master')
UPDATE zone_files z 
JOIN domaine_list d ON d.zone_file_id = z.id
SET z.domain = d.domain
WHERE z.file_type = 'master' AND z.domain IS NULL;

-- Verification query (run manually to verify migration)
-- SELECT COUNT(*) as migrated_domains FROM zone_files WHERE domain IS NOT NULL;
-- SELECT z.id, z.name, z.domain, z.file_type FROM zone_files WHERE domain IS NOT NULL LIMIT 10;

-- ROLLBACK INSTRUCTIONS
-- To rollback this migration:
-- 1. Stop the application
-- 2. Run the following SQL:
--    ALTER TABLE zone_files DROP INDEX idx_domain;
--    ALTER TABLE zone_files DROP COLUMN domain;
-- 3. Revert code changes
-- 4. Restart the application
-- 
-- Note: domaine_list table is NOT dropped in this migration for safety.
--       It can be dropped in a future migration after verification.
