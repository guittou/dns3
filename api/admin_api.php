<?php
// api/admin_api.php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/models/User.php';

$auth = new Auth();
if (!$auth->isLoggedIn() || !$auth->isAdmin()) {
    http_response_code(403);
    echo json_encode(['error' => 'forbidden']);
    exit;
}

$userModel = new UserModel();
$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    if ($action === 'list_users') {
        $q = $_GET['q'] ?? '';
        $limit = (int)($_GET['limit'] ?? 200);
        $offset = (int)($_GET['offset'] ?? 0);
        $rows = $userModel->list($limit, $offset, $q);
        echo json_encode(['data'=>$rows]);
        exit;
    }

    if ($action === 'get_user') {
        $id = (int)($_GET['id'] ?? 0);
        $u = $userModel->getById($id);
        if (!$u) { http_response_code(404); echo json_encode(['error'=>'not_found']); exit; }
        echo json_encode(['data'=>$u]);
        exit;
    }

    if ($action === 'create_user') {
        // server enforces DB-only user creation
        $payload = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        if (empty($payload['username']) || empty($payload['password'])) {
            http_response_code(400); echo json_encode(['error'=>'username_and_password_required']); exit;
        }
        $payload['auth_method'] = 'database'; // force DB-only
        $id = $userModel->create($payload, $auth->getCurrentUser()['id'] ?? null);
        echo json_encode(['id'=>$id]);
        exit;
    }

    if ($action === 'update_user') {
        $id = (int)($_GET['id'] ?? $_POST['id'] ?? 0);
        $payload = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        // prevent switching to non-db auth via update (unless admin wants otherwise)
        if (isset($payload['auth_method']) && $payload['auth_method'] !== 'database') {
            // ignore or reject — here we force DB only for created users; allow update to keep same
            unset($payload['auth_method']);
        }
        $ok = $userModel->update($id, $payload);
        echo json_encode(['ok'=>(bool)$ok]);
        exit;
    }

    if ($action === 'list_roles') {
        echo json_encode(['data'=>$userModel->listRoles()]);
        exit;
    }

    if ($action === 'list_mappings') {
        $pdo = Database::getInstance()->getConnection();
        $stmt = $pdo->prepare("SELECT am.*, r.name AS role_name FROM auth_mappings am JOIN roles r ON r.id = am.role_id ORDER BY am.created_at DESC");
        $stmt->execute();
        echo json_encode(['data'=>$stmt->fetchAll(PDO::FETCH_ASSOC)]);
        exit;
    }

    if ($action === 'create_mapping') {
        $payload = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $pdo = Database::getInstance()->getConnection();
        $stmt = $pdo->prepare("INSERT INTO auth_mappings (source, dn_or_group, role_id, created_by, notes) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$payload['source'], $payload['dn_or_group'], $payload['role_id'], $auth->getCurrentUser()['id'] ?? null, $payload['notes'] ?? null]);
        echo json_encode(['id'=>$pdo->lastInsertId()]);
        exit;
    }

    if ($action === 'delete_mapping') {
        $id = (int)($_POST['id'] ?? $_GET['id'] ?? 0);
        $pdo = Database::getInstance()->getConnection();
        $stmt = $pdo->prepare("DELETE FROM auth_mappings WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['ok'=>true]);
        exit;
    }

    http_response_code(400);
    echo json_encode(['error'=>'unknown_action']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error'=>$e->getMessage()]);
}
