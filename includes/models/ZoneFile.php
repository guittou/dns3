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
     * @param array $filters Optional filters (name, file_type, status, owner, q for general search)
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
        
        // Support 'q' parameter for general search (searches name and filename)
        if (isset($filters['q']) && $filters['q'] !== '') {
            $sql .= " AND (zf.name LIKE ? OR zf.filename LIKE ?)";
            $params[] = '%' . $filters['q'] . '%';
            $params[] = '%' . $filters['q'] . '%';
        }
        
        // Legacy 'name' filter support
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
        
        if (isset($filters['owner']) && $filters['owner'] !== '') {
            $sql .= " AND zf.created_by = ?";
            $params[] = $filters['owner'];
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
     * Count zone files matching filters (for pagination)
     * 
     * @param array $filters Optional filters (same as search method)
     * @return int Total count of matching zone files
     */
    public function count($filters = []) {
        $sql = "SELECT COUNT(*) as total
                FROM zone_files zf
                WHERE 1=1";
        
        $params = [];
        
        // Support 'q' parameter for general search
        if (isset($filters['q']) && $filters['q'] !== '') {
            $sql .= " AND (zf.name LIKE ? OR zf.filename LIKE ?)";
            $params[] = '%' . $filters['q'] . '%';
            $params[] = '%' . $filters['q'] . '%';
        }
        
        // Legacy 'name' filter support
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
        
        if (isset($filters['owner']) && $filters['owner'] !== '') {
            $sql .= " AND zf.created_by = ?";
            $params[] = $filters['owner'];
        }
        
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $result = $stmt->fetch();
            return (int)$result['total'];
        } catch (Exception $e) {
            error_log("ZoneFile count error: " . $e->getMessage());
            return 0;
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
     * Assign an include file to a parent zone with cycle detection
     * 
     * @param int $parentId Parent zone file ID (can be master or include)
     * @param int $includeId Include zone file ID
     * @param int $position Position for ordering (default 0)
     * @return bool|string Success status or error message
     */
    public function assignInclude($parentId, $includeId, $position = 0) {
        try {
            // Prevent self-include
            if ($parentId === $includeId) {
                return "Cannot include a zone file in itself";
            }
            
            // Verify both zones exist
            $parent = $this->getById($parentId);
            $include = $this->getById($includeId);
            
            if (!$parent || !$include) {
                return "Zone file not found";
            }
            
            // Verify include is actually an include type
            if ($include['file_type'] !== 'include') {
                return "Only include-type zone files can be assigned as includes";
            }
            
            // Check for cycles: verify that includeId doesn't have parentId as an ancestor
            if ($this->hasAncestor($includeId, $parentId)) {
                return "Cannot create circular dependency: this would create a cycle in the include tree";
            }
            
            $sql = "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at)
                    VALUES (?, ?, ?, NOW())
                    ON DUPLICATE KEY UPDATE position = VALUES(position)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId, $includeId, $position]);
            
            return true;
        } catch (Exception $e) {
            error_log("ZoneFile assignInclude error: " . $e->getMessage());
            return "Failed to assign include: " . $e->getMessage();
        }
    }
    
    /**
     * Check if a zone file has a specific ancestor in its include tree
     * Used for cycle detection
     * 
     * @param int $candidateIncludeId The zone that would be included
     * @param int $targetId The zone we're checking for in the ancestry
     * @return bool True if targetId is an ancestor of candidateIncludeId
     */
    public function hasAncestor($candidateIncludeId, $targetId) {
        try {
            // Use recursive query if MySQL 8.0+ supports it
            // Otherwise use PHP-based traversal
            $visited = [];
            return $this->hasAncestorRecursive($candidateIncludeId, $targetId, $visited);
        } catch (Exception $e) {
            error_log("ZoneFile hasAncestor error: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Recursive helper for cycle detection
     * 
     * @param int $currentId Current zone file being checked
     * @param int $targetId Target zone we're looking for
     * @param array &$visited Array of visited IDs to prevent infinite loops
     * @return bool True if targetId is found in the include tree
     */
    private function hasAncestorRecursive($currentId, $targetId, &$visited) {
        // Prevent infinite loops
        if (in_array($currentId, $visited)) {
            return false;
        }
        $visited[] = $currentId;
        
        // Get all includes for current zone
        $sql = "SELECT include_id FROM zone_file_includes WHERE parent_id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$currentId]);
        $includes = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        foreach ($includes as $includeId) {
            // If we find the target, we have a cycle
            if ($includeId == $targetId) {
                return true;
            }
            // Check recursively
            if ($this->hasAncestorRecursive($includeId, $targetId, $visited)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Remove an include assignment
     * 
     * @param int $parentId Parent zone file ID
     * @param int $includeId Include zone file ID
     * @return bool Success status
     */
    public function removeInclude($parentId, $includeId) {
        try {
            $sql = "DELETE FROM zone_file_includes WHERE parent_id = ? AND include_id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId, $includeId]);
            return true;
        } catch (Exception $e) {
            error_log("ZoneFile removeInclude error: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Get the complete include tree for a zone file
     * Returns a recursive structure of all includes
     * 
     * @param int $rootId Root zone file ID
     * @param array &$visited Array to track visited nodes (prevents infinite loops)
     * @return array Recursive tree structure
     */
    public function getIncludeTree($rootId, &$visited = []) {
        try {
            // Prevent infinite loops
            if (in_array($rootId, $visited)) {
                return [
                    'error' => 'Circular reference detected',
                    'id' => $rootId
                ];
            }
            $visited[] = $rootId;
            
            // Get root zone info
            $root = $this->getById($rootId);
            if (!$root) {
                return null;
            }
            
            $tree = [
                'id' => $root['id'],
                'name' => $root['name'],
                'filename' => $root['filename'],
                'file_type' => $root['file_type'],
                'status' => $root['status'],
                'includes' => []
            ];
            
            // Get includes ordered by position
            $sql = "SELECT zf.*, zfi.position
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'
                    ORDER BY zfi.position, zf.name";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$rootId]);
            $includes = $stmt->fetchAll();
            
            foreach ($includes as $include) {
                // Recursively build tree for each include
                $subtree = $this->getIncludeTree($include['id'], $visited);
                if ($subtree) {
                    $subtree['position'] = $include['position'];
                    $tree['includes'][] = $subtree;
                }
            }
            
            return $tree;
        } catch (Exception $e) {
            error_log("ZoneFile getIncludeTree error: " . $e->getMessage());
            return null;
        }
    }
    
    /**
     * Render the complete resolved content for a zone file
     * Flattens all includes recursively into a single content string
     * 
     * @param int $rootId Root zone file ID
     * @param array &$visited Array to track visited nodes (prevents infinite loops)
     * @return string|null Flattened content or null on error
     */
    public function renderResolvedContent($rootId, &$visited = []) {
        try {
            // Prevent infinite loops
            if (in_array($rootId, $visited)) {
                return "\n; ERROR: Circular reference detected for zone ID $rootId\n";
            }
            $visited[] = $rootId;
            
            // Get zone info
            $zone = $this->getById($rootId);
            if (!$zone) {
                return null;
            }
            
            $content = '';
            
            // Add comment header
            $content .= "; Zone: {$zone['name']} ({$zone['filename']})\n";
            $content .= "; Type: {$zone['file_type']}\n";
            $content .= "; Generated: " . date('Y-m-d H:i:s') . "\n\n";
            
            // Add zone's own content
            if (!empty($zone['content'])) {
                $content .= $zone['content'] . "\n\n";
            }
            
            // Get includes ordered by position
            $sql = "SELECT zf.id, zf.name, zf.filename, zfi.position
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'
                    ORDER BY zfi.position, zf.name";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$rootId]);
            $includes = $stmt->fetchAll();
            
            foreach ($includes as $include) {
                $content .= "; Including: {$include['name']} ({$include['filename']})\n";
                // Recursively render includes
                $includeContent = $this->renderResolvedContent($include['id'], $visited);
                if ($includeContent !== null) {
                    $content .= $includeContent . "\n";
                }
            }
            
            return $content;
        } catch (Exception $e) {
            error_log("ZoneFile renderResolvedContent error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get includes for a parent zone
     * 
     * @param int $parentId Parent zone file ID
     * @return array Array of include zone files
     */
    public function getIncludes($parentId) {
        try {
            $sql = "SELECT zf.*, zfi.position
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'
                    ORDER BY zfi.position, zf.name";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId]);
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
