<?php
/**
 * Générateur corrigé : crée masters, includes liés, chains nested includes et enregistrements.
 *
 * Usage example (test) :
 * php scripts/generate_test_data.php --masters=2 --includes-per-master=5 --nested-levels=1 --records-per-include=2 --user=1
 *
 * WARNING: volumétrie élevée possible. Faire un dump avant exécution.
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

$mastersCount = isset($options['masters']) ? max(1, (int)$options['masters']) : 10;
$includesPerMaster = isset($options['includes-per-master']) ? max(0, (int)$options['includes-per-master']) : 100;
$nestedLevels = isset($options['nested-levels']) ? max(0, (int)$options['nested-levels']) : 3;
$recordsPerInclude = isset($options['records-per-include']) ? max(0, (int)$options['records-per-include']) : 5;
$userId = isset($options['user']) ? (int)$options['user'] : 1;
$batchSize = isset($options['batch-size']) ? max(1, (int)$options['batch-size']) : 500;

echo "Config: masters={$mastersCount}, includesPerMaster={$includesPerMaster}, nestedLevels={$nestedLevels}, recordsPerInclude={$recordsPerInclude}, user={$userId}, batchSize={$batchSize}\n";

$pdo = Database::getInstance()->getConnection();
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

function now() {
    return date('Y-m-d H:i:s');
}

function make_master_domain($index) {
    return "root{$index}.example.test";
}

/**
 * Prepared statements
 */
$insertZoneStmt = $pdo->prepare(
    "INSERT INTO zone_files (name, filename, content, file_type, domain, status, created_by, created_at, updated_at)
     VALUES (:name, :filename, :content, :file_type, :domain, 'active', :created_by, :created_at, :updated_at)"
);

$insertZoneFileIncludesStmt = $pdo->prepare(
    "INSERT INTO zone_file_includes (parent_id, include_id, position, created_at) VALUES (:parent_id, :include_id, :position, :created_at)"
);

