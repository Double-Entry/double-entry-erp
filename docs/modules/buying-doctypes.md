---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: buying
status: complete
related_docs:
  - ./buying.md
  - ../flows/buying-flow.md
  - ../flows/accounting-flow.md
  - ../flows/stock-flow.md
  - ../flows/payments-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
  - ./accounts-doctypes.md
  - ./stock-doctypes.md
---

# Buying DocType Reference Cards

> **TL;DR:** One card per buying-relevant DocType. Pair with [modules/buying.md](./buying.md) (module map) and [flows/buying-flow.md](../flows/buying-flow.md) (MR → RFQ → SQ → PO → PR → PI cascade). Cards focus on **buying-side behavior**: hooks overridden, the `status_updater` dicts that drive the cascade, buying-specific validations. GL / SLE side effects are cross-linked to the accounts / stock cards rather than restated.

## Reading a card

- **File** / **Class** — source file and class with line.
- **Inheritance** — direct parents (most buying transactional DocTypes go through `BuyingController`).
- **Hooks implemented** — lifecycle methods overridden; everything else is inherited.
- **Cascade** — the `status_updater` dicts (qty / amount roll-up contract).
- **SLE / GL** — cross-link when the DocType is covered in [modules/stock-doctypes.md](./stock-doctypes.md) or [modules/accounts-doctypes.md](./accounts-doctypes.md).
- **Notes** — buying-specific behavior worth calling out.

---

## Material Request

