/// Offline Videos Screen
/// Uses system file picker (ACTION_OPEN_DOCUMENT) — no READ_MEDIA_* permission.
/// Lists, plays, and deletes picked videos via content URIs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/native_ad_widget.dart';
import 'terabox/local_player_screen.dart';

/// Picked video entry: path or content URI + display name
class PickedVideo {
  final String pathOrUri;
  final String name;

  PickedVideo({required this.pathOrUri, required this.name});

  bool get isContentUri =>
      pathOrUri.startsWith('content://') || pathOrUri.startsWith('file://');
}

class OfflineVideosScreen extends StatefulWidget {
  final bool isDark;

  const OfflineVideosScreen({super.key, required this.isDark});

  @override
  State<OfflineVideosScreen> createState() => _OfflineVideosScreenState();
}

class _OfflineVideosScreenState extends State<OfflineVideosScreen> {
  final List<PickedVideo> _pickedVideos = [];

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final newEntries = <PickedVideo>[];
      for (final file in result.files) {
        final path = file.path;
        if (path != null && path.isNotEmpty) {
          newEntries.add(PickedVideo(
            pathOrUri: path,
            name: file.name.isNotEmpty ? file.name : path.split('/').last,
          ));
        }
      }

      if (newEntries.isNotEmpty) {
        setState(() {
          _pickedVideos.addAll(newEntries);
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'video_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorLight,
          colorText: Colors.white,
        );
      }
    }
  }

  void _removeAt(int index) {
    setState(() {
      _pickedVideos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Offline Videos',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: _pickedVideos.isEmpty
          ? _buildEmptyState(isDark)
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                const NativeAdWidget(),
                SizedBox(height: 12.h),
                ...List.generate(_pickedVideos.length, (index) {
                  final video = _pickedVideos[index];
                  return _PickedVideoCard(
                    video: video,
                    isDark: isDark,
                    onPlay: () => _openPlayer(video),
                    onRemove: () => _removeAt(index),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickVideos,
        backgroundColor: AppColors.primaryLight,
        icon: const Icon(Icons.video_library_rounded),
        label: const Text('Choose videos'),
      ),
    );
  }

  void _openPlayer(PickedVideo video) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        Get.to(
          () => LocalPlayerScreen(
            videoPath: video.pathOrUri,
            title: video.name,
            contentUri: video.pathOrUri.startsWith('content://')
                ? video.pathOrUri
                : null,
          ),
        )?.then((_) {
          if (mounted) setState(() {});
        });
      });
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_rounded,
              size: 80.w,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            SizedBox(height: 24.h),
            Text(
              'no_videos_device'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Tap "Choose videos" to pick videos from your device. No storage permission required.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _pickVideos,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Choose videos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedVideoCard extends StatelessWidget {
  final PickedVideo video;
  final bool isDark;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _PickedVideoCard({
    required this.video,
    required this.isDark,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.video_file_rounded,
            color: AppColors.primaryLight,
            size: 28.w,
          ),
        ),
        title: Text(
          video.name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.play_circle_filled_rounded, color: AppColors.primaryLight),
              onPressed: onPlay,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.errorLight),
              onPressed: onRemove,
            ),
          ],
        ),
        onTap: onPlay,
      ),
    );
  }
}
