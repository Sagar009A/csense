/// Purchase Screen
/// Premium subscription + credit pack purchase UI with glassmorphism and animations
library;

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../services/app_config_service.dart';
import '../../services/credit_service.dart';
import 'purchase_controller.dart';

class PurchaseScreen extends GetView<PurchaseController> {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _AnimatedBackground(isDark: isDark),

          // Floating particles
          const _FloatingParticles(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 4.h),
                        _buildHeroSection(isDark),
                        SizedBox(height: 24.h),
                        _buildSubscriptionTab(isDark),
                        SizedBox(height: 20.h),
                        _buildRestoreButton(isDark),
                        SizedBox(height: 16.h),
                        Obx(() {
                          final plan = controller.plans[controller.selectedPlanIndex.value];
                          return _buildFeaturesList(isDark, plan);
                        }),
                        SizedBox(height: 16.h),
                        _buildTermsText(isDark),
                        SizedBox(height: 12.h),
                        _buildSecurityBadge(isDark),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          // Back button with glassmorphic background
          _GlassContainer(
            isDark: isDark,
            borderRadius: 12.r,
            padding: EdgeInsets.all(8.r),
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12.r),
              child: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                size: 22.w,
              ),
            ),
          ),
          const Spacer(),
          // Credits badge
          Obx(() {
            if (Get.isRegistered<CreditService>()) {
              return _GlassContainer(
                isDark: isDark,
                borderRadius: 20.r,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GradientIcon(
                      icon: Icons.stars_rounded,
                      size: 18.w,
                      colors: const [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${CreditService.to.credits.value}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ─── Hero Section ────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDark) {
    return Column(
      children: [
        // Animated crown with glow
        _PulsingGlow(
          glowColor: const Color(0xFFFFD700),
          child: Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 44.w,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Title with gradient text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFC084FC), Color(0xFFFFD700)],
          ).createShader(bounds),
          child: Text(
            'Go Premium',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          'Unlock unlimited access with a subscription',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
            letterSpacing: 0.2,
          ),
        ),

        // Active subscription badge
        Obx(() {
          if (!controller.isSubscribed.value) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: EdgeInsets.only(top: 12.h),
            child: _GlassContainer(
              isDark: isDark,
              borderRadius: 24.r,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              borderColor: AppColors.successLight.withValues(alpha: 0.4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.successLight.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Subscription Active',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successLight,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.verified_rounded,
                      color: AppColors.successLight, size: 16.w),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Subscription Tab ────────────────────────────────────────────────
  Widget _buildSubscriptionTab(bool isDark) {
    return Column(
      children: [
        // Store availability notice
        Obx(() {
          if (!controller.isPurchasing.value && !controller.isStoreAvailable) {
            return _buildStoreUnavailableCard(isDark);
          }
          return const SizedBox.shrink();
        }),
        _buildPlanCards(isDark),
        SizedBox(height: 24.h),
        _buildSubscribeButton(isDark),
      ],
    );
  }

  Widget _buildStoreUnavailableCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store_rounded,
            color: Colors.orange,
            size: 28.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Not Available',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'In-app purchases are temporarily unavailable. Please try again later.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(bool isDark) {
    return Obx(
      () => Row(
        children: List.generate(
          controller.plans.length,
          (index) => Expanded(
            child: _buildPlanCard(
              index: index,
              plan: controller.plans[index],
              isSelected: controller.selectedPlanIndex.value == index,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required Map<String, dynamic> plan,
    required bool isSelected,
    required bool isDark,
  }) {
    final badge = plan['badge'] as String?;
    final savings = plan['savings'] as String?;
    final isBestValue = badge == 'Best Value';
    final isPopular = badge == 'Popular';

    final List<Color> gradientColors = isBestValue
        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
        : isPopular
            ? [const Color(0xFF8B5CF6), const Color(0xFFC084FC)]
            : [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];

    return GestureDetector(
      onTap: () => controller.selectPlan(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withValues(alpha: isDark ? 0.2 : 0.12),
                    gradientColors[1].withValues(alpha: isDark ? 0.1 : 0.06),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? gradientColors[0].withValues(alpha: 0.6)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (badge == null) SizedBox(height: 18.h),

            SizedBox(height: 10.h),

            // Plan Title
            Text(
              plan['title'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? (isSelected ? Colors.white : Colors.white60)
                    : (isSelected
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight),
              ),
            ),

            SizedBox(height: 6.h),

            // Price with gradient when selected
            isSelected
                ? ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(colors: gradientColors)
                            .createShader(bounds),
                    child: Text(
                      controller.getPlanPrice(plan),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Text(
                    controller.getPlanPrice(plan),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    ),
                  ),

            SizedBox(height: 2.h),

            Text(
              '/${plan['duration']}',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.white30 : AppColors.textSecondaryLight,
              ),
            ),

            // Savings tag
            if (savings != null) ...[
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.successLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  savings,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successLight,
                  ),
                ),
              ),
            ],
            if (savings == null) SizedBox(height: 20.h),

            SizedBox(height: 8.h),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        width: 2,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 14.w, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(bool isDark) {
    return Obx(() {
      final selectedPlan = controller.plans[controller.selectedPlanIndex.value];
      final localPrice = controller.getPlanPrice(selectedPlan);
      final duration = selectedPlan['duration'] as String;

      return SizedBox(
        width: double.infinity,
        height: 58.h,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFC084FC)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isPurchasing.value
                ? null
                : controller.purchaseSelected,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
            child: controller.isPurchasing.value
                ? SizedBox(
                    width: 26.w,
                    height: 26.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 22.w, color: Colors.white),
                      SizedBox(width: 8.w),
                      Text(
                        'Subscribe for $localPrice/$duration',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // ─── Restore Button ──────────────────────────────────────────────────
  Widget _buildRestoreButton(bool isDark) {
    return Obx(() => GestureDetector(
          onTap: controller.isPurchasing.value
              ? null
              : controller.restorePurchases,
          child: _GlassContainer(
            isDark: isDark,
            borderRadius: 14.r,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restore_rounded,
                    size: 20.w, color: AppColors.primaryLight),
                SizedBox(width: 8.w),
                Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // ─── Features List ───────────────────────────────────────────────────
  /// Returns icon + color for a feature based on its text content.
  Map<String, dynamic> _featureWithIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('all ads removed') || lower.contains('banner')) {
      return {'icon': Icons.block_rounded, 'color': const Color(0xFF06B6D4)};
    } else if (lower.contains('video ad resumes') || lower.contains('run out')) {
      return {'icon': Icons.info_outline_rounded, 'color': const Color(0xFFFFA500)};
    } else if (lower.contains('credits included') || lower.contains('ad-free anal')) {
      return {'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF8B5CF6)};
    } else if (lower.contains('credits valid') || lower.contains('expire')) {
      return {'icon': Icons.timer_outlined, 'color': const Color(0xFF06B6D4)};
    } else if (lower.contains('video streaming') || lower.contains('streaming')) {
      return {'icon': Icons.play_circle_rounded, 'color': const Color(0xFFFF6B35)};
    } else if (lower.contains('video') || lower.contains('educational')) {
      return {'icon': Icons.play_circle_rounded, 'color': const Color(0xFFFF6B35)};
    } else if (lower.contains('analysis') || lower.contains('unlimited')) {
      return {'icon': Icons.all_inclusive_rounded, 'color': const Color(0xFF8B5CF6)};
    } else if (lower.contains('signal') || lower.contains('insight') || lower.contains('chart')) {
      return {'icon': Icons.insights_rounded, 'color': const Color(0xFFFFD700)};
    } else if (lower.contains('support')) {
      return {'icon': Icons.support_agent_rounded, 'color': const Color(0xFF10B981)};
    } else if (lower.contains('ad')) {
      return {'icon': Icons.block_rounded, 'color': const Color(0xFF06B6D4)};
    }
    return {'icon': Icons.star_rounded, 'color': AppColors.primaryLight};
  }

  Widget _buildFeaturesList(bool isDark, Map<String, dynamic> plan) {
    final rawFeatures = (plan['features'] as List?)?.cast<String>() ?? [];
    final planTitle = plan['title'] as String? ?? 'Premium';

    return _GlassContainer(
      isDark: isDark,
      borderRadius: 20.r,
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GradientIcon(
                icon: Icons.auto_awesome_rounded,
                size: 20.w,
                colors: AppColors.primaryGradient,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '$planTitle Includes',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...rawFeatures.map((featureText) {
            final meta = _featureWithIcon(featureText);
            final color = meta['color'] as Color;
            final icon = meta['icon'] as IconData;
            final isWarning = featureText.toLowerCase().contains('run out') ||
                featureText.toLowerCase().contains('resumes');
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: color, size: 18.w),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      featureText,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isWarning
                            ? (isDark
                                ? Colors.orange.shade200
                                : Colors.orange.shade700)
                            : (isDark
                                ? Colors.white70
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                  Icon(
                    isWarning
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_rounded,
                    size: 18.w,
                    color: isWarning
                        ? Colors.orange.withValues(alpha: 0.7)
                        : AppColors.successLight.withValues(alpha: 0.7),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Terms ───────────────────────────────────────────────────────────
  // Apple App Store requirement: Terms of Service and Privacy Policy must be
  // tappable links on any screen that initiates a subscription purchase.
  Widget _buildTermsText(bool isDark) {
    final baseColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final linkColor = AppColors.primaryLight.withValues(alpha: 0.8);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 11.sp,
          color: baseColor,
          height: 1.6,
        ),
        children: [
          TextSpan(
            text: 'Subscription auto-renews. Cancel anytime in your\n'
                '${Platform.isIOS ? "App Store" : "Play Store"} account settings.\n'
                'By subscribing, you agree to our ',
          ),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(_resolveTermsUrl()),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: linkColor,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(_resolvePrivacyUrl()),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  String _resolvePrivacyUrl() {
    if (Get.isRegistered<AppConfigService>()) {
      final cfg = AppConfigService.to;
      if (Platform.isIOS) {
        final ios = cfg.privacyPolicyUrlIOS.value.trim();
        if (ios.isNotEmpty) return ios;
      }
      final main = cfg.privacyPolicyUrl.value.trim();
      if (main.isNotEmpty) return main;
    }
    return ApiConstants.privacyPolicyUrl;
  }

  String _resolveTermsUrl() {
    if (Get.isRegistered<AppConfigService>()) {
      final cfg = AppConfigService.to;
      if (Platform.isIOS) {
        final ios = cfg.termsOfServiceUrlIOS.value.trim();
        if (ios.isNotEmpty) return ios;
      }
      final main = cfg.termsOfServiceUrl.value.trim();
      if (main.isNotEmpty) return main;
    }
    return ApiConstants.termsOfServiceUrl;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.isAbsolute) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Widget _buildSecurityBadge(bool isDark) {
    return _GlassContainer(
      isDark: isDark,
      borderRadius: 12.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 16.w, color: AppColors.successLight),
          SizedBox(width: 6.w),
          Text(
            Platform.isIOS
                ? 'Secured by App Store'
                : 'Secured by Google Play',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Custom Widgets
// ═══════════════════════════════════════════════════════════════════════

/// Glassmorphic container with frosted glass effect
class _GlassContainer extends StatelessWidget {
  final bool isDark;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final Color? borderColor;

  const _GlassContainer({
    required this.isDark,
    required this.borderRadius,
    required this.padding,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9)),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient icon widget
class _GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;

  const _GradientIcon({
    required this.icon,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          LinearGradient(colors: colors).createShader(bounds),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

/// Pulsing glow animation around a widget
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const _PulsingGlow({required this.child, required this.glowColor});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = 0.2 + (_controller.value * 0.3);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: glow),
                blurRadius: 30 + (_controller.value * 20),
                spreadRadius: _controller.value * 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Animated gradient background
class _AnimatedBackground extends StatelessWidget {
  final bool isDark;
  const _AnimatedBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A14),
                  const Color(0xFF12101F),
                  const Color(0xFF0F0A1A),
                  const Color(0xFF0A0A14),
                ]
              : [
                  const Color(0xFFF5F0FF),
                  const Color(0xFFF0F7FF),
                  const Color(0xFFFFF5F0),
                  Colors.white,
                ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _BackgroundOrbsPainter(isDark: isDark),
      ),
    );
  }
}

/// Subtle gradient orbs painter for the background
class _BackgroundOrbsPainter extends CustomPainter {
  final bool isDark;
  _BackgroundOrbsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Purple orb top-right
    final purplePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.08),
          const Color(0xFF8B5CF6).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.12),
          radius: size.width * 0.5,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.5,
      purplePaint,
    );

    // Gold orb bottom-left
    final goldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: isDark ? 0.08 : 0.05),
          const Color(0xFFFFD700).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.7),
          radius: size.width * 0.4,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.7),
      size.width * 0.4,
      goldPaint,
    );

    // Cyan orb center
    final cyanPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.06 : 0.04),
          const Color(0xFF06B6D4).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.4),
          radius: size.width * 0.35,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      size.width * 0.35,
      cyanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating particles animation
class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 3,
        speed: 0.2 + rng.nextDouble() * 0.5,
        opacity: 0.1 + rng.nextDouble() * 0.2,
      ));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yOffset = (p.y + progress * p.speed) % 1.0;
      final xOffset = p.x + sin(progress * 2 * pi + p.y * 10) * 0.02;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(xOffset * size.width, yOffset * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
