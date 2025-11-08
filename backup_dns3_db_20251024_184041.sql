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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=4007 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(3007,227,'PTR','ptr1','ptr1.in-addr.arpa.',NULL,NULL,NULL,'ptr1.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3008,256,'A','host2','198.51.237.120','198.51.237.120',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3009,251,'CNAME','cname3','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3010,256,'A','host4','198.51.90.37','198.51.90.37',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3011,220,'A','host5','198.51.64.182','198.51.64.182',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3012,227,'A','host6','198.51.10.71','198.51.10.71',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3013,241,'CNAME','cname7','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3014,249,'A','host8','198.51.189.20','198.51.189.20',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3015,251,'TXT','txt9','test-txt-9',NULL,NULL,NULL,NULL,'test-txt-9',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3016,247,'CNAME','cname10','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3017,217,'TXT','txt11','test-txt-11',NULL,NULL,NULL,NULL,'test-txt-11',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3018,253,'AAAA','host12','2001:db8::a364',NULL,'2001:db8::a364',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3019,231,'TXT','txt13','test-txt-13',NULL,NULL,NULL,NULL,'test-txt-13',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3020,218,'CNAME','cname14','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3021,242,'PTR','ptr15','ptr15.in-addr.arpa.',NULL,NULL,NULL,'ptr15.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3022,229,'TXT','txt16','test-txt-16',NULL,NULL,NULL,NULL,'test-txt-16',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3023,251,'AAAA','host17','2001:db8::fa7f',NULL,'2001:db8::fa7f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3024,223,'CNAME','cname18','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3025,247,'AAAA','host19','2001:db8::a575',NULL,'2001:db8::a575',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3026,234,'PTR','ptr20','ptr20.in-addr.arpa.',NULL,NULL,NULL,'ptr20.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3027,221,'TXT','txt21','test-txt-21',NULL,NULL,NULL,NULL,'test-txt-21',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3028,219,'PTR','ptr22','ptr22.in-addr.arpa.',NULL,NULL,NULL,'ptr22.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3029,211,'A','host23','198.51.175.8','198.51.175.8',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3030,242,'CNAME','cname24','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3031,236,'TXT','txt25','test-txt-25',NULL,NULL,NULL,NULL,'test-txt-25',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3032,255,'CNAME','cname26','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3033,252,'CNAME','cname27','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3034,258,'PTR','ptr28','ptr28.in-addr.arpa.',NULL,NULL,NULL,'ptr28.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3035,222,'TXT','txt29','test-txt-29',NULL,NULL,NULL,NULL,'test-txt-29',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3036,258,'AAAA','host30','2001:db8::61c0',NULL,'2001:db8::61c0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3037,214,'TXT','txt31','test-txt-31',NULL,NULL,NULL,NULL,'test-txt-31',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3038,229,'A','host32','198.51.30.145','198.51.30.145',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3039,245,'TXT','txt33','test-txt-33',NULL,NULL,NULL,NULL,'test-txt-33',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3040,256,'TXT','txt34','test-txt-34',NULL,NULL,NULL,NULL,'test-txt-34',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3041,213,'CNAME','cname35','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3042,236,'A','host36','198.51.63.51','198.51.63.51',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3043,220,'TXT','txt37','test-txt-37',NULL,NULL,NULL,NULL,'test-txt-37',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3044,231,'CNAME','cname38','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3045,252,'CNAME','cname39','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3046,224,'CNAME','cname40','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3047,258,'CNAME','cname41','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3048,251,'AAAA','host42','2001:db8::7eea',NULL,'2001:db8::7eea',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3049,251,'AAAA','host43','2001:db8::2291',NULL,'2001:db8::2291',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3050,250,'AAAA','host44','2001:db8::9708',NULL,'2001:db8::9708',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3051,219,'PTR','ptr45','ptr45.in-addr.arpa.',NULL,NULL,NULL,'ptr45.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3052,238,'A','host46','198.51.184.227','198.51.184.227',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3053,219,'CNAME','cname47','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3054,221,'A','host48','198.51.19.5','198.51.19.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3055,257,'CNAME','cname49','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3056,241,'PTR','ptr50','ptr50.in-addr.arpa.',NULL,NULL,NULL,'ptr50.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3057,212,'TXT','txt51','test-txt-51',NULL,NULL,NULL,NULL,'test-txt-51',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3058,221,'A','host52','198.51.79.194','198.51.79.194',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3059,256,'AAAA','host53','2001:db8::1a',NULL,'2001:db8::1a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3060,231,'PTR','ptr54','ptr54.in-addr.arpa.',NULL,NULL,NULL,'ptr54.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3061,217,'A','host55','198.51.213.128','198.51.213.128',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3062,233,'PTR','ptr56','ptr56.in-addr.arpa.',NULL,NULL,NULL,'ptr56.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3063,251,'PTR','ptr57','ptr57.in-addr.arpa.',NULL,NULL,NULL,'ptr57.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3064,258,'CNAME','cname58','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3065,223,'AAAA','host59','2001:db8::6c1c',NULL,'2001:db8::6c1c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3066,237,'AAAA','host60','2001:db8::1c4d',NULL,'2001:db8::1c4d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3067,241,'AAAA','host61','2001:db8::219f',NULL,'2001:db8::219f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3068,256,'CNAME','cname62','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3069,225,'TXT','txt63','test-txt-63',NULL,NULL,NULL,NULL,'test-txt-63',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3070,216,'AAAA','host64','2001:db8::4f6b',NULL,'2001:db8::4f6b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3071,239,'TXT','txt65','test-txt-65',NULL,NULL,NULL,NULL,'test-txt-65',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3072,222,'A','host66','198.51.219.23','198.51.219.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3073,255,'CNAME','cname67','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3074,256,'PTR','ptr68','ptr68.in-addr.arpa.',NULL,NULL,NULL,'ptr68.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3075,238,'A','host69','198.51.60.86','198.51.60.86',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3076,252,'CNAME','cname70','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3077,250,'CNAME','cname71','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3078,232,'A','host72','198.51.57.51','198.51.57.51',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3079,252,'PTR','ptr73','ptr73.in-addr.arpa.',NULL,NULL,NULL,'ptr73.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3080,224,'CNAME','cname74','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3081,228,'PTR','ptr75','ptr75.in-addr.arpa.',NULL,NULL,NULL,'ptr75.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3082,220,'CNAME','cname76','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3083,239,'PTR','ptr77','ptr77.in-addr.arpa.',NULL,NULL,NULL,'ptr77.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3084,214,'AAAA','host78','2001:db8::84ba',NULL,'2001:db8::84ba',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3085,256,'CNAME','cname79','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3086,246,'A','host80','198.51.97.83','198.51.97.83',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3087,257,'PTR','ptr81','ptr81.in-addr.arpa.',NULL,NULL,NULL,'ptr81.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3088,213,'TXT','txt82','test-txt-82',NULL,NULL,NULL,NULL,'test-txt-82',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3089,222,'A','host83','198.51.183.150','198.51.183.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3090,259,'CNAME','cname84','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3091,212,'CNAME','cname85','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3092,238,'PTR','ptr86','ptr86.in-addr.arpa.',NULL,NULL,NULL,'ptr86.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3093,219,'CNAME','cname87','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3094,257,'PTR','ptr88','ptr88.in-addr.arpa.',NULL,NULL,NULL,'ptr88.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3095,259,'TXT','txt89','test-txt-89',NULL,NULL,NULL,NULL,'test-txt-89',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3096,256,'TXT','txt90','test-txt-90',NULL,NULL,NULL,NULL,'test-txt-90',3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3097,243,'PTR','ptr91','ptr91.in-addr.arpa.',NULL,NULL,NULL,'ptr91.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:21',NULL,'2025-10-24 14:40:21',NULL,NULL,NULL,NULL),
(3098,238,'AAAA','host92','2001:db8::8fb2',NULL,'2001:db8::8fb2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3099,246,'PTR','ptr93','ptr93.in-addr.arpa.',NULL,NULL,NULL,'ptr93.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3100,224,'PTR','ptr94','ptr94.in-addr.arpa.',NULL,NULL,NULL,'ptr94.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3101,240,'PTR','ptr95','ptr95.in-addr.arpa.',NULL,NULL,NULL,'ptr95.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3102,235,'TXT','txt96','test-txt-96',NULL,NULL,NULL,NULL,'test-txt-96',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3103,228,'A','host97','198.51.78.196','198.51.78.196',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3104,239,'PTR','ptr98','ptr98.in-addr.arpa.',NULL,NULL,NULL,'ptr98.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3105,213,'A','host99','198.51.50.116','198.51.50.116',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3106,255,'PTR','ptr100','ptr100.in-addr.arpa.',NULL,NULL,NULL,'ptr100.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3107,246,'TXT','txt101','test-txt-101',NULL,NULL,NULL,NULL,'test-txt-101',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3108,251,'TXT','txt102','test-txt-102',NULL,NULL,NULL,NULL,'test-txt-102',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3109,235,'TXT','txt103','test-txt-103',NULL,NULL,NULL,NULL,'test-txt-103',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3110,248,'AAAA','host104','2001:db8::9367',NULL,'2001:db8::9367',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3111,220,'CNAME','cname105','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3112,240,'A','host106','198.51.103.65','198.51.103.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3113,250,'PTR','ptr107','ptr107.in-addr.arpa.',NULL,NULL,NULL,'ptr107.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3114,243,'PTR','ptr108','ptr108.in-addr.arpa.',NULL,NULL,NULL,'ptr108.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3115,228,'TXT','txt109','test-txt-109',NULL,NULL,NULL,NULL,'test-txt-109',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3116,224,'TXT','txt110','test-txt-110',NULL,NULL,NULL,NULL,'test-txt-110',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3117,226,'TXT','txt111','test-txt-111',NULL,NULL,NULL,NULL,'test-txt-111',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3118,244,'AAAA','host112','2001:db8::f0a8',NULL,'2001:db8::f0a8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3119,240,'A','host113','198.51.252.142','198.51.252.142',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3120,230,'A','host114','198.51.165.36','198.51.165.36',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3121,244,'A','host115','198.51.241.242','198.51.241.242',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3122,229,'A','host116','198.51.189.134','198.51.189.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3123,258,'TXT','txt117','test-txt-117',NULL,NULL,NULL,NULL,'test-txt-117',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3124,236,'TXT','txt118','test-txt-118',NULL,NULL,NULL,NULL,'test-txt-118',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3125,251,'A','host119','198.51.58.174','198.51.58.174',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3126,256,'A','host120','198.51.101.196','198.51.101.196',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3127,234,'TXT','txt121','test-txt-121',NULL,NULL,NULL,NULL,'test-txt-121',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3128,255,'PTR','ptr122','ptr122.in-addr.arpa.',NULL,NULL,NULL,'ptr122.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3129,243,'CNAME','cname123','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3130,250,'PTR','ptr124','ptr124.in-addr.arpa.',NULL,NULL,NULL,'ptr124.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3131,244,'A','host125','198.51.4.179','198.51.4.179',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3132,244,'AAAA','host126','2001:db8::187',NULL,'2001:db8::187',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3133,215,'AAAA','host127','2001:db8::43e1',NULL,'2001:db8::43e1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3134,231,'CNAME','cname128','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3135,228,'A','host129','198.51.169.204','198.51.169.204',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3136,218,'PTR','ptr130','ptr130.in-addr.arpa.',NULL,NULL,NULL,'ptr130.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3137,248,'TXT','txt131','test-txt-131',NULL,NULL,NULL,NULL,'test-txt-131',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3138,249,'AAAA','host132','2001:db8::cd9a',NULL,'2001:db8::cd9a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3139,226,'PTR','ptr133','ptr133.in-addr.arpa.',NULL,NULL,NULL,'ptr133.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3140,216,'TXT','txt134','test-txt-134',NULL,NULL,NULL,NULL,'test-txt-134',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3141,259,'AAAA','host135','2001:db8::dceb',NULL,'2001:db8::dceb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3142,238,'PTR','ptr136','ptr136.in-addr.arpa.',NULL,NULL,NULL,'ptr136.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3143,214,'PTR','ptr137','ptr137.in-addr.arpa.',NULL,NULL,NULL,'ptr137.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3144,250,'CNAME','cname138','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3145,229,'A','host139','198.51.134.136','198.51.134.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3146,230,'A','host140','198.51.23.14','198.51.23.14',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3147,212,'AAAA','host141','2001:db8::46c4',NULL,'2001:db8::46c4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3148,259,'CNAME','cname142','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3149,252,'A','host143','198.51.35.98','198.51.35.98',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3150,242,'A','host144','198.51.17.60','198.51.17.60',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3151,247,'CNAME','cname145','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3152,220,'PTR','ptr146','ptr146.in-addr.arpa.',NULL,NULL,NULL,'ptr146.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3153,210,'CNAME','cname147','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3154,223,'A','host148','198.51.87.76','198.51.87.76',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3155,257,'TXT','txt149','test-txt-149',NULL,NULL,NULL,NULL,'test-txt-149',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3156,255,'AAAA','host150','2001:db8::52ca',NULL,'2001:db8::52ca',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3157,255,'TXT','txt151','test-txt-151',NULL,NULL,NULL,NULL,'test-txt-151',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3158,210,'PTR','ptr152','ptr152.in-addr.arpa.',NULL,NULL,NULL,'ptr152.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3159,220,'CNAME','cname153','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3160,247,'CNAME','cname154','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3161,240,'A','host155','198.51.113.36','198.51.113.36',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3162,253,'AAAA','host156','2001:db8::9dba',NULL,'2001:db8::9dba',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3163,235,'AAAA','host157','2001:db8::5e33',NULL,'2001:db8::5e33',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3164,212,'AAAA','host158','2001:db8::db73',NULL,'2001:db8::db73',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3165,220,'TXT','txt159','test-txt-159',NULL,NULL,NULL,NULL,'test-txt-159',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3166,212,'PTR','ptr160','ptr160.in-addr.arpa.',NULL,NULL,NULL,'ptr160.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3167,214,'AAAA','host161','2001:db8::fedc',NULL,'2001:db8::fedc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3168,230,'TXT','txt162','test-txt-162',NULL,NULL,NULL,NULL,'test-txt-162',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3169,216,'AAAA','host163','2001:db8::545f',NULL,'2001:db8::545f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3170,252,'TXT','txt164','test-txt-164',NULL,NULL,NULL,NULL,'test-txt-164',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3171,229,'TXT','txt165','test-txt-165',NULL,NULL,NULL,NULL,'test-txt-165',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3172,257,'TXT','txt166','test-txt-166',NULL,NULL,NULL,NULL,'test-txt-166',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3173,256,'PTR','ptr167','ptr167.in-addr.arpa.',NULL,NULL,NULL,'ptr167.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3174,227,'CNAME','cname168','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3175,228,'TXT','txt169','test-txt-169',NULL,NULL,NULL,NULL,'test-txt-169',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3176,220,'TXT','txt170','test-txt-170',NULL,NULL,NULL,NULL,'test-txt-170',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3177,256,'TXT','txt171','test-txt-171',NULL,NULL,NULL,NULL,'test-txt-171',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3178,223,'PTR','ptr172','ptr172.in-addr.arpa.',NULL,NULL,NULL,'ptr172.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3179,243,'CNAME','cname173','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3180,246,'PTR','ptr174','ptr174.in-addr.arpa.',NULL,NULL,NULL,'ptr174.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3181,228,'TXT','txt175','test-txt-175',NULL,NULL,NULL,NULL,'test-txt-175',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3182,252,'PTR','ptr176','ptr176.in-addr.arpa.',NULL,NULL,NULL,'ptr176.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3183,212,'CNAME','cname177','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3184,229,'CNAME','cname178','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3185,249,'A','host179','198.51.216.179','198.51.216.179',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3186,258,'TXT','txt180','test-txt-180',NULL,NULL,NULL,NULL,'test-txt-180',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3187,232,'CNAME','cname181','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3188,226,'AAAA','host182','2001:db8::fd67',NULL,'2001:db8::fd67',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3189,236,'CNAME','cname183','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3190,247,'TXT','txt184','test-txt-184',NULL,NULL,NULL,NULL,'test-txt-184',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3191,251,'TXT','txt185','test-txt-185',NULL,NULL,NULL,NULL,'test-txt-185',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3192,231,'CNAME','cname186','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3193,236,'TXT','txt187','test-txt-187',NULL,NULL,NULL,NULL,'test-txt-187',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3194,254,'CNAME','cname188','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3195,241,'AAAA','host189','2001:db8::1eb8',NULL,'2001:db8::1eb8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3196,210,'AAAA','host190','2001:db8::1f65',NULL,'2001:db8::1f65',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3197,221,'PTR','ptr191','ptr191.in-addr.arpa.',NULL,NULL,NULL,'ptr191.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3198,241,'A','host192','198.51.86.60','198.51.86.60',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3199,228,'CNAME','cname193','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3200,232,'CNAME','cname194','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3201,215,'PTR','ptr195','ptr195.in-addr.arpa.',NULL,NULL,NULL,'ptr195.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3202,254,'A','host196','198.51.50.140','198.51.50.140',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3203,253,'A','host197','198.51.206.130','198.51.206.130',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3204,251,'TXT','txt198','test-txt-198',NULL,NULL,NULL,NULL,'test-txt-198',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3205,256,'AAAA','host199','2001:db8::1fc9',NULL,'2001:db8::1fc9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3206,214,'A','host200','198.51.184.7','198.51.184.7',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3207,249,'TXT','txt201','test-txt-201',NULL,NULL,NULL,NULL,'test-txt-201',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3208,237,'CNAME','cname202','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3209,235,'AAAA','host203','2001:db8::9f72',NULL,'2001:db8::9f72',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3210,259,'AAAA','host204','2001:db8::508f',NULL,'2001:db8::508f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3211,217,'TXT','txt205','test-txt-205',NULL,NULL,NULL,NULL,'test-txt-205',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3212,213,'CNAME','cname206','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3213,230,'PTR','ptr207','ptr207.in-addr.arpa.',NULL,NULL,NULL,'ptr207.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3214,256,'CNAME','cname208','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3215,253,'A','host209','198.51.226.184','198.51.226.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3216,241,'A','host210','198.51.16.75','198.51.16.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3217,240,'AAAA','host211','2001:db8::f159',NULL,'2001:db8::f159',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3218,257,'CNAME','cname212','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3219,238,'TXT','txt213','test-txt-213',NULL,NULL,NULL,NULL,'test-txt-213',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3220,232,'A','host214','198.51.108.61','198.51.108.61',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3221,258,'TXT','txt215','test-txt-215',NULL,NULL,NULL,NULL,'test-txt-215',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3222,240,'CNAME','cname216','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3223,228,'TXT','txt217','test-txt-217',NULL,NULL,NULL,NULL,'test-txt-217',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3224,230,'AAAA','host218','2001:db8::98a8',NULL,'2001:db8::98a8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3225,221,'TXT','txt219','test-txt-219',NULL,NULL,NULL,NULL,'test-txt-219',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3226,226,'PTR','ptr220','ptr220.in-addr.arpa.',NULL,NULL,NULL,'ptr220.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3227,256,'TXT','txt221','test-txt-221',NULL,NULL,NULL,NULL,'test-txt-221',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3228,242,'PTR','ptr222','ptr222.in-addr.arpa.',NULL,NULL,NULL,'ptr222.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3229,225,'TXT','txt223','test-txt-223',NULL,NULL,NULL,NULL,'test-txt-223',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3230,245,'TXT','txt224','test-txt-224',NULL,NULL,NULL,NULL,'test-txt-224',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3231,253,'CNAME','cname225','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3232,229,'TXT','txt226','test-txt-226',NULL,NULL,NULL,NULL,'test-txt-226',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3233,228,'TXT','txt227','test-txt-227',NULL,NULL,NULL,NULL,'test-txt-227',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3234,257,'A','host228','198.51.106.114','198.51.106.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3235,254,'PTR','ptr229','ptr229.in-addr.arpa.',NULL,NULL,NULL,'ptr229.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3236,221,'CNAME','cname230','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3237,258,'PTR','ptr231','ptr231.in-addr.arpa.',NULL,NULL,NULL,'ptr231.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3238,212,'PTR','ptr232','ptr232.in-addr.arpa.',NULL,NULL,NULL,'ptr232.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3239,248,'CNAME','cname233','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3240,258,'TXT','txt234','test-txt-234',NULL,NULL,NULL,NULL,'test-txt-234',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3241,227,'PTR','ptr235','ptr235.in-addr.arpa.',NULL,NULL,NULL,'ptr235.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3242,243,'CNAME','cname236','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3243,258,'TXT','txt237','test-txt-237',NULL,NULL,NULL,NULL,'test-txt-237',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3244,256,'AAAA','host238','2001:db8::f821',NULL,'2001:db8::f821',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3245,247,'TXT','txt239','test-txt-239',NULL,NULL,NULL,NULL,'test-txt-239',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3246,214,'PTR','ptr240','ptr240.in-addr.arpa.',NULL,NULL,NULL,'ptr240.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3247,251,'PTR','ptr241','ptr241.in-addr.arpa.',NULL,NULL,NULL,'ptr241.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3248,243,'CNAME','cname242','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3249,214,'A','host243','198.51.65.173','198.51.65.173',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3250,253,'TXT','txt244','test-txt-244',NULL,NULL,NULL,NULL,'test-txt-244',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3251,255,'A','host245','198.51.95.175','198.51.95.175',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3252,231,'TXT','txt246','test-txt-246',NULL,NULL,NULL,NULL,'test-txt-246',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3253,215,'CNAME','cname247','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3254,226,'CNAME','cname248','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3255,245,'A','host249','198.51.0.217','198.51.0.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3256,255,'AAAA','host250','2001:db8::2583',NULL,'2001:db8::2583',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3257,242,'CNAME','cname251','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3258,243,'PTR','ptr252','ptr252.in-addr.arpa.',NULL,NULL,NULL,'ptr252.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3259,241,'PTR','ptr253','ptr253.in-addr.arpa.',NULL,NULL,NULL,'ptr253.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3260,233,'CNAME','cname254','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3261,252,'PTR','ptr255','ptr255.in-addr.arpa.',NULL,NULL,NULL,'ptr255.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3262,246,'PTR','ptr256','ptr256.in-addr.arpa.',NULL,NULL,NULL,'ptr256.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3263,220,'AAAA','host257','2001:db8::c72b',NULL,'2001:db8::c72b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3264,231,'PTR','ptr258','ptr258.in-addr.arpa.',NULL,NULL,NULL,'ptr258.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3265,213,'AAAA','host259','2001:db8::303f',NULL,'2001:db8::303f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3266,236,'AAAA','host260','2001:db8::f834',NULL,'2001:db8::f834',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3267,259,'AAAA','host261','2001:db8::34ad',NULL,'2001:db8::34ad',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3268,211,'TXT','txt262','test-txt-262',NULL,NULL,NULL,NULL,'test-txt-262',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3269,237,'A','host263','198.51.34.172','198.51.34.172',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3270,240,'CNAME','cname264','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3271,232,'A','host265','198.51.211.24','198.51.211.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3272,246,'AAAA','host266','2001:db8::718b',NULL,'2001:db8::718b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3273,229,'TXT','txt267','test-txt-267',NULL,NULL,NULL,NULL,'test-txt-267',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3274,242,'CNAME','cname268','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3275,217,'PTR','ptr269','ptr269.in-addr.arpa.',NULL,NULL,NULL,'ptr269.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3276,257,'A','host270','198.51.173.84','198.51.173.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3277,251,'CNAME','cname271','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3278,233,'TXT','txt272','test-txt-272',NULL,NULL,NULL,NULL,'test-txt-272',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3279,259,'CNAME','cname273','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3280,218,'TXT','txt274','test-txt-274',NULL,NULL,NULL,NULL,'test-txt-274',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3281,257,'A','host275','198.51.246.66','198.51.246.66',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3282,238,'CNAME','cname276','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3283,221,'PTR','ptr277','ptr277.in-addr.arpa.',NULL,NULL,NULL,'ptr277.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3284,226,'TXT','txt278','test-txt-278',NULL,NULL,NULL,NULL,'test-txt-278',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3285,248,'TXT','txt279','test-txt-279',NULL,NULL,NULL,NULL,'test-txt-279',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3286,242,'PTR','ptr280','ptr280.in-addr.arpa.',NULL,NULL,NULL,'ptr280.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3287,213,'TXT','txt281','test-txt-281',NULL,NULL,NULL,NULL,'test-txt-281',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3288,248,'TXT','txt282','test-txt-282',NULL,NULL,NULL,NULL,'test-txt-282',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3289,227,'TXT','txt283','test-txt-283',NULL,NULL,NULL,NULL,'test-txt-283',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3290,250,'A','host284','198.51.49.230','198.51.49.230',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3291,258,'TXT','txt285','test-txt-285',NULL,NULL,NULL,NULL,'test-txt-285',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3292,250,'PTR','ptr286','ptr286.in-addr.arpa.',NULL,NULL,NULL,'ptr286.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3293,250,'CNAME','cname287','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3294,246,'AAAA','host288','2001:db8::94b5',NULL,'2001:db8::94b5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3295,251,'PTR','ptr289','ptr289.in-addr.arpa.',NULL,NULL,NULL,'ptr289.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3296,251,'TXT','txt290','test-txt-290',NULL,NULL,NULL,NULL,'test-txt-290',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3297,242,'CNAME','cname291','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3298,255,'TXT','txt292','test-txt-292',NULL,NULL,NULL,NULL,'test-txt-292',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3299,223,'AAAA','host293','2001:db8::e539',NULL,'2001:db8::e539',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3300,235,'TXT','txt294','test-txt-294',NULL,NULL,NULL,NULL,'test-txt-294',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3301,212,'TXT','txt295','test-txt-295',NULL,NULL,NULL,NULL,'test-txt-295',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3302,250,'TXT','txt296','test-txt-296',NULL,NULL,NULL,NULL,'test-txt-296',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3303,254,'PTR','ptr297','ptr297.in-addr.arpa.',NULL,NULL,NULL,'ptr297.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3304,257,'PTR','ptr298','ptr298.in-addr.arpa.',NULL,NULL,NULL,'ptr298.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3305,258,'AAAA','host299','2001:db8::2789',NULL,'2001:db8::2789',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3306,259,'AAAA','host300','2001:db8::549d',NULL,'2001:db8::549d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3307,243,'TXT','txt301','test-txt-301',NULL,NULL,NULL,NULL,'test-txt-301',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3308,227,'AAAA','host302','2001:db8::7fa8',NULL,'2001:db8::7fa8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3309,256,'TXT','txt303','test-txt-303',NULL,NULL,NULL,NULL,'test-txt-303',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3310,214,'AAAA','host304','2001:db8::3eb6',NULL,'2001:db8::3eb6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3311,256,'PTR','ptr305','ptr305.in-addr.arpa.',NULL,NULL,NULL,'ptr305.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3312,242,'AAAA','host306','2001:db8::8ac',NULL,'2001:db8::8ac',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3313,245,'TXT','txt307','test-txt-307',NULL,NULL,NULL,NULL,'test-txt-307',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3314,219,'A','host308','198.51.22.254','198.51.22.254',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3315,220,'AAAA','host309','2001:db8::960b',NULL,'2001:db8::960b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3316,253,'TXT','txt310','test-txt-310',NULL,NULL,NULL,NULL,'test-txt-310',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3317,237,'PTR','ptr311','ptr311.in-addr.arpa.',NULL,NULL,NULL,'ptr311.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3318,256,'PTR','ptr312','ptr312.in-addr.arpa.',NULL,NULL,NULL,'ptr312.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3319,210,'TXT','txt313','test-txt-313',NULL,NULL,NULL,NULL,'test-txt-313',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3320,246,'TXT','txt314','test-txt-314',NULL,NULL,NULL,NULL,'test-txt-314',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3321,241,'AAAA','host315','2001:db8::8bd3',NULL,'2001:db8::8bd3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3322,258,'PTR','ptr316','ptr316.in-addr.arpa.',NULL,NULL,NULL,'ptr316.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3323,244,'PTR','ptr317','ptr317.in-addr.arpa.',NULL,NULL,NULL,'ptr317.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3324,240,'PTR','ptr318','ptr318.in-addr.arpa.',NULL,NULL,NULL,'ptr318.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3325,233,'A','host319','198.51.162.165','198.51.162.165',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3326,222,'CNAME','cname320','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3327,253,'CNAME','cname321','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3328,243,'A','host322','198.51.130.216','198.51.130.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3329,225,'PTR','ptr323','ptr323.in-addr.arpa.',NULL,NULL,NULL,'ptr323.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3330,218,'A','host324','198.51.197.150','198.51.197.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3331,254,'CNAME','cname325','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3332,238,'A','host326','198.51.12.22','198.51.12.22',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3333,210,'AAAA','host327','2001:db8::ed70',NULL,'2001:db8::ed70',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3334,218,'CNAME','cname328','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3335,216,'TXT','txt329','test-txt-329',NULL,NULL,NULL,NULL,'test-txt-329',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3336,237,'A','host330','198.51.112.111','198.51.112.111',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3337,236,'CNAME','cname331','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3338,233,'PTR','ptr332','ptr332.in-addr.arpa.',NULL,NULL,NULL,'ptr332.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3339,257,'CNAME','cname333','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3340,231,'PTR','ptr334','ptr334.in-addr.arpa.',NULL,NULL,NULL,'ptr334.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3341,255,'A','host335','198.51.152.247','198.51.152.247',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3342,259,'AAAA','host336','2001:db8::265b',NULL,'2001:db8::265b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3343,220,'AAAA','host337','2001:db8::88a5',NULL,'2001:db8::88a5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3344,233,'AAAA','host338','2001:db8::500b',NULL,'2001:db8::500b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3345,240,'PTR','ptr339','ptr339.in-addr.arpa.',NULL,NULL,NULL,'ptr339.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3346,244,'A','host340','198.51.178.155','198.51.178.155',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3347,245,'TXT','txt341','test-txt-341',NULL,NULL,NULL,NULL,'test-txt-341',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3348,235,'PTR','ptr342','ptr342.in-addr.arpa.',NULL,NULL,NULL,'ptr342.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3349,225,'A','host343','198.51.130.16','198.51.130.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3350,250,'TXT','txt344','test-txt-344',NULL,NULL,NULL,NULL,'test-txt-344',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3351,249,'AAAA','host345','2001:db8::55f2',NULL,'2001:db8::55f2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3352,234,'AAAA','host346','2001:db8::c9d9',NULL,'2001:db8::c9d9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3353,257,'CNAME','cname347','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3354,212,'AAAA','host348','2001:db8::e561',NULL,'2001:db8::e561',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3355,217,'CNAME','cname349','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3356,221,'TXT','txt350','test-txt-350',NULL,NULL,NULL,NULL,'test-txt-350',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3357,233,'CNAME','cname351','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3358,256,'CNAME','cname352','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3359,259,'A','host353','198.51.113.124','198.51.113.124',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3360,213,'PTR','ptr354','ptr354.in-addr.arpa.',NULL,NULL,NULL,'ptr354.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3361,233,'CNAME','cname355','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3362,223,'TXT','txt356','test-txt-356',NULL,NULL,NULL,NULL,'test-txt-356',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3363,256,'A','host357','198.51.105.167','198.51.105.167',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3364,252,'A','host358','198.51.15.241','198.51.15.241',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3365,215,'TXT','txt359','test-txt-359',NULL,NULL,NULL,NULL,'test-txt-359',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3366,249,'TXT','txt360','test-txt-360',NULL,NULL,NULL,NULL,'test-txt-360',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3367,259,'CNAME','cname361','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3368,254,'PTR','ptr362','ptr362.in-addr.arpa.',NULL,NULL,NULL,'ptr362.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3369,252,'CNAME','cname363','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3370,251,'CNAME','cname364','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3371,217,'CNAME','cname365','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3372,258,'CNAME','cname366','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3373,211,'CNAME','cname367','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3374,233,'AAAA','host368','2001:db8::df26',NULL,'2001:db8::df26',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3375,219,'A','host369','198.51.90.225','198.51.90.225',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3376,234,'PTR','ptr370','ptr370.in-addr.arpa.',NULL,NULL,NULL,'ptr370.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3377,220,'CNAME','cname371','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3378,232,'TXT','txt372','test-txt-372',NULL,NULL,NULL,NULL,'test-txt-372',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3379,247,'TXT','txt373','test-txt-373',NULL,NULL,NULL,NULL,'test-txt-373',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3380,253,'PTR','ptr374','ptr374.in-addr.arpa.',NULL,NULL,NULL,'ptr374.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3381,236,'AAAA','host375','2001:db8::5b93',NULL,'2001:db8::5b93',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3382,257,'A','host376','198.51.207.188','198.51.207.188',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3383,252,'AAAA','host377','2001:db8::13f5',NULL,'2001:db8::13f5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3384,220,'TXT','txt378','test-txt-378',NULL,NULL,NULL,NULL,'test-txt-378',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3385,229,'PTR','ptr379','ptr379.in-addr.arpa.',NULL,NULL,NULL,'ptr379.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3386,220,'CNAME','cname380','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3387,252,'CNAME','cname381','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3388,234,'CNAME','cname382','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3389,219,'AAAA','host383','2001:db8::a60',NULL,'2001:db8::a60',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3390,250,'TXT','txt384','test-txt-384',NULL,NULL,NULL,NULL,'test-txt-384',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3391,211,'AAAA','host385','2001:db8::2d84',NULL,'2001:db8::2d84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3392,251,'A','host386','198.51.129.118','198.51.129.118',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3393,252,'PTR','ptr387','ptr387.in-addr.arpa.',NULL,NULL,NULL,'ptr387.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3394,229,'AAAA','host388','2001:db8::6f13',NULL,'2001:db8::6f13',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3395,257,'CNAME','cname389','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3396,244,'CNAME','cname390','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3397,224,'A','host391','198.51.102.63','198.51.102.63',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3398,225,'TXT','txt392','test-txt-392',NULL,NULL,NULL,NULL,'test-txt-392',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3399,251,'TXT','txt393','test-txt-393',NULL,NULL,NULL,NULL,'test-txt-393',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3400,227,'TXT','txt394','test-txt-394',NULL,NULL,NULL,NULL,'test-txt-394',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3401,258,'AAAA','host395','2001:db8::a3fb',NULL,'2001:db8::a3fb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3402,249,'A','host396','198.51.18.247','198.51.18.247',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3403,239,'PTR','ptr397','ptr397.in-addr.arpa.',NULL,NULL,NULL,'ptr397.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3404,230,'TXT','txt398','test-txt-398',NULL,NULL,NULL,NULL,'test-txt-398',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3405,235,'CNAME','cname399','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3406,243,'A','host400','198.51.66.178','198.51.66.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3407,225,'PTR','ptr401','ptr401.in-addr.arpa.',NULL,NULL,NULL,'ptr401.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3408,243,'PTR','ptr402','ptr402.in-addr.arpa.',NULL,NULL,NULL,'ptr402.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3409,237,'AAAA','host403','2001:db8::afb0',NULL,'2001:db8::afb0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3410,250,'AAAA','host404','2001:db8::92da',NULL,'2001:db8::92da',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3411,230,'A','host405','198.51.233.28','198.51.233.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3412,251,'TXT','txt406','test-txt-406',NULL,NULL,NULL,NULL,'test-txt-406',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3413,254,'TXT','txt407','test-txt-407',NULL,NULL,NULL,NULL,'test-txt-407',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3414,216,'A','host408','198.51.8.2','198.51.8.2',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3415,219,'A','host409','198.51.23.209','198.51.23.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3416,250,'CNAME','cname410','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3417,218,'A','host411','198.51.69.111','198.51.69.111',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3418,229,'PTR','ptr412','ptr412.in-addr.arpa.',NULL,NULL,NULL,'ptr412.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3419,223,'CNAME','cname413','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3420,252,'CNAME','cname414','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3421,257,'CNAME','cname415','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3422,240,'TXT','txt416','test-txt-416',NULL,NULL,NULL,NULL,'test-txt-416',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3423,257,'A','host417','198.51.202.216','198.51.202.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3424,253,'AAAA','host418','2001:db8::1649',NULL,'2001:db8::1649',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3425,224,'PTR','ptr419','ptr419.in-addr.arpa.',NULL,NULL,NULL,'ptr419.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3426,220,'PTR','ptr420','ptr420.in-addr.arpa.',NULL,NULL,NULL,'ptr420.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3427,233,'A','host421','198.51.209.6','198.51.209.6',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3428,214,'AAAA','host422','2001:db8::2e65',NULL,'2001:db8::2e65',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3429,237,'AAAA','host423','2001:db8::f438',NULL,'2001:db8::f438',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3430,252,'CNAME','cname424','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3431,234,'CNAME','cname425','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3432,249,'A','host426','198.51.213.239','198.51.213.239',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3433,211,'PTR','ptr427','ptr427.in-addr.arpa.',NULL,NULL,NULL,'ptr427.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3434,254,'PTR','ptr428','ptr428.in-addr.arpa.',NULL,NULL,NULL,'ptr428.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3435,215,'CNAME','cname429','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3436,227,'PTR','ptr430','ptr430.in-addr.arpa.',NULL,NULL,NULL,'ptr430.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3437,252,'AAAA','host431','2001:db8::22a9',NULL,'2001:db8::22a9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3438,256,'PTR','ptr432','ptr432.in-addr.arpa.',NULL,NULL,NULL,'ptr432.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3439,218,'PTR','ptr433','ptr433.in-addr.arpa.',NULL,NULL,NULL,'ptr433.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3440,251,'TXT','txt434','test-txt-434',NULL,NULL,NULL,NULL,'test-txt-434',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3441,231,'A','host435','198.51.63.6','198.51.63.6',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3442,246,'AAAA','host436','2001:db8::af76',NULL,'2001:db8::af76',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3443,233,'AAAA','host437','2001:db8::e328',NULL,'2001:db8::e328',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3444,254,'PTR','ptr438','ptr438.in-addr.arpa.',NULL,NULL,NULL,'ptr438.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3445,232,'CNAME','cname439','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3446,251,'PTR','ptr440','ptr440.in-addr.arpa.',NULL,NULL,NULL,'ptr440.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3447,254,'TXT','txt441','test-txt-441',NULL,NULL,NULL,NULL,'test-txt-441',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3448,232,'TXT','txt442','test-txt-442',NULL,NULL,NULL,NULL,'test-txt-442',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3449,256,'AAAA','host443','2001:db8::d3f6',NULL,'2001:db8::d3f6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3450,235,'A','host444','198.51.129.80','198.51.129.80',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3451,236,'A','host445','198.51.130.238','198.51.130.238',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3452,250,'AAAA','host446','2001:db8::dcfb',NULL,'2001:db8::dcfb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3453,224,'PTR','ptr447','ptr447.in-addr.arpa.',NULL,NULL,NULL,'ptr447.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3454,248,'TXT','txt448','test-txt-448',NULL,NULL,NULL,NULL,'test-txt-448',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3455,215,'AAAA','host449','2001:db8::2c91',NULL,'2001:db8::2c91',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3456,253,'TXT','txt450','test-txt-450',NULL,NULL,NULL,NULL,'test-txt-450',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3457,240,'TXT','txt451','test-txt-451',NULL,NULL,NULL,NULL,'test-txt-451',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3458,216,'PTR','ptr452','ptr452.in-addr.arpa.',NULL,NULL,NULL,'ptr452.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3459,255,'CNAME','cname453','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3460,211,'A','host454','198.51.120.160','198.51.120.160',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3461,255,'TXT','txt455','test-txt-455',NULL,NULL,NULL,NULL,'test-txt-455',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3462,222,'PTR','ptr456','ptr456.in-addr.arpa.',NULL,NULL,NULL,'ptr456.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3463,250,'TXT','txt457','test-txt-457',NULL,NULL,NULL,NULL,'test-txt-457',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3464,251,'TXT','txt458','test-txt-458',NULL,NULL,NULL,NULL,'test-txt-458',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3465,252,'PTR','ptr459','ptr459.in-addr.arpa.',NULL,NULL,NULL,'ptr459.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3466,219,'A','host460','198.51.44.139','198.51.44.139',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3467,252,'TXT','txt461','test-txt-461',NULL,NULL,NULL,NULL,'test-txt-461',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3468,251,'PTR','ptr462','ptr462.in-addr.arpa.',NULL,NULL,NULL,'ptr462.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3469,246,'TXT','txt463','test-txt-463',NULL,NULL,NULL,NULL,'test-txt-463',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3470,225,'AAAA','host464','2001:db8::4fcd',NULL,'2001:db8::4fcd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3471,253,'AAAA','host465','2001:db8::1bb3',NULL,'2001:db8::1bb3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3472,252,'A','host466','198.51.201.254','198.51.201.254',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3473,225,'CNAME','cname467','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3474,252,'AAAA','host468','2001:db8::9e80',NULL,'2001:db8::9e80',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3475,231,'CNAME','cname469','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3476,254,'AAAA','host470','2001:db8::e84a',NULL,'2001:db8::e84a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3477,248,'AAAA','host471','2001:db8::b5ff',NULL,'2001:db8::b5ff',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3478,240,'AAAA','host472','2001:db8::ab8d',NULL,'2001:db8::ab8d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3479,234,'PTR','ptr473','ptr473.in-addr.arpa.',NULL,NULL,NULL,'ptr473.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3480,246,'AAAA','host474','2001:db8::d092',NULL,'2001:db8::d092',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3481,259,'PTR','ptr475','ptr475.in-addr.arpa.',NULL,NULL,NULL,'ptr475.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3482,259,'A','host476','198.51.85.57','198.51.85.57',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3483,233,'PTR','ptr477','ptr477.in-addr.arpa.',NULL,NULL,NULL,'ptr477.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3484,225,'TXT','txt478','test-txt-478',NULL,NULL,NULL,NULL,'test-txt-478',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3485,235,'CNAME','cname479','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3486,248,'AAAA','host480','2001:db8::c6e8',NULL,'2001:db8::c6e8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3487,229,'PTR','ptr481','ptr481.in-addr.arpa.',NULL,NULL,NULL,'ptr481.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3488,248,'A','host482','198.51.231.158','198.51.231.158',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3489,258,'PTR','ptr483','ptr483.in-addr.arpa.',NULL,NULL,NULL,'ptr483.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3490,250,'PTR','ptr484','ptr484.in-addr.arpa.',NULL,NULL,NULL,'ptr484.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3491,220,'AAAA','host485','2001:db8::f090',NULL,'2001:db8::f090',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3492,226,'PTR','ptr486','ptr486.in-addr.arpa.',NULL,NULL,NULL,'ptr486.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3493,212,'AAAA','host487','2001:db8::408',NULL,'2001:db8::408',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3494,241,'A','host488','198.51.18.246','198.51.18.246',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3495,249,'A','host489','198.51.91.41','198.51.91.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3496,259,'A','host490','198.51.91.236','198.51.91.236',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3497,231,'PTR','ptr491','ptr491.in-addr.arpa.',NULL,NULL,NULL,'ptr491.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3498,229,'A','host492','198.51.224.131','198.51.224.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3499,255,'PTR','ptr493','ptr493.in-addr.arpa.',NULL,NULL,NULL,'ptr493.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3500,246,'A','host494','198.51.202.127','198.51.202.127',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3501,258,'CNAME','cname495','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3502,243,'TXT','txt496','test-txt-496',NULL,NULL,NULL,NULL,'test-txt-496',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3503,256,'AAAA','host497','2001:db8::92b1',NULL,'2001:db8::92b1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3504,240,'AAAA','host498','2001:db8::dd4e',NULL,'2001:db8::dd4e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3505,216,'AAAA','host499','2001:db8::d32f',NULL,'2001:db8::d32f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3506,259,'A','host500','198.51.185.168','198.51.185.168',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3507,224,'AAAA','host501','2001:db8::bd78',NULL,'2001:db8::bd78',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3508,211,'A','host502','198.51.172.3','198.51.172.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3509,214,'PTR','ptr503','ptr503.in-addr.arpa.',NULL,NULL,NULL,'ptr503.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3510,214,'A','host504','198.51.118.228','198.51.118.228',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3511,251,'TXT','txt505','test-txt-505',NULL,NULL,NULL,NULL,'test-txt-505',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3512,259,'PTR','ptr506','ptr506.in-addr.arpa.',NULL,NULL,NULL,'ptr506.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3513,212,'TXT','txt507','test-txt-507',NULL,NULL,NULL,NULL,'test-txt-507',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3514,216,'PTR','ptr508','ptr508.in-addr.arpa.',NULL,NULL,NULL,'ptr508.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3515,238,'CNAME','cname509','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3516,210,'AAAA','host510','2001:db8::4bca',NULL,'2001:db8::4bca',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3517,217,'CNAME','cname511','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3518,237,'A','host512','198.51.17.174','198.51.17.174',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3519,243,'A','host513','198.51.62.142','198.51.62.142',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3520,259,'CNAME','cname514','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3521,246,'A','host515','198.51.9.67','198.51.9.67',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3522,252,'PTR','ptr516','ptr516.in-addr.arpa.',NULL,NULL,NULL,'ptr516.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3523,232,'AAAA','host517','2001:db8::ba44',NULL,'2001:db8::ba44',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3524,222,'TXT','txt518','test-txt-518',NULL,NULL,NULL,NULL,'test-txt-518',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3525,259,'A','host519','198.51.116.19','198.51.116.19',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3526,215,'PTR','ptr520','ptr520.in-addr.arpa.',NULL,NULL,NULL,'ptr520.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3527,251,'TXT','txt521','test-txt-521',NULL,NULL,NULL,NULL,'test-txt-521',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3528,254,'TXT','txt522','test-txt-522',NULL,NULL,NULL,NULL,'test-txt-522',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3529,215,'CNAME','cname523','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3530,236,'A','host524','198.51.114.209','198.51.114.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3531,216,'AAAA','host525','2001:db8::4290',NULL,'2001:db8::4290',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3532,213,'PTR','ptr526','ptr526.in-addr.arpa.',NULL,NULL,NULL,'ptr526.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3533,243,'A','host527','198.51.250.186','198.51.250.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3534,259,'PTR','ptr528','ptr528.in-addr.arpa.',NULL,NULL,NULL,'ptr528.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3535,210,'A','host529','198.51.89.14','198.51.89.14',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3536,257,'AAAA','host530','2001:db8::a4b8',NULL,'2001:db8::a4b8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3537,251,'PTR','ptr531','ptr531.in-addr.arpa.',NULL,NULL,NULL,'ptr531.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3538,215,'TXT','txt532','test-txt-532',NULL,NULL,NULL,NULL,'test-txt-532',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3539,222,'AAAA','host533','2001:db8::864c',NULL,'2001:db8::864c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3540,248,'CNAME','cname534','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3541,214,'AAAA','host535','2001:db8::442',NULL,'2001:db8::442',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3542,221,'CNAME','cname536','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3543,251,'CNAME','cname537','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3544,221,'A','host538','198.51.226.220','198.51.226.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3545,228,'A','host539','198.51.12.237','198.51.12.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3546,246,'CNAME','cname540','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3547,230,'PTR','ptr541','ptr541.in-addr.arpa.',NULL,NULL,NULL,'ptr541.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3548,215,'CNAME','cname542','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3549,222,'CNAME','cname543','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3550,255,'AAAA','host544','2001:db8::96c6',NULL,'2001:db8::96c6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3551,243,'A','host545','198.51.100.28','198.51.100.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3552,218,'PTR','ptr546','ptr546.in-addr.arpa.',NULL,NULL,NULL,'ptr546.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3553,255,'PTR','ptr547','ptr547.in-addr.arpa.',NULL,NULL,NULL,'ptr547.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3554,255,'CNAME','cname548','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3555,232,'CNAME','cname549','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3556,218,'PTR','ptr550','ptr550.in-addr.arpa.',NULL,NULL,NULL,'ptr550.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3557,218,'AAAA','host551','2001:db8::f45a',NULL,'2001:db8::f45a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3558,245,'PTR','ptr552','ptr552.in-addr.arpa.',NULL,NULL,NULL,'ptr552.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3559,248,'TXT','txt553','test-txt-553',NULL,NULL,NULL,NULL,'test-txt-553',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3560,254,'TXT','txt554','test-txt-554',NULL,NULL,NULL,NULL,'test-txt-554',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3561,223,'TXT','txt555','test-txt-555',NULL,NULL,NULL,NULL,'test-txt-555',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3562,239,'A','host556','198.51.226.93','198.51.226.93',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3563,256,'TXT','txt557','test-txt-557',NULL,NULL,NULL,NULL,'test-txt-557',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3564,219,'PTR','ptr558','ptr558.in-addr.arpa.',NULL,NULL,NULL,'ptr558.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3565,219,'TXT','txt559','test-txt-559',NULL,NULL,NULL,NULL,'test-txt-559',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3566,251,'AAAA','host560','2001:db8::d8f1',NULL,'2001:db8::d8f1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3567,245,'CNAME','cname561','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3568,248,'AAAA','host562','2001:db8::2307',NULL,'2001:db8::2307',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3569,235,'PTR','ptr563','ptr563.in-addr.arpa.',NULL,NULL,NULL,'ptr563.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3570,216,'A','host564','198.51.70.250','198.51.70.250',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3571,236,'TXT','txt565','test-txt-565',NULL,NULL,NULL,NULL,'test-txt-565',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3572,229,'AAAA','host566','2001:db8::c2e4',NULL,'2001:db8::c2e4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3573,251,'A','host567','198.51.243.184','198.51.243.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3574,233,'PTR','ptr568','ptr568.in-addr.arpa.',NULL,NULL,NULL,'ptr568.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3575,254,'AAAA','host569','2001:db8::e888',NULL,'2001:db8::e888',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3576,216,'TXT','txt570','test-txt-570',NULL,NULL,NULL,NULL,'test-txt-570',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3577,242,'CNAME','cname571','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3578,254,'AAAA','host572','2001:db8::e960',NULL,'2001:db8::e960',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3579,237,'AAAA','host573','2001:db8::471d',NULL,'2001:db8::471d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3580,258,'TXT','txt574','test-txt-574',NULL,NULL,NULL,NULL,'test-txt-574',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3581,227,'TXT','txt575','test-txt-575',NULL,NULL,NULL,NULL,'test-txt-575',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3582,242,'CNAME','cname576','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3583,251,'TXT','txt577','test-txt-577',NULL,NULL,NULL,NULL,'test-txt-577',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3584,258,'A','host578','198.51.173.231','198.51.173.231',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3585,231,'TXT','txt579','test-txt-579',NULL,NULL,NULL,NULL,'test-txt-579',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3586,256,'CNAME','cname580','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3587,211,'PTR','ptr581','ptr581.in-addr.arpa.',NULL,NULL,NULL,'ptr581.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3588,228,'AAAA','host582','2001:db8::90a9',NULL,'2001:db8::90a9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3589,211,'PTR','ptr583','ptr583.in-addr.arpa.',NULL,NULL,NULL,'ptr583.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3590,249,'TXT','txt584','test-txt-584',NULL,NULL,NULL,NULL,'test-txt-584',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3591,236,'PTR','ptr585','ptr585.in-addr.arpa.',NULL,NULL,NULL,'ptr585.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3592,251,'PTR','ptr586','ptr586.in-addr.arpa.',NULL,NULL,NULL,'ptr586.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3593,211,'A','host587','198.51.100.117','198.51.100.117',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3594,245,'TXT','txt588','test-txt-588',NULL,NULL,NULL,NULL,'test-txt-588',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3595,255,'CNAME','cname589','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3596,242,'TXT','txt590','test-txt-590',NULL,NULL,NULL,NULL,'test-txt-590',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3597,217,'A','host591','198.51.169.250','198.51.169.250',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3598,238,'PTR','ptr592','ptr592.in-addr.arpa.',NULL,NULL,NULL,'ptr592.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3599,225,'PTR','ptr593','ptr593.in-addr.arpa.',NULL,NULL,NULL,'ptr593.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3600,247,'CNAME','cname594','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3601,233,'A','host595','198.51.14.64','198.51.14.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3602,242,'AAAA','host596','2001:db8::6da7',NULL,'2001:db8::6da7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3603,222,'A','host597','198.51.29.202','198.51.29.202',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3604,215,'A','host598','198.51.244.144','198.51.244.144',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3605,220,'CNAME','cname599','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3606,215,'AAAA','host600','2001:db8::d1c3',NULL,'2001:db8::d1c3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3607,248,'TXT','txt601','test-txt-601',NULL,NULL,NULL,NULL,'test-txt-601',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3608,226,'CNAME','cname602','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3609,220,'PTR','ptr603','ptr603.in-addr.arpa.',NULL,NULL,NULL,'ptr603.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3610,251,'CNAME','cname604','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3611,256,'PTR','ptr605','ptr605.in-addr.arpa.',NULL,NULL,NULL,'ptr605.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3612,224,'PTR','ptr606','ptr606.in-addr.arpa.',NULL,NULL,NULL,'ptr606.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3613,253,'CNAME','cname607','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3614,210,'PTR','ptr608','ptr608.in-addr.arpa.',NULL,NULL,NULL,'ptr608.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3615,219,'AAAA','host609','2001:db8::c0be',NULL,'2001:db8::c0be',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3616,253,'A','host610','198.51.1.15','198.51.1.15',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3617,215,'CNAME','cname611','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3618,250,'AAAA','host612','2001:db8::8c53',NULL,'2001:db8::8c53',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3619,241,'A','host613','198.51.96.70','198.51.96.70',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3620,251,'TXT','txt614','test-txt-614',NULL,NULL,NULL,NULL,'test-txt-614',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3621,213,'A','host615','198.51.151.107','198.51.151.107',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3622,211,'AAAA','host616','2001:db8::465',NULL,'2001:db8::465',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3623,220,'A','host617','198.51.185.75','198.51.185.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3624,251,'A','host618','198.51.47.134','198.51.47.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3625,259,'CNAME','cname619','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3626,259,'TXT','txt620','test-txt-620',NULL,NULL,NULL,NULL,'test-txt-620',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3627,215,'AAAA','host621','2001:db8::df7e',NULL,'2001:db8::df7e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3628,239,'TXT','txt622','test-txt-622',NULL,NULL,NULL,NULL,'test-txt-622',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3629,222,'A','host623','198.51.218.40','198.51.218.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3630,249,'CNAME','cname624','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3631,258,'A','host625','198.51.185.121','198.51.185.121',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3632,224,'AAAA','host626','2001:db8::1648',NULL,'2001:db8::1648',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3633,234,'AAAA','host627','2001:db8::ef1d',NULL,'2001:db8::ef1d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3634,237,'TXT','txt628','test-txt-628',NULL,NULL,NULL,NULL,'test-txt-628',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3635,241,'PTR','ptr629','ptr629.in-addr.arpa.',NULL,NULL,NULL,'ptr629.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3636,248,'CNAME','cname630','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3637,215,'PTR','ptr631','ptr631.in-addr.arpa.',NULL,NULL,NULL,'ptr631.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3638,228,'AAAA','host632','2001:db8::6cc8',NULL,'2001:db8::6cc8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3639,241,'TXT','txt633','test-txt-633',NULL,NULL,NULL,NULL,'test-txt-633',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3640,226,'CNAME','cname634','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3641,247,'TXT','txt635','test-txt-635',NULL,NULL,NULL,NULL,'test-txt-635',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3642,253,'TXT','txt636','test-txt-636',NULL,NULL,NULL,NULL,'test-txt-636',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3643,258,'PTR','ptr637','ptr637.in-addr.arpa.',NULL,NULL,NULL,'ptr637.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3644,242,'AAAA','host638','2001:db8::45a3',NULL,'2001:db8::45a3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3645,259,'A','host639','198.51.226.68','198.51.226.68',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3646,241,'TXT','txt640','test-txt-640',NULL,NULL,NULL,NULL,'test-txt-640',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3647,214,'PTR','ptr641','ptr641.in-addr.arpa.',NULL,NULL,NULL,'ptr641.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3648,258,'A','host642','198.51.197.223','198.51.197.223',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3649,236,'CNAME','cname643','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3650,251,'AAAA','host644','2001:db8::4125',NULL,'2001:db8::4125',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3651,245,'TXT','txt645','test-txt-645',NULL,NULL,NULL,NULL,'test-txt-645',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3652,227,'PTR','ptr646','ptr646.in-addr.arpa.',NULL,NULL,NULL,'ptr646.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3653,250,'CNAME','cname647','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3654,219,'TXT','txt648','test-txt-648',NULL,NULL,NULL,NULL,'test-txt-648',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3655,246,'CNAME','cname649','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3656,243,'PTR','ptr650','ptr650.in-addr.arpa.',NULL,NULL,NULL,'ptr650.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3657,254,'TXT','txt651','test-txt-651',NULL,NULL,NULL,NULL,'test-txt-651',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3658,230,'A','host652','198.51.41.56','198.51.41.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3659,254,'PTR','ptr653','ptr653.in-addr.arpa.',NULL,NULL,NULL,'ptr653.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3660,230,'A','host654','198.51.196.131','198.51.196.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3661,221,'TXT','txt655','test-txt-655',NULL,NULL,NULL,NULL,'test-txt-655',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3662,231,'TXT','txt656','test-txt-656',NULL,NULL,NULL,NULL,'test-txt-656',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3663,254,'PTR','ptr657','ptr657.in-addr.arpa.',NULL,NULL,NULL,'ptr657.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3664,211,'PTR','ptr658','ptr658.in-addr.arpa.',NULL,NULL,NULL,'ptr658.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3665,241,'CNAME','cname659','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3666,225,'AAAA','host660','2001:db8::8145',NULL,'2001:db8::8145',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3667,226,'A','host661','198.51.2.178','198.51.2.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3668,235,'TXT','txt662','test-txt-662',NULL,NULL,NULL,NULL,'test-txt-662',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3669,218,'CNAME','cname663','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3670,247,'TXT','txt664','test-txt-664',NULL,NULL,NULL,NULL,'test-txt-664',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3671,240,'TXT','txt665','test-txt-665',NULL,NULL,NULL,NULL,'test-txt-665',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3672,236,'CNAME','cname666','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3673,251,'CNAME','cname667','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3674,256,'PTR','ptr668','ptr668.in-addr.arpa.',NULL,NULL,NULL,'ptr668.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3675,226,'A','host669','198.51.87.176','198.51.87.176',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3676,240,'PTR','ptr670','ptr670.in-addr.arpa.',NULL,NULL,NULL,'ptr670.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3677,256,'PTR','ptr671','ptr671.in-addr.arpa.',NULL,NULL,NULL,'ptr671.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3678,239,'AAAA','host672','2001:db8::ccc6',NULL,'2001:db8::ccc6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3679,250,'PTR','ptr673','ptr673.in-addr.arpa.',NULL,NULL,NULL,'ptr673.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3680,225,'AAAA','host674','2001:db8::4272',NULL,'2001:db8::4272',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3681,210,'CNAME','cname675','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3682,227,'TXT','txt676','test-txt-676',NULL,NULL,NULL,NULL,'test-txt-676',3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3683,255,'PTR','ptr677','ptr677.in-addr.arpa.',NULL,NULL,NULL,'ptr677.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:22',NULL,'2025-10-24 14:40:22',NULL,NULL,NULL,NULL),
(3684,254,'CNAME','cname678','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3685,253,'TXT','txt679','test-txt-679',NULL,NULL,NULL,NULL,'test-txt-679',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3686,234,'A','host680','198.51.85.121','198.51.85.121',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3687,211,'AAAA','host681','2001:db8::2508',NULL,'2001:db8::2508',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3688,243,'TXT','txt682','test-txt-682',NULL,NULL,NULL,NULL,'test-txt-682',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3689,233,'TXT','txt683','test-txt-683',NULL,NULL,NULL,NULL,'test-txt-683',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3690,221,'A','host684','198.51.151.91','198.51.151.91',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3691,244,'PTR','ptr685','ptr685.in-addr.arpa.',NULL,NULL,NULL,'ptr685.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3692,256,'PTR','ptr686','ptr686.in-addr.arpa.',NULL,NULL,NULL,'ptr686.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3693,251,'PTR','ptr687','ptr687.in-addr.arpa.',NULL,NULL,NULL,'ptr687.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3694,237,'TXT','txt688','test-txt-688',NULL,NULL,NULL,NULL,'test-txt-688',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3695,222,'A','host689','198.51.62.76','198.51.62.76',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3696,225,'CNAME','cname690','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3697,245,'AAAA','host691','2001:db8::fe8f',NULL,'2001:db8::fe8f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3698,241,'A','host692','198.51.205.212','198.51.205.212',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3699,254,'PTR','ptr693','ptr693.in-addr.arpa.',NULL,NULL,NULL,'ptr693.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3700,241,'PTR','ptr694','ptr694.in-addr.arpa.',NULL,NULL,NULL,'ptr694.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3701,221,'AAAA','host695','2001:db8::2272',NULL,'2001:db8::2272',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3702,246,'AAAA','host696','2001:db8::c828',NULL,'2001:db8::c828',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3703,245,'CNAME','cname697','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3704,252,'PTR','ptr698','ptr698.in-addr.arpa.',NULL,NULL,NULL,'ptr698.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3705,246,'A','host699','198.51.164.236','198.51.164.236',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3706,251,'PTR','ptr700','ptr700.in-addr.arpa.',NULL,NULL,NULL,'ptr700.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3707,213,'AAAA','host701','2001:db8::cec8',NULL,'2001:db8::cec8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3708,242,'PTR','ptr702','ptr702.in-addr.arpa.',NULL,NULL,NULL,'ptr702.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3709,232,'PTR','ptr703','ptr703.in-addr.arpa.',NULL,NULL,NULL,'ptr703.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3710,233,'PTR','ptr704','ptr704.in-addr.arpa.',NULL,NULL,NULL,'ptr704.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3711,239,'AAAA','host705','2001:db8::cbbd',NULL,'2001:db8::cbbd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3712,217,'AAAA','host706','2001:db8::4441',NULL,'2001:db8::4441',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3713,250,'TXT','txt707','test-txt-707',NULL,NULL,NULL,NULL,'test-txt-707',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3714,214,'PTR','ptr708','ptr708.in-addr.arpa.',NULL,NULL,NULL,'ptr708.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3715,215,'CNAME','cname709','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3716,233,'TXT','txt710','test-txt-710',NULL,NULL,NULL,NULL,'test-txt-710',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3717,239,'PTR','ptr711','ptr711.in-addr.arpa.',NULL,NULL,NULL,'ptr711.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3718,246,'AAAA','host712','2001:db8::766a',NULL,'2001:db8::766a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3719,243,'PTR','ptr713','ptr713.in-addr.arpa.',NULL,NULL,NULL,'ptr713.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3720,249,'A','host714','198.51.128.237','198.51.128.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3721,259,'A','host715','198.51.64.131','198.51.64.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3722,254,'AAAA','host716','2001:db8::2fd0',NULL,'2001:db8::2fd0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3723,245,'AAAA','host717','2001:db8::7484',NULL,'2001:db8::7484',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3724,231,'PTR','ptr718','ptr718.in-addr.arpa.',NULL,NULL,NULL,'ptr718.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3725,241,'A','host719','198.51.94.6','198.51.94.6',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3726,212,'PTR','ptr720','ptr720.in-addr.arpa.',NULL,NULL,NULL,'ptr720.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3727,232,'A','host721','198.51.216.62','198.51.216.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3728,246,'PTR','ptr722','ptr722.in-addr.arpa.',NULL,NULL,NULL,'ptr722.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3729,241,'A','host723','198.51.33.127','198.51.33.127',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3730,212,'AAAA','host724','2001:db8::98ea',NULL,'2001:db8::98ea',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3731,246,'AAAA','host725','2001:db8::eb54',NULL,'2001:db8::eb54',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3732,224,'TXT','txt726','test-txt-726',NULL,NULL,NULL,NULL,'test-txt-726',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3733,246,'PTR','ptr727','ptr727.in-addr.arpa.',NULL,NULL,NULL,'ptr727.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3734,252,'CNAME','cname728','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3735,231,'AAAA','host729','2001:db8::c3fc',NULL,'2001:db8::c3fc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3736,227,'TXT','txt730','test-txt-730',NULL,NULL,NULL,NULL,'test-txt-730',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3737,241,'A','host731','198.51.194.71','198.51.194.71',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3738,247,'CNAME','cname732','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3739,253,'TXT','txt733','test-txt-733',NULL,NULL,NULL,NULL,'test-txt-733',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3740,259,'AAAA','host734','2001:db8::c99c',NULL,'2001:db8::c99c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3741,226,'PTR','ptr735','ptr735.in-addr.arpa.',NULL,NULL,NULL,'ptr735.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3742,241,'CNAME','cname736','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3743,238,'PTR','ptr737','ptr737.in-addr.arpa.',NULL,NULL,NULL,'ptr737.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3744,219,'AAAA','host738','2001:db8::f5d6',NULL,'2001:db8::f5d6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3745,257,'A','host739','198.51.238.155','198.51.238.155',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3746,214,'TXT','txt740','test-txt-740',NULL,NULL,NULL,NULL,'test-txt-740',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3747,233,'CNAME','cname741','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3748,254,'PTR','ptr742','ptr742.in-addr.arpa.',NULL,NULL,NULL,'ptr742.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3749,217,'TXT','txt743','test-txt-743',NULL,NULL,NULL,NULL,'test-txt-743',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3750,256,'AAAA','host744','2001:db8::1001',NULL,'2001:db8::1001',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3751,252,'AAAA','host745','2001:db8::6ece',NULL,'2001:db8::6ece',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3752,239,'CNAME','cname746','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3753,218,'TXT','txt747','test-txt-747',NULL,NULL,NULL,NULL,'test-txt-747',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3754,254,'TXT','txt748','test-txt-748',NULL,NULL,NULL,NULL,'test-txt-748',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3755,247,'TXT','txt749','test-txt-749',NULL,NULL,NULL,NULL,'test-txt-749',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3756,236,'PTR','ptr750','ptr750.in-addr.arpa.',NULL,NULL,NULL,'ptr750.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3757,224,'TXT','txt751','test-txt-751',NULL,NULL,NULL,NULL,'test-txt-751',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3758,211,'AAAA','host752','2001:db8::ef0c',NULL,'2001:db8::ef0c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3759,218,'PTR','ptr753','ptr753.in-addr.arpa.',NULL,NULL,NULL,'ptr753.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3760,259,'CNAME','cname754','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3761,212,'AAAA','host755','2001:db8::2e30',NULL,'2001:db8::2e30',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3762,217,'CNAME','cname756','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3763,258,'TXT','txt757','test-txt-757',NULL,NULL,NULL,NULL,'test-txt-757',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3764,250,'TXT','txt758','test-txt-758',NULL,NULL,NULL,NULL,'test-txt-758',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3765,257,'A','host759','198.51.239.9','198.51.239.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3766,257,'PTR','ptr760','ptr760.in-addr.arpa.',NULL,NULL,NULL,'ptr760.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3767,231,'PTR','ptr761','ptr761.in-addr.arpa.',NULL,NULL,NULL,'ptr761.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3768,224,'TXT','txt762','test-txt-762',NULL,NULL,NULL,NULL,'test-txt-762',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3769,250,'PTR','ptr763','ptr763.in-addr.arpa.',NULL,NULL,NULL,'ptr763.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3770,212,'TXT','txt764','test-txt-764',NULL,NULL,NULL,NULL,'test-txt-764',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3771,234,'CNAME','cname765','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3772,253,'CNAME','cname766','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3773,227,'A','host767','198.51.86.33','198.51.86.33',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3774,230,'TXT','txt768','test-txt-768',NULL,NULL,NULL,NULL,'test-txt-768',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3775,248,'A','host769','198.51.78.203','198.51.78.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3776,225,'CNAME','cname770','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3777,255,'A','host771','198.51.34.40','198.51.34.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3778,221,'AAAA','host772','2001:db8::7270',NULL,'2001:db8::7270',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3779,237,'A','host773','198.51.62.201','198.51.62.201',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3780,225,'PTR','ptr774','ptr774.in-addr.arpa.',NULL,NULL,NULL,'ptr774.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3781,240,'TXT','txt775','test-txt-775',NULL,NULL,NULL,NULL,'test-txt-775',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3782,215,'AAAA','host776','2001:db8::e48f',NULL,'2001:db8::e48f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3783,221,'A','host777','198.51.171.26','198.51.171.26',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3784,225,'CNAME','cname778','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3785,222,'AAAA','host779','2001:db8::1f4d',NULL,'2001:db8::1f4d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3786,249,'TXT','txt780','test-txt-780',NULL,NULL,NULL,NULL,'test-txt-780',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3787,215,'TXT','txt781','test-txt-781',NULL,NULL,NULL,NULL,'test-txt-781',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3788,219,'PTR','ptr782','ptr782.in-addr.arpa.',NULL,NULL,NULL,'ptr782.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3789,259,'PTR','ptr783','ptr783.in-addr.arpa.',NULL,NULL,NULL,'ptr783.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3790,245,'CNAME','cname784','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3791,232,'A','host785','198.51.138.138','198.51.138.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3792,225,'A','host786','198.51.34.226','198.51.34.226',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3793,228,'CNAME','cname787','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3794,256,'CNAME','cname788','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3795,257,'AAAA','host789','2001:db8::6591',NULL,'2001:db8::6591',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3796,214,'A','host790','198.51.65.109','198.51.65.109',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3797,226,'AAAA','host791','2001:db8::39cb',NULL,'2001:db8::39cb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3798,258,'CNAME','cname792','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3799,237,'AAAA','host793','2001:db8::360e',NULL,'2001:db8::360e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3800,220,'AAAA','host794','2001:db8::7ad0',NULL,'2001:db8::7ad0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3801,231,'CNAME','cname795','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3802,253,'CNAME','cname796','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3803,259,'CNAME','cname797','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3804,242,'TXT','txt798','test-txt-798',NULL,NULL,NULL,NULL,'test-txt-798',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3805,252,'TXT','txt799','test-txt-799',NULL,NULL,NULL,NULL,'test-txt-799',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3806,245,'TXT','txt800','test-txt-800',NULL,NULL,NULL,NULL,'test-txt-800',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3807,216,'AAAA','host801','2001:db8::3037',NULL,'2001:db8::3037',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3808,229,'TXT','txt802','test-txt-802',NULL,NULL,NULL,NULL,'test-txt-802',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3809,259,'CNAME','cname803','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3810,257,'A','host804','198.51.121.10','198.51.121.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3811,258,'A','host805','198.51.153.87','198.51.153.87',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3812,252,'AAAA','host806','2001:db8::6ab9',NULL,'2001:db8::6ab9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3813,249,'TXT','txt807','test-txt-807',NULL,NULL,NULL,NULL,'test-txt-807',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3814,254,'A','host808','198.51.41.144','198.51.41.144',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3815,216,'A','host809','198.51.95.35','198.51.95.35',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3816,226,'PTR','ptr810','ptr810.in-addr.arpa.',NULL,NULL,NULL,'ptr810.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3817,210,'AAAA','host811','2001:db8::55c',NULL,'2001:db8::55c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3818,252,'TXT','txt812','test-txt-812',NULL,NULL,NULL,NULL,'test-txt-812',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3819,256,'CNAME','cname813','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3820,248,'AAAA','host814','2001:db8::37ca',NULL,'2001:db8::37ca',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3821,258,'A','host815','198.51.70.162','198.51.70.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3822,210,'CNAME','cname816','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3823,240,'AAAA','host817','2001:db8::501e',NULL,'2001:db8::501e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3824,234,'A','host818','198.51.189.67','198.51.189.67',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3825,252,'CNAME','cname819','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3826,259,'TXT','txt820','test-txt-820',NULL,NULL,NULL,NULL,'test-txt-820',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3827,241,'AAAA','host821','2001:db8::d874',NULL,'2001:db8::d874',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3828,250,'TXT','txt822','test-txt-822',NULL,NULL,NULL,NULL,'test-txt-822',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3829,244,'TXT','txt823','test-txt-823',NULL,NULL,NULL,NULL,'test-txt-823',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3830,243,'AAAA','host824','2001:db8::871f',NULL,'2001:db8::871f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3831,225,'TXT','txt825','test-txt-825',NULL,NULL,NULL,NULL,'test-txt-825',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3832,230,'TXT','txt826','test-txt-826',NULL,NULL,NULL,NULL,'test-txt-826',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3833,230,'AAAA','host827','2001:db8::b6a9',NULL,'2001:db8::b6a9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3834,238,'A','host828','198.51.177.34','198.51.177.34',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3835,246,'PTR','ptr829','ptr829.in-addr.arpa.',NULL,NULL,NULL,'ptr829.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3836,221,'CNAME','cname830','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3837,253,'PTR','ptr831','ptr831.in-addr.arpa.',NULL,NULL,NULL,'ptr831.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3838,230,'TXT','txt832','test-txt-832',NULL,NULL,NULL,NULL,'test-txt-832',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3839,228,'CNAME','cname833','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3840,223,'TXT','txt834','test-txt-834',NULL,NULL,NULL,NULL,'test-txt-834',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3841,228,'A','host835','198.51.197.64','198.51.197.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3842,229,'TXT','txt836','test-txt-836',NULL,NULL,NULL,NULL,'test-txt-836',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3843,250,'CNAME','cname837','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3844,234,'CNAME','cname838','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3845,223,'CNAME','cname839','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3846,241,'AAAA','host840','2001:db8::a5bc',NULL,'2001:db8::a5bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3847,215,'AAAA','host841','2001:db8::cdf0',NULL,'2001:db8::cdf0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3848,244,'PTR','ptr842','ptr842.in-addr.arpa.',NULL,NULL,NULL,'ptr842.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3849,211,'AAAA','host843','2001:db8::a244',NULL,'2001:db8::a244',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3850,255,'CNAME','cname844','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3851,254,'TXT','txt845','test-txt-845',NULL,NULL,NULL,NULL,'test-txt-845',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3852,211,'AAAA','host846','2001:db8::3829',NULL,'2001:db8::3829',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3853,252,'TXT','txt847','test-txt-847',NULL,NULL,NULL,NULL,'test-txt-847',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3854,246,'TXT','txt848','test-txt-848',NULL,NULL,NULL,NULL,'test-txt-848',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3855,238,'CNAME','cname849','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3856,247,'A','host850','198.51.191.157','198.51.191.157',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3857,214,'TXT','txt851','test-txt-851',NULL,NULL,NULL,NULL,'test-txt-851',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3858,232,'A','host852','198.51.189.83','198.51.189.83',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3859,255,'A','host853','198.51.137.113','198.51.137.113',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3860,258,'A','host854','198.51.23.60','198.51.23.60',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3861,254,'CNAME','cname855','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3862,229,'A','host856','198.51.206.247','198.51.206.247',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3863,238,'CNAME','cname857','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3864,252,'AAAA','host858','2001:db8::b117',NULL,'2001:db8::b117',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3865,228,'AAAA','host859','2001:db8::ea6d',NULL,'2001:db8::ea6d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3866,231,'TXT','txt860','test-txt-860',NULL,NULL,NULL,NULL,'test-txt-860',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3867,221,'A','host861','198.51.199.205','198.51.199.205',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3868,258,'TXT','txt862','test-txt-862',NULL,NULL,NULL,NULL,'test-txt-862',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3869,232,'CNAME','cname863','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3870,242,'CNAME','cname864','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3871,235,'TXT','txt865','test-txt-865',NULL,NULL,NULL,NULL,'test-txt-865',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3872,243,'PTR','ptr866','ptr866.in-addr.arpa.',NULL,NULL,NULL,'ptr866.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3873,216,'PTR','ptr867','ptr867.in-addr.arpa.',NULL,NULL,NULL,'ptr867.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3874,256,'CNAME','cname868','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3875,248,'AAAA','host869','2001:db8::3b22',NULL,'2001:db8::3b22',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3876,256,'CNAME','cname870','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3877,250,'AAAA','host871','2001:db8::a62a',NULL,'2001:db8::a62a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3878,242,'A','host872','198.51.155.102','198.51.155.102',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3879,220,'PTR','ptr873','ptr873.in-addr.arpa.',NULL,NULL,NULL,'ptr873.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3880,242,'CNAME','cname874','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3881,235,'AAAA','host875','2001:db8::f32',NULL,'2001:db8::f32',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3882,256,'PTR','ptr876','ptr876.in-addr.arpa.',NULL,NULL,NULL,'ptr876.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3883,250,'TXT','txt877','test-txt-877',NULL,NULL,NULL,NULL,'test-txt-877',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3884,250,'PTR','ptr878','ptr878.in-addr.arpa.',NULL,NULL,NULL,'ptr878.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3885,225,'TXT','txt879','test-txt-879',NULL,NULL,NULL,NULL,'test-txt-879',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3886,235,'A','host880','198.51.98.85','198.51.98.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3887,233,'AAAA','host881','2001:db8::fa8e',NULL,'2001:db8::fa8e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3888,215,'AAAA','host882','2001:db8::fe6b',NULL,'2001:db8::fe6b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3889,250,'TXT','txt883','test-txt-883',NULL,NULL,NULL,NULL,'test-txt-883',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3890,257,'AAAA','host884','2001:db8::bdb1',NULL,'2001:db8::bdb1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3891,239,'PTR','ptr885','ptr885.in-addr.arpa.',NULL,NULL,NULL,'ptr885.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3892,219,'A','host886','198.51.152.159','198.51.152.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3893,244,'TXT','txt887','test-txt-887',NULL,NULL,NULL,NULL,'test-txt-887',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3894,238,'TXT','txt888','test-txt-888',NULL,NULL,NULL,NULL,'test-txt-888',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3895,254,'A','host889','198.51.128.151','198.51.128.151',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3896,240,'PTR','ptr890','ptr890.in-addr.arpa.',NULL,NULL,NULL,'ptr890.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3897,227,'AAAA','host891','2001:db8::682e',NULL,'2001:db8::682e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3898,248,'TXT','txt892','test-txt-892',NULL,NULL,NULL,NULL,'test-txt-892',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3899,254,'CNAME','cname893','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3900,211,'CNAME','cname894','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3901,234,'AAAA','host895','2001:db8::455d',NULL,'2001:db8::455d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3902,211,'CNAME','cname896','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3903,230,'PTR','ptr897','ptr897.in-addr.arpa.',NULL,NULL,NULL,'ptr897.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3904,223,'AAAA','host898','2001:db8::e772',NULL,'2001:db8::e772',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3905,211,'AAAA','host899','2001:db8::e5c8',NULL,'2001:db8::e5c8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3906,234,'TXT','txt900','test-txt-900',NULL,NULL,NULL,NULL,'test-txt-900',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3907,215,'CNAME','cname901','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3908,211,'CNAME','cname902','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3909,252,'CNAME','cname903','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3910,232,'CNAME','cname904','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3911,220,'AAAA','host905','2001:db8::147c',NULL,'2001:db8::147c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3912,239,'TXT','txt906','test-txt-906',NULL,NULL,NULL,NULL,'test-txt-906',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3913,257,'TXT','txt907','test-txt-907',NULL,NULL,NULL,NULL,'test-txt-907',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3914,216,'TXT','txt908','test-txt-908',NULL,NULL,NULL,NULL,'test-txt-908',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3915,250,'PTR','ptr909','ptr909.in-addr.arpa.',NULL,NULL,NULL,'ptr909.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3916,247,'AAAA','host910','2001:db8::7702',NULL,'2001:db8::7702',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3917,236,'CNAME','cname911','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3918,252,'CNAME','cname912','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3919,228,'PTR','ptr913','ptr913.in-addr.arpa.',NULL,NULL,NULL,'ptr913.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3920,252,'A','host914','198.51.143.5','198.51.143.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3921,253,'CNAME','cname915','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3922,247,'A','host916','198.51.226.88','198.51.226.88',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3923,238,'TXT','txt917','test-txt-917',NULL,NULL,NULL,NULL,'test-txt-917',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3924,254,'AAAA','host918','2001:db8::4b21',NULL,'2001:db8::4b21',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3925,247,'A','host919','198.51.174.141','198.51.174.141',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3926,244,'A','host920','198.51.183.166','198.51.183.166',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3927,233,'A','host921','198.51.85.207','198.51.85.207',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3928,251,'TXT','txt922','test-txt-922',NULL,NULL,NULL,NULL,'test-txt-922',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3929,221,'CNAME','cname923','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3930,214,'AAAA','host924','2001:db8::302',NULL,'2001:db8::302',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3931,257,'PTR','ptr925','ptr925.in-addr.arpa.',NULL,NULL,NULL,'ptr925.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3932,236,'A','host926','198.51.64.50','198.51.64.50',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3933,222,'CNAME','cname927','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3934,218,'PTR','ptr928','ptr928.in-addr.arpa.',NULL,NULL,NULL,'ptr928.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3935,219,'TXT','txt929','test-txt-929',NULL,NULL,NULL,NULL,'test-txt-929',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3936,231,'PTR','ptr930','ptr930.in-addr.arpa.',NULL,NULL,NULL,'ptr930.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3937,251,'CNAME','cname931','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3938,253,'CNAME','cname932','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3939,251,'PTR','ptr933','ptr933.in-addr.arpa.',NULL,NULL,NULL,'ptr933.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3940,230,'CNAME','cname934','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3941,229,'PTR','ptr935','ptr935.in-addr.arpa.',NULL,NULL,NULL,'ptr935.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3942,211,'PTR','ptr936','ptr936.in-addr.arpa.',NULL,NULL,NULL,'ptr936.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3943,236,'CNAME','cname937','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3944,230,'TXT','txt938','test-txt-938',NULL,NULL,NULL,NULL,'test-txt-938',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3945,250,'PTR','ptr939','ptr939.in-addr.arpa.',NULL,NULL,NULL,'ptr939.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3946,253,'PTR','ptr940','ptr940.in-addr.arpa.',NULL,NULL,NULL,'ptr940.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3947,251,'AAAA','host941','2001:db8::b94e',NULL,'2001:db8::b94e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3948,235,'PTR','ptr942','ptr942.in-addr.arpa.',NULL,NULL,NULL,'ptr942.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3949,232,'CNAME','cname943','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3950,255,'TXT','txt944','test-txt-944',NULL,NULL,NULL,NULL,'test-txt-944',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3951,234,'TXT','txt945','test-txt-945',NULL,NULL,NULL,NULL,'test-txt-945',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3952,250,'TXT','txt946','test-txt-946',NULL,NULL,NULL,NULL,'test-txt-946',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3953,233,'AAAA','host947','2001:db8::fa5b',NULL,'2001:db8::fa5b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3954,220,'PTR','ptr948','ptr948.in-addr.arpa.',NULL,NULL,NULL,'ptr948.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3955,250,'PTR','ptr949','ptr949.in-addr.arpa.',NULL,NULL,NULL,'ptr949.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3956,253,'TXT','txt950','test-txt-950',NULL,NULL,NULL,NULL,'test-txt-950',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3957,258,'TXT','txt951','test-txt-951',NULL,NULL,NULL,NULL,'test-txt-951',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3958,253,'CNAME','cname952','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3959,255,'A','host953','198.51.231.45','198.51.231.45',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3960,246,'A','host954','198.51.106.73','198.51.106.73',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3961,219,'AAAA','host955','2001:db8::a4ea',NULL,'2001:db8::a4ea',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3962,248,'TXT','txt956','test-txt-956',NULL,NULL,NULL,NULL,'test-txt-956',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3963,253,'TXT','txt957','test-txt-957',NULL,NULL,NULL,NULL,'test-txt-957',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3964,228,'CNAME','cname958','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3965,231,'CNAME','cname959','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3966,213,'PTR','ptr960','ptr960.in-addr.arpa.',NULL,NULL,NULL,'ptr960.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3967,213,'CNAME','cname961','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3968,252,'CNAME','cname962','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3969,213,'TXT','txt963','test-txt-963',NULL,NULL,NULL,NULL,'test-txt-963',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3970,248,'AAAA','host964','2001:db8::2ee8',NULL,'2001:db8::2ee8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3971,251,'AAAA','host965','2001:db8::a3e8',NULL,'2001:db8::a3e8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3972,220,'PTR','ptr966','ptr966.in-addr.arpa.',NULL,NULL,NULL,'ptr966.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3973,256,'AAAA','host967','2001:db8::90ef',NULL,'2001:db8::90ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3974,210,'AAAA','host968','2001:db8::343d',NULL,'2001:db8::343d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3975,213,'A','host969','198.51.116.134','198.51.116.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3976,222,'A','host970','198.51.95.191','198.51.95.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3977,223,'AAAA','host971','2001:db8::191f',NULL,'2001:db8::191f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3978,256,'CNAME','cname972','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3979,251,'CNAME','cname973','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3980,217,'AAAA','host974','2001:db8::8982',NULL,'2001:db8::8982',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3981,259,'TXT','txt975','test-txt-975',NULL,NULL,NULL,NULL,'test-txt-975',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3982,254,'A','host976','198.51.48.14','198.51.48.14',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3983,213,'A','host977','198.51.5.212','198.51.5.212',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3984,248,'AAAA','host978','2001:db8::5c1b',NULL,'2001:db8::5c1b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3985,255,'AAAA','host979','2001:db8::4537',NULL,'2001:db8::4537',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3986,231,'A','host980','198.51.84.154','198.51.84.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3987,249,'AAAA','host981','2001:db8::fc22',NULL,'2001:db8::fc22',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3988,244,'TXT','txt982','test-txt-982',NULL,NULL,NULL,NULL,'test-txt-982',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3989,243,'A','host983','198.51.192.181','198.51.192.181',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3990,254,'A','host984','198.51.201.16','198.51.201.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3991,257,'A','host985','198.51.176.84','198.51.176.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3992,211,'TXT','txt986','test-txt-986',NULL,NULL,NULL,NULL,'test-txt-986',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3993,214,'AAAA','host987','2001:db8::917b',NULL,'2001:db8::917b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3994,233,'TXT','txt988','test-txt-988',NULL,NULL,NULL,NULL,'test-txt-988',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3995,251,'TXT','txt989','test-txt-989',NULL,NULL,NULL,NULL,'test-txt-989',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3996,246,'AAAA','host990','2001:db8::c22a',NULL,'2001:db8::c22a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3997,256,'AAAA','host991','2001:db8::34aa',NULL,'2001:db8::34aa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3998,244,'CNAME','cname992','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(3999,237,'AAAA','host993','2001:db8::f686',NULL,'2001:db8::f686',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4000,215,'TXT','txt994','test-txt-994',NULL,NULL,NULL,NULL,'test-txt-994',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4001,229,'PTR','ptr995','ptr995.in-addr.arpa.',NULL,NULL,NULL,'ptr995.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4002,237,'CNAME','cname996','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4003,252,'TXT','txt997','test-txt-997',NULL,NULL,NULL,NULL,'test-txt-997',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4004,230,'AAAA','host998','2001:db8::4117',NULL,'2001:db8::4117',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4005,222,'CNAME','cname999','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL),
(4006,254,'TXT','txt1000','test-txt-1000',NULL,NULL,NULL,NULL,'test-txt-1000',3600,NULL,NULL,'active',1,'2025-10-24 14:40:23',NULL,'2025-10-24 14:40:23',NULL,NULL,NULL,NULL);
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
(2,'guittou','guittou@gmail.com','$2y$10$.CJ6UeeKXSj7O3dZGcdtw.bjXze2e5z.n58462/hS.Rk4VgH5D21q','database','2025-10-20 09:24:16','2025-10-24 16:18:08',1);
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
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
INSERT INTO `zone_file_includes` VALUES
(35,219,250,1,'2025-10-24 16:40:21'),
(36,217,251,2,'2025-10-24 16:40:21'),
(37,240,252,3,'2025-10-24 16:40:21'),
(38,235,253,4,'2025-10-24 16:40:21'),
(39,249,254,5,'2025-10-24 16:40:21'),
(40,210,255,6,'2025-10-24 16:40:21'),
(41,236,256,7,'2025-10-24 16:40:21'),
(42,232,257,8,'2025-10-24 16:40:21'),
(43,221,258,9,'2025-10-24 16:40:21'),
(44,217,259,10,'2025-10-24 16:40:21');
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
) ENGINE=InnoDB AUTO_INCREMENT=135 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_validation`
--

LOCK TABLES `zone_file_validation` WRITE;
/*!40000 ALTER TABLE `zone_file_validation` DISABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=260 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(210,'test-master-1.local','db.test-master-1.local',NULL,'$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102401 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n\n$INCLUDE includes/common-include-6.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(211,'test-master-2.local','db.test-master-2.local',NULL,'$ORIGIN test-master-2.local.\n$TTL 3600\n@ IN SOA ns1.test-master-2.local. admin.test-master-2.local. ( 2025102402 3600 1800 604800 86400 )\n    IN NS ns1.test-master-2.local.\nns1 IN A 192.0.2.3\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(212,'test-master-3.local','db.test-master-3.local',NULL,'$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102403 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(213,'test-master-4.local','db.test-master-4.local',NULL,'$ORIGIN test-master-4.local.\n$TTL 3600\n@ IN SOA ns1.test-master-4.local. admin.test-master-4.local. ( 2025102404 3600 1800 604800 86400 )\n    IN NS ns1.test-master-4.local.\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(214,'test-master-5.local','db.test-master-5.local',NULL,'$ORIGIN test-master-5.local.\n$TTL 3600\n@ IN SOA ns1.test-master-5.local. admin.test-master-5.local. ( 2025102405 3600 1800 604800 86400 )\n    IN NS ns1.test-master-5.local.\nns1 IN A 192.0.2.6\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(215,'test-master-6.local','db.test-master-6.local',NULL,'$ORIGIN test-master-6.local.\n$TTL 3600\n@ IN SOA ns1.test-master-6.local. admin.test-master-6.local. ( 2025102406 3600 1800 604800 86400 )\n    IN NS ns1.test-master-6.local.\nns1 IN A 192.0.2.7\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(216,'test-master-7.local','db.test-master-7.local',NULL,'$ORIGIN test-master-7.local.\n$TTL 3600\n@ IN SOA ns1.test-master-7.local. admin.test-master-7.local. ( 2025102407 3600 1800 604800 86400 )\n    IN NS ns1.test-master-7.local.\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(217,'test-master-8.local','db.test-master-8.local',NULL,'$ORIGIN test-master-8.local.\n$TTL 3600\n@ IN SOA ns1.test-master-8.local. admin.test-master-8.local. ( 2025102408 3600 1800 604800 86400 )\n    IN NS ns1.test-master-8.local.\nns1 IN A 192.0.2.9\n\n$INCLUDE includes/common-include-2.inc\n\n$INCLUDE includes/common-include-10.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(218,'test-master-9.local','db.test-master-9.local',NULL,'$ORIGIN test-master-9.local.\n$TTL 3600\n@ IN SOA ns1.test-master-9.local. admin.test-master-9.local. ( 2025102409 3600 1800 604800 86400 )\n    IN NS ns1.test-master-9.local.\nns1 IN A 192.0.2.10\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(219,'test-master-10.local','db.test-master-10.local',NULL,'$ORIGIN test-master-10.local.\n$TTL 3600\n@ IN SOA ns1.test-master-10.local. admin.test-master-10.local. ( 2025102410 3600 1800 604800 86400 )\n    IN NS ns1.test-master-10.local.\nns1 IN A 192.0.2.11\n\n$INCLUDE includes/common-include-1.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(220,'test-master-11.local','db.test-master-11.local',NULL,'$ORIGIN test-master-11.local.\n$TTL 3600\n@ IN SOA ns1.test-master-11.local. admin.test-master-11.local. ( 2025102411 3600 1800 604800 86400 )\n    IN NS ns1.test-master-11.local.\nns1 IN A 192.0.2.12\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(221,'test-master-12.local','db.test-master-12.local',NULL,'$ORIGIN test-master-12.local.\n$TTL 3600\n@ IN SOA ns1.test-master-12.local. admin.test-master-12.local. ( 2025102412 3600 1800 604800 86400 )\n    IN NS ns1.test-master-12.local.\nns1 IN A 192.0.2.13\n\n$INCLUDE includes/common-include-9.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(222,'test-master-13.local','db.test-master-13.local',NULL,'$ORIGIN test-master-13.local.\n$TTL 3600\n@ IN SOA ns1.test-master-13.local. admin.test-master-13.local. ( 2025102413 3600 1800 604800 86400 )\n    IN NS ns1.test-master-13.local.\nns1 IN A 192.0.2.14\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(223,'test-master-14.local','db.test-master-14.local',NULL,'$ORIGIN test-master-14.local.\n$TTL 3600\n@ IN SOA ns1.test-master-14.local. admin.test-master-14.local. ( 2025102414 3600 1800 604800 86400 )\n    IN NS ns1.test-master-14.local.\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(224,'test-master-15.local','db.test-master-15.local',NULL,'$ORIGIN test-master-15.local.\n$TTL 3600\n@ IN SOA ns1.test-master-15.local. admin.test-master-15.local. ( 2025102415 3600 1800 604800 86400 )\n    IN NS ns1.test-master-15.local.\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(225,'test-master-16.local','db.test-master-16.local',NULL,'$ORIGIN test-master-16.local.\n$TTL 3600\n@ IN SOA ns1.test-master-16.local. admin.test-master-16.local. ( 2025102416 3600 1800 604800 86400 )\n    IN NS ns1.test-master-16.local.\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(226,'test-master-17.local','db.test-master-17.local',NULL,'$ORIGIN test-master-17.local.\n$TTL 3600\n@ IN SOA ns1.test-master-17.local. admin.test-master-17.local. ( 2025102417 3600 1800 604800 86400 )\n    IN NS ns1.test-master-17.local.\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(227,'test-master-18.local','db.test-master-18.local',NULL,'$ORIGIN test-master-18.local.\n$TTL 3600\n@ IN SOA ns1.test-master-18.local. admin.test-master-18.local. ( 2025102418 3600 1800 604800 86400 )\n    IN NS ns1.test-master-18.local.\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(228,'test-master-19.local','db.test-master-19.local',NULL,'$ORIGIN test-master-19.local.\n$TTL 3600\n@ IN SOA ns1.test-master-19.local. admin.test-master-19.local. ( 2025102419 3600 1800 604800 86400 )\n    IN NS ns1.test-master-19.local.\nns1 IN A 192.0.2.20\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(229,'test-master-20.local','db.test-master-20.local',NULL,'$ORIGIN test-master-20.local.\n$TTL 3600\n@ IN SOA ns1.test-master-20.local. admin.test-master-20.local. ( 2025102420 3600 1800 604800 86400 )\n    IN NS ns1.test-master-20.local.\nns1 IN A 192.0.2.21\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(230,'test-master-21.local','db.test-master-21.local',NULL,'$ORIGIN test-master-21.local.\n$TTL 3600\n@ IN SOA ns1.test-master-21.local. admin.test-master-21.local. ( 2025102421 3600 1800 604800 86400 )\n    IN NS ns1.test-master-21.local.\nns1 IN A 192.0.2.22\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(231,'test-master-22.local','db.test-master-22.local',NULL,'$ORIGIN test-master-22.local.\n$TTL 3600\n@ IN SOA ns1.test-master-22.local. admin.test-master-22.local. ( 2025102422 3600 1800 604800 86400 )\n    IN NS ns1.test-master-22.local.\nns1 IN A 192.0.2.23\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(232,'test-master-23.local','db.test-master-23.local',NULL,'$ORIGIN test-master-23.local.\n$TTL 3600\n@ IN SOA ns1.test-master-23.local. admin.test-master-23.local. ( 2025102423 3600 1800 604800 86400 )\n    IN NS ns1.test-master-23.local.\nns1 IN A 192.0.2.24\n\n$INCLUDE includes/common-include-8.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(233,'test-master-24.local','db.test-master-24.local',NULL,'$ORIGIN test-master-24.local.\n$TTL 3600\n@ IN SOA ns1.test-master-24.local. admin.test-master-24.local. ( 2025102424 3600 1800 604800 86400 )\n    IN NS ns1.test-master-24.local.\nns1 IN A 192.0.2.25\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(234,'test-master-25.local','db.test-master-25.local',NULL,'$ORIGIN test-master-25.local.\n$TTL 3600\n@ IN SOA ns1.test-master-25.local. admin.test-master-25.local. ( 2025102425 3600 1800 604800 86400 )\n    IN NS ns1.test-master-25.local.\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(235,'test-master-26.local','db.test-master-26.local',NULL,'$ORIGIN test-master-26.local.\n$TTL 3600\n@ IN SOA ns1.test-master-26.local. admin.test-master-26.local. ( 2025102426 3600 1800 604800 86400 )\n    IN NS ns1.test-master-26.local.\nns1 IN A 192.0.2.27\n\n$INCLUDE includes/common-include-4.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(236,'test-master-27.local','db.test-master-27.local',NULL,'$ORIGIN test-master-27.local.\n$TTL 3600\n@ IN SOA ns1.test-master-27.local. admin.test-master-27.local. ( 2025102427 3600 1800 604800 86400 )\n    IN NS ns1.test-master-27.local.\nns1 IN A 192.0.2.28\n\n$INCLUDE includes/common-include-7.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(237,'test-master-28.local','db.test-master-28.local',NULL,'$ORIGIN test-master-28.local.\n$TTL 3600\n@ IN SOA ns1.test-master-28.local. admin.test-master-28.local. ( 2025102428 3600 1800 604800 86400 )\n    IN NS ns1.test-master-28.local.\nns1 IN A 192.0.2.29\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(238,'test-master-29.local','db.test-master-29.local',NULL,'$ORIGIN test-master-29.local.\n$TTL 3600\n@ IN SOA ns1.test-master-29.local. admin.test-master-29.local. ( 2025102429 3600 1800 604800 86400 )\n    IN NS ns1.test-master-29.local.\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(239,'test-master-30.local','db.test-master-30.local',NULL,'$ORIGIN test-master-30.local.\n$TTL 3600\n@ IN SOA ns1.test-master-30.local. admin.test-master-30.local. ( 2025102430 3600 1800 604800 86400 )\n    IN NS ns1.test-master-30.local.\nns1 IN A 192.0.2.31\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(240,'test-master-31.local','db.test-master-31.local',NULL,'$ORIGIN test-master-31.local.\n$TTL 3600\n@ IN SOA ns1.test-master-31.local. admin.test-master-31.local. ( 2025102431 3600 1800 604800 86400 )\n    IN NS ns1.test-master-31.local.\nns1 IN A 192.0.2.32\n\n$INCLUDE includes/common-include-3.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(241,'test-master-32.local','db.test-master-32.local',NULL,'$ORIGIN test-master-32.local.\n$TTL 3600\n@ IN SOA ns1.test-master-32.local. admin.test-master-32.local. ( 2025102432 3600 1800 604800 86400 )\n    IN NS ns1.test-master-32.local.\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(242,'test-master-33.local','db.test-master-33.local',NULL,'$ORIGIN test-master-33.local.\n$TTL 3600\n@ IN SOA ns1.test-master-33.local. admin.test-master-33.local. ( 2025102433 3600 1800 604800 86400 )\n    IN NS ns1.test-master-33.local.\nns1 IN A 192.0.2.34\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(243,'test-master-34.local','db.test-master-34.local',NULL,'$ORIGIN test-master-34.local.\n$TTL 3600\n@ IN SOA ns1.test-master-34.local. admin.test-master-34.local. ( 2025102434 3600 1800 604800 86400 )\n    IN NS ns1.test-master-34.local.\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(244,'test-master-35.local','db.test-master-35.local',NULL,'$ORIGIN test-master-35.local.\n$TTL 3600\n@ IN SOA ns1.test-master-35.local. admin.test-master-35.local. ( 2025102435 3600 1800 604800 86400 )\n    IN NS ns1.test-master-35.local.\nns1 IN A 192.0.2.36\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(245,'test-master-36.local','db.test-master-36.local',NULL,'$ORIGIN test-master-36.local.\n$TTL 3600\n@ IN SOA ns1.test-master-36.local. admin.test-master-36.local. ( 2025102436 3600 1800 604800 86400 )\n    IN NS ns1.test-master-36.local.\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(246,'test-master-37.local','db.test-master-37.local',NULL,'$ORIGIN test-master-37.local.\n$TTL 3600\n@ IN SOA ns1.test-master-37.local. admin.test-master-37.local. ( 2025102437 3600 1800 604800 86400 )\n    IN NS ns1.test-master-37.local.\nns1 IN A 192.0.2.38\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(247,'test-master-38.local','db.test-master-38.local',NULL,'$ORIGIN test-master-38.local.\n$TTL 3600\n@ IN SOA ns1.test-master-38.local. admin.test-master-38.local. ( 2025102438 3600 1800 604800 86400 )\n    IN NS ns1.test-master-38.local.\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(248,'test-master-39.local','db.test-master-39.local',NULL,'$ORIGIN test-master-39.local.\n$TTL 3600\n@ IN SOA ns1.test-master-39.local. admin.test-master-39.local. ( 2025102439 3600 1800 604800 86400 )\n    IN NS ns1.test-master-39.local.\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(249,'test-master-40.local','db.test-master-40.local',NULL,'$ORIGIN test-master-40.local.\n$TTL 3600\n@ IN SOA ns1.test-master-40.local. admin.test-master-40.local. ( 2025102440 3600 1800 604800 86400 )\n    IN NS ns1.test-master-40.local.\nns1 IN A 192.0.2.41\n\n$INCLUDE includes/common-include-5.inc\n','master','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 16:40:21'),
(250,'common-include-1.inc.local','includes/common-include-1.inc',NULL,'; Include file for common records group 1\nmonitor IN A 198.51.1.10\nmonitor6 IN AAAA 2001:db8::65\ncommon-txt IN TXT \"include-group-1\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(251,'common-include-2.inc.local','includes/common-include-2.inc',NULL,'; Include file for common records group 2\nmonitor IN A 198.51.2.10\nmonitor6 IN AAAA 2001:db8::66\ncommon-txt IN TXT \"include-group-2\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(252,'common-include-3.inc.local','includes/common-include-3.inc',NULL,'; Include file for common records group 3\nmonitor IN A 198.51.3.10\nmonitor6 IN AAAA 2001:db8::67\ncommon-txt IN TXT \"include-group-3\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(253,'common-include-4.inc.local','includes/common-include-4.inc',NULL,'; Include file for common records group 4\nmonitor IN A 198.51.4.10\nmonitor6 IN AAAA 2001:db8::68\ncommon-txt IN TXT \"include-group-4\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(254,'common-include-5.inc.local','includes/common-include-5.inc',NULL,'; Include file for common records group 5\nmonitor IN A 198.51.5.10\nmonitor6 IN AAAA 2001:db8::69\ncommon-txt IN TXT \"include-group-5\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(255,'common-include-6.inc.local','includes/common-include-6.inc',NULL,'; Include file for common records group 6\nmonitor IN A 198.51.6.10\nmonitor6 IN AAAA 2001:db8::6a\ncommon-txt IN TXT \"include-group-6\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(256,'common-include-7.inc.local','includes/common-include-7.inc',NULL,'; Include file for common records group 7\nmonitor IN A 198.51.7.10\nmonitor6 IN AAAA 2001:db8::6b\ncommon-txt IN TXT \"include-group-7\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(257,'common-include-8.inc.local','includes/common-include-8.inc',NULL,'; Include file for common records group 8\nmonitor IN A 198.51.8.10\nmonitor6 IN AAAA 2001:db8::6c\ncommon-txt IN TXT \"include-group-8\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(258,'common-include-9.inc.local','includes/common-include-9.inc',NULL,'; Include file for common records group 9\nmonitor IN A 198.51.9.10\nmonitor6 IN AAAA 2001:db8::6d\ncommon-txt IN TXT \"include-group-9\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21'),
(259,'common-include-10.inc.local','includes/common-include-10.inc',NULL,'; Include file for common records group 10\nmonitor IN A 198.51.10.10\nmonitor6 IN AAAA 2001:db8::6e\ncommon-txt IN TXT \"include-group-10\"\n','include','active',1,NULL,'2025-10-24 14:40:21','2025-10-24 14:40:21');
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

-- Dump completed on 2025-10-24 18:40:41
