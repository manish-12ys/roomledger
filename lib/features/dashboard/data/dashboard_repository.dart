import '../../../core/database/roomledger_database.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._database);

  final RoomLedgerDatabase _database;

  Future<DashboardOverview> loadOverview() async {
    final database = await _database.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    // 1. Calculate Monthly Spending (Shared + Personal) via SQL
    final spendingResult = await database.rawQuery(
      '''
      SELECT 
        (SELECT COALESCE(SUM(total_amount), 0) FROM debts WHERE created_at >= ?) as shared_spending,
        (SELECT COALESCE(SUM(amount), 0) FROM personal_expenses WHERE created_at >= ?) as personal_spending
    ''',
      [startOfMonth, startOfMonth],
    );

    final sharedSpending =
        (spendingResult.first['shared_spending'] as num?)?.toInt() ?? 0;
    final personalSpending =
        (spendingResult.first['personal_spending'] as num?)?.toInt() ?? 0;
    final monthlySpending = sharedSpending + personalSpending;

    // 2. Calculate Pending Debt Totals and Debtor Count via SQL
    final debtStatsResult = await database.rawQuery('''
      SELECT 
        COALESCE(SUM(d.total_amount), 0) as total_debt,
        COALESCE(SUM(s_total.repaid), 0) as total_repaid,
        COUNT(DISTINCT CASE WHEN d.total_amount > COALESCE(s_total.repaid, 0) THEN d.friend_id END) as debtor_count
      FROM debts d
      LEFT JOIN (
        SELECT debt_id, SUM(amount) as repaid 
        FROM settlements 
        GROUP BY debt_id
      ) s_total ON s_total.debt_id = d.id
      WHERE d.total_amount > COALESCE(s_total.repaid, 0)
    ''');

    final totalDebt =
        (debtStatsResult.first['total_debt'] as num?)?.toInt() ?? 0;
    final totalRepaid =
        (debtStatsResult.first['total_repaid'] as num?)?.toInt() ?? 0;
    final totalPending = totalDebt - totalRepaid;
    final debtorCount =
        (debtStatsResult.first['debtor_count'] as num?)?.toInt() ?? 0;

    // 3. Get Top 5 Pending Debts
    final pendingDebtRows = await database.rawQuery('''
      SELECT
        friends.name AS friend_name,
        debts.note AS note,
        debts.total_amount AS total_amount,
        debts.created_at AS created_at,
        COALESCE(s_total.repaid, 0) AS repaid_amount
      FROM debts
      INNER JOIN friends ON friends.id = debts.friend_id
      LEFT JOIN (
        SELECT debt_id, SUM(amount) as repaid 
        FROM settlements 
        GROUP BY debt_id
      ) s_total ON s_total.debt_id = debts.id
      WHERE debts.total_amount > COALESCE(s_total.repaid, 0)
      ORDER BY datetime(debts.created_at) DESC
      LIMIT 5
    ''');

    final pendingDebts = pendingDebtRows
        .map(
          (row) => PendingDebtItem(
            friendName: row['friend_name'] as String,
            note: row['note'] as String,
            totalAmount: (row['total_amount'] as num?)?.toInt() ?? 0,
            repaidAmount: (row['repaid_amount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();

    // 4. Calculate Cash Balance and Emergency Reserve
    final cashResult = await database.rawQuery('''
      SELECT SUM(CASE WHEN type = 'IN' THEN amount ELSE -amount END) as balance
      FROM cash_transactions
    ''');
    final cashBalance = (cashResult.first['balance'] as num?)?.toInt() ?? 0;

    final reserveRows = await database.query(
      'wallet_settings',
      where: 'id = 1',
    );
    final emergencyReserve =
        (reserveRows.isNotEmpty
                ? reserveRows.first['emergency_reserve'] as num?
                : null)
            ?.toInt() ??
        0;

    // 5. Calculate Overdue Count
    final overdueCount = pendingDebts.where((debt) => debt.isOverdue).length;

    // 6. Recent Activities
    final activityRows = await database.rawQuery('''
      SELECT * FROM (
        SELECT 
          friends.name || ' owes ' || CAST(debts.total_amount AS INTEGER) as title,
          debts.note as subtitle,
          debts.total_amount as amount,
          debts.created_at as created_at,
          0 as is_settlement,
          0 as is_personal
        FROM debts
        JOIN friends ON friends.id = debts.friend_id
        
        UNION ALL
        
        SELECT 
          friends.name || ' made a repayment' as title,
          settlements.note as subtitle,
          settlements.amount as amount,
          settlements.created_at as created_at,
          1 as is_settlement,
          0 as is_personal
        FROM settlements
        JOIN debts ON debts.id = settlements.debt_id
        JOIN friends ON friends.id = debts.friend_id
        
        UNION ALL
        
        SELECT 
          'Personal: ' || category as title,
          description as subtitle,
          amount as amount,
          created_at as created_at,
          0 as is_settlement,
          1 as is_personal
        FROM personal_expenses
      )
      ORDER BY datetime(created_at) DESC
      LIMIT 5
    ''');

    final recentActivities = activityRows
        .map(
          (row) => DashboardActivity(
            title: row['title'] as String,
            subtitle: row['subtitle'] as String,
            amount: (row['amount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String),
            isSettlement: row['is_settlement'] == 1,
            isPersonal: row['is_personal'] == 1,
          ),
        )
        .toList();

    return DashboardOverview(
      totalPending: totalPending.toInt(),
      totalDebt: totalDebt.toInt(),
      totalRepaid: totalRepaid.toInt(),
      debtorCount: debtorCount.toInt(),
      monthlySpending: monthlySpending.toInt(),
      sharedSpending: sharedSpending.toInt(),
      personalSpending: personalSpending.toInt(),
      overdueCount: overdueCount.toInt(),
      pendingDebts: pendingDebts,
      recentActivities: recentActivities,
      cashBalance: cashBalance.toInt(),
      emergencyReserve: emergencyReserve.toInt(),
    );
  }
}
