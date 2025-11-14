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
) ENGINE=InnoDB AUTO_INCREMENT=3007 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(2007,191,'AAAA','host1','2001:db8::79b2',NULL,'2001:db8::79b2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2008,166,'TXT','txt2','test-txt-2',NULL,NULL,NULL,NULL,'test-txt-2',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2009,195,'A','host3','198.51.84.130','198.51.84.130',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2010,160,'PTR','ptr4','ptr4.in-addr.arpa.',NULL,NULL,NULL,'ptr4.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2011,168,'A','host5','198.51.157.95','198.51.157.95',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2012,197,'A','host6','198.51.238.138','198.51.238.138',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2013,200,'A','host7','198.51.179.94','198.51.179.94',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2014,191,'PTR','ptr8','ptr8.in-addr.arpa.',NULL,NULL,NULL,'ptr8.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2015,204,'AAAA','host9','2001:db8::69bf',NULL,'2001:db8::69bf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2016,182,'AAAA','host10','2001:db8::c15e',NULL,'2001:db8::c15e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2017,189,'TXT','txt11','test-txt-11',NULL,NULL,NULL,NULL,'test-txt-11',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2018,195,'AAAA','host12','2001:db8::2a84',NULL,'2001:db8::2a84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2019,171,'AAAA','host13','2001:db8::eefe',NULL,'2001:db8::eefe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2020,169,'TXT','txt14','test-txt-14',NULL,NULL,NULL,NULL,'test-txt-14',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2021,205,'A','host15','198.51.107.77','198.51.107.77',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2022,182,'AAAA','host16','2001:db8::9724',NULL,'2001:db8::9724',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2023,176,'A','host17','198.51.251.248','198.51.251.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2024,186,'TXT','txt18','test-txt-18',NULL,NULL,NULL,NULL,'test-txt-18',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2025,205,'PTR','ptr19','ptr19.in-addr.arpa.',NULL,NULL,NULL,'ptr19.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2026,195,'TXT','txt20','test-txt-20',NULL,NULL,NULL,NULL,'test-txt-20',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2027,180,'PTR','ptr21','ptr21.in-addr.arpa.',NULL,NULL,NULL,'ptr21.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2028,189,'AAAA','host22','2001:db8::cdc2',NULL,'2001:db8::cdc2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2029,191,'CNAME','cname23','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2030,163,'A','host24','198.51.238.47','198.51.238.47',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2031,164,'TXT','txt25','test-txt-25',NULL,NULL,NULL,NULL,'test-txt-25',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2032,206,'AAAA','host26','2001:db8::435f',NULL,'2001:db8::435f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2033,202,'A','host27','198.51.147.240','198.51.147.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2034,161,'CNAME','cname28','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2035,195,'AAAA','host29','2001:db8::12ec',NULL,'2001:db8::12ec',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2036,164,'CNAME','cname30','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2037,193,'TXT','txt31','test-txt-31',NULL,NULL,NULL,NULL,'test-txt-31',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2038,189,'PTR','ptr32','ptr32.in-addr.arpa.',NULL,NULL,NULL,'ptr32.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2039,206,'CNAME','cname33','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2040,188,'AAAA','host34','2001:db8::a8c2',NULL,'2001:db8::a8c2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2041,160,'AAAA','host35','2001:db8::90d7',NULL,'2001:db8::90d7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2042,209,'PTR','ptr36','ptr36.in-addr.arpa.',NULL,NULL,NULL,'ptr36.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2043,208,'CNAME','cname37','test-master-35.local.',NULL,NULL,'test-master-35.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2044,162,'PTR','ptr38','ptr38.in-addr.arpa.',NULL,NULL,NULL,'ptr38.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2045,201,'TXT','txt39','test-txt-39',NULL,NULL,NULL,NULL,'test-txt-39',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2046,206,'CNAME','cname40','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2047,163,'TXT','txt41','test-txt-41',NULL,NULL,NULL,NULL,'test-txt-41',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2048,174,'AAAA','host42','2001:db8::eb3f',NULL,'2001:db8::eb3f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2049,191,'PTR','ptr43','ptr43.in-addr.arpa.',NULL,NULL,NULL,'ptr43.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2050,191,'A','host44','198.51.166.148','198.51.166.148',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2051,190,'A','host45','198.51.56.46','198.51.56.46',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2052,173,'A','host46','198.51.238.134','198.51.238.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2053,208,'TXT','txt47','test-txt-47',NULL,NULL,NULL,NULL,'test-txt-47',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2054,169,'TXT','txt48','test-txt-48',NULL,NULL,NULL,NULL,'test-txt-48',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2055,162,'TXT','txt49','test-txt-49',NULL,NULL,NULL,NULL,'test-txt-49',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2056,167,'A','host50','198.51.105.237','198.51.105.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2057,203,'A','host51','198.51.11.179','198.51.11.179',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2058,203,'PTR','ptr52','ptr52.in-addr.arpa.',NULL,NULL,NULL,'ptr52.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2059,206,'TXT','txt53','test-txt-53',NULL,NULL,NULL,NULL,'test-txt-53',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2060,204,'TXT','txt54','test-txt-54',NULL,NULL,NULL,NULL,'test-txt-54',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2061,188,'CNAME','cname55','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2062,185,'PTR','ptr56','ptr56.in-addr.arpa.',NULL,NULL,NULL,'ptr56.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2063,202,'CNAME','cname57','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2064,203,'PTR','ptr58','ptr58.in-addr.arpa.',NULL,NULL,NULL,'ptr58.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2065,179,'PTR','ptr59','ptr59.in-addr.arpa.',NULL,NULL,NULL,'ptr59.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2066,197,'PTR','ptr60','ptr60.in-addr.arpa.',NULL,NULL,NULL,'ptr60.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2067,201,'TXT','txt61','test-txt-61',NULL,NULL,NULL,NULL,'test-txt-61',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2068,183,'TXT','txt62','test-txt-62',NULL,NULL,NULL,NULL,'test-txt-62',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2069,162,'A','host63','198.51.61.137','198.51.61.137',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2070,163,'TXT','txt64','test-txt-64',NULL,NULL,NULL,NULL,'test-txt-64',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2071,173,'PTR','ptr65','ptr65.in-addr.arpa.',NULL,NULL,NULL,'ptr65.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2072,172,'AAAA','host66','2001:db8::bb9f',NULL,'2001:db8::bb9f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2073,189,'AAAA','host67','2001:db8::6797',NULL,'2001:db8::6797',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2074,198,'A','host68','198.51.236.186','198.51.236.186',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2075,179,'AAAA','host69','2001:db8::7a55',NULL,'2001:db8::7a55',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2076,188,'A','host70','198.51.206.40','198.51.206.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2077,180,'PTR','ptr71','ptr71.in-addr.arpa.',NULL,NULL,NULL,'ptr71.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2078,189,'AAAA','host72','2001:db8::2962',NULL,'2001:db8::2962',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2079,182,'CNAME','cname73','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2080,167,'PTR','ptr74','ptr74.in-addr.arpa.',NULL,NULL,NULL,'ptr74.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2081,190,'AAAA','host75','2001:db8::443e',NULL,'2001:db8::443e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2082,161,'PTR','ptr76','ptr76.in-addr.arpa.',NULL,NULL,NULL,'ptr76.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2083,173,'PTR','ptr77','ptr77.in-addr.arpa.',NULL,NULL,NULL,'ptr77.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2084,202,'A','host78','198.51.58.69','198.51.58.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2085,208,'TXT','txt79','test-txt-79',NULL,NULL,NULL,NULL,'test-txt-79',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2086,204,'A','host80','198.51.11.205','198.51.11.205',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2087,167,'AAAA','host81','2001:db8::5ebf',NULL,'2001:db8::5ebf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2088,199,'AAAA','host82','2001:db8::5216',NULL,'2001:db8::5216',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2089,208,'PTR','ptr83','ptr83.in-addr.arpa.',NULL,NULL,NULL,'ptr83.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2090,163,'AAAA','host84','2001:db8::b1f2',NULL,'2001:db8::b1f2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2091,202,'AAAA','host85','2001:db8::624c',NULL,'2001:db8::624c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2092,166,'A','host86','198.51.205.101','198.51.205.101',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2093,166,'AAAA','host87','2001:db8::a1a9',NULL,'2001:db8::a1a9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2094,172,'A','host88','198.51.204.171','198.51.204.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2095,206,'AAAA','host89','2001:db8::6827',NULL,'2001:db8::6827',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2096,184,'AAAA','host90','2001:db8::9c8',NULL,'2001:db8::9c8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2097,162,'TXT','txt91','test-txt-91',NULL,NULL,NULL,NULL,'test-txt-91',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2098,166,'PTR','ptr92','ptr92.in-addr.arpa.',NULL,NULL,NULL,'ptr92.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2099,207,'PTR','ptr93','ptr93.in-addr.arpa.',NULL,NULL,NULL,'ptr93.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2100,200,'TXT','txt94','test-txt-94',NULL,NULL,NULL,NULL,'test-txt-94',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2101,180,'A','host95','198.51.248.17','198.51.248.17',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2102,165,'CNAME','cname96','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2103,181,'AAAA','host97','2001:db8::6cfc',NULL,'2001:db8::6cfc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2104,169,'AAAA','host98','2001:db8::9d3b',NULL,'2001:db8::9d3b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2105,167,'AAAA','host99','2001:db8::791c',NULL,'2001:db8::791c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2106,180,'TXT','txt100','test-txt-100',NULL,NULL,NULL,NULL,'test-txt-100',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2107,181,'PTR','ptr101','ptr101.in-addr.arpa.',NULL,NULL,NULL,'ptr101.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2108,189,'AAAA','host102','2001:db8::b947',NULL,'2001:db8::b947',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2109,205,'PTR','ptr103','ptr103.in-addr.arpa.',NULL,NULL,NULL,'ptr103.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2110,195,'AAAA','host104','2001:db8::a90a',NULL,'2001:db8::a90a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2111,186,'A','host105','198.51.151.34','198.51.151.34',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2112,186,'CNAME','cname106','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2113,166,'TXT','txt107','test-txt-107',NULL,NULL,NULL,NULL,'test-txt-107',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2114,184,'AAAA','host108','2001:db8::fada',NULL,'2001:db8::fada',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2115,168,'PTR','ptr109','ptr109.in-addr.arpa.',NULL,NULL,NULL,'ptr109.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2116,172,'AAAA','host110','2001:db8::2abb',NULL,'2001:db8::2abb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2117,205,'TXT','txt111','test-txt-111',NULL,NULL,NULL,NULL,'test-txt-111',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2118,167,'AAAA','host112','2001:db8::6bf1',NULL,'2001:db8::6bf1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2119,205,'TXT','txt113','test-txt-113',NULL,NULL,NULL,NULL,'test-txt-113',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2120,181,'PTR','ptr114','ptr114.in-addr.arpa.',NULL,NULL,NULL,'ptr114.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2121,163,'TXT','txt115','test-txt-115',NULL,NULL,NULL,NULL,'test-txt-115',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2122,204,'A','host116','198.51.47.137','198.51.47.137',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2123,203,'TXT','txt117','test-txt-117',NULL,NULL,NULL,NULL,'test-txt-117',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2124,179,'TXT','txt118','test-txt-118',NULL,NULL,NULL,NULL,'test-txt-118',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2125,201,'AAAA','host119','2001:db8::3faf',NULL,'2001:db8::3faf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2126,188,'PTR','ptr120','ptr120.in-addr.arpa.',NULL,NULL,NULL,'ptr120.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2127,171,'CNAME','cname121','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2128,181,'PTR','ptr122','ptr122.in-addr.arpa.',NULL,NULL,NULL,'ptr122.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2129,200,'PTR','ptr123','ptr123.in-addr.arpa.',NULL,NULL,NULL,'ptr123.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2130,193,'TXT','txt124','test-txt-124',NULL,NULL,NULL,NULL,'test-txt-124',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2131,186,'CNAME','cname125','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2132,185,'AAAA','host126','2001:db8::b349',NULL,'2001:db8::b349',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2133,173,'PTR','ptr127','ptr127.in-addr.arpa.',NULL,NULL,NULL,'ptr127.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2134,201,'TXT','txt128','test-txt-128',NULL,NULL,NULL,NULL,'test-txt-128',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2135,209,'AAAA','host129','2001:db8::1a6c',NULL,'2001:db8::1a6c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2136,207,'CNAME','cname130','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2137,199,'CNAME','cname131','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2138,164,'AAAA','host132','2001:db8::9012',NULL,'2001:db8::9012',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2139,171,'AAAA','host133','2001:db8::f973',NULL,'2001:db8::f973',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2140,173,'PTR','ptr134','ptr134.in-addr.arpa.',NULL,NULL,NULL,'ptr134.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2141,193,'CNAME','cname135','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2142,192,'PTR','ptr136','ptr136.in-addr.arpa.',NULL,NULL,NULL,'ptr136.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2143,198,'TXT','txt137','test-txt-137',NULL,NULL,NULL,NULL,'test-txt-137',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2144,182,'PTR','ptr138','ptr138.in-addr.arpa.',NULL,NULL,NULL,'ptr138.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2145,185,'A','host139','198.51.151.52','198.51.151.52',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2146,209,'CNAME','cname140','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2147,177,'AAAA','host141','2001:db8::7fc',NULL,'2001:db8::7fc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2148,186,'AAAA','host142','2001:db8::270b',NULL,'2001:db8::270b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2149,189,'CNAME','cname143','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2150,206,'TXT','txt144','test-txt-144',NULL,NULL,NULL,NULL,'test-txt-144',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2151,207,'CNAME','cname145','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2152,175,'CNAME','cname146','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2153,173,'TXT','txt147','test-txt-147',NULL,NULL,NULL,NULL,'test-txt-147',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2154,194,'A','host148','198.51.114.245','198.51.114.245',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2155,166,'PTR','ptr149','ptr149.in-addr.arpa.',NULL,NULL,NULL,'ptr149.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2156,209,'CNAME','cname150','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2157,166,'PTR','ptr151','ptr151.in-addr.arpa.',NULL,NULL,NULL,'ptr151.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2158,195,'PTR','ptr152','ptr152.in-addr.arpa.',NULL,NULL,NULL,'ptr152.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2159,185,'AAAA','host153','2001:db8::290a',NULL,'2001:db8::290a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2160,162,'A','host154','198.51.170.219','198.51.170.219',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2161,181,'AAAA','host155','2001:db8::a586',NULL,'2001:db8::a586',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2162,176,'A','host156','198.51.124.141','198.51.124.141',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2163,203,'AAAA','host157','2001:db8::cd28',NULL,'2001:db8::cd28',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2164,197,'AAAA','host158','2001:db8::50ac',NULL,'2001:db8::50ac',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2165,165,'A','host159','198.51.25.7','198.51.25.7',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2166,169,'PTR','ptr160','ptr160.in-addr.arpa.',NULL,NULL,NULL,'ptr160.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2167,195,'A','host161','198.51.124.225','198.51.124.225',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2168,198,'PTR','ptr162','ptr162.in-addr.arpa.',NULL,NULL,NULL,'ptr162.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2169,161,'AAAA','host163','2001:db8::3577',NULL,'2001:db8::3577',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2170,178,'A','host164','198.51.0.13','198.51.0.13',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2171,197,'AAAA','host165','2001:db8::fce9',NULL,'2001:db8::fce9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2172,188,'AAAA','host166','2001:db8::7b71',NULL,'2001:db8::7b71',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2173,201,'TXT','txt167','test-txt-167',NULL,NULL,NULL,NULL,'test-txt-167',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2174,168,'CNAME','cname168','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2175,196,'TXT','txt169','test-txt-169',NULL,NULL,NULL,NULL,'test-txt-169',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2176,161,'TXT','txt170','test-txt-170',NULL,NULL,NULL,NULL,'test-txt-170',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2177,200,'A','host171','198.51.109.252','198.51.109.252',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2178,200,'AAAA','host172','2001:db8::7ac9',NULL,'2001:db8::7ac9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2179,206,'A','host173','198.51.240.37','198.51.240.37',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2180,175,'CNAME','cname174','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2181,189,'PTR','ptr175','ptr175.in-addr.arpa.',NULL,NULL,NULL,'ptr175.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2182,184,'A','host176','198.51.186.125','198.51.186.125',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2183,164,'CNAME','cname177','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2184,205,'TXT','txt178','test-txt-178',NULL,NULL,NULL,NULL,'test-txt-178',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2185,179,'AAAA','host179','2001:db8::1c0f',NULL,'2001:db8::1c0f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2186,209,'TXT','txt180','test-txt-180',NULL,NULL,NULL,NULL,'test-txt-180',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2187,196,'TXT','txt181','test-txt-181',NULL,NULL,NULL,NULL,'test-txt-181',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2188,199,'A','host182','198.51.118.244','198.51.118.244',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2189,171,'TXT','txt183','test-txt-183',NULL,NULL,NULL,NULL,'test-txt-183',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2190,194,'CNAME','cname184','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2191,205,'CNAME','cname185','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2192,205,'CNAME','cname186','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2193,207,'TXT','txt187','test-txt-187',NULL,NULL,NULL,NULL,'test-txt-187',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2194,205,'PTR','ptr188','ptr188.in-addr.arpa.',NULL,NULL,NULL,'ptr188.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2195,203,'TXT','txt189','test-txt-189',NULL,NULL,NULL,NULL,'test-txt-189',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2196,162,'A','host190','198.51.165.92','198.51.165.92',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2197,188,'A','host191','198.51.200.149','198.51.200.149',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2198,168,'PTR','ptr192','ptr192.in-addr.arpa.',NULL,NULL,NULL,'ptr192.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2199,170,'A','host193','198.51.72.137','198.51.72.137',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2200,171,'PTR','ptr194','ptr194.in-addr.arpa.',NULL,NULL,NULL,'ptr194.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2201,180,'PTR','ptr195','ptr195.in-addr.arpa.',NULL,NULL,NULL,'ptr195.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2202,193,'AAAA','host196','2001:db8::f489',NULL,'2001:db8::f489',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2203,175,'PTR','ptr197','ptr197.in-addr.arpa.',NULL,NULL,NULL,'ptr197.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2204,202,'PTR','ptr198','ptr198.in-addr.arpa.',NULL,NULL,NULL,'ptr198.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2205,175,'A','host199','198.51.144.148','198.51.144.148',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2206,209,'AAAA','host200','2001:db8::9548',NULL,'2001:db8::9548',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2207,202,'TXT','txt201','test-txt-201',NULL,NULL,NULL,NULL,'test-txt-201',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2208,169,'A','host202','198.51.38.9','198.51.38.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2209,182,'PTR','ptr203','ptr203.in-addr.arpa.',NULL,NULL,NULL,'ptr203.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2210,181,'A','host204','198.51.182.85','198.51.182.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2211,162,'AAAA','host205','2001:db8::56ee',NULL,'2001:db8::56ee',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2212,203,'A','host206','198.51.156.11','198.51.156.11',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2213,173,'AAAA','host207','2001:db8::fd18',NULL,'2001:db8::fd18',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2214,178,'PTR','ptr208','ptr208.in-addr.arpa.',NULL,NULL,NULL,'ptr208.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2215,161,'AAAA','host209','2001:db8::4b46',NULL,'2001:db8::4b46',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2216,184,'PTR','ptr210','ptr210.in-addr.arpa.',NULL,NULL,NULL,'ptr210.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2217,204,'TXT','txt211','test-txt-211',NULL,NULL,NULL,NULL,'test-txt-211',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2218,207,'TXT','txt212','test-txt-212',NULL,NULL,NULL,NULL,'test-txt-212',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2219,167,'PTR','ptr213','ptr213.in-addr.arpa.',NULL,NULL,NULL,'ptr213.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2220,209,'PTR','ptr214','ptr214.in-addr.arpa.',NULL,NULL,NULL,'ptr214.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2221,207,'PTR','ptr215','ptr215.in-addr.arpa.',NULL,NULL,NULL,'ptr215.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2222,174,'CNAME','cname216','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2223,197,'AAAA','host217','2001:db8::618e',NULL,'2001:db8::618e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2224,206,'CNAME','cname218','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2225,200,'CNAME','cname219','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2226,200,'CNAME','cname220','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2227,171,'AAAA','host221','2001:db8::8a6c',NULL,'2001:db8::8a6c',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2228,204,'TXT','txt222','test-txt-222',NULL,NULL,NULL,NULL,'test-txt-222',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2229,163,'PTR','ptr223','ptr223.in-addr.arpa.',NULL,NULL,NULL,'ptr223.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2230,205,'TXT','txt224','test-txt-224',NULL,NULL,NULL,NULL,'test-txt-224',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2231,202,'CNAME','cname225','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2232,161,'PTR','ptr226','ptr226.in-addr.arpa.',NULL,NULL,NULL,'ptr226.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2233,199,'A','host227','198.51.84.34','198.51.84.34',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2234,181,'CNAME','cname228','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2235,166,'A','host229','198.51.173.85','198.51.173.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2236,208,'CNAME','cname230','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2237,163,'CNAME','cname231','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2238,192,'A','host232','198.51.71.240','198.51.71.240',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2239,167,'TXT','txt233','test-txt-233',NULL,NULL,NULL,NULL,'test-txt-233',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2240,167,'PTR','ptr234','ptr234.in-addr.arpa.',NULL,NULL,NULL,'ptr234.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2241,161,'AAAA','host235','2001:db8::437',NULL,'2001:db8::437',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2242,170,'TXT','txt236','test-txt-236',NULL,NULL,NULL,NULL,'test-txt-236',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2243,203,'PTR','ptr237','ptr237.in-addr.arpa.',NULL,NULL,NULL,'ptr237.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2244,204,'CNAME','cname238','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2245,189,'PTR','ptr239','ptr239.in-addr.arpa.',NULL,NULL,NULL,'ptr239.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2246,209,'PTR','ptr240','ptr240.in-addr.arpa.',NULL,NULL,NULL,'ptr240.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2247,202,'PTR','ptr241','ptr241.in-addr.arpa.',NULL,NULL,NULL,'ptr241.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2248,207,'CNAME','cname242','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2249,186,'PTR','ptr243','ptr243.in-addr.arpa.',NULL,NULL,NULL,'ptr243.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2250,209,'PTR','ptr244','ptr244.in-addr.arpa.',NULL,NULL,NULL,'ptr244.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2251,203,'PTR','ptr245','ptr245.in-addr.arpa.',NULL,NULL,NULL,'ptr245.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2252,208,'CNAME','cname246','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2253,206,'CNAME','cname247','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2254,208,'TXT','txt248','test-txt-248',NULL,NULL,NULL,NULL,'test-txt-248',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2255,204,'CNAME','cname249','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2256,162,'AAAA','host250','2001:db8::610a',NULL,'2001:db8::610a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2257,205,'PTR','ptr251','ptr251.in-addr.arpa.',NULL,NULL,NULL,'ptr251.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2258,173,'A','host252','198.51.197.43','198.51.197.43',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2259,163,'AAAA','host253','2001:db8::a00',NULL,'2001:db8::a00',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2260,192,'CNAME','cname254','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2261,205,'CNAME','cname255','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2262,172,'CNAME','cname256','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2263,162,'AAAA','host257','2001:db8::5d84',NULL,'2001:db8::5d84',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2264,175,'CNAME','cname258','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2265,172,'PTR','ptr259','ptr259.in-addr.arpa.',NULL,NULL,NULL,'ptr259.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2266,184,'TXT','txt260','test-txt-260',NULL,NULL,NULL,NULL,'test-txt-260',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2267,160,'A','host261','198.51.157.41','198.51.157.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2268,180,'PTR','ptr262','ptr262.in-addr.arpa.',NULL,NULL,NULL,'ptr262.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2269,192,'PTR','ptr263','ptr263.in-addr.arpa.',NULL,NULL,NULL,'ptr263.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2270,173,'A','host264','198.51.157.61','198.51.157.61',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2271,186,'TXT','txt265','test-txt-265',NULL,NULL,NULL,NULL,'test-txt-265',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2272,162,'PTR','ptr266','ptr266.in-addr.arpa.',NULL,NULL,NULL,'ptr266.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2273,187,'AAAA','host267','2001:db8::c104',NULL,'2001:db8::c104',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2274,209,'A','host268','198.51.168.23','198.51.168.23',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2275,200,'A','host269','198.51.99.162','198.51.99.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2276,172,'A','host270','198.51.254.3','198.51.254.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2277,160,'TXT','txt271','test-txt-271',NULL,NULL,NULL,NULL,'test-txt-271',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2278,178,'A','host272','198.51.94.27','198.51.94.27',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2279,202,'PTR','ptr273','ptr273.in-addr.arpa.',NULL,NULL,NULL,'ptr273.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2280,204,'AAAA','host274','2001:db8::1b8d',NULL,'2001:db8::1b8d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2281,171,'A','host275','198.51.231.46','198.51.231.46',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2282,209,'PTR','ptr276','ptr276.in-addr.arpa.',NULL,NULL,NULL,'ptr276.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2283,182,'A','host277','198.51.165.242','198.51.165.242',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2284,195,'AAAA','host278','2001:db8::2815',NULL,'2001:db8::2815',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2285,162,'PTR','ptr279','ptr279.in-addr.arpa.',NULL,NULL,NULL,'ptr279.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2286,198,'PTR','ptr280','ptr280.in-addr.arpa.',NULL,NULL,NULL,'ptr280.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2287,184,'AAAA','host281','2001:db8::f0c9',NULL,'2001:db8::f0c9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2288,180,'CNAME','cname282','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2289,174,'PTR','ptr283','ptr283.in-addr.arpa.',NULL,NULL,NULL,'ptr283.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2290,166,'A','host284','198.51.135.101','198.51.135.101',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2291,197,'A','host285','198.51.141.87','198.51.141.87',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2292,181,'CNAME','cname286','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2293,182,'TXT','txt287','test-txt-287',NULL,NULL,NULL,NULL,'test-txt-287',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2294,185,'CNAME','cname288','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2295,207,'A','host289','198.51.12.139','198.51.12.139',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2296,201,'A','host290','198.51.179.44','198.51.179.44',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2297,170,'AAAA','host291','2001:db8::b61e',NULL,'2001:db8::b61e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2298,199,'TXT','txt292','test-txt-292',NULL,NULL,NULL,NULL,'test-txt-292',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2299,168,'TXT','txt293','test-txt-293',NULL,NULL,NULL,NULL,'test-txt-293',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2300,183,'AAAA','host294','2001:db8::febd',NULL,'2001:db8::febd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2301,207,'CNAME','cname295','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2302,182,'PTR','ptr296','ptr296.in-addr.arpa.',NULL,NULL,NULL,'ptr296.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2303,202,'PTR','ptr297','ptr297.in-addr.arpa.',NULL,NULL,NULL,'ptr297.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2304,200,'AAAA','host298','2001:db8::faec',NULL,'2001:db8::faec',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2305,209,'CNAME','cname299','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2306,196,'AAAA','host300','2001:db8::5015',NULL,'2001:db8::5015',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2307,186,'AAAA','host301','2001:db8::b9b8',NULL,'2001:db8::b9b8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2308,193,'A','host302','198.51.8.2','198.51.8.2',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2309,184,'TXT','txt303','test-txt-303',NULL,NULL,NULL,NULL,'test-txt-303',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2310,209,'TXT','txt304','test-txt-304',NULL,NULL,NULL,NULL,'test-txt-304',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2311,193,'CNAME','cname305','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2312,199,'A','host306','198.51.173.113','198.51.173.113',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2313,169,'A','host307','198.51.155.147','198.51.155.147',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2314,192,'AAAA','host308','2001:db8::4729',NULL,'2001:db8::4729',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2315,171,'AAAA','host309','2001:db8::2f30',NULL,'2001:db8::2f30',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2316,204,'CNAME','cname310','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2317,203,'AAAA','host311','2001:db8::76',NULL,'2001:db8::76',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2318,162,'AAAA','host312','2001:db8::7503',NULL,'2001:db8::7503',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2319,190,'TXT','txt313','test-txt-313',NULL,NULL,NULL,NULL,'test-txt-313',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2320,176,'A','host314','198.51.144.160','198.51.144.160',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2321,173,'TXT','txt315','test-txt-315',NULL,NULL,NULL,NULL,'test-txt-315',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2322,178,'PTR','ptr316','ptr316.in-addr.arpa.',NULL,NULL,NULL,'ptr316.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2323,182,'AAAA','host317','2001:db8::13b3',NULL,'2001:db8::13b3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2324,160,'A','host318','198.51.210.154','198.51.210.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2325,187,'CNAME','cname319','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2326,161,'A','host320','198.51.139.149','198.51.139.149',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2327,194,'CNAME','cname321','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2328,162,'AAAA','host322','2001:db8::d0cc',NULL,'2001:db8::d0cc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2329,205,'PTR','ptr323','ptr323.in-addr.arpa.',NULL,NULL,NULL,'ptr323.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2330,203,'CNAME','cname324','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2331,174,'AAAA','host325','2001:db8::58cf',NULL,'2001:db8::58cf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2332,197,'PTR','ptr326','ptr326.in-addr.arpa.',NULL,NULL,NULL,'ptr326.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2333,198,'CNAME','cname327','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2334,194,'CNAME','cname328','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2335,208,'AAAA','host329','2001:db8::37bc',NULL,'2001:db8::37bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2336,189,'TXT','txt330','test-txt-330',NULL,NULL,NULL,NULL,'test-txt-330',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2337,204,'PTR','ptr331','ptr331.in-addr.arpa.',NULL,NULL,NULL,'ptr331.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2338,173,'CNAME','cname332','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2339,170,'A','host333','198.51.110.165','198.51.110.165',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2340,204,'AAAA','host334','2001:db8::22e5',NULL,'2001:db8::22e5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2341,167,'A','host335','198.51.67.79','198.51.67.79',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2342,184,'CNAME','cname336','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2343,171,'TXT','txt337','test-txt-337',NULL,NULL,NULL,NULL,'test-txt-337',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2344,187,'A','host338','198.51.240.246','198.51.240.246',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2345,208,'AAAA','host339','2001:db8::1053',NULL,'2001:db8::1053',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2346,204,'TXT','txt340','test-txt-340',NULL,NULL,NULL,NULL,'test-txt-340',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2347,199,'CNAME','cname341','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2348,179,'CNAME','cname342','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2349,185,'CNAME','cname343','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2350,175,'CNAME','cname344','test-master-14.local.',NULL,NULL,'test-master-14.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2351,163,'PTR','ptr345','ptr345.in-addr.arpa.',NULL,NULL,NULL,'ptr345.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2352,201,'AAAA','host346','2001:db8::ecad',NULL,'2001:db8::ecad',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2353,190,'CNAME','cname347','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2354,171,'PTR','ptr348','ptr348.in-addr.arpa.',NULL,NULL,NULL,'ptr348.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2355,180,'TXT','txt349','test-txt-349',NULL,NULL,NULL,NULL,'test-txt-349',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2356,203,'CNAME','cname350','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2357,184,'CNAME','cname351','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2358,208,'TXT','txt352','test-txt-352',NULL,NULL,NULL,NULL,'test-txt-352',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2359,182,'CNAME','cname353','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2360,164,'PTR','ptr354','ptr354.in-addr.arpa.',NULL,NULL,NULL,'ptr354.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2361,164,'CNAME','cname355','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2362,192,'CNAME','cname356','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2363,172,'CNAME','cname357','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2364,199,'A','host358','198.51.149.241','198.51.149.241',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2365,205,'PTR','ptr359','ptr359.in-addr.arpa.',NULL,NULL,NULL,'ptr359.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2366,209,'AAAA','host360','2001:db8::56e6',NULL,'2001:db8::56e6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2367,193,'A','host361','198.51.176.136','198.51.176.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2368,185,'A','host362','198.51.1.154','198.51.1.154',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2369,160,'AAAA','host363','2001:db8::6b6d',NULL,'2001:db8::6b6d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2370,190,'PTR','ptr364','ptr364.in-addr.arpa.',NULL,NULL,NULL,'ptr364.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2371,203,'PTR','ptr365','ptr365.in-addr.arpa.',NULL,NULL,NULL,'ptr365.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2372,174,'TXT','txt366','test-txt-366',NULL,NULL,NULL,NULL,'test-txt-366',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2373,209,'PTR','ptr367','ptr367.in-addr.arpa.',NULL,NULL,NULL,'ptr367.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2374,189,'AAAA','host368','2001:db8::27cc',NULL,'2001:db8::27cc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2375,193,'TXT','txt369','test-txt-369',NULL,NULL,NULL,NULL,'test-txt-369',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2376,163,'TXT','txt370','test-txt-370',NULL,NULL,NULL,NULL,'test-txt-370',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2377,209,'CNAME','cname371','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2378,187,'CNAME','cname372','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2379,171,'A','host373','198.51.77.45','198.51.77.45',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2380,188,'CNAME','cname374','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2381,176,'A','host375','198.51.249.72','198.51.249.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2382,196,'TXT','txt376','test-txt-376',NULL,NULL,NULL,NULL,'test-txt-376',3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2383,192,'AAAA','host377','2001:db8::b716',NULL,'2001:db8::b716',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2384,171,'A','host378','198.51.5.239','198.51.5.239',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2385,163,'A','host379','198.51.80.8','198.51.80.8',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2386,189,'PTR','ptr380','ptr380.in-addr.arpa.',NULL,NULL,NULL,'ptr380.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2387,207,'PTR','ptr381','ptr381.in-addr.arpa.',NULL,NULL,NULL,'ptr381.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2388,192,'PTR','ptr382','ptr382.in-addr.arpa.',NULL,NULL,NULL,'ptr382.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2389,186,'PTR','ptr383','ptr383.in-addr.arpa.',NULL,NULL,NULL,'ptr383.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:39',NULL,'2025-10-24 12:10:39',NULL,NULL,NULL,NULL),
(2390,184,'A','host384','198.51.48.237','198.51.48.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2391,187,'CNAME','cname385','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2392,170,'TXT','txt386','test-txt-386',NULL,NULL,NULL,NULL,'test-txt-386',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2393,194,'PTR','ptr387','ptr387.in-addr.arpa.',NULL,NULL,NULL,'ptr387.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2394,199,'PTR','ptr388','ptr388.in-addr.arpa.',NULL,NULL,NULL,'ptr388.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2395,166,'AAAA','host389','2001:db8::11f6',NULL,'2001:db8::11f6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2396,200,'AAAA','host390','2001:db8::22d1',NULL,'2001:db8::22d1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2397,163,'TXT','txt391','test-txt-391',NULL,NULL,NULL,NULL,'test-txt-391',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2398,206,'TXT','txt392','test-txt-392',NULL,NULL,NULL,NULL,'test-txt-392',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2399,193,'CNAME','cname393','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2400,193,'A','host394','198.51.156.218','198.51.156.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2401,188,'A','host395','198.51.117.220','198.51.117.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2402,169,'AAAA','host396','2001:db8::93b5',NULL,'2001:db8::93b5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2403,207,'TXT','txt397','test-txt-397',NULL,NULL,NULL,NULL,'test-txt-397',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2404,202,'TXT','txt398','test-txt-398',NULL,NULL,NULL,NULL,'test-txt-398',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2405,183,'A','host399','198.51.87.91','198.51.87.91',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2406,188,'TXT','txt400','test-txt-400',NULL,NULL,NULL,NULL,'test-txt-400',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2407,209,'A','host401','198.51.46.185','198.51.46.185',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2408,203,'PTR','ptr402','ptr402.in-addr.arpa.',NULL,NULL,NULL,'ptr402.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2409,204,'CNAME','cname403','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2410,179,'CNAME','cname404','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2411,190,'A','host405','198.51.192.108','198.51.192.108',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2412,172,'AAAA','host406','2001:db8::7782',NULL,'2001:db8::7782',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2413,204,'TXT','txt407','test-txt-407',NULL,NULL,NULL,NULL,'test-txt-407',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2414,181,'AAAA','host408','2001:db8::d2df',NULL,'2001:db8::d2df',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2415,190,'A','host409','198.51.90.114','198.51.90.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2416,207,'AAAA','host410','2001:db8::b8b4',NULL,'2001:db8::b8b4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2417,193,'CNAME','cname411','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2418,208,'CNAME','cname412','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2419,164,'PTR','ptr413','ptr413.in-addr.arpa.',NULL,NULL,NULL,'ptr413.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2420,185,'AAAA','host414','2001:db8::961',NULL,'2001:db8::961',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2421,174,'A','host415','198.51.233.6','198.51.233.6',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2422,208,'A','host416','198.51.245.47','198.51.245.47',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2423,204,'PTR','ptr417','ptr417.in-addr.arpa.',NULL,NULL,NULL,'ptr417.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2424,186,'TXT','txt418','test-txt-418',NULL,NULL,NULL,NULL,'test-txt-418',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2425,178,'A','host419','198.51.100.90','198.51.100.90',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2426,205,'A','host420','198.51.1.129','198.51.1.129',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2427,208,'CNAME','cname421','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2428,160,'CNAME','cname422','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2429,197,'CNAME','cname423','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2430,167,'A','host424','198.51.32.155','198.51.32.155',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2431,183,'TXT','txt425','test-txt-425',NULL,NULL,NULL,NULL,'test-txt-425',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2432,168,'AAAA','host426','2001:db8::b62e',NULL,'2001:db8::b62e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2433,166,'CNAME','cname427','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2434,202,'CNAME','cname428','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2435,166,'TXT','txt429','test-txt-429',NULL,NULL,NULL,NULL,'test-txt-429',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2436,208,'AAAA','host430','2001:db8::1771',NULL,'2001:db8::1771',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2437,173,'CNAME','cname431','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2438,177,'TXT','txt432','test-txt-432',NULL,NULL,NULL,NULL,'test-txt-432',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2439,175,'CNAME','cname433','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2440,166,'TXT','txt434','test-txt-434',NULL,NULL,NULL,NULL,'test-txt-434',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2441,196,'AAAA','host435','2001:db8::bcd2',NULL,'2001:db8::bcd2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2442,202,'A','host436','198.51.83.201','198.51.83.201',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2443,168,'TXT','txt437','test-txt-437',NULL,NULL,NULL,NULL,'test-txt-437',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2444,193,'CNAME','cname438','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2445,163,'TXT','txt439','test-txt-439',NULL,NULL,NULL,NULL,'test-txt-439',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2446,194,'CNAME','cname440','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2447,184,'A','host441','198.51.13.91','198.51.13.91',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2448,164,'TXT','txt442','test-txt-442',NULL,NULL,NULL,NULL,'test-txt-442',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2449,175,'AAAA','host443','2001:db8::3ce6',NULL,'2001:db8::3ce6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2450,179,'AAAA','host444','2001:db8::5083',NULL,'2001:db8::5083',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2451,189,'TXT','txt445','test-txt-445',NULL,NULL,NULL,NULL,'test-txt-445',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2452,170,'PTR','ptr446','ptr446.in-addr.arpa.',NULL,NULL,NULL,'ptr446.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2453,172,'PTR','ptr447','ptr447.in-addr.arpa.',NULL,NULL,NULL,'ptr447.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2454,167,'CNAME','cname448','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2455,190,'A','host449','198.51.61.249','198.51.61.249',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2456,166,'PTR','ptr450','ptr450.in-addr.arpa.',NULL,NULL,NULL,'ptr450.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2457,203,'PTR','ptr451','ptr451.in-addr.arpa.',NULL,NULL,NULL,'ptr451.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2458,185,'PTR','ptr452','ptr452.in-addr.arpa.',NULL,NULL,NULL,'ptr452.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2459,181,'A','host453','198.51.72.170','198.51.72.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2460,208,'PTR','ptr454','ptr454.in-addr.arpa.',NULL,NULL,NULL,'ptr454.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2461,164,'A','host455','198.51.166.9','198.51.166.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2462,203,'PTR','ptr456','ptr456.in-addr.arpa.',NULL,NULL,NULL,'ptr456.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2463,164,'PTR','ptr457','ptr457.in-addr.arpa.',NULL,NULL,NULL,'ptr457.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2464,169,'A','host458','198.51.219.141','198.51.219.141',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2465,194,'TXT','txt459','test-txt-459',NULL,NULL,NULL,NULL,'test-txt-459',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2466,207,'A','host460','198.51.30.184','198.51.30.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2467,162,'TXT','txt461','test-txt-461',NULL,NULL,NULL,NULL,'test-txt-461',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2468,205,'A','host462','198.51.56.18','198.51.56.18',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2469,209,'CNAME','cname463','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2470,202,'PTR','ptr464','ptr464.in-addr.arpa.',NULL,NULL,NULL,'ptr464.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2471,175,'PTR','ptr465','ptr465.in-addr.arpa.',NULL,NULL,NULL,'ptr465.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2472,190,'PTR','ptr466','ptr466.in-addr.arpa.',NULL,NULL,NULL,'ptr466.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2473,202,'AAAA','host467','2001:db8::7138',NULL,'2001:db8::7138',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2474,201,'CNAME','cname468','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2475,201,'AAAA','host469','2001:db8::5f97',NULL,'2001:db8::5f97',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2476,182,'PTR','ptr470','ptr470.in-addr.arpa.',NULL,NULL,NULL,'ptr470.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2477,202,'A','host471','198.51.145.62','198.51.145.62',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2478,206,'CNAME','cname472','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2479,196,'A','host473','198.51.92.162','198.51.92.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2480,167,'AAAA','host474','2001:db8::86b5',NULL,'2001:db8::86b5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2481,200,'A','host475','198.51.44.40','198.51.44.40',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2482,173,'TXT','txt476','test-txt-476',NULL,NULL,NULL,NULL,'test-txt-476',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2483,185,'AAAA','host477','2001:db8::1525',NULL,'2001:db8::1525',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2484,167,'AAAA','host478','2001:db8::42bc',NULL,'2001:db8::42bc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2485,189,'A','host479','198.51.227.59','198.51.227.59',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2486,170,'A','host480','198.51.55.72','198.51.55.72',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2487,206,'A','host481','198.51.201.215','198.51.201.215',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2488,204,'PTR','ptr482','ptr482.in-addr.arpa.',NULL,NULL,NULL,'ptr482.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2489,189,'PTR','ptr483','ptr483.in-addr.arpa.',NULL,NULL,NULL,'ptr483.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2490,209,'AAAA','host484','2001:db8::62f2',NULL,'2001:db8::62f2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2491,197,'CNAME','cname485','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2492,174,'PTR','ptr486','ptr486.in-addr.arpa.',NULL,NULL,NULL,'ptr486.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2493,198,'PTR','ptr487','ptr487.in-addr.arpa.',NULL,NULL,NULL,'ptr487.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2494,165,'CNAME','cname488','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2495,202,'CNAME','cname489','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2496,197,'A','host490','198.51.234.248','198.51.234.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2497,192,'AAAA','host491','2001:db8::d288',NULL,'2001:db8::d288',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2498,170,'PTR','ptr492','ptr492.in-addr.arpa.',NULL,NULL,NULL,'ptr492.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2499,189,'TXT','txt493','test-txt-493',NULL,NULL,NULL,NULL,'test-txt-493',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2500,199,'PTR','ptr494','ptr494.in-addr.arpa.',NULL,NULL,NULL,'ptr494.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2501,209,'PTR','ptr495','ptr495.in-addr.arpa.',NULL,NULL,NULL,'ptr495.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2502,203,'AAAA','host496','2001:db8::243f',NULL,'2001:db8::243f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2503,170,'AAAA','host497','2001:db8::a3c6',NULL,'2001:db8::a3c6',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2504,178,'A','host498','198.51.47.249','198.51.47.249',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2505,170,'A','host499','198.51.232.9','198.51.232.9',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2506,185,'AAAA','host500','2001:db8::f786',NULL,'2001:db8::f786',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2507,204,'PTR','ptr501','ptr501.in-addr.arpa.',NULL,NULL,NULL,'ptr501.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2508,188,'PTR','ptr502','ptr502.in-addr.arpa.',NULL,NULL,NULL,'ptr502.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2509,165,'PTR','ptr503','ptr503.in-addr.arpa.',NULL,NULL,NULL,'ptr503.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2510,176,'A','host504','198.51.242.171','198.51.242.171',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2511,177,'CNAME','cname505','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2512,204,'CNAME','cname506','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2513,187,'TXT','txt507','test-txt-507',NULL,NULL,NULL,NULL,'test-txt-507',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2514,194,'A','host508','198.51.153.76','198.51.153.76',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2515,195,'PTR','ptr509','ptr509.in-addr.arpa.',NULL,NULL,NULL,'ptr509.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2516,166,'CNAME','cname510','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2517,198,'PTR','ptr511','ptr511.in-addr.arpa.',NULL,NULL,NULL,'ptr511.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2518,180,'A','host512','198.51.156.193','198.51.156.193',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2519,165,'TXT','txt513','test-txt-513',NULL,NULL,NULL,NULL,'test-txt-513',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2520,208,'AAAA','host514','2001:db8::925b',NULL,'2001:db8::925b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2521,208,'AAAA','host515','2001:db8::aeb9',NULL,'2001:db8::aeb9',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2522,199,'AAAA','host516','2001:db8::a1c8',NULL,'2001:db8::a1c8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2523,206,'TXT','txt517','test-txt-517',NULL,NULL,NULL,NULL,'test-txt-517',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2524,182,'AAAA','host518','2001:db8::7cb4',NULL,'2001:db8::7cb4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2525,177,'CNAME','cname519','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2526,177,'CNAME','cname520','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2527,176,'A','host521','198.51.162.28','198.51.162.28',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2528,195,'A','host522','198.51.188.220','198.51.188.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2529,177,'A','host523','198.51.216.13','198.51.216.13',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2530,203,'AAAA','host524','2001:db8::21e3',NULL,'2001:db8::21e3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2531,165,'PTR','ptr525','ptr525.in-addr.arpa.',NULL,NULL,NULL,'ptr525.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2532,208,'TXT','txt526','test-txt-526',NULL,NULL,NULL,NULL,'test-txt-526',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2533,191,'PTR','ptr527','ptr527.in-addr.arpa.',NULL,NULL,NULL,'ptr527.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2534,202,'A','host528','198.51.3.184','198.51.3.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2535,203,'CNAME','cname529','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2536,160,'PTR','ptr530','ptr530.in-addr.arpa.',NULL,NULL,NULL,'ptr530.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2537,191,'CNAME','cname531','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2538,200,'TXT','txt532','test-txt-532',NULL,NULL,NULL,NULL,'test-txt-532',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2539,165,'A','host533','198.51.203.218','198.51.203.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2540,200,'PTR','ptr534','ptr534.in-addr.arpa.',NULL,NULL,NULL,'ptr534.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2541,186,'TXT','txt535','test-txt-535',NULL,NULL,NULL,NULL,'test-txt-535',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2542,208,'CNAME','cname536','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2543,194,'A','host537','198.51.12.169','198.51.12.169',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2544,198,'AAAA','host538','2001:db8::5ef3',NULL,'2001:db8::5ef3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2545,204,'A','host539','198.51.120.84','198.51.120.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2546,169,'AAAA','host540','2001:db8::eaf',NULL,'2001:db8::eaf',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2547,182,'A','host541','198.51.141.193','198.51.141.193',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2548,164,'CNAME','cname542','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2549,182,'A','host543','198.51.61.90','198.51.61.90',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2550,169,'CNAME','cname544','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2551,196,'A','host545','198.51.16.244','198.51.16.244',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2552,208,'CNAME','cname546','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2553,201,'TXT','txt547','test-txt-547',NULL,NULL,NULL,NULL,'test-txt-547',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2554,168,'CNAME','cname548','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2555,163,'TXT','txt549','test-txt-549',NULL,NULL,NULL,NULL,'test-txt-549',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2556,183,'PTR','ptr550','ptr550.in-addr.arpa.',NULL,NULL,NULL,'ptr550.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2557,176,'AAAA','host551','2001:db8::1a2e',NULL,'2001:db8::1a2e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2558,166,'PTR','ptr552','ptr552.in-addr.arpa.',NULL,NULL,NULL,'ptr552.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2559,161,'AAAA','host553','2001:db8::3140',NULL,'2001:db8::3140',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2560,193,'A','host554','198.51.197.87','198.51.197.87',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2561,165,'CNAME','cname555','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2562,166,'CNAME','cname556','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2563,190,'CNAME','cname557','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2564,161,'TXT','txt558','test-txt-558',NULL,NULL,NULL,NULL,'test-txt-558',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2565,177,'TXT','txt559','test-txt-559',NULL,NULL,NULL,NULL,'test-txt-559',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2566,203,'CNAME','cname560','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2567,202,'AAAA','host561','2001:db8::fd91',NULL,'2001:db8::fd91',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2568,192,'CNAME','cname562','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2569,209,'TXT','txt563','test-txt-563',NULL,NULL,NULL,NULL,'test-txt-563',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2570,166,'AAAA','host564','2001:db8::f74a',NULL,'2001:db8::f74a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2571,196,'PTR','ptr565','ptr565.in-addr.arpa.',NULL,NULL,NULL,'ptr565.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2572,208,'A','host566','198.51.10.81','198.51.10.81',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2573,172,'CNAME','cname567','test-master-21.local.',NULL,NULL,'test-master-21.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2574,197,'AAAA','host568','2001:db8::9b8',NULL,'2001:db8::9b8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2575,187,'CNAME','cname569','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2576,169,'CNAME','cname570','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2577,185,'A','host571','198.51.80.203','198.51.80.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2578,165,'TXT','txt572','test-txt-572',NULL,NULL,NULL,NULL,'test-txt-572',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2579,179,'TXT','txt573','test-txt-573',NULL,NULL,NULL,NULL,'test-txt-573',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2580,188,'TXT','txt574','test-txt-574',NULL,NULL,NULL,NULL,'test-txt-574',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2581,170,'AAAA','host575','2001:db8::bba8',NULL,'2001:db8::bba8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2582,181,'PTR','ptr576','ptr576.in-addr.arpa.',NULL,NULL,NULL,'ptr576.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2583,172,'PTR','ptr577','ptr577.in-addr.arpa.',NULL,NULL,NULL,'ptr577.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2584,208,'TXT','txt578','test-txt-578',NULL,NULL,NULL,NULL,'test-txt-578',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2585,203,'A','host579','198.51.113.52','198.51.113.52',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2586,202,'CNAME','cname580','test-master-39.local.',NULL,NULL,'test-master-39.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2587,188,'A','host581','198.51.100.229','198.51.100.229',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2588,197,'TXT','txt582','test-txt-582',NULL,NULL,NULL,NULL,'test-txt-582',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2589,208,'CNAME','cname583','test-master-17.local.',NULL,NULL,'test-master-17.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2590,207,'TXT','txt584','test-txt-584',NULL,NULL,NULL,NULL,'test-txt-584',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2591,166,'A','host585','198.51.43.219','198.51.43.219',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2592,167,'AAAA','host586','2001:db8::c5d0',NULL,'2001:db8::c5d0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2593,209,'AAAA','host587','2001:db8::7881',NULL,'2001:db8::7881',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2594,194,'TXT','txt588','test-txt-588',NULL,NULL,NULL,NULL,'test-txt-588',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2595,192,'TXT','txt589','test-txt-589',NULL,NULL,NULL,NULL,'test-txt-589',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2596,201,'AAAA','host590','2001:db8::4fe3',NULL,'2001:db8::4fe3',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2597,196,'TXT','txt591','test-txt-591',NULL,NULL,NULL,NULL,'test-txt-591',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2598,161,'PTR','ptr592','ptr592.in-addr.arpa.',NULL,NULL,NULL,'ptr592.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2599,203,'A','host593','198.51.182.109','198.51.182.109',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2600,194,'A','host594','198.51.103.230','198.51.103.230',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2601,180,'PTR','ptr595','ptr595.in-addr.arpa.',NULL,NULL,NULL,'ptr595.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2602,179,'CNAME','cname596','test-master-23.local.',NULL,NULL,'test-master-23.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2603,186,'TXT','txt597','test-txt-597',NULL,NULL,NULL,NULL,'test-txt-597',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2604,207,'TXT','txt598','test-txt-598',NULL,NULL,NULL,NULL,'test-txt-598',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2605,197,'AAAA','host599','2001:db8::ecc8',NULL,'2001:db8::ecc8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2606,161,'A','host600','198.51.61.74','198.51.61.74',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2607,194,'AAAA','host601','2001:db8::4bf4',NULL,'2001:db8::4bf4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2608,178,'A','host602','198.51.249.19','198.51.249.19',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2609,169,'AAAA','host603','2001:db8::6882',NULL,'2001:db8::6882',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2610,209,'PTR','ptr604','ptr604.in-addr.arpa.',NULL,NULL,NULL,'ptr604.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2611,193,'CNAME','cname605','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2612,207,'AAAA','host606','2001:db8::25be',NULL,'2001:db8::25be',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2613,168,'CNAME','cname607','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2614,165,'CNAME','cname608','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2615,160,'A','host609','198.51.67.207','198.51.67.207',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2616,174,'PTR','ptr610','ptr610.in-addr.arpa.',NULL,NULL,NULL,'ptr610.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2617,193,'A','host611','198.51.134.128','198.51.134.128',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2618,205,'A','host612','198.51.47.183','198.51.47.183',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2619,204,'PTR','ptr613','ptr613.in-addr.arpa.',NULL,NULL,NULL,'ptr613.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2620,195,'TXT','txt614','test-txt-614',NULL,NULL,NULL,NULL,'test-txt-614',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2621,201,'AAAA','host615','2001:db8::d6b0',NULL,'2001:db8::d6b0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2622,181,'CNAME','cname616','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2623,204,'TXT','txt617','test-txt-617',NULL,NULL,NULL,NULL,'test-txt-617',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2624,201,'TXT','txt618','test-txt-618',NULL,NULL,NULL,NULL,'test-txt-618',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2625,208,'PTR','ptr619','ptr619.in-addr.arpa.',NULL,NULL,NULL,'ptr619.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2626,202,'TXT','txt620','test-txt-620',NULL,NULL,NULL,NULL,'test-txt-620',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2627,178,'PTR','ptr621','ptr621.in-addr.arpa.',NULL,NULL,NULL,'ptr621.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2628,193,'CNAME','cname622','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2629,179,'PTR','ptr623','ptr623.in-addr.arpa.',NULL,NULL,NULL,'ptr623.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2630,164,'TXT','txt624','test-txt-624',NULL,NULL,NULL,NULL,'test-txt-624',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2631,162,'TXT','txt625','test-txt-625',NULL,NULL,NULL,NULL,'test-txt-625',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2632,164,'PTR','ptr626','ptr626.in-addr.arpa.',NULL,NULL,NULL,'ptr626.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2633,182,'TXT','txt627','test-txt-627',NULL,NULL,NULL,NULL,'test-txt-627',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2634,205,'CNAME','cname628','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2635,196,'A','host629','198.51.189.196','198.51.189.196',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2636,205,'CNAME','cname630','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2637,203,'AAAA','host631','2001:db8::d98',NULL,'2001:db8::d98',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2638,206,'AAAA','host632','2001:db8::7da8',NULL,'2001:db8::7da8',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2639,208,'A','host633','198.51.191.104','198.51.191.104',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2640,160,'CNAME','cname634','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2641,166,'PTR','ptr635','ptr635.in-addr.arpa.',NULL,NULL,NULL,'ptr635.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2642,187,'PTR','ptr636','ptr636.in-addr.arpa.',NULL,NULL,NULL,'ptr636.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2643,209,'A','host637','198.51.50.73','198.51.50.73',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2644,184,'PTR','ptr638','ptr638.in-addr.arpa.',NULL,NULL,NULL,'ptr638.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2645,203,'TXT','txt639','test-txt-639',NULL,NULL,NULL,NULL,'test-txt-639',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2646,200,'TXT','txt640','test-txt-640',NULL,NULL,NULL,NULL,'test-txt-640',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2647,191,'CNAME','cname641','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2648,186,'CNAME','cname642','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2649,190,'A','host643','198.51.154.226','198.51.154.226',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2650,160,'CNAME','cname644','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2651,208,'A','host645','198.51.242.97','198.51.242.97',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2652,179,'A','host646','198.51.206.238','198.51.206.238',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2653,166,'CNAME','cname647','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2654,182,'TXT','txt648','test-txt-648',NULL,NULL,NULL,NULL,'test-txt-648',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2655,170,'AAAA','host649','2001:db8::8099',NULL,'2001:db8::8099',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2656,208,'A','host650','198.51.109.226','198.51.109.226',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2657,175,'CNAME','cname651','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2658,188,'AAAA','host652','2001:db8::550b',NULL,'2001:db8::550b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2659,181,'PTR','ptr653','ptr653.in-addr.arpa.',NULL,NULL,NULL,'ptr653.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2660,179,'PTR','ptr654','ptr654.in-addr.arpa.',NULL,NULL,NULL,'ptr654.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2661,201,'PTR','ptr655','ptr655.in-addr.arpa.',NULL,NULL,NULL,'ptr655.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2662,170,'TXT','txt656','test-txt-656',NULL,NULL,NULL,NULL,'test-txt-656',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2663,205,'A','host657','198.51.148.230','198.51.148.230',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2664,196,'TXT','txt658','test-txt-658',NULL,NULL,NULL,NULL,'test-txt-658',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2665,176,'AAAA','host659','2001:db8::ceab',NULL,'2001:db8::ceab',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2666,168,'A','host660','198.51.180.12','198.51.180.12',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2667,203,'CNAME','cname661','test-master-28.local.',NULL,NULL,'test-master-28.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2668,192,'PTR','ptr662','ptr662.in-addr.arpa.',NULL,NULL,NULL,'ptr662.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2669,204,'TXT','txt663','test-txt-663',NULL,NULL,NULL,NULL,'test-txt-663',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2670,161,'CNAME','cname664','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2671,163,'PTR','ptr665','ptr665.in-addr.arpa.',NULL,NULL,NULL,'ptr665.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2672,190,'A','host666','198.51.235.201','198.51.235.201',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2673,169,'CNAME','cname667','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2674,176,'CNAME','cname668','test-master-12.local.',NULL,NULL,'test-master-12.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2675,184,'PTR','ptr669','ptr669.in-addr.arpa.',NULL,NULL,NULL,'ptr669.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2676,167,'CNAME','cname670','test-master-27.local.',NULL,NULL,'test-master-27.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2677,182,'A','host671','198.51.191.172','198.51.191.172',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2678,167,'CNAME','cname672','test-master-40.local.',NULL,NULL,'test-master-40.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2679,177,'AAAA','host673','2001:db8::6d03',NULL,'2001:db8::6d03',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2680,202,'AAAA','host674','2001:db8::e185',NULL,'2001:db8::e185',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2681,163,'AAAA','host675','2001:db8::27eb',NULL,'2001:db8::27eb',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2682,183,'TXT','txt676','test-txt-676',NULL,NULL,NULL,NULL,'test-txt-676',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2683,204,'TXT','txt677','test-txt-677',NULL,NULL,NULL,NULL,'test-txt-677',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2684,172,'AAAA','host678','2001:db8::76d7',NULL,'2001:db8::76d7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2685,201,'A','host679','198.51.192.114','198.51.192.114',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2686,195,'AAAA','host680','2001:db8::6e5d',NULL,'2001:db8::6e5d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2687,194,'TXT','txt681','test-txt-681',NULL,NULL,NULL,NULL,'test-txt-681',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2688,209,'TXT','txt682','test-txt-682',NULL,NULL,NULL,NULL,'test-txt-682',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2689,205,'CNAME','cname683','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2690,160,'AAAA','host684','2001:db8::b010',NULL,'2001:db8::b010',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2691,196,'CNAME','cname685','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2692,206,'TXT','txt686','test-txt-686',NULL,NULL,NULL,NULL,'test-txt-686',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2693,204,'CNAME','cname687','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2694,182,'A','host688','198.51.190.169','198.51.190.169',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2695,208,'A','host689','198.51.195.50','198.51.195.50',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2696,194,'A','host690','198.51.165.153','198.51.165.153',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2697,171,'PTR','ptr691','ptr691.in-addr.arpa.',NULL,NULL,NULL,'ptr691.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2698,186,'TXT','txt692','test-txt-692',NULL,NULL,NULL,NULL,'test-txt-692',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2699,178,'TXT','txt693','test-txt-693',NULL,NULL,NULL,NULL,'test-txt-693',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2700,191,'CNAME','cname694','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2701,178,'PTR','ptr695','ptr695.in-addr.arpa.',NULL,NULL,NULL,'ptr695.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2702,205,'AAAA','host696','2001:db8::9f63',NULL,'2001:db8::9f63',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2703,172,'CNAME','cname697','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2704,164,'AAAA','host698','2001:db8::f177',NULL,'2001:db8::f177',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2705,179,'CNAME','cname699','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2706,162,'CNAME','cname700','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2707,190,'AAAA','host701','2001:db8::48ee',NULL,'2001:db8::48ee',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2708,160,'CNAME','cname702','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2709,179,'CNAME','cname703','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2710,204,'TXT','txt704','test-txt-704',NULL,NULL,NULL,NULL,'test-txt-704',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2711,177,'PTR','ptr705','ptr705.in-addr.arpa.',NULL,NULL,NULL,'ptr705.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2712,160,'CNAME','cname706','test-master-3.local.',NULL,NULL,'test-master-3.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2713,187,'A','host707','198.51.16.83','198.51.16.83',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2714,190,'AAAA','host708','2001:db8::8c7',NULL,'2001:db8::8c7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2715,200,'TXT','txt709','test-txt-709',NULL,NULL,NULL,NULL,'test-txt-709',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2716,161,'TXT','txt710','test-txt-710',NULL,NULL,NULL,NULL,'test-txt-710',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2717,178,'A','host711','198.51.232.235','198.51.232.235',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2718,193,'AAAA','host712','2001:db8::86ba',NULL,'2001:db8::86ba',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2719,207,'A','host713','198.51.200.203','198.51.200.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2720,202,'CNAME','cname714','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2721,161,'PTR','ptr715','ptr715.in-addr.arpa.',NULL,NULL,NULL,'ptr715.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2722,171,'AAAA','host716','2001:db8::d9ce',NULL,'2001:db8::d9ce',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2723,163,'PTR','ptr717','ptr717.in-addr.arpa.',NULL,NULL,NULL,'ptr717.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2724,188,'AAAA','host718','2001:db8::c170',NULL,'2001:db8::c170',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2725,164,'A','host719','198.51.15.63','198.51.15.63',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2726,167,'A','host720','198.51.103.200','198.51.103.200',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2727,199,'PTR','ptr721','ptr721.in-addr.arpa.',NULL,NULL,NULL,'ptr721.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2728,207,'CNAME','cname722','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2729,202,'A','host723','198.51.235.162','198.51.235.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2730,206,'AAAA','host724','2001:db8::47e2',NULL,'2001:db8::47e2',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2731,174,'TXT','txt725','test-txt-725',NULL,NULL,NULL,NULL,'test-txt-725',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2732,203,'TXT','txt726','test-txt-726',NULL,NULL,NULL,NULL,'test-txt-726',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2733,190,'CNAME','cname727','test-master-24.local.',NULL,NULL,'test-master-24.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2734,164,'A','host728','198.51.137.10','198.51.137.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2735,162,'CNAME','cname729','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2736,205,'CNAME','cname730','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2737,178,'PTR','ptr731','ptr731.in-addr.arpa.',NULL,NULL,NULL,'ptr731.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2738,168,'CNAME','cname732','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2739,191,'TXT','txt733','test-txt-733',NULL,NULL,NULL,NULL,'test-txt-733',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2740,186,'A','host734','198.51.197.190','198.51.197.190',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2741,197,'A','host735','198.51.255.184','198.51.255.184',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2742,162,'A','host736','198.51.214.214','198.51.214.214',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2743,170,'AAAA','host737','2001:db8::a019',NULL,'2001:db8::a019',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2744,189,'TXT','txt738','test-txt-738',NULL,NULL,NULL,NULL,'test-txt-738',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2745,173,'CNAME','cname739','test-master-10.local.',NULL,NULL,'test-master-10.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2746,200,'A','host740','198.51.171.178','198.51.171.178',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2747,180,'CNAME','cname741','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2748,188,'A','host742','198.51.163.145','198.51.163.145',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2749,163,'A','host743','198.51.31.127','198.51.31.127',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2750,188,'A','host744','198.51.11.149','198.51.11.149',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2751,192,'TXT','txt745','test-txt-745',NULL,NULL,NULL,NULL,'test-txt-745',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2752,186,'PTR','ptr746','ptr746.in-addr.arpa.',NULL,NULL,NULL,'ptr746.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2753,172,'A','host747','198.51.231.150','198.51.231.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2754,160,'A','host748','198.51.181.86','198.51.181.86',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2755,202,'A','host749','198.51.245.10','198.51.245.10',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2756,184,'A','host750','198.51.180.20','198.51.180.20',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2757,180,'CNAME','cname751','test-master-36.local.',NULL,NULL,'test-master-36.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2758,186,'CNAME','cname752','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2759,165,'PTR','ptr753','ptr753.in-addr.arpa.',NULL,NULL,NULL,'ptr753.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2760,203,'CNAME','cname754','test-master-33.local.',NULL,NULL,'test-master-33.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2761,172,'PTR','ptr755','ptr755.in-addr.arpa.',NULL,NULL,NULL,'ptr755.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2762,201,'CNAME','cname756','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2763,206,'PTR','ptr757','ptr757.in-addr.arpa.',NULL,NULL,NULL,'ptr757.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2764,174,'A','host758','198.51.225.211','198.51.225.211',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2765,186,'TXT','txt759','test-txt-759',NULL,NULL,NULL,NULL,'test-txt-759',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2766,193,'A','host760','198.51.114.24','198.51.114.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2767,202,'AAAA','host761','2001:db8::ca5f',NULL,'2001:db8::ca5f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2768,160,'TXT','txt762','test-txt-762',NULL,NULL,NULL,NULL,'test-txt-762',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2769,187,'A','host763','198.51.220.150','198.51.220.150',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2770,187,'TXT','txt764','test-txt-764',NULL,NULL,NULL,NULL,'test-txt-764',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2771,160,'PTR','ptr765','ptr765.in-addr.arpa.',NULL,NULL,NULL,'ptr765.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2772,163,'A','host766','198.51.168.18','198.51.168.18',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2773,204,'TXT','txt767','test-txt-767',NULL,NULL,NULL,NULL,'test-txt-767',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2774,188,'TXT','txt768','test-txt-768',NULL,NULL,NULL,NULL,'test-txt-768',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2775,173,'CNAME','cname769','test-master-1.local.',NULL,NULL,'test-master-1.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2776,205,'CNAME','cname770','test-master-37.local.',NULL,NULL,'test-master-37.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2777,166,'AAAA','host771','2001:db8::eb38',NULL,'2001:db8::eb38',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2778,206,'TXT','txt772','test-txt-772',NULL,NULL,NULL,NULL,'test-txt-772',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2779,203,'PTR','ptr773','ptr773.in-addr.arpa.',NULL,NULL,NULL,'ptr773.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2780,163,'TXT','txt774','test-txt-774',NULL,NULL,NULL,NULL,'test-txt-774',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2781,166,'A','host775','198.51.35.54','198.51.35.54',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2782,160,'PTR','ptr776','ptr776.in-addr.arpa.',NULL,NULL,NULL,'ptr776.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2783,162,'TXT','txt777','test-txt-777',NULL,NULL,NULL,NULL,'test-txt-777',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2784,208,'A','host778','198.51.195.198','198.51.195.198',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2785,170,'PTR','ptr779','ptr779.in-addr.arpa.',NULL,NULL,NULL,'ptr779.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2786,163,'TXT','txt780','test-txt-780',NULL,NULL,NULL,NULL,'test-txt-780',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2787,209,'A','host781','198.51.124.91','198.51.124.91',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2788,189,'A','host782','198.51.14.147','198.51.14.147',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2789,200,'PTR','ptr783','ptr783.in-addr.arpa.',NULL,NULL,NULL,'ptr783.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2790,176,'CNAME','cname784','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2791,186,'A','host785','198.51.193.220','198.51.193.220',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2792,196,'CNAME','cname786','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2793,169,'AAAA','host787','2001:db8::eada',NULL,'2001:db8::eada',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2794,170,'PTR','ptr788','ptr788.in-addr.arpa.',NULL,NULL,NULL,'ptr788.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2795,164,'PTR','ptr789','ptr789.in-addr.arpa.',NULL,NULL,NULL,'ptr789.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2796,171,'A','host790','198.51.106.162','198.51.106.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2797,190,'TXT','txt791','test-txt-791',NULL,NULL,NULL,NULL,'test-txt-791',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2798,161,'TXT','txt792','test-txt-792',NULL,NULL,NULL,NULL,'test-txt-792',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2799,209,'AAAA','host793','2001:db8::a29d',NULL,'2001:db8::a29d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2800,172,'A','host794','198.51.72.105','198.51.72.105',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2801,197,'PTR','ptr795','ptr795.in-addr.arpa.',NULL,NULL,NULL,'ptr795.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2802,206,'TXT','txt796','test-txt-796',NULL,NULL,NULL,NULL,'test-txt-796',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2803,168,'AAAA','host797','2001:db8::187',NULL,'2001:db8::187',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2804,205,'TXT','txt798','test-txt-798',NULL,NULL,NULL,NULL,'test-txt-798',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2805,174,'PTR','ptr799','ptr799.in-addr.arpa.',NULL,NULL,NULL,'ptr799.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2806,207,'TXT','txt800','test-txt-800',NULL,NULL,NULL,NULL,'test-txt-800',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2807,205,'A','host801','198.51.24.252','198.51.24.252',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2808,164,'AAAA','host802','2001:db8::360',NULL,'2001:db8::360',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2809,199,'A','host803','198.51.76.133','198.51.76.133',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2810,183,'A','host804','198.51.231.109','198.51.231.109',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2811,193,'CNAME','cname805','test-master-8.local.',NULL,NULL,'test-master-8.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2812,186,'PTR','ptr806','ptr806.in-addr.arpa.',NULL,NULL,NULL,'ptr806.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2813,179,'AAAA','host807','2001:db8::7d01',NULL,'2001:db8::7d01',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2814,197,'TXT','txt808','test-txt-808',NULL,NULL,NULL,NULL,'test-txt-808',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2815,193,'TXT','txt809','test-txt-809',NULL,NULL,NULL,NULL,'test-txt-809',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2816,170,'PTR','ptr810','ptr810.in-addr.arpa.',NULL,NULL,NULL,'ptr810.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2817,180,'A','host811','198.51.172.3','198.51.172.3',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2818,196,'A','host812','198.51.11.25','198.51.11.25',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2819,176,'TXT','txt813','test-txt-813',NULL,NULL,NULL,NULL,'test-txt-813',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2820,186,'AAAA','host814','2001:db8::bc59',NULL,'2001:db8::bc59',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2821,203,'TXT','txt815','test-txt-815',NULL,NULL,NULL,NULL,'test-txt-815',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2822,172,'PTR','ptr816','ptr816.in-addr.arpa.',NULL,NULL,NULL,'ptr816.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2823,184,'TXT','txt817','test-txt-817',NULL,NULL,NULL,NULL,'test-txt-817',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2824,162,'TXT','txt818','test-txt-818',NULL,NULL,NULL,NULL,'test-txt-818',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2825,195,'CNAME','cname819','test-master-15.local.',NULL,NULL,'test-master-15.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2826,162,'A','host820','198.51.125.218','198.51.125.218',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2827,173,'PTR','ptr821','ptr821.in-addr.arpa.',NULL,NULL,NULL,'ptr821.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2828,180,'AAAA','host822','2001:db8::e1c0',NULL,'2001:db8::e1c0',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2829,169,'AAAA','host823','2001:db8::439b',NULL,'2001:db8::439b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2830,173,'A','host824','198.51.98.85','198.51.98.85',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2831,202,'AAAA','host825','2001:db8::b7af',NULL,'2001:db8::b7af',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2832,182,'TXT','txt826','test-txt-826',NULL,NULL,NULL,NULL,'test-txt-826',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2833,201,'A','host827','198.51.128.234','198.51.128.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2834,173,'A','host828','198.51.137.127','198.51.137.127',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2835,168,'PTR','ptr829','ptr829.in-addr.arpa.',NULL,NULL,NULL,'ptr829.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2836,202,'AAAA','host830','2001:db8::4344',NULL,'2001:db8::4344',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2837,180,'PTR','ptr831','ptr831.in-addr.arpa.',NULL,NULL,NULL,'ptr831.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2838,180,'TXT','txt832','test-txt-832',NULL,NULL,NULL,NULL,'test-txt-832',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2839,202,'A','host833','198.51.115.219','198.51.115.219',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2840,177,'TXT','txt834','test-txt-834',NULL,NULL,NULL,NULL,'test-txt-834',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2841,183,'A','host835','198.51.232.151','198.51.232.151',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2842,192,'TXT','txt836','test-txt-836',NULL,NULL,NULL,NULL,'test-txt-836',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2843,185,'A','host837','198.51.125.24','198.51.125.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2844,173,'TXT','txt838','test-txt-838',NULL,NULL,NULL,NULL,'test-txt-838',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2845,208,'A','host839','198.51.176.27','198.51.176.27',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2846,203,'TXT','txt840','test-txt-840',NULL,NULL,NULL,NULL,'test-txt-840',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2847,204,'A','host841','198.51.246.24','198.51.246.24',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2848,193,'CNAME','cname842','test-master-20.local.',NULL,NULL,'test-master-20.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2849,174,'TXT','txt843','test-txt-843',NULL,NULL,NULL,NULL,'test-txt-843',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2850,186,'CNAME','cname844','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2851,164,'CNAME','cname845','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2852,198,'CNAME','cname846','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2853,189,'A','host847','198.51.43.203','198.51.43.203',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2854,207,'AAAA','host848','2001:db8::8ea5',NULL,'2001:db8::8ea5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2855,200,'CNAME','cname849','test-master-13.local.',NULL,NULL,'test-master-13.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2856,202,'A','host850','198.51.103.58','198.51.103.58',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2857,164,'PTR','ptr851','ptr851.in-addr.arpa.',NULL,NULL,NULL,'ptr851.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2858,197,'AAAA','host852','2001:db8::5394',NULL,'2001:db8::5394',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2859,201,'A','host853','198.51.168.41','198.51.168.41',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2860,209,'CNAME','cname854','test-master-26.local.',NULL,NULL,'test-master-26.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2861,175,'CNAME','cname855','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2862,204,'PTR','ptr856','ptr856.in-addr.arpa.',NULL,NULL,NULL,'ptr856.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2863,188,'AAAA','host857','2001:db8::beec',NULL,'2001:db8::beec',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2864,188,'TXT','txt858','test-txt-858',NULL,NULL,NULL,NULL,'test-txt-858',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2865,164,'CNAME','cname859','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2866,171,'A','host860','198.51.44.185','198.51.44.185',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2867,169,'CNAME','cname861','test-master-4.local.',NULL,NULL,'test-master-4.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2868,192,'PTR','ptr862','ptr862.in-addr.arpa.',NULL,NULL,NULL,'ptr862.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2869,204,'A','host863','198.51.203.210','198.51.203.210',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2870,201,'A','host864','198.51.101.58','198.51.101.58',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2871,200,'AAAA','host865','2001:db8::c7fe',NULL,'2001:db8::c7fe',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2872,205,'PTR','ptr866','ptr866.in-addr.arpa.',NULL,NULL,NULL,'ptr866.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2873,183,'AAAA','host867','2001:db8::28e5',NULL,'2001:db8::28e5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2874,171,'TXT','txt868','test-txt-868',NULL,NULL,NULL,NULL,'test-txt-868',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2875,177,'A','host869','198.51.41.185','198.51.41.185',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2876,183,'TXT','txt870','test-txt-870',NULL,NULL,NULL,NULL,'test-txt-870',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2877,201,'PTR','ptr871','ptr871.in-addr.arpa.',NULL,NULL,NULL,'ptr871.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2878,200,'CNAME','cname872','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2879,200,'AAAA','host873','2001:db8::9dc7',NULL,'2001:db8::9dc7',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2880,172,'AAAA','host874','2001:db8::5acc',NULL,'2001:db8::5acc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2881,162,'TXT','txt875','test-txt-875',NULL,NULL,NULL,NULL,'test-txt-875',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2882,188,'PTR','ptr876','ptr876.in-addr.arpa.',NULL,NULL,NULL,'ptr876.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2883,168,'A','host877','198.51.66.136','198.51.66.136',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2884,183,'AAAA','host878','2001:db8::48f1',NULL,'2001:db8::48f1',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2885,177,'AAAA','host879','2001:db8::d39',NULL,'2001:db8::d39',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2886,181,'PTR','ptr880','ptr880.in-addr.arpa.',NULL,NULL,NULL,'ptr880.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2887,172,'A','host881','198.51.225.82','198.51.225.82',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2888,165,'CNAME','cname882','test-master-5.local.',NULL,NULL,'test-master-5.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2889,170,'CNAME','cname883','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2890,204,'CNAME','cname884','test-master-6.local.',NULL,NULL,'test-master-6.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2891,202,'TXT','txt885','test-txt-885',NULL,NULL,NULL,NULL,'test-txt-885',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2892,175,'A','host886','198.51.140.245','198.51.140.245',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2893,197,'CNAME','cname887','test-master-25.local.',NULL,NULL,'test-master-25.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2894,160,'TXT','txt888','test-txt-888',NULL,NULL,NULL,NULL,'test-txt-888',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2895,167,'AAAA','host889','2001:db8::bd5f',NULL,'2001:db8::bd5f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2896,203,'A','host890','198.51.119.90','198.51.119.90',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2897,177,'A','host891','198.51.197.170','198.51.197.170',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2898,168,'PTR','ptr892','ptr892.in-addr.arpa.',NULL,NULL,NULL,'ptr892.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2899,192,'A','host893','198.51.30.163','198.51.30.163',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2900,206,'A','host894','198.51.70.16','198.51.70.16',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2901,206,'A','host895','198.51.129.188','198.51.129.188',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2902,197,'PTR','ptr896','ptr896.in-addr.arpa.',NULL,NULL,NULL,'ptr896.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2903,171,'A','host897','198.51.205.226','198.51.205.226',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2904,171,'PTR','ptr898','ptr898.in-addr.arpa.',NULL,NULL,NULL,'ptr898.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2905,174,'A','host899','198.51.8.234','198.51.8.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2906,171,'CNAME','cname900','test-master-34.local.',NULL,NULL,'test-master-34.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2907,183,'A','host901','198.51.214.176','198.51.214.176',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2908,201,'A','host902','198.51.174.166','198.51.174.166',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2909,170,'TXT','txt903','test-txt-903',NULL,NULL,NULL,NULL,'test-txt-903',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2910,187,'PTR','ptr904','ptr904.in-addr.arpa.',NULL,NULL,NULL,'ptr904.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2911,179,'A','host905','198.51.167.20','198.51.167.20',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2912,206,'TXT','txt906','test-txt-906',NULL,NULL,NULL,NULL,'test-txt-906',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2913,184,'AAAA','host907','2001:db8::fcc4',NULL,'2001:db8::fcc4',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2914,206,'A','host908','198.51.163.162','198.51.163.162',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2915,169,'PTR','ptr909','ptr909.in-addr.arpa.',NULL,NULL,NULL,'ptr909.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2916,181,'PTR','ptr910','ptr910.in-addr.arpa.',NULL,NULL,NULL,'ptr910.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2917,195,'TXT','txt911','test-txt-911',NULL,NULL,NULL,NULL,'test-txt-911',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2918,177,'CNAME','cname912','test-master-29.local.',NULL,NULL,'test-master-29.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2919,198,'A','host913','198.51.87.64','198.51.87.64',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2920,186,'AAAA','host914','2001:db8::e66f',NULL,'2001:db8::e66f',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2921,205,'AAAA','host915','2001:db8::1e9a',NULL,'2001:db8::1e9a',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2922,182,'AAAA','host916','2001:db8::5e9e',NULL,'2001:db8::5e9e',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2923,200,'TXT','txt917','test-txt-917',NULL,NULL,NULL,NULL,'test-txt-917',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2924,208,'CNAME','cname918','test-master-19.local.',NULL,NULL,'test-master-19.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2925,170,'A','host919','198.51.74.247','198.51.74.247',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2926,164,'PTR','ptr920','ptr920.in-addr.arpa.',NULL,NULL,NULL,'ptr920.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2927,162,'AAAA','host921','2001:db8::aa38',NULL,'2001:db8::aa38',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2928,202,'CNAME','cname922','test-master-30.local.',NULL,NULL,'test-master-30.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2929,202,'CNAME','cname923','test-master-7.local.',NULL,NULL,'test-master-7.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2930,177,'TXT','txt924','test-txt-924',NULL,NULL,NULL,NULL,'test-txt-924',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2931,170,'AAAA','host925','2001:db8::8666',NULL,'2001:db8::8666',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2932,199,'A','host926','198.51.207.78','198.51.207.78',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2933,198,'A','host927','198.51.192.247','198.51.192.247',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2934,201,'TXT','txt928','test-txt-928',NULL,NULL,NULL,NULL,'test-txt-928',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2935,160,'TXT','txt929','test-txt-929',NULL,NULL,NULL,NULL,'test-txt-929',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2936,189,'TXT','txt930','test-txt-930',NULL,NULL,NULL,NULL,'test-txt-930',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2937,201,'AAAA','host931','2001:db8::f31b',NULL,'2001:db8::f31b',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2938,192,'TXT','txt932','test-txt-932',NULL,NULL,NULL,NULL,'test-txt-932',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2939,160,'AAAA','host933','2001:db8::3e39',NULL,'2001:db8::3e39',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2940,185,'A','host934','198.51.192.159','198.51.192.159',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2941,193,'AAAA','host935','2001:db8::106d',NULL,'2001:db8::106d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2942,198,'PTR','ptr936','ptr936.in-addr.arpa.',NULL,NULL,NULL,'ptr936.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2943,181,'CNAME','cname937','test-master-31.local.',NULL,NULL,'test-master-31.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2944,186,'CNAME','cname938','test-master-2.local.',NULL,NULL,'test-master-2.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2945,181,'CNAME','cname939','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2946,205,'A','host940','198.51.108.123','198.51.108.123',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2947,187,'PTR','ptr941','ptr941.in-addr.arpa.',NULL,NULL,NULL,'ptr941.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2948,178,'TXT','txt942','test-txt-942',NULL,NULL,NULL,NULL,'test-txt-942',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2949,163,'TXT','txt943','test-txt-943',NULL,NULL,NULL,NULL,'test-txt-943',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2950,206,'PTR','ptr944','ptr944.in-addr.arpa.',NULL,NULL,NULL,'ptr944.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2951,197,'PTR','ptr945','ptr945.in-addr.arpa.',NULL,NULL,NULL,'ptr945.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2952,203,'TXT','txt946','test-txt-946',NULL,NULL,NULL,NULL,'test-txt-946',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2953,207,'AAAA','host947','2001:db8::28ee',NULL,'2001:db8::28ee',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2954,209,'CNAME','cname948','test-master-22.local.',NULL,NULL,'test-master-22.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2955,182,'PTR','ptr949','ptr949.in-addr.arpa.',NULL,NULL,NULL,'ptr949.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2956,194,'A','host950','198.51.55.5','198.51.55.5',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2957,166,'AAAA','host951','2001:db8::bc26',NULL,'2001:db8::bc26',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2958,173,'CNAME','cname952','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2959,172,'A','host953','198.51.104.234','198.51.104.234',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2960,171,'AAAA','host954','2001:db8::3ffd',NULL,'2001:db8::3ffd',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2961,187,'CNAME','cname955','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2962,177,'CNAME','cname956','test-master-9.local.',NULL,NULL,'test-master-9.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2963,180,'TXT','txt957','test-txt-957',NULL,NULL,NULL,NULL,'test-txt-957',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2964,208,'A','host958','198.51.100.237','198.51.100.237',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2965,194,'A','host959','198.51.212.219','198.51.212.219',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2966,202,'AAAA','host960','2001:db8::ad74',NULL,'2001:db8::ad74',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2967,172,'TXT','txt961','test-txt-961',NULL,NULL,NULL,NULL,'test-txt-961',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2968,209,'AAAA','host962','2001:db8::115',NULL,'2001:db8::115',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2969,164,'A','host963','198.51.242.248','198.51.242.248',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2970,189,'TXT','txt964','test-txt-964',NULL,NULL,NULL,NULL,'test-txt-964',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2971,202,'CNAME','cname965','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2972,206,'AAAA','host966','2001:db8::2385',NULL,'2001:db8::2385',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2973,167,'TXT','txt967','test-txt-967',NULL,NULL,NULL,NULL,'test-txt-967',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2974,189,'CNAME','cname968','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2975,194,'A','host969','198.51.100.11','198.51.100.11',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2976,167,'A','host970','198.51.195.69','198.51.195.69',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2977,189,'AAAA','host971','2001:db8::aa61',NULL,'2001:db8::aa61',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2978,199,'A','host972','198.51.191.38','198.51.191.38',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2979,173,'PTR','ptr973','ptr973.in-addr.arpa.',NULL,NULL,NULL,'ptr973.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2980,175,'A','host974','198.51.222.250','198.51.222.250',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2981,206,'CNAME','cname975','test-master-32.local.',NULL,NULL,'test-master-32.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2982,167,'TXT','txt976','test-txt-976',NULL,NULL,NULL,NULL,'test-txt-976',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2983,193,'A','host977','198.51.210.48','198.51.210.48',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2984,174,'CNAME','cname978','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2985,167,'PTR','ptr979','ptr979.in-addr.arpa.',NULL,NULL,NULL,'ptr979.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2986,186,'A','host980','198.51.180.84','198.51.180.84',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2987,167,'PTR','ptr981','ptr981.in-addr.arpa.',NULL,NULL,NULL,'ptr981.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2988,206,'TXT','txt982','test-txt-982',NULL,NULL,NULL,NULL,'test-txt-982',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2989,202,'TXT','txt983','test-txt-983',NULL,NULL,NULL,NULL,'test-txt-983',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2990,209,'PTR','ptr984','ptr984.in-addr.arpa.',NULL,NULL,NULL,'ptr984.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2991,209,'CNAME','cname985','test-master-11.local.',NULL,NULL,'test-master-11.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2992,171,'CNAME','cname986','test-master-38.local.',NULL,NULL,'test-master-38.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2993,203,'TXT','txt987','test-txt-987',NULL,NULL,NULL,NULL,'test-txt-987',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2994,160,'CNAME','cname988','test-master-18.local.',NULL,NULL,'test-master-18.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2995,163,'AAAA','host989','2001:db8::1a3d',NULL,'2001:db8::1a3d',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2996,209,'AAAA','host990','2001:db8::c6a5',NULL,'2001:db8::c6a5',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2997,203,'CNAME','cname991','test-master-16.local.',NULL,NULL,'test-master-16.local.',NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2998,186,'TXT','txt992','test-txt-992',NULL,NULL,NULL,NULL,'test-txt-992',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(2999,176,'AAAA','host993','2001:db8::69cc',NULL,'2001:db8::69cc',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3000,184,'PTR','ptr994','ptr994.in-addr.arpa.',NULL,NULL,NULL,'ptr994.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3001,184,'PTR','ptr995','ptr995.in-addr.arpa.',NULL,NULL,NULL,'ptr995.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3002,184,'TXT','txt996','test-txt-996',NULL,NULL,NULL,NULL,'test-txt-996',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3003,206,'PTR','ptr997','ptr997.in-addr.arpa.',NULL,NULL,NULL,'ptr997.in-addr.arpa.',NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3004,165,'A','host998','198.51.96.134','198.51.96.134',NULL,NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3005,165,'TXT','txt999','test-txt-999',NULL,NULL,NULL,NULL,'test-txt-999',3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL),
(3006,174,'AAAA','host1000','2001:db8::7e50',NULL,'2001:db8::7e50',NULL,NULL,NULL,3600,NULL,NULL,'active',1,'2025-10-24 12:10:40',NULL,'2025-10-24 12:10:40',NULL,NULL,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
INSERT INTO `zone_file_includes` VALUES
(25,162,200,1,'2025-10-24 14:10:39'),
(26,183,201,2,'2025-10-24 14:10:39'),
(27,180,202,3,'2025-10-24 14:10:39'),
(28,179,203,4,'2025-10-24 14:10:39'),
(29,172,204,5,'2025-10-24 14:10:39'),
(30,180,205,6,'2025-10-24 14:10:39'),
(31,194,206,7,'2025-10-24 14:10:39'),
(32,172,207,8,'2025-10-24 14:10:39'),
(33,169,208,9,'2025-10-24 14:10:39'),
(34,168,209,10,'2025-10-24 14:10:39');
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
) ENGINE=InnoDB AUTO_INCREMENT=210 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(160,'test-master-1.local','db.test-master-1.local',NULL,'$ORIGIN test-master-1.local.\n$TTL 3600\n@ IN SOA ns1.test-master-1.local. admin.test-master-1.local. ( 2025102401 3600 1800 604800 86400 )\n    IN NS ns1.test-master-1.local.\nns1 IN A 192.0.2.2\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(161,'test-master-2.local','db.test-master-2.local',NULL,'$ORIGIN test-master-2.local.\n$TTL 3600\n@ IN SOA ns1.test-master-2.local. admin.test-master-2.local. ( 2025102402 3600 1800 604800 86400 )\n    IN NS ns1.test-master-2.local.\nns1 IN A 192.0.2.3\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(162,'test-master-3.local','db.test-master-3.local',NULL,'$ORIGIN test-master-3.local.\n$TTL 3600\n@ IN SOA ns1.test-master-3.local. admin.test-master-3.local. ( 2025102403 3600 1800 604800 86400 )\n    IN NS ns1.test-master-3.local.\nns1 IN A 192.0.2.4\n\n$INCLUDE includes/common-include-1.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(163,'test-master-4.local','db.test-master-4.local',NULL,'$ORIGIN test-master-4.local.\n$TTL 3600\n@ IN SOA ns1.test-master-4.local. admin.test-master-4.local. ( 2025102404 3600 1800 604800 86400 )\n    IN NS ns1.test-master-4.local.\nns1 IN A 192.0.2.5\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(164,'test-master-5.local','db.test-master-5.local',NULL,'$ORIGIN test-master-5.local.\n$TTL 3600\n@ IN SOA ns1.test-master-5.local. admin.test-master-5.local. ( 2025102405 3600 1800 604800 86400 )\n    IN NS ns1.test-master-5.local.\nns1 IN A 192.0.2.6\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(165,'test-master-6.local','db.test-master-6.local',NULL,'$ORIGIN test-master-6.local.\n$TTL 3600\n@ IN SOA ns1.test-master-6.local. admin.test-master-6.local. ( 2025102406 3600 1800 604800 86400 )\n    IN NS ns1.test-master-6.local.\nns1 IN A 192.0.2.7\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(166,'test-master-7.local','db.test-master-7.local',NULL,'$ORIGIN test-master-7.local.\n$TTL 3600\n@ IN SOA ns1.test-master-7.local. admin.test-master-7.local. ( 2025102407 3600 1800 604800 86400 )\n    IN NS ns1.test-master-7.local.\nns1 IN A 192.0.2.8\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(167,'test-master-8.local','db.test-master-8.local',NULL,'$ORIGIN test-master-8.local.\n$TTL 3600\n@ IN SOA ns1.test-master-8.local. admin.test-master-8.local. ( 2025102408 3600 1800 604800 86400 )\n    IN NS ns1.test-master-8.local.\nns1 IN A 192.0.2.9\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(168,'test-master-9.local','db.test-master-9.local',NULL,'$ORIGIN test-master-9.local.\n$TTL 3600\n@ IN SOA ns1.test-master-9.local. admin.test-master-9.local. ( 2025102409 3600 1800 604800 86400 )\n    IN NS ns1.test-master-9.local.\nns1 IN A 192.0.2.10\n\n$INCLUDE includes/common-include-10.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(169,'test-master-10.local','db.test-master-10.local',NULL,'$ORIGIN test-master-10.local.\n$TTL 3600\n@ IN SOA ns1.test-master-10.local. admin.test-master-10.local. ( 2025102410 3600 1800 604800 86400 )\n    IN NS ns1.test-master-10.local.\nns1 IN A 192.0.2.11\n\n$INCLUDE includes/common-include-9.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(170,'test-master-11.local','db.test-master-11.local',NULL,'$ORIGIN test-master-11.local.\n$TTL 3600\n@ IN SOA ns1.test-master-11.local. admin.test-master-11.local. ( 2025102411 3600 1800 604800 86400 )\n    IN NS ns1.test-master-11.local.\nns1 IN A 192.0.2.12\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(171,'test-master-12.local','db.test-master-12.local',NULL,'$ORIGIN test-master-12.local.\n$TTL 3600\n@ IN SOA ns1.test-master-12.local. admin.test-master-12.local. ( 2025102412 3600 1800 604800 86400 )\n    IN NS ns1.test-master-12.local.\nns1 IN A 192.0.2.13\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(172,'test-master-13.local','db.test-master-13.local',NULL,'$ORIGIN test-master-13.local.\n$TTL 3600\n@ IN SOA ns1.test-master-13.local. admin.test-master-13.local. ( 2025102413 3600 1800 604800 86400 )\n    IN NS ns1.test-master-13.local.\nns1 IN A 192.0.2.14\n\n$INCLUDE includes/common-include-5.inc\n\n$INCLUDE includes/common-include-8.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(173,'test-master-14.local','db.test-master-14.local',NULL,'$ORIGIN test-master-14.local.\n$TTL 3600\n@ IN SOA ns1.test-master-14.local. admin.test-master-14.local. ( 2025102414 3600 1800 604800 86400 )\n    IN NS ns1.test-master-14.local.\nns1 IN A 192.0.2.15\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(174,'test-master-15.local','db.test-master-15.local',NULL,'$ORIGIN test-master-15.local.\n$TTL 3600\n@ IN SOA ns1.test-master-15.local. admin.test-master-15.local. ( 2025102415 3600 1800 604800 86400 )\n    IN NS ns1.test-master-15.local.\nns1 IN A 192.0.2.16\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(175,'test-master-16.local','db.test-master-16.local',NULL,'$ORIGIN test-master-16.local.\n$TTL 3600\n@ IN SOA ns1.test-master-16.local. admin.test-master-16.local. ( 2025102416 3600 1800 604800 86400 )\n    IN NS ns1.test-master-16.local.\nns1 IN A 192.0.2.17\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(176,'test-master-17.local','db.test-master-17.local',NULL,'$ORIGIN test-master-17.local.\n$TTL 3600\n@ IN SOA ns1.test-master-17.local. admin.test-master-17.local. ( 2025102417 3600 1800 604800 86400 )\n    IN NS ns1.test-master-17.local.\nns1 IN A 192.0.2.18\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(177,'test-master-18.local','db.test-master-18.local',NULL,'$ORIGIN test-master-18.local.\n$TTL 3600\n@ IN SOA ns1.test-master-18.local. admin.test-master-18.local. ( 2025102418 3600 1800 604800 86400 )\n    IN NS ns1.test-master-18.local.\nns1 IN A 192.0.2.19\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(178,'test-master-19.local','db.test-master-19.local',NULL,'$ORIGIN test-master-19.local.\n$TTL 3600\n@ IN SOA ns1.test-master-19.local. admin.test-master-19.local. ( 2025102419 3600 1800 604800 86400 )\n    IN NS ns1.test-master-19.local.\nns1 IN A 192.0.2.20\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(179,'test-master-20.local','db.test-master-20.local',NULL,'$ORIGIN test-master-20.local.\n$TTL 3600\n@ IN SOA ns1.test-master-20.local. admin.test-master-20.local. ( 2025102420 3600 1800 604800 86400 )\n    IN NS ns1.test-master-20.local.\nns1 IN A 192.0.2.21\n\n$INCLUDE includes/common-include-4.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(180,'test-master-21.local','db.test-master-21.local',NULL,'$ORIGIN test-master-21.local.\n$TTL 3600\n@ IN SOA ns1.test-master-21.local. admin.test-master-21.local. ( 2025102421 3600 1800 604800 86400 )\n    IN NS ns1.test-master-21.local.\nns1 IN A 192.0.2.22\n\n$INCLUDE includes/common-include-3.inc\n\n$INCLUDE includes/common-include-6.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(181,'test-master-22.local','db.test-master-22.local',NULL,'$ORIGIN test-master-22.local.\n$TTL 3600\n@ IN SOA ns1.test-master-22.local. admin.test-master-22.local. ( 2025102422 3600 1800 604800 86400 )\n    IN NS ns1.test-master-22.local.\nns1 IN A 192.0.2.23\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(182,'test-master-23.local','db.test-master-23.local',NULL,'$ORIGIN test-master-23.local.\n$TTL 3600\n@ IN SOA ns1.test-master-23.local. admin.test-master-23.local. ( 2025102423 3600 1800 604800 86400 )\n    IN NS ns1.test-master-23.local.\nns1 IN A 192.0.2.24\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(183,'test-master-24.local','db.test-master-24.local',NULL,'$ORIGIN test-master-24.local.\n$TTL 3600\n@ IN SOA ns1.test-master-24.local. admin.test-master-24.local. ( 2025102424 3600 1800 604800 86400 )\n    IN NS ns1.test-master-24.local.\nns1 IN A 192.0.2.25\n\n$INCLUDE includes/common-include-2.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(184,'test-master-25.local','db.test-master-25.local',NULL,'$ORIGIN test-master-25.local.\n$TTL 3600\n@ IN SOA ns1.test-master-25.local. admin.test-master-25.local. ( 2025102425 3600 1800 604800 86400 )\n    IN NS ns1.test-master-25.local.\nns1 IN A 192.0.2.26\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(185,'test-master-26.local','db.test-master-26.local',NULL,'$ORIGIN test-master-26.local.\n$TTL 3600\n@ IN SOA ns1.test-master-26.local. admin.test-master-26.local. ( 2025102426 3600 1800 604800 86400 )\n    IN NS ns1.test-master-26.local.\nns1 IN A 192.0.2.27\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(186,'test-master-27.local','db.test-master-27.local',NULL,'$ORIGIN test-master-27.local.\n$TTL 3600\n@ IN SOA ns1.test-master-27.local. admin.test-master-27.local. ( 2025102427 3600 1800 604800 86400 )\n    IN NS ns1.test-master-27.local.\nns1 IN A 192.0.2.28\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(187,'test-master-28.local','db.test-master-28.local',NULL,'$ORIGIN test-master-28.local.\n$TTL 3600\n@ IN SOA ns1.test-master-28.local. admin.test-master-28.local. ( 2025102428 3600 1800 604800 86400 )\n    IN NS ns1.test-master-28.local.\nns1 IN A 192.0.2.29\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(188,'test-master-29.local','db.test-master-29.local',NULL,'$ORIGIN test-master-29.local.\n$TTL 3600\n@ IN SOA ns1.test-master-29.local. admin.test-master-29.local. ( 2025102429 3600 1800 604800 86400 )\n    IN NS ns1.test-master-29.local.\nns1 IN A 192.0.2.30\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(189,'test-master-30.local','db.test-master-30.local',NULL,'$ORIGIN test-master-30.local.\n$TTL 3600\n@ IN SOA ns1.test-master-30.local. admin.test-master-30.local. ( 2025102430 3600 1800 604800 86400 )\n    IN NS ns1.test-master-30.local.\nns1 IN A 192.0.2.31\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(190,'test-master-31.local','db.test-master-31.local',NULL,'$ORIGIN test-master-31.local.\n$TTL 3600\n@ IN SOA ns1.test-master-31.local. admin.test-master-31.local. ( 2025102431 3600 1800 604800 86400 )\n    IN NS ns1.test-master-31.local.\nns1 IN A 192.0.2.32\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(191,'test-master-32.local','db.test-master-32.local',NULL,'$ORIGIN test-master-32.local.\n$TTL 3600\n@ IN SOA ns1.test-master-32.local. admin.test-master-32.local. ( 2025102432 3600 1800 604800 86400 )\n    IN NS ns1.test-master-32.local.\nns1 IN A 192.0.2.33\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(192,'test-master-33.local','db.test-master-33.local',NULL,'$ORIGIN test-master-33.local.\n$TTL 3600\n@ IN SOA ns1.test-master-33.local. admin.test-master-33.local. ( 2025102433 3600 1800 604800 86400 )\n    IN NS ns1.test-master-33.local.\nns1 IN A 192.0.2.34\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(193,'test-master-34.local','db.test-master-34.local',NULL,'$ORIGIN test-master-34.local.\n$TTL 3600\n@ IN SOA ns1.test-master-34.local. admin.test-master-34.local. ( 2025102434 3600 1800 604800 86400 )\n    IN NS ns1.test-master-34.local.\nns1 IN A 192.0.2.35\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(194,'test-master-35.local','db.test-master-35.local',NULL,'$ORIGIN test-master-35.local.\n$TTL 3600\n@ IN SOA ns1.test-master-35.local. admin.test-master-35.local. ( 2025102435 3600 1800 604800 86400 )\n    IN NS ns1.test-master-35.local.\nns1 IN A 192.0.2.36\n\n$INCLUDE includes/common-include-7.inc\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 14:10:39'),
(195,'test-master-36.local','db.test-master-36.local',NULL,'$ORIGIN test-master-36.local.\n$TTL 3600\n@ IN SOA ns1.test-master-36.local. admin.test-master-36.local. ( 2025102436 3600 1800 604800 86400 )\n    IN NS ns1.test-master-36.local.\nns1 IN A 192.0.2.37\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(196,'test-master-37.local','db.test-master-37.local',NULL,'$ORIGIN test-master-37.local.\n$TTL 3600\n@ IN SOA ns1.test-master-37.local. admin.test-master-37.local. ( 2025102437 3600 1800 604800 86400 )\n    IN NS ns1.test-master-37.local.\nns1 IN A 192.0.2.38\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(197,'test-master-38.local','db.test-master-38.local',NULL,'$ORIGIN test-master-38.local.\n$TTL 3600\n@ IN SOA ns1.test-master-38.local. admin.test-master-38.local. ( 2025102438 3600 1800 604800 86400 )\n    IN NS ns1.test-master-38.local.\nns1 IN A 192.0.2.39\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(198,'test-master-39.local','db.test-master-39.local',NULL,'$ORIGIN test-master-39.local.\n$TTL 3600\n@ IN SOA ns1.test-master-39.local. admin.test-master-39.local. ( 2025102439 3600 1800 604800 86400 )\n    IN NS ns1.test-master-39.local.\nns1 IN A 192.0.2.40\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(199,'test-master-40.local','db.test-master-40.local',NULL,'$ORIGIN test-master-40.local.\n$TTL 3600\n@ IN SOA ns1.test-master-40.local. admin.test-master-40.local. ( 2025102440 3600 1800 604800 86400 )\n    IN NS ns1.test-master-40.local.\nns1 IN A 192.0.2.41\n','master','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(200,'common-include-1.inc.local','includes/common-include-1.inc',NULL,'; Include file for common records group 1\nmonitor IN A 198.51.1.10\nmonitor6 IN AAAA 2001:db8::65\ncommon-txt IN TXT \"include-group-1\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(201,'common-include-2.inc.local','includes/common-include-2.inc',NULL,'; Include file for common records group 2\nmonitor IN A 198.51.2.10\nmonitor6 IN AAAA 2001:db8::66\ncommon-txt IN TXT \"include-group-2\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(202,'common-include-3.inc.local','includes/common-include-3.inc',NULL,'; Include file for common records group 3\nmonitor IN A 198.51.3.10\nmonitor6 IN AAAA 2001:db8::67\ncommon-txt IN TXT \"include-group-3\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(203,'common-include-4.inc.local','includes/common-include-4.inc',NULL,'; Include file for common records group 4\nmonitor IN A 198.51.4.10\nmonitor6 IN AAAA 2001:db8::68\ncommon-txt IN TXT \"include-group-4\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(204,'common-include-5.inc.local','includes/common-include-5.inc',NULL,'; Include file for common records group 5\nmonitor IN A 198.51.5.10\nmonitor6 IN AAAA 2001:db8::69\ncommon-txt IN TXT \"include-group-5\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(205,'common-include-6.inc.local','includes/common-include-6.inc',NULL,'; Include file for common records group 6\nmonitor IN A 198.51.6.10\nmonitor6 IN AAAA 2001:db8::6a\ncommon-txt IN TXT \"include-group-6\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(206,'common-include-7.inc.local','includes/common-include-7.inc',NULL,'; Include file for common records group 7\nmonitor IN A 198.51.7.10\nmonitor6 IN AAAA 2001:db8::6b\ncommon-txt IN TXT \"include-group-7\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(207,'common-include-8.inc.local','includes/common-include-8.inc',NULL,'; Include file for common records group 8\nmonitor IN A 198.51.8.10\nmonitor6 IN AAAA 2001:db8::6c\ncommon-txt IN TXT \"include-group-8\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(208,'common-include-9.inc.local','includes/common-include-9.inc',NULL,'; Include file for common records group 9\nmonitor IN A 198.51.9.10\nmonitor6 IN AAAA 2001:db8::6d\ncommon-txt IN TXT \"include-group-9\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39'),
(209,'common-include-10.inc.local','includes/common-include-10.inc',NULL,'; Include file for common records group 10\nmonitor IN A 198.51.10.10\nmonitor6 IN AAAA 2001:db8::6e\ncommon-txt IN TXT \"include-group-10\"\n','include','active',1,NULL,'2025-10-24 12:10:39','2025-10-24 12:10:39');
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

-- Dump completed on 2025-10-24 18:39:34
