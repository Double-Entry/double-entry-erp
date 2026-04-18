---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: selling
status: complete
related_docs:
  - ./selling.md
  - ../flows/selling-flow.md
  - ../flows/accounting-flow.md
  - ../flows/stock-flow.md
  - ../flows/payments-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
  - ./accounts-doctypes.md
  - ./stock-doctypes.md
---

# Selling DocType Reference Cards

> **TL;DR:** One card per selling-relevant DocType. Pair with [modules/selling.md](./selling.md) (module map) and [flows/selling-flow.md](../flows/selling-flow.md) (QTN → SO → DN → SI cascade). Cards focus on **selling-side behavior**: hooks overridden, the `status_updater` dicts that drive the cascade, selling-specific validations. GL / SLE side effects are cross-linked to the accounts / stock cards rather than restated.

## Reading a card

- **File** / **Class** — source file and class with line.
- **Inheritance** — direct parents (most selling transactional DocTypes go through `SellingController`).
- **Hooks implemented** — lifecycle methods overridden; everything else is inherited.
- **Cascade** — the `status_updater` dicts (qty / amount roll-up contract).
- **SLE / GL** — cross-link when the DocType is covered in [modules/stock-doctypes.md](./stock-doctypes.md) or [modules/accounts-doctypes.md](./accounts-doctypes.md).
- **Notes** — selling-specific behavior worth calling out.

---

## Quotation

