/// Subscription Service
/// Handles in-app subscriptions + credit pack purchases via native
/// Apple StoreKit / Google Play Billing.
/// Direct connection to App Store Connect & Google Play Console (native StoreKit / Play Billing).
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'credit_service.dart';

class SubscriptionService extends GetxService {
  static SubscriptionService get to => Get.find();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  final RxBool isAvailable = false.obs;
  final RxBool isPurchasing = false.obs;
  final RxBool isSubscribed = false.obs;
  final RxString activeSubscriptionId = ''.obs;
  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final RxList<ProductDetails> creditProducts = <ProductDetails>[].obs;
  final RxString errorMessage = ''.obs;

  static const _defaultCreditPacks = [
    {
      'id': 'credits_10',
      'credits': 10,
      'price': '₹20',
      'badge': null,
      'active': true,
    },
    {
      'id': 'credits_50',
      'credits': 50,
      'price': '₹80',
      'badge': null,
      'active': true,
    },
    {
      'id': 'credits_100',
      'credits': 100,
      'price': '₹150',
      'badge': 'Popular',
      'active': true,
    },
    {
      'id': 'credits_200',
      'credits': 200,
      'price': '₹300',
      'badge': null,
      'active': true,
    },
    {
      'id': 'credits_500',
      'credits': 500,
      'price': '₹750',
      'badge': 'Best Value',
      'active': true,
    },
    {
      'id': 'credits_1000',
      'credits': 1000,
      'price': '₹1500',
      'badge': null,
      'active': true,
    },
  ];

  // Product IDs must match App Store Connect / Google Play exactly:
  //   monthly     → 1 Week
  //   pro_monthly → 1 Month
  //   pro_yearly  → 3 Months
  static const List<Map<String, dynamic>> _defaultSubscriptionPlans = [
    {
      'id': 'monthly',
      'productId': 'monthly',
      'title': '1 Week',
      'price': '₹29',
      'duration': '1 week',
      'durationDays': 7,
      'badge': null,
      'savings': null,
      'bonusCredits': 5,
      'features': [
        'All Ads Removed (Banner, Video & Native)',
        '5 Credits Included — 5 Ad-Free Analyses',
        'Credits Valid for 7 Days',
        'Ad-Free Video Streaming',
        'Video Ad Resumes When Credits Run Out',
      ],
    },
    {
      'id': 'pro_monthly',
      'productId': 'pro_monthly',
      'title': '1 Month',
      'price': '₹79',
      'duration': '1 month',
      'durationDays': 30,
      'badge': 'Popular',
      'savings': null,
      'bonusCredits': 10,
      'features': [
        'All Ads Removed (Banner, Video & Native)',
        '10 Credits Included — 10 Ad-Free Analyses',
        'Credits Valid for 30 Days',
        'Ad-Free Video Streaming',
        'Video Ad Resumes When Credits Run Out',
      ],
    },
    {
      'id': 'pro_yearly',
      'productId': 'pro_yearly',
      'title': '3 Months',
      'price': '₹199',
      'duration': '3 months',
      'durationDays': 90,
      'badge': 'Best Value',
      'savings': 'Save 40%',
      'bonusCredits': 25,
      'features': [
        'All Ads Removed (Banner, Video & Native)',
        '25 Credits Included — 25 Ad-Free Analyses',
        'Credits Valid for 90 Days',
        'Ad-Free Video Streaming',
        'Video Ad Resumes When Credits Run Out',
      ],
    },
  ];

  // ─── Dynamic state (loaded from Firebase) ─────────────────────────────
  final RxList<Map<String, dynamic>> _dynamicPlans =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _dynamicCreditPacks =
      <Map<String, dynamic>>[].obs;

  /// Active product IDs for store queries (populated from Firebase or defaults).
  Set<String> _subscriptionProductIds = {};
  Set<String> _creditPackProductIds = {};

  /// productId → number of credits for each credit pack
  Map<String, int> get creditPackAmounts {
    final packs = creditPackPlans;
    return {for (final p in packs) p['id'] as String: (p['credits'] as int)};
  }

  List<Map<String, dynamic>> get subscriptionPlans => _dynamicPlans.isNotEmpty
      ? _dynamicPlans.toList()
      : _defaultSubscriptionPlans;

  List<Map<String, dynamic>> get creditPackPlans =>
      _dynamicCreditPacks.isNotEmpty
      ? _dynamicCreditPacks.toList()
      : _defaultCreditPacks;

