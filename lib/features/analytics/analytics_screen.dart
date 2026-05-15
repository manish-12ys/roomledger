import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_states.dart';
import 'analytics_providers.dart';
import 'domain/analytics_models.dart';

// ─── Category color helper (mirrors personal screen) ─────────────────────────
Color _catColor(String category) {
  return switch (category.toLowerCase()) {
    'food' => const Color(0xFFFF6B6B),
    'travel' => const Color(0xFF4ECDC4),
    'bills' => const Color(0xFFFFE66D),
    'entertainment' => const Color(0xFFA78BFA),
    'shopping' => const Color(0xFFF97316),
    'utilities' => const Color(0xFF38BDF8),
    _ => AppTheme.muted,
  };
}

// ─── Month label helper ───────────────────────────────────────────────────────
String _monthLabel(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return months[d.month - 1];
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(analyticsReportProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _AnalyticsHeader(dateRange: dateRange, ref: ref),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppListLoadingSkeleton(itemCount: 4),
              error: (e, _) => AppStatusView(
                icon: Icons.insights_outlined,
                title: 'Analysis Unavailable',
                message: 'Could not process your financial data.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(analyticsReportProvider),
              ),
              data: (report) => RefreshIndicator(
                color: AppTheme.secondary,
                backgroundColor: AppTheme.surfaceElevated,
                onRefresh: () async {
                  ref.invalidate(analyticsReportProvider);
                  await ref.read(analyticsReportProvider.future);
                },
                child: _AnalyticsBody(report: report),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header with date filter ──────────────────────────────────────────────────
class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.dateRange, required this.ref});
  final DateRange dateRange;
  final WidgetRef ref;

  bool _isCurrentMonth(DateRange r) {
    final now = DateTime.now();
    return r.startDate.month == now.month && r.startDate.year == now.year;
  }

  bool _isLastMonths(DateRange r, int months) {
    final expected = DateRange.lastMonths(months);
    return r.startDate.month == expected.startDate.month &&
        r.startDate.year == expected.startDate.year;
  }

  Future<void> _pickCustom(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.secondary,
            surface: AppTheme.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(dateRangeProvider.notifier).setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMonth = _isCurrentMonth(dateRange);
    final is3M = _isLastMonths(dateRange, 3);
    final isCustom = !isMonth && !is3M;
    final canPop = Navigator.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(
              color: AppTheme.onSurface.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: AppTheme.onSurface),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.insights_rounded,
                        color: AppTheme.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Insights',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'This Month',
                    active: isMonth,
                    onTap: () =>
                        ref.read(dateRangeProvider.notifier).setCurrentMonth(),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last 3 Months',
                    active: is3M,
                    onTap: () => ref
                        .read(dateRangeProvider.notifier)
                        .setLastThreeMonths(),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Custom',
                    active: isCustom,
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickCustom(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.secondary.withValues(alpha: 0.15)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppTheme.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
                  color: active ? AppTheme.secondary : AppTheme.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppTheme.secondary : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analytics Body ───────────────────────────────────────────────────────────
class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.report});
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ── KPI row ──
        _KpiRow(report: report),
        const SizedBox(height: 24),

        // ── Line chart: spending trend ──
        if (report.spendingTrend.isNotEmpty) ...[
          _SectionTitle(title: 'SPENDING TREND'),
          const SizedBox(height: 14),
          _SpendingLineChart(trend: report.spendingTrend),
          const SizedBox(height: 24),
        ],

        // ── Donut: shared vs personal ──
        _SectionTitle(title: 'SHARED VS PERSONAL'),
        const SizedBox(height: 14),
        _SharedVsPersonalDonut(breakdown: report.breakdown),
        const SizedBox(height: 24),

        // ── Horizontal bar: category breakdown ──
        if (report.categoryBreakdown.isNotEmpty) ...[
          _SectionTitle(title: 'CATEGORY BREAKDOWN'),
          const SizedBox(height: 14),
          _CategoryBarChart(categories: report.categoryBreakdown),
          const SizedBox(height: 24),
        ],

        // ── Friend debt comparison ──
        if (report.friendDebtComparison.isNotEmpty) ...[
          _SectionTitle(title: 'FRIEND DEBT OVERVIEW'),
          const SizedBox(height: 14),
          _FriendDebtChart(friends: report.friendDebtComparison),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2),
        ),
      ],
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.report});
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    final total = report.breakdown.totalSpending;
    final shared = report.breakdown.sharedTotal;
    final personal = report.breakdown.personalTotal;

    return Row(
      children: [
        _KpiCard(
          label: 'Total',
          value: '₹${total.toInt()}',
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.secondary,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          label: 'Shared',
          value: '₹${shared.toInt()}',
          icon: Icons.groups_outlined,
          color: AppTheme.info,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          label: 'Personal',
          value: '₹${personal.toInt()}',
          icon: Icons.person_outline_rounded,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Spending Line Chart ──────────────────────────────────────────────────────
class _SpendingLineChart extends StatelessWidget {
  const _SpendingLineChart({required this.trend});
  final List<SpendingTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final maxY = trend.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.2;

    final sharedSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.sharedAmount);
    }).toList();

    final personalSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.personalAmount);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: safeMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.onSurface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: safeMax / 4,
                      getTitlesWidget: (val, _) => Text(
                        '₹${val.toInt()}',
                        style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthLabel(trend[idx].month),
                            style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceElevated,
                    getTooltipItems: (spots) => spots.map((s) {
                      final isShared = s.barIndex == 0;
                      return LineTooltipItem(
                        '₹${s.y.toInt()}',
                        TextStyle(
                          color: isShared ? AppTheme.secondary : AppTheme.warning,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  // Shared line
                  LineChartBarData(
                    spots: sharedSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.secondary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.secondary,
                        strokeWidth: 1.5,
                        strokeColor: AppTheme.background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.secondary.withValues(alpha: 0.18),
                          AppTheme.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Personal line
                  LineChartBarData(
                    spots: personalSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.warning,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.warning,
                        strokeWidth: 1.5,
                        strokeColor: AppTheme.background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.warning.withValues(alpha: 0.12),
                          AppTheme.warning.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppTheme.secondary, label: 'Shared'),
              const SizedBox(width: 20),
              _Legend(color: AppTheme.warning, label: 'Personal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Shared vs Personal Donut ─────────────────────────────────────────────────
class _SharedVsPersonalDonut extends StatelessWidget {
  const _SharedVsPersonalDonut({required this.breakdown});
  final SpendingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final total = breakdown.totalSpending;
    final hasData = total > 0;

    final sections = hasData
        ? [
            PieChartSectionData(
              value: breakdown.sharedTotal,
              color: AppTheme.secondary,
              radius: 36,
              title: '',
              showTitle: false,
            ),
            PieChartSectionData(
              value: breakdown.personalTotal,
              color: AppTheme.warning,
              radius: 36,
              title: '',
              showTitle: false,
            ),
          ]
        : [
            PieChartSectionData(
              value: 1,
              color: AppTheme.surfaceElevated,
              radius: 36,
              title: '',
              showTitle: false,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 42,
                    sectionsSpace: hasData ? 3 : 0,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${total.toInt()}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.onSurface),
                    ),
                    const Text('total',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DonutLegendRow(
                  color: AppTheme.secondary,
                  label: 'Shared',
                  amount: breakdown.sharedTotal,
                  pct: breakdown.sharedPercentage,
                ),
                const SizedBox(height: 16),
                _DonutLegendRow(
                  color: AppTheme.warning,
                  label: 'Personal',
                  amount: breakdown.personalTotal,
                  pct: breakdown.personalPercentage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.pct,
  });
  final Color color;
  final String label;
  final double amount;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface)),
            const Spacer(),
            Text('${pct.toInt()}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Text('₹${amount.toInt()}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.onSurface)),
      ],
    );
  }
}

// ─── Category Horizontal Bar Chart ───────────────────────────────────────────
class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.categories});
  final List<CategorySpending> categories;

  @override
  Widget build(BuildContext context) {
    final maxVal = categories.fold<double>(0, (m, c) => c.amount > m ? c.amount : m);
    final top = categories.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: top.asMap().entries.map((entry) {
          final cat = entry.value;
          final color = _catColor(cat.category);
          final pct = maxVal > 0 ? cat.amount / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        cat.category,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) {
                            return LinearProgressIndicator(
                              value: val,
                              minHeight: 10,
                              backgroundColor:
                                  AppTheme.surfaceElevated,
                              valueColor:
                                  AlwaysStoppedAnimation(color),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '₹${cat.amount.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Friend Debt Chart ────────────────────────────────────────────────────────
class _FriendDebtChart extends StatelessWidget {
  const _FriendDebtChart({required this.friends});
  final List<FriendDebtComparison> friends;

  @override
  Widget build(BuildContext context) {
    final maxVal = friends.fold<double>(
        0, (m, f) => f.totalDebt > m ? f.totalDebt : m);

    final groups = friends.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: f.totalDebt,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.error.withValues(alpha: 0.7),
                AppTheme.error,
              ],
            ),
          ),
          BarChartRodData(
            toY: f.totalSettled,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.secondary.withValues(alpha: 0.7),
                AppTheme.secondary,
              ],
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.onSurface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (val, _) => Text(
                        '₹${val.toInt()}',
                        style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= friends.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            friends[idx].friendName.split(' ').first,
                            style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceElevated,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Total' : 'Settled';
                      final color =
                          rodIndex == 0 ? AppTheme.error : AppTheme.secondary;
                      return BarTooltipItem(
                        '$label\n₹${rod.toY.toInt()}',
                        TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppTheme.error, label: 'Total Debt'),
              const SizedBox(width: 20),
              _Legend(color: AppTheme.secondary, label: 'Settled'),
            ],
          ),
        ],
      ),
    );
  }
}
