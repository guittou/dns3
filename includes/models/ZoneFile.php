<?php
/**
 * ZoneFile Model
 * Handles CRUD operations for zone files with history tracking
 */

require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/../lib/DnsValidator.php';

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
            // Validate zone name
            $nameValidation = DnsValidator::validateName($data['name'], true);
            if (!$nameValidation['valid']) {
                throw new Exception("Invalid zone name: " . $nameValidation['error']);
            }
            
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
            throw $e;
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
            // Validate zone name if it's being updated
            if (isset($data['name'])) {
                $nameValidation = DnsValidator::validateName($data['name'], true);
                if (!$nameValidation['valid']) {
                    throw new Exception("Invalid zone name: " . $nameValidation['error']);
                }
            }
            
            $this->db->beginTransaction();
            
            // Get current zone file for history
            $current = $this->getById($id);
            if (!$current) {
                $this->db->rollBack();
                throw new Exception("Zone file not found");
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
            throw $e;
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
     * Generate flattened zone content for validation
     * Concatenates master content with all include contents recursively in order
     * Used by validation to create a single complete zone file for named-checkzone
     * 
     * @param int $masterId Master zone file ID
     * @param array &$visited Array to track visited include IDs (prevents cycles)
     * @return string|null Flattened zone content or null on error
     */
    private function generateFlatZone($masterId, &$visited = []) {
        try {
            // Prevent infinite loops
            if (in_array($masterId, $visited)) {
                $this->logValidation("ERROR: Circular reference detected in generateFlatZone for zone ID $masterId");
                return null;
            }
            $visited[] = $masterId;
            
            // Get zone info
            $zone = $this->getById($masterId);
            if (!$zone) {
                $this->logValidation("ERROR: Zone file not found (ID: $masterId) in generateFlatZone");
                return null;
            }
            
            $content = '';
            
            // Add zone's own content first (without $INCLUDE directives)
            if (!empty($zone['content'])) {
                // Remove any $INCLUDE directives from the master content
                // We'll be inlining the actual content instead
                $zoneContent = preg_replace('/^\s*\$INCLUDE\s+[^\n]+$/m', '', $zone['content']);
                $content .= trim($zoneContent);
                if (!empty($content)) {
                    $content .= "\n\n";
                }
            }
            
            // Get includes ordered by position
            $sql = "SELECT zf.id, zf.name, zf.filename, zf.content, zfi.position
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'
                    ORDER BY zfi.position, zf.name";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$masterId]);
            $includes = $stmt->fetchAll();
            
            foreach ($includes as $include) {
                $content .= "; BEGIN INCLUDE: {$include['name']} ({$include['filename']})\n";
                
                // Recursively get flattened content for this include
                $includeContent = $this->generateFlatZone($include['id'], $visited);
                if ($includeContent !== null) {
                    $content .= $includeContent;
                } else {
                    // If we can't get content, add the include's own content at least
                    if (!empty($include['content'])) {
                        $includeContentClean = preg_replace('/^\s*\$INCLUDE\s+[^\n]+$/m', '', $include['content']);
                        $content .= trim($includeContentClean) . "\n";
                    }
                }
                
                $content .= "; END INCLUDE: {$include['name']}\n\n";
            }
            
            // Add DNS records associated with this zone formatted in BIND syntax
            $records = $this->getDnsRecordsByZone($masterId);
            if (count($records) > 0) {
                $content .= "; DNS Records\n";
                foreach ($records as $record) {
                    $content .= $this->formatDnsRecordBind($record) . "\n";
                }
            }
            
            return $content;
        } catch (Exception $e) {
            error_log("ZoneFile generateFlatZone error: " . $e->getMessage());
            $this->logValidation("ERROR in generateFlatZone: " . $e->getMessage());
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
     * Validate zone file using named-checkzone
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

            // Check if this is an include file
            if ($zone['file_type'] === 'include') {
                $this->logValidation("Zone ID $zoneId is an include file - finding top master for validation");
                
                // Includes need to be validated via their top master
                // Find the top-level master by traversing the parent chain
                $topMasterResult = $this->findTopMaster($zoneId);
                
                // Check for errors (no master found or cycle detected)
                if (isset($topMasterResult['error'])) {
                    $errorMsg = $topMasterResult['error'];
                    $this->logValidation("ERROR: Failed to find top master for include zone ID $zoneId: $errorMsg");
                    if ($sync) {
                        $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId);
                        return [
                            'status' => 'failed',
                            'output' => $errorMsg,
                            'return_code' => 1
                        ];
                    } else {
                        $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId);
                        return true;
                    }
                }
                
                $topMasterId = $topMasterResult['id'];
                $topMasterName = $topMasterResult['name'];
                
                $this->logValidation("Found top master for include zone ID $zoneId: master zone '{$topMasterName}' (ID: {$topMasterId})");
                
                // Validate the top master
                if ($sync) {
                    // Run named-checkzone on the top master
                    $result = $this->runNamedCheckzone($topMasterId, $topMasterResult, $userId);
                    
                    // Build include-specific output for return value
                    $includeOutput = "Validation performed on top master zone '{$topMasterName}' (ID: {$topMasterId}):\n\n" . $result['output'];
                    
                    return [
                        'status' => $result['status'],
                        'output' => $includeOutput,
                        'return_code' => $result['return_code']
                    ];
                } else {
                    // For async validation, queue the top master instead
                    // But still record that we're validating the include
                    $this->storeValidationResult($zoneId, 'pending', "Validation queued for top master zone (ID: {$topMasterId})", $userId);
                    return $this->queueValidation($topMasterId, $userId);
                }
            }

            // Not an include - proceed with normal validation
            $this->logValidation("Zone ID $zoneId is a {$zone['file_type']} zone - validating directly");
            if ($sync) {
                // Run validation synchronously
                return $this->runNamedCheckzone($zoneId, $zone, $userId);
            } else {
                // Queue for background processing
                return $this->queueValidation($zoneId, $userId);
            }
        } catch (Exception $e) {
            error_log("ZoneFile validateZoneFile error: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Find the top-level master zone by traversing the parent chain
     * Protects against cycles and handles cases where no master is found
     * 
     * @param int $zoneId Starting zone file ID
     * @return array Array with 'id', 'name', 'file_type' of master, or 'error' if not found/cycle detected
     */
    private function findTopMaster($zoneId) {
        $visited = [];
        $currentId = $zoneId;
        
        while (true) {
            // Cycle detection
            if (in_array($currentId, $visited)) {
                $this->logValidation("ERROR: Circular dependency detected in include chain at zone ID $currentId");
                return ['error' => "Circular dependency detected in include chain; cannot validate"];
            }
            $visited[] = $currentId;
            
            // Get current zone
            $current = $this->getById($currentId, true);
            if (!$current) {
                $this->logValidation("ERROR: Zone file (ID: {$currentId}) not found in parent chain");
                return ['error' => "Zone file (ID: {$currentId}) not found in parent chain"];
            }
            
            $this->logValidation("Traversing parent chain: zone ID $currentId, type='{$current['file_type']}', name='{$current['name']}'");
            
            // If we found a master, return it
            if ($current['file_type'] === 'master') {
                $this->logValidation("Found master zone: ID {$current['id']}, name '{$current['name']}'");
                return [
                    'id' => $current['id'],
                    'name' => $current['name'],
                    'file_type' => $current['file_type']
                ];
            }
            
            // Current is an include, find its parent
            $parentId = null;
            
            // Try to get parent_id from the zone data (already JOINed in getById)
            if (isset($current['parent_id']) && $current['parent_id']) {
                $parentId = $current['parent_id'];
            }
            
            // If no parent found via direct relationship, return error
            if (!$parentId) {
                $this->logValidation("ERROR: Include file (ID: {$currentId}) has no master parent");
                return ['error' => "Include file has no master parent; cannot validate standalone"];
            }
            
            $this->logValidation("Moving up to parent zone ID: $parentId");
            
            // Move up to parent
            $currentId = $parentId;
        }
    }

    /**
     * Run named-checkzone command synchronously with flattened zone content
     * 
     * @param int $zoneId Zone file ID
     * @param array $zone Zone data
     * @param int|null $userId User ID
     * @return array Validation result [status, output, return_code]
     */
    private function runNamedCheckzone($zoneId, $zone, $userId) {
        $namedCheckzone = defined('NAMED_CHECKZONE_PATH') ? NAMED_CHECKZONE_PATH : 'named-checkzone';
        
        // Create secure temporary directory
        $tmpDir = sys_get_temp_dir() . '/dns3_validate_' . uniqid();
        if (!mkdir($tmpDir, 0700, true)) {
            $errorMsg = "Failed to create temporary directory for validation";
            $this->logValidation("ERROR: $errorMsg");
            $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId, null, 1);
            return [
                'status' => 'failed',
                'output' => $errorMsg,
                'return_code' => 1
            ];
        }
        
        $this->logValidation("Created temporary directory for zone ID $zoneId: $tmpDir");
        
        try {
            // Generate flattened zone content (master + all includes inlined)
            $visited = [];
            $flatContent = $this->generateFlatZone($zoneId, $visited);
            
            if ($flatContent === null) {
                $errorMsg = "Failed to generate flattened zone content for zone ID $zoneId";
                $this->logValidation("ERROR: $errorMsg");
                $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId, null, 1);
                return [
                    'status' => 'failed',
                    'output' => $errorMsg,
                    'return_code' => 1
                ];
            }
            
            $this->logValidation("Generated flattened zone content for zone ID $zoneId (" . strlen($flatContent) . " bytes)");
            
            // Write flattened zone file to disk
            $tempFileName = 'zone_' . $zoneId . '_flat.db';
            $tempFilePath = $tmpDir . '/' . $tempFileName;
            
            if (file_put_contents($tempFilePath, $flatContent) === false) {
                $errorMsg = "Failed to write flattened zone file to disk for zone ID $zoneId";
                $this->logValidation("ERROR: $errorMsg");
                $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId, null, 1);
                return [
                    'status' => 'failed',
                    'output' => $errorMsg,
                    'return_code' => 1
                ];
            }
            
            $this->logValidation("Flattened zone file written to: $tempFilePath");
            
            // Build named-checkzone command with -q for quiet mode (less verbose)
            $zoneName = $zone['name'];
            $command = escapeshellcmd($namedCheckzone) . ' -q ' . 
                       escapeshellarg($zoneName) . ' ' . 
                       escapeshellarg($tempFilePath) . ' 2>&1';
            
            $this->logValidation("Executing command for zone ID $zoneId: $command");
            
            // Execute command
            exec($command, $output, $returnCode);
            $outputText = implode("\n", $output);
            
            $this->logValidation("Command exit code for zone ID $zoneId: $returnCode");
            
            // Log errors if validation failed
            if ($returnCode !== 0) {
                $this->logValidation("Validation FAILED for zone ID $zoneId. Output: " . substr($outputText, 0, 500));
            } else {
                $this->logValidation("Validation PASSED for zone ID $zoneId");
            }
            
            // Determine status
            $status = ($returnCode === 0) ? 'passed' : 'failed';
            
            // Store validation result with command and return code embedded in output
            $this->storeValidationResult($zoneId, $status, $outputText, $userId, $command, $returnCode);
            
            // If this is a master or parent zone, propagate validation result to all includes
            $this->propagateValidationToIncludes($zoneId, $zone['name'], $status, $outputText, $userId, $command, $returnCode);
            
            return [
                'status' => $status,
                'output' => $outputText,
                'return_code' => $returnCode
            ];
        } finally {
            // Clean up temporary directory unless DEBUG_KEEP_TMPDIR is set
            if (!defined('DEBUG_KEEP_TMPDIR') || !DEBUG_KEEP_TMPDIR) {
                $this->rrmdir($tmpDir);
                $this->logValidation("Temporary directory cleaned up: $tmpDir");
            } else {
                $this->logValidation("DEBUG: Temporary directory kept at: $tmpDir (JOBS_KEEP_TMP=1)");
            }
        }
    }
    
    /**
     * Write zone file and all its includes to disk recursively
     * Creates proper directory structure for $INCLUDE directives
     * 
     * @param int $zoneId Zone file ID to write
     * @param string $tmpDir Temporary directory base path
     * @param array &$visited Array of visited zone IDs to prevent cycles
     * @return void
     * @throws Exception if zone not found or circular dependency detected
     */
    private function writeZoneFilesToDisk($zoneId, $tmpDir, &$visited = []) {
        // Cycle detection
        if (in_array($zoneId, $visited)) {
            throw new Exception("Circular dependency detected in include chain");
        }
        $visited[] = $zoneId;
        
        // Get zone file
        $zone = $this->getById($zoneId);
        if (!$zone) {
            throw new Exception("Zone file not found: ID $zoneId");
        }
        
        // Generate content with $INCLUDE directives (not inlined)
        $content = $this->generateZoneFile($zoneId);
        
        // Determine file path based on zone type and directory
        if ($zone['file_type'] === 'master' || empty($zone['directory'])) {
            // Master zones go in the root of tmpDir
            $filePath = $tmpDir . '/zone_' . $zoneId . '.db';
        } else {
            // Include zones respect their directory structure
            $dirPath = $tmpDir . '/' . $zone['directory'];
            if (!is_dir($dirPath)) {
                if (!mkdir($dirPath, 0700, true)) {
                    throw new Exception("Failed to create directory: " . $zone['directory']);
                }
            }
            $filePath = $dirPath . '/' . $zone['filename'];
        }
        
        // Write zone content to disk
        if (file_put_contents($filePath, $content) === false) {
            throw new Exception("Failed to write zone file: $filePath");
        }
        
        // Recursively write all includes
        $includes = $this->getIncludes($zoneId);
        foreach ($includes as $include) {
            $this->writeZoneFilesToDisk($include['id'], $tmpDir, $visited);
        }
    }
    
    /**
     * Enrich validation output by extracting line context from errors
     * 
     * @param string $outputText Original named-checkzone output
     * @param string $tmpDir Temporary directory containing zone files
     * @param string $zoneFilename Main zone file name in tmpDir
     * @return string Enriched output with line context appended
     */
    private function enrichValidationOutput($outputText, $tmpDir, $zoneFilename) {
        $lines = explode("\n", $outputText);
        $extractions = [];
        
        // Pattern to match error lines: "filename:line: message"
        $pattern = '/^(.+?):(\d+):\s*(.*)$/';
        
        foreach ($lines as $line) {
            if (preg_match($pattern, $line, $matches)) {
                $reportedFile = $matches[1];
                $lineNumber = (int)$matches[2];
                $message = $matches[3];
                
                // Resolve the file path
                $resolvedPath = $this->resolveValidationFilePath($reportedFile, $tmpDir, $zoneFilename);
                
                if ($resolvedPath && file_exists($resolvedPath)) {
                    // Extract line context
                    $context = $this->getFileLineContext($resolvedPath, $lineNumber, 2);
                    if ($context) {
                        $extractions[] = "File: " . basename($reportedFile) . ", Line: $lineNumber\n" . 
                                       "Message: $message\n" . 
                                       $context;
                    }
                } else {
                    $extractions[] = "File: " . basename($reportedFile) . ", Line: $lineNumber\n" . 
                                   "Message: $message\n" . 
                                   "(Unable to locate file for line extraction)";
                }
            }
        }
        
        // Append extractions if any were found
        if (!empty($extractions)) {
            $outputText .= "\n\n=== EXTRACTED LINES FROM INLINED FILE(S) ===\n\n";
            $outputText .= implode("\n\n---\n\n", $extractions);
            $outputText .= "\n\n=== END OF EXTRACTED LINES ===";
        }
        
        return $outputText;
    }
    
    /**
     * Resolve the file path referenced in named-checkzone output
     * 
     * @param string $reportedFile File path from error message
     * @param string $tmpDir Temporary directory
     * @param string $zoneFilename Main zone file name
     * @return string|null Resolved file path or null if not found
     */
    private function resolveValidationFilePath($reportedFile, $tmpDir, $zoneFilename) {
        // Strategy 1: Check if it's an absolute path in tmpDir
        if (strpos($reportedFile, $tmpDir) === 0 && file_exists($reportedFile)) {
            return $reportedFile;
        }
        
        // Strategy 2: Check if basename matches zone filename
        if (basename($reportedFile) === $zoneFilename) {
            $path = $tmpDir . '/' . $zoneFilename;
            if (file_exists($path)) {
                return $path;
            }
        }
        
        // Strategy 3: Try basename in tmpDir
        $path = $tmpDir . '/' . basename($reportedFile);
        if (file_exists($path)) {
            return $path;
        }
        
        // Strategy 4: Try the reported file as-is relative to tmpDir
        $path = $tmpDir . '/' . $reportedFile;
        if (file_exists($path)) {
            return $path;
        }
        
        return null;
    }
    
    /**
     * Get file line context with surrounding lines
     * 
     * @param string $path File path
     * @param int $lineNumber Target line number (1-based)
     * @param int $contextLines Number of context lines before and after
     * @return string Formatted block with line numbers, or empty string on error
     */
    private function getFileLineContext($path, $lineNumber, $contextLines = 2) {
        if (!file_exists($path) || !is_readable($path)) {
            return '';
        }
        
        $fileLines = file($path, FILE_IGNORE_NEW_LINES);
        if ($fileLines === false) {
            return '';
        }
        
        $totalLines = count($fileLines);
        if ($lineNumber < 1 || $lineNumber > $totalLines) {
            return '';
        }
        
        // Calculate range (convert to 0-based index)
        $startLine = max(0, $lineNumber - 1 - $contextLines);
        $endLine = min($totalLines - 1, $lineNumber - 1 + $contextLines);
        
        $result = [];
        for ($i = $startLine; $i <= $endLine; $i++) {
            $displayLineNum = $i + 1;
            $prefix = ($displayLineNum === $lineNumber) ? '>' : ' ';
            $result[] = sprintf("%s %4d: %s", $prefix, $displayLineNum, $fileLines[$i]);
        }
        
        return implode("\n", $result);
    }
    
    /**
     * Inline $INCLUDE directives recursively (LEGACY - kept for backward compatibility)
     * Replaces $INCLUDE directives with the actual generated content
     * 
     * Note: This method is kept for backward compatibility but is no longer used
     * by the validation system. Validation now writes files to disk instead.
     * 
     * @param string $content Zone file content with $INCLUDE directives
     * @param array &$visited Array of visited filenames to prevent loops
     * @param int $depth Current recursion depth
     * @return string Content with all $INCLUDE directives replaced
     * @throws Exception if include not found, depth exceeded, or loop detected
     */
    private function inlineIncludes($content, &$visited = [], $depth = 0) {
        // Depth limit to prevent excessive recursion
        $maxDepth = 10;
        if ($depth > $maxDepth) {
            throw new Exception("Maximum include depth ($maxDepth) exceeded");
        }
        
        // Find all $INCLUDE directives
        // Pattern: $INCLUDE "path/to/file" or $INCLUDE path/to/file
        $pattern = '/^\s*\$INCLUDE\s+["\']?([^\s"\']+)["\']?\s*$/m';
        
        $result = preg_replace_callback($pattern, function($matches) use (&$visited, $depth) {
            $includePath = $matches[1];
            $includeBasename = basename($includePath);
            
            // Check for loops
            if (in_array($includeBasename, $visited)) {
                throw new Exception("Circular include detected: $includeBasename");
            }
            $visited[] = $includeBasename;
            
            // Try to find the include by filename in zone_files table
            $sql = "SELECT id FROM zone_files WHERE filename = ? AND status = 'active' LIMIT 1";
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$includeBasename]);
            $includeZone = $stmt->fetch();
            
            if ($includeZone) {
                // Generate content for this include
                $includeContent = $this->generateZoneFile($includeZone['id']);
                
                // Recursively inline any nested includes
                $includeContent = $this->inlineIncludes($includeContent, $visited, $depth + 1);
                
                // Return inlined content with comments for debugging
                return "; BEGIN INCLUDE: $includeBasename\n" .
                       trim($includeContent) . "\n" .
                       "; END INCLUDE: $includeBasename\n";
            }
            
            // Fallback: try to read from disk if file exists
            // This is optional and provides backward compatibility
            $possiblePath = __DIR__ . '/../../' . $includePath;
            $realPath = realpath($possiblePath);
            
            if ($realPath && file_exists($realPath) && is_readable($realPath)) {
                $includeContent = file_get_contents($realPath);
                
                // Recursively inline any nested includes in the disk file
                $includeContent = $this->inlineIncludes($includeContent, $visited, $depth + 1);
                
                return "; BEGIN INCLUDE: $includeBasename (from disk)\n" .
                       trim($includeContent) . "\n" .
                       "; END INCLUDE: $includeBasename\n";
            }
            
            // Include not found - throw exception
            throw new Exception("Included file not found for validation: $includeBasename (path: $includePath)");
        }, $content);
        
        return $result;
    }
    
    /**
     * Recursively remove a directory and its contents
     * 
     * @param string $dir Directory path to remove
     * @return bool Success status
     */
    private function rrmdir($dir) {
        if (!is_dir($dir)) {
            return false;
        }
        
        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = $dir . '/' . $file;
            is_dir($path) ? $this->rrmdir($path) : unlink($path);
        }
        
        return rmdir($dir);
    }
    
    /**
     * Propagate validation result to all descendant includes of a parent zone (recursively)
     * This is called after validating a master/parent zone to update include validation status
     * Uses BFS (breadth-first search) to traverse the include tree
     * 
     * @param int $parentId Parent zone file ID
     * @param string $parentName Parent zone name (top master for output message)
     * @param string $status Validation status
     * @param string $output Validation output
     * @param int|null $userId User ID
     * @param string|null $command Command executed
     * @param int|null $returnCode Exit code
     * @return void
     */
    private function propagateValidationToIncludes($parentId, $parentName, $status, $output, $userId, $command = null, $returnCode = null) {
        try {
            // Use BFS to traverse all descendants
            $queue = [$parentId];
            $visited = [];
            
            while (!empty($queue)) {
                $currentId = array_shift($queue);
                
                // Prevent infinite loops
                if (in_array($currentId, $visited)) {
                    continue;
                }
                $visited[] = $currentId;
                
                // Get all direct includes of current zone
                $sql = "SELECT include_id FROM zone_file_includes WHERE parent_id = ?";
                $stmt = $this->db->prepare($sql);
                $stmt->execute([$currentId]);
                $includes = $stmt->fetchAll(PDO::FETCH_COLUMN);
                
                // Update validation result for each include and add to queue
                foreach ($includes as $includeId) {
                    $includeOutput = "Validation performed on parent zone '{$parentName}' (ID: {$parentId}):\n\n" . $output;
                    $this->storeValidationResult($includeId, $status, $includeOutput, $userId, $command, $returnCode);
                    
                    // Add to queue for recursive processing
                    $queue[] = $includeId;
                }
            }
        } catch (Exception $e) {
            error_log("ZoneFile propagateValidationToIncludes error: " . $e->getMessage());
        }
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
     * @param string $output Command output (should include command, exit code, and stdout/stderr)
     * @param int|null $userId User ID
     * @param string|null $command Command executed (will be embedded in output)
     * @param int|null $returnCode Exit code (will be embedded in output)
     * @return bool Success status
     */
    private function storeValidationResult($zoneId, $status, $output, $userId, $command = null, $returnCode = null) {
        try {
            // Embed command and return code into output field if provided
            $fullOutput = $output;
            if ($command !== null || $returnCode !== null) {
                $fullOutput = '';
                if ($command !== null) {
                    $fullOutput .= "Command: $command\n";
                }
                if ($returnCode !== null) {
                    $fullOutput .= "Exit Code: $returnCode\n";
                }
                $fullOutput .= "\n" . $output;
            }
            
            // Truncate if too large (keep first 10000 chars)
            $maxOutputLength = 10000;
            $originalLength = strlen($fullOutput);
            if ($originalLength > $maxOutputLength) {
                $fullOutput = substr($fullOutput, 0, $maxOutputLength) . 
                             "\n\n[Output truncated: " . ($originalLength - $maxOutputLength) . " additional bytes]";
            }
            
            $sql = "INSERT INTO zone_file_validation (zone_file_id, status, output, run_by, checked_at)
                    VALUES (?, ?, ?, ?, NOW())";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$zoneId, $status, $fullOutput, $userId]);
            
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
    
    /**
     * Log validation messages to worker.log
     * 
     * @param string $message Message to log
     * @return void
     */
    private function logValidation($message) {
        $logFile = __DIR__ . '/../../jobs/worker.log';
        $timestamp = date('Y-m-d H:i:s');
        $logLine = "[$timestamp] [ZoneFile] $message\n";
        file_put_contents($logFile, $logLine, FILE_APPEND);
    }
}
?>
