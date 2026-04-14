/// Video Service
/// Handles Firebase Realtime Database operations for videos
library;

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import '../modules/video/video_model.dart';

class VideoService extends GetxService {
  static VideoService get to => Get.find();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('videos');
  StreamSubscription? _videoSubscription;

  final RxList<VideoModel> videos = <VideoModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToVideos();
  }

  @override
  void onClose() {
    _videoSubscription?.cancel();
    super.onClose();
  }

  /// Listen to real-time video updates from Firebase
  void _listenToVideos() {
    isLoading.value = true;
    hasError.value = false;

    _videoSubscription = _dbRef.onValue.listen(
      (event) {
        isLoading.value = false;
        hasError.value = false;

        final data = event.snapshot.value;
        if (data == null) {
          videos.clear();
          return;
        }

        if (data is Map) {
          final videoList = <VideoModel>[];
          data.forEach((key, value) {
            if (value is Map) {
              try {
                // Check if it's a valid video node (must have video_url)
                if (value['video_url'] == null || value['video_url'].toString().isEmpty) {
                  return; 
                }
                
                final video = VideoModel.fromMap(key.toString(), value);
                
                // Double check validity
                if (video.videoUrl.isNotEmpty && video.title != 'Untitled') {
                  videoList.add(video);
                }
              } catch (e) {
                // Skip invalid entries
              }
            }
          });
          
          // Sort videos by title
          videoList.sort((a, b) => a.title.compareTo(b.title));
          videos.value = videoList;
        }
      },
      onError: (error) {
        isLoading.value = false;
        hasError.value = true;
        errorMessage.value = error.toString();
      },
    );
  }


  /// Refresh videos manually
  Future<void> refreshVideos() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final snapshot = await _dbRef.get();
      final data = snapshot.value;

      if (data == null) {
        videos.clear();
        return;
      }

      if (data is Map) {
        final videoList = <VideoModel>[];
        data.forEach((key, value) {
          if (value is Map) {
            try {
               // Check if it's a valid video node (must have video_url)
              if (value['video_url'] == null || value['video_url'].toString().isEmpty) {
                return; 
              }

              final video = VideoModel.fromMap(key.toString(), value);
              
              // Double check validity
              if (video.videoUrl.isNotEmpty && video.title != 'Untitled') {
                videoList.add(video);
              }
            } catch (e) {
              // Skip invalid entries
            }
          }
        });

        videoList.sort((a, b) => a.title.compareTo(b.title));
        videos.value = videoList;
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
