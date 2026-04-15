<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: iap.php');
        exit;
    }
    $action = $_POST['action'] ?? '';
    
    if ($action === 'save_general') {
        $config = [
            'enableIAP' => isset($_POST['enableIAP']),
            'freeCredits' => (int)($_POST['freeCredits'] ?? 5),
            'creditsPerAnalysis' => (int)($_POST['creditsPerAnalysis'] ?? 1),
            'showUpgradePrompt' => isset($_POST['showUpgradePrompt']),
        ];
        $result = $firebase->updateIAPConfig($config);
        if ($result['success']) {
            $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'General IAP settings saved!'];
        } else {
            $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to save settings.'];
        }
        header('Location: iap.php');
        exit;
    }

    if ($action === 'save_credit_packs') {
        $packs = [];
        if (isset($_POST['cp_id']) && is_array($_POST['cp_id'])) {
            foreach ($_POST['cp_id'] as $i => $id) {
                $id = trim($id);
                if (empty($id)) continue;
                $packs[] = [
                    'id' => $id,
                    'credits' => (int)($_POST['cp_credits'][$i] ?? 0),
                    'price' => trim($_POST['cp_price'][$i] ?? ''),
                    'badge' => trim($_POST['cp_badge'][$i] ?? '') ?: null,
                    'active' => isset($_POST['cp_active'][$i]),
                ];
            }
        }
        $result = $firebase->set('iap_config/credit_packs', $packs);
        if ($result['success']) {
            $_SESSION['flash_message'] = ['type' => 'success', 'text' => '✅ Credit packs saved! App reflects on next launch.'];
        } else {
            $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to save credit packs.'];
        }
        header('Location: iap.php');
        exit;
    }

    if ($action === 'save_plan_config') {
        // Plan IDs must match App Store Connect & Google Play Console product IDs
        $planIds = ['weekly', 'monthly', 'quarterly'];
        $plansConfig   = [];  // iap_config/plans       — bonus credits, duration, price
        $plansDisplay  = [];  // iap_config/subscription_plans — title, badge, features

        foreach ($planIds as $pid) {
            // Config (pricing & credits)
            $plansConfig[$pid] = [
                'productIdAndroid' => trim($_POST["plan_{$pid}_pid_android"] ?? $pid),
                'productIdIOS'     => trim($_POST["plan_{$pid}_pid_ios"]     ?? $pid),
                'displayPrice'     => trim($_POST["plan_{$pid}_price"]       ?? ''),
                'durationDays'     => (int)($_POST["plan_{$pid}_duration"]   ?? 30),
                'bonusCredits'     => (int)($_POST["plan_{$pid}_bonus"]      ?? 0),
                'active'           => isset($_POST["plan_{$pid}_active"]),
            ];

            // Display (title, badge, features)
            $rawFeats = $_POST["plan_{$pid}_features"] ?? '';
            $features = array_values(array_filter(
                array_map('trim', explode("\n", $rawFeats))
            ));
            $plansDisplay[$pid] = [
                'title'    => trim($_POST["plan_{$pid}_title"]   ?? ''),
                'badge'    => trim($_POST["plan_{$pid}_badge"]   ?? '') ?: null,
                'savings'  => trim($_POST["plan_{$pid}_savings"] ?? '') ?: null,
                'price'    => trim($_POST["plan_{$pid}_price"]   ?? ''),
                'features' => $features,
            ];
        }

        $r1 = $firebase->set('iap_config/plans', $plansConfig);
        $r2 = $firebase->set('iap_config/subscription_plans', $plansDisplay);

        if ($r1['success'] && $r2['success']) {
            $_SESSION['flash_message'] = ['type' => 'success', 'text' => '✅ Subscription plans saved! App reflects changes on next launch.'];
        } else {
            $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to save plan configuration.'];
        }
        header('Location: iap.php');
        exit;
    }
}

// Fetch current config
$configResult = $firebase->getIAPConfig();
$config = $configResult['data'] ?? [];

// Fetch plan config (bonus credits, duration) from Firebase
$planConfigResult = $firebase->get('iap_config/plans');
$planConfig = $planConfigResult['data'] ?? [];

// Fetch plan display config (title, features) from Firebase
$subPlansResult = $firebase->get('iap_config/subscription_plans');
$planDisplay = $subPlansResult['data'] ?? [];

