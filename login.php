<?php
require_once 'config.php';
require_once 'includes/auth.php';

$auth = new Auth();
$error = '';
$success = '';

// Handle logout via GET parameter
if (isset($_GET['logout'])) {
    $auth->logout();
    $success = 'Vous avez été déconnecté avec succès.';
}

// Handle login form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $method = $_POST['auth_method'] ?? 'auto';
    
    if (empty($username) || empty($password)) {
        $error = 'Veuillez remplir tous les champs.';
    } else {
        if ($auth->login($username, $password, $method)) {
            header('Location: ' . BASE_URL . 'index.php');
            exit;
        } else {
            $error = 'Identifiants incorrects. Veuillez réessayer.';
        }
    }
}

// Redirect if already logged in
if ($auth->isLoggedIn() && !isset($_GET['logout'])) {
    header('Location: ' . BASE_URL . 'index.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connexion - <?php echo SITE_NAME; ?></title>
    <link rel="stylesheet" href="<?php echo BASE_URL; ?>assets/css/style.css">
</head>
<body>
    <div class="login-container">
        <h1>Connexion</h1>
        
        <?php if ($error): ?>
            <div class="error-message"><?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>
        
        <?php if ($success): ?>
            <div class="success-message"><?php echo htmlspecialchars($success); ?></div>
        <?php endif; ?>
        
        <form method="POST" action="">
            <div class="form-group">
                <label for="username">Nom d'utilisateur</label>
                <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            
            <div class="form-group">
                <label for="password">Mot de passe</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            
            <div class="form-group">
                <label for="auth_method">Méthode d'authentification</label>
                <select id="auth_method" name="auth_method">
                    <option value="auto">Automatique</option>
                    <option value="database">Base de données</option>
                    <option value="ad">Active Directory</option>
                    <option value="ldap">OpenLDAP</option>
                </select>
            </div>
            
            <button type="submit" class="btn btn-submit">Se connecter</button>
        </form>
        
        <p style="text-align: center; margin-top: 20px;">
            <a href="<?php echo BASE_URL; ?>index.php">Retour à l'accueil</a>
        </p>
    </div>
</body>
</html>
