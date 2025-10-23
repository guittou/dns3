# Background Jobs for DNS3

This directory contains background job workers for DNS3 application.

## Zone Validation Worker

The zone validation worker processes queued `named-checkzone` validation jobs for zone files.

### Setup

1. Ensure the `named-checkzone` binary is installed and accessible:
   ```bash
   which named-checkzone
   ```

2. Make the worker script executable:
   ```bash
   chmod +x jobs/worker.sh
   ```

3. Test the worker manually:
   ```bash
   ./jobs/worker.sh
   ```

4. Add to crontab to run every minute:
   ```bash
   crontab -e
   ```
   
   Add this line:
   ```
   * * * * * /path/to/dns3/jobs/worker.sh >> /var/log/dns3-worker.log 2>&1
   ```

### How it works

1. When a zone is created or updated, a validation job is queued in `jobs/validation_queue.json`
2. The cron job runs `worker.sh` every minute
3. The worker processes all queued jobs using `process_validations.php`:
   - For zones with `$INCLUDE` directives, the worker **flattens** the zone by inlining all include file contents recursively
   - Writes the flattened zone to a temporary file
   - Runs `named-checkzone` against the flattened file
   - Stores validation results in the database
   - Cleans up temporary files (unless `JOBS_KEEP_TMP=1`)
4. Validation results are stored in the `zone_file_validation` table
5. Results can be retrieved via the API: `/api/zone_api.php?action=zone_validate&id=<zone_id>`

### Configuration

Set these options in `config.php`:

- `ZONE_VALIDATE_SYNC`: Set to `true` to run validation synchronously (default: `false`)
- `NAMED_CHECKZONE_PATH`: Path to the `named-checkzone` binary (default: `named-checkzone`)

Set these environment variables when running the worker:

- `JOBS_KEEP_TMP`: Set to `1` to keep temporary files for debugging (default: not set, files are cleaned up)

### Logs

Worker logs are written to:
- `jobs/worker.log` - Worker execution log
- System logs based on cron configuration

### Troubleshooting

**Issue**: Validations stay in "pending" status
- Check if cron job is running: `grep CRON /var/log/syslog`
- Check worker log: `cat jobs/worker.log`
- Verify named-checkzone is installed: `which named-checkzone`

**Issue**: Validation fails with "command not found"
- Update `NAMED_CHECKZONE_PATH` in config.php with full path to binary
- Example: `define('NAMED_CHECKZONE_PATH', '/usr/sbin/named-checkzone');`

**Issue**: Permission denied
- Ensure worker.sh is executable: `chmod +x jobs/worker.sh`
- Ensure web server user can write to jobs directory: `chown -R www-data:www-data jobs/`

**Issue**: Include file validation fails
- Ensure include files exist in `zone_files` table with `file_type='include'`
- Check for circular dependencies in include chains
- Set `JOBS_KEEP_TMP=1` and inspect the flattened zone file in `/tmp/dns3_validate_*`

For detailed documentation on include flattening, see `VALIDATION_FLATTENING_IMPLEMENTATION.md`
