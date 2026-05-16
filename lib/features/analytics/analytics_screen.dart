import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_states.dart';
import 'analytics_providers.dart';
import 'domain/analytics_models.dart';
import 'widgets/analytics_widgets.dart';

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

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.report});
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        _KpiRow(report: report),
        const SizedBox(height: 24),

        if (report.spendingTrend.isNotEmpty) ...[
          const SectionTitle(title: 'SPENDING TREND'),
          const SizedBox(height: 14),
          SpendingLineChart(trend: report.spendingTrend),
          const SizedBox(height: 24),
        ],

        const SectionTitle(title: 'SHARED VS PERSONAL'),
        const SizedBox(height: 14),
        SharedVsPersonalDonut(breakdown: report.breakdown),
        const SizedBox(height: 24),

        if (report.categoryBreakdown.isNotEmpty) ...[
          const SectionTitle(title: 'CATEGORY BREAKDOWN'),
          const SizedBox(height: 14),
          CategoryBarChart(categories: report.categoryBreakdown),
          const SizedBox(height: 24),
        ],

        if (report.friendDebtComparison.isNotEmpty) ...[
          const SectionTitle(title: 'FRIEND DEBT OVERVIEW'),
          const SizedBox(height: 14),
          FriendDebtChart(friends: report.friendDebtComparison),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.report});
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KpiCard(
          label: 'Total',
          value: '₹${report.breakdown.totalSpending.toInt()}',
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.secondary,
        ),
        const SizedBox(width: 10),
        KpiCard(
          label: 'Shared',
          value: '₹${report.breakdown.sharedTotal.toInt()}',
          icon: Icons.groups_outlined,
          color: AppTheme.info,
        ),
        const SizedBox(width: 10),
        KpiCard(
          label: 'Personal',
          value: '₹${report.breakdown.personalTotal.toInt()}',
          icon: Icons.person_outline_rounded,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}
