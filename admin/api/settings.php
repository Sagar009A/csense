<?php
/**
 * App Settings API Endpoint
 * For mobile app to fetch remote configuration
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firebase.php';

$firebase = new Firebase();

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Get app settings
        $result = $firebase->get('app_settings');
        if ($result['success']) {
            jsonResponse(true, 'Settings fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'Failed to fetch settings');
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
