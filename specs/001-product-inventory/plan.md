# Implementation Plan: Products & Inventory Management

**Date**: 2026-07-29 | **Spec**: specs/001-product-inventory/spec.md
**Input**: Feature specification from `specs/001-product-inventory/spec.md`

## Summary

Add a standalone product catalog and single-location stock ledger to Invois, following the app's existing patterns exactly: plain Dart domain models, a thin Isar `@collection` wrapper per entity (indexed scalar fields + `rawJson` blob), and Riverpod `StateNotifier` providers as the single source of truth per screen family — same shape as `Invoice`/`StoredInvoice`/`invoicesListProvider`. No changes to invoice creation or the existing `Invoice`/`InvoiceItem` models (per FR-010, FR-014).

## Technical Context

**Language/Version**: Dart (Flutter SDK ^3.11.0, per pubspec.yaml)

**Primary Dependencies**: `flutter_riverpod` (state), `isar`/`isar_flutter_libs` (storage, already in use), `uuid` (entity IDs, already in use) — no new dependencies needed.

**Storage**: Isar, extending the existing single local database (same `Isar.open` call in `StorageService.init`, adding two new collection schemas alongside `StoredInvoiceSchema`).

**Testing**: `flutter_test`, matching existing `test/models`, `test/providers`, `test/services` structure.

**Target Platform**: Android (mobile), offline-first — matches the rest of Invois.

**Project Type**: Single Flutter app (not web/multi-tenant).

**Performance Goals**: Product search/filter feels instant on a 200+ item catalog (SC-002) — achievable with in-memory filtering over a Riverpod-held list, same approach the app already uses for invoices/clients; no need for Isar query-time filtering at this scale.

**Constraints**: Must work fully offline (FR-011); must not alter existing `Invoice`/`InvoiceItem` behavior (FR-010, FR-014).

**Scale/Scope**: Single business, single location, indicatively hundreds (not thousands) of products/movements — consistent with the SME target market.

## Constitution Check

No `constitution.md` on file for this project — skipping gate (established project, adding one feature; not warranted here).

## Project Structure

### Documentation (this feature)

```text
specs/001-product-inventory/
├── plan.md              # This file
├── data-model.md         # Phase 1 output
└── tasks.md              # Phase 2 output
```
(No `research.md` — no unresolved unknowns after Clarify. No `contracts/` — no external API. No `quickstart.md` — covered by acceptance scenarios in spec.md.)

### Source Code (repository root)

```text
lib/
├── models/
│   ├── models.dart              # add Product, StockMovement domain classes here
│   ├── stored_product.dart      # new: Isar @collection wrapper (mirrors stored_invoice.dart)
│   └── stored_stock_movement.dart  # new: Isar @collection wrapper
├── services/
│   └── storage_service.dart     # extend: add Product/StockMovement CRUD, add schemas to Isar.open
├── providers/
│   ├── products_list_provider.dart   # new: StateNotifier, mirrors invoices_list_provider.dart
│   └── inventory_provider.dart       # new: stock movement operations + on-hand recompute
├── views/
│   ├── products_view.dart       # new: catalog list, search/filter/sort, low-stock badges
│   ├── product_form_view.dart   # new: add/edit product
│   └── inventory_view.dart      # new: per-product stock history + restock/reduce/adjust actions
└── widgets/
    └── (reuse existing app_design_system.dart, empty_state.dart, shimmer_loading.dart — no new shared widgets anticipated)

test/
├── models/models_test.dart       # extend: Product/StockMovement serialization round-trip
├── providers/                    # new: products_list_provider_test.dart, inventory_provider_test.dart
└── services/storage_service_test.dart  # extend: product/stock persistence
```

**Structure Decision**: Single Flutter project, extending existing `lib/{models,services,providers,views}` folders in place — no new top-level structure, matching how `Client`/`Invoice` are already organized.

## Complexity Tracking

No Constitution Check violations to justify — this feature adds two new entities using patterns already established in the codebase, with no new dependencies, no new architectural layer, and explicit non-goals (no invoice integration, no multi-location, no notifications) keeping scope tight.
