<?php
/**
 * Announcements API
 * Manages app announcements stored in Firebase Realtime Database
 * Firebase node: /announcement (single active announcement object)
 */
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firebase.php';

header('Content-Type: application/json');
requireLogin();

$firebase = new Firebase();
$method   = $_SERVER['REQUEST_METHOD'];
$action   = $_GET['action'] ?? '';

// ── GET: fetch current announcement ─────────────────────────────────────────
if ($method === 'GET') {
    try {
        $data = $firebase->get('announcement');
        echo json_encode(['success' => true, 'data' => $data]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}

// ── POST: save / update announcement ────────────────────────────────────────
if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) $input = $_POST;

    $action = $input['action'] ?? 'save';

    if ($action === 'delete') {
        $result = $firebase->delete('announcement');
        if ($result['success'] ?? false) {
            echo json_encode(['success' => true, 'message' => 'Announcement deleted']);
        } else {
            echo json_encode(['success' => false, 'message' => $result['error'] ?? 'Failed to delete announcement']);
        }
        exit;
    }

    // save / update
    $title      = trim($input['title']       ?? '');
    $message    = trim($input['message']     ?? '');
    $imageUrl   = trim($input['image_url']   ?? '');
    $buttonText = trim($input['button_text'] ?? '');
    $buttonUrl  = trim($input['button_url']  ?? '');
    $isActive   = isset($input['is_active'])  ? (bool)$input['is_active'] : true;
    $showOnce   = isset($input['show_once'])  ? (bool)$input['show_once'] : true;

    if (empty($title) || empty($message)) {
        echo json_encode(['success' => false, 'message' => 'Title and message are required']);
        exit;
    }

    // Unique ID — changes when admin saves a new/updated announcement so
    // the app knows to show it again even to users who dismissed the previous one.
    $announcementId = 'ann_' . time();

    $announcement = [
        'announcement_id' => $announcementId,
        'title'           => $title,
        'message'         => $message,
        'image_url'       => $imageUrl,
        'button_text'     => $buttonText,
        'button_url'      => $buttonUrl,
        'is_active'       => $isActive,
        'show_once'       => $showOnce,
        'updated_at'      => date('Y-m-d H:i:s'),
    ];

    $result = $firebase->set('announcement', $announcement);
    if ($result['success'] ?? false) {
        echo json_encode(['success' => true, 'message' => 'Announcement saved successfully', 'data' => $announcement]);
    } else {
        echo json_encode(['success' => false, 'message' => $result['error'] ?? 'Failed to save announcement']);
    }
    exit;
}

echo json_encode(['success' => false, 'message' => 'Method not allowed']);