  static List<Map<String, dynamic>> get subscriptionPlansStatic =>
      SubscriptionService.to.subscriptionPlans;

  // ─── Initialization ──────────────────────────────────────────────────
  Future<SubscriptionService> init() async {
    try {
      await Future.wait([
        _loadPlanConfigFromFirebase(),
        _loadCreditPackConfigFromFirebase(),
        _iap.isAvailable().then((available) {
          isAvailable.value = available;
          if (!available)
            debugPrint('SubscriptionService: Store not available');
        }),
      ]);

      _buildProductIdSets();

      if (!isAvailable.value) return this;

      _purchaseSubscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      await loadProducts();
      await _restoreAndCheckStatus();

      debugPrint('SubscriptionService initialized successfully');
    } catch (e) {
      debugPrint('SubscriptionService initialization error: $e');
    }
    return this;
  }

  /// Build product ID sets from current plans (for store queries).
  void _buildProductIdSets() {
    final isIOS = !kIsWeb && Platform.isIOS;

    _subscriptionProductIds = subscriptionPlans.map((p) {
      final pid = p['productId'] as String? ?? p['id'] as String;
      if (isIOS && p['productIdIOS'] != null)
        return p['productIdIOS'] as String;
      if (!isIOS && p['productIdAndroid'] != null)
        return p['productIdAndroid'] as String;
      return pid;
    }).toSet();

    _creditPackProductIds = creditPackPlans
        .where((p) => p['active'] != false)
        .map((p) => p['id'] as String)
        .toSet();

    debugPrint('SubscriptionService: sub IDs = $_subscriptionProductIds');
    debugPrint('SubscriptionService: credit IDs = $_creditPackProductIds');
  }

  /// Fetch subscription plan config from Firebase.
  Future<void> _loadPlanConfigFromFirebase() async {
    try {
      final results = await Future.wait([
        FirebaseDatabase.instance.ref('iap_config/plans').get(),
        FirebaseDatabase.instance.ref('iap_config/subscription_plans').get(),
      ]);

      final plansRaw = (results[0].exists && results[0].value != null)
          ? Map<String, dynamic>.from(results[0].value as Map)
          : <String, dynamic>{};
      final displayRaw = (results[1].exists && results[1].value != null)
          ? Map<String, dynamic>.from(results[1].value as Map)
          : <String, dynamic>{};

      final updated = <Map<String, dynamic>>[];

      for (final defaults in _defaultSubscriptionPlans) {
        final planId = defaults['id'] as String;
        final merged = Map<String, dynamic>.from(defaults);

        if (plansRaw.containsKey(planId)) {
          final cfg = Map<String, dynamic>.from(plansRaw[planId] as Map);
          if (cfg['productIdAndroid'] != null) {
            merged['productIdAndroid'] = cfg['productIdAndroid'];
          }
          if (cfg['productIdIOS'] != null) {
            merged['productIdIOS'] = cfg['productIdIOS'];
          }
          if (cfg['bonusCredits'] != null) {
            merged['bonusCredits'] = (cfg['bonusCredits'] as num).toInt();
          }
          if (cfg['durationDays'] != null) {
            merged['durationDays'] = (cfg['durationDays'] as num).toInt();
          }
          if (cfg['displayPrice'] != null &&
              (cfg['displayPrice'] as String).isNotEmpty) {
            merged['price'] = cfg['displayPrice'];
          }
          if (cfg['active'] != null) merged['active'] = cfg['active'];
          // Use platform-specific product ID for purchase
          final isIOS = !kIsWeb && Platform.isIOS;
          if (isIOS && cfg['productIdIOS'] != null) {
            merged['productId'] = cfg['productIdIOS'];
          } else if (!isIOS && cfg['productIdAndroid'] != null) {
            merged['productId'] = cfg['productIdAndroid'];
          }
        }

        if (displayRaw.containsKey(planId)) {
          final disp = Map<String, dynamic>.from(displayRaw[planId] as Map);
          // Title is hardcoded in _defaultSubscriptionPlans — do not override from Firebase
          merged['badge'] = disp['badge'];
          merged['savings'] = disp['savings'];
          if (disp['features'] is List) {
            merged['features'] = List<String>.from(disp['features'] as List);
          }
          if (disp['price'] != null && (disp['price'] as String).isNotEmpty) {
            merged['price'] = disp['price'];
          }
        }

        updated.add(merged);
      }

      _dynamicPlans.assignAll(updated);
      debugPrint(
        'SubscriptionService: loaded ${updated.length} plans from Firebase',
      );
    } catch (e) {
      debugPrint(
        'SubscriptionService: plan config load error (using defaults): $e',
      );
    }
  }

