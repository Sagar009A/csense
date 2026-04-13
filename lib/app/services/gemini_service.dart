/// Gemini Service
/// Handles AI analysis using Google Gemini API
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';
import 'app_config_service.dart';
import 'storage_service.dart';

class GeminiService extends GetxService {
  GenerativeModel? _model;
  late final AppConfigService _config;

  Future<GeminiService> init() async {
    try {
      _config = Get.find<AppConfigService>();
    } catch (e) {
      debugPrint(
        'GeminiService: AppConfigService not found, initializing it now...',
      );
      // Initialize AppConfigService if not already done
      _config = await Get.putAsync(() => AppConfigService().init());
    }

    final apiKey = _config.geminiApiKey.value.trim();
    if (apiKey.isEmpty) {
      debugPrint(
        'GeminiService: API key not configured, service will fail on use',
      );
      // Don't throw here - allow service to initialize but fail gracefully on use
      return this;
    }

    _model = GenerativeModel(
      model: _config.geminiModel.value.trim().isNotEmpty
          ? _config.geminiModel.value.trim()
          : ApiConstants.geminiModel,
      apiKey: apiKey,
    );
    return this;
  }

  /// Get the language name from saved locale code
  String _getLanguageName() {
    try {
      final storageService = Get.find<StorageService>();
      final savedLang = storageService.savedLanguage;

      if (savedLang == null) return 'English';

      // Map locale codes to language names
      final languageMap = {
        'en_US': 'English',
        'hi_IN': 'Hindi',
        'es_ES': 'Spanish',
        'fr_FR': 'French',
        'de_DE': 'German',
        'zh_CN': 'Chinese (Simplified)',
        'ja_JP': 'Japanese',
        'ar_SA': 'Arabic',
      };

      return languageMap[savedLang] ?? 'English';
    } catch (e) {
      return 'English';
    }
  }

