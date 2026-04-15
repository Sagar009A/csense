<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

// Set current page for sidebar
$currentPage = 'firebase_check';

$firebase = new Firebase();
$config = $firebase->checkConfiguration();

// Test write permission
$writeTest = ['success' => false, 'error' => ''];
$testData = ['test' => true, 'timestamp' => date('c')];
$writeResult = $firebase->set('_test_write', $testData);
if ($writeResult['success']) {
    $writeTest['success'] = true;
    // Clean up test data
    $firebase->delete('_test_write');
} else {
    $writeTest['error'] = $writeResult['error'] ?? 'Unknown error';
}

// Test read permission
$readTest = ['success' => false, 'error' => ''];
$readResult = $firebase->get('app_settings');
if ($readResult['success'] !== false) {
    $readTest['success'] = true;
} else {
    $readTest['error'] = $readResult['error'] ?? 'Unknown error';
}

// Get service account file info (without sensitive data)
$serviceAccountInfo = null;
$serviceAccountPath = defined('FIREBASE_SERVICE_ACCOUNT_KEY') ? FIREBASE_SERVICE_ACCOUNT_KEY : null;
if (!empty($serviceAccountPath) && file_exists($serviceAccountPath)) {
    $serviceAccount = @json_decode(file_get_contents($serviceAccountPath), true);
    if ($serviceAccount) {
        $serviceAccountInfo = [
            'project_id' => $serviceAccount['project_id'] ?? 'N/A',
            'client_email' => $serviceAccount['client_email'] ?? 'N/A',
            'private_key_exists' => !empty($serviceAccount['private_key']),
            'file_size' => filesize($serviceAccountPath),
            'file_readable' => is_readable($serviceAccountPath),
            'file_path' => $serviceAccountPath
        ];
    }
}

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1><i class="bi bi-shield-check me-2"></i>Firebase Configuration Check</h1>
        <p>Verify Firebase setup and diagnose configuration issues</p>
    </div>
    
    <div class="row g-4">
        <!-- Overall Status -->
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-info-circle me-2"></i>Overall Status</h5>
                </div>
                <div class="card-body">
                    <?php if ($config['configured'] && $config['canAuthenticate']): ?>
                        <div class="alert alert-success mb-0">
                            <h5 class="alert-heading"><i class="bi bi-check-circle me-2"></i>All Systems Operational</h5>
                            <p class="mb-0">Firebase is properly configured and ready to use. All checks passed successfully.</p>
                        </div>
                    <?php else: ?>
                        <div class="alert alert-danger mb-0">
                            <h5 class="alert-heading"><i class="bi bi-exclamation-triangle me-2"></i>Configuration Issues Detected</h5>
                            <p class="mb-0">Please review the details below and fix the issues to enable Firebase functionality.</p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Service Account Configuration -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-key me-2"></i>Service Account</h5>
                </div>
                <div class="card-body">
                    <?php if ($config['serviceAccountExists']): ?>
                        <div class="mb-3">
                            <span class="badge bg-success me-2"><i class="bi bi-check-circle"></i> File Found</span>
                        </div>
                        <?php if ($serviceAccountInfo): ?>
                            <table class="table table-sm table-borderless mb-0">
                                <tr>
                                    <td><strong>Project ID:</strong></td>
                                    <td><?php echo htmlspecialchars($serviceAccountInfo['project_id']); ?></td>
                                </tr>
                                <tr>
                                    <td><strong>Client Email:</strong></td>
                                    <td><code><?php echo htmlspecialchars($serviceAccountInfo['client_email']); ?></code></td>
                                </tr>
                                <tr>
                                    <td><strong>Private Key:</strong></td>
                                    <td>
                                        <?php if ($serviceAccountInfo['private_key_exists']): ?>
                                            <span class="badge bg-success">Present</span>
                                        <?php else: ?>
                                            <span class="badge bg-danger">Missing</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                                <tr>
                                    <td><strong>File Size:</strong></td>
                                    <td><?php echo number_format($serviceAccountInfo['file_size'] / 1024, 2); ?> KB</td>
                                </tr>
                                <tr>
                                    <td><strong>Readable:</strong></td>
                                    <td>
                                        <?php if ($serviceAccountInfo['file_readable']): ?>
                                            <span class="badge bg-success">Yes</span>
                                        <?php else: ?>
                                            <span class="badge bg-danger">No</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                                <tr>
                                    <td><strong>File Path:</strong></td>
                                    <td><small><code><?php echo htmlspecialchars($serviceAccountInfo['file_path']); ?></code></small></td>
                                </tr>
                            </table>
                        <?php endif; ?>
                    <?php else: ?>
                        <div class="alert alert-warning mb-0">
                            <i class="bi bi-exclamation-triangle me-2"></i>
                            <strong>Service Account File Not Found</strong>
                            <p class="mb-0 mt-2">Please upload the Firebase service account JSON file to:<br>
                            <code><?php echo htmlspecialchars(defined('FIREBASE_SERVICE_ACCOUNT_KEY') ? FIREBASE_SERVICE_ACCOUNT_KEY : 'config/'); ?></code></p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Database Configuration -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-database me-2"></i>Database Configuration</h5>
                </div>
                <div class="card-body">
                    <table class="table table-sm table-borderless mb-0">
                        <tr>
                            <td><strong>Database URL:</strong></td>
                            <td>
                                <?php if (!empty(FIREBASE_DATABASE_URL)): ?>
                                    <span class="badge bg-success me-2"><i class="bi bi-check-circle"></i> Configured</span>
                                    <br><small><code><?php echo htmlspecialchars(FIREBASE_DATABASE_URL); ?></code></small>
                                <?php else: ?>
                                    <span class="badge bg-danger">Not Configured</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>API Key:</strong></td>
                            <td>
                                <?php if (!empty(FIREBASE_API_KEY)): ?>
                                    <span class="badge bg-success"><i class="bi bi-check-circle"></i> Configured</span>
                                <?php else: ?>
                                    <span class="badge bg-danger">Not Configured</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Project ID:</strong></td>
                            <td>
                                <?php if (!empty(FIREBASE_PROJECT_ID)): ?>
                                    <span class="badge bg-success"><i class="bi bi-check-circle"></i> <?php echo htmlspecialchars(FIREBASE_PROJECT_ID); ?></span>
                                <?php else: ?>
                                    <span class="badge bg-danger">Not Configured</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    </table>
                </div>
            </div>
        </div>
        
        <!-- Authentication Test -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-shield-lock me-2"></i>Authentication Test</h5>
                </div>
                <div class="card-body">
                    <?php if ($config['canAuthenticate']): ?>
                        <div class="alert alert-success mb-0">
                            <i class="bi bi-check-circle me-2"></i>
                            <strong>Authentication Successful</strong>
                            <p class="mb-0 mt-2">Service account authentication is working correctly. Access tokens can be generated.</p>
                        </div>
                    <?php else: ?>
                        <div class="alert alert-danger mb-0">
                            <i class="bi bi-x-circle me-2"></i>
                            <strong>Authentication Failed</strong>
                            <p class="mb-0 mt-2">Unable to generate access token. Check service account file and permissions.</p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Read Permission Test -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-eye me-2"></i>Read Permission Test</h5>
                </div>
                <div class="card-body">
                    <?php if ($readTest['success']): ?>
                        <div class="alert alert-success mb-0">
                            <i class="bi bi-check-circle me-2"></i>
                            <strong>Read Access: OK</strong>
                            <p class="mb-0 mt-2">Can successfully read data from Firebase Realtime Database.</p>
                        </div>
                    <?php else: ?>
                        <div class="alert alert-danger mb-0">
                            <i class="bi bi-x-circle me-2"></i>
                            <strong>Read Access: Failed</strong>
                            <p class="mb-0 mt-2">Error: <?php echo htmlspecialchars($readTest['error']); ?></p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Write Permission Test -->
        <div class="col-md-6">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-pencil me-2"></i>Write Permission Test</h5>
                </div>
                <div class="card-body">
                    <?php if ($writeTest['success']): ?>
                        <div class="alert alert-success mb-0">
                            <i class="bi bi-check-circle me-2"></i>
                            <strong>Write Access: OK</strong>
                            <p class="mb-0 mt-2">Can successfully write data to Firebase Realtime Database.</p>
                        </div>
                    <?php else: ?>
                        <div class="alert alert-danger mb-0">
                            <i class="bi bi-x-circle me-2"></i>
                            <strong>Write Access: Failed</strong>
                            <p class="mb-0 mt-2">Error: <?php echo htmlspecialchars($writeTest['error']); ?></p>
                            <p class="mb-0 mt-2"><small>This usually means Firebase security rules are blocking writes or service account authentication failed.</small></p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        
        <!-- Configuration Issues -->
        <?php if (!empty($config['issues']) || !empty($config['warnings'])): ?>
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-exclamation-triangle me-2"></i>Issues & Warnings</h5>
                </div>
                <div class="card-body">
                    <?php if (!empty($config['issues'])): ?>
                        <h6 class="text-danger mb-3"><i class="bi bi-x-circle me-2"></i>Critical Issues</h6>
                        <ul class="list-group mb-4">
                            <?php foreach ($config['issues'] as $issue): ?>
                                <li class="list-group-item list-group-item-danger">
                                    <i class="bi bi-x-circle me-2"></i><?php echo htmlspecialchars($issue); ?>
                                </li>
                            <?php endforeach; ?>
                        </ul>
                    <?php endif; ?>
                    
                    <?php if (!empty($config['warnings'])): ?>
                        <h6 class="text-warning mb-3"><i class="bi bi-exclamation-triangle me-2"></i>Warnings</h6>
                        <ul class="list-group mb-0">
                            <?php foreach ($config['warnings'] as $warning): ?>
                                <li class="list-group-item list-group-item-warning">
                                    <i class="bi bi-exclamation-triangle me-2"></i><?php echo htmlspecialchars($warning); ?>
                                </li>
                            <?php endforeach; ?>
                        </ul>
                    <?php endif; ?>
                </div>
            </div>
        </div>
        <?php endif; ?>
        
        <!-- Quick Actions -->
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-tools me-2"></i>Quick Actions</h5>
                </div>
                <div class="card-body">
                    <div class="d-flex gap-2 flex-wrap">
                        <a href="settings.php" class="btn btn-primary">
                            <i class="bi bi-gear me-2"></i>Go to Settings
                        </a>
                        <a href="videos.php" class="btn btn-primary">
                            <i class="bi bi-play-circle me-2"></i>Manage Videos
                        </a>
                        <button onclick="location.reload()" class="btn btn-secondary">
                            <i class="bi bi-arrow-clockwise me-2"></i>Refresh Check
                        </button>
                        <?php if (!$config['configured']): ?>
                        <a href="FIREBASE_SETUP.md" target="_blank" class="btn btn-info">
                            <i class="bi bi-book me-2"></i>View Setup Guide
                        </a>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Firebase Rules Info -->
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-shield me-2"></i>Firebase Security Rules</h5>
                </div>
                <div class="card-body">
                    <div class="alert alert-info mb-0">
                        <h6 class="alert-heading"><i class="bi bi-info-circle me-2"></i>Important</h6>
                        <p class="mb-2">Make sure your Firebase Realtime Database security rules allow authenticated writes. Recommended rules:</p>
                        <pre class="bg-dark text-light p-3 rounded mb-0" style="font-size: 0.85rem;"><code>{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "videos": { ".read": true, ".write": "auth != null" },
    "app_settings": { ".read": true, ".write": "auth != null" },
    "api_config": { ".read": true, ".write": "auth != null" }
  }
}</code></pre>
                        <p class="mb-0 mt-3">
                            <strong>Location:</strong> Firebase Console > Realtime Database > Rules<br>
                            <strong>File:</strong> See <code>firebase_rules.json</code> in admin panel directory
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>
