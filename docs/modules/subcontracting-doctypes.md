---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: subcontracting
status: complete
related_docs:
  - ./subcontracting.md
  - ../flows/subcontracting-flow.md
  - ./buying-doctypes.md
  - ./stock-doctypes.md
  - ../flows/buying-flow.md
  - ../flows/stock-flow.md
  - ../flows/accounting-flow.md
  - ../architecture/controllers.md
---

# Subcontracting DocType reference cards

> **TL;DR:** One card per DocType that participates in either the legacy PO/PR-embedded subcontracting flow or the new Subcontracting Order / Receipt flow, including the inward customer-provided pattern. Each card lists file path, controller inheritance, lifecycle hooks, key status-updater rows, SLE and GL entry points, and cross-links to [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) for the end-to-end cascade.

## Scope of this document

- **Covered here:** `Subcontracting Order`, `Subcontracting Receipt`, `Subcontracting BOM`, `Subcontracting Inward Order` and their child tables; legacy `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied` (cross-link to [buying-doctypes.md](./buying-doctypes.md)); Stock Entry subcontracting purposes (cross-link to [stock-doctypes.md](./stock-doctypes.md)).
- **Not covered here:** controller-level reference ([subcontracting.md](./subcontracting.md)); end-to-end cascade ([subcontracting-flow.md](../flows/subcontracting-flow.md)); Purchase Order / Purchase Invoice cards ([buying-doctypes.md](./buying-doctypes.md)).

## Index

