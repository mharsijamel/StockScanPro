<?php
require_once __DIR__ . '/../common/OdooConnector.php';
require_once __DIR__ . '/../common/TokenManager.php';
require_once __DIR__ . '/../config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method Not Allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

$url = $input['url'] ?? '';
$db = $input['database'] ?? '';
$login = $input['login'] ?? '';
$password = $input['password'] ?? '';

if (empty($url) || empty($db) || empty($login) || empty($password)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields: url, database, login, password']);
    exit;
}

$odoo = new OdooConnector($url, $db, $login, $password);
$uid = $odoo->connect();

if ($uid) {
    $credentials = ['url' => $url, 'db' => $db, 'login' => $login, 'password' => $password];
    $token = TokenManager::generateToken($login, $credentials);
    echo json_encode(['status' => 'success', 'token' => $token]);
} else {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Authentication failed']);
}
