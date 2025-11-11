<?php
/**
 * Générateur déterministe de test : masters -> L1 (100) -> L2 (10 per L1) -> L3 (10 per L2)
 * Tous les includes (L1/L2/L3) reçoivent N enregistrements (par défaut 5).
 *
 * Usage (exemple petit) :
 * php scripts/generate_test_data.php --masters=1 --records-per-include=1 --user=1
 *
 * Usage pour le jeu complet demandé (ATTENTION volumétrie énorme) :
 * php scripts/generate_test_data.php --masters=30 --records-per-include=5 --user=1
 *
 * Options :
 * --masters                Nombre de masters (défaut 30)
 * --records-per-include    Nombre d'enregistrements par include (défaut 5)
 * --user                   user_id pour created_by (défaut 1)
 * --batch-size             log / commit frequency (défaut 500)
 *
 * IMPORTANT :
 * - Sauvegarde la base avant exécution (mysqldump).
 * - Tester en staging avec de petits paramètres.
 * - Ce script crée systématiquement : pour chaque master 100 L1; pour chaque L1 10 L2; pour chaque L2 10 L3.
 */

require_once __DIR__ . '/../includes/db.php';

$options = getopt("", ["masters::", "records-per-include::", "user::", "batch-size::"]);

$mastersCount = isset($options['masters']) ? max(1, (int)$options['masters']) : 10;
$recordsPerInclude = isset($options['records-per-include']) ? max(0, (int)$options['records-per-include']) : 5;
$userId = isset($options['user']) ? (int)$options['user'] : 1;
$batchSize = isset($options['batch-size']) ? max(1, (int)$options['batch-size']) : 500;

/* Fixed tree shape as requested */
$L1_PER_MASTER = 100;
$L2_PER_L1 = 5;
$L3_PER_L2 = 2;

echo "Config: masters={$mastersCount}, L1_per_master={$L1_PER_MASTER}, L2_per_L1={$L2_PER_L1}, L3_per_L2={$L3_PER_L2}, recordsPerInclude={$recordsPerInclude}, user={$userId}\n";

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

function now() { return date('Y-m-d H:i:s'); }
function make_master_domain($i) { return "root{$i}.example.test"; }

// Prepared statements
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, domain, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, :domain, 'active', :created_by, :created_at, :updated_at)"
);

$insertIncludeLinkStmt = $pdo->prepare(
    "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)"
);

$insertIncludeLinkNewStmt = $pdo->prepare(
    "INSERT INTO zone_file_includes_new (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)"
);

$updateContentStmt = $pdo->prepare("UPDATE zone_files SET content = CONCAT(COALESCE(content, ''), :append) WHERE id = :id");

$insertRecordStmt = $pdo->prepare(
    "INSERT INTO dns_records
     (zone_file_id, record_type, name, value, address_ipv4, address_ipv6, cname_target, ptrdname, txt, ttl, priority, requester, status, created_by, created_at, updated_at)
     VALUES
     (:zone_file_id, :record_type, :name, :value, :address_ipv4, :address_ipv6, :cname_target, :ptrdname, :txt, :ttl, :priority, :requester, :status, :created_by, :created_at, :updated_at)"
);

// Counters
$totalMasters = 0;
$totalL1 = 0;
$totalL2 = 0;
$totalL3 = 0;
$totalIncludes = 0;
$totalRecords = 0;

echo "Starting generation...\n";

