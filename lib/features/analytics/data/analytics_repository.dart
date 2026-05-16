import 'package:roomledger/core/database/roomledger_database.dart';
import '../domain/analytics_models.dart';

class AnalyticsRepository {
  const AnalyticsRepository({required this.database});

  final RoomLedgerDatabase database;

  /// Get spending trend for a date range (monthly or daily aggregation)
  Future<List<SpendingTrendPoint>> getSpendingTrend({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database.database;

    // Use daily grouping if the range is 31 days or less
    final isShortRange = endDate.difference(startDate).inDays <= 31;
    final format = isShortRange ? '%Y-%m-%d' : '%Y-%m';

    // 1. Get aggregated shared expenses (debts)
    final sharedResults = await db.rawQuery(
      '''
      SELECT 
        strftime(?, created_at) as key,
        MIN(created_at) as raw_date,
        SUM(total_amount) as amount
      FROM debts
      WHERE created_at BETWEEN ? AND ?
      GROUP BY key
    ''',
      [format, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // 2. Get aggregated personal expenses
    final personalResults = await db.rawQuery(
      '''
      SELECT 
        strftime(?, created_at) as key,
        MIN(created_at) as raw_date,
        SUM(amount) as amount
      FROM personal_expenses
      WHERE created_at BETWEEN ? AND ?
      GROUP BY key
    ''',
      [format, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // Combine data
    final aggregatedData = <String, _Aggregate>{};

    for (final row in sharedResults) {
      final key = row['key'] as String;
      final date = DateTime.parse(row['raw_date'] as String);
      final amount = (row['amount'] as num).toDouble();

      aggregatedData[key] = _Aggregate(date: date)..sharedAmount = amount;
    }

    for (final row in personalResults) {
      final key = row['key'] as String;
      final date = DateTime.parse(row['raw_date'] as String);
      final amount = (row['amount'] as num).toDouble();

      if (aggregatedData.containsKey(key)) {
        aggregatedData[key]!.personalAmount = amount;
      } else {
        aggregatedData[key] = _Aggregate(date: date)..personalAmount = amount;
      }
    }

    // Convert to sorted list
    final trends = aggregatedData.values
        .map(
          (agg) => SpendingTrendPoint(
            month: agg.date,
            amount: agg.totalAmount,
            sharedAmount: agg.sharedAmount,
            personalAmount: agg.personalAmount,
          ),
        )
        .toList();

    trends.sort((a, b) => a.month.compareTo(b.month));
    return trends;
  }

  /// Get spending breakdown for a date range
  Future<SpendingBreakdown> getSpendingBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database.database;

    // Get shared expenses total
    final debtResults = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM debts WHERE created_at BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final sharedTotal = (debtResults.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get personal expenses total
    final personalResults = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM personal_expenses WHERE created_at BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final personalTotal =
        (personalResults.first['total'] as num?)?.toDouble() ?? 0.0;

    return SpendingBreakdown(
      sharedTotal: sharedTotal,
      personalTotal: personalTotal,
    );
  }

  /// Get category breakdown for personal expenses
  Future<List<CategorySpending>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        category,
        COALESCE(SUM(amount), 0) as total,
        COUNT(*) as count
      FROM personal_expenses
      WHERE created_at BETWEEN ? AND ?
      GROUP BY category
      ORDER BY total DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results
        .map(
          (row) => CategorySpending(
            category: row['category'] as String,
            amount: (row['total'] as num).toDouble(),
            count: row['count'] as int,
          ),
        )
        .toList();
  }

  /// Get friend debt comparison for the date range
  Future<List<FriendDebtComparison>> getFriendDebtComparison({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database.database;

    // We use subqueries to avoid the Cartesian product duplication of total_debt
    // when a debt has multiple settlements.
    final results = await db.rawQuery(
      '''
      SELECT 
        f.id,
        f.name,
        (
          SELECT COALESCE(SUM(total_amount), 0) 
          FROM debts 
          WHERE friend_id = f.id AND created_at BETWEEN ? AND ?
        ) as total_debt,
        (
          SELECT COALESCE(SUM(s.amount), 0) 
          FROM settlements s 
          JOIN debts d ON s.debt_id = d.id 
          WHERE d.friend_id = f.id AND s.created_at BETWEEN ? AND ?
        ) as total_settled
      FROM friends f
      GROUP BY f.id, f.name
      HAVING total_debt > 0 OR total_settled > 0
      ORDER BY total_debt DESC
    ''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return results.map((row) {
      final totalDebt = (row['total_debt'] as num).toDouble();
      final totalSettled = (row['total_settled'] as num).toDouble();
      return FriendDebtComparison(
        friendId: (row['id'] as int).toString(),
        friendName: row['name'] as String,
        totalDebt: totalDebt,
        totalSettled: totalSettled,
        pendingAmount: totalDebt - totalSettled,
      );
    }).toList();
  }

  /// Get complete analytics report for a date range
  Future<AnalyticsReport> getAnalyticsReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final trend = await getSpendingTrend(
      startDate: startDate,
      endDate: endDate,
    );
    final breakdown = await getSpendingBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
    final categoryBreakdown = await getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
    final friendComparison = await getFriendDebtComparison(
      startDate: startDate,
      endDate: endDate,
    );

    return AnalyticsReport(
      startDate: startDate,
      endDate: endDate,
      spendingTrend: trend,
      breakdown: breakdown,
      categoryBreakdown: categoryBreakdown,
      friendDebtComparison: friendComparison,
    );
  }

  /// Get analytics for current month
  Future<AnalyticsReport> getCurrentMonthAnalytics() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return getAnalyticsReport(startDate: startDate, endDate: endDate);
  }

  /// Get analytics for last N months (default 6)
  Future<AnalyticsReport> getLastMonthsAnalytics({int months = 6}) async {
    final now = DateTime.now();
    final endDate = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));
    final startDate = DateTime(endDate.year, endDate.month - months + 1, 1);

    return getAnalyticsReport(startDate: startDate, endDate: endDate);
  }
}

class _Aggregate {
  _Aggregate({required this.date});

  final DateTime date;
  double sharedAmount = 0;
  double personalAmount = 0;

  double get totalAmount => sharedAmount + personalAmount;
}
