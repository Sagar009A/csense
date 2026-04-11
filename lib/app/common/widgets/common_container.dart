/// Common Container Widget
/// A reusable container with glassmorphism and gradient effects
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class CommonContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<Color>? gradientColors;
  final double? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final bool isGlass;
  final VoidCallback? onTap;

  const CommonContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.gradientColors,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.alignment,
    this.isGlass = false,
    this.onTap,
  });

  /// Glass morphism container
  factory CommonContainer.glass({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      isGlass: true,
      onTap: onTap,
      child: child,
    );
  }

  /// Gradient container
  factory CommonContainer.gradient({
    required Widget child,
    required List<Color> colors,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      gradientColors: colors,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  /// Card style container
  factory CommonContainer.card({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return CommonContainer(
      width: width,
      height: height,
      padding: padding ?? EdgeInsets.all(16.r),
      margin: margin,
      borderRadius: 16,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final radius = BorderRadius.circular((borderRadius ?? 12).r);

    Widget container;

    if (isGlass) {
      container = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: width?.w,
            height: height?.h,
            padding: padding,
            margin: margin,
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : AppColors.glassGradient,
              ),
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                  ),
            ),
            child: child,
          ),
        ),
      );
    } else {
      container = Container(
        width: width?.w,
        height: height?.h,
        padding: padding,
        margin: margin,
        alignment: alignment,
        decoration: BoxDecoration(
          color: gradientColors == null ? bgColor : null,
          gradient: gradientColors != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors!,
                )
              : null,
          borderRadius: radius,
          border: border,
          boxShadow: boxShadow,
        ),
        child: child,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: container),
      );
    }

    return container;
  }
}
