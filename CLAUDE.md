# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ERPNext — an open-source ERP system built on the **Frappe Framework**. Python 3.14+ backend, JavaScript/Vue.js frontend. Uses MariaDB or PostgreSQL. This is a Frappe "app" that runs inside a `bench` environment.

## Development Environment

ERPNext requires the `bench` CLI (Frappe's development tool). All commands run from the `frappe-bench` directory (the parent of this repo's install location):

```bash
# Start dev server (runs Redis, MariaDB watcher, web server on :8000)
bench start

# Run a specific site
bench --site <site-name> migrate
```

## Running Tests

```bash
# Full parallel test suite
bench --site <site-name> run-parallel-tests --lightmode --app erpnext

# Single module
bench --site <site-name> run-tests --module erpnext.accounts.doctype.sales_invoice.test_sales_invoice

# Single test class/method
bench --site <site-name> run-tests --module erpnext.accounts.doctype.sales_invoice.test_sales_invoice --test test_sales_invoice_change_naming_series
```

Test files live alongside their doctypes as `test_*.py`. Test classes extend `ERPNextTestSuite` (from `erpnext/tests/utils.py`).

## Linting & Formatting

Pre-commit hooks handle everything. Run manually with:

```bash
pre-commit run --all-files
```

- **Python**: Ruff (lint + format). Line length 110, tab indentation, target Python 3.10+. Config in `pyproject.toml`.
- **JavaScript/Vue/SCSS**: Prettier + ESLint.
- JSON files use 1-space indentation (`.editorconfig`).

## Commit Convention

Conventional commits enforced by commitlint:
```
<type>(<scope>): <subject>
```
Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`, `ci`, `perf`, `revert`, `build`

Direct commits to `develop` are blocked by pre-commit hook.

## Architecture

### Frappe DocType Pattern

Every business entity is a **DocType**. Each lives in `erpnext/<module>/doctype/<doctype_name>/` and contains:
- `<doctype_name>.json` — field definitions, permissions, workflow (the schema)
- `<doctype_name>.py` — Python controller (extends `Document` or a controller class)
- `<doctype_name>.js` — client-side form script
- `test_<doctype_name>.py` — tests

### Controller Hierarchy

Transaction doctypes inherit through a chain of controllers in `erpnext/controllers/`:

```
StatusUpdater (Document)
  └── AccountsController (TransactionBase)
        └── StockController
              ├── SellingController    → Sales Order, Sales Invoice, Delivery Note, Quotation
              └── SubcontractingController
                    └── BuyingController → Purchase Order, Purchase Invoice, Purchase Receipt
