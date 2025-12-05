# DNS3 Database Schema Documentation

> **Last Updated**: 2025-12-05  
> **Schema Source**: `database.sql`  
> **Exported From**: MariaDB 10.11.14

This document describes the database schema for the DNS3 application, including all tables, their purpose, fields, foreign keys, and indexes.

---

## Changelog

| Date       | Summary                                                                 |
|------------|-------------------------------------------------------------------------|
| 2025-12-05 | **SOA/TTL Fields for Zone Files**: Added columns `default_ttl`, `soa_refresh`, `soa_retry`, `soa_expire`, `soa_minimum`, `soa_rname` to `zone_files` table for customizable SOA timers and default TTL. See `migrations/20251205_add_soa_fields_to_zone_files.sql`. |
| 2025-12-05 | **Extended DNS Record Types Migration**: Migrated `dns_records.record_type` from ENUM to VARCHAR(50) for extensibility. Added new columns for SRV, TLSA, SSHFP, CAA, NAPTR, SVCB/HTTPS, LOC, and RP record types. Added `record_types` reference table with UI categories. See `migrations/README.md` for details. |
| 2025-12-05 | Removed legacy/migration tables (`acl_entries_old`, `acl_entries_new`, `zone_file_includes_new`). Updated `acl_history` FK reference. |
| 2025-12-04 | Initial schema documentation based on `structure_ok_dns3_db.sql` export |

---

## Table of Contents

