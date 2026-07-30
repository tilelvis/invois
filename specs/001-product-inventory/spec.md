# Feature Specification: Products & Inventory Management

**Created**: 2026-07-29
**Status**: Clarified
**Input**: User description: "Products Module (SKU, barcode, unit, cost price, selling price, VAT, category, stock alerts, search/filter/sorting) and Inventory (add/reduce/adjust stock, transfers, history/audit trail, low stock alerts, inventory valuation)" — Phases 6 & 7 of the Invois Production Build Plan v1.0, combined into one feature since inventory has no meaning without a product catalog to track.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Maintain a product catalog (Priority: P1)

A business owner adds the goods or services they sell — name, SKU, unit, cost price, selling price, VAT category, and category tag — so they exist as reusable, searchable entries instead of being retyped on every invoice.

**Why this priority**: Nothing else in this feature (stock tracking, alerts, valuation) has meaning without products to track. This alone is already useful: a searchable price list a business can maintain, independent of invoicing.

**Independent Test**: Add a product with all fields, edit it, search for it by name and by SKU, delete it. No invoice or inventory feature needs to exist for this to be fully testable and useful.

**Acceptance Scenarios**:

1. **Given** the Products screen is empty, **When** the user adds a product with name, unit, cost price, selling price, and VAT category, **Then** it appears in the product list immediately, available offline.
2. **Given** an existing product, **When** the user edits its selling price, **Then** the updated price is reflected in the product list and in any future invoice line pulled from it (past invoices are unaffected — see FR-010).
3. **Given** a product list of 200+ items, **When** the user searches by partial name or exact SKU, **Then** matching products appear as they type.
4. **Given** an attempt to add a second product with a SKU that already exists, **When** the user saves, **Then** the system blocks the save and shows which product already uses that SKU.

---

### User Story 2 - Track stock levels against products (Priority: P2)

A business owner records stock coming in (purchases/restocks) and going out (sales outside of invoicing, spoilage, correction), so the app always reflects an accurate on-hand quantity per product.

**Why this priority**: Builds directly on P1's catalog. Valuable as its own slice — a business can track stock accurately even before any alerting or invoice-integration exists on top of it.

**Independent Test**: With a product already in the catalog, add stock, reduce stock, and make a manual adjustment (e.g. correcting a miscount) — verify the on-hand quantity updates correctly after each, and that every movement is visible in that product's history.

**Acceptance Scenarios**:

1. **Given** a product with 0 stock, **When** the user adds 50 units via a "restock" entry, **Then** on-hand quantity becomes 50 and a stock-history entry is recorded with the date, quantity, and reason.
2. **Given** a product with 50 units, **When** the user records a reduction of 10 units with a reason, **Then** on-hand quantity becomes 40 and the reduction is logged.
3. **Given** a product with 40 units, **When** the user makes a manual adjustment to set stock to 35 (correcting a physical count mismatch), **Then** on-hand becomes 35 and the history shows the adjustment distinctly from ordinary in/out movements.
4. **Given** a reduction request larger than current stock, **When** the user submits it, **Then** the system warns that this will take stock negative and requires explicit confirmation before proceeding (never silently blocks or silently allows).

---

### User Story 3 - See stock health at a glance (Priority: P3)

A business owner sees, without hunting through every product, which items are low on stock and what their total inventory is currently worth.

**Why this priority**: Genuinely useful, but it's a read-only lens over data already captured in P1/P2 — nothing breaks or becomes untestable if this ships later or even not at all for a first release.

**Independent Test**: With a mix of products at various stock levels (some below their reorder point, some not), verify low-stock items are visually distinguished in the product list and a computed inventory valuation is shown, without needing to build anything else.

**Acceptance Scenarios**:

1. **Given** a product with a configured reorder threshold, **When** its stock falls to or below that threshold, **Then** it's visually flagged as low-stock in the product list.
2. **Given** a set of products with varying stock levels and cost prices, **When** the user views inventory valuation, **Then** the total shown equals the sum of (on-hand quantity × cost price) across all products.

---

### Edge Cases

