import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/analytics_models.dart';

// ─── Category color helper ───────────────────────────────────────────────────
Color catColor(String category) {
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

String monthLabel(DateTime d) {
  const months = [
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
  return months[d.month - 1];
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
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
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
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
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Legend extends StatelessWidget {
  const Legend({super.key, required this.color, required this.label});
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
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SpendingLineChart extends StatelessWidget {
  const SpendingLineChart({super.key, required this.trend});
  final List<SpendingTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final maxY = trend.fold<int>(0, (m, p) => p.amount > m ? p.amount : m).toDouble();
    final safeMax = maxY == 0 ? 100.0 : maxY * 1.2;

    final sharedSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.sharedAmount.toDouble());
    }).toList();

    final personalSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.personalAmount.toDouble());
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
                          fontWeight: FontWeight.w600,
                        ),
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
                            monthLabel(trend[idx].month),
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceElevated,
                    getTooltipItems: (spots) => spots.map((s) {
                      final isShared = s.barIndex == 0;
                      return LineTooltipItem(
                        '₹${s.y.toInt()}',
                        TextStyle(
                          color: isShared
                              ? AppTheme.secondary
                              : AppTheme.warning,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Legend(color: AppTheme.secondary, label: 'Shared'),
              SizedBox(width: 20),
              Legend(color: AppTheme.warning, label: 'Personal'),
            ],
          ),
        ],
      ),
    );
  }
}

class SharedVsPersonalDonut extends StatelessWidget {
  const SharedVsPersonalDonut({super.key, required this.breakdown});
  final SpendingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final total = breakdown.totalSpending;
    final hasData = total > 0;

    final sections = hasData
        ? [
            PieChartSectionData(
              value: breakdown.sharedTotal.toDouble(),
              color: AppTheme.secondary,
              radius: 36,
              title: '',
              showTitle: false,
            ),
            PieChartSectionData(
              value: breakdown.personalTotal.toDouble(),
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
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const Text(
                      'total',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
  final int amount;
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${pct.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toInt()}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({super.key, required this.categories});
  final List<CategorySpending> categories;

  @override
  Widget build(BuildContext context) {
    final maxVal = categories.fold<int>(
      0,
      (m, c) => c.amount > m ? c.amount : m,
    ).toDouble();
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
          final color = catColor(cat.category);
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
                          color: AppTheme.onSurface,
                        ),
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
                              backgroundColor: AppTheme.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation(color),
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
                          color: color,
                        ),
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

class FriendDebtChart extends StatelessWidget {
  const FriendDebtChart({super.key, required this.friends});
  final List<FriendDebtComparison> friends;

  @override
  Widget build(BuildContext context) {
    final maxVal = friends.fold<int>(
      0,
      (m, f) => f.totalDebt > m ? f.totalDebt : m,
    ).toDouble();

    final groups = friends.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: f.totalDebt.toDouble(),
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppTheme.error.withValues(alpha: 0.7), AppTheme.error],
            ),
          ),
          BarChartRodData(
            toY: f.totalSettled.toDouble(),
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
                maxY: (maxVal == 0) ? 100 : maxVal * 1.2,
                barGroups: groups,
                gridData: const FlGridData(show: false),
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
                          fontWeight: FontWeight.w600,
                        ),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceElevated,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Total' : 'Settled';
                      final color = rodIndex == 0
                          ? AppTheme.error
                          : AppTheme.secondary;
                      return BarTooltipItem(
                        '$label\n₹${rod.toY.toInt()}',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Legend(color: AppTheme.error, label: 'Total Debt'),
              SizedBox(width: 20),
              Legend(color: AppTheme.secondary, label: 'Settled'),
            ],
          ),
        ],
      ),
    );
  }
}
