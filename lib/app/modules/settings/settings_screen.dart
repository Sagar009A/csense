/// Settings Screen
/// Beautiful settings page with dark mode, language, share, and rating
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_container.dart';
import '../../common/widgets/common_sizebox.dart';
import '../../services/credit_service.dart';
import '../../services/app_settings_service.dart';
import 'settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: CommonText.title('settings')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Info Card
              _UserInfoCard(controller: controller, isDark: isDark),
              CommonSizedBox.h24,

              // Credits Section
              CommonText.subtitle('credits'),
              CommonSizedBox.h12,
              _CreditsCard(controller: controller, isDark: isDark),
              CommonSizedBox.h24,

              // Appearance Section
              CommonText.subtitle('appearance'),
              CommonSizedBox.h12,
              _ThemeSelectorCard(controller: controller, isDark: isDark),
              CommonSizedBox.h24,

              // Language Section
              CommonText.subtitle('language'),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.language_rounded,
                iconColor: Colors.blue,
                title: 'change_language',
                subtitle: controller.currentLanguageName,
                isDark: isDark,
                onTap: controller.openLanguageSettings,
              ),
              CommonSizedBox.h24,

              // Support Section
              CommonText.subtitle('about'),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                title: 'rate_app',
                subtitle: 'rate_app_desc',
                isDark: isDark,
                onTap: controller.rateApp,
              ),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.share_rounded,
                iconColor: Colors.green,
                title: 'share_app',
                subtitle: 'share_app_desc',
                isDark: isDark,
                onTap: controller.shareApp,
              ),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.apps_rounded,
                iconColor: Colors.purple,
                title: 'more_apps',
                subtitle: 'more_apps_desc',
                isDark: isDark,
                onTap: controller.openMoreApps,
              ),
              CommonSizedBox.h24,

              // Legal Section (between About and Account)
              CommonText.subtitle('legal'),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.privacy_tip_rounded,
                iconColor: Colors.teal,
                title: 'privacy_policy',
                subtitle: 'privacy_policy_desc',
                isDark: isDark,
                onTap: controller.openPrivacyPolicy,
              ),
              CommonSizedBox.h12,
              _SettingCard(
                icon: Icons.description_rounded,
                iconColor: Colors.indigo,
                title: 'terms_of_service',
                subtitle: 'terms_of_service_desc',
                isDark: isDark,
                onTap: controller.openTermsOfService,
              ),
              Obx(() {
                if (!Get.isRegistered<AppSettingsService>()) {
                  return const SizedBox.shrink();
                }
                if (!Get.find<AppSettingsService>().shouldShowAdConsentOption) {
                  return const SizedBox.shrink();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonSizedBox.h12,
                    _SettingCard(
                      icon: Icons.ads_click_rounded,
                      iconColor: Colors.orange,
                      title: 'ad_consent',
                      subtitle: 'ad_consent_desc',
                      isDark: isDark,
                      onTap: controller.openAdConsentOptions,
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

              CommonSizedBox.h24,
              // Version
              Center(
                child: Column(
                  children: [
                    CommonText.caption(
                      'version',
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    CommonSizedBox.h4,
                    CommonText.body(
                      '1.0.0',
                      isTranslate: false,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100.h),
            ],
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
              controller.logout();
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
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24.sp),
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
              controller.deleteAccount();
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

class _UserInfoCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const _UserInfoCard({required this.controller, required this.isDark});

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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, AppColors.secondaryLight],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (controller.displayName?.isNotEmpty == true
                        ? controller.displayName![0]
                        : controller.userEmail?[0] ?? 'U')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          CommonSizedBox.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                CommonSizedBox.h4,
                Text(
                  controller.userEmail ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const _CreditsCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CommonContainer(
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
            // Credits icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: AppColors.warningLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.warningLight,
                size: 24.w,
              ),
            ),
            CommonSizedBox.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'available_credits'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  CommonSizedBox.h4,
                  Text(
                    '${Get.find<CreditService>().credits.value} scans',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Buy button
            ElevatedButton(
              onPressed: controller.openPurchaseScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              child: Text(
                'buy_more'.tr,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
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
