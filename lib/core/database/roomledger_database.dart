import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class RoomLedgerDatabase {
  Database? _database;
  String? _databasePath;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database>? _dbFuture;

  Future<Database> _initDatabase() async {
    _dbFuture ??= _doInit();
    return _dbFuture!;
  }

  Future<Database> _doInit() async {
    final databasePath = await getDatabasePath();

    final openedDatabase = await openDatabase(
      databasePath,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE wallet_settings (
              id INTEGER PRIMARY KEY,
              emergency_reserve INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE cash_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              amount INTEGER NOT NULL,
              note TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.insert('wallet_settings', {
            'id': 1,
            'emergency_reserve': 500,
          });
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE reminders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              reminder_date TEXT NOT NULL,
              type TEXT NOT NULL,
              completed INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS personal_expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              description TEXT NOT NULL,
              amount INTEGER NOT NULL,
              category TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          // Add category column to debts table
          try {
            await db.execute(
              'ALTER TABLE debts ADD COLUMN category TEXT NOT NULL DEFAULT "Others"',
            );
          } catch (e) {
            // Column might already exist
          }
        }
      },
      onOpen: (db) async {
        // Safety check to ensure category column exists in debts table
        final tableInfo = await db.rawQuery('PRAGMA table_info(debts)');
        final hasCategory = tableInfo.any((column) => column['name'] == 'category');
        if (!hasCategory) {
          await db.execute('ALTER TABLE debts ADD COLUMN category TEXT NOT NULL DEFAULT "Others"');
        }
      },
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<String> getDatabasePath() async {
    final currentPath = _databasePath;
    if (currentPath != null) {
      return currentPath;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final resolvedPath = path.join(documentsDirectory.path, 'roomledger.db');
    _databasePath = resolvedPath;
    return resolvedPath;
  }

  Future<Directory> getBackupDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final backupDirectory = Directory(
      path.join(documentsDirectory.path, 'backups'),
    );

    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }

    return backupDirectory;
  }

  Future<String> createBackupFile() async {
    final databasePath = await getDatabasePath();
    final backupDirectory = await getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = path.join(
      backupDirectory.path,
      'roomledger_backup_$timestamp.db',
    );

    await File(databasePath).copy(backupPath);
    return backupPath;
  }

  Future<void> restoreFromBackupFile(String backupPath) async {
    final databasePath = await getDatabasePath();
    final backupFile = File(backupPath);

    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist at $backupPath');
    }

    await _database?.close();
    _database = null;
    _dbFuture = null; // Clear the future so it can be re-initialized

    final databaseFile = File(databasePath);
    final rollbackPath = '$databasePath.rollback';
    final rollbackFile = File(rollbackPath);

    bool renamed = false;
    if (await databaseFile.exists()) {
      await databaseFile.rename(rollbackPath);
      renamed = true;
    }

    try {
      await backupFile.copy(databasePath);
      if (renamed && await rollbackFile.exists()) {
        await rollbackFile.delete();
      }
    } catch (e) {
      // Rollback if copy fails
      if (renamed && await rollbackFile.exists()) {
        if (await databaseFile.exists()) {
          await databaseFile.delete();
        }
        await rollbackFile.rename(databasePath);
      }
      rethrow;
    } finally {
      // Re-initialize database
      await database;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        friend_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        category TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(friend_id) REFERENCES friends(id)
      )
    ''');

    await database.execute('''
      CREATE TABLE settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(debt_id) REFERENCES debts(id)
      )
    ''');

    await database.execute('''
      CREATE TABLE wallet_settings (
        id INTEGER PRIMARY KEY,
        emergency_reserve INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        reminder_date TEXT NOT NULL,
        type TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE personal_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

  }
}
