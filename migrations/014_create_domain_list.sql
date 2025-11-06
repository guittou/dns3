-- Migration 014: Create Domain List Table
-- This migration creates a table to manage domains attached to zone files
-- Purpose: Fix the 1146 error "Table 'dns3_db.domaine_list' doesn't exist"
--          by creating the domaine_list table with proper structure,
--          foreign keys, and constraints.

USE dns3_db;

-- Create domaine_list table
CREATE TABLE IF NOT EXISTS `domaine_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) NOT NULL,
  `zone_file_id` int(11) NOT NULL,
  `created_by` int(11) NOT NULL,
  `status` enum('active','deleted') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_domain` (`domain`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `domaine_list_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `domaine_list_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `domaine_list_ibfk_3` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
