import 'package:flutter_test/flutter_test.dart';
import 'package:invois_app/models/models.dart';
import 'package:invois_app/models/stored_invoice.dart';

void main() {
  group('StoredInvoice mapping tests', () {
    test('Can map Invoice to StoredInvoice properties correctly', () {
      final client = Client(id: 'c1', fullName: 'Contractor Bob', phoneNumber: '0711223344');
      final payment = PaymentDetails(mpesaType: MpesaType.paybill, mpesaNumber: '12345', accountName: 'ProjA');

      final invoice = Invoice(
        id: 'INV-1234',
        client: client,
        items: [],
        issueDate: DateTime(2025, 6, 20),
        dueDate: DateTime(2025, 6, 27),
        paymentDetails: payment,
      );

      final stored = StoredInvoice()
        ..invoiceId = invoice.id
        ..clientName = invoice.client.fullName
        ..date = invoice.issueDate.toIso8601String()
        ..grandTotal = invoice.grandTotal
        ..rawJson = '{}';

      expect(stored.invoiceId, 'INV-1234');
      expect(stored.clientName, 'Contractor Bob');
      expect(stored.grandTotal, 0.0);
    });
  });
}
