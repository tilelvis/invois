import 'package:flutter_test/flutter_test.dart';
import 'package:invois_app/models/models.dart';
import 'package:invois_app/services/pdf_service.dart';

void main() {
  group('PdfService Tests', () {
    test('generateInvoicePdf returns non-empty document bytes', () async {
      final client = Client(
        id: 'c1',
        fullName: 'John Contractor',
        phoneNumber: '0712345678',
        kraPin: 'A123456789B',
      );

      final payment = PaymentDetails(
        mpesaType: MpesaType.tillNumber,
        mpesaNumber: '556677',
      );

      final labor = InvoiceItem(
        description: 'Wiring per hour',
        type: ItemType.labor,
        quantity: 4.5,
        unitPrice: 1000.0,
        vatCategory: VatCategory.exempt,
      );

      final material = InvoiceItem(
        description: 'PVC conduits',
        type: ItemType.material,
        quantity: 12,
        unitPrice: 150.0,
        vatCategory: VatCategory.standard16,
      );

      final invoice = Invoice(
        id: 'INV-99999',
        client: client,
        items: [labor, material],
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        paymentDetails: payment,
        etimsInvoiceNumber: 'ETIMS-MOCK-REF-777',
        isEtimsValidated: true,
      );

      final pdfBytes = await PdfService.generateInvoicePdf(invoice);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100)); // Standard PDF header and metadata should be at least a few KB
    });
  });
}
