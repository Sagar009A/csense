/// AdMob Ad Service
/// Centralized service for managing all ad types with preloading and callbacks
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/ad_config.dart';
import 'consent_service.dart';
import 'credit_service.dart';

/// Callback types for ad events
typedef AdCallback = void Function();
typedef RewardCallback = void Function(RewardItem reward);
typedef AdFailedCallback = void Function(String error);

class AdService extends GetxService {
  static AdService get to => Get.find<AdService>();

  /// Global flag to control ad visibility based on user credits/subscription
  final RxBool shouldShowAds = true.obs;

  // ═══════════════════════════════════════════════════════════════════════════
  //                              BANNER ADS
  // ═══════════════════════════════════════════════════════════════════════════
  final Rx<BannerAd?> bannerAd = Rx<BannerAd?>(null);
  final RxBool isBannerAdLoaded = false.obs;
  int _bannerAdRetryAttempt = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  //                              NATIVE ADS
  // ═══════════════════════════════════════════════════════════════════════════
  final RxList<NativeAd> _nativeAds = <NativeAd>[].obs;
  final RxBool isNativeAdLoaded = false.obs;
  final RxBool isLoadingNativeAd = false.obs;
  int _nativeAdRetryAttempt = 0;
  static const int _maxNativeAdsPool = 5;
  static const int _minNativeAdsPool = 2;
  bool _isLoadingNativeAd = false;

  // ═══════════════════════════════════════════════════════════════════════════
  //                           INTERSTITIAL ADS
  // ═══════════════════════════════════════════════════════════════════════════
  final RxList<InterstitialAd> _interstitialAds = <InterstitialAd>[].obs;
  final RxBool isInterstitialAdLoaded = false.obs;
  final RxBool isLoadingInterstitialAd = false.obs;
  DateTime? _lastInterstitialTime;
  int _interstitialAdRetryAttempt = 0;
  static const int _maxInterstitialAdsPool = 5;
  static const int _minInterstitialAdsPool = 2;
  bool _isLoadingInterstitialAd = false;

  // ═══════════════════════════════════════════════════════════════════════════
  //                             REWARDED ADS
  // ═══════════════════════════════════════════════════════════════════════════
  final RxList<RewardedAd> _rewardedAds = <RewardedAd>[].obs;
  final RxBool isRewardedAdLoaded = false.obs;
  final RxBool isLoadingRewardedAd = false.obs;
  int _rewardedAdRetryAttempt = 0;
  static const int _maxRewardedAdsPool = 5; // Maximum ads to preload
  static const int _minRewardedAdsPool = 2; // Minimum ads to maintain
  bool _isLoadingRewardedAd = false;

  // ═══════════════════════════════════════════════════════════════════════════
  //                            APP OPEN ADS
  // ═══════════════════════════════════════════════════════════════════════════
  AppOpenAd? _appOpenAd;
  final RxBool isAppOpenAdLoaded = false.obs;
  DateTime? _lastAppOpenTime;
  bool _isShowingAppOpenAd = false;
  int _appOpenAdRetryAttempt = 0;

  /// Flag to prevent app open ads during external activities (camera, gallery, etc.)
  bool _isExternalActivityInProgress = false;

  /// Call this before opening camera/gallery to prevent app open ad
  void pauseAppOpenAds() {
    _isExternalActivityInProgress = true;
    debugPrint('AdService: App open ads paused for external activity');
  }

  /// Call this after camera/gallery is closed
  void resumeAppOpenAds() {
    _isExternalActivityInProgress = false;
    debugPrint('AdService: App open ads resumed');
  }


  // ═══════════════════════════════════════════════════════════════════════════
  //                            INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<AdService> init() async {
    await MobileAds.instance.initialize();

