import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'analytics_providers.dart';
import 'domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(analyticsReportProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _DateFilterBar(dateRange: dateRange, ref: ref),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppListLoadingSkeleton(itemCount: 3),
              error: (error, stackTrace) => AppStatusView(
                icon: Icons.insights_outlined,
                title: 'Analysis Unavailable',
                message: 'We couldn\'t process your financial data for this period.',
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
                child: _AnalyticsContent(report: report),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({required this.dateRange, required this.ref});
  final DateRange dateRange;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _DateChip(
            label: 'This Month',
            isActive: _isCurrentMonth(dateRange),
            onTap: () => ref.read(dateRangeProvider.notifier).setCurrentMonth(),
          ),
          const SizedBox(width: 10),
          _DateChip(
            label: 'Last 3 Months',
            isActive: _isLastMonths(dateRange, 3),
            onTap: () => ref.read(dateRangeProvider.notifier).setLastThreeMonths(),
          ),
          const SizedBox(width: 10),
          _DateChip(
            label: 'Custom',
            isActive: !_isCurrentMonth(dateRange) && !_isLastMonths(dateRange, 3),
            onTap: () => _selectCustomRange(context, ref),
            icon: Icons.calendar_today_rounded,
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
    return range.startDate.month == expected.startDate.month && range.startDate.year == expected.startDate.year;
  }

  Future<void> _selectCustomRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.secondary, surface: AppTheme.surfaceElevated)),
        child: child!,
      ),
    );
    if (picked != null) ref.read(dateRangeProvider.notifier).setCustomRange(picked.start, picked.end);
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.isActive, required this.onTap, this.icon});
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.secondary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppTheme.secondary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isActive ? AppTheme.secondary : AppTheme.muted), const SizedBox(width: 8)],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? AppTheme.secondary : AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.report});
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        // Summary Cards
        Row(
          children: [
            _HeroMetric(label: 'Total Spent', value: '₹${report.breakdown.totalSpending.toInt()}', color: Colors.white),
            const SizedBox(width: 12),
            _HeroMetric(label: 'Shared', value: '₹${report.breakdown.sharedTotal.toInt()}', color: AppTheme.secondary),
          ],
        ),
        const SizedBox(height: 28),
        
        // Charts and Graphs
        _SectionTitle(title: 'Spending Breakdown'),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: _DonutChart(breakdown: report.breakdown),
        ),
        const SizedBox(height: 28),

        _SectionTitle(title: 'Top Categories'),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: report.categoryBreakdown.map((cat) => _CategoryItem(cat: cat)).toList(),
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2));
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.cat});
  final CategorySpending cat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(cat.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Text('₹${cat.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.secondary)),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.breakdown});
  final SpendingBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final sharedP = breakdown.totalSpending > 0 ? breakdown.sharedTotal / breakdown.totalSpending : 0.0;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140, height: 140,
              child: CircularProgressIndicator(
                value: sharedP,
                strokeWidth: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
              ),
            ),
            Column(
              children: [
                const Text('Shared', style: TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${(sharedP * 100).toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChartLegend(label: 'Shared', color: AppTheme.secondary),
            const SizedBox(width: 20),
            _ChartLegend(label: 'Personal', color: Colors.white24),
          ],
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 8, height: 8, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))]);
  }
}
