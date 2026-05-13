import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/roomledger_database.dart';
import 'data/dashboard_repository.dart';
import 'domain/dashboard_models.dart';

final roomLedgerDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(roomLedgerDatabaseProvider));
});

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((ref) {
  return ref.watch(dashboardRepositoryProvider).loadOverview();
});

enum TransactionFilter { all, expenses, repayments, personal }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter.all);