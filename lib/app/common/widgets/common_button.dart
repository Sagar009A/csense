/// Common Button Widget
/// Reusable button widgets with various styles
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import 'common_text.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final Widget? icon;
  final bool iconAfterText;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final bool isOutlined;
  final bool isTextOnly;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.icon,
    this.iconAfterText = false,
    this.padding,
    this.gradientColors,
    this.isOutlined = false,
    this.isTextOnly = false,
  });

  /// Primary gradient button
  factory CommonButton.primary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      gradientColors: AppColors.primaryGradient,
      icon: icon,
    );
  }

  /// Secondary outlined button
  factory CommonButton.secondary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      icon: icon,
      isOutlined: true,
    );
  }

  /// Text only button
  factory CommonButton.text({
    required String text,
    VoidCallback? onPressed,
    Color? textColor,
    Widget? icon,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      textColor: textColor,
      icon: icon,
      isTextOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isTextOnly) {
      return _buildTextButton(isDark);
    }

    if (isOutlined) {
      return _buildOutlinedButton(isDark);
    }

    return _buildPrimaryButton(isDark);
  }

  Widget _buildPrimaryButton(bool isDark) {
    final effectiveBackgroundColor =
        backgroundColor ??
        (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    return SizedBox(
      width: width?.w,
      height: (height ?? 52).h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradientColors != null
              ? LinearGradient(
                  colors: isDisabled
                      ? gradientColors!
                            .map((c) => c.withValues(alpha: 0.5))
                            .toList()
                      : gradientColors!,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: gradientColors == null
              ? (isDisabled
                    ? effectiveBackgroundColor.withValues(alpha: 0.5)
                    : effectiveBackgroundColor)
              : null,
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: (gradientColors?.first ?? effectiveBackgroundColor)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
            child: Center(
              child: Padding(
                padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
                child: isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            textColor ?? Colors.white,
                          ),
                        ),
                      )
                    : _buildContent(textColor ?? Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(bool isDark) {
    final borderColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return SizedBox(
      width: width?.w,
      height: (height ?? 52).h,
      child: OutlinedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDisabled
                ? borderColor.withValues(alpha: 0.5)
                : borderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                ),
              )
            : _buildContent(borderColor),
      ),
    );
  }

  Widget _buildTextButton(bool isDark) {
    final color =
        textColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: 4.w)],
          CommonText(
            text: text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color contentColor) {
    final children = <Widget>[
      if (icon != null && !iconAfterText) ...[icon!, SizedBox(width: 8.w)],
      CommonText.button(text, color: contentColor),
      if (icon != null && iconAfterText) ...[SizedBox(width: 8.w), icon!],
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
