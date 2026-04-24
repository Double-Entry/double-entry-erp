---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: stock
status: complete
related_docs:
  - ./stock.md
  - ../flows/stock-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
  - ../flows/accounting-flow.md
---

# Stock DocType Reference Cards

> **TL;DR:** One card per major Stock DocType. Each card lists the file path, class/controller inheritance, the lifecycle hooks that are overridden, and the SLE + GL entry points that matter when debugging. Pair this document with [flows/stock-flow.md](../flows/stock-flow.md) (the SLE write path) and [modules/stock.md](./stock.md) (module map).

## Reading a card

- **Class** — the Python class, fully qualified.
- **Inheritance** — direct parent(s). `StockController` inherits from `AccountsController`; see [architecture/controllers.md](../architecture/controllers.md).
- **Hooks implemented** — lifecycle methods the class overrides. Everything not listed is inherited.
- **SLE entry points** — where `make_sl_entries` is called (or "none" for non-transactional DocTypes).
- **GL entry points** — if the DocType feeds the GL.
- **Notes** — behaviour worth pointing out when tracing.

---

## Stock Ledger Entry

- **File**: [stock_ledger_entry.py](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py)
- **Class**: `StockLedgerEntry(Document)` ([line 35](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:35))
- **Inheritance**: `Document` (no ERPNext controller chain)
- **Hooks implemented**:
  - `autoname` ([line 77](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:77)) — temporary hash name; renamed by scheduler job `rename_gle_sle_docs` at [hooks.py:443](erpnext/hooks.py:443).
  - `validate` ([line 86](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:86)) — frozen date, warehouse validity, group-warehouse block, backdated-entry role check, inventory dimension negative-stock guard.
  - `on_submit` ([line 174](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:174)) — `check_stock_frozen_date` + `SerialBatchBundle(sle=self, ...)` post-processing.
  - `on_cancel` ([line 345](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:345)) — **throws**: SLEs are cancelled only through voucher-level cancellation.
- **SLE / GL**: this *is* the SLE; writes are driven by `stock_ledger.make_entry` ([stock_ledger.py:197](erpnext/stock/stock_ledger.py:197)).
- **Notes**: `on_doctype_update` ([line 351](erpnext/stock/doctype/stock_ledger_entry/stock_ledger_entry.py:351)) adds `(voucher_no, voucher_type)` and `(item_code, warehouse, posting_datetime, creation)` indexes. Exempt from auto-cancel ([hooks.py:425](erpnext/hooks.py:425)).

## Bin

- **File**: [bin.py](erpnext/stock/doctype/bin/bin.py)
- **Class**: `Bin(Document)` ([line 12](erpnext/stock/doctype/bin/bin.py:12))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `before_save` ([line 61](erpnext/stock/doctype/bin/bin.py:61)) — fills `stock_uom` + recomputes `projected_qty`.
- **SLE / GL**: consumer only — Bin is a cache of SLE aggregates.
- **Key module functions**:
  - `update_qty(bin_name, args)` ([line 260](erpnext/stock/doctype/bin/bin.py:260)) — called from `stock_ledger.make_sl_entries` to bump reservation columns.
  - `get_actual_qty(item_code, warehouse)` ([line 303](erpnext/stock/doctype/bin/bin.py:303)) — last SLE's `qty_after_transaction`.
  - `on_doctype_update` ([line 238](erpnext/stock/doctype/bin/bin.py:238)) — DB-level unique(item_code, warehouse).
- **Notes**: single-doc mutation is via `frappe.db.set_value` (not through `save()`), so `before_save` rarely fires during normal SLE writes. `Bin.recalculate_qty` ([line 40](erpnext/stock/doctype/bin/bin.py:40)) is the manual rescue button.

## Serial and Batch Bundle

