<?php
/**
 * ZoneFile Model
 * Handles CRUD operations for zone files with history tracking
 */

require_once __DIR__ . '/../db.php';

class ZoneFile {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Search zone files with filters
     * 
     * @param array $filters Optional filters (name, file_type, status)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of zone files
     */
    public function search($filters = [], $limit = 100, $offset = 0) {
        $sql = "SELECT zf.*, 
                       u1.username as created_by_username,
                       u2.username as updated_by_username
                FROM zone_files zf
                LEFT JOIN users u1 ON zf.created_by = u1.id
                LEFT JOIN users u2 ON zf.updated_by = u2.id
                WHERE 1=1";
        
        $params = [];
        
        if (isset($filters['name']) && $filters['name'] !== '') {
            $sql .= " AND zf.name LIKE ?";
            $params[] = '%' . $filters['name'] . '%';
        }
        
        if (isset($filters['file_type']) && $filters['file_type'] !== '') {
            $sql .= " AND zf.file_type = ?";
            $params[] = $filters['file_type'];
        }
        
        if (isset($filters['status']) && $filters['status'] !== '') {
            $sql .= " AND zf.status = ?";
            $params[] = $filters['status'];
        }
        
        $sql .= " ORDER BY zf.created_at DESC LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;
        
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ZoneFile search error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a zone file by ID
     * 
     * @param int $id Zone file ID
     * @param bool $includeDeleted If true, include deleted zones
     * @return array|null Zone file data or null if not found
     */
    public function getById($id, $includeDeleted = false) {
        try {
            $sql = "SELECT zf.*, 
                           u1.username as created_by_username,
                           u2.username as updated_by_username
                    FROM zone_files zf
                    LEFT JOIN users u1 ON zf.created_by = u1.id
                    LEFT JOIN users u2 ON zf.updated_by = u2.id
                    WHERE zf.id = ?";
            
            if (!$includeDeleted) {
                $sql .= " AND zf.status != 'deleted'";
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("ZoneFile getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get zone file by name
     * 
     * @param string $name Zone name
     * @return array|null Zone file data or null if not found
     */
    public function getByName($name) {
        try {
            $sql = "SELECT zf.*, 
                           u1.username as created_by_username,
                           u2.username as updated_by_username
                    FROM zone_files zf
                    LEFT JOIN users u1 ON zf.created_by = u1.id
                    LEFT JOIN users u2 ON zf.updated_by = u2.id
                    WHERE zf.name = ? AND zf.status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$name]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("ZoneFile getByName error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new zone file
     * 
     * @param array $data Zone file data (name, filename, file_type, content)
     * @param int $user_id User creating the zone file
     * @return int|bool New zone file ID or false on failure
     */
    public function create($data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            $sql = "INSERT INTO zone_files (name, filename, content, file_type, status, created_by, created_at)
                    VALUES (?, ?, ?, ?, 'active', ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'],
                $data['filename'],
                $data['content'] ?? null,
                $data['file_type'] ?? 'master',
                $user_id
            ]);
            
            $zone_id = $this->db->lastInsertId();
            
            // Write history
            $this->writeHistory($zone_id, 'created', null, 'active', $user_id, 'Zone file created');
            
            $this->db->commit();
            return $zone_id;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("ZoneFile create error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Update a zone file
     * 
     * @param int $id Zone file ID
     * @param array $data Updated zone file data
     * @param int $user_id User updating the zone file
     * @return bool Success status
     */
    public function update($id, $data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            // Get current zone file for history
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE zone_files 
                    SET name = ?, filename = ?, content = ?, file_type = ?,
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'] ?? $current['name'],
                $data['filename'] ?? $current['filename'],
                isset($data['content']) ? $data['content'] : $current['content'],
                $data['file_type'] ?? $current['file_type'],
                $user_id,
                $id
            ]);
            
            // Write history if content changed
            $action = 'updated';
            if (isset($data['content']) && $data['content'] !== $current['content']) {
                $action = 'content_changed';
            }
            
            $this->writeHistory($id, $action, $current['status'], $current['status'], $user_id, 'Zone file updated', $current['content'], $data['content'] ?? $current['content']);
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("ZoneFile update error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Set zone file status
     * 
     * @param int $id Zone file ID
     * @param string $status New status (active, inactive, deleted)
     * @param int $user_id User changing the status
     * @return bool Success status
     */
    public function setStatus($id, $status, $user_id) {
        $valid_statuses = ['active', 'inactive', 'deleted'];
        if (!in_array($status, $valid_statuses)) {
            return false;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Get current zone file INCLUDING deleted
            $current = $this->getById($id, true);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE zone_files 
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
            error_log("ZoneFile setStatus error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Assign an include file to a master zone
     * 
     * @param int $master_id Master zone file ID
     * @param int $include_id Include zone file ID
     * @return bool Success status
     */
    public function assignInclude($master_id, $include_id) {
        try {
            // Verify both zones exist
            $master = $this->getById($master_id);
            $include = $this->getById($include_id);
            
            if (!$master || !$include) {
                return false;
            }
            
            // Verify master is actually a master and include is actually an include
            if ($master['file_type'] !== 'master' || $include['file_type'] !== 'include') {
                return false;
            }
            
            $sql = "INSERT INTO zone_file_includes (master_id, include_id, created_at)
                    VALUES (?, ?, NOW())
                    ON DUPLICATE KEY UPDATE created_at = created_at";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$master_id, $include_id]);
            
            return true;
        } catch (Exception $e) {
            error_log("ZoneFile assignInclude error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get includes for a master zone
     * 
     * @param int $master_id Master zone file ID
     * @return array Array of include zone files
     */
    public function getIncludes($master_id) {
        try {
            $sql = "SELECT zf.* 
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.master_id = ? AND zf.status = 'active'
                    ORDER BY zf.name";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$master_id]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ZoneFile getIncludes error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Write history entry for a zone file change
     * 
     * @param int $zone_file_id Zone file ID
     * @param string $action Action performed
     * @param string|null $old_status Old status
     * @param string $new_status New status
     * @param int $user_id User who made the change
     * @param string|null $notes Additional notes
     * @param string|null $old_content Old content
     * @param string|null $new_content New content
     * @return bool Success status
     */
    public function writeHistory($zone_file_id, $action, $old_status, $new_status, $user_id, $notes = null, $old_content = null, $new_content = null) {
        try {
            // Get current zone file data
            $sql = "SELECT name, filename, file_type FROM zone_files WHERE id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_file_id]);
            $zone = $stmt->fetch();
            
            if (!$zone) {
                return false;
            }
            
            $sql = "INSERT INTO zone_file_history 
                    (zone_file_id, action, name, filename, file_type, old_status, new_status, old_content, new_content, changed_by, notes)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $zone_file_id,
                $action,
                $zone['name'],
                $zone['filename'],
                $zone['file_type'],
                $old_status,
                $new_status,
                $old_content,
                $new_content,
                $user_id,
                $notes
            ]);
            
            return true;
        } catch (Exception $e) {
            error_log("ZoneFile writeHistory error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get history for a specific zone file
     * 
     * @param int $zone_file_id Zone file ID
     * @return array Array of history entries
     */
    public function getHistory($zone_file_id) {
        try {
            $sql = "SELECT h.*, u.username as changed_by_username
                    FROM zone_file_history h
                    LEFT JOIN users u ON h.changed_by = u.id
                    WHERE h.zone_file_id = ?
                    ORDER BY h.changed_at DESC";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zone_file_id]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ZoneFile getHistory error: " . $e->getMessage());
            return [];
        }
    }
}
?>