| DocType | Flow | Role | Card |
|---|---|---|---|
| Subcontracting Order | New | Execution order (cut from PO) | [#subcontracting-order](#subcontracting-order) |
| Subcontracting Order Item | New | FG items child table on SCO | [#subcontracting-order-item](#subcontracting-order-item) |
| Subcontracting Order Service Item | New | Service items child table on SCO | [#subcontracting-order-service-item](#subcontracting-order-service-item) |
| Subcontracting Order Supplied Item | New | Raw-material tracking on SCO | [#subcontracting-order-supplied-item](#subcontracting-order-supplied-item) |
| Subcontracting Receipt | New | FG receipt (posts SLE + GL) | [#subcontracting-receipt](#subcontracting-receipt) |
| Subcontracting Receipt Item | New | FG items child table on SCR | [#subcontracting-receipt-item](#subcontracting-receipt-item) |
| Subcontracting Receipt Supplied Item | New | Consumed raw materials on SCR | [#subcontracting-receipt-supplied-item](#subcontracting-receipt-supplied-item) |
| Subcontracting BOM | Both | FG ↔ service item binding | [#subcontracting-bom](#subcontracting-bom) |
| Subcontracting Inward Order | Inward | Customer-provided inward order | [#subcontracting-inward-order](#subcontracting-inward-order) |
| Purchase Order Item Supplied | Legacy | Raw-material tracking on legacy PO | [#purchase-order-item-supplied-legacy](#purchase-order-item-supplied-legacy) |
| Purchase Receipt Item Supplied | Legacy | Consumed raw materials on legacy PR | [#purchase-receipt-item-supplied-legacy](#purchase-receipt-item-supplied-legacy) |
| Stock Entry (subcontracting purposes) | Both | Send to Subcontractor etc. | [#stock-entry-subcontracting-purposes](#stock-entry-subcontracting-purposes) |

## Subcontracting Order

- **File**: [erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:20)
- **Naming series**: `SC-ORD-.YYYY.-`
- **Controller**: `SubcontractingOrder(SubcontractingController)` — skips `BuyingController`.
- **Submittable**: yes.
- **Status literal**: `Draft`, `Open`, `Partially Received`, `Completed`, `Material Transferred`, `Partial Material Transferred`, `Cancelled`, `Closed` ([subcontracting_order.py:69](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:69)).
- **Child tables**: `items` → Subcontracting Order Item; `service_items` → Subcontracting Order Service Item; `supplied_items` → Subcontracting Order Supplied Item; `additional_costs` → Landed Cost Taxes and Charges.
- **Parent link**: `purchase_order` (mandatory).

### Lifecycle

| Hook | Method | Line | Summary |
|---|---|---|---|
| `onload` | `onload` | [:92](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:92) | Surface `over_transfer_allowance`, `over_delivery_receipt_allowance`, `backflush_based_on`, reservation flags. |
| `before_validate` | `before_validate` | [:113](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:113) | Delegates to `SubcontractingController.before_validate` → trims empty rows, sets `conversion_factor=1`. |
| `validate` | `validate` | [:116](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:116) | `super().validate()` explodes BOM into `supplied_items` via `create_raw_materials_supplied_or_received`; then `validate_purchase_order_for_subcontracting` (rejects legacy-flow PO / unsubmitted PO / fully-received PO), `validate_items`, `validate_service_items`, `validate_supplied_items`, `set_missing_values`. |
| `on_submit` | `on_submit` | [:125](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:125) | `update_status` (recomputes Bin: `ordered_qty`, `reserved_qty_for_sub_contracting`), `update_subcontracted_quantity_in_po` (bumps `PO Item.subcontracted_qty`), `reserve_raw_materials` (if `reserve_stock=1`). |
| `on_cancel` | `on_cancel` | [:130](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:130) | `update_status` → `Cancelled`, `update_subcontracted_quantity_in_po(cancel=True)`. |

### Key methods

- [`populate_items_table`](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:230) — invoked by the PO → SCO mapper `post_process` ([purchase_order.py:960](../../erpnext/buying/doctype/purchase_order/purchase_order.py:960)). For each service item, resolves `fg_item` → BOM via active `Subcontracting BOM` (or `Item.default_bom`), appends `items` row.
- [`calculate_items_qty_and_amount`](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:197) — `item.rate = rm_cost_per_qty + service_cost_per_qty + additional_cost_per_qty`.
- [`update_status`](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:292) — derives status from `per_received` + supplied-qty totals; optionally recomputes Bin.
- [`reserve_raw_materials`](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:347) — creates Stock Reservation Entries against RM reserve warehouses; supports Production Plan hand-off.

### Entry points (external callers)

- [make_subcontracting_order (from PO)](../../erpnext/buying/doctype/purchase_order/purchase_order.py:915) — whitelisted mapper invoked from PO form or auto via `auto_create_subcontracting_order`.
- [make_subcontracting_receipt (from SCO)](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:433) — whitelisted mapper invoked from SCO form ("Create Subcontracting Receipt" button).
- [make_rm_stock_entry](../../erpnext/controllers/subcontracting_controller.py:1381) — builds Send-to-Subcontractor Stock Entry from SCO supplied items.
- [get_materials_from_supplier](../../erpnext/controllers/subcontracting_controller.py:1572) — builds RM-return Stock Entry from SCO available materials.

### SLE / GL

- **No direct SLE or GL on SCO** — the SCO is a planning / commitment document. SLE flows through the Send-to-Subcontractor Stock Entry and the downstream Subcontracting Receipt.
- Bin impact: `ordered_qty`, `reserved_qty_for_sub_contracting` only (via `update_status`).

## Subcontracting Order Item

- **File**: [erpnext/subcontracting/doctype/subcontracting_order_item/subcontracting_order_item.py](../../erpnext/subcontracting/doctype/subcontracting_order_item/subcontracting_order_item.py:8)
- **Role**: FG items on SCO.
- **Key fields**: `item_code` (FG), `qty`, `received_qty`, `returned_qty`, `bom`, `rate`, `rm_cost_per_qty`, `service_cost_per_qty`, `additional_cost_per_qty`, `warehouse`, `purchase_order_item`, `material_request_item`, `production_plan_sub_assembly_item`, `job_card`, `subcontracting_conversion_factor`, `include_exploded_items`.
- **Status-updater target**: `received_qty` + `per_received` (via `Subcontracting Receipt Item` → this row). See [subcontracting_receipt.py:101](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:101).

## Subcontracting Order Service Item

- **File**: [erpnext/subcontracting/doctype/subcontracting_order_service_item/subcontracting_order_service_item.py](../../erpnext/subcontracting/doctype/subcontracting_order_service_item/subcontracting_order_service_item.py:8)
- **Role**: Non-stock service items mapped 1:1 from `Purchase Order Item`.
- **Key fields**: `item_code` (service item, non-stock), `fg_item`, `qty`, `fg_item_qty`, `rate`, `amount`, `purchase_order_item`, `material_request_item`.
- **Validation**: `Item.is_stock_item` must be 0 — enforced in [SubcontractingOrder.validate_service_items](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:163).

## Subcontracting Order Supplied Item

- **File**: [erpnext/subcontracting/doctype/subcontracting_order_supplied_item/subcontracting_order_supplied_item.py](../../erpnext/subcontracting/doctype/subcontracting_order_supplied_item/subcontracting_order_supplied_item.py:8)
- **Role**: Raw materials planned to be supplied per FG. Exploded from BOM during SCO validate via `SubcontractingController.create_raw_materials_supplied_or_received`.
- **Key fields**: `rm_item_code`, `main_item_code` (FG), `bom_detail_no`, `required_qty`, `supplied_qty`, `total_supplied_qty`, `consumed_qty`, `returned_qty`, `stock_reserved_qty`, `reserve_warehouse`, `rate`, `amount`, `reference_name` (parent FG item row).
- **Written by**:
  - `create_raw_materials_supplied_or_received` at SCO validate.
  - [StockEntry.update_subcontract_order_supplied_items](../../erpnext/stock/doctype/stock_entry/stock_entry.py:3532) on Send-to-Subcontractor / Material-Transfer-return submit → `supplied_qty`, `returned_qty`, `total_supplied_qty`.
  - [SubcontractingController.set_consumed_qty_in_subcontract_order](../../erpnext/controllers/subcontracting_controller.py:1137) on SCR submit → `consumed_qty`.

## Subcontracting Receipt

- **File**: [erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:28)
- **Naming series**: `MAT-SCR-.YYYY.-` / `MAT-SCR-RET-.YYYY.-`.
- **Controller**: `SubcontractingReceipt(SubcontractingController)` — skips `BuyingController`.
- **Submittable**: yes.
- **Status literal**: `Draft`, `Completed`, `Return`, `Return Issued`, `Cancelled`, `Closed` ([subcontracting_receipt.py:85](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:85)).
- **Child tables**: `items` → Subcontracting Receipt Item; `supplied_items` → Subcontracting Receipt Supplied Item; `additional_costs` → Landed Cost Taxes and Charges.
- **Parent link**: `items[].subcontracting_order` (per row).

### `__init__.status_updater`

One row ([:101](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:101)):

| source_dt | target_dt | join_field | target_field | target_parent_dt / field |
|---|---|---|---|---|
| `Subcontracting Receipt Item` | `Subcontracting Order Item` | `subcontracting_order_item` | `received_qty` | `Subcontracting Order` / `per_received` |

On `is_return=1`, `update_status_updater_args` ([:649](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:649)) adds two more rows: SCO Item `returned_qty` and SCR Item `returned_qty + per_returned`.

### Lifecycle

| Hook | Method | Line | Summary |
|---|---|---|---|
| `onload` | `onload` | [:116](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:116) | Surface `backflush_based_on`. |
| `before_validate` | `before_validate` | [:122](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:122) | `validate_items_qty`, `set_items_bom`, `set_items_cost_center`, `set_service_expense_account`, `set_expense_account_for_subcontracted_items`. |
| `validate` | `validate` | [:135](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:135) | `reset_supplied_items` (BOM-mode re-explosion), `super().validate()` (supplied-items build + `set_valuation_rate_for_rm`), `get_secondary_items`, `set_missing_values`, warehouse validations, supplied-item cost-center + expense-account defaults. |
| `on_submit` | `on_submit` | [:164](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:164) | `validate_closed_subcontracting_order`, `validate_available_qty_for_consumption`, `validate_bom_required_qty`, `update_status_updater_args`, `update_prevdoc_status`, `set_subcontracting_order_status`, `set_consumed_qty_in_subcontract_order`, serial-batch bundles, SRE updates, `update_stock_ledger`, `make_gl_entries`, `repost_future_sle_and_gle`, `update_status`, `auto_create_purchase_receipt`, `update_job_card`. |
| `on_update` | `on_update` | [:184](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:184) | `set_serial_and_batch_bundle` for both `items` and `supplied_items`. |
| `on_cancel` | `on_cancel` | [:189](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:189) | Ignore GL/SLE/SABB links; reverse status updater; reverse consumed/received on SCO; reverse SLE; `make_gl_entries_on_cancel`; repost; `update_status → Cancelled`; `delete_auto_created_batches`; `update_job_card`. |

### SLE (via `SubcontractingController.update_stock_ledger` at [:1197](../../erpnext/controllers/subcontracting_controller.py:1197))

Per FG `items` row:

1. Inward at `item.warehouse` with `actual_qty = qty × conversion_factor`, `incoming_rate = item.rate`, `recalculate_rate=1`.
2. Rejected inward at `item.rejected_warehouse` with `incoming_rate=0` (non-return) — adjusted by rejected-rate settings.

Per supplied-item row (via `make_sl_entries_for_supplier_warehouse` at [:1179](../../erpnext/controllers/subcontracting_controller.py:1179)):

3. Negative at `self.supplier_warehouse` with `actual_qty = -consumed_qty`, `incoming_rate = item.rate if is_return else 0`, `dependant_sle_voucher_detail_no = reference_name`.

### GL (via `get_gl_entries` at [:701](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:701))

Per FG item row:

- **Accepted Warehouse Account** (Debit) = `stock_value_difference` from SLE.
- **Expense Account** (Credit) = `stock_value_diff − service_cost`.
- **Service Expense Account** (Credit) = `service_cost_per_qty × qty`.
- For each supplied-item under this row:
  - **Supplier Warehouse Account** (Credit) = `rm_item.amount`.
  - **Expense Account** (Debit) = `rm_item.amount`.
- **Expense Account** (Debit) = `qty × additional_cost_per_qty` (if any).
- **Stock Adjustment** / **Expense** pair for divisional loss `= item.amount − stock_value_diff`.

Per `additional_costs` row: credit `expense_account` for `base_amount` (or `amount` when same currency).

LCV contras via `make_item_gl_entries_for_lcv` at [:903](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:903).

### Entry points

- [make_subcontracting_receipt (from SCO)](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:433).
- [make_subcontract_return](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:977), [make_subcontract_return_against_rejected_warehouse](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:970).
- [make_purchase_receipt (SCR → PR)](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:984) — invoked directly on form and from `auto_create_purchase_receipt` at [:954](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:954).
- [reset_raw_materials](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:209) — whitelisted; clears + re-explodes `supplied_items`.
- [get_secondary_items](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:347) — whitelisted; adds scrap / by-product rows.

## Subcontracting Receipt Item

- **File**: [erpnext/subcontracting/doctype/subcontracting_receipt_item/subcontracting_receipt_item.py](../../erpnext/subcontracting/doctype/subcontracting_receipt_item/subcontracting_receipt_item.py:8)
- **Role**: FG / scrap / by-product items received.
- **Key fields**: `item_code`, `qty`, `received_qty`, `rejected_qty`, `process_loss_qty`, `returned_qty`, `rate`, `rm_cost_per_qty`, `service_cost_per_qty`, `additional_cost_per_qty`, `secondary_items_cost_per_qty`, `rm_supp_cost`, `warehouse`, `rejected_warehouse`, `expense_account`, `service_expense_account`, `cost_center`, `bom`, `include_exploded_items`, `subcontracting_order`, `subcontracting_order_item`, `purchase_order`, `purchase_order_item`, `type` (one of `""`, `Co-Product`, `By-Product`, `Scrap`, `Additional Finished Good`), `is_legacy_scrap_item`, `reference_name` (parent FG row for secondary items), `landed_cost_voucher_amount`, `job_card`, `quality_inspection`.
- **Cost formula** (main FG rows): `rate = rm_cost_per_qty + service_cost_per_qty + additional_cost_per_qty + (lcv_amount / qty)` ([subcontracting_receipt.py:511](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:511)), with BOM `cost_allocation_per` applied per-row.

## Subcontracting Receipt Supplied Item

- **File**: [erpnext/subcontracting/doctype/subcontracting_receipt_supplied_item/subcontracting_receipt_supplied_item.py](../../erpnext/subcontracting/doctype/subcontracting_receipt_supplied_item/subcontracting_receipt_supplied_item.py:8)
- **Role**: Raw materials consumed per FG row at SCR submit.
- **Key fields**: `rm_item_code`, `main_item_code` (FG), `bom_detail_no`, `consumed_qty`, `required_qty`, `rate`, `amount`, `available_qty_for_consumption`, `current_stock`, `batch_no`, `serial_no`, `serial_and_batch_bundle`, `use_serial_batch_fields`, `reference_name` (parent FG row), `subcontracting_order`, `expense_account`, `cost_center`.
- **Written by**:
  - `__add_supplied_or_received_item` during `create_raw_materials_supplied_or_received` at SCR validate.
  - `set_valuation_rate_for_rm` at [subcontracting_controller.py:79](../../erpnext/controllers/subcontracting_controller.py:79) — pulls fresh rate from `supplier_warehouse` via `get_incoming_rate`.
  - `set_rate_for_supplied_items` at [subcontracting_controller.py:836](../../erpnext/controllers/subcontracting_controller.py:836) — same but with the bundle already attached.

## Subcontracting BOM

- **File**: [erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:10)
- **Role**: Binding between a finished-good stock item and its service (non-stock) item + the BOM used to explode raw materials.
- **Submittable**: no (plain Document).
- **Key fields**: `finished_good` (stock item, subcontracted), `finished_good_qty`, `finished_good_uom`, `finished_good_bom` (exploded for RM at SCO validate), `service_item` (non-stock), `service_item_qty`, `service_item_uom`, `conversion_factor` (auto = `service_item_qty / finished_good_qty`), `is_active`.
- **Validate rules**:
  - `finished_good` must not be disabled, must be stock item, must be sub-contracted item, must have a `default_bom` ([:38](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:38)).
  - `service_item` must not be disabled and must be non-stock ([:58](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:58)).
  - Only one active SCBOM per `finished_good` ([:70](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:70)).
- **`before_save`**: `set_conversion_factor` ([:82](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:82)).

### Module-level helpers

- [`get_subcontracting_boms_for_finished_goods(fg_items)`](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:86) — one or many FG items → active SCBOM records. Used by [PurchaseOrder.set_service_items_for_finished_goods](../../erpnext/buying/doctype/purchase_order/purchase_order.py:601) to auto-fill the service line on PO, and by [SubcontractingOrder.populate_items_table](../../erpnext/subcontracting/doctype/subcontracting_order/subcontracting_order.py:254) to resolve the FG BOM.
- [`get_subcontracting_boms_for_service_item(service_item)`](../../erpnext/subcontracting/doctype/subcontracting_bom/subcontracting_bom.py:105) — reverse lookup for service → FG resolution.

## Subcontracting Inward Order

- **File**: [erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:14)
- **Naming series**: `SCI-ORD-.YYYY.-`.
- **Controller**: `SubcontractingInwardOrder(SubcontractingController)` — branches inside `SubcontractingController.__init__` at [:39](../../erpnext/controllers/subcontracting_controller.py:39) to `scio_detail` / `Subcontracting Inward Order` field names; does **not** reuse the outward supplied-items child tables.
- **Submittable**: yes.
- **Status literal**: `Draft`, `Open`, `Ongoing`, `Produced`, `Delivered`, `Returned`, `Cancelled`, `Closed` ([:55](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:55)).
- **Child tables**: `items` (FG), `service_items`, `received_items` (customer-provided RMs), `secondary_items` (scrap / by-products).
- **Parent link**: `sales_order` (mandatory), `customer` + `customer_warehouse`.

### Lifecycle

| Hook | Method | Line | Summary |
|---|---|---|---|
| `validate` | `validate` | [:64](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:64) | `super().validate()` (BOM explosion into `received_items` via `create_raw_materials_supplied_or_received`), `set_is_customer_provided_item`, `validate_customer_provided_items` (≥1 customer-provided RM per FG), `validate_customer_warehouse`, `validate_service_items`, `set_missing_values`. |
| `on_submit` | `on_submit` | [:72](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:72) | `update_status`, `update_subcontracted_quantity_in_so` (`SO Item.subcontracted_qty +=`). |
| `on_cancel` | `on_cancel` | [:76](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:76) | `update_status`, `update_subcontracted_quantity_in_so` (minus on cancel). |

### Status computation

`update_status` ([:80](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:80)) writes six percent fields:

- `per_raw_material_received`, `per_raw_material_returned`
- `per_produced`, `per_process_loss`
- `per_delivered`, `per_returned`

And derives status via ladder `Open → Ongoing → Produced → Delivered → Returned`.

### Entry points

- [make_work_order](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:237) — whitelisted; creates one Work Order per FG row.
- [make_rm_stock_entry_inward](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:325) — Stock Entry with `purpose="Receive from Customer"`.
- [make_rm_return](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:388) — Stock Entry with `purpose="Return Raw Material to Customer"`.
- [make_subcontracting_delivery](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:429) — Stock Entry with `purpose="Subcontracting Delivery"`.
- [make_subcontracting_return](../../erpnext/subcontracting/doctype/subcontracting_inward_order/subcontracting_inward_order.py:507) — Stock Entry with `purpose="Subcontracting Return"`.

### Child tables (high level)

- **Subcontracting Inward Order Item** — FG items with `qty`, `produced_qty`, `process_loss_qty`, `delivered_qty`, `returned_qty`, `sales_order_item`, `delivery_warehouse`, `bom`, `include_exploded_items`, `subcontracting_conversion_factor`.
- **Subcontracting Inward Order Service Item** — service-item 1:1 mirror of Sales Order service rows.
- **Subcontracting Inward Order Received Item** — customer-provided RMs: `rm_item_code`, `main_item_code`, `required_qty`, `received_qty`, `returned_qty`, `work_order_qty`, `process_loss_qty`, `is_customer_provided_item`, `bom_detail_no`, `reference_name` (FG row).
- **Subcontracting Inward Order Secondary Item** — scrap / by-product FG companions: `item_code`, `type`, `required_qty`, `produced_qty`, `delivered_qty`, `reference_name` (FG row).

### SLE / GL

- **No direct SLE or GL** on the inward order itself. All movement is driven by the Stock Entries created via the four `make_*` helpers; production happens via Work Orders.

## Purchase Order Item Supplied (legacy)

- **File**: [erpnext/buying/doctype/purchase_order_item_supplied/purchase_order_item_supplied.py](../../erpnext/buying/doctype/purchase_order_item_supplied/purchase_order_item_supplied.py:8)
- **Role**: Raw-material tracking on a PO with `is_subcontracted=1 + is_old_subcontracting_flow=1`.
- **Parent**: Purchase Order.
- **Key fields**: `rm_item_code`, `main_item_code` (FG item), `bom_detail_no`, `required_qty`, `supplied_qty`, `total_supplied_qty`, `consumed_qty`, `returned_qty`, `reserve_warehouse`, `rate`, `amount`, `reference_name` (parent PO-Item row).
- **Written by**:
  - [PurchaseOrder.validate](../../erpnext/buying/doctype/purchase_order/purchase_order.py:217) → `create_raw_materials_supplied` when `is_old_subcontracting_flow` → `SubcontractingController.create_raw_materials_supplied_or_received`.
  - [StockEntry.update_subcontract_order_supplied_items](../../erpnext/stock/doctype/stock_entry/stock_entry.py:3532) on Send-to-Subcontractor / Material-Transfer-return submit.
  - [SubcontractingController.set_consumed_qty_in_subcontract_order](../../erpnext/controllers/subcontracting_controller.py:1137) on PR submit.

See also [modules/buying-doctypes.md](./buying-doctypes.md) for the cross-referenced card in the buying module.

## Purchase Receipt Item Supplied (legacy)

- **File**: [erpnext/buying/doctype/purchase_receipt_item_supplied/purchase_receipt_item_supplied.py](../../erpnext/buying/doctype/purchase_receipt_item_supplied/purchase_receipt_item_supplied.py)
- **Role**: Raw-material consumption tracking on a PR with `is_subcontracted=1 + is_old_subcontracting_flow=1` (also PI with `update_stock=1`).
- **Parent**: Purchase Receipt (or Purchase Invoice).
- **Key fields**: `rm_item_code`, `main_item_code`, `bom_detail_no`, `consumed_qty`, `required_qty`, `rate`, `amount`, `reference_name`, plus serial/batch companions.
- **Written by**:
  - [BuyingController.validate](../../erpnext/controllers/buying_controller.py:62) → `create_raw_materials_supplied` on PR / PI with `is_old_subcontracting_flow`.
- **Consumed by**:
  - [BuyingController.update_valuation_rate](../../erpnext/controllers/buying_controller.py:478) → `get_supplied_items_cost` folds each row's `amount` into the FG `valuation_rate`.
  - [BuyingController.make_sl_entries_for_supplier_warehouse](../../erpnext/controllers/buying_controller.py:871) → negative SLE per supplied row at `supplier_warehouse`.
  - [PurchaseReceipt.make_sub_contracting_gl_entries](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:677) → credits supplier-warehouse GL account for `rm_supp_cost`.

See also [modules/buying-doctypes.md](./buying-doctypes.md).

## Stock Entry (subcontracting purposes)

- **File**: [erpnext/stock/doctype/stock_entry/stock_entry.py](../../erpnext/stock/doctype/stock_entry/stock_entry.py:133)
- **Purpose literal (subcontracting-relevant subset)**: `Send to Subcontractor`, `Receive from Customer`, `Return Raw Material to Customer`, `Subcontracting Delivery`, `Subcontracting Return`.
- **Subcontracting link fields**: `subcontracting_order`, `subcontracting_inward_order`, `purchase_order` (legacy flow).

### Subcontracting purposes

| Purpose | Direction | Source | Target | Order field used |
|---|---|---|---|---|
| `Send to Subcontractor` | Outward → supplier | Reserve warehouse | `supplier_warehouse` | `purchase_order` (legacy) / `subcontracting_order` (new) |
| `Receive from Customer` | Inward ← customer | (none) | `customer_warehouse` on SCIO | `subcontracting_inward_order` |
| `Return Raw Material to Customer` | Outward → customer | `customer_warehouse` | (none) | `subcontracting_inward_order` |
| `Subcontracting Delivery` | Outward → customer | `delivery_warehouse` | (none) | `subcontracting_inward_order` |
| `Subcontracting Return` | Inward ← customer | (none) | (none) | `subcontracting_inward_order` |

Plus: `Material Transfer` with `is_return=1` + a subcontracting order link is the **RM return path** from supplier back to reserve (invoked via [get_materials_from_supplier](../../erpnext/controllers/subcontracting_controller.py:1572) → [make_return_stock_entry_for_subcontract](../../erpnext/controllers/subcontracting_controller.py:1525)).

### Hooks that fire on subcontracting-purpose Stock Entries

- [`update_subcontract_order_supplied_items`](../../erpnext/stock/doctype/stock_entry/stock_entry.py:3532) — on `purpose in ("Send to Subcontractor", "Material Transfer")` or `is_return=1` against a subcontract order.
- [`update_subcontracting_order_status`](../../erpnext/stock/doctype/stock_entry/stock_entry.py:3731) — on `Send to Subcontractor` / `Material Transfer` with `subcontracting_order` set; cascades to SCO status.
- [`reserve_stock_for_subcontracting`](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2150) — on `Send to Subcontractor` with SCO `reserve_stock=1`; transforms reserve-warehouse SREs into supplier-warehouse SREs via `SubcontractingOrder.reserve_raw_materials`.

See [modules/stock-doctypes.md](./stock-doctypes.md) for the full Stock Entry card.

## Related

- [modules/subcontracting.md](./subcontracting.md) — module overview and `SubcontractingController` responsibilities.
- [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) — end-to-end submit / cancel cascades, both flows.
- [modules/buying-doctypes.md](./buying-doctypes.md) — full buying DocType reference incl. Purchase Order / Purchase Receipt / legacy supplied-items.
- [modules/stock-doctypes.md](./stock-doctypes.md) — Stock Entry reference card.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL composition for SCR + legacy PR.
- [flows/stock-flow.md](../flows/stock-flow.md) — SLE writer, `update_entries_after`, Bin updates.
- [architecture/controllers.md](../architecture/controllers.md) — where `SubcontractingController` sits.

## Changelog

- `2026-04-17` — initial version.
