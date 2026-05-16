import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Data Stays Yours',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'RoomLedger is designed with a strict offline-first, privacy-centric philosophy. '
              'We believe that your financial data is highly sensitive and belongs exclusively to you.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Data Collection & Storage',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'All data entered into RoomLedger (expenses, friend names, notes, amounts) '
              'is stored locally on your device in a SQLite database. '
              'RoomLedger does not connect to any remote servers to upload, sync, or backup this data. '
              'We do not collect any personal information, usage analytics, or telemetry.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '2. Data Security & Backups',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Because your data is strictly local, you are entirely responsible for its safety. '
              'If you lose your device or uninstall the app without creating a manual backup, your data will be permanently lost. '
              'You can create a local backup of your database via the "Backup & Restore" screen '
              'and securely transfer it to another device or cloud storage solution of your choosing.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '3. Third-Party Services',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'RoomLedger does not use any third-party SDKs for analytics, advertising, or crash reporting. '
              'There are no hidden trackers.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Effective Date: May 2026',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
