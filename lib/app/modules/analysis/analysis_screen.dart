/// Analysis Screen
/// Premium UI for displaying AI analysis results with structured sections
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../common/widgets/common_text.dart';
import '../../common/widgets/common_sizebox.dart';
import '../../common/widgets/banner_ad_widget.dart';
import '../../services/gemini_service.dart';
import '../../routes/app_routes.dart';
import 'analysis_controller.dart';
import 'chat_controller.dart';

class AnalysisScreen extends GetView<AnalysisController> {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Image Header
              _buildHeroHeader(isDark),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Ad
                      const BannerAdWidget(),
                      CommonSizedBox.h16,
                      // Quick Stats Row
                      _buildQuickStats(isDark),
                      CommonSizedBox.h24,
                      // Stock Analysis Sections FIRST (prediction cards)
                      _buildSectionCards(isDark),
                      CommonSizedBox.h24,
                      // Binary Trade Prediction (same card style as stock sections)
                      _buildAdvancedSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Action Buttons
          _buildFloatingActions(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      leading: Padding(
        padding: EdgeInsets.all(8.r),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image with parallax effect
            Builder(
              builder: (context) {
                final imagePath = controller.imagePath.value;
                if (imagePath.isNotEmpty) {
                  return Hero(
                    tag: 'analysis_image',
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                    ),
                  );
                }
                return _buildPlaceholder(isDark);
              },
            ),
            // Overlay for text readability
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            // Recommendation Badge & Title
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => _AnimatedRecommendationBadge(
                      recommendation: controller.recommendation,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'AI Analysis Complete',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.analytics_rounded,
          size: 80.w,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return GetBuilder<AnalysisController>(
      id: AnalysisController.kAnalysisContentId,
      builder: (c) {
        final trend = c.trendDirection.value;
        final risk = c.riskLevel.value;
        final stock = c.stockName.value;

        return Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            if (stock.isNotEmpty)
              _QuickStatChip(
                icon: Icons.bar_chart_rounded,
                label: stock,
                color: AppColors.primaryLight,
                isDark: isDark,
              ),
            if (trend.isNotEmpty)
              _QuickStatChip(
                icon: _getTrendIcon(trend),
                label: trend,
                color: _getTrendColor(trend),
                isDark: isDark,
              ),
            if (risk.isNotEmpty)
              _QuickStatChip(
                icon: Icons.shield_rounded,
                label: '$risk Risk',
                color: _getRiskColor(risk),
                isDark: isDark,
              ),
            _QuickStatChip(
              icon: Icons.access_time_rounded,
              label: _formatTime(c.result.value?.timestamp),
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toUpperCase()) {
      case 'BULLISH':
        return Icons.trending_up_rounded;
      case 'BEARISH':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toUpperCase()) {
      case 'BULLISH':
        return AppColors.successLight;
      case 'BEARISH':
        return AppColors.errorLight;
      default:
        return AppColors.warningLight;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'LOW':
        return AppColors.successLight;
      case 'HIGH':
        return AppColors.errorLight;
      default:
        return AppColors.warningLight;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildAdvancedSection(bool isDark) {
    return GetBuilder<AnalysisController>(
      id: AnalysisController.kAnalysisContentId,
      builder: (c) {
        final r = c.result.value;
        if (r == null || !r.hasAdvancedData) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Binary Trade Signal - same card style as stock prediction
            _buildBinarySignalCard(r, isDark),
            if (r.confidencePercent != null && r.confidencePercent! > 0) ...[
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: _buildConfidenceCard(r.confidencePercent!, isDark),
              ),
            ],
            if (r.expiry30s != null ||
                r.expiry1m != null ||
                r.expiry2m != null ||
                r.expiry5m != null) ...[
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: _buildExpiryWiseSection(r, isDark),
              ),
            ],
            if (r.newsImpact != null && r.newsImpact!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: _buildNewsFilterSection(r.newsImpact!, isDark),
              ),
            ],
            if (r.oneLineExplain != null && r.oneLineExplain!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: _buildOneLineExplainSection(r.oneLineExplain!, isDark),
              ),
            ],
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: _buildDisclaimer(isDark),
            ),
          ],
        );
      },
    );
  }

  /// Binary Trade Signal in same card style as stock section cards
  Widget _buildBinarySignalCard(StockAnalysisResult r, bool isDark) {
    final pair = r.pair?.trim() ?? '—';
    final direction = (r.direction?.toUpperCase() ?? 'CALL').contains('PUT')
        ? 'PUT'
        : 'CALL';
    final entryTime = r.entryTimeIST?.trim() ?? '—';
    final expiry = r.expiry?.trim() ?? '—';
    final confidence = r.confidencePercent != null
        ? '${r.confidencePercent}%'
        : '—';
    final trend = r.trend?.trim() ?? '—';

    final content = '- **Pair:** $pair\n'
        '- **Direction:** $direction ${direction == 'CALL' ? '⬆️' : '⬇️'}\n'
        '- **Entry Time (IST):** $entryTime\n'
        '- **Expiry:** $expiry\n'
        '- **Confidence:** $confidence\n'
        '- **Trend:** $trend';

    return _AnalysisSectionCard(
      config: _SectionConfig(
        key: 'binary_signal',
        title: 'Binary Trade Signal',
        icon: Icons.candlestick_chart_rounded,
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)],
      ),
      content: content,
      isDark: isDark,
      initiallyExpanded: true,
    );
  }

  /// Confidence meter in same card style
  Widget _buildConfidenceCard(int percent, bool isDark) {
    String label;
    Color color;
    if (percent >= 80) {
      label = 'High Confidence';
      color = AppColors.successLight;
    } else if (percent >= 70) {
      label = 'Strong';
      color = Colors.orange;
    } else if (percent >= 60) {
      label = 'Medium';
      color = AppColors.warningLight;
    } else {
      label = 'Low';
      color = AppColors.errorLight;
    }

    final content = '- **Level:** $label\n'
        '- **Confidence:** $percent%';

    return _AnalysisSectionCard(
      config: _SectionConfig(
        key: 'confidence',
        title: 'Confidence Meter',
        icon: Icons.speed_rounded,
        gradient: [color, color.withValues(alpha: 0.7)],
      ),
      content: content,
      isDark: isDark,
      initiallyExpanded: true,
    );
  }

  /// Expiry-wise analysis in same card style
  Widget _buildExpiryWiseSection(StockAnalysisResult r, bool isDark) {
    String slot(String? v) {
      if (v == null) return '—';
      final lower = v.toLowerCase();
      if (lower.contains('avoid')) return '❌ avoid';
      if (lower.contains('best')) return '✅ best';
      if (lower.contains('risky')) return '⚠️ risky';
      if (lower.contains('slow')) return '❌ trend slow';
      return v;
    }

    final content = '- **30 sec:** ${slot(r.expiry30s)}\n'
        '- **1 min:** ${slot(r.expiry1m)}\n'
        '- **2 min:** ${slot(r.expiry2m)}\n'
        '- **5 min:** ${slot(r.expiry5m)}';

    return _AnalysisSectionCard(
      config: _SectionConfig(
        key: 'expiry_wise',
        title: 'Expiry-Wise Analysis',
        icon: Icons.schedule_rounded,
        gradient: [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      ),
      content: content,
      isDark: isDark,
      initiallyExpanded: true,
    );
  }

  /// News filter in same card style
  Widget _buildNewsFilterSection(String impact, bool isDark) {
    final upper = impact.toUpperCase();
    String label;
    if (upper.contains('HIGH')) {
      label = '🔴 NO TRADE';
    } else if (upper.contains('MEDIUM')) {
      label = '🟡 Low lot';
    } else {
      label = '🟢 Safe window';
    }

    final content = '- **Current Status:** $label\n'
        '- High impact news = NO TRADE\n'
        '- Medium impact = Low lot\n'
        '- No news = Safe window';

    return _AnalysisSectionCard(
      config: _SectionConfig(
        key: 'news_filter',
        title: 'News Filter',
        icon: Icons.newspaper_rounded,
        gradient: [const Color(0xFFFD79A8), const Color(0xFFE17055)],
      ),
      content: content,
      isDark: isDark,
      initiallyExpanded: true,
    );
  }

  /// One-line explain in same card style
  Widget _buildOneLineExplainSection(String oneLine, bool isDark) {
    return _AnalysisSectionCard(
      config: _SectionConfig(
        key: 'one_line_explain',
        title: 'AI Explain in 1 Line',
        icon: Icons.auto_awesome_rounded,
        gradient: [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
      ),
      content: oneLine,
      isDark: isDark,
      initiallyExpanded: true,
    );
  }

  Widget _buildDisclaimer(bool isDark) {
    const String disclaimer =
        'This app provides AI-based market analysis for educational purposes. Trading involves risk.';
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: (isDark ? Colors.orange : Colors.amber).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (isDark ? Colors.orange : Colors.amber).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              disclaimer,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCards(bool isDark) {
    final sectionConfigs = [
      _SectionConfig(
        key: 'summary',
        title: 'Summary',
        icon: Icons.lightbulb_rounded,
        gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        isHighlighted: true,
      ),
      _SectionConfig(
        key: 'stock_info',
        title: 'Stock Information',
        icon: Icons.candlestick_chart_rounded,
        gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      ),
      _SectionConfig(
        key: 'technical',
        title: 'Technical Analysis',
        icon: Icons.analytics_rounded,
        gradient: [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
      ),
      _SectionConfig(
        key: 'indicators',
        title: 'Key Indicators',
        icon: Icons.speed_rounded,
        gradient: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      ),
      _SectionConfig(
        key: 'recommendation',
        title: 'Recommendation',
        icon: Icons.star_rounded,
        gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      ),
      _SectionConfig(
        key: 'risk',
        title: 'Risk Assessment',
        icon: Icons.warning_amber_rounded,
        gradient: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      ),
    ];

    return GetBuilder<AnalysisController>(
      id: AnalysisController.kAnalysisContentId,
      builder: (c) {
        final sections = Map<String, String>.from(c.sections);

        // If no parsed sections, show full analysis
        if (sections.isEmpty) {
          return _buildFullAnalysisCard(isDark, c);
        }

        return Column(
          children: sectionConfigs.map((config) {
            final content = sections[config.key] ?? '';
            if (content.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _AnalysisSectionCard(
                config: config,
                content: content,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFullAnalysisCard(bool isDark, AnalysisController c) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 22.w,
                ),
              ),
              SizedBox(width: 12.w),
              CommonText.subtitle(
                'AI Analysis',
                isTranslate: false,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _MarkdownContent(content: c.analysis, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Save Button
            Expanded(
              child: GetBuilder<AnalysisController>(
                id: AnalysisController.kAnalysisContentId,
                builder: (c) => _ActionButton(
                  icon: c.isSaved.value
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  label: c.isSaved.value ? 'Saved' : 'Save',
                  color: c.isSaved.value
                      ? AppColors.successLight
                      : (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight),
                  isDark: isDark,
                  isOutlined: !c.isSaved.value,
                  onTap: controller.saveToHistory,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Share Button
            Expanded(
              child: _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                isDark: isDark,
                isOutlined: false,
                onTap: controller.shareAnalysis,
              ),
            ),
            SizedBox(width: 12.w),
            // Ask AI Button
            Expanded(
              child: _ActionButton(
                icon: Icons.psychology_rounded,
                label: 'Ask AI',
                color: const Color(0xFF10B981),
                isDark: isDark,
                isOutlined: false,
                onTap: () {
                  Get.toNamed(
                    AppRoutes.aiChat,
                    arguments: {
                      'analysisContext': controller.analysis,
                    },
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            // New Scan Button
            Expanded(
              child: _ActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'New Scan',
                color: const Color(0xFF667EEA),
                isDark: isDark,
                isOutlined: false,
                onTap: controller.newScan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== SUPPORTING WIDGETS ====

class _SectionConfig {
  final String key;
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final bool isHighlighted;

  _SectionConfig({
    required this.key,
    required this.title,
    required this.icon,
    required this.gradient,
    this.isHighlighted = false,
  });
}

class _AnimatedRecommendationBadge extends StatefulWidget {
  final String recommendation;

  const _AnimatedRecommendationBadge({required this.recommendation});

  @override
  State<_AnimatedRecommendationBadge> createState() =>
      _AnimatedRecommendationBadgeState();
}

class _AnimatedRecommendationBadgeState
    extends State<_AnimatedRecommendationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;

    switch (widget.recommendation.toUpperCase()) {
      case 'BUY':
        bgColor = AppColors.successLight;
        icon = Icons.trending_up_rounded;
        break;
      case 'SELL':
        bgColor = AppColors.errorLight;
        icon = Icons.trending_down_rounded;
        break;
      default:
        bgColor = AppColors.warningLight;
        icon = Icons.trending_flat_rounded;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  widget.recommendation.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          '',
          label,
          snackPosition: SnackPosition.TOP,
          backgroundColor: color.withValues(alpha: 0.95),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          icon: Icon(icon, color: Colors.white, size: 24),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        constraints: BoxConstraints(maxWidth: 160.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.w, color: color),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisSectionCard extends StatefulWidget {
  final _SectionConfig config;
  final String content;
  final bool isDark;
  final bool? initiallyExpanded;

  const _AnalysisSectionCard({
    required this.config,
    required this.content,
    required this.isDark,
    this.initiallyExpanded,
  });

  @override
  State<_AnalysisSectionCard> createState() => _AnalysisSectionCardState();
}

class _AnalysisSectionCardState extends State<_AnalysisSectionCard> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Use explicit initiallyExpanded if provided; otherwise summary expanded by default
    _isExpanded = widget.initiallyExpanded ?? (widget.config.key == 'summary');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20.r),
        border: widget.config.isHighlighted
            ? Border.all(
                color: widget.config.gradient[0].withValues(alpha: 0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.config.isHighlighted
                ? widget.config.gradient[0].withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: widget.config.isHighlighted ? 20 : 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.config.gradient,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        widget.config.icon,
                        color: Colors.white,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.config.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                // Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: _MarkdownContent(
                      content: widget.content,
                      isDark: widget.isDark,
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isOutlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.isOutlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(14.r),
            border: isOutlined ? Border.all(color: color, width: 2) : null,
            boxShadow: isOutlined
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.w, color: isOutlined ? color : Colors.white),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  final String content;
  final bool isDark;

  const _MarkdownContent({required this.content, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) {
        widgets.add(SizedBox(height: 4.h));
        continue;
      }

      // Skip section headers (we already show them as card titles)
      if (trimmedLine.startsWith('## ')) {
        continue;
      }

      // Handle bullet points
      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('• ')) {
        final text = trimmedLine.substring(2);
        widgets.add(_buildBulletPoint(_parseInlineMarkdown(text)));
        continue;
      }

      // Handle numbered lists
      if (RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
        final text = trimmedLine.replaceFirst(RegExp(r'^\d+\.\s'), '');
        widgets.add(_buildBulletPoint(_parseInlineMarkdown(text)));
        continue;
      }

      // Handle bold-only lines
      if (trimmedLine.startsWith('**') &&
          trimmedLine.endsWith('**') &&
          !trimmedLine.substring(2, trimmedLine.length - 2).contains('**')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 6.h, top: 4.h),
            child: Text(
              trimmedLine.substring(2, trimmedLine.length - 2),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        );
        continue;
      }

      // Regular text with inline formatting
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: _buildRichText(_parseInlineMarkdown(trimmedLine)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildBulletPoint(List<TextSpan> spans) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(child: _buildRichText(spans)),
        ],
      ),
    );
  }

  Widget _buildRichText(List<TextSpan> spans) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.sp,
          height: 1.6,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _parseInlineMarkdown(String text) {
    final List<TextSpan> spans = [];

    // Remove any remaining markdown headers
    String cleanText = text.replaceAll(RegExp(r'^#+\s*'), '');

    // Parse bold text (**text** or __text__)
    final boldPattern = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(cleanText)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: cleanText.substring(lastEnd, match.start)));
      }

      // Add bold text
      final boldText = match.group(1) ?? match.group(2) ?? '';
      spans.add(
        TextSpan(
          text: boldText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < cleanText.length) {
      spans.add(TextSpan(text: cleanText.substring(lastEnd)));
    }

    // If no spans were added, add the whole text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleanText));
    }

    return spans;
  }
}
