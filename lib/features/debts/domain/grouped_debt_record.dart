import 'debts_models.dart';

class GroupedDebtRecord {
  const GroupedDebtRecord({
    required this.friendId,
    required this.friendName,
    required this.debts,
  });

  final int friendId;
  final String friendName;
  final List<PendingDebtRecord> debts;

  int get totalAmount => debts.fold(0, (sum, debt) => sum + debt.totalAmount);
  int get repaidAmount => debts.fold(0, (sum, debt) => sum + debt.repaidAmount);
  int get remainingAmount => totalAmount - repaidAmount;
  
  bool get isFullySettled => remainingAmount == 0;
  
  bool get isOverdue => debts.any((debt) => debt.isOverdue);
  
  DateTime get lastActivityAt => debts.isEmpty 
      ? DateTime.now() 
      : debts.map((d) => d.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
}
