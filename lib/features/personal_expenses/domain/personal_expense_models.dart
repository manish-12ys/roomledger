enum ExpenseCategory {
  food('Food', '🍔'),
  travel('Travel', '🚕'),
  bills('Bills', '📄'),
  entertainment('Entertainment', '🎬'),
  shopping('Shopping', '🛍️'),
  utilities('Utilities', '⚡'),
  other('Other', '📌');

  const ExpenseCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

class PersonalExpense {
  const PersonalExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
  });

  final int id;
  final String description;
  final int amount;
  final ExpenseCategory category;
  final DateTime createdAt;
}

class PersonalExpenseSummary {
  const PersonalExpenseSummary({
    required this.totalSpending,
    required this.categoryBreakdown,
    required this.expenses,
  });

  final int totalSpending;
  final Map<ExpenseCategory, int> categoryBreakdown;
  final List<PersonalExpense> expenses;

  int getCategoryTotal(ExpenseCategory category) {
    return categoryBreakdown[category] ?? 0;
  }

  double getCategoryPercentage(ExpenseCategory category) {
    if (totalSpending == 0) return 0;
    return (getCategoryTotal(category) / totalSpending) * 100;
  }
}
