-- Migration: Add SOA fields to zone_files table
-- Date: 2025-12-05
-- Description: Adds columns for SOA timers and default TTL to zone_files table
--              to allow customization during zone creation and editing.

-- Add default_ttl column (for $TTL directive at start of zone file)
ALTER TABLE zone_files ADD COLUMN default_ttl INT NULL DEFAULT 86400 COMMENT 'Default TTL for zone records (seconds)';

-- Add SOA timer fields
ALTER TABLE zone_files ADD COLUMN soa_refresh INT NULL DEFAULT 10800 COMMENT 'SOA refresh timer (seconds)';
ALTER TABLE zone_files ADD COLUMN soa_retry INT NULL DEFAULT 900 COMMENT 'SOA retry timer (seconds)';
ALTER TABLE zone_files ADD COLUMN soa_expire INT NULL DEFAULT 604800 COMMENT 'SOA expire timer (seconds)';
ALTER TABLE zone_files ADD COLUMN soa_minimum INT NULL DEFAULT 3600 COMMENT 'SOA minimum/negative caching TTL (seconds)';

-- Add SOA RNAME field (contact email, stored without @ replacement)
ALTER TABLE zone_files ADD COLUMN soa_rname VARCHAR(255) NULL COMMENT 'SOA RNAME - contact email for zone (e.g., admin.example.com or admin@example.com)';

-- Note: SOA serial is auto-generated and managed by the application, not stored as a column.
-- The MNAME (primary nameserver) is derived from the zone domain or explicitly set in zone content.
