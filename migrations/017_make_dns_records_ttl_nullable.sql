-- Make dns_records.ttl column nullable with DEFAULT NULL
-- This allows records to explicitly have no TTL set, which means
-- the zone's default TTL will be used when generating zone files

ALTER TABLE dns_records MODIFY COLUMN ttl INT(11) NULL DEFAULT NULL;
