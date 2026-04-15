<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase    = new Firebase();
$currentPage = 'analytics';

// ── Fetch all analysis_stats from Firebase ──────────────────────────────────
$statsResult = $firebase->get('analysis_stats');
$rawStats    = [];
if ($statsResult['success'] && !empty($statsResult['data']) && is_array($statsResult['data'])) {
    $rawStats = $statsResult['data'];   // keyed by YYYY-MM-DD
    ksort($rawStats);                   // ensure chronological order
}

// ── Auto-purge entries older than 90 days (server-side safety net) ──────────
$cutoff    = date('Y-m-d', strtotime('-90 days'));
$toDelete  = [];
foreach ($rawStats as $dateKey => $count) {
    if ($dateKey < $cutoff) {
        $toDelete[] = $dateKey;
        unset($rawStats[$dateKey]);
    }
}
if (!empty($toDelete)) {
    $deletePayload = [];
    foreach ($toDelete as $k) {
        $deletePayload[$k] = null;
    }
    $firebase->update('analysis_stats', $deletePayload);
}

// ── Time boundaries ─────────────────────────────────────────────────────────
$tz          = new DateTimeZone('Asia/Kolkata');
$now         = new DateTime('now', $tz);
$todayKey    = $now->format('Y-m-d');
$weekStart   = (clone $now)->modify('monday this week')->format('Y-m-d');
$monthStart  = $now->format('Y-m-01');

// ── Aggregate counters ──────────────────────────────────────────────────────
$todayCount  = 0;
$weekCount   = 0;
$monthCount  = 0;
$totalCount  = 0;

foreach ($rawStats as $dateKey => $count) {
    $count = (int)$count;
    $totalCount += $count;
    if ($dateKey === $todayKey)               $todayCount  += $count;
    if ($dateKey >= $weekStart)              $weekCount   += $count;
    if ($dateKey >= $monthStart)             $monthCount  += $count;
}

// ── Build last-3-months daily chart data ────────────────────────────────────
// Generate every day from 89 days ago → today
$chartLabels = [];
$chartValues = [];
$threeMonthsAgo = (clone $now)->modify('-89 days');

$cursor = clone $threeMonthsAgo;
while ($cursor <= $now) {
    $key           = $cursor->format('Y-m-d');
    $chartLabels[] = $cursor->format('d M');   // e.g. "21 Nov"
    $chartValues[] = (int)($rawStats[$key] ?? 0);
    $cursor->modify('+1 day');
}

// ── Monthly aggregates for bar chart (last 3 full calendar months + current) ─
$monthlyData = [];
for ($i = 2; $i >= 0; $i--) {
    $mStart = (clone $now)->modify("-$i month")->format('Y-m-01');
    $mEnd   = (clone $now)->modify("-$i month")->format('Y-m-t');
    $mLabel = date('M Y', strtotime($mStart));
    $mCount = 0;
    foreach ($rawStats as $dateKey => $cnt) {
        if ($dateKey >= $mStart && $dateKey <= $mEnd) {
            $mCount += (int)$cnt;
        }
    }
    $monthlyData[] = ['label' => $mLabel, 'count' => $mCount];
}

// ── Top 5 busiest days ───────────────────────────────────────────────────────
arsort($rawStats);
$topDays = array_slice($rawStats, 0, 5, true);

// ── Yesterday / last week delta ──────────────────────────────────────────────
$yesterdayKey  = (clone $now)->modify('-1 day')->format('Y-m-d');
$yesterdayCount = (int)($rawStats[$yesterdayKey] ?? 0);
$todayVsYesterday = $yesterdayCount > 0
    ? round((($todayCount - $yesterdayCount) / $yesterdayCount) * 100, 1)
    : ($todayCount > 0 ? 100 : 0);

?>
<?php include __DIR__ . '/includes/header.php'; ?>
<?php include __DIR__ . '/includes/sidebar.php'; ?>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

