# Database Migrations

This directory contains SQL migration files for the DNS3 database schema.

## Migration Files

Migrations are numbered sequentially and should be run in order:

- `001_create_dns_tables.sql` - Initial DNS records table
- `002_create_auth_mappings.sql` - Authentication and authorization tables
- `003_add_dns_fields.sql` - Additional DNS record fields
- `004_remove_disabled_status.sql` - Remove disabled status from records
- `005_add_type_specific_fields.sql` - Add dedicated columns for DNS record types (A, AAAA, CNAME, PTR, TXT)
- `006_create_zone_files_and_apps_and_add_zone_to_dns_records.sql` - Zone files and applications tables
- `007_add_zone_files_indexes.sql` - Indexes for zone files
- `008_enforce_single_parent.sql` - Enforce single parent constraint for zone file includes
- `009_add_history_actions.sql` - Add history action types
- `010_add_directory_to_zone_files.sql` - Add directory field to zone files
- `011_create_zone_file_validation.sql` - Zone file validation tables
- `012_add_validation_command_fields.sql.disabled` - Validation command fields (disabled)
- `013_remove_legacy_zone_columns.sql` - Remove legacy compatibility columns from dns_records
- `014_create_domain_list.sql` - Domain list table for managing domains attached to zone files

## Running Migrations

### Prerequisites

- MySQL/MariaDB database server
- Database user with appropriate privileges (CREATE, ALTER, DROP, SELECT, INSERT, UPDATE, DELETE)
- The `dns3_db` database must exist

### Manual Execution

To run a migration manually:

```bash
mysql -u [username] -p dns3_db < migrations/001_create_dns_tables.sql
```

### Running All Migrations

To run all migrations in order:

```bash
for file in migrations/0*.sql; do
    if [[ ! "$file" =~ \.disabled$ ]]; then
        echo "Running migration: $file"
        mysql -u [username] -p dns3_db < "$file"
    fi
done
```

### Checking Migration Status

To see which migrations have been run, you can check the database schema:

```bash
mysql -u [username] -p dns3_db -e "SHOW TABLES;"
mysql -u [username] -p dns3_db -e "DESCRIBE dns_records;"
```

## Migration 013: Remove Legacy Zone Columns

### Overview

Migration 013 removes legacy compatibility columns that were used during development to ease migration from storing zone information directly in `dns_records` to using the canonical `zone_file_id` foreign key relationship.

### Legacy Columns Removed

If they exist, these columns are removed from `dns_records`:
- `zone` - VARCHAR - zone identifier
- `zone_name` - VARCHAR - display name of zone
- `zone_file_name` - VARCHAR - filename of zone file
- `zone_file` - TEXT - zone file content

### What It Does

1. **Detects** if any legacy columns exist in `dns_records`
2. **Creates backup table** `dns_records_legacy_backup` (if legacy columns exist)
3. **Backs up** existing legacy column data for audit/rollback purposes
4. **Backfills** `zone_file_id` using the following strategy:
   - Match `dns_records.zone` with `zone_files.name`
   - Match `dns_records.zone` with `zone_files.filename`
   - Match `dns_records.zone_name` with `zone_files.name`
   - Match `dns_records.zone_file_name` with `zone_files.filename`
5. **Drops** the legacy columns if they exist
6. **Reports** orphaned records (records without a valid `zone_file_id`)

### Idempotency

This migration is **idempotent** and can be safely re-run multiple times:
- Column existence is checked before any operation
- Backup table is only created once
- Drops are conditional on column existence
- No errors if columns are already removed

### Running the Migration

```bash
mysql -u [username] -p dns3_db < migrations/013_remove_legacy_zone_columns.sql
```

### Rollback Procedure

If you need to rollback this migration:

#### 1. Stop the Application

```bash
# Stop your web server or application
sudo systemctl stop apache2  # or nginx, php-fpm, etc.
```

#### 2. Restore Legacy Columns

```sql
USE dns3_db;

-- Re-add the legacy columns
ALTER TABLE dns_records ADD COLUMN zone VARCHAR(255) NULL AFTER zone_file_id;
ALTER TABLE dns_records ADD COLUMN zone_name VARCHAR(255) NULL AFTER zone;
ALTER TABLE dns_records ADD COLUMN zone_file_name VARCHAR(255) NULL AFTER zone_name;
ALTER TABLE dns_records ADD COLUMN zone_file MEDIUMTEXT NULL AFTER zone_file_name;

-- Add indexes for performance
CREATE INDEX idx_zone ON dns_records(zone);
CREATE INDEX idx_zone_name ON dns_records(zone_name);
CREATE INDEX idx_zone_file_name ON dns_records(zone_file_name);
```

#### 3. Restore Data from Backup

```sql
-- Restore legacy column data from backup table
UPDATE dns_records dr
JOIN dns_records_legacy_backup b ON dr.id = b.id
SET dr.zone = b.zone,
    dr.zone_name = b.zone_name,
    dr.zone_file_name = b.zone_file_name,
    dr.zone_file = b.zone_file
WHERE b.id IS NOT NULL;
```

#### 4. Revert Code Changes

```bash
# Checkout the previous version of the code
git revert [commit-hash]

# Or manually revert the API changes to read from legacy columns
```

#### 5. Restart the Application

