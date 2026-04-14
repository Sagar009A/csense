/// Watchlist Controller
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/watchlist_service.dart';

class WatchlistController extends GetxController {
  late final WatchlistService _service;

  final TextEditingController symbolController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<WatchlistService>()) {
      Get.put(WatchlistService());
    }
    _service = WatchlistService.to;
    _service.loadWatchlist();
  }

  @override
  void onClose() {
    symbolController.dispose();
    nameController.dispose();
    notesController.dispose();
    super.onClose();
  }

  List get items => _service.items;
  bool get isLoading => _service.isLoading.value;

  void showAddDialog() {
    symbolController.clear();
    nameController.clear();
    notesController.clear();

    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1F2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('add_to_watchlist'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol (e.g. NIFTY, EUR/USD)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Nifty 50)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => TextButton(
            onPressed: isSaving.value ? null : _addItem,
            child: isSaving.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add', style: TextStyle(color: Color(0xFF8B5CF6))),
          )),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final symbol = symbolController.text.trim();
    final name = nameController.text.trim();
    if (symbol.isEmpty || name.isEmpty) {
      Get.snackbar('error'.tr, 'symbol_required'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    isSaving.value = true;
    final success = await _service.addItem(
      symbol: symbol,
      name: name,
      notes: notesController.text.trim(),
    );
    isSaving.value = false;
    if (success) {
      Get.back();
      Get.snackbar('Added!', '$symbol added to watchlist.', backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  Future<void> removeItem(String id, String symbol) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove'),
        content: Text('Remove $symbol from watchlist?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.removeItem(id);
      Get.snackbar('Removed', '$symbol removed from watchlist.', backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }
}
