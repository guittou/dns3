<?php
// Gé®©rateur de jeu de test (zones master + include, enregistrements pour masters/includes)
// Usage : php scripts/generate_test_data.php --zones=50 --masters=40 --includes=10 --records=1000 --user=1 [--mx=1]
// Ce script gé®¨re des zones et includes valides (contenu BIND) afin que named-checkzone / worker.sh les valides.
// Ne pas exé£µter en production sans backup.

require_once __DIR__ . '/../includes/db.php';

$options = getopt("", ["zones::", "masters::", "includes::", "records::", "user::", "mx::"]);
$totalZones = isset($options['zones']) ? (int)$options['zones'] : 50;
$mastersArg  = isset($options['masters']) ? (int)$options['masters'] : null;
$includesArg = isset($options['includes']) ? (int)$options['includes'] : null;
$recordsCount = isset($options['records']) ? (int)$options['records'] : 1000;
$userId = isset($options['user']) ? (int)$options['user'] : 1;
$enableMx = isset($options['mx']) ? (bool)$options['mx'] : false;

if ($mastersArg !== null && $includesArg !== null) {
    $mastersCount = max(1, $mastersArg);
    $includesCount = max(0, $includesArg);
} elseif ($mastersArg !== null) {
    $mastersCount = max(1, $mastersArg);
    $includesCount = max(0, $totalZones - $mastersCount);
} elseif ($includesArg !== null) {
    $includesCount = max(0, $includesArg);
    $mastersCount = max(1, $totalZones - $includesCount);
} else {
    // default split 80% masters, 20% includes
    $mastersCount = max(1, (int)round($totalZones * 0.8));
    $includesCount = max(0, $totalZones - $mastersCount);
}

echo "Configuration: masters={$mastersCount}, includes={$includesCount}, records={$recordsCount}, user={$userId}\n";

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

function now() {
    return date('Y-m-d H:i:s');
}

function soa_serial($index = 1) {
    // format YYYYMMDDnn to be valid and increasing
    return date('Ymd') . sprintf('%02d', $index % 100);
}

// Prepare zone insert
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, 'active', :created_by, :created_at, :updated_at)"
);

// 1) Create master zones
$masterIds = [];
$masterMeta = []; // store meta (id,name,filename) for later
for ($i = 1; $i <= $mastersCount; $i++) {
    $name = "test-master-{$i}.local";
    $filename = "db.test-master-{$i}.local";
    $serial = soa_serial($i);
    // valid BIND content for master zone with $ORIGIN and SOA/NS and ns1 A
    $content = "";
    $content .= "\$ORIGIN {$name}.\n";
    $content .= "\$TTL 3600\n";
    $content .= "@ IN SOA ns1.{$name}. admin.{$name}. ( {$serial} 3600 1800 604800 86400 )\n";
    $content .= "    IN NS ns1.{$name}.\n";
    $nsIp = "192.0.2." . ($i % 250 + 1);
    $content .= "ns1 IN A {$nsIp}\n";
    // includes will be appended later once includes are created and linked
    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':file_type' => 'master',
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $zoneId = (int)$pdo->lastInsertId();
    $masterIds[] = $zoneId;
    $masterMeta[$zoneId] = ['name'=>$name,'filename'=>$filename,'serial'=>$serial];
    if ($i % 10 == 0) echo "  -> {$i} masters cré©³\n";
}
echo "Masters cré©³: " . count($masterIds) . "\n";

// 2) Create include zones
$includeIds = [];
$includeMeta = []; // store filename and sample content
for ($j = 1; $j <= $includesCount; $j++) {
    $name = "common-include-{$j}.inc.local"; // logical name for the include file
    // choose a filename that looks like an include file used by $INCLUDE directive
    $filename = "includes/common-include-{$j}.inc"; // path-like; generation uses this name
    // Build include content: records are relative to the master zone when included,
    // so we take care to use relative names (no $ORIGIN) or explicit FQDN if needed.
    $content = "; Include file for common records group {$j}\n";
    // Add some sample records that are valid when included (relative names)
    $content .= "monitor IN A 198.51." . ($j % 250) . ".10\n";
    $content .= "monitor6 IN AAAA 2001:db8::" . dechex(100 + $j) . "\n";
    $content .= "common-txt IN TXT \"include-group-{$j}\"\n";
    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':file_type' => 'include',
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $incId = (int)$pdo->lastInsertId();
    $includeIds[] = $incId;
    $includeMeta[$incId] = ['name'=>$name,'filename'=>$filename];
    if ($j % 10 == 0) echo "  -> {$j} includes cré©³\n";
}
echo "Includes cré©³: " . count($includeIds) . "\n";

