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
