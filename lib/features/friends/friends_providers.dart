import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/friends_repository.dart';
import 'domain/friends_models.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final database = ref.watch(roomLedgerDatabaseProvider);
  return FriendsRepository(database: database);
});

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  ref.watch(appDataVersionProvider);
  final repository = ref.watch(friendsRepositoryProvider);
  return repository.getFriends();
});

final friendsSummaryProvider = FutureProvider<List<FriendSummary>>((ref) async {
  ref.watch(appDataVersionProvider);
  final repository = ref.watch(friendsRepositoryProvider);
  return repository.getFriendsSummary();
});
