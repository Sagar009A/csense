/// Storage Service
/// Handles local data persistence using GetStorage
library;

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  // Observable to notify when history updates
  final RxInt historyUpdated = 0.obs;

  // Storage Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyHistory = 'history';
  static const String keyIntroSeen = 'intro_seen';

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // First Launch
  bool get isFirstLaunch => _box.read(keyFirstLaunch) ?? true;
  set isFirstLaunch(bool value) => _box.write(keyFirstLaunch, value);

  // Language
  String? get savedLanguage => _box.read(keyLanguage);
  set savedLanguage(String? value) => _box.write(keyLanguage, value);

  // Theme Mode (0: system, 1: light, 2: dark)
  int get themeMode => _box.read(keyThemeMode) ?? 0;
  set themeMode(int value) => _box.write(keyThemeMode, value);

  // Intro Seen
  bool get hasSeenIntro => _box.read(keyIntroSeen) ?? false;
  set hasSeenIntro(bool value) => _box.write(keyIntroSeen, value);

  // History
  List<Map<String, dynamic>> get history {
    final data = _box.read(keyHistory);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  set history(List<Map<String, dynamic>> value) {
    _box.write(keyHistory, value);
  }

  void addToHistory(Map<String, dynamic> item) {
    final currentHistory = history;

    // Ensure item has required fields
    if (!item.containsKey('isFavorite')) {
      item['isFavorite'] = false;
    }
    if (!item.containsKey('id')) {
      item['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Prevent duplicates - check if same analysis already exists (by content)
    final itemId = item['id'] as String;
    final itemAnalysis = (item['analysis'] ?? '').toString().trim();

    // Remove any existing duplicate entries with same analysis content
    currentHistory.removeWhere((existing) {
      final existingAnalysis = (existing['analysis'] ?? '').toString().trim();
      final existingId = existing['id'] as String?;
      // Don't remove the current item itself
      if (existingId == itemId) return false;
      // Remove if same analysis content (within reasonable time window)
      return existingAnalysis == itemAnalysis && existingAnalysis.isNotEmpty;
    });

    currentHistory.insert(0, item);
    // Keep only last 100 items
    if (currentHistory.length > 100) {
      currentHistory.removeRange(100, currentHistory.length);
    }
    history = currentHistory;
    historyUpdated.value++; // Notify listeners
  }

  void removeFromHistory(String id) {
    final currentHistory = history;
    currentHistory.removeWhere((item) => item['id'] == id);
    history = currentHistory;
    historyUpdated.value++;
  }

  void clearHistory() {
    history = [];
    historyUpdated.value++;
  }

  /// Toggle favorite status for an item
  void toggleFavorite(String id) {
    final currentHistory = history;
    final index = currentHistory.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      currentHistory[index]['isFavorite'] =
          !(currentHistory[index]['isFavorite'] ?? false);
      history = currentHistory;
      historyUpdated.value++;
    }
  }

  /// Get only favorite items
  List<Map<String, dynamic>> get favorites {
    return history.where((item) => item['isFavorite'] == true).toList();
  }

  /// Check if item is favorite
  bool isFavorite(String id) {
    final item = history.firstWhereOrNull((item) => item['id'] == id);
    return item?['isFavorite'] ?? false;
  }

  // Generic methods
  T? read<T>(String key) => _box.read<T>(key);
  void write(String key, dynamic value) => _box.write(key, value);
  void remove(String key) => _box.remove(key);
  void clearAll() => _box.erase();
}
