import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invois_app/models/models.dart';
import 'package:invois_app/providers/products_list_provider.dart';
import 'package:invois_app/services/storage_service.dart';

void main() {
  group('ProductsListNotifier (Feature 001, T015)', () {
    // NOTE: like storage_service_test.dart, this suite does not exercise a
    // live Isar database — plain `flutter_test` has no platform channel for
    // path_provider/Isar Core, so StorageService.init() cannot succeed here.
    // That mirrors this repo's existing convention (there's no
    // invoices_list_provider_test.dart for the same reason). What's
    // genuinely unit-testable without Isar is covered below: the notifier
    // resolving to a valid state instead of hanging/crashing, and the
    // SKU-conflict contract (add/edit "duplicate SKU rejected") that
    // products_view.dart and product_form_view.dart rely on.

    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts loading and settles to a terminal AsyncValue without throwing', () async {
      final notifier = container.read(productsListProvider.notifier);
      expect(container.read(productsListProvider), isA<AsyncLoading<List<Product>>>());

      // refresh() catches its own errors into AsyncValue.error — it must
      // never let StorageService.init() failures escape as an unhandled
      // exception up through the notifier.
      await notifier.refresh();

      final state = container.read(productsListProvider);
      expect(state, isNot(isA<AsyncLoading<List<Product>>>()));
    });

    test('ProductSkuConflictException names the conflicting product (surfaced by add/edit)', () {
      final conflicting = Product(id: 'p1', name: 'Existing Widget', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);
      final exception = ProductSkuConflictException(conflicting);

      expect(exception.conflictingProduct.id, 'p1');
      expect(exception.toString(), contains('Existing Widget'));
      expect(exception.toString(), contains('SKU-1'));
    });

    test('duplicate SKU is detected before save would occur (add case)', () {
      final existing = [
        Product(id: 'p1', name: 'Existing Widget', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1),
      ];
      final newProduct = Product(id: 'p2', name: 'New Widget', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1);

      expect(findProductSkuConflict(existing, newProduct)?.name, 'Existing Widget');
    });

    test('editing a product to keep its own SKU is not a conflict', () {
      final existing = [
        Product(id: 'p1', name: 'Widget', sku: 'SKU-1', unit: 'pcs', costPrice: 1, sellingPrice: 1),
      ];
      final edited = Product(id: 'p1', name: 'Widget v2', sku: 'SKU-1', unit: 'pcs', costPrice: 2, sellingPrice: 3);

      expect(findProductSkuConflict(existing, edited), isNull);
    });
  });
}
