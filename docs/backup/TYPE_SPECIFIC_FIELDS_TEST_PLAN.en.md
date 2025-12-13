# Type-Specific Fields Implementation - Test Plan

## Overview
This document outlines the testing requirements for the type-specific DNS record fields implementation.

## Changes Summary
- Added dedicated columns for each DNS record type (A, AAAA, CNAME, PTR, TXT)
- Restricted supported types to: A, AAAA, CNAME, PTR, TXT only
- API accepts `value` as an alias for backward compatibility
- Frontend uses dedicated fields instead of generic `value` field
- `last_seen` field is server-managed and cannot be set by clients

## Test Checklist

### 1. Migration Testing
- [ ] Apply migration 005_add_type_specific_fields.sql to database
- [ ] Verify all new columns exist in dns_records table:
  - [ ] address_ipv4 (VARCHAR(15))
  - [ ] address_ipv6 (VARCHAR(45))
  - [ ] cname_target (VARCHAR(255))
  - [ ] ptrdname (VARCHAR(255))
  - [ ] txt (TEXT)
- [ ] Verify all new columns exist in dns_record_history table
- [ ] Verify indexes are created:
  - [ ] idx_address_ipv4
  - [ ] idx_address_ipv6
  - [ ] idx_cname_target
- [ ] Test migration idempotency (run twice, verify no errors)
- [ ] If existing records exist, verify data migration:
  - [ ] A records: value → address_ipv4
  - [ ] AAAA records: value → address_ipv6
  - [ ] CNAME records: value → cname_target
  - [ ] PTR records: value → ptrdname
  - [ ] TXT records: value → txt

### 2. Backend/Model Testing (DnsRecord.php)
- [ ] Test search() method returns computed `value` field
- [ ] Test getById() method returns computed `value` field
- [ ] Test create() with dedicated fields:
  - [ ] Create A record with address_ipv4
  - [ ] Create AAAA record with address_ipv6
  - [ ] Create CNAME record with cname_target
  - [ ] Create PTR record with ptrdname
  - [ ] Create TXT record with txt
- [ ] Test create() with value alias:
  - [ ] Create A record with value → maps to address_ipv4
  - [ ] Create CNAME record with value → maps to cname_target
- [ ] Test update() with dedicated fields
- [ ] Test update() with value alias
- [ ] Test writeHistory() includes dedicated fields in history

### 3. API Testing (dns_api.php)

#### Type Validation
- [ ] POST create with A record → Success
- [ ] POST create with AAAA record → Success
- [ ] POST create with CNAME record → Success
- [ ] POST create with PTR record → Success
- [ ] POST create with TXT record → Success
- [ ] POST create with MX record → 400 error "Only A, AAAA, CNAME, PTR, and TXT are supported"
- [ ] POST create with SRV record → 400 error
- [ ] POST create with NS record → 400 error

#### Field Validation - A Record
```bash
# Valid A record with dedicated field
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "A", "name": "test.example.com", "address_ipv4": "192.168.1.1"}'
# Expected: 201 Created

# Valid A record with value alias
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "A", "name": "test2.example.com", "value": "192.168.1.2"}'
# Expected: 201 Created

# Invalid A record (not an IPv4)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "A", "name": "test3.example.com", "address_ipv4": "invalid"}'
# Expected: 400 error "Address must be a valid IPv4 address"
```

#### Field Validation - AAAA Record
```bash
# Valid AAAA record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "AAAA", "name": "test.example.com", "address_ipv6": "2001:db8::1"}'
# Expected: 201 Created

# Invalid AAAA record (not an IPv6)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "AAAA", "name": "test.example.com", "address_ipv6": "192.168.1.1"}'
# Expected: 400 error "Address must be a valid IPv6 address"
```

#### Field Validation - CNAME Record
```bash
# Valid CNAME record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "CNAME", "name": "www.example.com", "cname_target": "example.com"}'
# Expected: 201 Created

# Invalid CNAME record (IP address not allowed)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "CNAME", "name": "www.example.com", "cname_target": "192.168.1.1"}'
# Expected: 400 error "CNAME target cannot be an IP address"
```

#### Field Validation - PTR Record
```bash
# Valid PTR record with reverse DNS name
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "PTR", "name": "1.1.168.192.in-addr.arpa", "ptrdname": "host.example.com"}'
# Expected: 201 Created
```

#### Field Validation - TXT Record
```bash
# Valid TXT record
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "TXT", "name": "example.com", "txt": "v=spf1 include:_spf.example.com ~all"}'
# Expected: 201 Created

# Invalid TXT record (empty content)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "TXT", "name": "example.com", "txt": ""}'
# Expected: 400 error "TXT record content cannot be empty"
```

