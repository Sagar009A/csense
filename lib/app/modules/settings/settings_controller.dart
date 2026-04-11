/// Settings Controller
/// Manages app settings including theme, language, rating, and sharing
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/app_config_service.dart';
import '../../services/consent_service.dart';
import '../../core/constants/api_constants.dart';
import '../../translations/app_translations.dart';
import '../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final InAppReview _inAppReview = InAppReview.instance;
  AppConfigService? _appConfig;

  final RxInt themeMode = 0.obs; // 0: system, 1: light, 2: dark
  Rx<Locale?> currentLocale = Rx<Locale?>(null);

  // User info
  bool get isLoggedIn {
    try {
      return Get.find<AuthService>().isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  String? get userEmail {
    try {
      return Get.find<AuthService>().userEmail;
    } catch (e) {
      return null;
    }
  }

  String? get displayName {
    try {
      return Get.find<AuthService>().displayName;
    } catch (e) {
      return null;
    }
  }

  int get credits {
    try {
      return Get.find<CreditService>().credits.value;
    } catch (e) {
      return 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    _tryLoadAppConfig();
    // Ensure AppConfigService is always available and refresh when URLs change
    try {
      final appConfig = Get.find<AppConfigService>();
      ever(appConfig.privacyPolicyUrl, (_) {
        _tryLoadAppConfig();
      });
      ever(appConfig.termsOfServiceUrl, (_) {
        _tryLoadAppConfig();
      });
    } catch (e) {
      debugPrint(
        'SettingsController: AppConfigService not found in onInit: $e',
      );
    }
  }

  void loadSettings() {
    themeMode.value = _storage.themeMode;

    final savedLang = _storage.savedLanguage;
    if (savedLang != null) {
      final parts = savedLang.split('_');
      if (parts.length == 2) {
        currentLocale.value = Locale(parts[0], parts[1]);
      }
    }
  }

  void _tryLoadAppConfig() {
    try {
      _appConfig = Get.find<AppConfigService>();
      debugPrint('SettingsController: AppConfigService loaded successfully');
      debugPrint(
        'SettingsController: Privacy Policy URL = ${_appConfig?.privacyPolicyUrl.value}',
      );
      debugPrint(
        'SettingsController: T&C URL = ${_appConfig?.termsOfServiceUrl.value}',
      );
    } catch (e) {
      debugPrint('SettingsController: AppConfigService not found: $e');
      _appConfig = null;
    }
  }

  String _resolveUrl(String remoteValue, String fallback) {
    final url = remoteValue.trim();
    return url.isNotEmpty ? url : fallback;
  }

  ThemeMode get currentThemeMode {
    switch (themeMode.value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(int mode) {
    themeMode.value = mode;
    _storage.themeMode = mode;

    // Update app theme
    Get.changeThemeMode(currentThemeMode);
  }

  String get currentLanguageName {
    if (currentLocale.value == null) return 'English';

    final langInfo = AppTranslations.languages.firstWhereOrNull(
      (l) => l.locale.languageCode == currentLocale.value!.languageCode,
    );
    return langInfo?.nativeName ?? 'English';
  }

  void openLanguageSettings() {
    Get.toNamed(AppRoutes.languageSelect);
  }

  void openPurchaseScreen() {
    AuthService.to.openPurchaseScreenIfAllowed();
  }

  Future<void> logout() async {
    try {
      final authService = Get.find<AuthService>();
      await authService.signOut();

      // Clear local storage data (history)
      _storage.clearHistory();

      // Clear credit data
      try {
        Get.find<CreditService>().clearUser();
      } catch (e) {
        // Ignore if credit service not found
      }

      // Navigate to login
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      final authService = Get.find<AuthService>();
      final uid = authService.userId;
      if (uid == null) return;

      // Delete user data from Firebase RTDB
      try {
        await FirebaseDatabase.instance.ref().child('users').child(uid).remove();
      } catch (e) {
        debugPrint('Delete user RTDB data error: $e');
      }

      // Delete Firebase Auth account
      final deleted = await authService.deleteAccount();
      if (!deleted) {
        final msg = authService.errorMessage.value;
        Get.snackbar(
          'Error',
          msg.isNotEmpty ? msg : 'Failed to delete account',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withAlpha(200),
          colorText: Colors.white,
        );
        return;
      }

      // Clear local data
      _storage.clearHistory();
      try { Get.find<CreditService>().clearUser(); } catch (_) {}

      Get.snackbar(
        'delete_account'.tr,
        'delete_account_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(200),
        colorText: Colors.white,
      );

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
    }
  }

  Future<void> rateApp() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        // Open store directly
        final config = _appConfig;
        final url = Platform.isIOS
            ? _resolveUrl(
                config?.appStoreUrl.value ?? '',
                ApiConstants.appStoreUrl,
              )
            : _resolveUrl(
                config?.playStoreUrl.value ?? '',
                ApiConstants.playStoreUrl,
              );
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void shareApp() {
    final config = _appConfig;
    final storeUrl = Platform.isIOS
        ? _resolveUrl(
            config?.appStoreUrl.value ?? '',
            ApiConstants.appStoreUrl,
          )
        : _resolveUrl(
            config?.playStoreUrl.value ?? '',
            ApiConstants.playStoreUrl,
          );
    final message = 'share_message'.tr + storeUrl;
    SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> openMoreApps() async {
    try {
      final config = _appConfig;
      String url;
      if (Platform.isIOS) {
        final iosUrl = config?.moreAppsUrlIOS.value ?? '';
        url = iosUrl.isNotEmpty
            ? iosUrl
            : _resolveUrl(config?.appStoreUrl.value ?? '', ApiConstants.appStoreUrl);
      } else {
        url = _resolveUrl(config?.moreAppsUrl.value ?? '', ApiConstants.moreAppsUrl);
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> openPrivacyPolicy() async {
    _tryLoadAppConfig();

    try {
      final config = _appConfig ?? Get.find<AppConfigService>();
      String url;
      if (Platform.isIOS) {
        final iosUrl = config.privacyPolicyUrlIOS.value.trim();
        url = iosUrl.isNotEmpty ? iosUrl : config.privacyPolicyUrl.value.trim();
      } else {
        url = config.privacyPolicyUrl.value.trim();
      }

      if (url.isEmpty) {
        url = ApiConstants.privacyPolicyUrl;
      }

      debugPrint('SettingsController: Opening Privacy Policy URL: $url');

      if (url.isEmpty) {
        Get.snackbar(
          'Info',
          'Privacy Policy URL not configured. Please set it in admin panel under API Config.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid URL format: $url');
      }

      Get.toNamed(
        AppRoutes.legalWebView,
        arguments: {'url': url, 'title': 'privacy_policy'.tr},
      );
    } catch (e) {
      debugPrint('SettingsController: Error opening Privacy Policy: $e');
      Get.snackbar(
        'Error',
        'Failed to open Privacy Policy: ${e.toString()}. Please check the URL in admin panel.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> openTermsOfService() async {
    _tryLoadAppConfig();

    try {
      final config = _appConfig ?? Get.find<AppConfigService>();
      String url;
      if (Platform.isIOS) {
        final iosUrl = config.termsOfServiceUrlIOS.value.trim();
        url = iosUrl.isNotEmpty ? iosUrl : config.termsOfServiceUrl.value.trim();
      } else {
        url = config.termsOfServiceUrl.value.trim();
      }

      if (url.isEmpty) {
        url = ApiConstants.termsOfServiceUrl;
      }

      debugPrint('SettingsController: Opening Terms & Conditions URL: $url');

      if (url.isEmpty) {
        Get.snackbar(
          'Info',
          'Terms & Conditions URL not configured. Please set it in admin panel under API Config.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid URL format: $url');
      }

      Get.toNamed(
        AppRoutes.legalWebView,
        arguments: {'url': url, 'title': 'terms_of_service'.tr},
      );
    } catch (e) {
      debugPrint('SettingsController: Error opening Terms & Conditions: $e');
      Get.snackbar(
        'Error',
        'Failed to open Terms & Conditions: ${e.toString()}. Please check the URL in admin panel.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Opens Ad consent / Privacy options (for EEA users to change consent)
  Future<void> openAdConsentOptions() async {
    await ConsentService.instance.showPrivacyOptionsForm();
  }
}
