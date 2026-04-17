---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: accounts
status: complete
related_docs:
  - accounts.md
  - ../flows/accounting-flow.md
  - ../flows/taxes-and-totals.md
  - ../flows/payments-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
  - ../patterns/regional-overrides.md
---

# Accounts — DocType Reference Cards

> **TL;DR:** One card per principal accounting DocType (Sales Invoice, Purchase Invoice, Journal Entry, Payment Entry, POS Invoice, Period Closing Voucher). Each card lists the schema path, controller ancestry, lifecycle hooks implemented, the method that builds its GL map, and the distinctive behaviours. Use this as the jump table into [accounting-flow.md](../flows/accounting-flow.md), [taxes-and-totals.md](../flows/taxes-and-totals.md), and [payments-flow.md](../flows/payments-flow.md).

## How to read each card

Every card follows the same template:

- **Paths** — schema JSON, Python controller, JS controller, tests, plus child-table locations worth knowing.
- **Controller chain** — where the DocType sits in the [controller hierarchy](../architecture/controllers.md).
- **Lifecycle hooks implemented** — which of `validate`, `before_save`, `before_submit`, `on_submit`, `on_update_after_submit`, `before_cancel`, `on_cancel`, `on_trash` the controller defines (plus inherited super-calls).
- **GL entry point** — the exact line where the doc builds its GL map and calls into [`erpnext/accounts/general_ledger.py`](erpnext/accounts/general_ledger.py:28).
- **hooks.py wiring** — `doc_events`, `auto_cancel_exempted_doctypes`, `period_closing_doctypes`, `bank_reconciliation_doctypes`, etc.
- **Regional overrides** — country replacements that target this DocType.

## Sales Invoice

- **Schema:** [`erpnext/accounts/doctype/sales_invoice/sales_invoice.json`](erpnext/accounts/doctype/sales_invoice/sales_invoice.json)
- **Python:** [`erpnext/accounts/doctype/sales_invoice/sales_invoice.py`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:59) — [`class SalesInvoice(SellingController)`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:59)
- **JS:** [`erpnext/accounts/doctype/sales_invoice/sales_invoice.js`](erpnext/accounts/doctype/sales_invoice/sales_invoice.js:13)
- **Tests:** [`erpnext/accounts/doctype/sales_invoice/test_sales_invoice.py`](erpnext/accounts/doctype/sales_invoice/test_sales_invoice.py)
- **Child tables:** `Sales Invoice Item`, `Sales Invoice Payment`, `Sales Invoice Advance`, `Sales Invoice Timesheet`, `Sales Taxes and Charges`, `Payment Schedule`, `Pricing Rule Detail`, `Packed Item`, `Sales Team`.

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → StockController → SellingController → SalesInvoice`. See [controllers doc](../architecture/controllers.md).

**Lifecycle hooks implemented:**

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:300`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:300) | Calls `super().validate()` (SellingController → StockController → AccountsController), then POS/dropship/asset/delivery validations and `update_packing_list`, `set_billing_hours_and_amount`, `set_status`. |
| `before_save` | [`:443`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:443) | `set_account_for_mode_of_payment`, `set_paid_amount`. |
| `before_submit` | [`:447`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:447) | `add_remarks`. |
| `on_submit` | [`:450`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:450) | Authorization check → prev-doc status (SO/DN) → stock ledger (if `update_stock`) → asset depreciation → **`make_gl_entries()`** → `repost_future_sle_and_gle` → credit-limit → loyalty → inter-company link → `process_common_party_accounting`. |
| `before_cancel` | [`:578`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:578) | POS-closing guard, consolidated-invoice guard, `super().before_cancel()`. |
| `on_cancel` | [`:586`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:586) | Cancels stock ledger, asset depreciation, GL entries, exchange JE, loyalty. `ignore_linked_doctypes` set at [`:637`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:637). |
| `on_update_after_submit` | [`:841`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:841) | Repost trigger on selected fields. |

