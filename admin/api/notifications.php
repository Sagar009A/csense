<?php
/**
 * Push Notifications API Endpoint
 * For admin panel AJAX requests (secured)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/onesignal.php';

requireApiAuth();

$onesignal = new OneSignal();

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        // Get notification history
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
        $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
        
        $result = $onesignal->getNotifications($limit, $offset);
        if ($result['success']) {
            jsonResponse(true, 'Notifications fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'Failed to fetch notifications');
        }
        break;
        
    case 'POST':
        // Send notification
        $title = trim($input['title'] ?? '');
        $message = trim($input['message'] ?? '');
        $segment = $input['segment'] ?? 'All';
        $data = $input['data'] ?? [];
        $imageUrl = $input['image_url'] ?? null;
        $scheduleTime = $input['schedule_time'] ?? null;
        
        if (empty($title) || empty($message)) {
            jsonResponse(false, 'Title and message are required');
        }
        
        if ($scheduleTime) {
            $result = $onesignal->scheduleNotification($title, $message, $scheduleTime, $data, $imageUrl);
        } elseif ($segment === 'All') {
            $result = $onesignal->sendToAll($title, $message, $data, $imageUrl);
        } else {
            $result = $onesignal->sendToSegment($segment, $title, $message, $data, $imageUrl);
        }
        
        if ($result['success']) {
            jsonResponse(true, 'Notification sent successfully', $result['data']);
        } else {
            $error = is_array($result['data'] ?? null) ? ($result['data']['errors'][0] ?? 'Unknown error') : 'Unknown error';
            jsonResponse(false, 'Failed to send notification: ' . $error);
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