  /// Analyze stock chart image
  Future<StockAnalysisResult> analyzeStockChart(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      return await analyzeStockChartFromBytes(imageBytes);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  /// Analyze stock chart from bytes
  Future<StockAnalysisResult> analyzeStockChartFromBytes(
    Uint8List imageBytes,
  ) async {
    try {
      // Check if model is initialized
      if (_model == null) {
        final apiKey = _config.geminiApiKey.value.trim();
        if (apiKey.isEmpty) {
          throw Exception(
            'Gemini API key not configured. Please set it in admin panel.',
          );
        }
        _model = GenerativeModel(
          model: _config.geminiModel.value.trim().isNotEmpty
              ? _config.geminiModel.value.trim()
              : ApiConstants.geminiModel,
          apiKey: apiKey,
        );
      }

      final model = _model;
      if (model == null) {
        throw Exception('Gemini model not initialized');
      }

      final language = _getLanguageName();

      final prompt = _buildPrompt(language);

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);
      final analysisText = response.text ?? 'Unable to analyze the image.';

      // Extract recommendation from the analysis
      String recommendation = 'HOLD';
      if (analysisText.toUpperCase().contains('RECOMMENDATION: BUY') ||
          analysisText.toUpperCase().contains('OVERALL RECOMMENDATION: BUY') ||
          analysisText.toUpperCase().contains('BUY')) {
        recommendation = 'BUY';
      } else if (analysisText.toUpperCase().contains('RECOMMENDATION: SELL') ||
          analysisText.toUpperCase().contains('OVERALL RECOMMENDATION: SELL') ||
          analysisText.toUpperCase().contains('SELL')) {
        recommendation = 'SELL';
      }

      final advanced = _parseAdvancedFields(analysisText);

      return StockAnalysisResult(
        analysis: analysisText,
        recommendation: recommendation,
        timestamp: DateTime.now(),
        pair: advanced['pair'],
        direction: advanced['direction'],
        entryTimeIST: advanced['entryTimeIST'],
        expiry: advanced['expiry'],
        confidencePercent: advanced['confidencePercent'],
        trend: advanced['trend'],
        expiry30s: advanced['expiry30s'],
        expiry1m: advanced['expiry1m'],
        expiry2m: advanced['expiry2m'],
        expiry5m: advanced['expiry5m'],
        newsImpact: advanced['newsImpact'],
        oneLineExplain: advanced['oneLineExplain'],
      );
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  String _buildPrompt(String language) {
    final configuredPrompt = _config.analysisPrompt.value.trim();
    if (configuredPrompt.isNotEmpty) {
      final withLanguage = configuredPrompt.contains('{{language}}')
          ? configuredPrompt.replaceAll('{{language}}', language)
          : configuredPrompt;

      if (withLanguage.contains('IMPORTANT:')) {
        return withLanguage;
      }

      return '$withLanguage\n\nIMPORTANT: You MUST respond entirely in $language language.';
    }

    return _buildDefaultPrompt(language);
  }

  Map<String, dynamic> _parseAdvancedFields(String text) {
    final result = <String, dynamic>{};
    String? getLine(String pattern) {
      final r = RegExp(pattern, caseSensitive: false, dotAll: true);
      final m = r.firstMatch(text);
      return m?.group(1)?.trim();
    }

    result['pair'] =
        getLine(r'Pair:\s*([^\n]+)') ?? getLine(r'\*\s*Pair:\s*([^\n]+)');
    result['direction'] = getLine(r'Direction:\s*([^\n]+)');
    result['entryTimeIST'] =
        getLine(r'Entry Time\s*\(IST\):\s*([^\n]+)') ??
        getLine(r'Entry Time:\s*([^\n]+)');
    result['expiry'] = getLine(r'Expiry:\s*([^\n]+)');
    final confStr = getLine(r'Confidence:\s*([^\n]+)');
    if (confStr != null) {
      final num = int.tryParse(RegExp(r'\d+').stringMatch(confStr) ?? '');
      if (num != null) result['confidencePercent'] = num;
    }
    result['trend'] = getLine(r'Trend:\s*([^\n]+)');
    result['expiry30s'] = getLine(r'30\s*sec:\s*([^\n]+)');
    result['expiry1m'] = getLine(r'1\s*min:\s*([^\n]+)');
    result['expiry2m'] = getLine(r'2\s*min:\s*([^\n]+)');
    result['expiry5m'] = getLine(r'5\s*min:\s*([^\n]+)');
    result['newsImpact'] = getLine(r'Impact:\s*([^\n]+)');
    result['oneLineExplain'] =
        getLine(r'One-Line Explain:\s*([^\n]+)') ??
        getLine(r'One short sentence[^\n]*:\s*([^\n]+)');
    return result;
  }

  String _buildDefaultPrompt(String language) {
    return '''
You are an expert stock market analyst. Analyze this stock chart image and provide a comprehensive analysis.

**IMPORTANT: You MUST respond entirely in $language language. All text, headings, and content should be in $language.**

Please provide your analysis in the following structured format:

## Stock Information
- Identify the stock/index if visible
- Current trend direction (Bullish/Bearish/Sideways)
- Timeframe analysis

## Technical Analysis
- Support levels
- Resistance levels
- Chart patterns identified (e.g., Head & Shoulders, Triangle, etc.)
- Moving averages if visible
- Volume analysis if visible

## Key Indicators
- RSI analysis if visible
- MACD analysis if visible
- Other technical indicators

## Recommendation
- Overall recommendation: BUY / SELL / HOLD
- Entry points
- Stop loss suggestion
- Target prices

## Risk Assessment
- Risk level: LOW / MEDIUM / HIGH
- Key risks to watch

## Summary
Provide a brief 2-3 sentence summary of your analysis.

## Binary Signal (for credited users - use exact keys)
- Pair: (e.g. EUR/USD or NIFTY 50)
- Direction: CALL or PUT
- Entry Time (IST): (e.g. 14:32)
- Expiry: (e.g. 1 Minute, 30 Seconds, 2 Minutes, 5 Minutes)
- Confidence: (number 0-100 only, e.g. 82)
- Trend: Bullish or Bearish or Sideways

## Expiry-Wise Suggestion (one line each)
- 30 sec: avoid or best or risky or trend slow
- 1 min: avoid or best or risky or trend slow
- 2 min: avoid or best or risky or trend slow
- 5 min: avoid or best or risky or trend slow

## News Impact
- Impact: HIGH or MEDIUM or NONE (HIGH = NO TRADE, MEDIUM = Low lot, NONE = Safe window)

## One-Line Explain
- One short sentence summarizing the trade signal.

Be specific and data-driven. If information is not visible, say "not available".

Remember: Your ENTIRE response must be in $language language.
''';
  }

  /// Chat with Gemini using the analysis result as context.
  /// Returns the AI response text, or throws on failure.
  Future<String> chatWithAnalysis({
    required String analysisContext,
    required List<Map<String, String>> history,
    required String userMessage,
  }) async {
    if (_model == null) {
      final apiKey = _config.geminiApiKey.value.trim();
      if (apiKey.isEmpty) throw Exception('Gemini API key not configured.');
      _model = GenerativeModel(
        model: _config.geminiModel.value.trim().isNotEmpty
            ? _config.geminiModel.value.trim()
            : ApiConstants.geminiModel,
        apiKey: apiKey,
      );
    }

    final language = _getLanguageName();

    // Build the system instruction + context as first user message
    final systemPrompt =
        'You are an expert stock market and forex trading analyst. '
        'The user has previously analyzed a chart using AI. Below is the analysis result:\n\n'
        '$analysisContext\n\n'
        'Answer the user\'s follow-up questions about this analysis in $language. '
        'Be concise, clear, and helpful.';

    // Build conversation history as Content list
    final contents = <Content>[
      Content.user([TextPart(systemPrompt)]),
      Content.model([TextPart('Understood. I\'m ready to answer follow-up questions about this analysis.')]),
      // Previous conversation
      for (final msg in history)
        if (msg['role'] == 'user')
          Content.user([TextPart(msg['text'] ?? '')])
        else
          Content.model([TextPart(msg['text'] ?? '')]),
      // Current message
      Content.user([TextPart(userMessage)]),
    ];

    final response = await _model!.generateContent(contents);
    return response.text ?? 'Sorry, I could not generate a response.';
  }
}

/// Stock Analysis Result Model
class StockAnalysisResult {
  final String analysis;
  final String recommendation;
  final DateTime timestamp;
  final String? stockName;
  final String? riskLevel;
  // Advanced (credit-gated) fields
  final String? pair;
  final String? direction; // CALL / PUT
  final String? entryTimeIST;
  final String? expiry;
  final int? confidencePercent;
  final String? trend;
  final String? expiry30s;
  final String? expiry1m;
  final String? expiry2m;
  final String? expiry5m;
  final String? newsImpact;
  final String? oneLineExplain;

  StockAnalysisResult({
    required this.analysis,
    required this.recommendation,
    required this.timestamp,
    this.stockName,
    this.riskLevel,
    this.pair,
    this.direction,
    this.entryTimeIST,
    this.expiry,
    this.confidencePercent,
    this.trend,
    this.expiry30s,
    this.expiry1m,
    this.expiry2m,
    this.expiry5m,
    this.newsImpact,
    this.oneLineExplain,
  });

  bool get hasAdvancedData =>
      (confidencePercent != null && confidencePercent! > 0) ||
      (pair != null && pair!.isNotEmpty) ||
      (direction != null && direction!.isNotEmpty);

  Map<String, dynamic> toJson() => {
    'analysis': analysis,
    'recommendation': recommendation,
    'timestamp': timestamp.toIso8601String(),
    'stockName': stockName,
    'riskLevel': riskLevel,
    'pair': pair,
    'direction': direction,
    'entryTimeIST': entryTimeIST,
    'expiry': expiry,
    'confidencePercent': confidencePercent,
    'trend': trend,
    'expiry30s': expiry30s,
    'expiry1m': expiry1m,
    'expiry2m': expiry2m,
    'expiry5m': expiry5m,
    'newsImpact': newsImpact,
    'oneLineExplain': oneLineExplain,
  };

  factory StockAnalysisResult.fromJson(Map<String, dynamic> json) {
    return StockAnalysisResult(
      analysis: json['analysis'] ?? '',
      recommendation: json['recommendation'] ?? 'HOLD',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      stockName: json['stockName']?.toString(),
      riskLevel: json['riskLevel']?.toString(),
      pair: json['pair']?.toString(),
      direction: json['direction']?.toString(),
      entryTimeIST: json['entryTimeIST']?.toString(),
      expiry: json['expiry']?.toString(),
      confidencePercent: (json['confidencePercent'] as num?)?.toInt(),
      trend: json['trend']?.toString(),
      expiry30s: json['expiry30s']?.toString(),
      expiry1m: json['expiry1m']?.toString(),
      expiry2m: json['expiry2m']?.toString(),
      expiry5m: json['expiry5m']?.toString(),
      newsImpact: json['newsImpact']?.toString(),
      oneLineExplain: json['oneLineExplain']?.toString(),
    );
  }
}
