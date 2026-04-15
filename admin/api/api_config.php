<?php
/**
 * API Configuration Endpoint
 * For mobile app to fetch Gemini API key and other settings
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
        // Get API configuration
        $result = $firebase->getApiConfig();
        if ($result['success']) {
            jsonResponse(true, 'API config fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'Failed to fetch API config');
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
