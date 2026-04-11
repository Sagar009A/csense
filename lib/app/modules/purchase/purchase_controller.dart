/// Purchase Controller
/// Manages subscription + credit pack purchase state
library;

import 'package:get/get.dart';
import '../../services/subscription_service.dart';
import '../../services/credit_service.dart';
import '../../core/constants/app_colors.dart';

class PurchaseController extends GetxController {
  final SubscriptionService _subscriptionService = Get.find<SubscriptionService>();

  /// 0 = Subscriptions tab, 1 = Credit Packs tab
  final RxInt selectedTab = 0.obs;

  final RxInt selectedPlanIndex = 1.obs; // Default to Pro Monthly (Popular)

  List<Map<String, dynamic>> get plans => _subscriptionService.subscriptionPlans;
  List<Map<String, dynamic>> get creditPacks => _subscriptionService.creditPackPlans;
  RxBool get isPurchasing => _subscriptionService.isPurchasing;
  RxBool get isSubscribed => _subscriptionService.isSubscribed;
  RxString get activeSubscriptionId => _subscriptionService.activeSubscriptionId;
  RxString get errorMessage => _subscriptionService.errorMessage;
  bool get isStoreAvailable => _subscriptionService.isAvailable.value;
  bool get hasProducts => _subscriptionService.products.isNotEmpty || _subscriptionService.creditProducts.isNotEmpty;

  /// Current user credits
  int get currentCredits {
    try {
      if (Get.isRegistered<CreditService>()) {
        return CreditService.to.credits.value;
      }
    } catch (_) {}
    return 0;
  }

  /// Get localized price for a subscription plan (from store). Falls back to hardcoded price.
  String getPlanPrice(Map<String, dynamic> plan) {
    final storePrice =
        _subscriptionService.getLocalizedPrice(plan['productId'] as String);
    return storePrice ?? (plan['price'] as String);
  }

  /// Get localized price for a credit pack (from store). Falls back to hardcoded price.
  String getCreditPackPrice(Map<String, dynamic> pack) {
    final storePrice =
        _subscriptionService.getLocalizedPrice(pack['id'] as String);
    return storePrice ?? (pack['price'] as String);
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  void selectPlan(int index) {
    selectedPlanIndex.value = index;
  }

  Future<bool> purchaseSelected() async {
    final planId = plans[selectedPlanIndex.value]['productId'] as String;
    final success = await _subscriptionService.purchase(planId);

    if (success) {
      Get.snackbar(
        '🎉 Subscription Active!',
        'You now have unlimited premium access',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successLight,
        colorText: Get.theme.canvasColor,
      );
    } else {
      final msg = errorMessage.value.isNotEmpty ? errorMessage.value : 'Unknown error occurred';
      if (msg != 'Purchase cancelled') {
        Get.snackbar(
          'Purchase Failed',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warningLight,
          colorText: Get.theme.canvasColor,
        );
      }
    }

    return success;
  }

  Future<bool> purchaseCreditPack(String productId) async {
    final success = await _subscriptionService.purchaseCreditPack(productId);

    if (success) {
      final credits = _subscriptionService.creditPackAmounts[productId] ?? 0;
      Get.snackbar(
        '🎉 Credits Added!',
        '$credits credits have been added to your account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successLight,
        colorText: Get.theme.canvasColor,
      );
    } else {
      final msg = errorMessage.value.isNotEmpty ? errorMessage.value : 'Unknown error occurred';
      if (msg != 'Purchase cancelled') {
        Get.snackbar(
          'Purchase Failed',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warningLight,
          colorText: Get.theme.canvasColor,
        );
      }
    }

    return success;
  }

  Future<void> restorePurchases() async {
    final restored = await _subscriptionService.restorePurchases();
    if (restored) {
      Get.snackbar(
        '✅ Restored!',
        'Your subscription has been restored successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successLight,
        colorText: Get.theme.canvasColor,
      );
    } else {
      Get.snackbar(
        'No Subscription Found',
        'No active subscription was found to restore',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warningLight,
        colorText: Get.theme.canvasColor,
      );
    }
  }
}
