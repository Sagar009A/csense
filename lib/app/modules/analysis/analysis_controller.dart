/// Analysis Controller
/// Manages analysis result display and actions with section parsing
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/storage_service.dart';
import '../../services/gemini_service.dart';

class AnalysisController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  Rx<StockAnalysisResult?> result = Rx<StockAnalysisResult?>(null);
  RxString imagePath = ''.obs;
  RxBool isSaved = false.obs;

  // Parsed sections
  RxMap<String, String> sections = <String, String>{}.obs;
  RxString stockName = ''.obs;
  RxString trendDirection = ''.obs;
  RxString riskLevel = ''.obs;

  Map<String, dynamic>? historyItem;

  @override
  void onInit() {
    super.onInit();
    _loadArguments();

    // Defer auto-save and section parsing to after build so we don't trigger
    // historyUpdated (and thus HomeScreen's Obx) during AnalysisScreen's build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        _autoSaveIfNeeded();
        if (result.value != null) {
          _parseSections(result.value!.analysis);
        }
      });
    });
  }

  /// Id for GetBuilder so UI updates after sections/analysis/isSaved change
  static const String kAnalysisContentId = 'analysis_content';

  void _autoSaveIfNeeded() {
    // Auto-save to history if item exists and not already saved
    if (historyItem != null && !isSaved.value) {
      _storage.addToHistory(historyItem!);
      isSaved.value = true;
    }
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['result'] != null) {
        result.value = args['result'] as StockAnalysisResult;
      }

      if (args['historyItem'] != null) {
        historyItem = args['historyItem'] as Map<String, dynamic>;
        if (result.value == null && historyItem!['analysis'] != null) {
          result.value = StockAnalysisResult(
            analysis: historyItem!['analysis'],
            recommendation: historyItem!['recommendation'] ?? 'HOLD',
            timestamp: DateTime.parse(historyItem!['timestamp']),
            pair: historyItem!['pair']?.toString(),
            direction: historyItem!['direction']?.toString(),
            entryTimeIST: historyItem!['entryTimeIST']?.toString(),
            expiry: historyItem!['expiry']?.toString(),
            confidencePercent: (historyItem!['confidencePercent'] as num?)
                ?.toInt(),
            trend: historyItem!['trend']?.toString(),
            expiry30s: historyItem!['expiry30s']?.toString(),
            expiry1m: historyItem!['expiry1m']?.toString(),
            expiry2m: historyItem!['expiry2m']?.toString(),
            expiry5m: historyItem!['expiry5m']?.toString(),
            newsImpact: historyItem!['newsImpact']?.toString(),
            oneLineExplain: historyItem!['oneLineExplain']?.toString(),
          );
        }
      }

      imagePath.value = args['imagePath'] ?? '';

      // Parse sections will be done in postFrameCallback to avoid setState during build
    }
  }

  void _parseSections(String analysis) {
    final sectionPatterns = {
      'stock_info': RegExp(r'## Stock Information(.*?)(?=## |$)', dotAll: true),
      'technical': RegExp(r'## Technical Analysis(.*?)(?=## |$)', dotAll: true),
      'indicators': RegExp(r'## Key Indicators(.*?)(?=## |$)', dotAll: true),
      'recommendation': RegExp(
        r'## Recommendation(.*?)(?=## |$)',
        dotAll: true,
      ),
      'risk': RegExp(r'## Risk Assessment(.*?)(?=## |$)', dotAll: true),
      'summary': RegExp(r'## Summary(.*?)(?=## |$)', dotAll: true),
    };

    for (var entry in sectionPatterns.entries) {
      final match = entry.value.firstMatch(analysis);
      if (match != null && match.group(1) != null) {
        sections[entry.key] = match.group(1)!.trim();
      }
    }

    // Extract quick stats
    _extractQuickStats(analysis);
    // Refresh analysis UI without triggering during build
    update([kAnalysisContentId]);
  }

  void _extractQuickStats(String analysis) {
    // Extract trend direction
    final trendMatch = RegExp(
      r'Current trend.*?:\s*(Bullish|Bearish|Sideways)',
      caseSensitive: false,
    ).firstMatch(analysis);
    if (trendMatch != null) {
      trendDirection.value = trendMatch.group(1) ?? '';
    }

    // Extract risk level
    final riskMatch = RegExp(
      r'Risk level.*?:\s*(LOW|MEDIUM|HIGH)',
      caseSensitive: false,
    ).firstMatch(analysis);
    if (riskMatch != null) {
      riskLevel.value = riskMatch.group(1) ?? '';
    }

    // Extract stock name if visible
    final stockMatch = RegExp(
      r'stock/index.*?:\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(analysis);
    if (stockMatch != null) {
      stockName.value = stockMatch.group(1)?.trim() ?? '';
    }
  }

  void saveToHistory() {
    // Create historyItem from fresh analysis if it doesn't exist
    if (historyItem == null && result.value != null) {
      final r = result.value!;
      historyItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'analysis': r.analysis,
        'recommendation': r.recommendation,
        'timestamp': r.timestamp.toIso8601String(),
        'imagePath': imagePath.value,
        'isFavorite': false,
        'pair': r.pair,
        'direction': r.direction,
        'entryTimeIST': r.entryTimeIST,
        'expiry': r.expiry,
        'confidencePercent': r.confidencePercent,
        'trend': r.trend,
        'expiry30s': r.expiry30s,
        'expiry1m': r.expiry1m,
        'expiry2m': r.expiry2m,
        'expiry5m': r.expiry5m,
        'newsImpact': r.newsImpact,
        'oneLineExplain': r.oneLineExplain,
      };
    }

    if (historyItem != null && !isSaved.value) {
      _storage.addToHistory(historyItem!);
      isSaved.value = true;
      update([kAnalysisContentId]);

      Get.snackbar(
        'success'.tr,
        'save_to_history'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Toggle favorite status
  void toggleFavorite() {
    if (historyItem == null && result.value != null) {
      // Create and save first if not saved
      saveToHistory();
    }

    if (historyItem != null && historyItem!['id'] != null) {
      _storage.toggleFavorite(historyItem!['id']);
      historyItem!['isFavorite'] = _storage.isFavorite(historyItem!['id']);

      final isFav = historyItem!['isFavorite'] == true;
      Get.snackbar(
        isFav ? '❤️ Added to Favorites' : 'Removed from Favorites',
        isFav
            ? 'You can find this in Favorites tab'
            : 'Removed from your favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isFav
            ? Colors.orange.withValues(alpha: 0.9)
            : Colors.grey.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool get isFavorite => historyItem?['isFavorite'] == true;

  void shareAnalysis() {
    if (result.value != null) {
      final shareText =
          '''
📊 Stock Analysis - ${result.value!.recommendation}

${result.value!.analysis}

---
Analyzed with Stock Scanner AI
''';
      SharePlus.instance.share(ShareParams(text: shareText));
    }
  }

  void newScan() {
    Get.back();
  }

  String get recommendation => result.value?.recommendation ?? 'HOLD';
  String get analysis => result.value?.analysis ?? '';
}
