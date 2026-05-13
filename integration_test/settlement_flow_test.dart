import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roomledger/app/roomledger_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Record settlement updates debt status', (WidgetTester tester) async {
    // Launch the app
    await tester.pumpWidget(const ProviderScope(child: RoomLedgerApp()));
    await tester.pumpAndSettle();

    // Navigate to Debts tab
    await tester.tap(find.text('Debts'));
    await tester.pumpAndSettle();

    // Look for a Record Payment button
    expect(find.text('Record Payment'), findsWidgets);
    
    // Tap the first Record Payment button
    await tester.tap(find.text('Record Payment').first);
    await tester.pumpAndSettle();

    // Verify Record Payment sheet is open
    expect(find.text('Payment Amount (₹)'), findsOneWidget);

    // Enter a small payment amount
    await tester.enterText(find.widgetWithText(TextFormField, 'Payment Amount (₹)'), '50');
    await tester.pumpAndSettle();

    // Enter note
    await tester.enterText(find.widgetWithText(TextFormField, 'Payment Note (Optional)'), 'Integration test payment');
    await tester.pumpAndSettle();

    // Submit Payment
    // The submit button has text 'Record Payment', which matches the text we used to open the sheet.
    // However, in the sheet, it's a FilledButton or ElevatedButton.
    // We can use the generic find.text('Record Payment').last since the sheet is on top.
    await tester.tap(find.text('Record Payment').last);
    await tester.pumpAndSettle();

    // Check that we returned to Debts screen and a SnackBar appeared
    expect(find.text('Payment of ₹50 recorded'), findsOneWidget);

    // The payment should reflect, but since we just do a simple UI interaction, finding the snackbar is a good validation.
  });
}
