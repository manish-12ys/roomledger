class PendingDebtRecord {
  const PendingDebtRecord({
    required this.debtId,
    required this.friendId,
    required this.friendName,
    required this.note,
    required this.totalAmount,
    required this.repaidAmount,
    required this.createdAt,
  });

  final int debtId;
  final int friendId;
  final String friendName;
  final String note;
  final int totalAmount;
  final int repaidAmount;
  final DateTime createdAt;

  int get remainingAmount => totalAmount - repaidAmount;

  bool get isFullySettled => remainingAmount == 0;

  bool get isOverdue =>
      remainingAmount > 0 && DateTime.now().difference(createdAt).inDays > 7;
}

class SettlementRecord {
  const SettlementRecord({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int debtId;
  final int amount;
  final String note;
  final DateTime createdAt;
}
