<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/onesignal.php';

requireLogin();

$onesignal = new OneSignal();

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: notifications.php');
        exit;
    }
    $action = $_POST['action'] ?? '';
    
    if ($action === 'send') {
        $title = trim($_POST['title'] ?? '');
        $message = trim($_POST['message'] ?? '');
        $segment = $_POST['segment'] ?? 'All';
        $imageUrl = trim($_POST['image_url'] ?? '');
        $scheduleTime = $_POST['schedule_time'] ?? '';
        $data = [];
        
        // Parse additional data
        if (!empty($_POST['data_key']) && is_array($_POST['data_key'])) {
            foreach ($_POST['data_key'] as $index => $key) {
                if (!empty($key) && isset($_POST['data_value'][$index])) {
                    $data[$key] = $_POST['data_value'][$index];
                }
            }
        }
        
        if ($title && $message) {
            if (!empty($scheduleTime)) {
                $result = $onesignal->scheduleNotification(
                    $title, 
                    $message, 
                    $scheduleTime,
                    $segment,
                    $data,
                    $imageUrl ?: null
                );
            } else {
                // Send immediately
                if ($segment === 'All') {
                    $result = $onesignal->sendToAll($title, $message, $data, $imageUrl ?: null);
                } else {
                    $result = $onesignal->sendToSegment($segment, $title, $message, $data, $imageUrl ?: null);
                }
            }
            
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Notification sent successfully!'];
            } else {
                $error = $result['data']['errors'][0] ?? 'Unknown error occurred';
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to send notification: ' . $error];
            }
        } else {
            $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Title and message are required.'];
        }
        
        header('Location: notifications.php');
        exit;
    }
}

// Get segments
$segmentsResult = $onesignal->getSegments();
$segments = $segmentsResult['data'] ?? [];

// Get recent notifications
$notificationsResult = $onesignal->getNotifications(10);
$notifications = $notificationsResult['data']['notifications'] ?? [];

