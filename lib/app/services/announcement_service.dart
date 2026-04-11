/// Announcement Service
/// Fetches the active app announcement from Firebase Realtime Database.
/// Firebase node: /announcement  (single object – only one active announcement)
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AnnouncementModel {
  final String announcementId;
  final String title;
  final String message;
  final String imageUrl;
  final String buttonText;
  final String buttonUrl;
  final bool isActive;
  final bool showOnce;

  const AnnouncementModel({
    required this.announcementId,
    required this.title,
    required this.message,
    this.imageUrl = '',
    this.buttonText = '',
    this.buttonUrl = '',
    this.isActive = true,
    this.showOnce = true,
  });

  factory AnnouncementModel.fromMap(Map<dynamic, dynamic> map) {
    return AnnouncementModel(
      announcementId: map['announcement_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      buttonText: map['button_text']?.toString() ?? '',
      buttonUrl: map['button_url']?.toString() ?? '',
      isActive: map['is_active'] == true || map['is_active'] == 1,
      showOnce: map['show_once'] != false && map['show_once'] != 0,
    );
  }
}

class AnnouncementService extends GetxService {
  static AnnouncementService get to => Get.find();

  final _storage = GetStorage();
  static const _seenKeyPrefix = 'seen_ann_';

  /// Fetch the active announcement; returns null if none or already seen.
  Future<AnnouncementModel?> fetchAnnouncement() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('announcement').get();

      if (!snapshot.exists || snapshot.value == null) return null;

      final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final model = AnnouncementModel.fromMap(map);

      if (!model.isActive) return null;
      if (model.title.isEmpty || model.message.isEmpty) return null;

      // If show_once is true, check whether this user already saw this ID
      if (model.showOnce && _hasSeen(model.announcementId)) return null;

      return model;
    } catch (e) {
      debugPrint('AnnouncementService: fetch error – $e');
      return null;
    }
  }

  /// Mark an announcement as seen so it is not shown again (when show_once=true).
  void markSeen(String announcementId) {
    if (announcementId.isEmpty) return;
    _storage.write('$_seenKeyPrefix$announcementId', true);
  }

  bool _hasSeen(String announcementId) {
    if (announcementId.isEmpty) return false;
    return _storage.read<bool>('$_seenKeyPrefix$announcementId') == true;
  }
}
