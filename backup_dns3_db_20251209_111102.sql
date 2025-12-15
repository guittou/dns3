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
  `zone_file_id` int(11) DEFAULT NULL COMMENT 'Reference to zone_files.id for zone ACL entries',
  `subject_type` enum('user','role','ad_group') DEFAULT NULL COMMENT 'Type of ACL subject',
  `subject_identifier` varchar(255) DEFAULT NULL COMMENT 'User ID/username, role name, or AD group DN',
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
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_acl_subject` (`subject_type`,`subject_identifier`(100)),
  CONSTRAINT `acl_entries_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_entries_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `acl_entries_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `acl_entries_ibfk_4` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acl_entries`
--

LOCK TABLES `acl_entries` WRITE;
/*!40000 ALTER TABLE `acl_entries` DISABLE KEYS */;
INSERT INTO `acl_entries` VALUES
(1,NULL,NULL,'dns_record',NULL,54010,'user','toto','admin','enabled',2,'2025-11-28 14:38:21',NULL,'2025-11-28 14:47:12'),
(2,NULL,NULL,'dns_record',NULL,54010,'user','titi','read','enabled',2,'2025-11-29 17:52:55',NULL,NULL);
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
-- Table structure for table `api_tokens`
--

DROP TABLE IF EXISTS `api_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `token_name` varchar(255) NOT NULL COMMENT 'Human-readable name for the token',
  `token_hash` varchar(255) NOT NULL COMMENT 'SHA-256 hash of the token',
  `token_prefix` varchar(20) NOT NULL COMMENT 'First few characters for identification',
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL COMMENT 'NULL means no expiration',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `revoked_at` timestamp NULL DEFAULT NULL COMMENT 'NULL means active, set to revoke',
  `created_by` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token_prefix` (`token_prefix`),
  KEY `idx_revoked_at` (`revoked_at`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `api_tokens_ibfk_2` (`created_by`),
  KEY `idx_token_lookup` (`token_hash`,`revoked_at`,`expires_at`),
  CONSTRAINT `api_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `api_tokens_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `api_tokens`
--

LOCK TABLES `api_tokens` WRITE;
/*!40000 ALTER TABLE `api_tokens` DISABLE KEYS */;
INSERT INTO `api_tokens` VALUES
(1,2,'test','21e1d80f8eb160cd31d03905557eab5de4d2306265a80e6b31962820b044540d','8d54f933',NULL,'2025-12-09 20:46:20','2025-12-08 21:46:20',NULL,2);
/*!40000 ALTER TABLE `api_tokens` ENABLE KEYS */;
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
  `record_type` varchar(50) NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  `record_type` varchar(50) NOT NULL,
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
  `port` int(11) DEFAULT NULL COMMENT 'Port number for SRV records',
  `weight` int(11) DEFAULT NULL COMMENT 'Weight for SRV records',
  `srv_target` varchar(255) DEFAULT NULL COMMENT 'Target hostname for SRV records',
  `tlsa_usage` tinyint(4) DEFAULT NULL COMMENT 'TLSA certificate usage (0-3)',
  `tlsa_selector` tinyint(4) DEFAULT NULL COMMENT 'TLSA selector (0=full cert, 1=SubjectPublicKeyInfo)',
  `tlsa_matching` tinyint(4) DEFAULT NULL COMMENT 'TLSA matching type (0=exact, 1=SHA256, 2=SHA512)',
  `tlsa_data` text DEFAULT NULL COMMENT 'TLSA certificate association data (hex)',
  `sshfp_algo` tinyint(4) DEFAULT NULL COMMENT 'SSHFP algorithm (1=RSA, 2=DSA, 3=ECDSA, 4=Ed25519)',
  `sshfp_type` tinyint(4) DEFAULT NULL COMMENT 'SSHFP fingerprint type (1=SHA1, 2=SHA256)',
  `sshfp_fingerprint` text DEFAULT NULL COMMENT 'SSHFP fingerprint (hex)',
  `caa_flag` tinyint(4) DEFAULT NULL COMMENT 'CAA critical flag (0 or 128)',
  `caa_tag` varchar(32) DEFAULT NULL COMMENT 'CAA tag (issue, issuewild, iodef)',
  `caa_value` text DEFAULT NULL COMMENT 'CAA value (e.g., letsencrypt.org)',
  `naptr_order` int(11) DEFAULT NULL COMMENT 'NAPTR order (lower = higher priority)',
  `naptr_pref` int(11) DEFAULT NULL COMMENT 'NAPTR preference (lower = higher priority)',
  `naptr_flags` varchar(16) DEFAULT NULL COMMENT 'NAPTR flags (e.g., U, S, A)',
  `naptr_service` varchar(64) DEFAULT NULL COMMENT 'NAPTR service (e.g., E2U+sip)',
  `naptr_regexp` text DEFAULT NULL COMMENT 'NAPTR regexp substitution expression',
  `naptr_replacement` varchar(255) DEFAULT NULL COMMENT 'NAPTR replacement domain',
  `svc_priority` int(11) DEFAULT NULL COMMENT 'SVCB/HTTPS priority (0=AliasMode)',
  `svc_target` varchar(255) DEFAULT NULL COMMENT 'SVCB/HTTPS target name',
  `svc_params` text DEFAULT NULL COMMENT 'SVCB/HTTPS params (JSON or key=value pairs)',
  `ns_target` varchar(255) DEFAULT NULL COMMENT 'NS record target nameserver',
  `mx_target` varchar(255) DEFAULT NULL COMMENT 'MX record target mail server',
  `dname_target` varchar(255) DEFAULT NULL COMMENT 'DNAME record target',
  `rp_mbox` varchar(255) DEFAULT NULL COMMENT 'RP mailbox (email as domain)',
  `rp_txt` varchar(255) DEFAULT NULL COMMENT 'RP TXT domain reference',
  `loc_latitude` varchar(50) DEFAULT NULL COMMENT 'LOC latitude',
  `loc_longitude` varchar(50) DEFAULT NULL COMMENT 'LOC longitude',
  `loc_altitude` varchar(50) DEFAULT NULL COMMENT 'LOC altitude',
  `rdata_json` text DEFAULT NULL COMMENT 'JSON storage for complex record data',
  PRIMARY KEY (`id`),
  KEY `updated_by` (`updated_by`),
  KEY `idx_name` (`name`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_ticket_ref` (`ticket_ref`),
  KEY `idx_address_ipv4` (`address_ipv4`),
  KEY `idx_address_ipv6` (`address_ipv6`),
  KEY `idx_cname_target` (`cname_target`),
  KEY `idx_zone_file_id` (`zone_file_id`),
  KEY `idx_type` (`record_type`),
  KEY `idx_srv_target` (`srv_target`),
  KEY `idx_mx_target` (`mx_target`),
  KEY `idx_ns_target` (`ns_target`),
  CONSTRAINT `dns_records_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `dns_records_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=219771 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(219714,54620,'A','DR2NM-MIELWZ01V.fr.gouv.intradef.','110.55.255.113','110.55.255.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219715,54620,'CNAME','portail-2snm-centralisation-iel.fr.gouv.intradef.','DR2NM-MIELWZ01V.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELWZ01V.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219716,54620,'A','DR2NM-MIELLW01V.fr.gouv.intradef.','110.55.255.147','110.55.255.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219717,54620,'A','DR2NM-MIELLW01V.fr.gouv.intradef.','110.55.255.179','110.55.255.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219718,54620,'A','portail-2snm-siad-iel.fr.gouv.intradef.','110.55.255.147','110.55.255.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219719,54620,'A','DR2NM-MIELZP01P.fr.gouv.intradef.','110.55.255.59','110.55.255.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219720,54620,'CNAME','portail-2snm-parefeuintradef-iel.fr.gouv.intradef.','DR2NM-MIELZP01P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELZP01P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219721,54620,'A','DR2NM-MIELZP02P.fr.gouv.intradef.','110.55.255.91','110.55.255.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219722,54620,'CNAME','portail-2snm-parefeubalise-iel.fr.gouv.intradef.','DR2NM-MIELZP02P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELZP02P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219723,54620,'A','DR2NM-MIELLP01V.fr.gouv.intradef.','110.55.255.61','110.55.255.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219724,54620,'A','DR2NM-MIELLP02V.fr.gouv.intradef.','110.55.255.60','110.55.255.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219725,54620,'A','DR2NM-MIELLA01V.fr.gouv.intradef.','110.55.255.180','110.55.255.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219726,54620,'A','DR2NM-MIELLA02V.fr.gouv.intradef.','110.55.255.181','110.55.255.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219727,54620,'A','DR2NM-MIELLA03V.fr.gouv.intradef.','110.55.255.182','110.55.255.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219728,54620,'A','DR2NM-MIELLA04V.fr.gouv.intradef.','110.55.255.183','110.55.255.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219729,54620,'A','DR2NM-MIELLZ01V.fr.gouv.intradef.','110.55.255.177','110.55.255.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219730,54620,'A','DR2NM-MIELLB01V.fr.gouv.intradef.','110.55.255.178','110.55.255.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219731,54620,'A','DR2NM-MIELLS01V.fr.gouv.intradef.','110.55.255.12','110.55.255.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219732,54620,'A','DR2NM-MIELLS02V.fr.gouv.intradef.','110.55.255.14','110.55.255.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219733,54620,'A','DR2NM-MBTPWZ01V.fr.gouv.intradef.','111.30.237.113','111.30.237.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219734,54620,'CNAME','portail-2snm-centralisation-btp.fr.gouv.intradef.','DR2NM-MBTPWZ01V.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPWZ01V.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219735,54620,'A','DR2NM-MBTPLW01V.fr.gouv.intradef.','111.30.237.147','111.30.237.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219736,54620,'A','DR2NM-MBTPLW01V.fr.gouv.intradef.','111.30.237.179','111.30.237.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219737,54620,'A','DR2NM-MBTPZP01P.fr.gouv.intradef.','111.30.237.59','111.30.237.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219738,54620,'CNAME','portail-2snm-parefeuintradef-btp.fr.gouv.intradef.','DR2NM-MBTPZP01P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPZP01P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219739,54620,'A','DR2NM-MBTPZP02P.fr.gouv.intradef.','111.30.237.91','111.30.237.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219740,54620,'CNAME','portail-2snm-parefeubalise-btp.fr.gouv.intradef.','DR2NM-MBTPZP02P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPZP02P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219741,54620,'A','DR2NM-MBTPLP01V.fr.gouv.intradef.','111.30.237.61','111.30.237.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219742,54620,'A','DR2NM-MBTPLP02V.fr.gouv.intradef.','111.30.237.60','111.30.237.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219743,54620,'A','DR2NM-MBTPLA01V.fr.gouv.intradef.','111.30.237.180','111.30.237.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219744,54620,'A','DR2NM-MBTPLA02V.fr.gouv.intradef.','111.30.237.181','111.30.237.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219745,54620,'A','DR2NM-MBTPLA03V.fr.gouv.intradef.','111.30.237.182','111.30.237.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219746,54620,'A','DR2NM-MBTPLA04V.fr.gouv.intradef.','111.30.237.183','111.30.237.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219747,54620,'A','DR2NM-MBTPLZ01V.fr.gouv.intradef.','111.30.237.177','111.30.237.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219748,54620,'A','DR2NM-MBTPLB01V.fr.gouv.intradef.','111.30.237.178','111.30.237.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219749,54620,'A','DR2NM-MBTPLS01V.fr.gouv.intradef.','111.30.237.12','111.30.237.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219750,54620,'A','DR2NM-MBTPLS02V.fr.gouv.intradef.','111.30.237.14','111.30.237.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219751,54620,'A','portail-2snm-siad-btp.fr.gouv.intradef.','111.30.237.147','111.30.237.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219752,54620,'A','DR2NM-MCGAWZ01V.fr.gouv.intradef.','110.232.134.113','110.232.134.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219753,54620,'A','dr2nm-mcgalw01v.fr.gouv.intradef.','110.232.134.147','110.232.134.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219754,54620,'A','dr2nm-mcgalw01v.fr.gouv.intradef.','110.232.134.179','110.232.134.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219755,54620,'A','dr2nm-mcgazp01p.fr.gouv.intradef.','110.232.134.59','110.232.134.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219756,54620,'A','dr2nm-mcgazp02p.fr.gouv.intradef.','110.232.134.91','110.232.134.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219757,54620,'A','dr2nm-mcgalp01v.fr.gouv.intradef.','110.232.134.61','110.232.134.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219758,54620,'A','dr2nm-mcgalp02v.fr.gouv.intradef.','110.232.134.60','110.232.134.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219759,54620,'A','dr2nm-mcgala01v.fr.gouv.intradef.','110.232.134.180','110.232.134.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219760,54620,'A','dr2nm-mcgala02v.fr.gouv.intradef.','110.232.134.181','110.232.134.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219761,54620,'A','dr2nm-mcgala03v.fr.gouv.intradef.','110.232.134.182','110.232.134.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219762,54620,'A','dr2nm-mcgala04v.fr.gouv.intradef.','110.232.134.183','110.232.134.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219763,54620,'A','dr2nm-mcgalz01v.fr.gouv.intradef.','110.232.134.177','110.232.134.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219764,54620,'A','dr2nm-mcgalb01v.fr.gouv.intradef.','110.232.134.178','110.232.134.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219765,54620,'A','dr2nm-mcgals01v.fr.gouv.intradef.','110.232.134.12','110.232.134.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219766,54620,'A','dr2nm-mcgals02v.fr.gouv.intradef.','110.232.134.14','110.232.134.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219767,54620,'A','portail-2snm-siad-cga.fr.gouv.intradef.','110.232.134.147','110.232.134.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219768,54620,'CNAME','portail-2snm-centralisation-cga.fr.gouv.intradef.','dr2nm-mcgawz01v.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgawz01v.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219769,54620,'CNAME','portail-2snm-parefeuintradef-cga.fr.gouv.intradef.','dr2nm-mcgazp01p.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgazp01p.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219770,54620,'CNAME','portail-2snm-parefeubalise-cga.fr.gouv.intradef.','dr2nm-mcgazp02p.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgazp02p.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:55:38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `dns_records` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `record_types`
--

DROP TABLE IF EXISTS `record_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `record_types` (
  `name` varchar(50) NOT NULL,
  `category` varchar(50) DEFAULT 'other' COMMENT 'Category for UI grouping (pointing, extended, mail)',
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `record_types`
--

LOCK TABLES `record_types` WRITE;
/*!40000 ALTER TABLE `record_types` DISABLE KEYS */;
INSERT INTO `record_types` VALUES
('A','pointing','IPv4 address record','2025-12-05 11:56:00'),
('AAAA','pointing','IPv6 address record','2025-12-05 11:56:00'),
('CAA','extended','Certification Authority Authorization','2025-12-05 11:56:00'),
('CNAME','pointing','Canonical name (alias) record','2025-12-05 11:56:00'),
('DKIM','mail','DomainKeys Identified Mail (stored as TXT)','2025-12-05 11:56:00'),
('DMARC','mail','Domain-based Message Authentication (stored as TXT)','2025-12-05 11:56:00'),
('DNAME','pointing','Delegation name record','2025-12-05 11:56:00'),
('HTTPS','extended','HTTPS Service Binding record','2025-12-05 11:56:00'),
('LOC','extended','Location record','2025-12-05 11:56:00'),
('MX','mail','Mail exchange record','2025-12-05 11:56:00'),
('NAPTR','extended','Naming Authority Pointer','2025-12-05 11:56:00'),
('NS','pointing','Name server record','2025-12-05 11:56:00'),
('PTR','other','Pointer record (reverse DNS)','2025-12-05 11:56:00'),
('RP','extended','Responsible Person record','2025-12-05 11:56:00'),
('SOA','other','Start of Authority record','2025-12-05 11:56:00'),
('SPF','mail','Sender Policy Framework (stored as TXT)','2025-12-05 11:56:00'),
('SRV','extended','Service location record','2025-12-05 11:56:00'),
('SSHFP','extended','SSH Fingerprint record','2025-12-05 11:56:00'),
('SVCB','extended','Service Binding record','2025-12-05 11:56:00'),
('TLSA','extended','DANE TLS Association record','2025-12-05 11:56:00'),
('TXT','extended','Text record','2025-12-05 11:56:00');
/*!40000 ALTER TABLE `record_types` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'admin','admin@example.local','$2y$12$lpCQ0Zsw25LuvXr9L/gIWO6xQNwRidtDC.ZmF8WIfZkSU324PfOsq','database','2025-10-19 12:27:41','2025-10-20 09:19:30',1),
(2,'guittou','guittou@gmail.com','$2y$10$.CJ6UeeKXSj7O3dZGcdtw.bjXze2e5z.n58462/hS.Rk4VgH5D21q','database','2025-10-20 09:24:16','2025-12-09 09:19:53',1),
(3,'toto','toto@mail.com','$2y$10$8mCrxLMX1whrzWkQ8lsGhecl0AIZweGMUmNTY3F8RwrQsjVlvh7rO','database','2025-11-27 13:42:30','2025-11-29 22:01:45',1),
(4,'titi','titi@mail.com','$2y$10$LDaNOJ6KHUFIhTOyy0lpZeXhxCq88OyaxMmQQcFw8Wv3cB2sg/hee','database','2025-11-29 17:51:56','2025-11-29 22:00:24',1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `zone_acl_entries`
--

DROP TABLE IF EXISTS `zone_acl_entries`;
/*!50001 DROP VIEW IF EXISTS `zone_acl_entries`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `zone_acl_entries` AS SELECT
 1 AS `id`,
  1 AS `zone_file_id`,
  1 AS `subject_type`,
  1 AS `subject_identifier`,
  1 AS `permission`,
  1 AS `created_by`,
  1 AS `created_at` */;
SET character_set_client = @saved_cs_client;

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
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=53632 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_file_includes`
--

LOCK TABLES `zone_file_includes` WRITE;
/*!40000 ALTER TABLE `zone_file_includes` DISABLE KEYS */;
/*!40000 ALTER TABLE `zone_file_includes` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=493 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
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
  `domain` varchar(255) DEFAULT NULL COMMENT 'Domain name for master zones (migrated from domaine_list)',
  `default_ttl` int(11) DEFAULT 86400 COMMENT 'Default TTL for zone records (seconds)',
  `soa_refresh` int(11) DEFAULT 10800 COMMENT 'SOA refresh timer (seconds)',
  `soa_retry` int(11) DEFAULT 900 COMMENT 'SOA retry timer (seconds)',
  `soa_expire` int(11) DEFAULT 604800 COMMENT 'SOA expire timer (seconds)',
  `soa_minimum` int(11) DEFAULT 3600 COMMENT 'SOA minimum/negative caching TTL (seconds)',
  `soa_rname` varchar(255) DEFAULT NULL COMMENT 'SOA RNAME - contact email for zone (e.g., admin.example.com or admin@example.com)',
  `mname` varchar(255) DEFAULT NULL COMMENT 'SOA MNAME - primary master nameserver for zone (e.g., ns1.example.com.)',
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
) ENGINE=InnoDB AUTO_INCREMENT=54913 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(54620,'fr.gouv.intradef','2snm.db','/media/partage/master/intradef',NULL,'include','active',1,NULL,'2025-12-09 09:55:38',NULL,'fr.gouv.intradef',86400,10800,900,604800,3600,NULL,NULL);
/*!40000 ALTER TABLE `zone_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'dns3_db'
--

--
-- Final view structure for view `zone_acl_entries`
--

/*!50001 DROP VIEW IF EXISTS `zone_acl_entries`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb3 */;
/*!50001 SET character_set_results     = utf8mb3 */;
/*!50001 SET collation_connection      = utf8mb3_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `zone_acl_entries` AS select `acl_entries`.`id` AS `id`,`acl_entries`.`zone_file_id` AS `zone_file_id`,`acl_entries`.`subject_type` AS `subject_type`,`acl_entries`.`subject_identifier` AS `subject_identifier`,`acl_entries`.`permission` AS `permission`,`acl_entries`.`created_by` AS `created_by`,`acl_entries`.`created_at` AS `created_at` from `acl_entries` where `acl_entries`.`zone_file_id` is not null and `acl_entries`.`subject_type` is not null and `acl_entries`.`subject_identifier` is not null */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-09 11:11:03
