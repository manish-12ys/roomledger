import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_providers.dart';
import '../dashboard/dashboard_providers.dart';
import '../debts/debts_providers.dart';
import '../expenses/expenses_providers.dart';
import '../friends/friends_providers.dart';
import '../personal_expenses/personal_expenses_providers.dart';
import '../reminders/reminders_providers.dart';
import '../cash_management/cash_providers.dart';
import '../settings/privacy_policy_screen.dart';
import 'backup_restore_providers.dart';
import 'domain/backup_models.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupSnapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(backupSnapshotsProvider);
          await ref.read(backupSnapshotsProvider.future);
        },
        child: backupsAsync.when(
          loading: () => ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              _ErrorState(
                message: 'Could not load backups.',
                details: error.toString(),
                onRetry: () => ref.invalidate(backupSnapshotsProvider),
              ),
            ],
          ),
          data: (backups) {
              final entries = <_BackupListEntry>[
                _BackupListEntry.header(
                  onCreateBackup: () async {
                    await _createBackup(context, ref);
                  },
                  onRefresh: () async {
                    ref.invalidate(backupSnapshotsProvider);
                    await ref.read(backupSnapshotsProvider.future);
                  },
                ),
                const _BackupListEntry.spacer(20),
                const _BackupListEntry.recoveryDocs(),
                const _BackupListEntry.spacer(20),
                const _BackupListEntry.sectionTitle('Saved Backups'),
                const _BackupListEntry.spacer(12),
              ];

            if (backups.isEmpty) {
              entries.add(const _BackupListEntry.empty());
            } else {
              for (final backup in backups) {
                entries.add(_BackupListEntry.backup(backup));
              }
            }

            entries.add(const _BackupListEntry.spacer(24));
            entries.add(const _BackupListEntry.privacyPolicy());

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                switch (entry.type) {
                  case _BackupEntryType.header:
                    return _HeaderCard(
                      onCreateBackup: entry.onCreateBackup!,
                      onRefresh: entry.onRefresh!,
                    );
                  case _BackupEntryType.spacer:
                    return SizedBox(height: entry.spacerHeight);
                  case _BackupEntryType.sectionTitle:
                    return Text(
                      entry.title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    );
                  case _BackupEntryType.recoveryDocs:
                    return const _RecoveryDocsCard();
                  case _BackupEntryType.empty:
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No backups yet. Create one to protect your data.'),
                        ),
                      ),
                    );
                  case _BackupEntryType.backup:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BackupCard(
                        backup: entry.backup!,
                        onRestore: () async {
                          await _restoreBackup(context, ref, entry.backup!);
                        },
                      ),
                    );
                  case _BackupEntryType.privacyPolicy:
                    return Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('View Privacy Policy'),
                      ),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(backupRestoreRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repository.createBackup();
      await _refreshAppState(ref);
      ref.invalidate(backupSnapshotsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Backup created successfully.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $error')));
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref, BackupSnapshot backup) async {
    final repository = ref.read(backupRestoreRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace the current local database with ${backup.fileName}. Existing app data will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await repository.restoreBackup(backup);
      await _refreshAppState(ref);
      ref.invalidate(backupSnapshotsProvider);
      messenger.showSnackBar(SnackBar(content: Text('Restored ${backup.fileName}.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    }
  }

  Future<void> _refreshAppState(WidgetRef ref) async {
    ref.invalidate(dashboardOverviewProvider);
    ref.invalidate(expensesListProvider);
    ref.invalidate(friendOptionsProvider);
    ref.invalidate(pendingDebtsProvider);
    ref.invalidate(friendsListProvider);
    ref.invalidate(friendsSummaryProvider);
    ref.invalidate(personalExpensesSummaryProvider);
    ref.invalidate(personalExpensesListProvider);
    ref.invalidate(cashOverviewProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(analyticsReportProvider);
  }
}

enum _BackupEntryType {
  header,
  spacer,
  sectionTitle,
  empty,
  backup,
  recoveryDocs,
  privacyPolicy,
}

class _BackupListEntry {
  const _BackupListEntry._({
    required this.type,
    this.spacerHeight = 0,
    this.title,
    this.backup,
    this.onCreateBackup,
    this.onRefresh,
  });

  const _BackupListEntry.header({required VoidCallback onCreateBackup, required VoidCallback onRefresh})
      : this._(
          type: _BackupEntryType.header,
          onCreateBackup: onCreateBackup,
          onRefresh: onRefresh,
        );

  const _BackupListEntry.spacer(double spacerHeight)
      : this._(
          type: _BackupEntryType.spacer,
          spacerHeight: spacerHeight,
        );

  const _BackupListEntry.sectionTitle(String title)
      : this._(
          type: _BackupEntryType.sectionTitle,
          title: title,
        );

  const _BackupListEntry.empty()
      : this._(
          type: _BackupEntryType.empty,
        );

  const _BackupListEntry.recoveryDocs()
      : this._(
          type: _BackupEntryType.recoveryDocs,
        );

  const _BackupListEntry.backup(BackupSnapshot backup)
      : this._(
          type: _BackupEntryType.backup,
          backup: backup,
        );

  const _BackupListEntry.privacyPolicy()
      : this._(
          type: _BackupEntryType.privacyPolicy,
        );

  final _BackupEntryType type;
  final double spacerHeight;
  final String? title;
  final BackupSnapshot? backup;
  final VoidCallback? onCreateBackup;
  final VoidCallback? onRefresh;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onCreateBackup, required this.onRefresh});

  final VoidCallback onCreateBackup;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protect your local data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Backups are stored inside the app documents folder. Use restore to roll back to a previous copy of your database.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Semantics(
                  button: true,
                  label: 'Create a local backup file',
                  child: FilledButton.icon(
                    onPressed: onCreateBackup,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create Backup'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryDocsCard extends StatelessWidget {
  const _RecoveryDocsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
        title: const Text(
          'Emergency Recovery Guide',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Text(
            'RoomLedger stores all data locally on your device in a SQLite database. '
            'It does NOT sync to a remote server. You are responsible for keeping your data safe.\n\n'
            'How to recover data on a new device:\n'
            '1. Create a backup using the button above.\n'
            '2. Manually copy the `.zip` or `.json` backup file from your device\'s app documents folder '
            'to your new device.\n'
            '3. Install RoomLedger on the new device, place the file in the documents folder, and use the '
            'Restore button here.',
          ),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.backup, required this.onRestore});

  final BackupSnapshot backup;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.folder_zip_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('Created ${_formatDateTime(backup.createdAt)}'),
                  const SizedBox(height: 4),
                  Text('Size ${backup.sizeLabel}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'Restore from ${backup.fileName}',
              child: FilledButton(
                onPressed: onRestore,
                child: const Text('Restore'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.details, required this.onRetry});

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(details, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day $hour:$minute';
}
