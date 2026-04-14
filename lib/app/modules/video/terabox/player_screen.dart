/// TeraBox Player Screen
/// Full-featured video player for TeraBox streams
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'widgets/video_player_service.dart';
import 'widgets/custom_controls.dart';
import 'widgets/player_helpers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stockmarket_analysis/app/common/widgets/native_ad_widget.dart';
import '../../../core/constants/ad_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import 'ad_manager.dart';
import 'premium_manager.dart';

class TeraBoxPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String username;
  final String shortCode;
  final String fileSize;
  final String createdAt;
  final String userAvatarUrl;
  final String? subtitleUrl;
  final Map<String, dynamic>? streamUrls;
  final String? downloadLink;
  final String? normalDownloadLink;
  final String? streamDownloadUrl;
  final String? originalUrl;

  const TeraBoxPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.username,
    required this.shortCode,
    required this.fileSize,
    required this.createdAt,
    required this.userAvatarUrl,
    this.subtitleUrl,
    this.streamUrls,
    this.downloadLink,
    this.normalDownloadLink,
    this.streamDownloadUrl,
    this.originalUrl,
  });

  @override
  State<TeraBoxPlayerScreen> createState() => _TeraBoxPlayerScreenState();
}

class _TeraBoxPlayerScreenState extends State<TeraBoxPlayerScreen> {
  late VideoPlayerService _playerService;

  // Gesture & controls state
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _hasAutoHidden = false;
  bool _showSkipHint = false;
  int _skipHintSeconds = 0;
  bool _isSkipForward = true;
  Timer? _skipHintTimer;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _isLongPress2x = false;
  bool _isLongPressRewind = false;
  double _speedBeforeLongPress = 1.0;
  Timer? _rewindTimer;

  bool hasTrackedView = false;
  int videoTimerSeconds = 10;
  int playerStatus = 0;

  int _lastSaveTime = 0; // throttle progress saves
  int _errorCount = 0;
  static const int _maxErrors = 3;
  bool _hasStoppedDueToErrors = false;

  bool _hasShownMaintenancePopup = false;
  late bool isPremiumUser;

  // Download related variables
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadStatus;
  RewardedAd? _downloadRewardedAd;
  bool _isDownloadRewardedLoading = false;
  bool _isWaitingForRewarded = false;
  bool _showingAdLoader = false;
  bool _isAdDialogVisible = false;

  Timer? adRefreshTimer;

  // Cached SharedPreferences — initialized once in initState, reused everywhere
  // to avoid repeated platform-channel round-trips that can contribute to ANRs.
  SharedPreferences? _prefs;

  // Cache the recommended videos future to prevent re-fetching on every rebuild
  late Future<List<Video>> _recommendedVideosFuture;

  // Subtitle state
  List<Map<String, String>> _subtitleSources = [];
  List<String> _subtitleUrls = [];
  int _currentSubtitleIndex = -1; // -1 = none
  String? _currentSubtitleText;
  String _currentQuality = 'Auto';

  Future<void> loadAdSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    await AdManager.configureFromPrefs();

    final userIdString = prefs.getString('userId');

    if (userIdString != null) {
      final userId = int.tryParse(userIdString) ?? 0;
      updateUserCount(userId, "total_video_watch");
    }

    await PremiumManager.load();
    isPremiumUser = PremiumManager.isPremiumUser;

    if (isPremiumUser) {
      if (mounted) setState(() {});
      return;
    }

