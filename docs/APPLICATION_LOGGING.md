# Application Logging

DNS3 includes a comprehensive application logging system to help diagnose issues with authentication, ACL checks, and API operations.

## Configuration

In `config.php`, configure logging path and level:

```php
// Enable logging to a custom file
define('APP_LOG_PATH', '/var/log/dns3/app.log');

// Or use null/omit to fall back to PHP's error_log
define('APP_LOG_PATH', null);

// Set log level: DEBUG logs all ACL checks, INFO logs auth/errors only
// Use INFO for production to avoid high log volume
define('APP_LOG_LEVEL', 'INFO');  // Options: DEBUG, INFO (default)
```

**Important**: 
- Ensure the web server has write permissions to the log file path
- Use `INFO` level in production environments to avoid performance impact
- Use `DEBUG` level only for troubleshooting specific issues

## Log Format

All log entries follow a consistent format:

```
TIMESTAMP [dns3][LEVEL][module] message {context_json}
```

- **TIMESTAMP**: ISO 8601 format (YYYY-MM-DD HH:MM:SS)
- **LEVEL**: DEBUG, INFO, WARN, or ERROR
- **module**: Component that generated the log (auth, acl, acl_api)
- **message**: Human-readable description
- **context_json**: Structured data in JSON format

### Log Levels

- **DEBUG**: Verbose logging including all ACL checks (high volume, use only for troubleshooting)
- **INFO**: Authentication events and system operations (recommended for production)
- **WARN**: Warning conditions that don't prevent operation (e.g., failed login, insufficient permissions)
- **ERROR**: Error conditions that prevent operation (e.g., connection failures, exceptions)

## Logged Events

### Authentication Events

**Login Attempts**
```
2025-12-19 14:30:15 [dns3][INFO][auth] Login attempt {"username":"john.doe","method":"ad","source":"192.168.1.100"}
```

**AD Group Fetching**
```
2025-12-19 14:30:16 [dns3][INFO][auth] AD groups fetched {"username":"john.doe","user_dn":"CN=John Doe,OU=Users,DC=example,DC=com","group_count":3}
```

**Successful Authentication**
```
2025-12-19 14:30:16 [dns3][INFO][auth] AD authentication successful {"username":"john.doe","user_id":42,"group_count":3,"matched_role_count":1,"has_acl":true}
2025-12-19 14:30:17 [dns3][INFO][auth] LDAP authentication successful {"username":"jane.smith","user_id":43,"matched_role_count":2,"has_acl":true}
2025-12-19 14:30:18 [dns3][INFO][auth] Database authentication successful {"username":"admin","user_id":1}
```

**Failed Authentication**
```
2025-12-19 14:30:20 [dns3][WARN][auth] Login failed {"username":"unknown.user","method":"auto","error":"invalid_credentials","source":"192.168.1.100"}
2025-12-19 14:30:21 [dns3][WARN][auth] AD authentication denied - no mappings or ACL {"username":"john.doe","user_dn":"CN=John Doe,OU=Users,DC=example,DC=com","group_count":3}
```

**Authentication Errors**
```
2025-12-19 14:30:25 [dns3][ERROR][auth] AD connection failed {"username":"john.doe","server":"ldap://ad.example.com","port":389}
2025-12-19 14:30:26 [dns3][ERROR][auth] AD authentication exception {"username":"john.doe","error":"Connection timeout"}
2025-12-19 14:30:27 [dns3][ERROR][auth] Database authentication error {"username":"admin","error":"Connection refused"}
```

### ACL Check Events

**Successful ACL Matches** (DEBUG level only)
```
2025-12-19 14:31:00 [dns3][DEBUG][acl] ACL match by user {"zone_id":123,"user_id":42,"permission":"write"}
2025-12-19 14:31:01 [dns3][DEBUG][acl] ACL match by role {"zone_id":123,"user_id":42,"role":"zone_editor","permission":"write"}
2025-12-19 14:31:02 [dns3][DEBUG][acl] ACL match by ad_group (exact) {"zone_id":123,"user_id":42,"user_group":"CN=DNSAdmins,OU=Groups,DC=example,DC=com","acl_group":"CN=DNSAdmins,OU=Groups,DC=example,DC=com","permission":"admin"}
```

Note: Successful ACL matches are only logged at DEBUG level to avoid excessive log volume in production.

**Failed ACL Checks**
```
2025-12-19 14:31:10 [dns3][WARN][acl] ACL check failed - insufficient permission {"zone_id":456,"user_id":42,"required":"admin","max_permission":"read","user_roles":["zone_editor"],"user_groups_count":3}
```

### ACL CRUD Operations

**ACL Entry Creation**
```
2025-12-19 14:32:00 [dns3][INFO][acl] ACL entry created {"acl_id":789,"zone_id":123,"subject_type":"ad_group","subject_identifier":"CN=DNSAdmins,OU=Groups,DC=example,DC=com","permission":"admin","created_by":1}
```

**ACL Entry Deletion**
```
2025-12-19 14:32:10 [dns3][INFO][acl] ACL entry deleted {"acl_id":789,"zone_id":123,"subject_type":"ad_group","subject_identifier":"CN=DNSAdmins,OU=Groups,DC=example,DC=com","permission":"admin"}
```

