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

    // 1. Get aggregated shared expenses (debts) - Total historical volume
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
      final amount = (row['amount'] as num).toInt();

      aggregatedData[key] = _Aggregate(date: date)..sharedAmount = amount;
    }

    for (final row in personalResults) {
      final key = row['key'] as String;
      final date = DateTime.parse(row['raw_date'] as String);
      final amount = (row['amount'] as num).toInt();

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

    // Get shared expenses total - Total historical volume
    final debtResults = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM debts WHERE created_at BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final sharedTotal = (debtResults.first['total'] as num?)?.toInt() ?? 0;

    // Get personal expenses total
    final personalResults = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM personal_expenses WHERE created_at BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final personalTotal =
        (personalResults.first['total'] as num?)?.toInt() ?? 0;

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
        COALESCE(SUM(item_count), 0) as total_count
      FROM (
        SELECT 
          category, 
          SUM(amount) as amount, 
          COUNT(*) as item_count 
        FROM personal_expenses 
        WHERE created_at BETWEEN ? AND ? 
        GROUP BY category
        
        UNION ALL
        
        SELECT 
          category, 
          SUM(total_amount) as amount, 
          COUNT(*) as item_count 
        FROM debts 
        WHERE created_at BETWEEN ? AND ? 
        GROUP BY category
      ) t
      GROUP BY category
      ORDER BY total DESC
    ''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return results
        .map(
          (row) => CategorySpending(
            category: row['category'] as String? ?? 'Others',
            amount: (row['total'] as num?)?.toInt() ?? 0,
            count: (row['total_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  /// Get category breakdown for shared expenses (debts table)
  Future<List<CategorySpending>> getSharedCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        d.category, 
        SUM(d.total_amount - COALESCE(s.repaid, 0)) as total, 
        COUNT(*) as total_count 
      FROM debts d 
      LEFT JOIN (
        SELECT debt_id, SUM(amount) as repaid 
        FROM settlements 
        GROUP BY debt_id
      ) s ON d.id = s.debt_id
      WHERE d.created_at BETWEEN ? AND ? 
      GROUP BY d.category
      HAVING total > 0
      ORDER BY total DESC
    ''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return results
        .map(
          (row) => CategorySpending(
            category: row['category'] as String? ?? 'Others',
            amount: (row['total'] as num?)?.toInt() ?? 0,
            count: (row['total_count'] as num?)?.toInt() ?? 0,
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
        ) as total_settled,
        (
          SELECT 
            COALESCE(SUM(d.total_amount), 0) - COALESCE((
              SELECT SUM(s2.amount) 
              FROM settlements s2 
              JOIN debts d2 ON s2.debt_id = d2.id 
              WHERE d2.friend_id = f.id AND s2.created_at <= ?
            ), 0)
          FROM debts d
          WHERE d.friend_id = f.id AND d.created_at <= ?
        ) as pending_amount
      FROM friends f
      GROUP BY f.id, f.name
      HAVING total_debt > 0 OR total_settled > 0 OR pending_amount > 0
      ORDER BY total_debt DESC
    ''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        endDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return results.map((row) {
      final totalDebt = (row['total_debt'] as num).toInt();
      final totalSettled = (row['total_settled'] as num).toInt();
      final pendingAmount = (row['pending_amount'] as num).toInt();
      return FriendDebtComparison(
        friendId: (row['id'] as int).toString(),
        friendName: row['name'] as String,
        totalDebt: totalDebt,
        totalSettled: totalSettled,
        pendingAmount: pendingAmount,
      );
    }).toList();
  }

  /// Get category breakdown for shared expenses (debts table) for all time
  Future<List<CategorySpending>> getHistoricalSharedCategoryBreakdown() async {
    final db = await database.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        d.category, 
        SUM(d.total_amount) as total, 
        COUNT(*) as total_count 
      FROM debts d 
      GROUP BY d.category
      HAVING total > 0
      ORDER BY total DESC
    '''
    );

    return results
        .map(
          (row) => CategorySpending(
            category: row['category'] as String? ?? 'Others',
            amount: (row['total'] as num?)?.toInt() ?? 0,
            count: (row['total_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  /// Get friend debt comparison for all time
  Future<List<FriendDebtComparison>> getHistoricalFriendDebtComparison() async {
    final db = await database.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        f.id,
        f.name,
        (
          SELECT COALESCE(SUM(total_amount), 0) 
          FROM debts 
          WHERE friend_id = f.id
        ) as total_debt,
        (
          SELECT COALESCE(SUM(s.amount), 0) 
          FROM settlements s 
          JOIN debts d ON s.debt_id = d.id 
          WHERE d.friend_id = f.id
        ) as total_settled,
        (
          SELECT 
            COALESCE(SUM(d.total_amount), 0) - COALESCE((
              SELECT SUM(s2.amount) 
              FROM settlements s2 
              JOIN debts d2 ON s2.debt_id = d2.id 
              WHERE d2.friend_id = f.id
            ), 0)
          FROM debts d
          WHERE d.friend_id = f.id
        ) as pending_amount
      FROM friends f
      GROUP BY f.id, f.name
      HAVING total_debt > 0 OR total_settled > 0 OR pending_amount > 0
      ORDER BY total_debt DESC
    '''
    );

    return results.map((row) {
      final totalDebt = (row['total_debt'] as num).toInt();
      final totalSettled = (row['total_settled'] as num).toInt();
      final pendingAmount = (row['pending_amount'] as num).toInt();
      return FriendDebtComparison(
        friendId: (row['id'] as int).toString(),
        friendName: row['name'] as String,
        totalDebt: totalDebt,
        totalSettled: totalSettled,
        pendingAmount: pendingAmount,
      );
    }).toList();
  }

  /// Get historical shared spending and repayment totals
  Future<Map<String, int>> getHistoricalSharedTotals() async {
    final db = await database.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        (SELECT COALESCE(SUM(total_amount), 0) FROM debts) as total_spending,
        (SELECT COALESCE(SUM(amount), 0) FROM settlements) as total_repaid
      '''
    );

    if (results.isEmpty) {
      return {'total_spending': 0, 'total_repaid': 0};
    }

    return {
      'total_spending': (results.first['total_spending'] as num?)?.toInt() ?? 0,
      'total_repaid': (results.first['total_repaid'] as num?)?.toInt() ?? 0,
    };
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
    
    final histSharedCategory = await getHistoricalSharedCategoryBreakdown();
    final histFriendComparison = await getHistoricalFriendDebtComparison();
    final histTotals = await getHistoricalSharedTotals();

    return AnalyticsReport(
      startDate: startDate,
      endDate: endDate,
      spendingTrend: trend,
      breakdown: breakdown,
      categoryBreakdown: categoryBreakdown,
      friendDebtComparison: friendComparison,
      historicalSharedCategoryBreakdown: histSharedCategory,
      historicalFriendComparison: histFriendComparison,
      historicalSharedTotal: histTotals['total_spending'] ?? 0,
      historicalSharedRepaid: histTotals['total_repaid'] ?? 0,
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
  int sharedAmount = 0;
  int personalAmount = 0;

  int get totalAmount => sharedAmount + personalAmount;
}