    if (!PremiumManager.isPremiumUser &&
        !PremiumManager.isRewardedAdsDisabled) {
      _loadDownloadRewardedAd();
    }
  }

  Future<void> _loadVideoTimer() async {
    _prefs ??= await SharedPreferences.getInstance();
    videoTimerSeconds =
        int.tryParse(_prefs!.getString('video_timer') ?? '10') ?? 10;
  }

  Future<void> _checkMaintenance() async {
    _prefs ??= await SharedPreferences.getInstance();
    final status =
        int.tryParse(_prefs!.getString('player_status') ?? '0') ?? 0;
    if (mounted) setState(() => playerStatus = status);
  }

  @override
  void initState() {
    super.initState();
    isPremiumUser = false;

    _recommendedVideosFuture = fetchVideos();

    // Pre-cache SharedPreferences once so all subsequent calls (save progress,
    // timers, maintenance check) don't hit the platform channel every time.
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      if (!mounted) return;
      // Now that prefs is ready, kick off everything that needs it.
      loadAdSettings();
      _loadVideoTimer();
      _checkMaintenance();
    }).catchError((e) {
      debugPrint('PlayerScreen: SharedPreferences init failed: $e');
    });

    // Native ad refresh disabled — load once, don't auto-refresh
    // adRefreshTimer = Timer.periodic(const Duration(seconds: 100), (timer) {
    //   _refreshTopAd();
    // });

    // Subtitles loaded asynchronously — manifest returns HLS playlist, not direct SRT
    if (widget.subtitleUrl != null && widget.subtitleUrl!.isNotEmpty) {
      debugPrint('🎬 Subtitle URL: ${widget.subtitleUrl}');
      _loadSubtitlesFromManifest(widget.subtitleUrl!);
    }

    // Initialize VideoPlayerService
    _playerService = VideoPlayerService();
    _playerService.addListener(_onPlayerStateChanged);
    _playerService.initializePlayer(widget.videoUrl);

    // Check for resume position after player is ready
    _checkAndShowResumeDialog();

    // Start auto-hide controls timer
    _startHideControlsTimer();
  }

  /// Listener for VideoPlayerService state changes
  PlayerState? _lastKnownState;

  void _onPlayerStateChanged() {
    if (!mounted) return;

    // Maintenance popup
    if (playerStatus == 1 && !_hasShownMaintenancePopup) {
      _hasShownMaintenancePopup = true;
      _showMaintenancePopup();
    }

    // Track video play
    if (!hasTrackedView && _playerService.isPlaying) {
      final position = _playerService.position;
      if (position.inSeconds >= videoTimerSeconds) {
        hasTrackedView = true;
        _trackVideoPlay(widget.shortCode);
      }
    }

    // Save watch progress every 5 seconds of playback
    if (_playerService.isPlaying) {
      final nowSec = _playerService.position.inSeconds;
      if ((nowSec - _lastSaveTime).abs() >= 5) {
        _lastSaveTime = nowSec;
        _saveWatchProgress(widget.shortCode, _playerService.position);
      }
    }

    // Error handling — only increment once per error transition
    final currentState = _playerService.state;
    if (_playerService.hasError && _lastKnownState != PlayerState.error) {
      _errorCount++;
      debugPrint('🚨 Video error #$_errorCount/$_maxErrors');
      if (_errorCount >= _maxErrors && !_hasStoppedDueToErrors) {
        _hasStoppedDueToErrors = true;
        _playerService.pause();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                'Video Unavailable',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              content: Text(
                'Stream has expired or is unavailable. Please go back and try again.',
                style: TextStyle(color: AppColors.textSecondaryDark),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Go Back',
                    style: TextStyle(color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          );
        }
      }
      _lastKnownState = currentState;
      setState(() {}); // Rebuild for error state
      return;
    }
    _lastKnownState = currentState;

    // Auto-hide controls when player first starts playing
    if (_playerService.isPlaying && _showControls && !_hasAutoHidden) {
      _hasAutoHidden = true;
      _startHideControlsTimer();
    }

    // Safe at 1Hz polling — only 1 rebuild per second
    // Must be unconditional so subtitles update via _getCurrentSubtitleText()
    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _playerService.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _handleDoubleTap(TapDownDetails details, BoxConstraints constraints) {
    final tapX = details.localPosition.dx;
    final screenWidth = constraints.maxWidth;
    final isForward = tapX > screenWidth / 2;

    _skipHintTimer?.cancel();
    setState(() {
      _showSkipHint = true;
      _isSkipForward = isForward;
      _skipHintSeconds = isForward ? 10 : -10;
    });

    if (isForward) {
      _playerService.seekForward(10);
    } else {
      _playerService.seekBackward(10);
    }

    _skipHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showSkipHint = false);
    });
    _startHideControlsTimer();
  }

  void _handleVerticalDrag(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    final tapX = details.localPosition.dx;
    final screenWidth = constraints.maxWidth;
    final isRightSide = tapX > screenWidth / 2;
    final delta = -details.delta.dy / 200;

    if (isRightSide) {
      // Volume
      final newVol = (_playerService.volume + delta * 100).clamp(0.0, 100.0);
      _playerService.setVolume(newVol);
      setState(() => _showVolumeIndicator = true);
    } else {
      // Brightness
      final newBright = (_playerService.brightness + delta).clamp(0.0, 1.0);
      _playerService.setBrightness(newBright);
      setState(() => _showBrightnessIndicator = true);
    }
  }

  void _handleVerticalDragEnd() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  void _handleLongPressStart(
    LongPressStartDetails details,
    BoxConstraints constraints,
  ) {
    if (!_playerService.isInitialized) return;
    final tapX = details.localPosition.dx;
    final screenWidth = constraints.maxWidth;
    final isRightSide = tapX > screenWidth / 2;

    _speedBeforeLongPress = _playerService.playbackSpeed;
    _hideControlsTimer?.cancel();

    if (isRightSide) {
      // Right side → 2X forward
      _playerService.setPlaybackSpeed(2.0);
      setState(() {
        _isLongPress2x = true;
        _isLongPressRewind = false;
        _showControls = false;
      });
    } else {
      // Left side → continuous rewind
      setState(() {
        _isLongPress2x = false;
        _isLongPressRewind = true;
        _showControls = false;
      });
      _rewindTimer?.cancel();
      _playerService.seekBackward(2);
      _rewindTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (_isLongPressRewind && _playerService.isInitialized) {
          _playerService.seekBackward(2);
        }
      });
    }
  }

  void _handleLongPressEnd() {
    if (_isLongPress2x) {
      _playerService.setPlaybackSpeed(_speedBeforeLongPress);
    }
    _rewindTimer?.cancel();
    setState(() {
      _isLongPress2x = false;
      _isLongPressRewind = false;
    });
    _startHideControlsTimer();
  }

  void _onQualityChanged(String quality) {
    if (quality == _currentQuality) return;
    if (widget.streamUrls == null) return;

    final newUrl = widget.streamUrls![quality]?.toString();
    if (newUrl == null || newUrl.isEmpty) return;

    // Save current position to resume after quality switch
    final currentPos = _playerService.position;

    setState(() {
      _currentQuality = quality;
    });

    debugPrint('🎥 Quality changed to $quality: $newUrl');

    // Re-initialize with new URL, resume from same position
    _playerService.initializePlayer(newUrl, startPosition: currentPos);
  }

  Future<void> _saveWatchProgress(String shortCode, Duration position) async {
    // Use cached prefs — this runs every 5 seconds, avoid getInstance() each time
    _prefs ??= await SharedPreferences.getInstance();
    _prefs!.setInt('watch_$shortCode', position.inSeconds);
  }

  /// Check for saved position and show resume dialog if applicable.
  Future<void> _checkAndShowResumeDialog() async {
    _prefs ??= await SharedPreferences.getInstance();
    final savedSeconds = _prefs!.getInt('watch_${widget.shortCode}') ?? 0;

    // Only show if saved position is meaningful (> 10 seconds)
    if (savedSeconds <= 10) return;

    // Wait until player is initialized
    int attempts = 0;
    while (!_playerService.isInitialized && attempts < 30 && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    if (!mounted || !_playerService.isInitialized) return;

    // Pause the player and show dialog
    _playerService.pause();
    _hideControlsTimer?.cancel();

    _showResumeDialog(savedSeconds);
  }

  void _showResumeDialog(int savedSeconds) {
    if (!mounted) return;
    final minutes = savedSeconds ~/ 60;
    final seconds = savedSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: AppColors.primaryLight,
              size: 26,
            ),
            SizedBox(width: 10.w),
            Text(
              'Resume Playback',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: Text(
          'You previously watched until $timeStr. Would you like to resume?',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondaryDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _playerService.seekTo(Duration.zero);
              _playerService.play();
              _startHideControlsTimer();
            },
            child: Text(
              'Start Over',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _playerService.seekTo(Duration(seconds: savedSeconds));
              _playerService.play();
              _startHideControlsTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('Resume ($timeStr)'),
          ),
        ],
      ),
    );
  }

  Future<void> _trackVideoPlay(String shortCode) async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = 'last_tracked_$shortCode';
    final lastTracked = _prefs!.getInt(key);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastTracked != null && now - lastTracked < 24 * 60 * 60 * 1000) return;

    try {
      final url = Uri.parse("https://teraboxurll.in/api/track_video_play.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"action": "play", "short_code": shortCode}),
      );

      if (response.statusCode == 200) {
        _prefs!.setInt(key, now);
      }
    } catch (e) {
      debugPrint("Error tracking video play: $e");
    }
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

  void _showMaintenancePopup() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "Player Maintenance",
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Text(
          "Temporary maintenance in progress. Video playback will resume tomorrow.\nSupport: @linkhelpfastbot",
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  Future<RewardedAd?> _loadDownloadRewardedAd() async {
    if (_isDownloadRewardedLoading) {
      debugPrint(
        '🎬 _loadDownloadRewardedAd: already loading, returning current: ${_downloadRewardedAd != null}',
      );
      return _downloadRewardedAd;
    }

    await PremiumManager.load();
    if (PremiumManager.isPremiumUser || PremiumManager.isRewardedAdsDisabled) {
      debugPrint('🎬 _loadDownloadRewardedAd: premium/disabled, skipping');
      return null;
    }

    if (_downloadRewardedAd != null) {
      debugPrint('🎬 _loadDownloadRewardedAd: already loaded');
      return _downloadRewardedAd;
    }

    _isDownloadRewardedLoading = true;
    final completer = Completer<RewardedAd?>();

    // Use AdManager ID, fallback to hardcoded production ID
    var adUnitId = AdManager.rewardedId;
    if (adUnitId.isEmpty) {
      adUnitId = AdConfig.rewardedAdId;
    }
    debugPrint('🎬 _loadDownloadRewardedAd: loading with adUnitId=$adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _downloadRewardedAd = ad;
          _isDownloadRewardedLoading = false;
          debugPrint('🎬 Rewarded ad LOADED successfully');
          completer.complete(ad);
        },
        onAdFailedToLoad: (err) {
          _downloadRewardedAd = null;
          _isDownloadRewardedLoading = false;
          debugPrint(
            '🎬 Rewarded ad FAILED to load: ${err.message} (code: ${err.code})',
          );
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  Future<bool> _showDownloadRewardedAd(RewardedAd ad) async {
    final completer = Completer<bool>();
    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _downloadRewardedAd = null;
        if (!completer.isCompleted) completer.complete(rewardEarned);
        _loadDownloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _downloadRewardedAd = null;
        if (!completer.isCompleted) completer.complete(false);
        _loadDownloadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return completer.future;
  }

  Future<void> _showAdLoadingDialog() async {
    if (_isAdDialogVisible || !mounted) return;
    _isAdDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Loading ad, please wait...",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isAdDialogVisible = false;
    });
  }

  void _hideAdLoadingDialog() {
    if (!_isAdDialogVisible || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _isAdDialogVisible = false;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    _isWaitingForRewarded = false;

    debugPrint('📥 ═══ _handleDownload START ═══');

    await PremiumManager.load();
    final isPremium = PremiumManager.isPremiumUser;
    debugPrint('📥 isPremium=$isPremium');

    // ── PREMIUM USER: skip ads → direct download ──
    if (isPremium) {
      debugPrint('📥 Premium user → direct download');
      _startDownload();
      return;
    }

    // ── FREE USER: rewarded ad → interstitial fallback → no download ──
    _isWaitingForRewarded = true;

    try {
      bool adWatched = false;

      // STEP 1: Try rewarded ad
      if (_downloadRewardedAd != null) {
        // Pre-loaded → show directly
        debugPrint('📥 FREE: Showing pre-loaded rewarded ad');
        adWatched = await _showDownloadRewardedAd(_downloadRewardedAd!);
        debugPrint('📥 Rewarded ad result: $adWatched');
      } else {
        // Not pre-loaded → load with loading dialog
        debugPrint('📥 FREE: Loading rewarded ad...');
        await _showAdLoadingDialog();

        final rewardedAdId = AdConfig.rewardedAdId;
        final completer = Completer<RewardedAd?>();
        RewardedAd.load(
          adUnitId: rewardedAdId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _downloadRewardedAd = ad;
              _isDownloadRewardedLoading = false;
              if (!completer.isCompleted) completer.complete(ad);
            },
            onAdFailedToLoad: (err) {
              debugPrint('📥 Rewarded ad FAILED: ${err.message}');
              _isDownloadRewardedLoading = false;
              if (!completer.isCompleted) completer.complete(null);
            },
          ),
        );

        RewardedAd? ad;
        try {
          ad = await completer.future.timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          );
        } catch (_) {
          ad = null;
        }

        if (!mounted) return;
        _hideAdLoadingDialog();

        if (ad != null) {
          debugPrint('📥 FREE: Showing loaded rewarded ad');
          adWatched = await _showDownloadRewardedAd(ad);
          debugPrint('📥 Rewarded ad result: $adWatched');
        }
      }

      // STEP 2: If rewarded ad failed/not watched → try interstitial
      if (!adWatched) {
        debugPrint('📥 FREE: Rewarded ad failed, trying interstitial...');

        // Try pre-loaded interstitial first
        final preloadedInter = AdManager.interstitialAd;
        if (preloadedInter != null) {
          debugPrint('📥 FREE: Showing pre-loaded interstitial');
          final interCompleter = Completer<bool>();
          preloadedInter.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              AdManager.interstitialAd = null;
              if (!interCompleter.isCompleted) interCompleter.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('📥 Interstitial failed to show: ${error.message}');
              ad.dispose();
              AdManager.interstitialAd = null;
              if (!interCompleter.isCompleted) interCompleter.complete(false);
            },
          );
          try {
            preloadedInter.show();
            adWatched = await interCompleter.future;
          } catch (e) {
            debugPrint('📥 Interstitial show error: $e');
            adWatched = false;
          }
          debugPrint('📥 Interstitial result: $adWatched');
        } else {
          // Load interstitial on-the-fly
          debugPrint('📥 FREE: Loading interstitial on-the-fly...');
          await _showAdLoadingDialog();

          final interstitialId = AdConfig.interstitialAdId;
          final interLoadCompleter = Completer<InterstitialAd?>();
          InterstitialAd.load(
            adUnitId: interstitialId,
            request: const AdRequest(),
            adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                if (!interLoadCompleter.isCompleted) {
                  interLoadCompleter.complete(ad);
                }
              },
              onAdFailedToLoad: (err) {
                debugPrint('📥 Interstitial FAILED to load: ${err.message}');
                if (!interLoadCompleter.isCompleted) {
                  interLoadCompleter.complete(null);
                }
              },
            ),
          );

          InterstitialAd? interAd;
          try {
            interAd = await interLoadCompleter.future.timeout(
              const Duration(seconds: 4),
              onTimeout: () => null,
            );
          } catch (_) {
            interAd = null;
          }

          if (!mounted) return;
          _hideAdLoadingDialog();

          if (interAd != null) {
            final showCompleter = Completer<bool>();
            interAd.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!showCompleter.isCompleted) showCompleter.complete(true);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!showCompleter.isCompleted) showCompleter.complete(false);
              },
            );
            interAd.show();
            adWatched = await showCompleter.future;
            debugPrint('📥 Interstitial on-the-fly result: $adWatched');
          }
        }
      }

      // STEP 3: Result
      if (!mounted) return;

      if (adWatched) {
        debugPrint('📥 FREE: Ad watched ✅ → starting download');
        _startDownload();
      } else {
        debugPrint('📥 FREE: Both ads failed ❌ → no download');
        _showSnack("Please watch an ad to unlock download.");
      }
    } catch (e) {
      debugPrint('📥 _handleDownload ERROR: $e');
      _hideAdLoadingDialog();
      _showSnack("Something went wrong. Please try again.");
    } finally {
      _hideAdLoadingDialog(); // Always dismiss loading dialog
      _isWaitingForRewarded = false;
      debugPrint('📥 ═══ _handleDownload END ═══');
    }
  }

  Future<void> _startDownload() async {
    try {
      // Request storage permission with popup dialog
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) return;

      // Get download link (already passed from ButtonScreen - NO extra API call)
      // Use downloadLink as primary, streamDownloadUrl as fallback
      final downloadLink = widget.downloadLink?.isNotEmpty == true
          ? widget.downloadLink
          : widget.streamDownloadUrl;

      if (downloadLink == null || downloadLink.isEmpty) {
        if (mounted) {
          _showSnack(
            "Download link not available. Please go back and try again.",
          );
        }
        return;
      }

      debugPrint("📥 Using download link from ButtonScreen (no extra API)");
      await _downloadVideo(downloadLink);
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
        _showSnack("Download failed: $e");
      }
    }
  }

  // Storage permission request (system dialog only)
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+): downloads save to app-specific or public Download
    // directory which does NOT require READ_MEDIA_* permissions.
    // Only older Android versions need storage permission.
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final result = await Permission.storage.request();
    if (result.isGranted) {
      // Brief delay after first-time grant so the OS registers filesystem access
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    // On Android 13+, Permission.storage always returns denied (not applicable).
    // Downloads still work via app-specific directory, so return true.
    if (result.isDenied || result.isRestricted) {
      return true;
    }

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  /// Shows a quality selection bottom sheet. Ad is already shown before this.
  void _showQualityDialog() {
    final options = <Map<String, String>>[];

    // Add quality-specific options from streamUrls (360p, 480p, 720p, etc.)
    if (widget.streamUrls != null && widget.streamUrls!.isNotEmpty) {
      final qualityOrder = ['360p', '480p', '720p', '1080p', '4k', '2160p'];
      for (final q in qualityOrder) {
        final url = widget.streamUrls![q];
        if (url != null && url.toString().isNotEmpty) {
          options.add({'label': q, 'url': url.toString()});
        }
      }
    }

    // Add original quality option (direct download link)
    // Use streamDownloadUrl as fallback if downloadLink is not available
    final directDownloadUrl = widget.downloadLink?.isNotEmpty == true
        ? widget.downloadLink
        : widget.streamDownloadUrl;
    if (directDownloadUrl != null && directDownloadUrl.isNotEmpty) {
      options.add({
        'label': 'Original Quality (${widget.fileSize})',
        'url': directDownloadUrl,
      });
    }

    if (options.isEmpty) {
      _showSnack("No download links available");
      return;
    }

    // If only one option, download directly
    if (options.length == 1) {
      _startDownloadWithUrl(options[0]['url']!, options[0]['label']!);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Select Download Quality",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.h,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              ...options.map(
                (q) => Container(
                  margin: EdgeInsets.only(bottom: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.download_rounded,
                      color: AppColors.primaryLight,
                    ),
                    title: Text(
                      q['label']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white38,
                      size: 16.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startDownloadWithUrl(q['url']!, q['label']!);
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Starts downloading with a specific URL and quality label.
  Future<void> _startDownloadWithUrl(String url, String quality) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) return;

      debugPrint('Download URL: $url');
      debugPrint('Quality: $quality');

      // m3u8 URLs need HLS segment download; others use direct HTTP download
      if (url.contains('.m3u8') || url.contains('m3u8')) {
        await _downloadHlsVideo(url, quality);
      } else {
        await _downloadVideo(url, quality: quality);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = null;
        });
        _showSnack("Download failed: $e");
      }
    }
  }

  /// Downloads video from m3u8 HLS stream by fetching and concatenating segments.
  Future<void> _downloadHlsVideo(String m3u8Url, String quality) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = "Fetching $quality segments...";
    });

    try {
      // 1. Fetch m3u8 manifest
      final manifestResponse = await http
          .get(Uri.parse(m3u8Url))
          .timeout(const Duration(seconds: 15));

      if (manifestResponse.statusCode != 200) {
        throw Exception("Failed to fetch video manifest");
      }

      final manifest = manifestResponse.body;
      final lines = manifest.split('\n');

      // 2. Extract segment URLs from manifest
      final segments = <String>[];
      // Compute base URL for resolving relative segment paths
      final uri = Uri.parse(m3u8Url);
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        if (trimmed.startsWith('http')) {
          segments.add(trimmed);
        } else if (trimmed.startsWith('/')) {
          segments.add('$baseUrl$trimmed');
        } else {
          // Relative to manifest path
          final manifestPath = m3u8Url.substring(
            0,
            m3u8Url.lastIndexOf('/') + 1,
          );
          segments.add('$manifestPath$trimmed');
        }
      }

      if (segments.isEmpty) {
        throw Exception("No video segments found in manifest");
      }

      debugPrint('Found ${segments.length} segments for $quality');

      // 3. Prepare output file
      Directory? downloadDir;
      if (Platform.isAndroid) {
        final publicDir = Directory(
          '/storage/emulated/0/Download/StockScannerVideos',
        );
        try {
          if (!await publicDir.exists()) {
            await publicDir.create(recursive: true);
          }
          final testFile = File('${publicDir.path}/.write_test');
          await testFile.writeAsString('test');
          await testFile.delete();
          downloadDir = Directory('/storage/emulated/0/Download');
        } catch (_) {
          debugPrint(
            '📥 Public Downloads not writable, using app-specific dir',
          );
          downloadDir = await getExternalStorageDirectory();
          downloadDir ??= await getApplicationDocumentsDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) throw Exception("Cannot access storage");

      final videoDir = Directory('${downloadDir.path}/StockScannerVideos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final fileName = widget.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final qualityTag = quality.replaceAll(RegExp(r'[^\w]'), '');
      String filePath =
          '${videoDir.path}/${fileName}_${qualityTag}_${widget.shortCode}.ts';

      File file = File(filePath);

      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // If we cannot delete the file (e.g. scoped storage lock from previous install),
        // generate a new unique filename so we can still download.
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath =
            '${videoDir.path}/${fileName}_${qualityTag}_${widget.shortCode}_$timestamp.ts';
        file = File(filePath);
      }

      // 4. Download segments and write to file
      setState(() => _downloadStatus = "Downloading $quality...");
      final fileSink = file.openWrite();
      int downloaded = 0;

      for (final segUrl in segments) {
        try {
          final segResponse = await http
              .get(Uri.parse(segUrl))
              .timeout(const Duration(seconds: 30));

          if (segResponse.statusCode == 200) {
            fileSink.add(segResponse.bodyBytes);
          }
        } catch (e) {
          debugPrint('Segment download error: $e');
        }

        downloaded++;
        if (mounted) {
          final progress = downloaded / segments.length;
          setState(() {
            _downloadProgress = progress;
            _downloadStatus =
                "Downloading $quality... ${(progress * 100).toStringAsFixed(0)}%";
          });
        }
      }

      await fileSink.flush();
      await fileSink.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = null;
        });
        _showSnack("Download Complete ($quality)");
      }
    } catch (e) {
      debugPrint('HLS download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = null;
        });
        _showSnack("Download failed: $e");
      }
    }
  }

  Future<void> _downloadVideo(
    String downloadUrl, {
    String quality = 'Original',
  }) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = "Preparing download...";
    });

    HttpClient? ioClient;

    try {
      Directory? downloadDir;
      if (Platform.isAndroid) {
        final publicDir = Directory(
          '/storage/emulated/0/Download/StockScannerVideos',
        );
        try {
          if (!await publicDir.exists()) {
            await publicDir.create(recursive: true);
          }
          final testFile = File('${publicDir.path}/.write_test');
          await testFile.writeAsString('test');
          await testFile.delete();
          downloadDir = Directory('/storage/emulated/0/Download');
        } catch (_) {
          debugPrint(
            '📥 Public Downloads not writable, using app-specific dir',
          );
          downloadDir = await getExternalStorageDirectory();
          downloadDir ??= await getApplicationDocumentsDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        throw Exception("Could not access download directory");
      }

      final videoDir = Directory('${downloadDir.path}/StockScannerVideos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final fileName = widget.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      const fileExtension = '.mp4';
      String filePath =
          '${videoDir.path}/${fileName}_${widget.shortCode}$fileExtension';

      File file = File(filePath);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath =
            '${videoDir.path}/${fileName}_${widget.shortCode}_$timestamp$fileExtension';
        file = File(filePath);
      }

      setState(() {
        _downloadStatus = "Connecting...";
      });

      debugPrint('📥 Starting download from $downloadUrl');

      // Use dart:io HttpClient with proper timeouts
      ioClient = HttpClient();
      ioClient.connectionTimeout = const Duration(seconds: 15);
      ioClient.idleTimeout = const Duration(seconds: 30);

      final uri = Uri.parse(downloadUrl);
      final request = await ioClient.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
      );
      request.headers.set('Referer', 'https://teraboxurll.in/');
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await request.close().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server did not respond within 30 seconds');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Content-Length: ${response.contentLength}');

      if (response.statusCode != 200) {
        ioClient.close();
        throw Exception("Download failed with status: ${response.statusCode}");
      }

      final contentLength = response.contentLength;
      final fileSink = file.openWrite();
      int downloadedBytes = 0;

      setState(() {
        _downloadStatus = "Downloading...";
      });

      await for (final chunk in response) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;

        if (!mounted) break;

        double progress;
        if (contentLength > 0) {
          progress = downloadedBytes / contentLength;
          final progressPercent = (progress * 100).toStringAsFixed(1);
          _downloadStatus = progress >= 1.0
              ? "Download Completed"
              : "Downloading $progressPercent%";
        } else {
          _downloadStatus =
              "Downloading... ${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB";
          progress = -1.0;
        }
        setState(() {
          _downloadProgress = progress;
        });
      }

      await fileSink.close();
      ioClient.close();
      ioClient = null;

      debugPrint('📥 Download complete! $downloadedBytes bytes');

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = null;
        });
        _showSnack("Video saved to your device");
      }
    } catch (e) {
      ioClient?.close();
      debugPrint('📥 Download error: $e');

      if (mounted) {
        // Fallback to normalDownloadLink if primary link failed
        if (downloadUrl == widget.downloadLink &&
            widget.normalDownloadLink != null &&
            widget.normalDownloadLink!.isNotEmpty) {
          debugPrint('📥 Retrying with normal download link...');
          setState(() {
            _downloadStatus = "Retrying with alternate link...";
          });
          await _downloadVideo(widget.normalDownloadLink!, quality: quality);
          return;
        }

        // Fallback to streamDownloadUrl
        if (downloadUrl == widget.normalDownloadLink &&
            widget.streamDownloadUrl != null &&
            widget.streamDownloadUrl!.isNotEmpty &&
            widget.streamDownloadUrl != downloadUrl) {
          debugPrint('📥 Retrying with stream download link...');
          setState(() {
            _downloadStatus = "Retrying with stream link...";
          });
          await _downloadVideo(widget.streamDownloadUrl!, quality: quality);
          return;
        }

        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = null;
        });
        _showSnack(
          "Download failed: ${e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e}",
        );
      }
    }
  }

  /// Fetches the HLS subtitle manifest and parses individual subtitle tracks.
  Future<void> _loadSubtitlesFromManifest(String manifestUrl) async {
    try {
      debugPrint('🎬 Loading subtitle from: $manifestUrl');
      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 15));

      debugPrint('🎬 Subtitle response status: ${response.statusCode}');
      debugPrint('🎬 Subtitle response length: ${response.body.length}');

      if (response.statusCode != 200) {
        debugPrint('🎬 Subtitle manifest fetch failed: ${response.statusCode}');
        return;
      }

      final body = response.body;
      final lines = body.split('\n');
      final List<Map<String, String>> parsed = []; // {name, url, language}

      // Check if this is an HLS manifest or direct subtitle file
      final isHlsManifest = body.contains('#EXT-X-MEDIA:TYPE=SUBTITLES');

      if (!isHlsManifest) {
        // Direct subtitle file (SRT/VTT) - add as single option
        debugPrint('🎬 Direct subtitle file detected');
        parsed.add({
          'name': 'Subtitles',
          'url': manifestUrl,
          'language': 'unknown',
        });
      } else {
        // HLS manifest - parse subtitle tracks
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          if (line.startsWith('#EXT-X-MEDIA:TYPE=SUBTITLES')) {
            // Parse NAME
            String name = 'Subtitle';
            final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
            if (nameMatch != null) {
              name = nameMatch.group(1) ?? 'Subtitle';
            }

            // Parse LANGUAGE
            String language = '';
            final langMatch = RegExp(r'LANGUAGE="([^"]+)"').firstMatch(line);
            if (langMatch != null) {
              language = langMatch.group(1) ?? '';
            }

            // Next non-empty, non-comment line is the subtitle URL
            String? subtitleFileUrl;
            for (int j = i + 1; j < lines.length; j++) {
              final nextLine = lines[j].trim();
              if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
                subtitleFileUrl = nextLine;
                break;
              }
            }

            if (subtitleFileUrl != null && subtitleFileUrl.isNotEmpty) {
              // Skip non-AI entries (MoviezVerse.org, English SDH) — they don't work
              if (name == 'MoviezVerse.org' || name == 'English SDH') {
                continue;
              }

              // Convert short language code to full name
              const langNames = {
                'ar': 'Arabic',
                'en': 'English',
                'eng': 'English',
                'hi': 'Hindi',
                'id': 'Indonesian',
                'ko': 'Korean',
                'origin': 'Original',
                'es': 'Spanish',
                'fr': 'French',
                'de': 'German',
                'pt': 'Portuguese',
                'ru': 'Russian',
                'ja': 'Japanese',
                'zh': 'Chinese',
                'tr': 'Turkish',
                'th': 'Thai',
                'vi': 'Vietnamese',
                'ms': 'Malay',
                'bn': 'Bengali',
                'ta': 'Tamil',
                'te': 'Telugu',
                'mr': 'Marathi',
                'gu': 'Gujarati',
                'kn': 'Kannada',
                'ml': 'Malayalam',
                'pa': 'Punjabi',
                'ur': 'Urdu',
                'it': 'Italian',
                'nl': 'Dutch',
                'pl': 'Polish',
                'sv': 'Swedish',
                'da': 'Danish',
                'no': 'Norwegian',
                'fi': 'Finnish',
                'el': 'Greek',
                'he': 'Hebrew',
                'ro': 'Romanian',
                'hu': 'Hungarian',
                'cs': 'Czech',
                'uk': 'Ukrainian',
                'fil': 'Filipino',
                'sw': 'Swahili',
              };
              String displayName =
                  langNames[language] ??
                  (language.isNotEmpty ? language : name);

              parsed.add({
                'name': displayName,
                'url': subtitleFileUrl,
                'language': language,
              });
              debugPrint('🎬 Parsed subtitle: $displayName');
            }
          }
        } // End of else block for HLS manifest parsing
      }

      if (parsed.isNotEmpty && mounted) {
        setState(() {
          _subtitleSources = parsed;
          _subtitleUrls = parsed.map((p) => p['url']!).toList();
        });

        // Don't auto-load any subtitle — user will select manually
        debugPrint(
          '🎬 Parsed ${parsed.length} subtitle tracks, ready for selection',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🎬 Subtitle manifest error: $e');
      debugPrint('🎬 Subtitle error stack: $stackTrace');
    }
  }

  /// Activates a subtitle by index, or disables subtitles if index is -1.
  /// Shows a loading dialog, fetches SRT content, sanitizes it, and stores parsed cues.
  List<Map<String, dynamic>> _parsedSubtitleCues = [];

  Future<void> _selectSubtitle(int index) async {
    if (index < 0 || index >= _subtitleSources.length) {
      // Disable subtitles
      setState(() {
        _currentSubtitleIndex = -1;
        _currentSubtitleText = null;
        _parsedSubtitleCues = [];
      });
      debugPrint('🎬 Subtitles disabled');
      return;
    }

    // Show loading overlay using OverlayEntry
    OverlayEntry? loadingOverlay;
    if (mounted) {
      loadingOverlay = OverlayEntry(
        builder: (_) => Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32.h,
                    height: 32.h,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Material(
                    color: Colors.transparent,
                    child: Text(
                      'Loading subtitle...',
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 14.h,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(loadingOverlay);
    }

    try {
      // Wait for the player to be initialized
      for (int i = 0; i < 20; i++) {
        if (_playerService.isInitialized) break;
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) {
          loadingOverlay?.remove();
          return;
        }
      }

      final url = _subtitleUrls[index];
      debugPrint(
        '🎬 Fetching subtitle: ${_subtitleSources[index]['name']} from $url',
      );

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('🎬 Subtitle fetch failed: ${response.statusCode}');
        loadingOverlay?.remove();
        return;
      }

      final rawContent = response.body;
      debugPrint('🎬 Raw SRT size: ${rawContent.length} chars');

      // Sanitize the SRT content
      final srtContent = _sanitizeSrt(rawContent);

      if (srtContent.isEmpty) {
        debugPrint('🎬 No valid subtitle cues found after sanitization');
        loadingOverlay?.remove();
        return;
      }

      debugPrint('🎬 Sanitized SRT size: ${srtContent.length} chars');

      // Parse SRT into cues for our custom overlay
      _parsedSubtitleCues = _parseSrtCues(srtContent);

      if (mounted) {
        setState(() => _currentSubtitleIndex = index);
        debugPrint('🎬 Subtitle activated: ${_subtitleSources[index]['name']}');
      }
    } catch (e) {
      debugPrint('🎬 Subtitle fetch error: $e');
    } finally {
      loadingOverlay?.remove();
    }
  }

  /// Parse SRT content into a list of cues with start/end times and text.
  List<Map<String, dynamic>> _parseSrtCues(String srt) {
    final cues = <Map<String, dynamic>>[];
    final blocks = srt.split('\n\n');
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;
      int tsLine = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(' --> ')) {
          tsLine = i;
          break;
        }
      }
      if (tsLine == -1) continue;
      final parts = lines[tsLine].split(' --> ');
      if (parts.length != 2) continue;
      final start = _parseSrtTime(parts[0].trim());
      final end = _parseSrtTime(parts[1].trim());
      if (start == null || end == null) continue;
      final text = lines.sublist(tsLine + 1).join('\n').trim();
      if (text.isNotEmpty) {
        cues.add({'start': start, 'end': end, 'text': text});
      }
    }
    return cues;
  }

  Duration? _parseSrtTime(String time) {
    // Format: 00:01:23,456 or 00:01:23.456
    time = time.replaceAll(',', '.');
    final parts = time.split(':');
    if (parts.length != 3) return null;
    try {
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final sParts = parts[2].split('.');
      final s = int.parse(sParts[0]);
      final ms = sParts.length > 1
          ? int.parse(sParts[1].padRight(3, '0').substring(0, 3))
          : 0;
      return Duration(hours: h, minutes: m, seconds: s, milliseconds: ms);
    } catch (_) {
      return null;
    }
  }

  /// Get current subtitle text based on position.
  String? _getCurrentSubtitleText() {
    if (_currentSubtitleIndex < 0 || _parsedSubtitleCues.isEmpty) return null;
    final pos = _playerService.position;
    for (final cue in _parsedSubtitleCues) {
      final start = cue['start'] as Duration;
      final end = cue['end'] as Duration;
      if (pos >= start && pos <= end) {
        return cue['text'] as String;
      }
    }
    return null;
  }

  /// Sanitizes SRT content to ensure BetterPlayer can parse it without crashing.
  /// BetterPlayer splits by \n\n, then expects each block to be:
  ///   [index]\n[timestamp --> timestamp]\n[text lines...]
  /// This method validates each block and rebuilds only valid ones.
  String _sanitizeSrt(String raw) {
    // Normalize line endings
    raw = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Remove BOM if present
    if (raw.startsWith('\uFEFF')) {
      raw = raw.substring(1);
    }

    // Split into blocks by double newline
    final blocks = raw.split('\n\n');
    final List<String> validBlocks = [];
    int cueIndex = 1;

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split('\n');
      if (lines.isEmpty) continue;

      // Find the line with ' --> ' (timestamp line)
      int timestampLineIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(' --> ')) {
          timestampLineIndex = i;
          break;
        }
      }

      if (timestampLineIndex == -1) {
        // No timestamp found — skip this block (e.g., WEBVTT header, NOTE, etc.)
        continue;
      }

      // Validate timestamp line has two parts
      final timeParts = lines[timestampLineIndex].split(' --> ');
      if (timeParts.length != 2) continue;

      // Collect text lines (everything after the timestamp)
      final textLines = lines.sublist(timestampLineIndex + 1);
      if (textLines.isEmpty) continue;

      // Remove any HTML tags from text (some SRTs have <font>, <b>, etc.)
      final cleanedText = textLines
          .map((l) => l.replaceAll(RegExp(r'<[^>]+>'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (cleanedText.isEmpty) continue;

      // Rebuild a clean SRT block: index\ntimestamp\ntext
      final cleanBlock =
          '$cueIndex\n${lines[timestampLineIndex].trim()}\n${cleanedText.join('\n')}';
      validBlocks.add(cleanBlock);
      cueIndex++;
    }

    if (validBlocks.isEmpty) return '';

    return '${validBlocks.join('\n\n')}\n\n';
  }

  /// Shows a bottom sheet to pick subtitle language.
  void _showSubtitlePicker() {
    if (_subtitleSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subtitles available for this video')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              SizedBox(height: 5.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // "None" option
                    ListTile(
                      leading: Icon(
                        _currentSubtitleIndex == -1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _currentSubtitleIndex == -1
                            ? AppColors.primaryLight
                            : Colors.white54,
                        size: 22.h,
                      ),
                      title: Text(
                        'None (Off)',
                        style: TextStyle(
                          color: _currentSubtitleIndex == -1
                              ? AppColors.primaryLight
                              : AppColors.textPrimaryDark,
                          fontSize: 15.h,
                          fontWeight: _currentSubtitleIndex == -1
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectSubtitle(-1);
                      },
                    ),
                    // Subtitle tracks
                    ...List.generate(_subtitleSources.length, (index) {
                      final source = _subtitleSources[index];
                      final isSelected = index == _currentSubtitleIndex;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.white54,
                          size: 22.h,
                        ),
                        title: Text(
                          source['name'] ?? 'Subtitle ${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.textPrimaryDark,
                            fontSize: 15.h,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _selectSubtitle(index);
                        },
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Save watch position before disposing
    _saveWatchProgress(widget.shortCode, _playerService.position);
    _playerService.removeListener(_onPlayerStateChanged);
    _playerService.disposeService();
    _hideControlsTimer?.cancel();
    _skipHintTimer?.cancel();
    _rewindTimer?.cancel();
    adRefreshTimer?.cancel();
    _downloadRewardedAd?.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Widget _buildVideoPlayerWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Video player
            if (_playerService.isInitialized &&
                _playerService.controller != null)
              SafeArea(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: _getVideoFit(),
                    child: SizedBox(
                      width: _playerService.controller!.value.size.width,
                      height: _playerService.controller!.value.size.height,
                      child: VideoPlayer(_playerService.controller!),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                ),
              ),

            // Gesture detector for tap/double-tap/swipe
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
                onDoubleTapDown: (details) =>
                    _handleDoubleTap(details, constraints),
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDrag(details, constraints),
                onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
                onLongPressStart: (details) =>
                    _handleLongPressStart(details, constraints),
                onLongPressEnd: (_) => _handleLongPressEnd(),
                child: const SizedBox.expand(),
              ),
            ),

            // Skip hint overlay
            if (_showSkipHint)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSkipForward ? Icons.forward_10 : Icons.replay_10,
                        color: Colors.white,
                        size: 35.h,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${_skipHintSeconds.abs()} seconds',
                        style: TextStyle(color: Colors.white, fontSize: 18.h),
                      ),
                    ],
                  ),
                ),
              ),

            // Volume indicator
            if (_showVolumeIndicator)
              Positioned(
                right: 16.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${_playerService.volume.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Brightness indicator
            if (_showBrightnessIndicator)
              Positioned(
                left: 16.w,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.brightness_6,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${(_playerService.brightness * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2X speed / Rewind indicator
            if (_isLongPress2x || _isLongPressRewind)
              Positioned(
                top: 16.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLongPress2x
                              ? Icons.fast_forward_rounded
                              : Icons.fast_rewind_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _isLongPress2x ? '2X Speed' : 'Rewinding',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Buffering indicator
            if (_playerService.isBuffering)
              Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),

            // Custom controls overlay
            if (_playerService.isInitialized)
              Positioned.fill(
                child: CustomControls(
                  showControls: _showControls,
                  playerService: _playerService,
                  title: widget.title,
                  subtitleSources: _subtitleSources,
                  currentSubtitleIndex: _currentSubtitleIndex,
                  subtitleText: _getCurrentSubtitleText(),
                  onSubtitleSelected: (index) => _selectSubtitle(index),
                  streamUrls: widget.streamUrls,
                  currentQuality: _currentQuality,
                  onQualityChanged: _onQualityChanged,
                  onToggleFullScreen: () async {
                    _playerService.toggleFullScreen();
                    if (_playerService.isFullScreen) {
                      // Check video aspect ratio - only rotate to landscape if video is horizontal
                      final videoSize = _playerService.controller?.value.size;
                      final isVideoVertical =
                          videoSize != null &&
                          videoSize.height > videoSize.width;

                      if (isVideoVertical) {
                        // Vertical video - stay in portrait fullscreen
                        await SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                        ]);
                      } else {
                        // Horizontal video - rotate to landscape
                        await SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      }
                      await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky,
                      );
                    } else {
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                    }
                  },
                  onToggleControls: _toggleControls,
                ),
              ),

            // Error overlay
            if (_playerService.hasError)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  margin: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48.w),
                      SizedBox(height: 12.h),
                      Text(
                        _playerService.errorMessage ?? 'Failed to load video',
                        style: TextStyle(color: Colors.white, fontSize: 14.h),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                        ),
                        onPressed: () async {
                          _errorCount = 0;
                          _hasStoppedDueToErrors = false;
                          // Reset player before retry to clear any bad state
                          await _playerService.resetForRetry();
                          _playerService.initializePlayer(widget.videoUrl);
                        },
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  BoxFit _getVideoFit() {
    if (!_playerService.isFullScreen) {
      return BoxFit.contain;
    }

    // Check video aspect ratio in fullscreen
    final videoSize = _playerService.controller?.value.size;
    if (videoSize != null && videoSize.height > videoSize.width) {
      // Vertical video - use contain to show full video without cropping
      return BoxFit.contain;
    } else {
      // Horizontal video - use cover to fill screen
      return BoxFit.cover;
    }
  }

  Widget buildButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18.w),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12.h),
            ),
          ],
        ),
      ),
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024)
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  String _formatFileSizeDisplay(String fileSize) {
    if (fileSize.contains('MB') ||
        fileSize.contains('KB') ||
        fileSize.contains('GB') ||
        fileSize.contains('B')) {
      return fileSize;
    }
    try {
      final bytes = int.parse(fileSize);
      return formatFileSize(bytes);
    } catch (e) {
      return fileSize.isNotEmpty ? fileSize : "0 B";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fullscreen mode — only show video player, no AppBar, no details
    if (_playerService.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideoPlayerWidget(),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundDark,

          body: Column(
            children: [
              // Video player - 30% of screen height for smaller footprint
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: _buildVideoPlayerWidget(),
              ),
              // Scrollable details
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video title
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.h,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        // Video details (smaller)
                        Text(
                          "${widget.fileSize == "0" ? "" : _formatFileSizeDisplay(widget.fileSize)}  ${widget.fileSize == "0" ? widget.createdAt : " • ${widget.createdAt}"}",
                          style: TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 11.h,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        // User info + Premium badge
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundImage: const AssetImage(
                                AppAssets.appLogo,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                widget.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.h,
                                ),
                              ),
                            ),
                            buildButton(
                              icon: Icons.diamond_rounded,
                              label: "Premium",
                              onTap: () {
                                try {
                                  if (Get.isRegistered<AuthService>()) {
                                    AuthService.to
                                        .openPurchaseScreenIfAllowed();
                                  } else {
                                    Get.toNamed(AppRoutes.purchase);
                                  }
                                } catch (_) {
                                  Get.toNamed(AppRoutes.purchase);
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: _isDownloading
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        LinearProgressIndicator(
                                          value: _downloadProgress,
                                          backgroundColor: AppColors.borderDark,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryLight,
                                              ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _downloadStatus ?? "Downloading...",
                                          style: TextStyle(
                                            color: AppColors.textSecondaryDark,
                                            fontSize: 12.h,
                                          ),
                                        ),
                                      ],
                                    )
                                  : buildButton(
                                      icon: Icons.download_rounded,
                                      label: "Download",
                                      onTap: _handleDownload,
                                    ),
                            ),

                            buildButton(
                              icon: Icons.share_rounded,
                              label: "Share",
                              onTap: () {
                                final deepLink = widget.shortCode.isNotEmpty
                                    ? 'https://teraboxurll.in/${widget.shortCode}'
                                    : '';
                                SharePlus.instance.share(
                                  ShareParams(
                                    text: '${widget.title}\n$deepLink',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Native Ad above recommended videos
                        if (!PremiumManager.isPremiumUser)
                          const NativeAdWidget(),
                        SizedBox(height: 12.h),
                        Text(
                          "Recommended Videos",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.h,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        FutureBuilder<List<Video>>(
                          future: _recommendedVideosFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryLight,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error loading videos',
                                style: TextStyle(
                                  color: AppColors.textSecondaryDark,
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text(
                                'No recommended videos',
                                style: TextStyle(
                                  color: AppColors.textSecondaryDark,
                                ),
                              );
                            }

                            final videos = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                final video = videos[index];
                                return GestureDetector(
                                  onTap: () {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          Future.delayed(
                                            const Duration(milliseconds: 150),
                                            () {
                                              Get.offNamed(
                                                AppRoutes.teraboxButton,
                                                arguments: video.shortCode,
                                              );
                                            },
                                          );
                                        });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 6.h),
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 100.w,
                                          height: 60.h,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceDark,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: video.thumbnailUrl != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                  child: Image.network(
                                                    video.thumbnailUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                          Icons
                                                              .video_library_rounded,
                                                          color: AppColors
                                                              .textSecondaryDark,
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.video_library_rounded,
                                                  color: AppColors
                                                      .textSecondaryDark,
                                                  size: 30.w,
                                                ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                video.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.h,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                '${video.views} views',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondaryDark,
                                                  fontSize: 12.h,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Ad loading overlay
        if (_showingAdLoader)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 20.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          "Loading ad, please wait...",
                          style: TextStyle(
                            fontSize: 14.h,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<List<Video>> fetchVideos() async {
  try {
    const url =
        'https://teraboxurll.in/api/recommended.php?EczOX0jbqbizIZi7a3RpJtPo&limit=5';
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.isEmpty) return [];

      final dynamic decoded = json.decode(body);
      if (decoded is! Map) return [];

      final dynamic videosJson = decoded['data']?['videos'];
      if (videosJson is! List) return [];

      return videosJson
          .whereType<Map<String, dynamic>>()
          .map((v) => Video.fromJson(v))
          .toList();
    } else {
      return [];
    }
  } catch (e) {
    debugPrint('fetchVideos error: $e');
    return [];
  }
}

class Video {
  final int id;
  final String shortCode;
  final String title;
  final String? thumbnailUrl;
  final int views;
  final String watchUrl;

  Video({
    required this.id,
    required this.shortCode,
    required this.title,
    this.thumbnailUrl,
    required this.views,
    required this.watchUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shortCode: json['short_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      watchUrl: json['watch_url']?.toString() ?? '',
    );
  }
}
