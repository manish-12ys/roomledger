// Domain models for analytics
import 'package:flutter/foundation.dart';

/// Represents a single data point for spending trend
class SpendingTrendPoint {
  final DateTime month;
  final double amount;
  final double sharedAmount;
  final double personalAmount;

  SpendingTrendPoint({
    required this.month,
    required this.amount,
    required this.sharedAmount,
    required this.personalAmount,
  });

  SpendingTrendPoint copyWith({
    DateTime? month,
    double? amount,
    double? sharedAmount,
    double? personalAmount,
  }) {
    return SpendingTrendPoint(
      month: month ?? this.month,
      amount: amount ?? this.amount,
      sharedAmount: sharedAmount ?? this.sharedAmount,
      personalAmount: personalAmount ?? this.personalAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingTrendPoint &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          amount == other.amount &&
          sharedAmount == other.sharedAmount &&
          personalAmount == other.personalAmount;

  @override
  int get hashCode =>
      month.hashCode ^ amount.hashCode ^ sharedAmount.hashCode ^ personalAmount.hashCode;
}

/// Represents spending breakdown data
class SpendingBreakdown {
  final double sharedTotal;
  final double personalTotal;
  final double totalSpending;

  SpendingBreakdown({
    required this.sharedTotal,
    required this.personalTotal,
  }) : totalSpending = sharedTotal + personalTotal;

  double get sharedPercentage => totalSpending > 0 ? (sharedTotal / totalSpending) * 100 : 0;
  double get personalPercentage => totalSpending > 0 ? (personalTotal / totalSpending) * 100 : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingBreakdown &&
          runtimeType == other.runtimeType &&
          sharedTotal == other.sharedTotal &&
          personalTotal == other.personalTotal;

  @override
  int get hashCode => sharedTotal.hashCode ^ personalTotal.hashCode;
}

/// Represents category spending data
class CategorySpending {
  final String category;
  final double amount;
  final int count; // number of expenses

  CategorySpending({
    required this.category,
    required this.amount,
    required this.count,
  });

  CategorySpending copyWith({
    String? category,
    double? amount,
    int? count,
  }) {
    return CategorySpending(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorySpending &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          amount == other.amount &&
          count == other.count;

  @override
  int get hashCode => category.hashCode ^ amount.hashCode ^ count.hashCode;
}

/// Represents friend debt comparison data
class FriendDebtComparison {
  final String friendName;
  final String friendId;
  final double totalDebt;
  final double totalSettled;
  final double pendingAmount;

  FriendDebtComparison({
    required this.friendName,
    required this.friendId,
    required this.totalDebt,
    required this.totalSettled,
    required this.pendingAmount,
  });

  FriendDebtComparison copyWith({
    String? friendName,
    String? friendId,
    double? totalDebt,
    double? totalSettled,
    double? pendingAmount,
  }) {
    return FriendDebtComparison(
      friendName: friendName ?? this.friendName,
      friendId: friendId ?? this.friendId,
      totalDebt: totalDebt ?? this.totalDebt,
      totalSettled: totalSettled ?? this.totalSettled,
      pendingAmount: pendingAmount ?? this.pendingAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendDebtComparison &&
          runtimeType == other.runtimeType &&
          friendName == other.friendName &&
          friendId == other.friendId &&
          totalDebt == other.totalDebt &&
          totalSettled == other.totalSettled &&
          pendingAmount == other.pendingAmount;

  @override
  int get hashCode =>
      friendName.hashCode ^
      friendId.hashCode ^
      totalDebt.hashCode ^
      totalSettled.hashCode ^
      pendingAmount.hashCode;
}

/// Represents complete analytics data for a date range
class AnalyticsReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<SpendingTrendPoint> spendingTrend;
  final SpendingBreakdown breakdown;
  final List<CategorySpending> categoryBreakdown;
  final List<FriendDebtComparison> friendDebtComparison;

  AnalyticsReport({
    required this.startDate,
    required this.endDate,
    required this.spendingTrend,
    required this.breakdown,
    required this.categoryBreakdown,
    required this.friendDebtComparison,
  });

  AnalyticsReport copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<SpendingTrendPoint>? spendingTrend,
    SpendingBreakdown? breakdown,
    List<CategorySpending>? categoryBreakdown,
    List<FriendDebtComparison>? friendDebtComparison,
  }) {
    return AnalyticsReport(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spendingTrend: spendingTrend ?? this.spendingTrend,
      breakdown: breakdown ?? this.breakdown,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      friendDebtComparison: friendDebtComparison ?? this.friendDebtComparison,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsReport &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          listEquals(spendingTrend, other.spendingTrend) &&
          breakdown == other.breakdown &&
          listEquals(categoryBreakdown, other.categoryBreakdown) &&
          listEquals(friendDebtComparison, other.friendDebtComparison);

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      spendingTrend.hashCode ^
      breakdown.hashCode ^
      categoryBreakdown.hashCode ^
      friendDebtComparison.hashCode;
}
