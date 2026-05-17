import '../../../core/database/roomledger_database.dart';
import '../domain/expense_models.dart';

class ExpensesRepository {
  ExpensesRepository(this._database);

  final RoomLedgerDatabase _database;

  Future<List<FriendOption>> loadFriends() async {
    final database = await _database.database;
    final rows = await database.query(
      'friends',
      columns: ['id', 'name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map(
          (row) =>
              FriendOption(id: row['id'] as int, name: row['name'] as String),
        )
        .toList();
  }

  Future<List<ExpenseListItem>> loadExpenses({
    int limit = 50,
    int offset = 0,
  }) async {
    final database = await _database.database;
    final rows = await database.rawQuery(
      '''
      SELECT
        debts.id AS debt_id,
        debts.friend_id AS friend_id,
        friends.name AS friend_name,
        debts.note AS note,
        debts.category AS category,
        debts.total_amount AS total_amount,
        debts.created_at AS created_at,
        COALESCE(SUM(settlements.amount), 0) AS repaid_amount
      FROM debts
      INNER JOIN friends ON friends.id = debts.friend_id
      LEFT JOIN settlements ON settlements.debt_id = debts.id
      GROUP BY debts.id
      ORDER BY datetime(debts.created_at) DESC
      LIMIT ? OFFSET ?
    ''',
      [limit, offset],
    );

    return rows
        .map(
          (row) => ExpenseListItem(
            id: row['debt_id'] as int,
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

  Future<void> addExpense(AddExpenseInput input) async {
    final database = await _database.database;
    final now =
        input.date?.toIso8601String() ?? DateTime.now().toIso8601String();
    await database.insert('debts', {
      'friend_id': input.friendId,
      'note': input.note,
      'category': input.category,
      'total_amount': input.amount,
      'created_at': now,
    });
  }

  Future<void> addSplitExpense(AddSplitExpenseInput input) async {
    if (!input.isValid()) {
      throw ArgumentError('Invalid split expense: does not sum to total');
    }

    final database = await _database.database;
    final shares = input.calculateShares();
    final now =
        input.date?.toIso8601String() ?? DateTime.now().toIso8601String();

    // If splitWithSelf is true, the first share is for the user, so we skip it for DB entries.
    final startIndex = input.splitWithSelf ? 1 : 0;

    for (int i = 0; i < input.participantIds.length; i++) {
      // The share for participantIds[i] is at shares[startIndex + i]
      await database.insert('debts', {
        'friend_id': input.participantIds[i],
        'note': input.note,
        'category': input.category,
        'total_amount': shares[startIndex + i],
        'created_at': now,
      });
    }
  }

  Future<void> addCustomSplitExpense(AddCustomSplitExpenseInput input) async {
    if (!input.isValid()) {
      throw ArgumentError(
        'Invalid custom split expense: allocations must match total',
      );
    }

    final database = await _database.database;
    final now =
        input.date?.toIso8601String() ?? DateTime.now().toIso8601String();

    await database.transaction((txn) async {
      for (final allocation in input.allocations) {
        await txn.insert('debts', {
          'friend_id': allocation.friendId,
          'note': input.note,
          'category': input.category,
          'total_amount': allocation.amount,
          'created_at': now,
        });
      }
    });
  }

  Future<void> addPercentageSplitExpense(
    AddPercentageSplitExpenseInput input,
  ) async {
    if (!input.isValid()) {
      throw ArgumentError(
        'Invalid percentage split expense: percentages must total 100',
      );
    }

    final database = await _database.database;
    final shares = input.calculateShares();
    final now =
        input.date?.toIso8601String() ?? DateTime.now().toIso8601String();

    await database.transaction((txn) async {
      for (var i = 0; i < input.allocations.length; i++) {
        await txn.insert('debts', {
          'friend_id': input.allocations[i].friendId,
          'note': input.note,
          'category': input.category,
          'total_amount': shares[i],
          'created_at': now,
        });
      }
    });
  }

  Future<void> addQuantitySplitExpense(
    AddQuantitySplitExpenseInput input,
  ) async {
    if (!input.isValid()) {
      throw ArgumentError(
        'Invalid quantity split expense: quantities must be positive',
      );
    }

    final database = await _database.database;
    final shares = input.calculateShares();
    final now =
        input.date?.toIso8601String() ?? DateTime.now().toIso8601String();

    await database.transaction((txn) async {
      for (var i = 0; i < input.allocations.length; i++) {
        await txn.insert('debts', {
          'friend_id': input.allocations[i].friendId,
          'note': input.note,
          'category': input.category,
          'total_amount': shares[i],
          'created_at': now,
        });
      }
    });
  }

  Future<void> updateExpense({
    required int debtId,
    required int friendId,
    required String note,
    required String category,
    required int amount,
    required DateTime date,
  }) async {
    final database = await _database.database;
    await database.update(
      'debts',
      {
        'friend_id': friendId,
        'note': note,
        'category': category,
        'total_amount': amount,
        'created_at': date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<bool> canDeleteExpense({required int debtId}) async {
    final database = await _database.database;
    final result = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total_settled FROM settlements WHERE debt_id = ?',
      [debtId],
    );
    final repaidAmount = (result.first['total_settled'] as num?)?.toInt() ?? 0;
    return repaidAmount == 0;
  }

  Future<void> deleteExpense({required int debtId}) async {
    final database = await _database.database;
    await database.transaction((txn) async {
      await txn.delete('settlements', where: 'debt_id = ?', whereArgs: [debtId]);
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
    });
  }
}
