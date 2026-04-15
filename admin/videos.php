<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $_SESSION['flash_message'] = ['type' => 'error', 'text' => 'Invalid CSRF token. Please refresh and try again.'];
        header('Location: videos.php');
        exit;
    }
    $action = $_POST['action'] ?? '';
    
    if ($action === 'add') {
        $title = trim($_POST['title'] ?? '');
        $subTitle = trim($_POST['sub_title'] ?? '');
        $videoUrl = trim($_POST['video_url'] ?? '');
        
        if ($title && $videoUrl) {
            $result = $firebase->addVideo($title, $subTitle, $videoUrl);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Video added successfully!'];
            } else {
                $errorMsg = 'Failed to add video.';
                if (!empty($result['error'])) {
                    $errorMsg .= ' Error: ' . $result['error'];
                }
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => $errorMsg];
            }
        }
        header('Location: videos.php');
        exit;
    }
    
    if ($action === 'update') {
        $id = sanitizeFirebaseKey($_POST['id'] ?? '');
        $title = trim($_POST['title'] ?? '');
        $subTitle = trim($_POST['sub_title'] ?? '');
        $videoUrl = trim($_POST['video_url'] ?? '');
        
        if ($id && $title && $videoUrl) {
            $result = $firebase->updateVideo($id, $title, $subTitle, $videoUrl);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Video updated successfully!'];
            } else {
                $errorMsg = 'Failed to update video.';
                if (!empty($result['error'])) {
                    $errorMsg .= ' Error: ' . $result['error'];
                }
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => $errorMsg];
            }
        }
        header('Location: videos.php');
        exit;
    }
    
    if ($action === 'delete') {
        $id = sanitizeFirebaseKey($_POST['id'] ?? '');
        if ($id) {
            $result = $firebase->deleteVideo($id);
            if ($result['success']) {
                $_SESSION['flash_message'] = ['type' => 'success', 'text' => 'Video deleted successfully!'];
            } else {
                $errorMsg = 'Failed to delete video.';
                if (!empty($result['error'])) {
                    $errorMsg .= ' Error: ' . $result['error'];
                }
                $_SESSION['flash_message'] = ['type' => 'error', 'text' => $errorMsg];
            }
        }
        header('Location: videos.php');
        exit;
    }
}

// Fetch videos
$videosResult = $firebase->getVideos();
$videos = $videosResult['data'] ?? [];

// Get flash message
$flashMessage = $_SESSION['flash_message'] ?? null;
unset($_SESSION['flash_message']);

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/sidebar.php';
?>

