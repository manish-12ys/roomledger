import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomledger/features/friends/domain/friends_models.dart';
import 'package:roomledger/features/friends/friends_providers.dart';
import 'package:roomledger/features/friends/friends_screen.dart';

void main() {
  group('FriendsScreen form', () {
    testWidgets('add roommate form validates empty name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendsSummaryProvider.overrideWith(
              (ref) async => <FriendSummary>[],
            ),
            friendsListProvider.overrideWith((ref) async => <Friend>[]),
          ],
          child: const MaterialApp(home: FriendsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Add New Roommate'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Roommate'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
    });
  });
}
