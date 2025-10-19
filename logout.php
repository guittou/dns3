<?php
require_once 'config.php';
require_once 'includes/auth.php';

$auth = new Auth();
$auth->logout();

header('Location: ' . BASE_URL . 'login.php?logout=1');
exit;
?>
