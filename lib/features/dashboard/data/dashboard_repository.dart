import '../../../core/database/roomledger_database.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._database);

  final RoomLedgerDatabase _database;

  Future<DashboardOverview> loadOverview() async {
    final database = await _database.database;

    final debtRows = await database.rawQuery('''
      SELECT
        debts.id AS debt_id,
        friends.name AS friend_name,
        debts.note AS note,
        debts.total_amount AS total_amount,
        debts.created_at AS created_at,
        COALESCE(SUM(settlements.amount), 0) AS repaid_amount
      FROM debts
      INNER JOIN friends ON friends.id = debts.friend_id
      LEFT JOIN settlements ON settlements.debt_id = debts.id
      GROUP BY debts.id
      ORDER BY datetime(debts.created_at) DESC
    ''');

    final settlementRows = await database.rawQuery('''
      SELECT
        settlements.id AS settlement_id,
        friends.name AS friend_name,
        debts.note AS debt_note,
        settlements.note AS note,
        settlements.amount AS amount,
        settlements.created_at AS created_at
      FROM settlements
      INNER JOIN debts ON debts.id = settlements.debt_id
      INNER JOIN friends ON friends.id = debts.friend_id
      ORDER BY datetime(settlements.created_at) DESC
    ''');

    final personalRows = await database.rawQuery('''
      SELECT
        id,
        category,
        description,
        amount,
        created_at
      FROM personal_expenses
      ORDER BY datetime(created_at) DESC
    ''');

    final pendingDebts = debtRows
        .map(
          (row) => PendingDebtItem(
            friendName: row['friend_name'] as String,
            note: row['note'] as String,
            totalAmount: (row['total_amount'] as num?)?.toInt() ?? 0,
            repaidAmount: (row['repaid_amount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .where((debt) => debt.remainingAmount > 0)
        .toList();

    final recentActivities = <DashboardActivity>[
      ...debtRows.map(
        (row) => DashboardActivity(
          title: '${row['friend_name']} owes ${row['total_amount']}',
          subtitle: row['note'] as String,
          amount: (row['total_amount'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.parse(row['created_at'] as String),
          isSettlement: false,
        ),
      ),
      ...settlementRows.map(
        (row) => DashboardActivity(
          title: '${row['friend_name']} made a repayment',
          subtitle: '${row['note']} · ${row['debt_note']}',
          amount: (row['amount'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.parse(row['created_at'] as String),
          isSettlement: true,
        ),
      ),
      ...personalRows.map(
        (row) => DashboardActivity(
          title: 'Personal: ${row['category']}',
          subtitle: row['description'] as String,
          amount: (row['amount'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.parse(row['created_at'] as String),
          isSettlement: false,
          isPersonal: true,
        ),
      ),
    ]..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);

    int monthlySpending = 0;
    int sharedSpending = 0;
    int personalSpending = 0;

    for (final activity in recentActivities) {
      if (activity.createdAt.isBefore(startOfMonth)) {
        continue;
      }

      if (activity.isPersonal) {
        personalSpending += activity.amount;
        monthlySpending += activity.amount;
      } else if (!activity.isSettlement) {
        sharedSpending += activity.amount;
        monthlySpending += activity.amount;
      }
    }

    final totalPending = pendingDebts.fold<int>(0, (sum, debt) => sum + debt.remainingAmount);
    final overdueCount = pendingDebts.where((debt) => debt.isOverdue).length;

    // Compute total ever owed and total repaid across ALL debts (for the ring)
    final totalDebt = debtRows.fold<int>(0, (sum, row) => sum + ((row['total_amount'] as num?)?.toInt() ?? 0));
    final totalRepaid = debtRows.fold<int>(0, (sum, row) => sum + ((row['repaid_amount'] as num?)?.toInt() ?? 0));
    
    // Count unique friends with pending debts
    final uniqueFriendDebts = <String>{};
    for (final debt in pendingDebts) {
      uniqueFriendDebts.add(debt.friendName);
    }
    final debtorCount = uniqueFriendDebts.length;

    final cashRows = await database.query('cash_transactions');
    int cashBalance = 0;
    for (final row in cashRows) {
      final amount = (row['amount'] as num?)?.toInt() ?? 0;
      if (row['type'] == 'IN') {
        cashBalance += amount;
      } else {
        cashBalance -= amount;
      }
    }

    final reserveRows = await database.query('wallet_settings', where: 'id = 1');
    final emergencyReserve = (reserveRows.isNotEmpty ? reserveRows.first['emergency_reserve'] as num? : null)?.toInt() ?? 0;

    return DashboardOverview(
      totalPending: totalPending,
      totalDebt: totalDebt,
      totalRepaid: totalRepaid,
      debtorCount: debtorCount,
      monthlySpending: monthlySpending,
      sharedSpending: sharedSpending,
      personalSpending: personalSpending,
      overdueCount: overdueCount,
      pendingDebts: pendingDebts,
      recentActivities: recentActivities.take(5).toList(),
      cashBalance: cashBalance,
      emergencyReserve: emergencyReserve,
    );
  }
}