1. [Core Tables](#core-tables)
   - [users](#users)
   - [roles](#roles)
   - [user_roles](#user_roles)
   - [sessions](#sessions)
   - [auth_mappings](#auth_mappings)
2. [Zone Management](#zone-management)
   - [zone_files](#zone_files)
   - [zone_file_includes](#zone_file_includes)
   - [zone_file_history](#zone_file_history)
   - [zone_file_validation](#zone_file_validation)
3. [DNS Records](#dns-records)
   - [dns_records](#dns_records)
   - [dns_record_history](#dns_record_history)
4. [Access Control](#access-control)
   - [acl_entries](#acl_entries)
   - [acl_history](#acl_history)
   - [zone_acl_entries (view)](#zone_acl_entries-view)
5. [Schema Cleanup Note (2025-12-05)](#schema-cleanup-note-2025-12-05)
6. [Foreign Keys Summary](#foreign-keys-summary)
7. [History & Audit Policy](#history--audit-policy)
8. [Useful SQL Queries](#useful-sql-queries)
9. [Import Instructions](#import-instructions)
10. [Known Documentation Divergences](#known-documentation-divergences)

---

## Core Tables

### users

Stores user accounts for authentication and authorization.

| Column       | Type                              | Description                          |
|--------------|-----------------------------------|--------------------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT         | Unique user identifier               |
| `username`   | VARCHAR(100) UNIQUE               | Login username                       |
| `email`      | VARCHAR(255) UNIQUE               | User email address                   |
| `password`   | VARCHAR(255)                      | Hashed password (bcrypt)             |
| `auth_method`| ENUM('database','ad','ldap')      | Authentication source                |
| `created_at` | TIMESTAMP                         | Account creation time                |
| `last_login` | TIMESTAMP NULL                    | Last successful login                |
| `is_active`  | TINYINT(1) DEFAULT 1              | Account status (1=active, 0=disabled)|

**Indexes**: `idx_username`, `idx_email`

---

### roles

Defines permission roles assignable to users.

| Column       | Type                      | Description            |
|--------------|---------------------------|------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT | Unique role identifier |
| `name`       | VARCHAR(50) UNIQUE        | Role name (e.g., admin)|
| `description`| VARCHAR(255) NULL         | Role description       |
| `created_at` | TIMESTAMP                 | Role creation time     |

**Indexes**: `idx_name`

---

### user_roles

Junction table linking users to roles (many-to-many).

| Column      | Type      | Description          |
|-------------|-----------|----------------------|
| `user_id`   | INT(11)   | FK → users.id        |
| `role_id`   | INT(11)   | FK → roles.id        |
| `assigned_at`| TIMESTAMP| Role assignment time |

**Primary Key**: (`user_id`, `role_id`)  
**Foreign Keys**: CASCADE on delete for both

---

### sessions

Stores active user sessions.

| Column         | Type         | Description                 |
|----------------|--------------|-----------------------------|
| `id`           | VARCHAR(128) | Session ID (PK)             |
| `user_id`      | INT(11)      | FK → users.id               |
| `ip_address`   | VARCHAR(45)  | Client IP address           |
| `user_agent`   | VARCHAR(255) | Browser/client user agent   |
| `created_at`   | TIMESTAMP    | Session start time          |
| `last_activity`| TIMESTAMP    | Last activity (auto-update) |

**Foreign Keys**: CASCADE on delete

---

### auth_mappings

Maps AD groups or LDAP DNs to application roles for external authentication.

| Column       | Type                  | Description                         |
|--------------|-----------------------|-------------------------------------|
| `id`         | INT(11) PK            | Unique mapping identifier           |
| `source`     | ENUM('ad','ldap')     | Authentication source               |
| `dn_or_group`| VARCHAR(255)          | AD group CN or LDAP DN/OU path      |
| `role_id`    | INT(11)               | FK → roles.id                       |
| `created_by` | INT(11) NULL          | FK → users.id (who created mapping) |
| `created_at` | TIMESTAMP             | Mapping creation time               |
| `notes`      | TEXT NULL             | Optional description                |

**Unique Constraint**: (`source`, `dn_or_group`, `role_id`)

---

## Zone Management

### zone_files

Primary table for DNS zone files. Supports both master zones and include files.

| Column      | Type                              | Description                                      |
|-------------|-----------------------------------|--------------------------------------------------|
| `id`        | INT(11) PK AUTO_INCREMENT         | Unique zone file identifier                      |
| `name`      | VARCHAR(255) UNIQUE               | Zone name (e.g., example.com)                    |
| `filename`  | VARCHAR(255)                      | Zone file name                                   |
| `directory` | VARCHAR(255) NULL                 | Directory path for zone file                     |
| `content`   | TEXT NULL                         | Zone file content                                |
| `file_type` | ENUM('master','include')          | Type of zone file                                |
| `status`    | ENUM('active','inactive','deleted')| Zone status                                     |
| `domain`    | VARCHAR(255) NULL                 | Domain name for master zones (migrated from domaine_list) |
| `default_ttl` | INT(11) DEFAULT 86400           | Default TTL for zone records (seconds) - used in $TTL directive |
| `soa_refresh` | INT(11) DEFAULT 10800           | SOA refresh timer (seconds)                      |
| `soa_retry` | INT(11) DEFAULT 900               | SOA retry timer (seconds)                        |
| `soa_expire` | INT(11) DEFAULT 604800           | SOA expire timer (seconds)                       |
| `soa_minimum` | INT(11) DEFAULT 3600            | SOA minimum/negative caching TTL (seconds)       |
| `soa_rname` | VARCHAR(255) NULL                 | SOA RNAME - contact email for zone               |
| `created_by`| INT(11) NULL                      | FK → users.id                                    |
| `updated_by`| INT(11) NULL                      | FK → users.id                                    |
| `created_at`| TIMESTAMP                         | Creation time                                    |
| `updated_at`| TIMESTAMP NULL                    | Last update time                                 |

**Indexes**: `idx_name`, `idx_file_type`, `idx_status`, `idx_created_by`, `idx_zone_type_status_name`, `idx_directory`, `idx_domain`

> **Migration Note (2025-12-05)**: Added columns `default_ttl`, `soa_refresh`, `soa_retry`, `soa_expire`, `soa_minimum`, and `soa_rname` to support customizable SOA timers and default TTL for master zones. See `migrations/20251205_add_soa_fields_to_zone_files.sql` for the ALTER TABLE statements.

---

### zone_file_includes

Links parent zone files (master or include) to their included files. Supports recursive/nested includes.

| Column      | Type                      | Description                                   |
|-------------|---------------------------|-----------------------------------------------|
| `id`        | INT(11) PK AUTO_INCREMENT | Unique include relationship identifier        |
| `parent_id` | INT(11)                   | FK → zone_files.id (parent zone)              |
| `include_id`| INT(11)                   | FK → zone_files.id (included zone)            |
| `position`  | INT(11) DEFAULT 0         | Order position for includes                   |
| `created_at`| DATETIME                  | Relationship creation time                    |

**Unique Constraints**:
- `ux_parent_include` (`parent_id`, `include_id`) — prevents duplicate parent/include pairs
- `ux_include_single_parent` (`include_id`) — enforces single parent per include (prevents multiple assignments)

**Foreign Keys**: CASCADE on delete for both

> **Note**: The column names are `parent_id` and `include_id`. Some older documentation may reference `master_id` and `include_id` — these are now deprecated.

---

### zone_file_history

Audit trail for zone file changes including content modifications.

| Column       | Type                                                                               | Description                    |
|--------------|------------------------------------------------------------------------------------|--------------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT                                                          | Unique history entry           |
| `zone_file_id`| INT(11)                                                                           | FK → zone_files.id             |
| `action`     | ENUM('created','updated','status_changed','content_changed','assign_include','reassign_include') | Type of change |
| `name`       | VARCHAR(255)                                                                       | Zone name at time of change    |
| `filename`   | VARCHAR(255)                                                                       | Filename at time of change     |
| `file_type`  | ENUM('master','include')                                                           | File type at time of change    |
| `old_status` | ENUM('active','inactive','deleted') NULL                                           | Previous status                |
| `new_status` | ENUM('active','inactive','deleted')                                                | New status                     |
| `old_content`| TEXT NULL                                                                          | Previous zone file content     |
| `new_content`| TEXT NULL                                                                          | New zone file content          |
| `changed_by` | INT(11)                                                                            | FK → users.id                  |
| `changed_at` | TIMESTAMP                                                                          | Change timestamp               |
| `notes`      | TEXT NULL                                                                          | Optional notes                 |

**Indexes**: `idx_zone_file_id`, `idx_action`, `idx_changed_at`

---

### zone_file_validation

Stores validation results from `named-checkzone` command.

| Column       | Type                                    | Description                             |
|--------------|-----------------------------------------|-----------------------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT               | Unique validation entry                 |
| `zone_file_id`| INT(11)                                | FK → zone_files.id                      |
| `status`     | ENUM('pending','passed','failed','error')| Validation status                      |
| `output`     | TEXT NULL                               | Output from named-checkzone command     |
| `checked_at` | TIMESTAMP                               | Validation time                         |
| `run_by`     | INT(11) NULL                            | FK → users.id (NULL for background jobs)|

**Indexes**: `idx_zone_file_id`, `idx_status`, `idx_checked_at`, `idx_zone_file_checked`

---

## DNS Records

### record_types

Reference table for extensible DNS record types with UI categorization. This table provides a catalog of supported record types.

| Column       | Type                      | Description                                        |
|--------------|---------------------------|----------------------------------------------------|
| `name`       | VARCHAR(50) PK            | Record type name (e.g., A, AAAA, CNAME)            |
| `category`   | VARCHAR(50) DEFAULT 'other'| Category for UI grouping (pointing, extended, mail)|
| `description`| VARCHAR(255) NULL         | Human-readable description                         |
| `created_at` | TIMESTAMP                 | Creation time                                      |

**Categories**:
- `pointing`: A, AAAA, NS, CNAME, DNAME
- `extended`: CAA, TXT, NAPTR, SRV, LOC, SSHFP, TLSA, RP, SVCB, HTTPS
- `mail`: MX, SPF, DKIM, DMARC
- `other`: PTR, SOA

---

### dns_records

Primary table for DNS records. Supports basic types (A, AAAA, CNAME, etc.) and extended types (SRV, CAA, TLSA, SSHFP, NAPTR, SVCB/HTTPS, LOC, RP).

| Column       | Type                                             | Description                                     |
|--------------|--------------------------------------------------|-------------------------------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT                        | Unique record identifier                        |
| `zone_file_id`| INT(11) NULL                                    | FK → zone_files.id (associated zone)            |
| `record_type`| VARCHAR(50) NOT NULL                             | DNS record type (extensible)                    |
| `name`       | VARCHAR(255)                                     | Record name (hostname)                          |
| `value`      | TEXT                                             | Record value (for backward compatibility)       |
| **Basic Type Fields** |                                          |                                                 |
| `address_ipv4`| VARCHAR(15) NULL                                | IPv4 address for A records                      |
| `address_ipv6`| VARCHAR(45) NULL                                | IPv6 address for AAAA records                   |
| `cname_target`| VARCHAR(255) NULL                               | Target hostname for CNAME records               |
| `ptrdname`   | VARCHAR(255) NULL                                | Reverse DNS name for PTR records                |
| `txt`        | TEXT NULL                                        | Text content for TXT/SPF/DKIM/DMARC records     |
| `mx_target`  | VARCHAR(255) NULL                                | Target mail server for MX records               |
| `ns_target`  | VARCHAR(255) NULL                                | Target nameserver for NS records                |
| `dname_target`| VARCHAR(255) NULL                               | Target for DNAME records                        |
| **SRV Record Fields** |                                           |                                                 |
| `priority`   | INT(11) NULL                                     | Priority (for MX, SRV)                          |
| `port`       | INT(11) NULL                                     | Port number for SRV records                     |
| `weight`     | INT(11) NULL                                     | Weight for SRV records                          |
| `srv_target` | VARCHAR(255) NULL                                | Target hostname for SRV records                 |
| **TLSA Record Fields** |                                          |                                                 |
| `tlsa_usage` | TINYINT NULL                                     | TLSA certificate usage (0-3)                    |
| `tlsa_selector`| TINYINT NULL                                   | TLSA selector (0=full cert, 1=SPKI)             |
| `tlsa_matching`| TINYINT NULL                                   | TLSA matching type (0=exact, 1=SHA256, 2=SHA512)|
| `tlsa_data`  | TEXT NULL                                        | TLSA certificate association data (hex)         |
| **SSHFP Record Fields** |                                         |                                                 |
| `sshfp_algo` | TINYINT NULL                                     | SSHFP algorithm (1=RSA, 2=DSA, 3=ECDSA, 4=Ed25519)|
| `sshfp_type` | TINYINT NULL                                     | SSHFP fingerprint type (1=SHA1, 2=SHA256)       |
| `sshfp_fingerprint`| TEXT NULL                                  | SSHFP fingerprint (hex)                         |
| **CAA Record Fields** |                                           |                                                 |
| `caa_flag`   | TINYINT NULL                                     | CAA critical flag (0 or 128)                    |
| `caa_tag`    | VARCHAR(32) NULL                                 | CAA tag (issue, issuewild, iodef)               |
| `caa_value`  | TEXT NULL                                        | CAA value (e.g., letsencrypt.org)               |
| **NAPTR Record Fields** |                                         |                                                 |
| `naptr_order`| INT(11) NULL                                     | NAPTR order (lower = higher priority)           |
| `naptr_pref` | INT(11) NULL                                     | NAPTR preference (lower = higher priority)      |
| `naptr_flags`| VARCHAR(16) NULL                                 | NAPTR flags (e.g., U, S, A)                     |
| `naptr_service`| VARCHAR(64) NULL                               | NAPTR service (e.g., E2U+sip)                   |
| `naptr_regexp`| TEXT NULL                                       | NAPTR regexp substitution expression            |
| `naptr_replacement`| VARCHAR(255) NULL                          | NAPTR replacement domain                        |
| **SVCB/HTTPS Record Fields** |                                    |                                                 |
| `svc_priority`| INT(11) NULL                                    | SVCB/HTTPS priority (0=AliasMode)               |
| `svc_target` | VARCHAR(255) NULL                                | SVCB/HTTPS target name                          |
| `svc_params` | TEXT NULL                                        | SVCB/HTTPS params (JSON or key=value pairs)     |
| **RP Record Fields** |                                            |                                                 |
| `rp_mbox`    | VARCHAR(255) NULL                                | RP mailbox (email as domain)                    |
| `rp_txt`     | VARCHAR(255) NULL                                | RP TXT domain reference                         |
| **LOC Record Fields** |                                           |                                                 |
| `loc_latitude`| VARCHAR(50) NULL                                | LOC latitude                                    |
| `loc_longitude`| VARCHAR(50) NULL                               | LOC longitude                                   |
| `loc_altitude`| VARCHAR(50) NULL                                | LOC altitude                                    |
| **Generic Storage** |                                             |                                                 |
| `rdata_json` | TEXT NULL                                        | JSON storage for complex record data            |
| **Metadata Fields** |                                             |                                                 |
| `ttl`        | INT(11) DEFAULT 3600                             | Time to live (seconds)                          |
| `requester`  | VARCHAR(255) NULL                                | Person or system requesting this record         |
| `status`     | ENUM('active','disabled','deleted')              | Record status                                   |
| `expires_at` | DATETIME NULL                                    | Expiration date for temporary records           |
| `ticket_ref` | VARCHAR(255) NULL                                | Reference to ticket system (JIRA, ServiceNow)   |
| `comment`    | TEXT NULL                                        | Additional notes or comments                    |
| `last_seen`  | DATETIME NULL                                    | Last time this record was viewed (server-managed)|
| `created_by` | INT(11)                                          | FK → users.id                                   |
| `updated_by` | INT(11) NULL                                     | FK → users.id                                   |
| `created_at` | TIMESTAMP                                        | Creation time                                   |
| `updated_at` | TIMESTAMP NULL                                   | Last update time                                |

**Indexes**: `idx_name`, `idx_type`, `idx_status`, `idx_created_by`, `idx_expires_at`, `idx_ticket_ref`, `idx_address_ipv4`, `idx_address_ipv6`, `idx_cname_target`, `idx_zone_file_id`, `idx_srv_target`, `idx_mx_target`, `idx_ns_target`

> **Note**: The `record_type` column has been migrated from ENUM to VARCHAR(50) to support extensible record types. See [migrations/README.md](../migrations/README.md) for migration details.

---

### dns_record_history

Audit trail for DNS record changes.

| Column       | Type                                             | Description                    |
|--------------|--------------------------------------------------|--------------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT                        | Unique history entry           |
| `record_id`  | INT(11)                                          | FK → dns_records.id            |
| `zone_file_id`| INT(11) NULL                                    | Zone file at time of change    |
| `action`     | ENUM('created','updated','status_changed')       | Type of change                 |
| `record_type`| VARCHAR(50) NOT NULL                             | Record type at time of change  |
| `name`       | VARCHAR(255)                                     | Record name at time of change  |
| `value`      | TEXT                                             | Record value at time of change |
| `address_ipv4`| VARCHAR(15) NULL                                | IPv4 at time of change         |
| `address_ipv6`| VARCHAR(45) NULL                                | IPv6 at time of change         |
| `cname_target`| VARCHAR(255) NULL                               | CNAME target at time of change |
| `ptrdname`   | VARCHAR(255) NULL                                | PTR name at time of change     |
| `txt`        | TEXT NULL                                        | TXT value at time of change    |
| `ttl`        | INT(11) NULL                                     | TTL at time of change          |
| `priority`   | INT(11) NULL                                     | Priority at time of change     |
| `old_status` | ENUM('active','disabled','deleted') NULL         | Previous status                |
| `new_status` | ENUM('active','disabled','deleted')              | New status                     |
| `changed_by` | INT(11)                                          | FK → users.id                  |
| `changed_at` | TIMESTAMP                                        | Change timestamp               |
| `notes`      | TEXT NULL                                        | Optional notes                 |

**Indexes**: `idx_record_id`, `idx_action`, `idx_changed_at`

---

## Access Control

### acl_entries

Access control list entries for resources (zones, records, global).

| Column            | Type                                   | Description                                  |
|-------------------|----------------------------------------|----------------------------------------------|
| `id`              | INT(11) PK AUTO_INCREMENT              | Unique ACL entry identifier                  |
| `user_id`         | INT(11) NULL                           | FK → users.id                                |
| `role_id`         | INT(11) NULL                           | FK → roles.id                                |
| `resource_type`   | ENUM('dns_record','zone','global')     | Type of resource                             |
| `resource_id`     | INT(11) NULL                           | ID of the resource                           |
| `zone_file_id`    | INT(11) NULL                           | FK → zone_files.id for zone ACL entries      |
| `subject_type`    | ENUM('user','role','ad_group') NULL    | Type of ACL subject                          |
| `subject_identifier`| VARCHAR(255) NULL                    | Username, role name, or AD group DN          |
| `permission`      | ENUM('read','write','delete','admin')  | Permission level                             |
| `status`          | ENUM('enabled','disabled')             | ACL entry status                             |
| `created_by`      | INT(11)                                | FK → users.id                                |
| `created_at`      | TIMESTAMP                              | Creation time                                |
| `updated_by`      | INT(11) NULL                           | FK → users.id                                |
| `updated_at`      | TIMESTAMP NULL                         | Last update time                             |

**Indexes**: `idx_user_id`, `idx_role_id`, `idx_resource`, `idx_status`, `idx_zone_file_id`, `idx_acl_subject`

---

### acl_history

Audit trail for ACL changes.

| Column       | Type                                   | Description              |
|--------------|----------------------------------------|--------------------------|
| `id`         | INT(11) PK AUTO_INCREMENT              | Unique history entry     |
| `acl_id`     | INT(11)                                | FK → acl_entries.id      |
| `action`     | ENUM('created','updated','status_changed') | Type of change       |
| `user_id`    | INT(11) NULL                           | User at time of change   |
| `role_id`    | INT(11) NULL                           | Role at time of change   |
| `resource_type`| ENUM('dns_record','zone','global')   | Resource type            |
| `resource_id`| INT(11) NULL                           | Resource ID              |
| `permission` | ENUM('read','write','delete','admin')  | Permission               |
| `old_status` | ENUM('enabled','disabled') NULL        | Previous status          |
| `new_status` | ENUM('enabled','disabled')             | New status               |
| `changed_by` | INT(11)                                | FK → users.id            |
| `changed_at` | TIMESTAMP                              | Change timestamp         |
| `notes`      | TEXT NULL                              | Optional notes           |

---

### zone_acl_entries (view)

Compatibility view that filters `acl_entries` to show only zone-specific entries with subject-based schema.

```sql
SELECT id, zone_file_id, subject_type, subject_identifier, permission, created_by, created_at
FROM acl_entries
WHERE zone_file_id IS NOT NULL 
  AND subject_type IS NOT NULL 
  AND subject_identifier IS NOT NULL;
```

---

## Schema Cleanup Note (2025-12-05)

The following legacy/migration tables have been removed from the database schema:

| Removed Table             | Previous Purpose                                              |
|---------------------------|--------------------------------------------------------------|
| `acl_entries_old`         | Backup of old ACL entries structure with CHECK constraint    |
| `acl_entries_new`         | Alternate ACL structure during migration                     |
| `zone_file_includes_new`  | Alternate includes structure during migration                |

The current schema uses only the canonical tables (`acl_entries`, `zone_file_includes`) documented above.

---

## Foreign Keys Summary

| Table                | Column       | References             | On Delete     |
|----------------------|--------------|------------------------|---------------|
| user_roles           | user_id      | users.id               | CASCADE       |
| user_roles           | role_id      | roles.id               | CASCADE       |
| sessions             | user_id      | users.id               | CASCADE       |
| auth_mappings        | role_id      | roles.id               | CASCADE       |
| auth_mappings        | created_by   | users.id               | SET NULL      |
| zone_files           | created_by   | users.id               | SET NULL      |
| zone_files           | updated_by   | users.id               | SET NULL      |
| zone_file_includes   | parent_id    | zone_files.id          | CASCADE       |
| zone_file_includes   | include_id   | zone_files.id          | CASCADE       |
| zone_file_history    | zone_file_id | zone_files.id          | CASCADE       |
| zone_file_history    | changed_by   | users.id               | CASCADE       |
| zone_file_validation | zone_file_id | zone_files.id          | CASCADE       |
| zone_file_validation | run_by       | users.id               | SET NULL      |
| dns_records          | created_by   | users.id               | (no action)   |
| dns_records          | updated_by   | users.id               | (no action)   |
| dns_record_history   | record_id    | dns_records.id         | CASCADE       |
| dns_record_history   | changed_by   | users.id               | (no action)   |
| acl_entries          | user_id      | users.id               | CASCADE       |
| acl_entries          | role_id      | roles.id               | CASCADE       |
| acl_entries          | created_by   | users.id               | (no action)   |
| acl_entries          | updated_by   | users.id               | (no action)   |

---

## History & Audit Policy

The DNS3 database maintains two history tables for audit purposes:

### dns_record_history

- **Trigger**: Every create, update, or status change on `dns_records`
- **Retention**: Unlimited (manual cleanup required)
- **Fields Captured**: All record fields at time of change, plus action type and user

### zone_file_history

- **Trigger**: Every create, update, status change, or content change on `zone_files`
- **Retention**: Unlimited (manual cleanup required)
- **Fields Captured**: Zone metadata, old/new content, action type, and user
- **Special Actions**: `assign_include` and `reassign_include` for include relationship changes

---

## Useful SQL Queries

### Find all changes to a specific DNS record

```sql
SELECT h.*, u.username as changed_by_username
FROM dns_record_history h
JOIN users u ON h.changed_by = u.id
WHERE h.record_id = :record_id
ORDER BY h.changed_at DESC;
```

### Get records for a specific zone (including all includes)

```sql
-- Get all DNS records for a master zone and its includes
WITH RECURSIVE zone_tree AS (
    -- Base case: the master zone
    SELECT id FROM zone_files WHERE id = :master_zone_id
    UNION ALL
    -- Recursive case: all includes
    SELECT zfi.include_id
    FROM zone_file_includes zfi
    JOIN zone_tree zt ON zfi.parent_id = zt.id
)
SELECT dr.*, zf.name as zone_name
FROM dns_records dr
JOIN zone_tree zt ON dr.zone_file_id = zt.id
JOIN zone_files zf ON dr.zone_file_id = zf.id
WHERE dr.status = 'active'
ORDER BY zf.name, dr.name;
```

### Map an include file to its master zone

```sql
WITH RECURSIVE parent_tree AS (
    -- Base case: start from the include
    SELECT parent_id, include_id, 1 as depth
    FROM zone_file_includes
    WHERE include_id = :include_zone_id
    UNION ALL
    -- Recursive case: go up the tree
    SELECT zfi.parent_id, zfi.include_id, pt.depth + 1
    FROM zone_file_includes zfi
    JOIN parent_tree pt ON zfi.include_id = pt.parent_id
)
SELECT zf.*
FROM zone_files zf
JOIN parent_tree pt ON zf.id = pt.parent_id
WHERE zf.file_type = 'master'
ORDER BY pt.depth DESC
LIMIT 1;
```

### Get include tree for a zone

```sql
WITH RECURSIVE include_tree AS (
    -- Base case: direct includes
    SELECT 
        zfi.parent_id, 
        zfi.include_id, 
        zfi.position,
        zf.name,
        zf.file_type,
        1 as depth
    FROM zone_file_includes zfi
    JOIN zone_files zf ON zfi.include_id = zf.id
    WHERE zfi.parent_id = :zone_id
    UNION ALL
    -- Recursive case: nested includes
    SELECT 
        zfi.parent_id, 
        zfi.include_id, 
        zfi.position,
        zf.name,
        zf.file_type,
        it.depth + 1
    FROM zone_file_includes zfi
    JOIN zone_files zf ON zfi.include_id = zf.id
    JOIN include_tree it ON zfi.parent_id = it.include_id
)
SELECT * FROM include_tree ORDER BY depth, position;
```

### Get latest validation status for all zones

```sql
SELECT zf.id, zf.name, zf.file_type, zfv.status, zfv.checked_at, zfv.output
FROM zone_files zf
LEFT JOIN zone_file_validation zfv ON zf.id = zfv.zone_file_id
    AND zfv.checked_at = (
        SELECT MAX(checked_at) 
        FROM zone_file_validation 
        WHERE zone_file_id = zf.id
    )
WHERE zf.status = 'active'
ORDER BY zf.name;
```

---

## Import Instructions

### Prerequisites

- MariaDB 10.3+ or MySQL 5.7+
- Database created with proper character set

### Create Database

```bash
mysql -u root -p -e "CREATE DATABASE dns3_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### Import Schema

```bash
mysql -u user -p dns3_db < database.sql
```

### Verify Import

```sql
-- Check all tables exist
SHOW TABLES;

-- Verify foreign keys
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'dns3_db' AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

## CTE and Temporary Table Requirements

### WITH RECURSIVE Support

Some utility scripts and queries in DNS3 use `WITH RECURSIVE` Common Table Expressions (CTEs) to traverse hierarchical data such as zone include relationships. This feature requires:

- **MariaDB 10.2.2+** or **MySQL 8.0+**

The `scripts/update_last_seen_from_bind_logs.sh` script uses CTEs to expand the full include tree when matching DNS records.

Example CTE usage:
```sql
WITH RECURSIVE zone_tree AS (
    SELECT id FROM zone_files WHERE id = :master_id
    UNION ALL
    SELECT zfi.include_id
    FROM zone_file_includes zfi
    JOIN zone_tree zt ON zfi.parent_id = zt.id
)
SELECT * FROM zone_tree;
```

### Temporary Table Engine Considerations

The batch updater script creates temporary tables using `ENGINE=MEMORY` for speed. For large datasets (>100k rows), consider:

1. **Increase memory limits**:
   ```sql
   SET GLOBAL max_heap_table_size = 256*1024*1024;  -- 256MB
   SET GLOBAL tmp_table_size = 256*1024*1024;
   ```

2. **Use InnoDB for temp tables** (requires schema modification in script):
   ```sql
   CREATE TEMPORARY TABLE tmp_fqdns (...) ENGINE=InnoDB;
   ```

3. **Process data in smaller batches** using the `--batch` option.

See [UPDATE_LAST_SEEN_FROM_BIND_LOGS.md](UPDATE_LAST_SEEN_FROM_BIND_LOGS.md) for detailed performance guidance.

---

## Known Documentation Divergences

The following documentation files may contain outdated terminology that differs from the current schema:

| File                                    | Issue                                                      | Current Schema                        |
|-----------------------------------------|------------------------------------------------------------|---------------------------------------|
| `docs/ZONE_FILES_IMPLEMENTATION_SUMMARY.md` | May reference `master_id` in zone_file_includes         | Column is now `parent_id`             |
| `docs/DELIVERY_SUMMARY.md`              | May reference `master_id` → `parent_id` rename as pending  | Rename is complete                    |

When in doubt, refer to this document or the `database.sql` file as the source of truth.
