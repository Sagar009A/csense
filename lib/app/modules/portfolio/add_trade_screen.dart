/// Add Trade Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import 'add_trade_controller.dart';

class AddTradeScreen extends GetView<AddTradeController> {
  const AddTradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : AppColors.textPrimaryLight),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Add Trade',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(isDark, 'Symbol'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller.symbolController,
              isDark,
              hint: 'e.g. NIFTY, EUR/USD',
              capitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 16.h),
            _buildLabel(isDark, 'Trade Type'),
            SizedBox(height: 8.h),
            Obx(() => Row(
                  children: [
                    _buildTypeChip('long', 'Long (Buy)', Colors.green, isDark),
                    SizedBox(width: 12.w),
                    _buildTypeChip('short', 'Short (Sell)', Colors.red, isDark),
                  ],
                )),
            SizedBox(height: 16.h),
            _buildLabel(isDark, 'Buy / Entry Price'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller.buyPriceController,
              isDark,
              hint: 'e.g. 21500.50',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16.h),
            _buildLabel(isDark, 'Quantity / Lots'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller.quantityController,
              isDark,
              hint: 'e.g. 10',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16.h),
            _buildLabel(isDark, 'Current Price (optional)'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller.currentPriceController,
              isDark,
              hint: 'Leave blank to use buy price',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16.h),
            _buildLabel(isDark, 'Notes (optional)'),
            SizedBox(height: 6.h),
            _buildTextField(
              controller.notesController,
              isDark,
              hint: 'Strategy, remarks...',
              maxLines: 3,
            ),
            SizedBox(height: 32.h),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value ? null : controller.saveTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text('Save Trade',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    bool isDark, {
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: TextStyle(
          fontSize: 15.sp,
          color: isDark ? Colors.white : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13.sp,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, Color color, bool isDark) {
    final isSelected = controller.tradeType.value == value;
    return GestureDetector(
      onTap: () => controller.tradeType.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
