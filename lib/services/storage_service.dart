import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../models/stored_invoice.dart';
import '../models/stored_product.dart';
import '../models/stored_stock_movement.dart';

/// Thrown by [StorageService.saveProduct] when the product's SKU duplicates
/// another product's SKU (FR-003). Carries the conflicting product so the
/// caller can tell the user exactly which product already uses that SKU.
class ProductSkuConflictException implements Exception {
  final Product conflictingProduct;
  ProductSkuConflictException(this.conflictingProduct);

  @override
  String toString() =>
      'SKU "${conflictingProduct.sku}" is already used by "${conflictingProduct.name}".';
}

class StorageService {
  static Isar? _isar;

  /// Initializes the Isar offline database.
  static Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StoredInvoiceSchema, StoredProductSchema, StoredStockMovementSchema],
      directory: dir.path,
    );
  }

  /// Saves a localized Invoice to Isar storage offline.
  static Future<void> saveInvoice(Invoice invoice) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final jsonStr = jsonEncode(invoice.toJson());
    final stored = StoredInvoice()
      ..invoiceId = invoice.id
      ..clientName = invoice.client.fullName
      ..date = invoice.issueDate.toIso8601String()
      ..grandTotal = invoice.grandTotal
      ..rawJson = jsonStr;

    await isar.writeTxn(() async {
      await isar.storedInvoices.putByInvoiceId(stored);
    });
  }

  /// Lists all previously saved Invoices offline.
  static Future<List<Invoice>> getAllInvoices() async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final storedList = await isar.storedInvoices.where().sortByDateDesc().findAll();
    return storedList.map((stored) {
      final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
      return Invoice.fromJson(decodedMap);
    }).toList();
  }

  /// Retrieves a specific Invoice by its ID.
  static Future<Invoice?> getInvoice(String invoiceId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final stored = await isar.storedInvoices.getByInvoiceId(invoiceId);
    if (stored == null) return null;

    final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
    return Invoice.fromJson(decodedMap);
  }

  /// Flips the paid/unpaid state of a stored invoice and re-persists it.
  static Future<Invoice?> setInvoicePaid(String invoiceId, bool isPaid) async {
    final existing = await getInvoice(invoiceId);
    if (existing == null) return null;
    final updated = existing.copyWith(isPaid: isPaid);
    await saveInvoice(updated);
    return updated;
  }

  /// Deletes a specific Invoice from storage.
  static Future<void> deleteInvoice(String invoiceId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    await isar.writeTxn(() async {
      await isar.storedInvoices.deleteByInvoiceId(invoiceId);
    });
  }

  // ==========================================
  // PRODUCT CATALOG (Feature 001 — Products & Inventory, US1)
  // ==========================================

  /// Saves (creates or updates) a Product. Enforces FR-003: a product's SKU
  /// (when present) must be unique across the catalog. Throws
  /// [ProductSkuConflictException] naming the conflicting product instead of
  /// silently overwriting or allowing the duplicate.
  static Future<void> saveProduct(Product product) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final existing = await getAllProducts();
    final conflict = findProductSkuConflict(existing, product);
    if (conflict != null) {
      throw ProductSkuConflictException(conflict);
    }

    final jsonStr = jsonEncode(product.toJson());
    final stored = StoredProduct()
      ..productId = product.id
      ..sku = product.sku
      ..name = product.name
      ..category = product.category
      ..onHandQuantity = product.onHandQuantity
      ..rawJson = jsonStr;

    await isar.writeTxn(() async {
      await isar.storedProducts.putByProductId(stored);
    });
  }

  /// Lists all products in the catalog. Sorted by name at the storage layer;
  /// screens apply their own search/filter/sort on top (SC-002), matching
  /// how invoices are handled.
  static Future<List<Product>> getAllProducts() async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final storedList = await isar.storedProducts.where().sortByName().findAll();
    return storedList.map((stored) {
      final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
      return Product.fromJson(decodedMap);
    }).toList();
  }

  /// Retrieves a specific Product by its ID.
  static Future<Product?> getProduct(String productId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final stored = await isar.storedProducts.getByProductId(productId);
    if (stored == null) return null;

    final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
    return Product.fromJson(decodedMap);
  }

  /// Deletes a specific Product from the catalog. Per FR-010 (by analogy),
  /// this only removes the catalog entry — it never touches past invoices,
  /// which keep their own name/price snapshot regardless of a product's
  /// later edit or deletion.
  static Future<void> deleteProduct(String productId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    await isar.writeTxn(() async {
      await isar.storedProducts.deleteByProductId(productId);
    });
  }

  /// Closes the Isar database. Only used for testing or cleaning resources.
  static Future<void> close() async {
    final isar = _isar;
    if (isar != null) {
      await isar.close();
      _isar = null;
    }
  }

  /// Checks if initialized
  static bool get isInitialized => _isar != null;
}