  /// Fetch credit pack config from Firebase.
  Future<void> _loadCreditPackConfigFromFirebase() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('iap_config/credit_packs')
          .get();
      if (!snap.exists || snap.value == null) return;

      final raw = snap.value;
      List<dynamic> packsList;

      if (raw is List) {
        packsList = raw;
      } else if (raw is Map) {
        packsList = raw.values.toList();
      } else {
        return;
      }

      final loaded = <Map<String, dynamic>>[];
      for (final item in packsList) {
        if (item == null) continue;
        final m = Map<String, dynamic>.from(item as Map);
        if (m['id'] == null || (m['id'] as String).isEmpty) continue;
        loaded.add({
          'id': m['id'],
          'credits': (m['credits'] as num?)?.toInt() ?? 0,
          'price': m['price'] ?? m['displayPrice'] ?? '',
          'badge': m['badge'],
          'active': m['active'] ?? true,
        });
      }

      if (loaded.isNotEmpty) {
        _dynamicCreditPacks.assignAll(loaded);
        debugPrint(
          'SubscriptionService: loaded ${loaded.length} credit packs from Firebase',
        );
      }
    } catch (e) {
      debugPrint(
        'SubscriptionService: credit pack config load error (using defaults): $e',
      );
    }
  }

  Future<void> refreshPlanConfig() async {
    await Future.wait([
      _loadPlanConfigFromFirebase(),
      _loadCreditPackConfigFromFirebase(),
    ]);
    _buildProductIdSets();
    if (isAvailable.value) await loadProducts();
  }

  // ─── Grant bonus credits on subscription activation ───────────────────
  void _grantPlanCredits(String productId) {
    try {
      final plan = subscriptionPlans.firstWhere(
        (p) =>
            p['productId'] == productId ||
            p['productIdAndroid'] == productId ||
            p['productIdIOS'] == productId,
        orElse: () => <String, dynamic>{},
      );
      final bonusCredits = (plan['bonusCredits'] as int?) ?? 0;
      final durationDays = (plan['durationDays'] as int?) ?? 30;
      if (bonusCredits <= 0) return;
      if (!Get.isRegistered<CreditService>()) return;

      final expiryMs = DateTime.now()
          .add(Duration(days: durationDays))
          .millisecondsSinceEpoch;
      Get.find<CreditService>().addPlanCredits(bonusCredits, expiryMs);
      debugPrint(
        'SubscriptionService: granted $bonusCredits plan credits (expire in $durationDays days)',
      );
    } catch (e) {
      debugPrint('SubscriptionService: error granting plan credits: $e');
    }
  }

  void _clearExpiredPlanCredits() {
    try {
      if (!Get.isRegistered<CreditService>()) return;
      Get.find<CreditService>().clearPlanCredits();
    } catch (e) {
      debugPrint('SubscriptionService: error clearing plan credits: $e');
    }
  }

  // ─── Load Products from Store ─────────────────────────────────────────
  Future<void> loadProducts() async {
    try {
      if (_subscriptionProductIds.isNotEmpty) {
        final subResponse = await _iap.queryProductDetails(
          _subscriptionProductIds,
        );
        if (subResponse.error != null) {
          debugPrint('Subscription query error: ${subResponse.error}');
        }
        if (subResponse.notFoundIDs.isNotEmpty) {
          debugPrint(
            'Subscriptions not found in store: ${subResponse.notFoundIDs}',
          );
        }
        products.value = subResponse.productDetails;
        debugPrint('Loaded ${products.length} subscription products');
      }

      if (_creditPackProductIds.isNotEmpty) {
        final creditResponse = await _iap.queryProductDetails(
          _creditPackProductIds,
        );
        if (creditResponse.error != null) {
          debugPrint('Credit pack query error: ${creditResponse.error}');
        }
        if (creditResponse.notFoundIDs.isNotEmpty) {
          debugPrint(
            'Credit packs not found in store: ${creditResponse.notFoundIDs}',
          );
        }
        creditProducts.value = creditResponse.productDetails;
        debugPrint('Loaded ${creditProducts.length} credit pack products');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  // ─── Get localized price from store ──────────────────────────────────
  String? getLocalizedPrice(String productId) {
    final product =
        products.firstWhereOrNull((p) => p.id == productId) ??
        creditProducts.firstWhereOrNull((p) => p.id == productId);
    return product?.price;
  }

  // ─── Purchase a subscription ─────────────────────────────────────────
  Future<bool> purchase(String productId) async {
    try {
      isPurchasing.value = true;
      errorMessage.value = '';

      final product = products.firstWhereOrNull((p) => p.id == productId);

      if (product == null) {
        errorMessage.value = 'Product not available. Please try again later.';
        isPurchasing.value = false;
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      bool initiated = false;
      try {
        initiated = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        // On iOS, user cancellation can throw an exception instead of
        // delivering PurchaseStatus.canceled on the stream.
        debugPrint('buyNonConsumable threw: $e');
        final msg = e.toString().toLowerCase();
        if (msg.contains('cancel') || msg.contains('skerror')) {
          errorMessage.value = 'Purchase cancelled';
        } else {
          errorMessage.value = 'Purchase failed. Please try again.';
        }
        isPurchasing.value = false;
        return false;
      }

      if (!initiated) {
        errorMessage.value = 'Could not initiate purchase';
        isPurchasing.value = false;
        return false;
      }

      final result = await _waitForPurchaseResult(productId);
      return result;
    } catch (e) {
      debugPrint('Purchase error: $e');
      errorMessage.value = 'Purchase failed. Please try again.';
      isPurchasing.value = false;
      return false;
    }
  }

  // ─── Purchase a credit pack (consumable) ─────────────────────────────
  Future<bool> purchaseCreditPack(String productId) async {
    try {
      isPurchasing.value = true;
      errorMessage.value = '';

      final product = creditProducts.firstWhereOrNull((p) => p.id == productId);

      if (product == null) {
        errorMessage.value =
            'Credit pack not available. Please try again later.';
        isPurchasing.value = false;
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      bool initiated = false;
      try {
        initiated = await _iap.buyConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        // On iOS, user cancellation can throw an exception instead of
        // delivering PurchaseStatus.canceled on the stream.
        debugPrint('buyConsumable threw: $e');
        final msg = e.toString().toLowerCase();
        if (msg.contains('cancel') || msg.contains('skerror')) {
          errorMessage.value = 'Purchase cancelled';
        } else {
          errorMessage.value = 'Purchase failed. Please try again.';
        }
        isPurchasing.value = false;
        return false;
      }

      if (!initiated) {
        errorMessage.value = 'Could not initiate purchase';
        isPurchasing.value = false;
        return false;
      }

      final result = await _waitForCreditPurchaseResult(productId);
      return result;
    } catch (e) {
      debugPrint('Credit pack purchase error: $e');
      errorMessage.value = 'Purchase failed. Please try again.';
      isPurchasing.value = false;
      return false;
    }
  }

  final Map<String, Completer<bool>> _pendingCreditCompleters = {};

  Future<bool> _waitForPurchaseResult(String productId) async {
    final completer = Completer<bool>();
    Worker? worker;
    Worker? errorWorker;
    Worker? cancelWorker;

    void cleanup() {
      worker?.dispose();
      errorWorker?.dispose();
      cancelWorker?.dispose();
    }

    final timer = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(false);
        isPurchasing.value = false;
        errorMessage.value = 'Purchase timed out. Please try again.';
        cleanup();
      }
    });

    worker = ever(isSubscribed, (bool subscribed) {
      if (subscribed && !completer.isCompleted) {
        completer.complete(true);
        timer.cancel();
        cleanup();
      }
    });

    errorWorker = ever(errorMessage, (String msg) {
      if (msg.isNotEmpty && !completer.isCompleted) {
        completer.complete(false);
        timer.cancel();
        cleanup();
      }
    });

    // Listen for cancellation (isPurchasing set to false by _onPurchaseUpdate)
    cancelWorker = ever(isPurchasing, (bool purchasing) {
      if (!purchasing && !completer.isCompleted) {
        completer.complete(false);
        timer.cancel();
        cleanup();
      }
    });

    return completer.future;
  }

  Future<bool> _waitForCreditPurchaseResult(String productId) async {
    final completer = Completer<bool>();
    _pendingCreditCompleters[productId] = completer;

    final timer = Timer(const Duration(seconds: 60), () {
      if (!completer.isCompleted) {
        completer.complete(false);
        isPurchasing.value = false;
        _pendingCreditCompleters.remove(productId);
      }
    });

    final result = await completer.future;
    timer.cancel();
    _pendingCreditCompleters.remove(productId);
    return result;
  }

  void _completeCreditPurchase(String productId, bool success) {
    final completer = _pendingCreditCompleters[productId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  // ─── Handle purchase updates from the store ──────────────────────────
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseList) async {
    for (final purchase in purchaseList) {
      debugPrint(
        'Purchase update: ${purchase.productID} status=${purchase.status}',
      );

      final isSubscription = _subscriptionProductIds.contains(
        purchase.productID,
      );
      final isCreditPack = _creditPackProductIds.contains(purchase.productID);

      // IMPORTANT: Process status FIRST, then completePurchase LAST.
      // Apple requires the app to progress through the purchasing workflow
      // before acknowledging the transaction (Guideline 2.1b).
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (isSubscription) {
            _handleSuccessfulSubscription(purchase);
          } else if (isCreditPack) {
            _handleSuccessfulCreditPurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchase);
          if (isCreditPack) _completeCreditPurchase(purchase.productID, false);
          break;
        case PurchaseStatus.canceled:
          debugPrint('Purchase cancelled: ${purchase.productID}');
          isPurchasing.value = false;
          errorMessage.value = 'Purchase cancelled';
          if (isCreditPack) _completeCreditPurchase(purchase.productID, false);
          break;
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchase.productID}');
          break;
      }

      // completePurchase called AFTER processing — await is critical on iOS
      // to properly dismiss the StoreKit payment sheet.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _handleSuccessfulSubscription(PurchaseDetails purchase) {
    debugPrint('✅ Subscription active: ${purchase.productID}');

    isSubscribed.value = true;
    activeSubscriptionId.value = purchase.productID;
    isPurchasing.value = false;

    _saveSubscriptionStatus(true, purchase.productID);
    _syncCreditService(true);
    _grantPlanCredits(purchase.productID);
  }

  void _handleSuccessfulCreditPurchase(PurchaseDetails purchase) async {
    debugPrint('✅ Credit pack purchased: ${purchase.productID}');
    isPurchasing.value = false;

    bool credited = false;
    try {
      if (Get.isRegistered<CreditService>()) {
        final purchaseToken = purchase.verificationData.serverVerificationData;
        credited = await Get.find<CreditService>().addCredits(
          purchase.productID,
          purchaseToken: purchaseToken,
        );
      }
    } catch (e) {
      debugPrint('Error adding credits after purchase: $e');
    }

    _completeCreditPurchase(purchase.productID, credited);
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    debugPrint('❌ Purchase error: ${purchase.error}');
    errorMessage.value = purchase.error?.message ?? 'Purchase failed';
    isPurchasing.value = false;
  }

  // ─── Restore Purchases ───────────────────────────────────────────────
  Future<bool> restorePurchases() async {
    try {
      isPurchasing.value = true;
      errorMessage.value = '';
      await _iap.restorePurchases();
      await Future.delayed(const Duration(seconds: 3));
      isPurchasing.value = false;

      if (isSubscribed.value) {
        debugPrint('Restore: Active subscription found');
        return true;
      }
      debugPrint('Restore: No active subscription found');
      return false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      errorMessage.value = 'Failed to restore purchases';
      isPurchasing.value = false;
      return false;
    }
  }

  Future<void> _restoreAndCheckStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStatus = prefs.getBool('is_subscribed') ?? false;
    final cachedProductId = prefs.getString('active_subscription_id') ?? '';

    if (cachedStatus) {
      isSubscribed.value = true;
      activeSubscriptionId.value = cachedProductId;
      _syncCreditService(true);
    } else {
      _clearExpiredPlanCredits();
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Silent restore failed: $e');
    }
  }

  Future<void> _saveSubscriptionStatus(
    bool subscribed,
    String productId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', subscribed);
    await prefs.setString('active_subscription_id', productId);
  }

  void _syncCreditService(bool subscribed) {
    try {
      if (Get.isRegistered<CreditService>()) {
        Get.find<CreditService>().updateSubscriptionStatus(subscribed);
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}
