/// App Color Constants
/// Defines vibrant color palette for both light and dark themes
/// Modern Gradient Theme - Purple/Cyan/Orange
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Vibrant Purple
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFFA78BFA);

  // Secondary Colors - Cyan/Teal
  static const Color secondaryLight = Color(0xFF06B6D4);
  static const Color secondaryDark = Color(0xFF22D3EE);

  // Accent Colors - Warm Orange
  static const Color accentLight = Color(0xFFFF6B35);
  static const Color accentDark = Color(0xFFFF8C00);

  // Success Colors - Vibrant Green
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);

  // Error Colors - Bright Red
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);

  // Warning Colors - Amber
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0A0A0F);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF13131A);

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A24);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);

  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D2D3A);

  // Vibrant Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF06B6D4),
    Color(0xFF0891B2),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFF8C00),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A0A0F),
    Color(0xFF13131A),
  ];

  static const List<Color> glassGradient = [
    Color(0x1A8B5CF6),
    Color(0x0A8B5CF6),
  ];

  // Shimmer Colors
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);
  static const Color shimmerBaseDark = Color(0xFF2D2D3A);
  static const Color shimmerHighlightDark = Color(0xFF3D3D4A);

  // Stock Colors
  static const Color stockUp = Color(0xFF10B981);
  static const Color stockDown = Color(0xFFEF4444);
  static const Color stockNeutral = Color(0xFF64748B);
}