- **File**: [serial_and_batch_bundle.py](erpnext/stock/doctype/serial_and_batch_bundle/serial_and_batch_bundle.py)
- **Class**: `SerialandBatchBundle(Document)` ([line 56](erpnext/stock/doctype/serial_and_batch_bundle/serial_and_batch_bundle.py:56))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `autoname` ([line 91](erpnext/stock/doctype/serial_and_batch_bundle/serial_and_batch_bundle.py:91)).
  - `validate` ([line 109](erpnext/stock/doctype/serial_and_batch_bundle/serial_and_batch_bundle.py:109)) — duplicate serial-no check, batch-qty validation, voucher-no consistency, future-entry exists check.
- **SLE / GL**: not an SLE producer; feeds SLE valuation. Bundle is linked from `StockLedgerEntry.serial_and_batch_bundle` and processed by `SerialBatchBundle(sle=...)` ([serial_batch_bundle.py:17](erpnext/stock/serial_batch_bundle.py:17)) when the SLE submits.
- **Companion classes in [serial_batch_bundle.py](erpnext/stock/serial_batch_bundle.py)**:
  - `SerialBatchBundle` ([line 17](erpnext/stock/serial_batch_bundle.py:17)) — post-SLE side effects on Serial No + Batch masters.
  - `SerialNoValuation` ([line 624](erpnext/stock/serial_batch_bundle.py:624)) — per-serial incoming rate lookup.
  - `BatchNoValuation` ([line 792](erpnext/stock/serial_batch_bundle.py:792)) — per-batch moving-average rate.
  - `SerialBatchCreation` ([line 1025](erpnext/stock/serial_batch_bundle.py:1025)) — factory for new bundles (used by `StockController.create_serial_batch_bundle` and returns/transfers).
- **Errors**: `SerialNoExistsInFutureTransactionError`, `BatchNegativeStockError`, `SerialNoDuplicateError`, `SerialNoWarehouseError` ([lines 40-52](erpnext/stock/doctype/serial_and_batch_bundle/serial_and_batch_bundle.py:40)).

## Delivery Note

- **File**: [delivery_note.py](erpnext/stock/doctype/delivery_note/delivery_note.py)
- **Class**: `DeliveryNote(SellingController)` ([line 26](erpnext/stock/doctype/delivery_note/delivery_note.py:26))
- **Inheritance**: `SellingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `validate` ([line 287](erpnext/stock/doctype/delivery_note/delivery_note.py:287)) — with `so_required`, `validate_with_previous_doc`, `validate_references`, warehouse + packed qty checks; also `set_actual_qty`.
  - `onload` ([line 244](erpnext/stock/doctype/delivery_note/delivery_note.py:244)) — dashboard state.
  - `on_submit` ([line 466](erpnext/stock/doctype/delivery_note/delivery_note.py:466)) — `update_prevdoc_status` (Sales Order delivery), `update_billing_status`, `check_credit_limit` or `make_return_invoice`, SABB creation, `update_stock_reservation_entries`, `update_stock_ledger`, `make_gl_entries`, `repost_future_sle_and_gle`.
  - `on_cancel` ([line 500](erpnext/stock/doctype/delivery_note/delivery_note.py:500)) — reverse order: reservation decrement, `update_stock_ledger`, packing slip cancel, pick list status, `make_gl_entries_on_cancel`, `repost_future_sle_and_gle`, `delete_auto_created_batches`.
- **SLE entry point**: `SellingController.update_stock_ledger` ([selling_controller.py:661](erpnext/controllers/selling_controller.py:661)) → source warehouse negative SLE; target warehouse positive SLE on internal transfers.
- **GL entry point**: `StockController.make_gl_entries` → `StockController.get_gl_entries` ([stock_controller.py:685](erpnext/controllers/stock_controller.py:685)). On perpetual-inventory companies, books Stock-in-Hand (credit) → COGS (debit).
- **Notes**: On cancel, `ignore_linked_doctypes = ("GL Entry", "Stock Ledger Entry", "Repost Item Valuation", "Serial and Batch Bundle")` ([line 520](erpnext/stock/doctype/delivery_note/delivery_note.py:520)) — those are immutable and compensated by reverse entries.

## Purchase Receipt

- **File**: [purchase_receipt.py](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py)
- **Class**: `PurchaseReceipt(BuyingController)` ([line 33](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:33))
- **Inheritance**: `BuyingController → SubcontractingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `before_validate` ([line 246](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:246)).
  - `validate` ([line 253](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:253)) — CWIP accounts ([line 282](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:282)), provisional expense account, UOM integers, `validate_with_previous_doc`, `po_required`, items QI.
  - `on_submit` ([line 385](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:385)) — approving authority, `update_prevdoc_status` (PO qty), `update_billing_status`, SABB, `update_stock_ledger`, `make_gl_entries`, `repost_future_sle_and_gle`, `reserve_stock`, production-plan received qty update.
  - `on_cancel` ([line 456](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:456)) — blocks if a Purchase Invoice is already submitted against this PR ([line 461](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:461)); reverses stock and GL.
  - `before_cancel` ([line 488](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:488)) — clears `amount_difference_with_purchase_invoice`.
  - `get_gl_entries` ([line 496](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:496)) — **override**: item GL + tax GL + `set_gl_entry_for_purchase_expense` + `update_regional_gl_entries`.
