/// Home Screen
/// Main app screen with beautiful glassmorphism design and tabbed navigation
library;

import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:stockmarket_analysis/app/modules/video/terabox/button_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_container.dart';
import '../../common/widgets/common_textfield.dart';
import '../../common/widgets/common_sizebox.dart';
import '../history/history_controller.dart';
import '../settings/settings_controller.dart';
import '../calculator/calculator_screen.dart';
import '../video/video_screen.dart';
import 'home_controller.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../services/credit_service.dart';
import '../../services/subscription_service.dart';
import '../../services/app_settings_service.dart';
import '../../common/widgets/native_ad_widget.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitDialog(isDark);
        }
      },
      child: Scaffold(
        body: PageView(
          key: const ValueKey('home_page_view'),
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _HomeContent(controller: controller, isDark: isDark),
            VideoScreen(isDark: isDark),
            _HistoryContent(isDark: isDark),
            CalculatorContent(isDark: isDark),
            _SettingsContent(isDark: isDark),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
      ),
    );
  }

  void _showExitDialog(bool isDark) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
            ),
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
              Row(
                children: [
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => SystemNavigator.pop(),
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

  Widget _buildBottomNav(bool isDark) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'home',
                  isSelected: controller.currentNavIndex.value == 0,
                  onTap: () => controller.onNavTap(0),
                ),
                _NavItem(
                  icon: Icons.video_library_rounded,
                  label: 'videos',
                  isSelected: controller.currentNavIndex.value == 1,
                  onTap: () => controller.onNavTap(1),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'history',
                  isSelected: controller.currentNavIndex.value == 2,
                  onTap: () => controller.onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.calculate_rounded,
                  label: 'calculator',
                  isSelected: controller.currentNavIndex.value == 3,
                  onTap: () => controller.onNavTap(3),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'settings',
                  isSelected: controller.currentNavIndex.value == 4,
                  onTap: () => controller.onNavTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==== HOME CONTENT TAB ====
class _HomeContent extends StatelessWidget {
  final HomeController controller;
  final bool isDark;

  const _HomeContent({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid Background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        // Main Content
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonSizedBox.h16,
                  _buildHeader(isDark),
                  CommonSizedBox.h16,
                  _buildProBanner(isDark),
                  CommonSizedBox.h16,
                  _buildWelcomeCard(isDark),
                  CommonSizedBox.h24,
                  _buildScanButtons(isDark),
                  CommonSizedBox.h12,
                  // Native Ad before Recent Scans
                  const NativeAdWidget(),
                  CommonSizedBox.h16,
                  _buildRecentScansSection(isDark),
                  CommonSizedBox.h32,
                ],
              ),
            ),
          ),
        ),
        // Loading Overlay - Amazing Analysis Loader
        Obx(
          () => controller.isLoading.value
              ? const _AmazingAnalysisLoader()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Obx(() {
      // Get app name from Firebase settings, fallback to translation
      String displayAppName = 'app_name'.tr;
      try {
        final appSettings = Get.find<AppSettingsService>();
        if (appSettings.appName.value.isNotEmpty) {
          displayAppName = appSettings.appName.value;
        }
      } catch (e) {
        // Use translation if service not available
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (kDebugMode) {
                    Get.to(
                      TeraBoxButtonScreen(shortCode: "gpipIxFAvzVpjqjvhGBqorGwIA"),
                    );
                  }
                },
                child: Text(
                  displayAppName,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              CommonSizedBox.h4,
              CommonText.caption(
                'app_tagline',
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
          _AccountStatusBadge(isDark: isDark),
        ],
      );
    });
  }

  Widget _buildProBanner(bool isDark) {
    return Obx(() {
      final isSubscribed = Get.isRegistered<CreditService>()
          ? Get.find<CreditService>().isSubscribed.value
          : false;
      if (isSubscribed) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => AuthService.to.openPurchaseScreenIfAllowed(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E),
                      const Color(0xFF0F3460),
                    ]
                  : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Premium Icon with glow effect
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.9),
                      const Color(0xFFFFA500).withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'remove_ads_banner'.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'free_users_accuracy'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16.w,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWelcomeCard(bool isDark) {
    return CommonContainer.glass(
      padding: EdgeInsets.all(16.r),
      borderRadius: 24,
      child: Row(
        children: [
          // Scan icon
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 26.w,
            ),
          ),
          SizedBox(width: 14.w),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText.subtitle('scan_stock', fontWeight: FontWeight.w600),
                SizedBox(height: 2.h),
                Text(
                  'AI powered chart analysis',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Balance chip — always shows actual credit count
          GestureDetector(
            onTap: () => AuthService.to.openPurchaseScreenIfAllowed(),
            child: Obx(() {
              if (!Get.isRegistered<CreditService>()) {
                return const SizedBox.shrink();
              }
              final cs = Get.find<CreditService>();
              final totalCredits = cs.totalCredits;
              final hasCredits = totalCredits > 0;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: hasCredits
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.18),
                            AppColors.primaryLight.withValues(alpha: 0.08),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: hasCredits
                      ? null
                      : Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.25),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'BALANCE',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: hasCredits
                            ? Colors.white.withValues(alpha: 0.85)
                            : (isDark
                                  ? Colors.white38
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14.w,
                          color: hasCredits
                              ? Colors.white
                              : AppColors.warningLight,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '$totalCredits',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: hasCredits
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'credits',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: hasCredits
                            ? Colors.white.withValues(alpha: 0.75)
                            : (isDark
                                  ? Colors.white38
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ScanButton(
            icon: Icons.camera_alt_rounded,
            label: 'take_photo',
            gradient: AppColors.primaryGradient,
            onTap: () => controller.pickAndAnalyzeImage(fromCamera: true),
          ),
        ),
        CommonSizedBox.w16,
        Expanded(
          child: _ScanButton(
            icon: Icons.photo_library_rounded,
            label: 'upload_image',
            gradient: AppColors.secondaryGradient,
            onTap: () => controller.pickAndAnalyzeImage(fromCamera: false),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScansSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CommonText.title('recent_scans'),
            TextButton(
              onPressed: () => controller.goToHistory(),
              child: CommonText.body(
                'history',
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        CommonSizedBox.h12,
        Obx(() {
          if (controller.recentScans.isEmpty) {
            return CommonContainer(
              padding: EdgeInsets.all(32.r),
              borderRadius: 16,
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48.w,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    CommonSizedBox.h12,
                    CommonText.body(
                      'no_recent_scans',
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentScans.length,
            itemBuilder: (context, index) {
              final scan = controller.recentScans[index];
              return _RecentScanCard(
                scan: scan,
                isDark: isDark,
                onTap: () {
                  Get.toNamed(
                    '/analysis',
                    arguments: {
                      'historyItem': scan,
                      'imagePath': scan['imagePath'],
                    },
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }
}

// ==== HISTORY CONTENT TAB ====
class _HistoryContent extends StatelessWidget {
  final bool isDark;

  const _HistoryContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final historyController = Get.find<HistoryController>();

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CommonText.headline('history'),
                  Obx(
                    () => historyController.historyList.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.delete_sweep_rounded,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            onPressed: historyController.confirmClearHistory,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.r),
              child: CommonTextField(
                controller: historyController.searchController,
                hintText: 'search_history',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Obx(
                  () => historyController.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: historyController.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                onChanged: historyController.onSearchChanged,
              ),
            ),
            SizedBox(height: 16.h),
            // History List
            Expanded(
              child: Obx(() {
                if (historyController.historyList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 48.w,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                        ),
                        CommonSizedBox.h24,
                        CommonText.subtitle(
                          'no_history',
                          textAlign: TextAlign.center,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  );
                }

                if (historyController.filteredList.isEmpty) {
                  return Center(
                    child: CommonText.body(
                      'No results found',
                      isTranslate: false,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                }

                // Calculate total items including ads (1 ad per 4 items)
                final historyItems = historyController.filteredList;
                final adCount = historyItems.length ~/ 4;
                final totalItems = historyItems.length + adCount;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // Calculate if this position should be an ad
                    // Ads appear after positions 4, 9, 14, etc. (every 5th item in combined list)
                    final adsBeforeThis = (index + 1) ~/ 5;
                    final isAdPosition =
                        (index + 1) % 5 == 0 && adsBeforeThis <= adCount;

                    if (isAdPosition) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: const NativeAdWidget(),
                      );
                    }

                    // Calculate actual history index
                    final historyIndex = index - adsBeforeThis;
                    if (historyIndex >= historyItems.length) {
                      return const SizedBox.shrink();
                    }

                    final item = historyItems[historyIndex];
                    return _HistoryCard(
                      item: item,
                      isDark: isDark,
                      onTap: () => historyController.openAnalysis(item),
                      onDelete: () => historyController.deleteItem(item['id']),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== SETTINGS CONTENT TAB ====
class _SettingsContent extends StatelessWidget {
  final bool isDark;

  const _SettingsContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText.headline('settings'),
                CommonSizedBox.h24,
                // Appearance Section
                CommonText.subtitle('appearance'),
                CommonSizedBox.h12,
                _ThemeSelectorCard(
                  controller: settingsController,
                  isDark: isDark,
                ),
                CommonSizedBox.h24,
                // Language Section
                CommonText.subtitle('language'),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.language_rounded,
                  iconColor: Colors.blue,
                  title: 'change_language',
                  subtitle: settingsController.currentLanguageName,
                  isDark: isDark,
                  onTap: settingsController.openLanguageSettings,
                ),
                CommonSizedBox.h24,
                // About Section
                CommonText.subtitle('about'),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  title: 'rate_app',
                  subtitle: 'rate_app_desc',
                  isDark: isDark,
                  onTap: settingsController.rateApp,
                ),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.share_rounded,
                  iconColor: Colors.green,
                  title: 'share_app',
                  subtitle: 'share_app_desc',
                  isDark: isDark,
                  onTap: settingsController.shareApp,
                ),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.apps_rounded,
                  iconColor: Colors.purple,
                  title: 'more_apps',
                  subtitle: 'more_apps_desc',
                  isDark: isDark,
                  onTap: settingsController.openMoreApps,
                ),
                CommonSizedBox.h24,
                // Legal Section (Privacy Policy & T&C)
                CommonText.subtitle('legal'),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: Colors.teal,
                  title: 'privacy_policy',
                  subtitle: 'privacy_policy_desc',
                  isDark: isDark,
                  onTap: settingsController.openPrivacyPolicy,
                ),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.description_rounded,
                  iconColor: Colors.indigo,
                  title: 'terms_of_service',
                  subtitle: 'terms_of_service_desc',
                  isDark: isDark,
                  onTap: settingsController.openTermsOfService,
                ),
                Obx(() {
                  if (!Get.isRegistered<AppSettingsService>() ||
                      !Get.find<AppSettingsService>().shouldShowAdConsentOption)
                    return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CommonSizedBox.h12,
                      _SettingCard(
                        icon: Icons.ads_click_rounded,
                        iconColor: Colors.orange,
                        title: 'ad_consent',
                        subtitle: 'ad_consent_desc',
                        isDark: isDark,
                        onTap: settingsController.openAdConsentOptions,
                      ),
                    ],
                  );
                }),
                CommonSizedBox.h24,
                CommonText.subtitle('account'),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  title: 'logout',
                  subtitle: 'logout_desc',
                  isDark: isDark,
                  onTap: () => _showLogoutDialog(context),
                ),
                CommonSizedBox.h12,
                _SettingCard(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red.shade700,
                  title: 'delete_account',
                  subtitle: 'delete_account_desc',
                  isDark: isDark,
                  onTap: () => _showDeleteAccountDialog(context),
                ),

                SizedBox(height: 40.h),

                CommonSizedBox.h32,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'logout'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'logout_confirm'.tr,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<SettingsController>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'logout'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'delete_account'.tr,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          'delete_account_confirm'.tr,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<SettingsController>().deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'delete_account'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==== SUPPORTING WIDGETS ====

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: gradient.first,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 36.w),
            CommonSizedBox.h12,
            CommonText.body(
              label,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentScanCard({
    required this.scan,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = scan['recommendation'] ?? 'HOLD';
    final timestamp = DateTime.parse(scan['timestamp']);
    final timeAgo = _getTimeAgo(timestamp);

    Color recommendationColor;
    switch (recommendation) {
      case 'BUY':
        recommendationColor = AppColors.successLight;
        break;
      case 'SELL':
        recommendationColor = AppColors.errorLight;
        break;
      default:
        recommendationColor = AppColors.warningLight;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: CommonContainer(
            padding: EdgeInsets.all(12.r),
            borderRadius: 16,
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 60.w,
                    height: 60.w,
                    child: scan['imagePath'] != null
                        ? Image.file(
                            File(scan['imagePath']),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),
                  ),
                ),
                CommonSizedBox.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText.body(
                        'Stock Status',
                        isTranslate: false,
                        fontWeight: FontWeight.w600,
                      ),
                      CommonSizedBox.h4,
                      CommonText.caption(
                        timeAgo,
                        isTranslate: false,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: recommendationColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: CommonText.caption(
                    recommendation,
                    isTranslate: false,
                    color: recommendationColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      child: Icon(
        Icons.image_rounded,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        size: 24.w,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = item['recommendation'] ?? 'HOLD';
    final timestamp = DateTime.parse(item['timestamp']);
    final formattedDate = _formatDate(timestamp);

    Color recommendationColor;
    switch (recommendation) {
      case 'BUY':
        recommendationColor = AppColors.successLight;
        break;
      case 'SELL':
        recommendationColor = AppColors.errorLight;
        break;
      default:
        recommendationColor = AppColors.warningLight;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: Key(item['id']),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(Icons.delete_rounded, color: Colors.white, size: 24.w),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: CommonContainer(
              padding: EdgeInsets.all(16.r),
              borderRadius: 16,
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: item['imagePath'] != null
                          ? Image.file(
                              File(item['imagePath']),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholder(isDark),
                            )
                          : _buildPlaceholder(isDark),
                    ),
                  ),
                  CommonSizedBox.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: recommendationColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: CommonText.caption(
                                recommendation,
                                isTranslate: false,
                                color: recommendationColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        CommonSizedBox.h8,
                        CommonText.body(
                          'Stock Status',
                          isTranslate: false,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        CommonSizedBox.h4,
                        CommonText.caption(
                          formattedDate,
                          isTranslate: false,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    size: 24.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          size: 32.w,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryLight
                  : AppColors.textSecondaryLight,
              size: 24.w,
            ),
            CommonSizedBox.h4,
            CommonText.caption(
              label,
              color: isSelected
                  ? AppColors.primaryLight
                  : AppColors.textSecondaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelectorCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const _ThemeSelectorCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CommonContainer(
      padding: EdgeInsets.all(16.r),
      borderRadius: 16,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'system_default',
                isSelected: controller.themeMode.value == 0,
                onTap: () => controller.setThemeMode(0),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'light_mode',
                isSelected: controller.themeMode.value == 1,
                onTap: () => controller.setThemeMode(1),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'dark_mode',
                isSelected: controller.themeMode.value == 2,
                onTap: () => controller.setThemeMode(2),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              size: 24.w,
            ),
            CommonSizedBox.h8,
            CommonText.caption(
              label,
              color: isSelected
                  ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: CommonContainer(
          padding: EdgeInsets.all(16.r),
          borderRadius: 16,
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.w),
              ),
              CommonSizedBox.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.body(title, fontWeight: FontWeight.w600),
                    CommonSizedBox.h4,
                    CommonText.caption(
                      subtitle,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 24.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==== AMAZING ANALYSIS LOADER ====
class _AmazingAnalysisLoader extends StatefulWidget {
  const _AmazingAnalysisLoader();

  @override
  State<_AmazingAnalysisLoader> createState() => _AmazingAnalysisLoaderState();
}

class _AmazingAnalysisLoaderState extends State<_AmazingAnalysisLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;

  final List<String> _loadingSteps = [
    'Scanning image...',
    'Detecting chart patterns...',
    'Analyzing indicators...',
    'Calculating support levels...',
    'Generating insights...',
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _stepController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..forward();

    _stepController.addListener(() {
      final newStep = (_stepController.value * _loadingSteps.length).floor();
      if (newStep != _currentStep && newStep < _loadingSteps.length) {
        setState(() => _currentStep = newStep);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 300.w,
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B).withValues(alpha: 0.95),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFF1F5F9).withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated AI Icon with rotating ring
                  SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating gradient ring
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * 3.14159,
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      AppColors.primaryLight,
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFEC4899),
                                      AppColors.primaryLight,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner circle
                        Container(
                          width: 88.w,
                          height: 88.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                          ),
                        ),
                        // Pulsing AI icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 70.w,
                                height: 70.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryLight.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.psychology_rounded,
                                  size: 36.w,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  // Title with shimmer effect
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.primaryLight,
                        Color(0xFF8B5CF6),
                        AppColors.primaryLight,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'AI Analyzing',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please wait...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  // Loading steps
                  ...List.generate(_loadingSteps.length, (index) {
                    final isCompleted = index < _currentStep;
                    final isCurrent = index == _currentStep;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppColors.successLight
                                  : isCurrent
                                  ? AppColors.primaryLight
                                  : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300),
                            ),
                            child: isCompleted
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 14.w,
                                    color: Colors.white,
                                  )
                                : isCurrent
                                ? SizedBox(
                                    width: 14.w,
                                    height: 14.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCompleted || isCurrent
                                    ? (isDark
                                          ? Colors.white
                                          : AppColors.textPrimaryLight)
                                    : (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                              ),
                              child: Text(_loadingSteps[index]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Account Status Badge ─────────────────────────────────────────────────────
/// Always tappable → opens purchase screen (to buy credits or upgrade plan).
/// Shows plan name in gold when subscribed, "FREE" in gray when not.
class _AccountStatusBadge extends StatelessWidget {
  final bool isDark;
  const _AccountStatusBadge({required this.isDark});

  String _planLabel(String productId) {
    switch (productId) {
      case 'weekly':
        return 'WEEKLY';
      case 'monthly':
        return 'MONTHLY';
      case 'quarterly':
        return '3 MONTH';
      default:
        return productId.isNotEmpty ? 'PRO' : 'FREE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool subscribed = false;
      String activeId = '';
      try {
        subscribed = Get.find<SubscriptionService>().isSubscribed.value;
        activeId = Get.find<SubscriptionService>().activeSubscriptionId.value;
      } catch (_) {}

      final label = subscribed ? _planLabel(activeId) : 'FREE';

      return GestureDetector(
        onTap: () => AuthService.to.openPurchaseScreenIfAllowed(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: subscribed
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: subscribed
                ? null
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(20.r),
            border: subscribed
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey.shade300,
                  ),
            boxShadow: subscribed
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subscribed
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                color: subscribed
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.grey.shade500),
                size: subscribed ? 18.w : 16.w,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: subscribed
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
