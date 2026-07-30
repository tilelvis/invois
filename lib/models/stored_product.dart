import 'package:isar/isar.dart';

part 'stored_product.g.dart';

/// Isar collection wrapper for [Product] (feature 001 — Products & Inventory).
/// Mirrors the [StoredInvoice] pattern exactly: a few indexed scalar fields
/// for search/sort/filter at the Isar level, plus a `rawJson` blob holding
/// the full serialized domain object for round-trip fidelity.
@collection
class StoredProduct {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String productId;

  @Index()
  String? sku;

  late String name;
  late String category;
  late int onHandQuantity;

  late String rawJson; // full serialized Product
}
