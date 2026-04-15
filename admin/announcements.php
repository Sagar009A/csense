<?php
require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/firebase.php';

requireLogin();

$firebase = new Firebase();
$currentPage = 'announcements';

// Fetch current announcement
$result = $firebase->get('announcement');
$announcement = ($result['success'] && !empty($result['data'])) ? $result['data'] : null;
?>
<?php include __DIR__ . '/includes/header.php'; ?>
<?php include __DIR__ . '/includes/sidebar.php'; ?>

<div class="main-content">
    <!-- Page Header -->
    <div class="page-header d-flex justify-content-between align-items-center flex-wrap gap-3">
        <div>
            <h1><i class="bi bi-megaphone-fill me-2" style="color:var(--primary-color)"></i>App Announcements</h1>
            <p>Show a popup announcement to users when they open the home screen.</p>
        </div>
        <?php if ($announcement && !empty($announcement['is_active'])): ?>
            <span class="badge bg-success fs-6"><i class="bi bi-broadcast me-1"></i>Active</span>
        <?php else: ?>
            <span class="badge bg-danger fs-6"><i class="bi bi-pause-circle me-1"></i>Inactive</span>
        <?php endif; ?>
    </div>

    <div class="row g-4">
        <!-- ── Announcement Form ───────────────────────────── -->
        <div class="col-lg-7">
            <div class="card">
                <div class="card-header d-flex align-items-center gap-2">
                    <i class="bi bi-pencil-square" style="color:var(--primary-color)"></i>
                    <h5 class="card-title mb-0">
                        <?= $announcement ? 'Edit Announcement' : 'Create Announcement' ?>
                    </h5>
                </div>
                <div class="card-body p-4">
                    <form id="announcementForm">
                        <!-- Title -->
                        <div class="mb-3">
                            <label class="form-label">Title <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="title" name="title"
                                   placeholder="e.g. New Feature Available!"
                                   value="<?= htmlspecialchars($announcement['title'] ?? '') ?>" required>
                        </div>

                        <!-- Message -->
                        <div class="mb-3">
                            <label class="form-label">Message <span class="text-danger">*</span></label>
                            <textarea class="form-control" id="message" name="message" rows="4"
                                      placeholder="Write your announcement message here..."
                                      required><?= htmlspecialchars($announcement['message'] ?? '') ?></textarea>
                        </div>

                        <!-- Image URL (optional) -->
                        <div class="mb-3">
                            <label class="form-label">
                                <i class="bi bi-image me-1"></i>Banner Image URL
                                <span class="text-secondary" style="font-size:0.8em">(optional)</span>
                            </label>
                            <input type="url" class="form-control" id="image_url" name="image_url"
                                   placeholder="https://example.com/banner.jpg"
                                   value="<?= htmlspecialchars($announcement['image_url'] ?? '') ?>"
                                   oninput="previewImage(this.value)">
                            <div class="form-text">Leave empty for text-only announcement popup.</div>

                            <!-- Image Preview -->
                            <div id="imagePreviewBox" class="mt-2 <?= empty($announcement['image_url']) ? 'd-none' : '' ?>">
                                <img id="imagePreview"
                                     src="<?= htmlspecialchars($announcement['image_url'] ?? '') ?>"
                                     alt="Preview"
                                     class="rounded"
                                     style="max-height:160px;max-width:100%;object-fit:cover;border:1px solid var(--border-color)">
                            </div>
                        </div>

                        <!-- CTA Button (optional) -->
                        <div class="row g-3 mb-3">
                            <div class="col-md-5">
                                <label class="form-label">
                                    <i class="bi bi-cursor me-1"></i>Button Text
                                    <span class="text-secondary" style="font-size:0.8em">(optional)</span>
                                </label>
                                <input type="text" class="form-control" id="button_text" name="button_text"
                                       placeholder="e.g. Learn More"
                                       value="<?= htmlspecialchars($announcement['button_text'] ?? '') ?>">
                            </div>
                            <div class="col-md-7">
                                <label class="form-label">Button URL
                                    <span class="text-secondary" style="font-size:0.8em">(optional)</span>
                                </label>
                                <input type="url" class="form-control" id="button_url" name="button_url"
                                       placeholder="https://..."
                                       value="<?= htmlspecialchars($announcement['button_url'] ?? '') ?>">
                            </div>
                        </div>

                        <!-- Options Row -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <div class="p-3 rounded" style="background:rgba(255,255,255,0.04);border:1px solid var(--border-color)">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_active" name="is_active"
                                               <?= (!$announcement || !empty($announcement['is_active'])) ? 'checked' : '' ?>>
                                        <label class="form-check-label" for="is_active">
                                            <strong>Active</strong><br>
                                            <span class="text-secondary" style="font-size:0.8em">Show this announcement to users</span>
                                        </label>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="p-3 rounded" style="background:rgba(255,255,255,0.04);border:1px solid var(--border-color)">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="show_once" name="show_once"
                                               <?= (!$announcement || !isset($announcement['show_once']) || !empty($announcement['show_once'])) ? 'checked' : '' ?>>
                                        <label class="form-check-label" for="show_once">
                                            <strong>Show Once Per User</strong><br>
                                            <span class="text-secondary" style="font-size:0.8em">Each user sees it only once</span>
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Buttons -->
                        <div class="d-flex gap-2 flex-wrap">
                            <button type="submit" class="btn btn-primary" id="saveBtn">
                                <i class="bi bi-save me-1"></i>
                                <?= $announcement ? 'Update Announcement' : 'Publish Announcement' ?>
                            </button>
                            <?php if ($announcement): ?>
                                <button type="button" class="btn btn-danger" id="deleteBtn" onclick="deleteAnnouncement()">
                                    <i class="bi bi-trash me-1"></i>Delete
                                </button>
                            <?php endif; ?>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- ── Live Preview + Info ────────────────────────── -->
        <div class="col-lg-5">
            <!-- Live Phone Preview -->
            <div class="card mb-4">
                <div class="card-header d-flex align-items-center gap-2">
                    <i class="bi bi-phone" style="color:var(--primary-color)"></i>
                    <h5 class="card-title mb-0">Live Preview</h5>
                </div>
                <div class="card-body p-3 d-flex justify-content-center">
                    <!-- Phone mockup -->
                    <div style="
                        width: 240px;
                        background: #111;
                        border-radius: 32px;
                        padding: 12px;
                        border: 3px solid #333;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.5);
                    ">
                        <div style="background:#1a1a2e;border-radius:22px;min-height:420px;overflow:hidden;position:relative;display:flex;align-items:center;justify-content:center;padding:16px">
                            <!-- Blur overlay -->
                            <div style="position:absolute;inset:0;background:rgba(0,0,0,0.6);backdrop-filter:blur(2px);border-radius:22px"></div>

                            <!-- Popup card -->
                            <div style="position:relative;width:100%;background:#fff;border-radius:20px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.4)">
                                <!-- Close button -->
                                <div style="position:absolute;top:8px;right:8px;z-index:10;
                                            width:26px;height:26px;background:#333;border-radius:50%;
                                            display:flex;align-items:center;justify-content:center;cursor:pointer">
                                    <i class="bi bi-x" style="color:#fff;font-size:14px;line-height:1"></i>
                                </div>

                                <!-- Image -->
                                <div id="previewImgWrap">
                                    <?php if (!empty($announcement['image_url'])): ?>
                                        <img src="<?= htmlspecialchars($announcement['image_url']) ?>"
                                             id="previewImg"
                                             style="width:100%;height:110px;object-fit:cover;display:block">
                                    <?php else: ?>
                                        <div id="previewImgPlaceholder"
                                             style="width:100%;height:80px;background:linear-gradient(135deg,#8B5CF6,#6366F1);display:flex;align-items:center;justify-content:center">
                                            <i class="bi bi-megaphone-fill" style="color:rgba(255,255,255,0.5);font-size:28px"></i>
                                        </div>
                                    <?php endif; ?>
                                </div>

                                <!-- Content -->
                                <div style="padding:12px 12px 14px">
                                    <p id="previewTitle" style="font-weight:700;font-size:13px;color:#111;margin:0 0 5px;line-height:1.3">
                                        <?= htmlspecialchars($announcement['title'] ?? 'Announcement Title') ?>
                                    </p>
                                    <p id="previewMsg" style="font-size:11px;color:#555;margin:0 0 10px;line-height:1.4">
                                        <?= htmlspecialchars($announcement['message'] ?? 'Your announcement message will appear here.') ?>
                                    </p>
                                    <!-- CTA Button -->
                                    <div id="previewBtnWrap" style="<?= empty($announcement['button_text']) ? 'display:none' : '' ?>">
                                        <div id="previewBtn" style="
                                            background:linear-gradient(135deg,#8B5CF6,#6366F1);
                                            color:#fff;font-size:11px;font-weight:600;
                                            padding:7px 12px;border-radius:10px;text-align:center">
                                            <?= htmlspecialchars($announcement['button_text'] ?? 'Learn More') ?>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Home bar -->
                        <div style="height:4px;background:#333;border-radius:2px;width:60px;margin:8px auto 0"></div>
                    </div>
                </div>
            </div>

            <!-- Info Card -->
            <div class="card">
                <div class="card-header">
                    <h6 class="card-title mb-0"><i class="bi bi-info-circle me-1"></i>How It Works</h6>
                </div>
                <div class="card-body p-3">
                    <ul class="list-unstyled mb-0" style="font-size:0.85rem;color:var(--text-secondary)">
                        <li class="mb-2"><i class="bi bi-check-circle text-success me-1"></i>Popup shows when user opens the <strong>home screen</strong>.</li>
                        <li class="mb-2"><i class="bi bi-check-circle text-success me-1"></i>Works on <strong>Android &amp; iOS</strong>.</li>
                        <li class="mb-2"><i class="bi bi-check-circle text-success me-1"></i>Optional <strong>banner image</strong> support.</li>
                        <li class="mb-2"><i class="bi bi-check-circle text-success me-1"></i>Optional <strong>CTA button</strong> that opens a URL.</li>
                        <li class="mb-2"><i class="bi bi-check-circle text-success me-1"></i>When <em>Show Once</em> is ON, user sees it only once. Turn it OFF to show every time.</li>
                        <li><i class="bi bi-check-circle text-success me-1"></i>Each save generates a new announcement ID — <strong>existing users will see it again</strong>.</li>
                    </ul>
                </div>
            </div>
        </div>
    </div><!-- /row -->
</div><!-- /main-content -->

<script>
// ── Image preview ────────────────────────────────────────────────────────────
function previewImage(url) {
    const box  = document.getElementById('imagePreviewBox');
    const img  = document.getElementById('imagePreview');
    const pImg = document.getElementById('previewImg');
    const pPh  = document.getElementById('previewImgPlaceholder');

    if (url && url.startsWith('http')) {
        if (img)  { img.src  = url; box.classList.remove('d-none'); }
        if (pImg) { pImg.src = url; pImg.style.display = 'block'; if (pPh) pPh.style.display = 'none'; }
        else {
            // Create img element dynamically
            const newImg = document.createElement('img');
            newImg.id    = 'previewImg';
            newImg.src   = url;
            newImg.style.cssText = 'width:100%;height:110px;object-fit:cover;display:block';
            document.getElementById('previewImgWrap').innerHTML = '';
            document.getElementById('previewImgWrap').appendChild(newImg);
        }
    } else {
        if (box) box.classList.add('d-none');
        document.getElementById('previewImgWrap').innerHTML =
            '<div id="previewImgPlaceholder" style="width:100%;height:80px;background:linear-gradient(135deg,#8B5CF6,#6366F1);display:flex;align-items:center;justify-content:center">' +
            '<i class="bi bi-megaphone-fill" style="color:rgba(255,255,255,0.5);font-size:28px"></i></div>';
    }
}

// ── Live preview updates ─────────────────────────────────────────────────────
document.getElementById('title').addEventListener('input', function () {
    document.getElementById('previewTitle').textContent = this.value || 'Announcement Title';
});
document.getElementById('message').addEventListener('input', function () {
    document.getElementById('previewMsg').textContent = this.value || 'Your announcement message will appear here.';
});
document.getElementById('button_text').addEventListener('input', function () {
    const wrap = document.getElementById('previewBtnWrap');
    const btn  = document.getElementById('previewBtn');
    if (this.value) { wrap.style.display = 'block'; btn.textContent = this.value; }
    else            { wrap.style.display = 'none'; }
});
document.getElementById('image_url').addEventListener('input', function () {
    previewImage(this.value);
});

// ── Form submit ──────────────────────────────────────────────────────────────
document.getElementById('announcementForm').addEventListener('submit', async function (e) {
    e.preventDefault();
    const btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Saving...';

    const payload = {
        action     : 'save',
        title      : document.getElementById('title').value.trim(),
        message    : document.getElementById('message').value.trim(),
        image_url  : document.getElementById('image_url').value.trim(),
        button_text: document.getElementById('button_text').value.trim(),
        button_url : document.getElementById('button_url').value.trim(),
        is_active  : document.getElementById('is_active').checked  ? 1 : 0,
        show_once  : document.getElementById('show_once').checked   ? 1 : 0,
    };

    try {
        const res  = await fetch('api/announcements.php', {
            method : 'POST',
            headers: {'Content-Type': 'application/json'},
            body   : JSON.stringify(payload),
        });
        const data = await res.json();

        if (data.success) {
            Swal.fire({ icon: 'success', title: 'Saved!', text: data.message, confirmButtonColor: '#8B5CF6' })
                .then(() => location.reload());
        } else {
            Swal.fire({ icon: 'error', title: 'Error', text: data.message, confirmButtonColor: '#8B5CF6' });
        }
    } catch (err) {
        Swal.fire({ icon: 'error', title: 'Network Error', text: err.message, confirmButtonColor: '#8B5CF6' });
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-save me-1"></i>Update Announcement';
    }
});

// ── Delete ───────────────────────────────────────────────────────────────────
async function deleteAnnouncement() {
    const confirm = await Swal.fire({
        icon             : 'warning',
        title            : 'Delete Announcement?',
        text             : 'Users will no longer see any popup. This cannot be undone.',
        showCancelButton : true,
        confirmButtonText: 'Yes, Delete',
        confirmButtonColor: '#EF4444',
        cancelButtonColor : '#6B7280',
    });
    if (!confirm.isConfirmed) return;

    const btn = document.getElementById('deleteBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Deleting...';

    try {
        const res  = await fetch('api/announcements.php', {
            method : 'POST',
            headers: {'Content-Type': 'application/json'},
            body   : JSON.stringify({ action: 'delete' }),
        });
        const data = await res.json();

        if (data.success) {
            Swal.fire({ icon: 'success', title: 'Deleted!', text: 'Announcement removed.', confirmButtonColor: '#8B5CF6' })
                .then(() => location.reload());
        } else {
            Swal.fire({ icon: 'error', title: 'Error', text: data.message, confirmButtonColor: '#8B5CF6' });
        }
    } catch (err) {
        Swal.fire({ icon: 'error', title: 'Network Error', text: err.message, confirmButtonColor: '#8B5CF6' });
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-trash me-1"></i>Delete';
    }
}
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>
