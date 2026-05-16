import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/roomledger_database.dart';
import 'data/backup_restore_repository.dart';
import 'domain/backup_models.dart';

final backupRestoreDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

final backupRestoreRepositoryProvider = Provider<BackupRestoreRepository>((
  ref,
) {
  return BackupRestoreRepository(
    database: ref.watch(backupRestoreDatabaseProvider),
  );
});

final backupSnapshotsProvider = FutureProvider<List<BackupSnapshot>>((ref) {
  return ref.watch(backupRestoreRepositoryProvider).listBackups();
});
