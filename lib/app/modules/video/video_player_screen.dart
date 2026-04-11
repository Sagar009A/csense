/// Video Player Screen
/// Unified player using video_player for mp4/m3u8 and youtube_player_flutter for YouTube
library;

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'terabox/widgets/video_player_service.dart';
import 'terabox/widgets/custom_controls.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/constants/ad_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/credit_service.dart';
import 'video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoModel? video;

  // For mp4/m3u8 (video_player)
  VideoPlayerService? _videoPlayerService;

  // For YouTube
  YoutubePlayerController? _youtubeController;

  bool _isLoading = true;
  String? _errorMessage;
  bool _youtubeFullscreen = false;
  bool _youtubeMuted = false;
  bool _showControls = true;

  // Native ad below YouTube player
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    video = Get.arguments as VideoModel?;
    if (video == null) {
      setState(() {
        _errorMessage = 'Invalid video data';
        _isLoading = false;
      });
      return;
    }
    _checkPremiumAndLoadAd();
    _initializePlayer();
  }

  void _checkPremiumAndLoadAd() {
    try {
      _isPremium = Get.find<CreditService>().isSubscribed.value;
    } catch (_) {
      _isPremium = false;
    }
    if (!_isPremium && video?.videoType == VideoType.youtube) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    final adUnitId = AdConfig.nativeAdId;
    if (adUnitId.isEmpty) return;

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: AdConfig.nativeAdFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isNativeAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('VideoPlayer native ad failed: $error');
        },
      ),
    )..load();
  }

  Future<void> _initializePlayer() async {
    if (video == null) return;
    try {
      if (video!.videoType == VideoType.youtube) {
        _initYouTubePlayer();
      } else {
        _initVideoPlayer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _initYouTubePlayer() {
    final videoId = video?.youtubeVideoId;
    if (videoId == null) {
      setState(() {
        _errorMessage = 'Invalid YouTube URL';
        _isLoading = false;
      });
      return;
    }

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
        loop: true,
        hideControls: true,
        controlsVisibleAtStart: false,
        showLiveFullscreenButton: false,
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _initVideoPlayer() {
    _videoPlayerService = VideoPlayerService();
    _videoPlayerService!.addListener(() {
      if (!mounted) return;
      if (_videoPlayerService!.isInitialized && _isLoading) {
        setState(() => _isLoading = false);
      }
      if (_videoPlayerService!.hasError) {
        setState(() {
          _errorMessage =
              _videoPlayerService!.errorMessage ?? 'Failed to play video';
          _isLoading = false;
        });
      }
      setState(() {});
    });
    _videoPlayerService!.initializePlayer(video!.videoUrl);
  }

  @override
  void dispose() {
    _videoPlayerService?.disposeService();
    _youtubeController?.dispose();
    _nativeAd?.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPlayerService != null && _videoPlayerService!.isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildVideoPlayerOnly(),
        ),
      );
    }

    // YouTube fullscreen
    if (_youtubeFullscreen && video?.videoType == VideoType.youtube) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: _buildYouTubePlayerWithControls(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            if (_videoPlayerService != null && _videoPlayerService!.isFullScreen) {
               _videoPlayerService!.toggleFullScreen();
               setState((){});
               return;
            }
            if (_youtubeFullscreen) {
               setState(() => _youtubeFullscreen = false);
               return;
            }
            Get.back();
          },
        ),
        title: Text(
          video?.title ?? 'Video',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            SizedBox(height: 16.h),
            Text(
              'loading_video'.tr,
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Video Player — 30% of screen height for smaller footprint
        video?.videoType == VideoType.youtube
            ? _buildYouTubePlayerWithControls()
            : SizedBox(
                height: MediaQuery.of(context).size.height * 0.30,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      _videoPlayerService != null &&
                          _videoPlayerService!.isInitialized &&
                          _videoPlayerService!.controller != null
                      ? _buildVideoPlayerOnly()
                      : Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                ),
              ),
        // Video Info below player + native ad for YouTube
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video?.title ?? 'Untitled',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    video?.subTitle ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12.sp,
                    ),
                  ),
                  // Native ad below YouTube video
                  if (video?.videoType == VideoType.youtube &&
                      !_isPremium &&
                      _isNativeAdLoaded &&
                      _nativeAd != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      height: 280.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: AppColors.surfaceDark,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AdWidget(ad: _nativeAd!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxFit _getVideoFit() {
    if (_videoPlayerService == null || !_videoPlayerService!.isFullScreen) {
      return BoxFit.contain;
    }
    final videoSize = _videoPlayerService!.controller?.value.size;
    if (videoSize != null && videoSize.height > videoSize.width) {
      return BoxFit.contain;
    }
    return BoxFit.cover;
  }

  Widget _buildVideoPlayerOnly() {
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: _getVideoFit(),
            child: SizedBox(
              width: _videoPlayerService!.controller!.value.size.width,
              height: _videoPlayerService!.controller!.value.size.height,
              child: VideoPlayer(_videoPlayerService!.controller!),
            ),
          ),
        ),
        if (_videoPlayerService!.isBuffering)
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _showControls = !_showControls),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          child: CustomControls(
            showControls: _showControls,
            playerService: _videoPlayerService!,
            title: video?.title,
            subtitleText: video?.subTitle,
            onToggleControls: () => setState(() => _showControls = !_showControls),
            onToggleFullScreen: () async {
              _videoPlayerService!.toggleFullScreen();
              setState(() {});
              if (_videoPlayerService!.isFullScreen) {
                final videoSize = _videoPlayerService!.controller?.value.size;
                final isVideoVertical = videoSize != null && videoSize.height > videoSize.width;
                if (isVideoVertical) {
                  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                } else {
                  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                }
                await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              } else {
                await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
                await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePlayerWithControls() {
    if (_youtubeController == null) {
      return _buildErrorWidget();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
            bottomActions: const [],
            topActions: const [],
            onReady: () {},
          ),
        ),
        // Visible control bar below player
        Container(
          color: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<YoutubePlayerValue>(
                valueListenable: _youtubeController!,
                builder: (context, value, _) {
                  final position = value.position.inSeconds.clamp(
                    0,
                    value.metaData.duration.inSeconds,
                  );
                  final duration = value.metaData.duration.inSeconds;
                  return Row(
                    children: [
                      SizedBox(
                        width: 36.w,
                        child: Text(
                          _formatDuration(value.position),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primaryLight,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.primaryLight,
                            overlayColor: AppColors.primaryLight.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: duration > 0 ? position.toDouble() : 0,
                            max: duration > 0 ? duration.toDouble() : 100,
                            onChanged: (v) {
                              _youtubeController!.seekTo(
                                Duration(seconds: v.round()),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36.w,
                        child: Text(
                          _formatDuration(value.metaData.duration),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final pos = _youtubeController!.value.position;
                      _youtubeController!.seekTo(
                        Duration(
                          seconds: (pos.inSeconds - 10).clamp(0, 999999),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<YoutubePlayerValue>(
                    valueListenable: _youtubeController!,
                    builder: (context, value, _) {
                      return IconButton(
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: AppColors.primaryLight,
                          size: 44.w,
                        ),
                        onPressed: () {
                          if (value.isPlaying) {
                            _youtubeController!.pause();
                          } else {
                            _youtubeController!.play();
                          }
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final pos = _youtubeController!.value.position;
                      final dur = _youtubeController!.value.metaData.duration;
                      _youtubeController!.seekTo(
                        Duration(
                          seconds: (pos.inSeconds + 10).clamp(0, dur.inSeconds),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _youtubeMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _youtubeMuted = !_youtubeMuted);
                      _youtubeController!.setVolume(_youtubeMuted ? 0 : 100);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _youtubeFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _youtubeFullscreen = !_youtubeFullscreen);
                      if (_youtubeFullscreen) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorLight,
              size: 64.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'video_error'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
