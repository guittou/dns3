-- Migration: Add Application and Trigramme metadata fields to zone_files table
-- Date: 2025-12-18
-- Description: Adds application and trigramme columns to support metadata
--              for include zone files (not used for master zones)

-- Add application column
ALTER TABLE zone_files 
ADD COLUMN application VARCHAR(255) NULL 
COMMENT 'Application metadata for include files (optional)'
AFTER dnssec_include_zsk;

-- Add trigramme column
ALTER TABLE zone_files 
ADD COLUMN trigramme VARCHAR(255) NULL 
COMMENT 'Trigramme metadata for include files (optional)'
AFTER application;

-- Verify the changes
DESCRIBE zone_files;
