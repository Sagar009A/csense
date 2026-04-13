/// Banner Ad Widget
/// Displays adaptive banner ad with shimmer loading
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/ad_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  bool _adLoadStarted = false;
  bool _shouldShowAds = true;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    // Initialize with current value
    try {
      _shouldShowAds = AdService.to.shouldShowAds.value;

      // Listen for changes safely
      _worker = ever(AdService.to.shouldShowAds, (bool val) {
        if (mounted) {
          // Schedule setState to avoid "during build" error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _shouldShowAds = val;
              });
            }
          });
        }
      });
    } catch (e) {
      debugPrint('BannerAdWidget: Error initializing ad listener: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load ad here instead of initState to safely access MediaQuery
    if (!_adLoadStarted) {
      _adLoadStarted = true;
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    if (!AdConfig.showBannerAd) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    debugPrint('BannerAdWidget: Loading banner ad...');

    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      debugPrint('BannerAdWidget: Unable to get adaptive banner size');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAdWidget: Banner ad loaded successfully');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'BannerAdWidget: Banner ad failed to load - ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        onAdClicked: (ad) {
          debugPrint('BannerAdWidget: Banner ad clicked');
        },
        onAdImpression: (ad) {
          debugPrint('BannerAdWidget: Banner ad impression');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _worker?.dispose();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.showBannerAd) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_shouldShowAds) return const SizedBox.shrink();

    if (_isLoading) {
      return _buildShimmer(isDark);
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      width: double.infinity,
      height: AdConfig.bannerAdShimmerHeight.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Color(AdConfig.shimmerBaseDark)
            : Color(AdConfig.shimmerBaseLight),
        highlightColor: isDark
            ? Color(AdConfig.shimmerHighlightDark)
            : Color(AdConfig.shimmerHighlightLight),
        child: Container(
          margin: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}

/// Sticky Bottom Banner Widget (for screens with fixed bottom area)
class StickyBottomBannerAd extends StatelessWidget {
  final Widget child;

  const StickyBottomBannerAd({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.showBannerAd) return child;

    return Column(
      children: [
        Expanded(child: child),
        const BannerAdWidget(),
      ],
    );
  }
}
