/// Web Preview Screen
/// Shown when running on web without Firebase (e.g. Chrome for UI testing)
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class WebPreviewScreen extends StatelessWidget {
  const WebPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.laptop_chromebook_rounded,
                size: 80.w,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              SizedBox(height: 24.h),
              Text(
                'Stock Scanner AI',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'Web preview – Firebase is not configured for browser.\n\n'
                'For full experience (login, scans, videos), run the app on Android or iOS.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Text(
                'Chrome run is for UI/layout check only.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
