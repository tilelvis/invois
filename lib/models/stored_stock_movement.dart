import 'package:isar/isar.dart';

part 'stored_stock_movement.g.dart';

/// Isar collection wrapper for [StockMovement] (feature 001 — Products &
/// Inventory). Movements are append-only (never edited or deleted — an
/// incorrect entry is corrected with a new `adjustment` movement instead),
/// so this collection has no unique index beyond the Isar-assigned `id`.
@collection
class StoredStockMovement {
  Id id = Isar.autoIncrement;

  @Index()
  late String productId;

  late String movementId;
  late String timestamp; // ISO8601, for sort
  late String rawJson; // full serialized StockMovement
}
