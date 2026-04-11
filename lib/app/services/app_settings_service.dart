/// App Settings Service
/// Loads app settings like maintenance mode and force update
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

/// Country/region codes where ad consent (EEA/UK) is legally required.
/// Ad consent & privacy option is shown only in these regions when admin enables it.
const Set<String> _adConsentRequiredCountryCodes = {
  'AT',
  'BE',
  'BG',
  'HR',
  'CY',
  'CZ',
  'DK',
  'EE',
  'FI',
  'FR',
  'DE',
  'GR',
  'HU',
  'IE',
  'IT',
  'LV',
  'LT',
  'LU',
  'MT',
  'NL',
  'PL',
  'PT',
  'RO',
  'SK',
  'SI',
  'ES',
  'SE',
  'IS',
  'LI',
  'NO',
  'GB',
  'UK',
};

class AppSettingsService extends GetxService {
  static AppSettingsService get to => Get.find<AppSettingsService>();

  final RxString appName = ''.obs;
  final RxString appVersion = ''.obs;
  final RxBool maintenanceMode = false.obs;
  final RxString maintenanceMessage = ''.obs;
  final RxString forceUpdateVersion = ''.obs;
  final RxString forceUpdateMessage = ''.obs;
  final RxBool showAdConsentOption = true.obs;

  /// True if device region is one where ad consent is required (EEA/UK).
  bool get isInAdConsentRequiredRegion {
    final code = Get.deviceLocale?.countryCode;
    if (code == null || code.isEmpty) return false;
    return _adConsentRequiredCountryCodes.contains(code.toUpperCase());
  }

  /// Show "Ad consent & privacy options" only when admin enabled it AND user is in EEA/UK.
  bool get shouldShowAdConsentOption =>
      showAdConsentOption.value && isInAdConsentRequiredRegion;

  Future<AppSettingsService> init() async {
    await _fetchSettings();
    return this;
  }

  Future<void> _fetchSettings() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('app_settings')
          .get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _applySettings(data);
        debugPrint('AppSettings: Loaded app_settings');
      } else {
        debugPrint('AppSettings: No app_settings found');
      }
    } catch (e) {
      debugPrint('AppSettings: Failed to load app_settings: $e');
    }
  }

  void _applySettings(Map<String, dynamic> data) {
    _setIfNotEmpty(appName, data['appName']);
    _setIfNotEmpty(appVersion, data['appVersion']);
    maintenanceMode.value = data['maintenanceMode'] == true;
    _setIfNotEmpty(maintenanceMessage, data['maintenanceMessage']);
    // Normalize to string so Firebase number/string both work
    final fv = data['forceUpdateVersion'];
    _setIfNotEmpty(forceUpdateVersion, fv != null ? fv.toString().trim() : '');
    _setIfNotEmpty(forceUpdateMessage, data['forceUpdateMessage']);
    if (data.containsKey('showAdConsentOption')) {
      showAdConsentOption.value = data['showAdConsentOption'] == true;
    }
  }

  bool isForceUpdateRequired(String currentVersion) {
    final requiredVersion = forceUpdateVersion.value.trim();
    if (requiredVersion.isEmpty) return false;
    final current = currentVersion.trim();
    if (current.isEmpty) return true;
    return _compareVersion(current, requiredVersion) < 0;
  }

  int _compareVersion(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);
    final maxLen = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;
    for (var i = 0; i < maxLen; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) {
        return aVal.compareTo(bVal);
      }
    }
    return 0;
  }

  List<int> _parseVersion(String version) {
    final sanitized = version.split('+').first.split('-').first;
    return sanitized
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }

  void _setIfNotEmpty(RxString target, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      target.value = text;
    }
  }
}
