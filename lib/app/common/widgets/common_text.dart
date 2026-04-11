/// Common Text Widget
/// A reusable text widget with responsive sizing using ScreenUtil
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CommonText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTranslate;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final double? height;
  final FontStyle? fontStyle;

  const CommonText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTranslate = true,
    this.decoration,
    this.letterSpacing,
    this.height,
    this.fontStyle,
  });

  /// Headline text - Large titles
  factory CommonText.headline(
    String text, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    bool isTranslate = true,
    FontWeight? fontWeight,
  }) {
    return CommonText(
      text: text,
      fontSize: 28,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      isTranslate: isTranslate,
    );
  }

  /// Title text - Section titles
  factory CommonText.title(
    String text, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    bool isTranslate = true,
    FontWeight? fontWeight,
  }) {
    return CommonText(
      text: text,
      fontSize: 22,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      isTranslate: isTranslate,
    );
  }

  /// Subtitle text
  factory CommonText.subtitle(
    String text, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    bool isTranslate = true,
    FontWeight? fontWeight,
  }) {
    return CommonText(
      text: text,
      fontSize: 18,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      isTranslate: isTranslate,
    );
  }

  /// Body text - Regular content
  factory CommonText.body(
    String text, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    bool isTranslate = true,
    FontWeight? fontWeight,
    TextOverflow? overflow,
  }) {
    return CommonText(
      text: text,
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      isTranslate: isTranslate,
    );
  }

  /// Caption text - Small text
  factory CommonText.caption(
    String text, {
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    bool isTranslate = true,
    FontWeight? fontWeight,
    TextOverflow? overflow,
  }) {
    return CommonText(
      text: text,
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      isTranslate: isTranslate,
    );
  }

  /// Button text
  factory CommonText.button(
    String text, {
    Color? color,
    TextAlign? textAlign,
    bool isTranslate = true,
  }) {
    return CommonText(
      text: text,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
      textAlign: textAlign,
      isTranslate: isTranslate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = isTranslate ? text.tr : text;

    return Text(
      displayText,
      style: TextStyle(
        fontSize: (fontSize ?? 14).sp,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
        decoration: decoration,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
