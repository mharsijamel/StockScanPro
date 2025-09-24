<?php
use Ripcord\Ripcord;

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../common/TokenManager.php';
require_once __DIR__ . '/../config.php';

header('Content-Type: application/json');

// Validate token
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Missing or invalid authorization header']);
    exit;
}

$token = $matches[1];
$credentials = TokenManager::getCredentials($token);

if (!$credentials) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Invalid or expired token']);
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

try {
    $picking_type_code = $_GET['picking_type_code'] ?? '';
    error_log("Picking type code: " . $picking_type_code);

    $filter = [['state', '=', 'assigned']];
    if (!empty($picking_type_code)) {
        $filter[] = ['picking_type_id.code', '=', $picking_type_code];
    }

    $pickings = $models->execute_kw(
        $db,
        $uid,
        $password,
        'stock.picking',
        'search_read',
        [$filter],
        ['fields' => ['id', 'name', 'origin', 'state', 'picking_type_id', 'move_lines','partner_id','scheduled_date']]
    );

    error_log("Found " . count($pickings) . " pickings.");

    $move_line_ids = [];
    foreach ($pickings as $picking) {
        $move_line_ids = array_merge($move_line_ids, $picking['move_lines']);
    }

    if (!empty($move_line_ids)) {
        $move_lines = $models->execute_kw(
            $db,
            $uid,
            $password,
            'stock.move',
            'read',
            [$move_line_ids],
            ['fields' => ['id', 'product_id', 'product_uom_qty', 'quantity_done', 'display_name', 'picking_id']]
        );

        $pickings_with_lines = [];
        foreach ($pickings as $picking) {
            $picking['move_lines'] = [];
            foreach ($move_lines as $move_line) {
                if ($move_line['picking_id'][0] == $picking['id']) {
                    $picking['move_lines'][] = $move_line;
                }
            }
            $pickings_with_lines[] = $picking;
        }
    } else {
        $pickings_with_lines = $pickings;
    }

    echo json_encode([
        'status' => 'success',
        'pickings' => $pickings_with_lines
    ]);

} catch (Exception $e) {
    error_log("Exception: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Query failed: ' . $e->getMessage()]);
}
?>