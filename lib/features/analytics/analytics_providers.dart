import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomledger/core/database/roomledger_database.dart';
import 'data/analytics_repository.dart';
import 'domain/analytics_models.dart';

// Database provider
final roomLedgerDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final database = ref.watch(roomLedgerDatabaseProvider);
  return AnalyticsRepository(database: database);
});

// Date range state notifier
class DateRangeNotifier extends StateNotifier<DateRange> {
  DateRangeNotifier() : super(DateRange.currentMonth());

  void setCurrentMonth() => state = DateRange.currentMonth();
  void setLastThreeMonths() => state = DateRange.lastMonths(3);
  void setLastSixMonths() => state = DateRange.lastMonths(6);
  void setLastYear() => state = DateRange.lastMonths(12);
  void setCustomRange(DateTime start, DateTime end) =>
      state = DateRange(startDate: start, endDate: end);
}

class DateRange {
  DateRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  factory DateRange.currentMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
    );
  }

  factory DateRange.lastMonths(int months) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final endDate = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    return DateRange(startDate: startDate, endDate: endDate);
  }
}

final dateRangeProvider = StateNotifierProvider<DateRangeNotifier, DateRange>((
  ref,
) {
  return DateRangeNotifier();
});

// Analytics report provider
final analyticsReportProvider = FutureProvider.autoDispose<AnalyticsReport>((
  ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final dateRange = ref.watch(dateRangeProvider);

  return repository.getAnalyticsReport(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});

// Spending trend provider
final spendingTrendProvider =
    FutureProvider.autoDispose<List<SpendingTrendPoint>>((ref) async {
      final repository = ref.watch(analyticsRepositoryProvider);
      final dateRange = ref.watch(dateRangeProvider);

      return repository.getSpendingTrend(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// Spending breakdown provider
final spendingBreakdownProvider = FutureProvider.autoDispose<SpendingBreakdown>(
  (ref) async {
    final repository = ref.watch(analyticsRepositoryProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return repository.getSpendingBreakdown(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

// Category breakdown provider
final categoryBreakdownProvider =
    FutureProvider.autoDispose<List<CategorySpending>>((ref) async {
      final repository = ref.watch(analyticsRepositoryProvider);
      final dateRange = ref.watch(dateRangeProvider);

      return repository.getCategoryBreakdown(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// Friend debt comparison provider
final friendDebtComparisonProvider =
    FutureProvider.autoDispose<List<FriendDebtComparison>>((ref) async {
      final repository = ref.watch(analyticsRepositoryProvider);
      final dateRange = ref.watch(dateRangeProvider);

      return repository.getFriendDebtComparison(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });
