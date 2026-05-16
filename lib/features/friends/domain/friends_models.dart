class Friend {
  const Friend({required this.id, required this.name, required this.createdAt});

  final int id;
  final String name;
  final DateTime createdAt;
}

class FriendSummary {
  const FriendSummary({
    required this.id,
    required this.name,
    required this.totalDebt,
    required this.repaidAmount,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int totalDebt;
  final int repaidAmount;
  final DateTime createdAt;

  int get remainingDebt => totalDebt - repaidAmount;

  bool get hasActiveDebt => remainingDebt > 0;
}
