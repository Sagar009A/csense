/// Native Ad Widget
/// Displays native ad with shimmer loading and theme support
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../../core/constants/ad_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ad_service.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _shouldShowAds = true; // default to showing ads
  Worker? _adVisibilityWorker;
  Worker? _poolAdWorker;
  Timer? _poolPollTimer;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdService>()) {
      // Normal flow: AdService already initialized, consume ad from pool
      _setupAdVisibilityListener();
      _loadAd();
    } else {
      // Deeplink cold start: wait for AdService (MobileAds) to be ready
      _waitForAdService();
    }
  }

  /// Poll until AdService is registered, then set up listener and load ad.
  void _waitForAdService() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (Get.isRegistered<AdService>()) {
        _setupAdVisibilityListener();
        _loadAd();
      } else {
        _waitForAdService();
      }
    });
  }

  void _setupAdVisibilityListener() {
    _adVisibilityWorker?.dispose();
    final adService = AdService.to;
    // Immediately sync current value
    if (mounted) {
      setState(() => _shouldShowAds = adService.shouldShowAds.value);
    }
    // Listen for future changes (e.g. user subscribes)
    _adVisibilityWorker = ever(adService.shouldShowAds, (bool show) {
      if (mounted) setState(() => _shouldShowAds = show);
    });
  }

  void _loadAd() {
    if (!AdConfig.showNativeAd) {
      setState(() => _isLoading = false);
      return;
    }

    // Try to consume a pre-loaded native ad from AdService pool first.
    // This avoids issuing a new NativeAd request on every widget mount.
    if (Get.isRegistered<AdService>()) {
      _consumeFromPool();
    } else {
      // Deeplink cold start fallback: load directly (AdService not available)
      final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
      _loadNewAd(isDark);
    }
  }

  /// Pop a ready native ad from AdService pool. If the pool is empty, subscribe
  /// to the pool's loaded-state observable and consume the next one that arrives.
  void _consumeFromPool() {
    final adService = AdService.to;
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final pooled = adService.getNativeAdSync(isDarkMode: isDark);
    if (pooled != null) {
      debugPrint('NativeAdWidget: Consumed native ad from pool');
      if (mounted) {
        setState(() {
          _nativeAd = pooled;
          _isLoaded = true;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    // Pool empty — wait for the pool to refill (AdService is already loading).
    debugPrint('NativeAdWidget: Pool empty, waiting for refill...');
    _poolAdWorker?.dispose();
    _poolAdWorker = ever(adService.isNativeAdLoaded, (bool loaded) {
      if (!mounted || _nativeAd != null) return;
      if (loaded) {
        final ad = adService.getNativeAdSync(isDarkMode: isDark);
        if (ad != null) {
          _poolAdWorker?.dispose();
          _poolAdWorker = null;
          _poolPollTimer?.cancel();
          _poolPollTimer = null;
          setState(() {
            _nativeAd = ad;
            _isLoaded = true;
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    });

    // Safety timeout: if pool never fills within 8s, stop waiting and hide.
    _poolPollTimer?.cancel();
    _poolPollTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _nativeAd != null) return;
      _poolAdWorker?.dispose();
      _poolAdWorker = null;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  void _loadNewAd(bool isDark) {
    debugPrint('NativeAdWidget: Loading native ad directly (no pool)...');

    _nativeAd = NativeAd(
      adUnitId: AdConfig.nativeAdId,
      factoryId: AdConfig.nativeAdFactoryId,
      customOptions: {
        'buttonColor': AdConfig.nativeButtonColor,
        'buttonTextColor': AdConfig.nativeButtonTextColor,
        'backgroundColor': isDark
            ? AdConfig.nativeBackgroundColorDark
            : AdConfig.nativeBackgroundColor,
        'cornerRadius': AdConfig.nativeCornerRadius,
        'isDarkMode': isDark,
      },
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('NativeAdWidget: Ad loaded successfully');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
              _hasError = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'NativeAdWidget: Failed to load - ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          _nativeAd = null;
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
        onAdClicked: (ad) {
          debugPrint('NativeAdWidget: Ad clicked');
        },
        onAdImpression: (ad) {
          debugPrint('NativeAdWidget: Ad impression recorded');
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _adVisibilityWorker?.dispose();
    _poolAdWorker?.dispose();
    _poolPollTimer?.cancel();
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.showNativeAd) return const SizedBox.shrink();
    if (!_shouldShowAds) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildShimmer(isDark);
    }

    if (_hasError || !_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AdConfig.nativeCornerRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AdConfig.nativeCornerRadius.r),
        child: SizedBox(
          height: 350.h,
          width: double.infinity,
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      height: 260.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AdConfig.nativeCornerRadius.r),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Color(AdConfig.shimmerBaseDark)
            : Color(AdConfig.shimmerBaseLight),
        highlightColor: isDark
            ? Color(AdConfig.shimmerHighlightDark)
            : Color(AdConfig.shimmerHighlightLight),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad badge shimmer
              Container(
                width: 24.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              // Media shimmer
              Container(
                width: double.infinity,
                height: 180.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 12.h),
              // Content row shimmer
              Row(
                children: [
                  // Icon shimmer
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Text shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 100.w,
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Button shimmer
              Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AdConfig.nativeCornerRadius.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
