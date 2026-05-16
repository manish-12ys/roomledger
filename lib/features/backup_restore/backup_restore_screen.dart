import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/privacy_policy_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import 'backup_restore_providers.dart';
import 'domain/backup_models.dart';
import '../../core/providers/app_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(backupSnapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(backupSnapshotsProvider);
          await ref.read(backupSnapshotsProvider.future);
        },
        child: backupsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
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
              const _BackupListEntry.sectionTitle('External Ledger Sharing'),
              const _BackupListEntry.spacer(12),
              _BackupListEntry.externalSharing(
                onShare: () => _shareDatabase(context, ref),
                onImport: () => _importDatabase(context, ref),
              ),
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
                  case _BackupEntryType.externalSharing:
                    return _ExternalSharingCard(
                      onShare: entry.onShare!,
                      onImport: entry.onImport!,
                    );
                  case _BackupEntryType.empty:
                    return const GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.space400),
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
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace the current local database with ${backup.fileName}. Existing app data will be overwritten.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.muted)),
          ),
          ActionButton(
            label: 'Restore',
            icon: Icons.restore_rounded,
            onPressed: () => Navigator.pop(dialogContext, true),
            variant: ActionButtonVariant.primary,
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

  Future<void> _shareDatabase(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(backupRestoreRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final dbPath = await repository.getDatabasePath();
      final file = XFile(dbPath);
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: 'RoomLedger Database Backup',
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Sharing failed: $error')));
    }
  }

  Future<void> _importDatabase(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(backupRestoreRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.surfaceVariant,
          title: const Text('Import External Ledger?'),
          content: const Text(
            'This will replace your current data with the selected file. This action cannot be undone unless you have a backup.',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.muted)),
            ),
            ActionButton(
              label: 'Import',
              icon: Icons.upload_file_rounded,
              onPressed: () => Navigator.pop(dialogContext, true),
              variant: ActionButtonVariant.primary,
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await repository.restoreFromPath(filePath);
      await _refreshAppState(ref);
      ref.invalidate(backupSnapshotsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('External ledger imported successfully.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $error')));
    }
  }

  Future<void> _refreshAppState(WidgetRef ref) async {
    ref.read(appDataVersionProvider.notifier).update((state) => state + 1);
  }
}

enum _BackupEntryType {
  header,
  spacer,
  sectionTitle,
  empty,
  backup,
  externalSharing,
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
    this.onShare,
    this.onImport,
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

  const _BackupListEntry.backup(BackupSnapshot backup)
      : this._(
          type: _BackupEntryType.backup,
          backup: backup,
        );

  const _BackupListEntry.externalSharing({required VoidCallback onShare, required VoidCallback onImport})
      : this._(
          type: _BackupEntryType.externalSharing,
          onShare: onShare,
          onImport: onImport,
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
  final VoidCallback? onShare;
  final VoidCallback? onImport;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onCreateBackup, required this.onRefresh});

  final VoidCallback onCreateBackup;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protect your local data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.secondary,
            ),
          ),
          const AppSpacing.vertical(AppTheme.space100),
          Text(
            'Backups are stored inside the app documents folder. Use restore to roll back to a previous copy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const AppSpacing.vertical(AppTheme.space300),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Create Backup',
                  icon: Icons.backup_outlined,
                  onPressed: onCreateBackup,
                  variant: ActionButtonVariant.primary,
                ),
              ),
              const AppSpacing.horizontal(AppTheme.space150),
              ActionButton(
                label: 'Refresh',
                icon: Icons.refresh,
                onPressed: onRefresh,
                variant: ActionButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExternalSharingCard extends StatelessWidget {
  const _ExternalSharingCard({required this.onShare, required this.onImport});

  final VoidCallback onShare;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.share_rounded, color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: 14),
              const Text(
                'External Transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const AppSpacing.vertical(AppTheme.space150),
          const Text(
            'Send your ledger to another device via WhatsApp or email. You can also import a shared file.',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
          const AppSpacing.vertical(AppTheme.space200),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Share Ledger',
                  icon: Icons.send_rounded,
                  onPressed: onShare,
                  variant: ActionButtonVariant.ghost,
                ),
              ),
              const AppSpacing.horizontal(AppTheme.space100),
              Expanded(
                child: ActionButton(
                  label: 'Import File',
                  icon: Icons.file_open_rounded,
                  onPressed: onImport,
                  variant: ActionButtonVariant.ghost,
                ),
              ),
            ],
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
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(Icons.folder_zip_outlined, color: AppTheme.secondary, size: 28),
          ),
          const AppSpacing.horizontal(AppTheme.space200),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.fileName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const AppSpacing.vertical(4),
                Text(
                  'Created ${_formatDateTime(backup.createdAt)} • ${backup.sizeLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const AppSpacing.horizontal(AppTheme.space100),
          ActionButton(
            label: 'Restore',
            icon: Icons.restore_rounded,
            onPressed: onRestore,
            variant: ActionButtonVariant.ghost,
          ),
        ],
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
      child: GlassCard(
        accentColor: AppTheme.error,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const AppSpacing.vertical(AppTheme.space150),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const AppSpacing.vertical(AppTheme.space100),
            Text(
              details,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const AppSpacing.vertical(AppTheme.space200),
            ActionButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry,
              variant: ActionButtonVariant.primary,
            ),
          ],
        ),
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
