<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Plan presets (must match iap.php / subscription_service.dart)
$planPresets = [
    'weekly'    => ['label' => 'Weekly (1 Week)',    'credits' => 5,  'days' => 7,  'productId' => 'weekpro'],
    'monthly'   => ['label' => 'Monthly (1 Month)',  'credits' => 25, 'days' => 30, 'productId' => 'pro_monthly'],
    'quarterly' => ['label' => 'Quarterly (3 Months)', 'credits' => 50, 'days' => 90, 'productId' => 'pro_yearly'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: users.php');
        exit;
    }
    $action = $_POST['action'] ?? '';

    // ── Add Credits (single user) ──────────────────────────────────────
    if ($action === 'add_credits') {
        $userId = sanitizeFirebaseKey($_POST['user_id'] ?? '');
        $credits = (int)($_POST['credits'] ?? 0);

        if ($userId && $credits > 0) {
            $userResult = $firebase->get('users/' . $userId);
            $currentCredits = (int)($userResult['data']['credits'] ?? 0);

            $result = $firebase->update('users/' . $userId, [
                'credits' => $currentCredits + $credits,
            ]);

            if ($result['success']) {
                $firebase->push('users/' . $userId . '/purchases', [
                    'packageId' => 'admin_grant',
                    'credits' => $credits,
                    'grantedBy' => 'admin',
                    'timestamp' => date('c')
                ]);
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => "Added $credits credits successfully!"];
            } else {
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to add credits.'];
            }
        }
        header('Location: users.php');
        exit;
    }

    // ── Grant Premium Plan (single user) ───────────────────────────────
    if ($action === 'grant_premium_plan') {
        $userId = sanitizeFirebaseKey($_POST['user_id'] ?? '');
        $planKey = $_POST['plan_type'] ?? 'monthly';
        $plan = $planPresets[$planKey] ?? $planPresets['monthly'];

        if ($userId) {
            $expiryMs = (int)(microtime(true) * 1000) + ($plan['days'] * 86400 * 1000);
            $result = $firebase->update('users/' . $userId, [
                'isPremium'        => true,
                'planCredits'      => $plan['credits'],
                'planCreditsExpiry'=> $expiryMs,
                'activePlan'       => $planKey,
            ]);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => "Granted {$plan['label']} plan with {$plan['credits']} credits!"];
            } else {
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to grant plan.'];
            }
        }
        header('Location: users.php');
        exit;
    }

    // ── Remove Premium (single user) ───────────────────────────────────
    if ($action === 'remove_premium') {
        $userId = sanitizeFirebaseKey($_POST['user_id'] ?? '');
        if ($userId) {
            $result = $firebase->update('users/' . $userId, [
                'isPremium'        => false,
                'planCredits'      => 0,
                'planCreditsExpiry'=> 0,
                'activePlan'       => null,
            ]);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Premium removed.'];
            } else {
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to remove premium.'];
            }
        }
        header('Location: users.php');
        exit;
    }

    // ── Bulk: Grant Premium Plan to multiple users ─────────────────────
    if ($action === 'bulk_grant_premium') {
        $userIds = $_POST['bulk_user_ids'] ?? '';
        $planKey = $_POST['plan_type'] ?? 'monthly';
        $plan = $planPresets[$planKey] ?? $planPresets['monthly'];

        $ids = array_filter(array_map('trim', explode(',', $userIds)));
        $successCount = 0;

        foreach ($ids as $uid) {
            $uid = sanitizeFirebaseKey($uid);
            if (empty($uid)) continue;
            $expiryMs = (int)(microtime(true) * 1000) + ($plan['days'] * 86400 * 1000);
            $r = $firebase->update('users/' . $uid, [
                'isPremium'        => true,
                'planCredits'      => $plan['credits'],
                'planCreditsExpiry'=> $expiryMs,
                'activePlan'       => $planKey,
            ]);
            if ($r['success']) $successCount++;
        }

        $_SESSION['flash_message'] = [
            'type' => $successCount > 0 ? 'success' : 'error',
            'text' => $successCount > 0
                ? "Granted {$plan['label']} to $successCount user(s)!"
                : 'Failed to grant plan to any user.',
        ];
        header('Location: users.php');
        exit;
    }

    // ── Bulk: Add Credits to multiple users ────────────────────────────
    if ($action === 'bulk_add_credits') {
        $userIds = $_POST['bulk_user_ids'] ?? '';
        $credits = (int)($_POST['credits'] ?? 0);
        $ids = array_filter(array_map('trim', explode(',', $userIds)));
        $successCount = 0;

        if ($credits > 0) {
            foreach ($ids as $uid) {
                $uid = sanitizeFirebaseKey($uid);
                if (empty($uid)) continue;
                $ur = $firebase->get('users/' . $uid);
                $cur = (int)($ur['data']['credits'] ?? 0);
                $r = $firebase->update('users/' . $uid, ['credits' => $cur + $credits]);
                if ($r['success']) {
                    $successCount++;
                    $firebase->push('users/' . $uid . '/purchases', [
                        'packageId' => 'admin_bulk_grant',
                        'credits' => $credits,
                        'grantedBy' => 'admin',
                        'timestamp' => date('c'),
                    ]);
                }
            }
        }

        $_SESSION['flash_message'] = [
            'type' => $successCount > 0 ? 'success' : 'error',
            'text' => $successCount > 0
                ? "Added $credits credits to $successCount user(s)!"
                : 'Failed to add credits.',
        ];
        header('Location: users.php');
        exit;
    }

    // ── Bulk: Remove Premium from multiple users ───────────────────────
    if ($action === 'bulk_remove_premium') {
        $userIds = $_POST['bulk_user_ids'] ?? '';
        $ids = array_filter(array_map('trim', explode(',', $userIds)));
        $successCount = 0;

        foreach ($ids as $uid) {
            $uid = sanitizeFirebaseKey($uid);
            if (empty($uid)) continue;
            $r = $firebase->update('users/' . $uid, [
                'isPremium' => false, 'planCredits' => 0,
                'planCreditsExpiry' => 0, 'activePlan' => null,
            ]);
            if ($r['success']) $successCount++;
        }

        $_SESSION['flash_message'] = [
            'type' => $successCount > 0 ? 'success' : 'error',
            'text' => "Removed premium from $successCount user(s).",
        ];
        header('Location: users.php');
        exit;
    }

    // ── Legacy: Add plan credits (single user) ─────────────────────────
    if ($action === 'add_plan_credits') {
        $userId = sanitizeFirebaseKey($_POST['user_id'] ?? '');
        $planCredits = (int)($_POST['plan_credits'] ?? 0);
        $expiryDays = (int)($_POST['expiry_days'] ?? 30);

        if ($userId && $planCredits > 0) {
            $expiryMs = (int)(microtime(true) * 1000) + ($expiryDays * 86400 * 1000);
            $result = $firebase->update('users/' . $userId, [
                'planCredits' => $planCredits,
                'planCreditsExpiry' => $expiryMs,
            ]);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => "Granted $planCredits plan credits (expires in $expiryDays days)."];
            } else {
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Failed to grant plan credits.'];
            }
        }
        header('Location: users.php');
        exit;
    }
}

