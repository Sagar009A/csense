/// PremiumManager for TeraBox Video Player
/// Wrapper around app's CreditService for compatibility with TeraBox screens
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/credit_service.dart';

class PremiumManager {
  static bool _isPremiumUser = false;
  static bool _isRewardedAdsDisabled = false;
  
  static bool get isPremiumUser => _isPremiumUser;
  static bool get isRewardedAdsDisabled => _isRewardedAdsDisabled;
  
  static Future<void> load() async {
    try {
      final creditService = Get.find<CreditService>();
      // isSubscribed = active subscription plan → removes all ads (banner, native, etc.)
      _isPremiumUser = creditService.isSubscribed.value;
      _isRewardedAdsDisabled = creditService.isSubscribed.value;
      debugPrint('PremiumManager: isSubscribed=$_isPremiumUser (from CreditService)');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', _isPremiumUser);
      await prefs.setBool('rewarded_ads_disabled', _isRewardedAdsDisabled);
    } catch (e) {
      debugPrint('PremiumManager: CreditService not found, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      _isPremiumUser = prefs.getBool('is_premium') ?? false;
      _isRewardedAdsDisabled = prefs.getBool('rewarded_ads_disabled') ?? false;
    }
  }
  
  static Future<void> setPremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);
  }
  
  static Future<void> setRewardedAdsDisabled(bool disabled) async {
    _isRewardedAdsDisabled = disabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rewarded_ads_disabled', disabled);
  }
}
