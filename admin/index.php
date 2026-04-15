<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Check Firebase configuration
$firebaseConfig = $firebase->checkConfiguration();

// Fetch stats
$videosResult   = $firebase->getVideos();
$adConfigResult = $firebase->getAdConfig();
$iapConfigResult = $firebase->getIAPConfig();

// Fetch analysis analytics
$statsResult   = $firebase->get('analysis_stats');
$todayKey      = date('Y-m-d');
$weekStartKey  = date('Y-m-d', strtotime('monday this week'));
$monthStartKey = date('Y-m-01');
$todayAnalysis = 0;
$weekAnalysis  = 0;
$monthAnalysis = 0;
if ($statsResult['success'] && !empty($statsResult['data']) && is_array($statsResult['data'])) {
    foreach ($statsResult['data'] as $dk => $cnt) {
        $c = (int)$cnt;
        if ($dk === $todayKey)    $todayAnalysis += $c;
        if ($dk >= $weekStartKey) $weekAnalysis  += $c;
        if ($dk >= $monthStartKey) $monthAnalysis += $c;
    }
}

$videoCount = count($videosResult['data'] ?? []);
$adsEnabled = 0;
if ($adConfigResult['success'] && $adConfigResult['data']) {
    $config = $adConfigResult['data'];
    if ($config['showBannerAd'] ?? false) $adsEnabled++;
    if ($config['showNativeAd'] ?? false) $adsEnabled++;
    if ($config['showInterstitialAd'] ?? false) $adsEnabled++;
    if ($config['showRewardedAd'] ?? false) $adsEnabled++;
    if ($config['showAppOpenAd'] ?? false) $adsEnabled++;
}

