---
title: Immutable ledger via auto_cancel_exempted_doctypes and reverse entries
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0001: Immutable ledger via `auto_cancel_exempted_doctypes` and reverse entries

## Context

ERPNext doctypes that descend from `AccountsController` and `StockController` write to ledger tables — `GL Entry`, `Stock Ledger Entry`, `Payment Ledger Entry`, `Account Closing Balance` — that are then read by every downstream report, balance computation, FX revaluation, and period-closing routine. Frappe's default cancel cascade would `cancel` (and effectively delete the impact of) any submittable child documents linked to a parent on cancel. For ledger rows that contract is unsafe: physical mutation breaks the audit trail, makes period closures non-reproducible, and corrupts running balances if the cancel happens after subsequent transactions have already consumed the original row.

The system needs ledger rows to behave as an append-only journal, while still letting the parent (Sales Invoice, Purchase Invoice, Stock Entry, Payment Entry, etc.) be cancelled and reposted.

## Decision

Ledger DocTypes are listed in [`auto_cancel_exempted_doctypes`](../../erpnext/hooks.py:418) so Frappe's auto-cancel cascade skips them. Cancel handlers in the parent instead invoke [`make_reverse_gl_entries`](../../erpnext/accounts/general_ledger.py:681) (and the analogous SLE path), which:

1. Reads the original rows where `is_cancelled = 0` ([general_ledger.py:704](../../erpnext/accounts/general_ledger.py:704)).
2. Marks them `is_cancelled = 1` via UPDATE ([general_ledger.py:756, 840](../../erpnext/accounts/general_ledger.py:756)).
3. Inserts new rows with debit/credit (or qty) swapped, also flagged `is_cancelled = 1`, so the net effect is zero but both legs remain on disk.

Payment Entry is also exempted ([hooks.py:421](../../erpnext/hooks.py:421)) — but for a different reason: to preserve cross-doc unlinking semantics rather than ledger immutability. Account Closing Balance is exempted because Period Closing Voucher cancels it under custom logic ([hooks.py:428-430](../../erpnext/hooks.py:428)).

## Rationale

- **Audit / regulatory.** Cancelled rows must remain on disk and queryable. Auditors need to see what was posted, when it was reversed, and by whom.
- **Period-closing safety.** Once a Period Closing Voucher consumes a set of GL rows, those rows cannot be physically removed without invalidating the PCV's totals. Reverse rows after the PCV cut-off post into the next period naturally.
- **Reposting idempotence.** [`Repost Item Valuation`](../modules/stock-doctypes.md) and backdated SLE rebuilds work by reading current state, applying changes forward, and writing new rows — they would race against deletes.
- **FX revaluation correctness.** Multi-currency revaluation against `Payment Ledger Entry` and `GL Entry` reads historical postings; deletes would silently drop revaluation history.

## Consequences

- **Every ledger query must filter `is_cancelled = 0`.** This is enforced by convention; missing the filter is a recurring bug class. See [accounting flow](../flows/accounting-flow.md) and [stock flow](../flows/stock-flow.md) for the canonical query shapes.
- **Storage grows monotonically.** Cancelling and re-submitting a Sales Invoice writes 3× the rows of the first submit (original + reversal + new). Long-lived sites accumulate `is_cancelled = 1` rows; cleanup is a manual housekeeping decision, not automatic.
- **Reposts append.** [`make_reverse_gl_entries`](../../erpnext/accounts/general_ledger.py:681) on cancel + a fresh `make_gl_entries` on resubmit means a single business correction produces 4 rows per leg. Reports must dedupe via `is_cancelled = 0`.
- **Custom cancel hooks must not bypass `make_reverse_gl_entries`.** Direct `frappe.db.delete("GL Entry", ...)` from custom code breaks the contract.
- **Period guards run at reverse time, not just at post time.** [`validate_accounting_period`](../../erpnext/accounts/general_ledger.py:716) and [`check_freezing_date`](../../erpnext/accounts/general_ledger.py:717) are re-evaluated against the row's original `posting_date` — a cancel into a closed period is rejected the same way a fresh post would be.

## Alternatives considered

- **Physical delete on cancel** — rejected: breaks audit trail, makes PCV non-reproducible, races with reposts.
- **Soft-delete flag without reverse rows** — rejected: would zero the impact at query time but leaves running totals incorrect for any code path that sums by date range without re-reading the flag (e.g. FX revaluation, perpetual stock balance).
- **Versioned ledger (snapshot per state)** — rejected: massive storage cost, no clear consumer, and Frappe's ORM has no native versioning support.

## Citations

- [`erpnext/hooks.py:418-431`](../../erpnext/hooks.py:418) — `auto_cancel_exempted_doctypes` list and inline rationale comments.
- [`erpnext/accounts/general_ledger.py:681-720`](../../erpnext/accounts/general_ledger.py:681) — `make_reverse_gl_entries` implementation.
- [`erpnext/accounts/general_ledger.py:756, 840`](../../erpnext/accounts/general_ledger.py:756) — `is_cancelled` UPDATE statements.

## Related docs

- [Hooks catalogue (per-DocType registries)](../architecture/hooks-catalogue.md) — full registry contents including `auto_cancel_exempted_doctypes`.
- [Accounting flow](../flows/accounting-flow.md) — `make_gl_entries` / `process_gl_map` / `make_reverse_gl_entries` end-to-end with Mermaid for SI submit + cancel.
- [Stock flow](../flows/stock-flow.md) — SLE write path and the analogous reverse-on-cancel for stock.
- [Payments flow](../flows/payments-flow.md) — Payment Entry's separate reason for being exempted.
