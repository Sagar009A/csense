/// App Pages
/// Defines all routes and page bindings
library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app_routes.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/splash/splash_controller.dart';
import '../modules/intro/intro_screen.dart';
import '../modules/intro/intro_controller.dart';
import '../modules/language_select/language_select_screen.dart';
import '../modules/language_select/language_controller.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/home/home_screen.dart';
import '../modules/home/home_controller.dart';
import '../modules/analysis/analysis_screen.dart';
import '../modules/analysis/analysis_controller.dart';
import '../modules/history/history_screen.dart';
import '../modules/history/history_controller.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/settings/settings_controller.dart';
import '../modules/purchase/purchase_screen.dart';
import '../modules/purchase/purchase_controller.dart';
import '../services/subscription_service.dart';
import '../modules/video/video_controller.dart';
import '../modules/video/video_player_screen.dart';
import '../modules/video/terabox/button_screen.dart';
import '../modules/video/terabox/player_screen.dart';
import '../modules/web_preview/web_preview_screen.dart';
import '../modules/legal_webview/legal_webview_screen.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SplashController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.intro,
      page: () => const IntroScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IntroController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.languageSelect,
      page: () => const LanguageSelectScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LanguageController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController());
        Get.lazyPut(() => HistoryController());
        Get.lazyPut(() => SettingsController());
        Get.lazyPut(() => VideoController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.analysis,
      page: () => const AnalysisScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AnalysisController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HistoryController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SettingsController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.purchase,
      page: () => const PurchaseScreen(),
      binding: BindingsBuilder(() {
        // Ensure SubscriptionService is always available — it may not be
        // registered when navigating from deep-link paths (e.g. video player).
        if (!Get.isRegistered<SubscriptionService>()) {
          final svc = SubscriptionService();
          Get.put(svc, permanent: true);
          svc.init().catchError((e) {
            debugPrint('SubscriptionService init error: $e');
            return svc;
          });
        }
        Get.lazyPut(() => PurchaseController());
      }),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.videoPlayer,
      page: () => const VideoPlayerScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.teraboxButton,
      page: () {
        // Read shortCode from arguments (normal nav) or GetStorage (deep link initial route)
        var shortCode = Get.arguments as String? ?? '';
        if (shortCode.isEmpty) {
          shortCode = GetStorage().read<String>('pending_deep_link_short_code') ?? '';
          // Clean up after reading
          GetStorage().remove('pending_deep_link_short_code');
        }
        print("312321321321231=====${shortCode}");
        return TeraBoxButtonScreen(shortCode: shortCode);
      },
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.teraboxPlayer,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        return TeraBoxPlayerScreen(
          videoUrl: args['videoUrl'] as String? ?? '',
          title: args['title'] as String? ?? 'Untitled Video',
          username: args['username'] as String? ?? 'Unknown',
          shortCode: args['shortCode'] as String? ?? '',
          fileSize: args['fileSize'] as String? ?? '0',
          createdAt: args['createdAt'] as String? ?? DateTime.now().toIso8601String(),
          userAvatarUrl: args['userAvatarUrl'] as String? ?? '',
          subtitleUrl: args['subtitleUrl'] as String?,
          streamUrls: args['streamUrls'] != null ? Map<String, dynamic>.from(args['streamUrls'] as Map) : null,
          downloadLink: args['downloadLink'] as String?,
          normalDownloadLink: args['normalDownloadLink'] as String?,
          streamDownloadUrl: args['streamDownloadUrl'] as String?,
          originalUrl: args['originalUrl'] as String?,
        );
      },
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.webPreview,
      page: () => const WebPreviewScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.legalWebView,
      page: () {
        final args = Get.arguments as Map<String, String>?;
        return LegalWebViewScreen(
          url: args?['url'] ?? '',
          title: args?['title'] ?? '',
        );
      },
      transition: Transition.rightToLeft,
    ),
  ];
}
