import '../../../core/database/roomledger_database.dart';
import '../domain/cash_models.dart';

class CashRepository {
  CashRepository(this._db);

  final RoomLedgerDatabase _db;

  Future<int> getEmergencyReserve() async {
    final database = await _db.database;
    final results = await database.query('wallet_settings', where: 'id = 1');
    if (results.isEmpty) return 0;
    return (results.first['emergency_reserve'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateEmergencyReserve(int amount) async {
    final database = await _db.database;
    await database.update('wallet_settings', {
      'emergency_reserve': amount,
    }, where: 'id = 1');
  }

  Future<List<CashTransaction>> getCashTransactions({
    int? limit,
    int? offset,
  }) async {
    final database = await _db.database;
    final results = await database.query(
      'cash_transactions',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map(CashTransaction.fromMap).toList();
  }

  Future<void> addTransaction(String type, int amount, String note) async {
    final database = await _db.database;
    final tx = CashTransaction(
      id: 0,
      type: type,
      amount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    await database.insert('cash_transactions', tx.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final database = await _db.database;
    await database.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CashOverview> getCashOverview() async {
    final database = await _db.database;
    final reserve = await getEmergencyReserve();

    // 1. Calculate balance via SQL
    final balanceResult = await database.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'IN' THEN amount ELSE -amount END) as balance
      FROM cash_transactions
    ''');
    final balance = (balanceResult.first['balance'] as num?)?.toInt() ?? 0;

    // 2. Calculate monthly usage via SQL
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final usageResult = await database.rawQuery(
      '''
      SELECT SUM(amount) as usage
      FROM cash_transactions
      WHERE type = 'OUT' AND created_at >= ?
    ''',
      [firstDayOfMonth],
    );
    final monthlyUsage = (usageResult.first['usage'] as num?)?.toInt() ?? 0;

    // 3. Get recent 20 transactions for preview
    final recentTransactions = await getCashTransactions(limit: 20);

    return CashOverview(
      currentBalance: balance,
      emergencyReserve: reserve,
      monthlyUsage: monthlyUsage,
      transactions: recentTransactions,
    );
  }
}