> Primary card: **[modules/stock-doctypes.md#material-request](./stock-doctypes.md#material-request)**.

Buying-side highlights:

- **File**: [material_request.py](../../erpnext/stock/doctype/material_request/material_request.py)
- **Class**: `MaterialRequest(BuyingController)` ([line 31](../../erpnext/stock/doctype/material_request/material_request.py:31))
- **Inheritance**: `BuyingController → SubcontractingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `__init__` ([line 88](../../erpnext/stock/doctype/material_request/material_request.py:88)) — seeds `status_updater` targeting `Sales Order Item.requested_qty` (for MRs cut against an SO) and `Packed Item.requested_qty`.
  - `validate` ([line 152](../../erpnext/stock/doctype/material_request/material_request.py:152)) — after `super().validate()`: `validate_schedule_date`, `check_for_on_hold_or_closed_status("Sales Order", "sales_order")`, `validate_uom_is_integer`, `validate_material_request_type` (clears `customer` unless type = `Customer Provided`), `validate_status` literal check, `validate_for_items`, `validate_pp_qty` (Production Plan linkage), `reset_default_field_value`.
  - `before_save` / `before_submit` ([line 240](../../erpnext/stock/doctype/material_request/material_request.py:240), [line 243](../../erpnext/stock/doctype/material_request/material_request.py:243)) — `set_status(update=True)`.
  - `on_submit` ([line 232](../../erpnext/stock/doctype/material_request/material_request.py:232)) — `update_requested_qty_in_production_plan`, `update_requested_qty` (Bin), `update_prevdoc_status` (Purchase only), `validate_budget` (if a budget is applicable on MR).
  - `on_cancel` ([line 290](../../erpnext/stock/doctype/material_request/material_request.py:290)) — reverses submit.
  - `before_cancel` ([line 246](../../erpnext/stock/doctype/material_request/material_request.py:246)) — `check_on_hold_or_closed_status` guard.
  - `before_update_after_submit` ([line 217](../../erpnext/stock/doctype/material_request/material_request.py:217)) — re-runs `validate_schedule_date`.
- **Cascade** (`status_updater`):
  - Material Request Item → **Sales Order Item** (`sales_order_item` → `requested_qty`) — outbound writeback when MR was cut from an SO.
  - Material Request Item → **Packed Item** (`packed_item` → `requested_qty`).
- **Inbound cascade target** (written by PO / PR / PI):
  - `Material Request Item.ordered_qty` + `Material Request.per_ordered` (from PO).
  - `Material Request Item.received_qty` + `Material Request.per_received` (from PR / PI-with-update_stock, with `validate_qty: False`).
  - For non-Purchase types: `ordered_qty` is written directly via `update_completed_qty` ([line 327](../../erpnext/stock/doctype/material_request/material_request.py:327)) triggered from Stock Entry / Work Order.
- **Status map**: [status_updater.py:115](../../erpnext/controllers/status_updater.py:115) — `Pending` → `Partially Ordered` → `Ordered` / `Issued` / `Transferred` → `Partially Received` → `Received`, plus manual `Stopped`. The literal depends on `material_request_type`.
- **Mappers** (`get_mapped_doc` adapters):
  - [make_purchase_order](../../erpnext/stock/doctype/material_request/material_request.py:502) — filters `ordered_qty < stock_qty`; sets `is_subcontracted=1` if type=Subcontracting.
  - [make_supplier_quotation](../../erpnext/stock/doctype/material_request/material_request.py:698).
  - [make_request_for_quotation](../../erpnext/stock/doctype/material_request/material_request.py:570).
  - [make_purchase_order_based_on_supplier](../../erpnext/stock/doctype/material_request/material_request.py:594) — filters to a single supplier's default items.
  - [make_stock_entry](../../erpnext/stock/doctype/material_request/material_request.py:728) — non-Purchase types (Transfer / Issue / Customer Provided).
  - [raise_work_orders](../../erpnext/stock/doctype/material_request/material_request.py:821) — Manufacture type.
  - [create_pick_list](../../erpnext/stock/doctype/material_request/material_request.py:892).
- **Notes**: MR shares its code with Stock; Purchase type is the only one that engages the buying cascade. `auto_created_via_reorder=1` marks scheduler-generated MRs from [reorder_item](../../erpnext/stock/reorder_item.py).

## Request for Quotation

- **File**: [request_for_quotation.py](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py)
- **Class**: `RequestforQuotation(BuyingController)` ([line 26](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:26))
- **Inheritance**: `BuyingController → SubcontractingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `before_validate` ([line 73](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:73)) — `set_has_unit_price_items`, `set_data_for_supplier` (pull email template).
  - `validate` ([line 78](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:78)) — `validate_duplicate_supplier`, `validate_supplier_list` (scorecard gate), `validate_qty_is_not_zero` (super), `validate_for_items`, `set_qty_as_per_stock_uom` (super), `update_email_id`; sets `status = "Draft"` if in draft.
  - `on_submit` ([line 161](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:161)) — `status = "Submitted"`, reset supplier rows (`email_sent = 0`, `quote_status = "Pending"`), `send_to_supplier()` (iterates suppliers, emails each with RFQ portal link).
  - `on_cancel` ([line 177](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:177)) — `status = "Cancelled"`.
  - `before_print` ([line 168](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:168)) — renders the first supplier's context unless `vendor` is explicitly set.
- **Cascade**: no `status_updater`. RFQ does not roll up into any prevdoc. The only downstream linkage is via `Supplier Quotation Item.request_for_quotation` + `request_for_quotation_item`, consumed by `SupplierQuotation.update_rfq_supplier_status` to flip `Request for Quotation Supplier.quote_status`.
- **Supplier-portal flow**: `send_to_supplier` ([line 192](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:192)) + `update_supplier_contact` ([line 225](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:225)) — creates a Website User + reset-password link for suppliers without a portal user. Portal route is `/rfq` ([hooks.py:190](../../erpnext/hooks.py:190)).
- **Supplier scorecard gate**: `validate_supplier_list` ([line 127](../../erpnext/buying/doctype/request_for_quotation/request_for_quotation.py:127)) — throws on `Supplier.prevent_rfqs=1`; warn on `warn_rfqs=1`.
- **Notes**: a single RFQ fans out to many suppliers; `Request for Quotation Supplier.quote_status` is the per-supplier pendulum (`Pending` / `Received` / `No Quote`) driven by SQ submit.

## Supplier Quotation

- **File**: [supplier_quotation.py](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py)
- **Class**: `SupplierQuotation(BuyingController)` ([line 19](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:19))
- **Inheritance**: `BuyingController → SubcontractingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `before_validate` ([line 112](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:112)) — `set_has_unit_price_items`.
  - `validate` ([line 116](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:116)) — `super().validate()`; sets `status = "Draft"` if blank; `validate_status`, `validate_for_items`, `validate_with_previous_doc` (against Material Request), `validate_uom_is_integer`, `validate_valid_till`.
  - `on_submit` ([line 131](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:131)) — `db_set("status", "Submitted")` + `update_rfq_supplier_status(1)`.
  - `on_cancel` ([line 135](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:135)) — reverses: `"Cancelled"` + `update_rfq_supplier_status(0)`.
  - `on_trash` ([line 139](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:139)) — explicit no-op override.
- **Cascade**: no outbound `status_updater`. Inbound: Supplier Quotation Item is the **target** of Purchase Order's implicit reference — PO `validate_with_previous_doc` checks `supplier`, `company`, `currency` match and `item_code`, `uom`, `conversion_factor` on the rows ([purchase_order.py:248](../../erpnext/buying/doctype/purchase_order/purchase_order.py:248)). `maintain_same_rate` enforces PO rate == SQ rate.
- **RFQ linkage**: [update_rfq_supplier_status](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:172) — for each linked RFQ, computes per-supplier `quote_status` by counting submitted SQ rows covering each RFQ item. `"Received"` only when every RFQ item has at least one SQ line; otherwise `"Pending"`.
- **Mappers**:
  - [make_purchase_order (from SQ)](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:244) — `name → supplier_quotation_item`, `parent → supplier_quotation`.
  - [make_purchase_invoice (from SQ)](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:300).
  - [make_quotation (sell-out from SQ)](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:321) — only items with `is_sales_item=1`.
- **Special methods**:
  - [set_expired_status](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:344) — scheduler job (daily) flips `valid_till < today` submitted SQs to `Expired`.
  - [get_purchased_items](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:356) — reports the qty already drawn into PO from this SQ.
- **Notes**: unlike Sales Quotation, SQ has no concept of `Ordered` / `Partially Ordered` status — its cascade to PO is tracked via PO `validate_with_previous_doc` only. Status literal set: `Draft`, `Submitted`, `Stopped`, `Cancelled`, `Expired`.

## Purchase Order

- **File**: [purchase_order.py](../../erpnext/buying/doctype/purchase_order/purchase_order.py)
- **Class**: `PurchaseOrder(BuyingController)` ([line 36](../../erpnext/buying/doctype/purchase_order/purchase_order.py:36))
- **Inheritance**: `BuyingController → SubcontractingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `__init__` ([line 173](../../erpnext/buying/doctype/purchase_order/purchase_order.py:173)) — seeds `status_updater[0]` targeting `Material Request Item.ordered_qty`.
  - `onload` ([line 189](../../erpnext/buying/doctype/purchase_order/purchase_order.py:189)) — sets `can_update_items` onload (blocks Update Items UI when a non-cancelled Subcontracting Order exists).
  - `before_validate` ([line 192](../../erpnext/buying/doctype/purchase_order/purchase_order.py:192)) — `set_has_unit_price_items`; switches `source_field` to `fg_item_qty` when `is_subcontracted=1`.
  - `validate` ([line 199](../../erpnext/buying/doctype/purchase_order/purchase_order.py:199)) — `super().validate()`; `set_status`; `validate_supplier` (scorecard gate — `prevent_pos` / `warn_pos`); `validate_schedule_date`; `validate_for_items`; `check_on_hold_or_closed_status` (MR); `validate_uom_is_integer`; `validate_with_previous_doc` (against SQ and MR, optionally `maintain_same_rate`); `validate_for_subcontracting`; `validate_minimum_order_qty`; `validate_against_blanket_order`; legacy subcontracting branch (`validate_bom_for_subcontracting_items`, `create_raw_materials_supplied`); `validate_fg_item_for_subcontracting` (new flow); `set_received_qty_for_drop_ship_items`; sets default `advance_payment_status = "Not Initiated"`; `validate_inter_company_party`; `reset_default_field_value`.
  - `on_submit` ([line 451](../../erpnext/buying/doctype/purchase_order/purchase_order.py:451)) — see [flows/buying-flow.md#cascade-on-po-submit](../flows/buying-flow.md#cascade-on-po-submit).
  - `on_cancel` ([line 478](../../erpnext/buying/doctype/purchase_order/purchase_order.py:478)) — see [flows/buying-flow.md#cascade-on-po-cancel](../flows/buying-flow.md#cascade-on-po-cancel).
- **Cascade** (`status_updater`, base + appended):
  - Purchase Order Item → **Material Request Item** (`material_request_item` → `ordered_qty`, `per_ordered`) — base ([line 176](../../erpnext/buying/doctype/purchase_order/purchase_order.py:176)).
  - If `is_against_so()`: append Purchase Order Item → **Sales Order Item** (`sales_order_item` → `ordered_qty`) and → **Packed Item** (`sales_order_packed_item` → `ordered_qty`) ([line 516](../../erpnext/buying/doctype/purchase_order/purchase_order.py:516)).
  - If `is_against_pp()`: append Purchase Order Item → **Production Plan Sub Assembly Item** (`production_plan_sub_assembly_item` → `received_qty`) ([line 542](../../erpnext/buying/doctype/purchase_order/purchase_order.py:542)).
- **Inbound cascade target** (written by PR / PI):
  - `Purchase Order Item.received_qty` + `Purchase Order.per_received` (from PR, SUM with PI when `update_stock=1`).
  - `Purchase Order Item.billed_amt` + `Purchase Order.per_billed` (from PI).
  - `Purchase Order Item.returned_qty` (from return PR / return PI-with-update_stock).
- **Status map**: [status_updater.py:68](../../erpnext/controllers/status_updater.py:68) — `To Receive and Bill` / `To Bill` / `To Receive` / `Completed` / `To Pay` (advance-payment-status-driven), plus manual `Closed` / `On Hold` and `Delivered` (drop-ship trigger).
- **Special methods**:
  - [update_status](../../erpnext/buying/doctype/purchase_order/purchase_order.py:440) — single-PO status flip (`Closed` / `Delivered` / `On Hold` / `Draft`); re-runs `update_requested_qty`, `update_ordered_qty`, `update_reserved_qty_for_subcontract`, `update_subcontracting_order_status`, `update_blanket_order`.
  - [close_or_unclose_purchase_orders](../../erpnext/buying/doctype/purchase_order/purchase_order.py:682) — bulk action; only closes if `per_received < 100 or per_billed < 100`.
  - [update_delivered_qty_in_sales_order](../../erpnext/buying/doctype/purchase_order/purchase_order.py:556) — drop-ship reverse lane.
  - [update_ordered_qty](../../erpnext/buying/doctype/purchase_order/purchase_order.py:415) — bumps `Bin.ordered_qty` (skips `delivered_by_supplier=1` drop-ship rows).
  - [update_reserved_qty_for_subcontract](../../erpnext/buying/doctype/purchase_order/purchase_order.py:584) — legacy flow; bumps `Bin.reserved_qty_for_sub_contract`.
  - [auto_create_subcontracting_order](../../erpnext/buying/doctype/purchase_order/purchase_order.py:646) — new-flow SCO auto-creation.
  - [update_status_updater](../../erpnext/buying/doctype/purchase_order/purchase_order.py:516), [update_status_updater_if_from_pp](../../erpnext/buying/doctype/purchase_order/purchase_order.py:542) — runtime append of extra `status_updater` rows.
  - [make_purchase_receipt](../../erpnext/buying/doctype/purchase_order/purchase_order.py:710), [make_purchase_invoice](../../erpnext/buying/doctype/purchase_order/purchase_order.py:776), [make_subcontracting_order](../../erpnext/buying/doctype/purchase_order/purchase_order.py:915), [make_inter_company_sales_order](../../erpnext/buying/doctype/purchase_order/purchase_order.py:908), [make_purchase_invoice_from_portal](../../erpnext/buying/doctype/purchase_order/purchase_order.py:783) — mappers.
- **Notes**: `advance_payment_status` is driven by `To Pay` status plus Payment Entry / Payment Request lifecycle (see [flows/payments-flow.md](../flows/payments-flow.md)). `hooks.py:526` registers PO in `advance_payment_payable_doctypes`.

## Purchase Receipt

> Primary card: **[modules/stock-doctypes.md#purchase-receipt](./stock-doctypes.md#purchase-receipt)**.

Buying-side highlights:

- **Class**: `PurchaseReceipt(BuyingController)` ([purchase_receipt.py:33](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:33)).
- **Cascade** (`status_updater`) — 4 entries on submit, 2 extra on return ([purchase_receipt.py:161](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:161)):
  - Purchase Receipt Item → **Purchase Order Item** (`purchase_order_item` → `received_qty`, `per_received`, with `second_source_dt=Purchase Invoice Item` for `update_stock=1` PIs).
  - Purchase Receipt Item → **Material Request Item** (`material_request_item` → `received_qty`, `per_received`, `validate_qty: False`).
  - Purchase Receipt Item → **Purchase Invoice Item** (`purchase_invoice_item` → `received_qty`) — fires only when PR references a PI (PI-first ordering).
  - Purchase Receipt Item → **Delivery Note Item** (`delivery_note_item` → `received_qty`) — internal transfer mirror.
  - On return: **PO Item.returned_qty** (with PI second-source for update_stock returns) + **PR Item.returned_qty** + **PR.per_returned** on the original PR.
- **Billing**: [update_billing_status](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:972) — per-item `billed_amt` from direct PI link, or FIFO-redistributed via [update_billed_amount_based_on_po](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:1121) when PI bills against PO. [update_billing_percentage](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:1254) computes `per_billed` excluding returned qty and optionally including rejected qty (Buying Settings flag).
- **Internal transfer**: `is_internal_transfer()` branches in SLE writer (outgoing SLE from `from_warehouse`) and in `set_incoming_rate` (overrides `rate` with `sales_incoming_rate`).
- **Asset auto-creation**: inherited via `BuyingController.process_fixed_asset` → [auto_make_assets](../../erpnext/controllers/buying_controller.py:997).
- **Landed Cost**: `landed_cost_voucher_amount` on item rows flows into `update_valuation_rate`; LCV submit re-posts SLE + GL ([landed_cost_voucher.py:309](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:309)).
- **Subcontracting (legacy)**: `supplier_warehouse` SLE + GL ([purchase_receipt.py:677](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:677)), `rm_supp_cost` in valuation rate.
- **Stock reservation on PR**: [reserve_stock](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:988) — if `Stock Settings.auto_reserve_stock_for_sales_order_on_purchase=1`, creates SREs against linked Sales Orders.
- **Quality Inspection**: `validate_items_quality_inspection` ([purchase_receipt.py:342](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:342)) — validates attached QI's reference_type/name match.
- **Provisional expense** (non-stock items): `provisional_expense_account` + `Company.enable_provisional_accounting_for_non_stock_items` triggers provisional GL via [add_provisional_gl_entry](../../erpnext/stock/doctype/purchase_receipt/purchase_receipt.py:839).

## Purchase Invoice

> Primary card: **[modules/accounts-doctypes.md#purchase-invoice](./accounts-doctypes.md#purchase-invoice)**.

Buying-side highlights:

- **Class**: `PurchaseInvoice(BuyingController)` ([purchase_invoice.py:54](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:54)).
- **Cascade** (`status_updater`) — 1 base entry, up to 3 appended:
  - Purchase Invoice Item → **Purchase Order Item** (`po_detail` → `billed_amt`, `per_billed`, `overflow_type="billing"`) — base ([line 228](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:228)).
  - If `update_stock=1`: append Purchase Invoice Item → **Purchase Order Item** (`po_detail` → `received_qty`, second_source=PR) and → **Material Request Item** (`material_request_item` → `received_qty`) ([line 679](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:679)).
  - If `is_return=1 and update_stock=1`: append PO Item `returned_qty`.
  - If `is_return=1 and not update_billed_amount_in_purchase_order`: `self.status_updater = []` ([line 758](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:758)) — cascade skipped entirely.
- **Inbound cascade target**: `Purchase Invoice Item.received_qty` + `Purchase Invoice.per_received` (from PR when PI-first ordering).
- **Billing writeback to PR**: [update_billing_status_in_pr](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:1787) — on submit, writes `billed_amt` / `per_billed` / status on every linked PR doc.
- **Gating**: `po_required` (Buying Settings) at [:272](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:272); `pr_required` at [:638](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:638) (non-internal-transfer, non-return).
- **Supplier invoice dedup**: [validate_supplier_invoice](../../erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:1756) — throws on duplicate `bill_no`+`supplier`+`company` within the fiscal year window (`Accounts Settings.unique_supplier_invoice_number`).
- **Accounts side (cross-link)**: GL composition, WHT, RCM, CWIP, `update_stock=1` SLE, `on_update_after_submit` repost — all covered in [modules/accounts-doctypes.md#purchase-invoice](./accounts-doctypes.md#purchase-invoice) and [flows/accounting-flow.md](../flows/accounting-flow.md).

## Supplier

- **File**: [supplier.py](../../erpnext/buying/doctype/supplier/supplier.py)
- **Class**: `Supplier(TransactionBase)` ([line 23](../../erpnext/buying/doctype/supplier/supplier.py:23)) — master, not a transactional controller.
- **Inheritance**: `TransactionBase → Document`
- **Hooks implemented**:
  - `onload` ([line 84](../../erpnext/buying/doctype/supplier/supplier.py:84)) — load address + contacts + dashboard info.
  - `autoname` ([line 100](../../erpnext/buying/doctype/supplier/supplier.py:100)) — `supp_master_name` switch.
  - `before_save` ([line 89](../../erpnext/buying/doctype/supplier/supplier.py:89)) — hold-type defaulting.
  - `validate` ([line 137](../../erpnext/buying/doctype/supplier/supplier.py:137)) — naming-series mandatory, `validate_party_accounts`, `validate_internal_supplier` (one per represents_company), `add_role_for_user`, `validate_currency_for_receivable_payable_and_advance_account`.
  - `on_update` ([line 109](../../erpnext/buying/doctype/supplier/supplier.py:109)) — `create_primary_contact`, `create_primary_address`.
  - `on_trash` ([line 208](../../erpnext/buying/doctype/supplier/supplier.py:208)) — cascade-delete contacts and addresses.
  - `before_rename` / `after_rename` — currency check on merge; `supplier_name` sync.
- **Cascade**: none. Supplier is the party master; transactional cascade is owned by PO / PR / PI.
- **Notes**: gating flags (`prevent_pos`, `warn_pos`, `prevent_rfqs`, `warn_rfqs`, `on_hold` + `hold_type` + `release_date`, `disabled`, `is_frozen`) are consumed by downstream transaction validations. See [modules/buying.md#supplier-master](./buying.md#supplier-master) for the full table.

## Supplier Group

- **File**: `erpnext/setup/doctype/supplier_group/supplier_group.py`
- **Class**: `SupplierGroup(NestedSet)` — tree-structured master.
- **Inheritance**: `NestedSet → Document`.
- **Role**: groups Suppliers for reporting and for `Supplier Group.accounts` / `payment_terms` defaults that cascade into new Suppliers via [Supplier.get_supplier_group_details](../../erpnext/buying/doctype/supplier/supplier.py:151).
- **Cascade**: none.

## Supplier Scorecard

- **File**: [supplier_scorecard.py](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py)
- **Class**: `SupplierScorecard(Document)` ([line 18](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:18))
- **Inheritance**: `Document`.
- **Hooks implemented**:
  - `validate` ([line 51](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:51)) — `validate_standings` (no score-range overlap, full 0-100 cover), `validate_criteria_weights` (weights sum to 100), `calculate_total_score`, `update_standing`.
  - `on_update` ([line 57](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:57)) — `make_all_scorecards` (generates any missing Supplier Scorecard Period rows).
- **Related DocTypes**:
  - `Supplier Scorecard Period` — per-window snapshot, `docstatus=1` when the window is locked.
  - `Supplier Scorecard Criteria` — reusable named criterion (e.g. "On-Time Delivery").
  - `Supplier Scorecard Variable` — named metric with a Python formula referenced in criteria.
  - `Supplier Scorecard Standing` — score band (e.g. `0-60 → Poor → prevent_pos=1`).
  - `Supplier Scorecard Scoring Criteria` / `Scoring Variable` / `Scoring Standing` — per-period captured values on the Period doc.
- **Scheduler**: [refresh_scorecards](../../erpnext/buying/doctype/supplier_scorecard/supplier_scorecard.py:183) runs daily ([hooks.py:469](../../erpnext/hooks.py:469)).
- **Effect on transactions**: the scorecard writes `Supplier.prevent_pos` / `warn_pos` / `prevent_rfqs` / `warn_rfqs` / `status` via the standing band — consumed by PO and RFQ validate.

## Purchase Taxes and Charges Template

- **File**: `erpnext/accounts/doctype/purchase_taxes_and_charges_template/purchase_taxes_and_charges_template.py`
- **Role**: reusable tax template attached on MR / SQ / PO / PR / PI via `taxes_and_charges`. Lines live in child `Purchase Taxes and Charges`.
- **Categories**: `Total`, `Valuation`, `Valuation and Total`. `Valuation` contributes to `item.item_tax_amount` (and hence to `valuation_rate`) via [BuyingController.update_valuation_rate](../../erpnext/controllers/buying_controller.py:403); `Total` contributes only to `grand_total`.
- **Inclusive-tax** flag per row: handled in [taxes_and_totals.py](../../erpnext/controllers/taxes_and_totals.py) — see [flows/taxes-and-totals.md](../flows/taxes-and-totals.md).
- **On-submit / on-cancel**: templates are masters, no lifecycle hooks beyond defaulting.
- **Tax Category** (`erpnext/accounts/doctype/tax_category/`) — modulates template selection via `Tax Rule`.
- **Cross-link**: [modules/accounts-doctypes.md](./accounts-doctypes.md) for template structure shared with Sales Taxes and Charges Template.

## Landed Cost Voucher

> Primary card: **[modules/stock-doctypes.md#landed-cost-voucher](./stock-doctypes.md#landed-cost-voucher)**.

Buying-side highlights:

- **File**: [landed_cost_voucher.py](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py)
- **Class**: `LandedCostVoucher(Document)` ([line 24](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:24)) — **does not** inherit BuyingController; it manipulates PR / PI / SCR directly.
- **Hooks implemented**:
  - `validate` ([line 81](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:81)) — `check_mandatory` (at least one receipt doc), `validate_receipt_documents` (docstatus=1, same company, PI must have `update_stock=1`), `validate_line_items`, `validate_expense_accounts`, `init_landed_taxes_and_totals`, `set_total_taxes_and_charges`, `set_applicable_charges_on_item`, `set_total_vendor_invoices_cost`.
  - `on_submit` ([line 291](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:291)) — `validate_applicable_charges_for_item`, `update_landed_cost` (cancel-then-submit-again PR cycle), `update_claimed_landed_cost` on linked vendor invoices.
  - `on_cancel` ([line 296](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:296)) — re-runs `update_landed_cost` (LCV amounts are zeroed on cancel, PR re-posts without the charge).
- **Cascade**: none. LCV is orthogonal to the PO / PR / PI status_updater chain. It mutates each linked PR's items to refresh `landed_cost_voucher_amount` and re-post SLE + GL.
- **Charges distribution** ([line 204](../../erpnext/stock/doctype/landed_cost_voucher/landed_cost_voucher.py:204)): `distribute_charges_based_on` = `Qty` / `Amount` / `Distribute Manually` → writes `applicable_charges` per PR item.
- **Notes**: LCV is idempotent — multiple LCVs can stack on the same PR. Vendor invoice tracking (`Landed Cost Vendor Invoice`) lets an LCV "claim" unbilled service-type PIs, writing `Purchase Invoice.claimed_landed_cost_amount`.

## Buying Settings

- **File**: [buying_settings.py](../../erpnext/buying/doctype/buying_settings/buying_settings.py)
- **Class**: `BuyingSettings(Document)` — Single DocType ([line 11](../../erpnext/buying/doctype/buying_settings/buying_settings.py:11)).
- **Hooks implemented**:
  - `validate` ([line 50](../../erpnext/buying/doctype/buying_settings/buying_settings.py:50)) — persists several flags as `frappe.db.defaults` (`supplier_group`, `supp_master_name`, `maintain_same_rate`, `buying_price_list`); triggers `set_by_naming_series` to toggle hidden state on `Supplier.naming_series`. If `bill_for_rejected_quantity_in_purchase_invoice=0`, forces `set_valuation_rate_for_rejected_materials=0`.
  - `before_save` ([line 66](../../erpnext/buying/doctype/buying_settings/buying_settings.py:66)) — `check_maintain_same_rate` — if `maintain_same_rate=1`, forces `set_landed_cost_based_on_purchase_invoice_rate=0` (mutually exclusive).
- **Cascade**: none. Settings doc.
- **Flag reference**: see [modules/buying.md#buying-settings](./buying.md#buying-settings) for the full consumer table.

## Purchase Order Item / Purchase Receipt Item / Purchase Invoice Item

Child-table DocTypes; schema lives next to each parent. Key fields that thread the cascade:

- **Purchase Order Item**: `material_request` / `material_request_item`, `supplier_quotation` / `supplier_quotation_item`, `sales_order` / `sales_order_item` (drop-ship + inter-company), `sales_order_packed_item`, `production_plan` / `production_plan_sub_assembly_item`, `fg_item` / `fg_item_qty` / `bom` / `subcontracted_qty` (subcontracting), `delivered_by_supplier` (drop-ship), `received_qty`, `billed_amt`, `returned_qty`.
- **Purchase Receipt Item**: `purchase_order` / `purchase_order_item`, `material_request` / `material_request_item`, `purchase_invoice` / `purchase_invoice_item` (PI-first), `delivery_note_item` (internal transfer), `rejected_qty` / `rejected_warehouse`, `from_warehouse` (internal transfer), `landed_cost_voucher_amount`, `amount_difference_with_purchase_invoice`, `rm_supp_cost` (legacy subcontracting), `billed_amt`, `returned_qty`, `return_qty_from_rejected_warehouse`.
- **Purchase Invoice Item**: `po_detail` (PO Item.name), `purchase_order`, `pr_detail` (PR Item.name), `purchase_receipt`, `material_request` / `material_request_item`, `purchase_order_item` (for update_stock=1 flow), `received_qty`, `rejected_qty`, `rm_supp_cost`, `provisional_expense_account`.

## Purchase Order Item Supplied / Purchase Receipt Item Supplied

Child tables for legacy subcontracting supplied-items (new-flow moves these to `Subcontracting Order Supplied Item` / `Subcontracting Receipt Supplied Item`). Rows are generated by [SubcontractingController.create_raw_materials_supplied_or_received](../../erpnext/controllers/subcontracting_controller.py:1112) on PO validate (legacy) or PR validate (legacy). The `reserve_warehouse` field is mandatory on PO for each supplied item; `rm_supp_cost` is rolled up into `BuyingController.update_valuation_rate` at PR submit.

## Customer Number at Supplier

- **File**: `erpnext/buying/doctype/customer_number_at_supplier/`
- **Role**: child table on Supplier (`Supplier.customer_numbers`) mapping `our Customer → Supplier's internal customer id`, used for printing and EDI.
- **Cascade**: none.

## Request for Quotation Item / Request for Quotation Supplier

Child tables on RFQ.

- **Request for Quotation Item** — line item with `material_request` / `material_request_item` references so the RFQ can track partial inclusion.
- **Request for Quotation Supplier** — per-supplier row with `email_id`, `contact`, `email_sent`, `send_email`, `no_quote`, `quote_status` (`Pending` / `Received` / `No Quote`). `quote_status` is maintained by [SupplierQuotation.update_rfq_supplier_status](../../erpnext/buying/doctype/supplier_quotation/supplier_quotation.py:172).

## Supplier Quotation Item

- **File**: `erpnext/buying/doctype/supplier_quotation_item/`
- **Role**: line item on SQ. References `request_for_quotation` / `request_for_quotation_item` back to the RFQ, and `material_request` / `material_request_item` back to the MR. `lead_time_days` per row feeds the RFQ comparison report.

## Related

- [buying module](./buying.md) — module overview, BuyingController responsibilities, Buying Settings knobs.
- [flows/buying-flow.md](../flows/buying-flow.md) — MR → RFQ → SQ → PO → PR → PI cascade end-to-end.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL writes on PI / PR submit.
- [flows/stock-flow.md](../flows/stock-flow.md) — SLE writes on PR submit, LCV revaluation.
- [flows/payments-flow.md](../flows/payments-flow.md) — Payment Entry against PO / PI.
- [modules/accounts-doctypes.md](./accounts-doctypes.md) — Purchase Invoice, Payment Entry cards.
- [modules/stock-doctypes.md](./stock-doctypes.md) — Material Request, Purchase Receipt, Landed Cost Voucher cards.
- [modules/selling-doctypes.md](./selling-doctypes.md) — Pricing Rule, Promotional Scheme (shared with buying via `buying=1` flag).
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy.
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — per-event call order.

## Changelog

- `2026-04-17` — initial version.
