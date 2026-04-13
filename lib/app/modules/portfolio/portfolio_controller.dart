/// Portfolio Controller
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/portfolio_service.dart';

class PortfolioController extends GetxController {
  late final PortfolioService _service;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<PortfolioService>()) {
      Get.put(PortfolioService());
    }
    _service = PortfolioService.to;
    _service.loadTrades();
  }

  List<TradeModel> get trades => _service.trades;
  bool get isLoading => _service.isLoading.value;
  double get totalPnl => _service.totalPnl;
  double get totalInvested => _service.totalInvested;

  Future<void> deleteTrade(String id, String symbol) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Trade'),
        content: Text('Delete $symbol trade?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteTrade(id);
      Get.snackbar('Deleted', '$symbol trade removed.', backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  Future<void> updatePrice(String tradeId, String symbol) async {
    final ctrl = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Update Price: $symbol'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Current Price', border: OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Update', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final price = double.tryParse(ctrl.text.trim());
      if (price != null && price > 0) {
        await _service.updateCurrentPrice(tradeId, price);
      }
    }
    ctrl.dispose();
  }

  Future<void> refresh() => _service.loadTrades();
}
