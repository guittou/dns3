-- Migration 008: Enforce Single Parent Per Include
-- This migration enforces that each include can only have ONE parent zone file.
-- IMPORTANT: BACKUP YOUR DATABASE BEFORE RUNNING THIS MIGRATION!
--
-- What this migration does:
-- 1. Detects includes with multiple parents
-- 2. Keeps only the oldest parent relationship (by created_at)
-- 3. Creates a new table with UNIQUE(include_id) constraint
-- 4. Preserves the old table for rollback (zone_file_includes_old)
--
-- This migration is idempotent and can be run multiple times safely.

USE dns3_db;

-- Check if we already migrated (zone_file_includes_old exists means migration was run)
SET @migration_done = 0;
SELECT COUNT(*) INTO @migration_done 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes_old';

-- Only proceed if migration hasn't been done
SET @skip_migration = IF(@migration_done > 0, 1, 0);

-- Step 1: Create new table with the correct schema (including UNIQUE constraint on include_id)
CREATE TABLE IF NOT EXISTS zone_file_includes_new (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL COMMENT 'ID of parent zone file (can be master or include)',
    include_id INT NOT NULL COMMENT 'ID of include zone file',
    position INT DEFAULT 0 COMMENT 'Order position for includes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_parent_include (parent_id, include_id),
    UNIQUE KEY unique_include (include_id) COMMENT 'Enforce single parent per include',
    INDEX idx_parent_id (parent_id),
    INDEX idx_include_id (include_id),
    INDEX idx_position (position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Step 2: If migration not done yet, migrate data keeping only oldest parent per include
SET @sql = IF(@skip_migration = 0,
    'INSERT INTO zone_file_includes_new (parent_id, include_id, position, created_at)
     SELECT parent_id, include_id, position, created_at
     FROM (
         SELECT zfi.parent_id, zfi.include_id, zfi.position, zfi.created_at,
                ROW_NUMBER() OVER (PARTITION BY zfi.include_id ORDER BY zfi.created_at ASC, zfi.id ASC) as rn
         FROM zone_file_includes zfi
     ) as ranked
     WHERE rn = 1
     ON DUPLICATE KEY UPDATE 
         parent_id = VALUES(parent_id),
         position = VALUES(position),
         created_at = VALUES(created_at)',
    'SELECT "Migration already completed, skipping data copy" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 3: Rename old table to zone_file_includes_old (for rollback purposes)
SET @sql = IF(@skip_migration = 0,
    'RENAME TABLE zone_file_includes TO zone_file_includes_old',
    'SELECT "Old table already renamed" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 4: Rename new table to zone_file_includes
SET @sql = IF(@skip_migration = 0,
    'RENAME TABLE zone_file_includes_new TO zone_file_includes',
    'SELECT "New table already active" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 5: Re-create foreign key constraints (they were lost during table rename)
-- First, drop any existing foreign keys if they exist
SET @fk_parent_exists = 0;
SELECT COUNT(*) INTO @fk_parent_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_1';

SET @sql = IF(@fk_parent_exists > 0 AND @skip_migration = 0,
    'ALTER TABLE zone_file_includes DROP FOREIGN KEY zone_file_includes_ibfk_1',
    'SELECT "Parent FK does not exist or migration skipped" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_include_exists = 0;
SELECT COUNT(*) INTO @fk_include_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'dns3_db' 
  AND TABLE_NAME = 'zone_file_includes' 
  AND CONSTRAINT_NAME = 'zone_file_includes_ibfk_2';

SET @sql = IF(@fk_include_exists > 0 AND @skip_migration = 0,
    'ALTER TABLE zone_file_includes DROP FOREIGN KEY zone_file_includes_ibfk_2',
    'SELECT "Include FK does not exist or migration skipped" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Now add the foreign keys
SET @sql = IF(@skip_migration = 0 OR @fk_parent_exists = 0,
    'ALTER TABLE zone_file_includes 
     ADD CONSTRAINT zone_file_includes_ibfk_1 
     FOREIGN KEY (parent_id) REFERENCES zone_files(id) ON DELETE CASCADE',
    'SELECT "Parent FK already added" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(@skip_migration = 0 OR @fk_include_exists = 0,
    'ALTER TABLE zone_file_includes 
     ADD CONSTRAINT zone_file_includes_ibfk_2 
     FOREIGN KEY (include_id) REFERENCES zone_files(id) ON DELETE CASCADE',
    'SELECT "Include FK already added" AS info');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Step 6: Report on any duplicates that were resolved
SELECT 'Migration 008 completed successfully!' AS status;

-- Show includes that had multiple parents (for audit purposes)
SELECT 'Includes that had multiple parents (oldest parent was kept):' AS info;
SELECT 
    zf.id,
    zf.name,
    zf.filename,
    COUNT(*) as parent_count,
    GROUP_CONCAT(DISTINCT zfi.parent_id ORDER BY zfi.created_at SEPARATOR ', ') as all_parent_ids
FROM zone_file_includes_old zfi
INNER JOIN zone_files zf ON zfi.include_id = zf.id
GROUP BY zf.id, zf.name, zf.filename
HAVING parent_count > 1
ORDER BY parent_count DESC;

-- Notes for rollback:
-- To rollback this migration:
-- 1. RENAME TABLE zone_file_includes TO zone_file_includes_failed;
-- 2. RENAME TABLE zone_file_includes_old TO zone_file_includes;
-- 3. DROP TABLE zone_file_includes_failed;
-- 4. Verify foreign keys are intact

-- IMPORTANT: DO NOT DROP zone_file_includes_old until you're confident the migration is successful
-- and you have verified all functionality works correctly.

-- End of migration 008
