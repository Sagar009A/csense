/// Splash Controller
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../services/storage_service.dart';
import '../../services/app_config_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/ad_service.dart';
import '../../services/consent_service.dart';
import '../../services/video_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/subscription_service.dart';
import '../../services/security_service.dart';
import '../../routes/app_routes.dart';

import '../../../../app/globals.dart'; // Access global pendingInitialDeepLink

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ... (existing firebase options)
  static const FirebaseOptions _firebaseOptions = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    databaseURL: '',
    storageBucket: '',
  );

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  Future<void>? _firebaseInitFuture;
  bool _firebaseInitialized = false;

  /// Guard: prevents _performNavigation from firing more than once.
  bool _hasNavigated = false;

  /// Deep link short code
  String? _pendingShortCode;

  /// True when opened via teraboxurll.in deep link.
  bool get isDirectLinkLaunch =>
      _pendingShortCode != null && _pendingShortCode!.isNotEmpty;

  final StorageService _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();

    // 1. Try Global Variable (from AppBootstrapper)
    // 2. Try GetStorage (persistence backup)
    _pendingShortCode =
        pendingInitialDeepLink ??
        GetStorage().read<String>('pending_deep_link_short_code');

    _setupAnimations();

    if (isDirectLinkLaunch) {
      // Deep link: skip ALL heavy service init.
      // ButtonScreen will init its own services via _initCoreServicesIfNeeded().
      // Just wait for splash to be fully built, then navigate.
      _navigateToDeepLinkVideo();
    } else {
      _initializeServicesAndNavigate();
    }
  }

  void _setupAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    animationController.forward();
  }

  /// Deep link fast-path: wait for splash to be fully rendered, then navigate.
  /// No heavy service init here — ButtonScreen handles its own bootstrap.
  void _navigateToDeepLinkVideo() {
    final code = _pendingShortCode!;

    // Clear storage/globals so it doesn't trigger again on next normal launch
    // BUT keep _pendingShortCode set so isDirectLinkLaunch returns true
    // for SplashScreen.build() — shows "Opening video..." UI.
    GetStorage().remove('pending_deep_link_short_code');
    pendingInitialDeepLink = null; // Clear global

    // Use SchedulerBinding to guarantee we're past the very first build frame,
    // then add a minimal delay so the element tree is settled.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_hasNavigated) return;
        _hasNavigated = true;
        _pendingShortCode = null; // Clear after navigation guard is set

        if (animationController.isAnimating) {
          animationController.stop();
        }

        try {
          Get.offNamed(AppRoutes.teraboxButton, arguments: code);
        } catch (e) {
          debugPrint('Deep link navigation failed: $e');
        }
      });
    });

    // Safety timeout: if navigation hasn't happened after 3s, force it
    Future.delayed(const Duration(seconds: 3), () {
      if (_hasNavigated) return;
      _hasNavigated = true;
      _pendingShortCode = null;
      if (animationController.isAnimating) {
        animationController.stop();
      }
      try {
        Get.offNamed(AppRoutes.teraboxButton, arguments: code);
      } catch (e) {
        debugPrint('Deep link safety timeout navigation failed: $e');
      }
    });
  }

  Future<void> _initializeServicesAndNavigate() async {
    try {
      // Initialize Security Service first
      await Get.putAsync(() => SecurityService().init());

      // Check if device is secure
      if (!SecurityService.to.isSecure()) {
        _showSecurityWarning();
        return;
      }

      try {
        if (Firebase.apps.isEmpty) {
          final hasInlineOptions =
              _firebaseOptions.apiKey.isNotEmpty &&
              _firebaseOptions.appId.isNotEmpty &&
              _firebaseOptions.messagingSenderId.isNotEmpty &&
              _firebaseOptions.projectId.isNotEmpty;

          // On web, Firebase requires explicit options; skip init if none provided
          if (kIsWeb && !hasInlineOptions) {
            debugPrint(
              'Splash: Web platform without Firebase options - skipping Firebase init',
            );
            _firebaseInitialized = false;
          } else if (hasInlineOptions) {
            _firebaseInitFuture ??= Firebase.initializeApp(
              options: _firebaseOptions,
            );
            await _firebaseInitFuture;
            _firebaseInitialized = true;
          } else {
            _firebaseInitFuture ??= Firebase.initializeApp();
            await _firebaseInitFuture;
            _firebaseInitialized = true;
          }
        } else {
          _firebaseInitialized = true;
        }
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          _firebaseInitialized = true;
        } else {
          debugPrint('Firebase initialization failed: $e');
          if (kIsWeb) {
            _firebaseInitialized = false;
          } else {
            throw Exception('Firebase init failed: $e');
          }
        }
      } catch (e) {
        debugPrint('Firebase initialization failed: $e');
        if (kIsWeb) {
          _firebaseInitialized = false;
        } else {
          throw Exception('Firebase init failed: $e');
        }
      }

      // Initialize core services
      Get.put(ImagePickerService());

      // Initialize Firebase-dependent services
      if (_firebaseInitialized) {
        // Load remote config and app settings in parallel (both depend on Firebase, not on each other)
        await Future.wait([
          Get.putAsync(() => AppConfigService().init()),
          Get.putAsync(() => AppSettingsService().init()),
        ]);

        // Note: GeminiService will be initialized lazily when user actually scans a stock chart

        // Enforce maintenance/force update before heavy services
        final canProceed = await _enforceAppRestrictions();
        if (!canProceed) {
          return;
        }

        // These lightweight services don't need await
        Get.put(VideoService());
        Get.put(CreditService());
        Get.put(AuthService());
      }

      // Subscription, Connectivity, Consent all independent - run in parallel
      await Future.wait([
        if (_firebaseInitialized)
          Get.putAsync(() => SubscriptionService().init()),
        Get.putAsync(() => ConnectivityService().init()),
        ConsentService.instance.requestConsentAndShowFormIfRequired(),
      ]);

      try {
        await Get.putAsync(() => AdService().init());
      } catch (e) {
        debugPrint('AdService init error: $e');
      }

      // No artificial delay - proceed immediately
      if (Get.isRegistered<AdService>()) {
        AdService.to.showAppOpenAd(onAdClosed: () => _performNavigation());
      } else {
        _performNavigation();
      }
    } catch (e) {
      debugPrint('Service initialization error: $e');
      _showErrorDialog(e.toString());
    }
  }

  Future<bool> _enforceAppRestrictions() async {
    final settings = Get.find<AppSettingsService>();

    if (settings.maintenanceMode.value) {
      _showMaintenanceDialog(settings.maintenanceMessage.value);
      return false;
    }

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version.trim();
    if (settings.isForceUpdateRequired(currentVersion)) {
      await _showForceUpdateDialog(settings.forceUpdateMessage.value);
      return false;
    }

    return true;
  }

  void _showErrorDialog(String error) {
    Get.dialog(
      AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(
          'Failed to initialize app services. Please check your connection and try again.\n\nError: $error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              _initializeServicesAndNavigate(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showSecurityWarning() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Security Alert'),
          ],
        ),
        content: const Text(
          'This app cannot run on modified or rooted devices for security reasons.\n\n'
          'Please use an unmodified device to ensure secure access to your data.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Exit the app
              Get.back();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showMaintenanceDialog(String message) {
    final body = message.isNotEmpty
        ? message
        : 'We are currently performing maintenance. Please try again later.';

    Get.dialog(
      AlertDialog(
        title: const Text('Maintenance Mode'),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showForceUpdateDialog(String message) async {
    // On Android, try native in-app update first (works when app is from Play Store)
    if (GetPlatform.isAndroid) {
      try {
        final updateInfo = await InAppUpdate.checkForUpdate();
        if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.success) {
            return; // App will restart after update
          }
          // If user denied or update failed, fall through to manual dialog
        }
      } catch (e) {
        debugPrint('InAppUpdate not available (e.g. not from Play): $e');
      }
    }

    final config = Get.find<AppConfigService>();
    final urlText = GetPlatform.isIOS
        ? config.appStoreUrl.value.trim()
        : config.playStoreUrl.value.trim();
    const fallbackPlay =
        'https://play.google.com/store/apps/details?id=com.chartsense.ai.app';
    const fallbackApp = 'https://apps.apple.com/in/app/chartsense-ai/id6759394053';
    final resolved = urlText.isNotEmpty
        ? urlText
        : (GetPlatform.isIOS ? fallbackApp : fallbackPlay);
    final url = Uri.tryParse(resolved);
    final body = message.isNotEmpty
        ? message
        : 'A new version is required. Please update to continue.';

    await Get.dialog(
      AlertDialog(
        title: const Text('Update Required'),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () async {
              if (url != null && url.isAbsolute) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _performNavigation() {
    // Guard: prevent double navigation
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Stop splash animation before navigating to avoid ticker/element conflicts
    if (animationController.isAnimating) {
      animationController.stop();
    }

    if (_storage.isFirstLaunch) {
      Get.offNamed(AppRoutes.languageSelect);
      return;
    }
    if (!_storage.hasSeenIntro) {
      Get.offNamed(AppRoutes.intro);
      return;
    }
    // On web without Firebase, show web preview (Home needs Firebase services)
    if (!_firebaseInitialized) {
      Get.offNamed(AppRoutes.webPreview);
      return;
    }
    final bool isLoggedIn = _isUserLoggedIn();
    if (!isLoggedIn) {
      Get.offNamed(AppRoutes.login);
    } else {
      Get.offNamed(AppRoutes.home);
    }
  }

  bool _isUserLoggedIn() {
    try {
      final authService = Get.find<AuthService>();
      return authService.isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
