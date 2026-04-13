/// Add Trade Controller
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/portfolio_service.dart';

class AddTradeController extends GetxController {
  final symbolController = TextEditingController();
  final buyPriceController = TextEditingController();
  final quantityController = TextEditingController();
  final currentPriceController = TextEditingController();
  final notesController = TextEditingController();

  final RxString tradeType = 'long'.obs;
  final RxBool isSaving = false.obs;

  @override
  void onClose() {
    symbolController.dispose();
    buyPriceController.dispose();
    quantityController.dispose();
    currentPriceController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> saveTrade() async {
    final symbol = symbolController.text.trim();
    final buyPriceStr = buyPriceController.text.trim();
    final quantityStr = quantityController.text.trim();
    final currentPriceStr = currentPriceController.text.trim();

    if (symbol.isEmpty || buyPriceStr.isEmpty || quantityStr.isEmpty) {
      Get.snackbar('Error', 'Symbol, buy price, and quantity are required.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final buyPrice = double.tryParse(buyPriceStr);
    final quantity = double.tryParse(quantityStr);
    final currentPrice = double.tryParse(currentPriceStr);

    if (buyPrice == null || buyPrice <= 0) {
      Get.snackbar('Error', 'Enter a valid buy price.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (quantity == null || quantity <= 0) {
      Get.snackbar('Error', 'Enter a valid quantity.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isSaving.value = true;

    if (!Get.isRegistered<PortfolioService>()) {
      Get.put(PortfolioService());
    }

    final success = await PortfolioService.to.addTrade(
      symbol: symbol,
      buyPrice: buyPrice,
      quantity: quantity,
      currentPrice: currentPrice ?? buyPrice,
      type: tradeType.value,
      notes: notesController.text.trim(),
    );

    isSaving.value = false;

    if (success) {
      Get.back(result: true);
      Get.snackbar('Trade Added!', '$symbol added to portfolio.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to save trade.', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