// Fetch all users
$usersResult = $firebase->get('users');
$users = [];

if ($usersResult['success'] && $usersResult['data']) {
    foreach ($usersResult['data'] as $id => $userData) {
        $userData['id'] = $id;
        $users[] = $userData;
    }
}

usort($users, function($a, $b) {
    return ($b['credits'] ?? 0) - ($a['credits'] ?? 0);
});

$guestCount = count(array_filter($users, function($u) {
    return ($u['isGuest'] ?? false) || (trim($u['email'] ?? '') === '');
}));

$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header d-flex justify-content-between align-items-center flex-wrap gap-2">
        <div>
            <h1>User Management</h1>
            <p>View and manage app users, credits, and subscriptions</p>
        </div>
    </div>

    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <!-- Stats -->
    <div class="row g-4 mb-4">
        <div class="col-md-3">
            <div class="stats-card"><div class="icon purple"><i class="bi bi-people"></i></div>
                <h3><?php echo count($users); ?></h3><p>Total Users</p></div>
        </div>
        <div class="col-md-3">
            <div class="stats-card"><div class="icon green"><i class="bi bi-star"></i></div>
                <h3><?php echo count(array_filter($users, fn($u) => ($u['isPremium'] ?? false))); ?></h3><p>Premium Users</p></div>
        </div>
        <div class="col-md-3">
            <div class="stats-card"><div class="icon blue"><i class="bi bi-coin"></i></div>
                <h3><?php echo array_sum(array_column($users, 'credits')); ?></h3><p>Total Credits</p></div>
        </div>
        <div class="col-md-3">
            <div class="stats-card"><div class="icon orange"><i class="bi bi-person-check"></i></div>
                <h3><?php echo count(array_filter($users, fn($u) => ($u['credits'] ?? 0) > 0)); ?></h3><p>Active Users</p></div>
        </div>
        <div class="col-md-3">
            <div class="stats-card"><div class="icon teal"><i class="bi bi-person-dash"></i></div>
                <h3><?php echo $guestCount; ?></h3><p>Guest Accounts</p></div>
        </div>
    </div>

    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <h5 class="card-title mb-0">All Users (<?php echo count($users); ?>)</h5>
            <div id="bulkBar" class="d-none d-flex gap-2 align-items-center">
                <span class="badge bg-primary" id="selectedCount">0</span> selected
                <button type="button" class="btn btn-sm btn-success" onclick="bulkGrantPremium()">
                    <i class="bi bi-star-fill me-1"></i>Grant Plan
                </button>
                <button type="button" class="btn btn-sm btn-primary" onclick="bulkAddCredits()">
                    <i class="bi bi-plus-circle me-1"></i>Credits
                </button>
                <button type="button" class="btn btn-sm btn-outline-danger" onclick="bulkRemovePremium()">
                    <i class="bi bi-x-circle me-1"></i>Remove Premium
                </button>
            </div>
        </div>
        <div class="card-body">
            <?php if (empty($users)): ?>
                <div class="text-center py-5">
                    <i class="bi bi-people text-secondary" style="font-size: 4rem;"></i>
                    <h5 class="mt-3">No Users Yet</h5>
                    <p class="text-secondary">Users will appear here once they sign up</p>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table" id="usersTable">
                        <thead>
                            <tr>
                                <th style="width:40px;"><input type="checkbox" id="selectAll" onclick="toggleSelectAll(this)"></th>
                                <th>Email</th>
                                <th>Credits</th>
                                <th>Plan</th>
                                <th>Status</th>
                                <th>Joined</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($users as $user): ?>
                                <tr>
                                    <?php
                                    $isGuestUser = ($user['isGuest'] ?? false) || (trim($user['email'] ?? '') === '');
                                    $displayEmail = $isGuestUser ? 'Guest' : ($user['email'] ?? 'Unknown');
                                    $pc = (int)($user['planCredits'] ?? 0);
                                    $pce = (int)($user['planCreditsExpiry'] ?? 0);
                                    $pcActive = ($pc > 0 && $pce > 0 && (microtime(true) * 1000) < $pce);
                                    $activePlan = $user['activePlan'] ?? '';
                                    $planLabel = isset($planPresets[$activePlan]) ? $planPresets[$activePlan]['label'] : '';
                                    ?>
                                    <td><input type="checkbox" class="user-check" value="<?php echo htmlspecialchars($user['id']); ?>" onclick="updateBulkBar()"></td>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <div class="avatar me-2" style="width:40px;height:40px;background:linear-gradient(135deg,var(--primary-color),#6366F1);border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:bold;">
                                                <?php echo strtoupper(substr($displayEmail, 0, 1)); ?>
                                            </div>
                                            <div>
                                                <strong><?php echo htmlspecialchars($displayEmail); ?></strong>
                                                <?php if ($isGuestUser): ?><span class="badge bg-info ms-1" style="font-size:0.7rem;">Guest</span><?php endif; ?>
                                                <small class="d-block text-secondary"><?php echo substr($user['id'], 0, 12); ?>...</small>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="badge bg-<?php echo ($user['credits'] ?? 0) > 0 ? 'success' : 'secondary'; ?>" style="font-size:0.85rem;">
                                            <?php echo number_format($user['credits'] ?? 0); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <?php if ($pcActive && $planLabel): ?>
                                            <span class="badge bg-primary" style="font-size:0.75rem;"><?php echo htmlspecialchars($planLabel); ?></span>
                                            <small class="d-block text-secondary"><?php echo $pc; ?> cr · exp <?php echo date('M j', $pce / 1000); ?></small>
                                        <?php elseif ($pcActive): ?>
                                            <span class="badge bg-primary" style="font-size:0.85rem;"><?php echo $pc; ?> cr</span>
                                            <small class="d-block text-secondary">exp <?php echo date('M j', $pce / 1000); ?></small>
                                        <?php elseif ($pc > 0): ?>
                                            <span class="badge bg-danger" style="font-size:0.75rem;">Expired</span>
                                        <?php else: ?>
                                            <span class="text-secondary">—</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php if ($user['isPremium'] ?? false): ?>
                                            <span class="badge bg-warning"><i class="bi bi-star-fill me-1"></i>Premium</span>
                                        <?php else: ?>
                                            <span class="badge bg-secondary">Free</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php
                                        $createdAt = $user['createdAt'] ?? null;
                                        echo $createdAt ? date('M j, Y', $createdAt / 1000) : '-';
                                        ?>
                                    </td>
                                    <td>
                                        <div class="btn-group">
                                            <button type="button" class="btn btn-sm btn-outline-primary"
                                                onclick="addCredits('<?php echo htmlspecialchars($user['id']); ?>', '<?php echo htmlspecialchars($displayEmail); ?>')">
                                                <i class="bi bi-plus-circle"></i>
                                            </button>
                                            <?php if ($user['isPremium'] ?? false): ?>
                                                <button type="button" class="btn btn-sm btn-outline-danger"
                                                    onclick="removePremium('<?php echo htmlspecialchars($user['id']); ?>', '<?php echo htmlspecialchars($displayEmail); ?>')">
                                                    <i class="bi bi-star-fill"></i><i class="bi bi-x-lg" style="font-size:0.6rem;margin-left:2px;"></i>
                                                </button>
                                            <?php else: ?>
                                                <button type="button" class="btn btn-sm btn-outline-success"
                                                    onclick="grantPremium('<?php echo htmlspecialchars($user['id']); ?>', '<?php echo htmlspecialchars($displayEmail); ?>')">
                                                    <i class="bi bi-star"></i><i class="bi bi-plus-lg" style="font-size:0.6rem;margin-left:2px;"></i>
                                                </button>
                                            <?php endif; ?>
                                        </div>
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

