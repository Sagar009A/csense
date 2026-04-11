/// History Controller
/// Manages scan history list and actions with favorites support
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';

class HistoryController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final RxList<Map<String, dynamic>> historyList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredList =
      <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Favorites filter
  final RxBool showFavoritesOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();

    // Listen to search query changes
    debounce(
      searchQuery,
      (_) => filterHistory(),
      time: const Duration(milliseconds: 300),
    );

    // Listen to storage updates
    ever(_storage.historyUpdated, (_) => loadHistory());
  }

  void loadHistory() {
    historyList.value = _storage.history;
    filterHistory();
  }

  void toggleFavoritesFilter() {
    showFavoritesOnly.value = !showFavoritesOnly.value;
    filterHistory();
  }

  void filterHistory() {
    List<Map<String, dynamic>> result = historyList;

    // Filter by favorites if enabled
    if (showFavoritesOnly.value) {
      result = result.where((item) => item['isFavorite'] == true).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((item) {
        final analysis = (item['analysis'] ?? '').toString().toLowerCase();
        final recommendation = (item['recommendation'] ?? '')
            .toString()
            .toLowerCase();
        return analysis.contains(query) || recommendation.contains(query);
      }).toList();
    }

    filteredList.value = result;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void toggleFavorite(String id) {
    _storage.toggleFavorite(id);
    loadHistory();
  }

  void openAnalysis(Map<String, dynamic> item) {
    Get.toNamed(
      AppRoutes.analysis,
      arguments: {'historyItem': item, 'imagePath': item['imagePath']},
    );
  }

  void deleteItem(String id) {
    _storage.removeFromHistory(id);
    loadHistory();
    filterHistory();

    Get.snackbar(
      'success'.tr,
      'delete'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void confirmClearHistory() {
    Get.dialog(
      AlertDialog(
        title: Text('clear_history'.tr),
        content: Text('confirm_clear_history'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              _storage.clearHistory();
              loadHistory();
              filterHistory();
              Get.back();
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
