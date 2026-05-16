import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/category_utils.dart';
import '../../core/widgets/app_components.dart';
import '../dashboard/dashboard_providers.dart';
import '../expenses/expenses_providers.dart';
import '../expenses/expenses_controller.dart';
import '../analytics/analytics_providers.dart';
import 'debts_providers.dart';
import 'domain/debts_models.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({required this.debt, super.key});

  final PendingDebtRecord debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(settlementsForDebtProvider(debt.debtId));

    return Scaffold(
      appBar: AppBar(title: const Text('Debt Details')),
      body: settlementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: 'Could not load settlement history.',
          details: error.toString(),
          onRetry: () =>
              ref.invalidate(settlementsForDebtProvider(debt.debtId)),
        ),
        data: (settlements) {
          // Calculate actual repaid amount from settlements list for real-time updates
          final actualRepaidAmount = settlements.fold<int>(
            0,
            (sum, s) => sum + s.amount,
          );

          final liveDebt = PendingDebtRecord(
            debtId: debt.debtId,
            friendId: debt.friendId,
            friendName: debt.friendName,
            note: debt.note,
            category: debt.category,
            totalAmount: debt.totalAmount,
            repaidAmount: actualRepaidAmount,
            createdAt: debt.createdAt,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PremiumSummaryCard(debt: liveDebt),
                  const SizedBox(height: 20),
                  _AnimatedProgressSection(debt: liveDebt),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'SETTLEMENT TIMELINE'),
                  const SizedBox(height: 12),
                  if (settlements.isEmpty)
                    _EmptyTimeline()
                  else
                    _SettlementTimeline(settlements: settlements),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: !debt.isFullySettled
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: () => _openRecordSettlementSheet(context, ref),
                  icon: Icons.add,
                  label: 'Record Payment',
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _openRecordSettlementSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _RecordSettlementSheet(
          debt: debt,
          onCreated: () {
            ref.invalidate(pendingDebtsProvider);
            ref.invalidate(settlementsForDebtProvider(debt.debtId));
            ref.invalidate(dashboardOverviewProvider);
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _PremiumSummaryCard extends StatelessWidget {
  const _PremiumSummaryCard({required this.debt});

  final PendingDebtRecord debt;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: debt.isOverdue ? AppTheme.error : AppTheme.secondary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    CategoryUtils.getIcon(debt.category),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Split with ${debt.friendName}',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (debt.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        debt.note,
                        style: TextStyle(
                          color: AppTheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(debt.createdAt)}',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Debt',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(debt.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        color: debt.isOverdue ? AppTheme.error : AppTheme.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(debt.remainingAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: debt.remainingAmount == 0
                            ? AppTheme.success
                            : debt.isOverdue
                            ? AppTheme.error
                            : AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (debt.isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Overdue by ${DateTime.now().difference(debt.createdAt).inDays} days',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedProgressSection extends StatelessWidget {
  const _AnimatedProgressSection({required this.debt});

  final PendingDebtRecord debt;

  @override
  Widget build(BuildContext context) {
    final progress = debt.totalAmount > 0
        ? debt.repaidAmount / debt.totalAmount
        : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress * 100),
                duration: AppTheme.animSlow,
                curve: AppTheme.animCurve,
                builder: (context, value, _) {
                  return Text(
                    '${value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular progress ring centered
          Center(
            child: ProgressRing(
              progress: progress,
              size: 100,
              strokeWidth: 8,
              activeColor: debt.remainingAmount == 0
                  ? AppTheme.success
                  : AppTheme.secondary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrency(debt.repaidAmount),
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'paid',
                    style: TextStyle(color: AppTheme.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Milestone markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Milestone(label: '0%', isReached: true),
              _Milestone(label: '25%', isReached: progress >= 0.25),
              _Milestone(label: '50%', isReached: progress >= 0.50),
              _Milestone(label: '75%', isReached: progress >= 0.75),
              _Milestone(label: '100%', isReached: progress >= 1.0),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ${_formatCurrency(debt.repaidAmount)}',
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Pending: ${_formatCurrency(debt.remainingAmount)}',
                style: TextStyle(
                  color: debt.remainingAmount == 0
                      ? AppTheme.success
                      : AppTheme.onSurfaceVariant,
                  fontSize: 11,
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

class _Milestone extends StatelessWidget {
  const _Milestone({required this.label, required this.isReached});

  final String label;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isReached ? AppTheme.secondary : AppTheme.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: isReached ? AppTheme.secondary : AppTheme.muted,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isReached ? AppTheme.secondary : AppTheme.muted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 24,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No payments recorded yet',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SettlementTimeline extends StatelessWidget {
  const _SettlementTimeline({required this.settlements});

  final List<SettlementRecord> settlements;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(settlements.length, (index) {
        final settlement = settlements[index];
        final isFirst = index == 0;
        final isLast = index == settlements.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimelineDot(
                isFirst: isFirst,
                isLast: isLast,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settlement.note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(settlement.createdAt),
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formatCurrency(settlement.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RecordSettlementSheet extends ConsumerStatefulWidget {
  const _RecordSettlementSheet({required this.debt, required this.onCreated});

  final PendingDebtRecord debt;
  final VoidCallback onCreated;

  @override
  ConsumerState<_RecordSettlementSheet> createState() =>
      _RecordSettlementSheetState();
}

class _RecordSettlementSheetState
    extends ConsumerState<_RecordSettlementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Payment',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.debt.friendName} \u00b7 ${widget.debt.note}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining to pay',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(widget.debt.remainingAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total debt',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(widget.debt.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (\u20b9)',
                  hintText: 'Enter amount to pay',
                  prefixText: '\u20b9 ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount > widget.debt.remainingAmount) {
                    return 'Cannot exceed remaining amount (\u20b9${widget.debt.remainingAmount})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Payment Note (Optional)',
                  hintText: 'e.g., Partial payment in cash',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitForm,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final amount = int.parse(_amountController.text);
      final note = _noteController.text.isNotEmpty
          ? _noteController.text
          : 'Payment recorded';

      final repository = ref.read(debtsRepositoryProvider);
      await repository.addSettlement(
        debtId: widget.debt.debtId,
        amount: amount,
        note: note,
      );

      // Invalidate providers to force immediate UI refresh
      ref.invalidate(settlementsForDebtProvider(widget.debt.debtId));
      ref.invalidate(expensesListProvider);
      ref.invalidate(groupedExpensesProvider);
      ref.invalidate(pendingDebtsProvider);
      ref.invalidate(groupedDebtsProvider);
      ref.invalidate(dashboardOverviewProvider);
      // Invalidate analytics as well
      ref.invalidate(sharedCategoryBreakdownProvider);

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of \u20b9$amount recorded'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
  return '\u20b9${amount.toStringAsFixed(0)}';
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays == 1) {
    return 'yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  } else {
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
}
