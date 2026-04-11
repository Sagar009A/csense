import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

enum PlayerState {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
}

class VideoPlayerService extends ChangeNotifier {
  VideoPlayerController? _controller;
  PlayerState _state = PlayerState.idle;
  String? _errorMessage;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  bool _isFullScreen = false;
  bool _isMuted = false;
  double _volume = 100.0;
  double _playbackSpeed = 1.0;
  double _brightness = 0.5;

  bool _isSeeking = false;
  bool _isDisposed = false;

  StreamSubscription<double>? _volumeSubscription;

  // Getters
  VideoPlayerController? get player => _controller;
  VideoPlayerController? get controller => _controller;
  PlayerState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get hasError => _state == PlayerState.error;

  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;

  bool get isPlaying => _state == PlayerState.playing;
  bool get isPaused => _state == PlayerState.paused;
  bool get isBuffering => _state == PlayerState.buffering;
  bool get isLoading => _state == PlayerState.loading;
  bool get isFullScreen => _isFullScreen;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  double get brightness => _brightness;

  bool get isInitialized => _controller != null && _controller!.value.isInitialized;

  double get positionProgress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  double get bufferedProgress {
    if (_duration.inMilliseconds == 0) return 0;
    return _bufferedPosition.inMilliseconds / _duration.inMilliseconds;
  }

  double get bufferProgress => bufferedProgress;

  String? _currentUrl;
  String? get currentUrl => _currentUrl;

