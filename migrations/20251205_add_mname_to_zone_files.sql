-- Migration: Add MNAME field to zone_files table
-- Date: 2025-12-05
-- Description: Adds mname column for SOA primary master nameserver to zone_files table.
--              The MNAME is the authoritative nameserver for the zone.

-- Add MNAME field (primary master nameserver)
ALTER TABLE zone_files ADD COLUMN mname VARCHAR(255) NULL COMMENT 'SOA MNAME - primary master nameserver for zone (e.g., ns1.example.com.)';
