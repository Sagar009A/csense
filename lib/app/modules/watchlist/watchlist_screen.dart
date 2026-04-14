/// Watchlist Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../services/watchlist_service.dart';
import 'watchlist_controller.dart';

class WatchlistScreen extends GetView<WatchlistController> {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'watchlist'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF8B5CF6)),
            onPressed: controller.showAddDialog,
            tooltip: 'Add Symbol',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        onPressed: controller.showAddDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
        }
        if (controller.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border_rounded, size: 64.w,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                SizedBox(height: 16.h),
                Text('no_symbols_watchlist'.tr, style: TextStyle(fontSize: 16.sp,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                SizedBox(height: 8.h),
                Text('add_symbols_hint'.tr, style: TextStyle(fontSize: 13.sp,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.r),
          itemCount: controller.items.length,
          itemBuilder: (_, i) {
            final item = controller.items[i] as WatchlistItem;
            return _WatchlistCard(item: item, isDark: isDark, controller: controller);
          },
        );
      }),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final WatchlistItem item;
  final bool isDark;
  final WatchlistController controller;

  const _WatchlistCard({required this.item, required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                item.symbol.length > 3 ? item.symbol.substring(0, 3) : item.symbol,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.symbol, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                Text(item.name, style: TextStyle(fontSize: 12.sp,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                if (item.notes.isNotEmpty)
                  Text(item.notes, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF8B5CF6)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => controller.removeItem(item.id, item.symbol),
          ),
        ],
      ),
    );
  }
}
