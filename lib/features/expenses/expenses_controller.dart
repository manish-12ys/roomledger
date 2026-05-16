import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/expense_models.dart';
import 'expenses_providers.dart';

class GroupedExpenses {
  const GroupedExpenses({
    required this.today,
    required this.yesterday,
    required this.earlier,
    required this.totalPending,
    required this.totalAmount,
  });

  final List<ExpenseListItem> today;
  final List<ExpenseListItem> yesterday;
  final List<ExpenseListItem> earlier;
  final int totalPending;
  final int totalAmount;
}

final groupedExpensesProvider = Provider<AsyncValue<GroupedExpenses>>((ref) {
  final expensesAsync = ref.watch(expensesListProvider);

  return expensesAsync.whenData((items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <ExpenseListItem>[];
    final yesterdayItems = <ExpenseListItem>[];
    final earlierItems = <ExpenseListItem>[];

    for (final item in items) {
      final itemDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (itemDate == today) {
        todayItems.add(item);
      } else if (itemDate == yesterday) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    final totalPending = items.fold<int>(0, (s, e) => s + e.remainingAmount);
    final totalAmount = items.fold<int>(0, (s, e) => s + e.totalAmount);

    return GroupedExpenses(
      today: todayItems,
      yesterday: yesterdayItems,
      earlier: earlierItems,
      totalPending: totalPending,
      totalAmount: totalAmount,
    );
  });
});
