class CashTransaction {
  const CashTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String type; // 'IN' or 'OUT'
  final int amount;
  final String note;
  final DateTime createdAt;

  factory CashTransaction.fromMap(Map<String, dynamic> map) {
    return CashTransaction(
      id: map['id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      note: map['note'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'type': type,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CashOverview {
  const CashOverview({
    required this.currentBalance,
    required this.emergencyReserve,
    required this.monthlyUsage,
    required this.transactions,
  });

  final int currentBalance;
  final int emergencyReserve;
  final int monthlyUsage;
  final List<CashTransaction> transactions;

  bool get isLowCash => currentBalance <= emergencyReserve;
}
