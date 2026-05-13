import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_providers.dart';
import 'domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(analyticsReportProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date range selector
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 8,
                      children: [
                        _DateFilterChip(
                          label: 'This month',
                          onTap: () => ref.read(dateRangeProvider.notifier).setCurrentMonth(),
                          isActive: _isCurrentMonth(dateRange),
                        ),
                        _DateFilterChip(
                          label: '3 months',
                          onTap: () => ref.read(dateRangeProvider.notifier).setLastThreeMonths(),
                          isActive: _isLastMonths(dateRange, 3),
                        ),
                        _DateFilterChip(
                          label: '6 months',
                          onTap: () => ref.read(dateRangeProvider.notifier).setLastSixMonths(),
                          isActive: _isLastMonths(dateRange, 6),
                        ),
                        _DateFilterChip(
                          label: 'Last year',
                          onTap: () => ref.read(dateRangeProvider.notifier).setLastYear(),
                          isActive: _isLastMonths(dateRange, 12),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Select custom date range',
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _selectDateRange(context, ref),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(
                message: 'Could not load analytics.',
                details: error.toString(),
                onRetry: () => ref.invalidate(analyticsReportProvider),
              ),
              data: (report) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(analyticsReportProvider);
                  await ref.read(analyticsReportProvider.future);
                },
                child: _AnalyticsContent(report: report),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentMonth(DateRange range) {
    final now = DateTime.now();
    return range.startDate.month == now.month && range.startDate.year == now.year;
  }

  bool _isLastMonths(DateRange range, int months) {
    final expected = DateRange.lastMonths(months);
    return range.startDate.compareTo(expected.startDate) == 0;
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: ref.read(dateRangeProvider).startDate,
        end: ref.read(dateRangeProvider).endDate,
      ),
    );

    if (picked != null && context.mounted) {
      ref.read(dateRangeProvider.notifier).setCustomRange(picked.start, picked.end);
    }
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.report});

  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Spending',
                value: _formatCurrency(report.breakdown.totalSpending.toInt()),
                icon: Icons.trending_up_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Shared',
                value: _formatCurrency(report.breakdown.sharedTotal.toInt()),
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Personal',
                value: _formatCurrency(report.breakdown.personalTotal.toInt()),
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Spending trend chart
        if (report.spendingTrend.isNotEmpty) ...[
          Text(
            'Spending Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _SpendingTrendChart(points: report.spendingTrend),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Breakdown pie chart
        Text(
          'Spending Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SpendingBreakdownChart(breakdown: report.breakdown),
          ),
        ),
        const SizedBox(height: 24),

        // Category breakdown
        if (report.categoryBreakdown.isNotEmpty) ...[
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CategoryBreakdownChart(categories: report.categoryBreakdown),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Friend debt comparison
        if (report.friendDebtComparison.isNotEmpty) ...[
          Text(
            'Friend Debt Comparison',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._buildFriendDebtCards(report.friendDebtComparison),
        ],
      ],
    );
  }

  List<Widget> _buildFriendDebtCards(List<FriendDebtComparison> debts) {
    return debts
        .map(
          (debt) => Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            debt.friendName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _formatCurrency(debt.totalDebt.toInt()),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Settled: ${_formatCurrency(debt.totalSettled.toInt())}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Pending: ${_formatCurrency(debt.pendingAmount.toInt())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: debt.pendingAmount > 0 ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: debt.totalDebt > 0 ? debt.totalSettled / debt.totalDebt : 0,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        )
        .toList();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.onTap,
    required this.isActive,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: 'Filter by $label',
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SpendingTrendChart extends StatelessWidget {
  const _SpendingTrendChart({required this.points});

  final List<SpendingTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _TrendChartPainter(points: points),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  const Text('Shared', style: TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  const Text('Personal', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({required this.points});

  final List<SpendingTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxAmount = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    if (maxAmount == 0) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final sharedPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final personalPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final pointCount = points.length;
    final pointWidth = pointCount > 1 ? chartWidth / (pointCount - 1).toDouble() : 0.0;

    // Draw axes
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );

    // Draw shared line
    if (pointCount == 1) {
      final p = points[0];
      final x = padding + (chartWidth / 2);
      final y = size.height - padding - ((p.sharedAmount / maxAmount) * chartHeight);
      canvas.drawCircle(Offset(x, y), 4, sharedPaint..style = PaintingStyle.fill);
    } else {
      for (int i = 0; i < pointCount - 1; i++) {
        final currentPoint = points[i];
        final nextPoint = points[i + 1];

        final x1 = padding + (i * pointWidth);
        final y1 = size.height - padding - ((currentPoint.sharedAmount / maxAmount) * chartHeight);
        final x2 = padding + ((i + 1) * pointWidth);
        final y2 = size.height - padding - ((nextPoint.sharedAmount / maxAmount) * chartHeight);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), sharedPaint);
      }
    }

    // Draw personal line
    if (pointCount == 1) {
      final p = points[0];
      final x = padding + (chartWidth / 2);
      final y = size.height - padding - ((p.personalAmount / maxAmount) * chartHeight);
      canvas.drawCircle(Offset(x, y), 4, personalPaint..style = PaintingStyle.fill);
    } else {
      for (int i = 0; i < pointCount - 1; i++) {
        final currentPoint = points[i];
        final nextPoint = points[i + 1];

        final x1 = padding + (i * pointWidth);
        final y1 = size.height - padding - ((currentPoint.personalAmount / maxAmount) * chartHeight);
        final x2 = padding + ((i + 1) * pointWidth);
        final y2 = size.height - padding - ((nextPoint.personalAmount / maxAmount) * chartHeight);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), personalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _SpendingBreakdownChart extends StatelessWidget {
  const _SpendingBreakdownChart({required this.breakdown});

  final SpendingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _PieChartPainter(breakdown: breakdown),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 24,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text('Shared', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${breakdown.sharedPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text('Personal', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${breakdown.personalPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.breakdown});

  final SpendingBreakdown breakdown;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;

    if (breakdown.totalSpending == 0) return;

    final sharedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final personalPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final sharedAngle = (breakdown.sharedTotal / breakdown.totalSpending) * (2 * 3.14159);

    // Draw shared slice
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sharedAngle,
      true,
      sharedPaint,
    );

    // Draw personal slice
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + sharedAngle,
      2 * 3.14159 - sharedAngle,
      true,
      personalPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.breakdown != breakdown;
  }
}

class _CategoryBreakdownChart extends StatelessWidget {
  const _CategoryBreakdownChart({required this.categories});

  final List<CategorySpending> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No category data available')),
      );
    }

    final maxAmount = categories.map((c) => c.amount).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200 + (categories.length * 40.0),
      child: Column(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category.category, style: const TextStyle(fontSize: 12)),
                        Text(
                          _formatCurrency(category.amount.toInt()),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: category.amount / maxAmount,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int amount) {
  return '₹$amount';
}