    // Fetch remote config from Realtime Database
    try {
      debugPrint('AdService: Fetching remote config...');
      final snapshot = await FirebaseDatabase.instance.ref('ad_config').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('AdService: Raw remote config: $data');
        AdConfig.fromJson(data);
        debugPrint('AdService: Remote config loaded. Banner: ${AdConfig.showBannerAd}, Interstitial: ${AdConfig.showInterstitialAd}');
      } else {
        debugPrint('AdService: No remote config found, using defaults');
      }
    } catch (e) {
      debugPrint('AdService: Failed to load remote config: $e');
    }

    // Check GDPR consent status before loading ads
    final consent = ConsentService.instance;
    if (!consent.canRequestAds) {
      debugPrint('AdService: Cannot request ads — consent not obtained (GDPR)');
      return this;
    }

    // Initialize ad visibility based on credits/subscription
    _initAdVisibility();
    
    debugPrint('AdService: shouldShowAds: ${shouldShowAds.value}');

    // Preload all ads only if needed
    if (shouldShowAds.value) {
      debugPrint('AdService: Preloading ads...');
      _preloadAds();
    } else {
      debugPrint('AdService: Skipping ad preload because shouldShowAds is false');
    }

    return this;
  }

  void _initAdVisibility() {
    try {
      final creditService = Get.find<CreditService>();

      // isSubscribed = has an active plan → hide all ads
      _updateAdVisibility(creditService.isSubscribed.value);

      ever(creditService.isSubscribed, (bool subscribed) {
        _updateAdVisibility(subscribed);
      });
    } catch (e) {
      debugPrint('AdService: Error connecting to CreditService: $e');
    }
  }

  void _updateAdVisibility(bool subscribed) {
    final showAds = !subscribed;
    debugPrint('AdService: updateAdVisibility: subscribed=$subscribed, showAds=$showAds');

    if (shouldShowAds.value != showAds) {
      shouldShowAds.value = showAds;
      debugPrint('AdService: Ad visibility changed to $showAds (subscribed: $subscribed)');

      if (showAds) {
        // Ads enabled - reload them
        _preloadAds();
      } else {
        // Ads disabled - dispose them to save resources
        _disposeAllAds();
      }
    }
  }

  void _disposeAllAds() {
    disposeBannerAd();

    for (final ad in _nativeAds) {
      ad.dispose();
    }
    _nativeAds.clear();
    isNativeAdLoaded.value = false;

    for (final ad in _interstitialAds) {
      ad.dispose();
    }
    _interstitialAds.clear();
    isInterstitialAdLoaded.value = false;

    // Keep rewarded ads loaded just in case user wants to earn credits
    // But maybe dispose them too if we want a clean slate? 
    // Let's keep them as they are "opt-in" anyway.

    _appOpenAd?.dispose();
    _appOpenAd = null;
    isAppOpenAdLoaded.value = false;
  }

  void _preloadAds() {
    if (!shouldShowAds.value) return;

    if (AdConfig.showBannerAd) loadBannerAd();
    if (AdConfig.showNativeAd) _preloadNativeAds();
    if (AdConfig.showInterstitialAd) _preloadInterstitialAds();
    if (AdConfig.showRewardedAd) _preloadRewardedAds();
    if (AdConfig.showAppOpenAd) loadAppOpenAd();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                           BANNER AD METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> loadBannerAd() async {
    if (!AdConfig.showBannerAd || !shouldShowAds.value) return;
    if (isBannerAdLoaded.value) return;

    final ctx = Get.context;
    if (ctx == null) {
      _bannerAdRetryAttempt++;
      Future.delayed(_calculateRetryDelay(_bannerAdRetryAttempt), loadBannerAd);
      return;
    }

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(ctx).size.width.truncate(),
    );

    if (size == null) {
      debugPrint('AdService: Unable to get adaptive banner size');
      // Retry with exponential backoff
      _bannerAdRetryAttempt++;
      final retryDelay = _calculateRetryDelay(_bannerAdRetryAttempt);
      Future.delayed(retryDelay, loadBannerAd);
      return;
    }

    bannerAd.value = BannerAd(
      adUnitId: AdConfig.bannerAdId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerAdLoaded.value = true;
          _bannerAdRetryAttempt = 0;
          debugPrint('AdService: Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          isBannerAdLoaded.value = false;
          ad.dispose();
          bannerAd.value = null;
          debugPrint('AdService: Banner ad failed to load: ${error.message}');
          // Exponential backoff retry
          _bannerAdRetryAttempt++;
          final retryDelay = _calculateRetryDelay(_bannerAdRetryAttempt);
          debugPrint('AdService: Retrying banner ad in ${retryDelay.inSeconds}s');
          Future.delayed(retryDelay, loadBannerAd);
        },
      ),
    );

    bannerAd.value?.load();
  }

  void disposeBannerAd() {
    bannerAd.value?.dispose();
    bannerAd.value = null;
    isBannerAdLoaded.value = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                           NATIVE AD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Preload multiple native ads for instant availability
  void _preloadNativeAds() {
    debugPrint('AdService: Preloading $_maxNativeAdsPool native ads...');
    for (int i = 0; i < _maxNativeAdsPool; i++) {
      _loadSingleNativeAd();
    }
  }

  /// Load a single native ad with retry mechanism
  void _loadSingleNativeAd({bool isDarkMode = false}) {
    if (!AdConfig.showNativeAd || !shouldShowAds.value) return;

    // Don't load if pool is full
    if (_nativeAds.length >= _maxNativeAdsPool) {
      debugPrint('AdService: Native ad pool full (${_nativeAds.length}/$_maxNativeAdsPool)');
      return;
    }

    // Prevent too many concurrent loads
    if (_isLoadingNativeAd && _nativeAds.isNotEmpty) return;

    _isLoadingNativeAd = true;
    isLoadingNativeAd.value = true;

    final nativeAd = NativeAd(
      adUnitId: AdConfig.nativeAdId,
      factoryId: AdConfig.nativeAdFactoryId,
      customOptions: {
        'buttonColor': AdConfig.nativeButtonColor,
        'buttonTextColor': AdConfig.nativeButtonTextColor,
        'backgroundColor': isDarkMode
            ? AdConfig.nativeBackgroundColorDark
            : AdConfig.nativeBackgroundColor,
        'cornerRadius': AdConfig.nativeCornerRadius,
        'isDarkMode': isDarkMode,
      },
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isLoadingNativeAd = false;
          _nativeAds.add(ad as NativeAd);
          isNativeAdLoaded.value = true;
          isLoadingNativeAd.value = false;
          _nativeAdRetryAttempt = 0;
          debugPrint('AdService: Native ad loaded. Total: ${_nativeAds.length}');

          // Keep pool topped up
          if (_nativeAds.length < _maxNativeAdsPool) {
            Future.delayed(const Duration(milliseconds: 500), () => _loadSingleNativeAd(isDarkMode: isDarkMode));
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isLoadingNativeAd = false;
          isLoadingNativeAd.value = false;
          ad.dispose();
          debugPrint('AdService: Native ad failed to load: ${error.message}');

          // Exponential backoff retry
          _nativeAdRetryAttempt++;
          final retryDelay = _calculateRetryDelay(_nativeAdRetryAttempt);
          debugPrint('AdService: Retrying native ad in ${retryDelay.inSeconds}s (attempt $_nativeAdRetryAttempt)');
          Future.delayed(retryDelay, () => _loadSingleNativeAd(isDarkMode: isDarkMode));
        },
      ),
    );

    nativeAd.load();
  }

  /// Force reload native ads pool
  void _forceReloadNativeAds({bool isDarkMode = false}) {
    debugPrint('AdService: Force reloading native ads...');
    _nativeAdRetryAttempt = 0;
    _isLoadingNativeAd = false;

    for (int i = 0; i < _minNativeAdsPool; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _isLoadingNativeAd = false;
        _loadSingleNativeAd(isDarkMode: isDarkMode);
      });
    }
  }

  /// Ensure native ads pool is topped up
  void _ensureNativeAdsPool({bool isDarkMode = false}) {
    if (_nativeAds.length < _minNativeAdsPool) {
      debugPrint('AdService: Native ad pool low (${_nativeAds.length}/$_minNativeAdsPool), loading more...');
      final adsToLoad = _maxNativeAdsPool - _nativeAds.length;
      for (int i = 0; i < adsToLoad; i++) {
        Future.delayed(Duration(milliseconds: i * 300), () {
          _isLoadingNativeAd = false;
          _loadSingleNativeAd(isDarkMode: isDarkMode);
        });
      }
    }
  }

  /// Get a native ad - waits if none available
  Future<NativeAd?> getNativeAd({bool isDarkMode = false}) async {
    if (_nativeAds.isEmpty) {
      debugPrint('AdService: No native ad available, waiting for load...');
      _forceReloadNativeAds(isDarkMode: isDarkMode);

      // Wait for ad to load (max 10 seconds)
      final success = await _waitForNativeAd(timeout: const Duration(seconds: 10));
      if (!success || _nativeAds.isEmpty) {
        debugPrint('AdService: Timeout waiting for native ad');
        return null;
      }
    }

    final ad = _nativeAds.removeAt(0);

    // Ensure pool stays topped up
    _ensureNativeAdsPool(isDarkMode: isDarkMode);

    if (_nativeAds.isEmpty) {
      isNativeAdLoaded.value = false;
    }

    return ad;
  }

  /// Wait for a native ad to become available
  Future<bool> _waitForNativeAd({required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (_nativeAds.isNotEmpty) {
        stopwatch.stop();
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    stopwatch.stop();
    return _nativeAds.isNotEmpty;
  }

  /// Get native ad synchronously (returns null if not available)
  NativeAd? getNativeAdSync({bool isDarkMode = false}) {
    if (_nativeAds.isEmpty) {
      _forceReloadNativeAds(isDarkMode: isDarkMode);
      return null;
    }

    final ad = _nativeAds.removeAt(0);
    _ensureNativeAdsPool(isDarkMode: isDarkMode);

    if (_nativeAds.isEmpty) {
      isNativeAdLoaded.value = false;
    }

    return ad;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                        INTERSTITIAL AD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Preload multiple interstitial ads
  void _preloadInterstitialAds() {
    debugPrint('AdService: Preloading $_maxInterstitialAdsPool interstitial ads...');
    for (int i = 0; i < _maxInterstitialAdsPool; i++) {
      _loadSingleInterstitialAd();
    }
  }

  /// Load a single interstitial ad with retry mechanism
  void _loadSingleInterstitialAd() {
    if (!AdConfig.showInterstitialAd || !shouldShowAds.value) return;

    // Don't load if pool is full
    if (_interstitialAds.length >= _maxInterstitialAdsPool) {
      debugPrint('AdService: Interstitial ad pool full (${_interstitialAds.length}/$_maxInterstitialAdsPool)');
      return;
    }

    // Prevent too many concurrent loads
    if (_isLoadingInterstitialAd && _interstitialAds.isNotEmpty) return;

    _isLoadingInterstitialAd = true;
    isLoadingInterstitialAd.value = true;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitialAd = false;
          _interstitialAds.add(ad);
          isInterstitialAdLoaded.value = true;
          isLoadingInterstitialAd.value = false;
          _interstitialAdRetryAttempt = 0;
          debugPrint('AdService: Interstitial ad loaded. Total: ${_interstitialAds.length}');

          // Keep pool topped up
          if (_interstitialAds.length < _maxInterstitialAdsPool) {
            Future.delayed(const Duration(milliseconds: 500), _loadSingleInterstitialAd);
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitialAd = false;
          isLoadingInterstitialAd.value = false;
          debugPrint('AdService: Interstitial ad failed to load: ${error.message}');

          // Exponential backoff retry
          _interstitialAdRetryAttempt++;
          final retryDelay = _calculateRetryDelay(_interstitialAdRetryAttempt);
          debugPrint('AdService: Retrying interstitial ad in ${retryDelay.inSeconds}s (attempt $_interstitialAdRetryAttempt)');
          Future.delayed(retryDelay, _loadSingleInterstitialAd);
        },
      ),
    );
  }

  /// Force reload interstitial ads pool
  void _forceReloadInterstitialAds() {
    debugPrint('AdService: Force reloading interstitial ads...');
    _interstitialAdRetryAttempt = 0;
    _isLoadingInterstitialAd = false;

    for (int i = 0; i < _minInterstitialAdsPool; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _isLoadingInterstitialAd = false;
        _loadSingleInterstitialAd();
      });
    }
  }

  /// Ensure interstitial ads pool is topped up
  void _ensureInterstitialAdsPool() {
    if (_interstitialAds.length < _minInterstitialAdsPool) {
      debugPrint('AdService: Interstitial ad pool low (${_interstitialAds.length}/$_minInterstitialAdsPool), loading more...');
      final adsToLoad = _maxInterstitialAdsPool - _interstitialAds.length;
      for (int i = 0; i < adsToLoad; i++) {
        Future.delayed(Duration(milliseconds: i * 300), () {
          _isLoadingInterstitialAd = false;
          _loadSingleInterstitialAd();
        });
      }
    }
  }

  /// Wait for interstitial ad to become available
  Future<bool> _waitForInterstitialAd({required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (_interstitialAds.isNotEmpty) {
        stopwatch.stop();
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    stopwatch.stop();
    return _interstitialAds.isNotEmpty;
  }

  /// Show interstitial ad with callbacks - waits if not available
  void showInterstitialAd({
    AdCallback? onAdClosed,
    AdFailedCallback? onAdFailed,
  }) async {
    if (!AdConfig.showInterstitialAd || !shouldShowAds.value) {
      onAdClosed?.call();
      return;
    }

    // Check cooldown
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!).inSeconds;
      if (elapsed < AdConfig.interstitialCooldownSeconds) {
        debugPrint('AdService: Interstitial on cooldown. Remaining: ${AdConfig.interstitialCooldownSeconds - elapsed}s');
        onAdClosed?.call();
        return;
      }
    }

    // Wait for ad if not available
    if (_interstitialAds.isEmpty) {
      debugPrint('AdService: No interstitial ad available, waiting for load...');
      _forceReloadInterstitialAds();

      // Wait for ad (max 10 seconds)
      final success = await _waitForInterstitialAd(timeout: const Duration(seconds: 10));
      if (!success || _interstitialAds.isEmpty) {
        debugPrint('AdService: Timeout waiting for interstitial ad');
        onAdClosed?.call(); // Continue anyway
        return;
      }
    }

    final ad = _interstitialAds.removeAt(0);

    // Immediately ensure pool is topped up
    _ensureInterstitialAdsPool();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdClosed?.call();
        _ensureInterstitialAdsPool();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('AdService: Interstitial ad failed to show: ${error.message}');
        onAdFailed?.call(error.message);
        _ensureInterstitialAdsPool();
      },
    );

    ad.show();
    _lastInterstitialTime = DateTime.now();

    if (_interstitialAds.isEmpty) {
      isInterstitialAdLoaded.value = false;
    }
  }

  /// Check if interstitial ad is ready
  bool get isInterstitialReady => _interstitialAds.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  //                          REWARDED AD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Preload multiple rewarded ads to ensure availability
  void _preloadRewardedAds() {
    debugPrint('AdService: Preloading $_maxRewardedAdsPool rewarded ads...');
    for (int i = 0; i < _maxRewardedAdsPool; i++) {
      _loadSingleRewardedAd();
    }
  }

  /// Load a single rewarded ad with retry mechanism
  void _loadSingleRewardedAd() {
    if (!AdConfig.showRewardedAd) return;
    // Note: We might want Rewarded Ads even if shouldShowAds is false to allow user to earn MORE credits?
    // But typically 'Ad Free' means ad free. 
    // However, the requirement says "credit khatam hone ke bad ads chalu".
    // So if they have credits, ads are OFF. 
    // But rewarded ads are voluntary. Let's allow them to load so they can "top up" if they want? 
    // Or follow the prompt strictly: "buy kiya hain to usko ads remove kar dena hain"
    // Usually "Remove Ads" refers to forced ads (Banner/Interstitial/Native). 
    // Rewarded ads are usually exempt because they are user-initiated.
    // I will allow Rewarded Ads to load even if shouldShowAds is false, unless checking Logic.

    // Actually, prompt says: "credit available hain utni bar use image banana dena hain" -> No ads.
    // "credit khatam hone ke bad ads chalu kar dena hain" -> Ads ON.
    // So if credits > 0, we can skip loading forced ads.
    // Rewarded ads are needed for "Watch Ad to Scan" flow when credits == 0.
    // When credits > 0, user might arguably NOT want to see "Watch Ad" options.
    // I'll keep them loadable for now as they are low impact and user requested.

    // Don't load if we already have enough ads
    if (_rewardedAds.length >= _maxRewardedAdsPool) {
      debugPrint('AdService: Rewarded ad pool full (${_rewardedAds.length}/$_maxRewardedAdsPool)');
      return;
    }

    // Prevent concurrent loading
    if (_isLoadingRewardedAd && _rewardedAds.isNotEmpty) return;

    _isLoadingRewardedAd = true;
    isLoadingRewardedAd.value = true;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewardedAd = false;
          _rewardedAds.add(ad);
          isRewardedAdLoaded.value = true;
          isLoadingRewardedAd.value = false;
          _rewardedAdRetryAttempt = 0; // Reset retry counter on success
          debugPrint('AdService: Rewarded ad loaded. Total: ${_rewardedAds.length}');

          // Keep the pool topped up
          if (_rewardedAds.length < _maxRewardedAdsPool) {
            Future.delayed(const Duration(milliseconds: 500), _loadSingleRewardedAd);
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedAd = false;
          isLoadingRewardedAd.value = false;
          debugPrint('AdService: Rewarded ad failed to load: ${error.message}');

          // Exponential backoff retry (max 60 seconds)
          _rewardedAdRetryAttempt++;
          final retryDelay = _calculateRetryDelay(_rewardedAdRetryAttempt);
          debugPrint('AdService: Retrying rewarded ad in ${retryDelay.inSeconds}s (attempt $_rewardedAdRetryAttempt)');

          Future.delayed(retryDelay, _loadSingleRewardedAd);
        },
      ),
    );
  }

  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int attempt) {
    // 2, 4, 8, 16, 32, 60, 60... seconds
    final seconds = (2 << (attempt - 1).clamp(0, 5)).clamp(2, 60);
    return Duration(seconds: seconds);
  }

  /// Force reload rewarded ads pool (call when pool is empty)
  void _forceReloadRewardedAds() {
    debugPrint('AdService: Force reloading rewarded ads...');
    _rewardedAdRetryAttempt = 0;
    _isLoadingRewardedAd = false;

    // Load multiple ads immediately
    for (int i = 0; i < _minRewardedAdsPool; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _isLoadingRewardedAd = false;
        _loadSingleRewardedAd();
      });
    }
  }

  /// Show rewarded ad with callbacks
  /// If no ad is available, will wait for one to load (with timeout)
  void showRewardedAd({
    required RewardCallback onRewarded,
    AdCallback? onAdClosed,
    AdFailedCallback? onAdFailed,
  }) async {
    if (!AdConfig.showRewardedAd) {
      onAdFailed?.call('Rewarded ads disabled');
      return;
    }

    // If no ad is available, wait for one to load
    if (_rewardedAds.isEmpty) {
      debugPrint('AdService: No rewarded ad available, waiting for load...');

      // Force reload if pool is empty
      _forceReloadRewardedAds();

      // Wait for ad to load (max 15 seconds)
      final success = await _waitForRewardedAd(timeout: const Duration(seconds: 15));

      if (!success || _rewardedAds.isEmpty) {
        debugPrint('AdService: Timeout waiting for rewarded ad');
        onAdFailed?.call('Ad loading timeout');
        return;
      }
    }

    final ad = _rewardedAds.removeAt(0);

    // Immediately start preloading more ads
    _ensureRewardedAdsPool();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdClosed?.call();
        _ensureRewardedAdsPool();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('AdService: Rewarded ad failed to show: ${error.message}');
        onAdFailed?.call(error.message);
        _ensureRewardedAdsPool();
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        onRewarded(reward);
      },
    );

    if (_rewardedAds.isEmpty) {
      isRewardedAdLoaded.value = false;
    }
  }

  /// Wait for a rewarded ad to become available
  Future<bool> _waitForRewardedAd({required Duration timeout}) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (_rewardedAds.isNotEmpty) {
        stopwatch.stop();
        return true;
      }

      // Check every 100ms
      await Future.delayed(const Duration(milliseconds: 100));
    }

    stopwatch.stop();
    return _rewardedAds.isNotEmpty;
  }

  /// Ensure the rewarded ads pool is topped up
  void _ensureRewardedAdsPool() {
    if (_rewardedAds.length < _minRewardedAdsPool) {
      debugPrint('AdService: Rewarded ad pool low (${_rewardedAds.length}/$_minRewardedAdsPool), loading more...');
      final adsToLoad = _maxRewardedAdsPool - _rewardedAds.length;
      for (int i = 0; i < adsToLoad; i++) {
        Future.delayed(Duration(milliseconds: i * 300), () {
          _isLoadingRewardedAd = false;
          _loadSingleRewardedAd();
        });
      }
    }
  }

  /// Check if rewarded ad is ready
  bool get isRewardedReady => _rewardedAds.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  //                          APP OPEN AD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load app open ad with retry mechanism
  void loadAppOpenAd() {
    if (!AdConfig.showAppOpenAd || !shouldShowAds.value) return;
    if (isAppOpenAdLoaded.value) return; // Already loaded

    AppOpenAd.load(
      adUnitId: AdConfig.appOpenAdId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          isAppOpenAdLoaded.value = true;
          _appOpenAdRetryAttempt = 0;
          debugPrint('AdService: App open ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: App open ad failed to load: ${error.message}');
          // Exponential backoff retry
          _appOpenAdRetryAttempt++;
          final retryDelay = _calculateRetryDelay(_appOpenAdRetryAttempt);
          debugPrint('AdService: Retrying app open ad in ${retryDelay.inSeconds}s');
          Future.delayed(retryDelay, loadAppOpenAd);
        },
      ),
    );
  }


  /// Show app open ad (typically on splash or app resume)
  void showAppOpenAd({AdCallback? onAdClosed}) {
    // Don't show if external activity (camera/gallery) is in progress
    if (_isExternalActivityInProgress) {
      debugPrint('AdService: Skipping app open ad - external activity in progress');
      onAdClosed?.call();
      return;
    }

    if (!AdConfig.showAppOpenAd || !shouldShowAds.value || _isShowingAppOpenAd) {
      onAdClosed?.call();
      return;
    }


    // Check cooldown
    if (_lastAppOpenTime != null) {
      final elapsed = DateTime.now().difference(_lastAppOpenTime!).inSeconds;
      if (elapsed < AdConfig.appOpenCooldownSeconds) {
        debugPrint('AdService: App open ad on cooldown');
        onAdClosed?.call();
        return;
      }
    }

    if (_appOpenAd == null) {
      debugPrint('AdService: No app open ad available');
      onAdClosed?.call();
      loadAppOpenAd();
      return;
    }

    _isShowingAppOpenAd = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        isAppOpenAdLoaded.value = false;
        onAdClosed?.call();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        isAppOpenAdLoaded.value = false;
        onAdClosed?.call();
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
    _lastAppOpenTime = DateTime.now();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                              CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void onClose() {
    disposeBannerAd();

    for (final ad in _nativeAds) {
      ad.dispose();
    }
    _nativeAds.clear();

    for (final ad in _interstitialAds) {
      ad.dispose();
    }
    _interstitialAds.clear();

    for (final ad in _rewardedAds) {
      ad.dispose();
    }
    _rewardedAds.clear();

    _appOpenAd?.dispose();
    _appOpenAd = null;

    super.onClose();
  }
}
