/// AI Chat Controller
/// Manages follow-up conversation with Gemini about a chart analysis
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/gemini_service.dart';
import '../../services/credit_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final TextEditingController inputController = TextEditingController();

  late final String analysisContext;
  GeminiService? _gemini;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    analysisContext = args?['analysisContext'] as String? ?? '';
    // Add welcome message
    messages.add(ChatMessage(
      text: 'I\'ve analyzed your chart. Ask me anything about the analysis — patterns, entry points, risk levels, or trading strategy!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }

  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    // Deduct 1 credit per message
    if (Get.isRegistered<CreditService>()) {
      final hasCredits = CreditService.to.hasCredits();
      if (!hasCredits) {
        Get.snackbar(
          'No Credits',
          'You need credits to use AI Chat. Please purchase more.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }
    }

    inputController.clear();
    messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    isLoading.value = true;

    // Build history from existing messages (skip first welcome message)
    final history = messages
        .skip(1) // skip welcome
        .where((m) => !m.isUser || m.text != text) // exclude current message
        .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
        .toList();

    try {
      // Deduct credit
      if (Get.isRegistered<CreditService>()) {
        await CreditService.to.deductCredit();
      }

      _gemini ??= Get.isRegistered<GeminiService>()
          ? Get.find<GeminiService>()
          : await Get.putAsync(() => GeminiService().init());

      final response = await _gemini!.chatWithAnalysis(
        analysisContext: analysisContext,
        history: history,
        userMessage: text,
      );

      messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
    } catch (e) {
      debugPrint('ChatController: error: $e');
      messages.add(ChatMessage(
        text: 'Sorry, I couldn\'t process your question. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
    }
  }
}
