---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: accounts
status: complete
related_docs:
  - ../architecture/controllers.md
  - ../architecture/hooks-and-overrides.md
  - ../patterns/regional-overrides.md
  - ../flows/accounting-flow.md
  - ../flows/taxes-and-totals.md
  - ../flows/payments-flow.md
  - accounts-doctypes.md
---

# Module: Accounts

> **TL;DR:** The `erpnext/accounts/` module owns the Chart of Accounts (hierarchical, multi-company, multi-currency), the universal General Ledger write path, accounting dimensions and cost centers, fiscal-year / accounting-period controls, period closing, taxes and payment vouchers. It is the most heavily regional-overridden module; country specifics attach via [`regional_overrides`](../patterns/regional-overrides.md) without forking the core.

## Directory layout

- [`erpnext/accounts/doctype/`](erpnext/accounts/doctype) — 186 DocType folders covering transactions (Sales Invoice, Purchase Invoice, Payment Entry, Journal Entry), masters (Account, Cost Center, Fiscal Year, Mode of Payment), ledgers (GL Entry, Payment Ledger Entry, Advance Payment Ledger Entry, Account Closing Balance), and configuration singletons (Accounts Settings, Accounting Dimension, Accounting Dimension Filter).
- [`erpnext/accounts/general_ledger.py`](erpnext/accounts/general_ledger.py:1) — the canonical GL write path. See [accounting flow](../flows/accounting-flow.md).
- [`erpnext/accounts/utils.py`](erpnext/accounts/utils.py:1) — shared helpers: fiscal-year lookup, party-account resolution, ledger-health scheduler, payment-ledger creation, exchange-rate revaluation.
- [`erpnext/accounts/party.py`](erpnext/accounts/party.py:1) — `get_party_account`, `get_due_date`, party-level account currency resolution.
- [`erpnext/accounts/deferred_revenue.py`](erpnext/accounts/deferred_revenue.py:1) — monthly long-running job [`process_deferred_accounting`](erpnext/hooks.py:497) that posts deferred-revenue / deferred-expense JE entries.
- [`erpnext/accounts/report/`](erpnext/accounts/report) — 60+ financial reports (Balance Sheet, Profit and Loss, Trial Balance, General Ledger, Accounts Receivable/Payable, Budget Variance, Cash Flow, Tax Details, and country-specific reports).

## Chart of Accounts

Modelled as a [`NestedSet`](erpnext/accounts/doctype/account/account.py:25) tree (`parent_account`, `lft`, `rgt`) so sub-tree queries on balances, report roll-ups, and hierarchy listings stay O(log n). One tree per company — the `company` field gates everything.

### Account schema essentials

Defined in [`erpnext/accounts/doctype/account/account.py`](erpnext/accounts/doctype/account/account.py:1):

