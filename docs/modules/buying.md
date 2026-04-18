---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: buying
status: complete
related_docs:
  - ../architecture/overview.md
  - ../architecture/controllers.md
  - ../flows/buying-flow.md
  - ../flows/accounting-flow.md
  - ../flows/stock-flow.md
  - ./buying-doctypes.md
---

# Buying Module

> **TL;DR:** The Buying module owns pre-receipt documents (`Request for Quotation`, `Supplier Quotation`, `Purchase Order`), the Supplier master and its ecosystem (`Supplier Group`, `Supplier Scorecard` + its 5 sub-doctypes), the buying-side settings (`Buying Settings`), and the `BuyingController` that underpins every buying-side transaction (MR / RFQ / SQ / PO / PR / PI). Buying code is thin on bookkeeping — it delegates GL to the Accounts module and SLE to the Stock module. What is **unique** here is the qty / amount cascade across the buying chain, supplier-scorecard gating, item-rate memory (`last_purchase_rate`), valuation-rate composition (`net_rate + item_tax + LCV + rm_supp_cost`), asset auto-creation, subcontracting-supplied-items (via the `SubcontractingController` parent), drop-ship PO → SO delivery writeback, internal-transfer `sales_incoming_rate` handling, and Landed Cost Voucher revaluation. Pair this document with [flows/buying-flow.md](../flows/buying-flow.md) (end-to-end MR → PO → PR → PI cascade) and [modules/buying-doctypes.md](./buying-doctypes.md) (per-DocType reference cards).

## Scope of this document

