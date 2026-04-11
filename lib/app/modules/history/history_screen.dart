/// History Screen
/// Displays saved analysis history
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_textfield.dart';
import '../../common/widgets/common_container.dart';
import '../../common/widgets/common_sizebox.dart';
import 'history_controller.dart';

class HistoryScreen extends GetView<HistoryController> {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: CommonText.title('history'),
        actions: [
          Obx(
            () => controller.historyList.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: controller.confirmClearHistory,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    controller: controller.searchController,
                    hintText: 'search_history',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Obx(
                      () => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink(),
                    ),
                    onChanged: controller.onSearchChanged,
                  ),
                ),
                SizedBox(width: 12.w),
                // Favorites Toggle
                Obx(
                  () => GestureDetector(
                    onTap: controller.toggleFavoritesFilter,
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: controller.showFavoritesOnly.value
                            ? AppColors.primaryLight
                            : (isDark ? AppColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: controller.showFavoritesOnly.value
                              ? AppColors.primaryLight
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                        ),
                      ),
                      child: Icon(
                        controller.showFavoritesOnly.value
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: controller.showFavoritesOnly.value
                            ? Colors.white
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: Obx(() {
              if (controller.historyList.isEmpty) {
                return _buildEmptyState(isDark);
              }

              if (controller.filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.showFavoritesOnly.value
                            ? Icons.favorite_border_rounded
                            : Icons.search_off_rounded,
                        size: 48.w,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      SizedBox(height: 16.h),
                      CommonText.body(
                        controller.showFavoritesOnly.value
                            ? 'No favorites yet'
                            : 'No results found',
                        isTranslate: false,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  final item = controller.filteredList[index];
                  return _HistoryCard(
                    item: item,
                    isDark: isDark,
                    onTap: () => controller.openAnalysis(item),
                    onDelete: () => controller.deleteItem(item['id']),
                    onFavorite: () => controller.toggleFavorite(item['id']),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48.w,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
            CommonSizedBox.h24,
            CommonText.subtitle(
              'no_history',
              textAlign: TextAlign.center,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = item['recommendation'] ?? 'HOLD';
    final timestamp = DateTime.parse(item['timestamp']);
    final formattedDate = _formatDate(timestamp);
    final isFavorite = item['isFavorite'] == true;

    Color recommendationColor;
    switch (recommendation) {
      case 'BUY':
        recommendationColor = AppColors.successLight;
        break;
      case 'SELL':
        recommendationColor = AppColors.errorLight;
        break;
      default:
        recommendationColor = AppColors.warningLight;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: Key(item['id']),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(Icons.delete_rounded, color: Colors.white, size: 24.w),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: CommonContainer(
              padding: EdgeInsets.all(16.r),
              borderRadius: 16,
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: item['imagePath'] != null
                          ? Image.file(
                              File(item['imagePath']),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholder(isDark),
                            )
                          : _buildPlaceholder(isDark),
                    ),
                  ),
                  CommonSizedBox.w16,
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: recommendationColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: CommonText.caption(
                                recommendation,
                                isTranslate: false,
                                color: recommendationColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        CommonSizedBox.h8,
                        CommonText.body(
                          'Stock Status',
                          isTranslate: false,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        CommonSizedBox.h4,
                        CommonText.caption(
                          formattedDate,
                          isTranslate: false,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Colors.red
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        size: 24.w,
                      ),
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    size: 24.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          size: 32.w,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
