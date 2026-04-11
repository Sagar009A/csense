import 'package:flutter/material.dart';
import 'player_constants.dart';

class BufferIndicator extends StatelessWidget {
  final double bufferProgress;
  final bool isBuffering;

  const BufferIndicator({
    super.key,
    required this.bufferProgress,
    required this.isBuffering,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBuffering && bufferProgress >= 1.0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(PlayerSpacing.medium),
      decoration: BoxDecoration(
        color: PlayerColors.primary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 4,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    PlayerColors.bufferIndicator,
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

class BufferProgressBar extends StatefulWidget {
  final double bufferProgress;
  final double positionProgress;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onSeekStart;

  const BufferProgressBar({
    super.key,
    required this.bufferProgress,
    required this.positionProgress,
    required this.position,
    required this.duration,
    this.onSeek,
    this.onSeekStart,
  });

  @override
  State<BufferProgressBar> createState() => _BufferProgressBarState();
}

class _BufferProgressBarState extends State<BufferProgressBar> {
  double? _dragValue;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // While dragging, use _dragValue.
    // After drag ends, keep showing _dragValue until the service position
    // catches up (within 5% of the seek target) to prevent slider snap-back
    // on iOS where HLS seeks can take 1-2 seconds.
    double displayValue;
    if (_dragValue != null) {
      displayValue = _dragValue!;
    } else {
      displayValue = widget.positionProgress;
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: PlayerColors.secondary,
        inactiveTrackColor: PlayerColors.bufferBackground,
        thumbColor: PlayerColors.secondary,
        overlayColor: PlayerColors.secondary.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: displayValue.clamp(0.0, 1.0),
        onChangeStart: (value) {
          _isDragging = true;
          widget.onSeekStart?.call();
        },
        onChanged: (value) {
          setState(() {
            _dragValue = value;
          });
        },
        onChangeEnd: (value) {
          _isDragging = false;
          if (widget.onSeek != null) {
            final newPosition = Duration(
              milliseconds: (value * widget.duration.inMilliseconds).toInt(),
            );
            widget.onSeek!(newPosition);
          }
          // Keep _dragValue set — it will be cleared by didUpdateWidget
          // once the service position catches up to the seek target.
          // This prevents the slider from snapping back on iOS.
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant BufferProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear _dragValue once the actual position has caught up to the seek target
    if (_dragValue != null && !_isDragging) {
      final diff = (widget.positionProgress - _dragValue!).abs();
      if (diff < 0.05) {
        // Position caught up — start using live position again
        _dragValue = null;
      }
    }
  }
}
