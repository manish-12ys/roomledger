import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/dashboard_repository.dart';
import 'domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(roomLedgerDatabaseProvider));
});

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((ref) {
  ref.watch(appDataVersionProvider);
  return ref.watch(dashboardRepositoryProvider).loadOverview();
});

enum TransactionFilter { all, expenses, repayments, personal }

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter.all);