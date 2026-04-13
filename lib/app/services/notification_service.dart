/// Notification Service
/// Handles Firebase Cloud Messaging (FCM) for push notifications
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_service.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('NotificationService: Background message received: ${message.messageId}');
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS requires explicit request; Android 13+ also needs it)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('NotificationService: Permission granted');
      await _getAndSaveToken();
      _subscribeToTopics();
    } else {
      debugPrint('NotificationService: Permission denied');
      return;
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('NotificationService: FCM Token = $token');
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('NotificationService: error getting FCM token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      if (!Get.isRegistered<AuthService>()) return;
      final uid = AuthService.to.currentUser?.uid;
      if (uid == null) return;
      await _dbRef.child('users').child(uid).child('fcmToken').set(token);
      debugPrint('NotificationService: Token saved to Firebase');
    } catch (e) {
      debugPrint('NotificationService: error saving token: $e');
    }
  }

  void _subscribeToTopics() {
    _messaging.subscribeToTopic('all_users');
    debugPrint('NotificationService: Subscribed to all_users topic');

    // Subscribe to premium/free topic based on subscription status
    if (Get.isRegistered<AuthService>()) {
      // Topic subscription updates handled by auth/subscription state changes
    }
  }

  /// Subscribe user to premium topic (call when user purchases subscription)
  Future<void> subscribeToPremiumTopic() async {
    await _messaging.subscribeToTopic('premium_users');
    await _messaging.unsubscribeFromTopic('free_users');
    debugPrint('NotificationService: Subscribed to premium_users topic');
  }

  /// Subscribe user to free topic (call when subscription expires)
  Future<void> subscribeToFreeTopic() async {
    await _messaging.subscribeToTopic('free_users');
    await _messaging.unsubscribeFromTopic('premium_users');
    debugPrint('NotificationService: Subscribed to free_users topic');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: Foreground message: ${message.notification?.title}');
    // Show in-app notification banner
    final notification = message.notification;
    if (notification != null && Get.context != null) {
      Get.snackbar(
        notification.title ?? 'ChartSense AI',
        notification.body ?? '',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.95),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.notifications_rounded, color: Colors.white),
      );
    }
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('NotificationService: Notification tapped: ${message.data}');
    // Handle navigation based on notification data
    final data = message.data;
    if (data['route'] != null) {
      Get.toNamed(data['route'], arguments: data['args']);
    }
  }
}
