<?php
// Configuration file for the application

// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'dns3_db');
define('DB_USER', 'dns3_user');
define('DB_PASS', 'dns3_pass');

// Active Directory configuration
define('AD_SERVER', 'ldap://ad.example.com');
define('AD_PORT', 389);
define('AD_BASE_DN', 'DC=example,DC=com');
define('AD_DOMAIN', 'EXAMPLE');

// OpenLDAP configuration
define('LDAP_SERVER', 'ldap://ldap.example.com');
define('LDAP_PORT', 389);
define('LDAP_BASE_DN', 'dc=example,dc=com');
define('LDAP_BIND_DN', 'cn=admin,dc=example,dc=com');
define('LDAP_BIND_PASS', 'your_ldap_password');

// Application configuration
define('SITE_NAME', 'DNS3');
define('BASE_URL', '/');

// Zone validation configuration
define('ZONE_VALIDATE_SYNC', false); // Set to true to run named-checkzone synchronously
define('NAMED_CHECKZONE_PATH', 'named-checkzone'); // Path to named-checkzone binary

// Session configuration
ini_set('session.cookie_httponly', 1);
ini_set('session.use_strict_mode', 1);
session_start();
?>
