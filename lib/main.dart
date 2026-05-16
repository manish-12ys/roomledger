import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/reminders/services/notification_service.dart';
import 'core/widgets/error_boundary.dart';

import 'app/roomledger_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
