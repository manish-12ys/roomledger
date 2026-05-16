import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roomledger/app/roomledger_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add shared expense updates dashboard', (
    WidgetTester tester,
  ) async {
    // Launch the app
    await tester.pumpWidget(const ProviderScope(child: RoomLedgerApp()));
    await tester.pumpAndSettle();

    // Navigate to Roommates (in drawer)
    await tester.tap(find.byIcon(Icons.menu)); // Open drawer
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roommates'));
    await tester.pumpAndSettle();

    // Add first friend
    await tester.tap(find.text('Add Roommate'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Roommate Name'),
      'Alice',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add roommate'));
    await tester.pumpAndSettle();

    // Add second friend
    await tester.tap(find.text('Add Roommate'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Roommate Name'),
      'Bob',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add roommate'));
    await tester.pumpAndSettle();

    // Navigate to Shared (Expenses) tab
    await tester.tap(find.text('Shared'));
    await tester.pumpAndSettle();

    // Tap Add Expense FAB
    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    // Verify Add Expense sheet is open
    expect(find.text('Add Shared Expense'), findsOneWidget);

    // Select Equal Split
    await tester.tap(find.text('Equal Split'));
    await tester.pumpAndSettle();

    // Select friends
    await tester.tap(find.text('Alice'));
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    // Enter amount
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount (INR)'),
      '500',
    );
    await tester.pumpAndSettle();

    // Enter note
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expense Note'),
      'Dinner',
    );
    await tester.pumpAndSettle();

    // Save Expense
    await tester.tap(find.bySemanticsLabel('Save expense'));
    await tester.pumpAndSettle();

    // Verify we are back to Expenses screen
    expect(find.text('Add Shared Expense'), findsNothing); // Should be closed

    // Navigate back to Home (Dashboard)
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // The Dashboard should show the new 'Dinner' transaction in Recent Transactions
    expect(find.text('Dinner'), findsWidgets);
  });
}
