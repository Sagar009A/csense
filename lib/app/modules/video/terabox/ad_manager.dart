/// AdManager for TeraBox Video Player
/// Wrapper around app's AdService for compatibility with TeraBox screens
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../services/ad_service.dart';
import '../../../core/constants/ad_config.dart';

class AdManager {
  static String get nativeId => AdConfig.nativeAdId;
  static String get fallbackNativeId => AdConfig.nativeAdId;
  static String get rewardedId => AdConfig.rewardedAdId;
  static String get interstitialId => AdConfig.interstitialAdId;
  
  static InterstitialAd? interstitialAd;
  static RewardedAd? _rewardedAd;
  static bool _isRewardedLoading = false;
  
  static Future<void> initialize() async {
    await configureFromPrefs();
  }
  
  static Future<void> configureFromPrefs() async {
    // Configuration is already loaded from Firebase in AdService
    // This is kept for compatibility
  }
  
  static void loadInterstitial() {
    try {
      final adService = Get.find<AdService>();
      // AdService handles interstitial loading
      if (!adService.isInterstitialAdLoaded.value) {
        // AdService will auto-load
      }
    } catch (e) {
      debugPrint('AdManager: Error loading interstitial: $e');
    }
  }
  
  /// Show interstitial. Optional [onAdClosed] runs after ad is dismissed (safer for navigation).
  static void showInterstitial({VoidCallback? onAdClosed}) {
    try {
      final adService = Get.find<AdService>();
      adService.showInterstitialAd(onAdClosed: onAdClosed);
    } catch (e) {
      debugPrint('AdManager: Error showing interstitial: $e');
      onAdClosed?.call();
    }
  }

  static bool get isInterstitialReady {
    try {
      return Get.find<AdService>().isInterstitialReady;
    } catch (_) {
      return false;
    }
  }
  
  static void loadRewarded() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    
    _isRewardedLoading = true;
    
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('AdManager: Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('AdManager: Rewarded ad failed to load: ${error.message}');
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), loadRewarded);
        },
      ),
    );
  }
  
  static RewardedAd? getRewardedAd() => _rewardedAd;
  
  static void showRewarded({
    required VoidCallback onReward,
    VoidCallback? onAdClosed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('AdManager: No rewarded ad available');
      onAdClosed?.call();
      return;
    }

    VoidCallback? closed = onAdClosed;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
        closed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
        closed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        onReward();
      },
    );
  }
  
  static void dispose() {
    interstitialAd?.dispose();
    interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