- **Covered here:** module layout, `BuyingController` responsibilities, what `SubcontractingController` contributes, Buying Settings knobs, Supplier + Supplier Scorecard, buying-side scheduler jobs, reports, Website/portal integration, regional hooks.
- **Covered elsewhere:** MR → RFQ → SQ → PO → PR → PI cascade ([flows/buying-flow.md](../flows/buying-flow.md)); GL writes on PI / PR submit ([flows/accounting-flow.md](../flows/accounting-flow.md)); SLE on PR submit + LCV revaluation ([flows/stock-flow.md](../flows/stock-flow.md)); taxes ([flows/taxes-and-totals.md](../flows/taxes-and-totals.md)); Payment Entry / payment schedule ([flows/payments-flow.md](../flows/payments-flow.md)). Per-DocType hooks → [modules/buying-doctypes.md](./buying-doctypes.md). PI accounting detail → [modules/accounts-doctypes.md#purchase-invoice](./accounts-doctypes.md#purchase-invoice).

## Directory layout

```
erpnext/buying/
├── __init__.py
├── doctype/                 # Buying-owned DocTypes (see below)
├── report/                  # ~20 buying reports
├── dashboard_chart/
├── buying_dashboard/
├── number_card/
├── onboarding_step/
├── module_onboarding/
├── page/
├── print_format/
├── print_format_field_template/
├── form_tour/
├── workspace/
├── utils.py                 # update_last_purchase_rate, validate_for_items, check_on_hold_or_closed_status, get_linked_material_requests
└── README.md
```

The buying DocTypes (in `erpnext/buying/doctype/`):

- Transactional: `request_for_quotation`, `request_for_quotation_item`, `request_for_quotation_supplier`, `supplier_quotation`, `supplier_quotation_item`, `purchase_order`, `purchase_order_item`, `purchase_order_item_supplied`, `purchase_receipt_item_supplied`.
- Masters: `supplier`, `customer_number_at_supplier`.
- Supplier Scorecard: `supplier_scorecard`, `supplier_scorecard_criteria`, `supplier_scorecard_period`, `supplier_scorecard_scoring_criteria`, `supplier_scorecard_scoring_standing`, `supplier_scorecard_scoring_variable`, `supplier_scorecard_standing`, `supplier_scorecard_variable`.
- Settings: `buying_settings`.

Note: several DocTypes that are logically "buying" live in other modules:

- `Material Request` → `erpnext/stock/doctype/material_request/` (shared across Purchase / Manufacture / Material Transfer / Material Issue / Subcontracting / Customer Provided — it writes `Bin.indented_qty`). See [modules/stock-doctypes.md#material-request](./stock-doctypes.md#material-request).
- `Purchase Receipt` → `erpnext/stock/doctype/purchase_receipt/` (because it writes SLEs and inherits `BuyingController`). See [modules/stock-doctypes.md#purchase-receipt](./stock-doctypes.md#purchase-receipt).
- `Purchase Invoice`, `Purchase Invoice Item`, `Purchase Invoice Advance` → `erpnext/accounts/doctype/` (GL side). See [modules/accounts-doctypes.md](./accounts-doctypes.md).
- `Purchase Taxes and Charges Template` / `Purchase Taxes and Charges` → `erpnext/accounts/doctype/`.
- `Pricing Rule`, `Promotional Scheme`, `Shipping Rule` → `erpnext/accounts/doctype/`. See [modules/selling-doctypes.md](./selling-doctypes.md) (Pricing Rule card covers both `selling=1` and `buying=1` flags).
- `Landed Cost Voucher`, `Landed Cost Item`, `Landed Cost Taxes and Charges`, `Landed Cost Purchase Receipt` → `erpnext/stock/doctype/landed_cost_voucher/`. See [modules/stock-doctypes.md#landed-cost-voucher](./stock-doctypes.md#landed-cost-voucher).
- `Supplier Group` → `erpnext/setup/doctype/supplier_group/`.
- `Subcontracting Order`, `Subcontracting Receipt`, `Subcontracting BOM` → `erpnext/subcontracting/doctype/`. See [modules/subcontracting.md](./subcontracting.md) for the module overview, [modules/subcontracting-doctypes.md](./subcontracting-doctypes.md) for per-DocType cards, and [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) for the end-to-end cascade.
- `Blanket Order` → `erpnext/manufacturing/doctype/blanket_order/` (shared with Sales Order).

## `BuyingController`

File: [erpnext/controllers/buying_controller.py](../../erpnext/controllers/buying_controller.py:29). Position in the chain:

```
Document → StatusUpdater → TransactionBase → AccountsController → StockController → SubcontractingController → BuyingController
```

See [architecture/controllers.md](../architecture/controllers.md) for the full hierarchy.

Consumers (direct subclasses):

- [MaterialRequest](../../erpnext/stock/doctype/material_request/material_request.py:31)
- [RequestforQuotation](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:26)
- [SupplierQuotation](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:19)
- [PurchaseOrder](../../erpnext/buying/doctype/purchase_order/purchase_order.py:36)
- [PurchaseReceipt](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:33)
- [PurchaseInvoice](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:54)

### Responsibilities

`BuyingController.validate` ([buying_controller.py:33](../../erpnext/controllers/buying_controller.py:33)) runs **before** its subclasses' own `validate`:

| Method | Purpose | Line |
|---|---|---|
| `set_rate_for_standalone_debit_note` | For `is_return=1 + update_stock=1 + no return_against`, auto-fills item `rate` from `get_incoming_rate` (valuation rate) and zeroes discounts / margin. | [183](../../erpnext/controllers/buying_controller.py:183) |
| `validate_items` | `is_purchase_item=1` check (or `is_sub_contracted_item=1` for legacy subcontract) via `validate_item_type`; skipped for Material Request. | [1194](../../erpnext/controllers/buying_controller.py:1194) |
| `set_qty_as_per_stock_uom` | `stock_qty = qty × conversion_factor`; also `received_stock_qty`. `Stock Settings.allow_to_edit_stock_uom_qty_for_purchase` toggles override. | [658](../../erpnext/controllers/buying_controller.py:658) |
| `validate_stock_or_nonstock_items` | If all items are non-stock, rewrites `Valuation` / `Valuation and Total` tax rows to `Total` category. | [256](../../erpnext/controllers/buying_controller.py:256) |
| `validate_warehouse` | Inherited (StockController) — ensures each stock item has a warehouse. | — |
| `validate_from_warehouse` | `from_warehouse ≠ warehouse`; bans `from_warehouse` when `is_subcontracted=1`. | [298](../../erpnext/controllers/buying_controller.py:298) |
| `set_supplier_address` | Fills `address_display`, `shipping_address_display`, `dispatch_address_display`, `billing_address_display` via `render_address`. | [316](../../erpnext/controllers/buying_controller.py:316) |
| `validate_asset_return` | Rejects a return PR/PI when submitted Assets are linked to `return_against`. | [272](../../erpnext/controllers/buying_controller.py:272) |
| `validate_auto_repeat_subscription_dates` | (inherited plumbing reused). | — |
| `create_package_for_transfer` | Internal-transfer PR/PI: clone the DN's Serial and Batch Bundle as the outgoing package at `from_warehouse`. | [131](../../erpnext/controllers/buying_controller.py:131) |
| `validate_purchase_receipt_if_update_stock` (PI) | Throws if `update_stock=1` and any item references an existing PR. | (on PI, via [purchase_invoice.py:730](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:730)) |
| **PR / PI with stock-impact branch** (from [buying_controller.py:53](../../erpnext/controllers/buying_controller.py:53)): | | |
| `validate_purchase_return` | Clears `rejected_warehouse` on non-rejected return rows. | [687](../../erpnext/controllers/buying_controller.py:687) |
| `validate_rejected_warehouse` | (inherited from SubcontractingController) — rejected qty requires a rejected warehouse; disallows same as warehouse. | [subcontracting_controller.py:111](../../erpnext/controllers/subcontracting_controller.py:111) |
| `validate_accepted_rejected_qty` | Enforces `received_qty == qty + rejected_qty` per row. | [693](../../erpnext/controllers/buying_controller.py:693) |
| `validate_for_items` (module-level, buying/utils.py) | Refreshes `projected_qty`, validates `is_stock_item` vs warehouse, `end_of_life`, duplicate-item check (gated by `Buying Settings.allow_multiple_items`). | [buying/utils.py:49](../../erpnext/buying/utils.py:49) |
| `validate_for_subcontracting` | Legacy flow: `supplier_warehouse` mandatory on PR/PI, BOM mandatory per item, reserve warehouse mandatory per supplied item. | [628](../../erpnext/controllers/buying_controller.py:628) |
| `create_raw_materials_supplied` | Legacy flow: build `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied` rows from BOM explosion. Delegated to `SubcontractingController.create_raw_materials_supplied_or_received`. | [buying_controller.py:62](../../erpnext/controllers/buying_controller.py:62) → [subcontracting_controller.py:1112](../../erpnext/controllers/subcontracting_controller.py:1112) |
| `set_landed_cost_voucher_amount` | Pulls aggregated LCV amount per item row from `Landed Cost Item` (invoked via `LandedCostVoucher.update_landed_cost`). | (inherited) |
| **PR + PI branch** (from [buying_controller.py:65](../../erpnext/controllers/buying_controller.py:65)): | | |
| `update_valuation_rate` | Distributes valuation taxes + item-tax across rows; computes `item.valuation_rate = (net_rate + item_tax_amount + landed_cost_voucher_amount + amount_difference_with_purchase_invoice + rm_supp_cost) / qty_in_stock_uom`. Calls `@allow_regional update_regional_item_valuation_rate(doc)`. | [403](../../erpnext/controllers/buying_controller.py:403) |
| `set_serial_and_batch_bundle` | (inherited) — attach SABB to items; respects `Stock Settings.use_serial_batch_fields`. | — |

### `set_missing_values`

[buying_controller.py:208](../../erpnext/controllers/buying_controller.py:208) — runs:

1. `super().set_missing_values()` — inherited through `AccountsController` → `TransactionBase`.
2. `set_supplier_from_item_default` — if supplier is blank, pulls from `Item Default.default_supplier` (item-level first, then item-group).
3. `set_price_list_currency("Buying")` — sets `buying_price_list` currency and the company's `plc_conversion_rate`.
4. `get_party_details(supplier, party_type="Supplier", ...)` — populates address, contact, payment terms, taxes-and-charges template via [accounts/party.py](../../erpnext/accounts/party.py).
5. `set_missing_item_details(for_validate)` — inherited.
6. Taxes auto-fetch: if `taxes_and_charges` is set but no tax rows exist yet, pull from the linked `Purchase Taxes and Charges Template`.

### `set_incoming_rate` (PR / PI only)

[buying_controller.py:545](../../erpnext/controllers/buying_controller.py:545) — only active when `is_internal_transfer()` is True (internal supplier with linked DN / SI):

- Skips returns (outgoing rate is derived differently for returns).
- Writes `item.sales_incoming_rate` via [set_sales_incoming_rate_for_internal_transfer](../../erpnext/controllers/buying_controller.py:586): either the DN Item / SI Item `incoming_rate` × conversion_factor, or recomputed via `get_incoming_rate` at the source warehouse.
- Unless `Stock Settings.allow_internal_transfer_at_arms_length_price=1`, **overrides** `item.rate` with `sales_incoming_rate`, zeroing `discount_percentage`, `discount_amount`, `margin_rate_or_amount` — so the valuation stays consistent across the internal transfer.

See [flows/stock-flow.md](../flows/stock-flow.md) for the SLE writer and [flows/accounting-flow.md](../flows/accounting-flow.md) for the GL bridge.

### `update_stock_ledger` (PR / PI-with-update_stock)

[buying_controller.py:736](../../erpnext/controllers/buying_controller.py:736) — the SLE write path for buying-side inward moves:

1. `update_ordered_and_reserved_qty` ([:906](../../erpnext/controllers/buying_controller.py:906)) — re-aggregates `Bin.ordered_qty` and `reserved_qty_for_sub_contract` on the linked PO.
2. Per item:
   - Normal flow: one **inward** SLE at `d.warehouse` with `incoming_rate = d.valuation_rate`.
   - If `d.from_warehouse` (internal transfer): one **outward** SLE at the source warehouse first, with `outgoing_rate = d.rate`.
   - If `d.rejected_qty`: one inward SLE at `d.rejected_warehouse` (at `valuation_rate` if `set_valuation_rate_for_rejected_materials=1`, else 0).
   - On cancel (`docstatus=2`): type_of_transaction flips to Outward; source-warehouse SLE comes last.
   - Return flow: `outgoing_rate` comes from `get_rate_for_return` (mirrors original item cost).
3. Legacy subcontracting: `make_sl_entries_for_supplier_warehouse` ([:871](../../erpnext/controllers/buying_controller.py:871)) posts a dummy outward SLE at `supplier_warehouse` for consumed raw materials.
4. Calls `make_sl_entries` on `StockController`, which funnels to module-level `stock.stock_ledger.make_sl_entries`.

### `on_submit` / `on_cancel`

[BuyingController.on_submit](../../erpnext/controllers/buying_controller.py:932) — common post-submit for PO / PR / PI:

- Skip for `is_return=1`.
- PR / PI: `process_fixed_asset` ([:989](../../erpnext/controllers/buying_controller.py:989)) — if any item is a fixed asset, auto-create `Asset` records via `auto_make_assets` ([:997](../../erpnext/controllers/buying_controller.py:997)).
- PO / PR / PI: `update_last_purchase_rate(is_submit=1)` ([buying/utils.py:14](../../erpnext/buying/utils.py:14)) — writes `Item.last_purchase_rate` (skipped if `Buying Settings.disable_last_purchase_rate` or `Supplier.is_internal_supplier`).

[BuyingController.on_cancel](../../erpnext/controllers/buying_controller.py:946) — reverses: `update_last_purchase_rate(is_submit=0)`, `delete_linked_asset` + `update_fixed_asset(delete_asset=True)` for PR / PI.

### Fixed-asset auto-creation

On PR submit (or PI submit with `update_stock=1`), [auto_make_assets](../../erpnext/controllers/buying_controller.py:997) iterates items with `is_fixed_asset=1` and, if the Item has `auto_create_assets=1` + `asset_naming_series`, creates one `Asset` doc per qty (or one grouped asset if `is_grouped_asset=1`). `purchase_amount = valuation_rate × asset_quantity`. Accounting dimensions are inherited from the PR item / parent.

### Purchase Expense (contra) GL

[set_gl_entry_for_purchase_expense](../../erpnext/controllers/buying_controller.py:330) — per item, posts a pair of GL entries: `purchase_expense_account` (debit) against `purchase_expense_contra_account` (credit) at `valuation_rate × stock_qty`. Accounts resolved via [get_purchase_expense_account](../../erpnext/controllers/buying_controller.py:1264) — Item Default → Item Group Default → Item Brand Default. Called from `PurchaseReceipt.get_gl_entries` ([purchase_receipt.py:503](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:503)).

## What `SubcontractingController` contributes

File: [erpnext/controllers/subcontracting_controller.py](../../erpnext/controllers/subcontracting_controller.py:26). It sits between `StockController` and `BuyingController` and is the parent for both the legacy subcontracting flow (driven through PO/PR) and the new flow's own DocTypes (`Subcontracting Order`, `Subcontracting Receipt`, `Subcontracting Inward Order`).

What `SubcontractingController` contributes **to the buying chain**:

- **`__init__.subcontract_data`** ([subcontracting_controller.py:27](../../erpnext/controllers/subcontracting_controller.py:27)) — sets field-name constants for legacy (`order_doctype='Purchase Order'`, `order_supplied_items_field='Purchase Order Item Supplied'`, `receipt_supplied_items_field='Purchase Receipt Item Supplied'`) vs new (`order_doctype='Subcontracting Order'`, `sco_rm_detail`, `Subcontracting Order Supplied Item`).
- **Supplied-items build** — `set_materials_for_subcontracted_items` + `create_raw_materials_supplied_or_received` ([:1112](../../erpnext/controllers/subcontracting_controller.py:1112)) explode BOM to fill the `supplied_items` child table.
- **Raw-material cost attribution** — `get_supplied_items_cost(item_row_id)` ([:1239](../../erpnext/controllers/subcontracting_controller.py:1239)) computes `rm_supp_cost` per PR / PI item, which feeds into `BuyingController.update_valuation_rate` at [:478](../../erpnext/controllers/buying_controller.py:478).
- **Rejected-warehouse validation** — `validate_rejected_warehouse` at [:111](../../erpnext/controllers/subcontracting_controller.py:111).
- **Valuation rate for raw material** at Subcontracting Receipt — `set_valuation_rate_for_rm` ([:79](../../erpnext/controllers/subcontracting_controller.py:79)) — re-calls `get_incoming_rate` against the supplier warehouse.

The full subcontracting flow (SCO → raw-material Stock Entry → Subcontracting Receipt) is a separate topic — see [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) for the end-to-end cascade (legacy PO/PR-embedded and new SCO/SCR flows), [modules/subcontracting.md](./subcontracting.md) for `SubcontractingController` method-level responsibilities, and [modules/subcontracting-doctypes.md](./subcontracting-doctypes.md) for per-DocType reference cards.

## Supplier master

[Supplier](../../erpnext/buying/doctype/supplier/supplier.py:23) inherits from `TransactionBase`, **not** `BuyingController` — masters don't go through the transactional chain.

Key hooks:

- `autoname` ([supplier.py:100](../../erpnext/buying/doctype/supplier/supplier.py:100)) — switches on `supp_master_name` default (`Supplier Name` / `Naming Series` / `Auto Name`) set in Buying Settings.
- `validate` ([supplier.py:137](../../erpnext/buying/doctype/supplier/supplier.py:137)) — naming-series mandatory check, `validate_party_accounts`, `validate_internal_supplier` (one internal supplier per represented Company), `validate_currency_for_receivable_payable_and_advance_account`, `add_role_for_user` (grants `Supplier` role to linked portal users).
- `before_save` ([supplier.py:89](../../erpnext/buying/doctype/supplier/supplier.py:89)) — if `on_hold=0`, clears `hold_type` + `release_date`; if `on_hold=1` without `hold_type`, defaults to `All`.
- `on_update` ([supplier.py:109](../../erpnext/buying/doctype/supplier/supplier.py:109)) — creates primary address + primary contact.
- `on_trash` ([supplier.py:208](../../erpnext/buying/doctype/supplier/supplier.py:208)) — cascades `delete_contact_and_address`.
- `before_rename` / `after_rename` — handles currency-before-merging validation and `supplier_name` sync.

### Supplier flags that gate transactions

| Field | Consumer | Effect |
|---|---|---|
| `disabled` | PO / RFQ / SQ validate | Supplier cannot be used. |
| `on_hold` + `hold_type` (`All` / `Invoices` / `Payments`) + `release_date` | PI `invoice_is_blocked` + Payment Entry allocation | Blocks PI submit / payment. |
| `prevent_pos` | `PurchaseOrder.validate_supplier` | Throws with Scorecard standing reason. |
| `warn_pos` | `PurchaseOrder.validate_supplier` | Warn-level msgprint with scorecard standing. |
| `prevent_rfqs` | `RequestforQuotation.validate_supplier_list` | Throws. |
| `warn_rfqs` | `RequestforQuotation.validate_supplier_list` | Warn. |
| `is_internal_supplier` + `represents_company` | Inter-company flow | Ties this supplier to a mirror company for auto-created PO / PI from SI / SO. |
| `is_transporter` | Delivery Trip / LR No integration | Supplier can be selected as a transporter. |
| `tax_withholding_category` / `tax_withholding_group` | PI on_submit → `PurchaseTaxWithholding` | Auto-computes WHT accruals. |
| `allow_purchase_invoice_creation_without_purchase_order` / `...without_purchase_receipt` | PI `po_required` / `pr_required` | Per-supplier override of global Buying Settings enforcement. |

## Supplier Scorecard

Tracks supplier performance over time and feeds the `prevent_pos` / `warn_pos` / `prevent_rfqs` / `warn_rfqs` gating.

Structure:

- `Supplier Scorecard` ([supplier_scorecard.py:18](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:18)) — one per Supplier. Holds `period` (Per Week / Per Month / Per Year), weighting function, current `supplier_score` + `status`, gating flags (`prevent_pos`, `warn_pos`, `prevent_rfqs`, `warn_rfqs`).
- `Supplier Scorecard Period` — one per evaluation window; generated by the scheduler when a period has elapsed.
- `Supplier Scorecard Criteria` — weighted criteria (Delivery, Quality, Response Time, …) with a formula referencing Variables.
- `Supplier Scorecard Variable` — metric formulas (e.g. `total_ontime_shipments / total_shipments`).
- `Supplier Scorecard Standing` — score → standing bands (e.g. `0-60 = Poor → prevent_pos`).
- `Supplier Scorecard Scoring Criteria` / `...Scoring Variable` / `...Scoring Standing` — per-period snapshots.

Lifecycle:

- `Supplier Scorecard.validate` ([:51](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:51)) — weight sum check, standing non-overlap check, score calc, standing update.
- `Supplier Scorecard.on_update` ([:57](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:57)) — re-runs `make_all_scorecards` (period generation + scoring).
- Scheduler: `refresh_scorecards` ([:183](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:183)) runs daily ([hooks.py:469](../../erpnext/hooks.py:469)) to close elapsed periods and propagate the new standing.

## Buying Settings

File: [buying_settings.py](../../erpnext/buying/doctype/buying_settings/buying_settings.py:11). A Single DocType (one row).

Key knobs wired into controllers and flows:

| Flag | Consumer | Effect |
|---|---|---|
| `supp_master_name` | `Supplier.autoname` | Supplier naming strategy. |
| `supplier_group` | Defaults for new Supplier. | — |
| `buying_price_list` | Defaults on PO / SQ / PR / PI / MR. | — |
| `po_required` (Yes/No) | `PurchaseInvoice.po_required` ([:272](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:272)) | Enforces PO-before-PI for non-internal-transfer PI. |
| `pr_required` (Yes/No) | `PurchaseInvoice.pr_required` ([:638](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:638)) | Enforces PR-before-PI for non-internal-transfer PI. |
| `maintain_same_rate` | `PurchaseOrder.validate_with_previous_doc` ([:276](../../erpnext/buying/doctype/purchase_order/purchase_order.py:276)) + `PurchaseReceipt.validate_with_previous_doc` ([:324](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:324)) | Forces PO rate = SQ rate, PR rate = PO rate. |
| `maintain_same_rate_action` (`Stop` / `Warn`) | Same | Escalation. |
| `role_to_override_stop_action` | Same | Per-role override for `Stop`. |
| `allow_multiple_items` | `validate_for_items` ([buying/utils.py:62](../../erpnext/buying/utils.py:62)) | Allows same item on multiple rows. |
| `allow_zero_qty_in_purchase_order` / `..._supplier_quotation` / `..._request_for_quotation` | `set_has_unit_price_items` on each of those DocTypes | "Unit price" rows (qty=0 placeholders). |
| `disable_last_purchase_rate` | `BuyingController.on_submit` / `on_cancel` | Skips `Item.last_purchase_rate` update. |
| `auto_create_purchase_receipt` | — | `TODO(verify)` where the auto-create-PR-from-PO wiring consumes this flag. |
| `auto_create_subcontracting_order` | `PurchaseOrder.auto_create_subcontracting_order` ([:646](../../erpnext/buying/doctype/purchase_order/purchase_order.py:646)) | Auto-cuts a Subcontracting Order on PO submit (new flow). |
| `backflush_raw_materials_of_subcontract_based_on` (`BOM` / `Material Transferred for Subcontract`) | Subcontracting flow | How consumed raw-material qty is computed. Surfaced via `onload` at [buying_controller.py:73](../../erpnext/controllers/buying_controller.py:73). |
| `bill_for_rejected_quantity_in_purchase_invoice` | `update_billing_percentage` ([purchase_receipt.py:1287](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:1287)) + `PurchaseInvoice.validate` | Includes rejected qty in PI `billed_amt` base; toggles `set_valuation_rate_for_rejected_materials` dependency. |
| `set_valuation_rate_for_rejected_materials` | `BuyingController.update_valuation_rate` + SLE writer ([:853](../../erpnext/controllers/buying_controller.py:853)) | Post rejected qty SLE at `valuation_rate` (otherwise at 0). |
| `set_landed_cost_based_on_purchase_invoice_rate` | `BuyingController.update_valuation_rate` via `amount_difference_with_purchase_invoice` | Reconciles PR valuation to PI rate when PI posts a different amount. Mutually exclusive with `maintain_same_rate` ([buying_settings.py:69](../../erpnext/buying/doctype/buying_settings/buying_settings.py:69)). |
| `blanket_order_allowance` | `validate_against_blanket_order` (shared with selling) | % over-booking allowance against Blanket Order. |
| `over_transfer_allowance` | Subcontracting raw-material transfer | Allowance on transferred-qty vs required. |
| `project_update_frequency` (`Each Transaction` / `Manual`) | `PurchaseInvoice.on_submit` ([:790](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:790)) | Gates real-time Project cost sync. |
| `use_transaction_date_exchange_rate` | FX handling | Uses `transaction_date` rate instead of `posting_date` rate. |
| `validate_consumed_qty` | Subcontracting flow | Strict consumed-qty vs required check. |
| `show_pay_button` | Portal UI | Toggles pay button on portal supplier invoices. |
| `fixed_email` | RFQ emails | Fixed sender address. |

`BuyingSettings.validate` ([:50](../../erpnext/buying/doctype/buying_settings/buying_settings.py:50)) persists several flags as `frappe.db.defaults` (`supplier_group`, `supp_master_name`, `maintain_same_rate`, `buying_price_list`) and toggles the `Supplier` naming-series field hidden state via `set_by_naming_series`.

## Scheduler jobs

From [hooks.py:433](../../erpnext/hooks.py:433):

- **Daily** (`scheduler_events.daily_maintenance` at [hooks.py:462](../../erpnext/hooks.py:462)):
  - `erpnext.buying.doctype.supplier_scorecard.supplier_scorecard.refresh_scorecards` ([hooks.py:469](../../erpnext/hooks.py:469)) — closes elapsed scorecard periods, recomputes scores, updates standings and `prevent_pos` / `warn_pos` flags.
  - `erpnext.buying.doctype.supplier_quotation.supplier_quotation.set_expired_status` ([hooks.py:481](../../erpnext/hooks.py:481)) — flips `valid_till < today` SQs to `Expired`.
  - `erpnext.stock.reorder_item.reorder_item` ([hooks.py:486](../../erpnext/hooks.py:486)) — auto-creates Material Requests for items below reorder level. MR is the buying entry point.
  - `erpnext.controllers.accounts_controller.update_invoice_status` ([hooks.py:465](../../erpnext/hooks.py:465)) — refreshes Purchase Invoice status (`Overdue` / `Paid`) from outstanding + due date.

Doc events: `Stock Entry.on_submit` / `on_cancel` → `material_request.update_completed_and_requested_qty` at [hooks.py:353](../../erpnext/hooks.py:353) — completes Material Requests used for Material Transfer / Issue / Customer Provided.

## Reports

From `erpnext/buying/report/`. Notable:

- `purchase_analytics` — grouped totals across Supplier / Item / Item Group / Territory.
- `purchase_order_analysis` / `purchase_order_trends` / `supplier_quotation_comparison` — pipeline & trend dashboards.
- `procurement_tracker` — PO / PR / PI completion sheet.
- `quoted_item_comparison` — SQ rate comparison across suppliers for one item.
- `requested_items_to_order_and_receive` / `material_requests_for_which_supplier_quotations_are_not_created` — MR follow-through.
- `supplier_wise_sales_analytics` — supplier billing trends.
- `subcontracted_raw_materials_to_be_transferred` / `subcontracted_item_to_be_received` — subcontracting tracking.

From `erpnext/accounts/report/` (buying-related):

- `accounts_payable` / `accounts_payable_summary` — AP aging from PI.
- `purchase_register` — PI register with tax breakup.
- `item_wise_purchase_register` — item-wise PI breakdown.

From `erpnext/stock/report/` (buying-related):

- `purchase_receipt_trends` — PR trends.
- `supplier_wise_item_price` — Item Supplier pricing.

## Website integration

From [hooks.py](../../erpnext/hooks.py):

- **Website routes** ([hooks.py:137](../../erpnext/hooks.py:137)): `/supplier-quotations`, `/purchase-orders`, `/purchase-invoices`, `/rfq`, `/material-requests` render portal-list views for supplier users.
- **Website permissions** ([hooks.py:308](../../erpnext/hooks.py:308)): SQ, PO, PI use `erpnext.controllers.website_list_for_contact.has_website_permission`.
- **Portal menu** ([hooks.py:232](../../erpnext/hooks.py:232)): `Request for Quotations`, `Supplier Quotation`, `Purchase Orders`, `Purchase Invoices`, `Material Request` appear under the portal sidebar with role filtering.
- **Global search** ([hooks.py:636](../../erpnext/hooks.py:636)): Supplier index 1, PO 11, PR 12, PI 13, MR 16.
- **Supplier portal flow** — RFQ email links to `/rfq/{name}`; supplier submits a Supplier Quotation via `make_supplier_quotation_from_rfq` whitelisted endpoint. PI from the portal uses `make_purchase_invoice_from_portal` ([purchase_order.py:783](../../erpnext/buying/doctype/purchase_order/purchase_order.py:783)) with a `Portal User` permission check against the supplier.

## Regional hooks touching buying

From `doc_events` at [hooks.py:384](../../erpnext/hooks.py:384) and `regional_overrides` at [hooks.py:608](../../erpnext/hooks.py:608):

- **United Arab Emirates** ([hooks.py:610](../../erpnext/hooks.py:610)):
  - `erpnext.accounts.doctype.purchase_invoice.purchase_invoice.make_regional_gl_entries` → `erpnext.regional.united_arab_emirates.utils.make_regional_gl_entries` — RCM GL lines (reverse-charge VAT) for PI submit.
  - `erpnext.controllers.taxes_and_totals.update_itemised_tax_data` → UAE VAT variant — item-wise VAT breakdown for PI.
  - `Purchase Invoice.validate` → `update_grand_total_for_rcm` + `validate_returns` ([hooks.py:384](../../erpnext/hooks.py:384)).
- **Saudi Arabia** ([hooks.py:614](../../erpnext/hooks.py:614)): shares the UAE `update_itemised_tax_data` variant.
- **Italy** ([hooks.py:617](../../erpnext/hooks.py:617)): no dedicated buying override — the `update_itemised_tax_data` regional hook covers PI item-wise tax when Italian localization is active. Italy e-invoicing inbound (XML-FatturaPA parsing into PI) is **not** wired through `regional_overrides`; it lives as a standalone DocType `Import Supplier Invoice` ([regional/doctype/import_supplier_invoice/import_supplier_invoice.py:19](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:19)). Entry is the whitelisted `process_file_data` ([:158](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:158)) which enqueues `import_xml_data` ([:46](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:46)) on the `long` queue; the worker parses each XML with BeautifulSoup, upserts Suppliers and Addresses, then calls `create_purchase_invoice` ([:355](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:355)) to insert a **draft** PI per invoice with the original XML attached. Full sequence and field mapping: [modules/regional.md](./regional.md#italy) and [modules/regional-doctypes.md](./regional-doctypes.md#import-supplier-invoice).
- **Generic PR/PI valuation hook**: `update_regional_item_valuation_rate(doc)` at [buying_controller.py:1258](../../erpnext/controllers/buying_controller.py:1258) is decorated `@erpnext.allow_regional` but has **no registered country override** in core at this commit ([hooks.py:608](../../erpnext/hooks.py:608) has no mapping for this path under any country). It is an override slot reserved for external localization apps (e.g., the former `india_compliance` app used it for landed-cost-like adjustments). Called unconditionally from `BuyingController.set_incoming_rate` at [buying_controller.py:495](../../erpnext/controllers/buying_controller.py:495). See [modules/regional.md](./regional.md#erpnextallow_regional-stubs-override-slots) for the full inventory of open override slots.

See [patterns/regional-overrides.md](../patterns/regional-overrides.md) for the `@erpnext.allow_regional` mechanism and [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) for the complete hook inventory.

## Notification defaults

[hooks.py:258](../../erpnext/hooks.py:258) — Email Digest recipient entries for Purchase Order, Purchase Receipt, Purchase Invoice, Material Request, Supplier Quotation, Request for Quotation alongside their selling counterparts.

## Related

- [flows/buying-flow.md](../flows/buying-flow.md) — MR → PO → PR → PI cascade.
- [modules/buying-doctypes.md](./buying-doctypes.md) — per-DocType reference cards.
- [modules/accounts.md](./accounts.md) — Accounts module (Purchase Invoice GL).
- [modules/accounts-doctypes.md](./accounts-doctypes.md) — PI / Payment Entry cards.
- [modules/stock.md](./stock.md) — Stock module (PR SLE writes, MR, Landed Cost Voucher).
- [modules/stock-doctypes.md](./stock-doctypes.md) — MR / PR / LCV cards.
- [modules/selling.md](./selling.md) — drop-ship reverse lane, inter-company mirror.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy.
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — per-event call order.
- [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) — hook registrations.
- [patterns/regional-overrides.md](../patterns/regional-overrides.md) — regional override mechanism.

## Changelog

- `2026-04-17` — initial version.
