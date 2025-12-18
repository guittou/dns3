-- Migration: Add DNSSEC include path fields to zone_files table
-- Date: 2025-12-18
-- Description: Adds dnssec_include_ksk and dnssec_include_zsk columns to support
--              DNSSEC key include directives in master zones

-- Add DNSSEC KSK include path column
ALTER TABLE zone_files 
ADD COLUMN dnssec_include_ksk VARCHAR(255) NULL 
COMMENT 'Path to DNSSEC KSK include file (e.g., /etc/bind/keys/domain.ksk.key)'
AFTER mname;

-- Add DNSSEC ZSK include path column
ALTER TABLE zone_files 
ADD COLUMN dnssec_include_zsk VARCHAR(255) NULL 
COMMENT 'Path to DNSSEC ZSK include file (e.g., /etc/bind/keys/domain.zsk.key)'
AFTER dnssec_include_ksk;

-- Verify the changes
DESCRIBE zone_files;
