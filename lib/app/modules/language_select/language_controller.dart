/// Language Controller
/// Manages language selection and persistence
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../translations/app_translations.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class LanguageController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final Rx<Locale?> selectedLocale = Rx<Locale?>(null);

  List<LanguageInfo> get languages => AppTranslations.languages;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final savedLang = _storage.savedLanguage;
    if (savedLang != null) {
      final parts = savedLang.split('_');
      if (parts.length == 2) {
        selectedLocale.value = Locale(parts[0], parts[1]);
      }
    }
  }

  void selectLanguage(LanguageInfo language) {
    selectedLocale.value = language.locale;
    Get.updateLocale(language.locale);
    _storage.savedLanguage = language.localeString;
  }

  void continueToNextScreen() {
    if (selectedLocale.value != null) {
      // If user has already completed first launch (coming from settings), just go back
      if (!_storage.isFirstLaunch) {
        Get.back();
        return;
      }
      
      // First time launch flow
      _storage.isFirstLaunch = false;

      if (!_storage.hasSeenIntro) {
        Get.offNamed(AppRoutes.intro);
      } else {
        // Enforce mandatory login
        final bool isLoggedIn = Get.find<AuthService>().isLoggedIn;
        if (isLoggedIn) {
          Get.offNamed(AppRoutes.home);
        } else {
          Get.offNamed(AppRoutes.login);
        }
      }
    } else {
      Get.snackbar(
        'error'.tr,
        'select_language'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  bool isSelected(LanguageInfo language) {
    return selectedLocale.value?.languageCode == language.locale.languageCode &&
        selectedLocale.value?.countryCode == language.locale.countryCode;
  }
}
