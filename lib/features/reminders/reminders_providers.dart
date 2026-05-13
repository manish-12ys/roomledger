import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/roomledger_database.dart';
import 'data/reminders_repository.dart';
import 'domain/reminder_models.dart';
import 'services/notification_service.dart';

final remindersDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.watch(remindersDatabaseProvider));
});

final remindersProvider = FutureProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).getReminders();
});

class RemindersController extends StateNotifier<AsyncValue<void>> {
  RemindersController(this._repo, this._notifService, this._ref) : super(const AsyncData(null));

  final RemindersRepository _repo;
  final NotificationService _notifService;
  final Ref _ref;

  Future<void> addReminder(String title, DateTime date, String type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _notifService.requestPermissions();
      
      final newReminder = Reminder(
        id: 0,
        title: title,
        reminderDate: date,
        type: type,
        completed: false,
      );
      
      final id = await _repo.addReminder(newReminder);
      
      await _notifService.scheduleReminder(
        id: id,
        title: 'RoomLedger Reminder',
        body: title,
        scheduledDate: date,
      );
      
      _ref.invalidate(remindersProvider);
    });
  }

  Future<void> toggleReminder(Reminder reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = reminder.copyWith(completed: !reminder.completed);
      await _repo.updateReminder(updated);
      
      if (updated.completed) {
        await _notifService.cancelReminder(reminder.id);
      } else {
        if (updated.reminderDate.isAfter(DateTime.now())) {
          await _notifService.scheduleReminder(
            id: updated.id,
            title: 'RoomLedger Reminder',
            body: updated.title,
            scheduledDate: updated.reminderDate,
          );
        }
      }
      
      _ref.invalidate(remindersProvider);
    });
  }

  Future<void> deleteReminder(Reminder reminder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.deleteReminder(reminder.id);
      await _notifService.cancelReminder(reminder.id);
      _ref.invalidate(remindersProvider);
    });
  }
}

final remindersControllerProvider = StateNotifierProvider<RemindersController, AsyncValue<void>>((ref) {
  return RemindersController(
    ref.watch(remindersRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref,
  );
});