```bash
sudo systemctl start apache2  # or nginx, php-fpm, etc.
```

#### 6. Verify

```sql
-- Check that legacy columns are restored
DESCRIBE dns_records;

-- Check that data is restored
SELECT id, zone, zone_name, zone_file_name 
FROM dns_records 
LIMIT 10;
```

### Post-Migration Verification

After running the migration, verify:

1. **Check for orphaned records:**
   ```sql
   SELECT COUNT(*) AS orphaned_records
   FROM dns_records
   WHERE zone_file_id IS NULL OR zone_file_id = 0;
   ```

2. **Verify API still works:**
   - Test DNS record list endpoint: `GET /api/dns_api.php?action=list`
   - Test DNS record get endpoint: `GET /api/dns_api.php?action=get&id=1`
   - Verify response includes `zone_name` and `zone_filename` from join

3. **Verify frontend display:**
   - Open DNS Management page
   - Verify zone names display correctly in table
   - Verify zone selection works in create/edit modal

4. **Check backup table:**
   ```sql
   SELECT COUNT(*) FROM dns_records_legacy_backup;
   SELECT * FROM dns_records_legacy_backup LIMIT 5;
   ```

### Notes

- The migration preserves all existing `zone_file_id` values
- Only records with NULL or 0 `zone_file_id` are backfilled
- If a record cannot be matched to a zone file, it remains orphaned (check the verification query)
- The backup table `dns_records_legacy_backup` is kept indefinitely for safety
- API code has been updated to join `zone_files` and return `zone_name` and `zone_filename`
- Frontend already uses API-provided fields, no changes needed

## Migration 014: Create Domain List Table

### Overview

Migration 014 creates a new table `domaine_list` for managing domains that are attached to zone files. This feature allows administrators to associate domain names with master zone files.

### What It Creates

1. **Table `domaine_list`** with the following columns:
   - `id` - Primary key (int AUTO_INCREMENT)
   - `domain` - Domain name (varchar 255, unique, NOT NULL)
   - `zone_file_id` - Foreign key to zone_files (int, NOT NULL)
   - `created_by` - User who created the domain (int, NOT NULL)
   - `updated_by` - User who last updated the domain (int, NULL)
   - `created_at` - Creation timestamp (timestamp, default CURRENT_TIMESTAMP)
   - `updated_at` - Last update timestamp (timestamp, NULL, auto-update on change)
   - `status` - ENUM('active', 'deleted') DEFAULT 'active' for soft delete

2. **Indexes**:
   - Unique index `uq_domain` on `domain`
   - Index `idx_zone_file_id` on `zone_file_id`
   - Index `idx_status` on `status`

3. **Foreign Key Constraints**:
   - `domaine_list_ibfk_1`: `zone_file_id` -> `zone_files.id`
   - `domaine_list_ibfk_2`: `created_by` -> `users.id`
   - `domaine_list_ibfk_3`: `updated_by` -> `users.id`

### Running the Migration

```bash
mysql -u [username] -p dns3_db < migrations/014_create_domain_list.sql
```

### API and UI

This migration is accompanied by:
- **Model**: `includes/models/Domain.php` - Domain CRUD operations
- **API**: `api/domain_api.php` - REST API endpoints
- **UI**: Admin panel "Domaines" tab with create/edit/delete functionality

### Security Features

- Server-side validation of domain format (regex)
- Verification that zone_file_id references a 'master' type zone
- Admin-only access for create/update/delete operations
- Prepared statements for SQL injection prevention

## Best Practices

1. **Always backup your database** before running migrations:
   ```bash
   mysqldump -u [username] -p dns3_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Test migrations** in a development environment first

3. **Run migrations during maintenance windows** to avoid conflicts

4. **Document any manual steps** required after migration

5. **Keep migration files** - they serve as documentation of schema evolution

6. **Use transactions** where possible (included in migration files)

7. **Make migrations idempotent** so they can be safely re-run

## Troubleshooting

### Migration Fails with "Table already exists"

Most migrations check for existence before creating tables. If you see this error, the migration might not be idempotent. Check the migration file and manually verify the state.

### Migration Fails with Permission Denied

Ensure your database user has the required privileges:

```sql
GRANT ALL PRIVILEGES ON dns3_db.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

### Need to Skip a Migration

If a migration has already been applied manually or needs to be skipped, simply don't run it. Migrations are designed to be run sequentially but are also idempotent where possible.

### Orphaned Records After Migration 013

If records have NULL `zone_file_id` after migration 013, you can manually fix them:

```sql
-- Find orphaned records
SELECT id, name, record_type 
FROM dns_records 
WHERE zone_file_id IS NULL OR zone_file_id = 0;

-- Manually assign to a zone file
UPDATE dns_records 
SET zone_file_id = [zone_file_id] 
WHERE id = [record_id];
```

## Schema Version Tracking

This project does not currently use an automated migration tracking system. To track which migrations have been applied:

1. Keep a log of migrations run (e.g., in a text file or notes)
2. Check database schema manually with `DESCRIBE` and `SHOW TABLES`
3. Consider implementing a migrations table in the future:

```sql
CREATE TABLE migrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    migration VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Support

For questions or issues with migrations, please:
1. Check this README
2. Review the migration file comments
3. Check existing issues in the repository
4. Create a new issue if needed
