/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: dns3_db
-- ------------------------------------------------------
-- Server version	10.11.14-MariaDB-0+deb12u2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `acl_entries`
--

DROP TABLE IF EXISTS `acl_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `acl_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `resource_type` enum('dns_record','zone','global') NOT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `permission` enum('read','write','delete','admin') NOT NULL,
  `status` enum('enabled','disabled') DEFAULT 'enabled',
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_role_id` (`role_id`),
  KEY `idx_resource` (`resource_type`,`resource_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `acl_entries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_entries_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_entries_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `acl_entries_ibfk_4` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_user_or_role` CHECK (`user_id` is not null or `role_id` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acl_entries`
--

LOCK TABLES `acl_entries` WRITE;
/*!40000 ALTER TABLE `acl_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `acl_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `acl_history`
--

DROP TABLE IF EXISTS `acl_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `acl_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `acl_id` int(11) NOT NULL,
  `action` enum('created','updated','status_changed') NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `resource_type` enum('dns_record','zone','global') NOT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `permission` enum('read','write','delete','admin') NOT NULL,
  `old_status` enum('enabled','disabled') DEFAULT NULL,
  `new_status` enum('enabled','disabled') NOT NULL,
  `changed_by` int(11) NOT NULL,
  `changed_at` timestamp NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `changed_by` (`changed_by`),
  KEY `idx_acl_id` (`acl_id`),
  KEY `idx_action` (`action`),
  KEY `idx_changed_at` (`changed_at`),
  CONSTRAINT `acl_history_ibfk_1` FOREIGN KEY (`acl_id`) REFERENCES `acl_entries` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_history_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acl_history`
--

LOCK TABLES `acl_history` WRITE;
/*!40000 ALTER TABLE `acl_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `acl_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `applications`
--

DROP TABLE IF EXISTS `applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Application name',
  `description` text DEFAULT NULL COMMENT 'Application description',
  `owner` varchar(255) DEFAULT NULL COMMENT 'Application owner',
  `zone_file_id` int(11) NOT NULL COMMENT 'Associated zone file',
  `status` enum('active','inactive','deleted') DEFAULT 'active' COMMENT 'Application status',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_name` (`name`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `applications_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `applications`
--

LOCK TABLES `applications` WRITE;
/*!40000 ALTER TABLE `applications` DISABLE KEYS */;
/*!40000 ALTER TABLE `applications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_mappings`
--

DROP TABLE IF EXISTS `auth_mappings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` enum('ad','ldap') NOT NULL,
  `dn_or_group` varchar(255) NOT NULL COMMENT 'AD group CN or LDAP DN/OU path',
  `role_id` int(11) NOT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL COMMENT 'Optional description of this mapping',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mapping` (`source`,`dn_or_group`,`role_id`),
  KEY `created_by` (`created_by`),
  KEY `idx_source` (`source`),
  KEY `idx_role_id` (`role_id`),
  CONSTRAINT `auth_mappings_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `auth_mappings_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_mappings`
--

LOCK TABLES `auth_mappings` WRITE;
/*!40000 ALTER TABLE `auth_mappings` DISABLE KEYS */;
INSERT INTO `auth_mappings` VALUES
(1,'ad','CN=DNSAdmins,OU=Groups,DC=example,DC=com',2,1,'2025-10-20 09:21:09','');
/*!40000 ALTER TABLE `auth_mappings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dns_record_history`
--

DROP TABLE IF EXISTS `dns_record_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dns_record_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `record_id` int(11) NOT NULL,
  `zone_file_id` int(11) DEFAULT NULL,
  `action` enum('created','updated','status_changed') NOT NULL,
  `record_type` enum('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL,
  `name` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `address_ipv4` varchar(15) DEFAULT NULL,
  `address_ipv6` varchar(45) DEFAULT NULL,
  `cname_target` varchar(255) DEFAULT NULL,
  `ptrdname` varchar(255) DEFAULT NULL,
  `txt` text DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `priority` int(11) DEFAULT NULL,
  `old_status` enum('active','disabled','deleted') DEFAULT NULL,
  `new_status` enum('active','disabled','deleted') NOT NULL,
  `changed_by` int(11) NOT NULL,
  `changed_at` timestamp NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `changed_by` (`changed_by`),
  KEY `idx_record_id` (`record_id`),
  KEY `idx_action` (`action`),
  KEY `idx_changed_at` (`changed_at`),
  CONSTRAINT `dns_record_history_ibfk_1` FOREIGN KEY (`record_id`) REFERENCES `dns_records` (`id`) ON DELETE CASCADE,
  CONSTRAINT `dns_record_history_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_record_history`
--

LOCK TABLES `dns_record_history` WRITE;
/*!40000 ALTER TABLE `dns_record_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `dns_record_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dns_records`
--

DROP TABLE IF EXISTS `dns_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dns_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_file_id` int(11) DEFAULT NULL COMMENT 'Associated zone file',
  `record_type` enum('A','AAAA','CNAME','MX','TXT','NS','SOA','PTR','SRV') NOT NULL,
  `name` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `address_ipv4` varchar(15) DEFAULT NULL COMMENT 'IPv4 address for A records',
  `address_ipv6` varchar(45) DEFAULT NULL COMMENT 'IPv6 address for AAAA records',
  `cname_target` varchar(255) DEFAULT NULL COMMENT 'Target hostname for CNAME records',
  `ptrdname` varchar(255) DEFAULT NULL COMMENT 'Reverse DNS name for PTR records',
  `txt` text DEFAULT NULL COMMENT 'Text content for TXT records',
  `ttl` int(11) DEFAULT 3600,
  `priority` int(11) DEFAULT NULL,
  `requester` varchar(255) DEFAULT NULL COMMENT 'Person or system requesting this DNS record',
  `status` enum('active','disabled','deleted') DEFAULT 'active',
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `expires_at` datetime DEFAULT NULL COMMENT 'Expiration date for temporary records',
  `ticket_ref` varchar(255) DEFAULT NULL COMMENT 'Reference to ticket system (JIRA, ServiceNow, etc.)',
  `comment` text DEFAULT NULL COMMENT 'Additional notes or comments about this record',
  `last_seen` datetime DEFAULT NULL COMMENT 'Last time this record was viewed (server-managed)',
  PRIMARY KEY (`id`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_name` (`name`),
  KEY `idx_type` (`record_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_ticket_ref` (`ticket_ref`),
  KEY `idx_address_ipv4` (`address_ipv4`),
  KEY `idx_address_ipv6` (`address_ipv6`),
  KEY `idx_cname_target` (`cname_target`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  CONSTRAINT `dns_records_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `dns_records_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
/*!40000 ALTER TABLE `dns_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES
(1,'admin','Administrator with full access','2025-10-20 07:21:05'),
(2,'user','Regular user with limited access','2025-10-20 07:21:05');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `last_activity` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_roles` (
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `assigned_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_role_id` (`role_id`),
  CONSTRAINT `user_roles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_roles_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES
(1,1,'2025-10-20 07:21:05'),
(2,1,'2025-10-20 09:24:16');
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `auth_method` enum('database','ad','ldap') DEFAULT 'database',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_username` (`username`),
  KEY `idx_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'admin','admin@example.local','$2y$12$lpCQ0Zsw25LuvXr9L/gIWO6xQNwRidtDC.ZmF8WIfZkSU324PfOsq','database','2025-10-19 12:27:41','2025-10-20 09:19:30',1),
(2,'guittou','guittou@gmail.com','$2y$10$.CJ6UeeKXSj7O3dZGcdtw.bjXze2e5z.n58462/hS.Rk4VgH5D21q','database','2025-10-20 09:24:16','2025-10-23 08:22:09',1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zone_file_history`
--

DROP TABLE IF EXISTS `zone_file_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_file_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_file_id` int(11) NOT NULL COMMENT 'ID of the zone file',
  `action` enum('created','updated','status_changed','content_changed','assign_include','reassign_include') NOT NULL,
  `name` varchar(255) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `file_type` enum('master','include') NOT NULL,
  `old_status` enum('active','inactive','deleted') DEFAULT NULL,
  `new_status` enum('active','inactive','deleted') NOT NULL,
  `old_content` text DEFAULT NULL COMMENT 'Previous zone file content',
  `new_content` text DEFAULT NULL COMMENT 'New zone file content',
  `changed_by` int(11) NOT NULL,
  `changed_at` timestamp NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `changed_by` (`changed_by`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_action` (`action`),
  KEY `idx_changed_at` (`changed_at`),
  CONSTRAINT `zone_file_history_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `zone_file_history_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_history`
--

LOCK TABLES `zone_file_history` WRITE;
/*!40000 ALTER TABLE `zone_file_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `zone_file_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zone_file_includes`
--

DROP TABLE IF EXISTS `zone_file_includes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_file_includes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL,
  `include_id` int(11) NOT NULL,
  `position` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_parent_include` (`parent_id`,`include_id`),
  UNIQUE KEY `ux_include_single_parent` (`include_id`),
  KEY `idx_parent` (`parent_id`),
  KEY `idx_include` (`include_id`),
  CONSTRAINT `zone_file_includes_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `zone_file_includes_ibfk_2` FOREIGN KEY (`include_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
/*!40000 ALTER TABLE `zone_file_includes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zone_file_includes_new`
--

DROP TABLE IF EXISTS `zone_file_includes_new`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_file_includes_new` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL COMMENT 'ID of parent zone file (can be master or include)',
  `include_id` int(11) NOT NULL COMMENT 'ID of include zone file',
  `position` int(11) DEFAULT 0 COMMENT 'Order position for includes',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_parent_include` (`parent_id`,`include_id`),
  UNIQUE KEY `unique_include` (`include_id`) COMMENT 'Enforce single parent per include',
  KEY `idx_parent_id` (`parent_id`),
  KEY `idx_include_id` (`include_id`),
  KEY `idx_position` (`position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes_new`
--

LOCK TABLES `zone_file_includes_new` WRITE;
/*!40000 ALTER TABLE `zone_file_includes_new` DISABLE KEYS */;
/*!40000 ALTER TABLE `zone_file_includes_new` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zone_file_validation`
--

DROP TABLE IF EXISTS `zone_file_validation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_file_validation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `zone_file_id` int(11) NOT NULL,
  `status` enum('pending','passed','failed','error') NOT NULL DEFAULT 'pending',
  `output` text DEFAULT NULL COMMENT 'Output from named-checkzone command',
  `checked_at` timestamp NULL DEFAULT current_timestamp(),
  `run_by` int(11) DEFAULT NULL COMMENT 'User ID who triggered the validation (NULL for background jobs)',
  PRIMARY KEY (`id`),
  KEY `run_by` (`run_by`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_status` (`status`),
  KEY `idx_checked_at` (`checked_at`),
  KEY `idx_zone_file_checked` (`zone_file_id`,`checked_at` DESC),
  CONSTRAINT `zone_file_validation_ibfk_1` FOREIGN KEY (`zone_file_id`) REFERENCES `zone_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `zone_file_validation_ibfk_2` FOREIGN KEY (`run_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_validation`
--

LOCK TABLES `zone_file_validation` WRITE;
/*!40000 ALTER TABLE `zone_file_validation` DISABLE KEYS */;
INSERT INTO `zone_file_validation` VALUES
(1,1,'pending','Validation queued for background processing','2025-10-22 06:35:39',2),
(2,1,'pending','Validation queued for background processing','2025-10-22 06:36:15',2),
(3,1,'pending','Validation queued for background processing','2025-10-22 06:41:00',2),
(4,1,'pending','Validation queued for background processing','2025-10-22 07:23:39',2),
(5,1,'pending','Validation queued for background processing','2025-10-22 07:23:55',2),
(6,1,'pending','Validation queued for background processing','2025-10-22 07:24:02',2),
(7,1,'pending','Validation queued for background processing','2025-10-22 07:30:31',2),
(8,1,'pending','Validation queued for background processing','2025-10-22 07:31:20',2),
(9,1,'pending','Validation queued for background processing','2025-10-22 07:31:28',2),
(10,1,'failed','dns_master_load: /tmp/zone_cilua3n6p91i9BbyVFd:1: unexpected end of line\ndns_master_load: /tmp/zone_cilua3n6p91i9BbyVFd:1: unexpected end of input\n/tmp/zone_cilua3n6p91i9BbyVFd:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_cilua3n6p91i9BbyVFd:5: zone_include_1.db: file not found\n/tmp/zone_cilua3n6p91i9BbyVFd:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_cilua3n6p91i9BbyVFd failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(11,1,'failed','dns_master_load: /tmp/zone_d8h702ss63877JCXHiQ:1: unexpected end of line\ndns_master_load: /tmp/zone_d8h702ss63877JCXHiQ:1: unexpected end of input\n/tmp/zone_d8h702ss63877JCXHiQ:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_d8h702ss63877JCXHiQ:5: zone_include_1.db: file not found\n/tmp/zone_d8h702ss63877JCXHiQ:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_d8h702ss63877JCXHiQ failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(12,1,'failed','dns_master_load: /tmp/zone_1lpq8u8i7b6t74WGXmG:1: unexpected end of line\ndns_master_load: /tmp/zone_1lpq8u8i7b6t74WGXmG:1: unexpected end of input\n/tmp/zone_1lpq8u8i7b6t74WGXmG:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_1lpq8u8i7b6t74WGXmG:5: zone_include_1.db: file not found\n/tmp/zone_1lpq8u8i7b6t74WGXmG:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_1lpq8u8i7b6t74WGXmG failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(13,1,'failed','dns_master_load: /tmp/zone_la8hthecajjp9d1AKj8:1: unexpected end of line\ndns_master_load: /tmp/zone_la8hthecajjp9d1AKj8:1: unexpected end of input\n/tmp/zone_la8hthecajjp9d1AKj8:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_la8hthecajjp9d1AKj8:5: zone_include_1.db: file not found\n/tmp/zone_la8hthecajjp9d1AKj8:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_la8hthecajjp9d1AKj8 failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(14,1,'failed','dns_master_load: /tmp/zone_k6tst4vtfaap7pPeMS4:1: unexpected end of line\ndns_master_load: /tmp/zone_k6tst4vtfaap7pPeMS4:1: unexpected end of input\n/tmp/zone_k6tst4vtfaap7pPeMS4:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_k6tst4vtfaap7pPeMS4:5: zone_include_1.db: file not found\n/tmp/zone_k6tst4vtfaap7pPeMS4:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_k6tst4vtfaap7pPeMS4 failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(15,1,'failed','dns_master_load: /tmp/zone_bobjuc5cfiteegCS3m4:1: unexpected end of line\ndns_master_load: /tmp/zone_bobjuc5cfiteegCS3m4:1: unexpected end of input\n/tmp/zone_bobjuc5cfiteegCS3m4:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_bobjuc5cfiteegCS3m4:5: zone_include_1.db: file not found\n/tmp/zone_bobjuc5cfiteegCS3m4:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_bobjuc5cfiteegCS3m4 failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(16,1,'failed','dns_master_load: /tmp/zone_olrsvei2p0b3beWBrRX:1: unexpected end of line\ndns_master_load: /tmp/zone_olrsvei2p0b3beWBrRX:1: unexpected end of input\n/tmp/zone_olrsvei2p0b3beWBrRX:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_olrsvei2p0b3beWBrRX:5: zone_include_1.db: file not found\n/tmp/zone_olrsvei2p0b3beWBrRX:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_olrsvei2p0b3beWBrRX failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(17,1,'failed','dns_master_load: /tmp/zone_9bs1h0n84anm3IwQWzP:1: unexpected end of line\ndns_master_load: /tmp/zone_9bs1h0n84anm3IwQWzP:1: unexpected end of input\n/tmp/zone_9bs1h0n84anm3IwQWzP:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_9bs1h0n84anm3IwQWzP:5: zone_include_1.db: file not found\n/tmp/zone_9bs1h0n84anm3IwQWzP:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_9bs1h0n84anm3IwQWzP failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(18,1,'failed','dns_master_load: /tmp/zone_l411krm533pn1q8yI8d:1: unexpected end of line\ndns_master_load: /tmp/zone_l411krm533pn1q8yI8d:1: unexpected end of input\n/tmp/zone_l411krm533pn1q8yI8d:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_l411krm533pn1q8yI8d:5: zone_include_1.db: file not found\n/tmp/zone_l411krm533pn1q8yI8d:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_l411krm533pn1q8yI8d failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:34:50',2),
(19,1,'pending','Validation queued for background processing','2025-10-22 07:35:10',2),
(20,1,'failed','dns_master_load: /tmp/zone_uvardfqf052u75KLiwM:1: unexpected end of line\ndns_master_load: /tmp/zone_uvardfqf052u75KLiwM:1: unexpected end of input\n/tmp/zone_uvardfqf052u75KLiwM:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_uvardfqf052u75KLiwM:5: zone_include_1.db: file not found\n/tmp/zone_uvardfqf052u75KLiwM:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_uvardfqf052u75KLiwM failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:42:38',2),
(21,1,'pending','Validation queued for background processing','2025-10-22 07:43:39',2),
(22,1,'pending','Validation queued for background processing','2025-10-22 07:44:52',2),
(23,1,'failed','dns_master_load: /tmp/zone_0ohkqnqv1doe2kslJZc:1: unexpected end of line\ndns_master_load: /tmp/zone_0ohkqnqv1doe2kslJZc:1: unexpected end of input\n/tmp/zone_0ohkqnqv1doe2kslJZc:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_0ohkqnqv1doe2kslJZc:5: zone_include_1.db: file not found\n/tmp/zone_0ohkqnqv1doe2kslJZc:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_0ohkqnqv1doe2kslJZc failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:45:30',2),
(24,1,'failed','dns_master_load: /tmp/zone_qaggtcr3j7co0Sk5dLO:1: unexpected end of line\ndns_master_load: /tmp/zone_qaggtcr3j7co0Sk5dLO:1: unexpected end of input\n/tmp/zone_qaggtcr3j7co0Sk5dLO:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_qaggtcr3j7co0Sk5dLO:5: zone_include_1.db: file not found\n/tmp/zone_qaggtcr3j7co0Sk5dLO:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_qaggtcr3j7co0Sk5dLO failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 07:45:30',2),
(25,1,'pending','Validation queued for background processing','2025-10-22 08:15:20',2),
(26,1,'failed','dns_master_load: /tmp/zone_hj6q5jh63icid8fSqqF:1: unexpected end of line\ndns_master_load: /tmp/zone_hj6q5jh63icid8fSqqF:1: unexpected end of input\n/tmp/zone_hj6q5jh63icid8fSqqF:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_hj6q5jh63icid8fSqqF:5: zone_include_1.db: file not found\n/tmp/zone_hj6q5jh63icid8fSqqF:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_hj6q5jh63icid8fSqqF failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 08:15:28',2),
(27,7,'pending','Validation queued for background processing','2025-10-22 08:24:42',2),
(28,7,'failed','zone Z5/IN: has 0 SOA records\nzone Z5/IN: has no NS records\nzone Z5/IN: not loaded due to errors.','2025-10-22 08:24:50',2),
(29,1,'pending','Validation queued for background processing','2025-10-22 09:57:12',2),
(30,1,'failed','dns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of line\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of input\n/tmp/zone_3gaqqoubtn40fpR5cYW:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:5: zone_include_1.db: file not found\n/tmp/zone_3gaqqoubtn40fpR5cYW:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_3gaqqoubtn40fpR5cYW failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 09:57:22',2),
(31,2,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of line\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of input\n/tmp/zone_3gaqqoubtn40fpR5cYW:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:5: zone_include_1.db: file not found\n/tmp/zone_3gaqqoubtn40fpR5cYW:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_3gaqqoubtn40fpR5cYW failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 09:57:22',2),
(32,3,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of line\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:1: unexpected end of input\n/tmp/zone_3gaqqoubtn40fpR5cYW:3: unknown RR type \'3600\'\ndns_master_load: /tmp/zone_3gaqqoubtn40fpR5cYW:5: zone_include_1.db: file not found\n/tmp/zone_3gaqqoubtn40fpR5cYW:8: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_3gaqqoubtn40fpR5cYW failed: unexpected end of input\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 09:57:22',2),
(33,1,'pending','Validation queued for background processing','2025-10-22 09:59:42',2),
(34,1,'pending','Validation queued for background processing','2025-10-22 09:59:48',2),
(35,1,'pending','Validation queued for background processing','2025-10-22 09:59:55',2),
(36,1,'failed','/tmp/zone_2vhfc6se6v9n8AW2ADn:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_2vhfc6se6v9n8AW2ADn:15: zone_include_1.db: file not found\n/tmp/zone_2vhfc6se6v9n8AW2ADn:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_2vhfc6se6v9n8AW2ADn failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(37,2,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_2vhfc6se6v9n8AW2ADn:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_2vhfc6se6v9n8AW2ADn:15: zone_include_1.db: file not found\n/tmp/zone_2vhfc6se6v9n8AW2ADn:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_2vhfc6se6v9n8AW2ADn failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(38,3,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_2vhfc6se6v9n8AW2ADn:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_2vhfc6se6v9n8AW2ADn:15: zone_include_1.db: file not found\n/tmp/zone_2vhfc6se6v9n8AW2ADn:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_2vhfc6se6v9n8AW2ADn failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(39,1,'failed','/tmp/zone_5k0tn3b0eugnavdKahg:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_5k0tn3b0eugnavdKahg:15: zone_include_1.db: file not found\n/tmp/zone_5k0tn3b0eugnavdKahg:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_5k0tn3b0eugnavdKahg failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(40,2,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_5k0tn3b0eugnavdKahg:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_5k0tn3b0eugnavdKahg:15: zone_include_1.db: file not found\n/tmp/zone_5k0tn3b0eugnavdKahg:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_5k0tn3b0eugnavdKahg failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(41,3,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_5k0tn3b0eugnavdKahg:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_5k0tn3b0eugnavdKahg:15: zone_include_1.db: file not found\n/tmp/zone_5k0tn3b0eugnavdKahg:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_5k0tn3b0eugnavdKahg failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(42,1,'failed','/tmp/zone_djohvp34t6m4chvzt5B:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_djohvp34t6m4chvzt5B:15: zone_include_1.db: file not found\n/tmp/zone_djohvp34t6m4chvzt5B:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_djohvp34t6m4chvzt5B failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(43,2,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_djohvp34t6m4chvzt5B:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_djohvp34t6m4chvzt5B:15: zone_include_1.db: file not found\n/tmp/zone_djohvp34t6m4chvzt5B:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_djohvp34t6m4chvzt5B failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(44,3,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_djohvp34t6m4chvzt5B:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_djohvp34t6m4chvzt5B:15: zone_include_1.db: file not found\n/tmp/zone_djohvp34t6m4chvzt5B:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_djohvp34t6m4chvzt5B failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:00:03',2),
(45,4,'failed','Include file has no master parent; cannot validate standalone','2025-10-22 10:30:32',2),
(46,4,'failed','Include file has no master parent; cannot validate standalone','2025-10-22 10:30:41',2),
(47,6,'pending','Validation queued for background processing','2025-10-22 10:31:10',2),
(48,6,'pending','Validation queued for background processing','2025-10-22 10:31:20',2),
(49,6,'passed','zone Z4/IN: loaded serial 2025102201\nOK','2025-10-22 10:31:30',2),
(50,6,'passed','zone Z4/IN: loaded serial 2025102201\nOK','2025-10-22 10:31:30',2),
(51,1,'pending','Validation queued for background processing','2025-10-22 10:32:30',2),
(52,1,'failed','/tmp/zone_f113fshhf3cdfORKuuN:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_f113fshhf3cdfORKuuN:15: zone_include_1.db: file not found\n/tmp/zone_f113fshhf3cdfORKuuN:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_f113fshhf3cdfORKuuN failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:32:37',2),
(53,2,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_f113fshhf3cdfORKuuN:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_f113fshhf3cdfORKuuN:15: zone_include_1.db: file not found\n/tmp/zone_f113fshhf3cdfORKuuN:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_f113fshhf3cdfORKuuN failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:32:37',2),
(54,3,'failed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\n/tmp/zone_f113fshhf3cdfORKuuN:13: ns1.zone\\032de\\032test: bad owner name (check-names)\ndns_master_load: /tmp/zone_f113fshhf3cdfORKuuN:15: zone_include_1.db: file not found\n/tmp/zone_f113fshhf3cdfORKuuN:18: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loading from master file /tmp/zone_f113fshhf3cdfORKuuN failed: file not found\nzone zone\\032de\\032test/IN: not loaded due to errors.','2025-10-22 10:32:37',2),
(55,1,'pending','Validation queued for background processing','2025-10-22 11:16:20',2),
(56,1,'passed','zone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:16:26',2),
(57,2,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:16:26',2),
(58,3,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: NOM_TEST.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:16:26',2),
(59,1,'pending','Validation queued for background processing','2025-10-22 11:19:54',2),
(60,1,'passed','zone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:20:03',2),
(61,2,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:20:03',2),
(62,3,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:20:03',2),
(63,1,'pending','Validation queued for background processing','2025-10-22 11:31:11',2),
(64,1,'passed','zone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:31:17',2),
(65,2,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:31:17',2),
(66,3,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK','2025-10-22 11:31:17',2),
(67,1,'pending','Validation queued for background processing','2025-10-22 12:06:15',2),
(68,1,'passed','zone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:06:26',2),
(69,2,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:06:26',2),
(70,3,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:06:26',2),
(71,6,'pending','Validation queued for background processing','2025-10-22 12:07:30',2),
(72,6,'passed','zone Z4/IN: loaded serial 2025102201\nOK','2025-10-22 12:07:35',2),
(73,1,'pending','Validation queued for background processing','2025-10-22 12:08:18',2),
(74,1,'passed','zone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:08:36',2),
(75,2,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:08:36',2),
(76,3,'passed','Validation performed on parent zone \'zone de test\' (ID: 1):\n\nzone_1.db:13: ns1.zone\\032de\\032test: bad owner name (check-names)\nzone_1.db:21: nomtest.zone\\032de\\032test: bad owner name (check-names)\nzone zone\\032de\\032test/IN: loaded serial 2025102201\nOK\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: zone_1.db, Line: 13\nMessage: ns1.zone\\032de\\032test: bad owner name (check-names)\n    11: \n    12: ; ----- Enregistrements A -----\n>   13: ns1 IN  A   192.168.1.10\n    14: ; BEGIN INCLUDE: zone_include_1.db\n    15: ; BEGIN INCLUDE: sous_zone_1.db\n\n---\n\nFile: zone_1.db, Line: 21\nMessage: nomtest.zone\\032de\\032test: bad owner name (check-names)\n    19: \n    20: ; DNS Records\n>   21: nomtest                          3600 IN A      192.168.1.100\n\n=== END OF EXTRACTED LINES ===','2025-10-22 12:08:36',2),
(77,1,'pending','Validation queued for background processing','2025-10-22 12:59:09',2),
(78,9,'pending','Validation queued for background processing','2025-10-22 12:59:24',2),
(79,9,'pending','Validation queued for background processing','2025-10-22 12:59:33',2),
(80,1,'passed','zone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 12:59:40',2),
(81,2,'passed','Validation performed on parent zone \'zonedetest\' (ID: 1):\n\nzone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 12:59:40',2),
(82,3,'passed','Validation performed on parent zone \'zonedetest\' (ID: 1):\n\nzone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 12:59:40',2),
(83,9,'failed','zone dgdfg\\032dfgdfg/IN: has 0 SOA records\nzone dgdfg\\032dfgdfg/IN: has no NS records\nzone dgdfg\\032dfgdfg/IN: not loaded due to errors.','2025-10-22 12:59:40',2),
(84,9,'failed','zone dgdfg\\032dfgdfg/IN: has 0 SOA records\nzone dgdfg\\032dfgdfg/IN: has no NS records\nzone dgdfg\\032dfgdfg/IN: not loaded due to errors.','2025-10-22 12:59:40',2),
(85,1,'pending','Validation queued for background processing','2025-10-22 13:01:03',2),
(86,1,'passed','zone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 13:01:09',2),
(87,2,'passed','Validation performed on parent zone \'zonedetest\' (ID: 1):\n\nzone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 13:01:09',2),
(88,3,'passed','Validation performed on parent zone \'zonedetest\' (ID: 1):\n\nzone zonedetest/IN: loaded serial 2025102201\nOK','2025-10-22 13:01:09',2),
(89,4,'failed','Include file has no master parent; cannot validate standalone','2025-10-22 13:01:44',2);
/*!40000 ALTER TABLE `zone_file_validation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `zone_files`
--

DROP TABLE IF EXISTS `zone_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Zone name (e.g., example.com)',
  `filename` varchar(255) NOT NULL COMMENT 'Zone file name',
  `directory` varchar(255) DEFAULT NULL COMMENT 'Directory path for zone file',
  `content` text DEFAULT NULL COMMENT 'Zone file content',
  `file_type` enum('master','include') NOT NULL DEFAULT 'master' COMMENT 'Type of zone file',
  `status` enum('active','inactive','deleted') DEFAULT 'active' COMMENT 'Zone status',
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_name` (`name`),
  KEY `idx_file_type` (`file_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_zone_type_status_name` (`file_type`,`status`,`name`(100)),
  KEY `idx_directory` (`directory`),
  CONSTRAINT `zone_files_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `zone_files_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(10,'test-zone-1.local','db.test-zone-1.local',NULL,'; Zone de test 1\n$TTL 3600\n@ IN SOA ns1.test-zone-1.local. admin.test-zone-1.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.2\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(11,'test-zone-2.local','db.test-zone-2.local',NULL,'; Zone de test 2\n$TTL 3600\n@ IN SOA ns1.test-zone-2.local. admin.test-zone-2.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.3\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(12,'test-zone-3.local','db.test-zone-3.local',NULL,'; Zone de test 3\n$TTL 3600\n@ IN SOA ns1.test-zone-3.local. admin.test-zone-3.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.4\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(13,'test-zone-4.local','db.test-zone-4.local',NULL,'; Zone de test 4\n$TTL 3600\n@ IN SOA ns1.test-zone-4.local. admin.test-zone-4.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(14,'test-zone-5.local','db.test-zone-5.local',NULL,'; Zone de test 5\n$TTL 3600\n@ IN SOA ns1.test-zone-5.local. admin.test-zone-5.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.6\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(15,'test-zone-6.local','db.test-zone-6.local',NULL,'; Zone de test 6\n$TTL 3600\n@ IN SOA ns1.test-zone-6.local. admin.test-zone-6.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.7\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(16,'test-zone-7.local','db.test-zone-7.local',NULL,'; Zone de test 7\n$TTL 3600\n@ IN SOA ns1.test-zone-7.local. admin.test-zone-7.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(17,'test-zone-8.local','db.test-zone-8.local',NULL,'; Zone de test 8\n$TTL 3600\n@ IN SOA ns1.test-zone-8.local. admin.test-zone-8.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.9\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(18,'test-zone-9.local','db.test-zone-9.local',NULL,'; Zone de test 9\n$TTL 3600\n@ IN SOA ns1.test-zone-9.local. admin.test-zone-9.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.10\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(19,'test-zone-10.local','db.test-zone-10.local',NULL,'; Zone de test 10\n$TTL 3600\n@ IN SOA ns1.test-zone-10.local. admin.test-zone-10.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.11\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(20,'test-zone-11.local','db.test-zone-11.local',NULL,'; Zone de test 11\n$TTL 3600\n@ IN SOA ns1.test-zone-11.local. admin.test-zone-11.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.12\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(21,'test-zone-12.local','db.test-zone-12.local',NULL,'; Zone de test 12\n$TTL 3600\n@ IN SOA ns1.test-zone-12.local. admin.test-zone-12.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.13\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(22,'test-zone-13.local','db.test-zone-13.local',NULL,'; Zone de test 13\n$TTL 3600\n@ IN SOA ns1.test-zone-13.local. admin.test-zone-13.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.14\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(23,'test-zone-14.local','db.test-zone-14.local',NULL,'; Zone de test 14\n$TTL 3600\n@ IN SOA ns1.test-zone-14.local. admin.test-zone-14.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(24,'test-zone-15.local','db.test-zone-15.local',NULL,'; Zone de test 15\n$TTL 3600\n@ IN SOA ns1.test-zone-15.local. admin.test-zone-15.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(25,'test-zone-16.local','db.test-zone-16.local',NULL,'; Zone de test 16\n$TTL 3600\n@ IN SOA ns1.test-zone-16.local. admin.test-zone-16.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(26,'test-zone-17.local','db.test-zone-17.local',NULL,'; Zone de test 17\n$TTL 3600\n@ IN SOA ns1.test-zone-17.local. admin.test-zone-17.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(27,'test-zone-18.local','db.test-zone-18.local',NULL,'; Zone de test 18\n$TTL 3600\n@ IN SOA ns1.test-zone-18.local. admin.test-zone-18.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(28,'test-zone-19.local','db.test-zone-19.local',NULL,'; Zone de test 19\n$TTL 3600\n@ IN SOA ns1.test-zone-19.local. admin.test-zone-19.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.20\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(29,'test-zone-20.local','db.test-zone-20.local',NULL,'; Zone de test 20\n$TTL 3600\n@ IN SOA ns1.test-zone-20.local. admin.test-zone-20.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.21\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(30,'test-zone-21.local','db.test-zone-21.local',NULL,'; Zone de test 21\n$TTL 3600\n@ IN SOA ns1.test-zone-21.local. admin.test-zone-21.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.22\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(31,'test-zone-22.local','db.test-zone-22.local',NULL,'; Zone de test 22\n$TTL 3600\n@ IN SOA ns1.test-zone-22.local. admin.test-zone-22.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.23\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(32,'test-zone-23.local','db.test-zone-23.local',NULL,'; Zone de test 23\n$TTL 3600\n@ IN SOA ns1.test-zone-23.local. admin.test-zone-23.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.24\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(33,'test-zone-24.local','db.test-zone-24.local',NULL,'; Zone de test 24\n$TTL 3600\n@ IN SOA ns1.test-zone-24.local. admin.test-zone-24.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.25\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(34,'test-zone-25.local','db.test-zone-25.local',NULL,'; Zone de test 25\n$TTL 3600\n@ IN SOA ns1.test-zone-25.local. admin.test-zone-25.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(35,'test-zone-26.local','db.test-zone-26.local',NULL,'; Zone de test 26\n$TTL 3600\n@ IN SOA ns1.test-zone-26.local. admin.test-zone-26.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.27\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(36,'test-zone-27.local','db.test-zone-27.local',NULL,'; Zone de test 27\n$TTL 3600\n@ IN SOA ns1.test-zone-27.local. admin.test-zone-27.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.28\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(37,'test-zone-28.local','db.test-zone-28.local',NULL,'; Zone de test 28\n$TTL 3600\n@ IN SOA ns1.test-zone-28.local. admin.test-zone-28.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.29\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(38,'test-zone-29.local','db.test-zone-29.local',NULL,'; Zone de test 29\n$TTL 3600\n@ IN SOA ns1.test-zone-29.local. admin.test-zone-29.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(39,'test-zone-30.local','db.test-zone-30.local',NULL,'; Zone de test 30\n$TTL 3600\n@ IN SOA ns1.test-zone-30.local. admin.test-zone-30.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.31\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(40,'test-zone-31.local','db.test-zone-31.local',NULL,'; Zone de test 31\n$TTL 3600\n@ IN SOA ns1.test-zone-31.local. admin.test-zone-31.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.32\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(41,'test-zone-32.local','db.test-zone-32.local',NULL,'; Zone de test 32\n$TTL 3600\n@ IN SOA ns1.test-zone-32.local. admin.test-zone-32.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(42,'test-zone-33.local','db.test-zone-33.local',NULL,'; Zone de test 33\n$TTL 3600\n@ IN SOA ns1.test-zone-33.local. admin.test-zone-33.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.34\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(43,'test-zone-34.local','db.test-zone-34.local',NULL,'; Zone de test 34\n$TTL 3600\n@ IN SOA ns1.test-zone-34.local. admin.test-zone-34.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(44,'test-zone-35.local','db.test-zone-35.local',NULL,'; Zone de test 35\n$TTL 3600\n@ IN SOA ns1.test-zone-35.local. admin.test-zone-35.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.36\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(45,'test-zone-36.local','db.test-zone-36.local',NULL,'; Zone de test 36\n$TTL 3600\n@ IN SOA ns1.test-zone-36.local. admin.test-zone-36.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(46,'test-zone-37.local','db.test-zone-37.local',NULL,'; Zone de test 37\n$TTL 3600\n@ IN SOA ns1.test-zone-37.local. admin.test-zone-37.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.38\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(47,'test-zone-38.local','db.test-zone-38.local',NULL,'; Zone de test 38\n$TTL 3600\n@ IN SOA ns1.test-zone-38.local. admin.test-zone-38.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(48,'test-zone-39.local','db.test-zone-39.local',NULL,'; Zone de test 39\n$TTL 3600\n@ IN SOA ns1.test-zone-39.local. admin.test-zone-39.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(49,'test-zone-40.local','db.test-zone-40.local',NULL,'; Zone de test 40\n$TTL 3600\n@ IN SOA ns1.test-zone-40.local. admin.test-zone-40.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.41\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(50,'test-zone-41.local','db.test-zone-41.local',NULL,'; Zone de test 41\n$TTL 3600\n@ IN SOA ns1.test-zone-41.local. admin.test-zone-41.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.42\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(51,'test-zone-42.local','db.test-zone-42.local',NULL,'; Zone de test 42\n$TTL 3600\n@ IN SOA ns1.test-zone-42.local. admin.test-zone-42.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.43\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(52,'test-zone-43.local','db.test-zone-43.local',NULL,'; Zone de test 43\n$TTL 3600\n@ IN SOA ns1.test-zone-43.local. admin.test-zone-43.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.44\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(53,'test-zone-44.local','db.test-zone-44.local',NULL,'; Zone de test 44\n$TTL 3600\n@ IN SOA ns1.test-zone-44.local. admin.test-zone-44.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.45\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(54,'test-zone-45.local','db.test-zone-45.local',NULL,'; Zone de test 45\n$TTL 3600\n@ IN SOA ns1.test-zone-45.local. admin.test-zone-45.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.46\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(55,'test-zone-46.local','db.test-zone-46.local',NULL,'; Zone de test 46\n$TTL 3600\n@ IN SOA ns1.test-zone-46.local. admin.test-zone-46.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.47\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(56,'test-zone-47.local','db.test-zone-47.local',NULL,'; Zone de test 47\n$TTL 3600\n@ IN SOA ns1.test-zone-47.local. admin.test-zone-47.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.48\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(57,'test-zone-48.local','db.test-zone-48.local',NULL,'; Zone de test 48\n$TTL 3600\n@ IN SOA ns1.test-zone-48.local. admin.test-zone-48.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.49\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(58,'test-zone-49.local','db.test-zone-49.local',NULL,'; Zone de test 49\n$TTL 3600\n@ IN SOA ns1.test-zone-49.local. admin.test-zone-49.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.50\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18'),
(59,'test-zone-50.local','db.test-zone-50.local',NULL,'; Zone de test 50\n$TTL 3600\n@ IN SOA ns1.test-zone-50.local. admin.test-zone-50.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2.51\n','master','active',1,NULL,'2025-10-23 06:54:18','2025-10-23 06:54:18');
/*!40000 ALTER TABLE `zone_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'dns3_db'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-23 11:26:58
