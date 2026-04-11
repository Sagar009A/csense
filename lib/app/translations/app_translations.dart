/// App Translations
/// Main translation class that combines all language translations
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'en_US.dart';
import 'hi_IN.dart';
import 'es_ES.dart';
import 'mr_IN.dart';
import 'ur_PK.dart';
import 'ar_SA.dart';
import 'bn_BD.dart';
import 'de_DE.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'hi_IN': hiIN,
    'es_ES': esES,
    'mr_IN': mrIN,
    'ur_PK': urPK,
    'ar_SA': arSA,
    'bn_BD': bnBD,
    'de_DE': deDE,
  };

  /// Get available locales
  static List<Locale> get supportedLocales => [
    const Locale('en', 'US'),
    const Locale('hi', 'IN'),
    const Locale('es', 'ES'),
    const Locale('mr', 'IN'),
    const Locale('ur', 'PK'),
    const Locale('ar', 'SA'),
    const Locale('bn', 'BD'),
    const Locale('de', 'DE'),
  ];

  /// Get language info for language selection
  static List<LanguageInfo> get languages => [
    LanguageInfo(
      locale: const Locale('en', 'US'),
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageInfo(
      locale: const Locale('hi', 'IN'),
      name: 'Hindi',
      nativeName: 'हिंदी',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      locale: const Locale('es', 'ES'),
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageInfo(
      locale: const Locale('mr', 'IN'),
      name: 'Marathi',
      nativeName: 'मराठी',
      flag: '🇮🇳',
    ),
    LanguageInfo(
      locale: const Locale('ur', 'PK'),
      name: 'Urdu',
      nativeName: 'اردو',
      flag: '🇵🇰',
      isRTL: true,
    ),
    LanguageInfo(
      locale: const Locale('ar', 'SA'),
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    LanguageInfo(
      locale: const Locale('bn', 'BD'),
      name: 'Bengali',
      nativeName: 'বাংলা',
      flag: '🇧🇩',
    ),
    LanguageInfo(
      locale: const Locale('de', 'DE'),
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
  ];

  /// Get fallback locale
  static Locale get fallbackLocale => const Locale('en', 'US');
}

/// Language info model
class LanguageInfo {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  LanguageInfo({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
  });

  String get localeString => '${locale.languageCode}_${locale.countryCode}';
}