- **SLE entry point**: `BuyingController.update_stock_ledger` ([buying_controller.py:736](erpnext/controllers/buying_controller.py:736)). Source warehouse `from_warehouse` SLE (internal transfer) + target warehouse SLE.
- **GL entry point**: own `get_gl_entries` plus shared items via `make_item_gl_entries` ([line 508](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:508)), `make_tax_gl_entries` ([line 894](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:894)), provisional accounting at `add_provisional_gl_entry` ([line 839](erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:839)).
- **Notes**: Landed Cost Voucher updates `item.landed_cost_voucher_amount` via `StockController.set_landed_cost_voucher_amount` ([stock_controller.py:1060](erpnext/controllers/stock_controller.py:1060)); reposting is triggered by the LCV submit. `repost_allowed_doctypes` at [hooks.py:707](erpnext/hooks.py:707) includes `Purchase Receipt`.

## Stock Entry

- **File**: [stock_entry.py](erpnext/stock/doctype/stock_entry/stock_entry.py)
- **Class**: `StockEntry(StockController, SubcontractingInwardController)` ([line 87](erpnext/stock/doctype/stock_entry/stock_entry.py:87))
- **Inheritance**: multiple — `StockController` + `SubcontractingInwardController` (for `Material Transfer (Subcontract)` / subcontracting inward flows).
- **Hooks implemented**:
  - `validate` ([line 237](erpnext/stock/doctype/stock_entry/stock_entry.py:237)) — purpose check, repack/BOM, source/target warehouse, FG completed qty, work-order status.
  - `on_submit` ([line 445](erpnext/stock/doctype/stock_entry/stock_entry.py:445)) — Work Order + Disassembled Order + Stock Reservation updates, `update_stock_ledger`, WIP/FG reserves, subcontract reserves, subcontract supplied items, `make_gl_entries`, `repost_future_sle_and_gle`, project cost, transferred qty, QI update, MR transfer status.
  - `on_cancel` ([line 474](erpnext/stock/doctype/stock_entry/stock_entry.py:474)) — mirror of submit with reversed semantics.
  - `on_update` ([line 513](erpnext/stock/doctype/stock_entry/stock_entry.py:513)).
  - `update_stock_ledger` ([line 1808](erpnext/stock/doctype/stock_entry/stock_entry.py:1808)) — **own implementation**; gathers `get_sle_for_source_warehouse` + `get_sle_for_target_warehouse`; reverses order on `docstatus == 2`.
  - `get_gl_entries` ([line 1953](erpnext/stock/doctype/stock_entry/stock_entry.py:1953)) — **override**: adds `additional_costs` expense rows.
