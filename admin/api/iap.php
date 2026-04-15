<?php
/**
 * In-App Purchase Configuration API Endpoint
 * GET: public (app reads config)
 * PUT: requires admin auth
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, PUT');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firebase.php';

$firebase = new Firebase();

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Public: app can read IAP config
        $result = $firebase->getIAPConfig();
        if ($result['success']) {
            jsonResponse(true, 'IAP config fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'Failed to fetch IAP config');
        }
        break;
        
    case 'PUT':
        requireApiAuth();
        if (empty($input)) {
            jsonResponse(false, 'Configuration data is required');
        }
        
        $result = $firebase->updateIAPConfig($input);
        if ($result['success']) {
            jsonResponse(true, 'IAP config updated successfully');
        } else {
            jsonResponse(false, 'Failed to update IAP config');
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