// 3) Link includes to masters (zone_file_includes) and append $INCLUDE to parent content
if (!empty($includeIds)) {
    $insertIncludeStmt = $pdo->prepare("INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)");
    $updateMasterContentStmt = $pdo->prepare("UPDATE zone_files SET content = CONCAT(content, :append) WHERE id = :id");
    $pos = 0;
    foreach ($includeIds as $incId) {
        // choose a random master as parent
        $parent = $masterIds[array_rand($masterIds)];
        $pos++;
        try {
            $insertIncludeStmt->execute([
                ':parent_id' => $parent,
                ':include_id' => $incId,
                ':position' => $pos,
                ':created_at' => now()
            ]);
        } catch (Exception $e) {
            // ignore uniqueness errors
        }

        // Append a $INCLUDE directive to the parent content using the include filename
        // Use the exact filename stored in the include (it may include a path)
        $incFilename = $includeMeta[$incId]['filename'];
        // The include directive must be on its own line; ensure proper format
        $append = "\n\$INCLUDE {$incFilename}\n";
        $updateMasterContentStmt->execute([
            ':append' => $append,
            ':id' => $parent
        ]);
    }
    echo "Includes lié³ aux masters et directives \$INCLUDE ajouté¥³.\n";
}

// 4) Detect compatibility columns in dns_records
// Check for optional legacy columns: zone, zone_name, zone_file_name, zone_file
$compatColumns = [];
$columnsStmt = $pdo->query("SHOW COLUMNS FROM dns_records");
$columns = $columnsStmt->fetchAll(PDO::FETCH_ASSOC);
foreach ($columns as $col) {
    $colName = $col['Field'];
    if (in_array($colName, ['zone', 'zone_name', 'zone_file_name', 'zone_file'])) {
        $compatColumns[] = $colName;
    }
}
if (!empty($compatColumns)) {
    echo "Detected compatibility columns in dns_records: " . implode(', ', $compatColumns) . "\n";
} else {
    echo "No compatibility columns detected (zone_file_id only mode).\n";
}

// Cache zone metadata for compatibility column population
$zoneMetadata = [];
if (!empty($compatColumns)) {
    $allZoneInfoStmt = $pdo->prepare("SELECT id, name, filename FROM zone_files");
    $allZoneInfoStmt->execute();
    while ($row = $allZoneInfoStmt->fetch(PDO::FETCH_ASSOC)) {
        $zoneMetadata[(int)$row['id']] = [
            'name' => $row['name'],
            'filename' => $row['filename']
        ];
    }
    echo "Cached metadata for " . count($zoneMetadata) . " zones for compatibility columns.\n";
}

// 5) Prepare dns_records insert
$insertRecordStmt = $pdo->prepare(
    "INSERT INTO dns_records (zone_file_id, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, requester, status, created_by, created_at, updated_at)
     VALUES (:zone_file_id, :record_type, :name, :value, :address_ipv4, :address_ipv6, :cname_target, :ptrdname, :txt, :ttl, :priority, :requester, :status, :created_by, :created_at, :updated_at)"
);

// supported types by UI
$types = ['A','AAAA','CNAME','PTR','TXT'];
if ($enableMx) $types[] = 'MX';

// choose target zone ids (both masters and includes)
$allZoneIds = array_merge($masterIds, $includeIds);
if (empty($allZoneIds)) {
    fwrite(STDERR, "Erreur: aucune zone trouvé¥ pour insé²¥r des enregistrements.\n");
    exit(1);
}