- **SLE entry point**: own `update_stock_ledger` → `StockController.make_sl_entries`. Source warehouse SLE is always inserted first (cancel reverses).
- **GL entry point**: own `get_gl_entries`. Books Stock-in-Hand transfers on `Material Transfer`; books FG/WIP asset + COGS/Scrap on `Manufacture`.
- **Notes**: `period_closing_doctypes` ([hooks.py:327](erpnext/hooks.py:327)) — save validated against open accounting periods. `doc_events` at [hooks.py:353](erpnext/hooks.py:353) trigger `update_completed_and_requested_qty` on MR.

## Stock Reconciliation

- **File**: [stock_reconciliation.py](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py)
- **Class**: `StockReconciliation(StockController)` ([line 34](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:34))
- **Inheritance**: `StockController`
- **Hooks implemented**:
  - `validate` ([line 67](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:67)) — items exist, default expense_account / cost_center, data validation, dimension restriction (only for opening), reserved-stock check on submit.
  - `on_update` ([line 93](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:93)) — `set_serial_and_batch_bundle(ignore_validate=True)`.
  - `on_submit` ([line 108](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:108)) — bundle-for-current-qty, bundle-using-old-fields, `update_stock_ledger`, `make_gl_entries`, `repost_future_sle_and_gle`.
  - `on_cancel` ([line 115](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:115)) — reserved-stock check, `make_sle_on_cancel`, `make_gl_entries_on_cancel`, `repost_future_sle_and_gle`, delete auto-created batches.
  - `update_stock_ledger` ([line 745](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:745)) — **own implementation**; for each item row, if qty+valuation zeroed, `make_adjustment_entry`; else compute difference against previous SLE.
  - `make_adjustment_entry` ([line 814](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:814)) — sets `is_adjustment_entry=1` + precomputed `stock_value_difference`.
  - `get_sle_for_items` ([line 870](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:870)) — writes `qty_after_transaction` directly (reconciliation is absolute, not incremental).
  - `make_sle_on_cancel` ([line 928](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:928)) — both the "new" SABB and the "current" SABB SLEs, reversed.
  - `get_gl_entries` ([line 973](erpnext/stock/doctype/stock_reconciliation/stock_reconciliation.py:973)) — **override** passing `expense_account` + `cost_center` to `StockController.get_gl_entries`.
- **Notes**: Period-closing validated ([hooks.py:339](erpnext/hooks.py:339)); accounting-dimension doctype ([hooks.py:566](erpnext/hooks.py:566)). `get_stock_reco_qty_shift` ([stock_ledger.py:2111](erpnext/stock/stock_ledger.py:2111)) governs how downstream SLEs shift.

## Material Request

- **File**: [material_request.py](erpnext/stock/doctype/material_request/material_request.py)
- **Class**: `MaterialRequest(BuyingController)` ([line 31](erpnext/stock/doctype/material_request/material_request.py:31))
- **Inheritance**: `BuyingController → ...`
- **Hooks implemented**:
  - `validate` ([line 152](erpnext/stock/doctype/material_request/material_request.py:152)) — material request type, PP qty check.
  - `before_save` ([line 240](erpnext/stock/doctype/material_request/material_request.py:240)).
  - `before_submit` ([line 243](erpnext/stock/doctype/material_request/material_request.py:243)) / `before_update_after_submit` ([line 217](erpnext/stock/doctype/material_request/material_request.py:217)).
  - `on_submit` ([line 232](erpnext/stock/doctype/material_request/material_request.py:232)) — status, `update_requested_qty`, notify, `update_requested_qty_in_production_plan`.
  - `before_cancel` ([line 246](erpnext/stock/doctype/material_request/material_request.py:246)) / `on_cancel` ([line 290](erpnext/stock/doctype/material_request/material_request.py:290)).
