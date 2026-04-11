/// Calculator Screen
/// Forex and Stock Market Calculators with premium amber theme
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/banner_ad_widget.dart';
import 'calculator_controller.dart';

class CalculatorContent extends StatelessWidget {
  final bool isDark;

  const CalculatorContent({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CalculatorController());

    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 8.h),
            // Banner Ad
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: BannerAdWidget(),
            ),
            SizedBox(height: 8.h),
            _buildCalculatorTabs(controller),
            SizedBox(height: 16.h),
            Expanded(child: Obx(() => _buildCalculatorContent(controller))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.calculate_rounded,
              color: Colors.white,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculators',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'Forex & Stock Tools',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTabs(CalculatorController controller) {
    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: controller.calculators.length,
        itemBuilder: (context, index) {
          final calc = controller.calculators[index];
          return Obx(() {
            final isSelected = controller.selectedCalculator.value == index;
            return GestureDetector(
              onTap: () => controller.selectCalculator(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90.w,
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(16.r),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      calc.icon,
                      size: 28.w,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.primaryLight),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      calc.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildCalculatorContent(CalculatorController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          _buildCurrentCalculator(controller),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildCurrentCalculator(CalculatorController controller) {
    switch (controller.selectedCalculator.value) {
      case 0:
        return _buildProfitLossCalculator(controller);
      case 1:
        return _buildPipValueCalculator(controller);
      case 2:
        return _buildPositionSizeCalculator(controller);
      case 3:
        return _buildRiskRewardCalculator(controller);
      case 4:
        return _buildMarginCalculator(controller);
      default:
        return _buildProfitLossCalculator(controller);
    }
  }

  Widget _buildProfitLossCalculator(CalculatorController controller) {
    return _CalculatorCard(
      isDark: isDark,
      title: 'Profit/Loss Calculator',
      children: [
        // Long/Short Toggle
        Obx(
          () => Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.isLong.value = true,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: controller.isLong.value
                          ? AppColors.successLight
                          : (isDark
                                ? AppColors.cardDark
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        'LONG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: controller.isLong.value
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.isLong.value = false,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: !controller.isLong.value
                          ? AppColors.errorLight
                          : (isDark
                                ? AppColors.cardDark
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        'SHORT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !controller.isLong.value
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _InputField(
          isDark: isDark,
          label: 'Entry Price',
          controller: controller.entryPriceController,
          hint: '0.00',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Exit Price',
          controller: controller.exitPriceController,
          hint: '0.00',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Quantity/Shares',
          controller: controller.quantityController,
          hint: '100',
        ),
        SizedBox(height: 20.h),
        _CalculateButton(onTap: controller.calculateProfitLoss),
        SizedBox(height: 20.h),
        Obx(
          () => _ResultCard(
            isDark: isDark,
            title: 'Profit/Loss',
            value: '\$${controller.profitLoss.value.toStringAsFixed(2)}',
            subtitle:
                '${controller.profitLossPercent.value.toStringAsFixed(2)}%',
            isPositive: controller.profitLoss.value >= 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPipValueCalculator(CalculatorController controller) {
    return _CalculatorCard(
      isDark: isDark,
      title: 'Pip Value Calculator',
      children: [
        Obx(
          () => _DropdownField(
            isDark: isDark,
            label: 'Currency Pair',
            value: controller.selectedPair.value,
            items: controller.currencyPairs,
            onChanged: (val) => controller.selectedPair.value = val!,
          ),
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Lot Size',
          controller: controller.lotSizeController,
          hint: '1.0',
        ),
        SizedBox(height: 20.h),
        _CalculateButton(onTap: controller.calculatePipValue),
        SizedBox(height: 20.h),
        Obx(
          () => _ResultCard(
            isDark: isDark,
            title: 'Pip Value',
            value: '\$${controller.pipValue.value.toStringAsFixed(2)}',
            subtitle: 'Per pip',
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSizeCalculator(CalculatorController controller) {
    return _CalculatorCard(
      isDark: isDark,
      title: 'Position Size Calculator',
      children: [
        _InputField(
          isDark: isDark,
          label: 'Account Balance (\$)',
          controller: controller.accountBalanceController,
          hint: '10000',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Risk Per Trade (%)',
          controller: controller.riskPercentController,
          hint: '2',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Stop Loss (Pips)',
          controller: controller.stopLossPipsController,
          hint: '50',
        ),
        SizedBox(height: 20.h),
        _CalculateButton(onTap: controller.calculatePositionSize),
        SizedBox(height: 20.h),
        Obx(
          () => _ResultCard(
            isDark: isDark,
            title: 'Position Size',
            value: '${controller.positionSize.value.toStringAsFixed(2)} Lots',
            subtitle: 'Recommended size',
          ),
        ),
      ],
    );
  }

  Widget _buildRiskRewardCalculator(CalculatorController controller) {
    return _CalculatorCard(
      isDark: isDark,
      title: 'Risk/Reward Calculator',
      children: [
        _InputField(
          isDark: isDark,
          label: 'Entry Price',
          controller: controller.rrEntryController,
          hint: '0.00',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Stop Loss',
          controller: controller.rrStopLossController,
          hint: '0.00',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Take Profit',
          controller: controller.rrTakeProfitController,
          hint: '0.00',
        ),
        SizedBox(height: 20.h),
        _CalculateButton(onTap: controller.calculateRiskReward),
        SizedBox(height: 20.h),
        Obx(
          () => _ResultCard(
            isDark: isDark,
            title: 'Risk:Reward Ratio',
            value: '1:${controller.riskRewardRatio.value.toStringAsFixed(2)}',
            subtitle: controller.riskRewardRatio.value >= 2
                ? 'Good ratio!'
                : 'Consider higher R:R',
            isPositive: controller.riskRewardRatio.value >= 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMarginCalculator(CalculatorController controller) {
    return _CalculatorCard(
      isDark: isDark,
      title: 'Margin Calculator',
      children: [
        _InputField(
          isDark: isDark,
          label: 'Lot Size',
          controller: controller.marginLotController,
          hint: '1.0',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Leverage (e.g. 100)',
          controller: controller.leverageController,
          hint: '100',
        ),
        SizedBox(height: 12.h),
        _InputField(
          isDark: isDark,
          label: 'Current Price',
          controller: controller.priceController,
          hint: '1.1000',
        ),
        SizedBox(height: 20.h),
        _CalculateButton(onTap: controller.calculateMargin),
        SizedBox(height: 20.h),
        Obx(
          () => _ResultCard(
            isDark: isDark,
            title: 'Margin Required',
            value: '\$${controller.marginRequired.value.toStringAsFixed(2)}',
            subtitle: 'Required margin',
          ),
        ),
      ],
    );
  }
}

// Helper Widgets
class _CalculatorCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;

  const _CalculatorCard({
    required this.isDark,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final String hint;

  const _InputField({
    required this.isDark,
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 16.sp,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _DropdownField({
    required this.isDark,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.cardDark : Colors.white,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _CalculateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CalculateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Calculate',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String value;
  final String subtitle;
  final bool? isPositive;

  const _ResultCard({
    required this.isDark,
    required this.title,
    required this.value,
    required this.subtitle,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive == null
        ? AppColors.primaryLight
        : (isPositive! ? AppColors.successLight : AppColors.errorLight);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
