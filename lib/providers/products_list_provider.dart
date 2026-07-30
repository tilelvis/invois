import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// Holds the full product catalog persisted in Isar, plus loading state.
/// Screens (Products, and later Inventory/Dashboard) all read from this
/// single source of truth so that saving/deleting a product in one place is
/// reflected everywhere else immediately. Mirrors [InvoicesListNotifier].
class ProductsListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsListNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      if (!StorageService.isInitialized) {
        await StorageService.init();
      }
      final products = await StorageService.getAllProducts();
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Saves (creates or updates) a product. Lets
  /// [ProductSkuConflictException] propagate uncaught so the calling form
  /// can show which product already uses that SKU (FR-003) instead of the
  /// list silently failing to refresh.
  Future<void> save(Product product) async {
    await StorageService.saveProduct(product);
    await refresh();
  }

  Future<void> delete(String productId) async {
    await StorageService.deleteProduct(productId);
    await refresh();
  }

  /// Re-saves a previously deleted product (used for "Undo" after a
  /// swipe-delete), matching the invoices list's undo pattern.
  Future<void> restore(Product product) async {
    await StorageService.saveProduct(product);
    await refresh();
  }
}

final productsListProvider =
    StateNotifierProvider<ProductsListNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsListNotifier();
});
