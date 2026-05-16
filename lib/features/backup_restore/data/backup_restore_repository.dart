import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../core/database/roomledger_database.dart';
import '../domain/backup_models.dart';

class BackupRestoreRepository {
  const BackupRestoreRepository({required this.database});

  final RoomLedgerDatabase database;

  Future<List<BackupSnapshot>> listBackups() async {
    final backupDirectory = await database.getBackupDirectory();
    if (!await backupDirectory.exists()) {
      return [];
    }

    final backups = <BackupSnapshot>[];
    await for (final entity in backupDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.db')) {
        continue;
      }

      final stat = await entity.stat();
      backups.add(
        BackupSnapshot(
          path: entity.path,
          fileName: path.basename(entity.path),
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }

    backups.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return backups;
  }

  Future<BackupSnapshot> createBackup() async {
    final backupPath = await database.createBackupFile();
    final file = File(backupPath);
    final stat = await file.stat();

    return BackupSnapshot(
      path: backupPath,
      fileName: path.basename(backupPath),
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<void> restoreBackup(BackupSnapshot backup) async {
    await database.restoreFromBackupFile(backup.path);
  }

  Future<String> getDatabasePath() async {
    return await database.getDatabasePath();
  }

  Future<void> restoreFromPath(String filePath) async {
    await database.restoreFromBackupFile(filePath);
  }
}
