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
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_record_history`
--

LOCK TABLES `dns_record_history` WRITE;
/*!40000 ALTER TABLE `dns_record_history` DISABLE KEYS */;
INSERT INTO `dns_record_history` VALUES
(15,5007,314,'created','A','testcname','192.168.1.3','192.168.1.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',2,'2025-11-06 13:34:34','Record created');
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
) ENGINE=InnoDB AUTO_INCREMENT=5008 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(4007,266,'AAAA','host1','2001:db8::4c25',NULL,'2001:db8::4c25',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4008,267,'CNAME','cname2','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4009,278,'TXT','txt3','test-txt-3',NULL,NULL,NULL,NULL,'test-txt-3',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4010,286,'CNAME','cname4','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4011,299,'TXT','txt5','test-txt-5',NULL,NULL,NULL,NULL,'test-txt-5',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4012,277,'CNAME','cname6','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4013,298,'A','host7','198.51.207.3','198.51.207.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4014,264,'PTR','ptr8','ptr8.in-addr.arpa.',NULL,NULL,NULL,'ptr8.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4015,307,'AAAA','host9','2001:db8::1e62',NULL,'2001:db8::1e62',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4016,304,'PTR','ptr10','ptr10.in-addr.arpa.',NULL,NULL,NULL,'ptr10.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4017,309,'AAAA','host11','2001:db8::87b7',NULL,'2001:db8::87b7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4018,262,'A','host12','198.51.16.223','198.51.16.223',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4019,281,'TXT','txt13','test-txt-13',NULL,NULL,NULL,NULL,'test-txt-13',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4020,301,'PTR','ptr14','ptr14.in-addr.arpa.',NULL,NULL,NULL,'ptr14.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4021,288,'A','host15','198.51.117.254','198.51.117.254',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4022,304,'TXT','txt16','test-txt-16',NULL,NULL,NULL,NULL,'test-txt-16',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4023,284,'PTR','ptr17','ptr17.in-addr.arpa.',NULL,NULL,NULL,'ptr17.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4024,277,'AAAA','host18','2001:db8::b10a',NULL,'2001:db8::b10a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4025,264,'AAAA','host19','2001:db8::58',NULL,'2001:db8::58',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4026,297,'AAAA','host20','2001:db8::409e',NULL,'2001:db8::409e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4027,306,'PTR','ptr21','ptr21.in-addr.arpa.',NULL,NULL,NULL,'ptr21.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4028,290,'A','host22','198.51.210.150','198.51.210.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4029,300,'TXT','txt23','test-txt-23',NULL,NULL,NULL,NULL,'test-txt-23',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4030,270,'TXT','txt24','test-txt-24',NULL,NULL,NULL,NULL,'test-txt-24',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4031,266,'CNAME','cname25','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4032,292,'A','host26','198.51.9.62','198.51.9.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4033,278,'CNAME','cname27','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4034,297,'PTR','ptr28','ptr28.in-addr.arpa.',NULL,NULL,NULL,'ptr28.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4035,308,'TXT','txt29','test-txt-29',NULL,NULL,NULL,NULL,'test-txt-29',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4036,296,'TXT','txt30','test-txt-30',NULL,NULL,NULL,NULL,'test-txt-30',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4037,264,'TXT','txt31','test-txt-31',NULL,NULL,NULL,NULL,'test-txt-31',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4038,301,'A','host32','198.51.173.225','198.51.173.225',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4039,266,'A','host33','198.51.233.31','198.51.233.31',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4040,292,'PTR','ptr34','ptr34.in-addr.arpa.',NULL,NULL,NULL,'ptr34.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4041,261,'PTR','ptr35','ptr35.in-addr.arpa.',NULL,NULL,NULL,'ptr35.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4042,302,'A','host36','198.51.218.138','198.51.218.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4043,277,'PTR','ptr37','ptr37.in-addr.arpa.',NULL,NULL,NULL,'ptr37.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4044,269,'A','host38','198.51.109.169','198.51.109.169',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4045,309,'PTR','ptr39','ptr39.in-addr.arpa.',NULL,NULL,NULL,'ptr39.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4046,303,'CNAME','cname40','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4047,272,'A','host41','198.51.2.51','198.51.2.51',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4048,280,'CNAME','cname42','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4049,300,'AAAA','host43','2001:db8::e19',NULL,'2001:db8::e19',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4050,291,'A','host44','198.51.92.229','198.51.92.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4051,296,'A','host45','198.51.30.164','198.51.30.164',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4052,261,'PTR','ptr46','ptr46.in-addr.arpa.',NULL,NULL,NULL,'ptr46.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4053,295,'A','host47','198.51.85.132','198.51.85.132',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4054,275,'PTR','ptr48','ptr48.in-addr.arpa.',NULL,NULL,NULL,'ptr48.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4055,267,'AAAA','host49','2001:db8::f4bc',NULL,'2001:db8::f4bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4056,266,'AAAA','host50','2001:db8::5041',NULL,'2001:db8::5041',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4057,277,'A','host51','198.51.199.68','198.51.199.68',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4058,294,'TXT','txt52','test-txt-52',NULL,NULL,NULL,NULL,'test-txt-52',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4059,306,'CNAME','cname53','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4060,274,'CNAME','cname54','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4061,307,'AAAA','host55','2001:db8::3b17',NULL,'2001:db8::3b17',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4062,273,'AAAA','host56','2001:db8::959b',NULL,'2001:db8::959b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4063,308,'PTR','ptr57','ptr57.in-addr.arpa.',NULL,NULL,NULL,'ptr57.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4064,283,'CNAME','cname58','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4065,304,'TXT','txt59','test-txt-59',NULL,NULL,NULL,NULL,'test-txt-59',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4066,301,'PTR','ptr60','ptr60.in-addr.arpa.',NULL,NULL,NULL,'ptr60.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4067,282,'CNAME','cname61','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4068,309,'CNAME','cname62','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4069,269,'TXT','txt63','test-txt-63',NULL,NULL,NULL,NULL,'test-txt-63',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4070,279,'A','host64','198.51.68.171','198.51.68.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4071,304,'A','host65','198.51.137.214','198.51.137.214',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4072,309,'AAAA','host66','2001:db8::a114',NULL,'2001:db8::a114',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4073,306,'AAAA','host67','2001:db8::eb76',NULL,'2001:db8::eb76',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4074,309,'TXT','txt68','test-txt-68',NULL,NULL,NULL,NULL,'test-txt-68',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4075,304,'CNAME','cname69','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4076,285,'PTR','ptr70','ptr70.in-addr.arpa.',NULL,NULL,NULL,'ptr70.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4077,303,'AAAA','host71','2001:db8::4361',NULL,'2001:db8::4361',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4078,309,'TXT','txt72','test-txt-72',NULL,NULL,NULL,NULL,'test-txt-72',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4079,303,'A','host73','198.51.13.149','198.51.13.149',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4080,284,'AAAA','host74','2001:db8::2325',NULL,'2001:db8::2325',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4081,309,'AAAA','host75','2001:db8::2b1b',NULL,'2001:db8::2b1b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4082,298,'PTR','ptr76','ptr76.in-addr.arpa.',NULL,NULL,NULL,'ptr76.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4083,265,'A','host77','198.51.220.122','198.51.220.122',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4084,307,'CNAME','cname78','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4085,261,'CNAME','cname79','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4086,303,'PTR','ptr80','ptr80.in-addr.arpa.',NULL,NULL,NULL,'ptr80.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4087,297,'AAAA','host81','2001:db8::a41e',NULL,'2001:db8::a41e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4088,301,'A','host82','198.51.254.229','198.51.254.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4089,276,'CNAME','cname83','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4090,272,'TXT','txt84','test-txt-84',NULL,NULL,NULL,NULL,'test-txt-84',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4091,307,'TXT','txt85','test-txt-85',NULL,NULL,NULL,NULL,'test-txt-85',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4092,284,'CNAME','cname86','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4093,288,'A','host87','198.51.172.209','198.51.172.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4094,264,'PTR','ptr88','ptr88.in-addr.arpa.',NULL,NULL,NULL,'ptr88.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4095,303,'A','host89','198.51.243.136','198.51.243.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4096,295,'AAAA','host90','2001:db8::543d',NULL,'2001:db8::543d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4097,269,'PTR','ptr91','ptr91.in-addr.arpa.',NULL,NULL,NULL,'ptr91.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4098,302,'CNAME','cname92','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4099,305,'PTR','ptr93','ptr93.in-addr.arpa.',NULL,NULL,NULL,'ptr93.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4100,275,'TXT','txt94','test-txt-94',NULL,NULL,NULL,NULL,'test-txt-94',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4101,260,'CNAME','cname95','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4102,263,'A','host96','198.51.103.52','198.51.103.52',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4103,301,'CNAME','cname97','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4104,290,'TXT','txt98','test-txt-98',NULL,NULL,NULL,NULL,'test-txt-98',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4105,309,'TXT','txt99','test-txt-99',NULL,NULL,NULL,NULL,'test-txt-99',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4106,285,'AAAA','host100','2001:db8::1145',NULL,'2001:db8::1145',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4107,306,'AAAA','host101','2001:db8::f90a',NULL,'2001:db8::f90a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4108,283,'TXT','txt102','test-txt-102',NULL,NULL,NULL,NULL,'test-txt-102',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4109,304,'PTR','ptr103','ptr103.in-addr.arpa.',NULL,NULL,NULL,'ptr103.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4110,278,'A','host104','198.51.125.32','198.51.125.32',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4111,288,'PTR','ptr105','ptr105.in-addr.arpa.',NULL,NULL,NULL,'ptr105.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4112,304,'PTR','ptr106','ptr106.in-addr.arpa.',NULL,NULL,NULL,'ptr106.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4113,281,'TXT','txt107','test-txt-107',NULL,NULL,NULL,NULL,'test-txt-107',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4114,285,'PTR','ptr108','ptr108.in-addr.arpa.',NULL,NULL,NULL,'ptr108.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4115,297,'CNAME','cname109','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4116,267,'AAAA','host110','2001:db8::5430',NULL,'2001:db8::5430',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4117,275,'PTR','ptr111','ptr111.in-addr.arpa.',NULL,NULL,NULL,'ptr111.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4118,294,'AAAA','host112','2001:db8::48a3',NULL,'2001:db8::48a3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4119,292,'TXT','txt113','test-txt-113',NULL,NULL,NULL,NULL,'test-txt-113',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4120,305,'A','host114','198.51.173.68','198.51.173.68',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4121,270,'CNAME','cname115','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4122,288,'CNAME','cname116','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4123,285,'PTR','ptr117','ptr117.in-addr.arpa.',NULL,NULL,NULL,'ptr117.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4124,278,'A','host118','198.51.123.85','198.51.123.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4125,268,'PTR','ptr119','ptr119.in-addr.arpa.',NULL,NULL,NULL,'ptr119.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4126,267,'A','host120','198.51.182.210','198.51.182.210',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4127,272,'PTR','ptr121','ptr121.in-addr.arpa.',NULL,NULL,NULL,'ptr121.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4128,268,'PTR','ptr122','ptr122.in-addr.arpa.',NULL,NULL,NULL,'ptr122.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4129,263,'TXT','txt123','test-txt-123',NULL,NULL,NULL,NULL,'test-txt-123',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4130,303,'A','host124','198.51.221.53','198.51.221.53',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4131,276,'TXT','txt125','test-txt-125',NULL,NULL,NULL,NULL,'test-txt-125',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4132,308,'CNAME','cname126','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4133,303,'PTR','ptr127','ptr127.in-addr.arpa.',NULL,NULL,NULL,'ptr127.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4134,269,'A','host128','198.51.172.240','198.51.172.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4135,303,'PTR','ptr129','ptr129.in-addr.arpa.',NULL,NULL,NULL,'ptr129.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4136,273,'A','host130','198.51.71.209','198.51.71.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4137,280,'TXT','txt131','test-txt-131',NULL,NULL,NULL,NULL,'test-txt-131',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4138,304,'AAAA','host132','2001:db8::4b12',NULL,'2001:db8::4b12',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4139,289,'AAAA','host133','2001:db8::8722',NULL,'2001:db8::8722',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4140,300,'PTR','ptr134','ptr134.in-addr.arpa.',NULL,NULL,NULL,'ptr134.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4141,293,'AAAA','host135','2001:db8::fc6d',NULL,'2001:db8::fc6d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4142,292,'TXT','txt136','test-txt-136',NULL,NULL,NULL,NULL,'test-txt-136',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4143,267,'PTR','ptr137','ptr137.in-addr.arpa.',NULL,NULL,NULL,'ptr137.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4144,304,'CNAME','cname138','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4145,286,'CNAME','cname139','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4146,263,'PTR','ptr140','ptr140.in-addr.arpa.',NULL,NULL,NULL,'ptr140.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4147,302,'PTR','ptr141','ptr141.in-addr.arpa.',NULL,NULL,NULL,'ptr141.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4148,271,'TXT','txt142','test-txt-142',NULL,NULL,NULL,NULL,'test-txt-142',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4149,276,'PTR','ptr143','ptr143.in-addr.arpa.',NULL,NULL,NULL,'ptr143.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4150,272,'TXT','txt144','test-txt-144',NULL,NULL,NULL,NULL,'test-txt-144',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4151,309,'CNAME','cname145','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4152,309,'AAAA','host146','2001:db8::bb95',NULL,'2001:db8::bb95',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4153,309,'PTR','ptr147','ptr147.in-addr.arpa.',NULL,NULL,NULL,'ptr147.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4154,305,'CNAME','cname148','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4155,282,'A','host149','198.51.51.25','198.51.51.25',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4156,300,'A','host150','198.51.153.65','198.51.153.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4157,309,'AAAA','host151','2001:db8::3058',NULL,'2001:db8::3058',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4158,271,'AAAA','host152','2001:db8::4faa',NULL,'2001:db8::4faa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4159,304,'A','host153','198.51.164.102','198.51.164.102',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4160,290,'PTR','ptr154','ptr154.in-addr.arpa.',NULL,NULL,NULL,'ptr154.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4161,279,'AAAA','host155','2001:db8::c975',NULL,'2001:db8::c975',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4162,286,'TXT','txt156','test-txt-156',NULL,NULL,NULL,NULL,'test-txt-156',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4163,273,'PTR','ptr157','ptr157.in-addr.arpa.',NULL,NULL,NULL,'ptr157.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4164,301,'CNAME','cname158','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4165,301,'CNAME','cname159','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4166,264,'AAAA','host160','2001:db8::1b03',NULL,'2001:db8::1b03',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4167,306,'TXT','txt161','test-txt-161',NULL,NULL,NULL,NULL,'test-txt-161',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4168,305,'A','host162','198.51.253.119','198.51.253.119',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4169,308,'A','host163','198.51.65.21','198.51.65.21',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4170,309,'AAAA','host164','2001:db8::84f4',NULL,'2001:db8::84f4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4171,298,'A','host165','198.51.151.119','198.51.151.119',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4172,303,'AAAA','host166','2001:db8::9045',NULL,'2001:db8::9045',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4173,293,'PTR','ptr167','ptr167.in-addr.arpa.',NULL,NULL,NULL,'ptr167.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4174,298,'TXT','txt168','test-txt-168',NULL,NULL,NULL,NULL,'test-txt-168',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4175,283,'PTR','ptr169','ptr169.in-addr.arpa.',NULL,NULL,NULL,'ptr169.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4176,285,'TXT','txt170','test-txt-170',NULL,NULL,NULL,NULL,'test-txt-170',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4177,291,'AAAA','host171','2001:db8::f7fc',NULL,'2001:db8::f7fc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4178,293,'A','host172','198.51.218.222','198.51.218.222',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4179,285,'TXT','txt173','test-txt-173',NULL,NULL,NULL,NULL,'test-txt-173',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4180,300,'PTR','ptr174','ptr174.in-addr.arpa.',NULL,NULL,NULL,'ptr174.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4181,295,'TXT','txt175','test-txt-175',NULL,NULL,NULL,NULL,'test-txt-175',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4182,299,'CNAME','cname176','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4183,302,'A','host177','198.51.56.62','198.51.56.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4184,304,'CNAME','cname178','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4185,304,'TXT','txt179','test-txt-179',NULL,NULL,NULL,NULL,'test-txt-179',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4186,281,'TXT','txt180','test-txt-180',NULL,NULL,NULL,NULL,'test-txt-180',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4187,289,'TXT','txt181','test-txt-181',NULL,NULL,NULL,NULL,'test-txt-181',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4188,272,'CNAME','cname182','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4189,298,'CNAME','cname183','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4190,300,'AAAA','host184','2001:db8::91ee',NULL,'2001:db8::91ee',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4191,294,'CNAME','cname185','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4192,264,'CNAME','cname186','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4193,289,'PTR','ptr187','ptr187.in-addr.arpa.',NULL,NULL,NULL,'ptr187.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4194,305,'A','host188','198.51.98.234','198.51.98.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4195,304,'AAAA','host189','2001:db8::263d',NULL,'2001:db8::263d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4196,268,'PTR','ptr190','ptr190.in-addr.arpa.',NULL,NULL,NULL,'ptr190.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4197,284,'PTR','ptr191','ptr191.in-addr.arpa.',NULL,NULL,NULL,'ptr191.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4198,309,'PTR','ptr192','ptr192.in-addr.arpa.',NULL,NULL,NULL,'ptr192.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4199,308,'A','host193','198.51.231.118','198.51.231.118',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4200,307,'PTR','ptr194','ptr194.in-addr.arpa.',NULL,NULL,NULL,'ptr194.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4201,270,'CNAME','cname195','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4202,309,'CNAME','cname196','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4203,270,'TXT','txt197','test-txt-197',NULL,NULL,NULL,NULL,'test-txt-197',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4204,294,'CNAME','cname198','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4205,269,'CNAME','cname199','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4206,309,'CNAME','cname200','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4207,298,'A','host201','198.51.81.235','198.51.81.235',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4208,276,'PTR','ptr202','ptr202.in-addr.arpa.',NULL,NULL,NULL,'ptr202.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4209,268,'CNAME','cname203','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4210,265,'CNAME','cname204','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4211,277,'AAAA','host205','2001:db8::2cd5',NULL,'2001:db8::2cd5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4212,270,'CNAME','cname206','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4213,274,'PTR','ptr207','ptr207.in-addr.arpa.',NULL,NULL,NULL,'ptr207.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4214,272,'CNAME','cname208','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4215,278,'CNAME','cname209','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4216,282,'TXT','txt210','test-txt-210',NULL,NULL,NULL,NULL,'test-txt-210',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4217,264,'A','host211','198.51.213.231','198.51.213.231',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4218,290,'TXT','txt212','test-txt-212',NULL,NULL,NULL,NULL,'test-txt-212',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4219,262,'CNAME','cname213','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4220,292,'CNAME','cname214','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4221,306,'CNAME','cname215','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4222,275,'PTR','ptr216','ptr216.in-addr.arpa.',NULL,NULL,NULL,'ptr216.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4223,276,'PTR','ptr217','ptr217.in-addr.arpa.',NULL,NULL,NULL,'ptr217.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4224,263,'TXT','txt218','test-txt-218',NULL,NULL,NULL,NULL,'test-txt-218',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4225,282,'CNAME','cname219','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4226,264,'AAAA','host220','2001:db8::52e4',NULL,'2001:db8::52e4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4227,304,'PTR','ptr221','ptr221.in-addr.arpa.',NULL,NULL,NULL,'ptr221.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4228,299,'TXT','txt222','test-txt-222',NULL,NULL,NULL,NULL,'test-txt-222',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4229,270,'CNAME','cname223','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4230,307,'AAAA','host224','2001:db8::2045',NULL,'2001:db8::2045',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4231,274,'PTR','ptr225','ptr225.in-addr.arpa.',NULL,NULL,NULL,'ptr225.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4232,270,'AAAA','host226','2001:db8::a01c',NULL,'2001:db8::a01c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4233,301,'CNAME','cname227','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4234,305,'AAAA','host228','2001:db8::7a51',NULL,'2001:db8::7a51',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4235,263,'TXT','txt229','test-txt-229',NULL,NULL,NULL,NULL,'test-txt-229',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4236,276,'TXT','txt230','test-txt-230',NULL,NULL,NULL,NULL,'test-txt-230',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4237,290,'AAAA','host231','2001:db8::ae12',NULL,'2001:db8::ae12',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4238,308,'CNAME','cname232','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4239,301,'PTR','ptr233','ptr233.in-addr.arpa.',NULL,NULL,NULL,'ptr233.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4240,301,'A','host234','198.51.252.24','198.51.252.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4241,306,'TXT','txt235','test-txt-235',NULL,NULL,NULL,NULL,'test-txt-235',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4242,288,'A','host236','198.51.161.237','198.51.161.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4243,304,'TXT','txt237','test-txt-237',NULL,NULL,NULL,NULL,'test-txt-237',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4244,267,'PTR','ptr238','ptr238.in-addr.arpa.',NULL,NULL,NULL,'ptr238.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4245,281,'AAAA','host239','2001:db8::d079',NULL,'2001:db8::d079',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4246,270,'PTR','ptr240','ptr240.in-addr.arpa.',NULL,NULL,NULL,'ptr240.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4247,291,'A','host241','198.51.179.217','198.51.179.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4248,269,'AAAA','host242','2001:db8::ccc',NULL,'2001:db8::ccc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4249,267,'CNAME','cname243','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4250,278,'TXT','txt244','test-txt-244',NULL,NULL,NULL,NULL,'test-txt-244',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4251,266,'AAAA','host245','2001:db8::f71e',NULL,'2001:db8::f71e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4252,263,'CNAME','cname246','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4253,309,'PTR','ptr247','ptr247.in-addr.arpa.',NULL,NULL,NULL,'ptr247.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4254,290,'CNAME','cname248','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4255,302,'AAAA','host249','2001:db8::d2d3',NULL,'2001:db8::d2d3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4256,305,'CNAME','cname250','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4257,282,'PTR','ptr251','ptr251.in-addr.arpa.',NULL,NULL,NULL,'ptr251.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4258,295,'TXT','txt252','test-txt-252',NULL,NULL,NULL,NULL,'test-txt-252',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4259,294,'AAAA','host253','2001:db8::41e0',NULL,'2001:db8::41e0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4260,309,'PTR','ptr254','ptr254.in-addr.arpa.',NULL,NULL,NULL,'ptr254.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4261,294,'PTR','ptr255','ptr255.in-addr.arpa.',NULL,NULL,NULL,'ptr255.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4262,269,'PTR','ptr256','ptr256.in-addr.arpa.',NULL,NULL,NULL,'ptr256.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4263,301,'PTR','ptr257','ptr257.in-addr.arpa.',NULL,NULL,NULL,'ptr257.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4264,303,'CNAME','cname258','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4265,270,'A','host259','198.51.110.9','198.51.110.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4266,299,'TXT','txt260','test-txt-260',NULL,NULL,NULL,NULL,'test-txt-260',3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4267,294,'AAAA','host261','2001:db8::b78d',NULL,'2001:db8::b78d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4268,270,'CNAME','cname262','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4269,304,'A','host263','198.51.172.9','198.51.172.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:48',NULL,'2025-10-24 14:40:48',NULL,NULL,NULL,NULL),
(4270,302,'CNAME','cname264','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4271,282,'PTR','ptr265','ptr265.in-addr.arpa.',NULL,NULL,NULL,'ptr265.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4272,308,'A','host266','198.51.22.202','198.51.22.202',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4273,269,'PTR','ptr267','ptr267.in-addr.arpa.',NULL,NULL,NULL,'ptr267.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4274,269,'TXT','txt268','test-txt-268',NULL,NULL,NULL,NULL,'test-txt-268',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4275,278,'AAAA','host269','2001:db8::6ad5',NULL,'2001:db8::6ad5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4276,277,'CNAME','cname270','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4277,290,'TXT','txt271','test-txt-271',NULL,NULL,NULL,NULL,'test-txt-271',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4278,262,'A','host272','198.51.0.166','198.51.0.166',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4279,300,'CNAME','cname273','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4280,301,'TXT','txt274','test-txt-274',NULL,NULL,NULL,NULL,'test-txt-274',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4281,280,'A','host275','198.51.126.108','198.51.126.108',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4282,273,'CNAME','cname276','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4283,304,'CNAME','cname277','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4284,299,'A','host278','198.51.159.179','198.51.159.179',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4285,301,'TXT','txt279','test-txt-279',NULL,NULL,NULL,NULL,'test-txt-279',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4286,303,'CNAME','cname280','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4287,304,'CNAME','cname281','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4288,298,'CNAME','cname282','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4289,296,'PTR','ptr283','ptr283.in-addr.arpa.',NULL,NULL,NULL,'ptr283.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4290,282,'CNAME','cname284','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4291,270,'CNAME','cname285','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4292,290,'CNAME','cname286','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4293,305,'A','host287','198.51.168.23','198.51.168.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4294,280,'AAAA','host288','2001:db8::4a82',NULL,'2001:db8::4a82',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4295,279,'CNAME','cname289','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4296,296,'A','host290','198.51.52.178','198.51.52.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4297,282,'AAAA','host291','2001:db8::ddb0',NULL,'2001:db8::ddb0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4298,301,'TXT','txt292','test-txt-292',NULL,NULL,NULL,NULL,'test-txt-292',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4299,278,'PTR','ptr293','ptr293.in-addr.arpa.',NULL,NULL,NULL,'ptr293.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4300,268,'TXT','txt294','test-txt-294',NULL,NULL,NULL,NULL,'test-txt-294',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4301,263,'TXT','txt295','test-txt-295',NULL,NULL,NULL,NULL,'test-txt-295',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4302,301,'A','host296','198.51.53.218','198.51.53.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4303,269,'CNAME','cname297','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4304,289,'AAAA','host298','2001:db8::c74d',NULL,'2001:db8::c74d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4305,279,'A','host299','198.51.34.89','198.51.34.89',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4306,265,'PTR','ptr300','ptr300.in-addr.arpa.',NULL,NULL,NULL,'ptr300.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4307,270,'A','host301','198.51.150.117','198.51.150.117',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4308,306,'AAAA','host302','2001:db8::ad45',NULL,'2001:db8::ad45',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4309,295,'PTR','ptr303','ptr303.in-addr.arpa.',NULL,NULL,NULL,'ptr303.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4310,274,'PTR','ptr304','ptr304.in-addr.arpa.',NULL,NULL,NULL,'ptr304.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4311,270,'PTR','ptr305','ptr305.in-addr.arpa.',NULL,NULL,NULL,'ptr305.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4312,276,'AAAA','host306','2001:db8::200d',NULL,'2001:db8::200d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4313,284,'PTR','ptr307','ptr307.in-addr.arpa.',NULL,NULL,NULL,'ptr307.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4314,278,'TXT','txt308','test-txt-308',NULL,NULL,NULL,NULL,'test-txt-308',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4315,303,'PTR','ptr309','ptr309.in-addr.arpa.',NULL,NULL,NULL,'ptr309.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4316,301,'TXT','txt310','test-txt-310',NULL,NULL,NULL,NULL,'test-txt-310',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4317,280,'A','host311','198.51.111.50','198.51.111.50',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4318,282,'PTR','ptr312','ptr312.in-addr.arpa.',NULL,NULL,NULL,'ptr312.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4319,289,'TXT','txt313','test-txt-313',NULL,NULL,NULL,NULL,'test-txt-313',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4320,275,'CNAME','cname314','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4321,262,'CNAME','cname315','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4322,304,'TXT','txt316','test-txt-316',NULL,NULL,NULL,NULL,'test-txt-316',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4323,266,'AAAA','host317','2001:db8::4b72',NULL,'2001:db8::4b72',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4324,305,'PTR','ptr318','ptr318.in-addr.arpa.',NULL,NULL,NULL,'ptr318.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4325,308,'AAAA','host319','2001:db8::97d3',NULL,'2001:db8::97d3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4326,265,'PTR','ptr320','ptr320.in-addr.arpa.',NULL,NULL,NULL,'ptr320.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4327,266,'PTR','ptr321','ptr321.in-addr.arpa.',NULL,NULL,NULL,'ptr321.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4328,303,'A','host322','198.51.43.133','198.51.43.133',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4329,291,'A','host323','198.51.117.191','198.51.117.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4330,306,'A','host324','198.51.40.69','198.51.40.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4331,292,'PTR','ptr325','ptr325.in-addr.arpa.',NULL,NULL,NULL,'ptr325.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4332,294,'AAAA','host326','2001:db8::aae9',NULL,'2001:db8::aae9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4333,276,'TXT','txt327','test-txt-327',NULL,NULL,NULL,NULL,'test-txt-327',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4334,307,'PTR','ptr328','ptr328.in-addr.arpa.',NULL,NULL,NULL,'ptr328.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4335,302,'PTR','ptr329','ptr329.in-addr.arpa.',NULL,NULL,NULL,'ptr329.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4336,284,'A','host330','198.51.89.36','198.51.89.36',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4337,304,'TXT','txt331','test-txt-331',NULL,NULL,NULL,NULL,'test-txt-331',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4338,290,'TXT','txt332','test-txt-332',NULL,NULL,NULL,NULL,'test-txt-332',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4339,285,'TXT','txt333','test-txt-333',NULL,NULL,NULL,NULL,'test-txt-333',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4340,273,'PTR','ptr334','ptr334.in-addr.arpa.',NULL,NULL,NULL,'ptr334.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4341,279,'PTR','ptr335','ptr335.in-addr.arpa.',NULL,NULL,NULL,'ptr335.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4342,271,'A','host336','198.51.38.208','198.51.38.208',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4343,309,'A','host337','198.51.132.92','198.51.132.92',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4344,261,'TXT','txt338','test-txt-338',NULL,NULL,NULL,NULL,'test-txt-338',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4345,304,'AAAA','host339','2001:db8::38',NULL,'2001:db8::38',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4346,289,'A','host340','198.51.94.212','198.51.94.212',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4347,305,'A','host341','198.51.64.136','198.51.64.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4348,300,'CNAME','cname342','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4349,302,'PTR','ptr343','ptr343.in-addr.arpa.',NULL,NULL,NULL,'ptr343.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4350,263,'TXT','txt344','test-txt-344',NULL,NULL,NULL,NULL,'test-txt-344',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4351,281,'A','host345','198.51.249.171','198.51.249.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4352,268,'TXT','txt346','test-txt-346',NULL,NULL,NULL,NULL,'test-txt-346',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4353,282,'TXT','txt347','test-txt-347',NULL,NULL,NULL,NULL,'test-txt-347',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4354,277,'AAAA','host348','2001:db8::1a68',NULL,'2001:db8::1a68',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4355,283,'CNAME','cname349','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4356,309,'TXT','txt350','test-txt-350',NULL,NULL,NULL,NULL,'test-txt-350',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4357,268,'A','host351','198.51.96.242','198.51.96.242',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4358,306,'A','host352','198.51.170.126','198.51.170.126',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4359,288,'AAAA','host353','2001:db8::fd49',NULL,'2001:db8::fd49',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4360,308,'A','host354','198.51.197.239','198.51.197.239',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4361,266,'A','host355','198.51.245.154','198.51.245.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4362,291,'TXT','txt356','test-txt-356',NULL,NULL,NULL,NULL,'test-txt-356',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4363,290,'A','host357','198.51.66.235','198.51.66.235',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4364,285,'TXT','txt358','test-txt-358',NULL,NULL,NULL,NULL,'test-txt-358',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4365,277,'PTR','ptr359','ptr359.in-addr.arpa.',NULL,NULL,NULL,'ptr359.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4366,263,'A','host360','198.51.6.250','198.51.6.250',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4367,300,'TXT','txt361','test-txt-361',NULL,NULL,NULL,NULL,'test-txt-361',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4368,309,'TXT','txt362','test-txt-362',NULL,NULL,NULL,NULL,'test-txt-362',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4369,277,'A','host363','198.51.99.125','198.51.99.125',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4370,294,'A','host364','198.51.107.134','198.51.107.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4371,279,'AAAA','host365','2001:db8::86ed',NULL,'2001:db8::86ed',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4372,261,'CNAME','cname366','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4373,306,'TXT','txt367','test-txt-367',NULL,NULL,NULL,NULL,'test-txt-367',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4374,300,'A','host368','198.51.218.191','198.51.218.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4375,277,'CNAME','cname369','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4376,309,'PTR','ptr370','ptr370.in-addr.arpa.',NULL,NULL,NULL,'ptr370.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4377,303,'CNAME','cname371','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4378,303,'A','host372','198.51.11.177','198.51.11.177',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4379,281,'PTR','ptr373','ptr373.in-addr.arpa.',NULL,NULL,NULL,'ptr373.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4380,291,'AAAA','host374','2001:db8::6cfa',NULL,'2001:db8::6cfa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4381,306,'PTR','ptr375','ptr375.in-addr.arpa.',NULL,NULL,NULL,'ptr375.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4382,283,'AAAA','host376','2001:db8::3e3f',NULL,'2001:db8::3e3f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4383,287,'PTR','ptr377','ptr377.in-addr.arpa.',NULL,NULL,NULL,'ptr377.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4384,308,'AAAA','host378','2001:db8::87bb',NULL,'2001:db8::87bb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4385,294,'PTR','ptr379','ptr379.in-addr.arpa.',NULL,NULL,NULL,'ptr379.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4386,302,'TXT','txt380','test-txt-380',NULL,NULL,NULL,NULL,'test-txt-380',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4387,293,'CNAME','cname381','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4388,294,'TXT','txt382','test-txt-382',NULL,NULL,NULL,NULL,'test-txt-382',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4389,291,'CNAME','cname383','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4390,265,'AAAA','host384','2001:db8::7f21',NULL,'2001:db8::7f21',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4391,268,'TXT','txt385','test-txt-385',NULL,NULL,NULL,NULL,'test-txt-385',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4392,292,'A','host386','198.51.46.40','198.51.46.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4393,262,'A','host387','198.51.194.136','198.51.194.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4394,281,'PTR','ptr388','ptr388.in-addr.arpa.',NULL,NULL,NULL,'ptr388.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4395,293,'A','host389','198.51.240.249','198.51.240.249',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4396,303,'A','host390','198.51.66.195','198.51.66.195',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4397,268,'AAAA','host391','2001:db8::6ce1',NULL,'2001:db8::6ce1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4398,260,'CNAME','cname392','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4399,309,'CNAME','cname393','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4400,293,'AAAA','host394','2001:db8::23e0',NULL,'2001:db8::23e0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4401,267,'AAAA','host395','2001:db8::d0de',NULL,'2001:db8::d0de',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4402,286,'PTR','ptr396','ptr396.in-addr.arpa.',NULL,NULL,NULL,'ptr396.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4403,303,'AAAA','host397','2001:db8::1988',NULL,'2001:db8::1988',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4404,270,'CNAME','cname398','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4405,295,'AAAA','host399','2001:db8::e4f1',NULL,'2001:db8::e4f1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4406,273,'TXT','txt400','test-txt-400',NULL,NULL,NULL,NULL,'test-txt-400',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4407,276,'A','host401','198.51.134.199','198.51.134.199',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4408,293,'AAAA','host402','2001:db8::1afd',NULL,'2001:db8::1afd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4409,262,'AAAA','host403','2001:db8::221f',NULL,'2001:db8::221f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4410,273,'PTR','ptr404','ptr404.in-addr.arpa.',NULL,NULL,NULL,'ptr404.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4411,292,'A','host405','198.51.104.144','198.51.104.144',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4412,268,'AAAA','host406','2001:db8::979',NULL,'2001:db8::979',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4413,271,'TXT','txt407','test-txt-407',NULL,NULL,NULL,NULL,'test-txt-407',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4414,297,'A','host408','198.51.49.168','198.51.49.168',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4415,283,'TXT','txt409','test-txt-409',NULL,NULL,NULL,NULL,'test-txt-409',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4416,269,'CNAME','cname410','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4417,268,'CNAME','cname411','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4418,291,'CNAME','cname412','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4419,269,'A','host413','198.51.236.252','198.51.236.252',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4420,299,'TXT','txt414','test-txt-414',NULL,NULL,NULL,NULL,'test-txt-414',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4421,301,'PTR','ptr415','ptr415.in-addr.arpa.',NULL,NULL,NULL,'ptr415.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4422,286,'A','host416','198.51.180.79','198.51.180.79',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4423,302,'AAAA','host417','2001:db8::e18',NULL,'2001:db8::e18',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4424,308,'CNAME','cname418','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4425,296,'AAAA','host419','2001:db8::b2e5',NULL,'2001:db8::b2e5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4426,308,'AAAA','host420','2001:db8::5f89',NULL,'2001:db8::5f89',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4427,306,'CNAME','cname421','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4428,301,'PTR','ptr422','ptr422.in-addr.arpa.',NULL,NULL,NULL,'ptr422.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4429,288,'A','host423','198.51.101.21','198.51.101.21',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4430,261,'AAAA','host424','2001:db8::f244',NULL,'2001:db8::f244',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4431,301,'PTR','ptr425','ptr425.in-addr.arpa.',NULL,NULL,NULL,'ptr425.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4432,301,'TXT','txt426','test-txt-426',NULL,NULL,NULL,NULL,'test-txt-426',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4433,269,'CNAME','cname427','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4434,265,'AAAA','host428','2001:db8::7152',NULL,'2001:db8::7152',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4435,302,'TXT','txt429','test-txt-429',NULL,NULL,NULL,NULL,'test-txt-429',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4436,285,'CNAME','cname430','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4437,305,'PTR','ptr431','ptr431.in-addr.arpa.',NULL,NULL,NULL,'ptr431.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4438,302,'CNAME','cname432','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4439,301,'PTR','ptr433','ptr433.in-addr.arpa.',NULL,NULL,NULL,'ptr433.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4440,263,'A','host434','198.51.0.95','198.51.0.95',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4441,300,'A','host435','198.51.54.9','198.51.54.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4442,284,'TXT','txt436','test-txt-436',NULL,NULL,NULL,NULL,'test-txt-436',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4443,285,'AAAA','host437','2001:db8::ae4',NULL,'2001:db8::ae4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4444,297,'TXT','txt438','test-txt-438',NULL,NULL,NULL,NULL,'test-txt-438',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4445,266,'CNAME','cname439','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4446,308,'PTR','ptr440','ptr440.in-addr.arpa.',NULL,NULL,NULL,'ptr440.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4447,284,'CNAME','cname441','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4448,303,'CNAME','cname442','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4449,261,'AAAA','host443','2001:db8::1271',NULL,'2001:db8::1271',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4450,268,'TXT','txt444','test-txt-444',NULL,NULL,NULL,NULL,'test-txt-444',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4451,287,'PTR','ptr445','ptr445.in-addr.arpa.',NULL,NULL,NULL,'ptr445.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4452,306,'A','host446','198.51.147.31','198.51.147.31',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4453,307,'TXT','txt447','test-txt-447',NULL,NULL,NULL,NULL,'test-txt-447',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4454,260,'TXT','txt448','test-txt-448',NULL,NULL,NULL,NULL,'test-txt-448',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4455,305,'CNAME','cname449','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4456,270,'AAAA','host450','2001:db8::d9fe',NULL,'2001:db8::d9fe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4457,308,'A','host451','198.51.184.49','198.51.184.49',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4458,264,'TXT','txt452','test-txt-452',NULL,NULL,NULL,NULL,'test-txt-452',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4459,266,'TXT','txt453','test-txt-453',NULL,NULL,NULL,NULL,'test-txt-453',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4460,282,'AAAA','host454','2001:db8::6b2a',NULL,'2001:db8::6b2a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4461,261,'TXT','txt455','test-txt-455',NULL,NULL,NULL,NULL,'test-txt-455',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4462,301,'A','host456','198.51.194.65','198.51.194.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4463,307,'AAAA','host457','2001:db8::c08c',NULL,'2001:db8::c08c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4464,301,'TXT','txt458','test-txt-458',NULL,NULL,NULL,NULL,'test-txt-458',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4465,264,'AAAA','host459','2001:db8::cd8d',NULL,'2001:db8::cd8d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4466,277,'A','host460','198.51.7.134','198.51.7.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4467,303,'A','host461','198.51.181.201','198.51.181.201',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4468,266,'PTR','ptr462','ptr462.in-addr.arpa.',NULL,NULL,NULL,'ptr462.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4469,264,'TXT','txt463','test-txt-463',NULL,NULL,NULL,NULL,'test-txt-463',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4470,297,'AAAA','host464','2001:db8::53fe',NULL,'2001:db8::53fe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4471,277,'TXT','txt465','test-txt-465',NULL,NULL,NULL,NULL,'test-txt-465',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4472,292,'TXT','txt466','test-txt-466',NULL,NULL,NULL,NULL,'test-txt-466',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4473,284,'TXT','txt467','test-txt-467',NULL,NULL,NULL,NULL,'test-txt-467',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4474,264,'A','host468','198.51.103.139','198.51.103.139',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4475,303,'AAAA','host469','2001:db8::936f',NULL,'2001:db8::936f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4476,263,'AAAA','host470','2001:db8::2dd7',NULL,'2001:db8::2dd7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4477,282,'TXT','txt471','test-txt-471',NULL,NULL,NULL,NULL,'test-txt-471',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4478,300,'A','host472','198.51.48.211','198.51.48.211',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4479,302,'A','host473','198.51.167.171','198.51.167.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4480,302,'CNAME','cname474','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4481,304,'PTR','ptr475','ptr475.in-addr.arpa.',NULL,NULL,NULL,'ptr475.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4482,276,'CNAME','cname476','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4483,275,'TXT','txt477','test-txt-477',NULL,NULL,NULL,NULL,'test-txt-477',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4484,284,'CNAME','cname478','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4485,306,'AAAA','host479','2001:db8::d784',NULL,'2001:db8::d784',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4486,275,'CNAME','cname480','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4487,287,'TXT','txt481','test-txt-481',NULL,NULL,NULL,NULL,'test-txt-481',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4488,304,'TXT','txt482','test-txt-482',NULL,NULL,NULL,NULL,'test-txt-482',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4489,261,'TXT','txt483','test-txt-483',NULL,NULL,NULL,NULL,'test-txt-483',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4490,267,'TXT','txt484','test-txt-484',NULL,NULL,NULL,NULL,'test-txt-484',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4491,290,'AAAA','host485','2001:db8::a4ba',NULL,'2001:db8::a4ba',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4492,301,'PTR','ptr486','ptr486.in-addr.arpa.',NULL,NULL,NULL,'ptr486.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4493,265,'TXT','txt487','test-txt-487',NULL,NULL,NULL,NULL,'test-txt-487',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4494,308,'AAAA','host488','2001:db8::1be8',NULL,'2001:db8::1be8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4495,294,'TXT','txt489','test-txt-489',NULL,NULL,NULL,NULL,'test-txt-489',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4496,264,'AAAA','host490','2001:db8::1d02',NULL,'2001:db8::1d02',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4497,296,'TXT','txt491','test-txt-491',NULL,NULL,NULL,NULL,'test-txt-491',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4498,268,'TXT','txt492','test-txt-492',NULL,NULL,NULL,NULL,'test-txt-492',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4499,289,'A','host493','198.51.227.32','198.51.227.32',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4500,280,'AAAA','host494','2001:db8::7775',NULL,'2001:db8::7775',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4501,276,'AAAA','host495','2001:db8::3d2',NULL,'2001:db8::3d2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4502,288,'PTR','ptr496','ptr496.in-addr.arpa.',NULL,NULL,NULL,'ptr496.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4503,260,'TXT','txt497','test-txt-497',NULL,NULL,NULL,NULL,'test-txt-497',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4504,292,'TXT','txt498','test-txt-498',NULL,NULL,NULL,NULL,'test-txt-498',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4505,271,'AAAA','host499','2001:db8::a7f4',NULL,'2001:db8::a7f4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4506,290,'TXT','txt500','test-txt-500',NULL,NULL,NULL,NULL,'test-txt-500',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4507,270,'CNAME','cname501','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4508,285,'AAAA','host502','2001:db8::6a8b',NULL,'2001:db8::6a8b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4509,307,'TXT','txt503','test-txt-503',NULL,NULL,NULL,NULL,'test-txt-503',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4510,261,'CNAME','cname504','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4511,293,'TXT','txt505','test-txt-505',NULL,NULL,NULL,NULL,'test-txt-505',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4512,291,'AAAA','host506','2001:db8::49b1',NULL,'2001:db8::49b1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4513,277,'A','host507','198.51.110.185','198.51.110.185',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4514,286,'A','host508','198.51.202.64','198.51.202.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4515,300,'AAAA','host509','2001:db8::a457',NULL,'2001:db8::a457',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4516,278,'A','host510','198.51.196.10','198.51.196.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4517,267,'CNAME','cname511','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4518,290,'A','host512','198.51.43.240','198.51.43.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4519,267,'TXT','txt513','test-txt-513',NULL,NULL,NULL,NULL,'test-txt-513',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4520,273,'CNAME','cname514','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4521,306,'AAAA','host515','2001:db8::1a48',NULL,'2001:db8::1a48',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4522,284,'PTR','ptr516','ptr516.in-addr.arpa.',NULL,NULL,NULL,'ptr516.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4523,302,'PTR','ptr517','ptr517.in-addr.arpa.',NULL,NULL,NULL,'ptr517.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4524,263,'AAAA','host518','2001:db8::fa73',NULL,'2001:db8::fa73',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4525,302,'A','host519','198.51.53.189','198.51.53.189',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4526,263,'PTR','ptr520','ptr520.in-addr.arpa.',NULL,NULL,NULL,'ptr520.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4527,305,'TXT','txt521','test-txt-521',NULL,NULL,NULL,NULL,'test-txt-521',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4528,300,'PTR','ptr522','ptr522.in-addr.arpa.',NULL,NULL,NULL,'ptr522.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4529,298,'AAAA','host523','2001:db8::fcad',NULL,'2001:db8::fcad',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4530,267,'A','host524','198.51.190.130','198.51.190.130',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4531,265,'TXT','txt525','test-txt-525',NULL,NULL,NULL,NULL,'test-txt-525',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4532,295,'TXT','txt526','test-txt-526',NULL,NULL,NULL,NULL,'test-txt-526',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4533,281,'TXT','txt527','test-txt-527',NULL,NULL,NULL,NULL,'test-txt-527',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4534,274,'PTR','ptr528','ptr528.in-addr.arpa.',NULL,NULL,NULL,'ptr528.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4535,274,'CNAME','cname529','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4536,308,'A','host530','198.51.211.174','198.51.211.174',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4537,293,'AAAA','host531','2001:db8::2ce4',NULL,'2001:db8::2ce4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4538,302,'A','host532','198.51.223.5','198.51.223.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4539,275,'AAAA','host533','2001:db8::9e1e',NULL,'2001:db8::9e1e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4540,276,'AAAA','host534','2001:db8::ecdc',NULL,'2001:db8::ecdc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4541,309,'TXT','txt535','test-txt-535',NULL,NULL,NULL,NULL,'test-txt-535',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4542,292,'PTR','ptr536','ptr536.in-addr.arpa.',NULL,NULL,NULL,'ptr536.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4543,291,'AAAA','host537','2001:db8::9fd7',NULL,'2001:db8::9fd7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4544,285,'TXT','txt538','test-txt-538',NULL,NULL,NULL,NULL,'test-txt-538',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4545,295,'A','host539','198.51.103.151','198.51.103.151',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4546,273,'AAAA','host540','2001:db8::9c3d',NULL,'2001:db8::9c3d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4547,290,'CNAME','cname541','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4548,301,'A','host542','198.51.82.193','198.51.82.193',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4549,296,'CNAME','cname543','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4550,309,'TXT','txt544','test-txt-544',NULL,NULL,NULL,NULL,'test-txt-544',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4551,290,'PTR','ptr545','ptr545.in-addr.arpa.',NULL,NULL,NULL,'ptr545.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4552,264,'A','host546','198.51.47.73','198.51.47.73',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4553,271,'A','host547','198.51.32.248','198.51.32.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4554,282,'AAAA','host548','2001:db8::559d',NULL,'2001:db8::559d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4555,301,'A','host549','198.51.252.86','198.51.252.86',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4556,262,'AAAA','host550','2001:db8::d98f',NULL,'2001:db8::d98f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4557,271,'CNAME','cname551','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4558,294,'PTR','ptr552','ptr552.in-addr.arpa.',NULL,NULL,NULL,'ptr552.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4559,266,'TXT','txt553','test-txt-553',NULL,NULL,NULL,NULL,'test-txt-553',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4560,272,'TXT','txt554','test-txt-554',NULL,NULL,NULL,NULL,'test-txt-554',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4561,264,'PTR','ptr555','ptr555.in-addr.arpa.',NULL,NULL,NULL,'ptr555.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4562,309,'TXT','txt556','test-txt-556',NULL,NULL,NULL,NULL,'test-txt-556',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4563,281,'TXT','txt557','test-txt-557',NULL,NULL,NULL,NULL,'test-txt-557',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4564,276,'A','host558','198.51.186.211','198.51.186.211',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4565,290,'AAAA','host559','2001:db8::7e28',NULL,'2001:db8::7e28',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4566,268,'CNAME','cname560','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4567,263,'TXT','txt561','test-txt-561',NULL,NULL,NULL,NULL,'test-txt-561',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4568,281,'CNAME','cname562','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4569,305,'A','host563','198.51.156.190','198.51.156.190',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4570,309,'CNAME','cname564','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4571,304,'A','host565','198.51.1.154','198.51.1.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4572,288,'TXT','txt566','test-txt-566',NULL,NULL,NULL,NULL,'test-txt-566',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4573,286,'PTR','ptr567','ptr567.in-addr.arpa.',NULL,NULL,NULL,'ptr567.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4574,292,'CNAME','cname568','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4575,306,'CNAME','cname569','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4576,284,'PTR','ptr570','ptr570.in-addr.arpa.',NULL,NULL,NULL,'ptr570.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4577,302,'CNAME','cname571','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4578,279,'CNAME','cname572','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4579,284,'CNAME','cname573','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4580,304,'CNAME','cname574','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4581,266,'CNAME','cname575','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4582,262,'CNAME','cname576','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4583,306,'TXT','txt577','test-txt-577',NULL,NULL,NULL,NULL,'test-txt-577',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4584,268,'CNAME','cname578','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4585,286,'PTR','ptr579','ptr579.in-addr.arpa.',NULL,NULL,NULL,'ptr579.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4586,296,'TXT','txt580','test-txt-580',NULL,NULL,NULL,NULL,'test-txt-580',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4587,308,'AAAA','host581','2001:db8::f77d',NULL,'2001:db8::f77d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4588,273,'A','host582','198.51.202.133','198.51.202.133',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4589,262,'TXT','txt583','test-txt-583',NULL,NULL,NULL,NULL,'test-txt-583',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4590,268,'CNAME','cname584','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4591,289,'AAAA','host585','2001:db8::e5d0',NULL,'2001:db8::e5d0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4592,283,'PTR','ptr586','ptr586.in-addr.arpa.',NULL,NULL,NULL,'ptr586.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4593,295,'A','host587','198.51.218.85','198.51.218.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4594,309,'AAAA','host588','2001:db8::a64e',NULL,'2001:db8::a64e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4595,285,'TXT','txt589','test-txt-589',NULL,NULL,NULL,NULL,'test-txt-589',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4596,305,'AAAA','host590','2001:db8::21fb',NULL,'2001:db8::21fb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4597,267,'TXT','txt591','test-txt-591',NULL,NULL,NULL,NULL,'test-txt-591',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4598,276,'A','host592','198.51.240.17','198.51.240.17',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4599,276,'PTR','ptr593','ptr593.in-addr.arpa.',NULL,NULL,NULL,'ptr593.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4600,304,'CNAME','cname594','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4601,286,'AAAA','host595','2001:db8::dd6b',NULL,'2001:db8::dd6b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4602,264,'AAAA','host596','2001:db8::3691',NULL,'2001:db8::3691',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4603,300,'PTR','ptr597','ptr597.in-addr.arpa.',NULL,NULL,NULL,'ptr597.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4604,295,'A','host598','198.51.216.46','198.51.216.46',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4605,302,'A','host599','198.51.247.248','198.51.247.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4606,268,'AAAA','host600','2001:db8::c24c',NULL,'2001:db8::c24c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4607,286,'A','host601','198.51.91.194','198.51.91.194',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4608,285,'TXT','txt602','test-txt-602',NULL,NULL,NULL,NULL,'test-txt-602',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4609,292,'AAAA','host603','2001:db8::8bb1',NULL,'2001:db8::8bb1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4610,287,'AAAA','host604','2001:db8::b483',NULL,'2001:db8::b483',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4611,290,'TXT','txt605','test-txt-605',NULL,NULL,NULL,NULL,'test-txt-605',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4612,272,'TXT','txt606','test-txt-606',NULL,NULL,NULL,NULL,'test-txt-606',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4613,301,'TXT','txt607','test-txt-607',NULL,NULL,NULL,NULL,'test-txt-607',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4614,284,'PTR','ptr608','ptr608.in-addr.arpa.',NULL,NULL,NULL,'ptr608.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4615,301,'PTR','ptr609','ptr609.in-addr.arpa.',NULL,NULL,NULL,'ptr609.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4616,299,'CNAME','cname610','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4617,297,'A','host611','198.51.146.1','198.51.146.1',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4618,303,'TXT','txt612','test-txt-612',NULL,NULL,NULL,NULL,'test-txt-612',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4619,303,'TXT','txt613','test-txt-613',NULL,NULL,NULL,NULL,'test-txt-613',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4620,265,'TXT','txt614','test-txt-614',NULL,NULL,NULL,NULL,'test-txt-614',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4621,304,'PTR','ptr615','ptr615.in-addr.arpa.',NULL,NULL,NULL,'ptr615.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4622,306,'TXT','txt616','test-txt-616',NULL,NULL,NULL,NULL,'test-txt-616',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4623,306,'TXT','txt617','test-txt-617',NULL,NULL,NULL,NULL,'test-txt-617',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4624,290,'CNAME','cname618','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4625,271,'CNAME','cname619','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4626,292,'TXT','txt620','test-txt-620',NULL,NULL,NULL,NULL,'test-txt-620',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4627,282,'TXT','txt621','test-txt-621',NULL,NULL,NULL,NULL,'test-txt-621',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4628,272,'AAAA','host622','2001:db8::d53',NULL,'2001:db8::d53',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4629,272,'PTR','ptr623','ptr623.in-addr.arpa.',NULL,NULL,NULL,'ptr623.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4630,260,'TXT','txt624','test-txt-624',NULL,NULL,NULL,NULL,'test-txt-624',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4631,270,'CNAME','cname625','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4632,303,'AAAA','host626','2001:db8::5887',NULL,'2001:db8::5887',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4633,292,'PTR','ptr627','ptr627.in-addr.arpa.',NULL,NULL,NULL,'ptr627.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4634,293,'CNAME','cname628','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4635,292,'A','host629','198.51.154.122','198.51.154.122',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4636,268,'PTR','ptr630','ptr630.in-addr.arpa.',NULL,NULL,NULL,'ptr630.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4637,300,'PTR','ptr631','ptr631.in-addr.arpa.',NULL,NULL,NULL,'ptr631.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4638,280,'TXT','txt632','test-txt-632',NULL,NULL,NULL,NULL,'test-txt-632',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4639,290,'PTR','ptr633','ptr633.in-addr.arpa.',NULL,NULL,NULL,'ptr633.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4640,275,'TXT','txt634','test-txt-634',NULL,NULL,NULL,NULL,'test-txt-634',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4641,308,'PTR','ptr635','ptr635.in-addr.arpa.',NULL,NULL,NULL,'ptr635.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4642,297,'PTR','ptr636','ptr636.in-addr.arpa.',NULL,NULL,NULL,'ptr636.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4643,277,'TXT','txt637','test-txt-637',NULL,NULL,NULL,NULL,'test-txt-637',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4644,273,'PTR','ptr638','ptr638.in-addr.arpa.',NULL,NULL,NULL,'ptr638.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4645,287,'TXT','txt639','test-txt-639',NULL,NULL,NULL,NULL,'test-txt-639',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4646,298,'AAAA','host640','2001:db8::7d2a',NULL,'2001:db8::7d2a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4647,297,'TXT','txt641','test-txt-641',NULL,NULL,NULL,NULL,'test-txt-641',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4648,305,'A','host642','198.51.39.45','198.51.39.45',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4649,307,'AAAA','host643','2001:db8::fd60',NULL,'2001:db8::fd60',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4650,265,'CNAME','cname644','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4651,271,'PTR','ptr645','ptr645.in-addr.arpa.',NULL,NULL,NULL,'ptr645.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4652,300,'PTR','ptr646','ptr646.in-addr.arpa.',NULL,NULL,NULL,'ptr646.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4653,308,'CNAME','cname647','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4654,296,'A','host648','198.51.213.135','198.51.213.135',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4655,268,'AAAA','host649','2001:db8::495a',NULL,'2001:db8::495a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4656,301,'A','host650','198.51.40.32','198.51.40.32',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4657,302,'TXT','txt651','test-txt-651',NULL,NULL,NULL,NULL,'test-txt-651',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4658,280,'PTR','ptr652','ptr652.in-addr.arpa.',NULL,NULL,NULL,'ptr652.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4659,272,'TXT','txt653','test-txt-653',NULL,NULL,NULL,NULL,'test-txt-653',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4660,260,'AAAA','host654','2001:db8::5152',NULL,'2001:db8::5152',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4661,303,'AAAA','host655','2001:db8::8bb2',NULL,'2001:db8::8bb2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4662,261,'AAAA','host656','2001:db8::c4a7',NULL,'2001:db8::c4a7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4663,309,'CNAME','cname657','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4664,268,'TXT','txt658','test-txt-658',NULL,NULL,NULL,NULL,'test-txt-658',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4665,262,'CNAME','cname659','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4666,261,'PTR','ptr660','ptr660.in-addr.arpa.',NULL,NULL,NULL,'ptr660.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4667,296,'AAAA','host661','2001:db8::c2c',NULL,'2001:db8::c2c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4668,297,'AAAA','host662','2001:db8::f3e9',NULL,'2001:db8::f3e9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4669,286,'PTR','ptr663','ptr663.in-addr.arpa.',NULL,NULL,NULL,'ptr663.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4670,302,'TXT','txt664','test-txt-664',NULL,NULL,NULL,NULL,'test-txt-664',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4671,279,'TXT','txt665','test-txt-665',NULL,NULL,NULL,NULL,'test-txt-665',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4672,279,'CNAME','cname666','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4673,262,'AAAA','host667','2001:db8::7ca',NULL,'2001:db8::7ca',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4674,267,'CNAME','cname668','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4675,298,'CNAME','cname669','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4676,277,'AAAA','host670','2001:db8::2aa4',NULL,'2001:db8::2aa4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4677,270,'AAAA','host671','2001:db8::55d0',NULL,'2001:db8::55d0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4678,291,'CNAME','cname672','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4679,293,'A','host673','198.51.39.217','198.51.39.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4680,286,'CNAME','cname674','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4681,269,'AAAA','host675','2001:db8::eec7',NULL,'2001:db8::eec7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4682,260,'TXT','txt676','test-txt-676',NULL,NULL,NULL,NULL,'test-txt-676',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4683,300,'AAAA','host677','2001:db8::d7cf',NULL,'2001:db8::d7cf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4684,305,'AAAA','host678','2001:db8::ea5e',NULL,'2001:db8::ea5e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4685,269,'A','host679','198.51.48.33','198.51.48.33',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4686,307,'AAAA','host680','2001:db8::6c3',NULL,'2001:db8::6c3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4687,279,'CNAME','cname681','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4688,267,'TXT','txt682','test-txt-682',NULL,NULL,NULL,NULL,'test-txt-682',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4689,300,'A','host683','198.51.60.77','198.51.60.77',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4690,281,'AAAA','host684','2001:db8::8db9',NULL,'2001:db8::8db9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4691,274,'AAAA','host685','2001:db8::89b2',NULL,'2001:db8::89b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4692,294,'CNAME','cname686','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4693,309,'PTR','ptr687','ptr687.in-addr.arpa.',NULL,NULL,NULL,'ptr687.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4694,272,'CNAME','cname688','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4695,282,'TXT','txt689','test-txt-689',NULL,NULL,NULL,NULL,'test-txt-689',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4696,269,'AAAA','host690','2001:db8::936e',NULL,'2001:db8::936e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4697,271,'PTR','ptr691','ptr691.in-addr.arpa.',NULL,NULL,NULL,'ptr691.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4698,277,'A','host692','198.51.182.216','198.51.182.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4699,301,'A','host693','198.51.168.136','198.51.168.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4700,261,'TXT','txt694','test-txt-694',NULL,NULL,NULL,NULL,'test-txt-694',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4701,266,'PTR','ptr695','ptr695.in-addr.arpa.',NULL,NULL,NULL,'ptr695.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4702,271,'PTR','ptr696','ptr696.in-addr.arpa.',NULL,NULL,NULL,'ptr696.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4703,269,'CNAME','cname697','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4704,288,'CNAME','cname698','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4705,302,'A','host699','198.51.144.215','198.51.144.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4706,281,'AAAA','host700','2001:db8::d2b8',NULL,'2001:db8::d2b8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4707,286,'CNAME','cname701','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4708,293,'TXT','txt702','test-txt-702',NULL,NULL,NULL,NULL,'test-txt-702',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4709,308,'A','host703','198.51.149.125','198.51.149.125',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4710,266,'TXT','txt704','test-txt-704',NULL,NULL,NULL,NULL,'test-txt-704',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4711,308,'AAAA','host705','2001:db8::b3f9',NULL,'2001:db8::b3f9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4712,309,'AAAA','host706','2001:db8::a3a2',NULL,'2001:db8::a3a2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4713,289,'A','host707','198.51.194.16','198.51.194.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4714,277,'PTR','ptr708','ptr708.in-addr.arpa.',NULL,NULL,NULL,'ptr708.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4715,287,'CNAME','cname709','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4716,273,'AAAA','host710','2001:db8::2c68',NULL,'2001:db8::2c68',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4717,284,'CNAME','cname711','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4718,305,'TXT','txt712','test-txt-712',NULL,NULL,NULL,NULL,'test-txt-712',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4719,264,'PTR','ptr713','ptr713.in-addr.arpa.',NULL,NULL,NULL,'ptr713.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4720,287,'PTR','ptr714','ptr714.in-addr.arpa.',NULL,NULL,NULL,'ptr714.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4721,282,'TXT','txt715','test-txt-715',NULL,NULL,NULL,NULL,'test-txt-715',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4722,292,'AAAA','host716','2001:db8::3039',NULL,'2001:db8::3039',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4723,276,'AAAA','host717','2001:db8::e4b2',NULL,'2001:db8::e4b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4724,262,'AAAA','host718','2001:db8::c8b9',NULL,'2001:db8::c8b9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4725,284,'A','host719','198.51.202.41','198.51.202.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4726,305,'A','host720','198.51.107.136','198.51.107.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4727,268,'PTR','ptr721','ptr721.in-addr.arpa.',NULL,NULL,NULL,'ptr721.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4728,294,'TXT','txt722','test-txt-722',NULL,NULL,NULL,NULL,'test-txt-722',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4729,276,'A','host723','198.51.219.235','198.51.219.235',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4730,262,'AAAA','host724','2001:db8::612',NULL,'2001:db8::612',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4731,260,'A','host725','198.51.240.186','198.51.240.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4732,287,'A','host726','198.51.71.90','198.51.71.90',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4733,309,'AAAA','host727','2001:db8::6754',NULL,'2001:db8::6754',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4734,304,'A','host728','198.51.134.130','198.51.134.130',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4735,287,'CNAME','cname729','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4736,286,'PTR','ptr730','ptr730.in-addr.arpa.',NULL,NULL,NULL,'ptr730.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4737,278,'A','host731','198.51.1.1','198.51.1.1',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4738,261,'PTR','ptr732','ptr732.in-addr.arpa.',NULL,NULL,NULL,'ptr732.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4739,309,'TXT','txt733','test-txt-733',NULL,NULL,NULL,NULL,'test-txt-733',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4740,291,'A','host734','198.51.147.56','198.51.147.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4741,306,'A','host735','198.51.161.69','198.51.161.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4742,301,'AAAA','host736','2001:db8::43fd',NULL,'2001:db8::43fd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4743,275,'PTR','ptr737','ptr737.in-addr.arpa.',NULL,NULL,NULL,'ptr737.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4744,303,'PTR','ptr738','ptr738.in-addr.arpa.',NULL,NULL,NULL,'ptr738.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4745,305,'PTR','ptr739','ptr739.in-addr.arpa.',NULL,NULL,NULL,'ptr739.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4746,307,'TXT','txt740','test-txt-740',NULL,NULL,NULL,NULL,'test-txt-740',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4747,280,'AAAA','host741','2001:db8::5c9c',NULL,'2001:db8::5c9c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4748,307,'CNAME','cname742','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4749,287,'A','host743','198.51.60.84','198.51.60.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4750,265,'TXT','txt744','test-txt-744',NULL,NULL,NULL,NULL,'test-txt-744',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4751,298,'PTR','ptr745','ptr745.in-addr.arpa.',NULL,NULL,NULL,'ptr745.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4752,274,'CNAME','cname746','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4753,302,'TXT','txt747','test-txt-747',NULL,NULL,NULL,NULL,'test-txt-747',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4754,277,'CNAME','cname748','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4755,309,'A','host749','198.51.64.54','198.51.64.54',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4756,292,'AAAA','host750','2001:db8::d250',NULL,'2001:db8::d250',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4757,292,'A','host751','198.51.197.147','198.51.197.147',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4758,301,'CNAME','cname752','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4759,260,'AAAA','host753','2001:db8::a037',NULL,'2001:db8::a037',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4760,308,'TXT','txt754','test-txt-754',NULL,NULL,NULL,NULL,'test-txt-754',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4761,282,'TXT','txt755','test-txt-755',NULL,NULL,NULL,NULL,'test-txt-755',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4762,300,'AAAA','host756','2001:db8::a03',NULL,'2001:db8::a03',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4763,287,'A','host757','198.51.110.23','198.51.110.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4764,284,'TXT','txt758','test-txt-758',NULL,NULL,NULL,NULL,'test-txt-758',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4765,260,'CNAME','cname759','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4766,284,'TXT','txt760','test-txt-760',NULL,NULL,NULL,NULL,'test-txt-760',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4767,267,'PTR','ptr761','ptr761.in-addr.arpa.',NULL,NULL,NULL,'ptr761.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4768,264,'TXT','txt762','test-txt-762',NULL,NULL,NULL,NULL,'test-txt-762',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4769,261,'PTR','ptr763','ptr763.in-addr.arpa.',NULL,NULL,NULL,'ptr763.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4770,297,'AAAA','host764','2001:db8::2165',NULL,'2001:db8::2165',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4771,260,'CNAME','cname765','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4772,272,'CNAME','cname766','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4773,300,'TXT','txt767','test-txt-767',NULL,NULL,NULL,NULL,'test-txt-767',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4774,287,'TXT','txt768','test-txt-768',NULL,NULL,NULL,NULL,'test-txt-768',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4775,263,'AAAA','host769','2001:db8::7057',NULL,'2001:db8::7057',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4776,290,'CNAME','cname770','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4777,301,'TXT','txt771','test-txt-771',NULL,NULL,NULL,NULL,'test-txt-771',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4778,262,'CNAME','cname772','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4779,293,'AAAA','host773','2001:db8::f315',NULL,'2001:db8::f315',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4780,291,'AAAA','host774','2001:db8::a294',NULL,'2001:db8::a294',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4781,281,'AAAA','host775','2001:db8::c875',NULL,'2001:db8::c875',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4782,266,'TXT','txt776','test-txt-776',NULL,NULL,NULL,NULL,'test-txt-776',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4783,308,'AAAA','host777','2001:db8::e602',NULL,'2001:db8::e602',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4784,307,'PTR','ptr778','ptr778.in-addr.arpa.',NULL,NULL,NULL,'ptr778.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4785,272,'CNAME','cname779','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4786,266,'CNAME','cname780','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4787,306,'TXT','txt781','test-txt-781',NULL,NULL,NULL,NULL,'test-txt-781',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4788,264,'PTR','ptr782','ptr782.in-addr.arpa.',NULL,NULL,NULL,'ptr782.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4789,302,'PTR','ptr783','ptr783.in-addr.arpa.',NULL,NULL,NULL,'ptr783.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4790,263,'A','host784','198.51.225.243','198.51.225.243',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4791,275,'A','host785','198.51.115.136','198.51.115.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4792,299,'A','host786','198.51.30.236','198.51.30.236',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4793,261,'CNAME','cname787','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4794,282,'TXT','txt788','test-txt-788',NULL,NULL,NULL,NULL,'test-txt-788',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4795,284,'AAAA','host789','2001:db8::478',NULL,'2001:db8::478',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4796,297,'CNAME','cname790','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4797,263,'CNAME','cname791','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4798,297,'AAAA','host792','2001:db8::3021',NULL,'2001:db8::3021',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4799,294,'A','host793','198.51.162.77','198.51.162.77',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4800,273,'A','host794','198.51.16.191','198.51.16.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4801,309,'CNAME','cname795','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4802,273,'PTR','ptr796','ptr796.in-addr.arpa.',NULL,NULL,NULL,'ptr796.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4803,292,'PTR','ptr797','ptr797.in-addr.arpa.',NULL,NULL,NULL,'ptr797.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4804,307,'TXT','txt798','test-txt-798',NULL,NULL,NULL,NULL,'test-txt-798',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4805,309,'PTR','ptr799','ptr799.in-addr.arpa.',NULL,NULL,NULL,'ptr799.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4806,286,'AAAA','host800','2001:db8::39ae',NULL,'2001:db8::39ae',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4807,302,'CNAME','cname801','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4808,309,'CNAME','cname802','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4809,304,'TXT','txt803','test-txt-803',NULL,NULL,NULL,NULL,'test-txt-803',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4810,294,'A','host804','198.51.234.229','198.51.234.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4811,296,'AAAA','host805','2001:db8::f829',NULL,'2001:db8::f829',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4812,275,'CNAME','cname806','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4813,292,'TXT','txt807','test-txt-807',NULL,NULL,NULL,NULL,'test-txt-807',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4814,296,'CNAME','cname808','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4815,289,'A','host809','198.51.55.148','198.51.55.148',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4816,269,'A','host810','198.51.103.28','198.51.103.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4817,262,'TXT','txt811','test-txt-811',NULL,NULL,NULL,NULL,'test-txt-811',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4818,308,'AAAA','host812','2001:db8::4ab9',NULL,'2001:db8::4ab9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4819,286,'A','host813','198.51.99.112','198.51.99.112',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4820,264,'PTR','ptr814','ptr814.in-addr.arpa.',NULL,NULL,NULL,'ptr814.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4821,275,'A','host815','198.51.95.217','198.51.95.217',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4822,300,'TXT','txt816','test-txt-816',NULL,NULL,NULL,NULL,'test-txt-816',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4823,309,'TXT','txt817','test-txt-817',NULL,NULL,NULL,NULL,'test-txt-817',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4824,286,'TXT','txt818','test-txt-818',NULL,NULL,NULL,NULL,'test-txt-818',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4825,274,'CNAME','cname819','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4826,263,'TXT','txt820','test-txt-820',NULL,NULL,NULL,NULL,'test-txt-820',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4827,279,'A','host821','198.51.159.188','198.51.159.188',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4828,292,'A','host822','198.51.35.210','198.51.35.210',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4829,266,'AAAA','host823','2001:db8::767c',NULL,'2001:db8::767c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4830,304,'PTR','ptr824','ptr824.in-addr.arpa.',NULL,NULL,NULL,'ptr824.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4831,302,'TXT','txt825','test-txt-825',NULL,NULL,NULL,NULL,'test-txt-825',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4832,281,'AAAA','host826','2001:db8::421',NULL,'2001:db8::421',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4833,272,'TXT','txt827','test-txt-827',NULL,NULL,NULL,NULL,'test-txt-827',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4834,280,'A','host828','198.51.115.172','198.51.115.172',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4835,308,'TXT','txt829','test-txt-829',NULL,NULL,NULL,NULL,'test-txt-829',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4836,283,'CNAME','cname830','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4837,309,'CNAME','cname831','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4838,280,'CNAME','cname832','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4839,271,'AAAA','host833','2001:db8::bf9a',NULL,'2001:db8::bf9a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4840,305,'A','host834','198.51.12.83','198.51.12.83',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4841,289,'PTR','ptr835','ptr835.in-addr.arpa.',NULL,NULL,NULL,'ptr835.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4842,304,'A','host836','198.51.190.159','198.51.190.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4843,263,'TXT','txt837','test-txt-837',NULL,NULL,NULL,NULL,'test-txt-837',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4844,269,'PTR','ptr838','ptr838.in-addr.arpa.',NULL,NULL,NULL,'ptr838.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4845,302,'A','host839','198.51.158.232','198.51.158.232',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4846,301,'PTR','ptr840','ptr840.in-addr.arpa.',NULL,NULL,NULL,'ptr840.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4847,285,'CNAME','cname841','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4848,275,'A','host842','198.51.177.222','198.51.177.222',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4849,272,'AAAA','host843','2001:db8::63f5',NULL,'2001:db8::63f5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4850,269,'CNAME','cname844','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4851,302,'A','host845','198.51.179.227','198.51.179.227',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4852,276,'AAAA','host846','2001:db8::c84d',NULL,'2001:db8::c84d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4853,274,'A','host847','198.51.27.76','198.51.27.76',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4854,290,'CNAME','cname848','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4855,265,'CNAME','cname849','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4856,265,'CNAME','cname850','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4857,301,'AAAA','host851','2001:db8::6102',NULL,'2001:db8::6102',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4858,263,'PTR','ptr852','ptr852.in-addr.arpa.',NULL,NULL,NULL,'ptr852.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4859,269,'TXT','txt853','test-txt-853',NULL,NULL,NULL,NULL,'test-txt-853',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4860,304,'PTR','ptr854','ptr854.in-addr.arpa.',NULL,NULL,NULL,'ptr854.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4861,273,'A','host855','198.51.242.72','198.51.242.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4862,285,'A','host856','198.51.156.15','198.51.156.15',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4863,276,'AAAA','host857','2001:db8::b2a1',NULL,'2001:db8::b2a1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4864,288,'TXT','txt858','test-txt-858',NULL,NULL,NULL,NULL,'test-txt-858',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4865,299,'A','host859','198.51.98.187','198.51.98.187',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4866,286,'AAAA','host860','2001:db8::6c47',NULL,'2001:db8::6c47',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4867,308,'PTR','ptr861','ptr861.in-addr.arpa.',NULL,NULL,NULL,'ptr861.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4868,288,'AAAA','host862','2001:db8::2253',NULL,'2001:db8::2253',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4869,276,'A','host863','198.51.180.106','198.51.180.106',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4870,269,'PTR','ptr864','ptr864.in-addr.arpa.',NULL,NULL,NULL,'ptr864.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4871,299,'CNAME','cname865','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4872,271,'A','host866','198.51.177.65','198.51.177.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4873,264,'TXT','txt867','test-txt-867',NULL,NULL,NULL,NULL,'test-txt-867',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4874,301,'CNAME','cname868','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4875,302,'PTR','ptr869','ptr869.in-addr.arpa.',NULL,NULL,NULL,'ptr869.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4876,265,'PTR','ptr870','ptr870.in-addr.arpa.',NULL,NULL,NULL,'ptr870.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4877,306,'TXT','txt871','test-txt-871',NULL,NULL,NULL,NULL,'test-txt-871',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4878,278,'A','host872','198.51.157.11','198.51.157.11',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4879,284,'CNAME','cname873','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4880,271,'TXT','txt874','test-txt-874',NULL,NULL,NULL,NULL,'test-txt-874',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4881,308,'A','host875','198.51.213.107','198.51.213.107',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4882,303,'PTR','ptr876','ptr876.in-addr.arpa.',NULL,NULL,NULL,'ptr876.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4883,308,'TXT','txt877','test-txt-877',NULL,NULL,NULL,NULL,'test-txt-877',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4884,279,'CNAME','cname878','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4885,268,'A','host879','198.51.111.69','198.51.111.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4886,297,'AAAA','host880','2001:db8::ec3a',NULL,'2001:db8::ec3a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4887,302,'CNAME','cname881','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4888,285,'PTR','ptr882','ptr882.in-addr.arpa.',NULL,NULL,NULL,'ptr882.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4889,303,'PTR','ptr883','ptr883.in-addr.arpa.',NULL,NULL,NULL,'ptr883.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4890,307,'TXT','txt884','test-txt-884',NULL,NULL,NULL,NULL,'test-txt-884',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4891,260,'A','host885','198.51.195.78','198.51.195.78',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4892,266,'TXT','txt886','test-txt-886',NULL,NULL,NULL,NULL,'test-txt-886',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4893,276,'CNAME','cname887','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4894,276,'CNAME','cname888','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4895,279,'A','host889','198.51.151.186','198.51.151.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4896,277,'PTR','ptr890','ptr890.in-addr.arpa.',NULL,NULL,NULL,'ptr890.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4897,283,'PTR','ptr891','ptr891.in-addr.arpa.',NULL,NULL,NULL,'ptr891.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4898,275,'TXT','txt892','test-txt-892',NULL,NULL,NULL,NULL,'test-txt-892',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4899,261,'AAAA','host893','2001:db8::b20b',NULL,'2001:db8::b20b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4900,286,'A','host894','198.51.159.101','198.51.159.101',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4901,292,'AAAA','host895','2001:db8::c66d',NULL,'2001:db8::c66d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4902,293,'CNAME','cname896','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4903,292,'AAAA','host897','2001:db8::b457',NULL,'2001:db8::b457',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4904,276,'AAAA','host898','2001:db8::1648',NULL,'2001:db8::1648',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4905,272,'CNAME','cname899','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4906,292,'CNAME','cname900','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4907,297,'CNAME','cname901','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4908,300,'PTR','ptr902','ptr902.in-addr.arpa.',NULL,NULL,NULL,'ptr902.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4909,272,'PTR','ptr903','ptr903.in-addr.arpa.',NULL,NULL,NULL,'ptr903.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4910,296,'CNAME','cname904','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4911,309,'TXT','txt905','test-txt-905',NULL,NULL,NULL,NULL,'test-txt-905',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4912,268,'CNAME','cname906','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4913,279,'TXT','txt907','test-txt-907',NULL,NULL,NULL,NULL,'test-txt-907',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4914,287,'AAAA','host908','2001:db8::6302',NULL,'2001:db8::6302',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4915,308,'TXT','txt909','test-txt-909',NULL,NULL,NULL,NULL,'test-txt-909',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4916,290,'PTR','ptr910','ptr910.in-addr.arpa.',NULL,NULL,NULL,'ptr910.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4917,285,'TXT','txt911','test-txt-911',NULL,NULL,NULL,NULL,'test-txt-911',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4918,275,'CNAME','cname912','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4919,262,'A','host913','198.51.71.164','198.51.71.164',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4920,285,'PTR','ptr914','ptr914.in-addr.arpa.',NULL,NULL,NULL,'ptr914.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4921,299,'TXT','txt915','test-txt-915',NULL,NULL,NULL,NULL,'test-txt-915',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4922,277,'A','host916','198.51.167.190','198.51.167.190',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4923,270,'A','host917','198.51.100.70','198.51.100.70',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4924,265,'TXT','txt918','test-txt-918',NULL,NULL,NULL,NULL,'test-txt-918',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4925,303,'TXT','txt919','test-txt-919',NULL,NULL,NULL,NULL,'test-txt-919',3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4926,275,'PTR','ptr920','ptr920.in-addr.arpa.',NULL,NULL,NULL,'ptr920.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4927,305,'PTR','ptr921','ptr921.in-addr.arpa.',NULL,NULL,NULL,'ptr921.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4928,298,'PTR','ptr922','ptr922.in-addr.arpa.',NULL,NULL,NULL,'ptr922.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4929,287,'A','host923','198.51.245.204','198.51.245.204',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4930,261,'A','host924','198.51.165.95','198.51.165.95',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:49',NULL,'2025-10-24 14:40:49',NULL,NULL,NULL,NULL),
(4931,282,'AAAA','host925','2001:db8::ba20',NULL,'2001:db8::ba20',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4932,309,'TXT','txt926','test-txt-926',NULL,NULL,NULL,NULL,'test-txt-926',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4933,273,'A','host927','198.51.240.124','198.51.240.124',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4934,308,'CNAME','cname928','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4935,308,'PTR','ptr929','ptr929.in-addr.arpa.',NULL,NULL,NULL,'ptr929.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4936,301,'TXT','txt930','test-txt-930',NULL,NULL,NULL,NULL,'test-txt-930',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4937,302,'PTR','ptr931','ptr931.in-addr.arpa.',NULL,NULL,NULL,'ptr931.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4938,287,'A','host932','198.51.92.184','198.51.92.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4939,299,'A','host933','198.51.188.45','198.51.188.45',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4940,306,'PTR','ptr934','ptr934.in-addr.arpa.',NULL,NULL,NULL,'ptr934.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4941,308,'A','host935','198.51.57.86','198.51.57.86',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4942,276,'AAAA','host936','2001:db8::667e',NULL,'2001:db8::667e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4943,300,'A','host937','198.51.111.143','198.51.111.143',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4944,289,'CNAME','cname938','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4945,300,'AAAA','host939','2001:db8::af5d',NULL,'2001:db8::af5d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4946,309,'A','host940','198.51.106.36','198.51.106.36',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4947,278,'PTR','ptr941','ptr941.in-addr.arpa.',NULL,NULL,NULL,'ptr941.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4948,288,'AAAA','host942','2001:db8::36dd',NULL,'2001:db8::36dd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4949,308,'TXT','txt943','test-txt-943',NULL,NULL,NULL,NULL,'test-txt-943',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4950,305,'CNAME','cname944','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4951,284,'AAAA','host945','2001:db8::8ba8',NULL,'2001:db8::8ba8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4952,265,'CNAME','cname946','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4953,297,'AAAA','host947','2001:db8::2bb0',NULL,'2001:db8::2bb0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4954,289,'CNAME','cname948','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4955,262,'AAAA','host949','2001:db8::e327',NULL,'2001:db8::e327',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4956,288,'A','host950','198.51.154.72','198.51.154.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4957,275,'CNAME','cname951','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4958,286,'A','host952','198.51.130.236','198.51.130.236',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4959,309,'CNAME','cname953','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4960,302,'A','host954','198.51.28.13','198.51.28.13',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4961,294,'AAAA','host955','2001:db8::79fe',NULL,'2001:db8::79fe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4962,280,'TXT','txt956','test-txt-956',NULL,NULL,NULL,NULL,'test-txt-956',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4963,305,'PTR','ptr957','ptr957.in-addr.arpa.',NULL,NULL,NULL,'ptr957.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4964,261,'PTR','ptr958','ptr958.in-addr.arpa.',NULL,NULL,NULL,'ptr958.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4965,304,'PTR','ptr959','ptr959.in-addr.arpa.',NULL,NULL,NULL,'ptr959.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4966,272,'AAAA','host960','2001:db8::59bc',NULL,'2001:db8::59bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4967,304,'CNAME','cname961','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4968,279,'A','host962','198.51.224.248','198.51.224.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4969,266,'PTR','ptr963','ptr963.in-addr.arpa.',NULL,NULL,NULL,'ptr963.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4970,296,'TXT','txt964','test-txt-964',NULL,NULL,NULL,NULL,'test-txt-964',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4971,296,'TXT','txt965','test-txt-965',NULL,NULL,NULL,NULL,'test-txt-965',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4972,288,'CNAME','cname966','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4973,294,'PTR','ptr967','ptr967.in-addr.arpa.',NULL,NULL,NULL,'ptr967.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4974,307,'PTR','ptr968','ptr968.in-addr.arpa.',NULL,NULL,NULL,'ptr968.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4975,266,'AAAA','host969','2001:db8::329',NULL,'2001:db8::329',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4976,301,'TXT','txt970','test-txt-970',NULL,NULL,NULL,NULL,'test-txt-970',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4977,281,'PTR','ptr971','ptr971.in-addr.arpa.',NULL,NULL,NULL,'ptr971.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4978,308,'AAAA','host972','2001:db8::12cc',NULL,'2001:db8::12cc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4979,280,'AAAA','host973','2001:db8::53',NULL,'2001:db8::53',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4980,272,'AAAA','host974','2001:db8::980b',NULL,'2001:db8::980b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4981,300,'A','host975','198.51.25.175','198.51.25.175',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4982,280,'A','host976','198.51.90.192','198.51.90.192',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4983,307,'TXT','txt977','test-txt-977',NULL,NULL,NULL,NULL,'test-txt-977',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4984,286,'A','host978','198.51.185.78','198.51.185.78',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4985,295,'AAAA','host979','2001:db8::2cb3',NULL,'2001:db8::2cb3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4986,278,'TXT','txt980','test-txt-980',NULL,NULL,NULL,NULL,'test-txt-980',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4987,306,'CNAME','cname981','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4988,294,'TXT','txt982','test-txt-982',NULL,NULL,NULL,NULL,'test-txt-982',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4989,308,'CNAME','cname983','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4990,275,'CNAME','cname984','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4991,272,'TXT','txt985','test-txt-985',NULL,NULL,NULL,NULL,'test-txt-985',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4992,260,'TXT','txt986','test-txt-986',NULL,NULL,NULL,NULL,'test-txt-986',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4993,298,'TXT','txt987','test-txt-987',NULL,NULL,NULL,NULL,'test-txt-987',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4994,304,'TXT','txt988','test-txt-988',NULL,NULL,NULL,NULL,'test-txt-988',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4995,272,'A','host989','198.51.251.192','198.51.251.192',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4996,290,'AAAA','host990','2001:db8::1603',NULL,'2001:db8::1603',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4997,261,'AAAA','host991','2001:db8::8b9a',NULL,'2001:db8::8b9a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4998,309,'PTR','ptr992','ptr992.in-addr.arpa.',NULL,NULL,NULL,'ptr992.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(4999,260,'CNAME','cname993','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5000,267,'PTR','ptr994','ptr994.in-addr.arpa.',NULL,NULL,NULL,'ptr994.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5001,274,'AAAA','host995','2001:db8::1b0c',NULL,'2001:db8::1b0c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5002,268,'A','host996','198.51.80.146','198.51.80.146',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5003,278,'AAAA','host997','2001:db8::6439',NULL,'2001:db8::6439',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5004,288,'PTR','ptr998','ptr998.in-addr.arpa.',NULL,NULL,NULL,'ptr998.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5005,279,'AAAA','host999','2001:db8::4e7b',NULL,'2001:db8::4e7b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5006,304,'TXT','txt1000','test-txt-1000',NULL,NULL,NULL,NULL,'test-txt-1000',3600,NULL,NULL,'active',1,'2025-10-24 14:40:50',NULL,'2025-10-24 14:40:50',NULL,NULL,NULL,NULL),
(5007,314,'A','testcname','192.168.1.3','192.168.1.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',2,'2025-11-06 13:34:34',NULL,NULL,NULL,NULL,NULL,NULL);
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
(2,'guittou','guittou@gmail.com','$2y$10$.CJ6UeeKXSj7O3dZGcdtw.bjXze2e5z.n58462/hS.Rk4VgH5D21q','database','2025-10-20 09:24:16','2025-11-11 07:44:36',1);
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
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_history`
--

