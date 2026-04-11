/// App Config Service
/// Loads remote configuration from Firebase Realtime Database
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/api_constants.dart';

class AppConfigService extends GetxService {
  static AppConfigService get to => Get.find<AppConfigService>();

  final RxString geminiApiKey = ApiConstants.geminiApiKey.obs;
  final RxString geminiModel = ApiConstants.geminiModel.obs;
  final RxString analysisPrompt = ''.obs;
  final RxString playStoreUrl = ApiConstants.playStoreUrl.obs;
  final RxString appStoreUrl = ApiConstants.appStoreUrl.obs;
  final RxString moreAppsUrl = ApiConstants.moreAppsUrl.obs;
  final RxString moreAppsUrlIOS = ApiConstants.moreAppsUrlIOS.obs;
  final RxString privacyPolicyUrl = ApiConstants.privacyPolicyUrl.obs;
  final RxString privacyPolicyUrlIOS = ''.obs;
  final RxString termsOfServiceUrl = ApiConstants.termsOfServiceUrl.obs;
  final RxString termsOfServiceUrlIOS = ''.obs;
  final RxString supportEmail = ''.obs;

  Future<AppConfigService> init() async {
    await _fetchRemoteConfig();
    return this;
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('api_config').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _applyConfig(data);
        debugPrint('AppConfig: Loaded remote api_config');
      } else {
        debugPrint('AppConfig: No api_config found, using defaults');
      }
    } catch (e) {
      debugPrint('AppConfig: Failed to load api_config: $e');
    }
  }

  void _applyConfig(Map<String, dynamic> data) {
    _setIfNotEmpty(geminiApiKey, data['geminiApiKey']);
    _setIfNotEmpty(geminiModel, data['geminiModel']);
    _setIfNotEmpty(analysisPrompt, data['analysisPrompt']);
    _setIfNotEmpty(playStoreUrl, data['playStoreUrl']);
    _setIfNotEmpty(appStoreUrl, data['appStoreUrl']);
    _setIfNotEmpty(moreAppsUrl, data['moreAppsUrl']);
    _setIfNotEmpty(moreAppsUrlIOS, data['moreAppsUrlIOS']);
    _setIfNotEmpty(privacyPolicyUrl, data['privacyPolicyUrl']);
    _setIfNotEmpty(privacyPolicyUrlIOS, data['privacyPolicyUrlIOS']);
    _setIfNotEmpty(termsOfServiceUrl, data['termsOfServiceUrl']);
    _setIfNotEmpty(termsOfServiceUrlIOS, data['termsOfServiceUrlIOS']);
    _setIfNotEmpty(supportEmail, data['supportEmail']);
  }

  void _setIfNotEmpty(RxString target, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      target.value = text;
    }
  }
}