**GL entry point.** [`make_gl_entries`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1537) builds via [`get_gl_entries`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1578) (customer → taxes → internal-transfer → items → precision-loss → discount → regional → merge → loyalty → POS → write-off → rounding). Submits with `merge_entries=False` because `get_gl_entries` already merged.

**hooks.py:**

- `doc_events`: `on_submit` → [`erpnext.regional.italy.utils.sales_invoice_on_submit`](erpnext/hooks.py:377), `on_cancel` → [`italy.utils.sales_invoice_on_cancel`](erpnext/hooks.py:380), `on_trash` → [`check_deletion_permission`](erpnext/hooks.py:382). Plus the `*` + `period_closing_doctypes` tuple at [`:350`](erpnext/hooks.py:350).
- Member of: `period_closing_doctypes` [`:323`](erpnext/hooks.py:323), `invoice_doctypes` [`:528`](erpnext/hooks.py:528), `bank_reconciliation_doctypes` [`:534`](erpnext/hooks.py:534), `subscription_doctypes` [`:592`](erpnext/hooks.py:592), `has_website_permission` [`:310`](erpnext/hooks.py:310).
- `make_regional_gl_entries` default: [`sales_invoice.py:2591`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:2591) (no-op `@erpnext.allow_regional`).

## Purchase Invoice

