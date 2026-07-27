import 'package:flutter_test/flutter_test.dart';
import 'package:invois_app/models/models.dart';

void main() {
  group('PaymentDetails Validation', () {
    test('Valid Paybill details pass', () {
      final payment = PaymentDetails(
        mpesaType: MpesaType.paybill,
        mpesaNumber: '522522',
        accountName: 'PROJ-123',
      );
      expect(payment.mpesaNumber, '522522');
      expect(payment.accountName, 'PROJ-123');
    });

    test('Valid Till number passes without account name', () {
      final payment = PaymentDetails(
        mpesaType: MpesaType.tillNumber,
        mpesaNumber: '123456',
      );
      expect(payment.mpesaNumber, '123456');
    });

    test('Invalid M-Pesa digits throws ArgumentError', () {
      expect(
        () => PaymentDetails(mpesaType: MpesaType.tillNumber, mpesaNumber: '1234'),
        throwsArgumentError,
      );
      expect(
        () => PaymentDetails(mpesaType: MpesaType.tillNumber, mpesaNumber: '1234567'),
        throwsArgumentError,
      );
    });

    test('Paybill without account name throws ArgumentError', () {
      expect(
        () => PaymentDetails(mpesaType: MpesaType.paybill, mpesaNumber: '123456', accountName: ''),
        throwsArgumentError,
      );
    });
  });

  group('Client Validation', () {
    test('Valid Kenyan phone numbers pass', () {
      final client1 = Client(id: '1', fullName: 'John Doe', phoneNumber: '0712345678');
      final client2 = Client(id: '2', fullName: 'Jane Doe', phoneNumber: '+254712345678');
      final client3 = Client(id: '3', fullName: 'Alex Smith', phoneNumber: '0112345678');

      expect(client1.phoneNumber, '0712345678');
      expect(client2.phoneNumber, '+254712345678');
      expect(client3.phoneNumber, '0112345678');
    });

    test('Invalid phone numbers throw ArgumentError', () {
      expect(
        () => Client(id: '1', fullName: 'John Doe', phoneNumber: '12345678'),
        throwsArgumentError,
      );
      expect(
        () => Client(id: '1', fullName: 'John Doe', phoneNumber: '071234567'),
        throwsArgumentError,
      );
    });

    test('Valid and invalid KRA PIN formats', () {
      // Valid
      final client = Client(
        id: '1',
        fullName: 'John Doe',
        phoneNumber: '0712345678',
        kraPin: 'A123456789B',
      );
      expect(client.kraPin, 'A123456789B');

      // Invalid length
      expect(
        () => Client(
          id: '1',
          fullName: 'John',
          phoneNumber: '0712345678',
          kraPin: 'A12345678B',
        ),
        throwsArgumentError,
      );

      // Invalid start/end
      expect(
        () => Client(
          id: '1',
          fullName: 'John',
          phoneNumber: '0712345678',
          kraPin: '11234567890',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Invoice & Item Calculations & Serialization', () {
    test('Calculates subtotals, VAT, and grand totals accurately', () {
      final labor = InvoiceItem(
        description: 'Wiring labor',
        type: ItemType.labor,
        quantity: 5.5,
        unitPrice: 1000.0,
        vatCategory: VatCategory.exempt,
      );

      final material = InvoiceItem(
        description: 'Pipes & Cables',
        type: ItemType.material,
        quantity: 10,
        unitPrice: 500.0,
        vatCategory: VatCategory.standard16,
      );

      expect(labor.subtotal, 5500.0);
      expect(labor.vatAmount, 0.0);

      expect(material.subtotal, 5000.0);
      expect(material.vatAmount, 800.0); // 16% of 5000

      final client = Client(id: '1', fullName: 'Alice', phoneNumber: '0711223344');
      final payment = PaymentDetails(mpesaType: MpesaType.tillNumber, mpesaNumber: '123456');

      final invoice = Invoice(
        id: 'INV-001',
        client: client,
        items: [labor, material],
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        paymentDetails: payment,
      );

      expect(invoice.totalSubtotal, 10500.0);
      expect(invoice.totalVat, 800.0);
      expect(invoice.grandTotal, 11300.0);
      expect(invoice.mpesaFormattedPhone, '254711223344');
    });

    test('Serialization (toJson <-> fromJson)', () {
      final client = Client(
        id: 'c1',
        fullName: 'Bob',
        phoneNumber: '+254712345678',
        kraPin: 'P012345678C',
      );
      final payment = PaymentDetails(
        mpesaType: MpesaType.paybill,
        mpesaNumber: '123456',
        accountName: 'Project X',
      );
      final item = InvoiceItem(
        description: 'Consultation',
        type: ItemType.labor,
        quantity: 2,
        unitPrice: 2500,
        vatCategory: VatCategory.standard16,
      );

      final invoice = Invoice(
        id: 'inv-99',
        client: client,
        items: [item],
        issueDate: DateTime(2025, 6, 15),
        dueDate: DateTime(2025, 6, 22),
        paymentDetails: payment,
        etimsInvoiceNumber: 'ETIMS-888',
        isEtimsValidated: true,
      );

      final json = invoice.toJson();
      final decoded = Invoice.fromJson(json);

      expect(decoded.id, 'inv-99');
      expect(decoded.client.fullName, 'Bob');
      expect(decoded.client.phoneNumber, '+254712345678');
      expect(decoded.client.kraPin, 'P012345678C');
      expect(decoded.paymentDetails.mpesaType, MpesaType.paybill);
      expect(decoded.paymentDetails.accountName, 'Project X');
      expect(decoded.items.length, 1);
      expect(decoded.items[0].description, 'Consultation');
      expect(decoded.items[0].subtotal, 5000.0);
      expect(decoded.items[0].vatAmount, 800.0);
      expect(decoded.etimsInvoiceNumber, 'ETIMS-888');
      expect(decoded.isEtimsValidated, true);
    });
  });
}
