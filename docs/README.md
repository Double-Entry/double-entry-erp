# Documentation Index

Architecture and internals documentation for this ERPNext repository. Every entry carries line-level citations back into the source.

Start with [architecture/overview.md](architecture/overview.md) if you are new. Use this index as a lookup map; use each page's `Key files` section to jump into the code.

## Architecture

- [Overview](architecture/overview.md) — module map, where-to-start-tracing cheatsheet, conventions.
- [Controller hierarchy](architecture/controllers.md) — `StatusUpdater → AccountsController → StockController → SellingController / SubcontractingController → BuyingController`, with per-layer responsibilities.
- [DocType pattern](architecture/doctype-pattern.md) — schema JSON + Python controller + JS + tests, and how transaction DocTypes plug into the controller chain.
- [DocType lifecycle](architecture/doctype-lifecycle.md) — `validate → before_save → on_submit → on_cancel → on_trash` and how each controller layer contributes.
- [Hooks and overrides](architecture/hooks-and-overrides.md) — complete tour of `erpnext/hooks.py`: `doc_events`, `scheduler_events`, `regional_overrides`, `extend_doctype_class`, portal routes, boot, metadata groupings.

## Patterns

- [Regional overrides](patterns/regional-overrides.md) — `@erpnext.allow_regional` decorator + `regional_overrides` registry + `erpnext/regional/<country>/` layout.
- [Patches](patterns/patches.md) — `patches.txt` manifest, `pre_model_sync` vs `post_model_sync`, how `bench migrate` consumes them.

## Flows

- [Accounting flow](flows/accounting-flow.md) — end-to-end GL write path: `make_gl_entries`, `process_gl_map`, `save_entries`, `make_reverse_gl_entries`, round-off, freeze, PCV guard. Mermaid diagrams for Sales Invoice submit and cancel.
- [Taxes and totals](flows/taxes-and-totals.md) — `calculate_taxes_and_totals` lifecycle: item values, inclusive/exclusive taxes, item-wise breakup with error diffusion, rounding, and tax-row → GL mapping.
- [Payments flow](flows/payments-flow.md) — Payment Entry `validate`/`on_submit`/`on_cancel`, five-composer GL build, allocations / advances / FX gain-loss / deductions, Payment Reconciliation, `set_payment_schedule`.
- [Stock flow](flows/stock-flow.md) — SLE write path (`make_sl_entries` → `update_entries_after` → `update_bin_qty`), valuation branches (FIFO/LIFO/Moving Average/Batch/Serial), negative-stock gating, backdated reposting, perpetual GL bridge, rounding diff for internal transfers. Mermaid for Purchase Receipt / Delivery Note / Stock Reconciliation submit + cancel.
- [Selling flow](flows/selling-flow.md) — Quotation → Sales Order → Delivery Note → Sales Invoice cascade: `status_updater[]` contract, `update_prevdoc_status`, `billed_amt` FIFO redistribution, SO close / hold / re-open, drop-ship SO→PO→PR reverse lane, stock-reservation consumption, inter-company mirror. Mermaid sequence diagrams per stage.
- [Buying flow](flows/buying-flow.md) — Material Request → RFQ → Supplier Quotation → Purchase Order → Purchase Receipt → Purchase Invoice cascade: `status_updater[]` contract, `update_prevdoc_status`, PO→SO drop-ship reverse lane, `update_billed_amount_based_on_po` FIFO redistribution, Stock Received But Not Billed bridge, Landed Cost Voucher revaluation, subcontracting branch to Subcontracting Order, internal-transfer `sales_incoming_rate`, return flow, inter-company mirror. Mermaid sequence diagrams per stage.
- [Subcontracting flow](flows/subcontracting-flow.md) — both coexisting flows: legacy PO/PR-embedded (`is_old_subcontracting_flow=1`) with `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied` and new SCO/SCR (`Subcontracting Order` → `Subcontracting Receipt`). Covers `SubcontractingController` dispatch (`subcontract_data`), BOM explosion vs material-transferred backflush, `make_rm_stock_entry`, supplier-warehouse SLE + GL, SCR cancel, and the inward customer-provided (`Subcontracting Inward Order`) mirror. Mermaid sequence diagrams per branch.
- [Manufacturing flow](flows/manufacturing-flow.md) — Production Plan → Work Order → Job Card → Stock Entry cascade. Covers BOM cost roll-up + explosion, sub-assembly branching (In House / Subcontract / Material Request), auto-creation of WOs / MRs / POs, Work Order status lifecycle (Not Started → In Process → Completed / Stopped / Closed), Job Card time-log + complete writeback to Work Order Operation, Stock Entry manufacturing purposes (`Material Transfer for Manufacture`, `Manufacture`, `Material Consumption for Manufacture`, `Disassemble`), BOM Update Log level-wise cost propagation cron. Mermaid sequence diagrams per stage.

## Modules

