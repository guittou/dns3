<?php
/**
 * Générateur de jeu de test (masters + includes + nested includes + records)
 *
 * Usage :
 * php scripts/generate_test_data.php \
 *   --masters=10 \
 *   --includes-per-master=100 \
 *   --nested-levels=3 \
 *   --records-per-include=50 \
 *   --user=1 \
 *   [--batch-size=500]
 *
 * NOTES:
 * - Par défaut ce script crée des nested includes POUR CHAQUE include (comportement demandé).
 * - ATTENTION : volume élevé (peut créer des centaines de milliers d'enregistrements).
 * - Tester en staging. Faire un dump avant (mysqldump).
 */

require_once __DIR__ . '/../includes/db.php';

$options = getopt("", [
    "masters::",
    "includes-per-master::",
    "nested-levels::",
    "records-per-include::",
    "user::",
    "batch-size::"
]);

$mastersCount = isset($options['masters']) ? max(1, (int)$options['masters']) : 30;
$includesPerMaster = isset($options['includes-per-master']) ? max(0, (int)$options['includes-per-master']) : 100;
$nestedLevels = isset($options['nested-levels']) ? max(0, (int)$options['nested-levels']) : 3; // levels to add under each include
$recordsPerInclude = isset($options['records-per-include']) ? max(0, (int)$options['records-per-include']) : 20;
$userId = isset($options['user']) ? (int)$options['user'] : 1;
$batchSize = isset($options['batch-size']) ? max(1, (int)$options['batch-size']) : 500;

echo "Config: masters={$mastersCount}, includesPerMaster={$includesPerMaster}, nestedLevels={$nestedLevels}, recordsPerInclude={$recordsPerInclude}, user={$userId}, batchSize={$batchSize}\n";

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

function now() {
    return date('Y-m-d H:i:s');
}

/**
 * Helper to build a valid test domain name.
 * We'll use example.test TLD to avoid conflicts.
 */
function make_master_domain($index) {
    return "root{$index}.example.test";
}

/**
 * Prepare statements
 */
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, domain, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, :domain, 'active', :created_by, :created_at, :updated_at)"
);

$insertIncludeLinkStmt = $pdo->prepare(
    "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)"
);

$updateContentStmt = $pdo->prepare("UPDATE zone_files SET content = CONCAT(content, :append) WHERE id = :id");

$insertRecordStmt = $pdo->prepare(
    "INSERT INTO dns_records
     (zone_file_id, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, requester, status, created_by, created_at, updated_at)
     VALUES
     (:zone_file_id, :record_type, :name, :value, :address_ipv4, :address_ipv6, :cname_target, :ptrdname, :txt, :ttl, :priority, :requester, :status, :created_by, :created_at, :updated_at)"
);

/**
 * Statistics counters
 */
$masterIds = [];
$topLevelIncludeCount = 0;
$nestedIncludeCount = 0;
$recordsInserted = 0;

/**
 * Create masters
 */
echo "Creating {$mastersCount} master zones...\n";
for ($m = 1; $m <= $mastersCount; $m++) {
    $domain = make_master_domain($m);
    $name = $domain;
    $filename = "db." . str_replace('.', '_', $domain) . ".db";
    $serial = date('Ymd') . sprintf('%02d', $m % 100);

    $content = "";
    $content .= "\$ORIGIN {$domain}.\n";
    $content .= "\$TTL 3600\n";
    $content .= "@ IN SOA ns1.{$domain}. admin.{$domain}. ( {$serial} 3600 1800 604800 86400 )\n";
    $content .= "    IN NS ns1.{$domain}.\n";
    $nsIp = "192.0.2." . ($m % 250 + 1);
    $content .= "ns1 IN A {$nsIp}\n";

    $insertZoneStmt->execute([
        ':name' => $name,
        ':filename' => $filename,
        ':content' => $content,
        ':file_type' => 'master',
        ':domain' => $domain,
        ':created_by' => $userId,
        ':created_at' => now(),
        ':updated_at' => now()
    ]);
    $zoneId = (int)$pdo->lastInsertId();
    $masterIds[] = $zoneId;

    if ($m % 5 == 0) echo "  -> {$m} masters created\n";
}
echo "Masters created: " . count($masterIds) . "\n";

/**
 * For each master create includes, and for each include create nestedLevels nested includes deterministically.
 * Link includes using zone_file_includes so includes may point to masters or to other includes.
 */
echo "Creating includes and nested includes...\n";
$globalIncCounter = 0;