- **File**: [quotation.py](../../erpnext/selling/doctype/quotation/quotation.py)
- **Class**: `Quotation(SellingController)` ([line 18](../../erpnext/selling/doctype/quotation/quotation.py:18))
- **Inheritance**: `SellingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `before_validate` ([line 137](../../erpnext/selling/doctype/quotation/quotation.py:137)) — `set_has_unit_price_items`.
  - `validate` ([line 141](../../erpnext/selling/doctype/quotation/quotation.py:141)) — after `super().validate()`: `set_status`, `validate_uom_is_integer`, `validate_valid_till` ([line 158](../../erpnext/selling/doctype/quotation/quotation.py:158)), `set_customer_name`, `make_packing_list` for bundles.
  - `before_submit` ([line 155](../../erpnext/selling/doctype/quotation/quotation.py:155)) — `set_has_alternative_item` (marks rows that have alternative items).
  - `on_submit` ([line 293](../../erpnext/selling/doctype/quotation/quotation.py:293)) — Authorization Control + `update_opportunity("Quotation")` + `update_lead()`.
  - `on_cancel` ([line 303](../../erpnext/selling/doctype/quotation/quotation.py:303)) — clears `lost_reasons`, runs `super().on_cancel()`, `set_status(update=True)`, `update_opportunity("Open")`, `update_lead()`.
  - `on_recurring` ([line 322](../../erpnext/selling/doctype/quotation/quotation.py:322)) — clears `valid_till` when auto-repeat spawns a new Quotation.
  - `set_indicator` ([line 129](../../erpnext/selling/doctype/quotation/quotation.py:129)) — portal color.
- **Cascade**: no `status_updater` outbound. Inbound: Quotation Item is the **target** of Sales Order's cascade (`target_dt='Quotation Item'`, `target_field='ordered_qty'`). Quotation status is derived from `Quotation Item.ordered_qty` via `get_ordered_status` ([line 183](../../erpnext/selling/doctype/quotation/quotation.py:183)) → `is_fully_ordered` / `is_partially_ordered` (referenced from `status_map["Quotation"]` at [status_updater.py:34](../../erpnext/controllers/status_updater.py:34)).
- **Special methods**:
  - [declare_enquiry_lost](../../erpnext/selling/doctype/quotation/quotation.py:261) — sets status `Lost` with reasons + competitors, updates Opportunity.
  - [set_expired_status](../../erpnext/selling/doctype/quotation/quotation.py:488) — scheduler job (daily) that flips expired Quotations to `Expired`, skipping those with a linked Sales Order.
  - [make_sales_order](../../erpnext/selling/doctype/quotation/quotation.py:360) / [make_sales_invoice](../../erpnext/selling/doctype/quotation/quotation.py:511) — `get_mapped_doc` adapters.
- **Notes**: `quotation_to` is dynamic: `Customer` / `Lead` / `Prospect` / `CRM Deal`. `_make_customer` ([line 564](../../erpnext/selling/doctype/quotation/quotation.py:564)) creates a Customer from Lead / Prospect at SO-creation time. Alternative items (`is_alternative`, `has_alternative_item`) branch in `_make_sales_order.can_map_row`.

## Sales Order

- **File**: [sales_order.py](../../erpnext/selling/doctype/sales_order/sales_order.py)
- **Class**: `SalesOrder(SellingController)` ([line 55](../../erpnext/selling/doctype/sales_order/sales_order.py:55))
- **Inheritance**: `SellingController → StockController → AccountsController → TransactionBase → StatusUpdater`
- **Hooks implemented**:
  - `__init__` ([line 200](../../erpnext/selling/doctype/sales_order/sales_order.py:200)) — seeds `status_updater` with the QTN-Item target.
  - `onload` ([line 213](../../erpnext/selling/doctype/sales_order/sales_order.py:213)) — sets `has_reserved_stock` / `has_unreserved_stock` onload flags.
  - `before_validate` ([line 236](../../erpnext/selling/doctype/sales_order/sales_order.py:236)) — `set_has_unit_price_items`.
  - `validate` ([line 240](../../erpnext/selling/doctype/sales_order/sales_order.py:240)) — on top of `super().validate()`: `validate_delivery_date`, `validate_proj_cust`, `validate_po`, `validate_for_items`, `validate_warehouse`, `validate_drop_ship` ([line 493](../../erpnext/selling/doctype/sales_order/sales_order.py:493)), `validate_reserved_stock`, `validate_serial_no_based_delivery`, `validate_against_blanket_order`, `validate_inter_company_party`, `validate_coupon_code`, `make_packing_list`, `validate_with_previous_doc` ([line 459](../../erpnext/selling/doctype/sales_order/sales_order.py:459)) (against Quotation with same-rate check), `validate_fg_item_for_subcontracting` ([line 281](../../erpnext/selling/doctype/sales_order/sales_order.py:281)), `set_status`, defaults.
  - `on_submit` ([line 498](../../erpnext/selling/doctype/sales_order/sales_order.py:498)) — see [flows/selling-flow.md#cascade-on-so-submit](../flows/selling-flow.md#cascade-on-so-submit).
  - `on_cancel` ([line 528](../../erpnext/selling/doctype/sales_order/sales_order.py:528)) — see [flows/selling-flow.md#cascade-on-so-cancel](../flows/selling-flow.md#cascade-on-so-cancel).
  - `on_update_after_submit` ([line 653](../../erpnext/selling/doctype/sales_order/sales_order.py:653)) — `calculate_commission` + `calculate_contribution` + `check_credit_limit`.
  - `before_update_after_submit` ([line 658](../../erpnext/selling/doctype/sales_order/sales_order.py:658)) — `validate_po`, `validate_drop_ship`, `validate_supplier_after_submit`, `validate_delivery_date`.
  - `on_recurring` ([line 749](../../erpnext/selling/doctype/sales_order/sales_order.py:749)) — recomputes per-item `delivery_date` for auto-repeat.
  - `update_prevdoc_status` **override** ([line 483](../../erpnext/selling/doctype/sales_order/sales_order.py:483)) — specialized to update Quotation status + Opportunity (no_allowance flow).
- **Cascade** (`status_updater`):
  - `Sales Order Item → Quotation Item` on `quotation_item` for `ordered_qty` ([line 202](../../erpnext/selling/doctype/sales_order/sales_order.py:202)).
- **Inbound cascade target** (written by DN / SI):
  - `Sales Order Item.delivered_qty` + `Sales Order.per_delivered` (from DN, SI-with-update-stock, and drop-ship PO via `update_delivery_status`).
  - `Sales Order Item.billed_amt` + `Sales Order.per_billed` (from SI).
  - `Sales Order Item.returned_qty` (return DN / SI).
- **Status map**: [status_updater.py:42](../../erpnext/controllers/status_updater.py:42) — `To Deliver and Bill`, `To Bill`, `To Deliver`, `Completed`, plus manual `Closed` / `On Hold` overrides. `Closed` requires explicit `close_or_unclose_sales_orders` ([line 986](../../erpnext/selling/doctype/sales_order/sales_order.py:986)).
- **Special methods**:
  - `update_delivery_status` ([line 681](../../erpnext/selling/doctype/sales_order/sales_order.py:681)) — drop-ship-only; SUMs delivered qty from PO Items whose PO `status='Delivered'`.
  - `update_picking_status` ([line 707](../../erpnext/selling/doctype/sales_order/sales_order.py:707)) — writes `per_picked` from linked Pick Lists.
  - `update_reserved_qty` ([line 628](../../erpnext/selling/doctype/sales_order/sales_order.py:628)) — recomputes `Bin.reserved_qty`.
  - `create_stock_reservation_entries` / `cancel_stock_reservation_entries` ([lines 839](../../erpnext/selling/doctype/sales_order/sales_order.py:839), [859](../../erpnext/selling/doctype/sales_order/sales_order.py:859)).
  - [make_material_request](../../erpnext/selling/doctype/sales_order/sales_order.py:1027), [make_delivery_note](../../erpnext/selling/doctype/sales_order/sales_order.py:1156), [make_project](../../erpnext/selling/doctype/sales_order/sales_order.py:1129), [make_purchase_order](../../erpnext/selling/doctype/sales_order/sales_order.py:1598), [make_work_orders](../../erpnext/selling/doctype/sales_order/sales_order.py) (manufacturing integration).
- **Notes**: `skip_delivery_note=1` bypasses DN and allows direct SI. `is_subcontracted=1` branch in `on_submit` + `validate_fg_item_for_subcontracting` feeds into Subcontracting Inward Order. `advance_payment_status` is driven by `To Pay` status and Payment Entry / Payment Request submission (see [flows/payments-flow.md](../flows/payments-flow.md)).

## Delivery Note

> Primary card: **[modules/stock-doctypes.md#delivery-note](./stock-doctypes.md#delivery-note)**.

Selling-side highlights:

- **Class**: `DeliveryNote(SellingController)` ([delivery_note.py:26](../../erpnext/stock/doctype/delivery_note/delivery_note.py:26)).
- **Cascade** (`status_updater`) — 3 entries on submit, 2 extra on return ([delivery_note.py:166](../../erpnext/stock/doctype/delivery_note/delivery_note.py:166)):
  - Delivery Note Item → **Sales Order Item** (`so_detail` → `delivered_qty`, `per_delivered`, `delivery_status`, with `second_source_dt=Sales Invoice Item` for `update_stock=1` SIs).
  - Delivery Note Item → **Sales Invoice Item** (`si_detail` → `delivered_qty`, `no_allowance`).
  - Delivery Note Item → **Pick List Item** (`pick_list_item` → `delivered_qty`, `per_delivered`).
  - On return: `returned_qty` at SO Item and at the original DN Item.
- **Billing**: `update_billing_status` ([delivery_note.py:668](../../erpnext/stock/doctype/delivery_note/delivery_note.py:668)) writes `billed_amt` per row, redistributed FIFO by [update_billed_amount_based_on_so](../../erpnext/stock/doctype/delivery_note/delivery_note.py:717) when SI bills against SO and not DN.
- **Stock reservation**: `update_stock_reservation_entries` from `SellingController` ([selling_controller.py:895](../../erpnext/controllers/selling_controller.py:895)).
- **Credit limit**: `check_credit_limit` ([delivery_note.py:571](../../erpnext/stock/doctype/delivery_note/delivery_note.py:571)) with bypass at SO-level flag.
- **Auto credit note**: `make_return_invoice` ([delivery_note.py:682](../../erpnext/stock/doctype/delivery_note/delivery_note.py:682)) if `is_return=1 and issue_credit_note=1`.
- **Inter-company**: `inter_company_reference` field for mirroring with a Purchase Receipt.
- **Mappers out**: [make_sales_invoice (from DN)](../../erpnext/stock/doctype/delivery_note/delivery_note.py:855), [make_delivery_trip](../../erpnext/stock/doctype/delivery_note/delivery_note.py:986), [make_installation_note](../../erpnext/stock/doctype/delivery_note/delivery_note.py:1018), [make_packing_slip](../../erpnext/stock/doctype/delivery_note/delivery_note.py:1048).

## Sales Invoice

> Primary card: **[modules/accounts-doctypes.md](./accounts-doctypes.md)** (GL focus).

Selling-side highlights:

- **Class**: `SalesInvoice(SellingController)` ([sales_invoice.py:59](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:59)).
- **Cascade** (`status_updater`) — seeded at init ([sales_invoice.py:257](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:257)):
  - Sales Invoice Item → **Sales Order Item** (`so_detail` → `billed_amt`, `per_billed`, `billing_status`, keyword `Billed`, `overflow_type=billing`).
  - `update_status_updater_args` ([sales_invoice.py:665](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:665)) **appends** additional rows at runtime:
    - If `update_stock=1`: SI → SO Item `delivered_qty` (with `second_source_dt=Delivery Note Item` for summed delivery counting).
    - If `is_return=1 and update_stock=1`: SI → SO Item `returned_qty`.
  - The list is cleared to `[]` ([sales_invoice.py:462](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:462)) when the SI is a consolidated POS invoice — cascade was already driven by individual POS Invoices.
- **Selling-side validations** in `validate` ([sales_invoice.py:300](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:300)):
  - `so_dn_required` — enforces `Selling Settings.so_required` / `dn_required`.
  - `check_sales_order_on_hold_or_close("sales_order")` — inherited from `SellingController` ([selling_controller.py:471](../../erpnext/controllers/selling_controller.py:471)).
  - `validate_with_previous_doc` — against SO and DN rates when `maintain_same_sales_rate` is on.
  - `validate_dropship_item` — blocks DN-like operations on drop-ship SO rows.
  - `validate_delivery_note` — when linked DN rows are referenced.
- **`update_stock=1`** path engages the full `SellingController.update_stock_ledger` + `set_incoming_rate` ([selling_controller.py:529](../../erpnext/controllers/selling_controller.py:529)); SI behaves as a DN+SI combo.
- **Inter-company**: `inter_company_invoice_reference`; `validate_inter_company_party` ([sales_invoice.py:2330](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:2330)), `update_linked_doc` ([sales_invoice.py:2372](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:2372)), `make_inter_company_purchase_invoice` ([sales_invoice.py:2587](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:2587)).
- **Credit limit**: `check_credit_limit` ([sales_invoice.py:709](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:709)).
- GL details → [flows/accounting-flow.md](../flows/accounting-flow.md). Tax math → [flows/taxes-and-totals.md](../flows/taxes-and-totals.md). Payment schedule → [flows/payments-flow.md](../flows/payments-flow.md).

## POS Invoice

- **File**: [pos_invoice.py](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py)
- **Class**: `POSInvoice(SalesInvoice)` ([line 31](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:31))
- **Inheritance**: `SalesInvoice → SellingController → ...`
- **Hooks implemented**:
  - `validate` ([line 200](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:200)) — enforces `is_pos=1`, calls `super(SalesInvoice, self).validate()` (i.e. **skips** SalesInvoice.validate, jumps straight to SellingController.validate), then POS-specific: `validate_pos_opening_entry`, `validate_is_pos_using_sales_invoice`, `validate_auto_set_posting_time`, `validate_mode_of_payment`, `validate_stock_availablility`, `validate_return_items_qty`, `validate_payment_amount`, `validate_loyalty_transaction`, `validate_company_with_pos_company`, `validate_full_payment`, `update_packing_list`.
  - `before_submit` ([line 238](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:238)) — `set_outstanding_amount`.
  - `on_submit` ([line 241](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:241)) — Loyalty point entries (make/delete as needed), `check_phone_payments`, SABB creation for returns + submission, `clear_unallocated_mode_of_payments`, consolidation for Sales-Invoice-mode returns.
  - `before_cancel` ([line 267](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:267)) — blocks cancel if `consolidated_invoice` submitted (must cancel POS Closing Entry first).
  - `on_cancel` ([line 286](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:286)) — `super(SalesInvoice, self).on_cancel()` (skip SI.on_cancel), delete loyalty entries, set status `Cancelled`.
- **Notes**:
  - POS Invoices are **not** consolidated into GL directly. `consolidate_pos_invoices` ([pos_invoice_merge_log.py](../../erpnext/accounts/doctype/pos_invoice_merge_log/pos_invoice_merge_log.py)) runs at POS Closing Entry submit to merge POS Invoices into a single Sales Invoice that **is** posted to GL.
  - `is_created_using_pos=1` + `is_consolidated=0` + `pos_closing_entry IS NULL` = unmerged (still eligible for closing).
  - Ignored linked doctypes on cancel: `["Payment Ledger Entry", "Serial and Batch Bundle"]`.

## POS Profile

- **File**: [pos_profile.py](../../erpnext/accounts/doctype/pos_profile/pos_profile.py)
- **Class**: `POSProfile(Document)` ([line 16](../../erpnext/accounts/doctype/pos_profile/pos_profile.py:16))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 78](../../erpnext/accounts/doctype/pos_profile/pos_profile.py:78)) — `validate_all_link_fields`, `validate_duplicate_groups`, `validate_payment_methods`, `validate_default_profile`, `validate_disabled`, `validate_accounting_dimensions`.
  - `on_update` ([line 203](../../erpnext/accounts/doctype/pos_profile/pos_profile.py:203)).
- **Notes**: POS Profile is the per-user / per-company POS configuration — default warehouse, customer, cost center, mode of payment accounts, tax template. `validate_payment_methods` enforces that every listed payment mode has a `Mode of Payment Account` for the profile's company.

## POS Opening Entry

- **File**: [pos_opening_entry.py](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py)
- **Class**: `POSOpeningEntry(StatusUpdater)` ([line 12](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py:12))
- **Inheritance**: `StatusUpdater → Document` (bypasses the SellingController chain since no item-level cascade).
- **Hooks implemented**:
  - `validate` ([line 38](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py:38)) — `validate_pos_profile_and_cashier`, `check_open_pos_exists` (enforces single-open per profile), `check_user_already_assigned`, `validate_payment_method_account`, `set_status`.
  - `on_submit` ([line 99](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py:99)) — `set_status(update=True)` → `Open`.
  - `before_cancel` ([line 102](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py:102)) — `check_poe_is_cancellable`: blocks if unconsolidated POS Invoices exist in this period.
  - `on_cancel` ([line 105](../../erpnext/accounts/doctype/pos_opening_entry/pos_opening_entry.py:105)) — status → `Cancelled`, publish realtime event.
- **Status map**: [status_updater.py:149](../../erpnext/controllers/status_updater.py:149) — `Draft` / `Open` (docstatus=1, no closing entry yet) / `Closed` (closing entry linked) / `Cancelled`.
- **Notes**: `balance_details` child table records opening cash/bank balance per mode of payment.

## POS Closing Entry

- **File**: [pos_closing_entry.py](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py)
- **Class**: `POSClosingEntry(StatusUpdater)` ([line 21](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:21))
- **Inheritance**: `StatusUpdater → Document`
- **Hooks implemented**:
  - `validate` ([line 62](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:62)) — `set_posting_date_and_time`, `fetch_invoice_type` (reads `POS Settings.invoice_type`), `validate_pos_opening_entry` (must be `Open`), `validate_invoice_mode` (POS-Invoice mode vs Sales-Invoice mode, no mixing).
  - `on_submit` ([line 211](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:211)) — `consolidate_pos_invoices(closing_entry=self)` (from `pos_invoice_merge_log`), publishes realtime, `update_sales_invoices_closing_entry`.
  - `before_cancel` ([line 221](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:221)) — `check_pce_is_cancellable`.
  - `on_cancel` ([line 224](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:224)) — `unconsolidate_pos_invoices(closing_entry=self)`.
- **Status map**: [status_updater.py:155](../../erpnext/controllers/status_updater.py:155) — `Draft` / `Submitted` / `Queued` (async consolidation in progress) / `Failed` / `Cancelled`.
- **Notes**: `consolidate_pos_invoices` is the moment POS activity becomes a GL-posted Sales Invoice. `retry` ([line 229](../../erpnext/accounts/doctype/pos_closing_entry/pos_closing_entry.py:229)) re-runs consolidation if it failed.

## Customer

- **File**: [customer.py](../../erpnext/selling/doctype/customer/customer.py)
- **Class**: `Customer(TransactionBase)` ([line 31](../../erpnext/selling/doctype/customer/customer.py:31))
- **Inheritance**: `TransactionBase → Document` (master, not in the SellingController chain).
- **Hooks implemented**:
  - `onload` ([line 101](../../erpnext/selling/doctype/customer/customer.py:101)) — address + contact + dashboard.
  - `autoname` ([line 110](../../erpnext/selling/doctype/customer/customer.py:110)) — switches on `cust_master_name` (Selling Settings).
  - `validate` ([line 174](../../erpnext/selling/doctype/customer/customer.py:174)) — `validate_customer_group`, `validate_party_accounts`, `validate_credit_limit_on_change` ([line 372](../../erpnext/selling/doctype/customer/customer.py:372)), `set_loyalty_program`, `check_customer_group_change`, `validate_default_bank_account`, `validate_internal_customer` ([line 239](../../erpnext/selling/doctype/customer/customer.py:239)), `add_role_for_user`, `validate_currency_for_receivable_payable_and_advance_account`, sales-team total-percentage check.
  - `after_insert` ([line 170](../../erpnext/selling/doctype/customer/customer.py:170)) — updates Lead status to `Converted` if sourced from Lead.
  - `on_update` ([line 261](../../erpnext/selling/doctype/customer/customer.py:261)) — name-vs-group guard, primary address / contact creation, lead-status update, link-address-and-contact, copy-communication from Lead, `update_customer_groups`.
- **Module-level functions**:
  - [check_credit_limit](../../erpnext/selling/doctype/customer/customer.py:599) — credit-limit throw.
  - [get_credit_limit](../../erpnext/selling/doctype/customer/customer.py) — resolves limit with fallback customer → customer group → company.
  - [make_contact](../../erpnext/selling/doctype/customer/customer.py) / [make_address](../../erpnext/selling/doctype/customer/customer.py) — primary-record factories.
- **Notes**: `is_internal_customer=1` + `represents_company` gates inter-company flows. `customer_primary_contact` / `customer_primary_address` are enforced 1:1 and updated on-change. Loyalty program assignment requires `validate_loyalty_points` ([loyalty_program.py](../../erpnext/accounts/doctype/loyalty_program/loyalty_program.py)).

## Customer Group

- **File**: [customer_group.py](../../erpnext/setup/doctype/customer_group/customer_group.py)
- **Class**: `CustomerGroup(NestedSet)` ([line 10](../../erpnext/setup/doctype/customer_group/customer_group.py:10))
- **Inheritance**: Frappe's `NestedSet` (tree DocType with `lft` / `rgt`).
- **Hooks implemented**:
  - `validate` ([line 36](../../erpnext/setup/doctype/customer_group/customer_group.py:36)) — `validate_currency_for_receivable_and_advance_account` ([line 41](../../erpnext/setup/doctype/customer_group/customer_group.py:41)).
  - `on_update` ([line 71](../../erpnext/setup/doctype/customer_group/customer_group.py:71)).
- **Notes**: Tree DocType; parent is `parent_customer_group`. Carries `payment_terms`, `default_price_list`, per-company credit limits, per-company Party Accounts (for Receivable account override). Consulted by `Customer.validate` via `validate_customer_group` ([customer.py:361](../../erpnext/selling/doctype/customer/customer.py:361)).

## Sales Person

- **File**: [sales_person.py](../../erpnext/setup/doctype/sales_person/sales_person.py)
- **Class**: `SalesPerson(NestedSet)` ([line 19](../../erpnext/setup/doctype/sales_person/sales_person.py:19))
- **Inheritance**: `NestedSet`
- **Hooks implemented**:
  - `validate` ([line 45](../../erpnext/setup/doctype/sales_person/sales_person.py:45)) — `validate_sales_person` ([line 90](../../erpnext/setup/doctype/sales_person/sales_person.py:90)), `validate_employee_id` ([line 117](../../erpnext/setup/doctype/sales_person/sales_person.py:117)).
  - `on_update` ([line 86](../../erpnext/setup/doctype/sales_person/sales_person.py:86)).
- **Notes**: Tree DocType. Linked from `Sales Team` child tables. Disabled sales persons throw at `SellingController.validate_sales_team` ([selling_controller.py:258](../../erpnext/controllers/selling_controller.py:258)). Monthly / quarterly targets live on `Sales Person Target Variance` (child table pattern).

## Sales Team

- **File**: [sales_team.py](../../erpnext/selling/doctype/sales_team/sales_team.py)
- **Class**: `SalesTeam(Document)` ([line 8](../../erpnext/selling/doctype/sales_team/sales_team.py:8)) — child DocType (no `istable=1` methods overridden).
- **Inheritance**: `Document`
- **Notes**: Child table attached to `Customer`, `Quotation`, `Sales Order`, `Delivery Note`, `Sales Invoice`. Columns: `sales_person`, `allocated_percentage`, `allocated_amount`, `commission_rate`, `incentives`. Commission math lives in `SellingController.calculate_contribution` ([selling_controller.py:230](../../erpnext/controllers/selling_controller.py:230)) — sum of `allocated_percentage` must be 100 ([selling_controller.py:256](../../erpnext/controllers/selling_controller.py:256)).

## Sales Partner

- **File**: [sales_partner.py](../../erpnext/setup/doctype/sales_partner/sales_partner.py)
- **Class**: `SalesPartner(WebsiteGenerator)` ([line 11](../../erpnext/setup/doctype/sales_partner/sales_partner.py:11))
- **Inheritance**: `WebsiteGenerator` (Frappe website-publishable DocType).
- **Hooks implemented**:
  - `validate` ([line 49](../../erpnext/setup/doctype/sales_partner/sales_partner.py:49)).
- **Notes**: Partner/channel identity with `commission_rate`, linked from Customer and from Quotation (`referral_sales_partner`), carried down through `_make_sales_order` → target SO `sales_partner` ([quotation.py:411](../../erpnext/selling/doctype/quotation/quotation.py:411)).

## Sales Taxes and Charges Template

- **File**: [sales_taxes_and_charges_template.py](../../erpnext/accounts/doctype/sales_taxes_and_charges_template/sales_taxes_and_charges_template.py)
- **Class**: `SalesTaxesandChargesTemplate(Document)` ([line 18](../../erpnext/accounts/doctype/sales_taxes_and_charges_template/sales_taxes_and_charges_template.py:18))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 39](../../erpnext/accounts/doctype/sales_taxes_and_charges_template/sales_taxes_and_charges_template.py:39)) — calls module-level `validate_disabled` + `validate_for_tax_category`.
- **Notes**: Template applied to QTN / SO / DN / SI via `taxes_and_charges` link. `SellingController.set_missing_lead_customer_details` ([selling_controller.py:162](../../erpnext/controllers/selling_controller.py:162)) fetches tax rows via [get_taxes_and_charges](../../erpnext/controllers/accounts_controller.py). Tax math pipeline → [flows/taxes-and-totals.md](../flows/taxes-and-totals.md).

## Pricing Rule

- **File**: [pricing_rule.py](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py)
- **Class**: `PricingRule(Document)` ([line 20](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:20))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 130](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:130)) — `validate_mandatory` ([line 159](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:159)), `validate_applicable_for_selling_or_buying` ([line 202](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:202)), `validate_min_max_qty` / `validate_min_max_amt`, `validate_max_discount`, `validate_price_list_with_currency`, `validate_dates`, `validate_condition` ([line 306](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:306)), `validate_rate_or_discount`, `validate_recursion` ([line 230](../../erpnext/accounts/doctype/pricing_rule/pricing_rule.py:230)), `validate_mixed_with_recursion`.
- **Notes**: Applied via `get_pricing_rules` in [pricing_rule/utils.py](../../erpnext/accounts/doctype/pricing_rule/utils.py) during `get_item_details` (selling + buying). `apply_on` can be Item / Item Group / Brand / Transaction. `rate_or_discount` ∈ {`Rate`, `Discount Percentage`, `Discount Amount`, `Free Item Quantity`}. Referenced by `PricingRuleDetail` child rows on transactions.

## Promotional Scheme

- **File**: [promotional_scheme.py](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py)
- **Class**: `PromotionalScheme(Document)` ([line 77](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py:77))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 145](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py:145)) — `validate_applicable_for`, `validate_pricing_rules` ([line 163](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py:163)), `validate_mixed_with_recursion`.
  - `on_update` ([line 212](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py:212)).
- **Errors**: `TransactionExists` ([line 73](../../erpnext/accounts/doctype/promotional_scheme/promotional_scheme.py:73)).
- **Notes**: Generates / updates `Pricing Rule` records in bulk via `on_update`. Used to model tiered discounts ("buy 10 get 1 free", "amount ≥ X → Y% off").

## Shipping Rule

- **File**: [shipping_rule.py](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py)
- **Class**: `ShippingRule(Document)` ([line 27](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:27))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 55](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:55)) — `validate_from_to_values` ([line 60](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:60)), `validate_countries` ([line 123](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:123)), `validate_overlapping_shipping_rule_conditions` ([line 175](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:175)).
- **Errors**: `OverlappingConditionError`, `FromGreaterThanToError`, `ManyBlankToValuesError` ([lines 15-25](../../erpnext/accounts/doctype/shipping_rule/shipping_rule.py:15)).
- **Notes**: Referenced from QTN / SO / DN / SI via `shipping_rule` link. `SellingController.remove_shipping_charge` ([selling_controller.py:178](../../erpnext/controllers/selling_controller.py:178)) strips the Actual-type tax row when the rule is cleared.

## Blanket Order

- **File**: [blanket_order.py](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py)
- **Class**: `BlanketOrder(Document)` ([line 15](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:15))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `validate` ([line 43](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:43)) — `validate_dates` ([line 49](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:49)), `validate_duplicate_items` ([line 90](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:90)), `validate_item_qty` ([line 121](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:121)).
- **Notes**: `blanket_order_type` ∈ {`Selling`, `Purchasing`}. Module-level [validate_against_blanket_order](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:168) consumed by `SalesOrder.validate` ([sales_order.py:252](../../erpnext/selling/doctype/sales_order/sales_order.py:252)). Allowance `Selling Settings.blanket_order_allowance` bounds over-booking.

## Product Bundle

- **File**: [product_bundle.py](../../erpnext/selling/doctype/product_bundle/product_bundle.py)
- **Class**: `ProductBundle(Document)` ([line 12](../../erpnext/selling/doctype/product_bundle/product_bundle.py:12))
- **Inheritance**: `Document`
- **Hooks implemented**:
  - `autoname` ([line 29](../../erpnext/selling/doctype/product_bundle/product_bundle.py:29)).
  - `validate` ([line 32](../../erpnext/selling/doctype/product_bundle/product_bundle.py:32)) — `validate_main_item` ([line 76](../../erpnext/selling/doctype/product_bundle/product_bundle.py:76)) (parent `new_item_code` must have `is_stock_item=0`), `validate_child_items` ([line 83](../../erpnext/selling/doctype/product_bundle/product_bundle.py:83)), `validate_child_items_qty_non_zero`.
- **Notes**: Parent Item is a **non-stock** item; children in `items` child table carry actual stock qtys. Selling cascade expands bundles into `Packed Item` rows via `make_packing_list`. `SellingController.has_product_bundle` ([selling_controller.py:407](../../erpnext/controllers/selling_controller.py:407)) caches lookup per-controller-instance. Never writes SLE against the parent; SLEs are written against the children ([selling_controller.py:349](../../erpnext/controllers/selling_controller.py:349)).

## Stock Reservation Entry

> Primary card: **[modules/stock-doctypes.md#stock-reservation-entry](./stock-doctypes.md#stock-reservation-entry)**.

Selling-side entry points:

- Created on **Sales Order submit** when `reserve_stock=1`: [SalesOrder.create_stock_reservation_entries](../../erpnext/selling/doctype/sales_order/sales_order.py:839) → [create_stock_reservation_entries_for_so_items](../../erpnext/stock/doctype/stock_reservation_entry/stock_reservation_entry.py).
- Consumed on **Delivery Note submit** (and **Sales Invoice submit** when `update_stock=1`) via [SellingController.update_stock_reservation_entries](../../erpnext/controllers/selling_controller.py:895), which walks open SREs `(voucher_type='Sales Order', voucher_no=against_sales_order, voucher_detail_no=so_detail, warehouse)` and increments `delivered_qty`.
- Cancelled on **Sales Order cancel** via [SalesOrder.cancel_stock_reservation_entries](../../erpnext/selling/doctype/sales_order/sales_order.py:859).
- DN cancel reverses the consumption (`_action='cancel'` branch at [selling_controller.py:976](../../erpnext/controllers/selling_controller.py:976)).
- Gated by `Stock Settings.enable_stock_reservation`. If `Selling Settings.dont_reserve_sales_order_qty_on_sales_return` is set, returns skip the reservation write-back.

## Installation Note

- **File**: [installation_note.py](../../erpnext/selling/doctype/installation_note/installation_note.py)
- **Class**: `InstallationNote(TransactionBase)` — not SellingController (no items stock flow).
- **Hooks implemented**:
  - `validate`, `on_submit`, `on_cancel` — cascade updates `Delivery Note Item.installed_qty` via `update_prevdoc_status` ([installation_note.py:127](../../erpnext/selling/doctype/installation_note/installation_note.py:127), [line 131](../../erpnext/selling/doctype/installation_note/installation_note.py:131)) with its own `status_updater` targeting `Delivery Note Item.installed_qty`.
- **Notes**: Purely post-delivery tracking; no SLE, no GL. Mapped from Delivery Note via [make_installation_note](../../erpnext/stock/doctype/delivery_note/delivery_note.py:1018).

## Selling Settings

- **File**: [selling_settings.py](../../erpnext/selling/doctype/selling_settings/selling_settings.py)
- **Class**: `SellingSettings(Document)` ([line 25](../../erpnext/selling/doctype/selling_settings/selling_settings.py:25)) — Single DocType.
- **Hooks implemented**:
  - `validate` ([line 72](../../erpnext/selling/doctype/selling_settings/selling_settings.py:72)) — persists defaults (`cust_master_name`, `customer_group`, `territory`, `maintain_same_sales_rate`, `editable_price_list_rate`, `selling_price_list`) via `frappe.db.set_default`, syncs customer naming series, fallback-price-list warning, toggles commission / UTM sections via property setters when the flag changes.
  - `on_update` ([line 67](../../erpnext/selling/doctype/selling_settings/selling_settings.py:67)) — `toggle_hide_tax_id`, `toggle_editable_rate_for_bundle_items`, `toggle_discount_accounting_fields`.
- **Notes**: All flags enumerated in [modules/selling.md#selling-settings](./selling.md#selling-settings). Changes to `enable_tracking_sales_commissions` / `enable_utm` / `enable_discount_accounting` / `hide_tax_id` / `editable_bundle_item_rates` write Property Setters to the underlying DocType metas — effects persist across systems without code changes.

## Related

- [flows/selling-flow.md](../flows/selling-flow.md) — end-to-end QTN → SO → DN → SI cascade.
- [modules/selling.md](./selling.md) — module map.
- [modules/accounts-doctypes.md](./accounts-doctypes.md) — SI, PI, JE, PE, POS Invoice (GL focus), Period Closing Voucher.
- [modules/stock-doctypes.md](./stock-doctypes.md) — DN, Pick List, Packing Slip, SRE, Warehouse, Batch, Serial No.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL write path.
- [flows/stock-flow.md](../flows/stock-flow.md) — SLE write path.
- [flows/taxes-and-totals.md](../flows/taxes-and-totals.md) — tax math.
- [flows/payments-flow.md](../flows/payments-flow.md) — Payment Entry, advance flow.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy.
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — `validate → on_submit → on_cancel` order.
- [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) — hook registrations.

## Changelog

- `2026-04-17` — initial version.
