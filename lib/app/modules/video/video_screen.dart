library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_sizebox.dart';
import '../../common/widgets/native_ad_widget.dart';
import 'video_controller.dart';
import 'video_model.dart';
import 'offline_videos_screen.dart';

class VideoScreen extends StatefulWidget {
  final bool isDark;

  const VideoScreen({super.key, required this.isDark});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VideoController controller = Get.find<VideoController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Tabs
            Padding(
              padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CommonText.headline('videos'),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: widget.isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    onPressed: controller.refreshVideos,
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.cardDark
                    : AppColors.shimmerBaseLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(4.r),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: widget.isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_outlined, size: 18.w),
                        SizedBox(width: 6.w),
                        Text('online'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 18.w),
                        SizedBox(width: 6.w),
                        Text('offline'.tr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Online Videos Tab
                  _OnlineVideosTab(
                    controller: controller,
                    isDark: widget.isDark,
                  ),
                  // Offline Videos Tab
                  OfflineVideosScreen(isDark: widget.isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Online Videos Tab
class _OnlineVideosTab extends StatelessWidget {
  final VideoController controller;
  final bool isDark;

  const _OnlineVideosTab({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.videos.isEmpty) {
        return _buildShimmerLoading();
      }

      if (controller.hasError.value && controller.videos.isEmpty) {
        return _buildErrorState();
      }

      if (controller.videos.isEmpty) {
        return _buildEmptyState();
      }

      // Calculate total items including ads (native ad after every 4 videos)
      final totalItems = controller.videos.length + (controller.videos.length ~/ 4);
      
      return RefreshIndicator(
        onRefresh: controller.refreshVideos,
        color: AppColors.primaryLight,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Show native ad after every 4 videos (at positions 4, 9, 14, etc.)
            // Position calculation: after 4 videos = at index 4, then after 4 more = at index 9
            final videosBeforeThisPosition = index - (index ~/ 5);
            final isAdPosition = index > 0 && (index % 5 == 0);
            
            if (isAdPosition) {
              // Show native ad
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const NativeAdWidget(),
              );
            }
            
            // Calculate actual video index (subtract number of ads before this position)
            final videoIndex = videosBeforeThisPosition;
            if (videoIndex >= controller.videos.length) {
              return const SizedBox.shrink();
            }
            
            final video = controller.videos[videoIndex];
            return _VideoCard(
              video: video,
              isDark: isDark,
              onTap: () => controller.openVideoPlayer(video),
            );
          },
        ),
      );
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _ShimmerVideoCard(isDark: isDark);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.errorLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40.w,
                color: AppColors.errorLight,
              ),
            ),
            CommonSizedBox.h24,
            CommonText.subtitle(
              'video_error',
              textAlign: TextAlign.center,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            CommonSizedBox.h16,
            GestureDetector(
              onTap: controller.refreshVideos,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: CommonText.body(
                  'retry',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_rounded,
              size: 48.w,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          CommonSizedBox.h24,
          CommonText.subtitle(
            'no_videos',
            textAlign: TextAlign.center,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}

// Shimmer Video Card for loading state
class _ShimmerVideoCard extends StatelessWidget {
  final bool isDark;

  const _ShimmerVideoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark
            ? AppColors.shimmerBaseDark
            : AppColors.shimmerBaseLight,
        highlightColor: isDark
            ? AppColors.shimmerHighlightDark
            : AppColors.shimmerHighlightLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Container(
              height: 180.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 18.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Subtitle placeholder
                  Container(
                    height: 14.h,
                    width: 200.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Badge placeholder
                  Container(
                    height: 24.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final VideoModel video;
  final bool isDark;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  Uint8List? _thumbnailData;
  bool _isLoadingThumbnail = true;
  String? _randomStockThumbnail;

  // Stock market chart images for m3u8 streams (from Unsplash - free to use)
  static const List<String> _stockThumbnails = [
    'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=480&q=80',
    // Trading chart
    'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?w=480&q=80',
    // Stock market
    'https://images.unsplash.com/photo-1642790106117-e829e14a795f?w=480&q=80',
    // Crypto chart
    'https://images.unsplash.com/photo-1535320903710-d993d3d77d29?w=480&q=80',
    // Trading screen
    'https://images.unsplash.com/photo-1518186285589-2f7649de83e0?w=480&q=80',
    // Data analysis
    'https://images.unsplash.com/photo-1560221328-12fe60f83ab8?w=480&q=80',
    // Stock graph
    'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=480&q=80',
    // Dashboard
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=480&q=80',
    // Analytics
    'https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=480&q=80',
    // Charts
    'https://images.unsplash.com/photo-1543286386-713bdd548da4?w=480&q=80',
    // Trading
    'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=480&q=80',
    // Finance
    'https://images.unsplash.com/photo-1559526324-593bc073d938?w=480&q=80',
    // Stock chart
    'https://images.unsplash.com/photo-1444653614773-995cb1ef9efa?w=480&q=80',
    // Market data
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=480&q=80',
    // Digital
    'https://images.unsplash.com/photo-1591696205602-2f950c417cb9?w=480&q=80',
    // Candlestick
    'https://images.unsplash.com/photo-1634542984003-e0fb8e200e91?w=480&q=80',
    // Crypto
    'https://images.unsplash.com/photo-1621761191319-c6fb62004040?w=480&q=80',
    // Coins
    'https://images.unsplash.com/photo-1605792657660-596af9009e82?w=480&q=80',
    // Bitcoin
    'https://images.unsplash.com/photo-1624996379697-f01d168b1a52?w=480&q=80',
    // Stock
    'https://images.unsplash.com/photo-1642543492481-44e81e3914a7?w=480&q=80',
    // Trading screen
    'https://images.unsplash.com/photo-1569025743873-ea3a9ber?w=480&q=80',
    // Finance
    'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=480&q=80',
    // Chart
    'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=480&q=80',
    // Analytics
    'https://images.unsplash.com/photo-1553729459-efe14ef6055d?w=480&q=80',
    // Money
    'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=480&q=80',
    // Financial
  ];

  @override
  void initState() {
    super.initState();
    // For m3u8, pick a random stock thumbnail
    if (widget.video.videoType == VideoType.m3u8 &&
        widget.video.displayThumbnail.isEmpty) {
      final random =
          DateTime.now().millisecondsSinceEpoch % _stockThumbnails.length;
      _randomStockThumbnail = _stockThumbnails[random];
    }
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    // If it's a YouTube video or has custom thumbnail, don't generate
    if (widget.video.displayThumbnail.isNotEmpty) {
      setState(() {
        _isLoadingThumbnail = false;
      });
      return;
    }

    // Skip thumbnail generation for m3u8 streams (can't generate thumbnails, often HTTP)
    if (widget.video.videoType == VideoType.m3u8) {
      setState(() {
        _isLoadingThumbnail = false;
      });
      return;
    }

    // Generate thumbnail from video URL for mp4 only
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.video.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 480,
        quality: 75,
      );
      if (mounted && thumbnail != null) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to generate thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDark ? 0.3 : 0.08,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                _buildThumbnail(),
                // Content
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.video.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.video.subTitle.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          widget.video.subTitle,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Video type badge
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.r),
        topRight: Radius.circular(16.r),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            _buildThumbnailImage(),
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 36.w,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    // If has custom/YouTube thumbnail URL
    if (widget.video.displayThumbnail.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.video.displayThumbnail,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildGradientPlaceholder(),
      );
    }

    // For m3u8 streams, show random stock market thumbnail
    if (_randomStockThumbnail != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _randomStockThumbnail!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildShimmerPlaceholder(),
            errorWidget: (context, url, error) => _buildGradientPlaceholder(),
          ),
          // LIVE badge overlay
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // If generated thumbnail available
    if (_thumbnailData != null) {
      return Image.memory(_thumbnailData!, fit: BoxFit.cover);
    }

    // If still loading thumbnail
    if (_isLoadingThumbnail) {
      return _buildShimmerPlaceholder();
    }

    // Fallback to gradient placeholder
    return _buildGradientPlaceholder();
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: widget.isDark
          ? AppColors.shimmerBaseDark
          : AppColors.shimmerBaseLight,
      highlightColor: widget.isDark
          ? AppColors.shimmerHighlightDark
          : AppColors.shimmerHighlightLight,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildGradientPlaceholder() {
    // Check if it's a live stream (m3u8)
    final isLive = widget.video.videoType == VideoType.m3u8;

    // Beautiful gradient placeholder with video icon
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLive
              ? [
                  AppColors.errorLight.withValues(alpha: 0.4),
                  AppColors.primaryLight.withValues(alpha: 0.3),
                ]
              : [
                  AppColors.primaryLight.withValues(alpha: 0.3),
                  AppColors.secondaryLight.withValues(alpha: 0.3),
                ],
        ),
      ),
      child: Stack(
        children: [
          // LIVE badge for m3u8
          if (isLive)
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLive
                      ? Icons.live_tv_rounded
                      : Icons.play_circle_outline_rounded,
                  size: 48.w,
                  color: widget.isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.video.title.length > 15
                      ? '${widget.video.title.substring(0, 15)}...'
                      : widget.video.title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
