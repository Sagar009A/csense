/// Admin Panel Controller
/// Reads and writes ad_config + api_config nodes in Firebase RTDB
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/ad_config.dart';
import '../../services/app_config_service.dart';

class AdminPanelController extends GetxController {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ── Ad Config ──────────────────────────────────────────────────────────────
  final RxString adNetwork = 'admob'.obs;
  final RxBool showBannerAd = true.obs;
  final RxBool showNativeAd = true.obs;
  final RxBool showInterstitialAd = true.obs;
  final RxBool showRewardedAd = true.obs;
  final RxBool showAppOpenAd = false.obs;
  final RxInt interstitialCooldownSeconds = 30.obs;

  // ── API Config ─────────────────────────────────────────────────────────────
  final TextEditingController geminiApiKeyCtrl = TextEditingController();
  final TextEditingController geminiModelCtrl = TextEditingController();
  final TextEditingController analysisPromptCtrl = TextEditingController();
  final TextEditingController playStoreUrlCtrl = TextEditingController();
  final TextEditingController appStoreUrlCtrl = TextEditingController();
  final TextEditingController privacyPolicyUrlCtrl = TextEditingController();
  final TextEditingController termsOfServiceUrlCtrl = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  @override
  void onClose() {
    geminiApiKeyCtrl.dispose();
    geminiModelCtrl.dispose();
    analysisPromptCtrl.dispose();
    playStoreUrlCtrl.dispose();
    appStoreUrlCtrl.dispose();
    privacyPolicyUrlCtrl.dispose();
    termsOfServiceUrlCtrl.dispose();
    super.onClose();
  }

