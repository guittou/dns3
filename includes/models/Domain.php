<?php
/**
 * Domain Model
 * Handles CRUD operations for domains attached to zone files
 */

require_once __DIR__ . '/../db.php';

class Domain {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * List domains with filters and pagination
     * 
     * @param array $filters Optional filters (domain, zone_file_id, status)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of domains with zone and user information
     */
    public function list($filters = [], $limit = 100, $offset = 0) {
        try {
            $sql = "SELECT dl.*, 
                           zf.name as zone_name,
                           zf.file_type as zone_file_type,
                           u1.username as created_by_username,
                           u2.username as updated_by_username
                    FROM domaine_list dl
                    LEFT JOIN zone_files zf ON dl.zone_file_id = zf.id
                    LEFT JOIN users u1 ON dl.created_by = u1.id
                    LEFT JOIN users u2 ON dl.updated_by = u2.id
                    WHERE 1=1";
            
            $params = [];
            
            // Filter by domain name (partial match)
            if (isset($filters['domain']) && $filters['domain'] !== '') {
                $sql .= " AND dl.domain LIKE ?";
                $params[] = '%' . $filters['domain'] . '%';
            }
            
            // Filter by zone_file_id
            if (isset($filters['zone_file_id']) && $filters['zone_file_id'] !== '') {
                $sql .= " AND dl.zone_file_id = ?";
                $params[] = (int)$filters['zone_file_id'];
            }
            
            // Filter by status
            if (isset($filters['status']) && $filters['status'] !== '') {
                $sql .= " AND dl.status = ?";
                $params[] = $filters['status'];
            }
            
            $sql .= " ORDER BY dl.created_at DESC LIMIT ? OFFSET ?";
            $params[] = (int)$limit;
            $params[] = (int)$offset;
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("Domain list error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get a specific domain by ID
     * 
     * @param int $id Domain ID
     * @return array|null Domain data or null if not found
     */
    public function getById($id) {
        try {
            $sql = "SELECT dl.*, 
                           zf.name as zone_name,
                           zf.file_type as zone_file_type,
                           u1.username as created_by_username,
                           u2.username as updated_by_username
                    FROM domaine_list dl
                    LEFT JOIN zone_files zf ON dl.zone_file_id = zf.id
                    LEFT JOIN users u1 ON dl.created_by = u1.id
                    LEFT JOIN users u2 ON dl.updated_by = u2.id
                    WHERE dl.id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([(int)$id]);
            $result = $stmt->fetch();
            
            return $result ?: null;
        } catch (Exception $e) {
            error_log("Domain getById error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create a new domain
     * 
     * @param array $data Domain data (domain, zone_file_id)
     * @param int $userId User ID creating the domain
     * @return array Result with success status and message
     */
    public function create($data, $userId) {
        try {
            // Validate required fields
            if (empty($data['domain'])) {
                return ['success' => false, 'error' => 'Domain name is required'];
            }
            
            if (empty($data['zone_file_id'])) {
                return ['success' => false, 'error' => 'Zone file is required'];
            }
            
            // Validate domain format (basic regex)
            if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $data['domain'])) {
                return ['success' => false, 'error' => 'Invalid domain format'];
            }
            
            // Verify zone file exists and is type 'master'
            $zoneStmt = $this->db->prepare("SELECT id, file_type FROM zone_files WHERE id = ? AND status = 'active'");
            $zoneStmt->execute([(int)$data['zone_file_id']]);
            $zone = $zoneStmt->fetch();
            
            if (!$zone) {
                return ['success' => false, 'error' => 'Zone file not found or inactive'];
            }
            
            if ($zone['file_type'] !== 'master') {
                return ['success' => false, 'error' => 'Zone file must be type master'];
            }
            
            // Insert domain
            $sql = "INSERT INTO domaine_list (domain, zone_file_id, created_by, status)
                    VALUES (?, ?, ?, 'active')";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['domain'],
                (int)$data['zone_file_id'],
                (int)$userId
            ]);
            
            $insertId = $this->db->lastInsertId();
            
            return [
                'success' => true,
                'id' => $insertId,
                'message' => 'Domain created successfully'
            ];
        } catch (PDOException $e) {
            // Check for duplicate domain
            if ($e->getCode() == '23000') {
                return ['success' => false, 'error' => 'Domain already exists'];
            }
            error_log("Domain create error: " . $e->getMessage());
            return ['success' => false, 'error' => 'Database error: ' . $e->getMessage()];
        } catch (Exception $e) {
            error_log("Domain create error: " . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Update an existing domain
     * 
     * @param int $id Domain ID
     * @param array $data Updated domain data
     * @param int $userId User ID updating the domain
     * @return array Result with success status and message
     */
    public function update($id, $data, $userId) {
        try {
            // Validate required fields
            if (empty($data['domain'])) {
                return ['success' => false, 'error' => 'Domain name is required'];
            }
            
            if (empty($data['zone_file_id'])) {
                return ['success' => false, 'error' => 'Zone file is required'];
            }
            
            // Validate domain format
            if (!preg_match('/^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/', $data['domain'])) {
                return ['success' => false, 'error' => 'Invalid domain format'];
            }
            
            // Verify zone file exists and is type 'master'
            $zoneStmt = $this->db->prepare("SELECT id, file_type FROM zone_files WHERE id = ? AND status = 'active'");
            $zoneStmt->execute([(int)$data['zone_file_id']]);
            $zone = $zoneStmt->fetch();
            
            if (!$zone) {
                return ['success' => false, 'error' => 'Zone file not found or inactive'];
            }
            
            if ($zone['file_type'] !== 'master') {
                return ['success' => false, 'error' => 'Zone file must be type master'];
            }
            
            // Update domain
            $sql = "UPDATE domaine_list 
                    SET domain = ?, zone_file_id = ?, updated_by = ?
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['domain'],
                (int)$data['zone_file_id'],
                (int)$userId,
                (int)$id
            ]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'error' => 'Domain not found'];
            }
            
            return [
                'success' => true,
                'message' => 'Domain updated successfully'
            ];
        } catch (PDOException $e) {
            // Check for duplicate domain
            if ($e->getCode() == '23000') {
                return ['success' => false, 'error' => 'Domain already exists'];
            }
            error_log("Domain update error: " . $e->getMessage());
            return ['success' => false, 'error' => 'Database error: ' . $e->getMessage()];
        } catch (Exception $e) {
            error_log("Domain update error: " . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Set domain status
     * 
     * @param int $id Domain ID
     * @param string $status New status (active or deleted)
     * @param int $userId User ID performing the action
     * @return array Result with success status and message
     */
    public function setStatus($id, $status, $userId) {
        try {
            // Validate status
            if (!in_array($status, ['active', 'deleted'])) {
                return ['success' => false, 'error' => 'Invalid status'];
            }
            
            $sql = "UPDATE domaine_list 
                    SET status = ?, updated_by = ?
                    WHERE id = ?";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $status,
                (int)$userId,
                (int)$id
            ]);
            
            if ($stmt->rowCount() === 0) {
                return ['success' => false, 'error' => 'Domain not found'];
            }
            
            return [
                'success' => true,
                'message' => 'Domain status updated successfully'
            ];
        } catch (Exception $e) {
            error_log("Domain setStatus error: " . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Delete a domain (alias for setStatus with 'deleted')
     * 
     * @param int $id Domain ID
     * @param int $userId User ID performing the deletion
     * @return array Result with success status and message
     */
    public function delete($id, $userId) {
        return $this->setStatus($id, 'deleted', $userId);
    }
}
