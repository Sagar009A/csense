    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    
    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    
    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.6/js/dataTables.bootstrap5.min.js"></script>
    
    <script>
        // CSRF Token for AJAX requests
        const csrfToken = '<?php echo generateCSRFToken(); ?>';
        
        // Toast notification helper
        function showToast(type, message) {
            const Toast = Swal.mixin({
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000,
                timerProgressBar: true,
                background: '#1A1A2E',
                color: '#F8FAFC',
            });
            
            Toast.fire({
                icon: type,
                title: message
            });
        }
        
        // Confirm dialog helper
        function confirmAction(title, text, confirmText = 'Yes, do it!') {
            return Swal.fire({
                title: title,
                text: text,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#8B5CF6',
                cancelButtonColor: '#6B7280',
                confirmButtonText: confirmText,
                cancelButtonText: 'Cancel',
                background: '#1A1A2E',
                color: '#F8FAFC'
            });
        }
        
        // Loading overlay helpers
        function showLoading() {
            $('body').append('<div class="spinner-overlay" id="loadingOverlay"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div></div>');
        }
        
        function hideLoading() {
            $('#loadingOverlay').remove();
        }
        
        // Initialize DataTables with dark theme
        function initDataTable(selector, options = {}) {
            const defaultOptions = {
                pageLength: 10,
                responsive: true,
                language: {
                    search: '',
                    searchPlaceholder: 'Search...',
                    lengthMenu: 'Show _MENU_ entries'
                }
            };
            
            return $(selector).DataTable({...defaultOptions, ...options});
        }
    </script>
</body>
</html>
