# Archived Migrations

This directory contains archived migration files that are kept for historical reference but are no longer actively used.

## Contents

### 006_create_zone_files_and_apps_and_add_zone_to_dns_records.sql

This migration originally created the following tables:
- `zone_files` - DNS zone file management
- `zone_file_includes` - Junction table for master/include relationships
- `applications` - Application management table (DEPRECATED - feature removed)
- `zone_file_history` - Audit trail for zone file changes

It also added:
- `zone_file_id` column to `dns_records` and `dns_record_history` tables

**Note**: The `applications` table schema remains in the database but the Applications feature has been removed from the application. The table is preserved for historical data but no longer used by any code.

## Important Notes

- These migrations have already been applied to the production database
- Do not re-run these migrations unless you need to recreate the schema from scratch
- If you need to drop the `applications` table, create a new migration with proper backup and rollback procedures
- See the main `migrations/README.md` for documentation on running migrations

## Removal of Applications Feature

The Applications feature was removed because:
- The product no longer uses this functionality
- Removing it reduces code complexity and maintenance burden
- It reduces the application's attack surface

If you need to completely remove the `applications` table from the database:

```bash
# Step 1: Create a complete backup of the applications table (structure + data)
mysqldump -u [username] -p --single-transaction dns3_db applications > applications_backup.sql

# Step 2: Verify the backup was created successfully
ls -la applications_backup.sql
```

```sql
-- Step 3: Drop the table (run in MySQL client)
DROP TABLE IF EXISTS applications;
```

**Warning**: This is irreversible. Make sure you have verified the backup before proceeding.
