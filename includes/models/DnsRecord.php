<?php
/**
 * DnsRecord Model
 * Handles CRUD operations for DNS records with automatic history tracking
 */

require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/../lib/DnsValidator.php';

class DnsRecord {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Search DNS records with filters
     * 
     * @param array $filters Optional filters (name, type, status)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of DNS records
     */
    public function search($filters = [], $limit = 100, $offset = 0) {
        $sql = "SELECT dr.*, 
                       u1.username as created_by_username,
                       u2.username as updated_by_username,
                       dr.zone_file_id,
                       COALESCE(zf.name, dr.zone_name, dr.zone) as zone_name,
                       COALESCE(zf.filename, dr.zone_file_name) as zone_file_name
                FROM dns_records dr
                LEFT JOIN users u1 ON dr.created_by = u1.id
                LEFT JOIN users u2 ON dr.updated_by = u2.id
                LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
                WHERE 1=1";
        
        $params = [];
        
        if (isset($filters['name']) && $filters['name'] !== '') {
            $sql .= " AND dr.name LIKE ?";
            $params[] = '%' . $filters['name'] . '%';
        }
        
        if (isset($filters['type']) && $filters['type'] !== '') {
            $sql .= " AND dr.record_type = ?";
            $params[] = $filters['type'];
        }
        
        if (isset($filters['status']) && $filters['status'] !== '') {
            $sql .= " AND dr.status = ?";
            $params[] = $filters['status'];
        }
        // If no status filter provided, do not force a default: return all statuses
        
        $sql .= " ORDER BY dr.created_at DESC LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;
        
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $records = $stmt->fetchAll();
            
            // Compute 'value' field from dedicated columns for backward compatibility
            foreach ($records as &$record) {
                $record['value'] = $this->getValueFromDedicatedField($record);
            }
            
            return $records;
        } catch (Exception $e) {
            error_log("DNS Record search error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a DNS record by ID
     * 
     * @param int $id Record ID
     * @param bool $includeDeleted If true, include records with status='deleted'
     * @return array|null Record data or null if not found
     */
    public function getById($id, $includeDeleted = false) {
        try {
            $sql = "SELECT dr.*, 
                           u1.username as created_by_username,
                           u2.username as updated_by_username,
                           dr.zone_file_id,
                           COALESCE(zf.name, dr.zone_name, dr.zone) as zone_name,
                           COALESCE(zf.filename, dr.zone_file_name) as zone_file_name
                    FROM dns_records dr
                    LEFT JOIN users u1 ON dr.created_by = u1.id
                    LEFT JOIN users u2 ON dr.updated_by = u2.id
                    LEFT JOIN zone_files zf ON dr.zone_file_id = zf.id
                    WHERE dr.id = ?";
            
            if (!$includeDeleted) {
                $sql .= " AND dr.status != 'deleted'";
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $record = $stmt->fetch();
            
            if ($record) {
                // Compute 'value' field from dedicated columns for backward compatibility
                $record['value'] = $this->getValueFromDedicatedField($record);
            }
            
            return $record ?: null;
        } catch (Exception $e) {
            error_log("DNS Record getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new DNS record
     * 
     * @param array $data Record data (record_type, name, and type-specific fields)
     * @param int $user_id User creating the record
     * @return int|bool New record ID or false on failure
     */
    public function create($data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            // Validate zone_file_id is required
            if (!isset($data['zone_file_id']) || empty($data['zone_file_id'])) {
                throw new Exception("zone_file_id is required");
            }
            
            // Validate that the zone file exists and is active
            $sql = "SELECT id FROM zone_files WHERE id = ? AND status = 'active'";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$data['zone_file_id']]);
            if (!$stmt->fetch()) {
                throw new Exception("Invalid or inactive zone_file_id");
            }
            
            // Explicitly remove last_seen, created_at, and updated_at if provided by client (security)
            unset($data['last_seen']);
            unset($data['created_at']);
            unset($data['updated_at']);
            
            // Map 'value' alias to dedicated field if provided
            if (isset($data['value']) && !empty($data['value'])) {
                $this->mapValueToDedicatedField($data);
            }
            
            // Extract the value for validation based on record type
            $recordType = $data['record_type'];
            $owner = $data['name'];
            $value = $this->getValueFromDedicatedFieldData($data);
            
            // Validate the record using DnsValidator
            $extraData = [];
            if (isset($data['priority'])) {
                $extraData['priority'] = $data['priority'];
            }
            
            $validation = DnsValidator::validateRecord($recordType, $owner, $value, $extraData);
            if (!$validation['valid']) {
                throw new Exception($validation['error']);
            }
            
            // Extract dedicated field values based on record type
            $dedicatedFields = $this->extractDedicatedFields($data);
            
            // Also set 'value' for backward compatibility
            $valueField = $this->getValueFromDedicatedFieldData($data);
            
            $sql = "INSERT INTO dns_records (zone_file_id, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, requester, expires_at, ticket_ref, comment, status, created_by, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['zone_file_id'],
                $data['record_type'],
                $data['name'],
                $valueField,
                $dedicatedFields['address_ipv4'],
                $dedicatedFields['address_ipv6'],
                $dedicatedFields['cname_target'],
                $dedicatedFields['ptrdname'],
                $dedicatedFields['txt'],
                $data['ttl'] ?? 3600,
                $data['priority'] ?? null,
                $data['requester'] ?? null,
                $data['expires_at'] ?? null,
                $data['ticket_ref'] ?? null,
                $data['comment'] ?? null,
                $user_id
            ]);
            
            $record_id = $this->db->lastInsertId();
            
            // Write history
            $this->writeHistory($record_id, 'created', null, 'active', $user_id, 'Record created');
            
            $this->db->commit();
            return $record_id;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("DNS Record create error: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Update a DNS record
     * 
     * @param int $id Record ID
     * @param array $data Updated record data
     * @param int $user_id User updating the record
     * @return bool Success status
     */
    public function update($id, $data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            // Validate zone_file_id if provided
            if (isset($data['zone_file_id']) && !empty($data['zone_file_id'])) {
                $sql = "SELECT id FROM zone_files WHERE id = ? AND status = 'active'";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$data['zone_file_id']]);
                if (!$stmt->fetch()) {
                    throw new Exception("Invalid or inactive zone_file_id");
                }
            }
            
            // Explicitly remove last_seen, created_at, and updated_at if provided by client (security)
            unset($data['last_seen']);
            unset($data['created_at']);
            unset($data['updated_at']);
            
            // Get current record for history
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                throw new Exception("Record not found");
            }
            
            // Map 'value' alias to dedicated field if provided
            if (isset($data['value']) && !empty($data['value'])) {
                $this->mapValueToDedicatedField($data);
            }
            
            // Determine the record type (use updated value if provided, otherwise current)
            $recordType = $data['record_type'] ?? $current['record_type'];
            $owner = $data['name'] ?? $current['name'];
            
            // Extract the value for validation (will use updated or current values)
            $dedicatedFieldsForValidation = $this->extractDedicatedFields($data, $current);
            $valueForValidation = $this->getValueFromDedicatedFieldData($data, $current);
            
            // Validate the record using DnsValidator
            $extraData = [];
            if (isset($data['priority'])) {
                $extraData['priority'] = $data['priority'];
            } elseif (isset($current['priority'])) {
                $extraData['priority'] = $current['priority'];
            }
            
            $validation = DnsValidator::validateRecord($recordType, $owner, $valueForValidation, $extraData);
            if (!$validation['valid']) {
                throw new Exception($validation['error']);
            }
            
            // Extract dedicated field values based on record type
            $dedicatedFields = $this->extractDedicatedFields($data, $current);
            
            // Also update 'value' for backward compatibility
            $valueField = $this->getValueFromDedicatedFieldData($data, $current);
            
            $sql = "UPDATE dns_records 
                    SET zone_file_id = ?, record_type = ?, name = ?, value = ?, 
                        address_ipv4 = ?, address_ipv6 = ?, cname_target = ?, ptrdname = ?, txt = ?,
                        ttl = ?, priority = ?, 
                        requester = ?, expires_at = ?, ticket_ref = ?, comment = ?,
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['zone_file_id'] ?? $current['zone_file_id'],
                $data['record_type'] ?? $current['record_type'],
                $data['name'] ?? $current['name'],
                $valueField,
                $dedicatedFields['address_ipv4'],
                $dedicatedFields['address_ipv6'],
                $dedicatedFields['cname_target'],
                $dedicatedFields['ptrdname'],
                $dedicatedFields['txt'],
                $data['ttl'] ?? $current['ttl'],
                $data['priority'] ?? $current['priority'],
                isset($data['requester']) ? $data['requester'] : $current['requester'],
                isset($data['expires_at']) ? $data['expires_at'] : $current['expires_at'],
                isset($data['ticket_ref']) ? $data['ticket_ref'] : $current['ticket_ref'],
                isset($data['comment']) ? $data['comment'] : $current['comment'],
                $user_id,
                $id
            ]);
            
