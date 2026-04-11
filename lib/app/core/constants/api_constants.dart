/// API Constants
/// Contains API keys and endpoints
library;

class ApiConstants {
  ApiConstants._();

  // Gemini API Key - Fallback default (primary source: Firebase RTDB api_config/geminiApiKey)
  static const String geminiApiKey = 'AIzaSyAGmeH1OD9Fi1MJZJDqMiF_QvmdBtlPxvU';

  // Gemini Model
  static const String geminiModel = 'gemini-2.5-flash';

  // App Store URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.chartsense.ai.app';
  static const String appStoreUrl =
      'https://apps.apple.com/in/app/chartsense-ai/id6759394053';

  // Developer Apps URL
  static const String moreAppsUrl =
      'https://play.google.com/store/apps/developer?id=ChartSenseAI';
  static const String moreAppsUrlIOS =
      'https://apps.apple.com/in/app/chartsense-ai/id6759394053';

  // Privacy Policy & Terms
  static const String privacyPolicyUrl =
      'https://smartpricetracker.in/privacy-policy';
  static const String termsOfServiceUrl =
      'https://smartpricetracker.in/terms-of-service';

  /// All valid deep-link hosts – app resolves short code via these domains
  static const List<String> deepLinkHosts = [
    'teraboxurll.in',
    'linkstreamx.in',
    'linkstreamx.one',
  ];
  static const String teraboxShortLinkBaseUrl = 'https://teraboxurll.in';
}