- **`root_type`** — `Asset | Liability | Income | Expense | Equity` ([type literal at `account.py:83`](erpnext/accounts/doctype/account/account.py:83)). Derived and propagated by [`set_root_and_report_type`](erpnext/accounts/doctype/account/account.py:163): when `parent_account` is set, the child inherits `root_type` and `report_type`. Editing `root_type` on a group account cascades to its descendants via a raw UPDATE using `lft`/`rgt` at [`account.py:178-186`](erpnext/accounts/doctype/account/account.py:178).
- **`report_type`** — `Balance Sheet | Profit and Loss`, auto-assigned at [`account.py:188`](erpnext/accounts/doctype/account/account.py:188): Asset/Liability/Equity → Balance Sheet, Income/Expense → Profit and Loss. Used heavily by [`period_closing_voucher.get_account_balances_based_on_dimensions`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:267) and the closing logic at [`general_ledger.make_round_off_gle`](erpnext/accounts/general_ledger.py:634).
- **`account_type`** — role-like tag: `Bank | Cash | Receivable | Payable | Tax | Stock | Cost of Goods Sold | Fixed Asset | Capital Work in Progress | Round Off | Round Off for Opening | Expense Account | Income Account | Expenses Included In Valuation | Stock Received But Not Billed | Service Received But Not Billed | Temporary | …` (full list at [`account.py:38-71`](erpnext/accounts/doctype/account/account.py:38)). Drives downstream behaviour: [`process_debit_credit_difference`](erpnext/accounts/general_ledger.py:471) uses `Round Off`, [`validate_cwip_accounts`](erpnext/accounts/general_ledger.py:444) uses `Capital Work in Progress`, Payment Entry uses `Bank`/`Cash` to decide the offsetting account.
- **`is_group`** — group vs ledger; validated with **balance-must-be** and **frozen** flags. Only group accounts can be parents ([`validate_parent`](erpnext/accounts/doctype/account/account.py:138)).
- **`account_currency`** — per-account currency. Transactions track `debit_in_account_currency` and `credit_in_account_currency` separately from the company-currency amounts (see [`general_ledger.merge_similar_entries`](erpnext/accounts/general_ledger.py:273) field list).
- **`freeze_account`** + Company-level `accounts_frozen_till_date` + `role_allowed_for_frozen_entries` — combined check at [`general_ledger.check_freezing_date`](erpnext/accounts/general_ledger.py:793) and [`gl_entry.validate_frozen_account`](erpnext/accounts/doctype/gl_entry/gl_entry.py:420).
- **`account_number`** — optional prefix; joined into the account name by [`get_autoname_with_number`](erpnext/accounts/doctype/account/account.py:103).
- **`include_in_gross`** — report flag for gross vs net rollups.

### Multi-company hierarchy

Parent-company accounts replicate into child companies via the parent-company flow at [`validate_root_company_and_sync_account_to_children`](erpnext/accounts/doctype/account/account.py:220). Child companies can opt out by setting `Company.allow_account_creation_against_child_company=1`. This keeps one canonical chart on the parent and per-company currency/number/disabled flags on the children.

### Chart templates

Chart-of-accounts seed files live under [`erpnext/accounts/doctype/account/chart_of_accounts/`](erpnext/accounts/doctype/account/chart_of_accounts):

- [`verified/`](erpnext/accounts/doctype/account/chart_of_accounts/verified) — country-by-country reviewed templates (e.g. `au_standard_chart_of_accounts.json`, `fr_plan_comptable.json`, `de_skr03.json`, many West-African CEMAC/UEMOA plans, SKR04, US GAAP variants).
- `unverified/` — community contributions not yet validated.
- [`chart_of_accounts.py`](erpnext/accounts/doctype/account/chart_of_accounts/chart_of_accounts.py) exposes the reader.
- User CSV import lives in [`chart_of_accounts_importer`](erpnext/accounts/doctype/chart_of_accounts_importer).

## Accounting dimensions + cost centers

Accounting dimensions are user-defined additional ledgers (e.g. `Project`, `Location`, `Branch`) that ride alongside `account` and `cost_center` on every GL Entry.

- **Definition.** [`Accounting Dimension`](erpnext/accounts/doctype/accounting_dimension/accounting_dimension.py:20) registers a source DocType (e.g. `Project`) and adds a custom field to all transactional and ledger DocTypes. The list is served by [`get_accounting_dimensions`](erpnext/accounts/doctype/accounting_dimension/accounting_dimension.py:1) and merged into merge-keys at [`general_ledger.get_merge_properties`](erpnext/accounts/general_ledger.py:329).
- **Auto-balancing (offsetting).** Per-company `Accounting Dimension Detail` rows can set `automatically_post_balancing_accounting_entry=1` with an `offsetting_account`. On `make_gl_entries`, [`make_acc_dimensions_offsetting_entry`](erpnext/accounts/general_ledger.py:70) appends a balancing row per dimension whenever the map mixes more than one value for that dimension — so dimension-scoped balances stay closed.
- **Filters.** [`Accounting Dimension Filter`](erpnext/accounts/doctype/accounting_dimension_filter/accounting_dimension_filter.py) restricts which dimension values are allowed/required on specific accounts. Enforced per row in [`validate_allowed_dimensions`](erpnext/accounts/general_ledger.py:847) with exception classes [`InvalidAccountDimensionError`, `MandatoryAccountDimensionError`](erpnext/exceptions.py:1).
- **Cost centers.** [`Cost Center`](erpnext/accounts/doctype/cost_center/cost_center.py:1) is also a `NestedSet`, scoped by company. Cost-center allocation is a separate DocType (`Cost Center Allocation` + `Cost Center Allocation Percentage`) and splits postings across sub-centers at write time — see [`distribute_gl_based_on_cost_center_allocation`](erpnext/accounts/general_ledger.py:203).
- **Hardcoded default dimensions.** Beyond user-defined ones, [`cost_center`, `finance_book`, `project`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:286) are always treated as dimensions by PCV and GL merge.

