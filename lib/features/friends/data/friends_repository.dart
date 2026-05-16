import 'package:roomledger/core/database/roomledger_database.dart';
import '../domain/friends_models.dart';

class FriendsRepository {
  const FriendsRepository({required this.database});

  final RoomLedgerDatabase database;

  Future<List<Friend>> getFriends() async {
    final db = await database.database;

    final result = await db.query('friends', orderBy: 'created_at DESC');

    return result
        .map(
          (row) => Friend(
            id: row['id'] as int,
            name: row['name'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<List<FriendSummary>> getFriendsSummary() async {
    final db = await database.database;

    final result = await db.rawQuery('''
      SELECT 
        f.id,
        f.name,
        f.created_at,
        COALESCE(SUM(d.total_amount), 0) as total_debt,
        COALESCE(SUM(s_total.repaid), 0) as repaid_amount
      FROM friends f
      LEFT JOIN debts d ON f.id = d.friend_id
      LEFT JOIN (
        SELECT debt_id, SUM(amount) as repaid 
        FROM settlements 
        GROUP BY debt_id
      ) s_total ON d.id = s_total.debt_id
      GROUP BY f.id
      ORDER BY f.created_at DESC
    ''');

    return result
        .map(
          (row) => FriendSummary(
            id: row['id'] as int,
            name: row['name'] as String,
            totalDebt: row['total_debt'] as int,
            repaidAmount: row['repaid_amount'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<int> addFriend({required String name}) async {
    final db = await database.database;

    final now = DateTime.now();
    final id = await db.insert('friends', {
      'name': name,
      'created_at': now.toIso8601String(),
    });

    return id;
  }

  Future<void> updateFriend({required int id, required String name}) async {
    final db = await database.database;

    await db.update(
      'friends',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> canDeleteFriend({required int friendId}) async {
    final db = await database.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM debts WHERE friend_id = ? AND id IN (SELECT DISTINCT debt_id FROM debts d LEFT JOIN settlements s ON d.id = s.debt_id WHERE d.friend_id = ? GROUP BY d.id HAVING COALESCE(SUM(s.amount), 0) < d.total_amount)',
      [friendId, friendId],
    );

    final count = (result.first['count'] as int?) ?? 0;
    return count == 0;
  }

  Future<void> deleteFriend({required int friendId}) async {
    final db = await database.database;

    await db.delete('friends', where: 'id = ?', whereArgs: [friendId]);
  }
}
