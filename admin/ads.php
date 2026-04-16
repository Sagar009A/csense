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

    $adNetwork = trim($_POST['adNetwork'] ?? 'admob');
    if (!in_array($adNetwork, ['admob', 'adx'])) $adNetwork = 'admob';

    $config = [
        // ── Network toggle ────────────────────────────────────────────────────
        'adNetwork' => $adNetwork,

        // ── Ad type switches ──────────────────────────────────────────────────
        'showBannerAd'       => isset($_POST['showBannerAd']),
        'showNativeAd'       => isset($_POST['showNativeAd']),
        'showInterstitialAd' => isset($_POST['showInterstitialAd']),
        'showRewardedAd'     => isset($_POST['showRewardedAd']),
        'showAppOpenAd'      => isset($_POST['showAppOpenAd']),

        // ── AdMob unit IDs ────────────────────────────────────────────────────
        'bannerAdId'       => trim($_POST['bannerAdId'] ?? ''),
        'nativeAdId'       => trim($_POST['nativeAdId'] ?? ''),
        'interstitialAdId' => trim($_POST['interstitialAdId'] ?? ''),
        'rewardedAdId'     => trim($_POST['rewardedAdId'] ?? ''),
        'appOpenAdId'      => trim($_POST['appOpenAdId'] ?? ''),

        // ── AdX (Google Ad Manager) unit IDs — Android ────────────────────────
        'adxAndroidBannerId'       => trim($_POST['adxAndroidBannerId'] ?? ''),
        'adxAndroidInterstitialId' => trim($_POST['adxAndroidInterstitialId'] ?? ''),
        'adxAndroidNativeId'       => trim($_POST['adxAndroidNativeId'] ?? ''),
        'adxAndroidRectangleId'    => trim($_POST['adxAndroidRectangleId'] ?? ''),
        'adxAndroidRewardedId'     => trim($_POST['adxAndroidRewardedId'] ?? ''),

        // ── AdX (Google Ad Manager) unit IDs — iOS ────────────────────────────
        'adxIosBannerId'       => trim($_POST['adxIosBannerId'] ?? ''),
        'adxIosInterstitialId' => trim($_POST['adxIosInterstitialId'] ?? ''),
        'adxIosNativeId'       => trim($_POST['adxIosNativeId'] ?? ''),
        'adxIosRectangleId'    => trim($_POST['adxIosRectangleId'] ?? ''),
        'adxIosRewardedId'     => trim($_POST['adxIosRewardedId'] ?? ''),

        // ── Native ad styling ─────────────────────────────────────────────────
        'nativeButtonColor'        => hexdec(ltrim($_POST['nativeButtonColor'] ?? '#8B5CF6', '#')) | 0xFF000000,
        'nativeButtonTextColor'    => hexdec(ltrim($_POST['nativeButtonTextColor'] ?? '#FFFFFF', '#')) | 0xFF000000,
        'nativeBackgroundColor'    => hexdec(ltrim($_POST['nativeBackgroundColor'] ?? '#FFFFFF', '#')) | 0xFF000000,
        'nativeBackgroundColorDark'=> hexdec(ltrim($_POST['nativeBackgroundColorDark'] ?? '#1A1A24', '#')) | 0xFF000000,
        'nativeCornerRadius'       => (float)($_POST['nativeCornerRadius'] ?? 12),
        'nativeAdFactoryId'        => trim($_POST['nativeAdFactoryId'] ?? 'mediumNativeAd'),

        // ── Timing & behaviour ────────────────────────────────────────────────
        'interstitialCooldownSeconds' => (int)($_POST['interstitialCooldownSeconds'] ?? 1),
        'appOpenCooldownSeconds'      => (int)($_POST['appOpenCooldownSeconds'] ?? 30),
        'preloadAdCount'              => (int)($_POST['preloadAdCount'] ?? 2),
        'adLoadTimeoutSeconds'        => (int)($_POST['adLoadTimeoutSeconds'] ?? 30),

        'shimmerBaseLight'      => 0xFFE2E8F0,
        'shimmerHighlightLight' => 0xFFF1F5F9,
        'shimmerBaseDark'       => 0xFF2D2D3A,
        'shimmerHighlightDark'  => 0xFF3D3D4A,
        'nativeAdShimmerHeight' => 280.0,
        'bannerAdShimmerHeight' => 60.0,
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

$currentNetwork = $config['adNetwork'] ?? 'admob';

// Default AdX IDs (baked into the Flutter app — shown for reference / override)
$adxDefaults = [
    'adxAndroidBannerId'       => '/21753324030,23133085249/com.chartsense.ai.app_Banner',
    'adxAndroidInterstitialId' => '/21753324030,23133085249/com.chartsense.ai.app_Interstitial',
    'adxAndroidNativeId'       => '/21753324030,23133085249/com.chartsense.ai.app_Native',
    'adxAndroidRectangleId'    => '/21753324030,23133085249/com.chartsense.ai.app_Rectangle',
    'adxAndroidRewardedId'     => '/21753324030,23133085249/com.chartsense.ai.app_Rewarded',
    'adxIosBannerId'           => '/21753324030,23133085249/6759394053_Banner',
    'adxIosInterstitialId'     => '/21753324030,23133085249/6759394053_Interstitial',
    'adxIosNativeId'           => '/21753324030,23133085249/6759394053_Native',
    'adxIosRectangleId'        => '/21753324030,23133085249/6759394053_Rectangle',
    'adxIosRewardedId'         => '/21753324030,23133085249/6759394053_Rewarded',
];

function intToHex($color) {
    return '#' . str_pad(dechex($color & 0xFFFFFF), 6, '0', STR_PAD_LEFT);
}

$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<style>
.network-card {
    cursor: pointer;
    border: 2px solid transparent;
    transition: all .2s ease;
    border-radius: 12px;
}
.network-card:hover { border-color: #8B5CF6; }
.network-card.selected-admob { border-color: #198754; background: rgba(25,135,84,.06); }
.network-card.selected-adx   { border-color: #0d6efd; background: rgba(13,110,253,.06); }
.network-card .network-icon  { font-size: 2rem; }
.network-badge { font-size: .7rem; padding: .25rem .55rem; border-radius: 20px; }
#adxSection { display: none; }
</style>

<main class="main-content">
    <div class="page-header">
        <h1>Ad Settings</h1>
        <p>Configure ad network, unit IDs, and display behaviour</p>
    </div>

    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <form method="POST" action="" id="adsForm">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
        <input type="hidden" name="adNetwork" id="adNetworkInput" value="<?php echo htmlspecialchars($currentNetwork); ?>">

        <div class="row g-4">

            <!-- ═══════════════════════════════════════════════════════════
                 Ad Network Selector  (full-width, top)
            ════════════════════════════════════════════════════════════ -->
            <div class="col-12">
                <div class="card border-0 shadow-sm">
                    <div class="card-header">
                        <h5 class="card-title mb-0">
                            <i class="bi bi-diagram-3 me-2"></i>Ad Network
                            <span class="badge bg-warning text-dark ms-2" style="font-size:.7rem">Active</span>
                        </h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">
                            Choose which ad network serves ads in the app.
                            Switching takes effect immediately — no app update needed.
                        </p>

                        <div class="row g-3">
                            <!-- AdMob option -->
                            <div class="col-md-6">
                                <div class="network-card p-4 <?php echo $currentNetwork === 'admob' ? 'selected-admob' : ''; ?>"
                                     id="cardAdmob" onclick="selectNetwork('admob')">
                                    <div class="d-flex align-items-center gap-3">
                                        <span class="network-icon">📊</span>
                                        <div class="flex-grow-1">
                                            <div class="d-flex align-items-center gap-2 mb-1">
                                                <strong class="fs-5">AdMob</strong>
                                                <span class="network-badge bg-success text-white">Google AdMob</span>
                                            </div>
                                            <small class="text-secondary">Standard Google AdMob ad units (ca-app-pub-xxx/xxx)</small>
                                        </div>
                                        <div id="checkAdmob" style="display:<?php echo $currentNetwork === 'admob' ? 'block' : 'none'; ?>">
                                            <i class="bi bi-check-circle-fill text-success fs-4"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- AdX option -->
                            <div class="col-md-6">
                                <div class="network-card p-4 <?php echo $currentNetwork === 'adx' ? 'selected-adx' : ''; ?>"
                                     id="cardAdx" onclick="selectNetwork('adx')">
                                    <div class="d-flex align-items-center gap-3">
                                        <span class="network-icon">🏢</span>
                                        <div class="flex-grow-1">
                                            <div class="d-flex align-items-center gap-2 mb-1">
                                                <strong class="fs-5">AdX (GAM)</strong>
                                                <span class="network-badge bg-primary text-white">Google Ad Manager</span>
                                            </div>
                                            <small class="text-secondary">Google Ad Manager / AdX premium demand (/networkCode/slot)</small>
                                        </div>
                                        <div id="checkAdx" style="display:<?php echo $currentNetwork === 'adx' ? 'block' : 'none'; ?>">
                                            <i class="bi bi-check-circle-fill text-primary fs-4"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Active network indicator -->
                        <div class="mt-3 p-3 rounded" id="networkIndicator"
                             style="background:<?php echo $currentNetwork === 'adx' ? 'rgba(13,110,253,.08)' : 'rgba(25,135,84,.08)'; ?>; border-left: 4px solid <?php echo $currentNetwork === 'adx' ? '#0d6efd' : '#198754'; ?>">
                            <small id="networkIndicatorText">
                                <?php if ($currentNetwork === 'adx'): ?>
                                    <i class="bi bi-info-circle me-1 text-primary"></i>
                                    <strong>AdX (GAM)</strong> is active — app is using Google Ad Manager unit IDs.
                                <?php else: ?>
                                    <i class="bi bi-info-circle me-1 text-success"></i>
                                    <strong>AdMob</strong> is active — app is using standard AdMob unit IDs.
                                <?php endif; ?>
                            </small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════
                 Ad Switches + AdMob IDs  (always visible)
            ════════════════════════════════════════════════════════════ -->
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
                            <input class="form-check-input" type="checkbox" id="showAppOpenAd" name="showAppOpenAd" <?php echo ($config['showAppOpenAd'] ?? false) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showAppOpenAd">
                                <strong>App Open Ads</strong>
                                <small class="d-block text-secondary">Ads when app opens from background</small>
                            </label>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-key me-2"></i>AdMob Unit IDs</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">Standard AdMob unit IDs (used when AdMob is selected)</p>

                        <div class="mb-3">
                            <label class="form-label">Banner Ad ID</label>
                            <input type="text" name="bannerAdId" class="form-control font-monospace" value="<?php echo htmlspecialchars($config['bannerAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Native Ad ID</label>
                            <input type="text" name="nativeAdId" class="form-control font-monospace" value="<?php echo htmlspecialchars($config['nativeAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Interstitial Ad ID</label>
                            <input type="text" name="interstitialAdId" class="form-control font-monospace" value="<?php echo htmlspecialchars($config['interstitialAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Rewarded Ad ID</label>
                            <input type="text" name="rewardedAdId" class="form-control font-monospace" value="<?php echo htmlspecialchars($config['rewardedAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                        <div class="mb-0">
                            <label class="form-label">App Open Ad ID</label>
                            <input type="text" name="appOpenAdId" class="form-control font-monospace" value="<?php echo htmlspecialchars($config['appOpenAdId'] ?? ''); ?>" placeholder="ca-app-pub-xxxxx/xxxxx">
                        </div>
                    </div>
                </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════
                 AdX Unit IDs  (shown only when AdX selected)
            ════════════════════════════════════════════════════════════ -->
            <div class="col-12" id="adxSection">
                <div class="card border-primary border-opacity-25">
                    <div class="card-header bg-primary bg-opacity-10">
                        <h5 class="card-title mb-0 text-primary">
                            <i class="bi bi-building me-2"></i>AdX (Google Ad Manager) Unit IDs
                        </h5>
                    </div>
                    <div class="card-body">
                        <p class="text-secondary mb-4">
                            These IDs are already baked into the app. You can override them here if needed.
                            Format: <code>/networkCode,publisherId/slotName</code>
                        </p>

                        <div class="row g-3">
                            <!-- Android -->
                            <div class="col-lg-6">
                                <h6 class="mb-3 d-flex align-items-center gap-2">
                                    <i class="bi bi-android2 text-success"></i> Android
                                    <small class="text-secondary fw-normal">App ID: ca-app-pub-7664893030317051~3785985150</small>
                                </h6>

                                <?php
                                $androidFields = [
                                    'adxAndroidBannerId'       => 'Banner',
                                    'adxAndroidInterstitialId' => 'Interstitial',
                                    'adxAndroidNativeId'       => 'Native',
                                    'adxAndroidRectangleId'    => 'Rectangle',
                                    'adxAndroidRewardedId'     => 'Rewarded',
                                ];
                                foreach ($androidFields as $field => $label):
                                    $val = $config[$field] ?? $adxDefaults[$field];
                                ?>
                                <div class="mb-3">
                                    <label class="form-label"><?php echo $label; ?> Ad ID</label>
                                    <input type="text" name="<?php echo $field; ?>" class="form-control form-control-sm font-monospace"
                                           value="<?php echo htmlspecialchars($val); ?>"
                                           placeholder="<?php echo htmlspecialchars($adxDefaults[$field]); ?>">
                                </div>
                                <?php endforeach; ?>
                            </div>

                            <!-- iOS -->
                            <div class="col-lg-6">
                                <h6 class="mb-3 d-flex align-items-center gap-2">
                                    <i class="bi bi-apple text-secondary"></i> iOS
                                    <small class="text-secondary fw-normal">App ID: ca-app-pub-7664893030317051~3213844558</small>
                                </h6>

                                <?php
                                $iosFields = [
                                    'adxIosBannerId'       => 'Banner',
                                    'adxIosInterstitialId' => 'Interstitial',
                                    'adxIosNativeId'       => 'Native',
                                    'adxIosRectangleId'    => 'Rectangle',
                                    'adxIosRewardedId'     => 'Rewarded',
                                ];
                                foreach ($iosFields as $field => $label):
                                    $val = $config[$field] ?? $adxDefaults[$field];
                                ?>
                                <div class="mb-3">
                                    <label class="form-label"><?php echo $label; ?> Ad ID</label>
                                    <input type="text" name="<?php echo $field; ?>" class="form-control form-control-sm font-monospace"
                                           value="<?php echo htmlspecialchars($val); ?>"
                                           placeholder="<?php echo htmlspecialchars($adxDefaults[$field]); ?>">
                                </div>
                                <?php endforeach; ?>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ═══════════════════════════════════════════════════════════
                 Timing & Behaviour
            ════════════════════════════════════════════════════════════ -->
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

            <!-- ═══════════════════════════════════════════════════════════
                 Native Ad Styling
            ════════════════════════════════════════════════════════════ -->
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
                                <option value="smallNativeAd"  <?php echo ($config['nativeAdFactoryId'] ?? '') === 'smallNativeAd'  ? 'selected' : ''; ?>>Small Native Ad</option>
                                <option value="largeNativeAd"  <?php echo ($config['nativeAdFactoryId'] ?? '') === 'largeNativeAd'  ? 'selected' : ''; ?>>Large Native Ad</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

        </div><!-- /.row -->

        <div class="mt-4 d-flex gap-3 align-items-center">
            <button type="submit" class="btn btn-primary btn-lg">
                <i class="bi bi-check-lg me-2"></i>Save Configuration
            </button>
            <small class="text-secondary">
                Changes are saved to Firebase and take effect in the app immediately.
            </small>
        </div>
    </form>
</main>

<script>
// ── Network selection logic ───────────────────────────────────────────────────
(function () {
    var currentNetwork = <?php echo json_encode($currentNetwork); ?>;

    function selectNetwork(network) {
        document.getElementById('adNetworkInput').value = network;
        currentNetwork = network;

        // Cards
        var cardAdmob = document.getElementById('cardAdmob');
        var cardAdx   = document.getElementById('cardAdx');
        cardAdmob.classList.remove('selected-admob', 'selected-adx');
        cardAdx.classList.remove('selected-admob', 'selected-adx');

        document.getElementById('checkAdmob').style.display = 'none';
        document.getElementById('checkAdx').style.display   = 'none';

        if (network === 'adx') {
            cardAdx.classList.add('selected-adx');
            document.getElementById('checkAdx').style.display = 'block';
            document.getElementById('adxSection').style.display = 'block';
            document.getElementById('networkIndicator').style.background = 'rgba(13,110,253,.08)';
            document.getElementById('networkIndicator').style.borderLeftColor = '#0d6efd';
            document.getElementById('networkIndicatorText').innerHTML =
                '<i class="bi bi-info-circle me-1 text-primary"></i><strong>AdX (GAM)</strong> is active — app will use Google Ad Manager unit IDs.';
        } else {
            cardAdmob.classList.add('selected-admob');
            document.getElementById('checkAdmob').style.display = 'block';
            document.getElementById('adxSection').style.display = 'none';
            document.getElementById('networkIndicator').style.background = 'rgba(25,135,84,.08)';
            document.getElementById('networkIndicator').style.borderLeftColor = '#198754';
            document.getElementById('networkIndicatorText').innerHTML =
                '<i class="bi bi-info-circle me-1 text-success"></i><strong>AdMob</strong> is active — app will use standard AdMob unit IDs.';
        }
    }

    // Expose globally for onclick
    window.selectNetwork = selectNetwork;

    // Apply initial state on page load
    selectNetwork(currentNetwork);
})();
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