  Future<void> initializePlayer(String url, {int retryCount = 0, Duration? startPosition}) async {
    if (_isDisposed) return;

    _currentUrl = url;
    _state = PlayerState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Dispose old controller if exists
      await _controller?.dispose();

      // Create new controller with format hint for HLS streams
      final uri = Uri.parse(url);
      final isHls = url.toLowerCase().contains('.m3u8');
      _controller = VideoPlayerController.networkUrl(
        uri,
        formatHint: isHls ? VideoFormat.hls : null,
      );

      // Initialize
      await _controller!.initialize();

      // Start polling timer instead of addListener (avoids message queue flood)
      _startPolling();

      // Keep video player volume at max — system volume controls actual output
      await _controller!.setVolume(1.0);

      // Hide system volume UI (we show our own indicator)
      VolumeController.instance.showSystemUI = false;

      // Read current system volume
      _volume = (await VolumeController.instance.getVolume()) * 100;

      // Listen for system volume changes
      _volumeSubscription?.cancel();
      _volumeSubscription = VolumeController.instance.addListener((volume) {
        _volume = volume * 100;
        if (_volume > 0 && _isMuted) {
          _isMuted = false;
        }
        notifyListeners();
      });

      // Start playback
      await _controller!.play();
      _state = PlayerState.playing;

      // Seek to start position if provided (quality switch resume)
      if (startPosition != null && startPosition.inSeconds > 0) {
        _controller!.seekTo(startPosition);
      }

      // Keep screen on
      await WakelockPlus.enable();

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing player (attempt ${retryCount + 1}): $e');
      _stopPolling();
      await _controller?.dispose();
      _controller = null;

      // Auto-retry up to 2 times with 2s delay
      if (retryCount < 1 && !_isDisposed) {
        debugPrint('Auto-retrying in 2s... (${retryCount + 2}/2)');
        await Future.delayed(const Duration(seconds: 2));
        return initializePlayer(url, retryCount: retryCount + 1, startPosition: startPosition);
      }

      _state = PlayerState.error;
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
    }
  }

  String _parseErrorMessage(dynamic error) {
    final errStr = error.toString();
    if (errStr.contains('403')) {
      return 'Access denied (403 Forbidden). The video URL may have expired or requires authentication.';
    } else if (errStr.contains('404')) {
      return 'Video not found (404). Please check the URL.';
    } else if (errStr.contains('401')) {
      return 'Unauthorized (401). Authentication required.';
    } else if (errStr.contains('SocketException') || errStr.contains('NetworkError')) {
      return 'Network error. Please check your internet connection.';
    } else if (errStr.contains('Source error')) {
      return 'Unable to play this video. The URL may be invalid or the format is unsupported.';
    }
    return 'Failed to load video: $errStr';
  }

  Timer? _pollTimer;

  void _startPolling() {
    _stopPolling();
    // Poll controller state at 1Hz — smooth enough for slider, no performance impact
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _pollPlayerState();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _pollPlayerState() {
    if (_controller == null || _isDisposed) return;

    final value = _controller!.value;

    // Update position only when not dragging slider
    if (!_isSeeking) {
      _position = value.position;
    }

    // Update duration
    if (value.duration.inMilliseconds > 0) {
      _duration = value.duration;
    }

    // Update buffered position
    if (value.buffered.isNotEmpty) {
      _bufferedPosition = value.buffered.last.end;
    }

    // Update state
    if (value.isPlaying) {
      _state = PlayerState.playing;
      _isSeeking = false;
    } else if (value.isBuffering) {
      _state = PlayerState.buffering;
    } else if (value.hasError) {
      // Auto-retry on playback error
      debugPrint('Playback error detected, auto-retrying...');
      _state = PlayerState.loading;
      _errorMessage = null;
      if (_currentUrl != null && !_isDisposed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!_isDisposed && _currentUrl != null) {
            initializePlayer(_currentUrl!);
          }
        });
      }
    } else if (value.isCompleted) {
      _state = PlayerState.paused;
    } else if (_state != PlayerState.loading && !_isSeeking) {
      _state = PlayerState.paused;
    }

    notifyListeners();
  }

  // Playback controls — fire and forget, state listener handles everything
  void play() {
    _controller?.play();
  }

  void pause() {
    _controller?.pause();
  }

  void togglePlayPause() {
    if (_controller?.value.isPlaying == true) {
      _controller?.pause();
    } else {
      _controller?.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_controller == null || _isDisposed) return;
    _isSeeking = true;
    _position = position;
    notifyListeners();
    try {
      await _controller!.seekTo(position);
      await _controller!.play();
    } catch (e) {
      debugPrint('Seek error: $e');
    }
    // Clear seeking flag after enough time for iOS HLS seek to settle
    // iOS seeks can take 1-2s on HLS streams; 300ms was too short
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isSeeking = false;
      notifyListeners();
    });
  }

  Future<void> seekForward(int seconds) async {
    final newPosition = _position + Duration(seconds: seconds);
    if (newPosition < _duration) {
      await seekTo(newPosition);
    } else {
      await seekTo(_duration);
    }
  }

  Future<void> seekBackward(int seconds) async {
    final newPosition = _position - Duration(seconds: seconds);
    if (newPosition > Duration.zero) {
      await seekTo(newPosition);
    } else {
      await seekTo(Duration.zero);
    }
  }

  // Volume control
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 100.0);
    try {
      await VolumeController.instance.setVolume(_volume / 100);
    } catch (e) {
      debugPrint('Error setting system volume: $e');
    }
    if (_volume > 0 && _isMuted) {
      _isMuted = false;
    }
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    try {
      await VolumeController.instance.setMute(_isMuted);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
    notifyListeners();
  }

  // Playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _controller?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  // Seeking state
  void startSeeking() {
    _isSeeking = true;
    notifyListeners();
  }

  void stopSeeking() {
    _isSeeking = false;
    notifyListeners();
  }

  // Fullscreen
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void setFullScreen(bool fullScreen) {
    _isFullScreen = fullScreen;
    notifyListeners();
  }

  // Brightness
  Future<void> setBrightness(double brightness) async {
    _brightness = brightness.clamp(0.0, 1.0);
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_brightness);
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
    notifyListeners();
  }

  // Stop and cleanup
  Future<void> stop() async {
    await savePosition();
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
    _position = Duration.zero;
    _state = PlayerState.idle;
    await WakelockPlus.disable();
    notifyListeners();
  }

  // Reset player state for retry
  Future<void> resetForRetry() async {
    _stopPolling();
    await _controller?.dispose();
    _controller = null;
    _state = PlayerState.idle;
    _errorMessage = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _bufferedPosition = Duration.zero;
    notifyListeners();
  }

  // Resume feature
  String _getPositionKey(String url) => 'video_position_${url.hashCode}';

  Future<void> savePosition() async {
    if (_controller == null || _position.inSeconds < 5) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_getPositionKey(_currentUrl!), _position.inMilliseconds);
    } catch (e) {
      debugPrint('Error saving position: $e');
    }
  }

  Future<Duration?> getSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final position = prefs.getInt(_getPositionKey(url));
      if (position != null && position > 0) {
        return Duration(milliseconds: position);
      }
    } catch (e) {
      debugPrint('Error getting saved position: $e');
    }
    return null;
  }

  Future<void> clearSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getPositionKey(url));
    } catch (e) {
      debugPrint('Error clearing saved position: $e');
    }
  }

  /// Dispose all resources. After calling this, the service must not be used.
  Future<void> disposeService() async {
    _isDisposed = true;
    _stopPolling();
    _volumeSubscription?.cancel();
    await savePosition();
    await _controller?.dispose();
    _controller = null;
    await WakelockPlus.disable();
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Could not reset brightness: $e');
    }
  }

  @override
  void dispose() {
    disposeService();
    super.dispose();
  }
}
