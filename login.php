<?php
require_once 'config.php';
require_once 'includes/auth.php';

// Initialise l'objet Auth
$auth = new Auth();
$error = '';
$success = '';

// Handle logout via GET parameter (only on GET requests, not POST)
// This prevents the logout from firing when the login form is submitted
// from a URL like login.php?logout=1
if (isset($_GET['logout']) && $_SERVER['REQUEST_METHOD'] === 'GET') {
    $auth->logout();
    $success = 'Vous avez été déconnecté avec succès.';
}

// Redirect if already logged in (and not logout)
if ($auth->isLoggedIn() && !isset($_GET['logout'])) {
    header('Location: ' . BASE_URL . 'dns-management.php');
    exit;
}

// Handle login form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $method = $_POST['auth_method'] ?? 'auto';
    
    if ($username === '' || $password === '') {
        $error = 'Veuillez remplir tous les champs.';
    } else {
        if ($auth->login($username, $password, $method)) {
            header('Location: ' . BASE_URL . 'dns-management.php');
            exit;
        } else {
            // Get error code to display appropriate message
            $errorCode = $auth->getLastError();
            
            switch ($errorCode) {
                case 'no_access':
                    $error = 'Accès refusé : aucun mapping AD/LDAP/ACL ne vous autorise.';
                    break;
                case 'server_unreachable':
                case 'ldap_bind_failed':
                    $error = 'Service d\'authentification indisponible.';
                    break;
                default:
                    $error = 'Identifiants incorrects. Veuillez réessayer.';
                    break;
            }
        }
    }
}

// Inclut le header (ouvre .page-body et <main class="main-content">)
require_once 'includes/header.php';
?>

<div class="login-container">
    <h1>Connexion</h1>

    <?php if ($error): ?>
        <div class="error-message"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>

    <?php if ($success): ?>
        <div class="success-message"><?php echo htmlspecialchars($success); ?></div>
    <?php endif; ?>

    <form method="POST" action="<?php echo htmlspecialchars(BASE_URL . 'login.php'); ?>">
        <div class="form-group">
            <label for="username">Nom d'utilisateur</label>
            <input type="text" id="username" name="username" required autocomplete="username" value="<?php echo isset($_POST['username']) ? htmlspecialchars($_POST['username']) : ''; ?>">
        </div>

        <div class="form-group">
            <label for="password">Mot de passe</label>
            <input type="password" id="password" name="password" required autocomplete="current-password">
        </div>

        <div class="form-group">
            <label for="auth_method">Méthode d'authentification</label>
            <select id="auth_method" name="auth_method">
                <option value="auto"<?php echo (isset($_POST['auth_method']) && $_POST['auth_method'] === 'auto') ? ' selected' : ''; ?>>Automatique</option>
                <option value="database"<?php echo (isset($_POST['auth_method']) && $_POST['auth_method'] === 'database') ? ' selected' : ''; ?>>Base de données</option>
                <option value="ad"<?php echo (isset($_POST['auth_method']) && $_POST['auth_method'] === 'ad') ? ' selected' : ''; ?>>Active Directory</option>
                <option value="ldap"<?php echo (isset($_POST['auth_method']) && $_POST['auth_method'] === 'ldap') ? ' selected' : ''; ?>>OpenLDAP</option>
            </select>
        </div>

        <button type="submit" class="btn btn-submit">Se connecter</button>
    </form>
</div>

<?php
// Inclut le footer (ferme .page-body et rend le footer)
require_once 'includes/footer.php';
