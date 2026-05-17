class FriendOption {
  const FriendOption({required this.id, required this.name});

  final int id;
  final String name;
}

class ExpenseListItem {
  const ExpenseListItem({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.note,
    required this.category,
    required this.totalAmount,
    required this.repaidAmount,
    required this.createdAt,
  });

  final int id;
  final int friendId;
  final String friendName;
  final String note;
  final String category;
  final int totalAmount;
  final int repaidAmount;
  final DateTime createdAt;

  int get remainingAmount => totalAmount - repaidAmount;
}

class AddExpenseInput {
  const AddExpenseInput({
    required this.friendId,
    required this.note,
    required this.category,
    required this.amount,
    this.date,
  });

  final int friendId;
  final String note;
  final String category;
  final int amount;
  final DateTime? date;
}

class AddSplitExpenseInput {
  const AddSplitExpenseInput({
    required this.note,
    required this.category,
    required this.totalAmount,
    required this.participantIds,
    this.splitWithSelf = true,
    this.date,
  });

  final String note;
  final String category;
  final int totalAmount;
  final List<int> participantIds;
  final bool splitWithSelf;
  final DateTime? date;

  int get participantCount => participantIds.length + (splitWithSelf ? 1 : 0);

  int get sharePerPerson => participantCount > 0 ? totalAmount ~/ participantCount : 0;

  List<int> calculateShares() {
    if (participantCount == 0) return [];
    
    final share = totalAmount ~/ participantCount;
    final remainder = totalAmount % participantCount;
    
    final shares = <int>[];
    for (int i = 0; i < participantCount; i++) {
      shares.add(share + (i < remainder ? 1 : 0));
    }
    return shares;
  }

  bool isValid() {
    if (participantCount == 0) return false;
    final shares = calculateShares();
    final sum = shares.fold<int>(0, (a, b) => a + b);
    return sum == totalAmount;
  }
}

class SplitAllocation {
  const SplitAllocation({required this.friendId, required this.amount});

  final int friendId;
  final int amount;
}

class AddCustomSplitExpenseInput {
  const AddCustomSplitExpenseInput({
    required this.note,
    required this.category,
    required this.totalAmount,
    required this.allocations,
    this.date,
  });

  final String note;
  final String category;
  final int totalAmount;
  final List<SplitAllocation> allocations;
  final DateTime? date;

  int get participantCount => allocations.length;

  int get allocatedAmount =>
      allocations.fold<int>(0, (sum, allocation) => sum + allocation.amount);

  bool isValid() {
    if (participantCount == 0) {
      return false;
    }

    final seenIds = <int>{};
    for (final allocation in allocations) {
      if (allocation.amount <= 0) {
        return false;
      }
      if (!seenIds.add(allocation.friendId)) {
        return false;
      }
    }

    return allocatedAmount == totalAmount;
  }
}

class PercentageAllocation {
  const PercentageAllocation({
    required this.friendId,
    required this.percentage,
  });

  final int friendId;
  final int percentage;
}

class AddPercentageSplitExpenseInput {
  const AddPercentageSplitExpenseInput({
    required this.note,
    required this.category,
    required this.totalAmount,
    required this.allocations,
    this.date,
  });

  final String note;
  final String category;
  final int totalAmount;
  final List<PercentageAllocation> allocations;
  final DateTime? date;

  int get participantCount => allocations.length;

  int get totalPercentage => allocations.fold<int>(
    0,
    (sum, allocation) => sum + allocation.percentage,
  );

  bool isValid() {
    if (participantCount == 0) {
      return false;
    }

    final seenIds = <int>{};
    for (final allocation in allocations) {
      if (allocation.percentage <= 0) {
        return false;
      }
      if (!seenIds.add(allocation.friendId)) {
        return false;
      }
    }

    return totalPercentage == 100;
  }

  List<int> calculateShares() {
    final rawShares = <_WeightedShare>[];
    var totalAllocated = 0;

    for (var index = 0; index < allocations.length; index++) {
      final allocation = allocations[index];
      final exactShare = totalAmount * allocation.percentage / 100.0;
      final share = exactShare.floor();
      totalAllocated += share;
      rawShares.add(
        _WeightedShare(
          index: index,
          amount: share,
          fractionalPart: exactShare - share,
        ),
      );
    }

    var remainder = totalAmount - totalAllocated;
    // Distribute remainder based on fractional parts (highest first)
    rawShares.sort((a, b) {
      final comparison = b.fractionalPart.compareTo(a.fractionalPart);
      if (comparison != 0) return comparison;
      return a.index.compareTo(b.index);
    });

    for (var i = 0; i < remainder; i++) {
      rawShares[i].amount += 1;
    }

    rawShares.sort((a, b) => a.index.compareTo(b.index));
    return rawShares.map((share) => share.amount).toList();
  }
}

class QuantityAllocation {
  const QuantityAllocation({required this.friendId, required this.quantity});

  final int friendId;
  final int quantity;
}

class AddQuantitySplitExpenseInput {
  const AddQuantitySplitExpenseInput({
    required this.note,
    required this.category,
    required this.totalAmount,
    required this.allocations,
    this.date,
  });

  final String note;
  final String category;
  final int totalAmount;
  final List<QuantityAllocation> allocations;
  final DateTime? date;

  int get participantCount => allocations.length;

  int get totalQuantity =>
      allocations.fold<int>(0, (sum, allocation) => sum + allocation.quantity);

  bool isValid() {
    if (participantCount == 0) {
      return false;
    }

    final seenIds = <int>{};
    for (final allocation in allocations) {
      if (allocation.quantity <= 0) {
        return false;
      }
      if (!seenIds.add(allocation.friendId)) {
        return false;
      }
    }

    return totalQuantity > 0;
  }

  List<int> calculateShares() {
    final rawShares = <_WeightedShare>[];
    var totalAllocated = 0;

    for (var index = 0; index < allocations.length; index++) {
      final allocation = allocations[index];
      final exactShare = totalAmount * allocation.quantity / totalQuantity;
      final share = exactShare.floor();
      totalAllocated += share;
      rawShares.add(
        _WeightedShare(
          index: index,
          amount: share,
          fractionalPart: exactShare - share,
        ),
      );
    }

    var remainder = totalAmount - totalAllocated;
    rawShares.sort((a, b) {
      final comparison = b.fractionalPart.compareTo(a.fractionalPart);
      if (comparison != 0) return comparison;
      return a.index.compareTo(b.index);
    });

    for (var i = 0; i < remainder; i++) {
      rawShares[i].amount += 1;
    }

    rawShares.sort((a, b) => a.index.compareTo(b.index));
    return rawShares.map((share) => share.amount).toList();
  }
}

class _WeightedShare {
  _WeightedShare({
    required this.index,
    required this.amount,
    required this.fractionalPart,
  });

  final int index;
  int amount;
  final double fractionalPart;
}
