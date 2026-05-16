import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/category_utils.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import '../analytics/analytics_providers.dart';
import '../debts/debt_detail_screen.dart';
import '../debts/domain/debts_models.dart';
import '../dashboard/dashboard_shell.dart';
import 'domain/expense_models.dart';
import 'expenses_providers.dart';
import 'expenses_controller.dart';
import 'widgets/add_shared_expense_sheet.dart';

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedExpensesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Shared Ledger'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _openAddFriendSheet(context, ref),
            icon: const Icon(
              Icons.person_add_outlined,
              size: 22,
              color: AppTheme.onSurfaceVariant,
            ),
            tooltip: 'Add Roommate',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.history_edu_outlined,
          title: 'Ledger Unavailable',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(expensesListProvider),
        ),
        data: (grouped) => RefreshIndicator(
          color: AppTheme.secondary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(expensesListProvider);
            await ref.read(expensesListProvider.future);
          },
          child:
              (grouped.today.isEmpty &&
                  grouped.yesterday.isEmpty &&
                  grouped.earlier.isEmpty)
              ? const _EmptyState()
              : _TimelineExpenseList(grouped: grouped),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => _openAddExpenseSheet(context, ref),
            icon: Icons.add_circle_outline,
            label: 'Add Shared Expense',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _openAddFriendSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFriendSheet(
        onCreated: () {
          ref.invalidate(friendOptionsProvider);
        },
      ),
    );
  }

  Future<void> _openAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AddSharedExpenseSheet(
          onCreated: () {
            ref.invalidate(expensesListProvider);
          },
        );
      },
    );
  }
}

class _TimelineExpenseList extends StatelessWidget {
  const _TimelineExpenseList({required this.grouped});
  final GroupedExpenses grouped;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _ExpensesSummaryHero(
              totalPending: grouped.totalPending,
              count:
                  grouped.today.length +
                  grouped.yesterday.length +
                  grouped.earlier.length,
              totalAmount: grouped.totalAmount,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'CATEGORY BREAKDOWN',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _SharedCategoryBreakdown(),
          ),
        ),
        if (grouped.today.isNotEmpty) ...[
          _buildSectionHeader(context, 'TODAY'),
          _buildExpenseSliver(grouped.today),
        ],
        if (grouped.yesterday.isNotEmpty) ...[
          _buildSectionHeader(context, 'YESTERDAY'),
          _buildExpenseSliver(grouped.yesterday),
        ],
        if (grouped.earlier.isNotEmpty) ...[
          _buildSectionHeader(context, 'PREVIOUS ENTRIES'),
          _buildExpenseSliver(grouped.earlier),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSliver(List<ExpenseListItem> sectionItems) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExpenseCard(item: sectionItems[index]),
          ),
          childCount: sectionItems.length,
        ),
      ),
    );
  }
}

class _ExpensesSummaryHero extends StatelessWidget {
  const _ExpensesSummaryHero({
    required this.totalPending,
    required this.count,
    required this.totalAmount,
  });
  final int totalPending;
  final int count;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final totalRepaid = totalAmount - totalPending;
    final progress = totalAmount > 0 ? totalRepaid / totalAmount : 0.0;
    final pct = (progress * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHARED OUTSTANDING',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹$totalPending',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$count active ledger entries in shared vault.',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(
                progress: progress,
                size: 80,
                strokeWidth: 6,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'repaid',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.item});
  final ExpenseListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = item.totalAmount > 0
        ? item.repaidAmount / item.totalAmount
        : 0.0;
    final isSettled = item.remainingAmount == 0;

    return GlassCard(
      onTap: () {
        final debtRecord = PendingDebtRecord(
          debtId: item.id,
          friendId: item.friendId,
          friendName: item.friendName,
          note: item.note,
          category: item.category,
          totalAmount: item.totalAmount,
          repaidAmount: item.repaidAmount,
          createdAt: item.createdAt,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtDetailScreen(debt: debtRecord),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    CategoryUtils.getIcon(item.category),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${item.friendName} • ${_formatRelativeDate(item.createdAt)}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress,
                size: 40,
                strokeWidth: 3.5,
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(label: 'TOTAL', value: '₹${item.totalAmount}'),
              _MetricItem(
                label: 'PAID',
                value: '₹${item.repaidAmount}',
                color: AppTheme.secondary,
              ),
              _MetricItem(
                label: 'REMAINING',
                value: '₹${item.remainingAmount}',
                color: isSettled
                    ? AppTheme.secondary
                    : AppTheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStatusView(
      icon: Icons.receipt_long_outlined,
      title: 'Shared ledger empty',
      message: 'Add shared expenses to track splits with roommates.',
      actionLabel: 'Add Roommate',
      onAction: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AddFriendSheet(
            onCreated: () {
              ref.invalidate(friendOptionsProvider);
            },
          ),
        );
      },
    );
  }
}
class _SharedCategoryBreakdown extends ConsumerWidget {
  const _SharedCategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(sharedCategoryBreakdownProvider);

    return breakdownAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (error, _) => const SizedBox.shrink(),
      data: (breakdown) {
        if (breakdown.isEmpty) return const SizedBox.shrink();

        final totalAmount = breakdown.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: breakdown.map((item) {
              final color = CategoryUtils.getColor(item.category);
              final pct = totalAmount > 0 ? (item.amount / totalAmount) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${CategoryUtils.getIcon(item.category)}  ${item.category}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '₹${item.amount.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppTheme.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
