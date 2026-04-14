/// Credit Service
/// Manages user credits in Firebase Realtime Database
library;

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'subscription_service.dart';

class CreditService extends GetxService {
  static CreditService get to => Get.find();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final RxInt credits = 0.obs;
  final RxBool isPremium = false.obs;
  final RxBool isSubscribed = false.obs;
  final RxBool isLoading = false.obs;

  // Plan bonus credits (tied to active subscription, expire with plan)
  final RxInt planCredits = 0.obs;
  final RxInt planCreditsExpiry = 0.obs; // millisecondsSinceEpoch, 0 = no expiry set

  /// True if plan credits are still within their validity window.
  bool get hasPlanCreditsActive {
    if (planCreditsExpiry.value == 0 || planCredits.value <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch < planCreditsExpiry.value;
  }

  String? _currentUserId;
  final List<StreamSubscription> _listeners = [];

  static const String _secretKey = 'stock_scanner_secure_key_2024';

  static const Map<String, int> _defaultPackages = {
    'credits_10': 10,
    'credits_50': 50,
    'credits_100': 100,
    'credits_200': 200,
    'credits_500': 500,
    'credits_1000': 1000,
  };

  /// Returns dynamic package map from SubscriptionService if available,
  /// otherwise falls back to hardcoded defaults.
  static Map<String, int> get packages {
    try {
      if (Get.isRegistered<SubscriptionService>()) {
        final dynamic = SubscriptionService.to.creditPackAmounts;
        if (dynamic.isNotEmpty) return dynamic;
      }
    } catch (_) {}
    return _defaultPackages;
  }

  // Initialize user credits in database (called on first login)
  /// [isGuest] true for anonymous/guest users (shown in admin panel).
  Future<void> initializeUserCredits(String userId, String email, {bool isGuest = false}) async {
    _currentUserId = userId;

    try {
      final userRef = _dbRef.child('users').child(userId);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'email': email,
          'credits': 0,
          'isPremium': false,
          'isGuest': isGuest,
          'createdAt': ServerValue.timestamp,
        });
        credits.value = 0;
        isPremium.value = false;
      } else {
        final data = snapshot.value as Map<dynamic, dynamic>;
        credits.value = (data['credits'] as num?)?.toInt() ?? 0;
        isPremium.value = (data['isPremium'] as bool?) ?? false;

        // Load plan credits and check expiry
        final pce = (data['planCreditsExpiry'] as num?)?.toInt() ?? 0;
        final pc = (data['planCredits'] as num?)?.toInt() ?? 0;
        planCreditsExpiry.value = pce;
        planCredits.value = pc;

        // Auto-clear expired plan credits
        if (pc > 0 && pce > 0 &&
            DateTime.now().millisecondsSinceEpoch >= pce) {
          await _clearPlanCreditsInFirebase();
        }
      }

