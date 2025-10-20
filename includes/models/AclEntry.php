<?php
/**
 * AclEntry Model
 * Handles CRUD operations for ACL entries with automatic history tracking
 */

require_once __DIR__ . '/../db.php';

class AclEntry {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Create a new ACL entry
     * 
     * @param array $data ACL data (user_id, role_id, resource_type, resource_id, permission)
     * @param int $created_by User creating the ACL
     * @return int|bool New ACL ID or false on failure
     */
    public function create($data, $created_by) {
        try {
            $this->db->beginTransaction();
            
            $sql = "INSERT INTO acl_entries (user_id, role_id, resource_type, resource_id, permission, status, created_by)
                    VALUES (?, ?, ?, ?, ?, 'enabled', ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['user_id'] ?? null,
                $data['role_id'] ?? null,
                $data['resource_type'],
                $data['resource_id'] ?? null,
                $data['permission'],
                $created_by
            ]);
            
            $acl_id = $this->db->lastInsertId();
            
            // Write history
            $this->writeHistory($acl_id, 'created', null, 'enabled', $created_by, 'ACL entry created');
            
            $this->db->commit();
            return $acl_id;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("ACL Entry create error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Update an ACL entry
     * 
     * @param int $id ACL ID
     * @param array $data Updated ACL data
     * @param int $updated_by User updating the ACL
     * @return bool Success status
     */
    public function update($id, $data, $updated_by) {
        try {
            $this->db->beginTransaction();
            
            // Get current ACL for history
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE acl_entries 
                    SET user_id = ?, role_id = ?, resource_type = ?, resource_id = ?, permission = ?, 
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'disabled'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['user_id'] ?? $current['user_id'],
                $data['role_id'] ?? $current['role_id'],
                $data['resource_type'] ?? $current['resource_type'],
                $data['resource_id'] ?? $current['resource_id'],
                $data['permission'] ?? $current['permission'],
                $updated_by,
                $id
            ]);
            
            // Write history
            $this->writeHistory($id, 'updated', $current['status'], $current['status'], $updated_by, 'ACL entry updated');
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("ACL Entry update error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Set ACL entry status
     * 
     * @param int $id ACL ID
     * @param string $status New status (enabled, disabled)
     * @param int $changed_by User changing the status
     * @return bool Success status
     */
    public function setStatus($id, $status, $changed_by) {
        $valid_statuses = ['enabled', 'disabled'];
        if (!in_array($status, $valid_statuses)) {
            return false;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Get current ACL
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE acl_entries 
                    SET status = ?, updated_by = ?, updated_at = NOW()
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$status, $changed_by, $id]);
            
            // Write history
            $this->writeHistory($id, 'status_changed', $current['status'], $status, $changed_by, "Status changed from {$current['status']} to {$status}");
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("ACL Entry setStatus error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Write history entry for an ACL change
     * 
     * @param int $acl_id ACL ID
     * @param string $action Action performed (created, updated, status_changed)
     * @param string|null $old_status Old status
     * @param string $new_status New status
     * @param int $changed_by User who made the change
     * @param string|null $notes Additional notes
     * @return bool Success status
     */
    public function writeHistory($acl_id, $action, $old_status, $new_status, $changed_by, $notes = null) {
        try {
            // Get current ACL data
            $sql = "SELECT user_id, role_id, resource_type, resource_id, permission FROM acl_entries WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$acl_id]);
            $acl = $stmt->fetch();
            
            if (!$acl) {
                return false;
            }
            
            $sql = "INSERT INTO acl_history 
                    (acl_id, action, user_id, role_id, resource_type, resource_id, permission, old_status, new_status, changed_by, notes)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $acl_id,
                $action,
                $acl['user_id'],
                $acl['role_id'],
                $acl['resource_type'],
                $acl['resource_id'],
                $acl['permission'],
                $old_status,
                $new_status,
                $changed_by,
                $notes
            ]);
            
            return true;
        } catch (Exception $e) {
            error_log("ACL Entry writeHistory error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get an ACL entry by ID
     * 
     * @param int $id ACL ID
     * @return array|null ACL data or null if not found
     */
    public function getById($id) {
        try {
            $sql = "SELECT a.*, 
                           u1.username as user_username,
                           r.name as role_name,
                           u2.username as created_by_username,
                           u3.username as updated_by_username
                    FROM acl_entries a
                    LEFT JOIN users u1 ON a.user_id = u1.id
                    LEFT JOIN roles r ON a.role_id = r.id
                    LEFT JOIN users u2 ON a.created_by = u2.id
                    LEFT JOIN users u3 ON a.updated_by = u3.id
                    WHERE a.id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $acl = $stmt->fetch();
            
            return $acl ?: null;
        } catch (Exception $e) {
            error_log("ACL Entry getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get history for a specific ACL entry
     * 
     * @param int $acl_id ACL ID
     * @return array Array of history entries
     */
    public function getHistory($acl_id) {
        try {
            $sql = "SELECT h.*, u.username as changed_by_username
                    FROM acl_history h
                    LEFT JOIN users u ON h.changed_by = u.id
                    WHERE h.acl_id = ?
                    ORDER BY h.changed_at DESC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$acl_id]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ACL Entry getHistory error: " . $e->getMessage());
            return [];
        }
    }
}
?>