<main class="main-content">
    <div class="page-header d-flex justify-content-between align-items-center">
        <div>
            <h1>Video Management</h1>
            <p>Add, edit and manage tutorial videos</p>
        </div>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addVideoModal">
            <i class="bi bi-plus-lg me-2"></i>Add Video
        </button>
    </div>
    
    <?php if ($flashMessage): ?>
        <div class="alert alert-<?php echo $flashMessage['type'] === 'success' ? 'success' : 'danger'; ?> alert-dismissible fade show" role="alert">
            <i class="bi bi-<?php echo $flashMessage['type'] === 'success' ? 'check-circle' : 'exclamation-circle'; ?> me-2"></i>
            <?php echo htmlspecialchars($flashMessage['text']); ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>
    
    <div class="card">
        <div class="card-header">
            <h5 class="card-title mb-0">All Videos (<?php echo count($videos); ?>)</h5>
        </div>
        <div class="card-body">
            <?php if (empty($videos)): ?>
                <div class="text-center py-5">
                    <i class="bi bi-play-circle text-secondary" style="font-size: 4rem;"></i>
                    <h5 class="mt-3">No Videos Found</h5>
                    <p class="text-secondary">Start by adding your first tutorial video</p>
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addVideoModal">
                        <i class="bi bi-plus-lg me-2"></i>Add Video
                    </button>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table" id="videosTable">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Title</th>
                                <th>Subtitle</th>
                                <th>Video URL</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($videos as $index => $video): ?>
                                <tr>
                                    <td><?php echo $index + 1; ?></td>
                                    <td>
                                        <strong><?php echo htmlspecialchars($video['title'] ?? ''); ?></strong>
                                    </td>
                                    <td><?php echo htmlspecialchars($video['sub_title'] ?? ''); ?></td>
                                    <td>
                                        <a href="<?php echo htmlspecialchars($video['video_url'] ?? ''); ?>" target="_blank" class="text-primary text-truncate d-inline-block" style="max-width: 200px;">
                                            <?php echo htmlspecialchars($video['video_url'] ?? ''); ?>
                                        </a>
                                    </td>
                                    <td>
                                        <div class="btn-group">
                                            <button type="button" class="btn btn-sm btn-outline-primary" 
                                                data-id="<?php echo htmlspecialchars($video['id']); ?>"
                                                data-title="<?php echo htmlspecialchars($video['title'] ?? ''); ?>"
                                                data-subtitle="<?php echo htmlspecialchars($video['sub_title'] ?? ''); ?>"
                                                data-url="<?php echo htmlspecialchars($video['video_url'] ?? ''); ?>"
                                                onclick="editVideo(this.dataset.id, this.dataset.title, this.dataset.subtitle, this.dataset.url)">
                                                <i class="bi bi-pencil"></i>
                                            </button>
                                            <button type="button" class="btn btn-sm btn-outline-danger" onclick="deleteVideo('<?php echo htmlspecialchars($video['id']); ?>')">
                                                <i class="bi bi-trash"></i>
                                            </button>
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

<!-- Add Video Modal -->
<div class="modal fade" id="addVideoModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-plus-circle me-2"></i>Add New Video</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="add">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    
                    <div class="mb-3">
                        <label class="form-label">Video Title *</label>
                        <input type="text" name="title" class="form-control" placeholder="Enter video title" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Subtitle</label>
                        <input type="text" name="sub_title" class="form-control" placeholder="Enter subtitle (optional)">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Video URL *</label>
                        <input type="url" name="video_url" class="form-control" placeholder="https://youtube.com/watch?v=..." required>
                        <small class="text-secondary">YouTube, Vimeo or direct video URL</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-plus-lg me-2"></i>Add Video
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Video Modal -->
<div class="modal fade" id="editVideoModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-pencil me-2"></i>Edit Video</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="POST" action="">
                <div class="modal-body">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
                    <input type="hidden" name="id" id="editVideoId">
                    
                    <div class="mb-3">
                        <label class="form-label">Video Title *</label>
                        <input type="text" name="title" id="editVideoTitle" class="form-control" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Subtitle</label>
                        <input type="text" name="sub_title" id="editVideoSubtitle" class="form-control">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Video URL *</label>
                        <input type="url" name="video_url" id="editVideoUrl" class="form-control" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg me-2"></i>Update Video
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Delete Form -->
<form id="deleteForm" method="POST" action="" style="display: none;">
    <input type="hidden" name="action" value="delete">
    <input type="hidden" name="csrf_token" value="<?php echo generateCSRFToken(); ?>">
    <input type="hidden" name="id" id="deleteVideoId">
</form>

<script>
function editVideo(id, title, subtitle, url) {
    document.getElementById('editVideoId').value = id;
    document.getElementById('editVideoTitle').value = title;
    document.getElementById('editVideoSubtitle').value = subtitle;
    document.getElementById('editVideoUrl').value = url;
    new bootstrap.Modal(document.getElementById('editVideoModal')).show();
}

function deleteVideo(id) {
    Swal.fire({
        title: 'Delete Video?',
        text: 'This action cannot be undone!',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#EF4444',
        cancelButtonColor: '#6B7280',
        confirmButtonText: 'Yes, delete it!',
        background: '#1A1A2E',
        color: '#F8FAFC'
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('deleteVideoId').value = id;
            document.getElementById('deleteForm').submit();
        }
    });
}
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>

<script>
$(document).ready(function() {
    if ($('#videosTable tbody tr').length > 0) {
        initDataTable('#videosTable');
    }
});
</script>