<div class="main-content">
    <!-- Page Header -->
    <div class="page-header d-flex justify-content-between align-items-center flex-wrap gap-3">
        <div>
            <h1><i class="bi bi-bar-chart-fill me-2" style="color:var(--primary-color)"></i>Analysis Analytics</h1>
            <p>Track how many AI chart analyses are performed by your users.</p>
        </div>
        <div class="d-flex align-items-center gap-2">
            <span class="badge" style="background:rgba(139,92,246,0.15);color:var(--primary-color);font-size:0.85rem;padding:8px 14px">
                <i class="bi bi-database me-1"></i>Last 90 days · Auto-cleanup ON
            </span>
            <button class="btn btn-sm btn-outline-primary" onclick="location.reload()">
                <i class="bi bi-arrow-clockwise me-1"></i>Refresh
            </button>
        </div>
    </div>

    <!-- ── KPI Cards ────────────────────────────────────────────────────────── -->
    <div class="row g-4 mb-4">
        <!-- Today -->
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon purple"><i class="bi bi-sun"></i></div>
                <h3 class="mb-1"><?= number_format($todayCount) ?></h3>
                <p class="mb-1">Today</p>
                <small style="color:<?= $todayVsYesterday >= 0 ? 'var(--success-color)' : 'var(--danger-color)' ?>">
                    <i class="bi bi-arrow-<?= $todayVsYesterday >= 0 ? 'up' : 'down' ?>-short"></i>
                    <?= abs($todayVsYesterday) ?>% vs yesterday
                </small>
            </div>
        </div>
        <!-- This Week -->
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon blue"><i class="bi bi-calendar-week"></i></div>
                <h3 class="mb-1"><?= number_format($weekCount) ?></h3>
                <p class="mb-0">This Week</p>
            </div>
        </div>
        <!-- This Month -->
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon green"><i class="bi bi-calendar-month"></i></div>
                <h3 class="mb-1"><?= number_format($monthCount) ?></h3>
                <p class="mb-0">This Month</p>
            </div>
        </div>
        <!-- 3-Month Total -->
        <div class="col-6 col-lg-3">
            <div class="stats-card">
                <div class="icon orange"><i class="bi bi-graph-up-arrow"></i></div>
                <h3 class="mb-1"><?= number_format($totalCount) ?></h3>
                <p class="mb-0">Last 90 Days</p>
            </div>
        </div>
    </div>

    <!-- ── Charts Row ────────────────────────────────────────────────────────── -->
    <div class="row g-4 mb-4">
        <!-- Daily trend (last 90 days) -->
        <div class="col-lg-8">
            <div class="card h-100">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="card-title mb-0"><i class="bi bi-activity me-2" style="color:var(--primary-color)"></i>Daily Analyses — Last 90 Days</h5>
                </div>
                <div class="card-body" style="position:relative;min-height:300px">
                    <canvas id="dailyChart"></canvas>
                </div>
            </div>
        </div>

        <!-- Monthly bar chart -->
        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-bar-chart me-2" style="color:var(--primary-color)"></i>Monthly Summary</h5>
                </div>
                <div class="card-body" style="position:relative;min-height:300px">
                    <canvas id="monthlyChart"></canvas>
                </div>
            </div>
        </div>
    </div>

    <!-- ── Bottom Row: Busiest Days + Calendar Heatmap ────────────────────── -->
    <div class="row g-4">
        <!-- Top Busiest Days -->
        <div class="col-lg-5">
            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0"><i class="bi bi-trophy me-2" style="color:var(--warning-color)"></i>Top 5 Busiest Days</h5>
                </div>
                <div class="card-body p-0">
                    <?php if (empty($topDays)): ?>
                        <div class="text-center py-5">
                            <i class="bi bi-bar-chart text-secondary" style="font-size:2.5rem"></i>
                            <p class="text-secondary mt-2 mb-0">No analysis data yet</p>
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table mb-0">
                                <thead>
                                    <tr>
                                        <th style="width:40px">#</th>
                                        <th>Date</th>
                                        <th>Analyses</th>
                                        <th>Bar</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php
                                    $maxVal  = max(array_values($topDays) ?: [1]);
                                    $rank    = 1;
                                    foreach ($topDays as $dateKey => $cnt):
                                        $pct = $maxVal > 0 ? round(($cnt / $maxVal) * 100) : 0;
                                        $medals = ['🥇','🥈','🥉'];
                                        $medal  = $medals[$rank - 1] ?? $rank;
                                    ?>
                                        <tr>
                                            <td><?= $medal ?></td>
                                            <td><strong><?= date('d M Y', strtotime($dateKey)) ?></strong><br>
                                                <small class="text-secondary"><?= date('l', strtotime($dateKey)) ?></small>
                                            </td>
                                            <td><span class="badge" style="background:rgba(139,92,246,0.2);color:var(--primary-color);font-size:0.9rem"><?= number_format((int)$cnt) ?></span></td>
                                            <td style="min-width:80px">
                                                <div style="background:var(--border-color);border-radius:4px;height:8px">
                                                    <div style="background:linear-gradient(90deg,#8B5CF6,#6366F1);border-radius:4px;height:8px;width:<?= $pct ?>%"></div>
                                                </div>
                                            </td>
                                        </tr>
                                    <?php $rank++; endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <!-- Recent Days Table -->
        <div class="col-lg-7">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="card-title mb-0"><i class="bi bi-clock-history me-2" style="color:var(--info-color)"></i>Last 14 Days — Daily Detail</h5>
                </div>
                <div class="card-body p-0">
                    <?php
                    $last14 = [];
                    for ($i = 0; $i < 14; $i++) {
                        $dk = (clone $now)->modify("-$i day")->format('Y-m-d');
                        $last14[$dk] = (int)($rawStats[$dk] ?? 0);
                    }
                    $maxLast14 = max(array_values($last14) ?: [1]);
                    ?>
                    <div class="table-responsive">
                        <table class="table mb-0">
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Day</th>
                                    <th>Analyses</th>
                                    <th>Trend</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($last14 as $dk => $cnt):
                                    $pct  = $maxLast14 > 0 ? round(($cnt / $maxLast14) * 100) : 0;
                                    $isToday = ($dk === $todayKey);
                                ?>
                                    <tr <?= $isToday ? 'style="background:rgba(139,92,246,0.07)"' : '' ?>>
                                        <td>
                                            <?= date('d M Y', strtotime($dk)) ?>
                                            <?php if ($isToday): ?><span class="badge bg-success ms-1" style="font-size:0.65rem">Today</span><?php endif; ?>
                                        </td>
                                        <td class="text-secondary" style="font-size:0.85rem"><?= date('D', strtotime($dk)) ?></td>
                                        <td><strong><?= number_format($cnt) ?></strong></td>
                                        <td style="min-width:100px">
                                            <div style="background:var(--border-color);border-radius:4px;height:6px">
                                                <div style="background:linear-gradient(90deg,#3B82F6,#8B5CF6);border-radius:4px;height:6px;width:<?= $pct ?>%;transition:width 0.5s"></div>
                                            </div>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div><!-- /row -->
