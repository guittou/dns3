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
) ENGINE=InnoDB AUTO_INCREMENT=1006 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(6,100,'PTR','ptr1','ptr1.in-addr.arpa.',NULL,NULL,NULL,'ptr1.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:21',NULL,'2025-10-23 07:27:21',NULL,NULL,NULL,NULL),
(7,69,'A','host2','198.51.160.192','198.51.160.192',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:21',NULL,'2025-10-23 07:27:21',NULL,NULL,NULL,NULL),
(8,106,'A','host3','198.51.48.83','198.51.48.83',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(9,104,'CNAME','cname4','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(10,80,'A','host5','198.51.135.35','198.51.135.35',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(11,79,'CNAME','cname6','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(12,68,'TXT','txt7','test-txt-7',NULL,NULL,NULL,NULL,'test-txt-7',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(13,78,'CNAME','cname8','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(14,92,'AAAA','host9','2001:db8::2064',NULL,'2001:db8::2064',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(15,101,'A','host10','198.51.55.67','198.51.55.67',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(16,101,'A','host11','198.51.204.144','198.51.204.144',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(17,60,'TXT','txt12','test-txt-12',NULL,NULL,NULL,NULL,'test-txt-12',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(18,97,'PTR','ptr13','ptr13.in-addr.arpa.',NULL,NULL,NULL,'ptr13.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(19,63,'CNAME','cname14','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(20,107,'A','host15','198.51.4.23','198.51.4.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(21,93,'A','host16','198.51.71.55','198.51.71.55',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(22,75,'CNAME','cname17','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(23,104,'AAAA','host18','2001:db8::df4e',NULL,'2001:db8::df4e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(24,79,'PTR','ptr19','ptr19.in-addr.arpa.',NULL,NULL,NULL,'ptr19.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(25,81,'PTR','ptr20','ptr20.in-addr.arpa.',NULL,NULL,NULL,'ptr20.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(26,87,'PTR','ptr21','ptr21.in-addr.arpa.',NULL,NULL,NULL,'ptr21.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(27,105,'PTR','ptr22','ptr22.in-addr.arpa.',NULL,NULL,NULL,'ptr22.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(28,101,'A','host23','198.51.183.159','198.51.183.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(29,100,'AAAA','host24','2001:db8::2d92',NULL,'2001:db8::2d92',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(30,107,'A','host25','198.51.114.235','198.51.114.235',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(31,106,'PTR','ptr26','ptr26.in-addr.arpa.',NULL,NULL,NULL,'ptr26.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(32,76,'CNAME','cname27','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(33,78,'TXT','txt28','test-txt-28',NULL,NULL,NULL,NULL,'test-txt-28',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(34,104,'A','host29','198.51.60.105','198.51.60.105',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(35,109,'A','host30','198.51.38.16','198.51.38.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(36,82,'AAAA','host31','2001:db8::ec2d',NULL,'2001:db8::ec2d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(37,78,'TXT','txt32','test-txt-32',NULL,NULL,NULL,NULL,'test-txt-32',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(38,76,'AAAA','host33','2001:db8::6945',NULL,'2001:db8::6945',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(39,66,'TXT','txt34','test-txt-34',NULL,NULL,NULL,NULL,'test-txt-34',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(40,109,'A','host35','198.51.174.240','198.51.174.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(41,79,'A','host36','198.51.113.47','198.51.113.47',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(42,104,'AAAA','host37','2001:db8::19bc',NULL,'2001:db8::19bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(43,60,'A','host38','198.51.228.64','198.51.228.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(44,103,'AAAA','host39','2001:db8::8099',NULL,'2001:db8::8099',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(45,80,'A','host40','198.51.198.144','198.51.198.144',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(46,85,'TXT','txt41','test-txt-41',NULL,NULL,NULL,NULL,'test-txt-41',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(47,107,'CNAME','cname42','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(48,105,'TXT','txt43','test-txt-43',NULL,NULL,NULL,NULL,'test-txt-43',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(49,103,'A','host44','198.51.121.88','198.51.121.88',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(50,66,'TXT','txt45','test-txt-45',NULL,NULL,NULL,NULL,'test-txt-45',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(51,74,'A','host46','198.51.188.160','198.51.188.160',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(52,98,'PTR','ptr47','ptr47.in-addr.arpa.',NULL,NULL,NULL,'ptr47.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(53,106,'AAAA','host48','2001:db8::f67b',NULL,'2001:db8::f67b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(54,60,'PTR','ptr49','ptr49.in-addr.arpa.',NULL,NULL,NULL,'ptr49.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(55,99,'AAAA','host50','2001:db8::2389',NULL,'2001:db8::2389',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(56,95,'A','host51','198.51.52.182','198.51.52.182',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(57,101,'TXT','txt52','test-txt-52',NULL,NULL,NULL,NULL,'test-txt-52',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(58,98,'CNAME','cname53','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(59,87,'AAAA','host54','2001:db8::d466',NULL,'2001:db8::d466',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(60,67,'TXT','txt55','test-txt-55',NULL,NULL,NULL,NULL,'test-txt-55',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(61,109,'AAAA','host56','2001:db8::f8ee',NULL,'2001:db8::f8ee',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(62,82,'AAAA','host57','2001:db8::3c2f',NULL,'2001:db8::3c2f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(63,90,'AAAA','host58','2001:db8::d6da',NULL,'2001:db8::d6da',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(64,109,'PTR','ptr59','ptr59.in-addr.arpa.',NULL,NULL,NULL,'ptr59.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(65,90,'A','host60','198.51.183.218','198.51.183.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(66,76,'CNAME','cname61','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(67,61,'PTR','ptr62','ptr62.in-addr.arpa.',NULL,NULL,NULL,'ptr62.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(68,83,'A','host63','198.51.178.159','198.51.178.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(69,107,'CNAME','cname64','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(70,90,'TXT','txt65','test-txt-65',NULL,NULL,NULL,NULL,'test-txt-65',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(71,107,'A','host66','198.51.97.185','198.51.97.185',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(72,88,'A','host67','198.51.57.178','198.51.57.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(73,70,'PTR','ptr68','ptr68.in-addr.arpa.',NULL,NULL,NULL,'ptr68.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(74,105,'PTR','ptr69','ptr69.in-addr.arpa.',NULL,NULL,NULL,'ptr69.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(75,68,'TXT','txt70','test-txt-70',NULL,NULL,NULL,NULL,'test-txt-70',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(76,86,'TXT','txt71','test-txt-71',NULL,NULL,NULL,NULL,'test-txt-71',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(77,96,'TXT','txt72','test-txt-72',NULL,NULL,NULL,NULL,'test-txt-72',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(78,93,'PTR','ptr73','ptr73.in-addr.arpa.',NULL,NULL,NULL,'ptr73.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(79,68,'TXT','txt74','test-txt-74',NULL,NULL,NULL,NULL,'test-txt-74',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(80,64,'CNAME','cname75','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(81,93,'PTR','ptr76','ptr76.in-addr.arpa.',NULL,NULL,NULL,'ptr76.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(82,87,'CNAME','cname77','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(83,69,'AAAA','host78','2001:db8::74e0',NULL,'2001:db8::74e0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(84,71,'PTR','ptr79','ptr79.in-addr.arpa.',NULL,NULL,NULL,'ptr79.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(85,109,'CNAME','cname80','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(86,107,'AAAA','host81','2001:db8::8240',NULL,'2001:db8::8240',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(87,108,'A','host82','198.51.42.217','198.51.42.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(88,90,'PTR','ptr83','ptr83.in-addr.arpa.',NULL,NULL,NULL,'ptr83.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(89,91,'AAAA','host84','2001:db8::832b',NULL,'2001:db8::832b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(90,100,'AAAA','host85','2001:db8::d85f',NULL,'2001:db8::d85f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(91,108,'CNAME','cname86','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(92,103,'TXT','txt87','test-txt-87',NULL,NULL,NULL,NULL,'test-txt-87',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(93,105,'PTR','ptr88','ptr88.in-addr.arpa.',NULL,NULL,NULL,'ptr88.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(94,78,'PTR','ptr89','ptr89.in-addr.arpa.',NULL,NULL,NULL,'ptr89.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(95,88,'A','host90','198.51.201.209','198.51.201.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(96,95,'TXT','txt91','test-txt-91',NULL,NULL,NULL,NULL,'test-txt-91',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(97,103,'TXT','txt92','test-txt-92',NULL,NULL,NULL,NULL,'test-txt-92',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(98,75,'TXT','txt93','test-txt-93',NULL,NULL,NULL,NULL,'test-txt-93',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(99,90,'AAAA','host94','2001:db8::40f',NULL,'2001:db8::40f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(100,80,'PTR','ptr95','ptr95.in-addr.arpa.',NULL,NULL,NULL,'ptr95.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(101,107,'AAAA','host96','2001:db8::9a4a',NULL,'2001:db8::9a4a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(102,65,'A','host97','198.51.117.154','198.51.117.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(103,108,'AAAA','host98','2001:db8::bfdb',NULL,'2001:db8::bfdb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(104,95,'PTR','ptr99','ptr99.in-addr.arpa.',NULL,NULL,NULL,'ptr99.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(105,86,'A','host100','198.51.8.200','198.51.8.200',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(106,107,'CNAME','cname101','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(107,70,'PTR','ptr102','ptr102.in-addr.arpa.',NULL,NULL,NULL,'ptr102.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(108,97,'PTR','ptr103','ptr103.in-addr.arpa.',NULL,NULL,NULL,'ptr103.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(109,66,'AAAA','host104','2001:db8::447c',NULL,'2001:db8::447c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(110,61,'CNAME','cname105','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(111,77,'PTR','ptr106','ptr106.in-addr.arpa.',NULL,NULL,NULL,'ptr106.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(112,108,'TXT','txt107','test-txt-107',NULL,NULL,NULL,NULL,'test-txt-107',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(113,63,'CNAME','cname108','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(114,64,'CNAME','cname109','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(115,96,'TXT','txt110','test-txt-110',NULL,NULL,NULL,NULL,'test-txt-110',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(116,102,'PTR','ptr111','ptr111.in-addr.arpa.',NULL,NULL,NULL,'ptr111.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(117,95,'PTR','ptr112','ptr112.in-addr.arpa.',NULL,NULL,NULL,'ptr112.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(118,67,'AAAA','host113','2001:db8::25af',NULL,'2001:db8::25af',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(119,93,'TXT','txt114','test-txt-114',NULL,NULL,NULL,NULL,'test-txt-114',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(120,100,'CNAME','cname115','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(121,101,'TXT','txt116','test-txt-116',NULL,NULL,NULL,NULL,'test-txt-116',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(122,99,'A','host117','198.51.129.237','198.51.129.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(123,89,'A','host118','198.51.98.75','198.51.98.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(124,84,'CNAME','cname119','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(125,61,'AAAA','host120','2001:db8::93aa',NULL,'2001:db8::93aa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(126,94,'AAAA','host121','2001:db8::a81e',NULL,'2001:db8::a81e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(127,106,'PTR','ptr122','ptr122.in-addr.arpa.',NULL,NULL,NULL,'ptr122.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(128,88,'TXT','txt123','test-txt-123',NULL,NULL,NULL,NULL,'test-txt-123',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(129,83,'CNAME','cname124','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(130,77,'A','host125','198.51.80.204','198.51.80.204',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(131,106,'PTR','ptr126','ptr126.in-addr.arpa.',NULL,NULL,NULL,'ptr126.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(132,103,'TXT','txt127','test-txt-127',NULL,NULL,NULL,NULL,'test-txt-127',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(133,77,'TXT','txt128','test-txt-128',NULL,NULL,NULL,NULL,'test-txt-128',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(134,96,'AAAA','host129','2001:db8::8c5f',NULL,'2001:db8::8c5f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(135,101,'PTR','ptr130','ptr130.in-addr.arpa.',NULL,NULL,NULL,'ptr130.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(136,82,'TXT','txt131','test-txt-131',NULL,NULL,NULL,NULL,'test-txt-131',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(137,66,'TXT','txt132','test-txt-132',NULL,NULL,NULL,NULL,'test-txt-132',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(138,96,'CNAME','cname133','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(139,93,'CNAME','cname134','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(140,67,'CNAME','cname135','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(141,88,'CNAME','cname136','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(142,69,'AAAA','host137','2001:db8::dc5f',NULL,'2001:db8::dc5f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(143,103,'AAAA','host138','2001:db8::bc48',NULL,'2001:db8::bc48',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(144,84,'A','host139','198.51.57.106','198.51.57.106',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(145,63,'AAAA','host140','2001:db8::2be5',NULL,'2001:db8::2be5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(146,84,'TXT','txt141','test-txt-141',NULL,NULL,NULL,NULL,'test-txt-141',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(147,108,'TXT','txt142','test-txt-142',NULL,NULL,NULL,NULL,'test-txt-142',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(148,78,'A','host143','198.51.154.126','198.51.154.126',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(149,82,'PTR','ptr144','ptr144.in-addr.arpa.',NULL,NULL,NULL,'ptr144.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(150,82,'TXT','txt145','test-txt-145',NULL,NULL,NULL,NULL,'test-txt-145',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(151,89,'CNAME','cname146','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(152,107,'TXT','txt147','test-txt-147',NULL,NULL,NULL,NULL,'test-txt-147',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(153,73,'AAAA','host148','2001:db8::6dc0',NULL,'2001:db8::6dc0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(154,102,'PTR','ptr149','ptr149.in-addr.arpa.',NULL,NULL,NULL,'ptr149.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(155,88,'CNAME','cname150','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(156,91,'PTR','ptr151','ptr151.in-addr.arpa.',NULL,NULL,NULL,'ptr151.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(157,63,'A','host152','198.51.203.205','198.51.203.205',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(158,109,'CNAME','cname153','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(159,108,'A','host154','198.51.227.1','198.51.227.1',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(160,65,'TXT','txt155','test-txt-155',NULL,NULL,NULL,NULL,'test-txt-155',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(161,85,'TXT','txt156','test-txt-156',NULL,NULL,NULL,NULL,'test-txt-156',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(162,102,'TXT','txt157','test-txt-157',NULL,NULL,NULL,NULL,'test-txt-157',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(163,68,'AAAA','host158','2001:db8::8f61',NULL,'2001:db8::8f61',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(164,88,'AAAA','host159','2001:db8::6478',NULL,'2001:db8::6478',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(165,73,'CNAME','cname160','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(166,65,'A','host161','198.51.109.52','198.51.109.52',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(167,108,'AAAA','host162','2001:db8::a89c',NULL,'2001:db8::a89c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(168,88,'AAAA','host163','2001:db8::d5cd',NULL,'2001:db8::d5cd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(169,86,'PTR','ptr164','ptr164.in-addr.arpa.',NULL,NULL,NULL,'ptr164.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(170,108,'AAAA','host165','2001:db8::13c2',NULL,'2001:db8::13c2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(171,61,'PTR','ptr166','ptr166.in-addr.arpa.',NULL,NULL,NULL,'ptr166.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(172,91,'AAAA','host167','2001:db8::a02',NULL,'2001:db8::a02',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(173,79,'AAAA','host168','2001:db8::bd52',NULL,'2001:db8::bd52',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(174,75,'AAAA','host169','2001:db8::2500',NULL,'2001:db8::2500',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(175,84,'TXT','txt170','test-txt-170',NULL,NULL,NULL,NULL,'test-txt-170',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(176,60,'TXT','txt171','test-txt-171',NULL,NULL,NULL,NULL,'test-txt-171',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(177,91,'TXT','txt172','test-txt-172',NULL,NULL,NULL,NULL,'test-txt-172',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(178,64,'TXT','txt173','test-txt-173',NULL,NULL,NULL,NULL,'test-txt-173',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(179,96,'TXT','txt174','test-txt-174',NULL,NULL,NULL,NULL,'test-txt-174',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(180,98,'CNAME','cname175','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(181,96,'PTR','ptr176','ptr176.in-addr.arpa.',NULL,NULL,NULL,'ptr176.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(182,108,'TXT','txt177','test-txt-177',NULL,NULL,NULL,NULL,'test-txt-177',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(183,97,'TXT','txt178','test-txt-178',NULL,NULL,NULL,NULL,'test-txt-178',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(184,74,'AAAA','host179','2001:db8::8100',NULL,'2001:db8::8100',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(185,109,'CNAME','cname180','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(186,102,'A','host181','198.51.112.155','198.51.112.155',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(187,66,'A','host182','198.51.213.190','198.51.213.190',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(188,108,'A','host183','198.51.230.75','198.51.230.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(189,73,'CNAME','cname184','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(190,102,'PTR','ptr185','ptr185.in-addr.arpa.',NULL,NULL,NULL,'ptr185.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(191,73,'PTR','ptr186','ptr186.in-addr.arpa.',NULL,NULL,NULL,'ptr186.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(192,107,'PTR','ptr187','ptr187.in-addr.arpa.',NULL,NULL,NULL,'ptr187.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(193,87,'CNAME','cname188','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(194,90,'TXT','txt189','test-txt-189',NULL,NULL,NULL,NULL,'test-txt-189',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(195,92,'A','host190','198.51.168.40','198.51.168.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(196,93,'PTR','ptr191','ptr191.in-addr.arpa.',NULL,NULL,NULL,'ptr191.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(197,100,'A','host192','198.51.215.165','198.51.215.165',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(198,104,'AAAA','host193','2001:db8::44a1',NULL,'2001:db8::44a1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(199,72,'AAAA','host194','2001:db8::bcfc',NULL,'2001:db8::bcfc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(200,90,'TXT','txt195','test-txt-195',NULL,NULL,NULL,NULL,'test-txt-195',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(201,78,'PTR','ptr196','ptr196.in-addr.arpa.',NULL,NULL,NULL,'ptr196.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(202,102,'TXT','txt197','test-txt-197',NULL,NULL,NULL,NULL,'test-txt-197',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(203,90,'A','host198','198.51.52.138','198.51.52.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(204,62,'PTR','ptr199','ptr199.in-addr.arpa.',NULL,NULL,NULL,'ptr199.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(205,100,'AAAA','host200','2001:db8::c512',NULL,'2001:db8::c512',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(206,104,'TXT','txt201','test-txt-201',NULL,NULL,NULL,NULL,'test-txt-201',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(207,79,'A','host202','198.51.72.5','198.51.72.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(208,98,'A','host203','198.51.115.233','198.51.115.233',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(209,60,'A','host204','198.51.175.138','198.51.175.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(210,79,'A','host205','198.51.225.58','198.51.225.58',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(211,104,'TXT','txt206','test-txt-206',NULL,NULL,NULL,NULL,'test-txt-206',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(212,82,'AAAA','host207','2001:db8::aa1b',NULL,'2001:db8::aa1b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(213,94,'A','host208','198.51.188.153','198.51.188.153',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(214,89,'CNAME','cname209','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(215,70,'AAAA','host210','2001:db8::9da2',NULL,'2001:db8::9da2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(216,69,'CNAME','cname211','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(217,82,'CNAME','cname212','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(218,103,'TXT','txt213','test-txt-213',NULL,NULL,NULL,NULL,'test-txt-213',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(219,96,'PTR','ptr214','ptr214.in-addr.arpa.',NULL,NULL,NULL,'ptr214.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(220,109,'A','host215','198.51.36.157','198.51.36.157',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(221,87,'TXT','txt216','test-txt-216',NULL,NULL,NULL,NULL,'test-txt-216',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(222,81,'A','host217','198.51.253.181','198.51.253.181',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(223,101,'A','host218','198.51.81.16','198.51.81.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(224,75,'PTR','ptr219','ptr219.in-addr.arpa.',NULL,NULL,NULL,'ptr219.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(225,106,'AAAA','host220','2001:db8::7f8',NULL,'2001:db8::7f8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(226,107,'CNAME','cname221','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(227,95,'TXT','txt222','test-txt-222',NULL,NULL,NULL,NULL,'test-txt-222',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(228,67,'CNAME','cname223','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(229,88,'AAAA','host224','2001:db8::33b9',NULL,'2001:db8::33b9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(230,94,'TXT','txt225','test-txt-225',NULL,NULL,NULL,NULL,'test-txt-225',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(231,94,'TXT','txt226','test-txt-226',NULL,NULL,NULL,NULL,'test-txt-226',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(232,108,'CNAME','cname227','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(233,88,'CNAME','cname228','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(234,99,'PTR','ptr229','ptr229.in-addr.arpa.',NULL,NULL,NULL,'ptr229.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(235,90,'CNAME','cname230','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(236,100,'PTR','ptr231','ptr231.in-addr.arpa.',NULL,NULL,NULL,'ptr231.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(237,74,'A','host232','198.51.92.115','198.51.92.115',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(238,68,'A','host233','198.51.190.44','198.51.190.44',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(239,101,'PTR','ptr234','ptr234.in-addr.arpa.',NULL,NULL,NULL,'ptr234.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(240,91,'PTR','ptr235','ptr235.in-addr.arpa.',NULL,NULL,NULL,'ptr235.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(241,77,'A','host236','198.51.214.215','198.51.214.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(242,84,'PTR','ptr237','ptr237.in-addr.arpa.',NULL,NULL,NULL,'ptr237.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(243,68,'CNAME','cname238','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(244,83,'CNAME','cname239','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(245,85,'PTR','ptr240','ptr240.in-addr.arpa.',NULL,NULL,NULL,'ptr240.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(246,89,'PTR','ptr241','ptr241.in-addr.arpa.',NULL,NULL,NULL,'ptr241.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(247,83,'PTR','ptr242','ptr242.in-addr.arpa.',NULL,NULL,NULL,'ptr242.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(248,70,'TXT','txt243','test-txt-243',NULL,NULL,NULL,NULL,'test-txt-243',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(249,91,'CNAME','cname244','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(250,100,'AAAA','host245','2001:db8::9920',NULL,'2001:db8::9920',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(251,69,'PTR','ptr246','ptr246.in-addr.arpa.',NULL,NULL,NULL,'ptr246.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(252,66,'AAAA','host247','2001:db8::e424',NULL,'2001:db8::e424',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(253,62,'AAAA','host248','2001:db8::c136',NULL,'2001:db8::c136',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(254,89,'AAAA','host249','2001:db8::8458',NULL,'2001:db8::8458',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(255,103,'TXT','txt250','test-txt-250',NULL,NULL,NULL,NULL,'test-txt-250',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(256,73,'AAAA','host251','2001:db8::92e3',NULL,'2001:db8::92e3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(257,90,'AAAA','host252','2001:db8::5d99',NULL,'2001:db8::5d99',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(258,91,'TXT','txt253','test-txt-253',NULL,NULL,NULL,NULL,'test-txt-253',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(259,98,'PTR','ptr254','ptr254.in-addr.arpa.',NULL,NULL,NULL,'ptr254.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(260,75,'AAAA','host255','2001:db8::8cc',NULL,'2001:db8::8cc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(261,79,'TXT','txt256','test-txt-256',NULL,NULL,NULL,NULL,'test-txt-256',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(262,95,'TXT','txt257','test-txt-257',NULL,NULL,NULL,NULL,'test-txt-257',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(263,105,'AAAA','host258','2001:db8::f631',NULL,'2001:db8::f631',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(264,96,'CNAME','cname259','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(265,109,'AAAA','host260','2001:db8::ec84',NULL,'2001:db8::ec84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(266,109,'CNAME','cname261','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(267,76,'A','host262','198.51.200.224','198.51.200.224',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(268,99,'A','host263','198.51.76.40','198.51.76.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(269,75,'A','host264','198.51.36.79','198.51.36.79',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(270,109,'TXT','txt265','test-txt-265',NULL,NULL,NULL,NULL,'test-txt-265',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(271,106,'AAAA','host266','2001:db8::cb4b',NULL,'2001:db8::cb4b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(272,109,'AAAA','host267','2001:db8::1f18',NULL,'2001:db8::1f18',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(273,69,'TXT','txt268','test-txt-268',NULL,NULL,NULL,NULL,'test-txt-268',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(274,92,'PTR','ptr269','ptr269.in-addr.arpa.',NULL,NULL,NULL,'ptr269.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(275,87,'CNAME','cname270','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(276,64,'PTR','ptr271','ptr271.in-addr.arpa.',NULL,NULL,NULL,'ptr271.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(277,78,'AAAA','host272','2001:db8::ae1f',NULL,'2001:db8::ae1f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(278,101,'PTR','ptr273','ptr273.in-addr.arpa.',NULL,NULL,NULL,'ptr273.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(279,72,'PTR','ptr274','ptr274.in-addr.arpa.',NULL,NULL,NULL,'ptr274.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(280,80,'A','host275','198.51.44.149','198.51.44.149',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(281,60,'CNAME','cname276','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(282,82,'CNAME','cname277','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(283,96,'AAAA','host278','2001:db8::b97b',NULL,'2001:db8::b97b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(284,72,'AAAA','host279','2001:db8::1c98',NULL,'2001:db8::1c98',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(285,82,'TXT','txt280','test-txt-280',NULL,NULL,NULL,NULL,'test-txt-280',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(286,90,'AAAA','host281','2001:db8::f5a',NULL,'2001:db8::f5a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(287,95,'TXT','txt282','test-txt-282',NULL,NULL,NULL,NULL,'test-txt-282',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(288,107,'CNAME','cname283','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(289,104,'A','host284','198.51.94.216','198.51.94.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(290,106,'TXT','txt285','test-txt-285',NULL,NULL,NULL,NULL,'test-txt-285',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(291,103,'AAAA','host286','2001:db8::cccd',NULL,'2001:db8::cccd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(292,79,'TXT','txt287','test-txt-287',NULL,NULL,NULL,NULL,'test-txt-287',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(293,63,'A','host288','198.51.114.99','198.51.114.99',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(294,72,'TXT','txt289','test-txt-289',NULL,NULL,NULL,NULL,'test-txt-289',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(295,101,'AAAA','host290','2001:db8::6e31',NULL,'2001:db8::6e31',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(296,85,'A','host291','198.51.80.54','198.51.80.54',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(297,79,'PTR','ptr292','ptr292.in-addr.arpa.',NULL,NULL,NULL,'ptr292.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(298,83,'PTR','ptr293','ptr293.in-addr.arpa.',NULL,NULL,NULL,'ptr293.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(299,80,'PTR','ptr294','ptr294.in-addr.arpa.',NULL,NULL,NULL,'ptr294.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(300,101,'TXT','txt295','test-txt-295',NULL,NULL,NULL,NULL,'test-txt-295',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(301,103,'AAAA','host296','2001:db8::4110',NULL,'2001:db8::4110',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(302,77,'PTR','ptr297','ptr297.in-addr.arpa.',NULL,NULL,NULL,'ptr297.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(303,71,'A','host298','198.51.120.165','198.51.120.165',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(304,84,'A','host299','198.51.13.3','198.51.13.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(305,79,'AAAA','host300','2001:db8::4f93',NULL,'2001:db8::4f93',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(306,86,'A','host301','198.51.243.214','198.51.243.214',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(307,104,'CNAME','cname302','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(308,98,'PTR','ptr303','ptr303.in-addr.arpa.',NULL,NULL,NULL,'ptr303.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(309,72,'AAAA','host304','2001:db8::d847',NULL,'2001:db8::d847',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(310,83,'TXT','txt305','test-txt-305',NULL,NULL,NULL,NULL,'test-txt-305',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(311,75,'A','host306','198.51.38.160','198.51.38.160',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(312,74,'CNAME','cname307','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(313,67,'TXT','txt308','test-txt-308',NULL,NULL,NULL,NULL,'test-txt-308',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(314,97,'A','host309','198.51.129.154','198.51.129.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(315,84,'PTR','ptr310','ptr310.in-addr.arpa.',NULL,NULL,NULL,'ptr310.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(316,60,'PTR','ptr311','ptr311.in-addr.arpa.',NULL,NULL,NULL,'ptr311.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(317,89,'CNAME','cname312','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(318,73,'PTR','ptr313','ptr313.in-addr.arpa.',NULL,NULL,NULL,'ptr313.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(319,95,'PTR','ptr314','ptr314.in-addr.arpa.',NULL,NULL,NULL,'ptr314.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(320,95,'TXT','txt315','test-txt-315',NULL,NULL,NULL,NULL,'test-txt-315',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(321,107,'A','host316','198.51.145.39','198.51.145.39',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(322,104,'AAAA','host317','2001:db8::d76e',NULL,'2001:db8::d76e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(323,76,'PTR','ptr318','ptr318.in-addr.arpa.',NULL,NULL,NULL,'ptr318.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(324,75,'A','host319','198.51.75.92','198.51.75.92',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(325,83,'AAAA','host320','2001:db8::8f84',NULL,'2001:db8::8f84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(326,79,'AAAA','host321','2001:db8::1048',NULL,'2001:db8::1048',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(327,100,'A','host322','198.51.92.252','198.51.92.252',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(328,86,'PTR','ptr323','ptr323.in-addr.arpa.',NULL,NULL,NULL,'ptr323.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(329,102,'PTR','ptr324','ptr324.in-addr.arpa.',NULL,NULL,NULL,'ptr324.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(330,87,'A','host325','198.51.41.97','198.51.41.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(331,101,'CNAME','cname326','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(332,107,'CNAME','cname327','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(333,106,'AAAA','host328','2001:db8::61a',NULL,'2001:db8::61a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(334,61,'CNAME','cname329','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(335,94,'AAAA','host330','2001:db8::178a',NULL,'2001:db8::178a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(336,104,'TXT','txt331','test-txt-331',NULL,NULL,NULL,NULL,'test-txt-331',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(337,80,'A','host332','198.51.200.178','198.51.200.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(338,67,'TXT','txt333','test-txt-333',NULL,NULL,NULL,NULL,'test-txt-333',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(339,102,'CNAME','cname334','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(340,82,'PTR','ptr335','ptr335.in-addr.arpa.',NULL,NULL,NULL,'ptr335.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(341,68,'CNAME','cname336','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(342,109,'AAAA','host337','2001:db8::32c2',NULL,'2001:db8::32c2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(343,61,'PTR','ptr338','ptr338.in-addr.arpa.',NULL,NULL,NULL,'ptr338.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(344,66,'PTR','ptr339','ptr339.in-addr.arpa.',NULL,NULL,NULL,'ptr339.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(345,88,'CNAME','cname340','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(346,107,'A','host341','198.51.222.131','198.51.222.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(347,87,'CNAME','cname342','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(348,89,'CNAME','cname343','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(349,67,'PTR','ptr344','ptr344.in-addr.arpa.',NULL,NULL,NULL,'ptr344.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(350,62,'TXT','txt345','test-txt-345',NULL,NULL,NULL,NULL,'test-txt-345',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(351,79,'AAAA','host346','2001:db8::1a51',NULL,'2001:db8::1a51',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(352,77,'TXT','txt347','test-txt-347',NULL,NULL,NULL,NULL,'test-txt-347',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(353,75,'TXT','txt348','test-txt-348',NULL,NULL,NULL,NULL,'test-txt-348',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(354,90,'CNAME','cname349','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(355,85,'CNAME','cname350','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(356,90,'CNAME','cname351','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(357,108,'TXT','txt352','test-txt-352',NULL,NULL,NULL,NULL,'test-txt-352',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(358,83,'CNAME','cname353','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(359,81,'A','host354','198.51.37.162','198.51.37.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(360,75,'CNAME','cname355','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(361,92,'CNAME','cname356','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(362,93,'TXT','txt357','test-txt-357',NULL,NULL,NULL,NULL,'test-txt-357',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(363,96,'A','host358','198.51.144.234','198.51.144.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(364,104,'TXT','txt359','test-txt-359',NULL,NULL,NULL,NULL,'test-txt-359',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(365,95,'CNAME','cname360','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(366,98,'TXT','txt361','test-txt-361',NULL,NULL,NULL,NULL,'test-txt-361',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(367,86,'A','host362','198.51.196.229','198.51.196.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(368,100,'A','host363','198.51.251.172','198.51.251.172',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(369,88,'A','host364','198.51.0.170','198.51.0.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(370,86,'CNAME','cname365','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(371,97,'TXT','txt366','test-txt-366',NULL,NULL,NULL,NULL,'test-txt-366',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(372,84,'CNAME','cname367','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(373,86,'A','host368','198.51.61.73','198.51.61.73',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(374,95,'A','host369','198.51.17.186','198.51.17.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(375,74,'A','host370','198.51.94.28','198.51.94.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(376,83,'A','host371','198.51.97.109','198.51.97.109',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(377,67,'PTR','ptr372','ptr372.in-addr.arpa.',NULL,NULL,NULL,'ptr372.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(378,105,'PTR','ptr373','ptr373.in-addr.arpa.',NULL,NULL,NULL,'ptr373.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(379,63,'A','host374','198.51.188.245','198.51.188.245',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(380,108,'TXT','txt375','test-txt-375',NULL,NULL,NULL,NULL,'test-txt-375',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(381,75,'CNAME','cname376','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(382,88,'AAAA','host377','2001:db8::c4c3',NULL,'2001:db8::c4c3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(383,93,'PTR','ptr378','ptr378.in-addr.arpa.',NULL,NULL,NULL,'ptr378.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(384,81,'TXT','txt379','test-txt-379',NULL,NULL,NULL,NULL,'test-txt-379',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(385,107,'TXT','txt380','test-txt-380',NULL,NULL,NULL,NULL,'test-txt-380',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(386,65,'PTR','ptr381','ptr381.in-addr.arpa.',NULL,NULL,NULL,'ptr381.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(387,82,'AAAA','host382','2001:db8::f9a1',NULL,'2001:db8::f9a1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(388,64,'CNAME','cname383','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(389,88,'AAAA','host384','2001:db8::251c',NULL,'2001:db8::251c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(390,63,'PTR','ptr385','ptr385.in-addr.arpa.',NULL,NULL,NULL,'ptr385.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(391,89,'CNAME','cname386','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(392,80,'PTR','ptr387','ptr387.in-addr.arpa.',NULL,NULL,NULL,'ptr387.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(393,108,'A','host388','198.51.63.195','198.51.63.195',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(394,105,'AAAA','host389','2001:db8::f931',NULL,'2001:db8::f931',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(395,91,'CNAME','cname390','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(396,106,'CNAME','cname391','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(397,99,'AAAA','host392','2001:db8::bec9',NULL,'2001:db8::bec9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(398,73,'AAAA','host393','2001:db8::ab7',NULL,'2001:db8::ab7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(399,106,'PTR','ptr394','ptr394.in-addr.arpa.',NULL,NULL,NULL,'ptr394.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(400,96,'TXT','txt395','test-txt-395',NULL,NULL,NULL,NULL,'test-txt-395',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(401,86,'AAAA','host396','2001:db8::9700',NULL,'2001:db8::9700',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(402,106,'CNAME','cname397','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(403,70,'A','host398','198.51.208.94','198.51.208.94',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(404,63,'AAAA','host399','2001:db8::3329',NULL,'2001:db8::3329',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(405,79,'CNAME','cname400','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(406,93,'TXT','txt401','test-txt-401',NULL,NULL,NULL,NULL,'test-txt-401',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(407,84,'TXT','txt402','test-txt-402',NULL,NULL,NULL,NULL,'test-txt-402',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(408,103,'A','host403','198.51.47.22','198.51.47.22',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(409,108,'A','host404','198.51.19.167','198.51.19.167',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(410,109,'PTR','ptr405','ptr405.in-addr.arpa.',NULL,NULL,NULL,'ptr405.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(411,92,'PTR','ptr406','ptr406.in-addr.arpa.',NULL,NULL,NULL,'ptr406.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(412,64,'PTR','ptr407','ptr407.in-addr.arpa.',NULL,NULL,NULL,'ptr407.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(413,95,'AAAA','host408','2001:db8::6bcc',NULL,'2001:db8::6bcc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(414,102,'CNAME','cname409','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(415,86,'TXT','txt410','test-txt-410',NULL,NULL,NULL,NULL,'test-txt-410',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(416,100,'CNAME','cname411','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(417,62,'PTR','ptr412','ptr412.in-addr.arpa.',NULL,NULL,NULL,'ptr412.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(418,62,'A','host413','198.51.189.13','198.51.189.13',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(419,98,'CNAME','cname414','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(420,70,'A','host415','198.51.128.63','198.51.128.63',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(421,81,'PTR','ptr416','ptr416.in-addr.arpa.',NULL,NULL,NULL,'ptr416.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(422,71,'A','host417','198.51.29.5','198.51.29.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(423,109,'TXT','txt418','test-txt-418',NULL,NULL,NULL,NULL,'test-txt-418',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(424,62,'A','host419','198.51.45.121','198.51.45.121',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(425,93,'CNAME','cname420','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(426,67,'A','host421','198.51.193.93','198.51.193.93',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(427,83,'A','host422','198.51.182.127','198.51.182.127',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(428,73,'TXT','txt423','test-txt-423',NULL,NULL,NULL,NULL,'test-txt-423',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(429,106,'A','host424','198.51.160.189','198.51.160.189',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(430,62,'CNAME','cname425','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(431,98,'A','host426','198.51.186.133','198.51.186.133',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(432,109,'PTR','ptr427','ptr427.in-addr.arpa.',NULL,NULL,NULL,'ptr427.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(433,61,'PTR','ptr428','ptr428.in-addr.arpa.',NULL,NULL,NULL,'ptr428.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(434,92,'CNAME','cname429','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(435,92,'CNAME','cname430','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(436,100,'A','host431','198.51.206.80','198.51.206.80',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(437,90,'CNAME','cname432','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(438,79,'A','host433','198.51.127.8','198.51.127.8',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(439,108,'TXT','txt434','test-txt-434',NULL,NULL,NULL,NULL,'test-txt-434',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(440,65,'CNAME','cname435','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(441,77,'PTR','ptr436','ptr436.in-addr.arpa.',NULL,NULL,NULL,'ptr436.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(442,72,'PTR','ptr437','ptr437.in-addr.arpa.',NULL,NULL,NULL,'ptr437.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(443,79,'A','host438','198.51.35.194','198.51.35.194',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(444,77,'AAAA','host439','2001:db8::7bf5',NULL,'2001:db8::7bf5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(445,105,'AAAA','host440','2001:db8::9f',NULL,'2001:db8::9f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(446,91,'A','host441','198.51.245.41','198.51.245.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(447,65,'A','host442','198.51.4.30','198.51.4.30',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(448,81,'PTR','ptr443','ptr443.in-addr.arpa.',NULL,NULL,NULL,'ptr443.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(449,85,'AAAA','host444','2001:db8::6268',NULL,'2001:db8::6268',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(450,65,'TXT','txt445','test-txt-445',NULL,NULL,NULL,NULL,'test-txt-445',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(451,108,'A','host446','198.51.49.174','198.51.49.174',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(452,107,'TXT','txt447','test-txt-447',NULL,NULL,NULL,NULL,'test-txt-447',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(453,108,'AAAA','host448','2001:db8::5fb2',NULL,'2001:db8::5fb2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(454,100,'AAAA','host449','2001:db8::1450',NULL,'2001:db8::1450',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(455,63,'TXT','txt450','test-txt-450',NULL,NULL,NULL,NULL,'test-txt-450',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(456,79,'AAAA','host451','2001:db8::7193',NULL,'2001:db8::7193',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(457,71,'TXT','txt452','test-txt-452',NULL,NULL,NULL,NULL,'test-txt-452',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(458,61,'CNAME','cname453','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(459,108,'CNAME','cname454','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(460,83,'A','host455','198.51.0.173','198.51.0.173',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(461,61,'CNAME','cname456','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(462,63,'TXT','txt457','test-txt-457',NULL,NULL,NULL,NULL,'test-txt-457',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(463,104,'TXT','txt458','test-txt-458',NULL,NULL,NULL,NULL,'test-txt-458',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(464,70,'TXT','txt459','test-txt-459',NULL,NULL,NULL,NULL,'test-txt-459',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(465,101,'CNAME','cname460','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(466,100,'TXT','txt461','test-txt-461',NULL,NULL,NULL,NULL,'test-txt-461',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(467,81,'AAAA','host462','2001:db8::2e99',NULL,'2001:db8::2e99',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(468,86,'PTR','ptr463','ptr463.in-addr.arpa.',NULL,NULL,NULL,'ptr463.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(469,107,'TXT','txt464','test-txt-464',NULL,NULL,NULL,NULL,'test-txt-464',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(470,85,'A','host465','198.51.192.233','198.51.192.233',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(471,81,'PTR','ptr466','ptr466.in-addr.arpa.',NULL,NULL,NULL,'ptr466.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(472,90,'AAAA','host467','2001:db8::de56',NULL,'2001:db8::de56',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(473,72,'A','host468','198.51.92.222','198.51.92.222',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(474,89,'AAAA','host469','2001:db8::6422',NULL,'2001:db8::6422',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(475,70,'CNAME','cname470','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(476,75,'AAAA','host471','2001:db8::c62e',NULL,'2001:db8::c62e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(477,78,'TXT','txt472','test-txt-472',NULL,NULL,NULL,NULL,'test-txt-472',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(478,91,'CNAME','cname473','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(479,80,'AAAA','host474','2001:db8::1c8c',NULL,'2001:db8::1c8c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(480,78,'TXT','txt475','test-txt-475',NULL,NULL,NULL,NULL,'test-txt-475',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(481,101,'TXT','txt476','test-txt-476',NULL,NULL,NULL,NULL,'test-txt-476',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(482,66,'AAAA','host477','2001:db8::e873',NULL,'2001:db8::e873',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(483,103,'CNAME','cname478','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(484,67,'AAAA','host479','2001:db8::6130',NULL,'2001:db8::6130',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(485,79,'AAAA','host480','2001:db8::fe4c',NULL,'2001:db8::fe4c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(486,103,'TXT','txt481','test-txt-481',NULL,NULL,NULL,NULL,'test-txt-481',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(487,98,'A','host482','198.51.168.125','198.51.168.125',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(488,106,'TXT','txt483','test-txt-483',NULL,NULL,NULL,NULL,'test-txt-483',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(489,91,'A','host484','198.51.0.198','198.51.0.198',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(490,105,'AAAA','host485','2001:db8::cb02',NULL,'2001:db8::cb02',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(491,106,'A','host486','198.51.57.11','198.51.57.11',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(492,67,'A','host487','198.51.78.129','198.51.78.129',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(493,65,'PTR','ptr488','ptr488.in-addr.arpa.',NULL,NULL,NULL,'ptr488.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(494,75,'TXT','txt489','test-txt-489',NULL,NULL,NULL,NULL,'test-txt-489',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(495,107,'AAAA','host490','2001:db8::4891',NULL,'2001:db8::4891',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(496,82,'CNAME','cname491','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(497,68,'CNAME','cname492','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(498,83,'TXT','txt493','test-txt-493',NULL,NULL,NULL,NULL,'test-txt-493',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(499,109,'AAAA','host494','2001:db8::fa12',NULL,'2001:db8::fa12',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(500,64,'CNAME','cname495','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(501,104,'CNAME','cname496','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(502,68,'A','host497','198.51.188.96','198.51.188.96',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(503,81,'TXT','txt498','test-txt-498',NULL,NULL,NULL,NULL,'test-txt-498',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(504,66,'TXT','txt499','test-txt-499',NULL,NULL,NULL,NULL,'test-txt-499',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(505,105,'TXT','txt500','test-txt-500',NULL,NULL,NULL,NULL,'test-txt-500',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(506,86,'PTR','ptr501','ptr501.in-addr.arpa.',NULL,NULL,NULL,'ptr501.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(507,66,'PTR','ptr502','ptr502.in-addr.arpa.',NULL,NULL,NULL,'ptr502.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(508,108,'PTR','ptr503','ptr503.in-addr.arpa.',NULL,NULL,NULL,'ptr503.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(509,61,'AAAA','host504','2001:db8::cb30',NULL,'2001:db8::cb30',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(510,96,'TXT','txt505','test-txt-505',NULL,NULL,NULL,NULL,'test-txt-505',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(511,96,'TXT','txt506','test-txt-506',NULL,NULL,NULL,NULL,'test-txt-506',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(512,107,'CNAME','cname507','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(513,98,'TXT','txt508','test-txt-508',NULL,NULL,NULL,NULL,'test-txt-508',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(514,73,'A','host509','198.51.62.164','198.51.62.164',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(515,64,'CNAME','cname510','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(516,95,'A','host511','198.51.70.191','198.51.70.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(517,69,'AAAA','host512','2001:db8::32eb',NULL,'2001:db8::32eb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(518,101,'AAAA','host513','2001:db8::7039',NULL,'2001:db8::7039',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(519,83,'PTR','ptr514','ptr514.in-addr.arpa.',NULL,NULL,NULL,'ptr514.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(520,97,'AAAA','host515','2001:db8::6541',NULL,'2001:db8::6541',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(521,92,'AAAA','host516','2001:db8::9263',NULL,'2001:db8::9263',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(522,106,'AAAA','host517','2001:db8::8dc',NULL,'2001:db8::8dc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(523,82,'PTR','ptr518','ptr518.in-addr.arpa.',NULL,NULL,NULL,'ptr518.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(524,97,'A','host519','198.51.193.254','198.51.193.254',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(525,63,'PTR','ptr520','ptr520.in-addr.arpa.',NULL,NULL,NULL,'ptr520.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(526,60,'CNAME','cname521','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(527,93,'CNAME','cname522','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(528,104,'CNAME','cname523','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(529,106,'CNAME','cname524','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(530,76,'PTR','ptr525','ptr525.in-addr.arpa.',NULL,NULL,NULL,'ptr525.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(531,86,'CNAME','cname526','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(532,71,'AAAA','host527','2001:db8::c8a4',NULL,'2001:db8::c8a4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(533,61,'PTR','ptr528','ptr528.in-addr.arpa.',NULL,NULL,NULL,'ptr528.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(534,68,'AAAA','host529','2001:db8::1023',NULL,'2001:db8::1023',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(535,102,'CNAME','cname530','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(536,90,'TXT','txt531','test-txt-531',NULL,NULL,NULL,NULL,'test-txt-531',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(537,69,'PTR','ptr532','ptr532.in-addr.arpa.',NULL,NULL,NULL,'ptr532.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(538,105,'CNAME','cname533','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(539,99,'CNAME','cname534','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(540,93,'A','host535','198.51.135.245','198.51.135.245',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(541,69,'CNAME','cname536','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(542,75,'A','host537','198.51.25.31','198.51.25.31',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(543,68,'TXT','txt538','test-txt-538',NULL,NULL,NULL,NULL,'test-txt-538',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(544,81,'TXT','txt539','test-txt-539',NULL,NULL,NULL,NULL,'test-txt-539',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(545,94,'A','host540','198.51.107.217','198.51.107.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(546,99,'CNAME','cname541','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(547,91,'PTR','ptr542','ptr542.in-addr.arpa.',NULL,NULL,NULL,'ptr542.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(548,78,'CNAME','cname543','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(549,83,'PTR','ptr544','ptr544.in-addr.arpa.',NULL,NULL,NULL,'ptr544.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(550,103,'A','host545','198.51.59.99','198.51.59.99',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(551,90,'CNAME','cname546','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(552,66,'AAAA','host547','2001:db8::e4bd',NULL,'2001:db8::e4bd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(553,102,'A','host548','198.51.127.240','198.51.127.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(554,78,'AAAA','host549','2001:db8::e4ef',NULL,'2001:db8::e4ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(555,84,'A','host550','198.51.178.63','198.51.178.63',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(556,65,'TXT','txt551','test-txt-551',NULL,NULL,NULL,NULL,'test-txt-551',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(557,75,'A','host552','198.51.19.9','198.51.19.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(558,101,'AAAA','host553','2001:db8::adbe',NULL,'2001:db8::adbe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(559,95,'A','host554','198.51.9.118','198.51.9.118',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(560,74,'AAAA','host555','2001:db8::40fa',NULL,'2001:db8::40fa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(561,70,'A','host556','198.51.227.97','198.51.227.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(562,92,'PTR','ptr557','ptr557.in-addr.arpa.',NULL,NULL,NULL,'ptr557.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(563,109,'CNAME','cname558','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(564,98,'PTR','ptr559','ptr559.in-addr.arpa.',NULL,NULL,NULL,'ptr559.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(565,62,'CNAME','cname560','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(566,73,'CNAME','cname561','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(567,65,'CNAME','cname562','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(568,61,'CNAME','cname563','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(569,97,'TXT','txt564','test-txt-564',NULL,NULL,NULL,NULL,'test-txt-564',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(570,107,'CNAME','cname565','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(571,102,'A','host566','198.51.131.215','198.51.131.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(572,74,'CNAME','cname567','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(573,108,'CNAME','cname568','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(574,67,'A','host569','198.51.245.194','198.51.245.194',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(575,95,'PTR','ptr570','ptr570.in-addr.arpa.',NULL,NULL,NULL,'ptr570.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(576,90,'CNAME','cname571','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(577,64,'TXT','txt572','test-txt-572',NULL,NULL,NULL,NULL,'test-txt-572',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(578,61,'AAAA','host573','2001:db8::e796',NULL,'2001:db8::e796',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(579,98,'A','host574','198.51.34.213','198.51.34.213',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(580,96,'PTR','ptr575','ptr575.in-addr.arpa.',NULL,NULL,NULL,'ptr575.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(581,100,'CNAME','cname576','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(582,64,'A','host577','198.51.198.203','198.51.198.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(583,94,'AAAA','host578','2001:db8::97ff',NULL,'2001:db8::97ff',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(584,102,'A','host579','198.51.165.210','198.51.165.210',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(585,94,'PTR','ptr580','ptr580.in-addr.arpa.',NULL,NULL,NULL,'ptr580.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(586,61,'CNAME','cname581','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(587,104,'CNAME','cname582','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(588,84,'CNAME','cname583','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(589,106,'A','host584','198.51.23.173','198.51.23.173',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(590,68,'AAAA','host585','2001:db8::8333',NULL,'2001:db8::8333',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(591,89,'CNAME','cname586','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(592,60,'A','host587','198.51.136.108','198.51.136.108',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(593,80,'AAAA','host588','2001:db8::393f',NULL,'2001:db8::393f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(594,109,'AAAA','host589','2001:db8::cf24',NULL,'2001:db8::cf24',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(595,60,'CNAME','cname590','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(596,108,'PTR','ptr591','ptr591.in-addr.arpa.',NULL,NULL,NULL,'ptr591.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(597,88,'AAAA','host592','2001:db8::faec',NULL,'2001:db8::faec',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(598,88,'A','host593','198.51.89.236','198.51.89.236',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(599,81,'TXT','txt594','test-txt-594',NULL,NULL,NULL,NULL,'test-txt-594',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(600,73,'CNAME','cname595','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(601,77,'A','host596','198.51.203.124','198.51.203.124',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(602,92,'AAAA','host597','2001:db8::325',NULL,'2001:db8::325',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(603,60,'AAAA','host598','2001:db8::a9cd',NULL,'2001:db8::a9cd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(604,109,'PTR','ptr599','ptr599.in-addr.arpa.',NULL,NULL,NULL,'ptr599.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(605,67,'PTR','ptr600','ptr600.in-addr.arpa.',NULL,NULL,NULL,'ptr600.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(606,61,'PTR','ptr601','ptr601.in-addr.arpa.',NULL,NULL,NULL,'ptr601.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(607,108,'PTR','ptr602','ptr602.in-addr.arpa.',NULL,NULL,NULL,'ptr602.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(608,103,'A','host603','198.51.72.229','198.51.72.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(609,105,'TXT','txt604','test-txt-604',NULL,NULL,NULL,NULL,'test-txt-604',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(610,109,'PTR','ptr605','ptr605.in-addr.arpa.',NULL,NULL,NULL,'ptr605.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(611,97,'A','host606','198.51.174.152','198.51.174.152',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(612,101,'PTR','ptr607','ptr607.in-addr.arpa.',NULL,NULL,NULL,'ptr607.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(613,79,'PTR','ptr608','ptr608.in-addr.arpa.',NULL,NULL,NULL,'ptr608.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(614,102,'AAAA','host609','2001:db8::3554',NULL,'2001:db8::3554',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(615,70,'AAAA','host610','2001:db8::bc29',NULL,'2001:db8::bc29',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(616,75,'TXT','txt611','test-txt-611',NULL,NULL,NULL,NULL,'test-txt-611',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(617,82,'A','host612','198.51.93.128','198.51.93.128',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(618,101,'CNAME','cname613','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(619,61,'A','host614','198.51.220.56','198.51.220.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(620,91,'AAAA','host615','2001:db8::186b',NULL,'2001:db8::186b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(621,66,'PTR','ptr616','ptr616.in-addr.arpa.',NULL,NULL,NULL,'ptr616.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(622,81,'A','host617','198.51.209.106','198.51.209.106',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(623,96,'PTR','ptr618','ptr618.in-addr.arpa.',NULL,NULL,NULL,'ptr618.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(624,70,'TXT','txt619','test-txt-619',NULL,NULL,NULL,NULL,'test-txt-619',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(625,96,'CNAME','cname620','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(626,107,'CNAME','cname621','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(627,73,'TXT','txt622','test-txt-622',NULL,NULL,NULL,NULL,'test-txt-622',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(628,109,'A','host623','198.51.33.28','198.51.33.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(629,62,'TXT','txt624','test-txt-624',NULL,NULL,NULL,NULL,'test-txt-624',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(630,106,'CNAME','cname625','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(631,67,'CNAME','cname626','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(632,96,'TXT','txt627','test-txt-627',NULL,NULL,NULL,NULL,'test-txt-627',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(633,77,'TXT','txt628','test-txt-628',NULL,NULL,NULL,NULL,'test-txt-628',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(634,107,'CNAME','cname629','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(635,101,'A','host630','198.51.188.141','198.51.188.141',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(636,77,'TXT','txt631','test-txt-631',NULL,NULL,NULL,NULL,'test-txt-631',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(637,90,'PTR','ptr632','ptr632.in-addr.arpa.',NULL,NULL,NULL,'ptr632.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(638,85,'PTR','ptr633','ptr633.in-addr.arpa.',NULL,NULL,NULL,'ptr633.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(639,96,'CNAME','cname634','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(640,109,'AAAA','host635','2001:db8::4041',NULL,'2001:db8::4041',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(641,100,'AAAA','host636','2001:db8::31a8',NULL,'2001:db8::31a8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(642,60,'PTR','ptr637','ptr637.in-addr.arpa.',NULL,NULL,NULL,'ptr637.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(643,82,'A','host638','198.51.132.241','198.51.132.241',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(644,104,'A','host639','198.51.223.2','198.51.223.2',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(645,75,'AAAA','host640','2001:db8::a6b2',NULL,'2001:db8::a6b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(646,91,'A','host641','198.51.76.193','198.51.76.193',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(647,64,'AAAA','host642','2001:db8::2b1f',NULL,'2001:db8::2b1f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(648,105,'PTR','ptr643','ptr643.in-addr.arpa.',NULL,NULL,NULL,'ptr643.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(649,81,'TXT','txt644','test-txt-644',NULL,NULL,NULL,NULL,'test-txt-644',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(650,72,'CNAME','cname645','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(651,80,'AAAA','host646','2001:db8::2527',NULL,'2001:db8::2527',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(652,109,'A','host647','198.51.181.69','198.51.181.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(653,102,'A','host648','198.51.49.237','198.51.49.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(654,70,'CNAME','cname649','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(655,64,'PTR','ptr650','ptr650.in-addr.arpa.',NULL,NULL,NULL,'ptr650.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(656,68,'TXT','txt651','test-txt-651',NULL,NULL,NULL,NULL,'test-txt-651',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(657,102,'CNAME','cname652','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(658,67,'AAAA','host653','2001:db8::2a1a',NULL,'2001:db8::2a1a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(659,76,'TXT','txt654','test-txt-654',NULL,NULL,NULL,NULL,'test-txt-654',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(660,89,'CNAME','cname655','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(661,105,'TXT','txt656','test-txt-656',NULL,NULL,NULL,NULL,'test-txt-656',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(662,105,'PTR','ptr657','ptr657.in-addr.arpa.',NULL,NULL,NULL,'ptr657.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(663,94,'TXT','txt658','test-txt-658',NULL,NULL,NULL,NULL,'test-txt-658',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(664,61,'TXT','txt659','test-txt-659',NULL,NULL,NULL,NULL,'test-txt-659',3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(665,63,'CNAME','cname660','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(666,76,'AAAA','host661','2001:db8::ee4f',NULL,'2001:db8::ee4f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(667,92,'A','host662','198.51.163.18','198.51.163.18',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(668,108,'CNAME','cname663','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(669,80,'PTR','ptr664','ptr664.in-addr.arpa.',NULL,NULL,NULL,'ptr664.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(670,84,'CNAME','cname665','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:22',NULL,'2025-10-23 07:27:22',NULL,NULL,NULL,NULL),
(671,84,'CNAME','cname666','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(672,79,'CNAME','cname667','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(673,79,'TXT','txt668','test-txt-668',NULL,NULL,NULL,NULL,'test-txt-668',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(674,78,'AAAA','host669','2001:db8::385d',NULL,'2001:db8::385d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(675,91,'PTR','ptr670','ptr670.in-addr.arpa.',NULL,NULL,NULL,'ptr670.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(676,106,'AAAA','host671','2001:db8::9cc1',NULL,'2001:db8::9cc1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(677,70,'TXT','txt672','test-txt-672',NULL,NULL,NULL,NULL,'test-txt-672',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(678,83,'A','host673','198.51.177.212','198.51.177.212',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(679,90,'PTR','ptr674','ptr674.in-addr.arpa.',NULL,NULL,NULL,'ptr674.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(680,68,'TXT','txt675','test-txt-675',NULL,NULL,NULL,NULL,'test-txt-675',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(681,75,'PTR','ptr676','ptr676.in-addr.arpa.',NULL,NULL,NULL,'ptr676.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(682,89,'TXT','txt677','test-txt-677',NULL,NULL,NULL,NULL,'test-txt-677',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(683,75,'TXT','txt678','test-txt-678',NULL,NULL,NULL,NULL,'test-txt-678',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(684,94,'CNAME','cname679','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(685,64,'CNAME','cname680','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(686,75,'AAAA','host681','2001:db8::6d5b',NULL,'2001:db8::6d5b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(687,80,'TXT','txt682','test-txt-682',NULL,NULL,NULL,NULL,'test-txt-682',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(688,84,'AAAA','host683','2001:db8::7c63',NULL,'2001:db8::7c63',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(689,62,'PTR','ptr684','ptr684.in-addr.arpa.',NULL,NULL,NULL,'ptr684.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(690,68,'AAAA','host685','2001:db8::3b3a',NULL,'2001:db8::3b3a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(691,95,'A','host686','198.51.219.131','198.51.219.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(692,101,'A','host687','198.51.144.147','198.51.144.147',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(693,77,'CNAME','cname688','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(694,76,'AAAA','host689','2001:db8::e076',NULL,'2001:db8::e076',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(695,103,'CNAME','cname690','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(696,101,'TXT','txt691','test-txt-691',NULL,NULL,NULL,NULL,'test-txt-691',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(697,78,'CNAME','cname692','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(698,101,'AAAA','host693','2001:db8::700d',NULL,'2001:db8::700d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(699,109,'CNAME','cname694','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(700,62,'CNAME','cname695','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(701,82,'PTR','ptr696','ptr696.in-addr.arpa.',NULL,NULL,NULL,'ptr696.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(702,102,'PTR','ptr697','ptr697.in-addr.arpa.',NULL,NULL,NULL,'ptr697.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(703,61,'AAAA','host698','2001:db8::4154',NULL,'2001:db8::4154',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(704,95,'PTR','ptr699','ptr699.in-addr.arpa.',NULL,NULL,NULL,'ptr699.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(705,87,'A','host700','198.51.138.94','198.51.138.94',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(706,67,'A','host701','198.51.186.28','198.51.186.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(707,88,'CNAME','cname702','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(708,69,'CNAME','cname703','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(709,105,'A','host704','198.51.101.243','198.51.101.243',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(710,99,'A','host705','198.51.207.213','198.51.207.213',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(711,69,'CNAME','cname706','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(712,87,'PTR','ptr707','ptr707.in-addr.arpa.',NULL,NULL,NULL,'ptr707.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(713,66,'PTR','ptr708','ptr708.in-addr.arpa.',NULL,NULL,NULL,'ptr708.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(714,81,'PTR','ptr709','ptr709.in-addr.arpa.',NULL,NULL,NULL,'ptr709.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(715,100,'A','host710','198.51.98.31','198.51.98.31',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(716,77,'AAAA','host711','2001:db8::89a8',NULL,'2001:db8::89a8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(717,80,'A','host712','198.51.164.180','198.51.164.180',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(718,89,'AAAA','host713','2001:db8::7258',NULL,'2001:db8::7258',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(719,63,'TXT','txt714','test-txt-714',NULL,NULL,NULL,NULL,'test-txt-714',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(720,73,'CNAME','cname715','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(721,63,'TXT','txt716','test-txt-716',NULL,NULL,NULL,NULL,'test-txt-716',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(722,94,'TXT','txt717','test-txt-717',NULL,NULL,NULL,NULL,'test-txt-717',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(723,95,'CNAME','cname718','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(724,105,'AAAA','host719','2001:db8::e57a',NULL,'2001:db8::e57a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(725,70,'A','host720','198.51.38.68','198.51.38.68',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(726,97,'CNAME','cname721','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(727,64,'TXT','txt722','test-txt-722',NULL,NULL,NULL,NULL,'test-txt-722',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(728,97,'PTR','ptr723','ptr723.in-addr.arpa.',NULL,NULL,NULL,'ptr723.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(729,70,'PTR','ptr724','ptr724.in-addr.arpa.',NULL,NULL,NULL,'ptr724.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(730,85,'TXT','txt725','test-txt-725',NULL,NULL,NULL,NULL,'test-txt-725',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(731,74,'AAAA','host726','2001:db8::c079',NULL,'2001:db8::c079',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(732,68,'TXT','txt727','test-txt-727',NULL,NULL,NULL,NULL,'test-txt-727',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(733,85,'CNAME','cname728','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(734,102,'CNAME','cname729','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(735,87,'PTR','ptr730','ptr730.in-addr.arpa.',NULL,NULL,NULL,'ptr730.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(736,80,'AAAA','host731','2001:db8::a837',NULL,'2001:db8::a837',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(737,81,'A','host732','198.51.239.1','198.51.239.1',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(738,68,'TXT','txt733','test-txt-733',NULL,NULL,NULL,NULL,'test-txt-733',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(739,108,'TXT','txt734','test-txt-734',NULL,NULL,NULL,NULL,'test-txt-734',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(740,74,'CNAME','cname735','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(741,98,'AAAA','host736','2001:db8::78ba',NULL,'2001:db8::78ba',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(742,102,'AAAA','host737','2001:db8::4ae2',NULL,'2001:db8::4ae2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(743,62,'CNAME','cname738','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(744,101,'PTR','ptr739','ptr739.in-addr.arpa.',NULL,NULL,NULL,'ptr739.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(745,86,'A','host740','198.51.30.191','198.51.30.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(746,87,'A','host741','198.51.161.193','198.51.161.193',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(747,96,'AAAA','host742','2001:db8::b8ef',NULL,'2001:db8::b8ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(748,64,'CNAME','cname743','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(749,72,'CNAME','cname744','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(750,60,'TXT','txt745','test-txt-745',NULL,NULL,NULL,NULL,'test-txt-745',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(751,100,'AAAA','host746','2001:db8::49b3',NULL,'2001:db8::49b3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(752,93,'AAAA','host747','2001:db8::d73a',NULL,'2001:db8::d73a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(753,89,'CNAME','cname748','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(754,104,'A','host749','198.51.204.227','198.51.204.227',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(755,100,'CNAME','cname750','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(756,71,'CNAME','cname751','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(757,101,'PTR','ptr752','ptr752.in-addr.arpa.',NULL,NULL,NULL,'ptr752.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(758,89,'AAAA','host753','2001:db8::2a3e',NULL,'2001:db8::2a3e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(759,104,'PTR','ptr754','ptr754.in-addr.arpa.',NULL,NULL,NULL,'ptr754.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(760,102,'A','host755','198.51.102.214','198.51.102.214',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(761,77,'TXT','txt756','test-txt-756',NULL,NULL,NULL,NULL,'test-txt-756',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(762,101,'A','host757','198.51.156.20','198.51.156.20',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(763,103,'PTR','ptr758','ptr758.in-addr.arpa.',NULL,NULL,NULL,'ptr758.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(764,77,'TXT','txt759','test-txt-759',NULL,NULL,NULL,NULL,'test-txt-759',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(765,105,'AAAA','host760','2001:db8::8212',NULL,'2001:db8::8212',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(766,85,'AAAA','host761','2001:db8::91e1',NULL,'2001:db8::91e1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(767,84,'A','host762','198.51.156.178','198.51.156.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(768,77,'AAAA','host763','2001:db8::a388',NULL,'2001:db8::a388',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(769,89,'A','host764','198.51.144.158','198.51.144.158',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(770,82,'TXT','txt765','test-txt-765',NULL,NULL,NULL,NULL,'test-txt-765',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(771,81,'A','host766','198.51.143.43','198.51.143.43',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(772,84,'PTR','ptr767','ptr767.in-addr.arpa.',NULL,NULL,NULL,'ptr767.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(773,78,'TXT','txt768','test-txt-768',NULL,NULL,NULL,NULL,'test-txt-768',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(774,72,'AAAA','host769','2001:db8::172',NULL,'2001:db8::172',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(775,105,'TXT','txt770','test-txt-770',NULL,NULL,NULL,NULL,'test-txt-770',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(776,68,'CNAME','cname771','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(777,103,'AAAA','host772','2001:db8::bc59',NULL,'2001:db8::bc59',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(778,80,'A','host773','198.51.182.114','198.51.182.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(779,79,'CNAME','cname774','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(780,71,'PTR','ptr775','ptr775.in-addr.arpa.',NULL,NULL,NULL,'ptr775.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(781,103,'AAAA','host776','2001:db8::cac4',NULL,'2001:db8::cac4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(782,95,'PTR','ptr777','ptr777.in-addr.arpa.',NULL,NULL,NULL,'ptr777.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(783,104,'TXT','txt778','test-txt-778',NULL,NULL,NULL,NULL,'test-txt-778',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(784,69,'TXT','txt779','test-txt-779',NULL,NULL,NULL,NULL,'test-txt-779',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(785,79,'PTR','ptr780','ptr780.in-addr.arpa.',NULL,NULL,NULL,'ptr780.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(786,99,'TXT','txt781','test-txt-781',NULL,NULL,NULL,NULL,'test-txt-781',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(787,104,'AAAA','host782','2001:db8::19cf',NULL,'2001:db8::19cf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(788,84,'AAAA','host783','2001:db8::e17e',NULL,'2001:db8::e17e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(789,85,'TXT','txt784','test-txt-784',NULL,NULL,NULL,NULL,'test-txt-784',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(790,88,'CNAME','cname785','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(791,86,'AAAA','host786','2001:db8::ce37',NULL,'2001:db8::ce37',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(792,104,'PTR','ptr787','ptr787.in-addr.arpa.',NULL,NULL,NULL,'ptr787.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(793,65,'A','host788','198.51.12.203','198.51.12.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(794,101,'TXT','txt789','test-txt-789',NULL,NULL,NULL,NULL,'test-txt-789',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(795,66,'A','host790','198.51.32.125','198.51.32.125',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(796,99,'AAAA','host791','2001:db8::cba8',NULL,'2001:db8::cba8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(797,79,'AAAA','host792','2001:db8::97d8',NULL,'2001:db8::97d8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(798,71,'AAAA','host793','2001:db8::93ef',NULL,'2001:db8::93ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(799,76,'TXT','txt794','test-txt-794',NULL,NULL,NULL,NULL,'test-txt-794',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(800,93,'TXT','txt795','test-txt-795',NULL,NULL,NULL,NULL,'test-txt-795',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(801,100,'A','host796','198.51.37.157','198.51.37.157',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(802,106,'PTR','ptr797','ptr797.in-addr.arpa.',NULL,NULL,NULL,'ptr797.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(803,62,'TXT','txt798','test-txt-798',NULL,NULL,NULL,NULL,'test-txt-798',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(804,89,'PTR','ptr799','ptr799.in-addr.arpa.',NULL,NULL,NULL,'ptr799.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(805,86,'CNAME','cname800','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(806,108,'AAAA','host801','2001:db8::d6fb',NULL,'2001:db8::d6fb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(807,87,'AAAA','host802','2001:db8::39b8',NULL,'2001:db8::39b8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(808,68,'A','host803','198.51.10.72','198.51.10.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(809,65,'CNAME','cname804','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(810,100,'TXT','txt805','test-txt-805',NULL,NULL,NULL,NULL,'test-txt-805',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(811,100,'CNAME','cname806','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(812,102,'PTR','ptr807','ptr807.in-addr.arpa.',NULL,NULL,NULL,'ptr807.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(813,103,'TXT','txt808','test-txt-808',NULL,NULL,NULL,NULL,'test-txt-808',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(814,63,'A','host809','198.51.88.69','198.51.88.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(815,75,'PTR','ptr810','ptr810.in-addr.arpa.',NULL,NULL,NULL,'ptr810.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(816,62,'CNAME','cname811','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(817,69,'A','host812','198.51.105.56','198.51.105.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(818,107,'TXT','txt813','test-txt-813',NULL,NULL,NULL,NULL,'test-txt-813',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(819,83,'AAAA','host814','2001:db8::cb49',NULL,'2001:db8::cb49',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(820,64,'A','host815','198.51.25.225','198.51.25.225',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(821,61,'AAAA','host816','2001:db8::8a10',NULL,'2001:db8::8a10',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(822,92,'CNAME','cname817','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(823,97,'PTR','ptr818','ptr818.in-addr.arpa.',NULL,NULL,NULL,'ptr818.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(824,98,'A','host819','198.51.31.18','198.51.31.18',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(825,109,'TXT','txt820','test-txt-820',NULL,NULL,NULL,NULL,'test-txt-820',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(826,100,'PTR','ptr821','ptr821.in-addr.arpa.',NULL,NULL,NULL,'ptr821.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(827,99,'AAAA','host822','2001:db8::44c',NULL,'2001:db8::44c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(828,66,'TXT','txt823','test-txt-823',NULL,NULL,NULL,NULL,'test-txt-823',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(829,108,'TXT','txt824','test-txt-824',NULL,NULL,NULL,NULL,'test-txt-824',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(830,91,'A','host825','198.51.224.248','198.51.224.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(831,92,'AAAA','host826','2001:db8::303',NULL,'2001:db8::303',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(832,94,'A','host827','198.51.86.182','198.51.86.182',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(833,68,'TXT','txt828','test-txt-828',NULL,NULL,NULL,NULL,'test-txt-828',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(834,90,'TXT','txt829','test-txt-829',NULL,NULL,NULL,NULL,'test-txt-829',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(835,91,'A','host830','198.51.124.10','198.51.124.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(836,77,'AAAA','host831','2001:db8::36b2',NULL,'2001:db8::36b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(837,90,'CNAME','cname832','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(838,65,'AAAA','host833','2001:db8::6c4c',NULL,'2001:db8::6c4c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(839,64,'TXT','txt834','test-txt-834',NULL,NULL,NULL,NULL,'test-txt-834',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(840,80,'TXT','txt835','test-txt-835',NULL,NULL,NULL,NULL,'test-txt-835',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(841,72,'A','host836','198.51.235.206','198.51.235.206',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(842,61,'TXT','txt837','test-txt-837',NULL,NULL,NULL,NULL,'test-txt-837',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(843,65,'A','host838','198.51.20.130','198.51.20.130',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(844,104,'CNAME','cname839','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(845,67,'CNAME','cname840','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(846,101,'CNAME','cname841','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(847,92,'TXT','txt842','test-txt-842',NULL,NULL,NULL,NULL,'test-txt-842',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(848,77,'A','host843','198.51.243.12','198.51.243.12',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(849,107,'CNAME','cname844','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(850,100,'A','host845','198.51.253.23','198.51.253.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(851,100,'PTR','ptr846','ptr846.in-addr.arpa.',NULL,NULL,NULL,'ptr846.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(852,96,'TXT','txt847','test-txt-847',NULL,NULL,NULL,NULL,'test-txt-847',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(853,106,'AAAA','host848','2001:db8::2d3e',NULL,'2001:db8::2d3e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(854,104,'AAAA','host849','2001:db8::8a40',NULL,'2001:db8::8a40',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(855,102,'TXT','txt850','test-txt-850',NULL,NULL,NULL,NULL,'test-txt-850',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(856,96,'CNAME','cname851','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(857,93,'TXT','txt852','test-txt-852',NULL,NULL,NULL,NULL,'test-txt-852',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(858,66,'TXT','txt853','test-txt-853',NULL,NULL,NULL,NULL,'test-txt-853',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(859,69,'A','host854','198.51.190.97','198.51.190.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(860,103,'TXT','txt855','test-txt-855',NULL,NULL,NULL,NULL,'test-txt-855',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(861,106,'TXT','txt856','test-txt-856',NULL,NULL,NULL,NULL,'test-txt-856',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(862,85,'PTR','ptr857','ptr857.in-addr.arpa.',NULL,NULL,NULL,'ptr857.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(863,75,'A','host858','198.51.242.77','198.51.242.77',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(864,88,'TXT','txt859','test-txt-859',NULL,NULL,NULL,NULL,'test-txt-859',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(865,85,'TXT','txt860','test-txt-860',NULL,NULL,NULL,NULL,'test-txt-860',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(866,87,'CNAME','cname861','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(867,102,'PTR','ptr862','ptr862.in-addr.arpa.',NULL,NULL,NULL,'ptr862.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(868,61,'PTR','ptr863','ptr863.in-addr.arpa.',NULL,NULL,NULL,'ptr863.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(869,100,'TXT','txt864','test-txt-864',NULL,NULL,NULL,NULL,'test-txt-864',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(870,60,'TXT','txt865','test-txt-865',NULL,NULL,NULL,NULL,'test-txt-865',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(871,72,'CNAME','cname866','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(872,61,'TXT','txt867','test-txt-867',NULL,NULL,NULL,NULL,'test-txt-867',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(873,76,'PTR','ptr868','ptr868.in-addr.arpa.',NULL,NULL,NULL,'ptr868.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(874,67,'CNAME','cname869','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(875,89,'AAAA','host870','2001:db8::f20e',NULL,'2001:db8::f20e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(876,108,'TXT','txt871','test-txt-871',NULL,NULL,NULL,NULL,'test-txt-871',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(877,61,'A','host872','198.51.54.108','198.51.54.108',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(878,81,'PTR','ptr873','ptr873.in-addr.arpa.',NULL,NULL,NULL,'ptr873.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(879,69,'A','host874','198.51.112.94','198.51.112.94',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(880,98,'CNAME','cname875','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(881,106,'A','host876','198.51.192.188','198.51.192.188',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(882,62,'TXT','txt877','test-txt-877',NULL,NULL,NULL,NULL,'test-txt-877',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(883,100,'AAAA','host878','2001:db8::a391',NULL,'2001:db8::a391',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(884,102,'TXT','txt879','test-txt-879',NULL,NULL,NULL,NULL,'test-txt-879',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(885,90,'CNAME','cname880','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(886,66,'CNAME','cname881','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(887,103,'A','host882','198.51.52.179','198.51.52.179',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(888,65,'CNAME','cname883','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(889,79,'TXT','txt884','test-txt-884',NULL,NULL,NULL,NULL,'test-txt-884',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(890,98,'A','host885','198.51.221.226','198.51.221.226',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(891,70,'PTR','ptr886','ptr886.in-addr.arpa.',NULL,NULL,NULL,'ptr886.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(892,103,'A','host887','198.51.19.96','198.51.19.96',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(893,100,'TXT','txt888','test-txt-888',NULL,NULL,NULL,NULL,'test-txt-888',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(894,70,'PTR','ptr889','ptr889.in-addr.arpa.',NULL,NULL,NULL,'ptr889.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(895,66,'TXT','txt890','test-txt-890',NULL,NULL,NULL,NULL,'test-txt-890',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(896,60,'PTR','ptr891','ptr891.in-addr.arpa.',NULL,NULL,NULL,'ptr891.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(897,105,'A','host892','198.51.83.117','198.51.83.117',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(898,64,'TXT','txt893','test-txt-893',NULL,NULL,NULL,NULL,'test-txt-893',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(899,95,'AAAA','host894','2001:db8::a134',NULL,'2001:db8::a134',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(900,85,'PTR','ptr895','ptr895.in-addr.arpa.',NULL,NULL,NULL,'ptr895.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(901,105,'AAAA','host896','2001:db8::180c',NULL,'2001:db8::180c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(902,80,'AAAA','host897','2001:db8::6c7',NULL,'2001:db8::6c7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(903,64,'A','host898','198.51.37.135','198.51.37.135',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(904,101,'TXT','txt899','test-txt-899',NULL,NULL,NULL,NULL,'test-txt-899',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(905,61,'AAAA','host900','2001:db8::2851',NULL,'2001:db8::2851',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(906,63,'CNAME','cname901','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(907,89,'A','host902','198.51.23.216','198.51.23.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(908,80,'A','host903','198.51.137.205','198.51.137.205',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(909,97,'A','host904','198.51.144.65','198.51.144.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(910,106,'AAAA','host905','2001:db8::9ab9',NULL,'2001:db8::9ab9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(911,87,'TXT','txt906','test-txt-906',NULL,NULL,NULL,NULL,'test-txt-906',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(912,86,'TXT','txt907','test-txt-907',NULL,NULL,NULL,NULL,'test-txt-907',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(913,84,'PTR','ptr908','ptr908.in-addr.arpa.',NULL,NULL,NULL,'ptr908.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(914,109,'A','host909','198.51.239.120','198.51.239.120',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(915,107,'TXT','txt910','test-txt-910',NULL,NULL,NULL,NULL,'test-txt-910',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(916,93,'A','host911','198.51.163.250','198.51.163.250',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(917,73,'A','host912','198.51.156.160','198.51.156.160',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(918,102,'PTR','ptr913','ptr913.in-addr.arpa.',NULL,NULL,NULL,'ptr913.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(919,70,'TXT','txt914','test-txt-914',NULL,NULL,NULL,NULL,'test-txt-914',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(920,103,'PTR','ptr915','ptr915.in-addr.arpa.',NULL,NULL,NULL,'ptr915.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(921,87,'AAAA','host916','2001:db8::dc37',NULL,'2001:db8::dc37',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(922,105,'A','host917','198.51.227.39','198.51.227.39',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(923,78,'PTR','ptr918','ptr918.in-addr.arpa.',NULL,NULL,NULL,'ptr918.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(924,90,'A','host919','198.51.87.115','198.51.87.115',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(925,105,'PTR','ptr920','ptr920.in-addr.arpa.',NULL,NULL,NULL,'ptr920.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(926,68,'CNAME','cname921','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(927,74,'TXT','txt922','test-txt-922',NULL,NULL,NULL,NULL,'test-txt-922',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(928,80,'AAAA','host923','2001:db8::45e0',NULL,'2001:db8::45e0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(929,76,'TXT','txt924','test-txt-924',NULL,NULL,NULL,NULL,'test-txt-924',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(930,69,'AAAA','host925','2001:db8::24c8',NULL,'2001:db8::24c8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(931,61,'AAAA','host926','2001:db8::9548',NULL,'2001:db8::9548',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(932,66,'A','host927','198.51.157.171','198.51.157.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(933,96,'A','host928','198.51.244.116','198.51.244.116',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(934,103,'CNAME','cname929','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(935,103,'AAAA','host930','2001:db8::56b5',NULL,'2001:db8::56b5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(936,105,'AAAA','host931','2001:db8::1ddd',NULL,'2001:db8::1ddd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(937,65,'PTR','ptr932','ptr932.in-addr.arpa.',NULL,NULL,NULL,'ptr932.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(938,107,'CNAME','cname933','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(939,70,'AAAA','host934','2001:db8::167c',NULL,'2001:db8::167c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(940,80,'A','host935','198.51.90.56','198.51.90.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(941,103,'TXT','txt936','test-txt-936',NULL,NULL,NULL,NULL,'test-txt-936',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(942,61,'PTR','ptr937','ptr937.in-addr.arpa.',NULL,NULL,NULL,'ptr937.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(943,108,'A','host938','198.51.115.19','198.51.115.19',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(944,68,'TXT','txt939','test-txt-939',NULL,NULL,NULL,NULL,'test-txt-939',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(945,68,'TXT','txt940','test-txt-940',NULL,NULL,NULL,NULL,'test-txt-940',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(946,98,'PTR','ptr941','ptr941.in-addr.arpa.',NULL,NULL,NULL,'ptr941.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(947,63,'TXT','txt942','test-txt-942',NULL,NULL,NULL,NULL,'test-txt-942',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(948,93,'PTR','ptr943','ptr943.in-addr.arpa.',NULL,NULL,NULL,'ptr943.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(949,104,'CNAME','cname944','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(950,107,'CNAME','cname945','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(951,73,'AAAA','host946','2001:db8::22da',NULL,'2001:db8::22da',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(952,88,'TXT','txt947','test-txt-947',NULL,NULL,NULL,NULL,'test-txt-947',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(953,69,'AAAA','host948','2001:db8::3cd0',NULL,'2001:db8::3cd0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(954,67,'A','host949','198.51.214.72','198.51.214.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(955,104,'AAAA','host950','2001:db8::76b2',NULL,'2001:db8::76b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(956,102,'TXT','txt951','test-txt-951',NULL,NULL,NULL,NULL,'test-txt-951',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(957,88,'TXT','txt952','test-txt-952',NULL,NULL,NULL,NULL,'test-txt-952',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(958,72,'TXT','txt953','test-txt-953',NULL,NULL,NULL,NULL,'test-txt-953',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(959,73,'PTR','ptr954','ptr954.in-addr.arpa.',NULL,NULL,NULL,'ptr954.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(960,68,'PTR','ptr955','ptr955.in-addr.arpa.',NULL,NULL,NULL,'ptr955.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(961,63,'PTR','ptr956','ptr956.in-addr.arpa.',NULL,NULL,NULL,'ptr956.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(962,77,'A','host957','198.51.20.148','198.51.20.148',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(963,63,'TXT','txt958','test-txt-958',NULL,NULL,NULL,NULL,'test-txt-958',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(964,78,'AAAA','host959','2001:db8::2c55',NULL,'2001:db8::2c55',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(965,74,'CNAME','cname960','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(966,96,'AAAA','host961','2001:db8::ec24',NULL,'2001:db8::ec24',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(967,105,'AAAA','host962','2001:db8::b680',NULL,'2001:db8::b680',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(968,83,'CNAME','cname963','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(969,90,'A','host964','198.51.71.138','198.51.71.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(970,91,'AAAA','host965','2001:db8::db0f',NULL,'2001:db8::db0f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(971,62,'TXT','txt966','test-txt-966',NULL,NULL,NULL,NULL,'test-txt-966',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(972,66,'AAAA','host967','2001:db8::74c4',NULL,'2001:db8::74c4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(973,61,'PTR','ptr968','ptr968.in-addr.arpa.',NULL,NULL,NULL,'ptr968.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(974,68,'AAAA','host969','2001:db8::59ea',NULL,'2001:db8::59ea',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(975,102,'A','host970','198.51.111.170','198.51.111.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(976,74,'TXT','txt971','test-txt-971',NULL,NULL,NULL,NULL,'test-txt-971',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(977,98,'TXT','txt972','test-txt-972',NULL,NULL,NULL,NULL,'test-txt-972',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(978,96,'CNAME','cname973','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(979,89,'TXT','txt974','test-txt-974',NULL,NULL,NULL,NULL,'test-txt-974',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(980,60,'CNAME','cname975','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(981,85,'AAAA','host976','2001:db8::73d6',NULL,'2001:db8::73d6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(982,79,'PTR','ptr977','ptr977.in-addr.arpa.',NULL,NULL,NULL,'ptr977.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(983,100,'A','host978','198.51.166.242','198.51.166.242',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(984,97,'TXT','txt979','test-txt-979',NULL,NULL,NULL,NULL,'test-txt-979',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(985,104,'CNAME','cname980','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(986,62,'PTR','ptr981','ptr981.in-addr.arpa.',NULL,NULL,NULL,'ptr981.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(987,64,'PTR','ptr982','ptr982.in-addr.arpa.',NULL,NULL,NULL,'ptr982.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(988,69,'PTR','ptr983','ptr983.in-addr.arpa.',NULL,NULL,NULL,'ptr983.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(989,102,'CNAME','cname984','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(990,107,'AAAA','host985','2001:db8::f214',NULL,'2001:db8::f214',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(991,85,'AAAA','host986','2001:db8::802e',NULL,'2001:db8::802e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(992,80,'AAAA','host987','2001:db8::fef7',NULL,'2001:db8::fef7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(993,67,'AAAA','host988','2001:db8::670c',NULL,'2001:db8::670c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(994,85,'AAAA','host989','2001:db8::a27b',NULL,'2001:db8::a27b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(995,67,'AAAA','host990','2001:db8::b12f',NULL,'2001:db8::b12f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(996,65,'CNAME','cname991','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(997,76,'CNAME','cname992','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(998,105,'CNAME','cname993','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(999,90,'CNAME','cname994','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1000,106,'TXT','txt995','test-txt-995',NULL,NULL,NULL,NULL,'test-txt-995',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1001,66,'TXT','txt996','test-txt-996',NULL,NULL,NULL,NULL,'test-txt-996',3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1002,95,'AAAA','host997','2001:db8::695b',NULL,'2001:db8::695b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1003,93,'AAAA','host998','2001:db8::44f6',NULL,'2001:db8::44f6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1004,101,'A','host999','198.51.221.138','198.51.221.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL),
(1005,72,'CNAME','cname1000','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:27:23',NULL,'2025-10-23 07:27:23',NULL,NULL,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
INSERT INTO `zone_file_includes` VALUES
(5,93,100,1,'2025-10-23 09:27:21'),
(6,85,101,2,'2025-10-23 09:27:21'),
(7,78,102,3,'2025-10-23 09:27:21'),
(8,89,103,4,'2025-10-23 09:27:21'),
(9,85,104,5,'2025-10-23 09:27:21'),
(10,99,105,6,'2025-10-23 09:27:21'),
(11,82,106,7,'2025-10-23 09:27:21'),
(12,64,107,8,'2025-10-23 09:27:21'),
(13,91,108,9,'2025-10-23 09:27:21'),
(14,91,109,10,'2025-10-23 09:27:21');
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
) ENGINE=InnoDB AUTO_INCREMENT=98 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_validation`
--

LOCK TABLES `zone_file_validation` WRITE;
/*!40000 ALTER TABLE `zone_file_validation` DISABLE KEYS */;
INSERT INTO `zone_file_validation` VALUES
(90,100,'pending','Validation queued for top master zone (ID: 93)','2025-10-23 09:27:50',2),
(91,93,'pending','Validation queued for background processing','2025-10-23 09:27:50',2),
(92,93,'failed','zone test-master-34.local/IN: has no NS records\nzone test-master-34.local/IN: not loaded due to errors.','2025-10-23 09:28:19',2),
(93,100,'failed','Validation performed on parent zone \'test-master-34.local\' (ID: 93):\n\nzone test-master-34.local/IN: has no NS records\nzone test-master-34.local/IN: not loaded due to errors.','2025-10-23 09:28:19',2),
(94,91,'pending','Validation queued for background processing','2025-10-23 09:29:19',2),
(95,91,'failed','zone test-master-32.local/IN: has no NS records\nzone test-master-32.local/IN: not loaded due to errors.','2025-10-23 09:29:28',2),
(96,108,'failed','Validation performed on parent zone \'test-master-32.local\' (ID: 91):\n\nzone test-master-32.local/IN: has no NS records\nzone test-master-32.local/IN: not loaded due to errors.','2025-10-23 09:29:28',2),
(97,109,'failed','Validation performed on parent zone \'test-master-32.local\' (ID: 91):\n\nzone test-master-32.local/IN: has no NS records\nzone test-master-32.local/IN: not loaded due to errors.','2025-10-23 09:29:28',2);
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
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(60,'test-master-1.local','db.test-master-1.local',NULL,'; Master zone test-master-1.local\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.2\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(61,'test-master-2.local','db.test-master-2.local',NULL,'; Master zone test-master-2.local\n$TTL 3600\n@ IN SOA ns1.test-master-2.local. admin.test-master-2.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.3\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(62,'test-master-3.local','db.test-master-3.local',NULL,'; Master zone test-master-3.local\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.4\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(63,'test-master-4.local','db.test-master-4.local',NULL,'; Master zone test-master-4.local\n$TTL 3600\n@ IN SOA ns1.test-master-4.local. admin.test-master-4.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(64,'test-master-5.local','db.test-master-5.local',NULL,'; Master zone test-master-5.local\n$TTL 3600\n@ IN SOA ns1.test-master-5.local. admin.test-master-5.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.6\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(65,'test-master-6.local','db.test-master-6.local',NULL,'; Master zone test-master-6.local\n$TTL 3600\n@ IN SOA ns1.test-master-6.local. admin.test-master-6.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.7\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(66,'test-master-7.local','db.test-master-7.local',NULL,'; Master zone test-master-7.local\n$TTL 3600\n@ IN SOA ns1.test-master-7.local. admin.test-master-7.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(67,'test-master-8.local','db.test-master-8.local',NULL,'; Master zone test-master-8.local\n$TTL 3600\n@ IN SOA ns1.test-master-8.local. admin.test-master-8.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.9\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(68,'test-master-9.local','db.test-master-9.local',NULL,'; Master zone test-master-9.local\n$TTL 3600\n@ IN SOA ns1.test-master-9.local. admin.test-master-9.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.10\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(69,'test-master-10.local','db.test-master-10.local',NULL,'; Master zone test-master-10.local\n$TTL 3600\n@ IN SOA ns1.test-master-10.local. admin.test-master-10.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.11\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(70,'test-master-11.local','db.test-master-11.local',NULL,'; Master zone test-master-11.local\n$TTL 3600\n@ IN SOA ns1.test-master-11.local. admin.test-master-11.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.12\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(71,'test-master-12.local','db.test-master-12.local',NULL,'; Master zone test-master-12.local\n$TTL 3600\n@ IN SOA ns1.test-master-12.local. admin.test-master-12.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.13\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(72,'test-master-13.local','db.test-master-13.local',NULL,'; Master zone test-master-13.local\n$TTL 3600\n@ IN SOA ns1.test-master-13.local. admin.test-master-13.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.14\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(73,'test-master-14.local','db.test-master-14.local',NULL,'; Master zone test-master-14.local\n$TTL 3600\n@ IN SOA ns1.test-master-14.local. admin.test-master-14.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(74,'test-master-15.local','db.test-master-15.local',NULL,'; Master zone test-master-15.local\n$TTL 3600\n@ IN SOA ns1.test-master-15.local. admin.test-master-15.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(75,'test-master-16.local','db.test-master-16.local',NULL,'; Master zone test-master-16.local\n$TTL 3600\n@ IN SOA ns1.test-master-16.local. admin.test-master-16.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(76,'test-master-17.local','db.test-master-17.local',NULL,'; Master zone test-master-17.local\n$TTL 3600\n@ IN SOA ns1.test-master-17.local. admin.test-master-17.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(77,'test-master-18.local','db.test-master-18.local',NULL,'; Master zone test-master-18.local\n$TTL 3600\n@ IN SOA ns1.test-master-18.local. admin.test-master-18.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(78,'test-master-19.local','db.test-master-19.local',NULL,'; Master zone test-master-19.local\n$TTL 3600\n@ IN SOA ns1.test-master-19.local. admin.test-master-19.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.20\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(79,'test-master-20.local','db.test-master-20.local',NULL,'; Master zone test-master-20.local\n$TTL 3600\n@ IN SOA ns1.test-master-20.local. admin.test-master-20.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.21\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(80,'test-master-21.local','db.test-master-21.local',NULL,'; Master zone test-master-21.local\n$TTL 3600\n@ IN SOA ns1.test-master-21.local. admin.test-master-21.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.22\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(81,'test-master-22.local','db.test-master-22.local',NULL,'; Master zone test-master-22.local\n$TTL 3600\n@ IN SOA ns1.test-master-22.local. admin.test-master-22.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.23\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(82,'test-master-23.local','db.test-master-23.local',NULL,'; Master zone test-master-23.local\n$TTL 3600\n@ IN SOA ns1.test-master-23.local. admin.test-master-23.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.24\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(83,'test-master-24.local','db.test-master-24.local',NULL,'; Master zone test-master-24.local\n$TTL 3600\n@ IN SOA ns1.test-master-24.local. admin.test-master-24.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.25\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(84,'test-master-25.local','db.test-master-25.local',NULL,'; Master zone test-master-25.local\n$TTL 3600\n@ IN SOA ns1.test-master-25.local. admin.test-master-25.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(85,'test-master-26.local','db.test-master-26.local',NULL,'; Master zone test-master-26.local\n$TTL 3600\n@ IN SOA ns1.test-master-26.local. admin.test-master-26.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.27\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(86,'test-master-27.local','db.test-master-27.local',NULL,'; Master zone test-master-27.local\n$TTL 3600\n@ IN SOA ns1.test-master-27.local. admin.test-master-27.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.28\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(87,'test-master-28.local','db.test-master-28.local',NULL,'; Master zone test-master-28.local\n$TTL 3600\n@ IN SOA ns1.test-master-28.local. admin.test-master-28.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.29\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(88,'test-master-29.local','db.test-master-29.local',NULL,'; Master zone test-master-29.local\n$TTL 3600\n@ IN SOA ns1.test-master-29.local. admin.test-master-29.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(89,'test-master-30.local','db.test-master-30.local',NULL,'; Master zone test-master-30.local\n$TTL 3600\n@ IN SOA ns1.test-master-30.local. admin.test-master-30.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.31\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(90,'test-master-31.local','db.test-master-31.local',NULL,'; Master zone test-master-31.local\n$TTL 3600\n@ IN SOA ns1.test-master-31.local. admin.test-master-31.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.32\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(91,'test-master-32.local','db.test-master-32.local',NULL,'; Master zone test-master-32.local\n$TTL 3600\n@ IN SOA ns1.test-master-32.local. admin.test-master-32.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(92,'test-master-33.local','db.test-master-33.local',NULL,'; Master zone test-master-33.local\n$TTL 3600\n@ IN SOA ns1.test-master-33.local. admin.test-master-33.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.34\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(93,'test-master-34.local','db.test-master-34.local',NULL,'; Master zone test-master-34.local\n$TTL 3600\n@ IN SOA ns1.test-master-34.local. admin.test-master-34.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(94,'test-master-35.local','db.test-master-35.local',NULL,'; Master zone test-master-35.local\n$TTL 3600\n@ IN SOA ns1.test-master-35.local. admin.test-master-35.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.36\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(95,'test-master-36.local','db.test-master-36.local',NULL,'; Master zone test-master-36.local\n$TTL 3600\n@ IN SOA ns1.test-master-36.local. admin.test-master-36.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(96,'test-master-37.local','db.test-master-37.local',NULL,'; Master zone test-master-37.local\n$TTL 3600\n@ IN SOA ns1.test-master-37.local. admin.test-master-37.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.38\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(97,'test-master-38.local','db.test-master-38.local',NULL,'; Master zone test-master-38.local\n$TTL 3600\n@ IN SOA ns1.test-master-38.local. admin.test-master-38.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(98,'test-master-39.local','db.test-master-39.local',NULL,'; Master zone test-master-39.local\n$TTL 3600\n@ IN SOA ns1.test-master-39.local. admin.test-master-39.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(99,'test-master-40.local','db.test-master-40.local',NULL,'; Master zone test-master-40.local\n$TTL 3600\n@ IN SOA ns1.test-master-40.local. admin.test-master-40.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2.41\n','master','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(100,'common-include-1.inc.local','include.common-1.conf',NULL,'; Include file common-include-1.inc.local\n; common records for group 1\nwww IN A 198.51.1.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(101,'common-include-2.inc.local','include.common-2.conf',NULL,'; Include file common-include-2.inc.local\n; common records for group 2\nwww IN A 198.51.2.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(102,'common-include-3.inc.local','include.common-3.conf',NULL,'; Include file common-include-3.inc.local\n; common records for group 3\nwww IN A 198.51.3.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(103,'common-include-4.inc.local','include.common-4.conf',NULL,'; Include file common-include-4.inc.local\n; common records for group 4\nwww IN A 198.51.4.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(104,'common-include-5.inc.local','include.common-5.conf',NULL,'; Include file common-include-5.inc.local\n; common records for group 5\nwww IN A 198.51.5.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(105,'common-include-6.inc.local','include.common-6.conf',NULL,'; Include file common-include-6.inc.local\n; common records for group 6\nwww IN A 198.51.6.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(106,'common-include-7.inc.local','include.common-7.conf',NULL,'; Include file common-include-7.inc.local\n; common records for group 7\nwww IN A 198.51.7.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(107,'common-include-8.inc.local','include.common-8.conf',NULL,'; Include file common-include-8.inc.local\n; common records for group 8\nwww IN A 198.51.8.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(108,'common-include-9.inc.local','include.common-9.conf',NULL,'; Include file common-include-9.inc.local\n; common records for group 9\nwww IN A 198.51.9.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21'),
(109,'common-include-10.inc.local','include.common-10.conf',NULL,'; Include file common-include-10.inc.local\n; common records for group 10\nwww IN A 198.51.10.1\n','include','active',1,NULL,'2025-10-23 07:27:21','2025-10-23 07:27:21');
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

-- Dump completed on 2025-10-23 11:33:33
