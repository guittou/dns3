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
     * Get database connection for direct queries
     * @return PDO Database connection
     */
    public function getConnection() {
        return $this->db;
    }

    /**
     * Search zone files with filters
     * 
     * @param array $filters Optional filters (name, file_type, status, owner, q for general search, zone_ids for ACL filtering)
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
        
        // ACL filter: restrict to specific zone IDs (for non-admin users)
        if (isset($filters['zone_ids']) && is_array($filters['zone_ids']) && !empty($filters['zone_ids'])) {
            $placeholders = implode(',', array_fill(0, count($filters['zone_ids']), '?'));
            $sql .= " AND zf.id IN ($placeholders)";
            $params = array_merge($params, $filters['zone_ids']);
        }
        
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
            $zones = $stmt->fetchAll();
            
            // For include zones, populate parent_domain with top master domain
            foreach ($zones as &$zone) {
                if ($zone['file_type'] === 'include') {
                    // Find top master and get its domain
                    $topMasterResult = $this->findTopMaster($zone['id']);
                    if (!isset($topMasterResult['error']) && isset($topMasterResult['id'])) {
                        $topMasterId = $topMasterResult['id'];
                        // Get the zone file to read its domain (without enrichment to avoid recursion)
                        $topMasterZone = $this->getById($topMasterId, true, false);
                        if ($topMasterZone && !empty($topMasterZone['domain'])) {
                            $zone['parent_domain'] = $topMasterZone['domain'];
                        }
                    }
                }
            }
            
            return $zones;
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
        
        // ACL filter: restrict to specific zone IDs (for non-admin users)
        if (isset($filters['zone_ids']) && is_array($filters['zone_ids']) && !empty($filters['zone_ids'])) {
            $placeholders = implode(',', array_fill(0, count($filters['zone_ids']), '?'));
            $sql .= " AND zf.id IN ($placeholders)";
            $params = array_merge($params, $filters['zone_ids']);
        }
        
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
     * List zone files accessible to a non-admin user via ACL
     * Returns only zones where user has at least the specified permission level
     * 
     * @param array $userCtx User context: ['id' => int, 'roles' => array of role names]
     * @param string $minPermission Minimum required permission (read, write, admin)
     * @param array $userGroups User's AD groups
     * @param array $filters Optional filters (same as search method)
     * @param int $limit Maximum number of results
     * @param int $offset Pagination offset
     * @return array Array of zone files accessible to the user
     */
    public function listForUser($userCtx, $minPermission = 'read', $userGroups = [], $filters = [], $limit = 100, $offset = 0) {
        require_once __DIR__ . '/ZoneAcl.php';
        
        try {
            $zoneAcl = new ZoneAcl();
            
            // Get all zone IDs that user has access to
            $accessibleZoneIds = $zoneAcl->getAccessibleZoneIds($userCtx, $minPermission, $userGroups);
            
            if (empty($accessibleZoneIds)) {
                return [];
            }
            
            // Build query with zone ID filter
            $placeholders = implode(',', array_fill(0, count($accessibleZoneIds), '?'));
            
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
                    WHERE zf.id IN ($placeholders)";
            
            $params = $accessibleZoneIds;
            
            // Apply additional filters
            if (isset($filters['q']) && $filters['q'] !== '') {
                $sql .= " AND (zf.name LIKE ? OR zf.filename LIKE ?)";
                $params[] = '%' . $filters['q'] . '%';
                $params[] = '%' . $filters['q'] . '%';
            }
            
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
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $zones = $stmt->fetchAll();
            
            // Enrich zones with parent_domain for includes
            foreach ($zones as &$zone) {
                if ($zone['file_type'] === 'include') {
                    $topMasterResult = $this->findTopMaster($zone['id']);
                    if (!isset($topMasterResult['error']) && isset($topMasterResult['id'])) {
                        $topMasterId = $topMasterResult['id'];
                        $topMasterZone = $this->getById($topMasterId, true, false);
                        if ($topMasterZone && !empty($topMasterZone['domain'])) {
                            $zone['parent_domain'] = $topMasterZone['domain'];
                        }
                    }
                }
            }
            
            return $zones;
        } catch (Exception $e) {
            error_log("ZoneFile listForUser error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Count zone files accessible to a non-admin user via ACL
     * 
     * @param array $userCtx User context: ['id' => int, 'roles' => array of role names]
     * @param string $minPermission Minimum required permission (read, write, admin)
     * @param array $userGroups User's AD groups
     * @param array $filters Optional filters (same as search method)
     * @return int Total count of accessible zone files
     */
    public function countForUser($userCtx, $minPermission = 'read', $userGroups = [], $filters = []) {
        require_once __DIR__ . '/ZoneAcl.php';
        
        try {
            $zoneAcl = new ZoneAcl();
            
            // Get all zone IDs that user has access to
            $accessibleZoneIds = $zoneAcl->getAccessibleZoneIds($userCtx, $minPermission, $userGroups);
            
            if (empty($accessibleZoneIds)) {
                return 0;
            }
            
            // Build query with zone ID filter
            $placeholders = implode(',', array_fill(0, count($accessibleZoneIds), '?'));
            
            $sql = "SELECT COUNT(DISTINCT zf.id) as total
                    FROM zone_files zf
                    WHERE zf.id IN ($placeholders)";
            
            $params = $accessibleZoneIds;
            
            // Apply additional filters
            if (isset($filters['q']) && $filters['q'] !== '') {
                $sql .= " AND (zf.name LIKE ? OR zf.filename LIKE ?)";
                $params[] = '%' . $filters['q'] . '%';
                $params[] = '%' . $filters['q'] . '%';
            }
            
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
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute($params);
            $result = $stmt->fetch();
            return (int)$result['total'];
        } catch (Exception $e) {
            error_log("ZoneFile countForUser error: " . $e->getMessage());
            return 0;
        }
    }

    /**
     * Get a zone file by ID
     * 
     * @param int $id Zone file ID
     * @param bool $includeDeleted If true, include deleted zones
     * @param bool $enrichParentDomain If true, populate parent_domain with top master domain for includes
     * @return array|null Zone file data or null if not found
     */
    public function getById($id, $includeDeleted = false, $enrichParentDomain = true) {
        try {
            $sql = "SELECT zf.*, 
                           u1.username as created_by_username,
                           u2.username as updated_by_username,
                           zfi.parent_id,
                           parent_zf.name as parent_name,
                           parent_zf.domain as parent_domain
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
            
            // For include zones, populate parent_domain with top master domain
            // Only if enrichParentDomain is true to avoid infinite recursion
            if ($result && $result['file_type'] === 'include' && $enrichParentDomain) {
                // Find top master and get its domain
                $topMasterResult = $this->findTopMaster($result['id']);
                if (!isset($topMasterResult['error']) && isset($topMasterResult['id'])) {
                    $topMasterId = $topMasterResult['id'];
                    // Get the zone file to read its domain (without enrichment to avoid recursion)
                    $topMasterZone = $this->getById($topMasterId, true, false);
                    if ($topMasterZone && !empty($topMasterZone['domain'])) {
                        $result['parent_domain'] = $topMasterZone['domain'];
                    }
                }
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
     * @param array $data Zone file data (name, filename, directory, file_type, content, default_ttl, soa_*)
     * @param int $user_id User creating the zone file
     * @return int|bool New zone file ID or false on failure
     */
    public function create($data, $user_id) {
        try {
            $this->db->beginTransaction();
            
            $sql = "INSERT INTO zone_files (name, filename, directory, content, file_type, domain, default_ttl, soa_refresh, soa_retry, soa_expire, soa_minimum, soa_rname, mname, dnssec_include_ksk, dnssec_include_zsk, application, trigramme, status, created_by, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, NOW())";
            
            // Only set domain and SOA fields if file_type is 'master'
            $domain = null;
            $defaultTtl = null;
            $soaRefresh = null;
            $soaRetry = null;
            $soaExpire = null;
            $soaMinimum = null;
            $soaRname = null;
            $mname = null;
            $dnssecKsk = null;
            $dnssecZsk = null;
            
            // Only set application and trigramme if file_type is 'include'
            $application = null;
            $trigramme = null;
            
            $fileType = $data['file_type'] ?? 'master';
            
            if ($fileType === 'master') {
                if (isset($data['domain'])) {
                    $domain = trim($data['domain']);
                    if ($domain === '') {
                        $domain = null;
                    }
                }
                // SOA/TTL fields
                $defaultTtl = isset($data['default_ttl']) && $data['default_ttl'] !== '' ? (int)$data['default_ttl'] : null;
                $soaRefresh = isset($data['soa_refresh']) && $data['soa_refresh'] !== '' ? (int)$data['soa_refresh'] : null;
                $soaRetry = isset($data['soa_retry']) && $data['soa_retry'] !== '' ? (int)$data['soa_retry'] : null;
                $soaExpire = isset($data['soa_expire']) && $data['soa_expire'] !== '' ? (int)$data['soa_expire'] : null;
                $soaMinimum = isset($data['soa_minimum']) && $data['soa_minimum'] !== '' ? (int)$data['soa_minimum'] : null;
                $soaRname = isset($data['soa_rname']) && trim($data['soa_rname']) !== '' ? trim($data['soa_rname']) : null;
                // MNAME (primary master nameserver)
                if (isset($data['mname']) && trim($data['mname']) !== '') {
                    $mname = $this->normalizeFqdn(trim($data['mname']));
                }
                // DNSSEC include paths (only for master zones)
                if (isset($data['dnssec_include_ksk']) && trim($data['dnssec_include_ksk']) !== '') {
                    $dnssecKsk = trim($data['dnssec_include_ksk']);
                }
                if (isset($data['dnssec_include_zsk']) && trim($data['dnssec_include_zsk']) !== '') {
                    $dnssecZsk = trim($data['dnssec_include_zsk']);
                }
            } else {
                // For include files, handle application and trigramme
                if (isset($data['application'])) {
                    $application = trim($data['application']);
                    if ($application === '') {
                        $application = null;
                    }
                }
                if (isset($data['trigramme'])) {
                    $trigramme = trim($data['trigramme']);
                    if ($trigramme === '') {
                        $trigramme = null;
                    }
                }
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'],
                $data['filename'],
                $data['directory'] ?? null,
                $data['content'] ?? null,
                $fileType,
                $domain,
                $defaultTtl,
                $soaRefresh,
                $soaRetry,
                $soaExpire,
                $soaMinimum,
                $soaRname,
                $mname,
                $dnssecKsk,
                $dnssecZsk,
                $application,
                $trigramme,
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
     * @param array $data Updated zone file data (includes default_ttl, soa_*, mname fields)
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
                    SET name = ?, filename = ?, directory = ?, content = ?, file_type = ?, domain = ?,
                        default_ttl = ?, soa_refresh = ?, soa_retry = ?, soa_expire = ?, soa_minimum = ?, soa_rname = ?, mname = ?,
                        dnssec_include_ksk = ?, dnssec_include_zsk = ?, application = ?, trigramme = ?,
                        updated_by = ?, updated_at = NOW()
                    WHERE id = ? AND status != 'deleted'";
            
            $fileType = $data['file_type'] ?? $current['file_type'];
            
            // Only allow domain and SOA fields for master zones
            $domain = $current['domain'] ?? null;
            $defaultTtl = $current['default_ttl'] ?? null;
            $soaRefresh = $current['soa_refresh'] ?? null;
            $soaRetry = $current['soa_retry'] ?? null;
            $soaExpire = $current['soa_expire'] ?? null;
            $soaMinimum = $current['soa_minimum'] ?? null;
            $soaRname = $current['soa_rname'] ?? null;
            $mname = $current['mname'] ?? null;
            $dnssecKsk = $current['dnssec_include_ksk'] ?? null;
            $dnssecZsk = $current['dnssec_include_zsk'] ?? null;
            
            // Only allow application and trigramme for include zones
            $application = $current['application'] ?? null;
            $trigramme = $current['trigramme'] ?? null;
            
            if ($fileType === 'master') {
                if (isset($data['domain'])) {
                    $domain = trim($data['domain']);
                    if ($domain === '') {
                        $domain = null;
                    }
                }
                // SOA/TTL fields
                if (array_key_exists('default_ttl', $data)) {
                    $defaultTtl = $data['default_ttl'] !== '' && $data['default_ttl'] !== null ? (int)$data['default_ttl'] : null;
                }
                if (array_key_exists('soa_refresh', $data)) {
                    $soaRefresh = $data['soa_refresh'] !== '' && $data['soa_refresh'] !== null ? (int)$data['soa_refresh'] : null;
                }
                if (array_key_exists('soa_retry', $data)) {
                    $soaRetry = $data['soa_retry'] !== '' && $data['soa_retry'] !== null ? (int)$data['soa_retry'] : null;
                }
                if (array_key_exists('soa_expire', $data)) {
                    $soaExpire = $data['soa_expire'] !== '' && $data['soa_expire'] !== null ? (int)$data['soa_expire'] : null;
                }
                if (array_key_exists('soa_minimum', $data)) {
                    $soaMinimum = $data['soa_minimum'] !== '' && $data['soa_minimum'] !== null ? (int)$data['soa_minimum'] : null;
                }
                if (array_key_exists('soa_rname', $data)) {
                    $soaRname = trim($data['soa_rname']) !== '' ? trim($data['soa_rname']) : null;
                }
                // MNAME (primary master nameserver)
                if (array_key_exists('mname', $data)) {
                    $mname = trim($data['mname']) !== '' ? $this->normalizeFqdn(trim($data['mname'])) : null;
                }
                // DNSSEC include paths (only for master zones)
                if (array_key_exists('dnssec_include_ksk', $data)) {
                    $dnssecKsk = trim($data['dnssec_include_ksk']) !== '' ? trim($data['dnssec_include_ksk']) : null;
                }
                if (array_key_exists('dnssec_include_zsk', $data)) {
                    $dnssecZsk = trim($data['dnssec_include_zsk']) !== '' ? trim($data['dnssec_include_zsk']) : null;
                }
            } else {
                // For include files, handle application and trigramme
                if (array_key_exists('application', $data)) {
                    $application = trim($data['application']);
                    if ($application === '') {
                        $application = null;
                    }
                }
                if (array_key_exists('trigramme', $data)) {
                    $trigramme = trim($data['trigramme']);
                    if ($trigramme === '') {
                        $trigramme = null;
                    }
                }
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                $data['name'] ?? $current['name'],
                $data['filename'] ?? $current['filename'],
                isset($data['directory']) ? $data['directory'] : $current['directory'],
                isset($data['content']) ? $data['content'] : $current['content'],
                $fileType,
                $domain,
                $defaultTtl,
                $soaRefresh,
                $soaRetry,
                $soaExpire,
                $soaMinimum,
                $soaRname,
                $mname,
                $dnssecKsk,
                $dnssecZsk,
                $application,
                $trigramme,
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
            
            // For top-level master zones, add required zone file header
            // Only add header if this is the first call (visited array has only current zone)
            if ($zone['file_type'] === 'master' && count($visited) === 1) {
                // Add $TTL directive
                $defaultTtl = !empty($zone['default_ttl']) ? $zone['default_ttl'] : 86400;
                $content .= '$TTL ' . $defaultTtl . "\n";
                
                // Add $ORIGIN directive
                $zoneName = $zone['name'] ?? $zone['domain'] ?? '';
                if (!empty($zoneName)) {
                    // Ensure zone name ends with a dot for FQDN
                    if (substr($zoneName, -1) !== '.') {
                        $zoneName .= '.';
                    }
                    $content .= '$ORIGIN ' . $zoneName . "\n";
                }
                $content .= "\n";
                
                // Generate and add SOA record
                $mname = !empty($zone['mname']) ? $zone['mname'] : null;
                $soaRecord = $this->generateSoaRecord($zone, $mname);
                $content .= $soaRecord . "\n\n";
                
                // Add DNSSEC include references (not inlined - kept as $INCLUDE directives)
                // These will be handled specially during validation to support absolute/relative paths
                $content = $this->addDnssecIncludes($content, $zone, true);
                
                $this->logValidation("Added zone header ($TTL, $ORIGIN, SOA) for master zone ID $masterId");
            }
            
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
            
            // For master zones, ensure at least one NS record exists
            if ($zone['file_type'] === 'master' && count($visited) === 1) {
                $hasNsRecord = false;
                foreach ($records as $record) {
                    if ($record['record_type'] === 'NS') {
                        $hasNsRecord = true;
                        break;
                    }
                }
                
                // If no NS record exists, add a default one
                if (!$hasNsRecord) {
                    $zoneDomain = $zone['domain'] ?? $zone['name'] ?? 'localhost';
                    $zoneDomain = rtrim($zoneDomain, '.');
                    
                    $defaultNs = [
                        'name' => '@',
                        'record_type' => 'NS',
                        'ttl' => null  // Will use zone default
                    ];
                    
                    // Set the NS value based on zone domain
                    if (!empty($zoneDomain) && $zoneDomain !== 'localhost') {
                        $defaultNs['value'] = 'ns1.' . $zoneDomain . '.';
                    } else {
                        $defaultNs['value'] = 'ns1.localhost.';
                    }
                    
                    // Prepend the default NS record
                    array_unshift($records, $defaultNs);
                    $this->logValidation("Added default NS record for zone ID $masterId (no NS records found)");
                }
            }
            
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
     * @param int|null $limit Maximum number of includes to return (null = no limit)
     * @return array Array of include zone files
     */
    public function getIncludes($parentId, $limit = null) {
        try {
            $sql = "SELECT zf.*, zfi.position
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'
                    ORDER BY zfi.position, zf.name";
            
            if ($limit !== null && $limit > 0) {
                $sql .= " LIMIT " . (int)$limit;
            }
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId]);
            return $stmt->fetchAll();
        } catch (Exception $e) {
            error_log("ZoneFile getIncludes error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get count of includes for a parent zone
     * 
     * @param int $parentId Parent zone file ID
     * @return int Count of active includes
     */
    public function getIncludesCount($parentId) {
        try {
            $sql = "SELECT COUNT(*) as count
                    FROM zone_files zf
                    INNER JOIN zone_file_includes zfi ON zf.id = zfi.include_id
                    WHERE zfi.parent_id = ? AND zf.status = 'active'";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$parentId]);
            $result = $stmt->fetch();
            return (int)($result['count'] ?? 0);
        } catch (Exception $e) {
            error_log("ZoneFile getIncludesCount error: " . $e->getMessage());
            return 0;
        }
    }

    /**
     * Get recursive tree of master and all its descendants (includes)
     * Uses BFS (breadth-first search) to traverse the include hierarchy
     * 
     * @param int $masterId Master zone file ID to start from
     * @param int|null $limit Maximum number of results to return (security limit)
     * @return array Array of zone file rows (same columns as getById/getIncludes)
     */
    public function getRecursiveTree($masterId, $limit = null) {
        try {
            // Get the master zone first
            $master = $this->getById($masterId);
            if (!$master) {
                error_log("ZoneFile getRecursiveTree: Master zone not found (ID: $masterId)");
                return [];
            }
            
            $results = [];
            $queue = [$masterId];
            $visited = [];
            
            // BFS traversal
            while (!empty($queue) && ($limit === null || count($results) < $limit)) {
                $currentId = array_shift($queue);
                
                // Cycle detection
                if (in_array($currentId, $visited)) {
                    error_log("ZoneFile getRecursiveTree: Cycle detected at zone ID $currentId");
                    continue;
                }
                $visited[] = $currentId;
                
                // Get current zone data
                $zone = $this->getById($currentId);
                if (!$zone) {
                    error_log("ZoneFile getRecursiveTree: Zone not found (ID: $currentId)");
                    continue;
                }
                
                // Add to results
                $results[] = $zone;
                
                // Stop if we've reached the limit
                if ($limit !== null && count($results) >= $limit) {
                    break;
                }
                
                // Get includes and add them to the queue
                $includes = $this->getIncludes($currentId);
                foreach ($includes as $include) {
                    if (!in_array($include['id'], $visited)) {
                        $queue[] = $include['id'];
                    }
                }
            }
            
            return $results;
        } catch (Exception $e) {
            error_log("ZoneFile getRecursiveTree error: " . $e->getMessage());
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
     * Uses zone's default_ttl for $TTL directive, mname and soa_* fields for SOA record
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
            
            // For master zones, add $TTL directive and SOA record
            if ($zone['file_type'] === 'master') {
                // Add $TTL directive if default_ttl is set
                $defaultTtl = !empty($zone['default_ttl']) ? $zone['default_ttl'] : 86400;
                $content .= '$TTL ' . $defaultTtl . "\n\n";
                
                // Generate SOA record using stored mname or default
                $mname = !empty($zone['mname']) ? $zone['mname'] : null;
                $soaRecord = $this->generateSoaRecord($zone, $mname);
                $content .= $soaRecord . "\n\n";
                
                // Add DNSSEC include directives (KSK first, then ZSK)
                // These are injected after SOA but before zone content and other includes
                $content = $this->addDnssecIncludes($content, $zone, false);
            }
            
            // Add zone's own content
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
     * Add DNSSEC include directives to zone content
     * 
     * @param string $content Current zone content
     * @param array $zone Zone data containing dnssec_include_ksk and dnssec_include_zsk
     * @param bool $forValidation If true, logs validation messages
     * @return string Content with DNSSEC includes added
     */
    private function addDnssecIncludes($content, $zone, $forValidation = false) {
        // Add DNSSEC KSK include if specified
        if (!empty($zone['dnssec_include_ksk'])) {
            $content .= '; DNSSEC KSK Include' . "\n";
            $content .= '$INCLUDE "' . $zone['dnssec_include_ksk'] . '"' . "\n\n";
            if ($forValidation) {
                $this->logValidation("Added DNSSEC KSK include reference: " . $zone['dnssec_include_ksk']);
            }
        }
        
        // Add DNSSEC ZSK include if specified
        if (!empty($zone['dnssec_include_zsk'])) {
            $content .= '; DNSSEC ZSK Include' . "\n";
            $content .= '$INCLUDE "' . $zone['dnssec_include_zsk'] . '"' . "\n\n";
            if ($forValidation) {
                $this->logValidation("Added DNSSEC ZSK include reference: " . $zone['dnssec_include_zsk']);
            }
        }
        
        return $content;
    }
    
    /**
     * Format RNAME (contact email) for SOA record
     * Converts email@domain.com to email.domain.com. format
     * Completes short names (without dots) with the zone domain
     * 
     * @param string $rname Contact email (may contain @ or be in DNS format)
     * @param string $zoneDomain Zone domain for completing short names
     * @return string RNAME in DNS format (with trailing dot)
     */
    public function formatSoaRname($rname, $zoneDomain = '') {
        // Get the zone domain (remove trailing dot if present for processing)
        $zoneDomain = rtrim(trim($zoneDomain), '.');
        
        if (empty($rname)) {
            // Default to hostmaster.<zone_domain>. or hostmaster. if no zone domain
            if (!empty($zoneDomain)) {
                return 'hostmaster.' . $zoneDomain . '.';
            }
            return 'hostmaster.';
        }
        
        // Replace @ with . for DNS format (email style: user@domain -> user.domain)
        $formatted = str_replace('@', '.', trim($rname));
        
        // Remove trailing dot temporarily to check if it contains a dot
        $withoutTrailingDot = rtrim($formatted, '.');
        
        // If the value doesn't contain a dot (short form like "hostmaster"),
        // complete it with the zone domain
        if (strpos($withoutTrailingDot, '.') === false && !empty($zoneDomain)) {
            $formatted = $withoutTrailingDot . '.' . $zoneDomain;
        }
        
        // Ensure trailing dot for FQDN
        if (substr($formatted, -1) !== '.') {
            $formatted .= '.';
        }
        
        return $formatted;
    }
    
    /**
     * Generate SOA record string using zone's SOA settings
     * 
     * @param array $zone Zone file data with SOA fields
     * @param string $mname Primary nameserver (MNAME)
     * @param int|null $serial SOA serial (if null, generates YYYYMMDDnn format)
     * @return string SOA record in BIND format
     */
    public function generateSoaRecord($zone, $mname, $serial = null) {
        // Default values matching RFC recommendations
        $refresh = $zone['soa_refresh'] ?? 10800;  // 3 hours
        $retry = $zone['soa_retry'] ?? 900;        // 15 minutes
        $expire = $zone['soa_expire'] ?? 604800;   // 7 days
        $minimum = $zone['soa_minimum'] ?? 3600;   // 1 hour
        
        // Get zone domain for completing short RNAME/MNAME values
        $zoneDomain = $zone['domain'] ?? $zone['name'] ?? '';
        
        // Format RNAME (contact) - pass zone domain for completing short names
        $rname = $this->formatSoaRname($zone['soa_rname'] ?? '', $zoneDomain);
        
        // Normalize MNAME with trailing dot, or use default if empty
        $mname = $this->normalizeFqdn($mname);
        if (empty($mname)) {
            // Use zone domain if available, otherwise use a placeholder
            if (!empty($zoneDomain)) {
                $mname = 'ns1.' . $zoneDomain . '.';
            } else {
                $mname = 'ns1.localhost.';
            }
        }
        
        // Generate serial if not provided (YYYYMMDDnn format)
        if ($serial === null) {
            $serial = date('Ymd') . '01';
        }
        
        // Format: @ IN SOA mname rname ( serial refresh retry expire minimum )
        return sprintf(
            "@ IN SOA %s %s (\n    %s ; Serial\n    %d ; Refresh\n    %d ; Retry\n    %d ; Expire\n    %d ; Minimum\n)",
            $mname,
            $rname,
            $serial,
            $refresh,
            $retry,
            $expire,
            $minimum
        );
    }
    
    /**
     * Normalize a hostname to FQDN format (with trailing dot)
     * 
     * @param string $hostname Hostname to normalize
     * @return string Hostname with trailing dot
     */
    public function normalizeFqdn($hostname) {
        if (empty($hostname)) {
            return '';
        }
        
        $hostname = trim($hostname);
        
        // Ensure trailing dot for FQDN
        if (substr($hostname, -1) !== '.') {
            $hostname .= '.';
        }
        
        return $hostname;
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
        $type = $record['record_type'];
        
        // Format the record value based on type
        $value = $this->getRecordValue($record);
        
        // Build the BIND format line
        // If TTL is null, omit it (BIND will use zone's default TTL)
        // Format: name [TTL] class type value
        if (array_key_exists('ttl', $record) && $record['ttl'] !== null) {
            // Include explicit TTL
            $line = sprintf("%-30s %6d IN %-6s %s", $name, $record['ttl'], $type, $value);
        } else {
            // Omit TTL (zone default will be used)
            $line = sprintf("%-30s        IN %-6s %s", $name, $type, $value);
        }
        
        return $line;
    }
    
    /**
     * Get the value for a DNS record based on its type
     * Formats the record data appropriately for BIND zone file syntax
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
            
            case 'DNAME':
                return $record['dname_target'] ?? $record['value'];
            
            case 'PTR':
                return $record['ptrdname'] ?? $record['value'];
            
            case 'MX':
                $priority = isset($record['priority']) ? $record['priority'] : 10;
                $target = $record['mx_target'] ?? $record['value'];
                return "$priority $target";
            
            case 'NS':
                return $record['ns_target'] ?? $record['value'];
            
            case 'TXT':
            case 'SPF':
            case 'DKIM':
            case 'DMARC':
                $txt = $record['txt'] ?? $record['value'];
                // Ensure TXT records are properly quoted
                if (substr($txt, 0, 1) !== '"') {
                    $txt = '"' . $txt . '"';
                }
                return $txt;
            
            case 'SOA':
                return $record['value'];
            
            case 'SRV':
                // SRV format: priority weight port target
                // Note: All SRV fields should come from the record; defaults only for backward compat
                $priority = isset($record['priority']) && $record['priority'] !== null ? $record['priority'] : 0;
                $weight = isset($record['weight']) && $record['weight'] !== null ? $record['weight'] : 0;
                // Port is required for SRV - if not set, try to extract from legacy 'value' field
                $port = isset($record['port']) && $record['port'] !== null ? $record['port'] : null;
                $target = $record['srv_target'] ?? null;
                
                // Backward compatibility: if srv_target or port missing, try to parse legacy value
                if (($target === null || $port === null) && isset($record['value'])) {
                    $parts = preg_split('/\s+/', trim($record['value']));
                    if (count($parts) >= 2 && $port === null) {
                        $port = $parts[0];
                    }
                    if (count($parts) >= 1 && $target === null) {
                        $target = end($parts);
                    }
                }
                
                // Ensure we have required values
                $port = $port !== null ? $port : 0;
                $target = $target ?? '.';
                
                return "$priority $weight $port $target";
            
            case 'CAA':
                // CAA format: flag tag "value"
                $flag = isset($record['caa_flag']) ? $record['caa_flag'] : 0;
                $tag = $record['caa_tag'] ?? 'issue';
                $value = $record['caa_value'] ?? '';
                return "$flag $tag \"$value\"";
            
            case 'TLSA':
                // TLSA format: usage selector matching certificate_data
                $usage = isset($record['tlsa_usage']) ? $record['tlsa_usage'] : 3;
                $selector = isset($record['tlsa_selector']) ? $record['tlsa_selector'] : 1;
                $matching = isset($record['tlsa_matching']) ? $record['tlsa_matching'] : 1;
                $data = $record['tlsa_data'] ?? '';
                return "$usage $selector $matching $data";
            
            case 'SSHFP':
                // SSHFP format: algorithm fingerprint_type fingerprint
                $algo = isset($record['sshfp_algo']) ? $record['sshfp_algo'] : 1;
                $fpType = isset($record['sshfp_type']) ? $record['sshfp_type'] : 2;
                $fingerprint = $record['sshfp_fingerprint'] ?? '';
                return "$algo $fpType $fingerprint";
            
            case 'NAPTR':
                // NAPTR format: order preference "flags" "service" "regexp" replacement
                $order = isset($record['naptr_order']) ? $record['naptr_order'] : 100;
                $pref = isset($record['naptr_pref']) ? $record['naptr_pref'] : 10;
                $flags = $record['naptr_flags'] ?? '';
                $service = $record['naptr_service'] ?? '';
                $regexp = $record['naptr_regexp'] ?? '';
                $replacement = $record['naptr_replacement'] ?? '.';
                return "$order $pref \"$flags\" \"$service\" \"$regexp\" $replacement";
            
            case 'SVCB':
            case 'HTTPS':
                // SVCB/HTTPS format: priority target [params]
                $priority = isset($record['svc_priority']) ? $record['svc_priority'] : 1;
                $target = $record['svc_target'] ?? '.';
                $params = $record['svc_params'] ?? '';
                $result = "$priority $target";
                if ($params) {
                    $result .= " $params";
                }
                return $result;
            
            case 'LOC':
                // LOC format: latitude longitude [altitude] [size] [hp] [vp]
                $lat = $record['loc_latitude'] ?? '';
                $lon = $record['loc_longitude'] ?? '';
                $alt = $record['loc_altitude'] ?? '';
                $result = "$lat $lon";
                if ($alt) {
                    $result .= " $alt";
                }
                return $result;
            
            case 'RP':
                // RP format: mailbox txt_domain
                $mbox = $record['rp_mbox'] ?? '.';
                $txt = $record['rp_txt'] ?? '.';
                return "$mbox $txt";
            
            default:
                return $record['value'] ?? '';
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
            // Avoid recursive enrichment call that would call findTopMaster() again
            $current = $this->getById($currentId, true, false);
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
     * Resolve DNSSEC include paths in zone content for validation
     * - Absolute paths: left as-is (named-checkzone will read the actual files)
     * - Relative paths: resolved using BIND_BASEDIR if configured, otherwise left as-is with warning
     * 
     * @param string $content Zone file content with $INCLUDE directives
     * @param string $tmpDir Temporary directory path (used for logging context)
     * @return string Content with resolved include paths
     */
    private function resolveDnssecIncludes($content, $tmpDir) {
        // Pattern to match $INCLUDE directives with DNSSEC comments
        // Matches: ; DNSSEC KSK Include\n$INCLUDE "path" or ; DNSSEC ZSK Include\n$INCLUDE "path"
        $pattern = '/; DNSSEC (KSK|ZSK) Include\s*\n\$INCLUDE\s+"([^"]+)"/';
        
        $content = preg_replace_callback($pattern, function($matches) use ($tmpDir) {
            $keyType = $matches[1]; // KSK or ZSK
            $includePath = $matches[2];
            
            // Check if path is absolute (starts with /)
            if (substr($includePath, 0, 1) === '/') {
                // Absolute path - leave as-is, named-checkzone will read the actual file
                $this->logValidation("DNSSEC $keyType include uses absolute path: $includePath (will be used as-is)");
                
                // Verify file exists and log warning if not
                if (!file_exists($includePath)) {
                    $this->logValidation("WARNING: DNSSEC $keyType include file not found: $includePath (validation may fail)");
                }
                
                return $matches[0]; // Return original unchanged
            } else {
                // Relative path - resolve using BIND_BASEDIR if configured
                $bindBasedir = defined('BIND_BASEDIR') ? BIND_BASEDIR : null;
                
                if ($bindBasedir !== null && $bindBasedir !== '') {
                    // Resolve relative path using BIND_BASEDIR
                    $resolvedPath = rtrim($bindBasedir, '/') . '/' . $includePath;
                    $this->logValidation("DNSSEC $keyType include resolved: $includePath -> $resolvedPath (using BIND_BASEDIR)");
                    
                    // Verify resolved file exists and log warning if not
                    if (!file_exists($resolvedPath)) {
                        $this->logValidation("WARNING: Resolved DNSSEC $keyType include file not found: $resolvedPath (validation may fail)");
                    }
                    
                    // Return updated include directive with resolved path
                    return "; DNSSEC $keyType Include\n\$INCLUDE \"$resolvedPath\"";
                } else {
                    // BIND_BASEDIR not configured - leave relative path as-is and warn
                    $this->logValidation("WARNING: DNSSEC $keyType include uses relative path ($includePath) but BIND_BASEDIR is not configured. Validation may fail if file doesn't exist in working directory.");
                    return $matches[0]; // Return original unchanged
                }
            }
        }, $content);
        
        return $content;
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
            
            // Fallback: if flatContent is empty or null, use generateZoneFile instead
            if ($flatContent === null || trim($flatContent) === '') {
                $this->logValidation("WARNING: generateFlatZone returned empty content for zone ID $zoneId, falling back to generateZoneFile");
                $flatContent = $this->generateZoneFile($zoneId);
                
                if ($flatContent === null || trim($flatContent) === '') {
                    $errorMsg = "Failed to generate zone content (both flatten and standard methods) for zone ID $zoneId";
                    $this->logValidation("ERROR: $errorMsg");
                    $this->storeValidationResult($zoneId, 'failed', $errorMsg, $userId, null, 1);
                    return [
                        'status' => 'failed',
                        'output' => $errorMsg,
                        'return_code' => 1
                    ];
                }
                $this->logValidation("Fallback successful: generateZoneFile returned content for zone ID $zoneId (" . strlen($flatContent) . " bytes)");
            } else {
                $this->logValidation("Generated flattened zone content for zone ID $zoneId (" . strlen($flatContent) . " bytes)");
            }
            
            // Clean content before writing: remove BOM, force UTF-8, ensure final newline
            // Remove UTF-8 BOM if present
            $flatContent = preg_replace('/^\xEF\xBB\xBF/', '', $flatContent);
            
            // Ensure UTF-8 encoding
            if (!mb_check_encoding($flatContent, 'UTF-8')) {
                $detectedEncoding = mb_detect_encoding($flatContent, mb_detect_order(), true);
                if ($detectedEncoding && $detectedEncoding !== 'UTF-8') {
                    $flatContent = mb_convert_encoding($flatContent, 'UTF-8', $detectedEncoding);
                    $this->logValidation("Content was re-encoded from $detectedEncoding to UTF-8 for zone ID $zoneId");
                } else {
                    // If encoding cannot be detected, log the issue but proceed with the content as-is
                    // Converting UTF-8 to UTF-8 won't fix corruption and may cause data loss
                    $this->logValidation("WARNING: Content encoding validation failed for zone ID $zoneId, but encoding could not be detected. Proceeding with content as-is.");
                }
            }
            
            // Ensure file ends with a newline
            if (!empty($flatContent) && substr($flatContent, -1) !== "\n") {
                $flatContent .= "\n";
            }
            
            $this->logValidation("Content cleaned and ready to write for zone ID $zoneId (final size: " . strlen($flatContent) . " bytes)");
            
            // Process DNSSEC includes: resolve relative paths using BIND_BASEDIR if configured
            $flatContent = $this->resolveDnssecIncludes($flatContent, $tmpDir);
            
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
            
            // Build named-checkzone command (no -q flag to capture full output)
            $zoneName = $zone['name'];
            $command = escapeshellcmd($namedCheckzone) . ' ' . 
                       escapeshellarg($zoneName) . ' ' . 
                       escapeshellarg($tempFilePath) . ' 2>&1';
            
            $this->logValidation("Executing command for zone ID $zoneId: $command");
            
            // Execute command and capture full output
            exec($command, $output, $returnCode);
            $outputText = implode("\n", $output);
            
            // Save validation output to a file in the temp directory
            $validationOutFile = $tmpDir . '/zone_' . $zoneId . '_validation_output.txt';
            file_put_contents($validationOutFile, $outputText);
            
            // Set restrictive permissions on the validation output file
            if (!chmod($validationOutFile, 0640)) {
                $this->logValidation("WARNING: Failed to set permissions on validation output file: $validationOutFile");
            }
            
            $this->logValidation("Command exit code for zone ID $zoneId: $returnCode");
            $this->logValidation("Full validation output saved to: $validationOutFile");
            
            // Log errors if validation failed with helpful excerpts
            if ($returnCode !== 0) {
                $this->logValidation("Validation FAILED for zone ID $zoneId. Full output saved to: $validationOutFile");
                
                // Print first 40 lines to the worker log for quick visibility
                $lines = explode("\n", $outputText);
                $excerpt = array_slice($lines, 0, 40);
                $this->logValidation("Validation output excerpt:\n" . implode("\n", $excerpt));
                
                if (count($lines) > 40) {
                    $this->logValidation("... (output truncated, see full output at: $validationOutFile)");
                }
            } else {
                $this->logValidation("Validation PASSED for zone ID $zoneId");
            }
            
            // Determine status
            $status = ($returnCode === 0) ? 'passed' : 'failed';
            
            // Prepend validation log file location to output for UI display
            $outputWithLogRef = "Validation log file: $validationOutFile\n\n" . $outputText;
            
            // Store validation result with command and return code embedded in output
            $this->storeValidationResult($zoneId, $status, $outputWithLogRef, $userId, $command, $returnCode);
            
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
                if ($this->rrmdir($tmpDir)) {
                    $this->logValidation("Temporary directory cleaned up successfully: $tmpDir");
                } else {
                    $this->logValidation("ERROR: Failed to clean up temporary directory: $tmpDir");
                }
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
            if (is_dir($path)) {
                if (!$this->rrmdir($path)) {
                    return false;
                }
            } else {
                // Attempt to delete file
                // Using @ to suppress PHP warnings since we explicitly check the return value
                // and capture the error via error_get_last() for better error messages
                if (!@unlink($path)) {
                    $error = error_get_last();
                    $errorMsg = $error ? $error['message'] : 'unknown error';
                    error_log("Failed to delete file: $path - $errorMsg");
                    return false;
                }
            }
        }
        
        // Attempt to remove the now-empty directory
        // Using @ to suppress PHP warnings since we explicitly check the return value
        // and capture the error via error_get_last() for better error messages
        if (!@rmdir($dir)) {
            $error = error_get_last();
            $errorMsg = $error ? $error['message'] : 'unknown error';
            error_log("Failed to remove directory: $dir - $errorMsg");
            return false;
        }
        
        return true;
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
    
    /**
     * Recursively collect all include files for a zone (with cycle detection)
     * 
     * @param int $zoneId Zone file ID
     * @param array $visited Array of already visited zone IDs (for cycle detection)
     * @return array Array of include zone file data arrays
     */
    public function collectAllIncludes($zoneId, &$visited = []) {
        // Cycle detection
        if (in_array($zoneId, $visited)) {
            return [];
        }
        $visited[] = $zoneId;
        
        $allIncludes = [];
        
        // Get direct includes for this zone
        $includes = $this->getIncludes($zoneId);
        
        foreach ($includes as $include) {
            // Add this include
            $allIncludes[] = $include;
            
            // Recursively get includes of this include
            $subIncludes = $this->collectAllIncludes($include['id'], $visited);
            $allIncludes = array_merge($allIncludes, $subIncludes);
        }
        
        return $allIncludes;
    }
    
    /**
     * Write zone file to disk under BIND_BASEDIR
     * Creates necessary directory structure and sets appropriate permissions
     * 
     * @param int $zoneId Zone file ID
     * @param string $bindBasedir Base directory for BIND zone files
     * @return array Result array with 'success' boolean, 'file_path' on success, or 'error' on failure
     */
    public function writeZoneFileToDisk($zoneId, $bindBasedir) {
        try {
            // Get zone file information
            $zone = $this->getById($zoneId);
            if (!$zone) {
                return [
                    'success' => false,
                    'error' => "Zone file not found: ID $zoneId"
                ];
            }
            
            // Generate zone file content
            $content = $this->generateZoneFile($zoneId);
            if ($content === null || trim($content) === '') {
                return [
                    'success' => false,
                    'error' => "Failed to generate zone file content for zone ID $zoneId"
                ];
            }
            
            // Clean content: remove BOM, ensure UTF-8, ensure final newline
            // Zone files should be UTF-8 encoded. Remove BOM if present.
            $content = preg_replace('/^\xEF\xBB\xBF/', '', $content);
            
            // Note: We expect zone files to be UTF-8 encoded from the database.
            // If encoding issues occur, they should be fixed at the source (database input validation)
            // rather than attempted conversion here which may cause data corruption.
            
            if (!empty($content) && substr($content, -1) !== "\n") {
                $content .= "\n";
            }
            
            // Determine target directory path
            $targetDir = rtrim($bindBasedir, '/');
            
            // If zone has a directory specified, append it to base
            if (!empty($zone['directory'])) {
                $targetDir .= '/' . trim($zone['directory'], '/');
            }
            
            // Create directory if it doesn't exist
            if (!is_dir($targetDir)) {
                if (!mkdir($targetDir, 0755, true)) {
                    return [
                        'success' => false,
                        'error' => "Failed to create directory: $targetDir"
                    ];
                }
            }
            
            // Verify directory is writable
            if (!is_writable($targetDir)) {
                return [
                    'success' => false,
                    'error' => "Directory is not writable: $targetDir"
                ];
            }
            
            // Determine filename
            $filename = $zone['filename'];
            if (empty($filename)) {
                // Fallback to zone name if filename is not set
                $filename = $zone['name'] . '.db';
            }
            
            // Build full file path
            $filePath = $targetDir . '/' . $filename;
            
            // Write content to file (overwrite if exists)
            $bytesWritten = file_put_contents($filePath, $content);
            
            if ($bytesWritten === false) {
                return [
                    'success' => false,
                    'error' => "Failed to write file: $filePath"
                ];
            }
            
            // Set file permissions to 0644 (readable by all, writable by owner)
            if (!chmod($filePath, 0644)) {
                // Log warning but don't fail the operation
                error_log("Warning: Failed to set permissions on zone file: $filePath");
            }
            
            return [
                'success' => true,
                'file_path' => $filePath,
                'bytes_written' => $bytesWritten
            ];
            
        } catch (Exception $e) {
            error_log("ZoneFile writeZoneFileToDisk error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => "Exception: " . $e->getMessage()
            ];
        }
    }
}
?>