<!-- Add Credits Modal -->
<div class="modal fade" id="addCreditsModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-plus-circle me-2"></i>Add Credits</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="add_credits">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="user_id" id="creditUserId">
                    <div class="mb-3">
                        <label class="form-label">User</label>
                        <input type="text" id="creditUserEmail" class="form-control" readonly>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Credits to Add</label>
                        <input type="number" name="credits" class="form-control" value="10" min="1" required>
                    </div>
                    <div class="d-flex gap-2 flex-wrap">
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#addCreditsModal input[name=credits]').value=10">+10</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#addCreditsModal input[name=credits]').value=50">+50</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#addCreditsModal input[name=credits]').value=100">+100</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#addCreditsModal input[name=credits]').value=500">+500</button>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Add Credits</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Grant Premium Plan Modal (single user) -->
<div class="modal fade" id="grantPremiumModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-star-fill me-2 text-warning"></i>Grant Premium Plan</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="grant_premium_plan">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="user_id" id="grantPremiumUserId">
                    <div class="mb-3">
                        <label class="form-label">User</label>
                        <input type="text" id="grantPremiumEmail" class="form-control" readonly>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Select Plan</label>
                        <div class="d-flex flex-column gap-2">
                            <?php foreach ($planPresets as $key => $preset): ?>
                            <label class="d-flex align-items-center p-3 rounded border <?php echo $key === 'monthly' ? 'border-warning' : ''; ?>" style="cursor:pointer;background:rgba(139,92,246,0.04);">
                                <input type="radio" name="plan_type" value="<?php echo $key; ?>" class="form-check-input me-3" <?php echo $key === 'monthly' ? 'checked' : ''; ?>>
                                <div class="flex-grow-1">
                                    <strong><?php echo $preset['label']; ?></strong>
                                    <?php if ($key === 'monthly'): ?><span class="badge bg-warning text-dark ms-1" style="font-size:0.65rem;">Popular</span><?php endif; ?>
                                    <small class="d-block text-secondary"><?php echo $preset['credits']; ?> bonus credits · expires in <?php echo $preset['days']; ?> days</small>
                                </div>
                            </label>
                            <?php endforeach; ?>
                        </div>
                    </div>
                    <div class="alert alert-info py-2 small mb-0">
                        <i class="bi bi-info-circle me-1"></i>
                        Sets <strong>isPremium = true</strong>, grants plan credits, and sets expiry.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success"><i class="bi bi-star-fill me-2"></i>Grant Plan</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Bulk Grant Premium Modal -->
