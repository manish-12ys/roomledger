import 'package:flutter_test/flutter_test.dart';
import 'package:roomledger/features/friends/domain/friends_models.dart';

void main() {
  group('Friend', () {
    test('Friend stores values correctly', () {
      final friend = Friend(id: 1, name: 'Ravi', createdAt: DateTime.now());

      expect(friend.id, 1);
      expect(friend.name, 'Ravi');
    });
  });

  group('FriendSummary', () {
    test('remainingDebt calculates correctly', () {
      final summary = FriendSummary(
        id: 1,
        name: 'Ravi',
        totalDebt: 5000,
        repaidAmount: 2000,
        createdAt: DateTime.now(),
      );

      expect(summary.remainingDebt, 3000);
    });

    test('hasActiveDebt returns true when remaining > 0', () {
      final summary = FriendSummary(
        id: 1,
        name: 'Ravi',
        totalDebt: 5000,
        repaidAmount: 2000,
        createdAt: DateTime.now(),
      );

      expect(summary.hasActiveDebt, true);
    });

    test('hasActiveDebt returns false when remaining == 0', () {
      final summary = FriendSummary(
        id: 1,
        name: 'Ravi',
        totalDebt: 5000,
        repaidAmount: 5000,
        createdAt: DateTime.now(),
      );

      expect(summary.hasActiveDebt, false);
    });

    test('FriendSummary aggregates multiple debts correctly', () {
      final summary = FriendSummary(
        id: 1,
        name: 'Ravi',
        totalDebt: 10000, // Multiple expenses summed
        repaidAmount: 3500, // Multiple settlements summed
        createdAt: DateTime.now(),
      );

      expect(summary.totalDebt, 10000);
      expect(summary.repaidAmount, 3500);
      expect(summary.remainingDebt, 6500);
    });
  });
}
