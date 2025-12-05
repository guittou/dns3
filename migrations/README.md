# DNS Record Types Migration Guide

## Overview

This migration extends the DNS3 application to support an extensible record type system, replacing the fixed ENUM with VARCHAR(50) and adding structured columns for advanced DNS record types.

## Prerequisites

- MariaDB 10.3+ or MySQL 5.7+
- Database backup capability
- Administrator access to the database
- Application downtime window (recommended: 30 minutes)

## Supported Record Types After Migration

### Pointing Records (Champs de pointage)
| Type | Description |
|------|-------------|
| A | IPv4 address record |
| AAAA | IPv6 address record |
| NS | Name server record |
| CNAME | Canonical name (alias) record |
| DNAME | Delegation name record |

### Extended Records (Champs étendus)
| Type | Description |
|------|-------------|
| CAA | Certification Authority Authorization |
| TXT | Text record |
| NAPTR | Naming Authority Pointer |
| SRV | Service location record |
| LOC | Location record |
| SSHFP | SSH Fingerprint record |
| TLSA | DANE TLS Association record |
| RP | Responsible Person record |
| SVCB | Service Binding record |
| HTTPS | HTTPS Service Binding record |

### Mail Records (Champs mails)
| Type | Description |
|------|-------------|
| MX | Mail exchange record |
| SPF | Sender Policy Framework (stored as TXT) |
| DKIM | DomainKeys Identified Mail (stored as TXT) |
| DMARC | Domain-based Message Authentication (stored as TXT) |

### Other Types
| Type | Description |
|------|-------------|
| PTR | Pointer record (reverse DNS) |
| SOA | Start of Authority record |

## Migration Steps

### Step 1: Pre-Migration Backup (CRITICAL)

```bash
# Full database backup
mysqldump -u dns3_user -p --single-transaction --routines --triggers dns3_db > dns3_db_backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup integrity
mysql -u dns3_user -p -e "SELECT COUNT(*) FROM dns_records" dns3_db
head -100 dns3_db_backup_*.sql
```

### Step 2: Stop Application (Recommended)

```bash
# Stop the web server to prevent data inconsistency
sudo systemctl stop apache2  # or nginx/php-fpm
```

### Step 3: Run Migration

```bash
# Apply the migration
mysql -u dns3_user -p dns3_db < migrations/001_migrate_record_type_enum_to_varchar.sql

# Check for errors
echo $?  # Should be 0
```

### Step 4: Verify Migration

```sql
-- Connect to database
mysql -u dns3_user -p dns3_db

-- Verify record_type column is VARCHAR
SHOW COLUMNS FROM dns_records LIKE 'record_type';
-- Expected: varchar(50)

-- Verify new columns exist
SHOW COLUMNS FROM dns_records;

-- Check record_types reference table
SELECT * FROM record_types ORDER BY category, name;

-- Verify data integrity
SELECT record_type, COUNT(*) as count 
FROM dns_records 
GROUP BY record_type 
ORDER BY count DESC;

-- Verify no NULL record_types
SELECT COUNT(*) AS null_types FROM dns_records WHERE record_type IS NULL;
-- Expected: 0
```

### Step 5: Restart Application

```bash
# Start the web server
sudo systemctl start apache2  # or nginx/php-fpm
```

### Step 6: Application Testing

1. Access the DNS management page
2. Verify existing records display correctly
3. Create a new A record - verify it saves
4. Create a new TXT record - verify it saves
5. Test the new extended record types (SRV, CAA, etc.)

## Rollback Procedure

If issues occur, rollback using:

```bash
# Option A: Restore from backup (safest)
mysql -u dns3_user -p dns3_db < dns3_db_backup_YYYYMMDD_HHMMSS.sql

# Option B: Run rollback script (if backup unavailable)
# WARNING: This may lose data for new extended record types!
mysql -u dns3_user -p dns3_db < migrations/001_rollback_record_type_varchar_to_enum.sql
```

## New Database Columns

The migration adds the following columns to `dns_records`:

### SRV Record Fields
- `port` INT - Port number
- `weight` INT - Weight for load balancing
- `srv_target` VARCHAR(255) - Target hostname

### TLSA Record Fields
- `tlsa_usage` TINYINT - Certificate usage (0-3)
- `tlsa_selector` TINYINT - Selector (0=full cert, 1=SPKI)
- `tlsa_matching` TINYINT - Matching type (0=exact, 1=SHA256, 2=SHA512)
- `tlsa_data` TEXT - Certificate association data (hex)

### SSHFP Record Fields
- `sshfp_algo` TINYINT - Algorithm (1=RSA, 2=DSA, 3=ECDSA, 4=Ed25519)
- `sshfp_type` TINYINT - Fingerprint type (1=SHA1, 2=SHA256)
- `sshfp_fingerprint` TEXT - Fingerprint (hex)

### CAA Record Fields
- `caa_flag` TINYINT - Critical flag (0 or 128)
- `caa_tag` VARCHAR(32) - Tag (issue, issuewild, iodef)
- `caa_value` TEXT - CA domain value

### NAPTR Record Fields
- `naptr_order` INT - Order (lower = higher priority)
- `naptr_pref` INT - Preference
- `naptr_flags` VARCHAR(16) - Flags (U, S, A)
- `naptr_service` VARCHAR(64) - Service
- `naptr_regexp` TEXT - Regular expression
- `naptr_replacement` VARCHAR(255) - Replacement domain

### SVCB/HTTPS Record Fields
- `svc_priority` INT - Priority (0 = AliasMode)
- `svc_target` VARCHAR(255) - Target name
- `svc_params` TEXT - Service parameters (JSON)

### Other Fields
- `ns_target` VARCHAR(255) - NS record target
- `mx_target` VARCHAR(255) - MX record target
- `dname_target` VARCHAR(255) - DNAME record target
- `rp_mbox` VARCHAR(255) - RP mailbox
- `rp_txt` VARCHAR(255) - RP TXT reference
- `loc_latitude` VARCHAR(50) - LOC latitude
- `loc_longitude` VARCHAR(50) - LOC longitude
- `loc_altitude` VARCHAR(50) - LOC altitude
- `rdata_json` TEXT - Generic JSON storage for complex data

## Files Modified

- `database.sql` - Updated schema with new structure
- `docs/DB_SCHEMA.md` - Updated documentation
- `includes/lib/DnsValidator.php` - Extended validation for new types
- `api/dns_api.php` - API endpoints for new record types
- `assets/js/dns-records.js` - Frontend support for new types
- `dns-management.php` - UI updates with type categories

## Troubleshooting

### Migration fails with "Column already exists"
The migration uses conditional checks. This is expected if running migration multiple times.

### "Data truncated" error
A record has a value that doesn't match the expected type. Check the specific record and fix manually.

### Application shows no records
Check if `record_type` column was renamed correctly:
```sql
SHOW COLUMNS FROM dns_records LIKE 'record_type';
```

### Extended records not showing in UI
Clear browser cache and verify JavaScript files are updated.

## Support

For issues with this migration, please:
1. Check the troubleshooting section above
2. Review the rollback procedure
3. Open an issue in the GitHub repository with:
   - Error message
   - MySQL/MariaDB version
   - Database dump of affected records (sanitized)