<div class="modal fade" id="bulkPremiumModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-people-fill me-2 text-warning"></i>Bulk Grant Premium Plan</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="bulk_grant_premium">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="bulk_user_ids" id="bulkPremiumUserIds">
                    <div class="mb-3">
                        <label class="form-label"><strong id="bulkPremiumCount">0</strong> users selected</label>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Select Plan for All</label>
                        <div class="d-flex flex-column gap-2">
                            <?php foreach ($planPresets as $key => $preset): ?>
                            <label class="d-flex align-items-center p-3 rounded border" style="cursor:pointer;background:rgba(139,92,246,0.04);">
                                <input type="radio" name="plan_type" value="<?php echo $key; ?>" class="form-check-input me-3" <?php echo $key === 'monthly' ? 'checked' : ''; ?>>
                                <div class="flex-grow-1">
                                    <strong><?php echo $preset['label']; ?></strong>
                                    <small class="d-block text-secondary"><?php echo $preset['credits']; ?> credits · <?php echo $preset['days']; ?> days</small>
                                </div>
                            </label>
                            <?php endforeach; ?>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success"><i class="bi bi-star-fill me-2"></i>Grant to All Selected</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Bulk Add Credits Modal -->
<div class="modal fade" id="bulkCreditsModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-people-fill me-2 text-primary"></i>Bulk Add Credits</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="bulk_add_credits">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="bulk_user_ids" id="bulkCreditsUserIds">
                    <div class="mb-3">
                        <label class="form-label"><strong id="bulkCreditsCount">0</strong> users selected</label>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Credits to Add (each user)</label>
                        <input type="number" name="credits" class="form-control" value="10" min="1" required>
                    </div>
                    <div class="d-flex gap-2 flex-wrap">
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#bulkCreditsModal input[name=credits]').value=10">+10</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#bulkCreditsModal input[name=credits]').value=50">+50</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#bulkCreditsModal input[name=credits]').value=100">+100</button>
                        <button type="button" class="btn btn-outline-primary btn-sm" onclick="document.querySelector('#bulkCreditsModal input[name=credits]').value=500">+500</button>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="bi bi-plus-lg me-2"></i>Add Credits to All</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Bulk Remove Premium Form -->
