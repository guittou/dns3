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
                       u2.username as updated_by_username,
                       zfi.parent_id,
                       parent_zf.name as parent_name
                FROM zone_files zf
                LEFT JOIN users u1 ON zf.created_by = u1.id
                LEFT JOIN users u2 ON zf.updated_by = u2.id
                LEFT JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                LEFT JOIN zone_files parent_zf ON zfi.parent_id = parent_zf.id
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
        $sql = "SELECT COUNT(DISTINCT zf.id) as total
                FROM zone_files zf
                LEFT JOIN zone_file_includes zfi ON zf.id = zfi.include_id
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
                           u2.username as updated_by_username,
                           zfi.parent_id,
                           parent_zf.name as parent_name
                    FROM zone_files zf
                    LEFT JOIN users u1 ON zf.created_by = u1.id
                    LEFT JOIN users u2 ON zf.updated_by = u2.id
                    LEFT JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    LEFT JOIN zone_files parent_zf ON zfi.parent_id = parent_zf.id
                    WHERE zf.id = ?";
            
            if (!$includeDeleted) {
                $sql .= " AND zf.status != 'deleted'";
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$id]);
            $result = $stmt->fetch();
            
            // Ensure directory is included in result
            if ($result && !isset($result['directory'])) {
                $result['directory'] = null;
            }
            
            return $result ?: null;
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
     * @param array $data Zone file data (name, filename, directory, file_type, content)
     * @param int $user_id User creating the zone file
     * @return int|bool New zone file ID or false on failure
     */
    public function create($data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            $sql = "INSERT INTO zone_files (name, filename, directory, content, file_type, status, created_by, created_at)
                    VALUES (?, ?, ?, ?, ?, 'active', ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'],
                $data['filename'],
                $data['directory'] ?? null,
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
                    SET name = ?, filename = ?, directory = ?, content = ?, file_type = ?,
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'] ?? $current['name'],
                $data['filename'] ?? $current['filename'],
                isset($data['directory']) ? $data['directory'] : $current['directory'],
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
     * Assign an include file to a parent zone with cycle detection and reassignment support
     * 
     * @param int $parentId Parent zone file ID (can be master or include)
     * @param int $includeId Include zone file ID
     * @param int $position Position for ordering (default 0)
     * @param int|null $userId User ID for history tracking
     * @return bool|string Success status or error message
     */
    public function assignInclude($parentId, $includeId, $position = 0, $userId = null) {
        try {
            $this->db->beginTransaction();
            
            // Prevent self-include
            if ($parentId === $includeId) {
                $this->db->rollBack();
                return "Cannot include a zone file in itself";
            }
            
            // Verify both zones exist
            $parent = $this->getById($parentId, true);
            $include = $this->getById($includeId, true);
            
            if (!$parent || !$include) {
                $this->db->rollBack();
                return "Zone file not found";
            }
            
            // Verify include is actually an include type
            if ($include['file_type'] !== 'include') {
                $this->db->rollBack();
                return "Only include-type zone files can be assigned as includes";
            }
            
            // Check for cycles: verify that includeId doesn't have parentId as an ancestor
            if ($this->hasAncestor($includeId, $parentId)) {
                $this->db->rollBack();
                return "Cannot create circular dependency: this would create a cycle in the include tree";
            }
            
            // Check if include already has a parent (reassignment case)
            $checkSql = "SELECT parent_id FROM zone_file_includes WHERE include_id = ?";
            $checkStmt = $this->db->prepare($checkSql);
            $checkStmt->execute([$includeId]);
            $existingParent = $checkStmt->fetch();
            
            if ($existingParent && $existingParent['parent_id'] != $parentId) {
                // Reassignment case - write history
                $oldParent = $this->getById($existingParent['parent_id'], true);
                $oldParentName = $oldParent ? $oldParent['name'] : 'Unknown';
                $newParentName = $parent['name'];
                
                $notes = "Include reassigned from parent '{$oldParentName}' (ID: {$existingParent['parent_id']}) to '{$newParentName}' (ID: {$parentId})";
                
                // Write history for the include being reassigned
                if ($userId) {
                    $this->writeHistory(
                        $includeId,
                        'reassign_include',
                        $include['status'],
                        $include['status'],
                        $userId,
                        $notes
                    );
                }
                
                // Update the parent_id and position
                $updateSql = "UPDATE zone_file_includes 
                             SET parent_id = ?, position = ? 
                             WHERE include_id = ?";
                $updateStmt = $this->db->prepare($updateSql);
                $updateStmt->execute([$parentId, $position, $includeId]);
            } else {
                // New assignment - insert
                $sql = "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at)
                        VALUES (?, ?, ?, NOW())
                        ON DUPLICATE KEY UPDATE position = VALUES(position)";
                
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$parentId, $includeId, $position]);
                
                // Write history for new assignment
                if ($userId && !$existingParent) {
                    $this->writeHistory(
                        $includeId,
                        'assign_include',
                        $include['status'],
                        $include['status'],
                        $userId,
                        "Include assigned to parent '{$parent['name']}' (ID: {$parentId})"
                    );
                }
            }
            
            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
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

    /**
     * Generate complete zone file content with includes and DNS records
     * 
     * @param int $zoneId Zone file ID
     * @return string|null Generated zone file content or null on error
     */
    public function generateZoneFile($zoneId) {
        try {
            // Get zone file information
            $zone = $this->getById($zoneId);
            if (!$zone) {
                return null;
            }
            
            $content = '';
            
            // Add zone's own content first
            if (!empty($zone['content'])) {
                $content .= $zone['content'];
                // Ensure there's a newline after content
                if (substr($content, -1) !== "\n") {
                    $content .= "\n";
                }
                $content .= "\n";
            }
            
            // Add $INCLUDE directives for direct includes
            $includes = $this->getIncludes($zoneId);
            foreach ($includes as $include) {
                // Build include path: directory/filename if directory exists, otherwise just filename
                $includePath = '';
                if (!empty($include['directory'])) {
                    $includePath = $include['directory'] . '/' . $include['filename'];
                } else {
                    // Use filename if available, otherwise fall back to name
                    $includePath = !empty($include['filename']) ? $include['filename'] : $include['name'];
                }
                
                $content .= '$INCLUDE "' . $includePath . '"' . "\n";
            }
            
            if (count($includes) > 0) {
                $content .= "\n";
            }
            
            // Add DNS records associated with this zone formatted in BIND syntax
            $records = $this->getDnsRecordsByZone($zoneId);
            if (count($records) > 0) {
                $content .= "; DNS Records\n";
                foreach ($records as $record) {
                    $content .= $this->formatDnsRecordBind($record) . "\n";
                }
            }
            
            return $content;
        } catch (Exception $e) {
            error_log("ZoneFile generateZoneFile error: " . $e->getMessage());
            return null;
        }
    }
    
    /**
     * Get DNS records for a specific zone file
     * 
     * @param int $zoneId Zone file ID
     * @return array Array of DNS records
     */
    private function getDnsRecordsByZone($zoneId) {
        try {
            $sql = "SELECT * FROM dns_records 
                    WHERE zone_file_id = ? AND status = 'active'
                    ORDER BY name, record_type";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zoneId]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ZoneFile getDnsRecordsByZone error: " . $e->getMessage());
            return [];
        }
    }
    
    /**
     * Format a DNS record in BIND zone file syntax
     * 
     * @param array $record DNS record data
     * @return string Formatted BIND record line
     */
    private function formatDnsRecordBind($record) {
        $name = $record['name'];
        $ttl = isset($record['ttl']) ? $record['ttl'] : 3600;
        $type = $record['record_type'];
        
        // Format the record value based on type
        $value = $this->getRecordValue($record);
        
        // Build the BIND format line
        // Format: name TTL class type value
        $line = sprintf("%-30s %6d IN %-6s %s", $name, $ttl, $type, $value);
        
        return $line;
    }
    
    /**
     * Get the value for a DNS record based on its type
     * 
     * @param array $record DNS record data
     * @return string Record value
     */
    private function getRecordValue($record) {
        $type = $record['record_type'];
        
        switch ($type) {
            case 'A':
                return $record['address_ipv4'] ?? $record['value'];
            
            case 'AAAA':
                return $record['address_ipv6'] ?? $record['value'];
            
            case 'CNAME':
                return $record['cname_target'] ?? $record['value'];
            
            case 'PTR':
                return $record['ptrdname'] ?? $record['value'];
            
            case 'MX':
                $priority = isset($record['priority']) ? $record['priority'] : 10;
                $target = $record['value'];
                return "$priority $target";
            
            case 'TXT':
                $txt = $record['txt'] ?? $record['value'];
                // Ensure TXT records are properly quoted
                if (substr($txt, 0, 1) !== '"') {
                    $txt = '"' . $txt . '"';
                }
                return $txt;
            
            case 'NS':
                return $record['value'];
            
            case 'SOA':
                return $record['value'];
            
            case 'SRV':
                // SRV format: priority weight port target
                $priority = isset($record['priority']) ? $record['priority'] : 10;
                return "$priority " . $record['value'];
            
            default:
                return $record['value'];
        }
    }

    /**
     * Find the top-level master parent for a zone file
     * Traverses the parent chain until a master is found or a cycle is detected
     * 
     * @param int $zoneId Zone file ID
     * @param array &$visited Array to track visited zones for cycle detection
     * @return array|null Array with 'master' zone data or error info, null on failure
     */
    private function findTopLevelMaster($zoneId, &$visited = []) {
        // Prevent infinite loops - cycle detection
        if (in_array($zoneId, $visited)) {
            return ['error' => 'cycle', 'message' => 'Circular dependency detected in parent chain'];
        }
        $visited[] = $zoneId;
        
        try {
            $zone = $this->getById($zoneId, true);
            if (!$zone) {
                return null;
            }
            
            // If this is a master, we found the top level
            if ($zone['file_type'] === 'master') {
                return ['master' => $zone, 'visited' => $visited];
            }
            
            // If this is an include, find its parent
            if ($zone['file_type'] === 'include') {
                // Check zone_file_includes table for parent
                $sql = "SELECT parent_id FROM zone_file_includes WHERE include_id = ?";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$zoneId]);
                $result = $stmt->fetch();
                
                if ($result && $result['parent_id']) {
                    // Recursively find the master from the parent
                    return $this->findTopLevelMaster($result['parent_id'], $visited);
                } else {
                    // Include has no parent - this is an error
                    return ['error' => 'no_parent', 'message' => 'Include file has no master parent'];
                }
            }
            
            return null;
        } catch (Exception $e) {
            error_log("ZoneFile findTopLevelMaster error: " . $e->getMessage());
            return null;
        }
    }
    
    /**
     * Get all child includes recursively (BFS/DFS)
     * Returns all descendant includes for a given zone
     * 
     * @param int $parentId Parent zone file ID
     * @param array &$visited Array to track visited zones for cycle detection
     * @return array Array of zone IDs
     */
    private function getAllChildIncludes($parentId, &$visited = []) {
        $children = [];
        
        // Prevent infinite loops
        if (in_array($parentId, $visited)) {
            return $children;
        }
        $visited[] = $parentId;
        
        try {
            // Get direct children
            $sql = "SELECT include_id FROM zone_file_includes WHERE parent_id = ?";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId]);
            $directChildren = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            foreach ($directChildren as $childId) {
                $children[] = $childId;
                // Recursively get children of this child
                $subChildren = $this->getAllChildIncludes($childId, $visited);
                $children = array_merge($children, $subChildren);
            }
            
            return array_unique($children);
        } catch (Exception $e) {
            error_log("ZoneFile getAllChildIncludes error: " . $e->getMessage());
            return $children;
        }
    }

    /**
     * Validate zone file using named-checkzone
     * For include files, validates the top-level master and propagates results
     * 
     * @param int $zoneId Zone file ID
     * @param int|null $userId User ID who triggered validation
     * @param bool $sync If true, run synchronously; if false, queue for background processing
     * @return array|bool Validation result array for sync mode, true for async queued, false on error
     */
    public function validateZoneFile($zoneId, $userId = null, $sync = null) {
        // Use config setting if not explicitly specified
        if ($sync === null) {
            $sync = defined('ZONE_VALIDATE_SYNC') ? ZONE_VALIDATE_SYNC : false;
        }

        try {
            $zone = $this->getById($zoneId);
            if (!$zone) {
                return false;
            }

            // Handle include-type zones differently
            if ($zone['file_type'] === 'include') {
                // Find the top-level master
                $visited = [];
                $result = $this->findTopLevelMaster($zoneId, $visited);
                
                if (!$result) {
                    // Error finding master
                    $this->storeValidationResult($zoneId, 'failed', 'Error finding master parent for include', $userId);
                    return false;
                }
                
                if (isset($result['error'])) {
                    // Cycle detected or no parent
                    $errorMsg = $result['message'];
                    $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId);
                    return false;
                }
                
                $topMaster = $result['master'];
                $topMasterId = $topMaster['id'];
                
                if ($sync) {
                    // Run validation synchronously on the master
                    $validationResult = $this->runNamedCheckzone($topMasterId, $topMaster, $userId);
                    
                    // Propagate results to all child includes
                    $allIncludes = $this->getAllChildIncludes($topMasterId);
                    
                    foreach ($allIncludes as $includeId) {
                        $includeZone = $this->getById($includeId, true);
                        if ($includeZone) {
                            $propagatedOutput = "Validation result from parent master '{$topMaster['name']}' (ID: {$topMasterId}):\n" . $validationResult['output'];
                            $this->storeValidationResult($includeId, $validationResult['status'], $propagatedOutput, $userId);
                        }
                    }
                    
                    return $validationResult;
                } else {
                    // Queue validation for the master
                    $this->queueValidation($topMasterId, $userId);
                    
                    // Mark include as pending with reference to queued parent
                    $pendingMsg = "Validation queued for background processing (parent master '{$topMaster['name']}' id={$topMasterId})";
                    $this->storeValidationResult($zoneId, 'pending', $pendingMsg, $userId);
                    
                    return true;
                }
            } else {
                // Master zone - validate directly
                if ($sync) {
                    // Run validation synchronously
                    $validationResult = $this->runNamedCheckzone($zoneId, $zone, $userId);
                    
                    // Also propagate to all child includes
                    $allIncludes = $this->getAllChildIncludes($zoneId);
                    
                    foreach ($allIncludes as $includeId) {
                        $includeZone = $this->getById($includeId, true);
                        if ($includeZone) {
                            $propagatedOutput = "Validation result from parent master '{$zone['name']}' (ID: {$zoneId}):\n" . $validationResult['output'];
                            $this->storeValidationResult($includeId, $validationResult['status'], $propagatedOutput, $userId);
                        }
                    }
                    
                    return $validationResult;
                } else {
                    // Queue for background processing
                    return $this->queueValidation($zoneId, $userId);
                }
            }
        } catch (Exception $e) {
            error_log("ZoneFile validateZoneFile error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Run named-checkzone command synchronously
     * 
     * @param int $zoneId Zone file ID
     * @param array $zone Zone data
     * @param int|null $userId User ID
     * @return array Validation result [status, output]
     */
    private function runNamedCheckzone($zoneId, $zone, $userId) {
        $namedCheckzone = defined('NAMED_CHECKZONE_PATH') ? NAMED_CHECKZONE_PATH : 'named-checkzone';
        
        // Create temporary file with zone content
        $tempFile = tempnam(sys_get_temp_dir(), 'zone_');
        $content = $this->generateZoneFile($zoneId);
        file_put_contents($tempFile, $content);
        
        // Run named-checkzone
        $zoneName = $zone['name'];
        $command = escapeshellcmd($namedCheckzone) . ' ' . escapeshellarg($zoneName) . ' ' . escapeshellarg($tempFile) . ' 2>&1';
        
        exec($command, $output, $returnCode);
        $outputText = implode("\n", $output);
        
        // Clean up temp file
        unlink($tempFile);
        
        // Determine status
        $status = ($returnCode === 0) ? 'passed' : 'failed';
        
        // Store validation result
        $this->storeValidationResult($zoneId, $status, $outputText, $userId);
        
        return [
            'status' => $status,
            'output' => $outputText,
            'return_code' => $returnCode
        ];
    }

    /**
     * Queue validation for background processing
     * 
     * @param int $zoneId Zone file ID
     * @param int|null $userId User ID
     * @return bool Success status
     */
    private function queueValidation($zoneId, $userId) {
        // Create jobs directory if it doesn't exist
        $jobsDir = __DIR__ . '/../../jobs';
        if (!is_dir($jobsDir)) {
            mkdir($jobsDir, 0755, true);
        }
        
        $queueFile = $jobsDir . '/validation_queue.json';
        
        // Load existing queue
        $queue = [];
        if (file_exists($queueFile)) {
            $queue = json_decode(file_get_contents($queueFile), true) ?: [];
        }
        
        // Add new job
        $queue[] = [
            'zone_id' => $zoneId,
            'user_id' => $userId,
            'queued_at' => date('Y-m-d H:i:s')
        ];
        
        // Save queue
        file_put_contents($queueFile, json_encode($queue, JSON_PRETTY_PRINT));
        
        // Store pending status
        $this->storeValidationResult($zoneId, 'pending', 'Validation queued for background processing', $userId);
        
        return true;
    }

    /**
     * Store validation result in database
     * 
     * @param int $zoneId Zone file ID
     * @param string $status Validation status
     * @param string $output Command output
     * @param int|null $userId User ID
     * @return bool Success status
     */
    private function storeValidationResult($zoneId, $status, $output, $userId) {
        try {
            $sql = "INSERT INTO zone_file_validation (zone_file_id, status, output, run_by, checked_at)
                    VALUES (?, ?, ?, ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zoneId, $status, $output, $userId]);
            
            return true;
        } catch (Exception $e) {
            error_log("ZoneFile storeValidationResult error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get latest validation result for a zone
     * 
     * @param int $zoneId Zone file ID
     * @return array|null Validation result or null
     */
    public function getLatestValidation($zoneId) {
        try {
            $sql = "SELECT v.*, u.username as run_by_username
                    FROM zone_file_validation v
                    LEFT JOIN users u ON v.run_by = u.id
                    WHERE v.zone_file_id = ?
                    ORDER BY v.checked_at DESC
                    LIMIT 1";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zoneId]);
            return $stmt->fetch() ?: null;
        } catch (Exception $e) {
            error_log("ZoneFile getLatestValidation error: " . $e->getMessage());
            return null;
        }
    }
}
?>
