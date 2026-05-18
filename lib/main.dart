import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'features/reminders/services/notification_service.dart';
import 'features/reminders/services/background_reminder_task.dart';
import 'core/widgets/error_boundary.dart';

import 'app/roomledger_app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await BackgroundReminderTask.execute();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(
    callbackDispatcher,
  );

  // Initialize notification service early to prevent crashes
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize global UI error boundaries
  GlobalErrorCatch.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // If we had a way to override the provider here, we would.
        // But we'll just let the provider return the same instance.
      ],
      child: const RoomLedgerApp(),
    ),
  );
}