$insertZoneFileIncludesNewStmt = $pdo->prepare(
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
$masterIds = [];
$topIncludes = 0;
$nestedIncludes = 0;
$recordsInserted = 0;

echo "Creating {$mastersCount} masters...\n";
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
 * For each master: create includes, link them to the master and create nested chains linked to the includes.
 * Use transaction per master to keep consistency and make debugging easier.
 */
echo "Creating includes and linking them to masters (and nested includes)...\n";
$globalIncludeCounter = 0;
foreach ($masterIds as $idx => $masterId) {
    $mi = $idx + 1;
    $masterDomain = make_master_domain($mi);
    $safeDir = str_replace('.', '_', $masterDomain);

    // Start transaction for this master
    $pdo->beginTransaction();
    try {
        for ($inc = 1; $inc <= $includesPerMaster; $inc++) {
            $globalIncludeCounter++;
            $incName = "inc_{$mi}_{$inc}";
            $incFilename = "includes/{$safeDir}/inc_{$inc}.inc";
            $incContent = "; Include {$incName} for {$masterDomain}\n";
            $incContent .= "monitor IN A 198.51." . ($inc % 250) . "." . (($mi + $inc) % 250) . "\n";
            $incContent .= "txt-{$inc} IN TXT \"include-{$incName}\"\n";

            // Insert include
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
            $topIncludes++;

            // Link include -> master in BOTH tables (if unique constraints, ignore duplicate errors)
            try {
                $insertZoneFileIncludesStmt->execute([
                    ':parent_id' => $masterId,
                    ':include_id' => $incId,
                    ':position' => $inc,
                    ':created_at' => now()
                ]);
            } catch (Exception $e) {
                // log but continue
                error_log("Warning: failed to insert into zone_file_includes parent={$masterId} include={$incId} : " . $e->getMessage());
            }

            try {
                $insertZoneFileIncludesNewStmt->execute([
                    ':parent_id' => $masterId,
                    ':include_id' => $incId,
                    ':position' => $inc,
                    ':created_at' => now()
                ]);
            } catch (Exception $e) {
                // log but continue
                error_log("Warning: failed to insert into zone_file_includes_new parent={$masterId} include={$incId} : " . $e->getMessage());
            }

            // Append $INCLUDE directive to master content
            try {
                $updateContentStmt->execute([':append' => "\n\$INCLUDE {$incFilename}\n", ':id' => $masterId]);
            } catch (Exception $e) {
                error_log("Warning: failed to append INCLUDE to master {$masterId}: " . $e->getMessage());
            }

            // Create nested chain deterministically under this include
            $parentForNested = $incId;
            for ($level = 1; $level <= $nestedLevels; $level++) {
                $nestedName = "inc_{$mi}_{$inc}_lvl{$level}";
                $nestedFilename = "includes/{$safeDir}/inc_{$inc}_lvl{$level}.inc";
                $nestedContent = "; Nested level {$level} for {$incName}\n";
                $nestedContent .= "nested{$level} IN A 203.0.113." . (($globalIncludeCounter + $level) % 250) . "\n";
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
                $nestedIncludes++;

                // Link nested include to its parent (which can be include)
                try {
                    $insertZoneFileIncludesStmt->execute([
                        ':parent_id' => $parentForNested,
                        ':include_id' => $nestedId,
                        ':position' => 1,
                        ':created_at' => now()
                    ]);
                } catch (Exception $e) {
                    error_log("Warning: failed to insert into zone_file_includes parent={$parentForNested} include={$nestedId} : " . $e->getMessage());
                }

                try {
                    $insertZoneFileIncludesNewStmt->execute([
                        ':parent_id' => $parentForNested,
                        ':include_id' => $nestedId,
                        ':position' => 1,
                        ':created_at' => now()
                    ]);
                } catch (Exception $e) {
                    error_log("Warning: failed to insert into zone_file_includes_new parent={$parentForNested} include={$nestedId} : " . $e->getMessage());
                }

                // Append $INCLUDE to parent include content
                try {
                    $updateContentStmt->execute([':append' => "\n\$INCLUDE {$nestedFilename}\n", ':id' => $parentForNested]);
                } catch (Exception $e) {
                    error_log("Warning: failed to append INCLUDE to parent include {$parentForNested}: " . $e->getMessage());
                }

                // Next parent becomes this nested include
                $parentForNested = $nestedId;
            } // end nested chain
        } // end includes loop

        // Commit transaction for this master
        $pdo->commit();
    } catch (Exception $txe) {
        $pdo->rollBack();
        error_log("Transaction rolled back for master {$masterId}: " . $txe->getMessage());
        // continue to next master
    }

    if (($globalIncludeCounter) % 500 == 0) {
        echo "  -> {$globalIncludeCounter} top-level includes created overall...\n";
    }

    echo "Master {$mi}: created {$includesPerMaster} includes (+ {$nestedLevels} nested per include)\n";
} // end masters

$totalIncludes = $topIncludes + $nestedIncludes;
echo "Top-level includes: {$topIncludes}\n";
echo "Nested includes: {$nestedIncludes}\n";
echo "Total includes created: {$totalIncludes}\n";

/**
 * Populate includes with records (only file_type == 'include')
 */
if ($recordsPerInclude > 0) {
    echo "Populating each include with {$recordsPerInclude} records...\n";

    // Fetch include ids
    $stmt = $pdo->query("SELECT id, filename FROM zone_files WHERE file_type = 'include'");
    $includes = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $totalIncludesToPopulate = count($includes);
    echo "Populating {$totalIncludesToPopulate} include files -> estimated records = " . ($totalIncludesToPopulate * $recordsPerInclude) . "\n";

    $types = ['A','AAAA','CNAME','TXT','PTR'];
    $masterNameStmt = $pdo->prepare("SELECT name FROM zone_files WHERE id = :id");

    $batchCounter = 0;
    foreach ($includes as $row) {
        $zoneId = (int)$row['id'];
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
                    $txt = "txt-record-{$r}";
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
    }

    echo "Records inserted: {$recordsInserted}\n";
} else {
    echo "Skipping record insertion (recordsPerInclude = 0)\n";
}

/**
 * Verification: for each master show how many includes are linked
 */
echo "Verifying include links per master (zone_file_includes)...\n";
$checkStmt = $pdo->prepare("SELECT COUNT(*) AS cnt FROM zone_file_includes WHERE parent_id = :parent_id");
foreach ($masterIds as $i => $mid) {
    $checkStmt->execute([':parent_id' => $mid]);
    $res = $checkStmt->fetch(PDO::FETCH_ASSOC);
    $cnt = $res ? (int)$res['cnt'] : 0;
    echo "Master " . ($i+1) . " (id={$mid}) has {$cnt} linked includes in zone_file_includes\n";
}

echo "SUMMARY:\n";
echo " Masters created: " . count($masterIds) . "\n";
echo " Top-level includes: {$topIncludes}\n";
echo " Nested includes: {$nestedIncludes}\n";
echo " Total includes: {$totalIncludes}\n";
echo " Records inserted: {$recordsInserted}\n";
echo "Done.\n";
