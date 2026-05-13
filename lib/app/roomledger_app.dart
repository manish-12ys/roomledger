import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/dashboard_shell.dart';

class RoomLedgerApp extends StatelessWidget {
  const RoomLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoomLedger',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark(),
      home: const DashboardShell(),
    );
  }
}