- **SLE / GL**: none. MR only updates `Bin.indented_qty` via `update_requested_qty` ([line 380](erpnext/stock/doctype/material_request/material_request.py:380)) and `Bin.reserved_qty_for_production_plan` via production plan hooks.
- **Notes**: `update_completed_and_requested_qty` ([line 422](erpnext/stock/doctype/material_request/material_request.py:422)) is wired from Stock Entry `on_submit`/`on_cancel` via `doc_events` at [hooks.py:354](erpnext/hooks.py:354). Accounting-dimension doctype ([hooks.py:553](erpnext/hooks.py:553)).

## Pick List

- **File**: [pick_list.py](erpnext/stock/doctype/pick_list/pick_list.py)
- **Class**: `PickList(TransactionBase)` ([line 45](erpnext/stock/doctype/pick_list/pick_list.py:45))
- **Inheritance**: `TransactionBase` (not `StockController`) — Pick List does not directly write SLEs, it only reserves stock.
- **Hooks implemented**:
  - `onload` ([line 95](erpnext/stock/doctype/pick_list/pick_list.py:95)), `validate` ([line 109](erpnext/stock/doctype/pick_list/pick_list.py:109)), `before_save` ([line 116](erpnext/stock/doctype/pick_list/pick_list.py:116)), `before_submit` ([line 239](erpnext/stock/doctype/pick_list/pick_list.py:239)), `on_submit` ([line 276](erpnext/stock/doctype/pick_list/pick_list.py:276)), `on_update_after_submit` ([line 342](erpnext/stock/doctype/pick_list/pick_list.py:342)), `on_cancel` ([line 349](erpnext/stock/doctype/pick_list/pick_list.py:349)), `on_update` ([line 379](erpnext/stock/doctype/pick_list/pick_list.py:379)), `on_trash` ([line 390](erpnext/stock/doctype/pick_list/pick_list.py:390)).
- **SLE / GL**: none. On submit, makes SABBs using old serial/batch fields ([line 312](erpnext/stock/doctype/pick_list/pick_list.py:312)) and links them to the pick-list rows.
- **Errors**: `MissingWarehouseValidationError`, `IncorrectWarehouseValidationError` ([lines 34-38](erpnext/stock/doctype/pick_list/pick_list.py:34)).
- **Notes**: Plumbed into Delivery Note `on_submit` via `update_pick_list_status` ([delivery_note.py:468](erpnext/stock/doctype/delivery_note/delivery_note.py:468)).

## Packing Slip

- **File**: [packing_slip.py](erpnext/stock/doctype/packing_slip/packing_slip.py)
- **Class**: `PackingSlip(StatusUpdater)` ([line 13](erpnext/stock/doctype/packing_slip/packing_slip.py:13))
- **Inheritance**: `StatusUpdater` directly — not a stock mover.
- **Hooks implemented**:
  - `validate` ([line 60](erpnext/stock/doctype/packing_slip/packing_slip.py:60)) — delivery note consistency, case numbers, items.
  - `on_submit` ([line 73](erpnext/stock/doctype/packing_slip/packing_slip.py:73)) / `on_cancel` ([line 76](erpnext/stock/doctype/packing_slip/packing_slip.py:76)).
- **SLE / GL**: none. Cancelled from `DeliveryNote.cancel_packing_slips` ([delivery_note.py:647](erpnext/stock/doctype/delivery_note/delivery_note.py:647)) when the DN is cancelled.

## Landed Cost Voucher

- **File**: [landed_cost_voucher.py](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py)
- **Class**: `LandedCostVoucher(Document)` ([line 24](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:24))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 81](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:81)) — line items, receipt documents, expense accounts, `set_total_taxes_and_charges`, applicable-charges distribution, `validate_applicable_charges_for_item`.
  - `on_submit` ([line 291](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:291)) — `update_landed_cost` which reposts each linked receipt's stock + GL via `via_landed_cost_voucher=True`.
  - `on_cancel` ([line 296](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:296)) — reverse.