</div><!-- /main-content -->

<script>
// ── Chart.js global defaults ────────────────────────────────────────────────
Chart.defaults.color          = '#94A3B8';
Chart.defaults.borderColor    = 'rgba(255,255,255,0.06)';
Chart.defaults.font.family    = 'Inter, sans-serif';

// ── Daily Line Chart ────────────────────────────────────────────────────────
(function () {
    const labels = <?= json_encode($chartLabels) ?>;
    const values = <?= json_encode($chartValues) ?>;

    // Show every 7th label to avoid clutter
    const displayLabels = labels.map((l, i) => (i % 7 === 0) ? l : '');

    const ctx = document.getElementById('dailyChart').getContext('2d');

    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0,   'rgba(139,92,246,0.45)');
    gradient.addColorStop(1,   'rgba(139,92,246,0)');

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: displayLabels,
            datasets: [{
                label: 'Analyses',
                data: values,
                borderColor: '#8B5CF6',
                backgroundColor: gradient,
                borderWidth: 2,
                pointRadius: values.map((v, i) => v > 0 ? 3 : 0),
                pointBackgroundColor: '#8B5CF6',
                fill: true,
                tension: 0.4,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        title: (items) => {
                            const idx = items[0].dataIndex;
                            return <?= json_encode($chartLabels) ?>[idx];
                        },
                        label: (item) => ` ${item.raw} analyses`,
                    }
                }
            },
            scales: {
                x: {
                    grid: { color: 'rgba(255,255,255,0.04)' },
                    ticks: { maxRotation: 0 }
                },
                y: {
                    grid: { color: 'rgba(255,255,255,0.04)' },
                    beginAtZero: true,
                    ticks: { precision: 0 }
                }
            }
        }
    });
})();

// ── Monthly Bar Chart ────────────────────────────────────────────────────────
(function () {
    const labels = <?= json_encode(array_column($monthlyData, 'label')) ?>;
    const values = <?= json_encode(array_column($monthlyData, 'count')) ?>;

    const ctx = document.getElementById('monthlyChart').getContext('2d');

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels,
            datasets: [{
                label: 'Analyses',
                data: values,
                backgroundColor: [
                    'rgba(99,102,241,0.7)',
                    'rgba(139,92,246,0.7)',
                    'rgba(167,139,250,0.7)',
                ],
                borderRadius: 10,
                borderSkipped: false,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: { label: (item) => ` ${item.raw} analyses` }
                }
            },
            scales: {
                x: { grid: { display: false } },
                y: {
                    grid: { color: 'rgba(255,255,255,0.04)' },
                    beginAtZero: true,
                    ticks: { precision: 0 }
                }
            }
        }
    });
})();
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
