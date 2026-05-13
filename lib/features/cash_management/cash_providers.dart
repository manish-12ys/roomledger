import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/roomledger_database.dart';
import 'data/cash_repository.dart';
import 'domain/cash_models.dart';

final cashDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  final db = ref.watch(cashDatabaseProvider);
  return CashRepository(db);
});

final cashOverviewProvider = FutureProvider<CashOverview>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.getCashOverview();
});

class CashController extends StateNotifier<AsyncValue<void>> {
  CashController(this._repo, this._ref) : super(const AsyncData(null));

  final CashRepository _repo;
  final Ref _ref;

  Future<void> addTransaction(String type, int amount, String note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.addTransaction(type, amount, note);
      _ref.invalidate(cashOverviewProvider);
    });
  }

  Future<void> updateEmergencyReserve(int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateEmergencyReserve(amount);
      _ref.invalidate(cashOverviewProvider);
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteTransaction(id);
      _ref.invalidate(cashOverviewProvider);
    });
  }
}

final cashControllerProvider = StateNotifierProvider<CashController, AsyncValue<void>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return CashController(repo, ref);
});
