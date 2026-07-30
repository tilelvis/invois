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

  group('Product Serialization (Feature 001)', () {
    test('toJson/fromJson round trip preserves all fields', () {
      final product = Product(
        id: 'prod-1',
        name: 'Bag of Cement 50kg',
        sku: 'CEM-50',
        unit: 'bag',
        costPrice: 650.0,
        sellingPrice: 800.0,
        vatCategory: VatCategory.standard16,
        category: 'Building materials',
        reorderThreshold: 10,
        onHandQuantity: 42,
      );

      final decoded = Product.fromJson(product.toJson());

      expect(decoded.id, 'prod-1');
      expect(decoded.name, 'Bag of Cement 50kg');
      expect(decoded.sku, 'CEM-50');
      expect(decoded.unit, 'bag');
      expect(decoded.costPrice, 650.0);
      expect(decoded.sellingPrice, 800.0);
      expect(decoded.vatCategory, VatCategory.standard16);
      expect(decoded.category, 'Building materials');
      expect(decoded.reorderThreshold, 10);
      expect(decoded.onHandQuantity, 42);
    });

    test('round trip preserves null sku and null reorderThreshold', () {
      final product = Product(
        id: 'prod-2',
        name: 'Consulting Hour',
        unit: 'hour',
        costPrice: 0,
        sellingPrice: 2500,
      );

      final decoded = Product.fromJson(product.toJson());

      expect(decoded.sku, isNull);
      expect(decoded.reorderThreshold, isNull);
      expect(decoded.onHandQuantity, 0);
      expect(decoded.category, '');
    });

    test('rejects blank name', () {
      expect(
        () => Product(id: 'p', name: '   ', unit: 'pcs', costPrice: 1, sellingPrice: 1),
        throwsArgumentError,
      );
    });

    test('rejects negative cost or selling price', () {
      expect(
        () => Product(id: 'p', name: 'X', unit: 'pcs', costPrice: -1, sellingPrice: 1),
        throwsArgumentError,
      );
      expect(
        () => Product(id: 'p', name: 'X', unit: 'pcs', costPrice: 1, sellingPrice: -1),
        throwsArgumentError,
      );
    });

    test('isLowStock is true only when a threshold is set and reached', () {
      final noThreshold = Product(id: 'p1', name: 'X', unit: 'pcs', costPrice: 1, sellingPrice: 1, onHandQuantity: 0);
      final aboveThreshold =
          Product(id: 'p2', name: 'X', unit: 'pcs', costPrice: 1, sellingPrice: 1, reorderThreshold: 5, onHandQuantity: 10);
      final atThreshold =
          Product(id: 'p3', name: 'X', unit: 'pcs', costPrice: 1, sellingPrice: 1, reorderThreshold: 5, onHandQuantity: 5);

      expect(noThreshold.isLowStock, false);
      expect(aboveThreshold.isLowStock, false);
      expect(atThreshold.isLowStock, true);
    });
  });

  group('findProductSkuConflict (FR-003)', () {
    test('returns null when no other product shares the SKU', () {
      final existing = [
        Product(id: 'p1', name: 'A', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1),
      ];
      final candidate = Product(id: 'p2', name: 'B', sku: 'SKU-2', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      expect(findProductSkuConflict(existing, candidate), isNull);
    });

    test('returns the conflicting product when SKUs match (case-insensitive)', () {
      final other = Product(id: 'p1', name: 'A', sku: 'sku-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);
      final candidate = Product(id: 'p2', name: 'B', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      expect(findProductSkuConflict([other], candidate)?.id, 'p1');
    });

    test('a product never conflicts with itself when editing', () {
      final self = Product(id: 'p1', name: 'A', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);
      final editedSelf = Product(id: 'p1', name: 'A renamed', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      expect(findProductSkuConflict([self], editedSelf), isNull);
    });

    test('blank/null SKUs never conflict', () {
      final existing = [
        Product(id: 'p1', name: 'A', unit: 'pcs', costPrice: 1, sellingPrice: 1),
        Product(id: 'p2', name: 'B', sku: '', unit: 'pcs', costPrice: 1, sellingPrice: 1),
      ];
      final candidate = Product(id: 'p3', name: 'C', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      expect(findProductSkuConflict(existing, candidate), isNull);
    });
  });

  group('StockMovement Serialization (Feature 001)', () {
    test('toJson/fromJson round trip preserves all fields', () {
      final movement = StockMovement(
        id: 'mov-1',
        productId: 'prod-1',
        type: StockMovementType.restock,
        quantityDelta: 20,
        resultingOnHand: 62,
        note: 'Delivery from supplier',
        timestamp: DateTime(2026, 7, 30, 9, 15),
      );

      final decoded = StockMovement.fromJson(movement.toJson());

      expect(decoded.id, 'mov-1');
      expect(decoded.productId, 'prod-1');
      expect(decoded.type, StockMovementType.restock);
      expect(decoded.quantityDelta, 20);
      expect(decoded.resultingOnHand, 62);
      expect(decoded.note, 'Delivery from supplier');
      expect(decoded.timestamp, DateTime(2026, 7, 30, 9, 15));
    });

    test('round trip preserves a null note', () {
      final movement = StockMovement(
        id: 'mov-2',
        productId: 'prod-1',
        type: StockMovementType.adjustment,
        quantityDelta: -3,
        resultingOnHand: 59,
        timestamp: DateTime(2026, 7, 30),
      );

      expect(StockMovement.fromJson(movement.toJson()).note, isNull);
    });

    test('rejects a negative resultingOnHand', () {
      expect(
        () => StockMovement(
          id: 'mov-3',
          productId: 'prod-1',
          type: StockMovementType.reduction,
          quantityDelta: -10,
          resultingOnHand: -1,
          timestamp: DateTime(2026, 7, 30),
        ),
        throwsArgumentError,
      );
    });
  });
}