- **SLE / GL**: LCV does not write SLEs itself. It mutates `PurchaseReceiptItem.landed_cost_voucher_amount` + `valuation_rate`, then calls `make_sl_entries` + `make_gl_entries` on the receipt with `via_landed_cost_voucher=True`, which flows through a special branch in `stock_ledger.make_sl_entries` that suppresses negative-stock checks during the compensating write.
- **Errors**: `IncorrectCompanyValidationError` ([line 20](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:20)).
- **Notes**: Period-closing doctype ([hooks.py:337](erpnext/hooks.py:337)). `update_rate_in_serial_no_for_non_asset_items` ([line 392](erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:392)) pushes new valuation down into Serial No master where applicable.

## Quality Inspection

- **File**: [quality_inspection.py](erpnext/stock/doctype/quality_inspection/quality_inspection.py)
- **Class**: `QualityInspection(Document)` ([line 18](erpnext/stock/doctype/quality_inspection/quality_inspection.py:18))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 69](erpnext/stock/doctype/quality_inspection/quality_inspection.py:69)), `set_company`, `set_child_row_reference`, `validate_inspection_required`, `get_item_specification_details`.
  - `before_submit` ([line 150](erpnext/stock/doctype/quality_inspection/quality_inspection.py:150)).
  - `on_submit` ([line 193](erpnext/stock/doctype/quality_inspection/quality_inspection.py:193)) / `on_cancel` ([line 200](erpnext/stock/doctype/quality_inspection/quality_inspection.py:200)) / `on_trash` ([line 205](erpnext/stock/doctype/quality_inspection/quality_inspection.py:205)) — all call `update_qc_reference` on the linked transaction row.
  - `on_update` ([line 185](erpnext/stock/doctype/quality_inspection/quality_inspection.py:185)).
- **SLE / GL**: none. QI status is checked by `StockController.validate_inspection` ([stock_controller.py:1410](erpnext/controllers/stock_controller.py:1410)) before stock-moving transactions submit.
- **Notes**: Rejection/submission actions driven by Stock Settings (`action_if_quality_inspection_is_rejected`, `action_if_quality_inspection_is_not_submitted`). See `validate_qi_presence` / `validate_qi_submission` / `validate_qi_rejection` at [stock_controller.py:1457-1496](erpnext/controllers/stock_controller.py:1457).

## Stock Reservation Entry

- **File**: [stock_reservation_entry.py](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py)
- **Class**: `StockReservationEntry(Document)` ([line 17](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:17))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 77](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:77)) — group warehouse, mandatory fields, UOM integers, reservation-based-on, amended-doc consistency.
  - `before_submit` ([line 87](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:87)) — validate against allowed qty.
  - `on_submit` ([line 93](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:93)) — update reserved qty in voucher + pick list + bin; set status.
  - `on_update_after_submit` ([line 99](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:99)) — incremental updates on `delivered_qty` / `transferred_qty` / `consumed_qty`.
  - `on_cancel` ([line 110](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:110)) / `before_cancel` ([line 117](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:117)).
- **SLE / GL**: none. Updates `Bin.reserved_stock` via `update_reserved_stock_in_bin` ([line 523](erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py:523)).
- **Notes**: Gated by `Stock Settings.enable_stock_reservation`. Consumed by `StockController.update_stock_reservation_entries` ([stock_controller.py:1811](erpnext/controllers/stock_controller.py:1811)) and by `DeliveryNote` / `StockEntry` `on_submit`.

## Repost Item Valuation

