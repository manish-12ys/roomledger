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

  Future<ReminderSettings> getReminderSettings() async {
    final database = await _db.database;
    final results = await database.query('reminder_settings', limit: 1);
    if (results.isEmpty) {
      return const ReminderSettings(
        id: 1,
        autoSendEnabled: 1,
        dispatchIntervalDays: 5,
        senderName: 'User',
      );
    }
    return ReminderSettings.fromMap(results.first);
  }

  Future<void> updateReminderSettings(ReminderSettings settings) async {
    final database = await _db.database;
    await database.update(
      'reminder_settings',
      {
        'auto_send_enabled': settings.autoSendEnabled,
        'dispatch_interval_days': settings.dispatchIntervalDays,
        'sender_name': settings.senderName,
      },
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<List<PendingDebtRecord>> getPendingDebtsGroupedByFriend() async {
    final database = await _db.database;
    final results = await database.rawQuery('''
      SELECT 
        f.name as friendName,
        f.phone_number as phoneNumber,
        COALESCE(SUM(d.total_amount), 0) - COALESCE(s_total.repaid, 0) as remainingAmount
      FROM friends f
      LEFT JOIN debts d ON f.id = d.friend_id
      LEFT JOIN (
        SELECT d2.friend_id, SUM(s.amount) as repaid 
        FROM settlements s
        JOIN debts d2 ON s.debt_id = d2.id
        GROUP BY d2.friend_id
      ) s_total ON f.id = s_total.friend_id
      GROUP BY f.id
      HAVING remainingAmount > 0
    ''');

    return results.map((row) {
      return PendingDebtRecord(
        friendName: row['friendName'] as String,
        phoneNumber: row['phoneNumber'] as String?,
        remainingAmount: (row['remainingAmount'] as num).toInt(),
      );
    }).toList();
  }
}
