<?php
/**
 * Access Denied Page Template
 * Displayed when a user attempts to access a page they don't have permission for.
 */
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Accès refusé - <?php echo defined('SITE_NAME') ? htmlspecialchars(SITE_NAME) : 'DNS3'; ?></title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background-color: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
            box-sizing: border-box;
        }
        .error-container {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 40px;
            text-align: center;
            max-width: 500px;
        }
        .error-code {
            font-size: 72px;
            font-weight: bold;
            color: #e74c3c;
            margin: 0;
        }
        .error-title {
            font-size: 24px;
            color: #333;
            margin: 10px 0 20px;
        }
        .error-message {
            color: #666;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        .btn-home {
            display: inline-block;
            padding: 12px 30px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 500;
            transition: background-color 0.2s;
        }
        .btn-home:hover {
            background-color: #2980b9;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <p class="error-code">403</p>
        <h1 class="error-title">Accès refusé</h1>
        <p class="error-message">
            Vous n'avez pas les autorisations nécessaires pour accéder à cette page.<br>
            Si vous pensez que c'est une erreur, veuillez contacter l'administrateur.
        </p>
        <a href="<?php echo defined('BASE_URL') ? htmlspecialchars(BASE_URL) : '/'; ?>" class="btn-home">Retour à l'accueil</a>
    </div>
</body>
</html>