$productsCount = 0;
if ($iapConfigResult['success'] && $iapConfigResult['data']) {
    $products = $iapConfigResult['data']['products'] ?? [];
    $productsCount = count(array_filter($products, fn($p) => $p['isActive'] ?? false));
}

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1>Dashboard</h1>
        <p>Welcome back, <?php echo htmlspecialchars($_SESSION['admin_username'] ?? 'Admin'); ?>!</p>
    </div>
    
    <?php if (!$firebaseConfig['configured'] || !empty($firebaseConfig['warnings'])): ?>
        <div class="alert alert-warning alert-dismissible fade show" role="alert">
            <h5 class="alert-heading"><i class="bi bi-exclamation-triangle me-2"></i>Firebase Configuration Issue</h5>
            <?php if (!empty($firebaseConfig['issues'])): ?>
                <p class="mb-2"><strong>Critical Issues:</strong></p>
                <ul class="mb-2">
                    <?php foreach ($firebaseConfig['issues'] as $issue): ?>
                        <li><?php echo htmlspecialchars($issue); ?></li>
                    <?php endforeach; ?>
                </ul>
            <?php endif; ?>
            <?php if (!empty($firebaseConfig['warnings'])): ?>
                <p class="mb-2"><strong>Warnings:</strong></p>
                <ul class="mb-2">
                    <?php foreach ($firebaseConfig['warnings'] as $warning): ?>
                        <li><?php echo htmlspecialchars($warning); ?></li>
                    <?php endforeach; ?>
                </ul>
            <?php endif; ?>
            <p class="mb-0">
                <strong>Solution:</strong> Please check <code>FIREBASE_SETUP.md</code> file for detailed setup instructions.
                You need to upload the Firebase service account JSON file and update Firebase security rules.
            </p>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>
    
    <!-- Stats Cards -->
    <div class="row g-4 mb-4">
        <!-- Today's Analyses -->
        <div class="col-6 col-lg-3">
            <a href="analytics.php" style="text-decoration:none">
                <div class="stats-card">
                    <div class="icon purple"><i class="bi bi-graph-up-arrow"></i></div>
                    <h3><?php echo number_format($todayAnalysis); ?></h3>
                    <p>Analyses Today</p>
                    <small style="color:var(--text-secondary);font-size:0.75rem">
                        <?= number_format($weekAnalysis) ?> this week &middot; <?= number_format($monthAnalysis) ?> this month
                    </small>
                </div>
            </a>
        </div>

        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon blue">
                    <i class="bi bi-play-circle"></i>
                </div>
                <h3><?php echo $videoCount; ?></h3>
                <p>Total Videos</p>
            </div>
        </div>
        
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon green">
                    <i class="bi bi-megaphone"></i>
                </div>
                <h3><?php echo $adsEnabled; ?>/5</h3>
                <p>Ads Enabled</p>
            </div>
        </div>
        
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon orange">
                    <i class="bi bi-credit-card"></i>
                </div>
                <h3><?php echo $productsCount; ?></h3>
                <p>Active Products</p>
            </div>
        </div>
    </div>
    
    <!-- Quick Actions -->
    <div class="row g-4">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="card-title mb-0">Quick Actions</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <a href="videos.php" class="btn btn-outline-primary w-100 py-3">
                                <i class="bi bi-plus-circle me-2"></i>Add New Video
                            </a>
                        </div>
                        <div class="col-md-6">
                            <a href="notifications.php" class="btn btn-outline-primary w-100 py-3">
                                <i class="bi bi-send me-2"></i>Send Notification
                            </a>
                        </div>
                        <div class="col-md-6">
                            <a href="ads.php" class="btn btn-outline-primary w-100 py-3">
                                <i class="bi bi-gear me-2"></i>Configure Ads
                            </a>
                        </div>
                        <div class="col-md-6">
                            <a href="iap.php" class="btn btn-outline-primary w-100 py-3">
                                <i class="bi bi-currency-dollar me-2"></i>Manage IAP
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0">System Status</h5>
                </div>
                <div class="card-body">
                    <ul class="list-unstyled mb-0">
                        <li class="d-flex justify-content-between align-items-center py-2 border-bottom" style="border-color: var(--border-color) !important;">
                            <span><i class="bi bi-database me-2"></i>Firebase</span>
                            <span class="badge bg-success">Connected</span>
                        </li>
                        <li class="d-flex justify-content-between align-items-center py-2 border-bottom" style="border-color: var(--border-color) !important;">
                            <span><i class="bi bi-bell me-2"></i>OneSignal</span>
                            <span class="badge bg-<?php echo ONESIGNAL_APP_ID !== 'your-onesignal-app-id' ? 'success' : 'warning'; ?>">
                                <?php echo ONESIGNAL_APP_ID !== 'your-onesignal-app-id' ? 'Configured' : 'Not Configured'; ?>
                            </span>
                        </li>
                        <li class="d-flex justify-content-between align-items-center py-2 border-bottom" style="border-color: var(--border-color) !important;">
                            <span><i class="bi bi-credit-card me-2"></i>In-App Purchases</span>
                            <span class="badge bg-success">Native (StoreKit / Play Billing)</span>
                        </li>
                        <li class="d-flex justify-content-between align-items-center py-2">
                            <span><i class="bi bi-clock me-2"></i>Last Login</span>
                            <span class="text-secondary"><?php echo date('M j, g:i A', $_SESSION['login_time'] ?? time()); ?></span>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Recent Videos -->
    <div class="card mt-4">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="card-title mb-0">Recent Videos</h5>
            <a href="videos.php" class="btn btn-sm btn-primary">View All</a>
        </div>
        <div class="card-body">
            <?php if (empty($videosResult['data'])): ?>
                <div class="text-center py-4">
                    <i class="bi bi-play-circle text-secondary" style="font-size: 3rem;"></i>
                    <p class="text-secondary mt-2 mb-0">No videos added yet</p>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Title</th>
                                <th>Subtitle</th>
                                <th>URL</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php 
                            $recentVideos = array_slice($videosResult['data'], 0, 5);
                            foreach ($recentVideos as $video): 
                            ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($video['title'] ?? ''); ?></td>
                                    <td><?php echo htmlspecialchars($video['sub_title'] ?? ''); ?></td>
                                    <td>
                                        <a href="<?php echo htmlspecialchars($video['video_url'] ?? ''); ?>" target="_blank" class="text-primary">
                                            <i class="bi bi-link-45deg"></i> Open
                                        </a>
                                    </td>
                                    <td>
                                        <a href="videos.php" class="btn btn-sm btn-outline-primary">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    </div>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>
