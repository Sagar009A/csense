/// Legal WebView Screen
/// Shows Privacy Policy or Terms & Conditions with loading animation until page loads
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';

class LegalWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const LegalWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );
    if (widget.url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.url));
    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: widget.url.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.w,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Invalid URL',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text('go_back'.tr),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  AnimatedOpacity(
                    opacity: _isLoading ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 52.w,
                              height: 52.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'loading'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
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
              ],
            ),
    );
  }
}

