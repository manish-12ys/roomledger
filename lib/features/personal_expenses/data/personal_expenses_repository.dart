import 'package:roomledger/core/database/roomledger_database.dart';
import '../domain/personal_expense_models.dart';

class PersonalExpensesRepository {
  const PersonalExpensesRepository({required this.database});

  final RoomLedgerDatabase database;

  Future<void> createPersonalExpensesTable() async {
    final db = await database.database;

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personal_expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount INTEGER NOT NULL,
          category TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    } catch (e) {
      // Table might already exist
    }
  }

  Future<int> addExpense({
    required String description,
    required int amount,
    required ExpenseCategory category,
  }) async {
    final db = await database.database;

    final id = await db.insert('personal_expenses', {
      'description': description,
      'amount': amount,
      'category': category.name,
      'created_at': DateTime.now().toIso8601String(),
    });

    return id;
  }

  Future<List<PersonalExpense>> getExpenses({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database.database;

    final result = await db.query(
      'personal_expenses',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return result
        .map(
          (row) => PersonalExpense(
            id: row['id'] as int,
            description: row['description'] as String,
            amount: (row['amount'] as num?)?.toInt() ?? 0,
            category: ExpenseCategory.fromString(row['category'] as String),
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<PersonalExpenseSummary> getSummary() async {
    final db = await database.database;

    // 1. Get total spending and category breakdown via SQL
    final breakdownResult = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM personal_expenses 
      GROUP BY category
    ''');

    final categoryBreakdown = <ExpenseCategory, int>{};
    int totalSpending = 0;

    for (final row in breakdownResult) {
      final category = ExpenseCategory.fromString(row['category'] as String);
      final total = (row['total'] as num?)?.toInt() ?? 0;
      categoryBreakdown[category] = total;
      totalSpending += total;
    }

    // 2. Get only the most recent 20 expenses for the summary preview
    final recentExpenses = await getExpenses(limit: 20, offset: 0);

    return PersonalExpenseSummary(
      totalSpending: totalSpending,
      categoryBreakdown: categoryBreakdown,
      expenses: recentExpenses,
    );
  }

  Future<void> updateExpense({
    required int id,
    required String description,
    required int amount,
    required ExpenseCategory category,
  }) async {
    final db = await database.database;

    await db.update(
      'personal_expenses',
      {'description': description, 'amount': amount, 'category': category.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense({required int id}) async {
    final db = await database.database;

    await db.delete('personal_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