## Fiscal year and accounting periods

- **[`Fiscal Year`](erpnext/accounts/doctype/fiscal_year/fiscal_year.py:12)** — date range with `year_start_date`, `year_end_date`, child table `fiscal_year_company`. Overlap validation at [`validate_overlap`](erpnext/accounts/doctype/fiscal_year/fiscal_year.py:57). Scheduler auto-creates the next year: [`erpnext.accounts.doctype.fiscal_year.fiscal_year.auto_create_fiscal_year`](erpnext/hooks.py:466) in `daily_maintenance`.
- **Accounting period.** [`Accounting Period`](erpnext/accounts/doctype/accounting_period/accounting_period.py) + `Closed Document` child table let admins mark individual DocTypes as closed over a date range, with optional `exempted_role`. Checked at [`general_ledger.validate_accounting_period`](erpnext/accounts/general_ledger.py:153). Every period-closing doctype also runs a pre-save check via [`validate_accounting_period_on_doc_save`](erpnext/hooks.py:351), registered in `doc_events`:
  ```python
  tuple(period_closing_doctypes): {
      "validate": "erpnext.accounts.doctype.accounting_period.accounting_period.validate_accounting_period_on_doc_save",
  },
  ```
  Membership list at [`hooks.py:322`](erpnext/hooks.py:322) covers Sales Invoice, Purchase Invoice, JE, PE, Stock Entry, Delivery Note, Purchase Receipt, Stock Reconciliation, etc.