            // Write history
            $this->writeHistory($id, 'updated', $current['status'], $current['status'], $user_id, 'Record updated');
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("DNS Record update error: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Set record status (soft delete, enable)
     * 
     * @param int $id Record ID
     * @param string $status New status (active, deleted)
     * @param int $user_id User changing the status
     * @return bool Success status
     */
    public function setStatus($id, $status, $user_id) {
        $valid_statuses = ['active', 'deleted'];
        if (!in_array($status, $valid_statuses)) {
            return false;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Get current record INCLUDING deleted so we can restore it
            $current = $this->getById($id, true);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE dns_records 
                    SET status = ?, updated_by = ?, updated_at = NOW()
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$status, $user_id, $id]);
            
            // Write history
            $this->writeHistory($id, 'status_changed', $current['status'], $status, $user_id, "Status changed from {$current['status']} to {$status}");
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("DNS Record setStatus error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Write history entry for a record change
     * 
     * @param int $record_id Record ID
     * @param string $action Action performed (created, updated, status_changed)
     * @param string|null $old_status Old status
     * @param string $new_status New status
     * @param int $user_id User who made the change
     * @param string|null $notes Additional notes
     * @return bool Success status
     */
    public function writeHistory($record_id, $action, $old_status, $new_status, $user_id, $notes = null) {
        try {
            // Get current record data including dedicated fields
            $sql = "SELECT record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, zone_file_id FROM dns_records WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$record_id]);
            $record = $stmt->fetch();
            
            if (!$record) {
                return false;
            }
            
            $sql = "INSERT INTO dns_record_history 
                    (record_id, zone_file_id, action, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, old_status, new_status, changed_by, notes)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $record_id,
                $record['zone_file_id'],
                $action,
                $record['record_type'],
                $record['name'],
                $record['value'],
                $record['address_ipv4'],
                $record['address_ipv6'],
                $record['cname_target'],
                $record['ptrdname'],
                $record['txt'],
                $record['ttl'],
                $record['priority'],
                $old_status,
                $new_status,
                $user_id,
                $notes
            ]);
            
            return true;
        } catch (Exception $e) {
            error_log("DNS Record writeHistory error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get history for a specific record
     * 
     * @param int $record_id Record ID
     * @return array Array of history entries
     */
    public function getHistory($record_id) {
        try {
            $sql = "SELECT h.*, u.username as changed_by_username
                    FROM dns_record_history h
                    LEFT JOIN users u ON h.changed_by = u.id
                    WHERE h.record_id = ?
                    ORDER BY h.changed_at DESC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$record_id]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("DNS Record getHistory error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Mark a record as seen (update last_seen timestamp)
     * This method is called when a record is viewed/retrieved
     * 
     * @param int $id Record ID
     * @param int|null $user_id Optional user ID who viewed the record
     * @return bool Success status
     */
    public function markSeen($id, $user_id = null) {
        try {
            $sql = "UPDATE dns_records 
                    SET last_seen = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            
            return true;
        } catch (Exception $e) {
            error_log("DNS Record markSeen error: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Get the value from the appropriate dedicated field based on record type
     * 
     * @param array $record Record data from database
     * @return string|null The value from the dedicated field
     */
    private function getValueFromDedicatedField($record) {
        switch ($record['record_type']) {
            case 'A':
                return $record['address_ipv4'] ?? $record['value'];
            case 'AAAA':
                return $record['address_ipv6'] ?? $record['value'];
            case 'CNAME':
                return $record['cname_target'] ?? $record['value'];
            case 'PTR':
                return $record['ptrdname'] ?? $record['value'];
            case 'TXT':
                return $record['txt'] ?? $record['value'];
            default:
                // For unsupported types, return the value field
                return $record['value'] ?? null;
        }
    }
    
    /**
     * Get the value from dedicated field data (for new/updated records)
     * 
     * @param array $data Input data
     * @param array|null $current Current record data (for updates)
     * @return string|null The value from the dedicated field
     */
    private function getValueFromDedicatedFieldData($data, $current = null) {
        $recordType = $data['record_type'] ?? ($current['record_type'] ?? null);
        
        switch ($recordType) {
            case 'A':
                return $data['address_ipv4'] ?? ($current['address_ipv4'] ?? null);
            case 'AAAA':
                return $data['address_ipv6'] ?? ($current['address_ipv6'] ?? null);
            case 'CNAME':
                return $data['cname_target'] ?? ($current['cname_target'] ?? null);
            case 'PTR':
                return $data['ptrdname'] ?? ($current['ptrdname'] ?? null);
            case 'TXT':
                return $data['txt'] ?? ($current['txt'] ?? null);
            default:
                return null;
        }
    }
    
    /**
     * Map the generic 'value' field to the appropriate dedicated field
     * This provides backward compatibility by accepting 'value' as an alias
     * 
     * @param array &$data Reference to input data
     */
    private function mapValueToDedicatedField(&$data) {
        if (!isset($data['record_type']) || !isset($data['value'])) {
            return;
        }
        
        switch ($data['record_type']) {
            case 'A':
                if (!isset($data['address_ipv4'])) {
                    $data['address_ipv4'] = $data['value'];
                }
                break;
            case 'AAAA':
                if (!isset($data['address_ipv6'])) {
                    $data['address_ipv6'] = $data['value'];
                }
                break;
            case 'CNAME':
                if (!isset($data['cname_target'])) {
                    $data['cname_target'] = $data['value'];
                }
                break;
            case 'PTR':
                if (!isset($data['ptrdname'])) {
                    $data['ptrdname'] = $data['value'];
                }
                break;
            case 'TXT':
                if (!isset($data['txt'])) {
                    $data['txt'] = $data['value'];
                }
                break;
        }
    }
    
    /**
     * Extract dedicated field values from input data
     * 
     * @param array $data Input data
     * @param array|null $current Current record data (for updates)
     * @return array Array with all dedicated field keys
     */
    private function extractDedicatedFields($data, $current = null) {
        $recordType = $data['record_type'] ?? ($current['record_type'] ?? null);
        
        $fields = [
            'address_ipv4' => null,
            'address_ipv6' => null,
            'cname_target' => null,
            'ptrdname' => null,
            'txt' => null
        ];
        
        // Set the appropriate field based on record type
        switch ($recordType) {
            case 'A':
                $fields['address_ipv4'] = $data['address_ipv4'] ?? ($current['address_ipv4'] ?? null);
                break;
            case 'AAAA':
                $fields['address_ipv6'] = $data['address_ipv6'] ?? ($current['address_ipv6'] ?? null);
                break;
            case 'CNAME':
                $fields['cname_target'] = $data['cname_target'] ?? ($current['cname_target'] ?? null);
                break;
            case 'PTR':
                $fields['ptrdname'] = $data['ptrdname'] ?? ($current['ptrdname'] ?? null);
                break;
            case 'TXT':
                $fields['txt'] = $data['txt'] ?? ($current['txt'] ?? null);
                break;
        }
        
        return $fields;
    }
}
?>
