import '../../../core/database/roomledger_database.dart';
import '../domain/reminder_models.dart';

class RemindersRepository {
  RemindersRepository(this._db);

  final RoomLedgerDatabase _db;

  Future<List<Reminder>> getReminders() async {
    final database = await _db.database;
    final results = await database.query(
      'reminders',
      orderBy: 'reminder_date ASC',
    );
    return results.map(Reminder.fromMap).toList();
  }

  Future<int> addReminder(Reminder reminder) async {
    final database = await _db.database;
    return await database.insert('reminders', reminder.toMap());
  }

  Future<void> updateReminder(Reminder reminder) async {
    final database = await _db.database;
    await database.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(int id) async {
    final database = await _db.database;
    await database.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