<form id="bulkRemoveForm" method="POST" action="" style="display:none;">
    <input type="hidden" name="action" value="bulk_remove_premium">
    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
    <input type="hidden" name="bulk_user_ids" id="bulkRemoveUserIds">
</form>

<!-- Single Remove Premium Form -->
<form id="removePremiumForm" method="POST" action="" style="display:none;">
    <input type="hidden" name="action" value="remove_premium">
    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
    <input type="hidden" name="user_id" id="removePremiumUserId">
</form>

<script>
function getSelectedIds() {
    return Array.from(document.querySelectorAll('.user-check:checked')).map(c => c.value);
}

function updateBulkBar() {
    const ids = getSelectedIds();
    const bar = document.getElementById('bulkBar');
    const countBadge = document.getElementById('selectedCount');
    if (ids.length > 0) {
        bar.classList.remove('d-none');
        countBadge.textContent = ids.length;
    } else {
        bar.classList.add('d-none');
    }
}

function toggleSelectAll(master) {
    document.querySelectorAll('.user-check').forEach(cb => cb.checked = master.checked);
    updateBulkBar();
}

function addCredits(userId, email) {
    document.getElementById('creditUserId').value = userId;
    document.getElementById('creditUserEmail').value = email;
    new bootstrap.Modal(document.getElementById('addCreditsModal')).show();
}

