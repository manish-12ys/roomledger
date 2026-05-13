import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_states.dart';
import 'cash_providers.dart';
import 'domain/cash_models.dart';

class CashManagementScreen extends ConsumerWidget {
  const CashManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(cashOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cash'),
      ),
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
    final controller = TextEditingController(text: overview.emergencyReserve.toString());
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
              ref.read(cashControllerProvider.notifier).updateEmergencyReserve(val);
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceCard(overview: overview),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showTransactionSheet(context, 'IN'),
                icon: const Icon(Icons.add),
                label: const Text('Cash In'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showTransactionSheet(context, 'OUT'),
                icon: const Icon(Icons.remove),
                label: const Text('Cash Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Emergency Reserve'),
            subtitle: Text('₹${overview.emergencyReserve}'),
            trailing: TextButton(
              onPressed: () => _showReserveDialog(context, ref),
              child: const Text('Edit'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Transactions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (overview.transactions.isEmpty)
          const AppStatusView(
            scrollable: false,
            icon: Icons.account_balance_wallet_outlined,
            title: 'No cash transactions yet',
            message: 'Add a cash-in or cash-out entry to build your history.',
          )
        else
          ...overview.transactions.map((tx) => _TransactionTile(tx: tx)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.overview});

  final CashOverview overview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = overview.isLowCash;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade900 : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: TextStyle(
              color: isLow ? Colors.red.shade100 : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${overview.currentBalance}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.white : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                size: 16,
                color: isLow ? Colors.red.shade100 : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Spent this month: ₹${overview.monthlyUsage}',
                style: TextStyle(
                  color: isLow ? Colors.red.shade100 : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOut ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isOut ? Icons.arrow_upward : Icons.arrow_downward,
            color: isOut ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
        title: Text(tx.note, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(formatter.format(tx.createdAt)),
        trailing: Text(
          '${isOut ? '-' : '+'}₹${tx.amount}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOut ? Colors.red.shade700 : Colors.green.shade700,
            fontSize: 16,
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Transaction'),
              content: const Text('Are you sure you want to delete this cash transaction?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    ref.read(cashControllerProvider.notifier).deleteTransaction(tx.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
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

    ref.read(cashControllerProvider.notifier).addTransaction(widget.type, amount, note);
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    backgroundColor: isOut ? Colors.red.shade700 : Colors.green.shade700,
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
