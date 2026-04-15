<?php
/**
 * Users API Endpoint
 * All operations require admin auth
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firebase.php';

requireApiAuth();

$firebase = new Firebase();

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        $userId = sanitizeFirebaseKey($_GET['id'] ?? '');
        
        if (empty($userId)) {
            jsonResponse(false, 'User ID is required');
        }
        
        $result = $firebase->get('users/' . $userId);
        if ($result['success']) {
            jsonResponse(true, 'User fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'User not found');
        }
        break;
        
    case 'POST':
        // Add credits to user
        $userId = sanitizeFirebaseKey($input['user_id'] ?? '');
        $credits = (int)($input['credits'] ?? 0);
        
        if (empty($userId) || $credits <= 0) {
            jsonResponse(false, 'User ID and credits amount are required');
        }
        
        // Get current credits
        $userResult = $firebase->get('users/' . $userId);
        $currentCredits = (int)($userResult['data']['credits'] ?? 0);
        
        // Update credits
        $result = $firebase->update('users/' . $userId, [
            'credits' => $currentCredits + $credits,
            'isPremium' => true
        ]);
        
        if ($result['success']) {
            jsonResponse(true, 'Credits added successfully', ['newCredits' => $currentCredits + $credits]);
        } else {
            jsonResponse(false, 'Failed to add credits');
        }
        break;
        
    case 'PUT':
        // Update user premium status
        $userId = sanitizeFirebaseKey($input['user_id'] ?? '');
        $isPremium = $input['is_premium'] ?? false;
        
        if (empty($userId)) {
            jsonResponse(false, 'User ID is required');
        }
        
        $result = $firebase->update('users/' . $userId, [
            'isPremium' => $isPremium
        ]);
        
        if ($result['success']) {
            jsonResponse(true, 'User updated successfully');
        } else {
            jsonResponse(false, 'Failed to update user');
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
