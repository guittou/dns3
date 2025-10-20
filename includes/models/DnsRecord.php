<?php
/**
 * DnsRecord Model
 * Handles CRUD operations for DNS records with automatic history tracking
 */

require_once __DIR__ . '/../db.php';

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
                       u2.username as updated_by_username
                FROM dns_records dr
                LEFT JOIN users u1 ON dr.created_by = u1.id
                LEFT JOIN users u2 ON dr.updated_by = u2.id
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
        } else {
            // Default: only show active records, not deleted
            $sql .= " AND dr.status = 'active'";
        }
        
        $sql .= " ORDER BY dr.created_at DESC LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;
        
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("DNS Record search error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a DNS record by ID
     * 
     * @param int $id Record ID
     * @return array|null Record data or null if not found
     */
    public function getById($id) {
        try {
            $sql = "SELECT dr.*, 
                           u1.username as created_by_username,
                           u2.username as updated_by_username
                    FROM dns_records dr
                    LEFT JOIN users u1 ON dr.created_by = u1.id
                    LEFT JOIN users u2 ON dr.updated_by = u2.id
                    WHERE dr.id = ? AND dr.status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $record = $stmt->fetch();
            
            return $record ?: null;
        } catch (Exception $e) {
            error_log("DNS Record getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new DNS record
     * 
     * @param array $data Record data (record_type, name, value, ttl, priority, requester, expires_at, ticket_ref, comment)
     * @param int $user_id User creating the record
     * @return int|bool New record ID or false on failure
     */
    public function create($data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            // Explicitly remove last_seen if provided by client (security)
            unset($data['last_seen']);
            
            $sql = "INSERT INTO dns_records (record_type, name, value, ttl, priority, requester, expires_at, ticket_ref, comment, status, created_by)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['record_type'],
                $data['name'],
                $data['value'],
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
            return false;
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
            
            // Explicitly remove last_seen if provided by client (security)
            unset($data['last_seen']);
            
            // Get current record for history
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE dns_records 
                    SET record_type = ?, name = ?, value = ?, ttl = ?, priority = ?, 
                        requester = ?, expires_at = ?, ticket_ref = ?, comment = ?,
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['record_type'] ?? $current['record_type'],
                $data['name'] ?? $current['name'],
                $data['value'] ?? $current['value'],
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
            return false;
        }
    }

    /**
     * Set record status (soft delete or enable)
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
            
            // Get current record
            $current = $this->getById($id);
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
            // Get current record data
            $sql = "SELECT record_type, name, value, ttl, priority FROM dns_records WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$record_id]);
            $record = $stmt->fetch();
            
            if (!$record) {
                return false;
            }
            
            $sql = "INSERT INTO dns_record_history 
                    (record_id, action, record_type, name, value, ttl, priority, old_status, new_status, changed_by, notes)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $record_id,
                $action,
                $record['record_type'],
                $record['name'],
                $record['value'],
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
}
?>