// Get flash message
$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1>Push Notifications</h1>
        <p>Send push notifications to your app users via OneSignal</p>
    </div>
    
    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>
    
    <div class="row g-4">
        <!-- Send Notification Form -->
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-send me-2"></i>Send Notification</h5>
                </div>
                <div class="card-body">
                    <form method="POST" action="">
                        <input type="hidden" name="action" value="send">
                        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                        
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Notification Title *</label>
                                <input type="text" name="title" class="form-control" placeholder="Enter notification title" required>
                            </div>
                            
                            <div class="col-md-6">
                                <label class="form-label">Target Segment</label>
                                <select name="segment" class="form-select">
                                    <?php foreach ($segments as $segment): ?>
                                        <option value="<?php echo htmlspecialchars($segment['name']); ?>">
                                            <?php echo htmlspecialchars($segment['name']); ?>
                                        </option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            
                            <div class="col-12">
                                <label class="form-label">Message *</label>
                                <textarea name="message" class="form-control" rows="3" placeholder="Enter notification message" required></textarea>
                            </div>
                            
                            <div class="col-md-6">
                                <label class="form-label">Image URL (Optional)</label>
                                <input type="url" name="image_url" class="form-control" placeholder="https://example.com/image.jpg">
                                <small class="text-secondary">Big picture for rich notifications</small>
                            </div>
                            
                            <div class="col-md-6">
                                <label class="form-label">Schedule (Optional)</label>
                                <input type="datetime-local" name="schedule_time" class="form-control">
                                <small class="text-secondary">Leave empty to send immediately</small>
                            </div>
                            
                            <div class="col-12">
                                <label class="form-label d-flex justify-content-between align-items-center">
                                    <span>Additional Data (Optional)</span>
                                    <button type="button" class="btn btn-sm btn-outline-primary" onclick="addDataField()">
                                        <i class="bi bi-plus"></i> Add Field
                                    </button>
                                </label>
                                <div id="dataFieldsContainer">
                                    <div class="data-field-row row g-2 mb-2">
                                        <div class="col-5">
                                            <input type="text" name="data_key[]" class="form-control" placeholder="Key (e.g., screen)">
                                        </div>
                                        <div class="col-5">
                                            <input type="text" name="data_value[]" class="form-control" placeholder="Value (e.g., home)">
                                        </div>
                                        <div class="col-2">
                                            <button type="button" class="btn btn-outline-danger w-100" onclick="removeDataField(this)">
                                                <i class="bi bi-x"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <small class="text-secondary">Add custom data to handle notification taps in app</small>
                            </div>
                        </div>
                        
                        <div class="mt-4">
                            <button type="submit" class="btn btn-primary">
                                <i class="bi bi-send me-2"></i>Send Notification
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        
        <!-- Quick Stats & Templates -->
        <div class="col-lg-4">
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-info-circle me-2"></i>OneSignal Status</h5>
                </div>
                <div class="card-body">
                    <?php if (ONESIGNAL_APP_ID === 'your-onesignal-app-id'): ?>
                        <div class="alert alert-warning mb-0">
                            <i class="bi bi-exclamation-triangle me-2"></i>
                            <strong>Not Configured</strong>
                            <p class="mb-0 mt-2">Set <code>ONESIGNAL_APP_ID</code> and <code>ONESIGNAL_REST_API_KEY</code> in <code>config/config.php</code>. Then add the OneSignal Flutter SDK to the app (see README).</p>
                        </div>
                    <?php else: ?>
                        <ul class="list-unstyled mb-0">
                            <li class="d-flex justify-content-between py-2 border-bottom" style="border-color: var(--border-color) !important;">
                                <span>Status</span>
                                <span class="badge bg-success">Active</span>
                            </li>
                            <li class="d-flex justify-content-between py-2 border-bottom" style="border-color: var(--border-color) !important;">
                                <span>App ID</span>
                                <span class="text-secondary text-truncate" style="max-width: 150px;"><?php echo htmlspecialchars(ONESIGNAL_APP_ID); ?></span>
                            </li>
                            <li class="d-flex justify-content-between py-2">
                                <span>API Key</span>
                                <span class="text-secondary">••••••••</span>
                            </li>
                        </ul>
                    <?php endif; ?>
                </div>
            </div>
            
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-phone me-2"></i>App Setup (OneSignal)</h5>
                </div>
                <div class="card-body">
                    <p class="small text-secondary mb-0">The ChartSense app does <strong>not</strong> include OneSignal SDK by default. To receive push notifications in the app:</p>
                    <ol class="small ps-3 mt-2 mb-0">
                        <li>Add <code>onesignal_flutter</code> to <code>pubspec.yaml</code></li>
                        <li>Initialize OneSignal in <code>main.dart</code> with the same App ID as in config above</li>
                        <li>Request notification permission and subscribe the user</li>
                    </ol>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-lightning me-2"></i>Quick Templates</h5>
                </div>
                <div class="card-body">
                    <div class="d-grid gap-2">
                        <button type="button" class="btn btn-outline-primary text-start" onclick="useTemplate('New Feature!', 'Check out our latest update with exciting new features. Update now!')">
                            <i class="bi bi-star me-2"></i>New Feature Announcement
                        </button>
                        <button type="button" class="btn btn-outline-primary text-start" onclick="useTemplate('Special Offer!', 'Get 50% off on Pro subscription. Limited time offer!')">
                            <i class="bi bi-percent me-2"></i>Special Offer
                        </button>
                        <button type="button" class="btn btn-outline-primary text-start" onclick="useTemplate('Market Update', 'Don\'t miss today\'s market analysis. Check it out now!')">
                            <i class="bi bi-graph-up me-2"></i>Market Update
                        </button>
                        <button type="button" class="btn btn-outline-primary text-start" onclick="useTemplate('New Video Added', 'A new tutorial video has been added. Watch now to learn more!')">
                            <i class="bi bi-play-circle me-2"></i>New Video
                        </button>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Recent Notifications -->
        <div class="col-12">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-clock-history me-2"></i>Recent Notifications</h5>
                </div>
                <div class="card-body">
                    <?php if (empty($notifications)): ?>
                        <div class="text-center py-4">
                            <i class="bi bi-bell text-secondary" style="font-size: 3rem;"></i>
                            <p class="text-secondary mt-2 mb-0">No notifications sent yet</p>
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Title</th>
                                        <th>Message</th>
                                        <th>Sent To</th>
                                        <th>Delivered</th>
                                        <th>Date</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($notifications as $notification): ?>
                                        <tr>
                                            <td><?php echo htmlspecialchars($notification['headings']['en'] ?? 'N/A'); ?></td>
                                            <td class="text-truncate" style="max-width: 200px;">
                                                <?php echo htmlspecialchars($notification['contents']['en'] ?? 'N/A'); ?>
                                            </td>
                                            <td><?php echo number_format($notification['successful'] ?? 0); ?></td>
                                            <td><?php echo number_format($notification['converted'] ?? 0); ?></td>
                                            <td><?php echo date('M j, g:i A', strtotime($notification['send_after'] ?? $notification['queued_at'] ?? 'now')); ?></td>
                                            <td>
                                                <?php if (($notification['canceled'] ?? false)): ?>
                                                    <span class="badge bg-danger">Canceled</span>
                                                <?php elseif (($notification['completed_at'] ?? null)): ?>
                                                    <span class="badge bg-success">Delivered</span>
                                                <?php else: ?>
                                                    <span class="badge bg-warning">Pending</span>
                                                <?php endif; ?>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
</main>

<script>
function useTemplate(title, message) {
    document.querySelector('input[name="title"]').value = title;
    document.querySelector('textarea[name="message"]').value = message;
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function addDataField() {
    const container = document.getElementById('dataFieldsContainer');
    const row = document.createElement('div');
    row.className = 'data-field-row row g-2 mb-2';
    row.innerHTML = `
        <div class="col-5">
            <input type="text" name="data_key[]" class="form-control" placeholder="Key">
        </div>
        <div class="col-5">
            <input type="text" name="data_value[]" class="form-control" placeholder="Value">
        </div>
        <div class="col-2">
            <button type="button" class="btn btn-outline-danger w-100" onclick="removeDataField(this)">
                <i class="bi bi-x"></i>
            </button>
        </div>
    `;
    container.appendChild(row);
}

function removeDataField(btn) {
    const rows = document.querySelectorAll('.data-field-row');
    if (rows.length > 1) {
        btn.closest('.data-field-row').remove();
    }
}
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
