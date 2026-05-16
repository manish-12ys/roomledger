class CategoryUtils {
  static String getIcon(String category) {
    switch (category) {
      case 'Groceries': return '🛒';
      case 'Vegetables': return '🥦';
      case 'Auto / Fuel': return '🚗';
      case 'Shopping': return '🛍️';
      case 'Bills': return '💡';
      case 'Food': return '🍔';
      case 'Entertainment': return '🎬';
      case 'Medical': return '💊';
      case 'Transport': return '🚕';
      case 'Education': return '📚';
      case 'Rent': return '🏠';
      case 'Recharge': return '📱';
      case 'Travel': return '✈️';
      case 'Utilities': return '⚡';
      default: return '🏷️';
    }
  }
}
