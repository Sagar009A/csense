/// TeraBox Button Screen
/// Video loading screen with ads before playing TeraBox videos
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../common/widgets/native_ad_widget.dart';
import '../../../core/constants/ad_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../services/ad_service.dart';
import '../../../services/app_config_service.dart';
import '../../../services/app_settings_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/consent_service.dart';
import '../../../services/credit_service.dart';
import '../../../services/security_service.dart';
import '../../../services/subscription_service.dart';
import 'ad_manager.dart';
import 'premium_manager.dart';
import 'security_manager.dart';

class TeraBoxButtonScreen extends StatefulWidget {
  final String shortCode;

  const TeraBoxButtonScreen({super.key, required this.shortCode});

  @override
  State<TeraBoxButtonScreen> createState() => _TeraBoxButtonScreenState();
}

class _TeraBoxButtonScreenState extends State<TeraBoxButtonScreen> {
  Map<String, dynamic>? videoData;
  bool isLoadingVideo = false;
  String? videoError;
  Timer? loadingMessageTimer;
  int loadingMessageIndex = 0;

  // Global cache to coalesce multiple requests for the same shortCode
  static final Map<String, Future<_VideoFetchResult>> _inFlightRequests = {};

  // Rotating loading messages
  final List<String> loadingMessages = [
    "⏳ Please wait…",
    "🔄 Loading…",
    "🎬 Preparing video…",
    "🚀 Almost ready…",
    "📡 Fetching data…",
    "⚡ Processing…",
    "🎥 Starting playback…",
    "🔍 Analyzing link…",
    "🧠 Smart mode active…",
    "⏱ Just a moment…",
  ];

  // ─── Direct ad unit IDs (no admin panel dependency) ─────────────────
  static String get _nativeAdUnit => AdConfig.nativeAdId;
  static String get _rewardedAdUnit => AdConfig.rewardedAdId;
  static String get _interstitialAdUnit => AdConfig.interstitialAdId;

  bool isTopAdLoaded = false;
  bool isBottomAdLoaded = false;
  bool _isTopAdLoading = false;
  bool _isBottomAdLoading = false;

  // Direct rewarded + interstitial (loaded without AdService)
  RewardedAd? _directRewarded;
  InterstitialAd? _directInterstitial;
  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;

  // Safe defaults - no late crash
  int userId = 1;
  bool isPremiumUser = false;
  bool isPremiumUserBasic = false;

  // Ad readiness: wait for at least one native ad to load (or timeout)
  bool _adReadyOrTimeout = false;
  Timer? _adWaitTimer;

  // Cached SharedPreferences to avoid repeated getInstance() calls
  SharedPreferences? _prefs;

  // Native ads are displayed via NativeAdWidget() directly in the build method.
  // These stubs are kept for call-site compatibility; actual loading is self-managed.
  void loadTopAd({bool useFallback = false}) {}

  void loadBottomAd({bool useFallback = false}) {}