#### last_seen Security Test
```bash
# Attempt to set last_seen (should be ignored)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=create' \
  -H 'Content-Type: application/json' \
  -d '{"record_type": "A", "name": "test.example.com", "address_ipv4": "192.168.1.1", "last_seen": "2024-01-01 00:00:00"}'
# Expected: 201 Created, but last_seen should be NULL in database

# Attempt to update last_seen (should be ignored)
curl -b cookies.txt -X POST 'http://localhost:8000/api/dns_api.php?action=update&id=1' \
  -H 'Content-Type: application/json' \
  -d '{"last_seen": "2024-01-01 00:00:00"}'
# Expected: 200 OK, but last_seen should remain unchanged
```

#### API Response Test
```bash
# Get a record and verify 'value' is included in response
curl -b cookies.txt 'http://localhost:8000/api/dns_api.php?action=get&id=1'
# Expected: Response includes both dedicated field AND computed 'value' field
```

### 4. Frontend/UI Testing (dns-management.php)

#### Form Field Visibility
- [ ] Select "A" type → only address_ipv4 field visible and required
- [ ] Select "AAAA" type → only address_ipv6 field visible and required
- [ ] Select "CNAME" type → only cname_target field visible and required
- [ ] Select "PTR" type → only ptrdname field visible and required
- [ ] Select "TXT" type → only txt field visible and required
- [ ] Type filter dropdown shows only: A, AAAA, CNAME, PTR, TXT
- [ ] Priority field is not present in the form

#### Create Record via UI
- [ ] Create A record with IPv4 address
- [ ] Create AAAA record with IPv6 address
- [ ] Create CNAME record with target hostname
- [ ] Create PTR record with reverse DNS name
- [ ] Create TXT record with text content
- [ ] Verify records appear in table with correct values

#### Edit Record via UI
- [ ] Open edit modal for A record → address_ipv4 field populated
- [ ] Open edit modal for CNAME record → cname_target field populated
- [ ] Modify A record IPv4 address → save → verify update
- [ ] Verify last_seen field is read-only on edit

#### Client-Side Validation
- [ ] A record with invalid IPv4 → error message
- [ ] AAAA record with invalid IPv6 → error message
- [ ] CNAME record with IP address → error message
- [ ] Empty required field → error message

### 5. JavaScript Testing (dns-records.js)

#### Payload Building
- [ ] A record payload includes both `address_ipv4` and `value` (same value)
- [ ] CNAME record payload includes both `cname_target` and `value`
- [ ] Payload never includes `last_seen` field

#### Validation
- [ ] validatePayloadForType() correctly validates A record IPv4
- [ ] validatePayloadForType() correctly validates AAAA record IPv6
- [ ] validatePayloadForType() correctly validates CNAME target (not IP)
- [ ] validatePayloadForType() correctly validates PTR target
- [ ] validatePayloadForType() correctly validates TXT content (not empty)

### 6. Documentation Verification
- [ ] DNS_MANAGEMENT_GUIDE.md lists only supported types (A, AAAA, CNAME, PTR, TXT)
- [ ] Documentation explains dedicated fields for each type
- [ ] Documentation mentions value alias for backward compatibility
- [ ] Documentation mentions last_seen security feature
- [ ] Examples show usage of dedicated fields

## Test Execution Steps

1. **Database Setup**
   ```bash
   mysql -u dns3_user -p dns3_db < database.sql
   ```

   > **Note** : Les fichiers de migration ont été supprimés. Utilisez `database.sql`.

2. **Verify Column Structure**
   ```sql
   DESCRIBE dns_records;
   SHOW INDEX FROM dns_records;
   ```

3. **Login as Admin**
   ```bash
   curl -c cookies.txt -X POST http://localhost:8000/login.php \
     -d "username=admin&password=admin123&auth_method=database"
   ```

4. **Run API Tests** (use curl commands above)

5. **Open Browser for UI Tests**
   - Navigate to http://localhost:8000/dns-management.php
   - Test form field visibility
   - Test CRUD operations
   - Test validation

6. **Verify Database State**
   ```sql
   SELECT id, record_type, name, address_ipv4, address_ipv6, cname_target, ptrdname, txt, value 
   FROM dns_records;
   
   SELECT * FROM dns_record_history ORDER BY changed_at DESC LIMIT 5;
   ```

## Success Criteria

All tests must pass:
- ✓ Migration applies successfully and is idempotent
- ✓ Unsupported types (MX, SRV, NS, SOA) return 400 error
- ✓ All supported types (A, AAAA, CNAME, PTR, TXT) work correctly
- ✓ Dedicated fields are validated according to type
- ✓ Value alias works for backward compatibility
- ✓ last_seen cannot be set by clients
- ✓ UI shows correct fields for each type
- ✓ Client-side and server-side validation work correctly
- ✓ History tracking includes dedicated fields
- ✓ Documentation is accurate and complete

## Known Limitations

1. The `value` field is kept in the database for backward compatibility and rollback capability
2. PTR records require the user to provide the reverse DNS name (no automatic conversion)
3. No `class` field in database (implicit class)
4. Priority field removed from UI (not used by supported types)
