---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: selling
status: complete
related_docs:
  - ../architecture/overview.md
  - ../architecture/controllers.md
  - ../flows/selling-flow.md
  - ../flows/accounting-flow.md
  - ../flows/stock-flow.md
  - ./selling-doctypes.md
---

# Selling Module

> **TL;DR:** The Selling module owns pre-invoice documents (`Quotation`, `Sales Order`), the Customer master and its ecosystem (`Customer Group`, `Sales Person`, `Sales Team`, `Sales Partner`, `Customer Credit Limit`), the selling-side settings + pricing primitives (`Selling Settings`, `Product Bundle`), and the `SellingController` that underpins every selling-side transaction (QTN / SO / DN / SI / POS-INV). Selling code is thin on bookkeeping — it delegates GL to the Accounts module and SLE to the Stock module. What's **unique** here is the qty / amount cascade across the selling chain, selling-rate validations, customer credit limits, product-bundle expansion into `Packed Item` rows, and drop-ship / inter-company / target-warehouse plumbing. Pair this document with [flows/selling-flow.md](../flows/selling-flow.md) (end-to-end QTN → SO → DN → SI cascade) and [modules/selling-doctypes.md](./selling-doctypes.md) (per-DocType reference cards).

## Scope of this document

- **Covered here:** module layout, `SellingController` responsibilities, selling-settings knobs, customer credit limit, product bundle expansion, selling-side scheduler jobs, selling-only reports & pages, regional hooks touching selling.
- **Covered elsewhere:** QTN → SO → DN → SI cascade ([flows/selling-flow.md](../flows/selling-flow.md)); GL writes on SI submit ([flows/accounting-flow.md](../flows/accounting-flow.md)); SLE on DN submit ([flows/stock-flow.md](../flows/stock-flow.md)); taxes ([flows/taxes-and-totals.md](../flows/taxes-and-totals.md)); Payment Entry / payment schedule ([flows/payments-flow.md](../flows/payments-flow.md)). Per-DocType hooks → [modules/selling-doctypes.md](./selling-doctypes.md).

## Directory layout

```
erpnext/selling/
├── __init__.py
├── doctype/                 # Selling-owned DocTypes (see below)
├── report/                  # ~24 selling reports
├── dashboard_chart/
├── selling_dashboard/
├── number_card/
├── onboarding_step/
├── module_onboarding/
├── page/
│   ├── point_of_sale/       # POS desk UI
│   └── sales_funnel/
├── print_format/
├── print_format_field_template/
├── form_tour/
├── workspace/
└── README.md
```

The selling DocTypes (in `erpnext/selling/doctype/`):

- Transactional: `quotation`, `quotation_item`, `sales_order`, `sales_order_item`, `delivery_schedule_item`, `sms_center`.
- Masters: `customer`, `customer_credit_limit`, `product_bundle`, `product_bundle_item`, `sales_team`, `sales_partner_type`, `supplier_number_at_customer`, `industry_type`, `party_specific_item`.
- Settings & misc: `selling_settings`, `installation_note`, `installation_note_item`.

Note: several DocTypes that are logically "selling" live in other modules:

- `Delivery Note` → `erpnext/stock/doctype/delivery_note/` (because it writes SLEs and inherits `SellingController`). See [modules/stock-doctypes.md#delivery-note](./stock-doctypes.md#delivery-note).
- `Sales Invoice`, `POS Invoice`, `POS Profile`, `POS Opening Entry`, `POS Closing Entry` → `erpnext/accounts/doctype/` (GL side). See [modules/accounts-doctypes.md](./accounts-doctypes.md).
- `Pricing Rule`, `Promotional Scheme`, `Shipping Rule`, `Sales Taxes and Charges Template` → `erpnext/accounts/doctype/`.
- `Sales Person`, `Sales Partner`, `Customer Group`, `Territory` → `erpnext/setup/doctype/`.
- `Blanket Order` → `erpnext/manufacturing/doctype/blanket_order/`.
- `Stock Reservation Entry` → `erpnext/stock/doctype/stock_reservation_entry/`. See [modules/stock-doctypes.md#stock-reservation-entry](./stock-doctypes.md#stock-reservation-entry).

## `SellingController`

File: [erpnext/controllers/selling_controller.py](../../erpnext/controllers/selling_controller.py:18). Position in the chain:

```
Document → StatusUpdater → TransactionBase → AccountsController → StockController → SellingController
```

See [architecture/controllers.md](../architecture/controllers.md) for the full hierarchy.

Consumers (direct subclasses):

- [Quotation](../../erpnext/selling/doctype/quotation/quotation.py:18)
- [SalesOrder](../../erpnext/selling/doctype/sales_order/sales_order.py:55)
- [DeliveryNote](../../erpnext/stock/doctype/delivery_note/delivery_note.py:26)
- [SalesInvoice](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:59)
- [POSInvoice](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:31) (via `SalesInvoice`)

### Responsibilities

`SellingController.validate` ([selling_controller.py:59](../../erpnext/controllers/selling_controller.py:59)) runs **before** its subclasses' own `validate`:

| Method | Purpose | Line |
|---|---|---|
| `validate_items` | `is_sales_item=1` check via `buying_controller.validate_item_type(self, 'is_sales_item', 'sales')` | [889](../../erpnext/controllers/selling_controller.py:889) |
| `validate_max_discount` | Throws if `discount_percentage > Item.max_discount` (skipped for debit / return) | [272](../../erpnext/controllers/selling_controller.py:272) |
| `validate_selling_price` | Gated by `Selling Settings.validate_selling_price`. For stock items: floor is `last_purchase_rate × conversion_factor` and `valuation_rate` (for SO/QTN) or `incoming_rate` (DN/SI). Bypassed for `is_internal_customer`. | [293](../../erpnext/controllers/selling_controller.py:293) |
| `set_qty_as_per_stock_uom` | `stock_qty = qty × conversion_factor`; `Stock Settings.allow_to_edit_stock_uom_qty_for_sales` toggles override. | [280](../../erpnext/controllers/selling_controller.py:280) |
| `set_po_nos` | Aggregates linked Purchase Order numbers across SO / DN / SI into parent `po_no`. | [752](../../erpnext/controllers/selling_controller.py:752) |
| `set_gross_profit` | On SO / QTN: `(stock_uom_rate - valuation_rate) × stock_qty` per item. | [787](../../erpnext/controllers/selling_controller.py:787) |
| `set_default_income_account_for_item` | Per-item income-account defaulting (module-level function). | [1044](../../erpnext/controllers/selling_controller.py:1044) |
| `set_customer_address` | Fills `address_display`, `shipping_address`, `company_address_display`, `dispatch_address` via `render_address`. | [795](../../erpnext/controllers/selling_controller.py:795) |
| `validate_for_duplicate_items` | Gated by `Selling Settings.allow_multiple_items`; scope differs SO / QTN vs DN vs SI. | [809](../../erpnext/controllers/selling_controller.py:809) |
| `validate_target_warehouse` | Target warehouse ≠ source warehouse; warns if `target_warehouse` is set without `is_internal_customer`. | [872](../../erpnext/controllers/selling_controller.py:872) |
| `validate_auto_repeat_subscription_dates` | (inherited plumbing reused). | — |
| `set_serial_and_batch_bundle` | Both for `items` and `packed_items` tables. | [75](../../erpnext/controllers/selling_controller.py:75) |

### `set_missing_values`

[selling_controller.py:109](../../erpnext/controllers/selling_controller.py:109) — runs:

1. `set_missing_lead_customer_details` — for QTN with `quotation_to='Lead'` pulls from Lead; for `quotation_to='Customer'` / Sales Order / DN / SI fetches `_get_party_details` (from [accounts/party.py](../../erpnext/accounts/party.py)). Populates address, contact, sales team, payment terms, taxes-and-charges template.
2. `set_price_list_and_item_details` — sets `Selling` price-list currency, then `set_missing_item_details` (inherited).
3. `set_company_contact_person` — defaults to `Company.default_sales_contact` if the doc has that field.

### `set_incoming_rate` (DN / SI only)

[selling_controller.py:501](../../erpnext/controllers/selling_controller.py:501) — resolves the cost basis for outgoing stock moves on Delivery Note and on Sales Invoice when `update_stock=1` or `is_internal_transfer`. Branches:

- **Skip non-stock items.**
- **Expired-batch standalone credit note** with `Selling Settings.set_zero_rate_for_expired_batch=1` → `incoming_rate = 0`.
- **Normal outward or return of non-serial/batch item on Moving Average** → pull via `stock.utils.get_incoming_rate(...)`, which replays the SLE up to `posting_datetime` ([stock/utils.py:242](../../erpnext/stock/utils.py:242)).
- **Return against a reference invoice** (`return_against` set) → `get_rate_for_return` from [sales_and_purchase_return.py](../../erpnext/controllers/sales_and_purchase_return.py) mirrors the original item cost.
- **Internal transfer** — if `update_stock=1` / DN flow, `incoming_rate = rate × conversion_factor` is written back onto the row (so the GL picks up rate × qty). `Stock Settings.allow_internal_transfer_at_arms_length_price` lets a different rate survive. On mismatch, `discount_percentage`, `discount_amount`, `margin_rate_or_amount` are zeroed to prevent double-discount surprises ([selling_controller.py:650](../../erpnext/controllers/selling_controller.py:650)).

See [flows/stock-flow.md](../flows/stock-flow.md) for the SLE writer that consumes this rate and [flows/accounting-flow.md](../flows/accounting-flow.md) for the GL bridge.

### `update_stock_ledger`

[selling_controller.py:661](../../erpnext/controllers/selling_controller.py:661) — for each item in `get_item_list` (expanding product bundles into their packed items):

- Skip non-stock items or zero qty.
- Order of SLE writes:
  - On **submit non-return** or **cancel return**: source warehouse (outward) first.
  - On **cancel non-return** or **submit return**: source warehouse last; target warehouse in between (so SN inward precedes outward on cancels and returns, to keep serial-no state consistent).
- Calls `make_sl_entries` on `StockController`, which funnels to module-level `stock.stock_ledger.make_sl_entries`.

`update_reserved_qty` ([selling_controller.py:478](../../erpnext/controllers/selling_controller.py:478)) — maps SO items to `Sales Order.update_reserved_qty` for the linked SO, which re-aggregates `Bin.reserved_qty`.

### `get_item_list` and product bundles

[selling_controller.py:349](../../erpnext/controllers/selling_controller.py:349) — when an item has a `Product Bundle` ([product_bundle.py:12](../../erpnext/selling/doctype/product_bundle/product_bundle.py:12)), the SLE list is built from the **packed_items** child table (each bundle child × parent qty). Non-bundle items land as a single row. This is why `update_stock_ledger` never writes SLEs for the parent bundle item itself — the bundle is only a pricing / delivery unit, never a stock unit.

The expansion is driven by [make_packing_list](../../erpnext/stock/doctype/packed_item/packed_item.py) called in QTN / SO / DN validate.

### Sales team & commission

[selling_controller.py:207](../../erpnext/controllers/selling_controller.py:207) — `calculate_commission` + `calculate_contribution`. Requires `sales_team` child table and `commission_rate`. Each Sales Team member's `allocated_percentage` must sum to 100 ([selling_controller.py:253](../../erpnext/controllers/selling_controller.py:253)). Individual `commission_rate` per member contributes to `incentives`. Disabled Sales Persons throw ([selling_controller.py:258](../../erpnext/controllers/selling_controller.py:258)).

UI section visibility toggled by `Selling Settings.enable_tracking_sales_commissions` via [toggle_tracking_sales_commissions_section](../../erpnext/selling/doctype/selling_settings/selling_settings.py:201).

## Customer & credit limits

[Customer](../../erpnext/selling/doctype/customer/customer.py:31) inherits from `TransactionBase`, **not** `SellingController` — masters don't go through the transactional chain.

Key hooks:

- `autoname` ([customer.py:110](../../erpnext/selling/doctype/customer/customer.py:110)) — switches on `cust_master_name` default (`Customer Name` / `Naming Series` / `Auto Name`) set in Selling Settings.
- `validate` ([customer.py:174](../../erpnext/selling/doctype/customer/customer.py:174)) — customer group, party accounts, credit limits, loyalty program, currency-for-receivable validation.
- `on_update` ([customer.py:261](../../erpnext/selling/doctype/customer/customer.py:261)) — primary address + primary contact creation, customer-group change propagation via `update_linked_doctypes`.
- `after_insert` → updates Lead status to `Converted`.

Credit limit enforcement: `credit_limits` child table (per Company). [check_credit_limit](../../erpnext/selling/doctype/customer/customer.py:599) function:

1. Resolves limit via `get_credit_limit(customer, company)` — falls back to `Customer Group.credit_limits` then `Company.credit_limit`.
2. If `customer_outstanding > credit_limit`, throws unless `ignore_outstanding_sales_order` is set (bypass at SO level via `Customer Credit Limit.bypass_credit_limit_check`).
3. Called from `SalesOrder.on_submit` ([sales_order.py:569](../../erpnext/selling/doctype/sales_order/sales_order.py:569)), `SalesOrder.update_status` on re-open ([sales_order.py:609](../../erpnext/selling/doctype/sales_order/sales_order.py:609)), `DeliveryNote.check_credit_limit` ([delivery_note.py:571](../../erpnext/stock/doctype/delivery_note/delivery_note.py:571)), `SalesInvoice.check_credit_limit` ([sales_invoice.py:709](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:709)), and `SalesOrder.on_update_after_submit` ([sales_order.py:653](../../erpnext/selling/doctype/sales_order/sales_order.py:653)).

## Selling Settings

File: [selling_settings.py](../../erpnext/selling/doctype/selling_settings/selling_settings.py:25). A Single DocType (one row).

Key knobs wired into controllers and flows:

| Flag | Consumer | Effect |
|---|---|---|
| `cust_master_name` | `Customer.autoname` | Customer naming strategy. |
| `allow_multiple_items` | `SellingController.validate_for_duplicate_items` | Allows same item on multiple rows in QTN/SO/DN/SI. |
| `allow_negative_rates_for_items` | `StatusUpdater.validate_qty` at [status_updater.py:284](../../erpnext/controllers/status_updater.py:284) | Skips negative-rate check. |
| `allow_sales_order_creation_for_expired_quotation` | `make_sales_order` at [quotation.py:363](../../erpnext/selling/doctype/quotation/quotation.py:363) | Bypasses valid-till gate. |
| `allow_zero_qty_in_quotation` / `allow_zero_qty_in_sales_order` | `Quotation.set_has_unit_price_items` / `SalesOrder.set_has_unit_price_items` | "Unit price" rows (qty=0 placeholders). |
| `allow_against_multiple_purchase_orders` | `SalesOrder.validate_po` at [sales_order.py:347](../../erpnext/selling/doctype/sales_order/sales_order.py:347) | Suppresses duplicate-PO-number warning. |
| `allow_delivery_of_overproduced_qty` | Manufacturing → Delivery cross-check. | — |
| `blanket_order_allowance` | `validate_against_blanket_order` at [blanket_order.py:168](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:168) | % over-booking allowance against blanket. |
| `customer_group` / `territory` | Defaults for new Customers. | — |
| `deliver_secondary_items` | DN packed-items treatment. | — |
| `dn_required` | `Customer.dn_required` inheritance; DN-before-SI enforcement. | — |
| `so_required` | Same, SO-before-SI enforcement. | — |
| `dont_reserve_sales_order_qty_on_sales_return` | SRE consumption on return path. | — |
| `editable_bundle_item_rates` | Property setter on `Packed Item.rate` readonly flag. | [selling_settings.py:131](../../erpnext/selling/doctype/selling_settings/selling_settings.py:131) |
| `editable_price_list_rate` | Price-list edit permission. | — |
| `enable_cutoff_date_on_bulk_delivery_note_creation` | SO → DN bulk flow. | — |
| `enable_discount_accounting` | Property setter on `Sales Invoice Item.discount_account` hidden flag + mandatory_depends_on. | [selling_settings.py:143](../../erpnext/selling/doctype/selling_settings/selling_settings.py:143) |
| `enable_tracking_sales_commissions` | Hides commission + sales_team sections via property setter. | [selling_settings.py:201](../../erpnext/selling/doctype/selling_settings/selling_settings.py:201) |
| `enable_utm` | Hides UTM analytics section across 8 DocTypes ([selling_settings.py:13](../../erpnext/selling/doctype/selling_settings/selling_settings.py:13) for the list). | [selling_settings.py:215](../../erpnext/selling/doctype/selling_settings/selling_settings.py:215) |
| `fallback_to_default_price_list` | Price-list resolution fallback. | — |
| `hide_tax_id` | Property setter to hide `tax_id` in SO/SI/DN. | [selling_settings.py:119](../../erpnext/selling/doctype/selling_settings/selling_settings.py:119) |
| `maintain_same_sales_rate` | SO validates rate vs linked QTN; DN / SI validate rate vs linked SO. | [sales_order.py:472](../../erpnext/selling/doctype/sales_order/sales_order.py:472) |
| `maintain_same_rate_action` | `Stop` vs `Warn` for the above. | — |
| `role_to_override_stop_action` | Override role for the `Stop` case. | — |
| `sales_update_frequency` | `Each Transaction` / `Daily` / `Monthly` — gates `SalesOrder.update_project` at [sales_order.py:561](../../erpnext/selling/doctype/sales_order/sales_order.py:561). | — |
| `set_zero_rate_for_expired_batch` | `SellingController.set_incoming_rate` branch. | [selling_controller.py:537](../../erpnext/controllers/selling_controller.py:537) |
| `validate_selling_price` | Enables selling-rate floor check. | [selling_controller.py:293](../../erpnext/controllers/selling_controller.py:293) |
| `use_legacy_js_reactivity` | UI flag. | — |

`SellingSettings.on_update` ([selling_settings.py:67](../../erpnext/selling/doctype/selling_settings/selling_settings.py:67)) toggles `tax_id` hidden, bundle-item rate editability, and discount-accounting fields via property setters (persistent in the DocType meta).

## Scheduler jobs

From [hooks.py:433](../../erpnext/hooks.py:433):

- **Daily** (`scheduler_events.daily_maintenance` at [hooks.py:480](../../erpnext/hooks.py:480)):
  - `erpnext.selling.doctype.quotation.quotation.set_expired_status` ([quotation.py:488](../../erpnext/selling/doctype/quotation/quotation.py:488)) — flips submitted Quotations past `valid_till` to `Expired`, **except** those that have a Sales Order against them (the SQL `NOT EXISTS(...)` subquery preserves status for quotations that were converted).

No other selling-specific scheduler jobs. Daily-maintenance jobs that touch selling tangentially include:

- `erpnext.controllers.accounts_controller.update_invoice_status` ([hooks.py:465](../../erpnext/hooks.py:465)) — updates `Sales Invoice.status` to `Overdue` / `Paid` by outstanding amount + due date.
- `erpnext.setup.doctype.company.company.cache_companies_monthly_sales_history` ([hooks.py:470](../../erpnext/hooks.py:470)).

## Reports

From `erpnext/selling/report/`. Notable:

- `sales_analytics` — grouped totals across Customer / Item / Territory / Item Group dimensions.
- `sales_order_analysis` / `sales_order_trends` / `quotation_trends` — pipeline & trend dashboards.
- `sales_person_commission_summary` / `sales_partner_commission_summary` — commission breakdowns.
- `sales_person_target_variance_based_on_item_group` / `territory_target_variance_based_on_item_group` / `sales_partner_target_variance_based_on_item_group` — target vs actual.
- `item_wise_sales_history` / `customer_wise_item_price` — per-item/customer price/qty sheets.
- `lost_quotations`, `inactive_customers`, `customers_without_any_sales_transactions` — lead-gen / retention triage.
- `customer_credit_balance` — outstanding vs limit.
- `payment_terms_status_for_sales_order`, `pending_so_items_for_purchase_request` — SO follow-through.
- `territory_wise_sales`, `sales_person_wise_transaction_summary`, `sales_partner_transaction_summary` — channel splits.
- `available_stock_for_packing_items` — Product Bundle component stock check.

## Pages

- [`point_of_sale`](../../erpnext/selling/page/point_of_sale/) — the POS UI (Vue-based). Writes `POS Invoice` docs ([pos_invoice.py:31](../../erpnext/accounts/doctype/pos_invoice/pos_invoice.py:31)) that are later consolidated by `POS Closing Entry`.
- [`sales_funnel`](../../erpnext/selling/page/sales_funnel/) — opportunity → quotation → order funnel chart.

POS invoice behavior is detailed in [modules/selling-doctypes.md#pos-invoice](./selling-doctypes.md#pos-invoice) and GL side in [modules/accounts-doctypes.md](./accounts-doctypes.md).

## Regional hooks touching selling

From `regional_overrides` at [hooks.py:608](../../erpnext/hooks.py:608):

- **Italy** ([hooks.py:617](../../erpnext/hooks.py:617)):
  - `erpnext.controllers.accounts_controller.validate_regional` → `erpnext.regional.italy.utils.sales_invoice_validate` (replaces the no-op validation hook).
  - `erpnext.controllers.taxes_and_totals.update_itemised_tax_data` → `erpnext.regional.italy.utils.update_itemised_tax_data`.
  - Plus `doc_events` at [hooks.py:375](../../erpnext/hooks.py:375): `Sales Invoice.on_submit` / `on_cancel` → italy.utils methods; `Address.validate` → italy state-code.
- **Saudi Arabia** ([hooks.py:614](../../erpnext/hooks.py:614)) / **UAE** ([hooks.py:610](../../erpnext/hooks.py:610)): `update_itemised_tax_data` → UAE VAT variant.
- **France** ([hooks.py:609](../../erpnext/hooks.py:609)): test stub.

See [patterns/regional-overrides.md](../patterns/regional-overrides.md) for the `@erpnext.allow_regional` mechanism and [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) for the complete hook inventory.

## Website integration

From [hooks.py](../../erpnext/hooks.py):

- **Website routes** ([hooks.py:172](../../erpnext/hooks.py:172)): `/quotations`, `/orders` (SO), `/invoices` (SI), `/shipments` (DN) render portal-list views.
- **Website permissions** ([hooks.py:308](../../erpnext/hooks.py:308)): SO / QTN / SI / DN use `erpnext.controllers.website_list_for_contact.has_website_permission`.
- **Global search** ([hooks.py:636](../../erpnext/hooks.py:636)): SI index 7, SO 8, QTN 9, DN 14.
- **Shopping Cart integration** — Quotation `order_type='Shopping Cart'` branch in `make_sales_order` validates the cart-sourced quotation before conversion.

## Notification defaults

[hooks.py:258](../../erpnext/hooks.py:258) registers `reference_doctype` entries (Email Digest recipients) for Quotation, Sales Order, Sales Invoice, Delivery Note, and their supplier counterparts.

## Related

- [flows/selling-flow.md](../flows/selling-flow.md) — QTN → SO → DN → SI cascade.
- [modules/selling-doctypes.md](./selling-doctypes.md) — per-DocType reference cards.
- [modules/accounts.md](./accounts.md) — Accounts module (Sales Invoice, POS, GL).
- [modules/accounts-doctypes.md](./accounts-doctypes.md) — SI / POS-INV / POS Closing cards.
- [modules/stock.md](./stock.md) — Stock module (Delivery Note SLE writes, reservation).
- [modules/stock-doctypes.md](./stock-doctypes.md) — DN / SRE / Pick List / Packing Slip cards.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy.
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — per-event call order.
- [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) — hook registrations.
- [patterns/regional-overrides.md](../patterns/regional-overrides.md) — regional override mechanism.

## Changelog

- `2026-04-17` — initial version.
