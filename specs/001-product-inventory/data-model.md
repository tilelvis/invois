# Data Model: Products & Inventory Management

## Product (domain model, in `lib/models/models.dart`)

| Field | Type | Notes |
|---|---|---|
| id | String (uuid) | matches `Invoice.id` / `Client` pattern |
| name | String | required |
| sku | String? | optional, unique when present (enforced at save time, checked against all products) |
| unit | String | free text, e.g. "pcs", "kg", "litre" |
| costPrice | double | |
| sellingPrice | double | |
| vatCategory | VatCategory | reuses existing enum from invoice items |
| category | String | free text tag, used for filtering |
| reorderThreshold | int? | optional; null = never flagged low-stock |
| onHandQuantity | int | derived/cached — recomputed from StockMovement history on every write, not independently editable |

## StockMovement (domain model)

| Field | Type | Notes |
|---|---|---|
| id | String (uuid) | |
| productId | String | FK to Product.id |
| type | enum { restock, reduction, adjustment } | adjustment = direct set, distinct from ordinary in/out |
| quantityDelta | int | signed for restock/reduction; adjustment stores the resulting total instead (see note) |
| resultingOnHand | int | on-hand quantity immediately after this movement — makes history self-verifying (SC-003) |
| note | String? | optional reason/memo |
| timestamp | DateTime | |

## Isar Collections (mirrors `StoredInvoice` pattern exactly)

```dart
// lib/models/stored_product.dart
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

// lib/models/stored_stock_movement.dart
@collection
class StoredStockMovement {
  Id id = Isar.autoIncrement;

  @Index()
  late String productId;

  late String movementId;
  late String timestamp; // ISO8601, for sort
  late String rawJson; // full serialized StockMovement
}
```

Indexes chosen the same way `StoredInvoice` does: enough scalar fields to search/sort/filter at the Isar level (name/sku/category/onHand for products; productId/timestamp for movements), full fidelity kept in `rawJson`.

## Invariants

- `Product.onHandQuantity` MUST always equal the `resultingOnHand` of that product's most recent `StockMovement` (or 0 if none exist yet).
- `StockMovement` records are append-only — never edited or deleted (an incorrect entry is corrected with a new `adjustment` movement, preserving history per FR-009).
- SKU uniqueness is checked across the full product list at save time (small catalog size makes this a cheap in-memory check; no unique Isar index needed on `sku` itself since it's nullable and Isar's unique index doesn't play well with repeated nulls across versions).
