import 'package:flutter/material.dart';

class PlayerColors {
  static const Color primary = Color(0xFF1E1E1E);
  static const Color secondary = Color(0xFFFF3D00);
  static const Color surface = Color(0xFF2D2D2D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color bufferIndicator = Color(0xFF4CAF50);
  static const Color bufferBackground = Color(0xFF333333);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
}

class PlayerSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
}

class PlayerDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

class PlaybackSpeeds {
  static const List<double> speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const double defaultSpeed = 1.0;
}
