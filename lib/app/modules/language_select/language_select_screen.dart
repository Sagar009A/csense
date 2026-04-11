/// Language Selection Screen
/// Beautiful grid layout for language selection at first launch
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_button.dart';
import '../../common/widgets/common_container.dart';
import '../../common/widgets/common_sizebox.dart';
import '../../translations/app_translations.dart';
import 'language_controller.dart';

class LanguageSelectScreen extends GetView<LanguageController> {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                // Header
                Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      size: 40.w,
                      color: Colors.white,
                    ),
                  ),
                ),
                CommonSizedBox.h24,
                Center(
                  child: CommonText.headline(
                    'select_language',
                    textAlign: TextAlign.center,
                  ),
                ),
                CommonSizedBox.h8,
                Center(
                  child: CommonText.body(
                    'choose_preferred_language',
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    textAlign: TextAlign.center,
                  ),
                ),
                CommonSizedBox.h32,
                // Language Grid
                Expanded(
                  child: Obx(() {
                    // Access observable to ensure GetX tracks changes
                    final selectedLocale = controller.selectedLocale.value;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: controller.languages.length,
                      itemBuilder: (context, index) {
                        final language = controller.languages[index];
                        final isSelected =
                            selectedLocale?.languageCode ==
                                language.locale.languageCode &&
                            selectedLocale?.countryCode ==
                                language.locale.countryCode;

                        return _LanguageCard(
                          language: language,
                          isSelected: isSelected,
                          onTap: () => controller.selectLanguage(language),
                        );
                      },
                    );
                  }),
                ),
                CommonSizedBox.h16,
                // Continue Button
                Obx(
                  () => CommonButton.primary(
                    text: 'continue_text',
                    width: double.infinity,
                    isDisabled: controller.selectedLocale.value == null,
                    onPressed: controller.continueToNextScreen,
                  ),
                ),
                CommonSizedBox.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageInfo language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: CommonContainer(
            padding: EdgeInsets.all(16.r),
            borderRadius: 16,
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withValues(alpha: 0.15)
                : isDark
                ? AppColors.cardDark
                : AppColors.cardLight,
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.flag, style: TextStyle(fontSize: 28.sp)),
                SizedBox(height: 6.h),
                Flexible(
                  child: CommonText.body(
                    language.nativeName,
                    isTranslate: false,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight)
                        : null,
                  ),
                ),
                SizedBox(height: 2.h),
                Flexible(
                  child: CommonText.caption(
                    language.name,
                    isTranslate: false,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
