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

  // Initialize global UI error boundaries (fast, no I/O)
  GlobalErrorCatch.initialize();

  // Run the app immediately — do NOT await heavy inits here.
  // WorkManager and NotificationService (which loads the full timezone
  // database via tz.initializeTimeZones) are deferred so the native
  // splash → Flutter splash transition is instant.
  runApp(
    ProviderScope(
      overrides: [],
      child: const RoomLedgerApp(),
    ),
  );

  // Kick off heavy background inits AFTER the first frame is on screen.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    Workmanager().initialize(callbackDispatcher);
    final notificationService = NotificationService();
    await notificationService.initialize();
  });
}
