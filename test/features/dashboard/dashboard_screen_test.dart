import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomledger/features/dashboard/dashboard_providers.dart';
import 'package:roomledger/features/dashboard/dashboard_screen.dart';
import 'package:roomledger/features/dashboard/domain/dashboard_models.dart';

void main() {
  group('DashboardScreen', () {
    testWidgets('shows loading state while overview is pending', (tester) async {
      final completer = Completer<DashboardOverview>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when overview fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) async => throw Exception('boom')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Could not load dashboard data.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders overview data and quick actions', (tester) async {
      final overview = DashboardOverview(
        totalPending: 4500,
        totalDebt: 5000,
        totalRepaid: 500,
        debtorCount: 3,
        monthlySpending: 12000,
        sharedSpending: 7500,
        personalSpending: 4500,
        overdueCount: 1,
        pendingDebts: [
          PendingDebtItem(
            friendName: 'Ravi',
            note: 'Groceries',
            totalAmount: 2500,
            repaidAmount: 500,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        ],
        recentActivities: [
          DashboardActivity(
            title: 'Debt added',
            subtitle: 'Ravi - Groceries',
            amount: 2500,
            createdAt: DateTime.utc(2026, 5, 1),
            isSettlement: false,
          ),
        ],
        cashBalance: 300,
        emergencyReserve: 500,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardOverviewProvider.overrideWith((ref) async => overview),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RoomLedger'), findsOneWidget);
      expect(find.text('Low Cash Warning'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Quick actions'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('View analytics'), findsOneWidget);
    });
  });
}