  /// Load rewarded ad directly (no AdService dependency)
  void _loadDirectRewarded() {
    if (isPremiumUser || _isRewardedLoading || _directRewarded != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _directRewarded = ad;
          _isRewardedLoading = false;
          debugPrint('✅ Direct rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('❌ Direct rewarded failed: ${error.message}');
        },
      ),
    );
  }

  /// Load interstitial ad directly (no AdService dependency)
  void _loadDirectInterstitial() {
    if (isPremiumUser || _isInterstitialLoading || _directInterstitial != null)
      return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _directInterstitial = ad;
          _isInterstitialLoading = false;
          debugPrint('✅ Direct interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('❌ Direct interstitial failed: ${error.message}');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Security check
    if (SecurityManager.isDeviceCompromised || SecurityManager.isAppTampered) {
      debugPrint(
        '⚠️ Security Warning: App may not function properly on compromised device',
      );
    }

    // Defer ALL work to after first frame to avoid _elements.contains(element).
    // Never call setState or async work that does setState from initState when opened as initial route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.microtask(() => _bootAndInit());
    });
  }

  /// Initialize core services if opened directly (deep link, no Splash).
  /// Then proceed with ad / version-check init and fetch video.
  Future<void> _bootAndInit() async {
    if (!mounted) return;
    // Small delay so element is definitely in tree (avoids framework assertion on some devices).
    await Future.delayed(const Duration(milliseconds: 20));
    if (!mounted) return;

    // Pre-cache SharedPreferences once (used by multiple methods)
    _prefs ??= await SharedPreferences.getInstance();

    // Check premium from cache IMMEDIATELY — premium users skip all ad waits
    final cachedPremium = _prefs!.getBool('is_premium') ?? false;
    if (cachedPremium) {
      isPremiumUser = true;
      _adReadyOrTimeout = true;
      if (mounted) setState(() {});
    }

    // Load ads DIRECTLY (no admin panel / AdService dependency) — instant start
    if (!isPremiumUser) {
      // Initialize MobileAds SDK first (required before loading any ads)
      // In deeplink flow, AdService may not be initialized yet
      await MobileAds.instance.initialize();
      debugPrint('🎬 MobileAds SDK initialized for deeplink flow');
      loadTopAd();
      loadBottomAd();
      _loadDirectRewarded();
      _loadDirectInterstitial();
      _adWaitTimer?.cancel();
      _adWaitTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_adReadyOrTimeout) {
          setState(() => _adReadyOrTimeout = true);
        }
      });
    }

    // Run service init (needed for premium check on deeplink)
    final servicesFuture = () async {
      if (!Get.isRegistered<AdService>()) {
        await _initCoreServicesIfNeeded();
      }
      if (!mounted) return;

      // ── COMPULSORY premium re-check after services are ready ──
      // CreditService + AuthService are now initialized; re-verify premium status
      await PremiumManager.load();
      if (PremiumManager.isPremiumUser && !isPremiumUser) {
        isPremiumUser = true;
        isPremiumUserBasic = true;
        _adReadyOrTimeout = true;
        debugPrint('🎬 Deeplink: Premium confirmed after service init ✅');
        if (mounted) setState(() {});
      }

      // Prefs, ads, and version check are independent - run in parallel
      await Future.wait([
        _initializePreferencesAndAds(),
        loadAdSettings(),
        _checkVersionOnInit(),
      ]);
    }();

    // Video fetch strategy (same as SmartBuy):
    // - Fetch video data IMMEDIATELY in parallel with service init
    // - Don't wait for services to complete — avoids network error blocking video
    // - If service init later confirms premium, re-fetch with tera3.php
    final videoFetchFuture = widget.shortCode.isNotEmpty
        ? fetchVideoData(widget.shortCode)
        : Future<void>.value();
 
    // Run both in parallel — video fetch should not depend on service init
    await Future.wait([videoFetchFuture, servicesFuture]);

    // After services are ready, if user turned out to be premium but video was
    // fetched with tera2.php (free), re-fetch with tera3.php for better quality
    if (isPremiumUser && widget.shortCode.isNotEmpty && videoData != null) {
      final usedFreeApi = !(videoData!['videoUrl']?.toString().contains('fast_stream') ?? false);
      if (usedFreeApi) {
        debugPrint('🎬 Deeplink: Re-fetching with tera3.php (premium confirmed after init)');
        await fetchVideoData(widget.shortCode);
      }
    }
  }

  /// Lightweight service bootstrap for deep-link cold-start (no Splash).
  Future<void> _initCoreServicesIfNeeded() async {
    try {
      // Security + Firebase in parallel (both are independent)
      await Future.wait([
        if (!Get.isRegistered<SecurityService>())
          Get.putAsync(() => SecurityService().init()),
      ]);

      // Firebase init separately with try-catch for iOS safety
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (e) {
          debugPrint('ButtonScreen: Firebase init error (may already be initialized): $e');
        }
      }

      // Firebase-dependent services in parallel
      await Future.wait([
        if (!Get.isRegistered<AppConfigService>())
          Get.putAsync(() => AppConfigService().init()),
        if (!Get.isRegistered<AppSettingsService>())
          Get.putAsync(() => AppSettingsService().init()),
        if (!Get.isRegistered<ConnectivityService>())
          Get.putAsync(() => ConnectivityService().init()),
      ]);

      // Auth + Credit services (needed for premium status on deep link)
      if (!Get.isRegistered<CreditService>()) {
        Get.put(CreditService());
      }
      if (!Get.isRegistered<AuthService>()) {
        Get.put(AuthService());
      }
      // SubscriptionService is required by PurchaseController — must be registered
      // before any purchase screen can be opened from this deep-link path.
      if (!Get.isRegistered<SubscriptionService>()) {
        Get.put(SubscriptionService());
        await Get.find<SubscriptionService>().init();
      }

      // Wait for Firebase Auth state to settle so CreditService loads premium
      await Future.delayed(const Duration(milliseconds: 600));
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn && auth.currentUser.value != null) {
        final user = auth.currentUser.value!;
        final cs = Get.find<CreditService>();
        await cs.initializeUserCredits(
          user.uid,
          user.email ?? '',
          isGuest: user.isAnonymous,
        );
      }

      // Re-check premium from CreditService (authoritative source)
      await PremiumManager.load();
      if (PremiumManager.isPremiumUser) {
        isPremiumUser = true;
        isPremiumUserBasic = true;
        if (mounted) setState(() => _adReadyOrTimeout = true);
        return; // skip Consent + AdService entirely for premium users
      }

      // Consent FIRST, then ads (consent must complete before ad requests)
      await ConsentService.instance.requestConsentAndShowFormIfRequired();

      try {
        await Get.putAsync<AdService>(() => AdService().init());
      } catch (e) {
        debugPrint('ButtonScreen: AdService init error: $e');
      }
    } catch (e) {
      debugPrint('ButtonScreen: Core services init error: $e');
    }
  }

  /// Defer navigation to avoid _elements.contains(element) assertion when called from ad callbacks.
  void _safeNavigate(VoidCallback navigate) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        navigate();
      });
    });
  }

  Future<void> _checkVersionOnInit() async {
    await _ensureSettingsLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkChartSenseForceUpdate();
    });
  }

  /// Uses ChartSenseAI Firebase app_settings (forceUpdateVersion, forceUpdateMessage) and app store link – not SmartBuy/terabox.
  Future<void> _checkChartSenseForceUpdate() async {
    try {
      final settings = Get.find<AppSettingsService>();
      final config = Get.find<AppConfigService>();
      final currentVersion = await _getCurrentVersion();
      if (currentVersion.isEmpty) return;

      if (!settings.isForceUpdateRequired(currentVersion)) return;

      if (!mounted) return;

      final message = settings.forceUpdateMessage.value.trim().isNotEmpty
          ? settings.forceUpdateMessage.value
          : 'Please update to the latest version to continue using the app.';

      final urlText = GetPlatform.isIOS
          ? config.appStoreUrl.value.trim()
          : config.playStoreUrl.value.trim();
      final storeUri = urlText.isNotEmpty
          ? Uri.tryParse(urlText)
          : Uri.parse(
              GetPlatform.isIOS
                  ? 'https://apps.apple.com/in/app/chartsense-ai/id6759394053'
                  : 'https://play.google.com/store/apps/details?id=com.chartsense.ai.app',
            );

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              backgroundColor: AppColors.cardDark,
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(15.r),
                      child: Icon(
                        Icons.download_rounded,
                        size: 50.w,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "New Version Available",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (storeUri != null &&
                              await canLaunchUrl(storeUri)) {
                            await launchUrl(
                              storeUri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          "Update",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Force update check error: $e');
    }
  }

  Future<String> _getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.trim();
    } catch (_) {
      return '';
    }
  }

  /// Fetches get_settings from teraboxurll.in and saves video_timer, player_status, native_ad_delay for PlayerScreen only. Force update and ads use ChartSenseAI (Firebase).
  Future<void> _ensureSettingsLoaded() async {
    try {
      final url = Uri.parse(
        'https://teraboxurll.in/admin_app/apis/get_settings.php',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) return;

      final Map<String, dynamic> data = jsonDecode(response.body);
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs!;

      // Write all settings in parallel (no need to await each one)
      await Future.wait([
        if (data['video_timer'] != null)
          prefs.setString('video_timer', data['video_timer'].toString()),
        if (data['player_status'] != null)
          prefs.setString('player_status', data['player_status'].toString()),
        if (data['native_ad_delay'] != null)
          prefs.setString(
            'native_ad_delay',
            data['native_ad_delay'].toString(),
          ),
      ]);
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> loadAdSettings() async {
    await PremiumManager.load();
    isPremiumUser = PremiumManager.isPremiumUser;
    isPremiumUserBasic = PremiumManager.isRewardedAdsDisabled;

    if (isPremiumUser) {
      debugPrint("User is premium. Ads will not be loaded.");
      _directRewarded?.dispose();
      _directRewarded = null;
      _directInterstitial?.dispose();
      _directInterstitial = null;
      if (mounted)
        setState(() {
          _adReadyOrTimeout = true;
          isTopAdLoaded = false;
          isBottomAdLoaded = false;
        });
    }
  }

  Future<void> _initializePreferencesAndAds() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final existingRewardedId = prefs.getString('rewarded_ad_id');
    if (existingRewardedId == null || existingRewardedId.isEmpty) {
      await prefs.setString('rewarded_ad_id', AdManager.rewardedId);
    }

    final userIdStr = prefs.getString('userId') ?? '1';
    userId = int.tryParse(userIdStr) ?? 1;
  }

  @override
  void dispose() {
    loadingMessageTimer?.cancel();
    _adWaitTimer?.cancel();
    _directRewarded?.dispose();
    _directInterstitial?.dispose();
    super.dispose();
  }

  void _startLoadingMessages() {
    loadingMessageTimer?.cancel();
    loadingMessageIndex = 0;
    loadingMessageTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        loadingMessageIndex =
            (loadingMessageIndex + 1) % loadingMessages.length;
      });
    });
  }

  Future<void> fetchVideoData(String shortCode) async {
    if (!mounted) return;

    setState(() {
      isLoadingVideo = true;
      videoError = null;
      videoData = null;
      loadingMessageIndex = 0;
    });
    _startLoadingMessages();

    final existing = _inFlightRequests[shortCode];
    final Future<_VideoFetchResult> requestFuture =
        existing ?? _loadVideoData(shortCode);

    if (existing == null) {
      _inFlightRequests[shortCode] = requestFuture;
    }

    _VideoFetchResult result;
    try {
      result = await requestFuture;
    } finally {
      _inFlightRequests.remove(shortCode);
    }

    if (!mounted) return;

    if (result.data != null) {
      setState(() {
        videoData = result.data;
        isLoadingVideo = false;
        videoError = null;
      });
      loadingMessageTimer?.cancel();
    } else {
      _setError(result.error ?? "Failed to load video");
    }
  }

  Future<_VideoFetchResult> _loadVideoData(String shortCode) async {
    final trackUrl =
        "https://teraboxurll.in/api/track_api.php?action=track&short_code=$shortCode&api_key=6f9a45a2901e0e83686415cd9365a3889c7a03a847546051aed4afc73f23af77";

    try {
      final trackResponse = await http
          .get(Uri.parse(trackUrl))
          .timeout(const Duration(seconds: 15));

      if (trackResponse.statusCode != 200) {
        return const _VideoFetchResult(error: "Failed to fetch video info");
      }

      final trackData = json.decode(trackResponse.body);
      final videoInfo = trackData['data'];

      if (videoInfo == null ||
          videoInfo['original_url'] == null ||
          videoInfo['original_url'].toString().isEmpty) {
        return const _VideoFetchResult(error: "Video URL not found");
      }

      final originalUrl = videoInfo['original_url'].toString();
      final tera2Url = isPremiumUser
          ? "https://teraboxurll.in/admin_app/apis/tera3.php"
          : "https://teraboxurll.in/admin_app/apis/tera2.php";
      debugPrint("🌐 Final API URL: $tera2Url | originalUrl: $originalUrl");

      final response = await http
          .post(
            Uri.parse(tera2Url),
            headers: {
              "User-Agent":
                  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
              "Content-Type": "application/json",
            },
            body: json.encode({"link": originalUrl}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        debugPrint(
          "TeraBox API response: ${const JsonEncoder.withIndent('  ').convert(resData)}",
          wrapWidth: 4096,
        );

        // ============================================
        // HANDLE ALL RESPONSE FORMATS
        // ============================================
        // Format 1: { "status": true/false, "data": { "errno": 0, "list": [...] } }
        // Format 2: { "status": false, "message": "...", "raw_response": { "errno": 0, "list": [...] } }
        // Format 3: { "errno": 0, "list": [...] }
        // Format 4: { "status": "success", "list": [...] }

        List<dynamic>? fileList;

        // Format 1: Check for data.list (new format with status + data wrapper)
        if (resData['data'] != null &&
            resData['data'] is Map &&
            resData['data']['list'] != null) {
          final data = Map<String, dynamic>.from(resData['data'] as Map);
          if (data['errno'] == 0) {
            fileList = data['list'] as List<dynamic>?;
          }
        }
        // Format 2: Check for raw_response (PHP error wrapper)
        else if (resData['raw_response'] != null &&
            resData['raw_response'] is Map) {
          final raw = Map<String, dynamic>.from(resData['raw_response'] as Map);
          if (raw['errno'] == 0 && raw['list'] != null) {
            fileList = raw['list'] as List<dynamic>?;
          }
        }
        // Format 3 & 4: Check for direct list
        else if (resData['list'] != null && resData['list'] is List) {
          if (resData['errno'] == null || resData['errno'] == 0) {
            fileList = resData['list'] as List<dynamic>?;
          }
        }

        if (fileList != null && fileList.isNotEmpty) {
          final fileData = Map<String, dynamic>.from(fileList[0] as Map);

          String? videoUrl;
          final fastStreamUrl = fileData['fast_stream_url'];
          final streamUrl = fileData['stream_url'];

          // Premium users get fast_stream_url, free users get stream_url
          if (isPremiumUser && fastStreamUrl != null && fastStreamUrl is Map) {
            final preferred = [
              fastStreamUrl['480p'],
              fastStreamUrl['360p'],
              fastStreamUrl['720p'],
              fastStreamUrl['1080p'],
              fastStreamUrl['4k'],
              fastStreamUrl['2160p'],
            ];
            for (final candidate in preferred) {
              if (_isPlayableUrl(candidate)) {
                videoUrl = candidate.toString();
                break;
              }
            }
          }

          // Free user: use stream_url (or fallback for premium if fast_stream failed)
          if (videoUrl == null && _isPlayableUrl(streamUrl)) {
            videoUrl = streamUrl.toString();
          }

          // Last fallback: try fast_stream_url for free users too
          if (videoUrl == null &&
              fastStreamUrl != null &&
              fastStreamUrl is Map) {
            final preferred = [
              fastStreamUrl['480p'],
              fastStreamUrl['360p'],
              fastStreamUrl['720p'],
            ];
            for (final candidate in preferred) {
              if (_isPlayableUrl(candidate)) {
                videoUrl = candidate.toString();
                break;
              }
            }
          }

          if (videoUrl != null && videoUrl.isNotEmpty) {
            // Validate the selected stream URL before passing to player
            // If fast_stream_url is expired (401/403), fallback to stream_url
            try {
              final validationResponse = await http
                  .head(Uri.parse(videoUrl))
                  .timeout(const Duration(seconds: 5));
              if (validationResponse.statusCode == 401 ||
                  validationResponse.statusCode == 403) {
                debugPrint(
                  '⚠️ fast_stream_url returned ${validationResponse.statusCode}, falling back to stream_url',
                );
                if (streamUrl != null &&
                    streamUrl.toString().isNotEmpty &&
                    _isPlayableUrl(streamUrl)) {
                  videoUrl = streamUrl.toString();
                }
              }
            } catch (_) {
              // Validation failed (timeout etc), proceed with original URL
              debugPrint('⚠️ URL validation failed, using original URL');
            }

            // Filter out expired quality URLs from streamUrls
            Map<String, dynamic> validStreamUrls = <String, dynamic>{};
            if (fileData['fast_stream_url'] != null &&
                fileData['fast_stream_url'] is Map) {
              final rawUrls = Map<String, dynamic>.from(
                fileData['fast_stream_url'] as Map,
              );
              for (final entry in rawUrls.entries) {
                if (entry.value != null &&
                    entry.value.toString().isNotEmpty) {
                  validStreamUrls[entry.key] = entry.value;
                }
              }
            }

            return _VideoFetchResult(
              data: {
                "videoUrl": videoUrl,
                "title":
                    fileData['name'] ?? videoInfo['title'] ?? 'Untitled Video',
                "username": videoInfo['username'] ?? 'Unknown',
                "fileSize":
                    fileData['size_formatted'] ??
                    fileData['size']?.toString() ??
                    '0',
                "createdAt":
                    videoInfo['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
                "userAvatarUrl": AppAssets.appLogo,
                // Both users default to fast_download_link if available, then fallback to download_link.
                // We keep both so player screen can retry on failure
                "downloadLink": fileData['fast_download_link'] ?? fileData['download_link'] ?? fileData['zip_dlink'],
                "normalDownloadLink": fileData['download_link'],
                "streamDownloadUrl": fileData['stream_download_url'],
                "subtitleUrl": fileData['subtitle_url'] ?? resData['subtitle_url'],
                // Pass validated stream URLs
                "streamUrls": validStreamUrls,
                "originalUrl": originalUrl,
              },
            );
          } else {
            return const _VideoFetchResult(error: "Stream not available");
          }
        } else {
          // Check for error response from server
          if (resData['status'] == false || (resData['errno'] != null && resData['errno'] != 0)) {
            final errorMsg = resData['message'] ?? resData['errmsg'] ?? 'Unknown error';
            return _VideoFetchResult(error: errorMsg);
          }
          return const _VideoFetchResult(error: "No files found or invalid response");
        }
      } else {
        return _VideoFetchResult(error: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      return const _VideoFetchResult(error: "Network error. Please try again.");
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        isLoadingVideo = false;
        videoError = message;
      });
      loadingMessageTimer?.cancel();
    }
  }

  bool _isPlayableUrl(dynamic url) {
    if (url == null) return false;
    final value = url.toString().toLowerCase();
    return value.contains('.m3u8') || value.contains('m3u8') ||
        value.contains('.mp4') || value.contains('mp4');
  }

  bool get canGoToVideo =>
      videoData != null && (isPremiumUser || _adReadyOrTimeout);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        title: Text(
          'Go to Video',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              // Deeplink flow: no previous route, go to splash
              Get.offAllNamed(AppRoutes.splash);
            }
          },
        ),
      ),
      body: isPremiumUser
          ? Center(child: _buildButtonSection())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 360.h, child: const NativeAdWidget()),
                  _buildButtonSection(),
                  SizedBox(
                    height: 360.h,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: const NativeAdWidget(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildButtonSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error status
        if (videoError != null && !isLoadingVideo)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.errorLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.errorLight,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      videoError!,
                      style: TextStyle(
                        color: AppColors.errorLight,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => fetchVideoData(widget.shortCode),
                    child: Text(
                      "Retry",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: 10.h),

        // Button area
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SizedBox(
            width: double.infinity,
            height: 55.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canGoToVideo
                    ? AppColors.primaryLight
                    : AppColors.textSecondaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: canGoToVideo ? 4 : 0,
              ),
              onPressed: canGoToVideo && !isLoadingVideo
                  ? () async {
                      loadingMessageTimer?.cancel();

                      await PremiumManager.load();
                      final isPremium = PremiumManager.isPremiumUser;
                      final isRewardedDisabled =
                          PremiumManager.isRewardedAdsDisabled;

                      void navigateToVideo() {
                        final args = {
                          'videoUrl': videoData?['videoUrl'] ?? '',
                          'title':
                              videoData?['title'] ?? 'Untitled Video',
                          'username':
                              videoData?['username'] ?? 'Unknown',
                          'shortCode': widget.shortCode,
                          'fileSize': videoData?['fileSize'] ?? '0',
                          'createdAt':
                              videoData?['createdAt'] ??
                              DateTime.now().toIso8601String(),
                          'userAvatarUrl':
                              videoData?['userAvatarUrl'] ??
                              AppAssets.appLogo,
                          'subtitleUrl': videoData?['subtitleUrl'],
                          'streamUrls': videoData?['streamUrls'],
                          'downloadLink': videoData?['downloadLink'],
                          'normalDownloadLink': videoData?['normalDownloadLink'],
                          'streamDownloadUrl': videoData?['streamDownloadUrl'],
                          'originalUrl': videoData?['originalUrl'],
                        };
                        _safeNavigate(() {
                          Get.toNamed(
                            AppRoutes.teraboxPlayer,
                            arguments: args,
                          );
                        });
                      }

                      if (isPremium) {
                        navigateToVideo();
                      } else if (!isRewardedDisabled &&
                          _directRewarded != null) {
                        _directRewarded!.fullScreenContentCallback =
                            FullScreenContentCallback(
                              onAdDismissedFullScreenContent: (ad) {
                                ad.dispose();
                                _directRewarded = null;
                                _loadDirectRewarded();
                                navigateToVideo();
                              },
                              onAdFailedToShowFullScreenContent:
                                  (ad, error) {
                                    ad.dispose();
                                    _directRewarded = null;
                                    _loadDirectRewarded();
                                    navigateToVideo();
                                  },
                            );
                        _directRewarded!.show(
                          onUserEarnedReward: (_, reward) {
                            updateUserCount(userId, "ad_watch");
                          },
                        );
                      } else if (_directInterstitial != null) {
                        _directInterstitial!
                                .fullScreenContentCallback =
                            FullScreenContentCallback(
                              onAdDismissedFullScreenContent: (ad) {
                                ad.dispose();
                                _directInterstitial = null;
                                _loadDirectInterstitial();
                                navigateToVideo();
                              },
                              onAdFailedToShowFullScreenContent:
                                  (ad, error) {
                                    ad.dispose();
                                    _directInterstitial = null;
                                    _loadDirectInterstitial();
                                    navigateToVideo();
                                  },
                            );
                        _directInterstitial!.show();
                      } else {
                        bool adHandled = false;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => PopScope(
                            canPop: false,
                            child: Dialog(
                              backgroundColor: AppColors.cardDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16.r,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 40.w,
                                      height: 40.w,
                                      child:
                                          CircularProgressIndicator(
                                            color: AppColors
                                                .primaryLight,
                                            strokeWidth: 3,
                                          ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      "Loading ad...",
                                      style: TextStyle(
                                        color:
                                            AppColors.textPrimaryDark,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Please wait a moment",
                                      style: TextStyle(
                                        color: AppColors
                                            .textSecondaryDark,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        void dismissAndNavigate() {
                          if (adHandled) return;
                          adHandled = true;
                          if (mounted &&
                              Navigator.of(context).canPop()) {
                            Navigator.of(
                              context,
                            ).pop();
                          }
                          navigateToVideo();
                        }

                        Future.delayed(
                          const Duration(seconds: 10),
                          () {
                            dismissAndNavigate();
                          },
                        );

                        RewardedAd.load(
                          adUnitId: _rewardedAdUnit,
                          request: const AdRequest(),
                          rewardedAdLoadCallback: RewardedAdLoadCallback(
                            onAdLoaded: (ad) {
                              if (adHandled) {
                                ad.dispose();
                                return;
                              }
                              adHandled = true;
                              if (mounted &&
                                  Navigator.of(context).canPop()) {
                                Navigator.of(
                                  context,
                                ).pop();
                              }
                              ad.fullScreenContentCallback =
                                  FullScreenContentCallback(
                                    onAdDismissedFullScreenContent:
                                        (ad) {
                                          ad.dispose();
                                          navigateToVideo();
                                        },
                                    onAdFailedToShowFullScreenContent:
                                        (ad, error) {
                                          ad.dispose();
                                          navigateToVideo();
                                        },
                                  );
                              ad.show(
                                onUserEarnedReward: (_, reward) {
                                  updateUserCount(userId, "ad_watch");
                                },
                              );
                            },
                            onAdFailedToLoad: (error) {
                              debugPrint(
                                '🎬 Rewarded failed, trying interstitial: ${error.message}',
                              );
                              InterstitialAd.load(
                                adUnitId: _interstitialAdUnit,
                                request: const AdRequest(),
                                adLoadCallback: InterstitialAdLoadCallback(
                                  onAdLoaded: (ad) {
                                    if (adHandled) {
                                      ad.dispose();
                                      return;
                                    }
                                    adHandled = true;
                                    if (mounted &&
                                        Navigator.of(
                                          context,
                                        ).canPop()) {
                                      Navigator.of(
                                        context,
                                      ).pop();
                                    }
                                    ad.fullScreenContentCallback =
                                        FullScreenContentCallback(
                                          onAdDismissedFullScreenContent:
                                              (ad) {
                                                ad.dispose();
                                                navigateToVideo();
                                              },
                                          onAdFailedToShowFullScreenContent:
                                              (ad, error) {
                                                ad.dispose();
                                                navigateToVideo();
                                              },
                                        );
                                    ad.show();
                                  },
                                  onAdFailedToLoad: (error) {
                                    debugPrint(
                                      '🎬 Interstitial also failed: ${error.message}',
                                    );
                                    dismissAndNavigate();
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      }
                    }
                  : null,
              child: canGoToVideo
                  ? Text(
                      'Go to Videos',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          isLoadingVideo
                              ? loadingMessages[loadingMessageIndex]
                              : "Please wait...",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> updateUserCount(int userId, String action) async {
    final url = Uri.parse(
      "https://teraboxurll.in/admin_app/apis/update_user_counts.php",
    );

    try {
      await http.post(
        url,
        body: {"user_id": userId.toString(), "action": action},
      );
    } catch (e) {
      debugPrint("Network error: $e");
    }
  }
}

class _VideoFetchResult {
  final Map<String, dynamic>? data;
  final String? error;

  const _VideoFetchResult({this.data, this.error});
}