function grantPremium(userId, email) {
    document.getElementById('grantPremiumUserId').value = userId;
    document.getElementById('grantPremiumEmail').value = email;
    new bootstrap.Modal(document.getElementById('grantPremiumModal')).show();
}

function removePremium(userId, email) {
    Swal.fire({
        title: 'Remove Premium?',
        text: `Remove premium from ${email}? This clears plan credits too.`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#EF4444',
        cancelButtonColor: '#6B7280',
        confirmButtonText: 'Yes, remove',
        background: '#1A1A2E',
        color: '#F8FAFC'
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('removePremiumUserId').value = userId;
            document.getElementById('removePremiumForm').submit();
        }
    });
}

function bulkGrantPremium() {
    const ids = getSelectedIds();
    if (!ids.length) return;
    document.getElementById('bulkPremiumUserIds').value = ids.join(',');
    document.getElementById('bulkPremiumCount').textContent = ids.length;
    new bootstrap.Modal(document.getElementById('bulkPremiumModal')).show();
}

function bulkAddCredits() {
    const ids = getSelectedIds();
    if (!ids.length) return;
    document.getElementById('bulkCreditsUserIds').value = ids.join(',');
    document.getElementById('bulkCreditsCount').textContent = ids.length;
    new bootstrap.Modal(document.getElementById('bulkCreditsModal')).show();
}

function bulkRemovePremium() {
    const ids = getSelectedIds();
    if (!ids.length) return;
    Swal.fire({
        title: 'Bulk Remove Premium?',
        text: `Remove premium from ${ids.length} user(s)? This clears all plan credits.`,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#EF4444',
        cancelButtonColor: '#6B7280',
        confirmButtonText: 'Yes, remove all',
        background: '#1A1A2E',
        color: '#F8FAFC'
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('bulkRemoveUserIds').value = ids.join(',');
            document.getElementById('bulkRemoveForm').submit();
        }
    });
}
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>

<script>
$(document).ready(function() {
    if ($('#usersTable tbody tr').length > 0) {
        initDataTable('#usersTable', { columnDefs: [{ orderable: false, targets: [0, 6] }] });
    }
});
</script>
