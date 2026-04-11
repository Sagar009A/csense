/// Common SizedBox Widget
/// Convenient sized boxes using ScreenUtil
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const CommonSizedBox({super.key, this.width, this.height, this.child});

  /// Horizontal spacing
  factory CommonSizedBox.w(double width) {
    return CommonSizedBox(width: width);
  }

  /// Vertical spacing
  factory CommonSizedBox.h(double height) {
    return CommonSizedBox(height: height);
  }

  /// Common horizontal spacings
  static Widget get w4 => SizedBox(width: 4.w);
  static Widget get w8 => SizedBox(width: 8.w);
  static Widget get w12 => SizedBox(width: 12.w);
  static Widget get w16 => SizedBox(width: 16.w);
  static Widget get w20 => SizedBox(width: 20.w);
  static Widget get w24 => SizedBox(width: 24.w);
  static Widget get w32 => SizedBox(width: 32.w);

  /// Common vertical spacings
  static Widget get h4 => SizedBox(height: 4.h);
  static Widget get h8 => SizedBox(height: 8.h);
  static Widget get h12 => SizedBox(height: 12.h);
  static Widget get h16 => SizedBox(height: 16.h);
  static Widget get h20 => SizedBox(height: 20.h);
  static Widget get h24 => SizedBox(height: 24.h);
  static Widget get h32 => SizedBox(height: 32.h);
  static Widget get h40 => SizedBox(height: 40.h);
  static Widget get h48 => SizedBox(height: 48.h);
  static Widget get h64 => SizedBox(height: 64.h);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width?.w, height: height?.h, child: child);
  }
}

/// Extension for convenient SizedBox creation
extension SizedBoxExtension on num {
  Widget get sw => SizedBox(width: toDouble().w);
  Widget get sh => SizedBox(height: toDouble().h);
}
