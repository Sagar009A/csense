/// Common TextField Widget
/// A reusable text field with responsive sizing
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CommonTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  /// Search text field variant
  factory CommonTextField.search({
    TextEditingController? controller,
    String? hintText,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onClear,
  }) {
    return CommonTextField(
      controller: controller,
      hintText: hintText ?? 'search'.tr,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      style: TextStyle(
        fontSize: 16.sp,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hintText?.tr,
        labelText: labelText?.tr,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            fillColor ??
            (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        contentPadding:
            contentPadding ??
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          borderSide: BorderSide(
            color:
                borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          borderSide: BorderSide(
            color:
                borderColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadius ?? 12).r),
          borderSide: BorderSide(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
