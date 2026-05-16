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
        d.category,
        d.total_amount,
        COALESCE(SUM(s.amount), 0) as repaid_amount,
        d.created_at
      FROM debts d
      LEFT JOIN friends f ON d.friend_id = f.id
      LEFT JOIN settlements s ON d.id = s.debt_id
      GROUP BY d.id
      HAVING COALESCE(SUM(s.amount), 0) < d.total_amount
      ORDER BY d.created_at DESC
    ''');

    return result
        .map(
          (row) => PendingDebtRecord(
            debtId: row['debt_id'] as int,
            friendId: row['friend_id'] as int,
            friendName: row['friend_name'] as String? ?? 'Unknown',
            note: row['note'] as String? ?? '',
            category: row['category'] as String? ?? 'Others',
            totalAmount: (row['total_amount'] as num?)?.toInt() ?? 0,
            repaidAmount: (row['repaid_amount'] as num?)?.toInt() ?? 0,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : DateTime.now(),
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
    }).toList()..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
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
    final id = await db.insert('settlements', {
      'debt_id': debtId,
      'amount': amount,
      'note': note,
      'created_at': now.toIso8601String(),
    });

    // Check if fully settled
    final remaining = await getRemainingAmount(debtId);
    if (remaining <= 0) {
      // Delete everything related to this debt as requested by user
      await db.transaction((txn) async {
        await txn.delete('settlements', where: 'debt_id = ?', whereArgs: [debtId]);
        await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
      });
    }

    return id;
  }

  Future<void> settleFriendDebts({
    required int friendId,
    required int amount,
    required String note,
  }) async {
    final db = await database.database;
    final allDebts = await getPendingDebts();
    final friendDebts = allDebts.where((d) => d.friendId == friendId).toList();

    // Sort by date (oldest first) to settle logically
    friendDebts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int remainingToSettle = amount;

    await db.transaction((txn) async {
      for (final debt in friendDebts) {
        if (remainingToSettle <= 0) break;

        final debtRemaining = debt.totalAmount - debt.repaidAmount;
        final settleAmount = remainingToSettle >= debtRemaining
            ? debtRemaining
            : remainingToSettle;

        if (settleAmount > 0) {
          final now = DateTime.now();
          await txn.insert('settlements', {
            'debt_id': debt.debtId,
            'amount': settleAmount,
            'note': note,
            'created_at': now.toIso8601String(),
          });

          remainingToSettle -= settleAmount;

          // If now fully settled, delete as per user's "completly" requirement
          if (settleAmount >= debtRemaining) {
            await txn.delete('settlements',
                where: 'debt_id = ?', whereArgs: [debt.debtId]);
            await txn.delete('debts',
                where: 'id = ?', whereArgs: [debt.debtId]);
          }
        }
      }
    });
  }

  Future<int> getRemainingAmount(int debtId) async {
    final db = await database.database;

    final debtResult = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (debtResult.isEmpty) return 0;

    final totalAmount =
        (debtResult.first['total_amount'] as num?)?.toInt() ?? 0;

    final settlementsResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total_settled FROM settlements WHERE debt_id = ?',
      [debtId],
    );

    final repaidAmount =
        (settlementsResult.first['total_settled'] as num?)?.toInt() ?? 0;

    return totalAmount - repaidAmount;
  }
}