// Get master names to use as possible CNAME targets
$masterNamesStmt = $pdo->prepare("SELECT id, name FROM zone_files WHERE file_type = 'master' LIMIT 1000");
$masterNamesStmt->execute();
$masterNameRows = $masterNamesStmt->fetchAll(PDO::FETCH_ASSOC);
$masterNames = array_map(function($r){ return $r['name']; }, $masterNameRows);

// create records
for ($r = 1; $r <= $recordsCount; $r++) {
    // pick random zone; bias: more records in masters than in includes (70/30)
    if (!empty($includeIds) && rand(1,100) <= 30) {
        $zoneId = $includeIds[array_rand($includeIds)];
    } else {
        $zoneId = $masterIds[array_rand($masterIds)];
    }

    $type = $types[array_rand($types)];
    $name = '';
    $value = '';
    $addr4 = null;
    $addr6 = null;
    $cname = null;
    $ptr = null;
    $txt = null;
    $priority = null;

    switch ($type) {
        case 'A':
            $addr4 = "198.51." . rand(0,255) . "." . rand(1,254);
            $value = $addr4;
            $name = "host{$r}";
            break;
        case 'AAAA':
            $addr6 = "2001:db8::" . dechex(rand(1, 0xffff));
            $value = $addr6;
            $name = "host{$r}";
            break;
        case 'CNAME':
            $target = count($masterNames) ? $masterNames[array_rand($masterNames)] : "alias.example.com.";
            // target should be FQDN; ensure trailing dot
            $cname = rtrim($target, '.') . '.';
            $value = $cname;
            $name = "cname{$r}";
            break;
        case 'PTR':
            $ptr = "ptr{$r}.in-addr.arpa.";
            $value = $ptr;
            $name = "ptr{$r}";
            break;
        case 'TXT':
            $txt = "test-txt-{$r}";
            $value = $txt;
            $name = "txt{$r}";
            break;
        case 'MX':
            $priority = rand(0,20);
            $value = "{$priority} mail" . rand(1,50) . ".example.com.";
            $name = "@";
            break;
        default:
            $value = "value{$r}";
            $name = "rec{$r}";
            break;
    }

    $params = [
        ':zone_file_id' => $zoneId,
        ':record_type' => $type,
        ':name' => $name,
        ':value' => $value,
        ':address_ipv4' => $addr4,
        ':address_ipv6' => $addr6,
        ':cname_target' => $cname,
        ':ptrdname' => $ptr,
        ':txt' => $txt,
        ':ttl' => 3600,
        ':priority' => $priority,
        ':requester' => null,
        ':status' => 'active',
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now(),
    ];

    // Execute insert
    $insertRecordStmt->execute($params);
    $recordId = (int)$pdo->lastInsertId();

    // Populate compatibility columns if they exist
    if (!empty($compatColumns) && isset($zoneMetadata[$zoneId])) {
        $zoneInfo = $zoneMetadata[$zoneId];
        
        // Build UPDATE statement dynamically based on detected columns
        $updateParts = [];
        $updateParams = [];
        
        foreach ($compatColumns as $compatCol) {
            if ($compatCol === 'zone' || $compatCol === 'zone_name') {
                // Populate with zone_files.name
                $updateParts[] = "{$compatCol} = ?";
                $updateParams[] = $zoneInfo['name'];
            } elseif ($compatCol === 'zone_file_name' || $compatCol === 'zone_file') {
                // Populate with zone_files.filename
                $updateParts[] = "{$compatCol} = ?";
                $updateParams[] = $zoneInfo['filename'];
            }
        }
        
        if (!empty($updateParts)) {
            $updateParams[] = $recordId;
            $updateSql = "UPDATE dns_records SET " . implode(', ', $updateParts) . " WHERE id = ?";
            $updateStmt = $pdo->prepare($updateSql);
            $updateStmt->execute($updateParams);
        }
    }

    if ($r % 100 == 0) echo "  -> {$r} enregistrements cré©³\n";
}

echo "Terminé º {$recordsCount} enregistrements insé²©s pour " . (count($masterIds)+count($includeIds)) . " zones ({$mastersCount} masters, {$includesCount} includes).\n";
