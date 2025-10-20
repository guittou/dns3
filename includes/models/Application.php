<?php
/**
 * Application Model
 * Handles CRUD operations for applications
 */

require_once __DIR__ . '/../db.php';

class Application {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Search applications with filters
     * 
     * @param array $filters Optional filters (name, status, zone_file_id)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of applications
     */
    public function search($filters = [], $limit = 100, $offset = 0) {
        $sql = "SELECT a.*, zf.name as zone_name, zf.file_type as zone_file_type
                FROM applications a
                LEFT JOIN zone_files zf ON a.zone_file_id = zf.id
                WHERE 1=1";
        
        $params = [];
        
        if (isset($filters['name']) && $filters['name'] !== '') {
            $sql .= " AND a.name LIKE ?";
            $params[] = '%' . $filters['name'] . '%';
        }
        
        if (isset($filters['status']) && $filters['status'] !== '') {
            $sql .= " AND a.status = ?";
            $params[] = $filters['status'];
        }
        
        if (isset($filters['zone_file_id']) && $filters['zone_file_id'] !== '') {
            $sql .= " AND a.zone_file_id = ?";
            $params[] = $filters['zone_file_id'];
        }
        
        $sql .= " ORDER BY a.created_at DESC LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;
        
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("Application search error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get an application by ID
     * 
     * @param int $id Application ID
     * @param bool $includeDeleted If true, include deleted applications
     * @return array|null Application data or null if not found
     */
    public function getById($id, $includeDeleted = false) {
        try {
            $sql = "SELECT a.*, zf.name as zone_name, zf.file_type as zone_file_type
                    FROM applications a
                    LEFT JOIN zone_files zf ON a.zone_file_id = zf.id
                    WHERE a.id = ?";
            
            if (!$includeDeleted) {
                $sql .= " AND a.status != 'deleted'";
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("Application getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get application by name
     * 
     * @param string $name Application name
     * @return array|null Application data or null if not found
     */
    public function getByName($name) {
        try {
            $sql = "SELECT a.*, zf.name as zone_name, zf.file_type as zone_file_type
                    FROM applications a
                    LEFT JOIN zone_files zf ON a.zone_file_id = zf.id
                    WHERE a.name = ? AND a.status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$name]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("Application getByName error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new application
     * 
     * @param array $data Application data (name, description, owner, zone_file_id)
     * @return int|bool New application ID or false on failure
     */
    public function create($data) {
        try {
            $this->db->beginTransaction();
            
            $sql = "INSERT INTO applications (name, description, owner, zone_file_id, status, created_at)
                    VALUES (?, ?, ?, ?, 'active', NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'],
                $data['description'] ?? null,
                $data['owner'] ?? null,
                $data['zone_file_id']
            ]);
            
            $app_id = $this->db->lastInsertId();
            
            $this->db->commit();
            return $app_id;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("Application create error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Update an application
     * 
     * @param int $id Application ID
     * @param array $data Updated application data
     * @return bool Success status
     */
    public function update($id, $data) {
        try {
            $this->db->beginTransaction();
            
            // Get current application
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE applications 
                    SET name = ?, description = ?, owner = ?, zone_file_id = ?,
                        updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'] ?? $current['name'],
                isset($data['description']) ? $data['description'] : $current['description'],
                isset($data['owner']) ? $data['owner'] : $current['owner'],
                $data['zone_file_id'] ?? $current['zone_file_id'],
                $id
            ]);
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("Application update error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Set application status
     * 
     * @param int $id Application ID
     * @param string $status New status (active, inactive, deleted)
     * @return bool Success status
     */
    public function setStatus($id, $status) {
        $valid_statuses = ['active', 'inactive', 'deleted'];
        if (!in_array($status, $valid_statuses)) {
            return false;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Get current application INCLUDING deleted
            $current = $this->getById($id, true);
            if (!$current) {
                $this->db->rollBack();
                return false;
            }
            
            $sql = "UPDATE applications 
                    SET status = ?, updated_at = NOW()
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$status, $id]);
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            error_log("Application setStatus error: " . $e->getMessage());
            return false;
        }
    }
}
?>
