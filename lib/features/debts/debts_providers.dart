import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/debts_repository.dart';
import 'domain/debts_models.dart';
import 'domain/grouped_debt_record.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  final database = ref.watch(roomLedgerDatabaseProvider);
  return DebtsRepository(database: database);
});

final pendingDebtsProvider = FutureProvider<List<PendingDebtRecord>>((
  ref,
) async {
  ref.watch(appDataVersionProvider);
  final repository = ref.watch(debtsRepositoryProvider);
  return repository.getPendingDebts();
});

final groupedDebtsProvider = FutureProvider<List<GroupedDebtRecord>>((
  ref,
) async {
  ref.watch(appDataVersionProvider);
  final repository = ref.watch(debtsRepositoryProvider);
  return repository.getGroupedPendingDebts();
});

final settlementsForDebtProvider =
    FutureProvider.family<List<SettlementRecord>, int>((ref, debtId) async {
      ref.watch(appDataVersionProvider);
      final repository = ref.watch(debtsRepositoryProvider);
      return repository.getSettlementsForDebt(debtId);
    });
