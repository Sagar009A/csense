/// Video Model
/// Data model for video items from Firebase
library;

enum VideoType { mp4, m3u8, youtube }

class VideoModel {
  final String id;
  final String title;
  final String subTitle;
  final String videoUrl;
  final String? thumbnail;
  final VideoType videoType;

  VideoModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.videoUrl,
    this.thumbnail,
    required this.videoType,
  });

  /// Factory to create from Firebase snapshot
  factory VideoModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final url = map['video_url'] as String? ?? '';
    return VideoModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled',
      subTitle: map['sub_title'] as String? ?? '',
      videoUrl: url,
      thumbnail: map['thumbnail'] as String?,
      videoType: _detectVideoType(url),
    );
  }

  /// Detect video type from URL
  static VideoType _detectVideoType(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      return VideoType.youtube;
    } else if (lowerUrl.contains('.m3u8')) {
      return VideoType.m3u8;
    } else {
      return VideoType.mp4;
    }
  }

  /// Get YouTube video ID from URL
  String? get youtubeVideoId {
    if (videoType != VideoType.youtube) return null;

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return null;

    // Handle youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    // Handle youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    return null;
  }

  /// Get YouTube thumbnail URL
  String get youtubeThumbnail {
    final videoId = youtubeVideoId;
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  /// Get display thumbnail (custom, YouTube, or placeholder)
  String get displayThumbnail {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      return thumbnail!;
    }
    if (videoType == VideoType.youtube) {
      return youtubeThumbnail;
    }
    return '';
  }
}