- **Period Closing Voucher.** [`Period Closing Voucher`](erpnext/accounts/doctype/period_closing_voucher/period_closing_voucher.py:21) rolls P&L balances into a closing `Equity` / `Liability` account on `period_end_date`. Full flow in [accounts-doctypes.md](accounts-doctypes.md#period-closing-voucher).
- **Company freeze.** `Company.accounts_frozen_till_date` is a blanket cut-off checked at [`general_ledger.check_freezing_date`](erpnext/accounts/general_ledger.py:793). `role_allowed_for_frozen_entries` lets specific roles (not Administrator) bypass.

## GL Entry and Payment Ledger Entry

- **[`GL Entry`](erpnext/accounts/doctype/gl_entry/gl_entry.py:28)** is a submittable DocType. [`validate`](erpnext/accounts/doctype/gl_entry/gl_entry.py:83) enforces account currency, fiscal year assignment ([`validate_and_set_fiscal_year`](erpnext/accounts/doctype/gl_entry/gl_entry.py:320)), cost-center presence for non-group accounts ([`validate_cost_center`](erpnext/accounts/doctype/gl_entry/gl_entry.py:256)), party presence for Receivable/Payable accounts ([`validate_party`](erpnext/accounts/doctype/gl_entry/gl_entry.py:276)), and dimension rules for P&L vs Balance-Sheet via [`validate_dimensions_for_pl_and_bs`](erpnext/accounts/doctype/gl_entry/gl_entry.py:188). [`update_outstanding_amt`](erpnext/accounts/doctype/gl_entry/gl_entry.py:348) keeps `outstanding_amount` in sync on the referenced voucher.
- **Payment Ledger Entry** mirrors GL with party/reference bookkeeping for outstanding tracking. Created by [`create_payment_ledger_entry`](erpnext/accounts/general_ledger.py:23) (imported from [`erpnext/accounts/utils.py`](erpnext/accounts/utils.py:1)) at the same call sites that write GL. Skipped for Period Closing Voucher ([`general_ledger.py:50`](erpnext/accounts/general_ledger.py:50)).
- **Advance Payment Ledger Entry** tracks SO/PO advance positions separately; populated by Payment Entry at [`make_advance_gl_entries`](erpnext/accounts/doctype/payment_entry/payment_entry.py:1442) when the Company option *Book Advance Payments in Separate Party Account* is on.
- **Account Closing Balance** stores the pre-closing balances by accounting-dimension tuple; written by [`make_closing_entries`](erpnext/accounts/doctype/account_closing_balance/account_closing_balance.py:1) during PCV submit.

## Tax framework

- **Masters.** `Sales Taxes and Charges Template`, `Purchase Taxes and Charges Template`, `Item Tax Template`, `Tax Category`, `Tax Rule`. The templates define `charge_type` (`Actual | On Net Total | On Previous Row Amount | On Previous Row Total | On Item Quantity`), rate, account head, cost center, `included_in_print_rate`, `add_deduct_tax`, `category` (`Total | Valuation | Valuation and Total`).
- **Runtime.** [`erpnext/controllers/taxes_and_totals.py`](erpnext/controllers/taxes_and_totals.py:26) is invoked from [`AccountsController.calculate_taxes_and_totals`](erpnext/controllers/accounts_controller.py:734) on every save of a tax-bearing transaction. The full pipeline is described in [taxes-and-totals.md](../flows/taxes-and-totals.md).
- **Withholding.** `Tax Withholding Category` + `Tax Withholding Entry` + the per-doctype `SalesTaxWithholding` / `PurchaseTaxWithholding` / `PaymentTaxWithholding` / `JournalTaxWithholding` wrappers plug into each invoice's `validate`, `on_submit`, and `on_cancel`. For example SI at [`sales_invoice.py:309`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:309), [`:464`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:464), [`:607`](erpnext/accounts/doctype/sales_invoice/sales_invoice.py:607).

## Payment and reconciliation

- **Payment Entry** ([`erpnext/accounts/doctype/payment_entry/payment_entry.py`](erpnext/accounts/doctype/payment_entry/payment_entry.py:1)) — covered in depth in [payments flow](../flows/payments-flow.md).
- **Payment Reconciliation** ([`erpnext/accounts/doctype/payment_reconciliation/payment_reconciliation.py:27`](erpnext/accounts/doctype/payment_reconciliation/payment_reconciliation.py:27)) — fetch unreconciled entries, allocate invoices vs payments vs credit/debit notes, write new JE links (`get_unreconciled_entries`, `allocate_entries`, `reconcile`).
- **Payment Request** ([`erpnext/accounts/doctype/payment_request/payment_request.py`](erpnext/accounts/doctype/payment_request/payment_request.py:1)) — upstream of Payment Entry; links to payment gateways.
- **Payment Terms / Payment Schedule** — computed on each invoice via [`AccountsController.set_payment_schedule`](erpnext/controllers/accounts_controller.py:2519); see [payments flow](../flows/payments-flow.md#payment-schedule).

## Bank clearance

- **Bank Clearance** ([`erpnext/accounts/doctype/bank_clearance/bank_clearance.py`](erpnext/accounts/doctype/bank_clearance/bank_clearance.py)) — reconciles `Payment Entry`, `Journal Entry`, `Purchase Invoice`, `Sales Invoice` against bank statements (see `bank_reconciliation_doctypes` at [`hooks.py:530`](erpnext/hooks.py:530)). Feeder functions declared in `hooks.py` as `get_payment_entries_for_bank_clearance` and related ([`hooks.py:600-606`](erpnext/hooks.py:600)).
- **Bank Reconciliation Tool** ([`erpnext/accounts/doctype/bank_reconciliation_tool`](erpnext/accounts/doctype/bank_reconciliation_tool)) — matches `Bank Transaction` rows to vouchers.

## Reports

Top-level reports in [`erpnext/accounts/report/`](erpnext/accounts/report):

- **Statements.** Balance Sheet, Profit and Loss Statement, Cash Flow, Trial Balance, Consolidated Financial Statement, Consolidated Trial Balance.
- **Ledgers.** General Ledger, Party Ledger (Customer/Supplier/Item-wise), Accounts Receivable, Accounts Payable, Payment Ledger.
- **Operational.** Budget Variance Report, Tax Detail, Sales/Purchase Register, Item-wise Sales/Purchase Register, Gross and Net Profit.
- **Asset.** Asset Depreciation Ledger, Asset Depreciations and Balances.

Most reports read `GL Entry` directly, joined with `Account`, accounting dimensions, and the voucher's own DocType for drill-down.

## Scheduler jobs wired in `hooks.py`

From [`erpnext/hooks.py`](erpnext/hooks.py:433):

- **Hourly, offset 30m.** `erpnext.accounts.doctype.gl_entry.gl_entry.rename_gle_sle_docs` — reattaches renamed vouchers to their ledger rows.
- **Daily maintenance.**
  - [`erpnext.controllers.accounts_controller.update_invoice_status`](erpnext/hooks.py:465) — updates `Overdue` status across invoices.
  - [`erpnext.accounts.doctype.fiscal_year.fiscal_year.auto_create_fiscal_year`](erpnext/hooks.py:466).
  - [`erpnext.accounts.doctype.process_statement_of_accounts.process_statement_of_accounts.send_auto_email`](erpnext/hooks.py:482).
  - [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_daily`](erpnext/hooks.py:483).
  - [`erpnext.accounts.utils.run_ledger_health_checks`](erpnext/hooks.py:484).
  - [`erpnext.accounts.doctype.process_subscription.process_subscription.create_subscription_process`](erpnext/hooks.py:487).
  - [`erpnext.assets.doctype.asset.depreciation.post_depreciation_entries`](erpnext/hooks.py:491).
- **Weekly.** [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_weekly`](erpnext/hooks.py:494).
- **Monthly long.**
  - [`erpnext.accounts.deferred_revenue.process_deferred_accounting`](erpnext/hooks.py:497).
  - [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_monthly`](erpnext/hooks.py:498).

See [hooks and overrides](../architecture/hooks-and-overrides.md) for the full `scheduler_events` tour and [patches](../patterns/patches.md) for migrations.

## Regional overrides for the accounts module

Declared in [`regional_overrides` at `hooks.py:608`](erpnext/hooks.py:608) — the accounts-module entries today:

- **United Arab Emirates.** Replaces [`erpnext.controllers.taxes_and_totals.update_itemised_tax_data`](erpnext/hooks.py:611) and [`erpnext.accounts.doctype.purchase_invoice.purchase_invoice.make_regional_gl_entries`](erpnext/hooks.py:612) (RCM entries).
- **Saudi Arabia.** Replaces `taxes_and_totals.update_itemised_tax_data`.
- **Italy.** Replaces `taxes_and_totals.update_itemised_tax_data` and `erpnext.controllers.accounts_controller.validate_regional` ([`hooks.py:619`](erpnext/hooks.py:619)). Also wires additional `doc_events` on Sales Invoice submit/cancel (`italy.utils.sales_invoice_on_submit/on_cancel` at [`hooks.py:377-380`](erpnext/hooks.py:377)).

The canonical default implementations (no-ops for GL hooks) are reachable via `@erpnext.allow_regional` — see [regional overrides](../patterns/regional-overrides.md).

## Related

- [Accounting flow](../flows/accounting-flow.md) — submit/cancel GL pipeline.
- [Taxes and totals](../flows/taxes-and-totals.md) — tax computation lifecycle.
- [Payments flow](../flows/payments-flow.md) — Payment Entry, reconciliation, advances, FX.
- [Accounts DocType reference cards](accounts-doctypes.md) — per-doctype paths, hooks, entry points.
- [Hooks and overrides](../architecture/hooks-and-overrides.md) — full `hooks.py` tour.
- [Regional overrides](../patterns/regional-overrides.md) — country-specific hooks.
- [Controller hierarchy](../architecture/controllers.md) — where `AccountsController` fits.

## Changelog

- `2026-04-17` — initial version (commit `fbe976fb3b`, branch `feat/setting-claude`).
