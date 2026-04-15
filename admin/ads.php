<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: ads.php');
        exit;
    }
    $config = [
        'showBannerAd' => isset($_POST['showBannerAd']),
        'showNativeAd' => isset($_POST['showNativeAd']),
        'showInterstitialAd' => isset($_POST['showInterstitialAd']),
        'showRewardedAd' => isset($_POST['showRewardedAd']),
        'showAppOpenAd' => isset($_POST['showAppOpenAd']),
        
        'bannerAdId' => trim($_POST['bannerAdId'] ?? ''),
        'nativeAdId' => trim($_POST['nativeAdId'] ?? ''),
        'interstitialAdId' => trim($_POST['interstitialAdId'] ?? ''),
        'rewardedAdId' => trim($_POST['rewardedAdId'] ?? ''),
        'appOpenAdId' => trim($_POST['appOpenAdId'] ?? ''),
        
        'nativeButtonColor' => hexdec(ltrim($_POST['nativeButtonColor'] ?? '#8B5CF6', '#')) | 0xFF000000,
        'nativeButtonTextColor' => hexdec(ltrim($_POST['nativeButtonTextColor'] ?? '#FFFFFF', '#')) | 0xFF000000,
        'nativeBackgroundColor' => hexdec(ltrim($_POST['nativeBackgroundColor'] ?? '#FFFFFF', '#')) | 0xFF000000,
        'nativeBackgroundColorDark' => hexdec(ltrim($_POST['nativeBackgroundColorDark'] ?? '#1A1A24', '#')) | 0xFF000000,
        'nativeCornerRadius' => (float)($_POST['nativeCornerRadius'] ?? 12),
        'nativeAdFactoryId' => trim($_POST['nativeAdFactoryId'] ?? 'mediumNativeAd'),
        
        'interstitialCooldownSeconds' => (int)($_POST['interstitialCooldownSeconds'] ?? 1),
        'appOpenCooldownSeconds' => (int)($_POST['appOpenCooldownSeconds'] ?? 30),
        'preloadAdCount' => (int)($_POST['preloadAdCount'] ?? 2),
        'adLoadTimeoutSeconds' => (int)($_POST['adLoadTimeoutSeconds'] ?? 30),
        
        'shimmerBaseLight' => 0xFFE2E8F0,
        'shimmerHighlightLight' => 0xFFF1F5F9,
        'shimmerBaseDark' => 0xFF2D2D3A,
        'shimmerHighlightDark' => 0xFF3D3D4A,
        'nativeAdShimmerHeight' => 280.0,
        'bannerAdShimmerHeight' => 60.0
    ];
    
    $result = $firebase->updateAdConfig($config);
    if ($result['success']) {
        $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Ad configuration saved successfully!'];
    } else {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to save configuration.'];
    }
    
    header('Location: ads.php');
    exit;
}

// Fetch current config
$configResult = $firebase->getAdConfig();
$config = $configResult['data'] ?? [];

// Convert colors to hex
function intToHex($color) {
    return '#' . str_pad(dechex($color & 0xFFFFFF), 6, '0', STR_PAD_LEFT);
}

