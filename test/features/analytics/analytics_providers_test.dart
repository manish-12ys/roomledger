import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomledger/features/analytics/analytics_providers.dart';

void main() {
  group('dateRangeProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to current month', () {
      final now = DateTime.now();
      final range = container.read(dateRangeProvider);

      expect(range.startDate.year, now.year);
      expect(range.startDate.month, now.month);
      expect(range.startDate.day, 1);

      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      expect(range.endDate.year, expectedEnd.year);
      expect(range.endDate.month, expectedEnd.month);
      expect(range.endDate.day, expectedEnd.day);
    });

    test('setLastThreeMonths updates range correctly', () {
      container.read(dateRangeProvider.notifier).setLastThreeMonths();
      final range = container.read(dateRangeProvider);

      final now = DateTime.now();
      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      final expectedStart = DateTime(
        expectedEnd.year,
        expectedEnd.month - 2,
        1,
      );

      expect(range.startDate.year, expectedStart.year);
      expect(range.startDate.month, expectedStart.month);
      expect(range.startDate.day, 1);

      expect(range.endDate.year, expectedEnd.year);
      expect(range.endDate.month, expectedEnd.month);
      expect(range.endDate.day, expectedEnd.day);
    });

    test('setLastSixMonths updates range correctly', () {
      container.read(dateRangeProvider.notifier).setLastSixMonths();
      final range = container.read(dateRangeProvider);

      final now = DateTime.now();
      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      final expectedStart = DateTime(
        expectedEnd.year,
        expectedEnd.month - 5,
        1,
      );

      expect(range.startDate.year, expectedStart.year);
      expect(range.startDate.month, expectedStart.month);
      expect(range.startDate.day, 1);

      expect(range.endDate.year, expectedEnd.year);
      expect(range.endDate.month, expectedEnd.month);
      expect(range.endDate.day, expectedEnd.day);
    });

    test('setLastYear updates range correctly', () {
      container.read(dateRangeProvider.notifier).setLastYear();
      final range = container.read(dateRangeProvider);

      final now = DateTime.now();
      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      final expectedStart = DateTime(
        expectedEnd.year,
        expectedEnd.month - 11,
        1,
      );

      expect(range.startDate.year, expectedStart.year);
      expect(range.startDate.month, expectedStart.month);
      expect(range.startDate.day, 1);

      expect(range.endDate.year, expectedEnd.year);
      expect(range.endDate.month, expectedEnd.month);
      expect(range.endDate.day, expectedEnd.day);
    });

    test('setCustomRange sets exact provided dates', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 3, 31);

      container.read(dateRangeProvider.notifier).setCustomRange(start, end);
      final range = container.read(dateRangeProvider);

      expect(range.startDate, start);
      expect(range.endDate, end);
    });

    test('setCurrentMonth resets to current month after custom range', () {
      container
          .read(dateRangeProvider.notifier)
          .setCustomRange(DateTime(2025, 6, 1), DateTime(2025, 7, 31));

      container.read(dateRangeProvider.notifier).setCurrentMonth();
      final range = container.read(dateRangeProvider);

      final now = DateTime.now();
      final expectedEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));

      expect(range.startDate.year, now.year);
      expect(range.startDate.month, now.month);
      expect(range.startDate.day, 1);

      expect(range.endDate.year, expectedEnd.year);
      expect(range.endDate.month, expectedEnd.month);
      expect(range.endDate.day, expectedEnd.day);
    });
  });
}
