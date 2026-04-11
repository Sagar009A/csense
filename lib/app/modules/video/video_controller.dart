/// Video Controller
/// Manages video list screen state
library;

import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import '../../services/video_service.dart';
import 'video_model.dart';

class VideoController extends GetxController {
  VideoService? _videoService;

  final RxList<VideoModel> _fallbackVideos = <VideoModel>[].obs;
  final RxBool _fallbackLoading = false.obs;
  final RxBool _fallbackError = true.obs;
  final RxString _fallbackErrorMessage = 'Firebase not configured'.obs;

  @override
  void onInit() {
    super.onInit();
    // Try to find VideoService (may not exist if Firebase failed)
    try {
      _videoService = Get.find<VideoService>();
    } catch (e) {
      _videoService = null;
    }
  }

  RxList<VideoModel> get videos => _videoService?.videos ?? _fallbackVideos;
  RxBool get isLoading => _videoService?.isLoading ?? _fallbackLoading;
  RxBool get hasError => _videoService?.hasError ?? _fallbackError;
  RxString get errorMessage =>
      _videoService?.errorMessage ?? _fallbackErrorMessage;

  Future<void> refreshVideos() async {
    if (_videoService != null) {
      await _videoService!.refreshVideos();
    }
  }

  /// If video_url is a teraboxurll.in short link, open TeraBox flow with short code; else open normal player.
  void openVideoPlayer(VideoModel video) {
    final shortCode = _extractTeraBoxShortCode(video.videoUrl);
    if (shortCode != null && shortCode.isNotEmpty) {
      Get.toNamed(AppRoutes.teraboxButton, arguments: shortCode);
    } else {
      Get.toNamed(AppRoutes.videoPlayer, arguments: video);
    }
  }

  /// Extracts short code from teraboxurll.in URL (e.g. https://teraboxurll.in/gmP4IRLoNFR35fnrpDYIKXGeKs → gmP4IRLoNFR35fnrpDYIKXGeKs).
  static String? _extractTeraBoxShortCode(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (!ApiConstants.deepLinkHosts.contains(host)) return null;
    final path = uri.path;
    if (path.isEmpty || path == '/') return null;
    final segment = path.startsWith('/') ? path.substring(1) : path;
    final trimmed = segment.split('/').first.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
