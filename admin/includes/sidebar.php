<!-- Sidebar -->
<nav class="sidebar" id="sidebar">
    <div class="sidebar-header">
        <h4><i class="bi bi-graph-up-arrow"></i> Stock AI Scanner</h4>
        <span>Admin Panel v1.0</span>
    </div>
    
    <div class="sidebar-nav">
        <div class="nav-section-title">Main Menu</div>
        
        <div class="nav-item">
            <a href="index.php" class="nav-link <?php echo $currentPage === 'index' ? 'active' : ''; ?>">
                <i class="bi bi-house-door"></i>
                Dashboard
            </a>
        </div>
        
        <div class="nav-item">
            <a href="analytics.php" class="nav-link <?php echo $currentPage === 'analytics' ? 'active' : ''; ?>">
                <i class="bi bi-bar-chart-fill"></i>
                Analytics
            </a>
        </div>
        
        <div class="nav-section-title">Content Management</div>
        
        <div class="nav-item">
            <a href="videos.php" class="nav-link <?php echo $currentPage === 'videos' ? 'active' : ''; ?>">
                <i class="bi bi-play-circle"></i>
                Video Management
            </a>
        </div>
        
        <div class="nav-section-title">Monetization</div>
        
        <div class="nav-item">
            <a href="ads.php" class="nav-link <?php echo $currentPage === 'ads' ? 'active' : ''; ?>">
                <i class="bi bi-megaphone"></i>
                AdMob Settings
            </a>
        </div>
        
        <div class="nav-item">
            <a href="iap.php" class="nav-link <?php echo $currentPage === 'iap' ? 'active' : ''; ?>">
                <i class="bi bi-credit-card"></i>
                In-App Purchases
            </a>
        </div>
        
        <div class="nav-section-title">Engagement</div>
        
        <div class="nav-item">
            <a href="announcements.php" class="nav-link <?php echo $currentPage === 'announcements' ? 'active' : ''; ?>">
                <i class="bi bi-megaphone-fill"></i>
                Announcements
            </a>
        </div>
        
        <div class="nav-item">
            <a href="notifications.php" class="nav-link <?php echo $currentPage === 'notifications' ? 'active' : ''; ?>">
                <i class="bi bi-bell"></i>
                Push Notifications
            </a>
        </div>
        
        <div class="nav-item">
            <a href="users.php" class="nav-link <?php echo $currentPage === 'users' ? 'active' : ''; ?>">
                <i class="bi bi-people"></i>
                User Management
            </a>
        </div>
        
        <div class="nav-section-title">Settings</div>
        
        <div class="nav-item">
            <a href="settings.php" class="nav-link <?php echo $currentPage === 'settings' ? 'active' : ''; ?>">
                <i class="bi bi-gear"></i>
                App Settings
            </a>
        </div>
        
        <div class="nav-item">
            <a href="firebase_check.php" class="nav-link <?php echo $currentPage === 'firebase_check' ? 'active' : ''; ?>">
                <i class="bi bi-shield-check"></i>
                Firebase Check
            </a>
        </div>
        
        <div class="nav-item">
            <a href="logout.php" class="nav-link">
                <i class="bi bi-box-arrow-right"></i>
                Logout
            </a>
        </div>
    </div>
</nav>

<!-- Mobile Menu Toggle -->
<button class="btn btn-primary d-lg-none position-fixed" style="top: 15px; left: 15px; z-index: 1001;" onclick="toggleSidebar()">
    <i class="bi bi-list"></i>
</button>

<script>
function toggleSidebar() {
    document.getElementById('sidebar').classList.toggle('show');
}
</script>
