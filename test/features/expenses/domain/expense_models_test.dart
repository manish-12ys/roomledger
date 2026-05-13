import 'package:flutter_test/flutter_test.dart';
import 'package:roomledger/features/expenses/domain/expense_models.dart';

void main() {
  group('AddSplitExpenseInput', () {
    test('calculateShares splits equally with no remainder', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 300,
        participantIds: [1, 2, 3],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [100, 100, 100]);
      expect(shares.fold<int>(0, (a, b) => a + b), 300);
    });

    test('calculateShares distributes remainder to first participants', () {
      final input = AddSplitExpenseInput(
        note: 'Lunch',
        totalAmount: 100,
        participantIds: [1, 2, 3],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [34, 33, 33]);
      expect(shares.fold<int>(0, (a, b) => a + b), 100);
    });

    test('calculateShares handles single participant', () {
      final input = AddSplitExpenseInput(
        note: 'Personal',
        totalAmount: 500,
        participantIds: [1],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [500]);
    });

    test('calculateShares handles two participants with remainder', () {
      final input = AddSplitExpenseInput(
        note: 'Bill',
        totalAmount: 101,
        participantIds: [1, 2],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [51, 50]);
      expect(shares.fold<int>(0, (a, b) => a + b), 101);
    });

    test('isValid returns true for valid split', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 300,
        participantIds: [1, 2, 3],
        splitWithSelf: false,
      );

      expect(input.isValid(), true);
    });

    test('isValid returns false for empty participants', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 300,
        participantIds: [],
        splitWithSelf: false,
      );

      expect(input.isValid(), false);
    });

    test('sharePerPerson calculates correct base share', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 325,
        participantIds: [1, 2, 3],
        splitWithSelf: false,
      );

      expect(input.sharePerPerson, 108);
    });

    test('remainder property returns correct value', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 325,
        participantIds: [1, 2, 3],
        splitWithSelf: false,
      );

      expect(input.remainder, 1);
    });

    test('participantCount returns correct count', () {
      final input = AddSplitExpenseInput(
        note: 'Dinner',
        totalAmount: 300,
        participantIds: [1, 2, 3, 4],
        splitWithSelf: false,
      );

      expect(input.participantCount, 4);
    });

    test('calculateShares with 4 people and ₹1000', () {
      final input = AddSplitExpenseInput(
        note: 'Rent split',
        totalAmount: 1000,
        participantIds: [1, 2, 3, 4],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [250, 250, 250, 250]);
      expect(shares.fold<int>(0, (a, b) => a + b), 1000);
    });

    test('calculateShares with 4 people and ₹1001', () {
      final input = AddSplitExpenseInput(
        note: 'Rent split',
        totalAmount: 1001,
        participantIds: [1, 2, 3, 4],
        splitWithSelf: false,
      );

      final shares = input.calculateShares();

      expect(shares, [251, 250, 250, 250]);
      expect(shares.fold<int>(0, (a, b) => a + b), 1001);
    });
  });

  group('AddExpenseInput', () {
    test('AddExpenseInput stores values correctly', () {
      final input = AddExpenseInput(
        friendId: 5,
        note: 'Groceries',
        amount: 250,
      );

      expect(input.friendId, 5);
      expect(input.note, 'Groceries');
      expect(input.amount, 250);
    });
  });

  group('AddCustomSplitExpenseInput', () {
    test('isValid returns true when allocations match total', () {
      final input = AddCustomSplitExpenseInput(
        note: 'Rent',
        totalAmount: 1000,
        allocations: const [
          SplitAllocation(friendId: 1, amount: 400),
          SplitAllocation(friendId: 2, amount: 350),
          SplitAllocation(friendId: 3, amount: 250),
        ],
      );

      expect(input.isValid(), true);
      expect(input.allocatedAmount, 1000);
      expect(input.remainder, 0);
      expect(input.participantCount, 3);
    });

    test('isValid returns false when allocations do not match total', () {
      final input = AddCustomSplitExpenseInput(
        note: 'Rent',
        totalAmount: 1000,
        allocations: const [
          SplitAllocation(friendId: 1, amount: 400),
          SplitAllocation(friendId: 2, amount: 300),
        ],
      );

      expect(input.isValid(), false);
      expect(input.remainder, 300);
    });

    test('isValid returns false for duplicate participant ids', () {
      final input = AddCustomSplitExpenseInput(
        note: 'Trip',
        totalAmount: 500,
        allocations: const [
          SplitAllocation(friendId: 1, amount: 200),
          SplitAllocation(friendId: 1, amount: 300),
        ],
      );

      expect(input.isValid(), false);
    });

    test('isValid returns false for zero or negative allocation amounts', () {
      final input = AddCustomSplitExpenseInput(
        note: 'Trip',
        totalAmount: 500,
        allocations: const [
          SplitAllocation(friendId: 1, amount: 0),
          SplitAllocation(friendId: 2, amount: 500),
        ],
      );

      expect(input.isValid(), false);
    });
  });

  group('AddPercentageSplitExpenseInput', () {
    test('isValid returns true when percentages total 100', () {
      final input = AddPercentageSplitExpenseInput(
        note: 'Trip',
        totalAmount: 1000,
        allocations: const [
          PercentageAllocation(friendId: 1, percentage: 50),
          PercentageAllocation(friendId: 2, percentage: 30),
          PercentageAllocation(friendId: 3, percentage: 20),
        ],
      );

      expect(input.isValid(), true);
      expect(input.totalPercentage, 100);
      expect(input.calculateShares(), [500, 300, 200]);
    });

    test('calculateShares distributes rounding remainder by fractional part', () {
      final input = AddPercentageSplitExpenseInput(
        note: 'Trip',
        totalAmount: 1001,
        allocations: const [
          PercentageAllocation(friendId: 1, percentage: 50),
          PercentageAllocation(friendId: 2, percentage: 30),
          PercentageAllocation(friendId: 3, percentage: 20),
        ],
      );

      expect(input.calculateShares(), [501, 300, 200]);
      expect(input.calculateShares().fold<int>(0, (a, b) => a + b), 1001);
    });

    test('isValid returns false when percentages do not total 100', () {
      final input = AddPercentageSplitExpenseInput(
        note: 'Trip',
        totalAmount: 1000,
        allocations: const [
          PercentageAllocation(friendId: 1, percentage: 40),
          PercentageAllocation(friendId: 2, percentage: 30),
        ],
      );

      expect(input.isValid(), false);
    });

    test('isValid returns false for duplicate participant ids', () {
      final input = AddPercentageSplitExpenseInput(
        note: 'Trip',
        totalAmount: 1000,
        allocations: const [
          PercentageAllocation(friendId: 1, percentage: 60),
          PercentageAllocation(friendId: 1, percentage: 40),
        ],
      );

      expect(input.isValid(), false);
    });
  });

  group('AddQuantitySplitExpenseInput', () {
    test('isValid returns true when quantities are positive', () {
      final input = AddQuantitySplitExpenseInput(
        note: 'Fuel',
        totalAmount: 900,
        allocations: const [
          QuantityAllocation(friendId: 1, quantity: 1),
          QuantityAllocation(friendId: 2, quantity: 2),
          QuantityAllocation(friendId: 3, quantity: 3),
        ],
      );

      expect(input.isValid(), true);
      expect(input.totalQuantity, 6);
      expect(input.calculateShares(), [150, 300, 450]);
    });

    test('calculateShares distributes rounding remainder by weight', () {
      final input = AddQuantitySplitExpenseInput(
        note: 'Fuel',
        totalAmount: 1000,
        allocations: const [
          QuantityAllocation(friendId: 1, quantity: 1),
          QuantityAllocation(friendId: 2, quantity: 2),
          QuantityAllocation(friendId: 3, quantity: 3),
        ],
      );

      expect(input.calculateShares(), [167, 333, 500]);
      expect(input.calculateShares().fold<int>(0, (a, b) => a + b), 1000);
    });

    test('isValid returns false when any quantity is zero', () {
      final input = AddQuantitySplitExpenseInput(
        note: 'Fuel',
        totalAmount: 900,
        allocations: const [
          QuantityAllocation(friendId: 1, quantity: 0),
          QuantityAllocation(friendId: 2, quantity: 2),
        ],
      );

      expect(input.isValid(), false);
    });

    test('isValid returns false for duplicate participant ids', () {
      final input = AddQuantitySplitExpenseInput(
        note: 'Fuel',
        totalAmount: 900,
        allocations: const [
          QuantityAllocation(friendId: 1, quantity: 1),
          QuantityAllocation(friendId: 1, quantity: 2),
        ],
      );

      expect(input.isValid(), false);
    });
  });
}
