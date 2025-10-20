-- Migration 004: Remove disabled status from DNS records
-- This migration converts all 'disabled' DNS records to 'deleted' status
-- and creates history entries to track the conversion.

USE dns3_db;

-- Start transaction
START TRANSACTION;

-- Convert all disabled DNS records to deleted (idempotent - only if still disabled)
UPDATE dns_records 
SET status = 'deleted', 
    updated_at = NOW()
WHERE status = 'disabled';

-- Create history entries for all converted records
-- This tracks the migration from 'disabled' to 'deleted' status
INSERT INTO dns_record_history (
    record_id,
    action,
    record_type,
    name,
    value,
    ttl,
    priority,
    old_status,
    new_status,
    changed_by,
    notes
)
SELECT 
    dr.id,
    'status_changed' as action,
    dr.record_type,
    dr.name,
    dr.value,
    dr.ttl,
    dr.priority,
    'disabled' as old_status,
    'deleted' as new_status,
    dr.updated_by as changed_by,
    'Automatic migration: disabled status removed from system' as notes
FROM dns_records dr
WHERE dr.status = 'deleted' 
  AND dr.updated_at >= DATE_SUB(NOW(), INTERVAL 1 MINUTE)
  AND NOT EXISTS (
      SELECT 1 FROM dns_record_history drh 
      WHERE drh.record_id = dr.id 
        AND drh.old_status = 'disabled' 
        AND drh.new_status = 'deleted'
        AND drh.notes = 'Automatic migration: disabled status removed from system'
  );

-- Commit transaction
COMMIT;

-- Note: The ENUM values in the schema will remain as is for backward compatibility
-- with any existing data. The application layer will enforce only 'active' and 'deleted'.
