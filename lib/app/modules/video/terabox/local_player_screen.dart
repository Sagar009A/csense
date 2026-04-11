/// Local Player Screen for Offline Videos
/// Supports file path or content:// URI (no READ_MEDIA_* permission).
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../common/widgets/native_ad_widget.dart';
import '../../../services/auth_service.dart';
import 'widgets/video_player_service.dart';
import 'widgets/custom_controls.dart';

class LocalPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String? title;

  /// Content URI for MediaStore.createDeleteRequest (Android 11+), no broad permission.
  final String? contentUri;

  const LocalPlayerScreen({
    super.key,
    required this.videoPath,
    this.title,
    this.contentUri,
  });

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  late VideoPlayerService _playerService;
  bool _showControls = true;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      final isContentUri = widget.videoPath.startsWith('content://');
      if (!isContentUri) {
        final file = File(widget.videoPath);
        if (!file.existsSync()) {
          setState(() {
            _errorMessage = 'Video file not found';
          });
          return;
        }
      }

      _playerService = VideoPlayerService();
      _playerService.addListener(() {
        if (!mounted) return;
        if (_playerService.isInitialized && !_isInitialized) {
          setState(() => _isInitialized = true);
        }
        if (_playerService.hasError) {
          setState(() {
            _errorMessage = _playerService.errorMessage ?? 'Failed to play video';
          });
        }
        setState(() {});
      });

      _playerService.initializePlayer(widget.videoPath);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _playerService.disposeService();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _getFileName() {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    return widget.videoPath
        .split('/')
        .last
        .replaceAll('.mp4', '')
        .replaceAll('_', ' ');
  }

  String _getFolderName() {
    if (widget.videoPath.startsWith('content://')) return 'Device';
    final parts = widget.videoPath.split('/');
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return 'Videos';
  }

  String _getFileSize() {
    if (widget.videoPath.startsWith('content://')) return '';
    try {
      final file = File(widget.videoPath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return "$bytes B";
        if (bytes < 1024 * 1024)
          return "${(bytes / 1024).toStringAsFixed(1)} KB";
        if (bytes < 1024 * 1024 * 1024)
          return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
        return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
      }
    } catch (e) {
      // Ignore
    }
    return '';
  }

  Widget _buildButton({
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
              style: TextStyle(color: Colors.white, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
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
                SizedBox(height: 24.h),
                Text(
                  'video_play_error'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text('go_back'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _getFileName(),
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Video player - 30% of screen height for smaller footprint
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.30,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  if (_playerService.isInitialized && _playerService.controller != null)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _playerService.controller!.value.size.width,
                          height: _playerService.controller!.value.size.height,
                          child: VideoPlayer(_playerService.controller!),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryLight),
                      ),
                    ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() => _showControls = !_showControls),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (_playerService.isBuffering)
                    Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
                  if (_playerService.isInitialized)
                    Positioned.fill(
                      child: CustomControls(
                        showControls: _showControls,
                        playerService: _playerService,
                        title: widget.title,
                        onToggleFullScreen: () {
                          _playerService.toggleFullScreen();
                          if (_playerService.isFullScreen) {
                            SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                          } else {
                            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          }
                        },
                        onToggleControls: () => setState(() => _showControls = !_showControls),
                      ),
                    ),
                ],
              ),
            ),
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
                      _getFileName(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Video details
                    Text(
                      _getFileSize().isEmpty
                          ? _getFolderName()
                          : '${_getFileSize()} • ${_getFolderName()}',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // User info + Premium badge
                    Row(
                      children: [
                        // Folder icon instead of avatar
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            color: AppColors.primaryLight,
                            size: 20.w,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _getFolderName(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        _buildButton(
                          icon: Icons.diamond_rounded,
                          label: "Premium",
                          onTap: () =>
                              AuthService.to.openPurchaseScreenIfAllowed(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Action buttons
                    Row(
                      children: [
                        if (!widget.videoPath.startsWith('content://'))
                          _buildButton(
                            icon: Icons.share_rounded,
                            label: "Share",
                            onTap: () {
                              SharePlus.instance.share(
                                ShareParams(
                                  files: [XFile(widget.videoPath)],
                                ),
                              );
                            },
                          ),
                        _buildButton(
                          icon: Icons.delete_outline_rounded,
                          label: "Delete",
                          onTap: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                backgroundColor: AppColors.cardDark,
                                title: Text(
                                  'delete_video'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                content: Text(
                                  'delete_video_confirm'.tr,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: Text('cancel'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: Text(
                                      'delete'.tr,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              // Delete handled by parent screen
                              Get.back();
                            }
                          },
                        ),
                        if (widget.contentUri != null)
                          _buildButton(
                            icon: Icons.delete_sweep_rounded,
                            label: "Remove",
                            onTap: () async {
                              final confirm = await Get.dialog<bool>(
                                AlertDialog(
                                  backgroundColor: AppColors.cardDark,
                                  title: Text(
                                    'remove_from_device'.tr,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'remove_from_device_confirm'.tr,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () => Get.back(result: true),
                                      child: Text(
                                        'remove'.tr,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                Get.back();
                              }
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Native ad
                    const NativeAdWidget(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
