/// AdMob Configuration Constants
/// Centralized settings for all ad types - modify these to customize ads
library;

import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  //                              AD NETWORK TOGGLE
  // ═══════════════════════════════════════════════════════════════════════════
  /// Ad network to use: 'admob' (default) or 'adx' (Google Ad Manager / AdX)
  /// Set via Firebase RTDB ad_config → adNetwork: "adx" to switch to AdX
  static String adNetwork = 'admob';

  // AdX (Google Ad Manager) — Android ad unit IDs
  static String _adxAndroidBannerId       = '/21753324030,23133085249/com.chartsense.ai.app_Banner';
  static String _adxAndroidInterstitialId = '/21753324030,23133085249/com.chartsense.ai.app_Interstitial';
  static String _adxAndroidNativeId       = '/21753324030,23133085249/com.chartsense.ai.app_Native';
  static String _adxAndroidRectangleId    = '/21753324030,23133085249/com.chartsense.ai.app_Rectangle';
  static String _adxAndroidRewardedId     = '/21753324030,23133085249/com.chartsense.ai.app_Rewarded';

  // AdX (Google Ad Manager) — iOS ad unit IDs
  static String _adxIosBannerId       = '/21753324030,23133085249/6759394053_Banner';
  static String _adxIosInterstitialId = '/21753324030,23133085249/6759394053_Interstitial';
  static String _adxIosNativeId       = '/21753324030,23133085249/6759394053_Native';
  static String _adxIosRectangleId    = '/21753324030,23133085249/6759394053_Rectangle';
  static String _adxIosRewardedId     = '/21753324030,23133085249/6759394053_Rewarded';

  // ═══════════════════════════════════════════════════════════════════════════
  //                              MASTER SWITCHES
  // ═══════════════════════════════════════════════════════════════════════════
  /// Enable/disable banner ads globally
  static bool showBannerAd = true;

  /// Enable/disable native ads globally
  static bool showNativeAd = true;

  /// Enable/disable interstitial ads globally
  static bool showInterstitialAd = true;

  /// Enable/disable rewarded ads globally
  static bool showRewardedAd = true;

  /// Enable/disable app open ads globally (disabled to avoid _elements assertion on open)
  static bool showAppOpenAd = false;

  // ═══════════════════════════════════════════════════════════════════════════
  //                         GOOGLE TEST AD UNIT IDs
  // ═══════════════════════════════════════════════════════════════════════════
  // Official Google test ad IDs — used automatically in debug mode
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  // ═══════════════════════════════════════════════════════════════════════════
  //                              AD UNIT IDs
  // ═══════════════════════════════════════════════════════════════════════════
  // Android App ID: ca-app-pub-5601247182612981~3175984056 (set in AndroidManifest.xml)
  // iOS App ID:     ca-app-pub-5601247182612981~9289706503 (set in Info.plist)
  // Production Ad Unit IDs - ChartSense AI

  static String _bannerAdId = 'ca-app-pub-5601247182612981/2201893287';
  /// Banner Ad Unit ID
  static String get bannerAdId {
    if (kDebugMode) return _testBannerId;
    if (adNetwork == 'adx') return Platform.isIOS ? _adxIosBannerId : _adxAndroidBannerId;
    if (Platform.isIOS) {
      return 'ca-app-pub-5601247182612981/9404781216'; // iOS Production ID
    }
    if (_bannerAdId.isNotEmpty) return _bannerAdId;
    return _testBannerId; // Android Test ID fallback
  }

  static String _nativeAdId = 'ca-app-pub-5601247182612981/1035985340';
  /// Native Ad Unit ID
  static String get nativeAdId {
    if (kDebugMode) return _testNativeId;
    if (adNetwork == 'adx') return Platform.isIOS ? _adxIosNativeId : _adxAndroidNativeId;
    if (Platform.isIOS) {
      return 'ca-app-pub-5601247182612981/8762617538'; // iOS Production ID
    }
    if (_nativeAdId.isNotEmpty) return _nativeAdId;
    return _testNativeId; // Android Test ID fallback
  }

  static String _interstitialAdId = 'ca-app-pub-5601247182612981/2473356029';
  /// Interstitial Ad Unit ID
  static String get interstitialAdId {
    if (kDebugMode) return _testInterstitialId;
    if (adNetwork == 'adx') return Platform.isIOS ? _adxIosInterstitialId : _adxAndroidInterstitialId;
    if (Platform.isIOS) {
      return 'ca-app-pub-5601247182612981/6307844580'; // iOS Production ID
    }
    if (_interstitialAdId.isNotEmpty) return _interstitialAdId;
    return _testInterstitialId; // Android Test ID fallback
  }

  static String _rewardedAdId = 'ca-app-pub-5601247182612981/6004138004';
  /// Rewarded Ad Unit ID
  static String get rewardedAdId {
    if (kDebugMode) return _testRewardedId;
    if (adNetwork == 'adx') return Platform.isIOS ? _adxIosRewardedId : _adxAndroidRewardedId;
    if (Platform.isIOS) {
      return 'ca-app-pub-5601247182612981/5781706331'; // iOS Production ID
    }
    if (_rewardedAdId.isNotEmpty) return _rewardedAdId;
    return _testRewardedId; // Android Test ID fallback
  }

  /// Rectangle Ad Unit ID (AdX only — falls back to banner for AdMob)
  static String get rectangleAdId {
    if (kDebugMode) return _testBannerId;
    if (adNetwork == 'adx') return Platform.isIOS ? _adxIosRectangleId : _adxAndroidRectangleId;
    return bannerAdId;
  }

  static String _appOpenAdId = '';
  /// App Open Ad Unit ID
  static String get appOpenAdId {
    if (kDebugMode) return _testAppOpenId;
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // iOS Test ID
    }
    if (_appOpenAdId.isNotEmpty) return _appOpenAdId;
    return _testAppOpenId; // Android Test ID fallback
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                         NATIVE AD STYLING (Android)
  // ═══════════════════════════════════════════════════════════════════════════
  /// Call-to-action button background color (Purple)
  static int nativeButtonColor = 0xFF8B5CF6;

  /// Call-to-action button text color
  static int nativeButtonTextColor = 0xFFFFFFFF;

  /// Native ad background color (Light mode)
  static int nativeBackgroundColor = 0xFFFFFFFF;

  /// Native ad background color (Dark mode)
  static int nativeBackgroundColorDark = 0xFF1A1A24;

  /// Corner radius for native ad container and button
  static double nativeCornerRadius = 12.0;

  /// Native ad factory ID (must match Android/iOS registration)
  static String nativeAdFactoryId = 'mediumNativeAd';

  // ═══════════════════════════════════════════════════════════════════════════
  //                           TIMING & BEHAVIOR
  // ═══════════════════════════════════════════════════════════════════════════
  /// Minimum seconds between interstitial ads (Google recommends 30+ for better UX & policy)
  static int interstitialCooldownSeconds = 30;

  /// Minimum seconds between app open ads
  static int appOpenCooldownSeconds = 30;

  /// Number of ads to preload for each type
  static int preloadAdCount = 2;

  /// Timeout for ad loading in seconds
  static int adLoadTimeoutSeconds = 30;

  // ═══════════════════════════════════════════════════════════════════════════
  //                           SHIMMER SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  /// Shimmer base color for light mode
  static int shimmerBaseLight = 0xFFE2E8F0;

  /// Shimmer highlight color for light mode
  static int shimmerHighlightLight = 0xFFF1F5F9;

  /// Shimmer base color for dark mode
  static int shimmerBaseDark = 0xFF2D2D3A;

  /// Shimmer highlight color for dark mode
  static int shimmerHighlightDark = 0xFF3D3D4A;

  /// Native ad shimmer height
  static double nativeAdShimmerHeight = 280.0;

  /// Banner ad shimmer height 
  static double bannerAdShimmerHeight = 60.0;

  /// Update configuration from JSON (Firebase Remote Config / Realtime DB)
  static void fromJson(Map<dynamic, dynamic> json) {
    // Master switches
    if (json['showBannerAd'] != null) showBannerAd = json['showBannerAd'];
    if (json['showNativeAd'] != null) showNativeAd = json['showNativeAd'];
    if (json['showInterstitialAd'] != null) showInterstitialAd = json['showInterstitialAd'];
    if (json['showRewardedAd'] != null) showRewardedAd = json['showRewardedAd'];
    if (json['showAppOpenAd'] != null) showAppOpenAd = json['showAppOpenAd'];

    // Ad Network Toggle ('admob' or 'adx')
    if (json['adNetwork'] != null) adNetwork = json['adNetwork'].toString();

    // Ad Unit IDs (AdMob)
    if (json['bannerAdId'] != null) _bannerAdId = json['bannerAdId'];
    if (json['nativeAdId'] != null) _nativeAdId = json['nativeAdId'];
    if (json['interstitialAdId'] != null) _interstitialAdId = json['interstitialAdId'];
    if (json['rewardedAdId'] != null) _rewardedAdId = json['rewardedAdId'];
    if (json['appOpenAdId'] != null) _appOpenAdId = json['appOpenAdId'];

    // Ad Unit IDs (AdX / Google Ad Manager) — optional overrides, baked-in defaults above
    if (json['adxAndroidBannerId'] != null) _adxAndroidBannerId = json['adxAndroidBannerId'].toString();
    if (json['adxAndroidInterstitialId'] != null) _adxAndroidInterstitialId = json['adxAndroidInterstitialId'].toString();
    if (json['adxAndroidNativeId'] != null) _adxAndroidNativeId = json['adxAndroidNativeId'].toString();
    if (json['adxAndroidRectangleId'] != null) _adxAndroidRectangleId = json['adxAndroidRectangleId'].toString();
    if (json['adxAndroidRewardedId'] != null) _adxAndroidRewardedId = json['adxAndroidRewardedId'].toString();
    if (json['adxIosBannerId'] != null) _adxIosBannerId = json['adxIosBannerId'].toString();
    if (json['adxIosInterstitialId'] != null) _adxIosInterstitialId = json['adxIosInterstitialId'].toString();
    if (json['adxIosNativeId'] != null) _adxIosNativeId = json['adxIosNativeId'].toString();
    if (json['adxIosRectangleId'] != null) _adxIosRectangleId = json['adxIosRectangleId'].toString();
    if (json['adxIosRewardedId'] != null) _adxIosRewardedId = json['adxIosRewardedId'].toString();

    // Native Ad Styling
    if (json['nativeButtonColor'] != null) nativeButtonColor = json['nativeButtonColor'];
    if (json['nativeButtonTextColor'] != null) nativeButtonTextColor = json['nativeButtonTextColor'];
    if (json['nativeBackgroundColor'] != null) nativeBackgroundColor = json['nativeBackgroundColor'];
    if (json['nativeBackgroundColorDark'] != null) nativeBackgroundColorDark = json['nativeBackgroundColorDark'];
    if (json['nativeCornerRadius'] != null) nativeCornerRadius = (json['nativeCornerRadius'] as num).toDouble();
    if (json['nativeAdFactoryId'] != null) nativeAdFactoryId = json['nativeAdFactoryId'];

    // Timing & Behavior
    if (json['interstitialCooldownSeconds'] != null) interstitialCooldownSeconds = json['interstitialCooldownSeconds'];
    if (json['appOpenCooldownSeconds'] != null) appOpenCooldownSeconds = json['appOpenCooldownSeconds'];
    if (json['preloadAdCount'] != null) preloadAdCount = json['preloadAdCount'];
    if (json['adLoadTimeoutSeconds'] != null) adLoadTimeoutSeconds = json['adLoadTimeoutSeconds'];
    
    // Shimmer Settings
    if (json['shimmerBaseLight'] != null) shimmerBaseLight = json['shimmerBaseLight'];
    if (json['shimmerHighlightLight'] != null) shimmerHighlightLight = json['shimmerHighlightLight'];
    if (json['shimmerBaseDark'] != null) shimmerBaseDark = json['shimmerBaseDark'];
    if (json['shimmerHighlightDark'] != null) shimmerHighlightDark = json['shimmerHighlightDark'];
    if (json['nativeAdShimmerHeight'] != null) nativeAdShimmerHeight = (json['nativeAdShimmerHeight'] as num).toDouble();
    if (json['bannerAdShimmerHeight'] != null) bannerAdShimmerHeight = (json['bannerAdShimmerHeight'] as num).toDouble();
  }}