  Future<void> _loadConfig() async {
    isLoading.value = true;
    try {
      // Load ad_config
      final adSnap = await _db.child('ad_config').get();
      if (adSnap.exists && adSnap.value is Map) {
        final data = Map<String, dynamic>.from(adSnap.value as Map);
        adNetwork.value = data['adNetwork']?.toString() ?? AdConfig.adNetwork;
        showBannerAd.value = data['showBannerAd'] as bool? ?? AdConfig.showBannerAd;
        showNativeAd.value = data['showNativeAd'] as bool? ?? AdConfig.showNativeAd;
        showInterstitialAd.value = data['showInterstitialAd'] as bool? ?? AdConfig.showInterstitialAd;
        showRewardedAd.value = data['showRewardedAd'] as bool? ?? AdConfig.showRewardedAd;
        showAppOpenAd.value = data['showAppOpenAd'] as bool? ?? AdConfig.showAppOpenAd;
        interstitialCooldownSeconds.value =
            (data['interstitialCooldownSeconds'] as num?)?.toInt() ??
            AdConfig.interstitialCooldownSeconds;
      } else {
        // Fall back to current in-memory AdConfig values
        adNetwork.value = AdConfig.adNetwork;
        showBannerAd.value = AdConfig.showBannerAd;
        showNativeAd.value = AdConfig.showNativeAd;
        showInterstitialAd.value = AdConfig.showInterstitialAd;
        showRewardedAd.value = AdConfig.showRewardedAd;
        showAppOpenAd.value = AdConfig.showAppOpenAd;
        interstitialCooldownSeconds.value = AdConfig.interstitialCooldownSeconds;
      }

      // Load api_config
      final apiSnap = await _db.child('api_config').get();
      if (apiSnap.exists && apiSnap.value is Map) {
        final data = Map<String, dynamic>.from(apiSnap.value as Map);
        geminiApiKeyCtrl.text = data['geminiApiKey']?.toString() ?? '';
        geminiModelCtrl.text = data['geminiModel']?.toString() ?? '';
        analysisPromptCtrl.text = data['analysisPrompt']?.toString() ?? '';
        playStoreUrlCtrl.text = data['playStoreUrl']?.toString() ?? '';
        appStoreUrlCtrl.text = data['appStoreUrl']?.toString() ?? '';
        privacyPolicyUrlCtrl.text = data['privacyPolicyUrl']?.toString() ?? '';
        termsOfServiceUrlCtrl.text = data['termsOfServiceUrl']?.toString() ?? '';
      } else {
        try {
          final appConfig = Get.find<AppConfigService>();
          geminiApiKeyCtrl.text = appConfig.geminiApiKey.value;
          geminiModelCtrl.text = appConfig.geminiModel.value;
          analysisPromptCtrl.text = appConfig.analysisPrompt.value;
          playStoreUrlCtrl.text = appConfig.playStoreUrl.value;
          appStoreUrlCtrl.text = appConfig.appStoreUrl.value;
          privacyPolicyUrlCtrl.text = appConfig.privacyPolicyUrl.value;
          termsOfServiceUrlCtrl.text = appConfig.termsOfServiceUrl.value;
        } catch (e) {
          debugPrint('AdminPanel: AppConfigService not found: $e');
        }
      }
    } catch (e) {
      debugPrint('AdminPanel: Error loading config: $e');
      statusMessage.value = 'Failed to load config: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAdConfig() async {
    isSaving.value = true;
    statusMessage.value = '';
    try {
      final data = {
        'adNetwork': adNetwork.value,
        'showBannerAd': showBannerAd.value,
        'showNativeAd': showNativeAd.value,
        'showInterstitialAd': showInterstitialAd.value,
        'showRewardedAd': showRewardedAd.value,
        'showAppOpenAd': showAppOpenAd.value,
        'interstitialCooldownSeconds': interstitialCooldownSeconds.value,
      };
      await _db.child('ad_config').update(data);

      // Apply locally so current session reflects the change immediately
      AdConfig.fromJson(data);

      statusMessage.value = 'Ad config saved!';
      Get.snackbar(
        'Saved',
        'Ad config updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('AdminPanel: Error saving ad config: $e');
      statusMessage.value = 'Save failed: $e';
      Get.snackbar(
        'Error',
        'Failed to save: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveApiConfig() async {
    isSaving.value = true;
    statusMessage.value = '';
    try {
      final data = <String, dynamic>{};
      final key = geminiApiKeyCtrl.text.trim();
      final model = geminiModelCtrl.text.trim();
      final prompt = analysisPromptCtrl.text.trim();
      final playStore = playStoreUrlCtrl.text.trim();
      final appStore = appStoreUrlCtrl.text.trim();
      final privacy = privacyPolicyUrlCtrl.text.trim();
      final terms = termsOfServiceUrlCtrl.text.trim();

      if (key.isNotEmpty) data['geminiApiKey'] = key;
      if (model.isNotEmpty) data['geminiModel'] = model;
      if (prompt.isNotEmpty) data['analysisPrompt'] = prompt;
      if (playStore.isNotEmpty) data['playStoreUrl'] = playStore;
      if (appStore.isNotEmpty) data['appStoreUrl'] = appStore;
      if (privacy.isNotEmpty) data['privacyPolicyUrl'] = privacy;
      if (terms.isNotEmpty) data['termsOfServiceUrl'] = terms;

      if (data.isEmpty) {
        Get.snackbar('Info', 'Nothing to save', snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16), borderRadius: 12);
        return;
      }

      await _db.child('api_config').update(data);

      // Apply locally
      try {
        final appConfig = Get.find<AppConfigService>();
        if (key.isNotEmpty) appConfig.geminiApiKey.value = key;
        if (model.isNotEmpty) appConfig.geminiModel.value = model;
        if (prompt.isNotEmpty) appConfig.analysisPrompt.value = prompt;
        if (playStore.isNotEmpty) appConfig.playStoreUrl.value = playStore;
        if (appStore.isNotEmpty) appConfig.appStoreUrl.value = appStore;
        if (privacy.isNotEmpty) appConfig.privacyPolicyUrl.value = privacy;
        if (terms.isNotEmpty) appConfig.termsOfServiceUrl.value = terms;
      } catch (e) {
        debugPrint('AdminPanel: AppConfigService update skipped: $e');
      }

      statusMessage.value = 'API config saved!';
      Get.snackbar(
        'Saved',
        'API config updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('AdminPanel: Error saving api config: $e');
      Get.snackbar(
        'Error',
        'Failed to save: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