- **File**: [repost_item_valuation.py](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py)
- **Class**: `RepostItemValuation(Document)` ([line 29](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:29))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 82](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:82)) — update-stock guard, recreate-stock-ledgers consistency, period-closing validation, accounts freeze check.
  - `on_submit` ([line 249](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:249)) — enqueue or inline-execute reposting.
  - `before_cancel` ([line 266](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:266)) — block if in-progress.
  - `on_cancel` ([line 219](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:219)), `on_trash` ([line 222](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:222)).
  - `on_discard` ([line 76](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:76)).
- **SLE / GL**: driver for both. `repost_sl_entries` ([line 450](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:450)) → `stock_ledger.repost_future_sle`. `repost_gl_entries` ([line 477](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:477)) → `repost_gle_for_stock_vouchers` (in `accounts.general_ledger`).
- **Scheduler**:
  - `run_parallel_reposting` ([line 580](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:580)) — every 30 min ([hooks.py:438](erpnext/hooks.py:438)).
  - `repost_entries` ([line 629](erpnext/stock/doctype/repost_item_valuation/repost_item_valuation.py:629)) — hourly maintenance ([hooks.py:453](erpnext/hooks.py:453)).
- **Notes**: Log clearing: 60 days ([hooks.py:693](erpnext/hooks.py:693)). Created from `StockController.repost_future_sle_and_gle` ([stock_controller.py:1745](erpnext/controllers/stock_controller.py:1745)).

## Stock Closing Entry

- **File**: [stock_closing_entry.py](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py)
- **Class**: `StockClosingEntry(Document)` ([line 16](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:16))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `before_save` ([line 36](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:36)) — `set_status`.
  - `validate` ([line 50](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:50)) — duplicate period check.
  - `on_submit` ([line 83](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:83)) — enqueue `prepare_closing_stock_balance`.
  - `on_cancel` ([line 87](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:87)) — remove the closing balance.
  - `on_discard` ([line 33](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:33)).
- **Companion**: `StockClosing` class ([line 160](erpnext/stock/doctype/stock_closing_entry/stock_closing_entry.py:160)) builds the FIFO queue snapshot via `get_stock_closing_entries` + `get_sle_entries` + `update_fifo_queue`.
- **SLE / GL**: read-only — snapshots SLE state into `Stock Closing Balance` rows. Serves as a pivot so future reposts don't need to walk beyond the closing date.

## Stock Closing Balance

- **File**: [stock_closing_balance.py](erpnext/stock/doctype/stock_closing_balance/stock_closing_balance.py)
- **Class**: `StockClosingBalance(Document)` ([line 8](erpnext/stock/doctype/stock_closing_balance/stock_closing_balance.py:8))
- **Inheritance**: `Document`
- **Hooks implemented**: none beyond schema-auto-generated typing.
- **SLE / GL**: record only — written by `StockClosingEntry.create_stock_closing_balance_entries`.
- **Notes**: per-(company, item, warehouse, closing_date) snapshot of qty + stock value + FIFO queue.

## Warehouse

- **File**: [warehouse.py](erpnext/stock/doctype/warehouse/warehouse.py)
- **Class**: `Warehouse(NestedSet)` ([line 21](erpnext/stock/doctype/warehouse/warehouse.py:21))
- **Inheritance**: Frappe's `NestedSet` (tree DocType with `lft`/`rgt`).
- **Hooks implemented**:
  - `autoname` ([line 55](erpnext/stock/doctype/warehouse/warehouse.py:55)), `onload` ([line 64](erpnext/stock/doctype/warehouse/warehouse.py:64)).
  - `validate` ([line 73](erpnext/stock/doctype/warehouse/warehouse.py:73)), `on_update` ([line 76](erpnext/stock/doctype/warehouse/warehouse.py:76)), `on_trash` ([line 82](erpnext/stock/doctype/warehouse/warehouse.py:82)).
  - `warn_about_multiple_warehouse_account` ([line 110](erpnext/stock/doctype/warehouse/warehouse.py:110)) — the warehouse-account link is expected 1:1.
