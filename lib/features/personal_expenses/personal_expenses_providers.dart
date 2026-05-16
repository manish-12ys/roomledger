import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/personal_expenses_repository.dart';
import 'domain/personal_expense_models.dart';

final personalExpensesRepositoryProvider =
    FutureProvider<PersonalExpensesRepository>((ref) async {
      final database = ref.watch(roomLedgerDatabaseProvider);
      final repository = PersonalExpensesRepository(database: database);
      await repository.createPersonalExpensesTable();
      return repository;
    });

final personalExpensesSummaryProvider = FutureProvider<PersonalExpenseSummary>((
  ref,
) async {
  ref.watch(appDataVersionProvider);
  final repository = await ref.watch(personalExpensesRepositoryProvider.future);
  return repository.getSummary();
});

final personalExpensesListProvider = FutureProvider<List<PersonalExpense>>((
  ref,
) async {
  ref.watch(appDataVersionProvider);
  final repository = await ref.watch(personalExpensesRepositoryProvider.future);
  return repository.getExpenses();
});
