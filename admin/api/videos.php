<?php
/**
 * Videos API Endpoint
 * GET: public (app reads videos)
 * POST/PUT/DELETE: requires admin auth
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
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
        // Public: app can read videos
        $result = $firebase->getVideos();
        if ($result['success']) {
            jsonResponse(true, 'Videos fetched successfully', $result['data']);
        } else {
            jsonResponse(false, 'Failed to fetch videos');
        }
        break;
        
    case 'POST':
        requireApiAuth();
        $title = trim($input['title'] ?? '');
        $subTitle = trim($input['sub_title'] ?? '');
        $videoUrl = trim($input['video_url'] ?? '');
        
        if (empty($title) || empty($videoUrl)) {
            jsonResponse(false, 'Title and video URL are required');
        }
        
        $result = $firebase->addVideo($title, $subTitle, $videoUrl);
        if ($result['success']) {
            jsonResponse(true, 'Video added successfully', ['id' => $result['data']['name'] ?? null]);
        } else {
            jsonResponse(false, 'Failed to add video');
        }
        break;
        
    case 'PUT':
        requireApiAuth();
        $id = sanitizeFirebaseKey($input['id'] ?? '');
        $title = trim($input['title'] ?? '');
        $subTitle = trim($input['sub_title'] ?? '');
        $videoUrl = trim($input['video_url'] ?? '');
        
        if (empty($id) || empty($title) || empty($videoUrl)) {
            jsonResponse(false, 'ID, title and video URL are required');
        }
        
        $result = $firebase->updateVideo($id, $title, $subTitle, $videoUrl);
        if ($result['success']) {
            jsonResponse(true, 'Video updated successfully');
        } else {
            jsonResponse(false, 'Failed to update video');
        }
        break;
        
    case 'DELETE':
        requireApiAuth();
        $id = sanitizeFirebaseKey($input['id'] ?? $_GET['id'] ?? '');
        
        if (empty($id)) {
            jsonResponse(false, 'Video ID is required');
        }
        
        $result = $firebase->deleteVideo($id);
        if ($result['success']) {
            jsonResponse(true, 'Video deleted successfully');
        } else {
            jsonResponse(false, 'Failed to delete video');
        }
        break;
        
    default:
        http_response_code(405);
        jsonResponse(false, 'Method not allowed');
}
?>
