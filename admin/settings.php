<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: settings.php');
        exit;
    }
    $action = $_POST['action'] ?? '';
    
    if ($action === 'save_app_settings') {
        // App Settings (must include all keys app reads from Firebase app_settings)
        $appSettings = [
            'appName' => trim($_POST['appName'] ?? ''),
            'appVersion' => trim($_POST['appVersion'] ?? ''),
            'maintenanceMode' => isset($_POST['maintenanceMode']),
            'maintenanceMessage' => trim($_POST['maintenanceMessage'] ?? ''),
            'forceUpdateVersion' => trim($_POST['forceUpdateVersion'] ?? ''),
            'forceUpdateMessage' => trim($_POST['forceUpdateMessage'] ?? ''),
            'showAdConsentOption' => isset($_POST['showAdConsentOption']),
        ];
        
        // API Config (stored separately for app to fetch)
        $apiConfig = [
            'geminiApiKey' => trim($_POST['geminiApiKey'] ?? ''),
            'geminiModel' => trim($_POST['geminiModel'] ?? 'gemini-2.5-flash'),
            'analysisPrompt' => trim($_POST['analysisPrompt'] ?? ''),
            'supportEmail' => trim($_POST['supportEmail'] ?? ''),
            'privacyPolicyUrl' => trim($_POST['privacyPolicyUrl'] ?? ''),
            'privacyPolicyUrlIOS' => trim($_POST['privacyPolicyUrlIOS'] ?? ''),
            'termsOfServiceUrl' => trim($_POST['termsOfServiceUrl'] ?? ''),
            'termsOfServiceUrlIOS' => trim($_POST['termsOfServiceUrlIOS'] ?? ''),
            'playStoreUrl' => trim($_POST['playStoreUrl'] ?? ''),
            'appStoreUrl' => trim($_POST['appStoreUrl'] ?? ''),
            'moreAppsUrl' => trim($_POST['moreAppsUrl'] ?? ''),
            'moreAppsUrlIOS' => trim($_POST['moreAppsUrlIOS'] ?? ''),
        ];
        
        // Save both
        $result1 = $firebase->set('app_settings', $appSettings);
        $result2 = $firebase->set('api_config', $apiConfig);
        
        if ($result1['success'] && $result2['success']) {
            $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'All settings saved successfully!'];
        } else {
            $errorMsg = 'Failed to save settings. ';
            if (!$result1['success']) {
                $errorMsg .= 'App Settings: ' . ($result1['error'] ?? 'Unknown error') . '. ';
            }
            if (!$result2['success']) {
                $errorMsg .= 'API Config: ' . ($result2['error'] ?? 'Unknown error') . '. ';
            }
            $_SESSION['flash_message'] = ['type' => 'error', 'text' => trim($errorMsg)];
        }
        
        header('Location: settings.php');
        exit;
    }
}

// Fetch current settings
$settingsResult = $firebase->get('app_settings');
$settings = $settingsResult['data'] ?? [];

// Fetch API config
$apiConfigResult = $firebase->getApiConfig();
$apiConfig = $apiConfigResult['data'] ?? [];