LOCK TABLES `zone_file_history` WRITE;
/*!40000 ALTER TABLE `zone_file_history` DISABLE KEYS */;
INSERT INTO `zone_file_history` VALUES
(20,310,'created','include.include','ii.db','include',NULL,'active',NULL,NULL,2,'2025-10-28 08:12:12','Zone file created'),
(21,310,'assign_include','include.include','ii.db','include','active','active',NULL,NULL,2,'2025-10-28 08:12:12','Include assigned to parent \'common-include-10.inc.local\' (ID: 309)'),
(22,311,'created','test1-include','test1-include.db','include',NULL,'active',NULL,NULL,2,'2025-11-04 08:26:12','Zone file created'),
(23,311,'assign_include','test1-include','test1-include.db','include','active','active',NULL,NULL,2,'2025-11-04 08:26:12','Include assigned to parent \'test-master-4.local\' (ID: 263)'),
(24,312,'created','test2-include','test2-include.db','include',NULL,'active',NULL,NULL,2,'2025-11-04 08:26:44','Zone file created'),
(25,312,'assign_include','test2-include','test2-include.db','include','active','active',NULL,NULL,2,'2025-11-04 08:26:44','Include assigned to parent \'test-master-4.local\' (ID: 263)'),
(26,313,'created','test3-include','test3-include.db','include',NULL,'active',NULL,NULL,2,'2025-11-04 08:27:16','Zone file created'),
(27,313,'assign_include','test3-include','test3-include.db','include','active','active',NULL,NULL,2,'2025-11-04 08:27:16','Include assigned to parent \'test-master-4.local\' (ID: 263)'),
(28,314,'created','include1','inc.db','include',NULL,'active',NULL,NULL,2,'2025-11-06 10:24:45','Zone file created'),
(29,314,'assign_include','include1','inc.db','include','active','active',NULL,NULL,2,'2025-11-06 10:24:45','Include assigned to parent \'test-master-1.local\' (ID: 260)'),
(30,260,'updated','test-master-1.local','db.test-master-1.local','master','active','active','$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102401 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n','$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102401 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n',2,'2025-11-08 22:03:06','Zone file updated'),
(31,262,'updated','test-master-3.local','db.test-master-3.local','master','active','active','$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102403 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n','$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102403 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n',2,'2025-11-08 22:55:52','Zone file updated'),
(32,315,'created','gdfg_uk','dfgdgdg.db','master',NULL,'active',NULL,NULL,2,'2025-11-10 22:06:51','Zone file created');
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
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
INSERT INTO `zone_file_includes` VALUES
(45,272,300,1,'2025-10-24 16:40:48'),
(46,289,301,2,'2025-10-24 16:40:48'),
(47,264,302,3,'2025-10-24 16:40:48'),
(48,265,303,4,'2025-10-24 16:40:48'),
(49,270,304,5,'2025-10-24 16:40:48'),
(50,281,305,6,'2025-10-24 16:40:48'),
(51,292,306,7,'2025-10-24 16:40:48'),
(52,271,307,8,'2025-10-24 16:40:48'),
(53,296,308,9,'2025-10-24 16:40:48'),
(54,268,309,10,'2025-10-24 16:40:48'),
(55,309,310,0,'2025-10-28 09:12:12'),
(56,263,311,0,'2025-11-04 09:26:12'),
(57,263,312,0,'2025-11-04 09:26:44'),
(58,263,313,0,'2025-11-04 09:27:16'),
(59,260,314,0,'2025-11-06 11:24:45');
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
) ENGINE=InnoDB AUTO_INCREMENT=154 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_validation`
--

LOCK TABLES `zone_file_validation` WRITE;
/*!40000 ALTER TABLE `zone_file_validation` DISABLE KEYS */;
INSERT INTO `zone_file_validation` VALUES
(135,261,'pending','Validation queued for background processing','2025-10-25 09:54:11',2),
(136,307,'pending','Validation queued for top master zone (ID: 271)','2025-10-26 10:56:01',2),
(137,271,'pending','Validation queued for background processing','2025-10-26 10:56:01',2),
(138,261,'passed','Command: named-checkzone -q \'test-master-2.local\' \'/tmp/dns3_validate_68fdfe5d8c74e/zone_261_flat.db\' 2>&1\nExit Code: 0\n\n','2025-10-26 10:56:29',2),
(139,271,'passed','Command: named-checkzone -q \'test-master-12.local\' \'/tmp/dns3_validate_68fdfe5d8fa0f/zone_271_flat.db\' 2>&1\nExit Code: 0\n\n','2025-10-26 10:56:29',2),
(140,307,'passed','Command: named-checkzone -q \'test-master-12.local\' \'/tmp/dns3_validate_68fdfe5d8fa0f/zone_271_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-12.local\' (ID: 271):\n\n','2025-10-26 10:56:29',2),
(141,310,'pending','Validation queued for top master zone (ID: 268)','2025-10-28 08:13:47',2),
(142,268,'pending','Validation queued for background processing','2025-10-28 08:13:47',2),
(143,268,'passed','Command: named-checkzone -q \'test-master-9.local\' \'/tmp/dns3_validate_69007b4ca83f8/zone_268_flat.db\' 2>&1\nExit Code: 0\n\n','2025-10-28 08:14:04',2),
(144,309,'passed','Command: named-checkzone -q \'test-master-9.local\' \'/tmp/dns3_validate_69007b4ca83f8/zone_268_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-9.local\' (ID: 268):\n\n','2025-10-28 08:14:04',2),
(145,310,'passed','Command: named-checkzone -q \'test-master-9.local\' \'/tmp/dns3_validate_69007b4ca83f8/zone_268_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-9.local\' (ID: 268):\n\n','2025-10-28 08:14:04',2),
(146,272,'pending','Validation queued for background processing','2025-11-04 15:58:32',2),
(147,272,'passed','Command: named-checkzone -q \'test-master-13.local\' \'/tmp/dns3_validate_690a22d032a93/zone_272_flat.db\' 2>&1\nExit Code: 0\n\n','2025-11-04 15:59:12',2),
(148,300,'passed','Command: named-checkzone -q \'test-master-13.local\' \'/tmp/dns3_validate_690a22d032a93/zone_272_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-13.local\' (ID: 272):\n\n','2025-11-04 15:59:12',2),
(149,262,'pending','Validation queued for background processing','2025-11-05 21:19:33',2),
(150,262,'passed','Command: named-checkzone -q \'test-master-3.local\' \'/tmp/dns3_validate_690bbf70c7553/zone_262_flat.db\' 2>&1\nExit Code: 0\n\n','2025-11-05 21:19:44',2),
(151,260,'pending','Validation queued for background processing','2025-11-08 22:03:06',2),
(152,262,'pending','Validation queued for background processing','2025-11-08 22:55:52',2),
(153,315,'pending','Validation queued for background processing','2025-11-10 22:06:51',2);
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
  `domain` varchar(255) DEFAULT NULL COMMENT 'Domain name for master zones (migrated from domaine_list)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_name` (`name`),
  KEY `idx_file_type` (`file_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_zone_type_status_name` (`file_type`,`status`,`name`(100)),
  KEY `idx_directory` (`directory`),
  KEY `idx_domain` (`domain`),
  CONSTRAINT `zone_files_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `zone_files_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=316 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(260,'test-master-1.local','db.test-master-1.local',NULL,'$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102401 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n','master','active',1,2,'2025-10-24 14:40:48','2025-11-08 22:03:06','test.fr'),
(261,'test-master-2.local','db.test-master-2.local',NULL,'$ORIGIN test-master-2.local.\n$TTL 3600\n@ IN SOA ns1.test-master-2.local. admin.test-master-2.local. ( 2025102402 3600 1800 604800 86400 )\n    IN NS ns1.test-master-2.local.\nns1 IN A 192.0.2.3\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-11-08 20:42:23','dsfsdf.dfsdfs.sdfsdfsd.sdfsdf.sdfsdf.fr'),
(262,'test-master-3.local','db.test-master-3.local',NULL,'$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102403 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n','master','active',1,2,'2025-10-24 14:40:48','2025-11-08 22:55:52','test3.com'),
(263,'test-master-4.local','db.test-master-4.local',NULL,'$ORIGIN test-master-4.local.\n$TTL 3600\n@ IN SOA ns1.test-master-4.local. admin.test-master-4.local. ( 2025102404 3600 1800 604800 86400 )\n    IN NS ns1.test-master-4.local.\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(264,'test-master-5.local','db.test-master-5.local',NULL,'$ORIGIN test-master-5.local.\n$TTL 3600\n@ IN SOA ns1.test-master-5.local. admin.test-master-5.local. ( 2025102405 3600 1800 604800 86400 )\n    IN NS ns1.test-master-5.local.\nns1 IN A 192.0.2.6\n\n$INCLUDE includes/common-include-3.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(265,'test-master-6.local','db.test-master-6.local',NULL,'$ORIGIN test-master-6.local.\n$TTL 3600\n@ IN SOA ns1.test-master-6.local. admin.test-master-6.local. ( 2025102406 3600 1800 604800 86400 )\n    IN NS ns1.test-master-6.local.\nns1 IN A 192.0.2.7\n\n$INCLUDE includes/common-include-4.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(266,'test-master-7.local','db.test-master-7.local',NULL,'$ORIGIN test-master-7.local.\n$TTL 3600\n@ IN SOA ns1.test-master-7.local. admin.test-master-7.local. ( 2025102407 3600 1800 604800 86400 )\n    IN NS ns1.test-master-7.local.\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(267,'test-master-8.local','db.test-master-8.local',NULL,'$ORIGIN test-master-8.local.\n$TTL 3600\n@ IN SOA ns1.test-master-8.local. admin.test-master-8.local. ( 2025102408 3600 1800 604800 86400 )\n    IN NS ns1.test-master-8.local.\nns1 IN A 192.0.2.9\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(268,'test-master-9.local','db.test-master-9.local',NULL,'$ORIGIN test-master-9.local.\n$TTL 3600\n@ IN SOA ns1.test-master-9.local. admin.test-master-9.local. ( 2025102409 3600 1800 604800 86400 )\n    IN NS ns1.test-master-9.local.\nns1 IN A 192.0.2.10\n\n$INCLUDE includes/common-include-10.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(269,'test-master-10.local','db.test-master-10.local',NULL,'$ORIGIN test-master-10.local.\n$TTL 3600\n@ IN SOA ns1.test-master-10.local. admin.test-master-10.local. ( 2025102410 3600 1800 604800 86400 )\n    IN NS ns1.test-master-10.local.\nns1 IN A 192.0.2.11\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(270,'test-master-11.local','db.test-master-11.local',NULL,'$ORIGIN test-master-11.local.\n$TTL 3600\n@ IN SOA ns1.test-master-11.local. admin.test-master-11.local. ( 2025102411 3600 1800 604800 86400 )\n    IN NS ns1.test-master-11.local.\nns1 IN A 192.0.2.12\n\n$INCLUDE includes/common-include-5.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(271,'test-master-12.local','db.test-master-12.local',NULL,'$ORIGIN test-master-12.local.\n$TTL 3600\n@ IN SOA ns1.test-master-12.local. admin.test-master-12.local. ( 2025102412 3600 1800 604800 86400 )\n    IN NS ns1.test-master-12.local.\nns1 IN A 192.0.2.13\n\n$INCLUDE includes/common-include-8.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(272,'test-master-13.local','db.test-master-13.local',NULL,'$ORIGIN test-master-13.local.\n$TTL 3600\n@ IN SOA ns1.test-master-13.local. admin.test-master-13.local. ( 2025102413 3600 1800 604800 86400 )\n    IN NS ns1.test-master-13.local.\nns1 IN A 192.0.2.14\n\n$INCLUDE includes/common-include-1.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(273,'test-master-14.local','db.test-master-14.local',NULL,'$ORIGIN test-master-14.local.\n$TTL 3600\n@ IN SOA ns1.test-master-14.local. admin.test-master-14.local. ( 2025102414 3600 1800 604800 86400 )\n    IN NS ns1.test-master-14.local.\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(274,'test-master-15.local','db.test-master-15.local',NULL,'$ORIGIN test-master-15.local.\n$TTL 3600\n@ IN SOA ns1.test-master-15.local. admin.test-master-15.local. ( 2025102415 3600 1800 604800 86400 )\n    IN NS ns1.test-master-15.local.\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(275,'test-master-16.local','db.test-master-16.local',NULL,'$ORIGIN test-master-16.local.\n$TTL 3600\n@ IN SOA ns1.test-master-16.local. admin.test-master-16.local. ( 2025102416 3600 1800 604800 86400 )\n    IN NS ns1.test-master-16.local.\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(276,'test-master-17.local','db.test-master-17.local',NULL,'$ORIGIN test-master-17.local.\n$TTL 3600\n@ IN SOA ns1.test-master-17.local. admin.test-master-17.local. ( 2025102417 3600 1800 604800 86400 )\n    IN NS ns1.test-master-17.local.\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(277,'test-master-18.local','db.test-master-18.local',NULL,'$ORIGIN test-master-18.local.\n$TTL 3600\n@ IN SOA ns1.test-master-18.local. admin.test-master-18.local. ( 2025102418 3600 1800 604800 86400 )\n    IN NS ns1.test-master-18.local.\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(278,'test-master-19.local','db.test-master-19.local',NULL,'$ORIGIN test-master-19.local.\n$TTL 3600\n@ IN SOA ns1.test-master-19.local. admin.test-master-19.local. ( 2025102419 3600 1800 604800 86400 )\n    IN NS ns1.test-master-19.local.\nns1 IN A 192.0.2.20\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(279,'test-master-20.local','db.test-master-20.local',NULL,'$ORIGIN test-master-20.local.\n$TTL 3600\n@ IN SOA ns1.test-master-20.local. admin.test-master-20.local. ( 2025102420 3600 1800 604800 86400 )\n    IN NS ns1.test-master-20.local.\nns1 IN A 192.0.2.21\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(280,'test-master-21.local','db.test-master-21.local',NULL,'$ORIGIN test-master-21.local.\n$TTL 3600\n@ IN SOA ns1.test-master-21.local. admin.test-master-21.local. ( 2025102421 3600 1800 604800 86400 )\n    IN NS ns1.test-master-21.local.\nns1 IN A 192.0.2.22\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(281,'test-master-22.local','db.test-master-22.local',NULL,'$ORIGIN test-master-22.local.\n$TTL 3600\n@ IN SOA ns1.test-master-22.local. admin.test-master-22.local. ( 2025102422 3600 1800 604800 86400 )\n    IN NS ns1.test-master-22.local.\nns1 IN A 192.0.2.23\n\n$INCLUDE includes/common-include-6.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(282,'test-master-23.local','db.test-master-23.local',NULL,'$ORIGIN test-master-23.local.\n$TTL 3600\n@ IN SOA ns1.test-master-23.local. admin.test-master-23.local. ( 2025102423 3600 1800 604800 86400 )\n    IN NS ns1.test-master-23.local.\nns1 IN A 192.0.2.24\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(283,'test-master-24.local','db.test-master-24.local',NULL,'$ORIGIN test-master-24.local.\n$TTL 3600\n@ IN SOA ns1.test-master-24.local. admin.test-master-24.local. ( 2025102424 3600 1800 604800 86400 )\n    IN NS ns1.test-master-24.local.\nns1 IN A 192.0.2.25\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(284,'test-master-25.local','db.test-master-25.local',NULL,'$ORIGIN test-master-25.local.\n$TTL 3600\n@ IN SOA ns1.test-master-25.local. admin.test-master-25.local. ( 2025102425 3600 1800 604800 86400 )\n    IN NS ns1.test-master-25.local.\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(285,'test-master-26.local','db.test-master-26.local',NULL,'$ORIGIN test-master-26.local.\n$TTL 3600\n@ IN SOA ns1.test-master-26.local. admin.test-master-26.local. ( 2025102426 3600 1800 604800 86400 )\n    IN NS ns1.test-master-26.local.\nns1 IN A 192.0.2.27\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(286,'test-master-27.local','db.test-master-27.local',NULL,'$ORIGIN test-master-27.local.\n$TTL 3600\n@ IN SOA ns1.test-master-27.local. admin.test-master-27.local. ( 2025102427 3600 1800 604800 86400 )\n    IN NS ns1.test-master-27.local.\nns1 IN A 192.0.2.28\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(287,'test-master-28.local','db.test-master-28.local',NULL,'$ORIGIN test-master-28.local.\n$TTL 3600\n@ IN SOA ns1.test-master-28.local. admin.test-master-28.local. ( 2025102428 3600 1800 604800 86400 )\n    IN NS ns1.test-master-28.local.\nns1 IN A 192.0.2.29\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(288,'test-master-29.local','db.test-master-29.local',NULL,'$ORIGIN test-master-29.local.\n$TTL 3600\n@ IN SOA ns1.test-master-29.local. admin.test-master-29.local. ( 2025102429 3600 1800 604800 86400 )\n    IN NS ns1.test-master-29.local.\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(289,'test-master-30.local','db.test-master-30.local',NULL,'$ORIGIN test-master-30.local.\n$TTL 3600\n@ IN SOA ns1.test-master-30.local. admin.test-master-30.local. ( 2025102430 3600 1800 604800 86400 )\n    IN NS ns1.test-master-30.local.\nns1 IN A 192.0.2.31\n\n$INCLUDE includes/common-include-2.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(290,'test-master-31.local','db.test-master-31.local',NULL,'$ORIGIN test-master-31.local.\n$TTL 3600\n@ IN SOA ns1.test-master-31.local. admin.test-master-31.local. ( 2025102431 3600 1800 604800 86400 )\n    IN NS ns1.test-master-31.local.\nns1 IN A 192.0.2.32\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(291,'test-master-32.local','db.test-master-32.local',NULL,'$ORIGIN test-master-32.local.\n$TTL 3600\n@ IN SOA ns1.test-master-32.local. admin.test-master-32.local. ( 2025102432 3600 1800 604800 86400 )\n    IN NS ns1.test-master-32.local.\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(292,'test-master-33.local','db.test-master-33.local',NULL,'$ORIGIN test-master-33.local.\n$TTL 3600\n@ IN SOA ns1.test-master-33.local. admin.test-master-33.local. ( 2025102433 3600 1800 604800 86400 )\n    IN NS ns1.test-master-33.local.\nns1 IN A 192.0.2.34\n\n$INCLUDE includes/common-include-7.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(293,'test-master-34.local','db.test-master-34.local',NULL,'$ORIGIN test-master-34.local.\n$TTL 3600\n@ IN SOA ns1.test-master-34.local. admin.test-master-34.local. ( 2025102434 3600 1800 604800 86400 )\n    IN NS ns1.test-master-34.local.\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(294,'test-master-35.local','db.test-master-35.local',NULL,'$ORIGIN test-master-35.local.\n$TTL 3600\n@ IN SOA ns1.test-master-35.local. admin.test-master-35.local. ( 2025102435 3600 1800 604800 86400 )\n    IN NS ns1.test-master-35.local.\nns1 IN A 192.0.2.36\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(295,'test-master-36.local','db.test-master-36.local',NULL,'$ORIGIN test-master-36.local.\n$TTL 3600\n@ IN SOA ns1.test-master-36.local. admin.test-master-36.local. ( 2025102436 3600 1800 604800 86400 )\n    IN NS ns1.test-master-36.local.\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(296,'test-master-37.local','db.test-master-37.local',NULL,'$ORIGIN test-master-37.local.\n$TTL 3600\n@ IN SOA ns1.test-master-37.local. admin.test-master-37.local. ( 2025102437 3600 1800 604800 86400 )\n    IN NS ns1.test-master-37.local.\nns1 IN A 192.0.2.38\n\n$INCLUDE includes/common-include-9.inc\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 16:40:48',NULL),
(297,'test-master-38.local','db.test-master-38.local',NULL,'$ORIGIN test-master-38.local.\n$TTL 3600\n@ IN SOA ns1.test-master-38.local. admin.test-master-38.local. ( 2025102438 3600 1800 604800 86400 )\n    IN NS ns1.test-master-38.local.\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(298,'test-master-39.local','db.test-master-39.local',NULL,'$ORIGIN test-master-39.local.\n$TTL 3600\n@ IN SOA ns1.test-master-39.local. admin.test-master-39.local. ( 2025102439 3600 1800 604800 86400 )\n    IN NS ns1.test-master-39.local.\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(299,'test-master-40.local','db.test-master-40.local',NULL,'$ORIGIN test-master-40.local.\n$TTL 3600\n@ IN SOA ns1.test-master-40.local. admin.test-master-40.local. ( 2025102440 3600 1800 604800 86400 )\n    IN NS ns1.test-master-40.local.\nns1 IN A 192.0.2.41\n','master','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(300,'common-include-1.inc.local','includes/common-include-1.inc',NULL,'; Include file for common records group 1\nmonitor IN A 198.51.1.10\nmonitor6 IN AAAA 2001:db8::65\ncommon-txt IN TXT \"include-group-1\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(301,'common-include-2.inc.local','includes/common-include-2.inc',NULL,'; Include file for common records group 2\nmonitor IN A 198.51.2.10\nmonitor6 IN AAAA 2001:db8::66\ncommon-txt IN TXT \"include-group-2\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(302,'common-include-3.inc.local','includes/common-include-3.inc',NULL,'; Include file for common records group 3\nmonitor IN A 198.51.3.10\nmonitor6 IN AAAA 2001:db8::67\ncommon-txt IN TXT \"include-group-3\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(303,'common-include-4.inc.local','includes/common-include-4.inc',NULL,'; Include file for common records group 4\nmonitor IN A 198.51.4.10\nmonitor6 IN AAAA 2001:db8::68\ncommon-txt IN TXT \"include-group-4\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(304,'common-include-5.inc.local','includes/common-include-5.inc',NULL,'; Include file for common records group 5\nmonitor IN A 198.51.5.10\nmonitor6 IN AAAA 2001:db8::69\ncommon-txt IN TXT \"include-group-5\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(305,'common-include-6.inc.local','includes/common-include-6.inc',NULL,'; Include file for common records group 6\nmonitor IN A 198.51.6.10\nmonitor6 IN AAAA 2001:db8::6a\ncommon-txt IN TXT \"include-group-6\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(306,'common-include-7.inc.local','includes/common-include-7.inc',NULL,'; Include file for common records group 7\nmonitor IN A 198.51.7.10\nmonitor6 IN AAAA 2001:db8::6b\ncommon-txt IN TXT \"include-group-7\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(307,'common-include-8.inc.local','includes/common-include-8.inc',NULL,'; Include file for common records group 8\nmonitor IN A 198.51.8.10\nmonitor6 IN AAAA 2001:db8::6c\ncommon-txt IN TXT \"include-group-8\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(308,'common-include-9.inc.local','includes/common-include-9.inc',NULL,'; Include file for common records group 9\nmonitor IN A 198.51.9.10\nmonitor6 IN AAAA 2001:db8::6d\ncommon-txt IN TXT \"include-group-9\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(309,'common-include-10.inc.local','includes/common-include-10.inc',NULL,'; Include file for common records group 10\nmonitor IN A 198.51.10.10\nmonitor6 IN AAAA 2001:db8::6e\ncommon-txt IN TXT \"include-group-10\"\n','include','active',1,NULL,'2025-10-24 14:40:48','2025-10-24 14:40:48',NULL),
(310,'include.include','ii.db',NULL,'','include','active',2,NULL,'2025-10-28 08:12:12',NULL,NULL),
(311,'test1-include','test1-include.db',NULL,'','include','active',2,NULL,'2025-11-04 08:26:12',NULL,NULL),
(312,'test2-include','test2-include.db',NULL,'','include','active',2,NULL,'2025-11-04 08:26:44',NULL,NULL),
(313,'test3-include','test3-include.db',NULL,'','include','active',2,NULL,'2025-11-04 08:27:16',NULL,NULL),
(314,'include1','inc.db',NULL,'','include','active',2,NULL,'2025-11-06 10:24:45',NULL,NULL),
(315,'gdfg_uk','dfgdgdg.db',NULL,'','master','active',2,NULL,'2025-11-10 22:06:51',NULL,'hfgf.uk');
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

-- Dump completed on 2025-11-11  9:13:44
