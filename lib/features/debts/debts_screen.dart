import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_states.dart';
import 'debts_providers.dart';
import 'domain/grouped_debt_record.dart';
import 'friend_debts_screen.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(groupedDebtsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Debts')),
      body: debtsAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (error, stackTrace) => _ErrorState(
          message: 'Could not load debts.',
          details: error.toString(),
          onRetry: () => ref.invalidate(groupedDebtsProvider),
        ),
        data: (debts) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupedDebtsProvider);
            await ref.read(groupedDebtsProvider.future);
          },
          child: debts.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: debts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final groupedDebt = debts[index];
                    return _GroupedDebtCard(
                      groupedDebt: groupedDebt,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _GroupedDebtCard extends StatelessWidget {
  const _GroupedDebtCard({
    required this.groupedDebt,
  });

  final GroupedDebtRecord groupedDebt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverdue = groupedDebt.isOverdue;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDebtsScreen(groupedDebt: groupedDebt),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isOverdue 
                        ? colorScheme.error.withValues(alpha: 0.10) 
                        : colorScheme.primary.withValues(alpha: 0.10),
                    child: Text(
                      groupedDebt.friendName.substring(0, 1),
                      style: TextStyle(
                        color: isOverdue ? colorScheme.error : colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupedDebt.friendName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '${groupedDebt.debts.length} pending items',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryItem(
                    label: 'Total',
                    value: _formatCurrency(groupedDebt.totalAmount),
                  ),
                  _SummaryItem(
                    label: 'Paid',
                    value: _formatCurrency(groupedDebt.repaidAmount),
                    color: colorScheme.primary,
                  ),
                  _SummaryItem(
                    label: 'Remaining',
                    value: _formatCurrency(groupedDebt.remainingAmount),
                    color: isOverdue ? colorScheme.error : null,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppStatusView(
      icon: Icons.check_circle_outline,
      title: 'No pending debts',
      message: 'All debts are settled!',
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
    return AppStatusView(
      icon: Icons.error_outline,
      title: message,
      message: details,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

String _formatCurrency(int amount) {
  return '₹${amount.toStringAsFixed(0)}';
}
