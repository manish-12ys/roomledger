import 'package:flutter_test/flutter_test.dart';
import 'package:roomledger/features/debts/domain/debts_models.dart';

void main() {
  group('PendingDebtRecord', () {
    test('remainingAmount calculates correctly', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 300,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(debt.remainingAmount, 700);
    });

    test('isFullySettled returns true when remaining is 0', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 1000,
        createdAt: DateTime.now(),
      );

      expect(debt.isFullySettled, true);
    });

    test('isFullySettled returns false when remaining > 0', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 500,
        createdAt: DateTime.now(),
      );

      expect(debt.isFullySettled, false);
    });

    test('isOverdue returns true for debts > 7 days old with unpaid balance', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(debt.isOverdue, true);
    });

    test('isOverdue returns false for debts < 7 days old', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(debt.isOverdue, false);
    });

    test('isOverdue returns false if debt is fully settled', () {
      final debt = PendingDebtRecord(
        debtId: 1,
        friendId: 2,
        friendName: 'Ravi',
        note: 'Groceries',
        totalAmount: 1000,
        repaidAmount: 1000,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(debt.isOverdue, false);
    });
  });

  group('SettlementRecord', () {
    test('SettlementRecord stores values correctly', () {
      final settlement = SettlementRecord(
        id: 1,
        debtId: 2,
        amount: 500,
        note: 'Partial payment',
        createdAt: DateTime.now(),
      );

      expect(settlement.id, 1);
      expect(settlement.debtId, 2);
      expect(settlement.amount, 500);
      expect(settlement.note, 'Partial payment');
    });
  });
}