- [Accounts](modules/accounts.md) — module layout, Chart of Accounts (`root_type`/`account_type`, company scoping), accounting dimensions, cost centers, fiscal year / accounting period, tax framework, bank clearance, reports, scheduler jobs, regional hooks.
- [Accounts DocType reference cards](modules/accounts-doctypes.md) — per-doctype cards for Sales Invoice, Purchase Invoice, Journal Entry, Payment Entry, POS Invoice, Period Closing Voucher.
- [Stock](modules/stock.md) — module layout (`stock_ledger.py`, `serial_batch_bundle.py`, `valuation.py`, `utils.py`, `reorder_item.py`, `stock_balance.py`), SLE model + Bin, Serial and Batch Bundle, Warehouse tree, Item stock flags, perpetual vs periodic, valuation math, scheduler jobs, stock-related metadata registries.
- [Stock DocType reference cards](modules/stock-doctypes.md) — per-doctype cards for SLE, Bin, SABB, Delivery Note, Purchase Receipt, Stock Entry, Stock Reconciliation, Material Request, Pick List, Packing Slip, Landed Cost Voucher, Quality Inspection, Stock Reservation Entry, Repost Item Valuation, Stock Closing Entry / Balance, Warehouse, Batch, Serial No.
- [Selling](modules/selling.md) — Selling-module overview: directory layout, `SellingController` responsibilities (validations, rate floor, product-bundle expansion, target warehouse, `set_incoming_rate`), customer + credit-limit plumbing, Selling Settings knobs, scheduler jobs (`set_expired_status`), reports, POS pages, regional hooks.
- [Selling DocType reference cards](modules/selling-doctypes.md) — per-doctype cards for Quotation, Sales Order, Delivery Note, Sales Invoice, POS Invoice, POS Profile, POS Opening / Closing Entry, Customer, Customer Group, Sales Person, Sales Team, Sales Partner, Sales Taxes and Charges Template, Pricing Rule, Promotional Scheme, Shipping Rule, Blanket Order, Product Bundle, Stock Reservation Entry, Installation Note, Selling Settings.
- [Buying](modules/buying.md) — Buying-module overview: directory layout, `BuyingController` responsibilities (valuation-rate composition, asset auto-creation, internal-transfer `sales_incoming_rate`, legacy subcontracting supplied-items), `SubcontractingController` contribution, Supplier + Supplier Scorecard, Buying Settings knobs, scheduler jobs (`refresh_scorecards`, `set_expired_status`, `reorder_item`), reports, regional hooks (UAE RCM).
- [Buying DocType reference cards](modules/buying-doctypes.md) — per-doctype cards for Material Request, Request for Quotation, Supplier Quotation, Purchase Order, Purchase Receipt, Purchase Invoice (buying-side notes), Supplier, Supplier Group, Supplier Scorecard + sub-DocTypes, Landed Cost Voucher, Purchase Taxes and Charges Template, Buying Settings, Purchase Order / Receipt / Invoice Item and Supplied-Item child tables.
- [Subcontracting](modules/subcontracting.md) — module layout, `SubcontractingController` responsibilities (flow dispatcher via `subcontract_data`, BOM explosion vs transferred backflush, supplier-warehouse SLE / GL, `make_rm_stock_entry`), `SubcontractingInwardController` summary, Buying Settings knobs, scheduler jobs (none), regional hooks (none), cross-links to legacy `buying/` supplied-item child tables.
- [Subcontracting DocType reference cards](modules/subcontracting-doctypes.md) — per-doctype cards for Subcontracting Order, Subcontracting Receipt, Subcontracting BOM, Subcontracting Inward Order, SCO Item / Service Item / Supplied Item, SCR Item / Supplied Item, legacy Purchase Order Item Supplied / Purchase Receipt Item Supplied, Stock Entry subcontracting purposes.
- [Manufacturing](modules/manufacturing.md) — Manufacturing-module overview: directory layout, controller posture (no controller — all four lifecycle DocTypes sit on `Document`), master data (BOM + children, Routing, Operation, Workstation + Workstation Type), planning (Production Plan, Master Production Schedule, Sales Forecast), execution (Work Order, Job Card), Manufacturing Settings knob reference, scheduler jobs (`resume_bom_cost_update_jobs` cron, `auto_update_latest_price_in_all_boms` daily), cross-module interactions, regional hooks (none).
- [Manufacturing DocType reference cards](modules/manufacturing-doctypes.md) — per-doctype cards for BOM + 6 children, BOM Creator + child, BOM Update Log / Batch / Tool, Routing, Operation + Sub Operation, Workstation + Workstation Type + 4 children, Plant Floor, Production Plan + 8 children, Master Production Schedule + child, Sales Forecast + child, Work Order + Work Order Item + Work Order Operation, Job Card + 5 children, Downtime Entry, Manufacturing Settings, Blanket Order + child (cross-module), Stock Entry manufacturing purposes.
- [Regional](modules/regional.md) — Regional-module inventory: directory layout, `regional_overrides` catalogue with purposes, `doc_events` per country, `@erpnext.allow_regional` stub slots, per-country deep dives (United Arab Emirates, Italy, United States, South Africa, Australia, Turkey, Saudi Arabia, France, Nepal), shared Italy FatturaPA inbound + outbound, UAE RCM flow, cross-module touchpoints. Mermaid diagrams for UAE PI submit with RCM, Italy SI submit outbound, FatturaPA inbound.
- [Regional DocType reference cards](modules/regional-doctypes.md) — per-doctype cards for Lower Deduction Certificate, Import Supplier Invoice, UAE VAT Settings + UAE VAT Account, South Africa VAT Settings, plus condensed per-country DocType shipping summary.

## ADRs

_No Architecture Decision Records yet._

## Writing conventions

- Every architectural claim cites `[name](path:line)`.
- Mermaid diagrams use `TD` for hierarchies and `LR` / `sequenceDiagram` for flows.
- Solid arrows are synchronous calls; dashed arrows are event-based / registration-time wiring.
- Each document's frontmatter carries `last_updated`, `commit`, `scope`, and `status`.
