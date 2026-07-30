import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:invois_app/models/models.dart';
import 'package:invois_app/models/stored_invoice.dart';
import 'package:invois_app/models/stored_product.dart';

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

  group('StoredProduct mapping tests (Feature 001, T016)', () {
    test('Can map Product to StoredProduct properties correctly', () {
      final product = Product(
        id: 'prod-1',
        name: 'Bag of Cement 50kg',
        sku: 'CEM-50',
        unit: 'bag',
        costPrice: 650.0,
        sellingPrice: 800.0,
        category: 'Building materials',
        onHandQuantity: 42,
      );

      final stored = StoredProduct()
        ..productId = product.id
        ..sku = product.sku
        ..name = product.name
        ..category = product.category
        ..onHandQuantity = product.onHandQuantity
        ..rawJson = jsonEncode(product.toJson());

      expect(stored.productId, 'prod-1');
      expect(stored.sku, 'CEM-50');
      expect(stored.name, 'Bag of Cement 50kg');
      expect(stored.category, 'Building materials');
      expect(stored.onHandQuantity, 42);
    });

    test('rawJson round trip reproduces the original Product (mirrors saveProduct/getAllProducts)', () {
      final product = Product(
        id: 'prod-2',
        name: 'Roofing Nails 1kg',
        unit: 'kg',
        costPrice: 120.0,
        sellingPrice: 180.0,
        vatCategory: VatCategory.standard16,
        reorderThreshold: 5,
        onHandQuantity: 3,
      );

      final stored = StoredProduct()
        ..productId = product.id
        ..sku = product.sku
        ..name = product.name
        ..category = product.category
        ..onHandQuantity = product.onHandQuantity
        ..rawJson = jsonEncode(product.toJson());

      final roundTripped = Product.fromJson(jsonDecode(stored.rawJson) as Map<String, dynamic>);

      expect(roundTripped.id, product.id);
      expect(roundTripped.name, product.name);
      expect(roundTripped.costPrice, product.costPrice);
      expect(roundTripped.sellingPrice, product.sellingPrice);
      expect(roundTripped.vatCategory, VatCategory.standard16);
      expect(roundTripped.reorderThreshold, 5);
      expect(roundTripped.onHandQuantity, 3);
      expect(roundTripped.isLowStock, true);
    });

    test('saveProduct-style SKU conflict check rejects a duplicate before it reaches storage', () {
      final existing = [
        Product(id: 'prod-1', name: 'A', sku: 'DUP-1', unit: 'pcs', costPrice: 1, sellingPrice: 1),
      ];
      final candidate = Product(id: 'prod-2', name: 'B', sku: 'DUP-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      final conflict = findProductSkuConflict(existing, candidate);
      expect(conflict, isNotNull);
      expect(conflict!.id, 'prod-1');
    });
  });
}
