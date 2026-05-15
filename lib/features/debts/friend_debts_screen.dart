import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import 'debt_detail_screen.dart';
import 'domain/debts_models.dart';
import 'domain/grouped_debt_record.dart';

class FriendDebtsScreen extends ConsumerWidget {
  const FriendDebtsScreen({
    required this.groupedDebt,
    super.key,
  });

  final GroupedDebtRecord groupedDebt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = groupedDebt.totalAmount > 0
        ? groupedDebt.repaidAmount / groupedDebt.totalAmount
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${groupedDebt.friendName}\'s Debts'),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Friend summary header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Large avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.secondary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              groupedDebt.friendName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupedDebt.friendName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${groupedDebt.debts.length} active debt${groupedDebt.debts.length != 1 ? 's' : ''}',
                                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        ProgressRing(
                          progress: progress,
                          size: 56,
                          strokeWidth: 5,
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Financial breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          _Stat(label: 'Total', value: _formatCurrency(groupedDebt.totalAmount)),
                          _Stat(label: 'Paid', value: _formatCurrency(groupedDebt.repaidAmount), color: AppTheme.secondary),
                          _Stat(label: 'Remaining', value: _formatCurrency(groupedDebt.remainingAmount), color: groupedDebt.isOverdue ? AppTheme.error : null, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: AppTheme.animSlow,
                        curve: AppTheme.animCurve,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Section label
          SliverToBoxAdapter(
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
                    'INDIVIDUAL DEBTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Debt items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final debt = groupedDebt.debts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtItemCard(debt: debt),
                  );
                },
                childCount: groupedDebt.debts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color, this.isBold = false});

  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtItemCard extends StatelessWidget {
  const _DebtItemCard({required this.debt});

  final PendingDebtRecord debt;

  StatusType get _statusType {
    if (debt.isFullySettled) return StatusType.paid;
    if (debt.repaidAmount > 0) return StatusType.partial;
    if (debt.isOverdue) return StatusType.overdue;
    return StatusType.pending;
  }

  @override
  Widget build(BuildContext context) {
    final progress = debt.totalAmount > 0 ? debt.repaidAmount / debt.totalAmount : 0.0;

    return GlassCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtDetailScreen(debt: debt),
          ),
        );
      },
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.note,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(debt.createdAt)}',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(debt.remainingAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: debt.isOverdue ? AppTheme.error : AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusChip(type: _statusType),
                ],
              ),
            ],
          ),
          if (debt.repaidAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: AppTheme.animSlow,
                curve: AppTheme.animCurve,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(
                      debt.isOverdue ? AppTheme.error : AppTheme.secondary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid ${_formatCurrency(debt.repaidAmount)}',
                  style: TextStyle(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                Text(
                  'of ${_formatCurrency(debt.totalAmount)}',
                  style: TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

String _formatCurrency(int amount) {
  return '\u20b9${amount.toStringAsFixed(0)}';
}