// Default plan definitions (must match subscription_service.dart)
$defaultPlans = [
    'weekly' => [
        'productIdAndroid' => 'weekpro',
        'productIdIOS'     => 'weekpro',
        'title'            => '1 Week',
        'price'            => '₹50',
        'displayPrice'     => '₹50',
        'durationDays'     => 7,
        'bonusCredits'     => 5,
        'badge'            => '',
        'savings'          => '',
        'active'           => true,
        'features'         => ['All Ads Removed (Banner, Video & Native)', '5 Credits Included — 5 Ad-Free Analyses', 'Credits Valid for 7 Days', 'Ad-Free Video Streaming', 'Video Ad Resumes When Credits Run Out'],
    ],
    'monthly' => [
        'productIdAndroid' => 'pro_monthly',
        'productIdIOS'     => 'pro_monthly',
        'title'            => '1 Month',
        'price'            => '₹150',
        'displayPrice'     => '₹150',
        'durationDays'     => 30,
        'bonusCredits'     => 25,
        'badge'            => 'Popular',
        'savings'          => '',
        'active'           => true,
        'features'         => ['All Ads Removed (Banner, Video & Native)', '25 Credits Included — 25 Ad-Free Analyses', 'Credits Valid for 30 Days', 'Ad-Free Video Streaming', 'Video Ad Resumes When Credits Run Out'],
    ],
    'quarterly' => [
        'productIdAndroid' => 'pro_yearly',
        'productIdIOS'     => 'pro_yearly',
        'title'            => '3 Months',
        'price'            => '₹450',
        'displayPrice'     => '₹450',
        'durationDays'     => 90,
        'bonusCredits'     => 50,
        'badge'            => 'Best Value',
        'savings'          => 'Save 25%',
        'active'           => true,
        'features'         => ['All Ads Removed (Banner, Video & Native)', '50 Credits Included — 50 Ad-Free Analyses', 'Credits Valid for 90 Days', 'Ad-Free Video Streaming', 'Video Ad Resumes When Credits Run Out'],
    ],
];

// Fetch credit pack config from Firebase
$creditPackResult = $firebase->get('iap_config/credit_packs');
$creditPacks = $creditPackResult['data'] ?? [];

// Default credit packs
$defaultCreditPacks = [
    ['id' => 'credits_10',   'credits' => 10,   'price' => '₹20',   'badge' => '',           'active' => true],
    ['id' => 'credits_50',   'credits' => 50,   'price' => '₹80',   'badge' => '',           'active' => true],
    ['id' => 'credits_100',  'credits' => 100,  'price' => '₹150',  'badge' => 'Popular',    'active' => true],
    ['id' => 'credits_200',  'credits' => 200,  'price' => '₹300',  'badge' => '',           'active' => true],
    ['id' => 'credits_500',  'credits' => 500,  'price' => '₹750',  'badge' => 'Best Value', 'active' => true],
    ['id' => 'credits_1000', 'credits' => 1000, 'price' => '₹1500', 'badge' => '',           'active' => true],
];

// Use Firebase credit packs if available, else defaults
if (is_array($creditPacks) && !empty($creditPacks)) {
    $mergedCreditPacks = array_values(array_filter($creditPacks, fn($p) => is_array($p) && !empty($p['id'])));
    if (empty($mergedCreditPacks)) $mergedCreditPacks = $defaultCreditPacks;
} else {
    $mergedCreditPacks = $defaultCreditPacks;
}

// Merge Firebase data over defaults
$mergedPlans = [];
foreach ($defaultPlans as $pid => $def) {
    $cfg  = is_array($planConfig[$pid]  ?? null) ? $planConfig[$pid]  : [];
    $disp = is_array($planDisplay[$pid] ?? null) ? $planDisplay[$pid] : [];
    $merged = array_merge($def, $cfg, $disp);
    // Normalise features to array
    if (!is_array($merged['features'] ?? null)) {
        $merged['features'] = $def['features'];
    }
    $mergedPlans[$pid] = $merged;
}

