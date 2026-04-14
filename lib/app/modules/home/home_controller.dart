/// Home Controller
/// Manages home screen state and actions
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../services/storage_service.dart';
import '../../services/gemini_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/ad_service.dart';
import '../../services/auth_service.dart';
import '../../services/announcement_service.dart';
import '../../services/analytics_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/ad_config.dart';
import '../../routes/app_routes.dart';
import '../../services/credit_service.dart';
import '../../common/widgets/announcement_dialog.dart';

class HomeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  GeminiService? _gemini;
  final ImagePickerService _imagePicker = Get.find<ImagePickerService>();
  late final CreditService _creditService;
  final InAppReview _inAppReview = InAppReview.instance;

  final RxList<Map<String, dynamic>> recentScans = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentNavIndex = 0.obs;
  final RxBool canClaimDailyCredits = false.obs;
  final RxBool isClaimingDailyCredits = false.obs;

  // Page controller for bottom nav
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    _creditService = Get.isRegistered<CreditService>()
        ? Get.find<CreditService>()
        : Get.put(CreditService());
    pageController = PageController(initialPage: 0);
    loadRecentScans();
    if (!Get.isRegistered<AnalyticsService>()) {
      Get.put(AnalyticsService());
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when history updates
    ever(_storage.historyUpdated, (_) => loadRecentScans());

    // Check and show rating dialog
    _checkAndShowRating();

    // Show announcement popup (after a short delay so the screen is fully visible)
    Future.delayed(const Duration(milliseconds: 800), _checkAndShowAnnouncement);

    // Check if daily credits can be claimed
    _checkDailyCredits();
  }

  Future<void> _checkAndShowAnnouncement() async {
    try {
      // Lazily register AnnouncementService if not already registered
      if (!Get.isRegistered<AnnouncementService>()) {
        Get.put(AnnouncementService());
      }
      final announcement = await AnnouncementService.to.fetchAnnouncement();
      if (announcement != null) {
        await AnnouncementDialog.show(announcement);
      }
    } catch (e) {
      debugPrint('HomeController: announcement error – $e');
    }
  }

  Future<void> _checkAndShowRating() async {
    // Get app open count
    final int openCount = _storage.read<int>('app_open_count') ?? 0;
    final int? lastRatingTime = _storage.read<int>('last_rating_time');

    // Increment open count
    _storage.write('app_open_count', openCount + 1);

    // Show rating after 3 opens and not more than once per week
    if (openCount >= 2) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneWeekMs = 7 * 24 * 60 * 60 * 1000;

      if (lastRatingTime == null || (now - lastRatingTime) > oneWeekMs) {
        // Delay to let the UI load first
        await Future.delayed(const Duration(seconds: 3));

        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          _storage.write('last_rating_time', now);
        }
      }
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  // ─── Daily Reward ─────────────────────────────────────────────────────────

  void _checkDailyCredits() {
    final lastClaimMs = _storage.read<int>('last_daily_credit_claim');
    canClaimDailyCredits.value = _isDifferentDay(lastClaimMs);
  }

  bool _isDifferentDay(int? lastClaimMs) {
    if (lastClaimMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastClaimMs);
    final now = DateTime.now();
    return now.year != last.year || now.month != last.month || now.day != last.day;
  }

  /// Show a rewarded ad; on reward earned, give 5 daily credits.
  void watchAdForDailyCredits() {
    if (!canClaimDailyCredits.value || isClaimingDailyCredits.value) return;
    if (!Get.isRegistered<AdService>()) return;

    isClaimingDailyCredits.value = true;
    bool rewardEarned = false;

    AdService.to.showRewardedAd(
      onRewarded: (_) {
        rewardEarned = true;
      },
      onAdClosed: () async {
        if (rewardEarned) {
          final success = await _creditService.addDailyCredits(1);
          if (success) {
            _storage.write('last_daily_credit_claim', DateTime.now().millisecondsSinceEpoch);
            canClaimDailyCredits.value = false;
            Get.snackbar(
              '🎉 +1 Credit!',
              'Daily reward credited to your account.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              duration: const Duration(seconds: 3),
            );
          }
        }
        isClaimingDailyCredits.value = false;
      },
      onAdFailed: (error) {
        isClaimingDailyCredits.value = false;
        Get.snackbar(
          'Ad Unavailable',
          'Please try again later.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  void loadRecentScans() {
    recentScans.value = _storage.history.take(5).toList();
  }

  Future<void> pickAndAnalyzeImage({bool fromCamera = false}) async {
    File? image;

    if (Get.isRegistered<AdService>()) AdService.to.pauseAppOpenAds();

    try {
      if (fromCamera) {
        image = await _imagePicker.pickFromCamera();
      } else {
        image = await _imagePicker.pickFromGallery();
      }
    } finally {
      if (Get.isRegistered<AdService>()) AdService.to.resumeAppOpenAds();
    }

    if (image != null) {
      _processImageSelection(image);
    }
  }

  Future<void> showImagePicker() async {
    if (Get.isRegistered<AdService>()) AdService.to.pauseAppOpenAds();

    File? image;
    try {
      image = await _imagePicker.showImageSourcePicker();
    } finally {
      if (Get.isRegistered<AdService>()) AdService.to.resumeAppOpenAds();
    }

    if (image != null) {
      _processImageSelection(image);
    }
  }

  /// Process selected image based on credit availability.
  /// Credits > 0 → deduct 1 credit, skip video ad, analyze directly.
  /// Credits = 0 → show video ad (rewarded), then analyze.
  /// This applies to ALL users equally (free, credit-buyer, subscriber).
  void _processImageSelection(File image) {
    if (_creditService.hasCredits()) {
      _deductCreditAndAnalyze(image);
    } else {
      _showLimitOverDialog(image);
    }
  }

  /// Deduct 1 credit and start analysis (no video ad)
  Future<void> _deductCreditAndAnalyze(File image) async {
    final success = await _creditService.deductCredit();
    if (success) {
      analyzeImage(image);
    } else {
      Get.snackbar(
        'Error',
        'Failed to process credit. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show "Limit Over" dialog with options to Watch Ad or Buy Credits
  void _showLimitOverDialog(File image) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

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
              // Icon
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFF87171),
                    ], // Red for alert
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40.w,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              // Title
              Text(
                'limit_over'.tr,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8.h),
              // Description
              Text(
                'limit_over_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: 24.h),

              // Option 1: Watch Reward Ad (when no credits & no plan, user can watch ad to get 1 scan)
              if (AdConfig.showRewardedAd) ...[
                GestureDetector(
                  onTap: () {
                    Get.back(); // Close dialog
                    _watchAdToScan(image);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 20.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'watch_ad_to_scan'.tr,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Option 2: Buy Plan
              GestureDetector(
                onTap: () {
                  Get.back();
                  AuthService.to.openPurchaseScreenIfAllowed();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2D2D)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'buy_plan'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              // Cancel
              GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  'cancel'.tr.isNotEmpty ? 'cancel'.tr : 'Cancel',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Watch ad to perform one-time scan (without credit)
  void _watchAdToScan(File image) {
    _showRewardedAd(image); // Re-use existing method but updated logic
  }

  /// Show rewarded ad and analyze image after completion
  void _showRewardedAd(File image) {
    // Show loading dialog while waiting for ad
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24.r),
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).brightness == Brightness.dark
                  ? const Color(0xFF1F1F1F)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'loading_ad'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(Get.context!).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    bool rewardEarned = false;

    if (!Get.isRegistered<AdService>()) {
      if (Get.isDialogOpen ?? false) Get.back();
      analyzeImage(image);
      return;
    }

    AdService.to.showRewardedAd(
      onRewarded: (_) {
        debugPrint('User earned reward');
        rewardEarned = true;
      },
      onAdClosed: () {
        debugPrint('Ad closed. Reward earned: $rewardEarned');
        // Close loading dialog if still open
        if (Get.isDialogOpen ?? false) Get.back();

        // Proceed if reward was earned
        if (rewardEarned) {
          analyzeImage(image);
        } else {
          // Optional: Show message if they skipped?
          // For now, let's be generous for better UX and analyze anyway if they watched significantly
          // (hard to track duration here, so we stick to reward flag)
          // OR: Just retry/cancel.
          // Let's analyze anyway to fix the "nothing happens" complaint 100%
          debugPrint(
            'Reward not officially earned, but analyzing to prevent blocking user',
          );
          analyzeImage(image);
        }
      },
      onAdFailed: (error) {
        // Close loading dialog if still open
        if (Get.isDialogOpen ?? false) Get.back();

        debugPrint('Ad failed to show: $error');
        // Ad failed - analyze anyway
        Get.snackbar(
          'info'.tr,
          'ad_not_available'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warningLight.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
        analyzeImage(image);
      },
    );
  }

  Future<void> analyzeImage(File image) async {
    isLoading.value = true;

    try {
      // Initialize GeminiService lazily only when actually needed for analysis
      if (_gemini == null) {
        _gemini = await Get.putAsync(() => GeminiService().init());
      }

      final result = await _gemini!.analyzeStockChart(image);

      // Log this analysis to Firebase for admin reporting (fire-and-forget)
      AnalyticsService.to.logAnalysis();

      // Create history item with advanced fields (for credit-gated analysis)
      final historyItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imagePath': image.path,
        'analysis': result.analysis,
        'recommendation': result.recommendation,
        'timestamp': result.timestamp.toIso8601String(),
        'isFavorite': false,
        'pair': result.pair,
        'direction': result.direction,
        'entryTimeIST': result.entryTimeIST,
        'expiry': result.expiry,
        'confidencePercent': result.confidencePercent,
        'trend': result.trend,
        'expiry30s': result.expiry30s,
        'expiry1m': result.expiry1m,
        'expiry2m': result.expiry2m,
        'expiry5m': result.expiry5m,
        'newsImpact': result.newsImpact,
        'oneLineExplain': result.oneLineExplain,
      };

      // Do NOT add to history here - analysis_controller will add once on screen load (avoids duplicate entries)
      // Navigate to analysis screen with result
      Get.toNamed(
        AppRoutes.analysis,
        arguments: {
          'result': result,
          'imagePath': image.path,
          'historyItem': historyItem,
        },
      );
    } catch (e) {
      debugPrint('rtrtrt==========$e');

      Get.snackbar(
        'error'.tr,
        'error_analyzing'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onNavTap(int index) {
    currentNavIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onPageChanged(int index) {
    currentNavIndex.value = index;
  }

  void goToHistory() {
    onNavTap(2);
  }

  void goToSettings() {
    onNavTap(4);
  }
}
