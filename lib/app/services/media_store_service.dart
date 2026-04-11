/// MediaStore Service
/// Calls Android MediaStore.createDeleteRequest via platform channel (no READ_MEDIA_* permission).
library;

import 'dart:io';
import 'package:flutter/services.dart';

class MediaStoreService {
  MediaStoreService._();
  static const MethodChannel _channel =
      MethodChannel('com.chartsense.ai.app/media_store');

  /// Request system delete for a content URI (Android 11+).
  /// Shows system confirmation dialog; no broad media permission required.
  /// Returns true if user confirmed delete, false otherwise.
  static Future<bool> requestDelete(String contentUri) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('deleteVideo', {
        'uri': contentUri,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      return false;
    }
  }
}
