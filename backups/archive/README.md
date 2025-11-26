# Archived Backups

This directory contains archived backup files that are kept for historical reference.

## Contents

### AAA.txt

Database dump from dns3_db that includes the schema for the `applications` table. This file is preserved because:

1. It contains the schema definition for the `applications` table which was part of the zone files feature
2. It may be needed for rollback purposes if the applications table needs to be restored
3. It serves as documentation of the database schema at a point in time

## Important Notes

- The Applications feature has been removed from the application code
- The `applications` table schema remains in the database but is no longer used
- If you need to restore data from these backups, verify compatibility with the current schema first

## Removal of Applications Feature

If you decide to completely remove the `applications` table from the database:

1. Create a new backup first: `mysqldump -u [username] -p dns3_db > backup_before_drop.sql`
2. Run: `DROP TABLE IF EXISTS applications;`
3. This is irreversible - ensure you have verified backups before proceeding
