import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'cash_providers.dart';
import 'domain/cash_models.dart';

class CashManagementScreen extends ConsumerWidget {
  const CashManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(cashOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cash')),
      body: overviewAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 3),
        error: (err, stack) => AppStatusView(
          icon: Icons.error_outline,
          title: 'Could not load cash data',
          message: err.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(cashOverviewProvider),
        ),
        data: (overview) => _CashContent(overview: overview),
      ),
    );
  }
}

class _CashContent extends ConsumerWidget {
  const _CashContent({required this.overview});

  final CashOverview overview;

  void _showTransactionSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransactionForm(type: type),
    );
  }

  void _showReserveDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: overview.emergencyReserve.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Reserve'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              ref
                  .read(cashControllerProvider.notifier)
                  .updateEmergencyReserve(val);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.background,
            AppTheme.surface.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BalanceCard(overview: overview),
          const AppSpacing.vertical(20),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Cash In',
                  icon: Icons.add_rounded,
                  onPressed: () => _showTransactionSheet(context, 'IN'),
                  variant: ActionButtonVariant.primary,
                ),
              ),
              const AppSpacing.horizontal(16),
              Expanded(
                child: ActionButton(
                  label: 'Cash Out',
                  icon: Icons.remove_rounded,
                  onPressed: () => _showTransactionSheet(context, 'OUT'),
                  variant: ActionButtonVariant.secondary,
                ),
              ),
            ],
          ),
          const AppSpacing.vertical(20),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            accentColor: AppTheme.secondary,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.secondary),
                const AppSpacing.horizontal(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Reserve',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '₹${overview.emergencyReserve}',
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showReserveDialog(context, ref),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          const AppSpacing.vertical(32),
          Text(
            'Transactions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const AppSpacing.vertical(12),
          if (overview.transactions.isEmpty)
            const AppStatusView(
              scrollable: false,
              icon: Icons.account_balance_wallet_outlined,
              title: 'No transactions',
              message: 'Add a cash entry to see it here.',
            )
          else
            ...overview.transactions.map((tx) => _TransactionTile(tx: tx)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.overview});

  final CashOverview overview;

  @override
  Widget build(BuildContext context) {
    final isLow = overview.isLowCash;
    final accentColor = isLow ? AppTheme.error : AppTheme.secondary;

    return GlassCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(AppTheme.space400),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: isLow ? AppTheme.error : AppTheme.onSurfaceVariant,
              ),
              const AppSpacing.horizontal(8),
              Text(
                'Current Balance',
                style: TextStyle(
                  color: isLow ? AppTheme.error : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const AppSpacing.vertical(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Text(
                  '₹',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              AnimatedCounterText(
                value: overview.currentBalance,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const AppSpacing.vertical(20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppTheme.muted,
                ),
                const AppSpacing.horizontal(8),
                Text(
                  'Spent this month: ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                Text(
                  '₹${overview.monthlyUsage}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.tx});

  final CashTransaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOut = tx.type == 'OUT';
    final formatter = DateFormat('MMM d, yyyy');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      accentColor: isOut ? AppTheme.error : AppTheme.success,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isOut ? AppTheme.error : AppTheme.success).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isOut ? AppTheme.error : AppTheme.success,
              size: 20,
            ),
          ),
          const AppSpacing.horizontal(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  formatter.format(tx.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isOut ? '-' : '+'}₹${tx.amount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isOut ? AppTheme.error : AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({required this.type});

  final String type;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text);
    final note = _noteController.text.trim();

    if (amount == null || amount <= 0 || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and note')),
      );
      return;
    }

    ref
        .read(cashControllerProvider.notifier)
        .addTransaction(widget.type, amount, note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isOut = widget.type == 'OUT';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isOut ? 'Cash Out' : 'Cash In',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Note (e.g., ATM Withdrawal, Groceries)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: isOut ? 'Record cash out' : 'Record cash in',
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: isOut ? AppTheme.error : AppTheme.success,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isOut ? 'Record Expense' : 'Add Cash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
