-- Migration 012: Add command and return_code fields to zone_file_validation table
-- This migration adds fields to capture the exact command executed and its exit code

USE dns3_db;

-- Add command column to store the executed named-checkzone command
ALTER TABLE zone_file_validation 
ADD COLUMN command TEXT DEFAULT NULL COMMENT 'Command executed for validation' 
AFTER output;

-- Add return_code column to store the exit code from named-checkzone
ALTER TABLE zone_file_validation 
ADD COLUMN return_code INT DEFAULT NULL COMMENT 'Exit code from validation command' 
AFTER command;

SELECT 'Migration 012 completed: command and return_code columns added to zone_file_validation' AS status;