```

Key behaviors at each level:
- **StatusUpdater**: tracks completion status across linked docs (e.g., ordered vs delivered qty)
- **AccountsController**: GL entries, tax calculations, payment scheduling
- **StockController**: stock ledger entries, quality inspection, batch/serial no handling
- **SellingController/BuyingController**: selling- or buying-specific validations and defaults

### hooks.py

`erpnext/hooks.py` is the central registration point — it wires up doc_events, scheduler jobs, website routes, portal menus, and boot session data. Check here first when tracing cross-cutting behavior.

### Key Modules

Modules (listed in `erpnext/modules.txt`): Accounts, Stock, Selling, Buying, Manufacturing, CRM, Projects, Assets, Support, Setup, Subcontracting, EDI, Regional, Quality Management, among others.

### Regional Overrides

Country-specific logic lives in `erpnext/regional/<country>/` and is registered via `regional_overrides` in hooks.py. This allows tax calculations, GL entries, and validations to be swapped per-country without touching core controllers.

### Patches

Database migrations live in `erpnext/patches/`. They run automatically during `bench migrate` and are registered in `patches.txt`.

## Detailed Documentation

Architecture docs with line-level source citations live under `docs/`. Start with [docs/README.md](docs/README.md) for the index.

- [docs/getting-started/README.md](docs/getting-started/README.md) — section overview + 5-minute quick start (`bench init` → `get-app` → `new-site` → `install-app` → `bench start`).
- [docs/getting-started/prerequisites.md](docs/getting-started/prerequisites.md) — Python 3.14, Node 24, MariaDB 10.6 / Postgres, Redis, `wkhtmltopdf` 0.12.6, apt packages, pre-commit toolchain pins.
- [docs/getting-started/installation.md](docs/getting-started/installation.md) — `bench init`/`get-app`/`new-site`/`install-app`, `site_config.json` keys, what `after_install` seeds (with link to `erpnext/setup/install.py`).
- [docs/getting-started/development.md](docs/getting-started/development.md) — `bench start` and the Procfile process catalogue, DB access, migrations.
- [docs/getting-started/testing-and-quality.md](docs/getting-started/testing-and-quality.md) — `run-parallel-tests`, `run-tests --module`/`--test`, `ERPNextTestSuite` rollback contract, pre-commit (Ruff/Prettier/ESLint), commitlint, `develop`-commit block.
- [docs/getting-started/operations.md](docs/getting-started/operations.md) — CLI cheatsheet, `site_config` / `common_site_config` key reference, production overview, troubleshooting, debugging tools.
- [docs/architecture/overview.md](docs/architecture/overview.md) — module map, where-to-start-tracing cheatsheet, repo-wide conventions.
- [docs/architecture/controllers.md](docs/architecture/controllers.md) — full controller hierarchy with per-layer responsibilities and `super()` call discipline.
- [docs/architecture/doctype-pattern.md](docs/architecture/doctype-pattern.md) — the four-file DocType layout and how transaction DocTypes plug into the controller chain.
- [docs/architecture/doctype-lifecycle.md](docs/architecture/doctype-lifecycle.md) — per-event call order (`validate`, `before_save`, `on_submit`, `on_cancel`, `on_trash`) through the controller chain + `doc_events`.
- [docs/architecture/hooks-and-overrides.md](docs/architecture/hooks-and-overrides.md) — exhaustive tour of `erpnext/hooks.py` registrations.
- [docs/patterns/regional-overrides.md](docs/patterns/regional-overrides.md) — how `@erpnext.allow_regional` + `regional_overrides` inject country-specific code.
- [docs/patterns/patches.md](docs/patterns/patches.md) — `patches.txt`, `pre_model_sync` vs `post_model_sync`, how to add a patch.
- [docs/flows/accounting-flow.md](docs/flows/accounting-flow.md) — end-to-end GL flow: `make_gl_entries`, `process_gl_map`, `save_entries`, `make_reverse_gl_entries`, round-off, PCV guards. Mermaid for SI submit + cancel.
- [docs/flows/taxes-and-totals.md](docs/flows/taxes-and-totals.md) — `calculate_taxes_and_totals` pipeline: inclusive/exclusive, item-wise breakup with error diffusion, rounding, tax-row → GL mapping.
- [docs/flows/payments-flow.md](docs/flows/payments-flow.md) — Payment Entry lifecycle, allocations/advances/FX/deductions, Payment Reconciliation, `set_payment_schedule`. Mermaid for PE submit.
- [docs/modules/accounts.md](docs/modules/accounts.md) — Accounts-module overview: CoA schema, dimensions + cost centers, fiscal year / accounting periods, tax framework, reports, scheduler jobs.
- [docs/modules/accounts-doctypes.md](docs/modules/accounts-doctypes.md) — per-doctype reference cards for Sales Invoice, Purchase Invoice, Journal Entry, Payment Entry, POS Invoice, Period Closing Voucher.
- [docs/flows/stock-flow.md](docs/flows/stock-flow.md) — SLE write path (`make_sl_entries` → `update_entries_after` → `update_bin_qty`), FIFO/LIFO/Moving Average/Batch/Serial valuation branches, negative-stock gates, backdated repost via `Repost Item Valuation`, perpetual GL bridge, internal-transfer rounding. Mermaid for Purchase Receipt / Delivery Note / Stock Reconciliation submit + cancel.
- [docs/modules/stock.md](docs/modules/stock.md) — Stock-module overview: directory layout, SLE model + Bin, Serial and Batch Bundle, Warehouse tree, Item stock flags, perpetual vs periodic, valuation math, scheduler jobs, stock-related hook registries.
- [docs/modules/stock-doctypes.md](docs/modules/stock-doctypes.md) — per-doctype reference cards for Stock Ledger Entry, Bin, Serial and Batch Bundle, Delivery Note, Purchase Receipt, Stock Entry, Stock Reconciliation, Material Request, Pick List, Packing Slip, Landed Cost Voucher, Quality Inspection, Stock Reservation Entry, Repost Item Valuation, Stock Closing Entry / Balance, Warehouse, Batch, Serial No.
- [docs/flows/selling-flow.md](docs/flows/selling-flow.md) — Quotation → Sales Order → Delivery Note → Sales Invoice cascade: `status_updater[]` contract, `update_prevdoc_status` chain, `billed_amt` FIFO redistribution, SO close/hold/re-open, drop-ship SO→PO→PR reverse lane via `update_delivery_status`, stock-reservation consumption, inter-company mirroring. Mermaid sequence diagrams per stage.
- [docs/modules/selling.md](docs/modules/selling.md) — Selling-module overview: `SellingController` responsibilities (selling validations, rate floor, product-bundle expansion, target warehouse, `set_incoming_rate`), customer + credit-limit plumbing, Selling Settings knobs, `set_expired_status` scheduler, reports, POS pages, regional hooks touching selling.
- [docs/modules/selling-doctypes.md](docs/modules/selling-doctypes.md) — per-doctype reference cards for Quotation, Sales Order, Delivery Note (selling-side), Sales Invoice (selling-side), POS Invoice, POS Profile, POS Opening / Closing Entry, Customer, Customer Group, Sales Person, Sales Team, Sales Partner, Sales Taxes and Charges Template, Pricing Rule, Promotional Scheme, Shipping Rule, Blanket Order, Product Bundle, Stock Reservation Entry (selling-side entry points), Installation Note, Selling Settings.
- [docs/flows/buying-flow.md](docs/flows/buying-flow.md) — Material Request → RFQ → Supplier Quotation → Purchase Order → Purchase Receipt → Purchase Invoice cascade: `status_updater[]` contract, `update_prevdoc_status` chain, PO→SO drop-ship reverse lane via `update_delivered_qty_in_sales_order`, `update_billed_amount_based_on_po` FIFO redistribution, Stock Received But Not Billed bridge, Landed Cost Voucher revaluation, subcontracting branch to Subcontracting Order, internal-transfer `sales_incoming_rate`, return flow, inter-company mirror. Mermaid sequence diagrams per stage.
- [docs/modules/buying.md](docs/modules/buying.md) — Buying-module overview: `BuyingController` responsibilities (valuation-rate composition, asset auto-creation, internal-transfer `sales_incoming_rate`, legacy subcontracting supplied-items, purchase-expense contra GL), `SubcontractingController` contribution (supplied-items build, `rm_supp_cost`), Supplier master + gating flags, Supplier Scorecard periodic scoring, Buying Settings knobs, scheduler jobs (`refresh_scorecards`, `set_expired_status`, `reorder_item`), reports, website/portal integration, regional hooks (UAE RCM on PI).
- [docs/modules/buying-doctypes.md](docs/modules/buying-doctypes.md) — per-doctype reference cards for Material Request (buying-side notes), Request for Quotation, Supplier Quotation, Purchase Order, Purchase Receipt (buying-side notes), Purchase Invoice (buying-side notes), Supplier, Supplier Group, Supplier Scorecard + 7 sub-DocTypes, Landed Cost Voucher (buying-side notes), Purchase Taxes and Charges Template, Buying Settings, PO/PR/PI Item and Supplied-Item child tables, Customer Number at Supplier.
- [docs/flows/subcontracting-flow.md](docs/flows/subcontracting-flow.md) — both coexisting subcontracting flows: legacy PO/PR-embedded (`is_old_subcontracting_flow=1`, `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied`) and new `Subcontracting Order` → `Subcontracting Receipt`. Covers `SubcontractingController.subcontract_data` dispatch, BOM vs Material-Transferred backflush, `make_rm_stock_entry`, supplier-warehouse SLE + GL, SCR cancel, and the inward customer-provided (`Subcontracting Inward Order`) mirror. Mermaid sequence diagrams per branch.
- [docs/modules/subcontracting.md](docs/modules/subcontracting.md) — Subcontracting-module overview: directory layout, `SubcontractingController` method-level reference (flow dispatcher, supplied-items build pipeline `__prepare_supplied_or_received_items` + `__set_supplied_or_received_items`, `set_consumed_qty_in_subcontract_order`, `make_sl_entries_for_supplier_warehouse`, `get_supplied_items_cost`, `make_rm_stock_entry` / `get_materials_from_supplier`), `SubcontractingInwardController` summary, Buying Settings knobs (`backflush_raw_materials_of_subcontract_based_on`, `over_transfer_allowance`, `validate_consumed_qty`, `auto_create_subcontracting_order`, `auto_create_purchase_receipt`), scheduler jobs (none), regional overrides (none).
- [docs/modules/subcontracting-doctypes.md](docs/modules/subcontracting-doctypes.md) — per-doctype reference cards for Subcontracting Order, Subcontracting Receipt, Subcontracting BOM, Subcontracting Inward Order, every child table (SCO Item / Service Item / Supplied Item, SCR Item / Supplied Item, SCIO Item / Service / Received / Secondary Item), cross-linked legacy `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied`, and Stock Entry subcontracting purposes.
- [docs/flows/manufacturing-flow.md](docs/flows/manufacturing-flow.md) — end-to-end manufacturing cascade: Production Plan demand aggregation + sub-assembly explosion + auto-creation of WO/MR/PO (subcontract branch), Work Order submit → required-items + operations + capacity-planned Job Cards, Stock Entry purposes (`Material Transfer for Manufacture`, `Manufacture`, `Material Consumption for Manufacture`, `Disassemble`) with their SLE/GL effects, Job Card time-log → Work Order Operation writeback, Work Order close/stop transitions, BOM cost-update level-wise scheduler. Mermaid sequence diagrams per stage.
- [docs/modules/manufacturing.md](docs/modules/manufacturing.md) — Manufacturing-module overview: directory layout, why manufacturing has **no** custom controller (all four lifecycle DocTypes sit directly on `Document` — Stock Entry carries the GL/SLE), Manufacturing Settings knob reference, scheduler jobs (`resume_bom_cost_update_jobs`, `auto_update_latest_price_in_all_boms`), cross-module interactions with Selling / Buying / Stock / Subcontracting / Projects, regional overrides (none).
- [docs/modules/manufacturing-doctypes.md](docs/modules/manufacturing-doctypes.md) — per-doctype reference cards for BOM + children, BOM Creator / BOM Update Log / Tool / Batch, Routing / Operation / Sub Operation, Workstation + Workstation Type + 4 children, Plant Floor, Production Plan + 8 children, Master Production Schedule, Sales Forecast, Work Order + 2 children, Job Card + 5 children, Downtime Entry, Manufacturing Settings (Single), Blanket Order (cross-module), and Stock Entry manufacturing purposes.
- [docs/modules/regional.md](docs/modules/regional.md) — Regional-module inventory: `erpnext/regional/` layout, `regional_overrides` catalogue with purposes, `doc_events` per country, `@erpnext.allow_regional` open override slots, per-country deep dives (UAE / Italy / US / South Africa / Australia / Turkey / Saudi Arabia / France-gap / Nepal), Italy FatturaPA outbound (SI submit → e-invoice.xml → File attachment) and inbound (Import Supplier Invoice → draft PI), UAE RCM GL append on PI submit. Mermaid for all three flows.
- [docs/modules/regional-doctypes.md](docs/modules/regional-doctypes.md) — per-doctype reference cards for Lower Deduction Certificate, Import Supplier Invoice, UAE VAT Settings + UAE VAT Account, South Africa VAT Settings, plus per-country DocType shipping summary.