- **SLE / GL**: no direct writes. Referenced from every SLE; the `account` field is the GL account for perpetual inventory (see [modules/stock.md](./stock.md#warehouse-tree)).
- **Notes**: `treeview` ([hooks.py:80](erpnext/hooks.py:80)). Warehouse → account mapping resolved by `get_warehouse_account_map` ([stock/__init__.py:19](erpnext/stock/__init__.py:19)).

## Batch

- **File**: [batch.py](erpnext/stock/doctype/batch/batch.py)
- **Class**: `Batch(Document)` ([line 90](erpnext/stock/doctype/batch/batch.py:90))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `autoname` ([line 118](erpnext/stock/doctype/batch/batch.py:118)) — from naming series / item prefix / hash.
  - `onload` ([line 146](erpnext/stock/doctype/batch/batch.py:146)), `after_delete` ([line 149](erpnext/stock/doctype/batch/batch.py:149)).
  - `validate` ([line 152](erpnext/stock/doctype/batch/batch.py:152)) — `item_has_batch_enabled`.
  - `before_save` ([line 192](erpnext/stock/doctype/batch/batch.py:192)) — `set_expiry_date`.
- **SLE / GL**: consumer. `get_batch_qty` ([line 238](erpnext/stock/doctype/batch/batch.py:238)) aggregates batch qty from SLEs at a given posting datetime.
- **Errors**: `UnableToSelectBatchError` ([line 18](erpnext/stock/doctype/batch/batch.py:18)).
- **Notes**: `use_batchwise_valuation` is set at creation by `set_batchwise_valuation` ([line 180](erpnext/stock/doctype/batch/batch.py:180)) — drives the batch-moving-average valuation branch in `process_sle`.

## Serial No

- **File**: [serial_no.py](erpnext/stock/doctype/serial_no/serial_no.py)
- **Class**: `SerialNo(StockController)` ([line 28](erpnext/stock/doctype/serial_no/serial_no.py:28))
- **Inheritance**: `StockController` — unusual; Serial No carries the controller so it inherits `validate_warehouse` + quality-inspection plumbing, but never writes SLEs directly.
- **Hooks implemented**:
  - `validate` ([line 67](erpnext/stock/doctype/serial_no/serial_no.py:67)) / `validate_warehouse` ([line 79](erpnext/stock/doctype/serial_no/serial_no.py:79)).
  - `set_maintenance_status` ([line 87](erpnext/stock/doctype/serial_no/serial_no.py:87)).
  - `on_trash` ([line 103](erpnext/stock/doctype/serial_no/serial_no.py:103)).
- **Errors**: `SerialNoCannotCreateDirectError`, `SerialNoCannotCannotChangeError`, `SerialNoWarehouseError` ([lines 16-24](erpnext/stock/doctype/serial_no/serial_no.py:16)).
- **Scheduler**: `update_maintenance_status` is the daily entry point ([hooks.py:468](erpnext/hooks.py:468)).
- **SLE / GL**: reference-data only. Warehouse/status updates are pushed from `SerialBatchBundle.set_warehouse_and_status_in_serial_nos` ([serial_batch_bundle.py:410](erpnext/stock/serial_batch_bundle.py:410)) post-SLE-submit.

## Related

- [Stock module overview](./stock.md)
- [Stock flow](../flows/stock-flow.md) — SLE write path + cancel + repost sequence diagrams.
- [Controller hierarchy](../architecture/controllers.md) — where `StockController`, `SellingController`, `BuyingController` fit.
- [DocType lifecycle](../architecture/doctype-lifecycle.md) — which hooks run in which order.
- [Accounting flow](../flows/accounting-flow.md) — GL write side (`make_gl_entries`, `process_gl_map`, `make_reverse_gl_entries`).
- [Hooks and overrides](../architecture/hooks-and-overrides.md) — for `doc_events`, `period_closing_doctypes`, `accounting_dimension_doctypes`, scheduler registrations.

## Changelog

- `2026-04-17` — initial version.