- What happens when a product referenced by a past invoice is later deleted? (Resolved by FR-010: past invoices keep their own snapshot of name/price and are unaffected.)
- How does the system handle a stock reduction that would take a product negative? (Resolved by Acceptance Scenario 2.4 — warn and require confirmation, never silent.)
- What happens when two products are given the same SKU? (Resolved by Acceptance Scenario 1.4 — blocked with a clear message.)
- What happens to stock history if the app is closed mid-entry? (Resolved by FR-011 — entries are only recorded on explicit save, matching the rest of the app's offline-first save behavior.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow creating a product with: name, SKU (optional but unique if provided), unit label (free text, e.g. "pcs", "kg", "litre"), cost price, selling price, VAT category, and category tag.
- **FR-002**: System MUST allow editing and deleting a product.
- **FR-003**: System MUST prevent saving a product whose SKU duplicates another product's SKU, and MUST identify the conflicting product to the user.
- **FR-004**: System MUST support searching the product list by name (partial match) and SKU (exact or partial match).
- **FR-005**: System MUST support filtering and sorting the product list by category and by stock level.
- **FR-006**: System MUST allow recording a stock increase ("restock") against a product, with a quantity and an optional note.
- **FR-007**: System MUST allow recording a stock decrease against a product, with a quantity, a reason, and MUST warn (requiring explicit confirmation) if the reduction would take on-hand stock negative.
- **FR-008**: System MUST allow a manual stock adjustment that sets on-hand quantity directly (for correcting physical-count mismatches), distinct in the history from ordinary increase/decrease entries.
- **FR-009**: System MUST maintain a per-product history of all stock movements (type, quantity, resulting on-hand total, timestamp, optional note), viewable from that product.
- **FR-010**: Invoices MUST continue to store their own snapshot of item name/price at time of invoicing (per existing `InvoiceItem` model) and MUST NOT be affected by later edits or deletion of a product — this feature does not change past-invoice behavior.
- **FR-011**: All product and stock operations MUST work fully offline and persist locally, consistent with the rest of the app (Isar-backed, no network dependency).
- **FR-012**: System MUST flag a product as low-stock in the product list once its on-hand quantity is at or below a per-product reorder threshold (optional field; products without a configured threshold are never flagged).
- **FR-013**: System MUST compute and display total inventory valuation as the sum of (on-hand quantity × cost price) across all products.
- **FR-014**: Invoice creation remains exactly as it is today (freeform line items, no product picker) for this feature. Products and Inventory form a standalone catalog/ledger in v1 — no auto-fill from a product onto an invoice line, and no automatic stock deduction when an invoice is saved. Stock is adjusted only through the Inventory screens (FR-006/FR-007/FR-008). Tighter invoice integration is explicitly deferred, not rejected — worth a follow-up feature once this standalone version is in use.
- **FR-015**: Inventory is scoped to a single business location for v1 — one on-hand quantity per product, no transfer-between-locations concept. Multi-location support is out of scope for this feature.
- **FR-016**: Low-stock indication is passive only: a visual badge/highlight on the affected product in the product list, plus a low-stock count surfaced on the Dashboard. No push/local notifications — avoids notification-permission requests and related Play Store review surface area for this feature.

### Key Entities *(include only if the feature involves data)*

- **Product**: A catalog item the business sells. Attributes: id, name, SKU (optional, unique), unit label, cost price, selling price, VAT category, category tag, current on-hand quantity (derived from stock history, not directly editable), optional reorder threshold.
- **StockMovement**: A single recorded change to a product's on-hand quantity. Attributes: id, product reference, type (restock / reduction / adjustment), quantity delta, resulting on-hand total, optional note/reason, timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can add a new product and have it appear, searchable, in under 5 seconds of interaction (matching the existing app's "instant" feel elsewhere).
- **SC-002**: A user can find any product in a 200-item catalog by typing 2-3 characters of its name or SKU, with results updating as they type.
- **SC-003**: Stock on-hand always exactly matches the sum of all recorded movements for that product — no drift, checkable at any time by summing a product's history.
- **SC-004**: A user can identify which products need reordering without opening each product individually — visible from the product list itself.
- **SC-005**: Everything in this feature works with the device in airplane mode, with zero functional difference from being online (consistent with the rest of Invois).

## Assumptions

- Invois remains single-user/single-business per install for this feature (no per-user attribution on stock movements) — consistent with the app's current lack of any login/multi-user system.
- "Barcode" scanning hardware/camera integration is out of scope for this feature; a barcode/SKU value is a plain text field a user can type or paste. Actual scan-to-fill is listed separately as a v1.1 nice-to-have in the broader build plan.
- VAT category on a Product reuses the existing `VatCategory` enum (`standard16`, `zeroRated`, `exempt`) already defined for invoice items — no new tax logic is introduced.
- Product and stock data follow the app's existing Isar storage pattern: a thin `@collection` wrapper with a few indexed scalar fields (for search/sort) plus a serialized JSON blob for the full record, matching `StoredInvoice`.
- This spec does not include CSV/Excel import or export of the product catalog — not requested in the original plan for this phase and would be a separate, independently-testable story if wanted later.
