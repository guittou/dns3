# DNSSEC Include Paths Feature

## Overview

This feature allows operators to reference external DNSSEC key files (KSK and ZSK) in master zones. These include directives are automatically injected into the generated zone file and are properly handled during validation.

## Configuration

### BIND_BASEDIR

Add the `BIND_BASEDIR` configuration parameter to your `config.php`:

```php
// BIND configuration
// BIND_BASEDIR: Base directory for resolving relative include paths during validation
// - If set, relative include paths will be resolved as BIND_BASEDIR/<path>
// - If not set (null), relative includes will be left as-is (validation may fail if file doesn't exist)
// - Absolute include paths are always used as-is, regardless of this setting
// Example: define('BIND_BASEDIR', '/etc/bind');
if (!defined('BIND_BASEDIR')) define('BIND_BASEDIR', null);
```

**Recommended**: Set `BIND_BASEDIR` to your BIND configuration directory (e.g., `/etc/bind`) if you plan to use relative paths for DNSSEC includes.

## Usage

### Adding DNSSEC Includes to a Master Zone

1. Navigate to the zone file detail page for a master zone
2. In the "Détails" tab, you'll find two new fields:
   - **DNSSEC KSK Include**: Path to the Key Signing Key include file
   - **DNSSEC ZSK Include**: Path to the Zone Signing Key include file

3. Enter the path(s) to your DNSSEC key files:
   - **Absolute paths** (recommended): `/etc/bind/keys/example.com.ksk.key`
   - **Relative paths**: `keys/example.com.ksk.key` (requires BIND_BASEDIR to be configured)

4. Save the zone

### Path Types

#### Absolute Paths (Recommended)

Absolute paths start with `/` and point to the exact location of the file on the filesystem:

```
/etc/bind/keys/example.com.ksk.key
/var/lib/bind/dnssec/example.com.zsk.key
```

**Advantages**:
- Work regardless of BIND_BASEDIR configuration
- Clear and unambiguous
- Named-checkzone validation will read the actual files

**During validation**: Absolute paths are used as-is. The system verifies that the files exist and logs warnings if they don't.

#### Relative Paths

Relative paths don't start with `/` and are resolved relative to BIND_BASEDIR:

```
keys/example.com.ksk.key
dnssec/example.com.zsk.key
```

**Requirements**:
- `BIND_BASEDIR` must be configured in `config.php`
- Files must exist under `BIND_BASEDIR/<relative_path>`

**During validation**: Relative paths are resolved to `BIND_BASEDIR/<path>` before passing to named-checkzone.

**Example**: If `BIND_BASEDIR = '/etc/bind'` and you specify `keys/example.com.ksk.key`, the validation will use `/etc/bind/keys/example.com.ksk.key`.

## Zone File Generation

When you generate a zone file for a master zone with DNSSEC includes, the system automatically injects `$INCLUDE` directives in the following order:

1. `$TTL` directive
2. SOA record
3. **DNSSEC KSK Include** (if specified)
4. **DNSSEC ZSK Include** (if specified)
5. Zone content
6. Other includes (from zone_file_includes table)
7. DNS records

Example generated zone file:

```
$TTL 86400

@ IN SOA ns1.example.com. admin.example.com. (
    2025121801 ; Serial
    10800 ; Refresh
    900 ; Retry
    604800 ; Expire
    3600 ; Minimum
)

; DNSSEC KSK Include
$INCLUDE "/etc/bind/keys/example.com.ksk.key"

; DNSSEC ZSK Include
$INCLUDE "/etc/bind/keys/example.com.zsk.key"

; Zone content and other includes...
```

## Validation Behavior

### With Absolute Paths

When DNSSEC includes use absolute paths:
1. The `$INCLUDE` directives are kept as-is in the generated zone file
2. Named-checkzone reads the actual files from disk during validation
3. No temporary files are created for DNSSEC includes
4. Validation passes if the files exist and are valid

### With Relative Paths and BIND_BASEDIR

