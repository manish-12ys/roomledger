import 'package:flutter/material.dart';

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

  static Color getColor(String category) {
    switch (category) {
      case 'Food': return const Color(0xFFFF6B6B);
      case 'Groceries': return const Color(0xFF4ADE80);
      case 'Vegetables': return const Color(0xFF84CC16);
      case 'Travel': return const Color(0xFF2DD4BF);
      case 'Transport': return const Color(0xFF2DD4BF);
      case 'Auto / Fuel': return const Color(0xFFFB923C);
      case 'Bills': return const Color(0xFFFFB800);
      case 'Entertainment': return const Color(0xFFA78BFA);
      case 'Shopping': return const Color(0xFFF472B6);
      case 'Medical': return const Color(0xFFF87171);
      case 'Education': return const Color(0xFF60A5FA);
      case 'Rent': return const Color(0xFF94A3B8);
      case 'Recharge': return const Color(0xFF38BDF8);
      case 'Utilities': return const Color(0xFFF59E0B);
      default: return const Color(0xFF94A3B8);
    }
  }
}
