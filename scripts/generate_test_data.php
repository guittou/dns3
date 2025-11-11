<?php
/**
 * Générateur de jeu de test mis à jour pour la structure actuelle de la base.
 *
 * Objectif demandé :
 * - 30 domaines racine (masters)
 * - Pour chaque master : ~100 includes
 * - Ajouter jusqu'à 3 niveaux d'include supplémentaires (chaînes imbriquées)
 * - Peupler chaque include (tous les includes créés) avec ~20 enregistrements DNS
 * - Les noms doivent être "parlants" et les domaines valides (labels conformes)
 *
 * Usage :
 * php scripts/generate_test_data.php --masters=30 --includes-per-master=100 --records-per-include=20 --nested-levels=3 --nested-prob=0.1 --user=1
 *
 * Options:
 * --masters               Nombre de masters racine (défaut 30)
 * --includes-per-master   Nombre d'includes par master (défaut 100)
 * --records-per-include   Nombre d'enregistrements par include (défaut 20)
 * --nested-levels         Profondeur additionnelle d'include (défaut 3)
 * --nested-prob           Probabilité (0..1) qu'un include ait une chaîne imbriquée (défaut 0.1)
 * --user                  user_id utilisé pour created_by (défaut 1)
 *
 * ATTENTION : opération destructive potentielle si répétée (créations en base). Tester en staging.
 */

require_once __DIR__ . '/../includes/db.php';

$options = getopt("", ["masters::", "includes-per-master::", "records-per-include::", "nested-levels::", "nested-prob::", "user::"]);

$mastersCount = isset($options['masters']) ? max(1, (int)$options['masters']) : 30;
$includesPerMaster = isset($options['includes-per-master']) ? max(0, (int)$options['includes-per-master']) : 100;
$recordsPerInclude = isset($options['records-per-include']) ? max(0, (int)$options['records-per-include']) : 20;
$nestedLevels = isset($options['nested-levels']) ? max(0, (int)$options['nested-levels']) : 3;
$nestedProb = isset($options['nested-prob']) ? (float)$options['nested-prob'] : 0.1;
$userId = isset($options['user']) ? (int)$options['user'] : 1;

echo "Config: masters={$mastersCount}, includesPerMaster={$includesPerMaster}, recordsPerInclude={$recordsPerInclude}, nestedLevels={$nestedLevels}, nestedProb={$nestedProb}, user={$userId}\n";

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Helpers
function now() {
    return date('Y-m-d H:i:s');
}

function soa_serial($index = 1) {
    return date('Ymd') . sprintf('%02d', $index % 100);
}

// Prepare statements
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, domain, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, :domain, 'active', :created_by, :created_at, :updated_at)"
);

$insertIncludeLinkStmt = $pdo->prepare(
    "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)"
);

// dns_records insert (columns adapted to common schema)
$insertRecordStmt = $pdo->prepare(
    "INSERT INTO dns_records 
     (zone_file_id, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, requester, status, created_by, created_at, updated_at)
     VALUES
     (:zone_file_id, :record_type, :name, :value, :address_ipv4, :address_ipv6, :cname_target, :ptrdname, :txt, :ttl, :priority, :requester, :status, :created_by, :created_at, :updated_at)"
);

// Utility to create a valid domain label
function make_domain($rootIndex) {
    // Use .example.test as safe reserved TLD for testing
    return "root{$rootIndex}.example.test";
}

// Keep track of created zones
$masterIds = [];
$allIncludeIds = []; // mapping masterId => array of include ids (top-level)
$allZoneIds = []; // all zone ids (masters + includes + nested includes)

/**
 * Create a master zone
 */
for ($mi = 1; $mi <= $mastersCount; $mi++) {
    $domain = make_domain($mi);
    $name = $domain; // for master, name == domain
    $filename = "db." . str_replace('.', '_', $domain) . ".db";
    $serial = soa_serial($mi);

    $content = "";
    $content .= "\$ORIGIN {$domain}.\n";
    $content .= "\$TTL 3600\n";
    $content .= "@ IN SOA ns1.{$domain}. admin.{$domain}. ( {$serial} 3600 1800 604800 86400 )\n";
    $content .= "    IN NS ns1.{$domain}.\n";
    $nsIp = "192.0.2." . ($mi % 250 + 1);
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
    $allZoneIds[] = $zoneId;
    $allIncludeIds[$zoneId] = [];

    if ($mi % 5 == 0) echo "Created {$mi} masters...\n";
}
echo "Masters created: " . count($masterIds) . "\n";

/**
 * Create includes per master
 * Also possibly create nested include chains for a subset (nestedProb)
 */
