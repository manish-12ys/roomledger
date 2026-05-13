import '../../../core/database/roomledger_database.dart';
import '../domain/cash_models.dart';

class CashRepository {
  CashRepository(this._db);

  final RoomLedgerDatabase _db;

  Future<int> getEmergencyReserve() async {
    final database = await _db.database;
    final results = await database.query('wallet_settings', where: 'id = 1');
    if (results.isEmpty) return 0;
    return results.first['emergency_reserve'] as int;
  }

  Future<void> updateEmergencyReserve(int amount) async {
    final database = await _db.database;
    await database.update(
      'wallet_settings',
      {'emergency_reserve': amount},
      where: 'id = 1',
    );
  }

  Future<List<CashTransaction>> getCashTransactions() async {
    final database = await _db.database;
    final results = await database.query(
      'cash_transactions',
      orderBy: 'created_at DESC',
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
    await database.delete('cash_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<CashOverview> getCashOverview() async {
    final reserve = await getEmergencyReserve();
    final transactions = await getCashTransactions();

    int balance = 0;
    int monthlyUsage = 0;
    final now = DateTime.now();

    for (final tx in transactions) {
      if (tx.type == 'IN') {
        balance += tx.amount;
      } else if (tx.type == 'OUT') {
        balance -= tx.amount;
        if (tx.createdAt.year == now.year && tx.createdAt.month == now.month) {
          monthlyUsage += tx.amount;
        }
      }
    }

    return CashOverview(
      currentBalance: balance,
      emergencyReserve: reserve,
      monthlyUsage: monthlyUsage,
      transactions: transactions,
    );
  }
}
