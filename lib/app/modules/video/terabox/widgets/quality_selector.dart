import 'package:flutter/material.dart';
import 'player_constants.dart';

class PlaybackSpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double>? onSpeedSelected;

  const PlaybackSpeedSelector({
    super.key,
    required this.currentSpeed,
    this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: Text(
        '${currentSpeed}x',
        style: const TextStyle(
          color: PlayerColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      tooltip: 'Playback Speed',
      color: PlayerColors.surface,
      onSelected: onSpeedSelected,
      itemBuilder: (context) {
        return PlaybackSpeeds.speeds.map((speed) {
          final isSelected = speed == currentSpeed;
          return PopupMenuItem<double>(
            value: speed,
            child: Row(
              children: [
                Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected
                        ? PlayerColors.secondary
                        : PlayerColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: PlayerColors.secondary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class VideoQualitySelector extends StatelessWidget {
  final Map<String, dynamic> streamUrls;
  final String currentQuality;
  final ValueChanged<String>? onQualitySelected;

  const VideoQualitySelector({
    super.key,
    required this.streamUrls,
    required this.currentQuality,
    this.onQualitySelected,
  });

  /// Sort qualities numerically (360 < 480 < 720 < 1080 < 2160/4k)
  List<String> get _sortedQualities {
    final keys = streamUrls.keys.toList();
    keys.sort((a, b) {
      final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    if (streamUrls.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hd, color: PlayerColors.textPrimary, size: 20),
          const SizedBox(width: 2),
          Text(
            currentQuality,
            style: const TextStyle(
              color: PlayerColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
      tooltip: 'Video Quality',
      color: PlayerColors.surface,
      onSelected: onQualitySelected,
      itemBuilder: (context) {
        return _sortedQualities.map((quality) {
          final isSelected = quality == currentQuality;
          return PopupMenuItem<String>(
            value: quality,
            child: Row(
              children: [
                Text(
                  quality.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? PlayerColors.secondary
                        : PlayerColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: PlayerColors.secondary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
