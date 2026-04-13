/// Portfolio Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/portfolio_service.dart';
import 'portfolio_controller.dart';

class PortfolioScreen extends GetView<PortfolioController> {
  const PortfolioScreen({super.key});

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
          'Portfolio',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF8B5CF6)),
            onPressed: () async {
              final result = await Get.toNamed(AppRoutes.addTrade);
              if (result == true) controller.refresh();
            },
            tooltip: 'Add Trade',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.addTrade);
          if (result == true) controller.refresh();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
        }
        if (controller.trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 64.w,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                SizedBox(height: 16.h),
                Text('No trades yet',
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                SizedBox(height: 8.h),
                Text('Tap + to add your first trade',
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _PnlSummaryCard(controller: controller, isDark: isDark),
            SizedBox(height: 16.h),
            ...controller.trades.map(
              (trade) => _TradeCard(
                  trade: trade, isDark: isDark, controller: controller),
            ),
            SizedBox(height: 80.h),
          ],
        );
      }),
    );
  }
}

class _PnlSummaryCard extends StatelessWidget {
  final PortfolioController controller;
  final bool isDark;

  const _PnlSummaryCard({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pnl = controller.totalPnl;
    final invested = controller.totalInvested;
    final isPositive = pnl >= 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Portfolio P&L',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.8))),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isPositive ? '+' : ''}${pnl.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      invested > 0
                          ? '${isPositive ? '+' : ''}${(pnl / invested * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Invested: ${invested.toStringAsFixed(2)}  •  Trades: ${controller.trades.length}',
            style: TextStyle(
                fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final TradeModel trade;
  final bool isDark;
  final PortfolioController controller;

  const _TradeCard(
      {required this.trade, required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPositive = trade.pnl >= 0;
    final pnlColor = isPositive ? Colors.green : Colors.red;

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: trade.type == 'long'
                        ? [Colors.green.shade600, Colors.green.shade400]
                        : [Colors.red.shade600, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(
                    trade.type == 'long'
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.symbol,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    ),
                    Text(
                      '${trade.type.toUpperCase()}  •  Qty: ${trade.quantity.toStringAsFixed(trade.quantity % 1 == 0 ? 0 : 2)}',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${trade.pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: pnlColor),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${trade.pnlPercent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12.sp, color: pnlColor),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _PriceInfo(label: 'Buy', value: trade.buyPrice.toStringAsFixed(2), isDark: isDark),
              SizedBox(width: 12.w),
              _PriceInfo(label: 'Current', value: trade.currentPrice.toStringAsFixed(2), isDark: isDark),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 18.sp, color: const Color(0xFF8B5CF6)),
                onPressed: () => controller.updatePrice(trade.id, trade.symbol),
                tooltip: 'Update Price',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              SizedBox(width: 12.w),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 18.sp, color: Colors.red),
                onPressed: () => controller.deleteTrade(trade.id, trade.symbol),
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (trade.notes.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                trade.notes,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _PriceInfo(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11.sp,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight),
        ),
      ],
    );
  }
}
