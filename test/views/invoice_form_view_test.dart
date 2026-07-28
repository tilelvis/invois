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

    // Verify rebranded app title loads
    expect(find.text('INVOIS KENYA'), findsOneWidget);

    // Verify Step 1 inline cards load
    expect(find.text('Customer Profile'), findsOneWidget);
    expect(find.text('Lipa Na M-Pesa Gateway'), findsOneWidget);

    // Verify key fields exist in Step 1
    expect(find.textContaining('Customer Full Name'), findsWidgets);
    expect(find.textContaining('Kenyan Phone'), findsWidgets);
    expect(find.textContaining('Business Till Number'), findsWidgets);
  });
}
