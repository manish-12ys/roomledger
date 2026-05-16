import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/roomledger_database.dart';

final roomLedgerDatabaseProvider = Provider<RoomLedgerDatabase>((ref) {
  return RoomLedgerDatabase();
});

/// A provider that tracks the version of the app data.
/// Incrementing this will trigger a refresh of all providers that watch it.
final appDataVersionProvider = StateProvider<int>((ref) => 0);
