import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'debts_providers.dart';
import 'domain/grouped_debt_record.dart';
import 'friend_debts_screen.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(groupedDebtsProvider);
    final allDebtsAsync = ref.watch(pendingDebtsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: debtsAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.error_outline,
          title: 'Ledger Error',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(groupedDebtsProvider),
        ),
        data: (debts) {
          // Use all debts (including settled) for the ring — same as Shared Ledger
          final allDebts = allDebtsAsync.valueOrNull ?? [];
          final totalDebt = allDebts.fold<int>(0, (s, d) => s + d.totalAmount);
          final totalRepaid = allDebts.fold<int>(
            0,
            (s, d) => s + d.repaidAmount,
          );
          return RefreshIndicator(
            color: AppTheme.secondary,
            backgroundColor: AppTheme.surfaceElevated,
            onRefresh: () async {
              ref.invalidate(groupedDebtsProvider);
              ref.invalidate(pendingDebtsProvider);
              await ref.read(groupedDebtsProvider.future);
            },
            child: debts.isEmpty
                ? const _EmptyState()
                : _DebtsContent(
                    debts: debts,
                    totalDebt: totalDebt,
                    totalRepaid: totalRepaid,
                  ),
          );
        },
      ),
    );
  }
}

class _DebtsContent extends StatelessWidget {
  const _DebtsContent({
    required this.debts,
    required this.totalDebt,
    required this.totalRepaid,
  });

  final List<GroupedDebtRecord> debts;
  final num totalDebt;
  final num totalRepaid;

  @override
  Widget build(BuildContext context) {
    final totalPending = debts.fold<num>(0, (s, d) => s + d.remainingAmount);
    final overallProgress = totalDebt > 0 ? totalRepaid / totalDebt : 0.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Premium Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: const Text(
              'Pending Debts',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),

        // Hero Summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pending',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(totalPending),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeroIndicator(
                              label: 'Debtors',
                              value: '${debts.length}',
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 16),
                            _HeroIndicator(
                              label: 'Overdue',
                              value:
                                  '${debts.where((d) => d.isOverdue).length}',
                              color: const Color(0xFFFF5252),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProgressRing(
                        progress: overallProgress,
                        size: 84,
                        strokeWidth: 7,
                        child: Text(
                          '${(overallProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
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
            ),
          ),
        ),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BY ROOMMATE',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Debt Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RoommateDebtCard(record: debts[index]),
              ),
              childCount: debts.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}

class _HeroIndicator extends StatelessWidget {
  const _HeroIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoommateDebtCard extends StatelessWidget {
  const _RoommateDebtCard({required this.record});

  final GroupedDebtRecord record;

  @override
  Widget build(BuildContext context) {
    final progress = record.totalAmount > 0
        ? record.repaidAmount / record.totalAmount
        : 0.0;

    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendDebtsScreen(groupedDebt: record),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    record.friendName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.friendName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.debts.length} pending items',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress,
                size: 48,
                strokeWidth: 4.5,
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inner Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151515), // Dark inner card
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatColumn(label: 'Total', value: _formatCurrency(record.totalAmount)),
                _StatColumn(
                  label: 'Paid',
                  value: _formatCurrency(record.repaidAmount),
                  color: AppTheme.secondary,
                ),
                _StatColumn(
                  label: 'Remaining',
                  value: _formatCurrency(record.remainingAmount),
                  color: AppTheme.secondary,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress underline
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool isBold;

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
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppStatusView(
      icon: Icons.done_all_rounded,
      title: 'Clear Skies',
      message: 'No pending debts at the moment.',
    );
  }
}

String _formatCurrency(num amount) {
  return '₹$amount';
}
