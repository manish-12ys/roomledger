import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${groupedDebt.friendName}\'s Debts'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: groupedDebt.debts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final debt = groupedDebt.debts[index];
          return _DebtItemCard(debt: debt);
        },
      ),
    );
  }
}

class _DebtItemCard extends StatelessWidget {
  const _DebtItemCard({required this.debt});

  final PendingDebtRecord debt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DebtDetailScreen(debt: debt),
            ),
          );
        },
        title: Text(debt.note, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Created ${_formatDate(debt.createdAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${debt.remainingAmount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: debt.isOverdue ? colorScheme.error : colorScheme.primary,
                fontSize: 16,
              ),
            ),
            if (debt.repaidAmount > 0)
              Text(
                'Paid ₹${debt.repaidAmount}',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
