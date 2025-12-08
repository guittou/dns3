# BIND Zone Import Tools

This document describes how to import BIND-format zone files into the dns3 application.

## Overview

The dns3 application provides two import tools for ingesting BIND zone files:

1. **Python Importer** (`scripts/import_bind_zones.py`) - Robust implementation using dnspython library
2. **Bash Importer** (`scripts/import_bind_zones.sh`) - Lightweight heuristic parser for simple zones

Both tools support dry-run mode for safe testing and can optionally skip existing zones.

## Table of Contents

- [Safety Recommendations](#safety-recommendations)
- [Python Importer](#python-importer)
  - [Features](#features)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Usage - API Mode](#usage---api-mode)
  - [Usage - Database Mode](#usage---database-mode)
  - [Options](#options)
- [Bash Importer](#bash-importer)
  - [Features](#features-1)
  - [Limitations](#limitations)
  - [Usage](#usage)
  - [Options](#options-1)
- [Comparison](#comparison)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Safety Recommendations

⚠️ **IMPORTANT**: Always follow these safety practices when importing zone files:

1. **Use dry-run mode first**: Test with `--dry-run` to see what will be imported without making changes
2. **Backup your database**: Create a backup before importing in production
3. **Test in staging**: Test imports in a non-production environment first
4. **Review zone files**: Inspect zone files for errors before importing
5. **Use skip-existing**: Use `--skip-existing` to avoid overwriting existing zones
6. **Start small**: Test with a small subset of zones before doing bulk imports

### Quick Safety Check

```bash
# 1. Create database backup
mysqldump -u root -p dns3_db > backup_before_import.sql

# 2. Run dry-run first
python3 scripts/import_bind_zones.py --dir /path/to/zones --dry-run --api-url http://localhost/dns3 --api-token YOUR_TOKEN

# 3. Review output, then run actual import
python3 scripts/import_bind_zones.py --dir /path/to/zones --skip-existing --api-url http://localhost/dns3 --api-token YOUR_TOKEN
```

---

## Python Importer

The Python importer (`scripts/import_bind_zones.py`) is the recommended tool for importing BIND zone files. It uses the dnspython library to parse zone files correctly and can operate in two modes.

### Features

- **Accurate parsing**: Uses dnspython library for RFC-compliant zone file parsing
- **$ORIGIN support**: Correctly handles $ORIGIN directives
- **SOA extraction**: Extracts SOA record fields (MNAME, RNAME, timers) and stores them in zone metadata
- **$INCLUDE processing**: Detects $INCLUDE directives (requires `--create-includes` flag)
- **Two operation modes**:
  - **API mode** (default): Uses HTTP endpoints (zone_api.php, dns_api.php) - preferred method
  - **DB mode**: Direct MySQL insertion with schema introspection
- **Dry-run support**: Preview what will be imported without making changes
- **Schema detection**: Automatically detects available database columns
- **Error handling**: Comprehensive error reporting and logging
- **Testing mode**: `--example` flag for quick smoke tests

### Dependencies

The Python importer requires:

- Python 3.6 or higher
- dnspython library (for zone parsing)
- requests library (for API mode)
- pymysql library (for DB mode)

### Installation

Install required Python packages:

```bash
# Install all dependencies
pip3 install dnspython requests pymysql

# Or install individually
pip3 install dnspython  # Required
pip3 install requests   # Required for API mode
pip3 install pymysql    # Required for DB mode
```

Alternatively, if a `requirements.txt` exists:

```bash
pip3 install -r requirements.txt
```

### Usage - API Mode

API mode is the **recommended** approach as it uses the application's existing authentication and validation logic.

**Prerequisites**:
- DNS3 application must be running and accessible
- You need an API authentication token (Bearer token)
- The API endpoints must be available: `/api/zone_api.php` and `/api/dns_api.php`

**Basic usage**:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_API_TOKEN
```

**With options**:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_API_TOKEN \
  --dry-run \
  --skip-existing \
  --verbose
```

### Usage - Database Mode

Database mode performs direct MySQL insertion. Use this mode when:
- The API is not available or not working
- You need faster bulk imports
- You're importing into a test/staging database

**Basic usage**:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db
```

**With options**:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-host localhost \
  --db-port 3306 \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db \
  --dry-run \
  --skip-existing
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dir PATH` | Directory containing zone files | Required |
| `--dry-run` | Preview mode - no changes made | Off |
| `--skip-existing` | Skip zones that already exist | Off |
| `--verbose, -v` | Enable detailed logging | Off |
| `--example` | Run with sample zone for testing | Off |
| **API Mode** | | |
| `--api-url URL` | Base URL of dns3 application | Required for API mode |
| `--api-token TOKEN` | API authentication token (Bearer) | Required for API mode |
| **Database Mode** | | |
| `--db-mode` | Use direct database insertion | Off (API mode default) |
| `--db-host HOST` | Database server hostname | localhost |
| `--db-port PORT` | Database server port | 3306 |
| `--db-user USER` | Database username | root |
| `--db-pass PASS` | Database password | Empty string |
| `--db-name NAME` | Database name | dns3_db |
| **Other** | | |
| `--user-id ID` | User ID for created_by field | 1 |
| `--create-includes` | Create entries for $INCLUDE directives | Off |

---

## Bash Importer

The Bash importer (`scripts/import_bind_zones.sh`) is a lightweight alternative for simple zone files. It uses heuristic parsing and is suitable for straightforward zones without complex features.

### Features

- **No dependencies**: Pure Bash script, only requires MySQL client
- **Heuristic parsing**: Simple regex-based parsing for common record types
- **Schema detection**: Introspects database schema via information_schema
- **Dry-run support**: Preview mode for testing
- **SQL injection protection**: Validates identifiers and escapes values

### Limitations

⚠️ **WARNING**: The Bash importer has limitations:

- **Heuristic parser**: May not handle complex or multi-line records correctly
- **Limited record types**: Supports A, AAAA, CNAME, MX, NS, PTR, TXT, SRV, CAA only
- **No $INCLUDE support**: Cannot process $INCLUDE directives
- **No DNSSEC**: Does not support DNSSEC records (DNSKEY, RRSIG, etc.)
- **Simple SOA**: Basic SOA parsing may fail on non-standard formatting
- **No validation**: Does not validate zone syntax before importing

**Recommendation**: Use the Python importer for:
- Complex zones with $INCLUDE directives
- Zones with DNSSEC records
- Multi-line records or non-standard formatting
- Production environments requiring accuracy

Use the Bash importer only for:
- Simple test zones
- Quick imports of straightforward zone files
- Environments where Python is not available

### Usage

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/zones \
  --db-user root \
  --db-pass YOUR_PASSWORD
```

**With options**:

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/zones \
  --db-user root \
  --db-pass YOUR_PASSWORD \
  --db-name dns3_db \
  --dry-run \
  --skip-existing
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dir PATH` | Directory containing zone files | Required |
| `--dry-run` | Preview mode - no changes made | Off |
| `--db-host HOST` | Database server hostname | localhost |
| `--db-port PORT` | Database server port | 3306 |
| `--db-user USER` | Database username | root |
| `--db-pass PASS` | Database password | Prompts if not provided |
| `--db-name NAME` | Database name | dns3_db |
| `--skip-existing` | Skip zones that already exist | Off |
| `--user-id ID` | User ID for created_by field | 1 |

---

## Comparison

| Feature | Python Importer | Bash Importer |
|---------|----------------|---------------|
| **Parsing Accuracy** | High (RFC-compliant) | Low (heuristic) |
| **Dependencies** | Python, dnspython, requests/pymysql | Bash, mysql client |
| **API Mode** | ✅ Yes | ❌ No |
| **DB Mode** | ✅ Yes | ✅ Yes |
| **$ORIGIN Support** | ✅ Yes | ⚠️ Basic |
| **$INCLUDE Support** | ✅ Yes (with flag) | ❌ No |
| **SOA Parsing** | ✅ Complete | ⚠️ Basic |
| **Record Types** | ✅ All types | ⚠️ Common types only |
| **DNSSEC Support** | ✅ Yes | ❌ No |
| **Multi-line Records** | ✅ Yes | ❌ No |
| **Error Handling** | ✅ Comprehensive | ⚠️ Basic |
| **Performance** | Medium | Fast |
| **Recommended For** | Production, complex zones | Testing, simple zones |

---

## Examples

### Example 1: Dry-run with Python (API mode)

Test what would be imported without making changes:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url http://localhost/dns3 \
  --api-token abc123xyz \
  --dry-run \
  --verbose
```

Output:
```
2024-12-08 15:00:00 [INFO] Using API mode (HTTP requests)
2024-12-08 15:00:00 [INFO] DRY-RUN mode enabled - no changes will be made
2024-12-08 15:00:00 [INFO] Found 3 zone file(s) in /var/named/zones
2024-12-08 15:00:00 [INFO] Processing zone file: example.com.zone
2024-12-08 15:00:00 [INFO] [DRY-RUN] Would create zone: example.com
2024-12-08 15:00:00 [INFO] [DRY-RUN] Would create 15 records
...
2024-12-08 15:00:05 [INFO] Import Statistics:
2024-12-08 15:00:05 [INFO]   Zones created: 3
2024-12-08 15:00:05 [INFO]   Records created: 45
2024-12-08 15:00:05 [INFO]   Errors: 0
```

### Example 2: Import with Python (DB mode)

Direct database import with existing zone skip:

```bash
python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --db-mode \
  --db-user dns3_user \
  --db-pass secretpassword \
  --db-name dns3_db \
  --skip-existing
```

### Example 3: Import with Bash (simple zones)

Import simple zones using Bash script:

```bash
./scripts/import_bind_zones.sh \
  --dir /var/named/simple_zones \
  --db-user root \
  --db-pass password \
  --dry-run
```

### Example 4: Test with example zone

Quick test using built-in example:

```bash
python3 scripts/import_bind_zones.py --example
```

Output:
```
2024-12-08 15:00:00 [INFO] Running in EXAMPLE mode with sample zone data
Sample zone content:

$ORIGIN example.com.
$TTL 3600
@       IN      SOA     ns1.example.com. admin.example.com. (...)
        IN      NS      ns1.example.com.
        IN      A       192.0.2.1
www     IN      A       192.0.2.1
...

Parsed zone successfully!

Extracted 7 records:
  - example.com. 3600 IN NS ns1.example.com.
  - example.com. 3600 IN NS ns2.example.com.
  - example.com. 3600 IN A 192.0.2.1
  - www.example.com. 3600 IN A 192.0.2.1
  ...
```

### Example 5: Import with authentication token

Using API mode with proper authentication:

```bash
# Set API token as environment variable (recommended)
export DNS3_API_TOKEN="your-secret-token-here"

python3 scripts/import_bind_zones.py \
  --dir /var/named/zones \
  --api-url https://dns.example.com \
  --api-token "$DNS3_API_TOKEN" \
  --skip-existing
```

---

## Troubleshooting

### Common Issues

#### 1. Python dependencies not found

**Error**: `ImportError: No module named 'dns'`

**Solution**: Install dnspython:
```bash
pip3 install dnspython
```

#### 2. API authentication fails

**Error**: `API error creating zone: 401 - Authentication required`

**Solution**: 
- Verify your API token is correct
- Check that the token is not expired
- Ensure you're using `Bearer` token format
- Test API endpoint manually: `curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost/dns3/api/zone_api.php?action=list_zones`

#### 3. Database connection fails

**Error**: `Database connection failed: Access denied for user`

**Solution**:
- Verify database credentials
- Check MySQL user has necessary privileges: `GRANT ALL ON dns3_db.* TO 'user'@'localhost';`
- Test connection manually: `mysql -u user -p dns3_db`

#### 4. Zone parsing fails

**Error**: `Failed to parse zone file: unexpected end of file`

**Solution**:
- Check zone file syntax: `named-checkzone example.com /path/to/zone/file`
- Ensure $ORIGIN is set correctly
- Verify zone file is not corrupted
- Use Python importer instead of Bash for complex zones

#### 5. Records not created

**Problem**: Zones created but no records appear

**Solution**:
- Check logs with `--verbose` flag
- Verify SOA record is not the only record in the zone
- Check that record types are supported by the database schema
- Ensure zone_file_id foreign key is set correctly

#### 6. Bash parser fails on valid zones

**Problem**: Bash importer skips valid records

**Solution**:
- Use Python importer for accurate parsing
- Bash parser is heuristic and may not handle all formats
- Check zone file has standard formatting (one record per line for simple records)

#### 7. Permission denied errors

**Error**: `Permission denied` when accessing zone files

**Solution**:
```bash
# Check file permissions
ls -l /var/named/zones/

# Make readable by your user
sudo chmod +r /var/named/zones/*.zone

# Or run as appropriate user
sudo -u named python3 scripts/import_bind_zones.py ...
```

### Debugging Tips

1. **Enable verbose logging**:
   ```bash
   python3 scripts/import_bind_zones.py --dir /path/to/zones --verbose ...
   ```

2. **Test with one zone file**:
   ```bash
   # Create test directory with single zone
   mkdir /tmp/test_import
   cp /var/named/zones/example.com.zone /tmp/test_import/
   python3 scripts/import_bind_zones.py --dir /tmp/test_import --dry-run ...
   ```

3. **Check database schema**:
   ```bash
   mysql -u root -p dns3_db -e "DESCRIBE zone_files;"
   mysql -u root -p dns3_db -e "DESCRIBE dns_records;"
   ```

4. **Validate zone file syntax**:
   ```bash
   named-checkzone example.com /var/named/zones/example.com.zone
   ```

5. **Test API endpoints manually**:
   ```bash
   # Test zone API
   curl -X POST -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name":"test.com","filename":"test.zone","file_type":"master"}' \
     http://localhost/dns3/api/zone_api.php?action=create_zone
   ```

### Getting Help

If you encounter issues not covered here:

1. Check application logs: `/var/log/dns3/` or web server error logs
2. Review database logs for SQL errors
3. Test with `--example` flag to verify basic functionality
4. Check zone file format with `named-checkzone`
5. Verify database schema matches expectations in `structure_ok_dns3_db.sql`

### Performance Considerations

For large imports (hundreds/thousands of zones):

- **Use DB mode** for better performance (bypasses HTTP overhead)
- **Disable foreign key checks** temporarily (only in DB mode, testing environment)
- **Import in batches** rather than all at once
- **Monitor database performance** during import
- **Use `--skip-existing`** to avoid redundant imports

Example for large imports:
```bash
# Import in batches
for batch in batch1 batch2 batch3; do
  python3 scripts/import_bind_zones.py \
    --dir /var/named/zones/$batch \
    --db-mode \
    --db-user root \
    --db-pass password \
    --skip-existing
  
  # Give database time to process
  sleep 10
done
```

---

## Summary

- **Use Python importer for production**: More accurate, supports complex zones
- **Use API mode when possible**: Leverages application authentication and validation
- **Always test with --dry-run first**: Preview changes before applying
- **Backup database before importing**: Safety first!
- **Use Bash importer for simple test cases only**: Limited accuracy

For most use cases, the recommended command is:

```bash
python3 scripts/import_bind_zones.py \
  --dir /path/to/zones \
  --api-url http://localhost/dns3 \
  --api-token YOUR_TOKEN \
  --dry-run \
  --skip-existing
```

Then remove `--dry-run` after verifying the output.
