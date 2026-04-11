/// Intro Controller
/// Manages onboarding/intro screens
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class IntroController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<IntroPageData> pages = [
    IntroPageData(
      icon: Icons.auto_graph_rounded,
      titleKey: 'intro_title_1',
      descriptionKey: 'intro_desc_1',
      gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    IntroPageData(
      icon: Icons.history_rounded,
      titleKey: 'intro_title_2',
      descriptionKey: 'intro_desc_2',
      gradient: const [Color(0xFF8B5CF6), Color(0xFF10B981)],
    ),
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (isLastPage) {
      completeIntro();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipIntro() {
    completeIntro();
  }

  void completeIntro() {
    _storage.hasSeenIntro = true;
    _storage.hasSeenIntro = true;

    // Enforce mandatory login
    final bool isLoggedIn = Get.find<AuthService>().isLoggedIn;
    if (isLoggedIn) {
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class IntroPageData {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final List<Color> gradient;

  IntroPageData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.gradient,
  });
}
