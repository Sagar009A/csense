library;
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/core/constants/api_constants.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'app/translations/app_translations.dart'; 
import 'app/services/storage_service.dart';
import 'app/services/ad_service.dart';
import 'app/modules/splash/splash_screen.dart';
import 'app/modules/splash/splash_controller.dart';
import 'app/globals.dart';

// Main entry point
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Setup error widget for release mode
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.deepPurple,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Runtime Error:\n${details.exception}\n${details.stack}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    };

    runApp(const AppBootstrapper());
  }, (error, stack) {
    debugPrint('Global Error: $error');
    debugPrint('Stack Trace: $stack');
  });
}

String? _extractTeraBoxShortCode(Uri uri) {
  if (!ApiConstants.deepLinkHosts.contains(uri.host.toLowerCase())) return null;
  final path = uri.path;
  if (path.isEmpty || path == '/') return null;
  final segment = path.startsWith('/') ? path.substring(1) : path;
  final trimmed = segment.split('/').first.trim();
  return trimmed.isEmpty ? null : trimmed;
}

// AppBootstrapper to handle async initialization
class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // 1. Core Services
      await ScreenUtil.ensureScreenSize();
      await GetStorage.init();
      await Get.putAsync(() => StorageService().init());

      // 2. Deep Link Handling (fast timeout to avoid blocking app startup)
      try {
        final uri = await AppLinks().getInitialLink()
            .timeout(const Duration(seconds: 1), onTimeout: () => null);
        if (uri != null) {
          final shortCode = _extractTeraBoxShortCode(uri);
          if (shortCode != null && shortCode.isNotEmpty) {
            pendingInitialDeepLink = shortCode;
            initialDeepLinkHandled = true;
            await GetStorage().write('pending_deep_link_short_code', shortCode);
          }
        }
      } catch (_) {
        // Ignore deep link errors during init
      }

      // 3. System UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint('Initialization Error: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error if initialization failed
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  'Initialization Error:\n$_error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show loading while initializing
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    // Show main app once initialized
    return const MyApp();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Listen for deep links while app is running (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // On iOS cold start, app_links fires the same link via BOTH
    // getInitialLink() AND uriLinkStream. Skip if already captured.
    if (initialDeepLinkHandled) {
      initialDeepLinkHandled = false;
      debugPrint('Deep link: skipping duplicate initial link (iOS)');
      return;
    }

    final shortCode = _extractTeraBoxShortCode(uri);
    if (shortCode != null && shortCode.isNotEmpty) {
      try {
        // Navigate to the video player with the short code
        Get.toNamed(AppRoutes.teraboxButton, arguments: shortCode);
      } catch (e) {
        debugPrint('Deep link navigation error: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Show app open ad when app comes to foreground (only if AdService is ready)
    if (state == AppLifecycleState.resumed) {
      try {
        if (Get.isRegistered<AdService>()) {
          AdService.to.showAppOpenAd();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();

    // Determine initial theme mode
    ThemeMode themeMode;
    switch (storageService.themeMode) {
      case 1:
        themeMode = ThemeMode.light;
        break;
      case 2:
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    // Determine initial locale
    Locale? locale;
    final savedLang = storageService.savedLanguage;
    if (savedLang != null) {
      final parts = savedLang.split('_');
      if (parts.length == 2) {
        locale = Locale(parts[0], parts[1]);
      }
    }

    return ScreenUtilInit(
      designSize: const Size(393, 852), // iPhone 14 Pro design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'ChartSense AI',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Localization
          translations: AppTranslations(),
          locale: locale ?? AppTranslations.fallbackLocale,
          fallbackLocale: AppTranslations.fallbackLocale,

          // Navigation: always start with Splash (handles deep links internally)
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,

          // Fallback: deep link URLs (e.g. https://teraboxurll.in/abc,
          // https://linkstreamx.in/abc, https://linkstreamx.one/abc) may be
          // passed by Android as the initial route.  Without a fallback GetX
          // crashes with "Null check operator used on a null value" in
          // PageRedirect.page because no GetPage matches the URL.
          unknownRoute: GetPage(
            name: '/notfound',
            page: () => const SplashScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SplashController());
            }),
          ),

          // Default transition (fast fade for snappy feel)
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 200),

          // Builder for responsive text scaling and RTL support
          builder: (context, widget) {
            final mediaQueryData = MediaQuery.of(context);
            final scaleFactor = mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            );
            final locale = Get.locale;
            final isRTL = locale != null &&
                (locale.languageCode == 'ar' || locale.languageCode == 'ur');
            final textDirection =
                isRTL ? TextDirection.rtl : TextDirection.ltr;
            return Directionality(
              textDirection: textDirection,
              child: MediaQuery(
                data: mediaQueryData.copyWith(textScaler: scaleFactor),
                child: widget!,
              ),
            );
          },
        );
      },
    );
  }
}
