<?php
require_once 'config.php';
require_once 'includes/auth.php';

// Initialize auth
$auth = new Auth();

// Redirect to dns-management.php if logged in, otherwise redirect to login
if (!$auth->isLoggedIn()) {
    header('Location: ' . BASE_URL . 'login.php');
    exit;
}

// Redirect logged-in users to DNS management page
header('Location: ' . BASE_URL . 'dns-management.php');
exit;
