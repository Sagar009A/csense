/// Connectivity Service
/// Monitors internet connection with stream-based checking
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';

class ConnectivityService extends GetxService {
  final RxBool isConnected = true.obs;
  Timer? _checkTimer;
  bool _wasConnected = true;

  Future<ConnectivityService> init() async {
    // Initial check
    await checkConnectivity();
    _wasConnected = isConnected.value;

    // Show dialog if initial check fails
    if (!isConnected.value) {
      Future.delayed(const Duration(milliseconds: 500), showNoInternetDialog);
    }

    // Start continuous monitoring
    _startMonitoring();

    return this;
  }

  void _startMonitoring() {
    // Check every 5 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await checkConnectivity();

      // Show dialog when connection drops
      if (_wasConnected && !isConnected.value) {
        showNoInternetDialog();
      }

      // Auto-close dialog when connection restores
      if (!_wasConnected && isConnected.value) {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }

      _wasConnected = isConnected.value;
    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      isConnected.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isConnected.value = false;
    } on TimeoutException catch (_) {
      isConnected.value = false;
    } catch (_) {
      isConnected.value = false;
    }

    return isConnected.value;
  }

  /// Show no internet dialog
  void showNoInternetDialog() {
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      _NoInternetDialog(
        onRetry: () async {
          final connected = await checkConnectivity();
          if (connected) {
            Get.back();
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    _checkTimer?.cancel();
    super.onClose();
  }
}

/// Beautiful No Internet Dialog
class _NoInternetDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoInternetDialog({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 40.w,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            SizedBox(height: 24.h),
            // Retry button
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beautiful Exit Dialog
class ExitDialog {
  static void show() {
    final isDark = Get.isDarkMode;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  size: 36.w,
                  color: AppColors.primaryLight,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Exit App?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to exit?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: 24.h),
              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2D2D2D)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Exit button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => exit(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Center(
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