// Get flash message
$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1>AdMob Settings</h1>
        <p>Configure your Google AdMob advertisement settings</p>
    </div>
    
    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>
    
    <form method="POST" action="">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
        <div class="row g-4">
            <!-- Ad Switches -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-toggle-on me-2"></i>Ad Visibility</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">Enable or disable different ad types in your app</p>
                        
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="showBannerAd" name="showBannerAd" <?php echo ($config['showBannerAd'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showBannerAd">
                                <strong>Banner Ads</strong>
                                <small class="d-block text-secondary">Display banner ads at screen bottom</small>
                            </label>
                        </div>
                        
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="showNativeAd" name="showNativeAd" <?php echo ($config['showNativeAd'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showNativeAd">
                                <strong>Native Ads</strong>
                                <small class="d-block text-secondary">Native ads in content feed</small>
                            </label>
                        </div>
                        
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="showInterstitialAd" name="showInterstitialAd" <?php echo ($config['showInterstitialAd'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showInterstitialAd">
                                <strong>Interstitial Ads</strong>
                                <small class="d-block text-secondary">Full-screen ads between screens</small>
                            </label>
                        </div>
                        
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="showRewardedAd" name="showRewardedAd" <?php echo ($config['showRewardedAd'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showRewardedAd">
                                <strong>Rewarded Ads</strong>
                                <small class="d-block text-secondary">Video ads for earning credits</small>
                            </label>
                        </div>
                        
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="showAppOpenAd" name="showAppOpenAd" <?php echo ($config['showAppOpenAd'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showAppOpenAd">
                                <strong>App Open Ads</strong>
                                <small class="d-block text-secondary">Ads when app opens from background</small>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Ad Unit IDs -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-key me-2"></i>Ad Unit IDs</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">Enter your AdMob unit IDs for each ad type</p>
                        
                        <div class="mb-3">
                            <label class="form-label">Banner Ad ID</label>
                            <input type="text" name="bannerAdId" class="form-control" value="<?php echo htmlspecialchars($config['bannerAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Native Ad ID</label>
                            <input type="text" name="nativeAdId" class="form-control" value="<?php echo htmlspecialchars($config['nativeAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Interstitial Ad ID</label>
                            <input type="text" name="interstitialAdId" class="form-control" value="<?php echo htmlspecialchars($config['interstitialAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Rewarded Ad ID</label>
                            <input type="text" name="rewardedAdId" class="form-control" value="<?php echo htmlspecialchars($config['rewardedAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label">App Open Ad ID</label>
                            <input type="text" name="appOpenAdId" class="form-control" value="<?php echo htmlspecialchars($config['appOpenAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Timing & Behavior -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-clock me-2"></i>Timing & Behavior</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">Configure ad display frequency and behavior</p>
                        
                        <div class="mb-3">
                            <label class="form-label">Interstitial Cooldown (seconds)</label>
                            <input type="number" name="interstitialCooldownSeconds" class="form-control" value="<?php echo (int)($config['interstitialCooldownSeconds'] ?? 1); ?>" min="0">
                            <small class="text-secondary">Minimum time between interstitial ads</small>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">App Open Cooldown (seconds)</label>
                            <input type="number" name="appOpenCooldownSeconds" class="form-control" value="<?php echo (int)($config['appOpenCooldownSeconds'] ?? 30); ?>" min="0">
                            <small class="text-secondary">Minimum time between app open ads</small>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Preload Ad Count</label>
                            <input type="number" name="preloadAdCount" class="form-control" value="<?php echo (int)($config['preloadAdCount'] ?? 2); ?>" min="1" max="5">
                            <small class="text-secondary">Number of ads to preload</small>
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label">Ad Load Timeout (seconds)</label>
                            <input type="number" name="adLoadTimeoutSeconds" class="form-control" value="<?php echo (int)($config['adLoadTimeoutSeconds'] ?? 30); ?>" min="5">
                            <small class="text-secondary">Maximum time to wait for ad to load</small>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Native Ad Styling -->
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-palette me-2"></i>Native Ad Styling</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">Customize native ad appearance</p>
                        
                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label">Button Color</label>
                                <input type="color" name="nativeButtonColor" class="form-control form-control-color w-100" value="<?php echo intToHex($config['nativeButtonColor'] ?? 0xFF8B5CF6); ?>">
                            </div>
                            
                            <div class="col-6 mb-3">
                                <label class="form-label">Button Text Color</label>
                                <input type="color" name="nativeButtonTextColor" class="form-control form-control-color w-100" value="<?php echo intToHex($config['nativeButtonTextColor'] ?? 0xFFFFFFFF); ?>">
                            </div>
                            
                            <div class="col-6 mb-3">
                                <label class="form-label">Background (Light)</label>
                                <input type="color" name="nativeBackgroundColor" class="form-control form-control-color w-100" value="<?php echo intToHex($config['nativeBackgroundColor'] ?? 0xFFFFFFFF); ?>">
                            </div>
                            
                            <div class="col-6 mb-3">
                                <label class="form-label">Background (Dark)</label>
                                <input type="color" name="nativeBackgroundColorDark" class="form-control form-control-color w-100" value="<?php echo intToHex($config['nativeBackgroundColorDark'] ?? 0xFF1A1A24); ?>">
                            </div>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label">Corner Radius</label>
                            <input type="number" name="nativeCornerRadius" class="form-control" value="<?php echo (float)($config['nativeCornerRadius'] ?? 12); ?>" min="0" step="0.5">
                        </div>
                        
                        <div class="mb-0">
                            <label class="form-label">Native Ad Factory ID</label>
                            <select name="nativeAdFactoryId" class="form-select">
                                <option value="mediumNativeAd" <?php echo ($config['nativeAdFactoryId'] ?? '') === 'mediumNativeAd' ? 'selected' : ''; ?>>Medium Native Ad</option>
                                <option value="smallNativeAd" <?php echo ($config['nativeAdFactoryId'] ?? '') === 'smallNativeAd' ? 'selected' : ''; ?>>Small Native Ad</option>
                                <option value="largeNativeAd" <?php echo ($config['nativeAdFactoryId'] ?? '') === 'largeNativeAd' ? 'selected' : ''; ?>>Large Native Ad</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="mt-4">
            <button type="submit" class="btn btn-primary btn-lg">
                <i class="bi bi-check-lg me-2"></i>Save Configuration
            </button>
        </div>
    </form>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>
