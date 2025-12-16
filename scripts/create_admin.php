<?php
// scripts/create_admin.php
// Usage:
//   php scripts/create_admin.php --username admin --password 'admin123'
// or interactive:
//   php scripts/create_admin.php
//
// This script will INSERT the admin user if missing or UPDATE the password if the user exists.
// It uses password_hash() to generate the bcrypt hash.

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/db.php';

function getArg($name) {
    global $argv;
    foreach ($argv as $i => $arg) {
        if ($arg === $name && isset($argv[$i+1])) return $argv[$i+1];
        if (strpos($arg, $name . '=') === 0) return substr($arg, strlen($name) + 1);
    }
    return null;
}

$username = getArg('--username');
$password = getArg('--password');

if (!$username || !$password) {
    // interactive prompt
    if (!$username) {
        echo "Nom d'utilisateur [admin]: ";
        $line = trim(fgets(STDIN));
        $username = $line !== '' ? $line : 'admin';
    }
    if (!$password) {
        if (function_exists('readline')) {
            $pw = readline("Mot de passe (sera masqué non supporté en readline) : ");
            $password = $pw;
        } else {
            echo "Mot de passe : ";
            $pw = trim(fgets(STDIN));
            $password = $pw;
        }
        if ($password === '') {
            echo "Mot de passe non fourni. Abandon.\n";
            exit(1);
        }
    }
}

try {
    $db = Database::getInstance()->getConnection();
} catch (Exception $e) {
    echo "Erreur de connexion à la base : " . $e->getMessage() . PHP_EOL;
    exit(1);
}

// generate hash
$hash = password_hash($password, PASSWORD_DEFAULT);

// check if user exists
$stmt = $db->prepare("SELECT id FROM users WHERE username = ?");
$stmt->execute([$username]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if ($user) {
    // update
    $stmt = $db->prepare("UPDATE users SET password = ?, auth_method = 'database', is_active = 1 WHERE id = ?");
    $stmt->execute([$hash, $user['id']]);
    echo "Utilisateur '{$username}' mis à jour (mot de passe réinitialisé).\n";
} else {
    // insert
    $stmt = $db->prepare("INSERT INTO users (username, password, auth_method, is_active, created_at) VALUES (?, ?, 'database', 1, NOW())");
    $stmt->execute([$username, $hash]);
    $newId = $db->lastInsertId();
    echo "Utilisateur '{$username}' créé avec l'ID {$newId}.\n";
}

// Optionnel: assigner un rôle admin si les tables roles/user_roles existent
try {
    // detect roles table
    $r = $db->query("SHOW TABLES LIKE 'roles'")->fetch();
    if ($r) {
        // find admin role id
        $stmt = $db->prepare("SELECT id FROM roles WHERE name = 'admin' LIMIT 1");
        $stmt->execute();
        $role = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($role) {
            // find user id
            $stmt = $db->prepare("SELECT id FROM users WHERE username = ? LIMIT 1");
            $stmt->execute([$username]);
            $u = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($u) {
                // insert user_roles if not exists
                $stmt = $db->prepare("SELECT 1 FROM user_roles WHERE user_id = ? AND role_id = ? LIMIT 1");
                $stmt->execute([$u['id'], $role['id']]);
                if (!$stmt->fetch()) {
                    $stmt = $db->prepare("INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES (?, ?, NOW())");
                    $stmt->execute([$u['id'], $role['id']]);
                    echo "Rôle 'admin' attribué à l'utilisateur {$username}.\n";
                } else {
                    echo "L'utilisateur {$username} a déjà le rôle 'admin'.\n";
                }
            }
        } else {
            echo "Table 'roles' présente mais rôle 'admin' introuvable — tu peux l'ajouter manuellement.\n";
        }
    } else {
        echo "Table 'roles' non trouvée : rôle admin non attribué automatiquement.\n";
    }
} catch (Exception $e) {
    echo "Vérification/attribution rôle échouée : " . $e->getMessage() . PHP_EOL;
}

echo "Terminé.\n";
