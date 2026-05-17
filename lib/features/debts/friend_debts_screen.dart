import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/category_utils.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import '../../core/providers/app_providers.dart';
import 'debt_detail_screen.dart';
import 'debts_providers.dart';
import 'domain/debts_models.dart';
import 'domain/grouped_debt_record.dart';

class FriendDebtsScreen extends ConsumerWidget {
  const FriendDebtsScreen({required this.groupedDebt, super.key});

  final GroupedDebtRecord groupedDebt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(groupedDebtsProvider);

    // Find the latest data for this friend, or use passed data as fallback
    final currentDebt = debtsAsync.maybeWhen(
      data: (list) {
        try {
          return list.firstWhere((g) => g.friendId == groupedDebt.friendId);
        } catch (_) {
          // Friend no longer has pending debts
          return null;
        }
      },
      orElse: () => groupedDebt,
    );

    // If friend is no longer in pending list, they are fully settled
    if (currentDebt == null) {
      return Scaffold(
        appBar: AppBar(title: Text('${groupedDebt.friendName}\'s Debts')),
        body: const AppStatusView(
          icon: Icons.done_all_rounded,
          title: 'Fully Settled!',
          message: 'All debts for this friend have been cleared.',
        ),
      );
    }

    final progress = currentDebt.totalAmount > 0
        ? currentDebt.repaidAmount / currentDebt.totalAmount
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text('${currentDebt.friendName}\'s Debts')),
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
                              currentDebt.friendName
                                  .substring(0, 1)
                                  .toUpperCase(),
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
                                currentDebt.friendName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentDebt.debts.length} active debt${currentDebt.debts.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
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
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        children: [
                          _Stat(
                            label: 'Total',
                            value: _formatCurrency(currentDebt.totalAmount),
                          ),
                          _Stat(
                            label: 'Paid',
                            value: _formatCurrency(currentDebt.repaidAmount),
                            color: AppTheme.secondary,
                          ),
                          _Stat(
                            label: 'Remaining',
                            value: _formatCurrency(currentDebt.remainingAmount),
                            color: currentDebt.isOverdue
                                ? AppTheme.error
                                : null,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bulk Action Button
                    SizedBox(
                      width: double.infinity,
                      child: NeumorphicButton(
                        onPressed: () => _openQuickSettleSheet(context, ref, currentDebt),
                        label: 'Bulk Repayment',
                        icon: Icons.bolt_rounded,
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
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.secondary,
                            ),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final debt = currentDebt.debts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DebtItemCard(debt: debt),
                );
              }, childCount: currentDebt.debts.length),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuickSettleSheet(
    BuildContext context,
    WidgetRef ref,
    GroupedDebtRecord groupedDebt,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _QuickSettleSheet(groupedDebt: groupedDebt),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    if (debt.isOverdue) return StatusType.overdue;
    if (debt.repaidAmount > 0) return StatusType.partial;
    return StatusType.pending;
  }

  @override
  Widget build(BuildContext context) {
    final progress = debt.totalAmount > 0
        ? debt.repaidAmount / debt.totalAmount
        : 0.0;

    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DebtDetailScreen(debt: debt),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.onSurface.withValues(alpha: 0.05),
                  ),
                ),
                child: Center(
                  child: Text(
                    CategoryUtils.getIcon(debt.category),
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
                      debt.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(debt.createdAt)}',
                      style: TextStyle(color: AppTheme.muted, fontSize: 10),
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
                      color: debt.isOverdue
                          ? AppTheme.error
                          : AppTheme.secondary,
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
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'of ${_formatCurrency(debt.totalAmount)}',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
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

class _QuickSettleSheet extends ConsumerStatefulWidget {
  const _QuickSettleSheet({required this.groupedDebt});

  final GroupedDebtRecord groupedDebt;

  @override
  ConsumerState<_QuickSettleSheet> createState() => _QuickSettleSheetState();
}

class _QuickSettleSheetState extends ConsumerState<_QuickSettleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.groupedDebt.remainingAmount.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final amount = int.parse(_amountController.text);
      final note = _noteController.text.isNotEmpty
          ? _noteController.text
          : 'Bulk Repayment';

      final repository = ref.read(debtsRepositoryProvider);
      await repository.settleFriendDebts(
        friendId: widget.groupedDebt.friendId,
        amount: amount,
        note: note,
      );

      // Signal that app data has changed to trigger global reactive updates
      ref.read(appDataVersionProvider.notifier).state++;

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processed \u20b9$amount repayment for ${widget.groupedDebt.friendName}'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Settlement',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Paying to ${widget.groupedDebt.friendName}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount to Pay',
                  hintText: '0',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount';
                    final amount = int.tryParse(value);
                    if (amount == null || amount <= 0) return 'Invalid amount';
                    if (amount > widget.groupedDebt.remainingAmount) {
                      return 'Exceeds total debt (\u20b9${widget.groupedDebt.remainingAmount})';
                    }
                    return null;
                  },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Bulk Repayment',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: _submitting ? () {} : () => _submitForm(),
                  label: _submitting ? 'Processing...' : 'Confirm Repayment',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(num amount) {
  return '\u20b9$amount';
}