**ACL API Errors**
```
2025-12-19 14:32:20 [dns3][ERROR][acl_api] Failed to create ACL entry {"zone_id":999,"subject_type":"user","subject_identifier":"invalid_user","permission":"read","created_by":1}
2025-12-19 14:32:21 [dns3][ERROR][acl_api] Failed to delete ACL entry {"acl_id":999,"zone_id":null,"subject_type":null,"subject_identifier":null}
```

## Security Features

### Sensitive Data Redaction

The logger automatically redacts sensitive information:

```
2025-12-19 14:33:00 [dns3][INFO][auth] Testing data sanitization {"username":"test.user","password":"[REDACTED]","api_key":"[REDACTED]","normal_data":"this_is_visible"}
```

**Redacted fields** (case-insensitive matching):
- password, passwd, pwd
- token
- secret
- api_key, apikey

## Usage Examples

### Diagnosing Authentication Issues

**Scenario**: User cannot log in via Active Directory

1. Search logs for username:
   ```bash
   grep "john.doe" /var/log/dns3/app.log
   ```

2. Look for authentication events:
   - Check if login attempt was recorded
   - Verify AD groups were fetched
   - Check for authentication success/failure
   - Look for error messages

**Example troubleshooting**:
```
2025-12-19 14:30:15 [dns3][INFO][auth] Login attempt {"username":"john.doe","method":"ad","source":"192.168.1.100"}
2025-12-19 14:30:16 [dns3][INFO][auth] AD groups fetched {"username":"john.doe","user_dn":"CN=John Doe,OU=Users,DC=example,DC=com","group_count":0}
2025-12-19 14:30:16 [dns3][WARN][auth] AD authentication denied - no mappings or ACL {"username":"john.doe","user_dn":"CN=John Doe,OU=Users,DC=example,DC=com","group_count":0}
```
→ **Diagnosis**: User has no AD groups, and no direct ACL or mapping exists.

### Diagnosing ACL Issues

**Scenario**: User has AD group but cannot access zone

1. Find ACL checks for the zone:
   ```bash
   grep "zone_id\":123" /var/log/dns3/app.log
   ```

2. Look for ACL match attempts:
   - Check if ad_group comparison was attempted
   - Verify the user's groups vs ACL groups
   - Check permission level required vs granted

**Example troubleshooting**:
```
2025-12-19 14:31:10 [dns3][WARN][acl] ACL check failed - insufficient permission {"zone_id":123,"user_id":42,"required":"admin","max_permission":"read","user_roles":["zone_editor"],"user_groups_count":3}
```
→ **Diagnosis**: User has 'read' permission but 'admin' is required.

### Analyzing Log Patterns

**Get all authentication failures**:
```bash
grep "[WARN][auth] Login failed" /var/log/dns3/app.log
```

**Get all ACL denials**:
```bash
grep "[WARN][acl] ACL check failed" /var/log/dns3/app.log
```

**Get all errors**:
```bash
grep "[ERROR]" /var/log/dns3/app.log
```

**Count logins by method**:
```bash
grep "authentication successful" /var/log/dns3/app.log | grep -o '"method":"[^"]*"' | sort | uniq -c
```

## Log Rotation

For production environments, configure log rotation using `logrotate`:

```bash
# /etc/logrotate.d/dns3
/var/log/dns3/app.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0644 www-data www-data
}
```

## Performance Considerations

### Log Level Impact

- **DEBUG level**: Logs every ACL check, can generate hundreds of entries per page load
- **INFO level**: Logs authentication and API operations only, minimal overhead
- **Recommendation**: Use INFO in production, DEBUG only for troubleshooting

### I/O Characteristics

- Log entries are written synchronously with file locking (`LOCK_EX`)
- Each log entry involves disk I/O (unless buffered by OS)
- File locking ensures log integrity but can become a bottleneck under high concurrency

### Optimization Strategies

For high-traffic production environments:

1. **Use INFO level** to reduce log volume
2. **Dedicated log partition** to isolate I/O from application data
3. **RAM disk** for log files (with periodic sync to permanent storage)
4. **Syslog integration**: Set `APP_LOG_PATH` to `null` and configure PHP error_log to use syslog
5. **External log aggregation**: Forward logs to centralized system (ELK, Splunk, etc.)
6. **Asynchronous logging**: Consider implementing a message queue for log entries

### Example: Syslog Integration

```php
// In config.php
define('APP_LOG_PATH', null);  // Use PHP error_log

// In php.ini or .htaccess
error_log = syslog
```

Then configure rsyslog to handle application logs separately:
```
# /etc/rsyslog.d/dns3.conf
if $programname == 'php' and $msg contains '[dns3]' then /var/log/dns3/app.log
& stop
```

## Integration with External Systems

The structured JSON format makes it easy to integrate with log aggregation tools:

### Elasticsearch/Logstash
Parse JSON context fields for structured searching

### Splunk
Index by timestamp and module for dashboard creation

### CloudWatch/DataDog
Forward logs and create alerts on ERROR level events