// Get flash message
$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1>App Settings</h1>
        <p>Configure general app settings and remote configuration</p>
    </div>
    
    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>
    
    <form method="POST" action="">
        <input type="hidden" name="action" value="save_app_settings">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
        
        <div class="row g-4">
            <!-- General Settings -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-gear me-2"></i>General Settings</h5>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label">App Name</label>
                            <input type="text" name="appName" class="form-control" value="<?php echo htmlspecialchars($settings['appName'] ?? 'Stock AI Scanner'); ?>">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">App Version</label>
                            <input type="text" name="appVersion" class="form-control" value="<?php echo htmlspecialchars($settings['appVersion'] ?? '1.0.0'); ?>">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Support Email</label>
                            <input type="email" name="supportEmail" class="form-control" value="<?php echo htmlspecialchars($apiConfig['supportEmail'] ?? ''); ?>" placeholder="support@example.com">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Privacy Policy URL — Android</label>
                            <input type="url" name="privacyPolicyUrl" class="form-control" value="<?php echo htmlspecialchars($apiConfig['privacyPolicyUrl'] ?? ''); ?>" placeholder="https://example.com/privacy">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label"><i class="bi bi-apple text-dark me-1"></i>Privacy Policy URL — iOS</label>
                            <input type="url" name="privacyPolicyUrlIOS" class="form-control" value="<?php echo htmlspecialchars($apiConfig['privacyPolicyUrlIOS'] ?? ''); ?>" placeholder="https://example.com/privacy-ios">
                            <small class="text-secondary">Leave empty to use same URL as Android</small>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Terms of Service URL — Android</label>
                            <input type="url" name="termsOfServiceUrl" class="form-control" value="<?php echo htmlspecialchars($apiConfig['termsOfServiceUrl'] ?? ''); ?>" placeholder="https://example.com/terms">
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label"><i class="bi bi-apple text-dark me-1"></i>Terms of Service URL — iOS</label>
                            <input type="url" name="termsOfServiceUrlIOS" class="form-control" value="<?php echo htmlspecialchars($apiConfig['termsOfServiceUrlIOS'] ?? ''); ?>" placeholder="https://example.com/terms-ios">
                            <small class="text-secondary">Leave empty to use same URL as Android</small>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Store Links -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-shop me-2"></i>Store Links</h5>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label"><i class="bi bi-google-play text-success me-1"></i>Google Play Store URL</label>
                            <input type="url" name="playStoreUrl" class="form-control" value="<?php echo htmlspecialchars($apiConfig['playStoreUrl'] ?? ''); ?>" placeholder="https://play.google.com/store/apps/details?id=...">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label"><i class="bi bi-apple text-dark me-1"></i>Apple App Store URL</label>
                            <input type="url" name="appStoreUrl" class="form-control" value="<?php echo htmlspecialchars($apiConfig['appStoreUrl'] ?? ''); ?>" placeholder="https://apps.apple.com/app/...">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">More Apps URL — Android (Developer Page)</label>
                            <input type="url" name="moreAppsUrl" class="form-control" value="<?php echo htmlspecialchars($apiConfig['moreAppsUrl'] ?? ''); ?>" placeholder="https://play.google.com/store/apps/developer?id=...">
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label"><i class="bi bi-apple text-dark me-1"></i>More Apps URL — iOS</label>
                            <input type="url" name="moreAppsUrlIOS" class="form-control" value="<?php echo htmlspecialchars($apiConfig['moreAppsUrlIOS'] ?? ''); ?>" placeholder="https://apps.apple.com/developer/...">
                            <small class="text-secondary">Leave empty to use App Store URL as fallback on iOS</small>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Maintenance Mode -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-tools me-2"></i>Maintenance Mode</h5>
                    </div>
                    <div class="card-body">
                        <div class="form-check form-switch mb-4">
                            <input class="form-check-input" type="checkbox" id="maintenanceMode" name="maintenanceMode" <?php echo ($settings['maintenanceMode'] ?? false) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="maintenanceMode">
                                <strong>Enable Maintenance Mode</strong>
                                <small class="d-block text-secondary">Show maintenance message to all users</small>
                            </label>
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label">Maintenance Message</label>
                            <textarea name="maintenanceMessage" class="form-control" rows="3" placeholder="We're currently performing scheduled maintenance. Please check back soon!"><?php echo htmlspecialchars($settings['maintenanceMessage'] ?? ''); ?></textarea>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Force Update -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-arrow-repeat me-2"></i>Force Update</h5>
                    </div>
                    <div class="card-body">
                        <div class="alert alert-info small py-2 mb-3">
                            <strong>How it works:</strong> Set the minimum version (e.g. <code>1.0.4</code>). Users with app version <em>lower</em> than this will see an “Update required” dialog. Fill <strong>Store Links</strong> (above) so the Update button opens the correct Play/App Store.
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Minimum Required Version</label>
                            <input type="text" name="forceUpdateVersion" class="form-control" value="<?php echo htmlspecialchars($settings['forceUpdateVersion'] ?? ''); ?>" placeholder="1.0.4">
                            <small class="text-secondary">Leave empty to disable. Use same format as app (e.g. 1.0.3, 1.0.10).</small>
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label">Update Message</label>
                            <textarea name="forceUpdateMessage" class="form-control" rows="3" placeholder="A new version is available. Please update to continue using the app."><?php echo htmlspecialchars($settings['forceUpdateMessage'] ?? ''); ?></textarea>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Privacy & Ads (App Settings) -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-shield-check me-2"></i>Privacy & Ads</h5>
                    </div>
                    <div class="card-body">
                        <div class="form-check form-switch mb-0">
                            <input class="form-check-input" type="checkbox" id="showAdConsentOption" name="showAdConsentOption" <?php echo (!isset($settings['showAdConsentOption']) || $settings['showAdConsentOption']) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showAdConsentOption">
                                <strong>Show Ad Consent & Privacy Option</strong>
                                <small class="d-block text-secondary">When enabled, the "Ad consent & privacy options" button is visible in the app Settings screen. When disabled, it is hidden.</small>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- AI Configuration -->
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-robot me-2"></i>AI Configuration (Gemini)</h5>
                    </div>
                    <div class="card-body">
                        <div class="alert alert-info mb-4">
                            <i class="bi bi-info-circle me-2"></i>
                            <strong>Important:</strong> These settings are synced to Firebase and will be used by your app. The app will fetch `api_config` from Firebase.
                        </div>
                        
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Gemini API Key *</label>
                                <div class="input-group">
                                    <input type="password" name="geminiApiKey" id="geminiApiKey" class="form-control" value="<?php echo htmlspecialchars($apiConfig['geminiApiKey'] ?? ''); ?>" placeholder="AIzaSy...">
                                    <button type="button" class="btn btn-outline-secondary" onclick="togglePassword('geminiApiKey')">
                                        <i class="bi bi-eye"></i>
                                    </button>
                                </div>
                                <small class="text-secondary">Get your API key from <a href="https://makersuite.google.com/app/apikey" target="_blank">Google AI Studio</a></small>
                            </div>
                            
                            <div class="col-md-6">
                                <label class="form-label">Gemini Model</label>
                                <select name="geminiModel" class="form-select">
                                    <option value="gemini-2.5-flash" <?php echo ($apiConfig['geminiModel'] ?? '') === 'gemini-2.5-flash' ? 'selected' : ''; ?>>Gemini 2.5 Flash (Recommended)</option>
                                    <option value="gemini-2.0-flash" <?php echo ($apiConfig['geminiModel'] ?? '') === 'gemini-2.0-flash' ? 'selected' : ''; ?>>Gemini 2.0 Flash</option>
                                    <option value="gemini-1.5-pro" <?php echo ($apiConfig['geminiModel'] ?? '') === 'gemini-1.5-pro' ? 'selected' : ''; ?>>Gemini 1.5 Pro</option>
                                    <option value="gemini-1.5-flash" <?php echo ($apiConfig['geminiModel'] ?? '') === 'gemini-1.5-flash' ? 'selected' : ''; ?>>Gemini 1.5 Flash</option>
                                </select>
                                <small class="text-secondary">Select the Gemini model for analysis</small>
                            </div>
                            
                            <div class="col-12">
                                <label class="form-label">Custom Analysis Prompt (Optional)</label>
                                <textarea name="analysisPrompt" class="form-control" rows="4" placeholder="Leave empty to use default prompt. Or enter custom instructions for AI analysis..."><?php echo htmlspecialchars($apiConfig['analysisPrompt'] ?? ''); ?></textarea>
                                <small class="text-secondary">Custom instructions to append to the default analysis prompt</small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="mt-4">
            <button type="submit" class="btn btn-primary btn-lg">
                <i class="bi bi-check-lg me-2"></i>Save Settings
            </button>
        </div>
    </form>
</main>

<script>
function togglePassword(inputId) {
    const input = document.getElementById(inputId);
    const icon = event.currentTarget.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('bi-eye');
        icon.classList.add('bi-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('bi-eye-slash');
        icon.classList.add('bi-eye');
    }
}
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