When DNSSEC includes use relative paths and `BIND_BASEDIR` is configured:
1. The system resolves the relative paths to absolute paths using `BIND_BASEDIR`
2. The resolved paths are used in the `$INCLUDE` directives
3. Named-checkzone reads the actual files from disk during validation
4. Validation passes if the resolved files exist and are valid

### With Relative Paths without BIND_BASEDIR

When DNSSEC includes use relative paths and `BIND_BASEDIR` is NOT configured:
1. The `$INCLUDE` directives are kept as-is with relative paths
2. Named-checkzone will look for files relative to its working directory
3. A warning is logged during validation
4. Validation may fail if named-checkzone cannot find the files

## Database Schema

The following columns were added to the `zone_files` table:

```sql
ALTER TABLE zone_files 
ADD COLUMN dnssec_include_ksk VARCHAR(255) NULL 
COMMENT 'Path to DNSSEC KSK include file (e.g., /etc/bind/keys/domain.ksk.key)'
AFTER mname;

ALTER TABLE zone_files 
ADD COLUMN dnssec_include_zsk VARCHAR(255) NULL 
COMMENT 'Path to DNSSEC ZSK include file (e.g., /etc/bind/keys/domain.zsk.key)'
AFTER dnssec_include_ksk;
```

To apply this migration to an existing database, run:

```bash
mysql -u root -p dns3_db < docs/migrations/add_dnssec_includes.sql
```

## API Changes

### Create Zone Endpoint

The `create_zone` endpoint now accepts two optional parameters for master zones:

```json
{
  "name": "example.com",
  "filename": "db.example.com",
  "file_type": "master",
  "dnssec_include_ksk": "/etc/bind/keys/example.com.ksk.key",
  "dnssec_include_zsk": "/etc/bind/keys/example.com.zsk.key"
}
```

### Update Zone Endpoint

The `update_zone` endpoint now accepts the same optional parameters:

```json
{
  "dnssec_include_ksk": "/etc/bind/keys/example.com.ksk.key",
  "dnssec_include_zsk": "/etc/bind/keys/example.com.zsk.key"
}
```

### Validation

The API validates DNSSEC include paths:
- Maximum length: 255 characters
- Path cannot contain `..` (for security)
- Only available for master zones (ignored for include zones)

## Best Practices

1. **Use absolute paths** for DNSSEC includes whenever possible for clarity and reliability
2. **Set BIND_BASEDIR** if you plan to use relative paths
3. **Ensure key files exist** on the filesystem before adding them to zones
4. **Use consistent naming** for key files (e.g., `domain.ksk.key`, `domain.zsk.key`)
5. **Test validation** after adding DNSSEC includes to ensure files are accessible
6. **Document key file locations** in your operational procedures

## Troubleshooting

### Validation fails with "file not found"

**For absolute paths**:
- Verify the file exists at the exact path specified
- Check file permissions (named-checkzone must be able to read it)

**For relative paths**:
- Verify `BIND_BASEDIR` is configured correctly in `config.php`
- Verify the file exists at `BIND_BASEDIR/<relative_path>`
- Check file permissions

### DNSSEC fields not visible in UI

- Verify you're editing a **master** zone (not an include zone)
- DNSSEC fields are only shown for master zones

### Validation logs show warnings

Check the validation output in the worker log (`jobs/worker.log`) for specific error messages about DNSSEC includes.

## Migration Guide

For existing installations, follow these steps:

1. **Backup your database**:
   ```bash
   mysqldump -u root -p dns3_db > backup_$(date +%Y%m%d).sql
   ```

2. **Apply the schema migration**:
   ```bash
   mysql -u root -p dns3_db < docs/migrations/add_dnssec_includes.sql
   ```

3. **Update config.php** to add the `BIND_BASEDIR` parameter (optional but recommended)

4. **Clear any cached zone files** if applicable

5. **Test with a non-production zone** first to verify the feature works as expected

## Security Considerations

- DNSSEC include paths are validated to prevent directory traversal attacks (`..` is rejected)
- No file contents are stored in the database - only paths
- The validation process runs with the same permissions as the web server
- Ensure DNSSEC key files have appropriate permissions (readable by web server user)
- Consider using absolute paths to avoid ambiguity
