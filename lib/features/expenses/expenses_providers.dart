import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_providers.dart';
import 'data/expenses_repository.dart';
import 'domain/expense_models.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(roomLedgerDatabaseProvider));
});

final expensesListProvider = FutureProvider<List<ExpenseListItem>>((ref) {
  return ref.watch(expensesRepositoryProvider).loadExpenses();
});

final friendOptionsProvider = FutureProvider<List<FriendOption>>((ref) {
  return ref.watch(expensesRepositoryProvider).loadFriends();
});