<?php
// Générateur de jeu de test (zones master + include, enregistrements pour masters/includes)
// Usage : php scripts/generate_test_data.php --zones=50 --masters=40 --includes=10 --records=1000 --user=1
// Si --masters/--includes omis, on split 80% masters / 20% includes.
// Ne pas exécuter en production sans backup.

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

// Prepare zone insert
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, 'active', :created_by, :created_at, :updated_at)"
);

// 1) Create master zones
$masterIds = [];
for ($i = 1; $i <= $mastersCount; $i++) {
    $name = "test-master-{$i}.local";
    $filename = "db.test-master-{$i}.local";
    $content = "; Master zone $name\n\$TTL 3600\n@ IN SOA ns1.$name. admin.$name. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; example NS\nns1 IN A 192.0.2." . ($i % 254 + 1) . "\n";
    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':file_type' => 'master',
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $masterIds[] = (int)$pdo->lastInsertId();
    if ($i % 10 == 0) echo "  -> {$i} masters créés\n";
}
echo "Masters créés: " . count($masterIds) . "\n";

// 2) Create include zones
$includeIds = [];
for ($j = 1; $j <= $includesCount; $j++) {
    $name = "common-include-{$j}.inc.local";
    $filename = "include.common-{$j}.conf";
    $content = "; Include file $name\n; common records for group $j\n";
    // Put some sample records inside include content
    $content .= "www IN A 198.51." . ($j % 254) . ".1\n";
    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':file_type' => 'include',
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $includeIds[] = (int)$pdo->lastInsertId();
    if ($j % 10 == 0) echo "  -> {$j} includes créés\n";
}
echo "Includes créés: " . count($includeIds) . "\n";

// 3) Link includes to masters (zone_file_includes)
if (!empty($includeIds)) {
    $insertIncludeStmt = $pdo->prepare("INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)");
    $pos = 0;
    foreach ($includeIds as $incId) {
        // choose a random master as parent
        $parent = $masterIds[array_rand($masterIds)];
        $pos++;
        // guard uniqueness: try/catch duplicate key
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
    }
    echo "Includes liés aux masters.\n";
}

// 4) Prepare dns_records insert (columns existants are known from schema)
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
    fwrite(STDERR, "Erreur: aucune zone trouvée pour insérer des enregistrements.\n");
    exit(1);
}

// Seed some values for CNAME targets - use master names
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
            // choose a target from master names if available else use example target
            $target = count($masterNames) ? $masterNames[array_rand($masterNames)] : "alias.example.com.";
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

    $insertRecordStmt->execute($params);

    if ($r % 100 == 0) echo "  -> {$r} enregistrements créés\n";
}

echo "Terminé : {$recordsCount} enregistrements insérés pour " . (count($masterIds)+count($includeIds)) . " zones ({$mastersCount} masters, {$includesCount} includes).\n";
