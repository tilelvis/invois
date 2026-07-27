import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invois_app/models/models.dart';
import 'package:invois_app/providers/invoice_provider.dart';

void main() {
  group('InvoiceState & InvoiceNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial State Setup', () {
      final state = container.read(invoiceProvider);
      expect(state.id, startsWith('INV-'));
      expect(state.items, isEmpty);
      expect(state.client, isNull);
      expect(state.paymentDetails, isNull);
      expect(state.isValid, isFalse);
    });

    test('Client and Payment details updating', () {
      final client = Client(id: 'c1', fullName: 'Jane Cooper', phoneNumber: '0712345678');
      final payment = PaymentDetails(mpesaType: MpesaType.tillNumber, mpesaNumber: '112233');

      final notifier = container.read(invoiceProvider.notifier);
      notifier.updateClient(client);
      notifier.updatePaymentDetails(payment);

      final state = container.read(invoiceProvider);
      expect(state.client?.fullName, 'Jane Cooper');
      expect(state.paymentDetails?.mpesaNumber, '112233');
      expect(state.isValid, isFalse); // False because no items added yet
    });

    test('Dynamic item additions and recalculations', () {
      final notifier = container.read(invoiceProvider.notifier);

      final laborItem = InvoiceItem(
        description: 'Electrical Labor',
        type: ItemType.labor,
        quantity: 3.5, // Decimals supported
        unitPrice: 1200.0,
        vatCategory: VatCategory.exempt,
      );

      final materialItem = InvoiceItem(
        description: 'Copper Pipes',
        type: ItemType.material,
        quantity: 10,
        unitPrice: 450.0,
        vatCategory: VatCategory.standard16,
      );

      notifier.addItem(laborItem);
      notifier.addItem(materialItem);

      var state = container.read(invoiceProvider);
      expect(state.items.length, 2);
      expect(state.totalSubtotal, 4200.0 + 4500.0); // 8700
      expect(state.totalVat, 4500 * 0.16); // 720
      expect(state.grandTotal, 8700 + 720); // 9420

      // Update item test
      final updatedLabor = InvoiceItem(
        description: 'Electrical Labor (Special Rates)',
        type: ItemType.labor,
        quantity: 3.5,
        unitPrice: 1500.0, // increased price
        vatCategory: VatCategory.exempt,
      );
      notifier.updateItem(0, updatedLabor);

      state = container.read(invoiceProvider);
      expect(state.items[0].description, 'Electrical Labor (Special Rates)');
      expect(state.totalSubtotal, 5250.0 + 4500.0); // 9750

      // Remove item test
      notifier.removeItem(0);
      state = container.read(invoiceProvider);
      expect(state.items.length, 1);
      expect(state.totalSubtotal, 4500.0);
    });

    test('Valid complete Invoice Generation', () {
      final client = Client(id: 'c1', fullName: 'Jane Cooper', phoneNumber: '0712345678');
      final payment = PaymentDetails(mpesaType: MpesaType.tillNumber, mpesaNumber: '112233');
      final item = InvoiceItem(
        description: 'Consultation',
        type: ItemType.labor,
        quantity: 1,
        unitPrice: 3000,
        vatCategory: VatCategory.exempt,
      );

      final notifier = container.read(invoiceProvider.notifier);
      notifier.updateClient(client);
      notifier.updatePaymentDetails(payment);
      notifier.addItem(item);

      final state = container.read(invoiceProvider);
      expect(state.isValid, isTrue);

      final invoice = state.toInvoice();
      expect(invoice.id, state.id);
      expect(invoice.client.fullName, 'Jane Cooper');
      expect(invoice.grandTotal, 3000.0);
    });
  });
}
