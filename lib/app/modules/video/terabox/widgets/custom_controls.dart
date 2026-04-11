import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'video_player_service.dart';
import 'player_constants.dart';
import 'player_helpers.dart';
import 'buffer_indicator.dart';
import 'quality_selector.dart';

class CustomControls extends StatefulWidget {
  final bool showControls;
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onToggleControls;
  final VideoPlayerService playerService;
  final String? title;
  final String? subtitleText;
  final List<Map<String, String>> subtitleSources;
  final int currentSubtitleIndex;
  final ValueChanged<int>? onSubtitleSelected;
  final Map<String, dynamic>? streamUrls;
  final String currentQuality;
  final ValueChanged<String>? onQualityChanged;

  const CustomControls({
    super.key,
    required this.showControls,
    required this.playerService,
    this.onToggleFullScreen,
    this.onToggleControls,
    this.title,
    this.subtitleText,
    this.subtitleSources = const [],
    this.currentSubtitleIndex = -1,
    this.onSubtitleSelected,
    this.streamUrls,
    this.currentQuality = 'Auto',
    this.onQualityChanged,
  });

  @override
  State<CustomControls> createState() => _CustomControlsState();
}

class _CustomControlsState extends State<CustomControls> {
  @override
  Widget build(BuildContext context) {
    final playerService = widget.playerService;

    if (!playerService.isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Subtitle overlay — always visible, never hides with controls
        if (widget.subtitleText != null && widget.subtitleText!.isNotEmpty)
          Positioned(left: 0, right: 0, bottom: 60, child: _buildSubtitle()),

        // Player controls — fade in/out
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.showControls,
            child: AnimatedOpacity(
              opacity: widget.showControls ? 1.0 : 0.0,
              duration: PlayerDurations.normal,
              child: Stack(
                children: [
                  // Buffer indicator
                  if (playerService.isBuffering)
                    Center(
                      child: BufferIndicator(
                        bufferProgress: playerService.bufferProgress,
                        isBuffering: playerService.isBuffering,
                      ),
                    ),

                  // Center controls (Play/Pause/Seek)
                  _buildCenterControls(playerService),

                  // Bottom controls - progress bar together at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomControls(playerService),
                  ),

                  // Top controls
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _buildTopControls(playerService),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterControls(VideoPlayerService playerService) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircleButton(
            icon: Icons.replay_10,
            onPressed: () => playerService.seekBackward(10),
            size: 40,
            iconSize: 28,
          ),
          const SizedBox(width: 24),
          _buildCircleButton(
            icon: playerService.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            onPressed: () => playerService.togglePlayPause(),
            size: 56,
            iconSize: 56,
          ),
          const SizedBox(width: 24),
          _buildCircleButton(
            icon: Icons.forward_10,
            onPressed: () => playerService.seekForward(10),
            size: 40,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
    double iconSize = 32,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PlayerColors.primary.withValues(alpha: 0.5),
          ),
          child: Icon(icon, size: iconSize, color: PlayerColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildTopControls(VideoPlayerService playerService) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (_) {},
      onTap: () => widget.onToggleControls?.call(),
      onDoubleTap: () {},
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PlayerColors.primary.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              if (!playerService.isFullScreen)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: PlayerColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      await SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge,
                      );
                    },
                  ),
                ),
              Expanded(
                child: Text(
                  widget.title ?? 'Video Player',
                  style: const TextStyle(
                    color: PlayerColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoPlayerService playerService) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (_) {},
      onTap: () => widget.onToggleControls?.call(),
      onDoubleTap: () {},
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                PlayerColors.primary.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 15.r, right: 15.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BufferProgressBar(
                  bufferProgress: playerService.bufferProgress,
                  positionProgress: playerService.positionProgress,
                  position: playerService.position,
                  duration: playerService.duration,
                  onSeekStart: () => playerService.startSeeking(),
                  onSeek: (position) => playerService.seekTo(position),
                ),
                Row(
                  children: [
                    Text(
                      '${formatDuration(playerService.position)} / ${formatDuration(playerService.duration)}',
                      style: const TextStyle(
                        color: PlayerColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    PlaybackSpeedSelector(
                      currentSpeed: playerService.playbackSpeed,
                      onSpeedSelected: (speed) =>
                          playerService.setPlaybackSpeed(speed),
                    ),
                    // Quality selector
                    if (widget.streamUrls != null &&
                        widget.streamUrls!.length > 1)
                      VideoQualitySelector(
                        streamUrls: widget.streamUrls!,
                        currentQuality: widget.currentQuality,
                        onQualitySelected: widget.onQualityChanged,
                      ),
                    SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        playerService.toggleMute();
                      },
                      child: Icon(
                        playerService.isMuted
                            ? Icons.volume_off
                            : playerService.volume > 50
                            ? Icons.volume_up
                            : Icons.volume_down,
                        color: PlayerColors.textPrimary,
                        size: 20,
                      ),
                    ),

                    SizedBox(width: 20),
                    // Subtitle button
                    GestureDetector(
                      onTap: () {
                        _showSubtitleSelector(context);
                      },
                      child: Icon(
                        Icons.closed_caption,
                        color: widget.currentSubtitleIndex != -1
                            ? PlayerColors.secondary
                            : PlayerColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        widget.onToggleFullScreen?.call();
                      },
                      child: Icon(
                        playerService.isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: PlayerColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.subtitleText!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.h,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    VideoPlayerService playerService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlayerColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(PlayerSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: PlayerColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: PlayerSpacing.large),
              const Text(
                'Playback Speed',
                style: TextStyle(
                  color: PlayerColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: PlayerSpacing.small),
              Wrap(
                spacing: PlayerSpacing.small,
                children: PlaybackSpeeds.speeds.map((speed) {
                  final isSelected = speed == playerService.playbackSpeed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    selectedColor: PlayerColors.secondary,
                    onSelected: (_) {
                      playerService.setPlaybackSpeed(speed);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubtitleSelector(BuildContext context) {
    if (widget.subtitleSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subtitles available for this video')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              Text(
                'Subtitles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.h,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // "None (Off)" option
                    ListTile(
                      leading: Icon(
                        widget.currentSubtitleIndex == -1
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: widget.currentSubtitleIndex == -1
                            ? Colors.green
                            : Colors.white54,
                        size: 22.h,
                      ),
                      title: Text(
                        'None (Off)',
                        style: TextStyle(
                          color: widget.currentSubtitleIndex == -1
                              ? Colors.green
                              : Colors.white,
                          fontSize: 15.h,
                          fontWeight: widget.currentSubtitleIndex == -1
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onSubtitleSelected?.call(-1);
                      },
                    ),
                    // Subtitle track options
                    ...List.generate(widget.subtitleSources.length, (index) {
                      final source = widget.subtitleSources[index];
                      final isSelected = index == widget.currentSubtitleIndex;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.green : Colors.white54,
                          size: 22.h,
                        ),
                        title: Text(
                          source['name'] ?? 'Subtitle ${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.green : Colors.white,
                            fontSize: 15.h,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onSubtitleSelected?.call(index);
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
}
