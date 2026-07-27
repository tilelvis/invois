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

    // Verify app title loads
    expect(find.text('JULES KENYA INVOICER'), findsOneWidget);

    // Verify initial empty states
    expect(find.text('No Client Info Added'), findsOneWidget);
    expect(find.text('No Payment Channels Saved'), findsOneWidget);
    expect(find.text('No services, labor hours, or materials added.'), findsOneWidget);

    // Verify grand total displays 0.00
    expect(find.textContaining('KES 0.00'), findsWidgets);
  });
}
