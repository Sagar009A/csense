/// Announcement Dialog
/// Full-screen overlay popup shown on home screen when admin publishes an announcement.
/// Matches the reference screenshot style: dark overlay, white card, X close button.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/announcement_service.dart';

class AnnouncementDialog extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  /// Show the dialog and mark it as seen on close.
  static Future<void> show(AnnouncementModel announcement) {
    return Get.dialog(
      AnnouncementDialog(announcement: announcement),
      barrierColor: Colors.black.withValues(alpha: 0.72),
      barrierDismissible: true,
    ).then((_) {
      // Mark seen after dialog is dismissed (tap outside or X button)
      if (announcement.showOnce) {
        AnnouncementService.to.markSeen(announcement.announcementId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = announcement.imageUrl.isNotEmpty;
    final bool hasButton =
        announcement.buttonText.isNotEmpty && announcement.buttonUrl.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Card ────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Banner image ─────────────────────────────────────
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: announcement.imageUrl,
                        height: 180.h,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180.h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 120.h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.campaign_rounded,
                              size: 48.w,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      // Gradient header strip when no image
                      Container(
                        height: 72.h,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.campaign_rounded,
                            size: 36.w,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),

                    // ── Text content ─────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            announcement.message,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── CTA button ───────────────────────────────────────
                    if (hasButton)
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                        child: GestureDetector(
                          onTap: () => _launchUrl(announcement.buttonUrl),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6366F1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              announcement.buttonText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Close text link ──────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'Close',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── X close button (top-right, outside card) ─────────────
              Positioned(
                top: -14.h,
                right: -14.w,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.isAbsolute) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}
