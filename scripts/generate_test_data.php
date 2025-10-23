<?php
// Génère un jeu de test : N zones et M enregistrements DNS répartis
// Usage : php scripts/generate_test_data.php --zones=50 --records=1000 --user=1

require_once __DIR__ . '/../includes/db.php';

$options = getopt("", ["zones::", "records::", "user::"]);
$zonesCount = isset($options['zones']) ? (int)$options['zones'] : 50;
$recordsCount = isset($options['records']) ? (int)$options['records'] : 1000;
$userId = isset($options['user']) ? (int)$options['user'] : 1;

$pdo = Database::getInstance()->getConnection();

echo "Génération de $zonesCount zones et $recordsCount enregistrements (user_id=$userId)\n";

// Helper pour insertion safe
function now() {
    return date('Y-m-d H:i:s');
}

// 1) Créer zones
$zoneIds = [];
$insertZoneStmt = $pdo->prepare("INSERT INTO zone_files (name, filename, content, file_type, status, created_by, created_at, updated_at) VALUES (:name, :filename, :content, 'master', 'active', :created_by, :created_at, :updated_at)");
for ($i = 1; $i <= $zonesCount; $i++) {
    $name = "test-zone-{$i}.local";
    $filename = "db.test-zone-{$i}.local";
    $content = "; Zone de test $i\n\$TTL 3600\n@ IN SOA ns1.test-zone-{$i}.local. admin.test-zone-{$i}.local. (\n    2025010101 ; serial\n    3600\n    1800\n    604800\n    86400 )\n\n; NS\nns1 IN A 192.0.2." . ($i % 254 + 1) . "\n";
    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $zoneId = (int)$pdo->lastInsertId();
    $zoneIds[] = $zoneId;
    if ($i % 10 == 0) echo "  -> $i zones créées\n";
}
echo "Zones créées: " . count($zoneIds) . "\n";

// 2) Créer enregistrements répartis
$recordTypes = ['A','AAAA','CNAME','TXT','MX'];
$insertRecordStmt = $pdo->prepare("INSERT INTO dns_records (zone_file_id, name, ttl, class, record_type, value, status, created_by, created_at, updated_at) VALUES (:zone_file_id, :name, :ttl, 'IN', :type, :value, 'active', :created_by, :created_at, :updated_at)");

for ($r = 1; $r <= $recordsCount; $r++) {
    // pick random zone
    $zoneIndex = array_rand($zoneIds);
    $zoneId = $zoneIds[$zoneIndex];

    $type = $recordTypes[array_rand($recordTypes)];

    // build simple payload per type
    switch ($type) {
        case 'A':
            $value = "198.51." . rand(0,255) . "." . rand(1,254);
            $name = "host{$r}";
            break;
        case 'AAAA':
            $value = "2001:db8::" . dechex(rand(1, 0xffff));
            $name = "host{$r}";
            break;
        case 'CNAME':
            $value = "alias" . rand(1,500) . ".example.com.";
            $name = "cname{$r}";
            break;
        case 'TXT':
            $value = "test-txt-value-{$r}";
            $name = "txt{$r}";
            break;
        case 'MX':
            $value = rand(0,20) . " mail" . rand(1,50) . ".example.com.";
            $name = "@";
            break;
        default:
            $value = "value{$r}";
            $name = "rec{$r}";
    }

    $insertRecordStmt->execute([
        ':zone_file_id' => $zoneId,
        ':name' => $name,
        ':ttl' => 3600,
        ':type' => $type,
        ':value' => $value,
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);

    if ($r % 100 == 0) echo "  -> $r enregistrements créés\n";
}

echo "Terminé : $recordsCount enregistrements insérés pour $zonesCount zones.\n";
