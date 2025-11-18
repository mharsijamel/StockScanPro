<?php
use Ripcord\Ripcord;

require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/common/TokenManager.php';
require_once __DIR__ . '/config.php';

header('Content-Type: application/json');

// 1. Valider le token
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Token not found or invalid format']);
    exit;
}
$token = $matches[1];
$credentials = TokenManager::getCredentials($token);

if (!$credentials) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Invalid or expired token']);
    exit;
}

// 2. Récupérer l'ID du picking depuis les paramètres de l'URL
$picking_id = $_GET['id'] ?? null;
if (!$picking_id || !is_numeric($picking_id)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Missing or invalid picking ID']);
    exit;
}

// Extract credentials
$url = $credentials['url'];
$db = $credentials['db'];
$username = $credentials['login'];
$password = $credentials['password'];

// Connect to Odoo using Ripcord
$common = Ripcord::client("$url/xmlrpc/2/common");
$uid = $common->authenticate($db, $username, $password, []);

if (!$uid) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Authentication failed. Check your username, password, and database.']);
    exit;
}

$models = Ripcord::client("$url/xmlrpc/2/object");

// 4. Rechercher les lignes de mouvement (stock.move) pour ce picking
$domain = [
    ['picking_id', '=', (int)$picking_id]
];

$fields = ['display_name', 'product_uom_qty', 'quantity_done', 'product_id'];

$lines = $models->execute_kw(
    $db,               // database
    $uid,              // authenticated user ID
    $password,         // user password
    'stock.move',      // model
    'search_read',     // method
    [$domain],         // args
    ['fields' => $fields] // kwargs
);

if ($lines === false) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to retrieve stock picking lines from Odoo.']);
} else {
    echo json_encode(['status' => 'success', 'data' => $lines]);
}
