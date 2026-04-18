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
- [docs/getting-started/after-install-seed.md](docs/getting-started/after-install-seed.md) — line-by-line walkthrough of `erpnext/setup/install.py:after_install`: 18 ordered seed steps (Analytics role, Single defaults + Currency Exchange Settings → frankfurter.dev, repost defaults, Print Settings + UTM Campaign custom fields, Email Account + Communication multi-tenant company links, default Success Actions, Incoterms CSV, 5 Role Profiles, navbar items, app name, Customer/Supplier `desk_access=0`, default `Assembly` Operation, pegged Gulf currencies pegged to USD, default print formats, 2 letter heads). Plus what is **not** seeded by `after_install` (Company / CoA / 5 default warehouses / cost centers / 14-entry department tree / per-country tax templates / country fixtures / demo data — all bootstrapped later by `Company.on_update` or the Setup Wizard).
- [docs/architecture/overview.md](docs/architecture/overview.md) — module map, where-to-start-tracing cheatsheet, repo-wide conventions.
- [docs/architecture/controllers.md](docs/architecture/controllers.md) — full controller hierarchy with per-layer responsibilities and `super()` call discipline.
- [docs/architecture/doctype-pattern.md](docs/architecture/doctype-pattern.md) — the four-file DocType layout and how transaction DocTypes plug into the controller chain.
- [docs/architecture/doctype-lifecycle.md](docs/architecture/doctype-lifecycle.md) — per-event call order (`validate`, `before_save`, `on_submit`, `on_cancel`, `on_trash`) through the controller chain + `doc_events`.
- [docs/architecture/hooks-and-overrides.md](docs/architecture/hooks-and-overrides.md) — exhaustive tour of `erpnext/hooks.py` registrations.
- [docs/architecture/scheduler-jobs.md](docs/architecture/scheduler-jobs.md) — full catalogue of every entry in `scheduler_events` ([hooks.py:433-500](erpnext/hooks.py:433)) grouped by frequency band (cron / hourly / hourly_maintenance / daily_maintenance / weekly / monthly_long): function path, owning module, what each job touches, what fails if it stops, cross-links to flow + module docs, and the `bench execute` / `Scheduled Job Type` / `Error Log` tracing recipe.
- [docs/architecture/hooks-catalogue.md](docs/architecture/hooks-catalogue.md) — depth read on the 17 per-DocType list/dict registries in `hooks.py` not covered by `hooks-and-overrides.md` (`period_closing_doctypes`, `auto_cancel_exempted_doctypes` immutable-ledger policy, `accounting_dimension_doctypes` 54-entry custom-field provisioner, `repost_allowed_doctypes`, `bank_reconciliation_doctypes`, `subscription_doctypes`, `invoice_doctypes`, `advance_payment_*_doctypes` PE liability routing, `communication_doctypes`, `treeviews`, `calendars`, `website_generators`, `naming_series_variables` 9-token engine, `default_log_clearing_doctypes`, `ignore_links_on_delete`, `additional_timeline_content`). Each registry has its consumer code path with `[file](path:line)` citations, semantics, and consequences of adding/removing a DocType.
- [docs/architecture/boot-session.md](docs/architecture/boot-session.md) — line-by-line walkthrough of `erpnext.startup.boot.boot_session` (every `bootinfo.sysdefaults.*` key it injects, plus Companies pre-load, `party_account_types`, `current_fiscal_year`, `repost_allowed_doctypes` surface) and `extend_bootinfo` (Support `add_sla_doctypes` + `bootinfo` employee link). Also covers `notification_config` (33 DocType counters + Company `monthly_sales_target` progress bar), `leaderboards` (Customer / Item / Supplier / Sales Partner / Sales Person), `filters_config` (Fiscal Year custom filter), `on_session_creation` (auto-create Customer/Supplier portal link), `get_help_messages`, `additional_print_settings`. Includes a per-login sequence diagram.
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
- [docs/modules/portal.md](docs/modules/portal.md) — Portal module: `on_session_creation` Customer/Supplier auto-provision, `website_route_rules` (14 entries), `standard_portal_menu_items` (14 entries), `has_website_permission` (11 transactional DocTypes routed through controllers/website_list_for_contact.py), `set_default_role` on User on_update. Module's own DocTypes are 2 child tables (Website Attribute, Website Filter Field) for storefront filtering.
- [docs/modules/portal-doctypes.md](docs/modules/portal-doctypes.md) — per-doctype cards for Website Attribute + Website Filter Field.
- [docs/flows/customer-portal-flow.md](docs/flows/customer-portal-flow.md) — end-to-end portal login → auto-provision → sidebar → list/detail → public contact form override (Lead/Opportunity/Communication composer). 4 sequence diagrams.
- [docs/modules/shopping-cart.md](docs/modules/shopping-cart.md) — Shopping Cart: empty in-tree shell at this commit (cart DocTypes moved to out-of-tree `webshop` app); only live wiring is `payment_gateway_enabled` ([hooks.py:521](erpnext/hooks.py:521)) → `accounts/utils.create_payment_gateway_account`.
- [docs/modules/shopping-cart-doctypes.md](docs/modules/shopping-cart-doctypes.md) — confirms zero in-tree DocTypes; cross-pointer to where cart-related DocTypes actually live.
- [docs/modules/www-and-templates.md](docs/modules/www-and-templates.md) — public-page surface inventory: 8 `www/` slots (only `book_appointment/`, `support/`, `payment_setup_certification` are live; 5 are empty placeholders), 6 `templates/` subdirs, `templates/utils.send_message` override of public contact form ([hooks.py:58](erpnext/hooks.py:58)).
- [docs/modules/utilities.md](docs/modules/utilities.md) — Utilities catch-all: `TransactionBase(StatusUpdater)` controller layer, `bulk_transaction.py` engine + `hourly_maintenance` retry, `activation.py` 24-doctype scoring + `get_help_messages` hook, `__init__.get_site_info` + `payment_app_import_guard`, `product.py` storefront pricing, `naming.py` Setup Wizard helper, `regional.temporary_flag` context manager. **`bot_parsers` registers a target whose file does not exist** (TODO(verify)).
- [docs/modules/utilities-doctypes.md](docs/modules/utilities-doctypes.md) — per-doctype cards for Video, Video Settings, Rename Tool, Portal User.
- [docs/modules/bulk-transaction.md](docs/modules/bulk-transaction.md) — Bulk Transaction module: ships only the two log DocTypes; engine lives in [erpnext/utilities/bulk_transaction.py](erpnext/utilities/bulk_transaction.py). `Bulk Transaction Log` is **virtual** (aggregates Detail rows by date). Hourly retry scheduler with savepoint isolation and `retried` flag de-duplication.
- [docs/modules/bulk-transaction-doctypes.md](docs/modules/bulk-transaction-doctypes.md) — per-doctype cards for Bulk Transaction Log (virtual) + Bulk Transaction Log Detail.
- [docs/modules/erpnext-integrations.md](docs/modules/erpnext-integrations.md) — ERPNext Integrations: only first-party integration is **Plaid bank-feed sync**. `automatic_synchronization` `hourly_maintenance` ([hooks.py:457](erpnext/hooks.py:457)) fans out per-account jobs that fetch transactions and submit `Bank Transaction` records. Helpers: `validate_webhooks_request`, `get_webhook_address`, `get_tracking_url`. `custom/contact.json` Customize Form fixture.
- [docs/modules/erpnext-integrations-doctypes.md](docs/modules/erpnext-integrations-doctypes.md) — per-doctype card for Plaid Settings (Single).
- [docs/modules/telephony.md](docs/modules/telephony.md) — Telephony module: 5 DocTypes around `Call Log`. `Call Log` lifecycle (4 hooks), Contact `after_insert` back-fill, universal `additional_timeline_content["*"]` injection ([hooks.py:684](erpnext/hooks.py:684)), `sounds` (3 desk audio assets). No scheduler jobs.
- [docs/modules/telephony-doctypes.md](docs/modules/telephony-doctypes.md) — per-doctype cards for Call Log, Incoming Call Settings, Incoming Call Handling Schedule, Voice Call Settings, Telephony Call Type.
- [docs/modules/communication.md](docs/modules/communication.md) — Communication module (distinct from Frappe core's Communication DocType): only **two** DocTypes — `Communication Medium` + child `Communication Medium Timeslot`. Pure schema. The `doc_events["Communication"]` wiring at [hooks.py:362-371](erpnext/hooks.py:362) dispatches into Support and CRM, NOT this module.
- [docs/modules/communication-doctypes.md](docs/modules/communication-doctypes.md) — per-doctype cards for Communication Medium + Communication Medium Timeslot.
- [docs/modules/edi.md](docs/modules/edi.md) — EDI module: new and intentionally narrow v17 module. Two DocTypes — `Code List` (versioned vocabulary, cascades on trash) and `Common Code` (Dynamic Link `applies_to` table; `validate_distinct_references`). Genericode-XML import driver via `doctype_list_js` ([hooks.py:45-52](erpnext/hooks.py:45)). DDL: composite index `(code_list, common_code)`. No GL/SLE impact.
- [docs/modules/edi-doctypes.md](docs/modules/edi-doctypes.md) — per-doctype cards for Code List + Common Code.
- [docs/modules/assets.md](docs/modules/assets.md) — Assets-module overview: `erpnext/assets/` directory layout, depreciation engine (`post_depreciation_entries` daily at `hooks.py:491` → active `Asset Depreciation Schedule` rows → JE per due row), depreciation methods (Straight Line / DDB / WDV / Manual + daily-prorata + shift sub-modes), multi-finance-book + `reschedule_depreciation`, capitalization vs repair vs movement vs adjustment GL/SLE matrix, Asset lifecycle, Asset Maintenance + Shift Allocation summaries, all four Assets daily scheduler entries, `@erpnext.allow_regional` open slots (`cancel_depreciation_entries`, `WDVMethod.get_wdv_or_dd_depr_amount`), cross-module ties to Buying / Selling / Accounts.
- [docs/modules/assets-doctypes.md](docs/modules/assets-doctypes.md) — per-doctype reference cards for Asset, Asset Depreciation Schedule (+ Depreciation Schedule child + DepreciationScheduleController + StraightLineMethod / WDVMethod), Asset Capitalization + 3 children, Asset Repair + 2 children, Asset Movement + Movement Item, Asset Value Adjustment, Asset Shift Allocation, Asset Maintenance + Task child + Team + Member, Asset Maintenance Log, Asset Category + Category Account, Asset Finance Book, Asset Shift Factor, Asset Activity, Location, Linked Location, plus the depreciation engine module-function catalogue.
- [docs/flows/assets-flow.md](docs/flows/assets-flow.md) — three asset flows with mermaid sequence diagrams: depreciation posting (daily scheduler → schedule lookup → JE per period → Dr Depreciation Expense / Cr Accumulated Depreciation, schedule-row `journal_entry` stamping), capitalization (Asset Capitalization SLE for consumed stock + GL via `get_gl_entries_on_asset_disposal` for consumed assets + service-cost mix → target asset value bump), repair (`Asset Repair` always issues a child Stock Entry; `capitalize_repair_cost=1` posts the GL bridge from PI expense account + SE expense account into the Fixed Asset account and bumps finance-book life via `reschedule_depreciation`).
- [docs/modules/setup.md](docs/modules/setup.md) — Setup-module overview: `erpnext/setup/` directory layout, Company DocType (`NestedSet`) `validate` 15-step chain + `on_update` mass-bootstrap (CoA / 5 default warehouses / cost centers / 14-entry Department tree / `install_country_fixtures`) + `on_trash` cleanup, Setup Wizard 3+1 stages (`stage_fixtures` / `setup_company` / `setup_defaults` / optional `setup_demo`), Naming Series engine (`naming_series_variables` registry → 9 variables FY/TFY/ABBR/MM/DD/YY/YYYY/JJJ/WW resolved by `parse_naming_series_variable` at `accounts/utils.py:1598`), Authorization Rule + AuthorizationControl(TransactionBase), Email Digest daily scheduler at `hooks.py:488`, Currency Exchange master + Currency Exchange Settings (frankfurter.dev provider, on-demand fetch with cache key `currency_exchange_rate_<date>:<from>:<to>`), Holiday List + 6 NestedSet master groups (Item / Customer / Supplier / Sales Person / Territory / Department), Transaction Deletion Record 6-task ordered workflow + Redis-cache `doc_events["*"].validate` guard, User → `validate_employee_role` employee-role auto-strip, demo loader (`erpnext/setup/demo.py` → `create_demo_company` + `process_masters` + `make_transactions` + `convert_order_to_invoices`), and an Open Question on the absent daily Currency Exchange refresh scheduler.
- [docs/modules/setup-doctypes.md](docs/modules/setup-doctypes.md) — per-doctype reference cards for the 41 files under `erpnext/setup/doctype/`: Company (1096 lines), Global Defaults (Single), Branch, the 6 NestedSet master groups, Employee + 3 work-history children + Employee Group + child + Designation, Holiday List + Holiday, Brand, Sales Partner (web generator), Quotation Lost Reason + child, Target Detail, Website Item Group, Vehicle + dashboard, Driver, Driving License Category, Incoterm (CSV-seeded), Currency Exchange (composite autoname), Authorization Rule, Authorization Control (`TransactionBase`), Email Digest + recipient child, Transaction Deletion Record + 2 Setup-side children + Accounts-side details child + `PROTECTED_CORE_DOCTYPES` constant + `LEDGER_ENTRY_DOCTYPES`, Terms and Conditions, UOM, UOM Conversion Factor, Party Type. Includes a 38-row module summary table (DocType / Class / Base / Tree / Hooks).
- [docs/modules/support.md](docs/modules/support.md) — Support-module overview: load-bearing `doc_events["*"].validate` SLA hook (`service_level_agreement.apply` runs on every doc save), Issue lifecycle (`Open / Replied / On Hold / Resolved / Closed`) + SLA `agreement_status` truth table, working-hours-aware first-response math, Communication ↔ Issue ↔ SLA wiring, Warranty Claim handoff to Maintenance, daily schedulers (`auto_close_tickets`, `check_agreement_status`).
- [docs/modules/support-doctypes.md](docs/modules/support-doctypes.md) — per-doctype reference cards for Issue, Issue Type, Issue Priority, Service Level Agreement + 4 child tables (Service Day, Service Level Priority, SLA Fulfilled On Status, Pause SLA On Status), Support Settings (Single), Support Search Source, Warranty Claim.
- [docs/modules/projects.md](docs/modules/projects.md) — Projects-module overview: Project lifecycle (`update_costing` aggregation from Timesheet Detail + Purchase Invoice Item + Sales Order + Sales Invoice + 4-mode `update_percent_complete` Manual / Task Completion / Task Progress / Task Weight), Task NestedSet (recursion guard, dependant rescheduling, daily `set_tasks_as_overdue`), Timesheet → Sales Invoice mapper, Project Update reminder cycle (Hourly / Twice Daily / Daily / Weekly with `collect_project_status` polling Communication replies), six scheduler jobs total, calendar/portal surface, cross-module touch points (Selling / Buying / Stock / Manufacturing / Support / Setup).
- [docs/modules/projects-doctypes.md](docs/modules/projects-doctypes.md) — per-doctype reference cards for Project, Project Type, Project Update, Project Template + Project Template Task, Task + Task Type + Task Depends On + Dependent Task, Timesheet + Timesheet Detail, Activity Type + Activity Cost, Project User, Projects Settings (Single).
- [docs/modules/crm.md](docs/modules/crm.md) — CRM-module overview: surprising controller-base split (Lead extends `SellingController`, Opportunity extends `TransactionBase` only), Lead → Opportunity → Quotation conversion mapper chain, Prospect aggregator over Leads + Opportunities, doc_events wiring (Communication / Event / Contact / Email Unsubscribe), CRM Settings knob set, Contract status machine + fulfilment checklist, Email Campaign daily send pipeline + unsubscribe handling, five scheduler jobs, GDPR `user_privacy_documents` registration.
- [docs/modules/crm-doctypes.md](docs/modules/crm-doctypes.md) — per-doctype reference cards for Lead, Lead Source, Opportunity + Opportunity Item + Opportunity Type + Opportunity Lost Reason + Lost Reason Detail + Opportunity Lost Reason Detail, Prospect + Prospect Lead + Prospect Opportunity, Email Campaign + Campaign + Campaign Email Schedule, Competitor + Competitor Detail, Sales Stage, Market Segment, CRM Note, CRM Settings (Single), Appointment + Appointment Booking Settings + Appointment Booking Slots + Availability Of Slots, Contract + Contract Fulfilment Checklist + Contract Template + Contract Template Fulfilment Terms.
- [docs/modules/quality-management.md](docs/modules/quality-management.md) — Quality Management-module overview: all-plain-`Document` posture (no transaction-controller chain, no GL/SLE, none in cross-cutting registries), Quality Procedure NestedSet with parent/child sync, Quality Goal → Quality Review daily cadence (`Daily / Weekly / Monthly / Quarterly` with day-of-month / day-of-week / quarter-month dispatch), Non Conformance → Quality Action workflow, Quality Feedback multi-parameter rating (auto-template clone, self-rating default), single scheduler job (`quality_review.review`). Note: `Quality Inspection` lives in Stock module despite the name.
- [docs/modules/quality-management-doctypes.md](docs/modules/quality-management-doctypes.md) — per-doctype reference cards for Quality Goal + Quality Goal Objective, Quality Procedure (NestedSet) + Quality Procedure Process, Quality Action + Quality Action Resolution, Quality Meeting + Quality Meeting Agenda + Quality Meeting Minutes, Quality Review + Quality Review Objective, Non Conformance, Quality Feedback + Quality Feedback Parameter, Quality Feedback Template + Quality Feedback Template Parameter.
- [docs/modules/maintenance.md](docs/modules/maintenance.md) — Maintenance-module overview: Maintenance Schedule generation (per-item × periodicity → `Maintenance Schedule Detail` rows with float-day stride and holiday-pull-back date generation), Sales-Person `frappe.Event` calendar creation on submit (10:00 private events owned by Sales Person's User), Serial No `amc_expiry_date` propagation bridge to Stock's `update_maintenance_status` daily scheduler, Maintenance Visit submit/cancel writeback to Schedule Detail and Warranty Claim (`Fully Completed → Closed`, cancel reverts to next-most-recent partial visit), `check_if_last_visit` cancel guard, **no scheduler jobs** of its own.
- [docs/modules/maintenance-doctypes.md](docs/modules/maintenance-doctypes.md) — per-doctype reference cards for Maintenance Schedule + Maintenance Schedule Item + Maintenance Schedule Detail, Maintenance Visit + Maintenance Visit Purpose.
- [docs/adr/README.md](docs/adr/README.md) — Architecture Decision Records index + convention. ADRs are immutable once accepted; supersession is via a new ADR. Currently 6 accepted decisions: [0001 Immutable ledger](docs/adr/0001-immutable-ledger.md) (`auto_cancel_exempted_doctypes` + reverse rows), [0002 Regional overrides pattern](docs/adr/0002-regional-overrides-pattern.md) (`@allow_regional` + hooks dict over per-country subclasses), [0003 No manufacturing controller](docs/adr/0003-no-manufacturing-controller.md) (WO/JC/PP/BOM extend `Document`; Stock Entry owns GL/SLE), [0004 `payments` app dependency](docs/adr/0004-payments-app-dependency.md) (install order + the one cross-app hook `payment_gateway_enabled`), [0005 `status_updater[]` vs `doc_events`](docs/adr/0005-status-updater-vs-doc-events.md) (declarative class attribute for cross-doc cascades; `doc_events` reserved for cross-cutting wildcards), [0006 Subcontracting v15 coexistence](docs/adr/0006-subcontracting-v15-coexistence.md) (`is_old_subcontracting_flow=1` flag, single `SubcontractingController` dispatches via `subcontract_data`).
