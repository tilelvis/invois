# Tasks: Products & Inventory Management

**Input**: Design documents from `specs/001-product-inventory/`
**Prerequisites**: plan.md, spec.md, data-model.md
**Tests**: included — this app has an existing test suite (`test/models`, `test/providers`, `test/services`) and this feature should extend it, not skip it.
**Organization**: grouped by user story so US1 (catalog) is fully shippable before US2 (stock) or US3 (alerts/valuation) exist.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- Every task names an exact file path

## Phase 1: Setup

- [x] T001 Create `specs/001-product-inventory/` docs (done: spec.md, plan.md, data-model.md, this file)
- [x] T002 [P] No new dependencies to add — confirm `pubspec.yaml` already has `isar`, `uuid`, `flutter_riverpod` (it does)

---

## Phase 2: Foundational (Blocking Prerequisites)

**No user story work can begin until this phase is complete.**

- [x] T003 Add `Product` and `StockMovement` classes (with `toJson`/`fromJson`, matching `Invoice`'s pattern) to `lib/models/models.dart`
- [x] T004 [P] Create `lib/models/stored_product.dart` (`@collection` per data-model.md), run `flutter pub run build_runner build` to generate `stored_product.g.dart`
- [x] T005 [P] Create `lib/models/stored_stock_movement.dart` (`@collection` per data-model.md), generate `stored_stock_movement.g.dart`
- [x] T006 Extend `lib/services/storage_service.dart`: add `StoredProductSchema` and `StoredStockMovementSchema` to the `Isar.open([...])` call in `init()` (depends on T004, T005)
- [x] T007 Extend `test/models/models_test.dart`: `Product`/`StockMovement` `toJson`/`fromJson` round-trip tests (depends on T003)

**Checkpoint**: Schemas exist and the app still boots (Isar re-opens with 3 collections instead of 1) — verify with `flutter test` before starting US1.

---

## Phase 3: User Story 1 - Maintain a product catalog (Priority: P1) 🎯 MVP

**Goal**: Add, edit, delete, and search products — a working price list, independent of stock/invoicing.
**Independent Test**: Add a product, edit it, search by name and SKU, delete it — no other phase required.

### Implementation for User Story 1

- [x] T010 [US1] Add `saveProduct`, `getAllProducts`, `getProduct`, `deleteProduct` methods to `lib/services/storage_service.dart` (mirrors `saveInvoice`/`getAllInvoices`/etc.), including the SKU-uniqueness check from FR-003 (depends on T006)
- [x] T011 [US1] Create `lib/providers/products_list_provider.dart` — `StateNotifier<AsyncValue<List<Product>>>`, mirrors `invoices_list_provider.dart` (depends on T010)
- [x] T012 [P] [US1] Create `lib/views/product_form_view.dart` — add/edit form (name, SKU, unit, cost price, selling price, VAT category dropdown, category, reorder threshold), reusing `AppColors`/`AppTypography` from `app_design_system.dart`
- [x] T013 [US1] Create `lib/views/products_view.dart` — list with search bar (name/SKU) and category filter/sort, using `empty_state.dart`/`shimmer_loading.dart` for empty/loading states like other list views (depends on T011)
- [x] T014 [US1] Wire a "Products" entry into `lib/views/main_tab_view.dart` navigation (same tab-based pattern as existing screens)
- [x] T015 [P] [US1] `test/providers/products_list_provider_test.dart` — add/edit/delete/duplicate-SKU-rejected cases (depends on T011)
- [x] T016 [P] [US1] `test/services/storage_service_test.dart` extension — product persistence round-trip (depends on T010)

**Checkpoint**: Products can be added, edited, deleted, searched — fully demoable without any stock feature existing yet.

---

## Phase 4: User Story 2 - Track stock levels against products (Priority: P2)

**Goal**: Restock, reduce, and adjust on-hand quantity per product, with full movement history.
**Independent Test**: With a product from US1, add stock, reduce stock, adjust stock — verify on-hand and history are correct after each.

### Implementation for User Story 2

- [ ] T020 [US2] Add `recordStockMovement`, `getStockHistory(productId)` to `lib/services/storage_service.dart`, recomputing and persisting `Product.onHandQuantity` on every write per the invariant in data-model.md (depends on T010)
- [ ] T021 [US2] Create `lib/providers/inventory_provider.dart` — exposes restock/reduce/adjust actions and refreshes `products_list_provider` after each write (depends on T020, T011)
- [ ] T022 [US2] Create `lib/views/inventory_view.dart` — per-product stock history list + restock/reduce/adjust action sheet, with the negative-stock confirmation dialog from FR-007 (depends on T021)
- [ ] T023 [US2] Add an "Inventory" action/entry point from `products_view.dart` into `inventory_view.dart` for a given product (depends on T013, T022)
- [ ] T024 [P] [US2] `test/providers/inventory_provider_test.dart` — restock/reduce/adjust/negative-stock-warning cases (depends on T021)
- [ ] T025 [P] [US2] `test/services/storage_service_test.dart` extension — stock movement persistence + on-hand recompute correctness (SC-003) (depends on T020)

**Checkpoint**: Stock can be tracked accurately end-to-end, independent of US3.

---

## Phase 5: User Story 3 - See stock health at a glance (Priority: P3)

**Goal**: Low-stock badges in the product list, plus a Dashboard low-stock count and inventory valuation.
**Independent Test**: With products at varying stock levels, verify low-stock flagging and a correct valuation total, without building anything further.

### Implementation for User Story 3

- [ ] T030 [P] [US3] Add low-stock badge rendering to `lib/views/products_view.dart` (product is low-stock when `onHandQuantity <= reorderThreshold`, per FR-012) (depends on T013, T020)
- [ ] T031 [P] [US3] Add an inventory valuation computation (sum of `onHandQuantity * costPrice`) — expose via `products_list_provider.dart` as a derived value (depends on T011, T020)
- [ ] T032 [US3] Add a low-stock count + valuation card to `lib/views/dashboard_view.dart`, following the existing `_StatCard` pattern already used there (depends on T031)
- [ ] T033 [P] [US3] `test/providers/products_list_provider_test.dart` extension — low-stock flagging and valuation-sum correctness (depends on T031)

**Checkpoint**: All 3 user stories demoable together; feature is complete for v1 scope as clarified in spec.md.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T040 [P] `flutter analyze` clean pass across all new files (match the app's current zero-warning baseline)
- [ ] T041 [P] Confirm dark-mode theming on all 3 new views uses `AppColors.*(brightness)` throughout — no hardcoded colors (this app has a known history of that specific bug class; check for it explicitly)
- [ ] T042 Manual airplane-mode pass across all 3 user stories (SC-005)

---

## Dependencies & Execution Order

- **Setup** (T001-T002): no dependencies
- **Foundational** (T003-T007): depends on Setup — blocks all user stories
- **US1** (T010-T016): depends on Foundational only
- **US2** (T020-T025): depends on Foundational + US1's `storage_service.dart`/`products_list_provider.dart` additions (T010, T011) — not on US1's UI
- **US3** (T030-T033): depends on US1's UI (T013) and US2's stock data (T020) — genuinely the last slice, matches its P3 priority
- **Polish** (T040-T042): after all desired stories are complete

## Implementation Strategy

**MVP first**: Setup → Foundational → US1 → stop, demo the catalog alone. Then US2 (stock tracking) is its own demoable slice. US3 (alerts/valuation) last — it's a thin read-only layer over US1+US2 data, lowest risk to defer if time-boxed.

## Notes

- No task touches `lib/views/invoice_form_view.dart` or the `Invoice`/`InvoiceItem` models — confirms FR-010/FR-014 (no invoice integration) stayed out of scope during breakdown, not just in the spec.
- [P] tasks within a phase touch different files; sequential tasks either share a file or have a genuine data dependency (e.g., can't write the provider before the storage method it calls exists).
