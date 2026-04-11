/// Intro Screen
/// Beautiful onboarding screens with animations
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_button.dart';
import '../../common/widgets/common_sizebox.dart';
import 'intro_controller.dart';

class IntroScreen extends GetView<IntroController> {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            itemCount: controller.pages.length,
            itemBuilder: (context, index) {
              return _IntroPage(data: controller.pages[index]);
            },
          ),
          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.h,
            right: 24.w,
            child: Obx(
              () => AnimatedOpacity(
                opacity: controller.isLastPage ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: CommonButton.text(
                  text: 'skip',
                  onPressed: controller.isLastPage
                      ? null
                      : controller.skipIntro,
                  textColor: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          // Bottom Navigation
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: MediaQuery.of(context).padding.bottom + 32.h,
            child: Column(
              children: [
                // Page Indicator
                SmoothPageIndicator(
                  controller: controller.pageController,
                  count: controller.pages.length,
                  effect: ExpandingDotsEffect(
                    dotWidth: 8.w,
                    dotHeight: 8.w,
                    expansionFactor: 3,
                    spacing: 8.w,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                CommonSizedBox.h32,
                // Next/Get Started Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: CommonText.button(
                        controller.isLastPage ? 'get_started' : 'next',
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IntroPageData data;

  const _IntroPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: data.gradient.first,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated Icon Container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 160.w,
                  height: 160.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        data.icon,
                        size: 60.w,
                        color: data.gradient.first,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Title
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: CommonText.headline(
                  data.titleKey,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
              ),
              CommonSizedBox.h16,
              // Description
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CommonText.body(
                    data.descriptionKey,
                    color: Colors.white.withValues(alpha: 0.9),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
