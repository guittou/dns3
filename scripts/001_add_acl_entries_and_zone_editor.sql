-- Migration: Add ACL entries for zone files and zone_editor role
-- This migration adds per-zone ACL support and a new zone_editor role
-- 
-- Run with: mysql -u dns3_user -p dns3_db < scripts/001_add_acl_entries_and_zone_editor.sql

-- --------------------------------------------------------
-- 1. Create zone_acl_entries table for per-zone ACL management
-- --------------------------------------------------------

CREATE TABLE IF NOT EXISTS `zone_acl_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_file_id` int(11) NOT NULL COMMENT 'Reference to zone_files.id',
  `subject_type` enum('user','role','ad_group') NOT NULL COMMENT 'Type of ACL subject',
  `subject_identifier` varchar(255) NOT NULL COMMENT 'User ID, role name, or AD group DN',
  `permission` enum('read','write','admin') NOT NULL DEFAULT 'read' COMMENT 'Permission level: read, write, or admin',
  `created_by` int(11) NOT NULL COMMENT 'User who created this ACL entry',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_subject` (`subject_type`, `subject_identifier`(100)),
  KEY `idx_permission` (`permission`),
  KEY `idx_created_by` (`created_by`),
  UNIQUE KEY `uq_zone_acl` (`zone_file_id`, `subject_type`, `subject_identifier`(100), `permission`),
  CONSTRAINT `zone_acl_entries_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `zone_acl_entries_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 2. Insert zone_editor role if it doesn't exist
-- --------------------------------------------------------

INSERT INTO `roles` (`name`, `description`, `created_at`)
SELECT 'zone_editor', 'Can view and edit zone files for which user has ACL permissions. Does not grant global admin access.', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `roles` WHERE `name` = 'zone_editor');

-- --------------------------------------------------------
-- 3. Verify migration success
-- --------------------------------------------------------

-- You can run these queries to verify:
-- SELECT * FROM roles WHERE name = 'zone_editor';
-- DESCRIBE zone_acl_entries;
