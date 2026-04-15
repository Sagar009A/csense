<?php
/**
 * Stock AI Scanner - Admin Panel Configuration
 * Main configuration file for the PHP admin panel
 */

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Error Reporting (disable display in production; log to file instead)
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Timezone
date_default_timezone_set('Asia/Kolkata');

// Site Configuration
define('SITE_NAME', 'Stock AI Scanner - Admin Panel');
// Change this to your domain URL
define('SITE_URL', 'https://smartpricetracker.in/chartsense');
define('ADMIN_EMAIL', 'admin@smartpricetracker.in');

// Firebase Configuration
define('FIREBASE_PROJECT_ID', 'chartsense-ai-1060a');
define('FIREBASE_DATABASE_URL', 'https://chartsense-ai-1060a-default-rtdb.firebaseio.com');
define('FIREBASE_API_KEY', 'AIzaSyDA5ILmlCFTImxB0gEHWA7FF472W7Z6HiE');
define('FIREBASE_SERVICE_ACCOUNT_KEY', __DIR__ . '/chartsense-ai-1060a-firebase-adminsdk-fbsvc-608d45033b.json');

// OneSignal Configuration (Push Notifications - set these for admin panel to send push to app)
define('ONESIGNAL_APP_ID', 'your-onesignal-app-id');
define('ONESIGNAL_REST_API_KEY', 'your-onesignal-rest-api-key');

// Admin Credentials (change these!)
define('ADMIN_USERNAME', 'admin');
// To generate a new hash run: php -r "echo password_hash('YourNewPassword', PASSWORD_DEFAULT);"
define('ADMIN_PASSWORD_HASH', '$2a$12$HrYn/DfJIiNry0eeLyp0P.XplQs.7B6NS4hIBzbXjKItshwp2SbO6'); // default: admin123

// Helper function to check if user is logged in
function isLoggedIn() {
    return isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
}

// Helper function to require login
// Works from any directory level (admin root or api/ subfolder)
function requireLogin() {
    if (!isLoggedIn()) {
        $dir = dirname($_SERVER['SCRIPT_NAME']);
        $base = rtrim($dir, '/');
        // If called from api/ subfolder, go up one level
        if (basename($dir) === 'api') {
            $base = dirname($base);
        }
        header('Location: ' . $base . '/login.php');
        exit;
    }
}

// Require API key or admin session for API endpoints
function requireApiAuth() {
    // Allow if admin is logged in (AJAX from admin panel)
    if (isLoggedIn()) return;
    // Check Authorization header for API key
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (!empty($auth) && $auth === 'Bearer ' . FIREBASE_API_KEY) return;
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

// Sanitize Firebase path segment (prevent path traversal)
function sanitizeFirebaseKey($key) {
    return preg_replace('/[^a-zA-Z0-9_\-]/', '', $key);
}

// Helper function for JSON responses
function jsonResponse($success, $message = '', $data = null) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

// CSRF Token Generation
function generateCSRFToken() {
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

// CSRF Token Verification
function verifyCSRFToken($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}
?>
