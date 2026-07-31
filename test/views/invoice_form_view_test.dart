import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invois_app/views/invoice_form_view.dart';

void main() {
  testWidgets('InvoiceFormView loads with empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: InvoiceFormView(),
        ),
      ),
    );

    // Verify shrunk-header title loads (was "INVOIS KENYA" before the
    // header-shrink fix; see invoice_form_view.dart AppBar)
    expect(find.text('New Invoice'), findsOneWidget);

    // Verify Step 1 inline cards load
    expect(find.text('Customer Profile'), findsOneWidget);
    expect(find.text('Lipa Na M-Pesa Gateway'), findsOneWidget);

    // Verify key fields exist in Step 1
    expect(find.textContaining('Customer Full Name'), findsWidgets);
    expect(find.textContaining('Kenyan Phone'), findsWidgets);
    expect(find.textContaining('Business Till Number'), findsWidgets);

    // Optional fields (email/KRA PIN/notes) are hidden behind a checkbox by
    // default now — verify the toggle exists and the fields start hidden.
    expect(find.textContaining('Add email, KRA PIN or notes'), findsOneWidget);
    expect(find.textContaining('Optional Email Address'), findsNothing);
  });
}
