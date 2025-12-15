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
) ENGINE=InnoDB AUTO_INCREMENT=219714 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dns_records`
--

LOCK TABLES `dns_records` WRITE;
/*!40000 ALTER TABLE `dns_records` DISABLE KEYS */;
INSERT INTO `dns_records` VALUES
(219289,54315,'NS','160.in-addr.arpa.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219290,54315,'NS','160.in-addr.arpa.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219291,54315,'NS','160.in-addr.arpa.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219292,54315,'NS','160.in-addr.arpa.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219293,54315,'NS','160.in-addr.arpa.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219294,54315,'PTR','128.77.1.160.in-addr.arpa.','exabdx03dbadm01.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03dbadm01.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219295,54315,'PTR','130.77.1.160.in-addr.arpa.','exabdx03celadm01.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm01.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219296,54315,'PTR','131.77.1.160.in-addr.arpa.','exabdx03celadm02.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm02.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219297,54315,'PTR','132.77.1.160.in-addr.arpa.','exabdx03celadm03.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm03.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219298,54315,'PTR','133.77.1.160.in-addr.arpa.','exabdx03dbadm01-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03dbadm01-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219299,54315,'PTR','134.77.1.160.in-addr.arpa.','exabdx03dbadm02-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03dbadm02-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219300,54315,'PTR','135.77.1.160.in-addr.arpa.','exabdx03celadm01-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm01-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219301,54315,'PTR','136.77.1.160.in-addr.arpa.','exabdx03celadm02-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm02-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219302,54315,'PTR','137.77.1.160.in-addr.arpa.','exabdx03celadm03-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03celadm03-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219303,54315,'PTR','138.77.1.160.in-addr.arpa.','exabdx03sw-adm0.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03sw-adm0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219304,54315,'PTR','139.77.1.160.in-addr.arpa.','exabdx03sw-iba0.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03sw-iba0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219305,54315,'PTR','140.77.1.160.in-addr.arpa.','exabdx03sw-ibb0.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03sw-ibb0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219306,54315,'PTR','128.78.1.160.in-addr.arpa.','exabdx0301vm1.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx0301vm1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219307,54315,'PTR','129.78.1.160.in-addr.arpa.','exabdx0302vm1.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx0302vm1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219308,54315,'PTR','130.78.1.160.in-addr.arpa.','exabdx0301vm1-vip.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx0301vm1-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219309,54315,'PTR','131.78.1.160.in-addr.arpa.','exabdx0302vm1-vip.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx0302vm1-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219310,54315,'PTR','132.78.1.160.in-addr.arpa.','exabdx03-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219311,54315,'PTR','133.78.1.160.in-addr.arpa.','exabdx03-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219312,54315,'PTR','134.78.1.160.in-addr.arpa.','exabdx03-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'exabdx03-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219313,54315,'PTR','128.100.150.160.in-addr.arpa.','examvl0201vm1.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219314,54315,'PTR','129.100.150.160.in-addr.arpa.','examvl0202vm1.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219315,54315,'PTR','130.100.150.160.in-addr.arpa.','examvl0201vm1-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm1-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219316,54315,'PTR','131.100.150.160.in-addr.arpa.','examvl0202vm1-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm1-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219317,54315,'PTR','132.100.150.160.in-addr.arpa.','examvl02-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219318,54315,'PTR','133.100.150.160.in-addr.arpa.','examvl02-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219319,54315,'PTR','134.100.150.160.in-addr.arpa.','examvl02-scan1.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan1.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219320,54315,'PTR','149.100.150.160.in-addr.arpa.','examvl0201vm2.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm2.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219321,54315,'PTR','150.100.150.160.in-addr.arpa.','examvl0202vm2.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm2.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219322,54315,'PTR','151.100.150.160.in-addr.arpa.','examvl0201vm2-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm2-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219323,54315,'PTR','152.100.150.160.in-addr.arpa.','examvl0202vm2-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm2-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219324,54315,'PTR','153.100.150.160.in-addr.arpa.','examvl02-scan2.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan2.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219325,54315,'PTR','154.100.150.160.in-addr.arpa.','examvl02-scan2.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan2.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219326,54315,'PTR','155.100.150.160.in-addr.arpa.','examvl02-scan2.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan2.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219327,54315,'PTR','163.100.150.160.in-addr.arpa.','examvl01-scan4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl01-scan4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219328,54315,'PTR','164.100.150.160.in-addr.arpa.','examvl01-scan4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl01-scan4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219329,54315,'PTR','170.100.150.160.in-addr.arpa.','examvl0202vm3.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm3.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219330,54315,'PTR','171.100.150.160.in-addr.arpa.','examvl0202vm3-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm3-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219331,54315,'PTR','172.100.150.160.in-addr.arpa.','examvl02-scan3.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan3.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219332,54315,'PTR','173.100.150.160.in-addr.arpa.','examvl02-scan3.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan3.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219333,54315,'PTR','174.100.150.160.in-addr.arpa.','examvl02-scan3.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan3.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219334,54315,'PTR','191.100.150.160.in-addr.arpa.','examvl0202vm4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219335,54315,'PTR','192.100.150.160.in-addr.arpa.','examvl0202vm4-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0202vm4-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219336,54315,'PTR','193.100.150.160.in-addr.arpa.','examvl02-scan4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219337,54315,'PTR','194.100.150.160.in-addr.arpa.','examvl02-scan4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219338,54315,'PTR','195.100.150.160.in-addr.arpa.','examvl02-scan4.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan4.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219339,54315,'PTR','212.100.150.160.in-addr.arpa.','examvl0201vm5.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm5.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219340,54315,'PTR','213.100.150.160.in-addr.arpa.','examvl0201vm5-vip.intradef.gouv.fr.',NULL,NULL,NULL,'examvl0201vm5-vip.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219341,54315,'PTR','214.100.150.160.in-addr.arpa.','examvl02-scan5.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan5.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219342,54315,'PTR','215.100.150.160.in-addr.arpa.','examvl02-scan5.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan5.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219343,54315,'PTR','216.100.150.160.in-addr.arpa.','examvl02-scan5.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02-scan5.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219344,54315,'PTR','128.101.150.160.in-addr.arpa.','examvl02dbadm01.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02dbadm01.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219345,54315,'PTR','129.101.150.160.in-addr.arpa.','examvl02dbadm02.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02dbadm02.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219346,54315,'PTR','130.101.150.160.in-addr.arpa.','examvl02celadm01.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm01.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219347,54315,'PTR','131.101.150.160.in-addr.arpa.','examvl02celadm02.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm02.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219348,54315,'PTR','132.101.150.160.in-addr.arpa.','examvl02celadm03.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm03.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219349,54315,'PTR','133.101.150.160.in-addr.arpa.','examvl02dbadm01-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02dbadm01-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219350,54315,'PTR','134.101.150.160.in-addr.arpa.','examvl02dbadm02-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02dbadm02-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219351,54315,'PTR','135.101.150.160.in-addr.arpa.','examvl02celadm01-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm01-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219352,54315,'PTR','136.101.150.160.in-addr.arpa.','examvl02celadm02-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm02-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219353,54315,'PTR','137.101.150.160.in-addr.arpa.','examvl02celadm03-ilom.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02celadm03-ilom.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219354,54315,'PTR','138.101.150.160.in-addr.arpa.','examvl02sw-adm0.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02sw-adm0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219355,54315,'PTR','139.101.150.160.in-addr.arpa.','examvl02sw-iba0.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02sw-iba0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219356,54315,'PTR','140.101.150.160.in-addr.arpa.','examvl02sw-ibb0.intradef.gouv.fr.',NULL,NULL,NULL,'examvl02sw-ibb0.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219357,54316,'NS','fr.gouv.defense.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219358,54316,'NS','fr.gouv.defense.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219359,54316,'NS','fr.gouv.defense.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219360,54316,'NS','fr.gouv.defense.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219361,54316,'NS','fr.gouv.defense.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219362,54316,'MX','*.fr.gouv.defense.','10 relais-mail.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,10,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'relais-mail.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219363,54319,'NS','fr.gouv.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219364,54319,'NS','fr.gouv.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219365,54319,'NS','fr.gouv.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219366,54319,'NS','fr.gouv.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219367,54319,'NS','fr.gouv.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219368,54319,'A','proxymeat.dr-cpt.fr.gouv.','221.34.43.80','221.34.43.80',NULL,NULL,NULL,NULL,30,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219369,54320,'NS','fr.gouv.defense.sirhmarine.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219370,54320,'NS','fr.gouv.defense.sirhmarine.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219371,54320,'NS','fr.gouv.defense.sirhmarine.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219372,54320,'NS','fr.gouv.defense.sirhmarine.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219373,54320,'NS','fr.gouv.defense.sirhmarine.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219374,54320,'A','hr.fr.gouv.defense.sirhmarine.','160.150.201.131','160.150.201.131',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219375,54320,'A','hr1.fr.gouv.defense.sirhmarine.','160.150.201.105','160.150.201.105',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219376,54320,'A','hr2.fr.gouv.defense.sirhmarine.','160.150.201.104','160.150.201.104',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219377,54320,'A','ads1.fr.gouv.defense.sirhmarine.','160.150.201.150','160.150.201.150',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219378,54320,'A','portail1.fr.gouv.defense.sirhmarine.','160.150.201.40','160.150.201.40',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219379,54320,'A','hr3.fr.gouv.defense.sirhmarine.','160.150.201.112','160.150.201.112',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219380,54320,'A','hr4.fr.gouv.defense.sirhmarine.','160.150.201.113','160.150.201.113',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219381,54320,'A','adm2.fr.gouv.defense.sirhmarine.','160.150.201.103','160.150.201.103',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219382,54320,'A','semb1.fr.gouv.defense.sirhmarine.','160.150.202.179','160.150.202.179',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219383,54320,'A','formation.fr.gouv.defense.sirhmarine.','160.150.38.52','160.150.38.52',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219384,54320,'A','ged.fr.gouv.defense.sirhmarine.','160.150.201.124','160.150.201.124',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219385,54320,'A','pi.fr.gouv.defense.sirhmarine.','160.150.201.146','160.150.201.146',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219386,54320,'A','ssm.fr.gouv.defense.sirhmarine.','160.150.201.171','160.150.201.171',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219387,54320,'A','pi1.fr.gouv.defense.sirhmarine.','160.150.201.16','160.150.201.16',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219388,54320,'A','pi2.fr.gouv.defense.sirhmarine.','160.150.201.17','160.150.201.17',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219389,54320,'A','rhapsodie-coffre.fr.gouv.defense.sirhmarine.','160.150.201.128','160.150.201.128',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219390,54320,'A','rhapsodie-coffre-api.fr.gouv.defense.sirhmarine.','160.150.201.128','160.150.201.128',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219391,54320,'A','pprod.rhapsodie-coffre.fr.gouv.defense.sirhmarine.','160.150.201.228','160.150.201.228',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219392,54320,'A','pprod.rhapsodie-coffre-api.fr.gouv.defense.sirhmarine.','160.150.201.228','160.150.201.228',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219393,54320,'A','gedpp.fr.gouv.defense.sirhmarine.','160.150.201.224','160.150.201.224',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219394,54320,'A','eccppas1.fr.gouv.defense.sirhmarine.','160.150.201.64','160.150.201.64',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219395,54320,'A','eccppas2.fr.gouv.defense.sirhmarine.','160.150.201.65','160.150.201.65',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219396,54320,'A','eccppdb.fr.gouv.defense.sirhmarine.','160.150.201.66','160.150.201.66',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219397,54320,'A','pi1pp.fr.gouv.defense.sirhmarine.','160.150.201.76','160.150.201.76',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219398,54320,'A','pi2pp.fr.gouv.defense.sirhmarine.','160.150.201.77','160.150.201.77',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219399,54320,'A','pipp.fr.gouv.defense.sirhmarine.','160.150.201.78','160.150.201.78',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219400,54320,'A','portailpp.fr.gouv.defense.sirhmarine.','160.150.201.70','160.150.201.70',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219401,54320,'A','sechr.fr.gouv.defense.sirhmarine.','160.1.42.40','160.1.42.40',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219402,54320,'A','sechr1.fr.gouv.defense.sirhmarine.','160.1.42.48','160.1.42.48',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219403,54320,'A','sechr2.fr.gouv.defense.sirhmarine.','160.1.42.49','160.1.42.49',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219404,54320,'A','sechr3.fr.gouv.defense.sirhmarine.','160.1.42.50','160.1.42.50',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219405,54320,'A','secpi.fr.gouv.defense.sirhmarine.','160.1.42.43','160.1.42.43',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219406,54320,'A','secpi1.fr.gouv.defense.sirhmarine.','160.1.42.56','160.1.42.56',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219407,54320,'A','secpi2.fr.gouv.defense.sirhmarine.','160.1.42.57','160.1.42.57',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219408,54320,'A','secads1.fr.gouv.defense.sirhmarine.','160.1.42.42','160.1.42.42',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219409,54320,'A','secged.fr.gouv.defense.sirhmarine.','160.1.42.58','160.1.42.58',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219410,54320,'A','secportail1.fr.gouv.defense.sirhmarine.','160.1.42.41','160.1.42.41',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219411,54320,'A','secssm.fr.gouv.defense.sirhmarine.','160.1.42.47','160.1.42.47',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219412,54321,'NS','221.in-addr.arpa.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219413,54321,'NS','221.in-addr.arpa.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219414,54321,'NS','221.in-addr.arpa.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219415,54321,'NS','221.in-addr.arpa.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219416,54321,'NS','221.in-addr.arpa.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219417,54321,'PTR','1.2.14.221.in-addr.arpa.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219418,54321,'PTR','1.3.14.221.in-addr.arpa.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219419,54321,'PTR','1.4.14.221.in-addr.arpa.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219420,54321,'PTR','1.5.14.221.in-addr.arpa.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219421,54321,'PTR','1.6.14.221.in-addr.arpa.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219422,54321,'PTR','170.65.10.221.in-addr.arpa.','annudef-alim-ctn.intradef.gouv.fr.',NULL,NULL,NULL,'annudef-alim-ctn.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219423,54321,'PTR','67.114.10.221.in-addr.arpa.','sigma-sso.intradef.gouv.fr.',NULL,NULL,NULL,'sigma-sso.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219424,54321,'PTR','6.149.10.221.in-addr.arpa.','asap.intradef.gouv.fr.',NULL,NULL,NULL,'asap.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219425,54321,'PTR','6.149.10.221.in-addr.arpa.','pfe.intradef.gouv.fr.',NULL,NULL,NULL,'pfe.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219426,54321,'PTR','6.149.10.221.in-addr.arpa.','gps.intradef.gouv.fr.',NULL,NULL,NULL,'gps.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219427,54321,'PTR','6.149.10.221.in-addr.arpa.','otc-air.intradef.gouv.fr.',NULL,NULL,NULL,'otc-air.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219428,54321,'PTR','6.149.10.221.in-addr.arpa.','lbe.intradef.gouv.fr.',NULL,NULL,NULL,'lbe.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219429,54321,'PTR','11.68.12.221.in-addr.arpa.','drinf-mbdxvz16v.intradef.gouv.fr.',NULL,NULL,NULL,'drinf-mbdxvz16v.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219430,54321,'PTR','12.68.12.221.in-addr.arpa.','drinf-mbdxvz17v.intradef.gouv.fr.',NULL,NULL,NULL,'drinf-mbdxvz17v.intradef.gouv.fr.',NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219431,54322,'NS','arpa.in-addr.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219432,54322,'NS','arpa.in-addr.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219433,54322,'NS','arpa.in-addr.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219434,54322,'NS','arpa.in-addr.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219435,54322,'NS','arpa.in-addr.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219436,54322,'NS','36.arpa.in-addr.','drstcl-mmvlll01v.air.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'drstcl-mmvlll01v.air.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219437,54322,'NS','36.arpa.in-addr.','drstcl-mmvlll02v.air.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'drstcl-mmvlll02v.air.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219438,54322,'NS','160.arpa.in-addr.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219439,54322,'NS','160.arpa.in-addr.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219440,54322,'NS','160.arpa.in-addr.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219441,54322,'NS','160.arpa.in-addr.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219442,54322,'NS','160.arpa.in-addr.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219443,54322,'NS','221.arpa.in-addr.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219444,54322,'NS','221.arpa.in-addr.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219445,54322,'NS','221.arpa.in-addr.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219446,54322,'NS','221.arpa.in-addr.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219447,54322,'NS','221.arpa.in-addr.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219448,54323,'NS','fr.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219449,54323,'NS','fr.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219450,54323,'NS','fr.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219451,54323,'NS','fr.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219452,54323,'NS','fr.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219453,54323,'A','dns-bdx.intradef.gouv.fr.','221.14.2.1','221.14.2.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219454,54323,'A','dns-llg.intradef.gouv.fr.','221.14.3.1','221.14.3.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219455,54323,'A','dns-rns.intradef.gouv.fr.','221.14.4.1','221.14.4.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219456,54323,'A','dns-mtz.intradef.gouv.fr.','221.14.5.1','221.14.5.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219457,54323,'A','dns-tln.intradef.gouv.fr.','221.14.6.1','221.14.6.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219458,54323,'NS','gouv.fr.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219459,54323,'NS','gouv.fr.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219460,54323,'NS','gouv.fr.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219461,54323,'NS','gouv.fr.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219462,54323,'NS','gouv.fr.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219463,54323,'A','proxy.gendarmerie.fr.','221.69.234.21','221.69.234.21',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219464,54323,'A','gendzilla.gendarmerie.fr.','221.69.234.22','221.69.234.22',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219465,54323,'A','smtp.gendarmerie.fr.','221.69.234.26','221.69.234.26',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219466,54323,'A','imap.gendarmerie.fr.','221.69.234.23','221.69.234.23',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219467,54323,'A','imap-gp.gendarmerie.fr.','221.69.234.24','221.69.234.24',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219468,54323,'A','imap.ad.gendarmerie.fr.','221.69.234.25','221.69.234.25',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219469,54323,'A','esb.gendarmerie.fr.','221.69.234.28','221.69.234.28',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219470,54323,'A','visabio.sso.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219471,54323,'A','visabio.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219472,54323,'A','proxycheopsv3.sso.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219473,54323,'A','intra-judiciaire.sso.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219474,54323,'A','auth.sso.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219475,54323,'A','crl.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219476,54323,'A','agenda.gendarmerie.fr.','221.69.234.30','221.69.234.30',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219477,54323,'A','amasis-minosweb.gendarmerie.fr.','221.69.1.201','221.69.1.201',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219478,54323,'A','www.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219479,54323,'A','www2.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219480,54323,'A','www3.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219481,54323,'A','www4.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219482,54323,'A','www5.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219483,54323,'A','www6.eopps.fr.','221.69.3.138','221.69.3.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219484,54323,'A','optyphon.fr.','111.38.10.83','111.38.10.83',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219485,54323,'A','calid.fr.','111.38.10.83','111.38.10.83',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219486,54323,'A','annudef.fr.','111.38.10.83','111.38.10.83',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219487,54323,'A','info-retraites.fr.','111.38.10.83','111.38.10.83',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219488,54324,'NS','fr.gouv.defense.terre.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219489,54324,'NS','fr.gouv.defense.terre.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219490,54324,'NS','fr.gouv.defense.terre.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219491,54324,'NS','fr.gouv.defense.terre.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219492,54324,'NS','fr.gouv.defense.terre.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219493,54324,'MX','oeat-se.fr.gouv.defense.terre.','1 mail.oeat-se.terre.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,900,1,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'mail.oeat-se.terre.defense.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219494,54324,'A','mail.oeat-se.fr.gouv.defense.terre.','221.10.29.83','221.10.29.83',NULL,NULL,NULL,NULL,900,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219495,54324,'A','www.fr.gouv.defense.terre.','221.10.12.117','221.10.12.117',NULL,NULL,NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219496,54324,'A','gestion-annuaire.fr.gouv.defense.terre.','208.128.160.70','208.128.160.70',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219497,54324,'CNAME','tomcat.fr.gouv.defense.terre.','gestion-annuaire.terre.defense.gouv.fr.',NULL,NULL,'gestion-annuaire.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219498,54324,'A','ldapw.fr.gouv.defense.terre.','208.128.160.72','208.128.160.72',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219499,54324,'A','ldaprepl1.fr.gouv.defense.terre.','208.128.160.73','208.128.160.73',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219500,54324,'A','ldaprepl2.fr.gouv.defense.terre.','208.128.160.74','208.128.160.74',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219501,54324,'CNAME','exportroles.fr.gouv.defense.terre.','ldaprepl1.terre.defense.gouv.fr.',NULL,NULL,'ldaprepl1.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219502,54324,'CNAME','exportunits.fr.gouv.defense.terre.','ldaprepl1.terre.defense.gouv.fr.',NULL,NULL,'ldaprepl1.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219503,54324,'A','aragorn.rt28-lyon.fr.gouv.defense.terre.','112.111.3.10','112.111.3.10',NULL,NULL,NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219504,54324,'A','apsi5033.rt53-lille.fr.gouv.defense.terre.','208.224.62.57','208.224.62.57',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219505,54324,'A','apsi3033.rt48-bordeaux.fr.gouv.defense.terre.','160.1.14.48','160.1.14.48',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219506,54324,'A','dns1.rt28-marseille.fr.gouv.defense.terre.','221.10.124.3','221.10.124.3',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219507,54324,'A','xxs22cirismld61.rt40-metz.fr.gouv.defense.terre.','160.163.244.24','160.163.244.24',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219508,54324,'A','www.concerto-formation.fr.gouv.defense.terre.','160.150.33.4','160.150.33.4',NULL,NULL,NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219509,54324,'CNAME','www.isatis-beat.fr.gouv.defense.terre.','mvl-svr-proxy-web-01.intradef.gouv.fr.',NULL,NULL,'mvl-svr-proxy-web-01.intradef.gouv.fr.',NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219510,54324,'CNAME','www.isatis-beat-dvd.fr.gouv.defense.terre.','mvl-svr-proxy-web-01.intradef.gouv.fr.',NULL,NULL,'mvl-svr-proxy-web-01.intradef.gouv.fr.',NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219511,54324,'CNAME','www.adonis.fr.gouv.defense.terre.','mvl-svr-proxy-web-02.intradef.gouv.fr.',NULL,NULL,'mvl-svr-proxy-web-02.intradef.gouv.fr.',NULL,NULL,300,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219512,54324,'A','bfao.drhat.fr.gouv.defense.terre.','208.129.2.19','208.129.2.19',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219513,54324,'A','www.drhat.fr.gouv.defense.terre.','208.129.2.20','208.129.2.20',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219514,54324,'A','exchange.drhat.fr.gouv.defense.terre.','208.129.2.29','208.129.2.29',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219515,54324,'A','listes.drhat.fr.gouv.defense.terre.','208.129.2.20','208.129.2.20',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219516,54324,'A','selinda.drhat.fr.gouv.defense.terre.','160.148.54.131','160.148.54.131',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219517,54324,'CNAME','ftp.drhat.fr.gouv.defense.terre.','www.drhat.terre.defense.gouv.fr.',NULL,NULL,'www.drhat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219518,54324,'CNAME','ext.drhat.fr.gouv.defense.terre.','www.drhat.terre.defense.gouv.fr.',NULL,NULL,'www.drhat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219519,54324,'CNAME','flux.drhat.fr.gouv.defense.terre.','www.drhat.terre.defense.gouv.fr.',NULL,NULL,'www.drhat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219520,54324,'CNAME','ww2.drhat.fr.gouv.defense.terre.','www.drhat.terre.defense.gouv.fr.',NULL,NULL,'www.drhat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219521,54324,'CNAME','idisk.drhat.fr.gouv.defense.terre.','www.drhat.terre.defense.gouv.fr.',NULL,NULL,'www.drhat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219522,54324,'A','srvweb.emat.fr.gouv.defense.terre.','221.11.72.151','221.11.72.151',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219523,54324,'A','portail-borg.emat.fr.gouv.defense.terre.','221.10.42.21','221.10.42.21',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219524,54324,'A','hydre.emat.fr.gouv.defense.terre.','160.136.193.42','160.136.193.42',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219525,54324,'A','hercules.emat.fr.gouv.defense.terre.','160.136.194.35','160.136.194.35',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219526,54324,'A','uni7w2000.emat.fr.gouv.defense.terre.','160.136.194.36','160.136.194.36',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219527,54324,'A','athena.emat.fr.gouv.defense.terre.','160.136.194.41','160.136.194.41',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219528,54324,'A','relais-mail.emat.fr.gouv.defense.terre.','160.136.200.112','160.136.200.112',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219529,54324,'A','owa.emat.fr.gouv.defense.terre.','160.138.10.37','160.138.10.37',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219530,54324,'A','mail.emat.fr.gouv.defense.terre.','160.138.10.37','160.138.10.37',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219531,54324,'A','webmail.emat.fr.gouv.defense.terre.','160.138.10.37','160.138.10.37',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219532,54324,'CNAME','www.emat.fr.gouv.defense.terre.','srvweb.emat.terre.defense.gouv.fr.',NULL,NULL,'srvweb.emat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219533,54324,'CNAME','asgbd.emat.fr.gouv.defense.terre.','hydre.emat.terre.defense.gouv.fr.',NULL,NULL,'hydre.emat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219534,54324,'CNAME','oraref.emat.fr.gouv.defense.terre.','hercules.emat.terre.defense.gouv.fr.',NULL,NULL,'hercules.emat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219535,54324,'CNAME','oraprod.emat.fr.gouv.defense.terre.','athena.emat.terre.defense.gouv.fr.',NULL,NULL,'athena.emat.terre.defense.gouv.fr.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219536,54324,'A','rt8-les-loges.fr.gouv.defense.terre.','160.138.101.43','160.138.101.43',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219537,54324,'A','apsi2033.rt8-les-loges.fr.gouv.defense.terre.','160.138.101.43','160.138.101.43',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219538,54325,'NS','fr.gouv.defense.orchestra.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219539,54325,'NS','fr.gouv.defense.orchestra.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219540,54325,'NS','fr.gouv.defense.orchestra.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219541,54325,'NS','fr.gouv.defense.orchestra.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219542,54325,'NS','fr.gouv.defense.orchestra.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219543,54325,'A','prd-saprouter.fr.gouv.defense.orchestra.','160.150.211.117','160.150.211.117',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219544,54325,'A','prd-ep.fr.gouv.defense.orchestra.','160.150.211.120','160.150.211.120',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219545,54325,'A','prd-bi.fr.gouv.defense.orchestra.','160.150.211.122','160.150.211.122',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219546,54325,'A','prd-ecc.fr.gouv.defense.orchestra.','160.150.211.119','160.150.211.119',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219547,54325,'A','prd-pi.fr.gouv.defense.orchestra.','160.150.211.123','160.150.211.123',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219548,54325,'A','nagios.fr.gouv.defense.orchestra.','160.150.211.182','160.150.211.182',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219549,54325,'A','orc-la10.fr.gouv.defense.orchestra.','160.150.211.210','160.150.211.210',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219550,54325,'A','orc-la11.fr.gouv.defense.orchestra.','160.150.211.211','160.150.211.211',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219551,54325,'A','orc-la62.fr.gouv.defense.orchestra.','160.150.211.159','160.150.211.159',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219552,54325,'A','orc-la52.fr.gouv.defense.orchestra.','160.150.211.156','160.150.211.156',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219553,54325,'CNAME','www.fr.gouv.defense.orchestra.','prd-ep.fr.gouv.defense.orchestra.',NULL,NULL,'prd-ep.fr.gouv.defense.orchestra.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219554,54325,'A','prp-saprouter.fr.gouv.defense.orchestra.','160.150.211.104','160.150.211.104',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219555,54325,'A','prp-pi.fr.gouv.defense.orchestra.','160.150.211.110','160.150.211.110',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219556,54325,'A','prp-ecc.fr.gouv.defense.orchestra.','160.150.211.106','160.150.211.106',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219557,54325,'A','prp-bi.fr.gouv.defense.orchestra.','160.150.211.109','160.150.211.109',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219558,54325,'A','orcvubp4.fr.gouv.defense.orchestra.','160.150.211.114','160.150.211.114',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219559,54325,'A','orcvubp4.fr.gouv.defense.orchestra.','160.1.73.204','160.1.73.204',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219560,54325,'A','orcvubi4.fr.gouv.defense.orchestra.','160.150.211.101','160.150.211.101',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219561,54325,'A','orc-la74.fr.gouv.defense.orchestra.','160.150.211.74','160.150.211.74',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219562,54325,'A','orc-la73.fr.gouv.defense.orchestra.','160.150.211.73','160.150.211.73',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219563,54325,'A','rec-ep.fr.gouv.defense.orchestra.','160.150.211.82','160.150.211.82',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219564,54325,'CNAME','rec.fr.gouv.defense.orchestra.','rec-ep.fr.gouv.defense.orchestra.',NULL,NULL,'rec-ep.fr.gouv.defense.orchestra.',NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219565,54325,'A','rec-bi.fr.gouv.defense.orchestra.','160.150.211.83','160.150.211.83',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219566,54325,'A','rec-ecc.fr.gouv.defense.orchestra.','160.150.211.81','160.150.211.81',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219567,54325,'A','pra-saprouter.fr.gouv.defense.orchestra.','160.1.73.207','160.1.73.207',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219568,54325,'A','orc-ubs1.fr.gouv.defense.orchestra.','160.1.73.101','160.1.73.101',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219569,54325,'A','orcsubs1.fr.gouv.defense.orchestra.','160.1.74.101','160.1.74.101',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219570,54325,'A','orcaubs1.fr.gouv.defense.orchestra.','160.1.75.101','160.1.75.101',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219571,54325,'A','orc-ubs2.fr.gouv.defense.orchestra.','160.1.73.102','160.1.73.102',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219572,54325,'A','orcsubs2.fr.gouv.defense.orchestra.','160.1.74.102','160.1.74.102',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219573,54325,'A','orcaubs2.fr.gouv.defense.orchestra.','160.1.75.102','160.1.75.102',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219574,54325,'A','orc-ubs3.fr.gouv.defense.orchestra.','160.1.73.103','160.1.73.103',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219575,54325,'A','orcsubs3.fr.gouv.defense.orchestra.','160.1.74.103','160.1.74.103',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219576,54325,'A','orcaubs3.fr.gouv.defense.orchestra.','160.1.75.103','160.1.75.103',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219577,54325,'A','orc-ubs4.fr.gouv.defense.orchestra.','160.1.73.104','160.1.73.104',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219578,54325,'A','orcsubs4.fr.gouv.defense.orchestra.','160.1.74.104','160.1.74.104',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219579,54325,'A','orcaubs4.fr.gouv.defense.orchestra.','160.1.75.104','160.1.75.104',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219580,54325,'A','orc-lbs5.fr.gouv.defense.orchestra.','160.1.73.105','160.1.73.105',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219581,54325,'A','orcslbs5.fr.gouv.defense.orchestra.','160.1.74.105','160.1.74.105',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219582,54325,'A','orcalbs5.fr.gouv.defense.orchestra.','160.1.75.105','160.1.75.105',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219583,54325,'A','orc-las6.fr.gouv.defense.orchestra.','160.1.73.106','160.1.73.106',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219584,54325,'A','orcslas6.fr.gouv.defense.orchestra.','160.1.74.106','160.1.74.106',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219585,54325,'A','orcalas6.fr.gouv.defense.orchestra.','160.1.75.106','160.1.75.106',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219586,54325,'A','orc-las7.fr.gouv.defense.orchestra.','160.1.73.107','160.1.73.107',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219587,54325,'A','orcslas7.fr.gouv.defense.orchestra.','160.1.74.107','160.1.74.107',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219588,54325,'A','orcalas7.fr.gouv.defense.orchestra.','160.1.75.107','160.1.75.107',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219589,54325,'A','orc-las8.fr.gouv.defense.orchestra.','160.1.73.108','160.1.73.108',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219590,54325,'A','orcslas8.fr.gouv.defense.orchestra.','160.1.74.108','160.1.74.108',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219591,54325,'A','orcalas8.fr.gouv.defense.orchestra.','160.1.75.108','160.1.75.108',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219592,54325,'A','orc-las9.fr.gouv.defense.orchestra.','160.1.73.109','160.1.73.109',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219593,54325,'A','orcslas9.fr.gouv.defense.orchestra.','160.1.74.109','160.1.74.109',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219594,54325,'A','orcalas9.fr.gouv.defense.orchestra.','160.1.75.109','160.1.75.109',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219595,54325,'A','orc-lasa.fr.gouv.defense.orchestra.','160.1.73.110','160.1.73.110',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219596,54325,'A','orcslasa.fr.gouv.defense.orchestra.','160.1.74.110','160.1.74.110',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219597,54325,'A','orcalasa.fr.gouv.defense.orchestra.','160.1.75.110','160.1.75.110',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219598,54325,'A','orc-lasb.fr.gouv.defense.orchestra.','160.1.73.111','160.1.73.111',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219599,54325,'A','orcslasb.fr.gouv.defense.orchestra.','160.1.74.111','160.1.74.111',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219600,54325,'A','orcalasb.fr.gouv.defense.orchestra.','160.1.75.111','160.1.75.111',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219601,54325,'A','orc-lasc.fr.gouv.defense.orchestra.','160.1.73.112','160.1.73.112',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219602,54325,'A','orcslasc.fr.gouv.defense.orchestra.','160.1.74.112','160.1.74.112',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219603,54325,'A','orcalasc.fr.gouv.defense.orchestra.','160.1.75.112','160.1.75.112',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219604,54325,'A','orc-lasd.fr.gouv.defense.orchestra.','160.1.73.113','160.1.73.113',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219605,54325,'A','orcslasd.fr.gouv.defense.orchestra.','160.1.74.113','160.1.74.113',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219606,54325,'A','orcalasd.fr.gouv.defense.orchestra.','160.1.75.113','160.1.75.113',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219607,54325,'A','orcsubse.fr.gouv.defense.orchestra.','160.1.74.114','160.1.74.114',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219608,54325,'A','orcaubse.fr.gouv.defense.orchestra.','160.1.75.114','160.1.75.114',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219609,54325,'A','orcsubsf.fr.gouv.defense.orchestra.','160.1.74.115','160.1.74.115',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219610,54325,'A','orcaubsf.fr.gouv.defense.orchestra.','160.1.75.115','160.1.75.115',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219611,54325,'A','orcsubsg.fr.gouv.defense.orchestra.','160.1.74.116','160.1.74.116',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219612,54325,'A','orcaubsg.fr.gouv.defense.orchestra.','160.1.75.116','160.1.75.116',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219613,54325,'A','orcvubp1.fr.gouv.defense.orchestra.','160.150.211.201','160.150.211.201',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219614,54325,'A','orcvubp2.fr.gouv.defense.orchestra.','160.1.73.202','160.1.73.202',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219615,54325,'A','orcvubp3.fr.gouv.defense.orchestra.','160.1.73.203','160.1.73.203',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219616,54325,'A','orcvubp5.fr.gouv.defense.orchestra.','160.1.73.205','160.1.73.205',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219617,54325,'A','orcvubp6.fr.gouv.defense.orchestra.','160.1.73.206','160.1.73.206',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219618,54325,'A','orcvlapa.fr.gouv.defense.orchestra.','160.1.73.207','160.1.73.207',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219619,54325,'A','orcvlapb.fr.gouv.defense.orchestra.','160.1.73.208','160.1.73.208',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219620,54325,'A','orcvlapc.fr.gouv.defense.orchestra.','160.1.73.209','160.1.73.209',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219621,54325,'A','orcvlapd.fr.gouv.defense.orchestra.','160.1.73.210','160.1.73.210',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219622,54325,'A','orcvlape.fr.gouv.defense.orchestra.','160.1.73.211','160.1.73.211',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219623,54325,'A','orcvlapf.fr.gouv.defense.orchestra.','160.1.73.212','160.1.73.212',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219624,54325,'A','orcvlapg.fr.gouv.defense.orchestra.','160.1.73.213','160.1.73.213',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219625,54325,'A','orcvubp7.fr.gouv.defense.orchestra.','160.1.73.214','160.1.73.214',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219626,54325,'A','orcvubm1.fr.gouv.defense.orchestra.','160.150.211.11','160.150.211.11',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219627,54325,'A','orcalysl.fr.gouv.defense.orchestra.','160.1.75.121','160.1.75.121',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219628,54325,'A','orcalysq.fr.gouv.defense.orchestra.','160.1.75.126','160.1.75.126',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219629,54325,'A','storage1-p2000.fr.gouv.defense.orchestra.','160.1.75.139','160.1.75.139',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219630,54325,'A','storage2-p2000.fr.gouv.defense.orchestra.','160.1.75.140','160.1.75.140',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219631,54325,'A','orcauysh.fr.gouv.defense.orchestra.','160.1.75.117','160.1.75.117',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219632,54325,'A','orcauysi.fr.gouv.defense.orchestra.','160.1.75.118','160.1.75.118',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219633,54325,'A','orcauysj.fr.gouv.defense.orchestra.','160.1.75.119','160.1.75.119',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219634,54325,'A','orcauysk.fr.gouv.defense.orchestra.','160.1.75.120','160.1.75.120',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219635,54325,'A','orcauysm.fr.gouv.defense.orchestra.','160.1.75.122','160.1.75.122',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219636,54325,'A','orcauyso.fr.gouv.defense.orchestra.','160.1.75.124','160.1.75.124',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219637,54325,'A','orcauysv.fr.gouv.defense.orchestra.','160.1.75.131','160.1.75.131',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219638,54325,'A','orcalysw.fr.gouv.defense.orchestra.','160.1.75.132','160.1.75.132',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219639,54325,'A','orcalysx.fr.gouv.defense.orchestra.','160.1.75.133','160.1.75.133',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219640,54325,'A','orcalysy.fr.gouv.defense.orchestra.','160.1.75.134','160.1.75.134',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219641,54325,'A','orcalysz.fr.gouv.defense.orchestra.','160.1.75.135','160.1.75.135',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219642,54325,'A','orcalys1.fr.gouv.defense.orchestra.','160.1.75.136','160.1.75.136',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219643,54325,'A','orcalys2.fr.gouv.defense.orchestra.','160.1.75.137','160.1.75.137',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219644,54325,'A','orcalys3.fr.gouv.defense.orchestra.','160.1.75.138','160.1.75.138',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219645,54325,'A','orcubi4.fr.gouv.defense.orchestra.','160.150.221.101','160.150.221.101',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219646,54325,'A','orcvubw1.fr.gouv.defense.orchestra.','160.150.211.157','160.150.211.157',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219647,54326,'NS','root.','dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-bdx.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219648,54326,'NS','root.','dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-llg.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219649,54326,'NS','root.','dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-rns.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219650,54326,'NS','root.','dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-tln.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219651,54326,'NS','root.','dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dns-mtz.intradef.gouv.fr.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219652,54326,'A','sophosx1.net.root.','127.0.0.1','127.0.0.1',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219653,54326,'A','osce11-fr-census.trendmicro.com.root.','127.0.0.1','127.0.0.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219654,54326,'A','osce12-fr-census.trendmicro.com.root.','127.0.0.1','127.0.0.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219655,54326,'A','osce13-fr-census.trendmicro.com.root.','127.0.0.1','127.0.0.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219656,54326,'A','osce14-fr-census.trendmicro.com.root.','127.0.0.1','127.0.0.1',NULL,NULL,NULL,NULL,84600,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219657,54327,'A','DR2NM-MIELWZ01V.fr.gouv.intradef.','110.55.255.113','110.55.255.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219658,54327,'CNAME','portail-2snm-centralisation-iel.fr.gouv.intradef.','DR2NM-MIELWZ01V.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELWZ01V.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219659,54327,'A','DR2NM-MIELLW01V.fr.gouv.intradef.','110.55.255.147','110.55.255.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219660,54327,'A','DR2NM-MIELLW01V.fr.gouv.intradef.','110.55.255.179','110.55.255.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219661,54327,'A','portail-2snm-siad-iel.fr.gouv.intradef.','110.55.255.147','110.55.255.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219662,54327,'A','DR2NM-MIELZP01P.fr.gouv.intradef.','110.55.255.59','110.55.255.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219663,54327,'CNAME','portail-2snm-parefeuintradef-iel.fr.gouv.intradef.','DR2NM-MIELZP01P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELZP01P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219664,54327,'A','DR2NM-MIELZP02P.fr.gouv.intradef.','110.55.255.91','110.55.255.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219665,54327,'CNAME','portail-2snm-parefeubalise-iel.fr.gouv.intradef.','DR2NM-MIELZP02P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MIELZP02P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219666,54327,'A','DR2NM-MIELLP01V.fr.gouv.intradef.','110.55.255.61','110.55.255.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219667,54327,'A','DR2NM-MIELLP02V.fr.gouv.intradef.','110.55.255.60','110.55.255.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219668,54327,'A','DR2NM-MIELLA01V.fr.gouv.intradef.','110.55.255.180','110.55.255.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219669,54327,'A','DR2NM-MIELLA02V.fr.gouv.intradef.','110.55.255.181','110.55.255.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219670,54327,'A','DR2NM-MIELLA03V.fr.gouv.intradef.','110.55.255.182','110.55.255.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219671,54327,'A','DR2NM-MIELLA04V.fr.gouv.intradef.','110.55.255.183','110.55.255.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219672,54327,'A','DR2NM-MIELLZ01V.fr.gouv.intradef.','110.55.255.177','110.55.255.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219673,54327,'A','DR2NM-MIELLB01V.fr.gouv.intradef.','110.55.255.178','110.55.255.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219674,54327,'A','DR2NM-MIELLS01V.fr.gouv.intradef.','110.55.255.12','110.55.255.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219675,54327,'A','DR2NM-MIELLS02V.fr.gouv.intradef.','110.55.255.14','110.55.255.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219676,54327,'A','DR2NM-MBTPWZ01V.fr.gouv.intradef.','111.30.237.113','111.30.237.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219677,54327,'CNAME','portail-2snm-centralisation-btp.fr.gouv.intradef.','DR2NM-MBTPWZ01V.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPWZ01V.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219678,54327,'A','DR2NM-MBTPLW01V.fr.gouv.intradef.','111.30.237.147','111.30.237.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219679,54327,'A','DR2NM-MBTPLW01V.fr.gouv.intradef.','111.30.237.179','111.30.237.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219680,54327,'A','DR2NM-MBTPZP01P.fr.gouv.intradef.','111.30.237.59','111.30.237.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219681,54327,'CNAME','portail-2snm-parefeuintradef-btp.fr.gouv.intradef.','DR2NM-MBTPZP01P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPZP01P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219682,54327,'A','DR2NM-MBTPZP02P.fr.gouv.intradef.','111.30.237.91','111.30.237.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219683,54327,'CNAME','portail-2snm-parefeubalise-btp.fr.gouv.intradef.','DR2NM-MBTPZP02P.fr.gouv.intradef.',NULL,NULL,'DR2NM-MBTPZP02P.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219684,54327,'A','DR2NM-MBTPLP01V.fr.gouv.intradef.','111.30.237.61','111.30.237.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219685,54327,'A','DR2NM-MBTPLP02V.fr.gouv.intradef.','111.30.237.60','111.30.237.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219686,54327,'A','DR2NM-MBTPLA01V.fr.gouv.intradef.','111.30.237.180','111.30.237.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219687,54327,'A','DR2NM-MBTPLA02V.fr.gouv.intradef.','111.30.237.181','111.30.237.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219688,54327,'A','DR2NM-MBTPLA03V.fr.gouv.intradef.','111.30.237.182','111.30.237.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219689,54327,'A','DR2NM-MBTPLA04V.fr.gouv.intradef.','111.30.237.183','111.30.237.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219690,54327,'A','DR2NM-MBTPLZ01V.fr.gouv.intradef.','111.30.237.177','111.30.237.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219691,54327,'A','DR2NM-MBTPLB01V.fr.gouv.intradef.','111.30.237.178','111.30.237.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219692,54327,'A','DR2NM-MBTPLS01V.fr.gouv.intradef.','111.30.237.12','111.30.237.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219693,54327,'A','DR2NM-MBTPLS02V.fr.gouv.intradef.','111.30.237.14','111.30.237.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219694,54327,'A','portail-2snm-siad-btp.fr.gouv.intradef.','111.30.237.147','111.30.237.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219695,54327,'A','DR2NM-MCGAWZ01V.fr.gouv.intradef.','110.232.134.113','110.232.134.113',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219696,54327,'A','dr2nm-mcgalw01v.fr.gouv.intradef.','110.232.134.147','110.232.134.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219697,54327,'A','dr2nm-mcgalw01v.fr.gouv.intradef.','110.232.134.179','110.232.134.179',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219698,54327,'A','dr2nm-mcgazp01p.fr.gouv.intradef.','110.232.134.59','110.232.134.59',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219699,54327,'A','dr2nm-mcgazp02p.fr.gouv.intradef.','110.232.134.91','110.232.134.91',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219700,54327,'A','dr2nm-mcgalp01v.fr.gouv.intradef.','110.232.134.61','110.232.134.61',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219701,54327,'A','dr2nm-mcgalp02v.fr.gouv.intradef.','110.232.134.60','110.232.134.60',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219702,54327,'A','dr2nm-mcgala01v.fr.gouv.intradef.','110.232.134.180','110.232.134.180',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219703,54327,'A','dr2nm-mcgala02v.fr.gouv.intradef.','110.232.134.181','110.232.134.181',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219704,54327,'A','dr2nm-mcgala03v.fr.gouv.intradef.','110.232.134.182','110.232.134.182',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219705,54327,'A','dr2nm-mcgala04v.fr.gouv.intradef.','110.232.134.183','110.232.134.183',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219706,54327,'A','dr2nm-mcgalz01v.fr.gouv.intradef.','110.232.134.177','110.232.134.177',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219707,54327,'A','dr2nm-mcgalb01v.fr.gouv.intradef.','110.232.134.178','110.232.134.178',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219708,54327,'A','dr2nm-mcgals01v.fr.gouv.intradef.','110.232.134.12','110.232.134.12',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219709,54327,'A','dr2nm-mcgals02v.fr.gouv.intradef.','110.232.134.14','110.232.134.14',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219710,54327,'A','portail-2snm-siad-cga.fr.gouv.intradef.','110.232.134.147','110.232.134.147',NULL,NULL,NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219711,54327,'CNAME','portail-2snm-centralisation-cga.fr.gouv.intradef.','dr2nm-mcgawz01v.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgawz01v.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219712,54327,'CNAME','portail-2snm-parefeuintradef-cga.fr.gouv.intradef.','dr2nm-mcgazp01p.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgazp01p.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(219713,54327,'CNAME','portail-2snm-parefeubalise-cga.fr.gouv.intradef.','dr2nm-mcgazp02p.fr.gouv.intradef.',NULL,NULL,'dr2nm-mcgazp02p.fr.gouv.intradef.',NULL,NULL,86400,NULL,NULL,'active',1,'2025-12-09 09:52:16',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
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
INSERT INTO `zone_file_validation` VALUES
(492,54316,'pending','Validation queued for background processing','2025-12-09 09:53:37',2);
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
) ENGINE=InnoDB AUTO_INCREMENT=54620 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `zone_files`
--

LOCK TABLES `zone_files` WRITE;
/*!40000 ALTER TABLE `zone_files` DISABLE KEYS */;
INSERT INTO `zone_files` VALUES
(54315,'160.in-addr.arpa','160.in-addr.arpa.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'160.in-addr.arpa',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54316,'fr.gouv.defense','fr.gouv.defense.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'fr.gouv.defense',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54317,'fr.gouv.defense.sga','drh-md.db','/media/partage/master/sga',NULL,'include','active',1,NULL,'2025-12-09 09:52:15',NULL,'fr.gouv.defense.sga',86400,10800,900,604800,3600,NULL,NULL),
(54319,'fr.gouv','fr.gouv.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'fr.gouv',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54320,'fr.gouv.defense.sirhmarine','fr.gouv.defense.sirhmarine.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'fr.gouv.defense.sirhmarine',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54321,'221.in-addr.arpa','221.in-addr.arpa.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'221.in-addr.arpa',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54322,'arpa.in-addr','arpa.in-addr.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:15',NULL,'arpa.in-addr',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54323,'fr','fr.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:16',NULL,'fr',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54324,'fr.gouv.defense.terre','fr.gouv.defense.terre.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:16',NULL,'fr.gouv.defense.terre',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54325,'fr.gouv.defense.orchestra','fr.gouv.defense.orchestra.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:16',NULL,'fr.gouv.defense.orchestra',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54326,'root','root.db','/media/partage/master',NULL,'master','active',1,NULL,'2025-12-09 09:52:16',NULL,'root',86400,10800,900,604800,3600,'dnsmaster.intradef.gouv.fr.','dns-hidden.intradef.gouv.fr.'),
(54327,'fr.gouv.intradef','2snm.db','/media/partage/master/intradef',NULL,'include','active',1,NULL,'2025-12-09 09:52:16',NULL,'fr.gouv.intradef',86400,10800,900,604800,3600,NULL,NULL);
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

-- Dump completed on 2025-12-09 10:54:54
