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

_Not yet written. Suggested next:_
- `flows/stock-flow.md` — Delivery Note / Purchase Receipt / Stock Entry submit → Stock Ledger entries, batch/serial bundles.
- `flows/selling-flow.md` — Quotation → Sales Order → Delivery Note → Sales Invoice.
- `flows/buying-flow.md` — Material Request → Purchase Order → Purchase Receipt → Purchase Invoice.

## Modules

- [Accounts](modules/accounts.md) — module layout, Chart of Accounts (`root_type`/`account_type`, company scoping), accounting dimensions, cost centers, fiscal year / accounting period, tax framework, bank clearance, reports, scheduler jobs, regional hooks.
- [Accounts DocType reference cards](modules/accounts-doctypes.md) — per-doctype cards for Sales Invoice, Purchase Invoice, Journal Entry, Payment Entry, POS Invoice, Period Closing Voucher.

_Not yet written. Suggested next:_
- `modules/stock.md`
- `modules/selling.md`
- `modules/buying.md`
- `modules/manufacturing.md`
- `modules/subcontracting.md`
- `modules/regional.md`

## ADRs

_No Architecture Decision Records yet._

## Writing conventions

- Every architectural claim cites `[name](path:line)`.
- Mermaid diagrams use `TD` for hierarchies and `LR` / `sequenceDiagram` for flows.
- Solid arrows are synchronous calls; dashed arrows are event-based / registration-time wiring.
- Each document's frontmatter carries `last_updated`, `commit`, `scope`, and `status`.
