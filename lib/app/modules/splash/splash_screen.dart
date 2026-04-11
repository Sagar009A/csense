/// Splash Screen
/// Professional animated splash with subtle stock theme
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import 'splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Deep link: show minimal loading screen while we wait for the safe navigate delay
    if (controller.isDirectLinkLaunch) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight.withValues(alpha: 0.9),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Opening video...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0D12),
              const Color(0xFF12121A),
              const Color(0xFF0D0D12),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background chart lines (professional, low opacity)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _StockChartPainter(
                      progress: controller.animationController.value,
                    ),
                  );
                },
              ),
            ),
            // Soft top accent (no harsh glow)
            Positioned(
              top: -80.h,
              right: -80.w,
              child: Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40.h,
              left: -40.w,
              child: Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: controller.fadeAnimation,
                    child: ScaleTransition(
                      scale: controller.scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with subtle container
                          Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.asset(
                                AppAssets.appLogo,
                                height: 120.h,
                                width: 120.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 36.h),
                          // App name – clean, single color
                          Text(
                            'ChartSense AI',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Tagline – subtle
                          Text(
                            'AI-Powered Stock Analysis',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 72.h),
                          // Minimal loading indicator
                          SizedBox(
                            width: 40.w,
                            height: 40.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryLight.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subtle chart lines – professional, low opacity
class _StockChartPainter extends CustomPainter {
  final double progress;

  _StockChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final yOffset = size.height * 0.35 + (i * size.height * 0.18);
      final path = Path();

      paint.color = i == 1
          ? AppColors.primaryLight.withValues(alpha: 0.12 * progress)
          : Colors.white.withValues(alpha: 0.06 * progress);

      path.moveTo(0, yOffset);
      final points = _generateChartPoints(size, yOffset, i);
      for (int j = 1; j < points.length; j++) {
        if (j / points.length <= progress) {
          final p0 = points[j - 1];
          final p1 = points[j];
          final controlX = (p0.dx + p1.dx) / 2;
          path.quadraticBezierTo(controlX, p0.dy, p1.dx, p1.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  List<Offset> _generateChartPoints(Size size, double baseY, int seed) {
    final random = math.Random(seed * 42);
    final List<Offset> points = [];
    const segments = 12;
    for (int i = 0; i <= segments; i++) {
      final x = (size.width / segments) * i;
      final variation = (random.nextDouble() - 0.5) * size.height * 0.08;
      points.add(Offset(x, baseY + variation));
    }
    return points;
  }

  @override
  bool shouldRepaint(_StockChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
