-- Migration: Create zone_acl_entries view for compatibility
-- This migration ensures the zone ACL system works correctly:
-- 1. Creates the acl_entries table for zone ACLs if it doesn't exist
-- 2. Creates a view zone_acl_entries pointing to acl_entries for code compatibility
--
-- Run with: mysql -u dns3_user -p dns3_db < scripts/002_create_zone_acl_view.sql

-- --------------------------------------------------------
-- 1. Create acl_entries table for zone ACL if it doesn't exist
-- --------------------------------------------------------
-- Note: This table stores zone-specific ACL entries.
-- The schema matches what ZoneAcl.php expects.

CREATE TABLE IF NOT EXISTS `acl_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_file_id` int(11) NOT NULL COMMENT 'Reference to zone_files.id',
  `subject_type` enum('user','role','ad_group') NOT NULL COMMENT 'Type of ACL subject',
  `subject_identifier` varchar(255) NOT NULL COMMENT 'User ID/username, role name, or AD group DN',
  `permission` enum('read','write','admin') NOT NULL DEFAULT 'read' COMMENT 'Permission level',
  `created_by` int(11) NOT NULL COMMENT 'User who created this ACL entry',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_subject` (`subject_type`, `subject_identifier`(100)),
  KEY `idx_permission` (`permission`),
  KEY `idx_created_by` (`created_by`),
  UNIQUE KEY `uq_zone_acl` (`zone_file_id`, `subject_type`, `subject_identifier`(100), `permission`),
  CONSTRAINT `acl_entries_zone_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_entries_zone_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 2. Create or replace view zone_acl_entries pointing to acl_entries
-- --------------------------------------------------------
-- This view provides compatibility for code that references zone_acl_entries
-- All columns are selected in the same order as the base table

CREATE OR REPLACE VIEW `zone_acl_entries` AS
SELECT
  `id`,
  `zone_file_id`,
  `subject_type`,
  `subject_identifier`,
  `permission`,
  `created_by`,
  `created_at`
FROM `acl_entries`;

-- --------------------------------------------------------
-- 3. Verify migration success
-- --------------------------------------------------------
-- You can run these queries to verify:
-- DESCRIBE acl_entries;
-- SHOW CREATE VIEW zone_acl_entries;
-- SELECT * FROM zone_acl_entries LIMIT 5;