$globalIncludeCounter = 0;
for ($masterIndex = 0; $masterIndex < count($masterIds); $masterIndex++) {
    $masterId = $masterIds[$masterIndex];
    $masterDomain = make_domain($masterIndex + 1);

    // Create top-level includes
    for ($inc = 1; $inc <= $includesPerMaster; $inc++) {
        $globalIncludeCounter++;
        $incName = "inc-{$masterIndex}-{$inc}"; // logical name
        // filename: includes/<masterDomain>/inc-<n>.inc
        $safeDomainDir = str_replace('.', '_', $masterDomain);
        $incFilename = "includes/{$safeDomainDir}/inc_{$inc}.inc";
        $incContent = "; Include file {$incName} for {$masterDomain}\n";
        $incContent .= "monitor IN A 198.51." . ($inc % 250) . "." . (($masterIndex + $inc) % 250) . "\n";
        $incContent .= "monitor6 IN AAAA 2001:db8::" . dechex(100 + ($globalIncludeCounter % 0xffff)) . "\n";
        $incContent .= "txt-{$inc} IN TXT \"include-{$incName}\"\n";

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
        $allIncludeIds[$masterId][] = $incId;
        $allZoneIds[] = $incId;

        // Link include to master (position ordering)
        $position = count($allIncludeIds[$masterId]);
        try {
            $insertIncludeLinkStmt->execute([
                ':parent_id' => $masterId,
                ':include_id' => $incId,
                ':position' => $position,
                ':created_at' => now()
            ]);
        } catch (Exception $e) {
            // ignore duplicates
        }

        // Append $INCLUDE directive to parent master content
        $appendDirective = "\n\$INCLUDE {$incFilename}\n";
        $updateStmt = $pdo->prepare("UPDATE zone_files SET content = CONCAT(content, :append) WHERE id = :id");
        $updateStmt->execute([':append' => $appendDirective, ':id' => $masterId]);

        // Possibly create nested include chains starting from this include
        if ($nestedLevels > 0 && mt_rand() / mt_getrandmax() <= $nestedProb) {
            $parentForNested = $incId;
            for ($level = 1; $level <= $nestedLevels; $level++) {
                // create a nested include file referencing the parent include
                $nestedFilename = "includes/{$safeDomainDir}/inc_{$inc}_lvl{$level}.inc";
                $nestedName = "{$incName}-lvl{$level}";
                $nestedContent = "; Nested include level {$level} for {$incName}\n";
                $nestedContent .= "nested{$level} IN A 203.0.113." . (($globalIncludeCounter + $level) % 250) . "\n";
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
                $allZoneIds[] = $nestedId;

                // Link nested include to its parent include
                try {
                    $insertIncludeLinkStmt->execute([
                        ':parent_id' => $parentForNested,
                        ':include_id' => $nestedId,
                        ':position' => 1,
                        ':created_at' => now()
                    ]);
                } catch (Exception $e) {
                    // ignore duplicates
                }

                // Append $INCLUDE directive in parent include content so resolution works
                $appendToParent = "\n\$INCLUDE {$nestedFilename}\n";
                $updateParentStmt = $pdo->prepare("UPDATE zone_files SET content = CONCAT(content, :append) WHERE id = :id");
                $updateParentStmt->execute([':append' => $appendToParent, ':id' => $parentForNested]);

                // the new nested include becomes parent for next level
                $parentForNested = $nestedId;
            }
        }

        if ($globalIncludeCounter % 500 == 0) {
            echo "Created {$globalIncludeCounter} includes overall...\n";
        }
    } // end includes per master

    echo "Master {$masterIndex}+1 : created " . count($allIncludeIds[$masterId]) . " top-level includes\n";
} // end masters loop

echo "Total includes created (top-level + nested): " . (count($allZoneIds) - count($masterIds)) . "\n";

/**
 * Populate all includes (and masters optionally) with DNS records
 *
 * We'll create records only for includes (file_type == 'include') to match requirement,
 * but you can include masters by iterating master ids too if desired.
 */
$types = ['A','AAAA','CNAME','TXT','PTR'];
$masterNamesStmt = $pdo->prepare("SELECT id, name, filename, file_type FROM zone_files WHERE id IN (" . implode(',', array_map('intval', $allZoneIds)) . ")");
$masterNamesStmt->execute();
$zoneRows = $masterNamesStmt->fetchAll(PDO::FETCH_ASSOC);

// Map zone id => file_type
$zoneInfo = [];
foreach ($zoneRows as $z) {
    $zoneInfo[(int)$z['id']] = $z;
}

// create records for every include (file_type == 'include')
$recordCreated = 0;
foreach ($zoneInfo as $zid => $zmeta) {
    if ($zmeta['file_type'] !== 'include') {
        continue; // skip masters
    }

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
                // point to one of the masters randomly (if any)
                $targetMasterId = $masterIds[array_rand($masterIds)];
                $t = $pdo->prepare("SELECT name FROM zone_files WHERE id = :id");
                $t->execute([':id' => $targetMasterId]);
                $tm = $t->fetch(PDO::FETCH_ASSOC);
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
            ':zone_file_id' => $zid,
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
        $recordCreated++;
    }

    if ($recordCreated % 1000 == 0) {
        echo "Inserted {$recordCreated} records...\n";
    }
}

echo "Done. Masters: " . count($masterIds) . ", Top-level includes total: " . array_reduce($allIncludeIds, function($carry, $arr){ return $carry + count($arr); }, 0) . ", Records inserted: {$recordCreated}\n";
echo "Total zone files (including nested includes): " . count($allZoneIds) . "\n";
