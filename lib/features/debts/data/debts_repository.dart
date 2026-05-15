import 'package:roomledger/core/database/roomledger_database.dart';
import '../domain/debts_models.dart';
import '../domain/grouped_debt_record.dart';

class DebtsRepository {
  const DebtsRepository({required this.database});

  final RoomLedgerDatabase database;

  Future<List<PendingDebtRecord>> getPendingDebts() async {
    final db = await database.database;

    final result = await db.rawQuery('''
      SELECT 
        d.id as debt_id,
        f.id as friend_id,
        f.name as friend_name,
        d.note,
        d.total_amount,
        COALESCE(SUM(s.amount), 0) as repaid_amount,
        d.created_at
      FROM debts d
      LEFT JOIN friends f ON d.friend_id = f.id
      LEFT JOIN settlements s ON d.id = s.debt_id
      GROUP BY d.id
      ORDER BY d.created_at DESC
    ''');

    return result
        .map(
          (row) => PendingDebtRecord(
            debtId: row['debt_id'] as int,
            friendId: row['friend_id'] as int,
            friendName: row['friend_name'] as String,
            note: row['note'] as String,
            totalAmount: (row['total_amount'] as num?)?.toInt() ?? 0,
            repaidAmount: (row['repaid_amount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<List<GroupedDebtRecord>> getGroupedPendingDebts() async {
    final allDebts = await getPendingDebts();
    
    final groupedMap = <int, List<PendingDebtRecord>>{};
    final namesMap = <int, String>{};
    
    for (final debt in allDebts) {
      if (debt.isFullySettled) continue;
      
      groupedMap.putIfAbsent(debt.friendId, () => []);
      groupedMap[debt.friendId]!.add(debt);
      namesMap[debt.friendId] = debt.friendName;
    }
    
    return groupedMap.entries.map((entry) {
      return GroupedDebtRecord(
        friendId: entry.key,
        friendName: namesMap[entry.key]!,
        debts: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
  }

  Future<List<SettlementRecord>> getSettlementsForDebt(int debtId) async {
    final db = await database.database;

    final result = await db.query(
      'settlements',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          (row) => SettlementRecord(
            id: row['id'] as int,
            debtId: row['debt_id'] as int,
            amount: (row['amount'] as num?)?.toInt() ?? 0,
            note: row['note'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<int> addSettlement({
    required int debtId,
    required int amount,
    required String note,
  }) async {
    final db = await database.database;

    final now = DateTime.now();
    final id = await db.insert(
      'settlements',
      {
        'debt_id': debtId,
        'amount': amount,
        'note': note,
        'created_at': now.toIso8601String(),
      },
    );

    return id;
  }

  Future<int> getRemainingAmount(int debtId) async {
    final db = await database.database;

    final debtResult = await db.query('debts', where: 'id = ?', whereArgs: [debtId]);
    if (debtResult.isEmpty) return 0;

    final totalAmount = (debtResult.first['total_amount'] as num?)?.toInt() ?? 0;

    final settlementsResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total_settled FROM settlements WHERE debt_id = ?',
      [debtId],
    );

    final repaidAmount = (settlementsResult.first['total_settled'] as num?)?.toInt() ?? 0;

    return totalAmount - repaidAmount;
  }
}
