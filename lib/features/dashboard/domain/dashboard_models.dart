class DashboardOverview {
  const DashboardOverview({
    required this.totalPending,
    required this.totalDebt,
    required this.totalRepaid,
    required this.debtorCount,
    required this.monthlySpending,
    required this.sharedSpending,
    required this.personalSpending,
    required this.overdueCount,
    required this.pendingDebts,
    required this.recentActivities,
    required this.cashBalance,
    required this.emergencyReserve,
  });

  final int totalPending;
  final int totalDebt;
  final int totalRepaid;
  final int debtorCount;
  final int monthlySpending;
  final int sharedSpending;
  final int personalSpending;
  final int overdueCount;
  final List<PendingDebtItem> pendingDebts;
  final List<DashboardActivity> recentActivities;
  final int cashBalance;
  final int emergencyReserve;
}

class PendingDebtItem {
  const PendingDebtItem({
    required this.friendName,
    required this.note,
    required this.totalAmount,
    required this.repaidAmount,
    required this.createdAt,
  });

  final String friendName;
  final String note;
  final int totalAmount;
  final int repaidAmount;
  final DateTime createdAt;

  int get remainingAmount => totalAmount - repaidAmount;

  bool get isOverdue => remainingAmount > 0 && DateTime.now().difference(createdAt).inDays > 7;
}

class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.createdAt,
    required this.isSettlement,
    this.isPersonal = false,
  });

  final String title;
  final String subtitle;
  final int amount;
  final DateTime createdAt;
  final bool isSettlement;
  final bool isPersonal;
}