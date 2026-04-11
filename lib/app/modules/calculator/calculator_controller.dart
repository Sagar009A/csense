/// Calculator Controller
/// Manages different forex and stock market calculators
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/ad_service.dart';

class CalculatorController extends GetxController {
  // Current calculator type
  final RxInt selectedCalculator = 0.obs;

  // Calculator types
  final List<CalculatorType> calculators = [
    CalculatorType(
      id: 0,
      name: 'Profit/Loss',
      icon: Icons.trending_up_rounded,
      description: 'Calculate P&L',
    ),
    CalculatorType(
      id: 1,
      name: 'Pip Value',
      icon: Icons.attach_money_rounded,
      description: 'Forex pip calculator',
    ),
    CalculatorType(
      id: 2,
      name: 'Position Size',
      icon: Icons.account_balance_rounded,
      description: 'Risk-based sizing',
    ),
    CalculatorType(
      id: 3,
      name: 'Risk/Reward',
      icon: Icons.balance_rounded,
      description: 'R:R ratio',
    ),
    CalculatorType(
      id: 4,
      name: 'Margin',
      icon: Icons.percent_rounded,
      description: 'Margin required',
    ),
  ];

  // Profit/Loss Calculator
  final TextEditingController entryPriceController = TextEditingController();
  final TextEditingController exitPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final RxBool isLong = true.obs;
  final RxDouble profitLoss = 0.0.obs;
  final RxDouble profitLossPercent = 0.0.obs;

  // Pip Value Calculator
  final TextEditingController lotSizeController = TextEditingController();
  final RxString selectedPair = 'EUR/USD'.obs;
  final RxDouble pipValue = 0.0.obs;
  final List<String> currencyPairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
  ];

  // Position Size Calculator
  final TextEditingController accountBalanceController =
      TextEditingController();
  final TextEditingController riskPercentController = TextEditingController();
  final TextEditingController stopLossPipsController = TextEditingController();
  final RxDouble positionSize = 0.0.obs;

  // Risk Reward Calculator
  final TextEditingController rrEntryController = TextEditingController();
  final TextEditingController rrStopLossController = TextEditingController();
  final TextEditingController rrTakeProfitController = TextEditingController();
  final RxDouble riskRewardRatio = 0.0.obs;

  // Margin Calculator
  final TextEditingController marginLotController = TextEditingController();
  final TextEditingController leverageController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final RxDouble marginRequired = 0.0.obs;

  void selectCalculator(int index) {
    selectedCalculator.value = index;
  }

  // Show interstitial ad then perform calculation
  void _showAdThenCalculate(VoidCallback calculation) {
    AdService.to.showInterstitialAd(
      onAdClosed: () {
        calculation();
      },
      onAdFailed: (_) {
        // Still perform calculation if ad fails
        calculation();
      },
    );
  }

  // Profit/Loss Calculation with Ad
  void calculateProfitLoss() {
    _showAdThenCalculate(_performProfitLossCalculation);
  }

  void _performProfitLossCalculation() {
    final entry = double.tryParse(entryPriceController.text) ?? 0;
    final exit = double.tryParse(exitPriceController.text) ?? 0;
    final qty = double.tryParse(quantityController.text) ?? 0;

    if (entry > 0 && exit > 0 && qty > 0) {
      if (isLong.value) {
        profitLoss.value = (exit - entry) * qty;
      } else {
        profitLoss.value = (entry - exit) * qty;
      }
      profitLossPercent.value = ((profitLoss.value) / (entry * qty)) * 100;
    }
  }

  // Pip Value Calculation with Ad
  void calculatePipValue() {
    _showAdThenCalculate(_performPipValueCalculation);
  }

  void _performPipValueCalculation() {
    final lots = double.tryParse(lotSizeController.text) ?? 0;

    if (lots > 0) {
      // Standard pip value for USD pairs
      if (selectedPair.value.endsWith('USD')) {
        pipValue.value = lots * 10; // $10 per pip for 1 lot
      } else if (selectedPair.value.startsWith('USD')) {
        pipValue.value = lots * 10 / 1.1; // Approximate
      } else {
        pipValue.value = lots * 10;
      }
    }
  }

  // Position Size Calculation with Ad
  void calculatePositionSize() {
    _showAdThenCalculate(_performPositionSizeCalculation);
  }

  void _performPositionSizeCalculation() {
    final balance = double.tryParse(accountBalanceController.text) ?? 0;
    final riskPercent = double.tryParse(riskPercentController.text) ?? 0;
    final stopLossPips = double.tryParse(stopLossPipsController.text) ?? 0;

    if (balance > 0 && riskPercent > 0 && stopLossPips > 0) {
      final riskAmount = balance * (riskPercent / 100);
      final pipValuePerLot = 10.0; // Standard pip value
      positionSize.value = riskAmount / (stopLossPips * pipValuePerLot);
    }
  }

  // Risk Reward Calculation with Ad
  void calculateRiskReward() {
    _showAdThenCalculate(_performRiskRewardCalculation);
  }

  void _performRiskRewardCalculation() {
    final entry = double.tryParse(rrEntryController.text) ?? 0;
    final stopLoss = double.tryParse(rrStopLossController.text) ?? 0;
    final takeProfit = double.tryParse(rrTakeProfitController.text) ?? 0;

    if (entry > 0 && stopLoss > 0 && takeProfit > 0) {
      final risk = (entry - stopLoss).abs();
      final reward = (takeProfit - entry).abs();
      if (risk > 0) {
        riskRewardRatio.value = reward / risk;
      }
    }
  }

  // Margin Calculation with Ad
  void calculateMargin() {
    _showAdThenCalculate(_performMarginCalculation);
  }

  void _performMarginCalculation() {
    final lots = double.tryParse(marginLotController.text) ?? 0;
    final leverage = double.tryParse(leverageController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    if (lots > 0 && leverage > 0 && price > 0) {
      final contractSize = 100000; // Standard lot
      marginRequired.value = (lots * contractSize * price) / leverage;
    }
  }

  void clearAll() {
    entryPriceController.clear();
    exitPriceController.clear();
    quantityController.clear();
    lotSizeController.clear();
    accountBalanceController.clear();
    riskPercentController.clear();
    stopLossPipsController.clear();
    rrEntryController.clear();
    rrStopLossController.clear();
    rrTakeProfitController.clear();
    marginLotController.clear();
    leverageController.clear();
    priceController.clear();

    profitLoss.value = 0;
    profitLossPercent.value = 0;
    pipValue.value = 0;
    positionSize.value = 0;
    riskRewardRatio.value = 0;
    marginRequired.value = 0;
  }

  @override
  void onClose() {
    entryPriceController.dispose();
    exitPriceController.dispose();
    quantityController.dispose();
    lotSizeController.dispose();
    accountBalanceController.dispose();
    riskPercentController.dispose();
    stopLossPipsController.dispose();
    rrEntryController.dispose();
    rrStopLossController.dispose();
    rrTakeProfitController.dispose();
    marginLotController.dispose();
    leverageController.dispose();
    priceController.dispose();
    super.onClose();
  }
}

class CalculatorType {
  final int id;
  final String name;
  final IconData icon;
  final String description;

  CalculatorType({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
