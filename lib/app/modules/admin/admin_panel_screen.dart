/// Admin Panel Screen
/// Controls ad network, ad switches, and API config via Firebase RTDB
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import 'admin_panel_controller.dart';

class AdminPanelScreen extends GetView<AdminPanelController> {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.ads_click_rounded), text: 'Ads Config'),
              Tab(icon: Icon(Icons.api_rounded), text: 'API Config'),
            ],
            indicatorColor: AppColors.primaryLight,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            children: [
              _AdsConfigTab(controller: controller, isDark: isDark),
              _ApiConfigTab(controller: controller, isDark: isDark),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 1 — Ads Config
// ─────────────────────────────────────────────────────────────────────────────
class _AdsConfigTab extends StatelessWidget {
  final AdminPanelController controller;
  final bool isDark;

  const _AdsConfigTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ad Network Toggle ──────────────────────────────────────────────
          _SectionHeader(title: 'Ad Network', isDark: isDark),
          SizedBox(height: 12.h),
          _AdNetworkToggle(controller: controller, isDark: isDark),
          SizedBox(height: 24.h),

          // ── Ad Type Switches ──────────────────────────────────────────────
          _SectionHeader(title: 'Ad Types', isDark: isDark),
          SizedBox(height: 12.h),
          _AdSwitchCard(isDark: isDark, children: [
            Obx(() => _AdToggleRow(
              icon: Icons.view_stream_rounded,
              label: 'Banner Ad',
              value: controller.showBannerAd.value,
              onChanged: (v) => controller.showBannerAd.value = v,
              isDark: isDark,
            )),
            _Divider(isDark: isDark),
            Obx(() => _AdToggleRow(
              icon: Icons.article_rounded,
              label: 'Native Ad',
              value: controller.showNativeAd.value,
              onChanged: (v) => controller.showNativeAd.value = v,
              isDark: isDark,
            )),
            _Divider(isDark: isDark),
            Obx(() => _AdToggleRow(
              icon: Icons.fullscreen_rounded,
              label: 'Interstitial Ad',
              value: controller.showInterstitialAd.value,
              onChanged: (v) => controller.showInterstitialAd.value = v,
              isDark: isDark,
            )),
            _Divider(isDark: isDark),
            Obx(() => _AdToggleRow(
              icon: Icons.card_giftcard_rounded,
              label: 'Rewarded Ad',
              value: controller.showRewardedAd.value,
              onChanged: (v) => controller.showRewardedAd.value = v,
              isDark: isDark,
            )),
            _Divider(isDark: isDark),
            Obx(() => _AdToggleRow(
              icon: Icons.open_in_new_rounded,
              label: 'App Open Ad',
              value: controller.showAppOpenAd.value,
              onChanged: (v) => controller.showAppOpenAd.value = v,
              isDark: isDark,
            )),
          ]),
          SizedBox(height: 24.h),

          // ── Cooldown ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Interstitial Cooldown', isDark: isDark),
          SizedBox(height: 12.h),
          _CooldownSelector(controller: controller, isDark: isDark),
          SizedBox(height: 32.h),

          // ── Save Button ───────────────────────────────────────────────────
          Obx(() => _SaveButton(
            label: 'Save Ad Config',
            isSaving: controller.isSaving.value,
            onTap: controller.saveAdConfig,
          )),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

class _AdNetworkToggle extends StatelessWidget {
  final AdminPanelController controller;
  final bool isDark;

  const _AdNetworkToggle({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAdx = controller.adNetwork.value == 'adx';
      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _NetworkOption(
              label: 'AdMob',
              icon: Icons.monetization_on_rounded,
              color: Colors.green,
              isSelected: !isAdx,
              isDark: isDark,
              onTap: () => controller.adNetwork.value = 'admob',
            ),
            _NetworkOption(
              label: 'AdX (GAM)',
              icon: Icons.business_center_rounded,
              color: Colors.blue,
              isSelected: isAdx,
              isDark: isDark,
              onTap: () => controller.adNetwork.value = 'adx',
            ),
          ],
        ),
      );
    });
  }
}

class _NetworkOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NetworkOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CooldownSelector extends StatelessWidget {
  final AdminPanelController controller;
  final bool isDark;

  const _CooldownSelector({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final secs = controller.interstitialCooldownSeconds.value;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.timer_rounded, color: AppColors.warningLight, size: 24.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '${secs}s between interstitials',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Row(
              children: [
                _CircleButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (secs > 10) {
                      controller.interstitialCooldownSeconds.value = secs - 10;
                    }
                  },
                  isDark: isDark,
                ),
                SizedBox(width: 8.w),
                Text(
                  '$secs',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
                SizedBox(width: 8.w),
                _CircleButton(
                  icon: Icons.add,
                  onTap: () {
                    if (secs < 120) {
                      controller.interstitialCooldownSeconds.value = secs + 10;
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleButton({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryLight, size: 18.w),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 2 — API Config
// ─────────────────────────────────────────────────────────────────────────────
class _ApiConfigTab extends StatelessWidget {
  final AdminPanelController controller;
  final bool isDark;

  const _ApiConfigTab({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gemini ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'Gemini AI', isDark: isDark),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.geminiApiKeyCtrl,
            label: 'Gemini API Key',
            hint: 'AIza...',
            icon: Icons.vpn_key_rounded,
            isDark: isDark,
            obscure: true,
          ),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.geminiModelCtrl,
            label: 'Gemini Model',
            hint: 'gemini-1.5-flash',
            icon: Icons.smart_toy_rounded,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.analysisPromptCtrl,
            label: 'Analysis Prompt (optional)',
            hint: 'Leave empty to use default prompt',
            icon: Icons.text_snippet_rounded,
            isDark: isDark,
            maxLines: 5,
          ),
          SizedBox(height: 24.h),

          // ── Store URLs ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Store URLs', isDark: isDark),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.playStoreUrlCtrl,
            label: 'Play Store URL',
            hint: 'https://play.google.com/store/apps/details?id=...',
            icon: Icons.android_rounded,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.appStoreUrlCtrl,
            label: 'App Store URL',
            hint: 'https://apps.apple.com/app/...',
            icon: Icons.apple_rounded,
            isDark: isDark,
          ),
          SizedBox(height: 24.h),

          // ── Legal URLs ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Legal URLs', isDark: isDark),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.privacyPolicyUrlCtrl,
            label: 'Privacy Policy URL',
            hint: 'https://...',
            icon: Icons.privacy_tip_rounded,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          _ConfigField(
            ctrl: controller.termsOfServiceUrlCtrl,
            label: 'Terms of Service URL',
            hint: 'https://...',
            icon: Icons.description_rounded,
            isDark: isDark,
          ),
          SizedBox(height: 32.h),

          // ── Save Button ────────────────────────────────────────────────────
          Obx(() => _SaveButton(
            label: 'Save API Config',
            isSaving: controller.isSaving.value,
            onTap: controller.saveApiConfig,
          )),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}

class _AdSwitchCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _AdSwitchCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _AdToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _AdToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: (value ? AppColors.primaryLight : Colors.grey)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primaryLight : Colors.grey,
              size: 18.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16.w,
      endIndent: 16.w,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final int maxLines;

  const _ConfigField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14.sp,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20.w),
        labelStyle: TextStyle(
          fontSize: 13.sp,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isSaving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          disabledBackgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 4,
        ),
        child: isSaving
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