foreach ($masterIds as $masterIdx => $masterId) {
    $mi = $masterIdx + 1;
    $masterDomain = make_master_domain($mi);
    $safeDir = str_replace('.', '_', $masterDomain);

    for ($inc = 1; $inc <= $includesPerMaster; $inc++) {
        $globalIncCounter++;
        $incName = "inc_{$mi}_{$inc}"; // short, valid label
        $incFilename = "includes/{$safeDir}/inc_{$inc}.inc";
        $incContent = "; Include {$incName} for {$masterDomain}\n";
        $incContent .= "monitor IN A 198.51." . ($inc % 250) . "." . (($mi + $inc) % 250) . "\n";
        $incContent .= "monitor6 IN AAAA 2001:db8::" . dechex(100 + ($globalIncCounter % 0xffff)) . "\n";
        $incContent .= "txt-{$inc} IN TXT \"include-{$incName}\"\n";

        // insert top-level include
        $insertZoneStmt->execute([
            ':name' => $incName,
            ':filename' => $incFilename,
            ':content' => $incContent,
            ':file_type' => 'include',
            ':domain' => null,
            ':created_by' => $userId,
            ':created_at' => now(),
            ':updated_at' => now()
        ]);
        $incId = (int)$pdo->lastInsertId();
        $topLevelIncludeCount++;

        // link include to master
        $position = $inc;
        try {
            $insertIncludeLinkStmt->execute([
                ':parent_id' => $masterId,
                ':include_id' => $incId,
                ':position' => $position,
                ':created_at' => now()
            ]);
        } catch (Exception $e) {
            // ignore duplicates or constraint issues
        }

        // append $INCLUDE directive to master content
        $updateContentStmt->execute([':append' => "\n\$INCLUDE {$incFilename}\n", ':id' => $masterId]);

        // create deterministic nested includes chain under this include
        $parentForNext = $incId;
        for ($level = 1; $level <= $nestedLevels; $level++) {
            $nestedName = "inc_{$mi}_{$inc}_lvl{$level}";
            $nestedFilename = "includes/{$safeDir}/inc_{$inc}_lvl{$level}.inc";
            $nestedContent = "; Nested include level {$level} for {$incName}\n";
            $nestedContent .= "nested{$level} IN A 203.0.113." . (($globalIncCounter + $level) % 250) . "\n";
            $nestedContent .= "txt-nest-{$level} IN TXT \"nested-{$level}-{$incName}\"\n";

            $insertZoneStmt->execute([
                ':name' => $nestedName,
                ':filename' => $nestedFilename,
                ':content' => $nestedContent,
                ':file_type' => 'include',
                ':domain' => null,
                ':created_by' => $userId,
                ':created_at' => now(),
                ':updated_at' => now()
            ]);
            $nestedId = (int)$pdo->lastInsertId();
            $nestedIncludeCount++;

            // link nested include to its parent (which can be an include)
            try {
                $insertIncludeLinkStmt->execute([
                    ':parent_id' => $parentForNext,
                    ':include_id' => $nestedId,
                    ':position' => 1,
                    ':created_at' => now()
                ]);
            } catch (Exception $e) {
                // ignore duplicates
            }

            // append $INCLUDE directive to parent content so resolution can follow the chain
            $updateContentStmt->execute([':append' => "\n\$INCLUDE {$nestedFilename}\n", ':id' => $parentForNext]);

            // next parent becomes this nested include
            $parentForNext = $nestedId;
        }

        if ($globalIncCounter % 500 == 0) {
            echo "  -> {$globalIncCounter} top-level includes created so far...\n";
        }
    } // end includes per master

    echo "Master {$mi}: created {$includesPerMaster} top-level includes (+ nested chain length {$nestedLevels} per include)\n";
} // end masters loop

$totalIncludes = $topLevelIncludeCount + $nestedIncludeCount;
echo "Top-level includes: {$topLevelIncludeCount}\n";
echo "Nested includes: {$nestedIncludeCount}\n";
echo "Total includes (expected to have $nestedLevels nested per top-level include): {$totalIncludes}\n";

if ($recordsPerInclude > 0) {
    echo "Populating includes with {$recordsPerInclude} records each (this may take a while)...\n";

    // Fetch all include ids to populate (only file_type == 'include')
    $stmtIncludes = $pdo->query("SELECT id, filename FROM zone_files WHERE file_type = 'include'");
    $includesRows = $stmtIncludes->fetchAll(PDO::FETCH_ASSOC);
    $totalIncludesToPopulate = count($includesRows);
    echo "Will populate {$totalIncludesToPopulate} include files with {$recordsPerInclude} records each => total records = " . ($totalIncludesToPopulate * $recordsPerInclude) . "\n";

    $types = ['A','AAAA','CNAME','TXT','PTR'];
    $masterNameStmt = $pdo->prepare("SELECT name FROM zone_files WHERE id = :id");

    $batchCounter = 0;
    foreach ($includesRows as $irow) {
        $zoneId = (int)$irow['id'];
        for ($r = 1; $r <= $recordsPerInclude; $r++) {
            $type = $types[array_rand($types)];
            $name = ""; $value = ""; $addr4 = null; $addr6 = null; $cname = null; $ptr = null; $txt = null; $priority = null;

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
                    // point to a random master domain
                    $targetMasterId = $masterIds[array_rand($masterIds)];
                    $masterNameStmt->execute([':id' => $targetMasterId]);
                    $tm = $masterNameStmt->fetch(PDO::FETCH_ASSOC);
                    $target = ($tm && isset($tm['name'])) ? $tm['name'] : "alias.example.test";
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
                default:
                    $txt = "test-txt-{$r}";
                    $value = $txt;
                    $name = "txt{$r}";
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
                ':updated_at' => now()
            ];

            $insertRecordStmt->execute($params);
            $recordsInserted++;
        }

        $batchCounter++;
        if ($batchCounter % $batchSize == 0) {
            echo "  -> inserted {$recordsInserted} records so far...\n";
        }
    } // end includesRows loop

    echo "Records insertion complete. Total records inserted: {$recordsInserted}\n";
} else {
    echo "recordsPerInclude = 0 => skipping records insertion\n";
}

echo "SUMMARY:\n";
echo " Masters created: " . count($masterIds) . "\n";
echo " Top-level includes created: {$topLevelIncludeCount}\n";
echo " Nested includes created: {$nestedIncludeCount}\n";
echo " Total includes: {$totalIncludes}\n";
echo " Records inserted: {$recordsInserted}\n";

$estimatedTotalRecords = $totalIncludes * $recordsPerInclude;
echo "Estimated total records (includes * recordsPerInclude): {$estimatedTotalRecords}\n";

echo "Done. Vérifier la DB et la charge avant d'exécuter en production.\n";
