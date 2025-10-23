# Migration 012 - Disabled

Migration 012 (`012_add_validation_command_fields.sql`) has been disabled because the actual database schema in `structure_ok_dns3_db.sql` does not include `command` and `return_code` columns in the `zone_file_validation` table.

Instead, the validation system now embeds the command and exit code directly into the `output` TEXT field, following this format:

```
Command: <command line>
Exit Code: <return code>

<stdout/stderr output>
```

This approach:
1. Matches the actual database schema
2. Keeps all validation information in a single field
3. Allows for proper truncation of large outputs
4. Maintains backward compatibility with existing validation records

If you need to apply this migration to an existing database that already has these columns, the system will continue to work by embedding the information in the output field.
