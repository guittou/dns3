# Update last_seen from BIND Logs

## Overview

The `scripts/update_last_seen_from_bind_logs.sh` script parses BIND DNS server query logs, extracts unique FQDNs for a specified query type (default: A records), and updates the `dns_records.last_seen` timestamp for all matching records in the database.

This is useful for:
- Tracking which DNS records are actively queried
- Identifying stale or unused records
- Auditing DNS usage patterns
- Capacity planning based on query frequency

## Prerequisites

### Software Requirements

- **MySQL CLI client**: The `mysql` command must be available in PATH
- **Database server**: MariaDB 10.2+ or MySQL 8.0+ (required for `WITH RECURSIVE` CTE support)
- **Bash**: Version 4.0 or later (for associative arrays and modern features)

### Database Requirements

The script requires the following tables to exist:

- `zone_files` - Master zone definitions with `domain` column
- `zone_file_includes` - Parent-child relationships between zones
- `dns_records` - DNS record entries with `zone_file_id` and `last_seen` columns

### Permissions

The database user needs:
- `SELECT` on `zone_files`, `zone_file_includes`
- `SELECT`, `UPDATE` on `dns_records`
- `CREATE TEMPORARY TABLES` privilege

## Installation

The script is included in the repository at:

```
scripts/update_last_seen_from_bind_logs.sh
```

Ensure it has execute permissions:

```bash
chmod +x scripts/update_last_seen_from_bind_logs.sh
```

## Usage

### Basic Syntax

```bash
./scripts/update_last_seen_from_bind_logs.sh [OPTIONS]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--db-host HOST` | localhost | MySQL/MariaDB host |
| `--db-user USER` | root | Database username |
| `--db-pass PASS` | (prompt) | Database password |
| `--db-name NAME` | dns3_db | Database name |
| `--logs FILES` | (required) | Comma-separated log files, or `-` for stdin |
| `--batch N` | 1000 | Batch size for INSERT statements |
| `--qtype TYPE` | A | Query type to filter (A, AAAA, CNAME, etc.) |
| `--tmpdir DIR` | /tmp | Temp directory for intermediate files |
| `--dry-run` | (off) | Perform lookup without applying UPDATE |
| `--log-file FILE` | (none) | Write execution log to file |
| `--help` | | Show help message |

### Examples

#### Dry-Run Mode (Recommended First Step)

```bash
./scripts/update_last_seen_from_bind_logs.sh \
    --db-host db.example.com \
    --db-user dns3_user \
    --logs "/var/log/named/query.log" \
    --dry-run \
    --log-file /tmp/update_preview.log
```

This will:
- Parse the log file
- Show which records would be updated
- NOT modify any database records

#### Production Update

```bash
./scripts/update_last_seen_from_bind_logs.sh \
    --db-host db.example.com \
    --db-user dns3_user \
    --db-pass "secure_password" \
    --logs "/var/log/named/query.log,/var/log/named/query.log.1.gz" \
    --log-file /var/log/dns3/last_seen_update.log
```

#### Reading from Stdin

```bash
cat /var/log/named/query.log | ./scripts/update_last_seen_from_bind_logs.sh \
    --logs "-" \
    --db-user dns3_user
```

#### Processing AAAA Queries

```bash
./scripts/update_last_seen_from_bind_logs.sh \
    --qtype AAAA \
    --logs "/var/log/named/query.log"
```

## Cron Configuration

### Daily Update Example

Add to `/etc/cron.d/dns3-last-seen`:

```cron
# Update last_seen from yesterday's query logs
0 2 * * * root /opt/dns3/scripts/update_last_seen_from_bind_logs.sh \
    --db-host localhost \
    --db-user dns3_updater \
    --logs "/var/log/named/query.log.1.gz" \
    --log-file /var/log/dns3/last_seen_$(date +\%Y\%m\%d).log \
    2>&1 | logger -t dns3-last-seen
```

### Hourly Update with Rotation