// Get flash message
$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header">
        <h1>In-App Purchases</h1>
        <p>Manage subscription plans and credit system (Native StoreKit / Play Billing)</p>
    </div>
    
    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <!-- General IAP & Credits Settings -->
    <form method="POST" action="">
        <input type="hidden" name="action" value="save_general">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
        
        <div class="row g-4 mb-4">
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-bag-check me-2"></i>General Settings</h5>
                    </div>
                    <div class="card-body">
                        <div class="alert alert-success py-2 mb-3 small">
                            <i class="bi bi-check-circle me-1"></i>
                            <strong>Native IAP</strong> — Uses Apple StoreKit (iOS) &amp; Google Play Billing (Android) directly. No third-party SDK needed.
                        </div>

                        <div class="form-check form-switch mb-4">
                            <input class="form-check-input" type="checkbox" id="enableIAP" name="enableIAP" <?php echo ($config['enableIAP'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="enableIAP">
                                <strong>Enable In-App Purchases</strong>
                                <small class="d-block text-secondary">Allow users to purchase subscriptions &amp; credit packs</small>
                            </label>
                        </div>

                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="showUpgradePrompt" name="showUpgradePrompt" <?php echo ($config['showUpgradePrompt'] ?? true) ? 'checked' : ''; ?>>
                            <label class="form-check-label" for="showUpgradePrompt">
                                <strong>Show Upgrade Prompt</strong>
                                <small class="d-block text-secondary">Prompt users to upgrade when credits are low</small>
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="card h-100">
                    <div class="card-header">
                        <h5 class="card-title mb-0"><i class="bi bi-coin me-2"></i>Credits System</h5>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Free Credits for New Users</label>
                            <input type="number" name="freeCredits" class="form-control" value="<?php echo (int)($config['freeCredits'] ?? 5); ?>" min="0">
                            <small class="text-secondary">Given on first signup</small>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Credits Per Analysis</label>
                            <input type="number" name="creditsPerAnalysis" class="form-control" value="<?php echo (int)($config['creditsPerAnalysis'] ?? 1); ?>" min="1">
                            <small class="text-secondary">Deducted per chart analysis (skips video ad)</small>
                        </div>

                        <div class="alert alert-warning py-2 mb-0 small">
                            <i class="bi bi-info-circle me-1"></i>
                            <strong>Credit packs</strong> are configured below and in App Store Connect / Play Console.
                            Prices shown to users are <em>from the store</em> (auto currency). The prices below are fallback only.
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <button type="submit" class="btn btn-primary mb-4">
            <i class="bi bi-check-lg me-2"></i>Save General Settings
        </button>
    </form>

    <!-- ═══ Subscription Plans Configuration ═══════════════════════════════ -->
    <form method="POST" action="" class="mt-5">
        <input type="hidden" name="action" value="save_plan_config">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <div>
                    <h5 class="card-title mb-1">
                        <i class="bi bi-stars me-2 text-warning"></i>Subscription Plans
                        <span class="badge bg-success ms-2" style="font-size:0.7rem;">Live — no app update needed</span>
                    </h5>
                    <small class="text-secondary">Control plan prices, bonus credits, features for iOS &amp; Android. Product IDs must match App Store Connect &amp; Play Console.</small>
                </div>
                <button type="submit" class="btn btn-success">
                    <i class="bi bi-cloud-upload me-1"></i>Save All Plans
                </button>
            </div>
            <div class="card-body">

                <!-- Info banner -->
                <div class="alert alert-info py-2 mb-4 small">
                    <i class="bi bi-info-circle me-1"></i>
                    <strong>How it works:</strong>
                    <ul class="mb-0 mt-1">
                        <li><strong>Credits only (no plan)</strong> — All ads show everywhere. 1 credit = 1 ad-free analysis (no video ad). Credits never expire.</li>
                        <li><strong>Subscription plan</strong> — All ads removed everywhere. Bonus credits included — 1 credit = 1 ad-free analysis. When bonus credits run out, video ad plays before analysis. Bonus credits expire when plan expires.</li>
                        <li>Prices here are <em>fallback display</em> only; actual charge is set in App Store Connect / Play Console.</li>
                        <li>Product IDs must match exactly in both stores.</li>
                    </ul>
                </div>

                <div class="row g-4">
                <?php
                $planMeta = [
                    'weekly'    => ['icon' => 'bi-calendar-week',   'color' => '#6366f1', 'label' => '1 Week'],
                    'monthly'   => ['icon' => 'bi-calendar-month',  'color' => '#f59e0b', 'label' => '1 Month'],
                    'quarterly' => ['icon' => 'bi-trophy',          'color' => '#10b981', 'label' => '3 Months'],
                ];
                foreach ($mergedPlans as $pid => $plan):
                    $meta = $planMeta[$pid] ?? ['icon' => 'bi-box', 'color' => '#6b7280', 'label' => $pid];
                    $featuresText = is_array($plan['features'] ?? null)
                        ? implode("\n", $plan['features'])
                        : '';
                ?>
                <div class="col-lg-4">
                    <div class="card h-100" style="border: 2px solid <?php echo $meta['color']; ?>33;">
                        <!-- Plan header -->
                        <div class="card-header d-flex justify-content-between align-items-center"
                             style="background: <?php echo $meta['color']; ?>18;">
                            <h6 class="mb-0">
                                <i class="bi <?php echo $meta['icon']; ?> me-2"
                                   style="color:<?php echo $meta['color']; ?>"></i>
                                <?php echo $meta['label']; ?>
                                <code class="ms-1 small" style="color:<?php echo $meta['color']; ?>88"><?php echo $pid; ?></code>
                            </h6>
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox"
                                    name="plan_<?php echo $pid; ?>_active"
                                    <?php echo ($plan['active'] ?? true) ? 'checked' : ''; ?>>
                                <label class="form-check-label small">Active</label>
                            </div>
                        </div>

                        <div class="card-body">
                            <!-- Display title -->
                            <div class="mb-3">
                                <label class="form-label fw-semibold">Display Title</label>
                                <input type="text" name="plan_<?php echo $pid; ?>_title"
                                    class="form-control"
                                    value="<?php echo htmlspecialchars($plan['title'] ?? ''); ?>"
                                    placeholder="e.g. 1 Month">
                            </div>

                            <!-- Product IDs -->
                            <div class="mb-3">
                                <label class="form-label fw-semibold">
                                    <i class="bi bi-google-play me-1" style="color:#3ddc84"></i>Android Product ID
                                </label>
                                <input type="text" name="plan_<?php echo $pid; ?>_pid_android"
                                    class="form-control form-control-sm font-monospace"
                                    value="<?php echo htmlspecialchars($plan['productIdAndroid'] ?? $pid); ?>"
                                    placeholder="<?php echo $pid; ?>">
                            </div>
                            <div class="mb-3">
                                <label class="form-label fw-semibold">
                                    <i class="bi bi-apple me-1"></i>iOS Product ID
                                </label>
                                <input type="text" name="plan_<?php echo $pid; ?>_pid_ios"
                                    class="form-control form-control-sm font-monospace"
                                    value="<?php echo htmlspecialchars($plan['productIdIOS'] ?? $pid); ?>"
                                    placeholder="<?php echo $pid; ?>">
                            </div>

                            <!-- Price & Duration row -->
                            <div class="row g-2 mb-3">
                                <div class="col-6">
                                    <label class="form-label fw-semibold">Display Price</label>
                                    <input type="text" name="plan_<?php echo $pid; ?>_price"
                                        class="form-control"
                                        value="<?php echo htmlspecialchars($plan['displayPrice'] ?? $plan['price'] ?? ''); ?>"
                                        placeholder="₹200">
                                    <small class="text-secondary">Fallback display only</small>
                                </div>
                                <div class="col-6">
                                    <label class="form-label fw-semibold">Duration (days)</label>
                                    <input type="number" name="plan_<?php echo $pid; ?>_duration"
                                        class="form-control"
                                        value="<?php echo (int)($plan['durationDays'] ?? 30); ?>"
                                        min="1" placeholder="30">
                                </div>
                            </div>

                            <!-- Bonus Credits & Badge row -->
                            <div class="row g-2 mb-3">
                                <div class="col-6">
                                    <label class="form-label fw-semibold">
                                        <i class="bi bi-stars text-warning me-1"></i>Bonus Credits
                                    </label>
                                    <input type="number" name="plan_<?php echo $pid; ?>_bonus"
                                        class="form-control"
                                        value="<?php echo (int)($plan['bonusCredits'] ?? 0); ?>"
                                        min="0" placeholder="25">
                                    <small class="text-secondary">Expire with plan</small>
                                </div>
                                <div class="col-6">
                                    <label class="form-label fw-semibold">Badge</label>
                                    <input type="text" name="plan_<?php echo $pid; ?>_badge"
                                        class="form-control"
                                        value="<?php echo htmlspecialchars($plan['badge'] ?? ''); ?>"
                                        placeholder="Popular">
                                    <label class="form-label fw-semibold mt-2">Savings Text</label>
                                    <input type="text" name="plan_<?php echo $pid; ?>_savings"
                                        class="form-control"
                                        value="<?php echo htmlspecialchars($plan['savings'] ?? ''); ?>"
                                        placeholder="Save 25%">
                                </div>
                            </div>

                            <!-- Features -->
                            <div class="mb-0">
                                <label class="form-label fw-semibold">
                                    Features <small class="text-secondary fw-normal">(one per line)</small>
                                </label>
                                <textarea name="plan_<?php echo $pid; ?>_features"
                                    class="form-control"
                                    rows="6"
                                    placeholder="All Ads Removed&#10;Unlimited AI Chart Analysis&#10;..."><?php echo htmlspecialchars($featuresText); ?></textarea>
                            </div>
                        </div>
                    </div>
                </div>
                <?php endforeach; ?>
                </div><!-- /.row -->

                <div class="mt-4 d-flex justify-content-end">
                    <button type="submit" class="btn btn-success btn-lg">
                        <i class="bi bi-cloud-upload me-2"></i>Save All Plans
                    </button>
                </div>
            </div>
        </div>
    </form>

    <!-- ═══ Credit Packs Configuration ═══════════════════════════════════ -->
    <form method="POST" action="" class="mt-5">
        <input type="hidden" name="action" value="save_credit_packs">
        <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <div>
                    <h5 class="card-title mb-1">
                        <i class="bi bi-coin me-2 text-warning"></i>Credit Packs
                        <span class="badge bg-success ms-2" style="font-size:0.7rem;">Live — no app update needed</span>
                    </h5>
                    <small class="text-secondary">Product IDs must match App Store Connect &amp; Play Console. Prices here are fallback — actual price from store (auto currency).</small>
                </div>
                <button type="submit" class="btn btn-success">
                    <i class="bi bi-cloud-upload me-1"></i>Save Credit Packs
                </button>
            </div>
            <div class="card-body">
                <div class="alert alert-info py-2 mb-4 small">
                    <i class="bi bi-info-circle me-1"></i>
                    <strong>How it works:</strong> User buys a credit pack → credits are added to their account permanently (never expire). 1 credit = 1 ad-free analysis. All other ads still show for credit-only users (no plan).
                </div>

                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Product ID</th>
                                <th>Credits</th>
                                <th>Fallback Price</th>
                                <th>Badge</th>
                                <th>Active</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($mergedCreditPacks as $i => $cp): ?>
                            <tr>
                                <td>
                                    <input type="text" name="cp_id[]" class="form-control form-control-sm font-monospace"
                                        value="<?php echo htmlspecialchars($cp['id'] ?? ''); ?>"
                                        placeholder="credits_100" style="min-width:140px;">
                                </td>
                                <td>
                                    <input type="number" name="cp_credits[]" class="form-control form-control-sm"
                                        value="<?php echo (int)($cp['credits'] ?? 0); ?>"
                                        min="1" style="width:90px;">
                                </td>
                                <td>
                                    <input type="text" name="cp_price[]" class="form-control form-control-sm"
                                        value="<?php echo htmlspecialchars($cp['price'] ?? ''); ?>"
                                        placeholder="₹150" style="width:100px;">
                                </td>
                                <td>
                                    <input type="text" name="cp_badge[]" class="form-control form-control-sm"
                                        value="<?php echo htmlspecialchars($cp['badge'] ?? ''); ?>"
                                        placeholder="Popular" style="width:110px;">
                                </td>
                                <td class="text-center">
                                    <div class="form-check form-switch d-inline-block">
                                        <input class="form-check-input" type="checkbox"
                                            name="cp_active[<?php echo $i; ?>]"
                                            <?php echo ($cp['active'] ?? true) ? 'checked' : ''; ?>>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>

                <div class="mt-3 d-flex justify-content-end">
                    <button type="submit" class="btn btn-success">
                        <i class="bi bi-cloud-upload me-2"></i>Save Credit Packs
                    </button>
                </div>
            </div>
        </div>
    </form>
</main>

<?php include __DIR__ . '/includes/footer.php'; ?>