for ($m = 1; $m <= $mastersCount; $m++) {
    $pdo->beginTransaction();
    try {
        $masterDomain = make_master_domain($m);
        $masterName = $masterDomain;
        $masterFilename = "db." . str_replace('.', '_', $masterDomain) . ".db";
        $serial = date('Ymd') . sprintf('%02d', $m % 100);

        $masterContent = "";
        $masterContent .= "\$ORIGIN {$masterDomain}.\n";
        $masterContent .= "\$TTL 3600\n";
        $masterContent .= "@ IN SOA ns1.{$masterDomain}. admin.{$masterDomain}. ( {$serial} 3600 1800 604800 86400 )\n";
        $masterContent .= "    IN NS ns1.{$masterDomain}.\n";
        $masterContent .= "ns1 IN A 192.0.2." . ($m % 250 + 1) . "\n";

        // create master
        $insertZoneStmt->execute([
            ':name' => $masterName,
            ':filename' => $masterFilename,
            ':content' => $masterContent,
            ':file_type' => 'master',
            ':domain' => $masterDomain,
            ':created_by' => $userId,
            ':created_at' => now(),
            ':updated_at' => now()
        ]);
        $masterId = (int)$pdo->lastInsertId();
        $totalMasters++;

        // create L1 includes and their subtrees
        for ($i1 = 1; $i1 <= $L1_PER_MASTER; $i1++) {
            // create L1 include
            $l1Name = "inc_m{$m}_l1_{$i1}";
            $safeDir = str_replace('.', '_', $masterDomain);
            $l1Filename = "includes/{$safeDir}/{$l1Name}.inc";
            $l1Content = "; L1 include {$l1Name} for {$masterDomain}\n";
            $l1Content .= "l1host IN A 198.51." . ($i1 % 250) . "." . (($m + $i1) % 250) . "\n";

            $insertZoneStmt->execute([
                ':name' => $l1Name,
                ':filename' => $l1Filename,
                ':content' => $l1Content,
                ':file_type' => 'include',
                ':domain' => null,
                ':created_by' => $userId,
                ':created_at' => now(),
                ':updated_at' => now()
            ]);
            $l1Id = (int)$pdo->lastInsertId();
            $totalL1++;

            // link L1 -> master
            try {
                $insertIncludeLinkStmt->execute([
                    ':parent_id' => $masterId,
                    ':include_id' => $l1Id,
                    ':position' => $i1,
                    ':created_at' => now()
                ]);
            } catch (Exception $e) {
                error_log("Warning: link L1 failed parent={$masterId} include={$l1Id} : " . $e->getMessage());
            }
            try {
                $insertIncludeLinkNewStmt->execute([
                    ':parent_id' => $masterId,
                    ':include_id' => $l1Id,
                    ':position' => $i1,
                    ':created_at' => now()
                ]);
            } catch (Exception $e) {
                // ignore
            }

            // append $INCLUDE to master content
            try {
                $updateContentStmt->execute([':append' => "\n\$INCLUDE {$l1Filename}\n", ':id' => $masterId]);
            } catch (Exception $e) {
                error_log("Warning: append INCLUDE to master failed for masterId={$masterId} : " . $e->getMessage());
            }

            // create L2 under this L1
            for ($i2 = 1; $i2 <= $L2_PER_L1; $i2++) {
                $l2Name = "inc_m{$m}_l1_{$i1}_l2_{$i2}";
                $l2Filename = "includes/{$safeDir}/{$l2Name}.inc";
                $l2Content = "; L2 {$l2Name}\n";
                $l2Content .= "l2host IN A 203.0.113." . ($i2 % 250) . "\n";

                $insertZoneStmt->execute([
                    ':name' => $l2Name,
                    ':filename' => $l2Filename,
                    ':content' => $l2Content,
                    ':file_type' => 'include',
                    ':domain' => null,
                    ':created_by' => $userId,
                    ':created_at' => now(),
                    ':updated_at' => now()
                ]);
                $l2Id = (int)$pdo->lastInsertId();
                $totalL2++;

                // link L2 -> L1
                try {
                    $insertIncludeLinkStmt->execute([
                        ':parent_id' => $l1Id,
                        ':include_id' => $l2Id,
                        ':position' => $i2,
                        ':created_at' => now()
                    ]);
                } catch (Exception $e) {
                    error_log("Warning: link L2 failed parent={$l1Id} include={$l2Id} : " . $e->getMessage());
                }
                try {
                    $insertIncludeLinkNewStmt->execute([
                        ':parent_id' => $l1Id,
                        ':include_id' => $l2Id,
                        ':position' => $i2,
                        ':created_at' => now()
                    ]);
                } catch (Exception $e) { /* ignore */ }

                // append $INCLUDE to L1 content (so resolution L1 -> L2)
                try {
                    $updateContentStmt->execute([':append' => "\n\$INCLUDE {$l2Filename}\n", ':id' => $l1Id]);
                } catch (Exception $e) {
                    error_log("Warning: append INCLUDE to L1 failed for id={$l1Id} : " . $e->getMessage());
                }

                // create L3 under this L2
                for ($i3 = 1; $i3 <= $L3_PER_L2; $i3++) {
                    $l3Name = "inc_m{$m}_l1_{$i1}_l2_{$i2}_l3_{$i3}";
                    $l3Filename = "includes/{$safeDir}/{$l3Name}.inc";
                    $l3Content = "; L3 {$l3Name}\n";
                    $l3Content .= "l3host IN A 198.51." . (($i3 + $i2) % 250) . "." . (($m + $i3) % 250) . "\n";

                    $insertZoneStmt->execute([
                        ':name' => $l3Name,
                        ':filename' => $l3Filename,
                        ':content' => $l3Content,
                        ':file_type' => 'include',
                        ':domain' => null,
                        ':created_by' => $userId,
                        ':created_at' => now(),
                        ':updated_at' => now()
                    ]);
                    $l3Id = (int)$pdo->lastInsertId();
                    $totalL3++;

                    // link L3 -> L2
                    try {
                        $insertIncludeLinkStmt->execute([
                            ':parent_id' => $l2Id,
                            ':include_id' => $l3Id,
                            ':position' => $i3,
                            ':created_at' => now()
                        ]);
                    } catch (Exception $e) {
                        error_log("Warning: link L3 failed parent={$l2Id} include={$l3Id} : " . $e->getMessage());
                    }
                    try {
                        $insertIncludeLinkNewStmt->execute([
                            ':parent_id' => $l2Id,
                            ':include_id' => $l3Id,
                            ':position' => $i3,
                            ':created_at' => now()
                        ]);
                    } catch (Exception $e) { /* ignore */ }

                    // append $INCLUDE to L2 content
                    try {
                        $updateContentStmt->execute([':append' => "\n\$INCLUDE {$l3Filename}\n", ':id' => $l2Id]);
                    } catch (Exception $e) {
                        error_log("Warning: append INCLUDE to L2 failed for id={$l2Id} : " . $e->getMessage());
                    }

                    // insert records for this L3 (recordsPerInclude)
                    for ($r = 1; $r <= $recordsPerInclude; $r++) {
                        $addr4 = "198.51." . rand(0,255) . "." . rand(1,254);
                        $params = [
                            ':zone_file_id' => $l3Id,
                            ':record_type' => 'A',
                            ':name' => "host{$r}",
                            ':value' => $addr4,
                            ':address_ipv4' => $addr4,
                            ':address_ipv6' => null,
                            ':cname_target' => null,
                            ':ptrdname' => null,
                            ':txt' => null,
                            ':ttl' => 3600,
                            ':priority' => null,
                            ':requester' => null,
                            ':status' => 'active',
                            ':created_by' => $userId,
                            ':created_at' => now(),
                            ':updated_at' => now()
                        ];
                        $insertRecordStmt->execute($params);
                        $totalRecords++;
                    }
                } // end L3 loop

                // insert records for L2
                for ($r = 1; $r <= $recordsPerInclude; $r++) {
                    $addr4 = "198.51." . rand(0,255) . "." . rand(1,254);
                    $params = [
                        ':zone_file_id' => $l2Id,
                        ':record_type' => 'A',
                        ':name' => "host{$r}",
                        ':value' => $addr4,
                        ':address_ipv4' => $addr4,
                        ':address_ipv6' => null,
                        ':cname_target' => null,
                        ':ptrdname' => null,
                        ':txt' => null,
                        ':ttl' => 3600,
                        ':priority' => null,
                        ':requester' => null,
                        ':status' => 'active',
                        ':created_by' => $userId,
                        ':created_at' => now(),
                        ':updated_at' => now()
                    ];
                    $insertRecordStmt->execute($params);
                    $totalRecords++;
                }

            } // end L2 loop

            // insert records for L1
            for ($r = 1; $r <= $recordsPerInclude; $r++) {
                $addr4 = "198.51." . rand(0,255) . "." . rand(1,254);
                $params = [
                    ':zone_file_id' => $l1Id,
                    ':record_type' => 'A',
                    ':name' => "host{$r}",
                    ':value' => $addr4,
                    ':address_ipv4' => $addr4,
                    ':address_ipv6' => null,
                    ':cname_target' => null,
                    ':ptrdname' => null,
                    ':txt' => null,
                    ':ttl' => 3600,
                    ':priority' => null,
                    ':requester' => null,
                    ':status' => 'active',
                    ':created_by' => $userId,
                    ':created_at' => now(),
                    ':updated_at' => now()
                ];
                $insertRecordStmt->execute($params);
                $totalRecords++;
            }

            // optional: commit in batches to avoid very large transactions (we keep outer per-master transaction)
            if (($totalL1 + $totalL2 + $totalL3) % $batchSize == 0) {
                $pdo->commit();
                $pdo->beginTransaction();
            }
        } // end L1 loop

        $pdo->commit();
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Transaction failed for master {$m}: " . $e->getMessage());
        // continue with next master
    }

    echo "Master {$m} done: cumulative includes L1={$totalL1}, L2={$totalL2}, L3={$totalL3}, records={$totalRecords}\n";
} // end masters loop

$totalIncludes = $totalL1 + $totalL2 + $totalL3;

echo "GENERATED SUMMARY:\n";
echo " Masters created: {$totalMasters}\n";
echo " L1 includes: {$totalL1}\n";
echo " L2 includes: {$totalL2}\n";
echo " L3 includes: {$totalL3}\n";
echo " Total includes: {$totalIncludes}\n";
echo " Total DNS records inserted: {$totalRecords}\n";
echo "Done.\n";
?>
