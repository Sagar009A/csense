/// Image Picker Service
/// Handles camera and gallery image selection
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerService extends GetxService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isGranted) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (image != null) {
          return File(image.path);
        }
      } catch (e) {
        debugPrint('Error picking image from camera: $e');
      }
    } else if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
    }

    return null;
  }

  /// Pick image from gallery (system picker — no READ_MEDIA_IMAGES on Android 13+).
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Show image source picker dialog
  Future<File?> showImageSourcePicker() async {
    final result = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('take_photo'.tr),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('upload_image'.tr),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (result == ImageSource.camera) {
      return await pickFromCamera();
    } else if (result == ImageSource.gallery) {
      return await pickFromGallery();
    }

    return null;
  }
}