      // Listen for credit changes in real-time
      _listenToUserUpdates(userId);
    } catch (e) {
      debugPrint('Error initializing credits: $e');
    }
  }

  void _cancelListeners() {
    for (final sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
  }

  void _listenToUserUpdates(String userId) {
    _cancelListeners();
    final base = _dbRef.child('users').child(userId);

    _listeners.add(base.child('credits').onValue.listen((e) {
      try {
        final v = e.snapshot.value;
        if (v != null) credits.value = (v as num).toInt();
      } catch (e) { debugPrint('CreditService: error parsing credits: $e'); }
    }));

    _listeners.add(base.child('isPremium').onValue.listen((e) {
      try {
        final v = e.snapshot.value;
        if (v != null) isPremium.value = v == true;
      } catch (e) { debugPrint('CreditService: error parsing isPremium: $e'); }
    }));

    _listeners.add(base.child('planCredits').onValue.listen((e) {
      try {
        final v = e.snapshot.value;
        planCredits.value = v != null ? (v as num).toInt() : 0;
      } catch (e) { debugPrint('CreditService: error parsing planCredits: $e'); }
    }));

    _listeners.add(base.child('planCreditsExpiry').onValue.listen((e) {
      try {
        final v = e.snapshot.value;
        planCreditsExpiry.value = v != null ? (v as num).toInt() : 0;
      } catch (e) { debugPrint('CreditService: error parsing planCreditsExpiry: $e'); }
    }));
  }

  /// Total usable credits: purchased credits + unexpired plan bonus credits.
  int get totalCredits {
    int total = credits.value;
    if (hasPlanCreditsActive) total += planCredits.value;
    return total;
  }

  /// True if the user has enough credits (purchased + plan) to perform an analysis.
  /// Subscribers are NOT exempt — they use credits to skip the video ad.
  bool hasCredits([int required = 1]) {
    return totalCredits >= required;
  }

  /// Deduct 1 credit. Deducts from plan credits first, then purchased credits.
  /// Returns true if deducted successfully.
  Future<bool> deductCredit([int amount = 1]) async {
    if (_currentUserId == null) return false;
    if (!hasCredits(amount)) return false;

    try {
      isLoading.value = true;

      int remaining = amount;
      final userRef = _dbRef.child('users').child(_currentUserId!);

      // 1) Deduct from plan credits first (if available & not expired)
      if (hasPlanCreditsActive && planCredits.value > 0) {
        final fromPlan = remaining.clamp(0, planCredits.value);
        if (fromPlan > 0) {
          final planResult =
              await userRef.child('planCredits').runTransaction((value) {
            final current = (value as num?)?.toInt() ?? 0;
            if (current >= fromPlan) {
              return Transaction.success(current - fromPlan);
            }
            return Transaction.abort();
          });
          if (planResult.committed) remaining -= fromPlan;
        }
      }

      // 2) Deduct remainder from purchased credits
      if (remaining > 0) {
        final result =
            await userRef.child('credits').runTransaction((value) {
          final current = (value as num?)?.toInt() ?? 0;
          if (current >= remaining) {
            return Transaction.success(current - remaining);
          }
          return Transaction.abort();
        });
        if (!result.committed) return false;
      }

      // Log the usage
      await userRef.child('usage').push().set({
        'type': 'analysis',
        'amount': amount,
        'timestamp': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      debugPrint('Error deducting credit: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Add credits as a daily reward (no purchase verification required).
  /// Returns true if credits were added successfully.
  Future<bool> addDailyCredits(int amount) async {
    if (_currentUserId == null) return false;
    try {
      final userRef = _dbRef.child('users').child(_currentUserId!);
      final result = await userRef.child('credits').runTransaction((value) {
        final current = (value as num?)?.toInt() ?? 0;
        return Transaction.success(current + amount);
      });
      if (result.committed) {
        await userRef.child('usage').push().set({
          'type': 'daily_reward',
          'amount': amount,
          'timestamp': ServerValue.timestamp,
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CreditService: error adding daily credits: $e');
      return false;
    }
  }

  // Generate purchase verification hash
  String _generatePurchaseHash(
    String userId,
    String packageId,
    int credits,
    int timestamp,
  ) {
    final data = '$userId:$packageId:$credits:$timestamp:$_secretKey';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Add credits after purchase with verification
  Future<bool> addCredits(String packageId, {String? purchaseToken}) async {
    if (_currentUserId == null) return false;

    final creditsToAdd = packages[packageId];
    if (creditsToAdd == null) return false;

    try {
      isLoading.value = true;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final verificationHash = _generatePurchaseHash(
        _currentUserId!,
        packageId,
        creditsToAdd,
        timestamp,
      );

      final userRef = _dbRef.child('users').child(_currentUserId!);

      // Use transaction to safely add credits.
      // NOTE: isPremium is intentionally NOT set here — credit pack buyers
      // still see video ads. Only subscription purchase sets isPremium = true.
      final committed = await userRef.runTransaction((value) {
        if (value == null) return Transaction.abort();

        final Map<dynamic, dynamic> userData = value as Map<dynamic, dynamic>;
        final currentCredits = (userData['credits'] as num?)?.toInt() ?? 0;

        userData['credits'] = currentCredits + creditsToAdd;
        userData['lastPurchaseHash'] = verificationHash;
        userData['lastPurchaseTime'] = timestamp;

        return Transaction.success(userData);
      });

      if (!committed.committed) return false;

      credits.value = credits.value + creditsToAdd;

      await userRef.child('purchases').push().set({
        'packageId': packageId,
        'credits': creditsToAdd,
        'timestamp': ServerValue.timestamp,
        'purchaseToken': purchaseToken ?? 'manual',
        'verificationHash': verificationHash,
        'verified': purchaseToken != null,
      });

      return true;
    } catch (e) {
      debugPrint('Error adding credits: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Verify user credits haven't been tampered with
  Future<bool> verifyCreditsIntegrity() async {
    if (_currentUserId == null) return false;

    try {
      final userRef = _dbRef.child('users').child(_currentUserId!);
      final snapshot = await userRef.get();

      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final storedHash = data['lastPurchaseHash'] as String?;
      final storedTime = data['lastPurchaseTime'] as int?;

      // If no purchases, credits should be 0 or from free tier
      if (storedHash == null || storedTime == null) {
        final currentCredits = (data['credits'] as num?)?.toInt() ?? 0;
        // Allow up to 10 free credits (welcome bonus, ads watched, etc.)
        return currentCredits <= 10;
      }

      return true;
    } catch (e) {
      debugPrint('Error verifying credits: $e');
      return false;
    }
  }

  // Get credits for a specific user (admin use)
  Future<int> getUserCredits(String userId) async {
    try {
      final snapshot = await _dbRef
          .child('users')
          .child(userId)
          .child('credits')
          .get();
      return (snapshot.value as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting user credits: $e');
      return 0;
    }
  }

  // Clear current user (on logout)
  /// Called by SubscriptionService when subscription status changes.
  /// isSubscribed controls ad removal; isPremium is a legacy Firebase field.
  void updateSubscriptionStatus(bool subscribed) {
    isSubscribed.value = subscribed;
    debugPrint('CreditService: subscription=$subscribed');
  }

  void clearUser() {
    _cancelListeners();
    _currentUserId = null;
    credits.value = 0;
    isPremium.value = false;
    isSubscribed.value = false;
    planCredits.value = 0;
    planCreditsExpiry.value = 0;
  }

  // ─── Plan Credits ──────────────────────────────────────────────────────

  /// Called by SubscriptionService when a plan is activated.
  /// Stores bonus credits in Firebase with an expiry timestamp.
  Future<void> addPlanCredits(int amount, int expiryMs) async {
    planCredits.value = amount;
    planCreditsExpiry.value = expiryMs;
    if (_currentUserId == null) return;
    try {
      await _dbRef.child('users').child(_currentUserId!).update({
        'planCredits': amount,
        'planCreditsExpiry': expiryMs,
      });
      debugPrint('CreditService: added $amount plan credits (expire: $expiryMs)');
    } catch (e) {
      debugPrint('CreditService: error saving plan credits: $e');
    }
  }

  /// Called by SubscriptionService when a plan expires or is cancelled.
  Future<void> clearPlanCredits() => _clearPlanCreditsInFirebase();

  Future<void> _clearPlanCreditsInFirebase() async {
    planCredits.value = 0;
    planCreditsExpiry.value = 0;
    if (_currentUserId == null) return;
    try {
      await _dbRef.child('users').child(_currentUserId!).update({
        'planCredits': 0,
        'planCreditsExpiry': 0,
      });
      debugPrint('CreditService: plan credits cleared');
    } catch (e) {
      debugPrint('CreditService: error clearing plan credits: $e');
    }
  }
}
