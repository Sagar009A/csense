<?php
require_once __DIR__ . '/../config/config.php';

// Get current page for active menu
$currentPage = basename($_SERVER['PHP_SELF'], '.php');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo SITE_NAME; ?></title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    
    <!-- DataTables -->
    <link href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #8B5CF6;
            --primary-dark: #7C3AED;
            --secondary-color: #6366F1;
            --success-color: #10B981;
            --danger-color: #EF4444;
            --warning-color: #F59E0B;
            --info-color: #3B82F6;
            --dark-bg: #0F0F1A;
            --card-bg: #1A1A2E;
            --sidebar-bg: #12121F;
            --text-primary: #F8FAFC;
            --text-secondary: #94A3B8;
            --border-color: #2D2D3A;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', sans-serif;
            background: var(--dark-bg);
            color: var(--text-primary);
            min-height: 100vh;
        }
        
        /* Sidebar Styles */
        .sidebar {
            position: fixed;
            top: 0;
            left: 0;
            width: 280px;
            height: 100vh;
            background: var(--sidebar-bg);
            border-right: 1px solid var(--border-color);
            z-index: 1000;
            transition: all 0.3s ease;
        }
        
        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .sidebar-header h4 {
            color: var(--primary-color);
            font-weight: 700;
            margin: 0;
            font-size: 1.25rem;
        }
        
        .sidebar-header span {
            color: var(--text-secondary);
            font-size: 0.75rem;
        }
        
        .sidebar-nav {
            padding: 20px 0;
        }
        
        .nav-item {
            margin: 5px 15px;
        }
        
        .nav-link {
            display: flex;
            align-items: center;
            padding: 12px 15px;
            color: var(--text-secondary);
            text-decoration: none;
            border-radius: 10px;
            transition: all 0.3s ease;
        }
        
        .nav-link:hover {
            background: rgba(139, 92, 246, 0.1);
            color: var(--primary-color);
        }
        
        .nav-link.active {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
        }
        
        .nav-link i {
            font-size: 1.25rem;
            margin-right: 12px;
            width: 24px;
            text-align: center;
        }
        
        .nav-section-title {
            padding: 15px 20px 5px;
            font-size: 0.7rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-secondary);
        }
        
        /* Main Content */
        .main-content {
            margin-left: 280px;
            padding: 30px;
            min-height: 100vh;
        }
        
        /* Cards */
        .card {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 16px;
        }
        
        .card-header {
            background: transparent;
            border-bottom: 1px solid var(--border-color);
            padding: 20px;
        }
        
        .card-title {
            margin: 0;
            color: var(--text-primary);
            font-weight: 600;
        }
        
        /* Stats Cards */
        .stats-card {
            background: linear-gradient(135deg, var(--card-bg), rgba(139, 92, 246, 0.1));
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 25px;
            position: relative;
            overflow: hidden;
        }
        
        .stats-card::before {
            content: '';
            position: absolute;
            top: 0;
            right: 0;
            width: 100px;
            height: 100px;
            background: var(--primary-color);
            opacity: 0.1;
            border-radius: 50%;
            transform: translate(30%, -30%);
        }
        
        .stats-card .icon {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            margin-bottom: 15px;
        }
        
        .stats-card .icon.purple { background: rgba(139, 92, 246, 0.2); color: var(--primary-color); }
        .stats-card .icon.blue { background: rgba(59, 130, 246, 0.2); color: var(--info-color); }
        .stats-card .icon.green { background: rgba(16, 185, 129, 0.2); color: var(--success-color); }
        .stats-card .icon.orange { background: rgba(245, 158, 11, 0.2); color: var(--warning-color); }
        .stats-card .icon.teal { background: rgba(20, 184, 166, 0.2); color: #14b8a6; }
        
        .stats-card h3 {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .stats-card p {
            color: var(--text-secondary);
            margin: 0;
        }
        
        /* Forms */
        .form-control, .form-select {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            color: var(--text-primary);
            padding: 12px 15px;
            border-radius: 10px;
        }
        
        .form-control:focus, .form-select:focus {
            background: rgba(255, 255, 255, 0.08);
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
            color: var(--text-primary);
        }
        
        .form-control::placeholder {
            color: var(--text-secondary);
        }
        
        .form-label {
            color: var(--text-secondary);
            font-size: 0.875rem;
            margin-bottom: 8px;
        }
        
        /* Buttons */
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            border: none;
            padding: 12px 24px;
            border-radius: 10px;
            font-weight: 500;
            transition: all 0.3s ease;
        }
        
        .btn-primary:hover {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary-color));
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(139, 92, 246, 0.4);
        }
        
        .btn-outline-primary {
            border: 1px solid var(--primary-color);
            color: var(--primary-color);
            padding: 12px 24px;
            border-radius: 10px;
        }
        
        .btn-outline-primary:hover {
            background: var(--primary-color);
            color: white;
        }
        
        .btn-danger {
            background: var(--danger-color);
            border: none;
        }
        
        .btn-success {
            background: var(--success-color);
            border: none;
        }
        
        /* Tables */
        .table {
            color: var(--text-primary);
        }
        
        .table thead th {
            background: rgba(139, 92, 246, 0.1);
            border-bottom: 1px solid var(--border-color);
            color: var(--text-secondary);
            font-weight: 500;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.5px;
            padding: 15px;
        }
        
        .table tbody td {
            border-bottom: 1px solid var(--border-color);
            padding: 15px;
            vertical-align: middle;
        }
        
        .table tbody tr:hover {
            background: rgba(139, 92, 246, 0.05);
        }
        
        /* Switches */
        .form-switch .form-check-input {
            width: 48px;
            height: 24px;
            background-color: var(--border-color);
            border: none;
            cursor: pointer;
        }
        
        .form-switch .form-check-input:checked {
            background-color: var(--primary-color);
        }
        
        .form-switch .form-check-input:focus {
            box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.2);
        }
        
        /* Badge */
        .badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-weight: 500;
        }
        
        .badge.bg-success { background: rgba(16, 185, 129, 0.2) !important; color: var(--success-color); }
        .badge.bg-danger { background: rgba(239, 68, 68, 0.2) !important; color: var(--danger-color); }
        .badge.bg-warning { background: rgba(245, 158, 11, 0.2) !important; color: var(--warning-color); }
        .badge.bg-info { background: rgba(59, 130, 246, 0.2) !important; color: var(--info-color); }
        
        /* Modal */
        .modal-content {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 16px;
        }
        
        .modal-header {
            border-bottom: 1px solid var(--border-color);
        }
        
        .modal-footer {
            border-top: 1px solid var(--border-color);
        }
        
        .btn-close {
            filter: invert(1);
        }
        
        /* Page Header */
        .page-header {
            margin-bottom: 30px;
        }
        
        .page-header h1 {
            font-size: 1.75rem;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .page-header p {
            color: var(--text-secondary);
            margin: 0;
        }
        
        /* DataTables */
        .dataTables_wrapper .dataTables_filter input {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            color: var(--text-primary);
            border-radius: 8px;
            padding: 8px 12px;
        }
        
        .dataTables_wrapper .dataTables_length select {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            color: var(--text-primary);
            border-radius: 8px;
        }
        
        .dataTables_wrapper .dataTables_info {
            color: var(--text-secondary);
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button {
            color: var(--text-secondary) !important;
            border: none;
            background: transparent;
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
            background: var(--primary-color) !important;
            color: white !important;
            border-radius: 8px;
        }
        
        /* Loading Spinner */
        .spinner-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(15, 15, 26, 0.8);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 9999;
        }
        
        /* Responsive */
        @media (max-width: 991px) {
            .sidebar {
                transform: translateX(-100%);
            }
            
            .sidebar.show {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0;
            }
        }
    </style>
</head>
<body>