```cron
# Process current log every hour
15 * * * * root /opt/dns3/scripts/update_last_seen_from_bind_logs.sh \
    --db-host localhost \
    --db-user dns3_updater \
    --logs "/var/log/named/query.log" \
    --log-file /var/log/dns3/hourly_update.log
```

## How It Works

### Processing Pipeline

1. **Parse Log Files**: Read BIND query logs (plain text or gzip compressed)
2. **Extract FQDNs**: Match lines containing `query: <fqdn> IN <qtype>` pattern
3. **Normalize**: Convert to lowercase, remove trailing dots, validate format
4. **Deduplicate**: Sort and remove duplicate FQDNs
5. **Batch Insert**: Insert unique FQDNs into temporary table in batches
6. **Resolve Masters**: Find the master zone for each FQDN using longest-match on `zone_files.domain`
7. **Expand Includes**: Use `WITH RECURSIVE` CTE to traverse include relationships
8. **Match Records**: Find matching `dns_records` by relative label, full FQDN, or apex
9. **Update**: Set `last_seen = UTC_TIMESTAMP()` for all matched records

### Master Zone Resolution

The script uses longest-match to find the authoritative master zone:

```
FQDN: api.v2.example.com

Available masters:
  - example.com      (length: 11)
  - v2.example.com   (length: 14) ← Selected (longest match)
```

### Record Matching Heuristics

For each FQDN, the script computes a relative label and matches against:

1. **Relative label**: `www` for `www.example.com` in zone `example.com`
2. **Full FQDN**: Direct match on `dns_records.name = 'www.example.com'`
3. **Apex match**: When relative label is `@`, match `name='@'` or `name='example.com'`

### Include Expansion

The script recursively expands zone includes using a CTE:

```sql
WITH RECURSIVE zone_tree AS (
    SELECT master_id AS root, master_id AS current FROM masters
    UNION ALL
    SELECT zt.root, zfi.include_id
    FROM zone_tree zt
    JOIN zone_file_includes zfi ON zfi.parent_id = zt.current
)
SELECT * FROM zone_tree;
```

This ensures records in included zones are also matched.

## Output Interpretation

### SQL Output Fields

The script outputs several diagnostic queries:

| Field | Description |
|-------|-------------|
| `fqdns_without_master` | FQDNs that couldn't be matched to any master zone |
| `matched_records_count` | Total number of dns_records that will be updated |
| `unique_fqdns_matched` | How many of the input FQDNs found matching records |
| `rows_updated` | Actual count of records updated (live mode only) |

### Sample Output

```
+----------------------+-------+
| metric               | value |
+----------------------+-------+
| matched_records_count|   147 |
| unique_fqdns_matched |    52 |
+----------------------+-------+

+-------------------------------------+
| info                                |
+-------------------------------------+
| Sample matches (first 10):          |
+-------------------------------------+
+-----------+-------------------+------------+
| record_id | fqdn              | match_type |
+-----------+-------------------+------------+
|       123 | www.example.com   | relative   |
|       456 | mail.example.com  | relative   |
|       789 | example.com       | apex       |
+-----------+-------------------+------------+
```

### Investigating Unmatched FQDNs

The script reports FQDNs that couldn't be matched to a master zone. Common reasons:

1. **No master zone defined**: The domain isn't managed in DNS3
2. **Inactive zone**: The master zone's status isn't 'active'
3. **Missing domain field**: Master zone exists but `domain` column is NULL
4. **External queries**: Queries for domains not managed by this DNS server

## Performance Considerations

### Memory Usage

- **Temporary tables use `ENGINE=MEMORY`** by default for speed
- For very large datasets (>100k FQDNs), consider:
  - Using `InnoDB` for temp tables (requires schema modification)
  - Increasing `max_heap_table_size` and `tmp_table_size`
  - Processing logs in smaller batches

### Batch Size

The `--batch` parameter controls INSERT batch size:

- **Default (1000)**: Good balance for most use cases
- **Smaller (100-500)**: Reduces memory pressure, slower overall
- **Larger (5000-10000)**: Faster for large datasets, more memory

### Execution Time

Typical performance:
- 100k FQDNs: ~30 seconds
- 1M FQDNs: ~5 minutes
- Depends on: database performance, network latency, index efficiency

### Alternative: LOAD DATA INFILE

For very large datasets, consider modifying the script to use `LOAD DATA INFILE` instead of batched INSERTs:

```sql
LOAD DATA LOCAL INFILE '/tmp/fqdns.txt'
INTO TABLE tmp_fqdns
LINES TERMINATED BY '\n'
(fqdn);
```

This requires:
- `local_infile=ON` in MySQL configuration
- `LOCAL` keyword for client-side files
- Proper file permissions

## Security Notes

### Password Handling

**Recommended**: Use a MySQL options file instead of command-line password:

```ini
# ~/.my.cnf
[client]
user = dns3_updater
password = your_secure_password
host = db.example.com
```

Then run without `--db-pass`:
```bash
./scripts/update_last_seen_from_bind_logs.sh --logs "/var/log/named/query.log"
```

### Privilege Minimization

Create a dedicated user with minimal privileges:

```sql
CREATE USER 'dns3_updater'@'%' IDENTIFIED BY 'secure_random_password';

GRANT SELECT ON dns3_db.zone_files TO 'dns3_updater'@'%';
GRANT SELECT ON dns3_db.zone_file_includes TO 'dns3_updater'@'%';
GRANT SELECT, UPDATE (last_seen) ON dns3_db.dns_records TO 'dns3_updater'@'%';
GRANT CREATE TEMPORARY TABLES ON dns3_db.* TO 'dns3_updater'@'%';

FLUSH PRIVILEGES;
```

### TLS Connections

For production, enforce TLS:

```bash
./scripts/update_last_seen_from_bind_logs.sh \
    --db-host db.example.com \
    --logs "/var/log/named/query.log"
```

Add to MySQL options file:
```ini
[client]
ssl-mode = REQUIRED
ssl-ca = /etc/ssl/certs/mysql-ca.pem
```

### Log File Permissions

If using `--log-file`, ensure appropriate permissions:

```bash
touch /var/log/dns3/last_seen.log
chown dns3:dns3 /var/log/dns3/last_seen.log
chmod 640 /var/log/dns3/last_seen.log
```

## Troubleshooting

### Common Errors

#### "mysql client not found"
Install MySQL client:
```bash
# Debian/Ubuntu
apt-get install mysql-client

# RHEL/CentOS
yum install mysql
```

#### "No log files specified"
The `--logs` option is required:
```bash
./scripts/update_last_seen_from_bind_logs.sh --logs "/var/log/named/query.log"
```

#### "Access denied for user"
Check credentials and permissions:
```sql
SHOW GRANTS FOR 'dns3_updater'@'%';
```

#### "Table doesn't exist"
Ensure the database schema is up to date:
```bash
mysql -u admin -p dns3_db < database.sql
```

#### "Out of memory" or temp table errors
Increase memory limits or reduce batch size:
```bash
./scripts/update_last_seen_from_bind_logs.sh --batch 500 --logs "..."
```

### Debug Mode

For troubleshooting, examine the generated SQL:

```bash
# Set a breakpoint before execution
./scripts/update_last_seen_from_bind_logs.sh \
    --logs "/var/log/named/query.log" \
    --dry-run \
    --log-file /tmp/debug.log

# Check the temp SQL file (printed in log)
cat /tmp/update_last_seen_XXXXXX.sql
```

## Related Documentation

- [DB_SCHEMA.md](DB_SCHEMA.md) - Database schema documentation
- [DELIVERY_SUMMARY.md](DELIVERY_SUMMARY.md) - Project delivery summary
- [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) - Implementation details

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-04 | 1.0.0 | Initial release with logging and dry-run support |
