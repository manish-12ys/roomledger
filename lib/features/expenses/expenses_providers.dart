import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/expenses_repository.dart';
import 'domain/expense_models.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(roomLedgerDatabaseProvider));
});

final expensesListProvider = FutureProvider<List<ExpenseListItem>>((ref) {
  ref.watch(appDataVersionProvider);
  return ref.watch(expensesRepositoryProvider).loadExpenses();
});

final friendOptionsProvider = FutureProvider<List<FriendOption>>((ref) {
  ref.watch(appDataVersionProvider);
  return ref.watch(expensesRepositoryProvider).loadFriends();
});