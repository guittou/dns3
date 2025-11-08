-- Migration 016: Drop domaine_list table
-- This migration drops the legacy domaine_list table after data has been migrated to zone_files.domain
-- Purpose: Complete the consolidation of domain information into zone_files table
--
-- CRITICAL: This migration is DESTRUCTIVE and drops the domaine_list table permanently.
--           DO NOT RUN unless you have:
--           1. Verified migration 015 completed successfully
--           2. Created a full database backup
--           3. Tested the application with zone_files.domain in staging
--
-- BACKUP COMMAND (run before this migration):
-- mysqldump -u [username] -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql

USE dns3_db;

-- Start transaction for safety
START TRANSACTION;

-- Check if table exists before attempting to drop
-- This makes the migration idempotent and safe to re-run
SET @table_exists = (
    SELECT COUNT(*) 
    FROM information_schema.tables 
    WHERE table_schema = 'dns3_db' 
    AND table_name = 'domaine_list'
);

-- Drop the domaine_list table if it exists
DROP TABLE IF EXISTS domaine_list;

-- Commit the transaction
COMMIT;

-- Verification queries (run manually after migration)
-- Verify table is gone:
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dns3_db' AND table_name = 'domaine_list';
-- Expected: 0
--
-- Verify domain data is in zone_files:
-- SELECT COUNT(*) as zones_with_domains FROM zone_files WHERE domain IS NOT NULL;
-- SELECT id, name, domain, file_type FROM zone_files WHERE domain IS NOT NULL LIMIT 10;

-- ROLLBACK INSTRUCTIONS
-- To rollback this migration:
-- 1. Stop the application immediately
-- 2. Restore the database from the backup taken before running this migration:
--    mysql -u [username] -p dns3_db < backup_YYYYMMDD_HHMMSS.sql
-- 3. Revert code changes (git revert or restore previous version)
-- 4. Restart the application
-- 5. Verify the application is working correctly
--
-- Note: If you need to recreate domaine_list without restoring from backup,
--       you can use migration 014_create_domain_list.sql and manually populate data
--       from zone_files.domain, but this is NOT recommended as you will lose
--       original created_at/updated_at timestamps and created_by/updated_by values.