- **Schema:** [`erpnext/accounts/doctype/purchase_invoice/purchase_invoice.json`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.json)
- **Python:** [`erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:54) — [`class PurchaseInvoice(BuyingController)`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:54)
- **JS:** [`erpnext/accounts/doctype/purchase_invoice/purchase_invoice.js`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.js:13)
- **Tests:** [`erpnext/accounts/doctype/purchase_invoice/test_purchase_invoice.py`](erpnext/accounts/doctype/purchase_invoice/test_purchase_invoice.py)
- **Child tables:** `Purchase Invoice Item`, `Purchase Invoice Advance`, `Purchase Taxes and Charges`, `Payment Schedule`, `Pricing Rule Detail`.

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → StockController → SubcontractingController → BuyingController → PurchaseInvoice`. See [controllers doc](../architecture/controllers.md).

**Lifecycle hooks implemented:**

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:261`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:261) | Release-date, cash-rule, credit-to account, warehouse, item-code, expense-account, write-off-account, receipt-if-update-stock. |
| `on_submit` | [`:750`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:750) | `super().on_submit()` first. Then PurchaseTaxWithholding → prev-doc status (PO/PR) → Authorization Control → stock ledger (if `update_stock`) → **`make_gl_entries()`** → `repost_future_sle_and_gle` → `update_project` → inter-company link → `process_common_party_accounting`. |
| `on_update_after_submit` | [`:797`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:797) | Repost trigger — checks `cash_bank_account`, `write_off_account`, `unrealized_profit_loss_account`, `is_opening`, `items.expense_account`, `taxes.account_head`. |
| `on_cancel` | [`:1682`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:1682) | Reverses GL, runs [`cancel_provisional_entries`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:830) on linked PR entries. |

**GL entry point.** [`make_gl_entries`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:810) builds via [`get_gl_entries`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:862) (supplier → items → precision-loss → taxes → internal-transfer → tax-withholding → regional → merge → payment (`is_paid`) → write-off → rounding → purchase-expense).

**hooks.py:**

- `doc_events`: `validate` → UAE handlers [`update_grand_total_for_rcm`, `validate_returns`](erpnext/hooks.py:385).
- Member of: `period_closing_doctypes`, `invoice_doctypes`, `bank_reconciliation_doctypes`, `subscription_doctypes`, `has_website_permission`.
- `make_regional_gl_entries` default: [`purchase_invoice.py:1947`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:1947) (`@erpnext.allow_regional`); **United Arab Emirates override** wires `erpnext.regional.united_arab_emirates.utils.make_regional_gl_entries` at [`hooks.py:612`](erpnext/hooks.py:612) — adds RCM (reverse-charge) lines.

## Journal Entry

- **Schema:** [`erpnext/accounts/doctype/journal_entry/journal_entry.json`](erpnext/accounts/doctype/journal_entry/journal_entry.json)
- **Python:** [`erpnext/accounts/doctype/journal_entry/journal_entry.py`](erpnext/accounts/doctype/journal_entry/journal_entry.py:43) — [`class JournalEntry(AccountsController)`](erpnext/accounts/doctype/journal_entry/journal_entry.py:43)
- **JS:** [`erpnext/accounts/doctype/journal_entry/journal_entry.js`](erpnext/accounts/doctype/journal_entry/journal_entry.js:299)
- **Tests:** [`erpnext/accounts/doctype/journal_entry/test_journal_entry.py`](erpnext/accounts/doctype/journal_entry/test_journal_entry.py)
- **Child tables:** `Journal Entry Account`. Templates: `Journal Entry Template`, `Journal Entry Template Account`.

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → JournalEntry`. Notice — JE skips `StockController`/`Selling`/`Buying` because it's a pure accounting voucher.

**Voucher types:** `Journal Entry | Inter Company Journal Entry | Bank Entry | Cash Entry | Credit Card Entry | Debit Note | Credit Note | Contra Entry | Excise Entry | Write Off Entry | Opening Entry | Depreciation Entry | Exchange Rate Revaluation | Exchange Gain Or Loss | Deferred Revenue | Deferred Expense | Periodic Accounting Entry`.

**Lifecycle hooks implemented:**

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:127`](erpnext/accounts/doctype/journal_entry/journal_entry.py:127) | Party, advance accounts, multi-currency, credit=debit, stock-accounts, references, inter-company, depreciation. Also `JournalTaxWithholding.on_validate`. |
| `submit` (override) | [`:182`](erpnext/accounts/doctype/journal_entry/journal_entry.py:182) | **Queues submission as a background job** when `len(accounts) > 100`. |
| `before_submit` | [`:197`](erpnext/accounts/doctype/journal_entry/journal_entry.py:197) | Re-verifies debit==credit (skipped during import). |
| `on_submit` | [`:202`](erpnext/accounts/doctype/journal_entry/journal_entry.py:202) | Cheque info → **`make_gl_entries()`** → credit-limit → asset-value update → inter-company link → invoice-discounting update → withholding submit. |
| `on_update_after_submit` | [`:281`](erpnext/accounts/doctype/journal_entry/journal_entry.py:281) | Repost when `accounts` rows changed; `ignore_reposting_on_reconciliation` flag guards against reconciliation loop. |
| `before_cancel` | [`:188`](erpnext/accounts/doctype/journal_entry/journal_entry.py:188) | Asset-adjustment entry check. |
| `cancel` (override) | [`:191`](erpnext/accounts/doctype/journal_entry/journal_entry.py:191) | Background queue when `len(accounts) > 100`. |
| `on_cancel` | [`:292`](erpnext/accounts/doctype/journal_entry/journal_entry.py:292) | `super().on_cancel()` → set `ignore_linked_doctypes` → `make_gl_entries(1)` → withholding cancel → unlink advance/asset/inter-company references. |

**GL entry point.** [`make_gl_entries`](erpnext/accounts/doctype/journal_entry/journal_entry.py:1204) writes directly from the `accounts` child table — no composer layer. Exchange-Gain-Or-Loss variant is exempt from the merge-time zero filter at [`general_ledger.py:317-321`](erpnext/accounts/general_ledger.py:317).

**hooks.py:**

- Member of: `period_closing_doctypes`, `bank_reconciliation_doctypes`, and the accounting-dimension registration set at [`hooks.py:551-552`](erpnext/hooks.py:551) (`Journal Entry Account`, `Journal Entry Template Account`).
- No active `doc_events` entries (outside the `*` + `period_closing_doctypes` tuple).

## Payment Entry

- **Schema:** [`erpnext/accounts/doctype/payment_entry/payment_entry.json`](erpnext/accounts/doctype/payment_entry/payment_entry.json)
- **Python:** [`erpnext/accounts/doctype/payment_entry/payment_entry.py`](erpnext/accounts/doctype/payment_entry/payment_entry.py:63) — [`class PaymentEntry(AccountsController)`](erpnext/accounts/doctype/payment_entry/payment_entry.py:63)
- **JS:** [`erpnext/accounts/doctype/payment_entry/payment_entry.js`](erpnext/accounts/doctype/payment_entry/payment_entry.js)
- **Tests:** [`erpnext/accounts/doctype/payment_entry/test_payment_entry.py`](erpnext/accounts/doctype/payment_entry/test_payment_entry.py)
- **Child tables:** `Payment Entry Reference`, `Payment Entry Deduction`, `Advance Taxes and Charges` (as `taxes`).

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → PaymentEntry`.

**Lifecycle hooks implemented:** see the [payments flow](../flows/payments-flow.md#payment-entry-lifecycle) for the full `validate` chain and `on_submit` sequence. Summary:

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:172`](erpnext/accounts/doctype/payment_entry/payment_entry.py:172) | Liability-account swap, refs, amounts, taxes, allocation checks, withholding. |
| `before_save` | [`:199`](erpnext/accounts/doctype/payment_entry/payment_entry.py:199) | `set_matched_unset_payment_requests_to_response`. |
| `on_submit` | [`:202`](erpnext/accounts/doctype/payment_entry/payment_entry.py:202) | `difference_amount==0` check → withholding → payment requests → payment schedule → **`make_gl_entries()`** → outstanding → status. |
| `on_update_after_submit` | [`:216`](erpnext/accounts/doctype/payment_entry/payment_entry.py:216) | Repost on references/taxes/deductions change; bypasses when `ignore_reposting_on_reconciliation`. |
| `on_cancel` | [`:295`](erpnext/accounts/doctype/payment_entry/payment_entry.py:295) | Set `ignore_linked_doctypes` → `super().on_cancel()` → withholding cancel → payment requests → payment schedule → `make_gl_entries(cancel=1)` → delink advance references → status. |

**GL entry point.** [`make_gl_entries`](erpnext/accounts/doctype/payment_entry/payment_entry.py:1302) → [`build_gl_map`](erpnext/accounts/doctype/payment_entry/payment_entry.py:1289) (party + bank + deductions + taxes + regional). Runs [`process_gl_map`](erpnext/accounts/general_ledger.py:188) *before* calling the universal `make_gl_entries` so merge runs with the PE's own `merge_similar_account_heads` semantics. Advance-separate-account mode adds a second pass via [`make_advance_gl_entries`](erpnext/accounts/doctype/payment_entry/payment_entry.py:1442).

**hooks.py:**

- `doc_events`: `on_trash` → [`check_deletion_permission`](erpnext/hooks.py:391).
- `auto_cancel_exempted_doctypes` includes Payment Entry ([`hooks.py:422`](erpnext/hooks.py:422)) — so cancelling an SI won't auto-cancel the PE; it just unlinks.
- Member of: `period_closing_doctypes`, `bank_reconciliation_doctypes`, accounting-dimension registration at [`hooks.py:557`](erpnext/hooks.py:557) (`Payment Entry Deduction`).
- `advance_payment_receivable_doctypes = ["Sales Order"]`, `advance_payment_payable_doctypes = ["Purchase Order"]` at [`hooks.py:525-526`](erpnext/hooks.py:525) drive the separate-account logic in [`set_liability_account`](erpnext/accounts/doctype/payment_entry/payment_entry.py:229).

## POS Invoice

- **Schema:** [`erpnext/accounts/doctype/pos_invoice/pos_invoice.json`](erpnext/accounts/doctype/pos_invoice/pos_invoice.json)
- **Python:** [`erpnext/accounts/doctype/pos_invoice/pos_invoice.py`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:31) — [`class POSInvoice(SalesInvoice)`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:31)
- **JS:** [`erpnext/accounts/doctype/pos_invoice/pos_invoice.js`](erpnext/accounts/doctype/pos_invoice/pos_invoice.js:8)
- **Tests:** [`erpnext/accounts/doctype/pos_invoice/test_pos_invoice.py`](erpnext/accounts/doctype/pos_invoice/test_pos_invoice.py:24) — `class POSInvoiceTestMixin(ERPNextTestSuite)`.
- **Child tables:** `POS Invoice Item` ([`pos_invoice_item.py:9`](erpnext/accounts/doctype/pos_invoice_item/pos_invoice_item.py:9) extends `SalesInvoiceItem`), `Sales Invoice Payment`, `Sales Invoice Advance`, `Sales Taxes and Charges`, `Payment Schedule`, `Sales Team`, `Pricing Rule Detail`, `Sales Invoice Timesheet`, `Packed Item`.

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → StockController → SellingController → SalesInvoice → POSInvoice`. Inherits the entire SI machinery and swaps a handful of methods.

**Lifecycle hooks implemented (overrides on top of `SalesInvoice`):**

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:200`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:200) | Calls `super(SalesInvoice, self).validate()` — skips Sales Invoice's own `validate` body and goes straight to `SellingController.validate`. Adds POS-opening-entry, mode-of-payment, change-amount, change-account, stock-amount validations (see [`pos_invoice.py:200-220`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:200)). |
| `before_submit` | [`:238`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:238) | POS-specific pre-submit (inherited super chain differs). |
| `on_submit` | [`:241`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:241) | Writes `POS Invoice Reference` rows, updates `POS Invoice Merge Log`. POS Invoices do *not* post GL entries directly — they feed into a `Sales Invoice` at `POS Closing Entry` / `POS Invoice Merge Log` time. |
| `on_cancel` | [`:286`](erpnext/accounts/doctype/pos_invoice/pos_invoice.py:286) | Unwinds merge log, reverses stock. |

**GL entry point.** Inherited. The pipeline is SI's [`make_gl_entries`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1537) — executed only when a **consolidated Sales Invoice** is produced by `POS Invoice Merge Log`. Individual POS Invoices submit without writing GL (their cash leg is absorbed into the consolidation).

**hooks.py:**

- Member of: `subscription_doctypes` [`:592`](erpnext/hooks.py:592), listed in the `naming_series` dimension-propagation set at [`hooks.py:572`](erpnext/hooks.py:572).
- No dedicated `doc_events` entries; inherits SI regional italy hooks since `is_pos=1` rejects those paths inside `SalesInvoice.on_submit` / `on_cancel`.

## Period Closing Voucher

- **Schema:** [`erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.json`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.json)
- **Python:** [`erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:21) — [`class PeriodClosingVoucher(AccountsController)`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:21)
- **JS:** [`erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.js`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.js)
- **Tests:** [`erpnext/accounts/doctype/period_closing_voucher/test_period_closing_voucher.py`](erpnext/accounts/doctype/period_closing_voucher/test_period_closing_voucher.py)
- **Related DocTypes:** [`Process Period Closing Voucher`](erpnext/accounts/doctype/process_period_closing_voucher/process_period_closing_voucher.py) (new path), `Account Closing Balance` ([`erpnext/accounts/doctype/account_closing_balance/account_closing_balance.py`](erpnext/accounts/doctype/account_closing_balance/account_closing_balance.py)).

**Controller chain.** `Document → StatusUpdater → TransactionBase → AccountsController → PeriodClosingVoucher`.

**Lifecycle hooks implemented:**

| Event | Location | Highlights |
| --- | --- | --- |
| `validate` | [`:42`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:42) | `validate_start_and_end_date` (aligns with previously closed period or fiscal-year start, rejects end > fy_end), `check_if_previous_year_closed`, `block_if_future_closing_voucher_exists`, `check_closing_account_type` (must be `Liability` or `Equity`), `check_closing_account_currency` (must equal company currency). |
| `on_submit` | [`:132`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:132) | Sets `gle_processing_status = "In Progress"`. When `Accounts Settings.use_legacy_controller_for_pcv=1`, calls its own `make_gl_entries` directly. Otherwise creates a `Process Period Closing Voucher` doc with `parent_pcv = self.name` and submits it — the actual GL write happens in that worker. |
| `on_cancel` | [`:140`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:140) | `block_if_future_closing_voucher_exists`, cancels `Process Period Closing Voucher` children, calls [`cancel_gl_entries`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:440) (enqueues `process_cancellation` when GL row count > 5000). |
| `on_trash` | [`:161`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:161) | Force-deletes linked PPCV docs regardless of docstatus. |

**GL entry point.** [`make_gl_entries`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:169) enqueues [`process_gl_and_closing_entries`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:463) when `tabGL Entry` count estimate exceeds 100 000, else runs inline. The worker calls [`get_pcv_gl_entries`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:185) (P&L reverse + closing account rows per dimension tuple) and then [`get_account_closing_balances`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:368) to write `Account Closing Balance` snapshots via [`make_closing_entries`](erpnext/accounts/doctype/account_closing_balance/account_closing_balance.py).

**Special handling in the universal GL pipeline.** The PCV voucher type is guarded out of:

- `BudgetValidation` — [`general_ledger.py:40`](erpnext/accounts/general_ledger.py:40).
- `create_payment_ledger_entry` — [`general_ledger.py:50`](erpnext/accounts/general_ledger.py:50).
- `distribute_gl_based_on_cost_center_allocation` — [`general_ledger.py:192`](erpnext/accounts/general_ledger.py:192).
- `validate_against_pcv` — [`general_ledger.py:416`](erpnext/accounts/general_ledger.py:416) (to avoid self-conflict during closing).

**hooks.py:**

- Member of: `period_closing_doctypes` [`:331`](erpnext/hooks.py:331).
- `auto_cancel_exempted_doctypes` also lists `Account Closing Balance` [`:430`](erpnext/hooks.py:430) so those rows don't cascade-cancel — PCV cleans them up via `process_cancellation`.
- No regional overrides.

## Cross-reference summary

| DocType | `on_submit` GL call-site | Cancel GL call-site | `auto_cancel_exempted` | In `period_closing_doctypes` | In `bank_reconciliation_doctypes` | Has repost (`on_update_after_submit`) |
| --- | --- | --- | --- | --- | --- | --- |
| Sales Invoice | [`:491`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:491) | [`:613`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:613) | no | yes | yes | yes ([`:841`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:841)) |
| Purchase Invoice | [`:785`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:785) | [`:1682`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:1682) | no | yes | yes | yes ([`:797`](erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py:797)) |
| Journal Entry | [`:204`](erpnext/accounts/doctype/journal_entry/journal_entry.py:204) | [`:316`](erpnext/accounts/doctype/journal_entry/journal_entry.py:316) | no | yes | yes | yes ([`:281`](erpnext/accounts/doctype/journal_entry/journal_entry.py:281)) |
| Payment Entry | [`:208`](erpnext/accounts/doctype/payment_entry/payment_entry.py:208) | [`:313`](erpnext/accounts/doctype/payment_entry/payment_entry.py:313) | yes ([`hooks.py:422`](erpnext/hooks.py:422)) | yes | yes | yes ([`:216`](erpnext/accounts/doctype/payment_entry/payment_entry.py:216)) |
| POS Invoice | inherited (consolidation) | inherited | no | no (Sales Invoice consolidates) | no | inherited |
| Period Closing Voucher | [`:135`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:135) or PPCV | [`:154`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:154) | no (but `Account Closing Balance` yes) | yes | no | no |

## Related

- [Accounts module](accounts.md) — directory map + masters.
- [Accounting flow](../flows/accounting-flow.md) — `make_gl_entries` pipeline.
- [Taxes and totals](../flows/taxes-and-totals.md) — how item/tax numbers are computed.
- [Payments flow](../flows/payments-flow.md) — PE lifecycle details.
- [Controller hierarchy](../architecture/controllers.md).
- [DocType lifecycle](../architecture/doctype-lifecycle.md).
- [Hooks and overrides](../architecture/hooks-and-overrides.md).
- [Regional overrides](../patterns/regional-overrides.md).

## Changelog

- `2026-04-18` — initial version (commit `fbe976fb3b`, branch `feat/setting-claude`).
