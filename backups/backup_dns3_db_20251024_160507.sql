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
INSERT INTO `dns_record_history` VALUES
(14,2006,110,'created','A','aaaaaaaabbbb','192.16.1.200','192.16.1.200',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',2,'2025-10-23 12:01:56','Record created');
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
) ENGINE=InnoDB AUTO_INCREMENT=2007 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(1006,127,'TXT','txt1','test-txt-1',NULL,NULL,NULL,NULL,'test-txt-1',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1007,144,'CNAME','cname2','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1008,122,'AAAA','host3','2001:db8::9c42',NULL,'2001:db8::9c42',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1009,124,'TXT','txt4','test-txt-4',NULL,NULL,NULL,NULL,'test-txt-4',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1010,134,'TXT','txt5','test-txt-5',NULL,NULL,NULL,NULL,'test-txt-5',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1011,115,'AAAA','host6','2001:db8::3100',NULL,'2001:db8::3100',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1012,118,'A','host7','198.51.119.114','198.51.119.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1013,131,'A','host8','198.51.184.4','198.51.184.4',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1014,146,'TXT','txt9','test-txt-9',NULL,NULL,NULL,NULL,'test-txt-9',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1015,150,'TXT','txt10','test-txt-10',NULL,NULL,NULL,NULL,'test-txt-10',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1016,148,'TXT','txt11','test-txt-11',NULL,NULL,NULL,NULL,'test-txt-11',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1017,136,'TXT','txt12','test-txt-12',NULL,NULL,NULL,NULL,'test-txt-12',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1018,129,'PTR','ptr13','ptr13.in-addr.arpa.',NULL,NULL,NULL,'ptr13.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1019,116,'A','host14','198.51.155.165','198.51.155.165',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1020,158,'A','host15','198.51.161.120','198.51.161.120',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1021,155,'A','host16','198.51.207.216','198.51.207.216',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1022,119,'A','host17','198.51.107.10','198.51.107.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1023,138,'A','host18','198.51.132.104','198.51.132.104',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1024,113,'A','host19','198.51.131.9','198.51.131.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1025,149,'PTR','ptr20','ptr20.in-addr.arpa.',NULL,NULL,NULL,'ptr20.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1026,126,'TXT','txt21','test-txt-21',NULL,NULL,NULL,NULL,'test-txt-21',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1027,128,'A','host22','198.51.152.211','198.51.152.211',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1028,114,'CNAME','cname23','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1029,144,'AAAA','host24','2001:db8::6ecc',NULL,'2001:db8::6ecc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1030,151,'AAAA','host25','2001:db8::c3f6',NULL,'2001:db8::c3f6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1031,156,'TXT','txt26','test-txt-26',NULL,NULL,NULL,NULL,'test-txt-26',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1032,144,'PTR','ptr27','ptr27.in-addr.arpa.',NULL,NULL,NULL,'ptr27.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1033,128,'A','host28','198.51.148.89','198.51.148.89',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1034,154,'TXT','txt29','test-txt-29',NULL,NULL,NULL,NULL,'test-txt-29',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1035,139,'AAAA','host30','2001:db8::c68c',NULL,'2001:db8::c68c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1036,150,'TXT','txt31','test-txt-31',NULL,NULL,NULL,NULL,'test-txt-31',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1037,155,'AAAA','host32','2001:db8::c9d7',NULL,'2001:db8::c9d7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1038,120,'AAAA','host33','2001:db8::aaaa',NULL,'2001:db8::aaaa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1039,119,'CNAME','cname34','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1040,134,'PTR','ptr35','ptr35.in-addr.arpa.',NULL,NULL,NULL,'ptr35.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1041,155,'PTR','ptr36','ptr36.in-addr.arpa.',NULL,NULL,NULL,'ptr36.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1042,121,'AAAA','host37','2001:db8::9d54',NULL,'2001:db8::9d54',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1043,152,'A','host38','198.51.73.139','198.51.73.139',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1044,115,'AAAA','host39','2001:db8::b35f',NULL,'2001:db8::b35f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1045,144,'TXT','txt40','test-txt-40',NULL,NULL,NULL,NULL,'test-txt-40',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1046,120,'AAAA','host41','2001:db8::52af',NULL,'2001:db8::52af',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1047,158,'CNAME','cname42','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1048,124,'PTR','ptr43','ptr43.in-addr.arpa.',NULL,NULL,NULL,'ptr43.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1049,122,'PTR','ptr44','ptr44.in-addr.arpa.',NULL,NULL,NULL,'ptr44.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1050,149,'PTR','ptr45','ptr45.in-addr.arpa.',NULL,NULL,NULL,'ptr45.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1051,150,'CNAME','cname46','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1052,132,'AAAA','host47','2001:db8::cc3d',NULL,'2001:db8::cc3d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1053,159,'CNAME','cname48','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1054,112,'AAAA','host49','2001:db8::7410',NULL,'2001:db8::7410',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1055,111,'CNAME','cname50','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1056,118,'PTR','ptr51','ptr51.in-addr.arpa.',NULL,NULL,NULL,'ptr51.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1057,131,'A','host52','198.51.154.110','198.51.154.110',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1058,117,'TXT','txt53','test-txt-53',NULL,NULL,NULL,NULL,'test-txt-53',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1059,121,'PTR','ptr54','ptr54.in-addr.arpa.',NULL,NULL,NULL,'ptr54.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1060,148,'CNAME','cname55','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1061,137,'PTR','ptr56','ptr56.in-addr.arpa.',NULL,NULL,NULL,'ptr56.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1062,142,'CNAME','cname57','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1063,121,'TXT','txt58','test-txt-58',NULL,NULL,NULL,NULL,'test-txt-58',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1064,137,'TXT','txt59','test-txt-59',NULL,NULL,NULL,NULL,'test-txt-59',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1065,156,'AAAA','host60','2001:db8::2c52',NULL,'2001:db8::2c52',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1066,155,'CNAME','cname61','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1067,158,'AAAA','host62','2001:db8::48c5',NULL,'2001:db8::48c5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1068,132,'AAAA','host63','2001:db8::ecbf',NULL,'2001:db8::ecbf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1069,150,'PTR','ptr64','ptr64.in-addr.arpa.',NULL,NULL,NULL,'ptr64.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1070,112,'CNAME','cname65','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1071,154,'A','host66','198.51.31.113','198.51.31.113',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1072,125,'TXT','txt67','test-txt-67',NULL,NULL,NULL,NULL,'test-txt-67',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1073,153,'A','host68','198.51.205.221','198.51.205.221',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1074,116,'CNAME','cname69','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1075,136,'TXT','txt70','test-txt-70',NULL,NULL,NULL,NULL,'test-txt-70',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1076,158,'PTR','ptr71','ptr71.in-addr.arpa.',NULL,NULL,NULL,'ptr71.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1077,140,'TXT','txt72','test-txt-72',NULL,NULL,NULL,NULL,'test-txt-72',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1078,154,'A','host73','198.51.142.129','198.51.142.129',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1079,125,'CNAME','cname74','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1080,114,'CNAME','cname75','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1081,112,'AAAA','host76','2001:db8::3546',NULL,'2001:db8::3546',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1082,144,'A','host77','198.51.89.119','198.51.89.119',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1083,132,'PTR','ptr78','ptr78.in-addr.arpa.',NULL,NULL,NULL,'ptr78.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1084,154,'PTR','ptr79','ptr79.in-addr.arpa.',NULL,NULL,NULL,'ptr79.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1085,154,'TXT','txt80','test-txt-80',NULL,NULL,NULL,NULL,'test-txt-80',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1086,151,'AAAA','host81','2001:db8::a401',NULL,'2001:db8::a401',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1087,121,'TXT','txt82','test-txt-82',NULL,NULL,NULL,NULL,'test-txt-82',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1088,155,'A','host83','198.51.129.162','198.51.129.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1089,152,'PTR','ptr84','ptr84.in-addr.arpa.',NULL,NULL,NULL,'ptr84.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1090,150,'PTR','ptr85','ptr85.in-addr.arpa.',NULL,NULL,NULL,'ptr85.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1091,150,'TXT','txt86','test-txt-86',NULL,NULL,NULL,NULL,'test-txt-86',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1092,142,'TXT','txt87','test-txt-87',NULL,NULL,NULL,NULL,'test-txt-87',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1093,143,'TXT','txt88','test-txt-88',NULL,NULL,NULL,NULL,'test-txt-88',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1094,129,'TXT','txt89','test-txt-89',NULL,NULL,NULL,NULL,'test-txt-89',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1095,151,'PTR','ptr90','ptr90.in-addr.arpa.',NULL,NULL,NULL,'ptr90.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1096,145,'CNAME','cname91','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1097,115,'TXT','txt92','test-txt-92',NULL,NULL,NULL,NULL,'test-txt-92',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1098,154,'A','host93','198.51.72.50','198.51.72.50',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1099,117,'A','host94','198.51.80.65','198.51.80.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1100,120,'A','host95','198.51.29.158','198.51.29.158',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1101,135,'TXT','txt96','test-txt-96',NULL,NULL,NULL,NULL,'test-txt-96',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1102,145,'PTR','ptr97','ptr97.in-addr.arpa.',NULL,NULL,NULL,'ptr97.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1103,113,'TXT','txt98','test-txt-98',NULL,NULL,NULL,NULL,'test-txt-98',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1104,116,'TXT','txt99','test-txt-99',NULL,NULL,NULL,NULL,'test-txt-99',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1105,140,'A','host100','198.51.180.201','198.51.180.201',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1106,127,'TXT','txt101','test-txt-101',NULL,NULL,NULL,NULL,'test-txt-101',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1107,115,'TXT','txt102','test-txt-102',NULL,NULL,NULL,NULL,'test-txt-102',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1108,150,'TXT','txt103','test-txt-103',NULL,NULL,NULL,NULL,'test-txt-103',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1109,148,'AAAA','host104','2001:db8::8f54',NULL,'2001:db8::8f54',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1110,157,'TXT','txt105','test-txt-105',NULL,NULL,NULL,NULL,'test-txt-105',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1111,126,'CNAME','cname106','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1112,110,'PTR','ptr107','ptr107.in-addr.arpa.',NULL,NULL,NULL,'ptr107.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1113,158,'AAAA','host108','2001:db8::e0ef',NULL,'2001:db8::e0ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1114,135,'A','host109','198.51.67.153','198.51.67.153',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1115,133,'CNAME','cname110','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1116,128,'CNAME','cname111','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1117,148,'TXT','txt112','test-txt-112',NULL,NULL,NULL,NULL,'test-txt-112',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1118,127,'TXT','txt113','test-txt-113',NULL,NULL,NULL,NULL,'test-txt-113',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1119,153,'PTR','ptr114','ptr114.in-addr.arpa.',NULL,NULL,NULL,'ptr114.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1120,153,'PTR','ptr115','ptr115.in-addr.arpa.',NULL,NULL,NULL,'ptr115.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1121,119,'TXT','txt116','test-txt-116',NULL,NULL,NULL,NULL,'test-txt-116',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1122,139,'AAAA','host117','2001:db8::184a',NULL,'2001:db8::184a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1123,156,'AAAA','host118','2001:db8::6062',NULL,'2001:db8::6062',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1124,157,'CNAME','cname119','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1125,136,'AAAA','host120','2001:db8::f9bb',NULL,'2001:db8::f9bb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1126,116,'CNAME','cname121','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1127,135,'PTR','ptr122','ptr122.in-addr.arpa.',NULL,NULL,NULL,'ptr122.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1128,155,'TXT','txt123','test-txt-123',NULL,NULL,NULL,NULL,'test-txt-123',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1129,112,'PTR','ptr124','ptr124.in-addr.arpa.',NULL,NULL,NULL,'ptr124.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1130,125,'AAAA','host125','2001:db8::cf31',NULL,'2001:db8::cf31',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1131,137,'TXT','txt126','test-txt-126',NULL,NULL,NULL,NULL,'test-txt-126',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1132,156,'TXT','txt127','test-txt-127',NULL,NULL,NULL,NULL,'test-txt-127',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1133,157,'AAAA','host128','2001:db8::350b',NULL,'2001:db8::350b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1134,151,'TXT','txt129','test-txt-129',NULL,NULL,NULL,NULL,'test-txt-129',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1135,118,'TXT','txt130','test-txt-130',NULL,NULL,NULL,NULL,'test-txt-130',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1136,130,'TXT','txt131','test-txt-131',NULL,NULL,NULL,NULL,'test-txt-131',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1137,110,'AAAA','host132','2001:db8::39c0',NULL,'2001:db8::39c0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1138,154,'PTR','ptr133','ptr133.in-addr.arpa.',NULL,NULL,NULL,'ptr133.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1139,118,'CNAME','cname134','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1140,157,'A','host135','198.51.15.156','198.51.15.156',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1141,122,'TXT','txt136','test-txt-136',NULL,NULL,NULL,NULL,'test-txt-136',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1142,149,'TXT','txt137','test-txt-137',NULL,NULL,NULL,NULL,'test-txt-137',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1143,152,'AAAA','host138','2001:db8::b4bf',NULL,'2001:db8::b4bf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1144,144,'TXT','txt139','test-txt-139',NULL,NULL,NULL,NULL,'test-txt-139',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1145,147,'AAAA','host140','2001:db8::2adc',NULL,'2001:db8::2adc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1146,113,'AAAA','host141','2001:db8::5c36',NULL,'2001:db8::5c36',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1147,153,'AAAA','host142','2001:db8::ff2e',NULL,'2001:db8::ff2e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1148,151,'AAAA','host143','2001:db8::6f29',NULL,'2001:db8::6f29',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1149,143,'CNAME','cname144','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1150,155,'CNAME','cname145','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1151,125,'PTR','ptr146','ptr146.in-addr.arpa.',NULL,NULL,NULL,'ptr146.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1152,121,'AAAA','host147','2001:db8::c309',NULL,'2001:db8::c309',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1153,111,'AAAA','host148','2001:db8::e9b3',NULL,'2001:db8::e9b3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1154,133,'A','host149','198.51.124.198','198.51.124.198',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1155,118,'CNAME','cname150','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1156,132,'TXT','txt151','test-txt-151',NULL,NULL,NULL,NULL,'test-txt-151',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1157,150,'A','host152','198.51.175.114','198.51.175.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1158,147,'CNAME','cname153','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1159,141,'TXT','txt154','test-txt-154',NULL,NULL,NULL,NULL,'test-txt-154',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1160,144,'TXT','txt155','test-txt-155',NULL,NULL,NULL,NULL,'test-txt-155',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1161,110,'A','host156','198.51.214.210','198.51.214.210',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1162,136,'A','host157','198.51.178.176','198.51.178.176',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1163,112,'A','host158','198.51.83.55','198.51.83.55',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1164,159,'AAAA','host159','2001:db8::2643',NULL,'2001:db8::2643',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1165,129,'TXT','txt160','test-txt-160',NULL,NULL,NULL,NULL,'test-txt-160',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1166,134,'TXT','txt161','test-txt-161',NULL,NULL,NULL,NULL,'test-txt-161',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1167,143,'PTR','ptr162','ptr162.in-addr.arpa.',NULL,NULL,NULL,'ptr162.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1168,121,'TXT','txt163','test-txt-163',NULL,NULL,NULL,NULL,'test-txt-163',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1169,152,'A','host164','198.51.193.116','198.51.193.116',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1170,155,'A','host165','198.51.101.114','198.51.101.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1171,139,'CNAME','cname166','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1172,153,'PTR','ptr167','ptr167.in-addr.arpa.',NULL,NULL,NULL,'ptr167.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1173,140,'CNAME','cname168','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1174,112,'CNAME','cname169','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1175,149,'CNAME','cname170','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1176,157,'AAAA','host171','2001:db8::b0f3',NULL,'2001:db8::b0f3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1177,119,'CNAME','cname172','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1178,120,'AAAA','host173','2001:db8::3c35',NULL,'2001:db8::3c35',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1179,152,'CNAME','cname174','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1180,143,'CNAME','cname175','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1181,150,'PTR','ptr176','ptr176.in-addr.arpa.',NULL,NULL,NULL,'ptr176.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1182,150,'A','host177','198.51.13.114','198.51.13.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1183,151,'AAAA','host178','2001:db8::21a3',NULL,'2001:db8::21a3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1184,154,'CNAME','cname179','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1185,141,'A','host180','198.51.50.54','198.51.50.54',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1186,159,'PTR','ptr181','ptr181.in-addr.arpa.',NULL,NULL,NULL,'ptr181.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1187,158,'CNAME','cname182','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1188,156,'CNAME','cname183','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1189,157,'TXT','txt184','test-txt-184',NULL,NULL,NULL,NULL,'test-txt-184',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1190,110,'A','host185','198.51.238.198','198.51.238.198',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1191,123,'PTR','ptr186','ptr186.in-addr.arpa.',NULL,NULL,NULL,'ptr186.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1192,141,'CNAME','cname187','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1193,129,'AAAA','host188','2001:db8::be47',NULL,'2001:db8::be47',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1194,150,'PTR','ptr189','ptr189.in-addr.arpa.',NULL,NULL,NULL,'ptr189.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1195,116,'CNAME','cname190','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1196,111,'AAAA','host191','2001:db8::ec59',NULL,'2001:db8::ec59',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1197,128,'TXT','txt192','test-txt-192',NULL,NULL,NULL,NULL,'test-txt-192',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1198,128,'A','host193','198.51.70.124','198.51.70.124',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1199,150,'TXT','txt194','test-txt-194',NULL,NULL,NULL,NULL,'test-txt-194',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1200,156,'AAAA','host195','2001:db8::2b8f',NULL,'2001:db8::2b8f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1201,146,'AAAA','host196','2001:db8::40a1',NULL,'2001:db8::40a1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1202,154,'A','host197','198.51.90.21','198.51.90.21',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1203,111,'A','host198','198.51.27.242','198.51.27.242',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1204,118,'AAAA','host199','2001:db8::9d7e',NULL,'2001:db8::9d7e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1205,150,'PTR','ptr200','ptr200.in-addr.arpa.',NULL,NULL,NULL,'ptr200.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1206,159,'AAAA','host201','2001:db8::9ab4',NULL,'2001:db8::9ab4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1207,134,'A','host202','198.51.121.61','198.51.121.61',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1208,147,'TXT','txt203','test-txt-203',NULL,NULL,NULL,NULL,'test-txt-203',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1209,157,'PTR','ptr204','ptr204.in-addr.arpa.',NULL,NULL,NULL,'ptr204.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1210,125,'CNAME','cname205','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1211,138,'PTR','ptr206','ptr206.in-addr.arpa.',NULL,NULL,NULL,'ptr206.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1212,129,'TXT','txt207','test-txt-207',NULL,NULL,NULL,NULL,'test-txt-207',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1213,150,'TXT','txt208','test-txt-208',NULL,NULL,NULL,NULL,'test-txt-208',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1214,159,'TXT','txt209','test-txt-209',NULL,NULL,NULL,NULL,'test-txt-209',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1215,158,'PTR','ptr210','ptr210.in-addr.arpa.',NULL,NULL,NULL,'ptr210.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1216,110,'A','host211','198.51.72.61','198.51.72.61',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1217,121,'AAAA','host212','2001:db8::f07c',NULL,'2001:db8::f07c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1218,156,'TXT','txt213','test-txt-213',NULL,NULL,NULL,NULL,'test-txt-213',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1219,136,'AAAA','host214','2001:db8::def4',NULL,'2001:db8::def4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1220,159,'A','host215','198.51.165.62','198.51.165.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1221,149,'A','host216','198.51.164.37','198.51.164.37',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1222,143,'AAAA','host217','2001:db8::e315',NULL,'2001:db8::e315',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1223,119,'TXT','txt218','test-txt-218',NULL,NULL,NULL,NULL,'test-txt-218',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1224,117,'A','host219','198.51.121.225','198.51.121.225',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1225,143,'TXT','txt220','test-txt-220',NULL,NULL,NULL,NULL,'test-txt-220',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1226,139,'PTR','ptr221','ptr221.in-addr.arpa.',NULL,NULL,NULL,'ptr221.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1227,152,'TXT','txt222','test-txt-222',NULL,NULL,NULL,NULL,'test-txt-222',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1228,157,'CNAME','cname223','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1229,149,'TXT','txt224','test-txt-224',NULL,NULL,NULL,NULL,'test-txt-224',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1230,146,'PTR','ptr225','ptr225.in-addr.arpa.',NULL,NULL,NULL,'ptr225.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1231,120,'PTR','ptr226','ptr226.in-addr.arpa.',NULL,NULL,NULL,'ptr226.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1232,150,'CNAME','cname227','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1233,145,'TXT','txt228','test-txt-228',NULL,NULL,NULL,NULL,'test-txt-228',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1234,152,'CNAME','cname229','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1235,119,'CNAME','cname230','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1236,158,'AAAA','host231','2001:db8::dc84',NULL,'2001:db8::dc84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1237,150,'CNAME','cname232','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1238,138,'TXT','txt233','test-txt-233',NULL,NULL,NULL,NULL,'test-txt-233',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1239,125,'TXT','txt234','test-txt-234',NULL,NULL,NULL,NULL,'test-txt-234',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1240,123,'TXT','txt235','test-txt-235',NULL,NULL,NULL,NULL,'test-txt-235',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1241,117,'PTR','ptr236','ptr236.in-addr.arpa.',NULL,NULL,NULL,'ptr236.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1242,138,'CNAME','cname237','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1243,115,'TXT','txt238','test-txt-238',NULL,NULL,NULL,NULL,'test-txt-238',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1244,154,'A','host239','198.51.121.34','198.51.121.34',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1245,120,'CNAME','cname240','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1246,138,'A','host241','198.51.29.215','198.51.29.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1247,116,'TXT','txt242','test-txt-242',NULL,NULL,NULL,NULL,'test-txt-242',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1248,117,'TXT','txt243','test-txt-243',NULL,NULL,NULL,NULL,'test-txt-243',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1249,144,'CNAME','cname244','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1250,158,'CNAME','cname245','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1251,112,'PTR','ptr246','ptr246.in-addr.arpa.',NULL,NULL,NULL,'ptr246.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1252,127,'PTR','ptr247','ptr247.in-addr.arpa.',NULL,NULL,NULL,'ptr247.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1253,145,'PTR','ptr248','ptr248.in-addr.arpa.',NULL,NULL,NULL,'ptr248.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1254,143,'PTR','ptr249','ptr249.in-addr.arpa.',NULL,NULL,NULL,'ptr249.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1255,155,'AAAA','host250','2001:db8::9a21',NULL,'2001:db8::9a21',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1256,115,'PTR','ptr251','ptr251.in-addr.arpa.',NULL,NULL,NULL,'ptr251.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1257,130,'A','host252','198.51.138.195','198.51.138.195',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1258,133,'PTR','ptr253','ptr253.in-addr.arpa.',NULL,NULL,NULL,'ptr253.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1259,151,'PTR','ptr254','ptr254.in-addr.arpa.',NULL,NULL,NULL,'ptr254.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1260,150,'TXT','txt255','test-txt-255',NULL,NULL,NULL,NULL,'test-txt-255',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1261,116,'AAAA','host256','2001:db8::99a9',NULL,'2001:db8::99a9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1262,144,'AAAA','host257','2001:db8::ab82',NULL,'2001:db8::ab82',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1263,149,'PTR','ptr258','ptr258.in-addr.arpa.',NULL,NULL,NULL,'ptr258.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1264,156,'A','host259','198.51.23.3','198.51.23.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1265,145,'CNAME','cname260','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1266,135,'TXT','txt261','test-txt-261',NULL,NULL,NULL,NULL,'test-txt-261',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1267,110,'AAAA','host262','2001:db8::3fcc',NULL,'2001:db8::3fcc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1268,150,'TXT','txt263','test-txt-263',NULL,NULL,NULL,NULL,'test-txt-263',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1269,132,'AAAA','host264','2001:db8::3aa6',NULL,'2001:db8::3aa6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1270,154,'A','host265','198.51.62.129','198.51.62.129',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1271,116,'PTR','ptr266','ptr266.in-addr.arpa.',NULL,NULL,NULL,'ptr266.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1272,155,'A','host267','198.51.97.91','198.51.97.91',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1273,125,'AAAA','host268','2001:db8::b671',NULL,'2001:db8::b671',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1274,130,'CNAME','cname269','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1275,121,'PTR','ptr270','ptr270.in-addr.arpa.',NULL,NULL,NULL,'ptr270.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1276,136,'TXT','txt271','test-txt-271',NULL,NULL,NULL,NULL,'test-txt-271',3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1277,133,'AAAA','host272','2001:db8::595b',NULL,'2001:db8::595b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1278,138,'PTR','ptr273','ptr273.in-addr.arpa.',NULL,NULL,NULL,'ptr273.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1279,148,'PTR','ptr274','ptr274.in-addr.arpa.',NULL,NULL,NULL,'ptr274.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1280,154,'CNAME','cname275','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1281,122,'A','host276','198.51.180.222','198.51.180.222',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1282,136,'PTR','ptr277','ptr277.in-addr.arpa.',NULL,NULL,NULL,'ptr277.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:11',NULL,'2025-10-23 07:34:11',NULL,NULL,NULL,NULL),
(1283,159,'PTR','ptr278','ptr278.in-addr.arpa.',NULL,NULL,NULL,'ptr278.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1284,115,'A','host279','198.51.32.224','198.51.32.224',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1285,110,'A','host280','198.51.134.253','198.51.134.253',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1286,112,'A','host281','198.51.83.55','198.51.83.55',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1287,156,'PTR','ptr282','ptr282.in-addr.arpa.',NULL,NULL,NULL,'ptr282.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1288,154,'A','host283','198.51.34.172','198.51.34.172',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1289,118,'CNAME','cname284','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1290,130,'CNAME','cname285','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1291,120,'TXT','txt286','test-txt-286',NULL,NULL,NULL,NULL,'test-txt-286',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1292,147,'TXT','txt287','test-txt-287',NULL,NULL,NULL,NULL,'test-txt-287',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1293,154,'TXT','txt288','test-txt-288',NULL,NULL,NULL,NULL,'test-txt-288',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1294,151,'AAAA','host289','2001:db8::b49d',NULL,'2001:db8::b49d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1295,155,'A','host290','198.51.189.246','198.51.189.246',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1296,150,'CNAME','cname291','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1297,150,'PTR','ptr292','ptr292.in-addr.arpa.',NULL,NULL,NULL,'ptr292.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1298,120,'CNAME','cname293','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1299,157,'AAAA','host294','2001:db8::8f1',NULL,'2001:db8::8f1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1300,155,'A','host295','198.51.27.142','198.51.27.142',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1301,136,'A','host296','198.51.29.209','198.51.29.209',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1302,146,'CNAME','cname297','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1303,135,'CNAME','cname298','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1304,119,'TXT','txt299','test-txt-299',NULL,NULL,NULL,NULL,'test-txt-299',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1305,123,'TXT','txt300','test-txt-300',NULL,NULL,NULL,NULL,'test-txt-300',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1306,122,'A','host301','198.51.147.87','198.51.147.87',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1307,120,'CNAME','cname302','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1308,152,'PTR','ptr303','ptr303.in-addr.arpa.',NULL,NULL,NULL,'ptr303.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1309,158,'TXT','txt304','test-txt-304',NULL,NULL,NULL,NULL,'test-txt-304',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1310,154,'AAAA','host305','2001:db8::1cd',NULL,'2001:db8::1cd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1311,158,'CNAME','cname306','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1312,126,'PTR','ptr307','ptr307.in-addr.arpa.',NULL,NULL,NULL,'ptr307.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1313,133,'AAAA','host308','2001:db8::9fc5',NULL,'2001:db8::9fc5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1314,154,'CNAME','cname309','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1315,153,'TXT','txt310','test-txt-310',NULL,NULL,NULL,NULL,'test-txt-310',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1316,133,'PTR','ptr311','ptr311.in-addr.arpa.',NULL,NULL,NULL,'ptr311.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1317,126,'CNAME','cname312','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1318,118,'CNAME','cname313','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1319,123,'AAAA','host314','2001:db8::d9f5',NULL,'2001:db8::d9f5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1320,115,'PTR','ptr315','ptr315.in-addr.arpa.',NULL,NULL,NULL,'ptr315.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1321,154,'PTR','ptr316','ptr316.in-addr.arpa.',NULL,NULL,NULL,'ptr316.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1322,152,'TXT','txt317','test-txt-317',NULL,NULL,NULL,NULL,'test-txt-317',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1323,126,'CNAME','cname318','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1324,141,'AAAA','host319','2001:db8::8deb',NULL,'2001:db8::8deb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1325,139,'PTR','ptr320','ptr320.in-addr.arpa.',NULL,NULL,NULL,'ptr320.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1326,147,'PTR','ptr321','ptr321.in-addr.arpa.',NULL,NULL,NULL,'ptr321.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1327,154,'TXT','txt322','test-txt-322',NULL,NULL,NULL,NULL,'test-txt-322',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1328,129,'A','host323','198.51.193.63','198.51.193.63',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1329,155,'CNAME','cname324','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1330,134,'CNAME','cname325','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1331,139,'TXT','txt326','test-txt-326',NULL,NULL,NULL,NULL,'test-txt-326',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1332,155,'PTR','ptr327','ptr327.in-addr.arpa.',NULL,NULL,NULL,'ptr327.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1333,156,'PTR','ptr328','ptr328.in-addr.arpa.',NULL,NULL,NULL,'ptr328.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1334,147,'TXT','txt329','test-txt-329',NULL,NULL,NULL,NULL,'test-txt-329',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1335,129,'PTR','ptr330','ptr330.in-addr.arpa.',NULL,NULL,NULL,'ptr330.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1336,140,'A','host331','198.51.135.10','198.51.135.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1337,147,'CNAME','cname332','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1338,128,'AAAA','host333','2001:db8::5da8',NULL,'2001:db8::5da8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1339,113,'CNAME','cname334','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1340,140,'CNAME','cname335','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1341,159,'A','host336','198.51.121.188','198.51.121.188',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1342,154,'CNAME','cname337','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1343,144,'A','host338','198.51.37.126','198.51.37.126',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1344,113,'PTR','ptr339','ptr339.in-addr.arpa.',NULL,NULL,NULL,'ptr339.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1345,154,'AAAA','host340','2001:db8::77be',NULL,'2001:db8::77be',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1346,139,'CNAME','cname341','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1347,123,'AAAA','host342','2001:db8::4c4c',NULL,'2001:db8::4c4c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1348,146,'CNAME','cname343','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1349,123,'CNAME','cname344','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1350,131,'PTR','ptr345','ptr345.in-addr.arpa.',NULL,NULL,NULL,'ptr345.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1351,132,'AAAA','host346','2001:db8::be02',NULL,'2001:db8::be02',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1352,111,'TXT','txt347','test-txt-347',NULL,NULL,NULL,NULL,'test-txt-347',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1353,120,'AAAA','host348','2001:db8::3bfc',NULL,'2001:db8::3bfc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1354,152,'CNAME','cname349','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1355,154,'A','host350','198.51.244.208','198.51.244.208',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1356,118,'AAAA','host351','2001:db8::feaa',NULL,'2001:db8::feaa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1357,139,'PTR','ptr352','ptr352.in-addr.arpa.',NULL,NULL,NULL,'ptr352.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1358,122,'CNAME','cname353','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1359,132,'AAAA','host354','2001:db8::ccef',NULL,'2001:db8::ccef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1360,152,'PTR','ptr355','ptr355.in-addr.arpa.',NULL,NULL,NULL,'ptr355.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1361,138,'TXT','txt356','test-txt-356',NULL,NULL,NULL,NULL,'test-txt-356',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1362,139,'CNAME','cname357','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1363,147,'PTR','ptr358','ptr358.in-addr.arpa.',NULL,NULL,NULL,'ptr358.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1364,131,'A','host359','198.51.67.65','198.51.67.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1365,110,'TXT','txt360','test-txt-360',NULL,NULL,NULL,NULL,'test-txt-360',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1366,114,'CNAME','cname361','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1367,118,'PTR','ptr362','ptr362.in-addr.arpa.',NULL,NULL,NULL,'ptr362.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1368,133,'A','host363','198.51.8.68','198.51.8.68',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1369,159,'CNAME','cname364','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1370,111,'AAAA','host365','2001:db8::8560',NULL,'2001:db8::8560',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1371,158,'A','host366','198.51.251.191','198.51.251.191',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1372,131,'CNAME','cname367','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1373,123,'CNAME','cname368','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1374,133,'TXT','txt369','test-txt-369',NULL,NULL,NULL,NULL,'test-txt-369',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1375,148,'TXT','txt370','test-txt-370',NULL,NULL,NULL,NULL,'test-txt-370',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1376,114,'CNAME','cname371','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1377,156,'PTR','ptr372','ptr372.in-addr.arpa.',NULL,NULL,NULL,'ptr372.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1378,147,'TXT','txt373','test-txt-373',NULL,NULL,NULL,NULL,'test-txt-373',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1379,151,'CNAME','cname374','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1380,134,'AAAA','host375','2001:db8::1c6f',NULL,'2001:db8::1c6f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1381,157,'CNAME','cname376','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1382,151,'A','host377','198.51.17.81','198.51.17.81',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1383,128,'CNAME','cname378','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1384,112,'PTR','ptr379','ptr379.in-addr.arpa.',NULL,NULL,NULL,'ptr379.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1385,151,'TXT','txt380','test-txt-380',NULL,NULL,NULL,NULL,'test-txt-380',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1386,155,'TXT','txt381','test-txt-381',NULL,NULL,NULL,NULL,'test-txt-381',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1387,125,'CNAME','cname382','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1388,111,'TXT','txt383','test-txt-383',NULL,NULL,NULL,NULL,'test-txt-383',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1389,127,'AAAA','host384','2001:db8::80a4',NULL,'2001:db8::80a4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1390,118,'CNAME','cname385','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1391,150,'CNAME','cname386','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1392,114,'A','host387','198.51.207.43','198.51.207.43',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1393,158,'A','host388','198.51.150.98','198.51.150.98',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1394,141,'PTR','ptr389','ptr389.in-addr.arpa.',NULL,NULL,NULL,'ptr389.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1395,143,'AAAA','host390','2001:db8::b71a',NULL,'2001:db8::b71a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1396,128,'CNAME','cname391','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1397,138,'CNAME','cname392','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1398,136,'PTR','ptr393','ptr393.in-addr.arpa.',NULL,NULL,NULL,'ptr393.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1399,143,'TXT','txt394','test-txt-394',NULL,NULL,NULL,NULL,'test-txt-394',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1400,120,'TXT','txt395','test-txt-395',NULL,NULL,NULL,NULL,'test-txt-395',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1401,121,'CNAME','cname396','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1402,154,'CNAME','cname397','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1403,121,'CNAME','cname398','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1404,132,'CNAME','cname399','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1405,124,'TXT','txt400','test-txt-400',NULL,NULL,NULL,NULL,'test-txt-400',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1406,136,'CNAME','cname401','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1407,110,'CNAME','cname402','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1408,145,'TXT','txt403','test-txt-403',NULL,NULL,NULL,NULL,'test-txt-403',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1409,153,'CNAME','cname404','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1410,122,'CNAME','cname405','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1411,112,'A','host406','198.51.141.27','198.51.141.27',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1412,115,'PTR','ptr407','ptr407.in-addr.arpa.',NULL,NULL,NULL,'ptr407.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1413,133,'CNAME','cname408','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1414,144,'CNAME','cname409','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1415,116,'TXT','txt410','test-txt-410',NULL,NULL,NULL,NULL,'test-txt-410',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1416,135,'AAAA','host411','2001:db8::3ce0',NULL,'2001:db8::3ce0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1417,124,'A','host412','198.51.183.174','198.51.183.174',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1418,119,'PTR','ptr413','ptr413.in-addr.arpa.',NULL,NULL,NULL,'ptr413.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1419,110,'TXT','txt414','test-txt-414',NULL,NULL,NULL,NULL,'test-txt-414',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1420,151,'TXT','txt415','test-txt-415',NULL,NULL,NULL,NULL,'test-txt-415',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1421,114,'AAAA','host416','2001:db8::93ea',NULL,'2001:db8::93ea',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1422,155,'PTR','ptr417','ptr417.in-addr.arpa.',NULL,NULL,NULL,'ptr417.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1423,134,'PTR','ptr418','ptr418.in-addr.arpa.',NULL,NULL,NULL,'ptr418.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1424,155,'TXT','txt419','test-txt-419',NULL,NULL,NULL,NULL,'test-txt-419',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1425,131,'AAAA','host420','2001:db8::519',NULL,'2001:db8::519',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1426,150,'PTR','ptr421','ptr421.in-addr.arpa.',NULL,NULL,NULL,'ptr421.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1427,144,'PTR','ptr422','ptr422.in-addr.arpa.',NULL,NULL,NULL,'ptr422.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1428,117,'CNAME','cname423','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1429,112,'AAAA','host424','2001:db8::19e5',NULL,'2001:db8::19e5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1430,151,'TXT','txt425','test-txt-425',NULL,NULL,NULL,NULL,'test-txt-425',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1431,145,'CNAME','cname426','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1432,119,'PTR','ptr427','ptr427.in-addr.arpa.',NULL,NULL,NULL,'ptr427.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1433,152,'AAAA','host428','2001:db8::778a',NULL,'2001:db8::778a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1434,149,'PTR','ptr429','ptr429.in-addr.arpa.',NULL,NULL,NULL,'ptr429.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1435,147,'CNAME','cname430','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1436,141,'PTR','ptr431','ptr431.in-addr.arpa.',NULL,NULL,NULL,'ptr431.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1437,153,'A','host432','198.51.177.12','198.51.177.12',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1438,150,'TXT','txt433','test-txt-433',NULL,NULL,NULL,NULL,'test-txt-433',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1439,125,'AAAA','host434','2001:db8::3271',NULL,'2001:db8::3271',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1440,122,'PTR','ptr435','ptr435.in-addr.arpa.',NULL,NULL,NULL,'ptr435.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1441,152,'TXT','txt436','test-txt-436',NULL,NULL,NULL,NULL,'test-txt-436',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1442,125,'AAAA','host437','2001:db8::b55b',NULL,'2001:db8::b55b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1443,152,'CNAME','cname438','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1444,133,'TXT','txt439','test-txt-439',NULL,NULL,NULL,NULL,'test-txt-439',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1445,153,'PTR','ptr440','ptr440.in-addr.arpa.',NULL,NULL,NULL,'ptr440.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1446,154,'AAAA','host441','2001:db8::a034',NULL,'2001:db8::a034',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1447,149,'AAAA','host442','2001:db8::b09f',NULL,'2001:db8::b09f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1448,147,'PTR','ptr443','ptr443.in-addr.arpa.',NULL,NULL,NULL,'ptr443.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1449,150,'AAAA','host444','2001:db8::1535',NULL,'2001:db8::1535',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1450,114,'TXT','txt445','test-txt-445',NULL,NULL,NULL,NULL,'test-txt-445',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1451,156,'A','host446','198.51.46.76','198.51.46.76',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1452,124,'PTR','ptr447','ptr447.in-addr.arpa.',NULL,NULL,NULL,'ptr447.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1453,157,'PTR','ptr448','ptr448.in-addr.arpa.',NULL,NULL,NULL,'ptr448.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1454,128,'PTR','ptr449','ptr449.in-addr.arpa.',NULL,NULL,NULL,'ptr449.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1455,141,'TXT','txt450','test-txt-450',NULL,NULL,NULL,NULL,'test-txt-450',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1456,134,'TXT','txt451','test-txt-451',NULL,NULL,NULL,NULL,'test-txt-451',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1457,131,'AAAA','host452','2001:db8::94b3',NULL,'2001:db8::94b3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1458,139,'A','host453','198.51.80.233','198.51.80.233',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1459,119,'A','host454','198.51.88.166','198.51.88.166',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1460,151,'TXT','txt455','test-txt-455',NULL,NULL,NULL,NULL,'test-txt-455',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1461,134,'AAAA','host456','2001:db8::5630',NULL,'2001:db8::5630',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1462,159,'TXT','txt457','test-txt-457',NULL,NULL,NULL,NULL,'test-txt-457',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1463,152,'TXT','txt458','test-txt-458',NULL,NULL,NULL,NULL,'test-txt-458',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1464,148,'CNAME','cname459','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1465,121,'TXT','txt460','test-txt-460',NULL,NULL,NULL,NULL,'test-txt-460',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1466,153,'TXT','txt461','test-txt-461',NULL,NULL,NULL,NULL,'test-txt-461',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1467,140,'TXT','txt462','test-txt-462',NULL,NULL,NULL,NULL,'test-txt-462',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1468,157,'A','host463','198.51.249.79','198.51.249.79',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1469,153,'TXT','txt464','test-txt-464',NULL,NULL,NULL,NULL,'test-txt-464',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1470,139,'AAAA','host465','2001:db8::5c43',NULL,'2001:db8::5c43',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1471,126,'AAAA','host466','2001:db8::2cff',NULL,'2001:db8::2cff',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1472,138,'AAAA','host467','2001:db8::693a',NULL,'2001:db8::693a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1473,111,'CNAME','cname468','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1474,140,'PTR','ptr469','ptr469.in-addr.arpa.',NULL,NULL,NULL,'ptr469.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1475,117,'A','host470','198.51.98.224','198.51.98.224',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1476,122,'AAAA','host471','2001:db8::e3eb',NULL,'2001:db8::e3eb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1477,144,'CNAME','cname472','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1478,149,'A','host473','198.51.29.100','198.51.29.100',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1479,118,'TXT','txt474','test-txt-474',NULL,NULL,NULL,NULL,'test-txt-474',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1480,129,'CNAME','cname475','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1481,123,'TXT','txt476','test-txt-476',NULL,NULL,NULL,NULL,'test-txt-476',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1482,130,'TXT','txt477','test-txt-477',NULL,NULL,NULL,NULL,'test-txt-477',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1483,122,'A','host478','198.51.216.228','198.51.216.228',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1484,112,'A','host479','198.51.33.121','198.51.33.121',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1485,130,'A','host480','198.51.144.41','198.51.144.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1486,156,'CNAME','cname481','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1487,133,'AAAA','host482','2001:db8::fc5c',NULL,'2001:db8::fc5c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1488,142,'A','host483','198.51.222.56','198.51.222.56',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1489,147,'AAAA','host484','2001:db8::c667',NULL,'2001:db8::c667',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1490,158,'AAAA','host485','2001:db8::98d6',NULL,'2001:db8::98d6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1491,135,'AAAA','host486','2001:db8::3325',NULL,'2001:db8::3325',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1492,126,'AAAA','host487','2001:db8::84d1',NULL,'2001:db8::84d1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1493,113,'CNAME','cname488','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1494,150,'PTR','ptr489','ptr489.in-addr.arpa.',NULL,NULL,NULL,'ptr489.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1495,156,'A','host490','198.51.130.246','198.51.130.246',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1496,113,'TXT','txt491','test-txt-491',NULL,NULL,NULL,NULL,'test-txt-491',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1497,152,'AAAA','host492','2001:db8::a356',NULL,'2001:db8::a356',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1498,156,'AAAA','host493','2001:db8::c88a',NULL,'2001:db8::c88a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1499,126,'A','host494','198.51.139.175','198.51.139.175',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1500,154,'AAAA','host495','2001:db8::4142',NULL,'2001:db8::4142',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1501,112,'A','host496','198.51.157.248','198.51.157.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1502,140,'AAAA','host497','2001:db8::ca16',NULL,'2001:db8::ca16',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1503,152,'TXT','txt498','test-txt-498',NULL,NULL,NULL,NULL,'test-txt-498',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1504,116,'PTR','ptr499','ptr499.in-addr.arpa.',NULL,NULL,NULL,'ptr499.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1505,143,'TXT','txt500','test-txt-500',NULL,NULL,NULL,NULL,'test-txt-500',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1506,137,'TXT','txt501','test-txt-501',NULL,NULL,NULL,NULL,'test-txt-501',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1507,134,'A','host502','198.51.204.167','198.51.204.167',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1508,157,'TXT','txt503','test-txt-503',NULL,NULL,NULL,NULL,'test-txt-503',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1509,126,'AAAA','host504','2001:db8::f648',NULL,'2001:db8::f648',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1510,127,'AAAA','host505','2001:db8::6c99',NULL,'2001:db8::6c99',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1511,128,'A','host506','198.51.229.122','198.51.229.122',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1512,110,'PTR','ptr507','ptr507.in-addr.arpa.',NULL,NULL,NULL,'ptr507.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1513,152,'TXT','txt508','test-txt-508',NULL,NULL,NULL,NULL,'test-txt-508',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1514,156,'CNAME','cname509','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1515,111,'PTR','ptr510','ptr510.in-addr.arpa.',NULL,NULL,NULL,'ptr510.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1516,117,'CNAME','cname511','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1517,147,'PTR','ptr512','ptr512.in-addr.arpa.',NULL,NULL,NULL,'ptr512.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1518,156,'PTR','ptr513','ptr513.in-addr.arpa.',NULL,NULL,NULL,'ptr513.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1519,141,'TXT','txt514','test-txt-514',NULL,NULL,NULL,NULL,'test-txt-514',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1520,126,'PTR','ptr515','ptr515.in-addr.arpa.',NULL,NULL,NULL,'ptr515.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1521,144,'TXT','txt516','test-txt-516',NULL,NULL,NULL,NULL,'test-txt-516',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1522,127,'A','host517','198.51.155.100','198.51.155.100',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1523,137,'AAAA','host518','2001:db8::55b1',NULL,'2001:db8::55b1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1524,153,'AAAA','host519','2001:db8::cfa0',NULL,'2001:db8::cfa0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1525,147,'AAAA','host520','2001:db8::6c7e',NULL,'2001:db8::6c7e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1526,154,'TXT','txt521','test-txt-521',NULL,NULL,NULL,NULL,'test-txt-521',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1527,149,'A','host522','198.51.192.77','198.51.192.77',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1528,138,'PTR','ptr523','ptr523.in-addr.arpa.',NULL,NULL,NULL,'ptr523.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1529,133,'A','host524','198.51.99.183','198.51.99.183',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1530,116,'TXT','txt525','test-txt-525',NULL,NULL,NULL,NULL,'test-txt-525',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1531,140,'AAAA','host526','2001:db8::8088',NULL,'2001:db8::8088',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1532,123,'PTR','ptr527','ptr527.in-addr.arpa.',NULL,NULL,NULL,'ptr527.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1533,138,'TXT','txt528','test-txt-528',NULL,NULL,NULL,NULL,'test-txt-528',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1534,153,'A','host529','198.51.26.169','198.51.26.169',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1535,112,'A','host530','198.51.122.189','198.51.122.189',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1536,155,'A','host531','198.51.249.142','198.51.249.142',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1537,126,'A','host532','198.51.138.35','198.51.138.35',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1538,110,'CNAME','cname533','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1539,110,'PTR','ptr534','ptr534.in-addr.arpa.',NULL,NULL,NULL,'ptr534.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1540,142,'PTR','ptr535','ptr535.in-addr.arpa.',NULL,NULL,NULL,'ptr535.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1541,127,'PTR','ptr536','ptr536.in-addr.arpa.',NULL,NULL,NULL,'ptr536.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1542,152,'CNAME','cname537','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1543,142,'CNAME','cname538','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1544,149,'AAAA','host539','2001:db8::24cf',NULL,'2001:db8::24cf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1545,124,'TXT','txt540','test-txt-540',NULL,NULL,NULL,NULL,'test-txt-540',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1546,119,'PTR','ptr541','ptr541.in-addr.arpa.',NULL,NULL,NULL,'ptr541.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1547,152,'CNAME','cname542','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1548,110,'CNAME','cname543','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1549,136,'A','host544','198.51.198.136','198.51.198.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1550,155,'A','host545','198.51.49.159','198.51.49.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1551,158,'PTR','ptr546','ptr546.in-addr.arpa.',NULL,NULL,NULL,'ptr546.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1552,125,'A','host547','198.51.77.237','198.51.77.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1553,158,'TXT','txt548','test-txt-548',NULL,NULL,NULL,NULL,'test-txt-548',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1554,110,'A','host549','198.51.237.25','198.51.237.25',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1555,133,'A','host550','198.51.130.7','198.51.130.7',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1556,148,'CNAME','cname551','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1557,112,'A','host552','198.51.30.187','198.51.30.187',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1558,140,'AAAA','host553','2001:db8::ae09',NULL,'2001:db8::ae09',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1559,153,'CNAME','cname554','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1560,138,'AAAA','host555','2001:db8::de15',NULL,'2001:db8::de15',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1561,112,'CNAME','cname556','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1562,124,'AAAA','host557','2001:db8::b86c',NULL,'2001:db8::b86c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1563,130,'CNAME','cname558','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1564,139,'A','host559','198.51.159.134','198.51.159.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1565,136,'TXT','txt560','test-txt-560',NULL,NULL,NULL,NULL,'test-txt-560',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1566,154,'TXT','txt561','test-txt-561',NULL,NULL,NULL,NULL,'test-txt-561',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1567,157,'AAAA','host562','2001:db8::7e8a',NULL,'2001:db8::7e8a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1568,156,'PTR','ptr563','ptr563.in-addr.arpa.',NULL,NULL,NULL,'ptr563.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1569,121,'CNAME','cname564','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1570,127,'CNAME','cname565','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1571,143,'PTR','ptr566','ptr566.in-addr.arpa.',NULL,NULL,NULL,'ptr566.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1572,135,'A','host567','198.51.200.133','198.51.200.133',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1573,139,'A','host568','198.51.23.78','198.51.23.78',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1574,151,'PTR','ptr569','ptr569.in-addr.arpa.',NULL,NULL,NULL,'ptr569.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1575,110,'CNAME','cname570','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1576,113,'PTR','ptr571','ptr571.in-addr.arpa.',NULL,NULL,NULL,'ptr571.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1577,155,'CNAME','cname572','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1578,140,'CNAME','cname573','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1579,150,'CNAME','cname574','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1580,123,'TXT','txt575','test-txt-575',NULL,NULL,NULL,NULL,'test-txt-575',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1581,124,'CNAME','cname576','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1582,116,'TXT','txt577','test-txt-577',NULL,NULL,NULL,NULL,'test-txt-577',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1583,120,'TXT','txt578','test-txt-578',NULL,NULL,NULL,NULL,'test-txt-578',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1584,157,'A','host579','198.51.111.123','198.51.111.123',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1585,137,'AAAA','host580','2001:db8::85ef',NULL,'2001:db8::85ef',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1586,152,'PTR','ptr581','ptr581.in-addr.arpa.',NULL,NULL,NULL,'ptr581.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1587,154,'PTR','ptr582','ptr582.in-addr.arpa.',NULL,NULL,NULL,'ptr582.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1588,155,'CNAME','cname583','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1589,159,'PTR','ptr584','ptr584.in-addr.arpa.',NULL,NULL,NULL,'ptr584.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1590,144,'PTR','ptr585','ptr585.in-addr.arpa.',NULL,NULL,NULL,'ptr585.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1591,155,'TXT','txt586','test-txt-586',NULL,NULL,NULL,NULL,'test-txt-586',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1592,131,'A','host587','198.51.233.199','198.51.233.199',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1593,131,'TXT','txt588','test-txt-588',NULL,NULL,NULL,NULL,'test-txt-588',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1594,124,'A','host589','198.51.39.227','198.51.39.227',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1595,111,'A','host590','198.51.59.178','198.51.59.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1596,114,'PTR','ptr591','ptr591.in-addr.arpa.',NULL,NULL,NULL,'ptr591.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1597,152,'A','host592','198.51.6.150','198.51.6.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1598,141,'TXT','txt593','test-txt-593',NULL,NULL,NULL,NULL,'test-txt-593',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1599,127,'PTR','ptr594','ptr594.in-addr.arpa.',NULL,NULL,NULL,'ptr594.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1600,148,'TXT','txt595','test-txt-595',NULL,NULL,NULL,NULL,'test-txt-595',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1601,113,'CNAME','cname596','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1602,120,'CNAME','cname597','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1603,126,'AAAA','host598','2001:db8::209b',NULL,'2001:db8::209b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1604,118,'AAAA','host599','2001:db8::30a6',NULL,'2001:db8::30a6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1605,120,'AAAA','host600','2001:db8::bc1d',NULL,'2001:db8::bc1d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1606,152,'A','host601','198.51.101.105','198.51.101.105',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1607,156,'TXT','txt602','test-txt-602',NULL,NULL,NULL,NULL,'test-txt-602',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1608,116,'AAAA','host603','2001:db8::c391',NULL,'2001:db8::c391',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1609,159,'TXT','txt604','test-txt-604',NULL,NULL,NULL,NULL,'test-txt-604',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1610,110,'CNAME','cname605','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1611,153,'A','host606','198.51.237.97','198.51.237.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1612,120,'CNAME','cname607','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1613,143,'AAAA','host608','2001:db8::5cb0',NULL,'2001:db8::5cb0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1614,156,'AAAA','host609','2001:db8::df1e',NULL,'2001:db8::df1e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1615,146,'TXT','txt610','test-txt-610',NULL,NULL,NULL,NULL,'test-txt-610',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1616,158,'AAAA','host611','2001:db8::359b',NULL,'2001:db8::359b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1617,158,'TXT','txt612','test-txt-612',NULL,NULL,NULL,NULL,'test-txt-612',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1618,115,'A','host613','198.51.172.121','198.51.172.121',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1619,111,'AAAA','host614','2001:db8::1449',NULL,'2001:db8::1449',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1620,151,'A','host615','198.51.208.98','198.51.208.98',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1621,110,'PTR','ptr616','ptr616.in-addr.arpa.',NULL,NULL,NULL,'ptr616.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1622,127,'A','host617','198.51.222.207','198.51.222.207',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1623,146,'TXT','txt618','test-txt-618',NULL,NULL,NULL,NULL,'test-txt-618',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1624,122,'A','host619','198.51.18.138','198.51.18.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1625,150,'TXT','txt620','test-txt-620',NULL,NULL,NULL,NULL,'test-txt-620',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1626,157,'CNAME','cname621','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1627,143,'AAAA','host622','2001:db8::a5b4',NULL,'2001:db8::a5b4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1628,111,'A','host623','198.51.121.156','198.51.121.156',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1629,123,'TXT','txt624','test-txt-624',NULL,NULL,NULL,NULL,'test-txt-624',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1630,158,'TXT','txt625','test-txt-625',NULL,NULL,NULL,NULL,'test-txt-625',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1631,130,'CNAME','cname626','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1632,144,'AAAA','host627','2001:db8::ccae',NULL,'2001:db8::ccae',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1633,113,'TXT','txt628','test-txt-628',NULL,NULL,NULL,NULL,'test-txt-628',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1634,134,'CNAME','cname629','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1635,121,'A','host630','198.51.244.65','198.51.244.65',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1636,129,'AAAA','host631','2001:db8::c7dd',NULL,'2001:db8::c7dd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1637,119,'AAAA','host632','2001:db8::828e',NULL,'2001:db8::828e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1638,153,'PTR','ptr633','ptr633.in-addr.arpa.',NULL,NULL,NULL,'ptr633.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1639,127,'CNAME','cname634','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1640,136,'AAAA','host635','2001:db8::7dd1',NULL,'2001:db8::7dd1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1641,135,'CNAME','cname636','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1642,157,'PTR','ptr637','ptr637.in-addr.arpa.',NULL,NULL,NULL,'ptr637.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1643,128,'PTR','ptr638','ptr638.in-addr.arpa.',NULL,NULL,NULL,'ptr638.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1644,115,'TXT','txt639','test-txt-639',NULL,NULL,NULL,NULL,'test-txt-639',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1645,135,'A','host640','198.51.241.220','198.51.241.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1646,154,'AAAA','host641','2001:db8::d42d',NULL,'2001:db8::d42d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1647,159,'PTR','ptr642','ptr642.in-addr.arpa.',NULL,NULL,NULL,'ptr642.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1648,149,'CNAME','cname643','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1649,138,'TXT','txt644','test-txt-644',NULL,NULL,NULL,NULL,'test-txt-644',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1650,131,'PTR','ptr645','ptr645.in-addr.arpa.',NULL,NULL,NULL,'ptr645.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1651,141,'TXT','txt646','test-txt-646',NULL,NULL,NULL,NULL,'test-txt-646',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1652,142,'PTR','ptr647','ptr647.in-addr.arpa.',NULL,NULL,NULL,'ptr647.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1653,113,'PTR','ptr648','ptr648.in-addr.arpa.',NULL,NULL,NULL,'ptr648.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1654,113,'PTR','ptr649','ptr649.in-addr.arpa.',NULL,NULL,NULL,'ptr649.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1655,114,'A','host650','198.51.61.212','198.51.61.212',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1656,150,'A','host651','198.51.94.162','198.51.94.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1657,159,'TXT','txt652','test-txt-652',NULL,NULL,NULL,NULL,'test-txt-652',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1658,130,'TXT','txt653','test-txt-653',NULL,NULL,NULL,NULL,'test-txt-653',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1659,112,'PTR','ptr654','ptr654.in-addr.arpa.',NULL,NULL,NULL,'ptr654.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1660,122,'AAAA','host655','2001:db8::7914',NULL,'2001:db8::7914',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1661,158,'CNAME','cname656','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1662,145,'TXT','txt657','test-txt-657',NULL,NULL,NULL,NULL,'test-txt-657',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1663,128,'A','host658','198.51.21.234','198.51.21.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1664,114,'CNAME','cname659','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1665,111,'PTR','ptr660','ptr660.in-addr.arpa.',NULL,NULL,NULL,'ptr660.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1666,117,'CNAME','cname661','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1667,135,'PTR','ptr662','ptr662.in-addr.arpa.',NULL,NULL,NULL,'ptr662.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1668,135,'CNAME','cname663','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1669,128,'CNAME','cname664','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1670,140,'CNAME','cname665','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1671,149,'AAAA','host666','2001:db8::3dfa',NULL,'2001:db8::3dfa',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1672,144,'PTR','ptr667','ptr667.in-addr.arpa.',NULL,NULL,NULL,'ptr667.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1673,152,'CNAME','cname668','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1674,140,'AAAA','host669','2001:db8::5c3d',NULL,'2001:db8::5c3d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1675,132,'CNAME','cname670','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1676,152,'PTR','ptr671','ptr671.in-addr.arpa.',NULL,NULL,NULL,'ptr671.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1677,138,'TXT','txt672','test-txt-672',NULL,NULL,NULL,NULL,'test-txt-672',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1678,159,'TXT','txt673','test-txt-673',NULL,NULL,NULL,NULL,'test-txt-673',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1679,131,'CNAME','cname674','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1680,137,'PTR','ptr675','ptr675.in-addr.arpa.',NULL,NULL,NULL,'ptr675.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1681,120,'CNAME','cname676','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1682,112,'AAAA','host677','2001:db8::610',NULL,'2001:db8::610',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1683,157,'PTR','ptr678','ptr678.in-addr.arpa.',NULL,NULL,NULL,'ptr678.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1684,155,'CNAME','cname679','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1685,118,'PTR','ptr680','ptr680.in-addr.arpa.',NULL,NULL,NULL,'ptr680.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1686,130,'AAAA','host681','2001:db8::a128',NULL,'2001:db8::a128',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1687,146,'AAAA','host682','2001:db8::f129',NULL,'2001:db8::f129',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1688,159,'AAAA','host683','2001:db8::6723',NULL,'2001:db8::6723',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1689,146,'PTR','ptr684','ptr684.in-addr.arpa.',NULL,NULL,NULL,'ptr684.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1690,149,'AAAA','host685','2001:db8::cfe1',NULL,'2001:db8::cfe1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1691,110,'AAAA','host686','2001:db8::71e3',NULL,'2001:db8::71e3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1692,139,'CNAME','cname687','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1693,129,'A','host688','198.51.242.75','198.51.242.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1694,148,'AAAA','host689','2001:db8::176f',NULL,'2001:db8::176f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1695,157,'TXT','txt690','test-txt-690',NULL,NULL,NULL,NULL,'test-txt-690',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1696,141,'A','host691','198.51.126.186','198.51.126.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1697,123,'PTR','ptr692','ptr692.in-addr.arpa.',NULL,NULL,NULL,'ptr692.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1698,158,'PTR','ptr693','ptr693.in-addr.arpa.',NULL,NULL,NULL,'ptr693.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1699,153,'AAAA','host694','2001:db8::f28b',NULL,'2001:db8::f28b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1700,148,'TXT','txt695','test-txt-695',NULL,NULL,NULL,NULL,'test-txt-695',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1701,148,'A','host696','198.51.254.105','198.51.254.105',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1702,112,'AAAA','host697','2001:db8::f73f',NULL,'2001:db8::f73f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1703,110,'A','host698','198.51.190.220','198.51.190.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1704,144,'A','host699','198.51.175.129','198.51.175.129',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1705,122,'AAAA','host700','2001:db8::4fa8',NULL,'2001:db8::4fa8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1706,138,'AAAA','host701','2001:db8::ca96',NULL,'2001:db8::ca96',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1707,156,'TXT','txt702','test-txt-702',NULL,NULL,NULL,NULL,'test-txt-702',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1708,131,'A','host703','198.51.181.1','198.51.181.1',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1709,138,'CNAME','cname704','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1710,121,'TXT','txt705','test-txt-705',NULL,NULL,NULL,NULL,'test-txt-705',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1711,142,'TXT','txt706','test-txt-706',NULL,NULL,NULL,NULL,'test-txt-706',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1712,122,'TXT','txt707','test-txt-707',NULL,NULL,NULL,NULL,'test-txt-707',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1713,140,'AAAA','host708','2001:db8::95f9',NULL,'2001:db8::95f9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1714,126,'A','host709','198.51.26.75','198.51.26.75',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1715,157,'AAAA','host710','2001:db8::e8b1',NULL,'2001:db8::e8b1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1716,123,'PTR','ptr711','ptr711.in-addr.arpa.',NULL,NULL,NULL,'ptr711.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1717,119,'CNAME','cname712','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1718,154,'AAAA','host713','2001:db8::dae5',NULL,'2001:db8::dae5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1719,130,'TXT','txt714','test-txt-714',NULL,NULL,NULL,NULL,'test-txt-714',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1720,155,'AAAA','host715','2001:db8::7a9c',NULL,'2001:db8::7a9c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1721,159,'A','host716','198.51.87.62','198.51.87.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1722,123,'A','host717','198.51.120.92','198.51.120.92',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1723,156,'TXT','txt718','test-txt-718',NULL,NULL,NULL,NULL,'test-txt-718',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1724,124,'TXT','txt719','test-txt-719',NULL,NULL,NULL,NULL,'test-txt-719',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1725,118,'PTR','ptr720','ptr720.in-addr.arpa.',NULL,NULL,NULL,'ptr720.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1726,130,'A','host721','198.51.177.64','198.51.177.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1727,141,'TXT','txt722','test-txt-722',NULL,NULL,NULL,NULL,'test-txt-722',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1728,148,'CNAME','cname723','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1729,144,'AAAA','host724','2001:db8::6ca2',NULL,'2001:db8::6ca2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1730,144,'CNAME','cname725','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1731,154,'TXT','txt726','test-txt-726',NULL,NULL,NULL,NULL,'test-txt-726',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1732,158,'AAAA','host727','2001:db8::b4ad',NULL,'2001:db8::b4ad',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1733,134,'CNAME','cname728','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1734,140,'TXT','txt729','test-txt-729',NULL,NULL,NULL,NULL,'test-txt-729',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1735,114,'TXT','txt730','test-txt-730',NULL,NULL,NULL,NULL,'test-txt-730',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1736,152,'CNAME','cname731','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1737,132,'CNAME','cname732','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1738,153,'TXT','txt733','test-txt-733',NULL,NULL,NULL,NULL,'test-txt-733',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1739,146,'PTR','ptr734','ptr734.in-addr.arpa.',NULL,NULL,NULL,'ptr734.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1740,152,'A','host735','198.51.231.237','198.51.231.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1741,141,'CNAME','cname736','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1742,150,'TXT','txt737','test-txt-737',NULL,NULL,NULL,NULL,'test-txt-737',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1743,123,'AAAA','host738','2001:db8::e7f3',NULL,'2001:db8::e7f3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1744,147,'TXT','txt739','test-txt-739',NULL,NULL,NULL,NULL,'test-txt-739',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1745,111,'CNAME','cname740','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1746,138,'TXT','txt741','test-txt-741',NULL,NULL,NULL,NULL,'test-txt-741',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1747,131,'PTR','ptr742','ptr742.in-addr.arpa.',NULL,NULL,NULL,'ptr742.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1748,159,'PTR','ptr743','ptr743.in-addr.arpa.',NULL,NULL,NULL,'ptr743.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1749,124,'TXT','txt744','test-txt-744',NULL,NULL,NULL,NULL,'test-txt-744',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1750,126,'A','host745','198.51.238.81','198.51.238.81',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1751,157,'PTR','ptr746','ptr746.in-addr.arpa.',NULL,NULL,NULL,'ptr746.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1752,146,'CNAME','cname747','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1753,158,'TXT','txt748','test-txt-748',NULL,NULL,NULL,NULL,'test-txt-748',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1754,151,'CNAME','cname749','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1755,132,'A','host750','198.51.140.9','198.51.140.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1756,112,'CNAME','cname751','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1757,154,'CNAME','cname752','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1758,110,'AAAA','host753','2001:db8::4f43',NULL,'2001:db8::4f43',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1759,139,'CNAME','cname754','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1760,138,'CNAME','cname755','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1761,112,'TXT','txt756','test-txt-756',NULL,NULL,NULL,NULL,'test-txt-756',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1762,123,'PTR','ptr757','ptr757.in-addr.arpa.',NULL,NULL,NULL,'ptr757.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1763,120,'A','host758','198.51.157.170','198.51.157.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1764,122,'TXT','txt759','test-txt-759',NULL,NULL,NULL,NULL,'test-txt-759',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1765,142,'AAAA','host760','2001:db8::b5a6',NULL,'2001:db8::b5a6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1766,127,'TXT','txt761','test-txt-761',NULL,NULL,NULL,NULL,'test-txt-761',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1767,140,'A','host762','198.51.217.244','198.51.217.244',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1768,149,'TXT','txt763','test-txt-763',NULL,NULL,NULL,NULL,'test-txt-763',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1769,122,'PTR','ptr764','ptr764.in-addr.arpa.',NULL,NULL,NULL,'ptr764.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1770,131,'AAAA','host765','2001:db8::4c3f',NULL,'2001:db8::4c3f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1771,157,'AAAA','host766','2001:db8::b997',NULL,'2001:db8::b997',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1772,111,'TXT','txt767','test-txt-767',NULL,NULL,NULL,NULL,'test-txt-767',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1773,155,'TXT','txt768','test-txt-768',NULL,NULL,NULL,NULL,'test-txt-768',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1774,149,'AAAA','host769','2001:db8::dbc2',NULL,'2001:db8::dbc2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1775,134,'TXT','txt770','test-txt-770',NULL,NULL,NULL,NULL,'test-txt-770',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1776,158,'CNAME','cname771','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1777,132,'AAAA','host772','2001:db8::9438',NULL,'2001:db8::9438',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1778,119,'TXT','txt773','test-txt-773',NULL,NULL,NULL,NULL,'test-txt-773',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1779,159,'AAAA','host774','2001:db8::dde8',NULL,'2001:db8::dde8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1780,152,'PTR','ptr775','ptr775.in-addr.arpa.',NULL,NULL,NULL,'ptr775.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1781,132,'CNAME','cname776','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1782,155,'TXT','txt777','test-txt-777',NULL,NULL,NULL,NULL,'test-txt-777',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1783,115,'PTR','ptr778','ptr778.in-addr.arpa.',NULL,NULL,NULL,'ptr778.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1784,119,'A','host779','198.51.240.87','198.51.240.87',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1785,151,'CNAME','cname780','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1786,117,'PTR','ptr781','ptr781.in-addr.arpa.',NULL,NULL,NULL,'ptr781.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1787,140,'TXT','txt782','test-txt-782',NULL,NULL,NULL,NULL,'test-txt-782',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1788,143,'TXT','txt783','test-txt-783',NULL,NULL,NULL,NULL,'test-txt-783',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1789,157,'AAAA','host784','2001:db8::a575',NULL,'2001:db8::a575',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1790,153,'PTR','ptr785','ptr785.in-addr.arpa.',NULL,NULL,NULL,'ptr785.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1791,112,'AAAA','host786','2001:db8::af4d',NULL,'2001:db8::af4d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1792,150,'TXT','txt787','test-txt-787',NULL,NULL,NULL,NULL,'test-txt-787',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1793,124,'PTR','ptr788','ptr788.in-addr.arpa.',NULL,NULL,NULL,'ptr788.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1794,156,'PTR','ptr789','ptr789.in-addr.arpa.',NULL,NULL,NULL,'ptr789.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1795,138,'TXT','txt790','test-txt-790',NULL,NULL,NULL,NULL,'test-txt-790',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1796,155,'AAAA','host791','2001:db8::1dde',NULL,'2001:db8::1dde',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1797,139,'CNAME','cname792','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1798,123,'A','host793','198.51.55.110','198.51.55.110',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1799,138,'CNAME','cname794','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1800,121,'A','host795','198.51.44.152','198.51.44.152',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1801,150,'PTR','ptr796','ptr796.in-addr.arpa.',NULL,NULL,NULL,'ptr796.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1802,155,'PTR','ptr797','ptr797.in-addr.arpa.',NULL,NULL,NULL,'ptr797.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1803,147,'AAAA','host798','2001:db8::20fe',NULL,'2001:db8::20fe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1804,153,'CNAME','cname799','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1805,121,'TXT','txt800','test-txt-800',NULL,NULL,NULL,NULL,'test-txt-800',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1806,112,'PTR','ptr801','ptr801.in-addr.arpa.',NULL,NULL,NULL,'ptr801.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1807,151,'TXT','txt802','test-txt-802',NULL,NULL,NULL,NULL,'test-txt-802',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1808,146,'TXT','txt803','test-txt-803',NULL,NULL,NULL,NULL,'test-txt-803',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1809,124,'AAAA','host804','2001:db8::5cc3',NULL,'2001:db8::5cc3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1810,142,'PTR','ptr805','ptr805.in-addr.arpa.',NULL,NULL,NULL,'ptr805.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1811,136,'TXT','txt806','test-txt-806',NULL,NULL,NULL,NULL,'test-txt-806',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1812,139,'CNAME','cname807','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1813,122,'PTR','ptr808','ptr808.in-addr.arpa.',NULL,NULL,NULL,'ptr808.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1814,157,'CNAME','cname809','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1815,156,'A','host810','198.51.217.194','198.51.217.194',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1816,119,'AAAA','host811','2001:db8::ec6b',NULL,'2001:db8::ec6b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1817,153,'A','host812','198.51.101.40','198.51.101.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1818,142,'AAAA','host813','2001:db8::effc',NULL,'2001:db8::effc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1819,116,'PTR','ptr814','ptr814.in-addr.arpa.',NULL,NULL,NULL,'ptr814.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1820,130,'TXT','txt815','test-txt-815',NULL,NULL,NULL,NULL,'test-txt-815',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1821,142,'A','host816','198.51.103.224','198.51.103.224',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1822,123,'AAAA','host817','2001:db8::e726',NULL,'2001:db8::e726',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1823,122,'A','host818','198.51.32.136','198.51.32.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1824,154,'TXT','txt819','test-txt-819',NULL,NULL,NULL,NULL,'test-txt-819',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1825,133,'AAAA','host820','2001:db8::92cb',NULL,'2001:db8::92cb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1826,140,'AAAA','host821','2001:db8::c72d',NULL,'2001:db8::c72d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1827,151,'TXT','txt822','test-txt-822',NULL,NULL,NULL,NULL,'test-txt-822',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1828,111,'TXT','txt823','test-txt-823',NULL,NULL,NULL,NULL,'test-txt-823',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1829,157,'A','host824','198.51.44.79','198.51.44.79',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1830,112,'AAAA','host825','2001:db8::6f53',NULL,'2001:db8::6f53',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1831,159,'AAAA','host826','2001:db8::6ac',NULL,'2001:db8::6ac',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1832,138,'TXT','txt827','test-txt-827',NULL,NULL,NULL,NULL,'test-txt-827',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1833,131,'A','host828','198.51.190.119','198.51.190.119',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1834,159,'CNAME','cname829','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1835,159,'CNAME','cname830','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1836,156,'TXT','txt831','test-txt-831',NULL,NULL,NULL,NULL,'test-txt-831',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1837,132,'TXT','txt832','test-txt-832',NULL,NULL,NULL,NULL,'test-txt-832',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1838,151,'TXT','txt833','test-txt-833',NULL,NULL,NULL,NULL,'test-txt-833',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1839,129,'PTR','ptr834','ptr834.in-addr.arpa.',NULL,NULL,NULL,'ptr834.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1840,131,'TXT','txt835','test-txt-835',NULL,NULL,NULL,NULL,'test-txt-835',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1841,125,'CNAME','cname836','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1842,134,'CNAME','cname837','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1843,127,'A','host838','198.51.86.176','198.51.86.176',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1844,156,'CNAME','cname839','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1845,116,'PTR','ptr840','ptr840.in-addr.arpa.',NULL,NULL,NULL,'ptr840.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1846,151,'CNAME','cname841','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1847,145,'TXT','txt842','test-txt-842',NULL,NULL,NULL,NULL,'test-txt-842',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1848,117,'PTR','ptr843','ptr843.in-addr.arpa.',NULL,NULL,NULL,'ptr843.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1849,129,'TXT','txt844','test-txt-844',NULL,NULL,NULL,NULL,'test-txt-844',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1850,150,'A','host845','198.51.248.128','198.51.248.128',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1851,132,'AAAA','host846','2001:db8::c17f',NULL,'2001:db8::c17f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1852,123,'TXT','txt847','test-txt-847',NULL,NULL,NULL,NULL,'test-txt-847',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1853,115,'A','host848','198.51.76.166','198.51.76.166',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1854,126,'A','host849','198.51.188.11','198.51.188.11',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1855,132,'CNAME','cname850','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1856,138,'AAAA','host851','2001:db8::eb95',NULL,'2001:db8::eb95',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1857,124,'PTR','ptr852','ptr852.in-addr.arpa.',NULL,NULL,NULL,'ptr852.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1858,118,'TXT','txt853','test-txt-853',NULL,NULL,NULL,NULL,'test-txt-853',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1859,151,'AAAA','host854','2001:db8::c21',NULL,'2001:db8::c21',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1860,154,'CNAME','cname855','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1861,126,'PTR','ptr856','ptr856.in-addr.arpa.',NULL,NULL,NULL,'ptr856.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1862,151,'CNAME','cname857','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1863,133,'CNAME','cname858','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1864,147,'PTR','ptr859','ptr859.in-addr.arpa.',NULL,NULL,NULL,'ptr859.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1865,147,'AAAA','host860','2001:db8::4963',NULL,'2001:db8::4963',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1866,153,'PTR','ptr861','ptr861.in-addr.arpa.',NULL,NULL,NULL,'ptr861.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1867,146,'PTR','ptr862','ptr862.in-addr.arpa.',NULL,NULL,NULL,'ptr862.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1868,153,'PTR','ptr863','ptr863.in-addr.arpa.',NULL,NULL,NULL,'ptr863.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1869,127,'AAAA','host864','2001:db8::8f97',NULL,'2001:db8::8f97',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1870,132,'TXT','txt865','test-txt-865',NULL,NULL,NULL,NULL,'test-txt-865',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1871,143,'TXT','txt866','test-txt-866',NULL,NULL,NULL,NULL,'test-txt-866',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1872,122,'PTR','ptr867','ptr867.in-addr.arpa.',NULL,NULL,NULL,'ptr867.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1873,110,'TXT','txt868','test-txt-868',NULL,NULL,NULL,NULL,'test-txt-868',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1874,118,'PTR','ptr869','ptr869.in-addr.arpa.',NULL,NULL,NULL,'ptr869.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1875,150,'TXT','txt870','test-txt-870',NULL,NULL,NULL,NULL,'test-txt-870',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1876,130,'PTR','ptr871','ptr871.in-addr.arpa.',NULL,NULL,NULL,'ptr871.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1877,152,'TXT','txt872','test-txt-872',NULL,NULL,NULL,NULL,'test-txt-872',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1878,121,'PTR','ptr873','ptr873.in-addr.arpa.',NULL,NULL,NULL,'ptr873.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1879,144,'CNAME','cname874','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1880,125,'PTR','ptr875','ptr875.in-addr.arpa.',NULL,NULL,NULL,'ptr875.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1881,113,'TXT','txt876','test-txt-876',NULL,NULL,NULL,NULL,'test-txt-876',3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1882,132,'A','host877','198.51.170.20','198.51.170.20',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1883,157,'PTR','ptr878','ptr878.in-addr.arpa.',NULL,NULL,NULL,'ptr878.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1884,151,'PTR','ptr879','ptr879.in-addr.arpa.',NULL,NULL,NULL,'ptr879.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1885,155,'AAAA','host880','2001:db8::ac7f',NULL,'2001:db8::ac7f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1886,134,'AAAA','host881','2001:db8::9b24',NULL,'2001:db8::9b24',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1887,155,'AAAA','host882','2001:db8::e996',NULL,'2001:db8::e996',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1888,155,'A','host883','198.51.220.218','198.51.220.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:12',NULL,'2025-10-23 07:34:12',NULL,NULL,NULL,NULL),
(1889,142,'A','host884','198.51.193.24','198.51.193.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1890,157,'PTR','ptr885','ptr885.in-addr.arpa.',NULL,NULL,NULL,'ptr885.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1891,124,'PTR','ptr886','ptr886.in-addr.arpa.',NULL,NULL,NULL,'ptr886.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1892,151,'CNAME','cname887','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1893,114,'CNAME','cname888','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1894,155,'PTR','ptr889','ptr889.in-addr.arpa.',NULL,NULL,NULL,'ptr889.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1895,122,'A','host890','198.51.98.171','198.51.98.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1896,141,'CNAME','cname891','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1897,132,'AAAA','host892','2001:db8::35ff',NULL,'2001:db8::35ff',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1898,129,'AAAA','host893','2001:db8::20a7',NULL,'2001:db8::20a7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1899,139,'CNAME','cname894','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1900,157,'A','host895','198.51.148.206','198.51.148.206',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1901,152,'CNAME','cname896','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1902,135,'PTR','ptr897','ptr897.in-addr.arpa.',NULL,NULL,NULL,'ptr897.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1903,119,'PTR','ptr898','ptr898.in-addr.arpa.',NULL,NULL,NULL,'ptr898.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1904,118,'CNAME','cname899','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1905,135,'A','host900','198.51.148.155','198.51.148.155',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1906,157,'CNAME','cname901','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1907,150,'CNAME','cname902','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1908,117,'AAAA','host903','2001:db8::a243',NULL,'2001:db8::a243',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1909,123,'A','host904','198.51.207.215','198.51.207.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1910,123,'TXT','txt905','test-txt-905',NULL,NULL,NULL,NULL,'test-txt-905',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1911,119,'AAAA','host906','2001:db8::c941',NULL,'2001:db8::c941',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1912,123,'CNAME','cname907','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1913,137,'A','host908','198.51.121.152','198.51.121.152',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1914,141,'AAAA','host909','2001:db8::157d',NULL,'2001:db8::157d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1915,152,'AAAA','host910','2001:db8::82e5',NULL,'2001:db8::82e5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1916,140,'TXT','txt911','test-txt-911',NULL,NULL,NULL,NULL,'test-txt-911',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1917,158,'CNAME','cname912','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1918,156,'PTR','ptr913','ptr913.in-addr.arpa.',NULL,NULL,NULL,'ptr913.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1919,112,'A','host914','198.51.238.202','198.51.238.202',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1920,117,'PTR','ptr915','ptr915.in-addr.arpa.',NULL,NULL,NULL,'ptr915.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1921,127,'TXT','txt916','test-txt-916',NULL,NULL,NULL,NULL,'test-txt-916',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1922,117,'AAAA','host917','2001:db8::26b0',NULL,'2001:db8::26b0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1923,157,'A','host918','198.51.167.47','198.51.167.47',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1924,136,'CNAME','cname919','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1925,133,'A','host920','198.51.150.95','198.51.150.95',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1926,156,'PTR','ptr921','ptr921.in-addr.arpa.',NULL,NULL,NULL,'ptr921.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1927,136,'CNAME','cname922','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1928,132,'A','host923','198.51.183.213','198.51.183.213',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1929,132,'CNAME','cname924','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1930,133,'AAAA','host925','2001:db8::adcc',NULL,'2001:db8::adcc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1931,147,'AAAA','host926','2001:db8::24f2',NULL,'2001:db8::24f2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1932,144,'AAAA','host927','2001:db8::8d62',NULL,'2001:db8::8d62',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1933,152,'PTR','ptr928','ptr928.in-addr.arpa.',NULL,NULL,NULL,'ptr928.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1934,129,'TXT','txt929','test-txt-929',NULL,NULL,NULL,NULL,'test-txt-929',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1935,138,'AAAA','host930','2001:db8::d05d',NULL,'2001:db8::d05d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1936,151,'TXT','txt931','test-txt-931',NULL,NULL,NULL,NULL,'test-txt-931',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1937,128,'PTR','ptr932','ptr932.in-addr.arpa.',NULL,NULL,NULL,'ptr932.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1938,151,'A','host933','198.51.114.135','198.51.114.135',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1939,123,'AAAA','host934','2001:db8::7995',NULL,'2001:db8::7995',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1940,127,'AAAA','host935','2001:db8::dfd0',NULL,'2001:db8::dfd0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1941,128,'CNAME','cname936','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1942,153,'A','host937','198.51.189.228','198.51.189.228',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1943,125,'PTR','ptr938','ptr938.in-addr.arpa.',NULL,NULL,NULL,'ptr938.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1944,128,'A','host939','198.51.194.97','198.51.194.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1945,131,'AAAA','host940','2001:db8::3d48',NULL,'2001:db8::3d48',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1946,154,'TXT','txt941','test-txt-941',NULL,NULL,NULL,NULL,'test-txt-941',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1947,131,'PTR','ptr942','ptr942.in-addr.arpa.',NULL,NULL,NULL,'ptr942.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1948,115,'A','host943','198.51.228.84','198.51.228.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1949,125,'PTR','ptr944','ptr944.in-addr.arpa.',NULL,NULL,NULL,'ptr944.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1950,150,'AAAA','host945','2001:db8::4cca',NULL,'2001:db8::4cca',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1951,117,'TXT','txt946','test-txt-946',NULL,NULL,NULL,NULL,'test-txt-946',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1952,128,'CNAME','cname947','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1953,120,'TXT','txt948','test-txt-948',NULL,NULL,NULL,NULL,'test-txt-948',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1954,113,'AAAA','host949','2001:db8::5e68',NULL,'2001:db8::5e68',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1955,125,'AAAA','host950','2001:db8::bdc9',NULL,'2001:db8::bdc9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1956,131,'A','host951','198.51.97.199','198.51.97.199',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1957,125,'PTR','ptr952','ptr952.in-addr.arpa.',NULL,NULL,NULL,'ptr952.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1958,128,'TXT','txt953','test-txt-953',NULL,NULL,NULL,NULL,'test-txt-953',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1959,154,'TXT','txt954','test-txt-954',NULL,NULL,NULL,NULL,'test-txt-954',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1960,152,'CNAME','cname955','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1961,149,'A','host956','198.51.146.200','198.51.146.200',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1962,148,'A','host957','198.51.217.170','198.51.217.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1963,155,'CNAME','cname958','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1964,123,'TXT','txt959','test-txt-959',NULL,NULL,NULL,NULL,'test-txt-959',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1965,159,'CNAME','cname960','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1966,110,'A','host961','198.51.106.44','198.51.106.44',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1967,116,'TXT','txt962','test-txt-962',NULL,NULL,NULL,NULL,'test-txt-962',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1968,153,'TXT','txt963','test-txt-963',NULL,NULL,NULL,NULL,'test-txt-963',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1969,127,'PTR','ptr964','ptr964.in-addr.arpa.',NULL,NULL,NULL,'ptr964.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1970,149,'TXT','txt965','test-txt-965',NULL,NULL,NULL,NULL,'test-txt-965',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1971,135,'CNAME','cname966','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1972,142,'AAAA','host967','2001:db8::952f',NULL,'2001:db8::952f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1973,135,'CNAME','cname968','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1974,132,'TXT','txt969','test-txt-969',NULL,NULL,NULL,NULL,'test-txt-969',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1975,156,'CNAME','cname970','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1976,131,'CNAME','cname971','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1977,147,'A','host972','198.51.105.94','198.51.105.94',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1978,157,'TXT','txt973','test-txt-973',NULL,NULL,NULL,NULL,'test-txt-973',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1979,152,'CNAME','cname974','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1980,120,'TXT','txt975','test-txt-975',NULL,NULL,NULL,NULL,'test-txt-975',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1981,157,'AAAA','host976','2001:db8::4789',NULL,'2001:db8::4789',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1982,142,'AAAA','host977','2001:db8::cb3a',NULL,'2001:db8::cb3a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1983,159,'AAAA','host978','2001:db8::4723',NULL,'2001:db8::4723',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1984,159,'A','host979','198.51.25.131','198.51.25.131',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1985,147,'PTR','ptr980','ptr980.in-addr.arpa.',NULL,NULL,NULL,'ptr980.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1986,155,'PTR','ptr981','ptr981.in-addr.arpa.',NULL,NULL,NULL,'ptr981.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1987,135,'PTR','ptr982','ptr982.in-addr.arpa.',NULL,NULL,NULL,'ptr982.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1988,131,'CNAME','cname983','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1989,157,'CNAME','cname984','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1990,126,'CNAME','cname985','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1991,147,'A','host986','198.51.197.203','198.51.197.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1992,152,'CNAME','cname987','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1993,157,'TXT','txt988','test-txt-988',NULL,NULL,NULL,NULL,'test-txt-988',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1994,120,'TXT','txt989','test-txt-989',NULL,NULL,NULL,NULL,'test-txt-989',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1995,131,'TXT','txt990','test-txt-990',NULL,NULL,NULL,NULL,'test-txt-990',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1996,153,'CNAME','cname991','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1997,137,'TXT','txt992','test-txt-992',NULL,NULL,NULL,NULL,'test-txt-992',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1998,138,'AAAA','host993','2001:db8::3fcf',NULL,'2001:db8::3fcf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(1999,143,'PTR','ptr994','ptr994.in-addr.arpa.',NULL,NULL,NULL,'ptr994.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2000,135,'TXT','txt995','test-txt-995',NULL,NULL,NULL,NULL,'test-txt-995',3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2001,120,'A','host996','198.51.50.171','198.51.50.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2002,151,'A','host997','198.51.68.232','198.51.68.232',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2003,136,'PTR','ptr998','ptr998.in-addr.arpa.',NULL,NULL,NULL,'ptr998.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2004,132,'PTR','ptr999','ptr999.in-addr.arpa.',NULL,NULL,NULL,'ptr999.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2005,124,'PTR','ptr1000','ptr1000.in-addr.arpa.',NULL,NULL,NULL,'ptr1000.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-23 07:34:13',NULL,'2025-10-23 07:34:13',NULL,NULL,NULL,NULL),
(2006,110,'A','aaaaaaaabbbb','192.16.1.200','192.16.1.200',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',2,'2025-10-23 12:01:56',NULL,NULL,NULL,NULL,NULL,NULL);
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
(2,'guittou','guittou@gmail.com','$2y$10$.CJ6UeeKXSj7O3dZGcdtw.bjXze2e5z.n58462/hS.Rk4VgH5D21q','database','2025-10-20 09:24:16','2025-10-24 13:07:11',1);
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
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
INSERT INTO `zone_file_includes` VALUES
(15,128,150,1,'2025-10-23 09:34:11'),
(16,146,151,2,'2025-10-23 09:34:11'),
(17,117,152,3,'2025-10-23 09:34:11'),
(18,122,153,4,'2025-10-23 09:34:11'),
(19,130,154,5,'2025-10-23 09:34:11'),
(20,114,155,6,'2025-10-23 09:34:11'),
(21,137,156,7,'2025-10-23 09:34:11'),
(22,111,157,8,'2025-10-23 09:34:11'),
(23,118,158,9,'2025-10-23 09:34:11'),
(24,118,159,10,'2025-10-23 09:34:11');
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
INSERT INTO `zone_file_validation` VALUES
(98,127,'pending','Validation queued for background processing','2025-10-23 09:36:29',2),
(99,127,'passed','zone test-master-18.local/IN: loaded serial 2025102318\nOK','2025-10-23 09:36:38',2),
(100,156,'pending','Validation queued for top master zone (ID: 137)','2025-10-23 09:37:15',2),
(101,137,'pending','Validation queued for background processing','2025-10-23 09:37:15',2),
(102,137,'failed','Failed to inline includes: Included file not found for validation: common-include-7.inc (path: includes/common-include-7.inc)','2025-10-23 09:37:26',2),
(103,156,'pending','Validation queued for top master zone (ID: 137)','2025-10-23 09:38:36',2),
(104,137,'pending','Validation queued for background processing','2025-10-23 09:38:36',2),
(105,137,'failed','Failed to inline includes: Included file not found for validation: common-include-7.inc (path: includes/common-include-7.inc)','2025-10-23 09:38:41',2),
(106,156,'pending','Validation queued for top master zone (ID: 137)','2025-10-23 09:41:18',2),
(107,137,'pending','Validation queued for background processing','2025-10-23 09:41:18',2),
(108,116,'pending','Validation queued for background processing','2025-10-23 12:02:23',2),
(109,137,'failed','dns_master_load: zone_137.db:7: includes/common-include-7.inc: file not found\ndns_master_load: zone_137.db:9: includes/common-include-7.inc: file not found\nzone test-master-28.local/IN: loading from master file zone_137.db failed: file not found\nzone test-master-28.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_137.db, Line: 7\nMessage: includes/common-include-7.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_137.db, Line: 9\nMessage: includes/common-include-7.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 12:02:28',2),
(110,156,'failed','Validation performed on parent zone \'test-master-28.local\' (ID: 137):\n\ndns_master_load: zone_137.db:7: includes/common-include-7.inc: file not found\ndns_master_load: zone_137.db:9: includes/common-include-7.inc: file not found\nzone test-master-28.local/IN: loading from master file zone_137.db failed: file not found\nzone test-master-28.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_137.db, Line: 7\nMessage: includes/common-include-7.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_137.db, Line: 9\nMessage: includes/common-include-7.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 12:02:28',2),
(111,116,'passed','zone test-master-7.local/IN: loaded serial 2025102307\nOK','2025-10-23 12:02:28',2),
(112,155,'pending','Validation queued for top master zone (ID: 114)','2025-10-23 12:03:01',2),
(113,114,'pending','Validation queued for background processing','2025-10-23 12:03:01',2),
(114,114,'failed','dns_master_load: zone_114.db:7: includes/common-include-6.inc: file not found\ndns_master_load: zone_114.db:9: includes/common-include-6.inc: file not found\nzone test-master-5.local/IN: loading from master file zone_114.db failed: file not found\nzone test-master-5.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_114.db, Line: 7\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_114.db, Line: 9\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 12:03:06',2),
(115,155,'failed','Validation performed on parent zone \'test-master-5.local\' (ID: 114):\n\ndns_master_load: zone_114.db:7: includes/common-include-6.inc: file not found\ndns_master_load: zone_114.db:9: includes/common-include-6.inc: file not found\nzone test-master-5.local/IN: loading from master file zone_114.db failed: file not found\nzone test-master-5.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_114.db, Line: 7\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_114.db, Line: 9\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 12:03:06',2),
(116,135,'pending','Validation queued for background processing','2025-10-23 12:12:15',2),
(117,135,'passed','Command: named-checkzone -q \'test-master-26.local\' \'/tmp/dns3_validate_135_1761221540/db.test-master-26.local.flat\' 2>&1\nExitCode: 0\n---\n\n','2025-10-23 12:12:20',NULL),
(118,155,'pending','Validation queued for top master zone (ID: 114)','2025-10-23 12:12:56',2),
(119,114,'pending','Validation queued for background processing','2025-10-23 12:12:56',2),
(120,114,'passed','Command: named-checkzone -q \'test-master-5.local\' \'/tmp/dns3_validate_114_1761221579/db.test-master-5.local.flat\' 2>&1\nExitCode: 0\n---\n\n','2025-10-23 12:12:59',NULL),
(121,117,'pending','Validation queued for background processing','2025-10-23 13:10:48',2),
(122,117,'failed','dns_master_load: zone_117.db:7: includes/common-include-3.inc: file not found\ndns_master_load: zone_117.db:9: includes/common-include-3.inc: file not found\nzone test-master-8.local/IN: loading from master file zone_117.db failed: file not found\nzone test-master-8.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_117.db, Line: 7\nMessage: includes/common-include-3.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_117.db, Line: 9\nMessage: includes/common-include-3.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 13:10:57',2),
(123,152,'failed','Validation performed on parent zone \'test-master-8.local\' (ID: 117):\n\ndns_master_load: zone_117.db:7: includes/common-include-3.inc: file not found\ndns_master_load: zone_117.db:9: includes/common-include-3.inc: file not found\nzone test-master-8.local/IN: loading from master file zone_117.db failed: file not found\nzone test-master-8.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_117.db, Line: 7\nMessage: includes/common-include-3.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_117.db, Line: 9\nMessage: includes/common-include-3.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 13:10:57',2),
(124,155,'pending','Validation queued for top master zone (ID: 114)','2025-10-23 13:11:38',2),
(125,114,'pending','Validation queued for background processing','2025-10-23 13:11:38',2),
(126,114,'failed','dns_master_load: zone_114.db:7: includes/common-include-6.inc: file not found\ndns_master_load: zone_114.db:9: includes/common-include-6.inc: file not found\nzone test-master-5.local/IN: loading from master file zone_114.db failed: file not found\nzone test-master-5.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_114.db, Line: 7\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_114.db, Line: 9\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 13:11:41',2),
(127,155,'failed','Validation performed on parent zone \'test-master-5.local\' (ID: 114):\n\ndns_master_load: zone_114.db:7: includes/common-include-6.inc: file not found\ndns_master_load: zone_114.db:9: includes/common-include-6.inc: file not found\nzone test-master-5.local/IN: loading from master file zone_114.db failed: file not found\nzone test-master-5.local/IN: not loaded due to errors.\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\nFile: dns_master_load: zone_114.db, Line: 7\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n---\n\nFile: dns_master_load: zone_114.db, Line: 9\nMessage: includes/common-include-6.inc: file not found\n(Unable to locate file for line extraction)\n\n=== END OF EXTRACTED LINES ===','2025-10-23 13:11:41',2),
(128,117,'pending','Validation queued for background processing','2025-10-24 13:07:25',2),
(129,117,'passed','Command: named-checkzone -q \'test-master-8.local\' \'/tmp/dns3_validate_68fb7a27d3b97/zone_117_flat.db\' 2>&1\nExit Code: 0\n\n','2025-10-24 13:07:51',2),
(130,152,'passed','Command: named-checkzone -q \'test-master-8.local\' \'/tmp/dns3_validate_68fb7a27d3b97/zone_117_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-8.local\' (ID: 117):\n\n','2025-10-24 13:07:51',2),
(131,152,'pending','Validation queued for top master zone (ID: 117)','2025-10-24 13:08:57',2),
(132,117,'pending','Validation queued for background processing','2025-10-24 13:08:57',2),
(133,117,'passed','Command: named-checkzone -q \'test-master-8.local\' \'/tmp/dns3_validate_68fb7a6f14137/zone_117_flat.db\' 2>&1\nExit Code: 0\n\n','2025-10-24 13:09:03',2),
(134,152,'passed','Command: named-checkzone -q \'test-master-8.local\' \'/tmp/dns3_validate_68fb7a6f14137/zone_117_flat.db\' 2>&1\nExit Code: 0\n\nValidation performed on parent zone \'test-master-8.local\' (ID: 117):\n\n','2025-10-24 13:09:03',2);
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
) ENGINE=InnoDB AUTO_INCREMENT=160 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(110,'test-master-1.local','db.test-master-1.local',NULL,'$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102301 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(111,'test-master-2.local','db.test-master-2.local',NULL,'$ORIGIN test-master-2.local.\n$TTL 3600\n@ IN SOA ns1.test-master-2.local. admin.test-master-2.local. ( 2025102302 3600 1800 604800 86400 )\n    IN NS ns1.test-master-2.local.\nns1 IN A 192.0.2.3\n\n$INCLUDE includes/common-include-8.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(112,'test-master-3.local','db.test-master-3.local',NULL,'$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102303 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(113,'test-master-4.local','db.test-master-4.local',NULL,'$ORIGIN test-master-4.local.\n$TTL 3600\n@ IN SOA ns1.test-master-4.local. admin.test-master-4.local. ( 2025102304 3600 1800 604800 86400 )\n    IN NS ns1.test-master-4.local.\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(114,'test-master-5.local','db.test-master-5.local',NULL,'$ORIGIN test-master-5.local.\n$TTL 3600\n@ IN SOA ns1.test-master-5.local. admin.test-master-5.local. ( 2025102305 3600 1800 604800 86400 )\n    IN NS ns1.test-master-5.local.\nns1 IN A 192.0.2.6\n\n$INCLUDE includes/common-include-6.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(115,'test-master-6.local','db.test-master-6.local',NULL,'$ORIGIN test-master-6.local.\n$TTL 3600\n@ IN SOA ns1.test-master-6.local. admin.test-master-6.local. ( 2025102306 3600 1800 604800 86400 )\n    IN NS ns1.test-master-6.local.\nns1 IN A 192.0.2.7\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(116,'test-master-7.local','db.test-master-7.local',NULL,'$ORIGIN test-master-7.local.\n$TTL 3600\n@ IN SOA ns1.test-master-7.local. admin.test-master-7.local. ( 2025102307 3600 1800 604800 86400 )\n    IN NS ns1.test-master-7.local.\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(117,'test-master-8.local','db.test-master-8.local',NULL,'$ORIGIN test-master-8.local.\n$TTL 3600\n@ IN SOA ns1.test-master-8.local. admin.test-master-8.local. ( 2025102308 3600 1800 604800 86400 )\n    IN NS ns1.test-master-8.local.\nns1 IN A 192.0.2.9\n\n$INCLUDE includes/common-include-3.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(118,'test-master-9.local','db.test-master-9.local',NULL,'$ORIGIN test-master-9.local.\n$TTL 3600\n@ IN SOA ns1.test-master-9.local. admin.test-master-9.local. ( 2025102309 3600 1800 604800 86400 )\n    IN NS ns1.test-master-9.local.\nns1 IN A 192.0.2.10\n\n$INCLUDE includes/common-include-9.inc\n\n$INCLUDE includes/common-include-10.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(119,'test-master-10.local','db.test-master-10.local',NULL,'$ORIGIN test-master-10.local.\n$TTL 3600\n@ IN SOA ns1.test-master-10.local. admin.test-master-10.local. ( 2025102310 3600 1800 604800 86400 )\n    IN NS ns1.test-master-10.local.\nns1 IN A 192.0.2.11\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(120,'test-master-11.local','db.test-master-11.local',NULL,'$ORIGIN test-master-11.local.\n$TTL 3600\n@ IN SOA ns1.test-master-11.local. admin.test-master-11.local. ( 2025102311 3600 1800 604800 86400 )\n    IN NS ns1.test-master-11.local.\nns1 IN A 192.0.2.12\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(121,'test-master-12.local','db.test-master-12.local',NULL,'$ORIGIN test-master-12.local.\n$TTL 3600\n@ IN SOA ns1.test-master-12.local. admin.test-master-12.local. ( 2025102312 3600 1800 604800 86400 )\n    IN NS ns1.test-master-12.local.\nns1 IN A 192.0.2.13\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(122,'test-master-13.local','db.test-master-13.local',NULL,'$ORIGIN test-master-13.local.\n$TTL 3600\n@ IN SOA ns1.test-master-13.local. admin.test-master-13.local. ( 2025102313 3600 1800 604800 86400 )\n    IN NS ns1.test-master-13.local.\nns1 IN A 192.0.2.14\n\n$INCLUDE includes/common-include-4.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(123,'test-master-14.local','db.test-master-14.local',NULL,'$ORIGIN test-master-14.local.\n$TTL 3600\n@ IN SOA ns1.test-master-14.local. admin.test-master-14.local. ( 2025102314 3600 1800 604800 86400 )\n    IN NS ns1.test-master-14.local.\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(124,'test-master-15.local','db.test-master-15.local',NULL,'$ORIGIN test-master-15.local.\n$TTL 3600\n@ IN SOA ns1.test-master-15.local. admin.test-master-15.local. ( 2025102315 3600 1800 604800 86400 )\n    IN NS ns1.test-master-15.local.\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(125,'test-master-16.local','db.test-master-16.local',NULL,'$ORIGIN test-master-16.local.\n$TTL 3600\n@ IN SOA ns1.test-master-16.local. admin.test-master-16.local. ( 2025102316 3600 1800 604800 86400 )\n    IN NS ns1.test-master-16.local.\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(126,'test-master-17.local','db.test-master-17.local',NULL,'$ORIGIN test-master-17.local.\n$TTL 3600\n@ IN SOA ns1.test-master-17.local. admin.test-master-17.local. ( 2025102317 3600 1800 604800 86400 )\n    IN NS ns1.test-master-17.local.\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(127,'test-master-18.local','db.test-master-18.local',NULL,'$ORIGIN test-master-18.local.\n$TTL 3600\n@ IN SOA ns1.test-master-18.local. admin.test-master-18.local. ( 2025102318 3600 1800 604800 86400 )\n    IN NS ns1.test-master-18.local.\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(128,'test-master-19.local','db.test-master-19.local',NULL,'$ORIGIN test-master-19.local.\n$TTL 3600\n@ IN SOA ns1.test-master-19.local. admin.test-master-19.local. ( 2025102319 3600 1800 604800 86400 )\n    IN NS ns1.test-master-19.local.\nns1 IN A 192.0.2.20\n\n$INCLUDE includes/common-include-1.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(129,'test-master-20.local','db.test-master-20.local',NULL,'$ORIGIN test-master-20.local.\n$TTL 3600\n@ IN SOA ns1.test-master-20.local. admin.test-master-20.local. ( 2025102320 3600 1800 604800 86400 )\n    IN NS ns1.test-master-20.local.\nns1 IN A 192.0.2.21\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(130,'test-master-21.local','db.test-master-21.local',NULL,'$ORIGIN test-master-21.local.\n$TTL 3600\n@ IN SOA ns1.test-master-21.local. admin.test-master-21.local. ( 2025102321 3600 1800 604800 86400 )\n    IN NS ns1.test-master-21.local.\nns1 IN A 192.0.2.22\n\n$INCLUDE includes/common-include-5.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(131,'test-master-22.local','db.test-master-22.local',NULL,'$ORIGIN test-master-22.local.\n$TTL 3600\n@ IN SOA ns1.test-master-22.local. admin.test-master-22.local. ( 2025102322 3600 1800 604800 86400 )\n    IN NS ns1.test-master-22.local.\nns1 IN A 192.0.2.23\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(132,'test-master-23.local','db.test-master-23.local',NULL,'$ORIGIN test-master-23.local.\n$TTL 3600\n@ IN SOA ns1.test-master-23.local. admin.test-master-23.local. ( 2025102323 3600 1800 604800 86400 )\n    IN NS ns1.test-master-23.local.\nns1 IN A 192.0.2.24\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(133,'test-master-24.local','db.test-master-24.local',NULL,'$ORIGIN test-master-24.local.\n$TTL 3600\n@ IN SOA ns1.test-master-24.local. admin.test-master-24.local. ( 2025102324 3600 1800 604800 86400 )\n    IN NS ns1.test-master-24.local.\nns1 IN A 192.0.2.25\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(134,'test-master-25.local','db.test-master-25.local',NULL,'$ORIGIN test-master-25.local.\n$TTL 3600\n@ IN SOA ns1.test-master-25.local. admin.test-master-25.local. ( 2025102325 3600 1800 604800 86400 )\n    IN NS ns1.test-master-25.local.\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(135,'test-master-26.local','db.test-master-26.local',NULL,'$ORIGIN test-master-26.local.\n$TTL 3600\n@ IN SOA ns1.test-master-26.local. admin.test-master-26.local. ( 2025102326 3600 1800 604800 86400 )\n    IN NS ns1.test-master-26.local.\nns1 IN A 192.0.2.27\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(136,'test-master-27.local','db.test-master-27.local',NULL,'$ORIGIN test-master-27.local.\n$TTL 3600\n@ IN SOA ns1.test-master-27.local. admin.test-master-27.local. ( 2025102327 3600 1800 604800 86400 )\n    IN NS ns1.test-master-27.local.\nns1 IN A 192.0.2.28\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(137,'test-master-28.local','db.test-master-28.local',NULL,'$ORIGIN test-master-28.local.\n$TTL 3600\n@ IN SOA ns1.test-master-28.local. admin.test-master-28.local. ( 2025102328 3600 1800 604800 86400 )\n    IN NS ns1.test-master-28.local.\nns1 IN A 192.0.2.29\n\n$INCLUDE includes/common-include-7.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(138,'test-master-29.local','db.test-master-29.local',NULL,'$ORIGIN test-master-29.local.\n$TTL 3600\n@ IN SOA ns1.test-master-29.local. admin.test-master-29.local. ( 2025102329 3600 1800 604800 86400 )\n    IN NS ns1.test-master-29.local.\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(139,'test-master-30.local','db.test-master-30.local',NULL,'$ORIGIN test-master-30.local.\n$TTL 3600\n@ IN SOA ns1.test-master-30.local. admin.test-master-30.local. ( 2025102330 3600 1800 604800 86400 )\n    IN NS ns1.test-master-30.local.\nns1 IN A 192.0.2.31\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(140,'test-master-31.local','db.test-master-31.local',NULL,'$ORIGIN test-master-31.local.\n$TTL 3600\n@ IN SOA ns1.test-master-31.local. admin.test-master-31.local. ( 2025102331 3600 1800 604800 86400 )\n    IN NS ns1.test-master-31.local.\nns1 IN A 192.0.2.32\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(141,'test-master-32.local','db.test-master-32.local',NULL,'$ORIGIN test-master-32.local.\n$TTL 3600\n@ IN SOA ns1.test-master-32.local. admin.test-master-32.local. ( 2025102332 3600 1800 604800 86400 )\n    IN NS ns1.test-master-32.local.\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(142,'test-master-33.local','db.test-master-33.local',NULL,'$ORIGIN test-master-33.local.\n$TTL 3600\n@ IN SOA ns1.test-master-33.local. admin.test-master-33.local. ( 2025102333 3600 1800 604800 86400 )\n    IN NS ns1.test-master-33.local.\nns1 IN A 192.0.2.34\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(143,'test-master-34.local','db.test-master-34.local',NULL,'$ORIGIN test-master-34.local.\n$TTL 3600\n@ IN SOA ns1.test-master-34.local. admin.test-master-34.local. ( 2025102334 3600 1800 604800 86400 )\n    IN NS ns1.test-master-34.local.\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(144,'test-master-35.local','db.test-master-35.local',NULL,'$ORIGIN test-master-35.local.\n$TTL 3600\n@ IN SOA ns1.test-master-35.local. admin.test-master-35.local. ( 2025102335 3600 1800 604800 86400 )\n    IN NS ns1.test-master-35.local.\nns1 IN A 192.0.2.36\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(145,'test-master-36.local','db.test-master-36.local',NULL,'$ORIGIN test-master-36.local.\n$TTL 3600\n@ IN SOA ns1.test-master-36.local. admin.test-master-36.local. ( 2025102336 3600 1800 604800 86400 )\n    IN NS ns1.test-master-36.local.\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(146,'test-master-37.local','db.test-master-37.local',NULL,'$ORIGIN test-master-37.local.\n$TTL 3600\n@ IN SOA ns1.test-master-37.local. admin.test-master-37.local. ( 2025102337 3600 1800 604800 86400 )\n    IN NS ns1.test-master-37.local.\nns1 IN A 192.0.2.38\n\n$INCLUDE includes/common-include-2.inc\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 09:34:11'),
(147,'test-master-38.local','db.test-master-38.local',NULL,'$ORIGIN test-master-38.local.\n$TTL 3600\n@ IN SOA ns1.test-master-38.local. admin.test-master-38.local. ( 2025102338 3600 1800 604800 86400 )\n    IN NS ns1.test-master-38.local.\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(148,'test-master-39.local','db.test-master-39.local',NULL,'$ORIGIN test-master-39.local.\n$TTL 3600\n@ IN SOA ns1.test-master-39.local. admin.test-master-39.local. ( 2025102339 3600 1800 604800 86400 )\n    IN NS ns1.test-master-39.local.\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(149,'test-master-40.local','db.test-master-40.local',NULL,'$ORIGIN test-master-40.local.\n$TTL 3600\n@ IN SOA ns1.test-master-40.local. admin.test-master-40.local. ( 2025102340 3600 1800 604800 86400 )\n    IN NS ns1.test-master-40.local.\nns1 IN A 192.0.2.41\n','master','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(150,'common-include-1.inc.local','includes/common-include-1.inc',NULL,'; Include file for common records group 1\nmonitor IN A 198.51.1.10\nmonitor6 IN AAAA 2001:db8::65\ncommon-txt IN TXT \"include-group-1\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(151,'common-include-2.inc.local','includes/common-include-2.inc',NULL,'; Include file for common records group 2\nmonitor IN A 198.51.2.10\nmonitor6 IN AAAA 2001:db8::66\ncommon-txt IN TXT \"include-group-2\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(152,'common-include-3.inc.local','includes/common-include-3.inc',NULL,'; Include file for common records group 3\nmonitor IN A 198.51.3.10\nmonitor6 IN AAAA 2001:db8::67\ncommon-txt IN TXT \"include-group-3\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(153,'common-include-4.inc.local','includes/common-include-4.inc',NULL,'; Include file for common records group 4\nmonitor IN A 198.51.4.10\nmonitor6 IN AAAA 2001:db8::68\ncommon-txt IN TXT \"include-group-4\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(154,'common-include-5.inc.local','includes/common-include-5.inc',NULL,'; Include file for common records group 5\nmonitor IN A 198.51.5.10\nmonitor6 IN AAAA 2001:db8::69\ncommon-txt IN TXT \"include-group-5\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(155,'common-include-6.inc.local','includes/common-include-6.inc',NULL,'; Include file for common records group 6\nmonitor IN A 198.51.6.10\nmonitor6 IN AAAA 2001:db8::6a\ncommon-txt IN TXT \"include-group-6\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(156,'common-include-7.inc.local','includes/common-include-7.inc',NULL,'; Include file for common records group 7\nmonitor IN A 198.51.7.10\nmonitor6 IN AAAA 2001:db8::6b\ncommon-txt IN TXT \"include-group-7\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(157,'common-include-8.inc.local','includes/common-include-8.inc',NULL,'; Include file for common records group 8\nmonitor IN A 198.51.8.10\nmonitor6 IN AAAA 2001:db8::6c\ncommon-txt IN TXT \"include-group-8\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(158,'common-include-9.inc.local','includes/common-include-9.inc',NULL,'; Include file for common records group 9\nmonitor IN A 198.51.9.10\nmonitor6 IN AAAA 2001:db8::6d\ncommon-txt IN TXT \"include-group-9\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11'),
(159,'common-include-10.inc.local','includes/common-include-10.inc',NULL,'; Include file for common records group 10\nmonitor IN A 198.51.10.10\nmonitor6 IN AAAA 2001:db8::6e\ncommon-txt IN TXT \"include-group-10\"\n','include','active',1,NULL,'2025-10-23 07:34:11','2025-10-23 07:34:11');
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

-- Dump completed on 2025-10-24 16:05:07
