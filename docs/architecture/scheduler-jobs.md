---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: architecture/scheduler
status: complete
related_docs:
  - architecture/hooks-and-overrides.md
  - flows/accounting-flow.md
  - flows/stock-flow.md
  - flows/assets-flow.md
  - flows/manufacturing-flow.md
  - modules/accounts.md
  - modules/stock.md
  - modules/assets.md
  - modules/buying.md
  - modules/selling.md
  - modules/manufacturing.md
  - modules/setup.md
---

# Scheduler jobs catalogue

> **TL;DR:** ERPNext registers ~32 background jobs in [`scheduler_events`](../../erpnext/hooks.py:433-500). They run under Frappe's scheduler worker (started by `bench start` via the `schedule` Procfile entry — see [development.md](../getting-started/development.md)). This page is the single inventory: every job, its frequency, its module, what it touches, and what fails if it stops. Cross-links point to the module/flow docs that already explain the job's effect in depth.

## Key files

- [erpnext/hooks.py](../../erpnext/hooks.py:433) — `scheduler_events` declaration (lines 433-500).
- [erpnext/hooks.py](../../erpnext/hooks.py:434-447) — `cron` block (3 cron entries + 1 reserved-but-empty slot at `45 0 * * *`).
- Frappe core dispatches scheduler entries from `frappe.utils.scheduler` (Frappe app, out-of-tree). `bench --site <site> trigger-scheduler-event <event>` executes a frequency band on demand.
- `Scheduled Job Type` DocType (Frappe core) — every entry below appears as a row there once `bench migrate` runs after a hooks change. Toggle `stopped` per row to disable a single job without redeploying.

## How frequency bands map to wall-clock

| Band | Default cron equivalent | Notes |
|------|--------------------------|-------|
| `cron` | exact cron string per entry | Used when you need sub-hourly cadence. ERPNext uses 3 cron strings (see below). |
| `hourly` | `0 * * * *` | Top of every hour. |
| `hourly_long` | `0 * * * *`, separate worker queue | For jobs that may run >5 min without blocking the hourly band. ERPNext registers nothing here. |
| `hourly_maintenance` | `0 * * * *`, `maintenance` queue | Hourly band for jobs that touch many rows but tolerate slip. |
| `daily` | `0 0 * * *` | Midnight. ERPNext registers nothing here. |
| `daily_long` | `0 0 * * *`, separate worker queue | For long daily jobs. ERPNext registers nothing here. |
| `daily_maintenance` | `0 0 * * *`, `maintenance` queue | The big nightly batch — 30 entries. |
| `weekly` | `0 0 * * 1` (Mon midnight) | One entry. |
| `monthly_long` | first-of-month midnight, long queue | Two entries. |

> **TODO(verify):** exact wall-clock for `daily_maintenance` vs `daily` is set by Frappe's scheduler config; the bands above mirror Frappe defaults but can be overridden in `common_site_config`'s `scheduler_interval`. No in-tree ERPNext file pins them.

## 1. `cron` band — fixed-cron entries

Declared at [hooks.py:434-447](../../erpnext/hooks.py:434).

| Cron | Function | Module | What it touches | If it stops |
|------|----------|--------|-----------------|-------------|
| `0/15 * * * *` | [`erpnext.manufacturing.doctype.bom_update_log.bom_update_log.resume_bom_cost_update_jobs`](../../erpnext/hooks.py:436) | Manufacturing | `BOM Update Log` rows in `In Progress` state; resumes paused level-wise BOM cost-roll-up batches. Walks `BOM` and `BOM Update Batch` to continue from the last completed level. | New BOM cost recalculations queued via `BOM Update Tool` stall after the first level. See [flows/manufacturing-flow.md](../flows/manufacturing-flow.md) and [modules/manufacturing.md](../modules/manufacturing.md). |
| `0/30 * * * *` | [`erpnext.stock.doctype.repost_item_valuation.repost_item_valuation.run_parallel_reposting`](../../erpnext/hooks.py:439) | Stock | `Repost Item Valuation` rows in `Queued` / `In Progress` state. Spawns parallel workers to rebuild SLE / Bin / GL after backdated stock changes. | Backdated stock entries leave SLE/Bin/GL inconsistent until manual repost. See [flows/stock-flow.md](../flows/stock-flow.md) and [modules/stock-doctypes.md](../modules/stock-doctypes.md). |
| `30 * * * *` | [`erpnext.accounts.doctype.gl_entry.gl_entry.rename_gle_sle_docs`](../../erpnext/hooks.py:443) | Accounts | `GL Entry` and `Stock Ledger Entry` rows whose name still uses the legacy hash-only format. Renames in batches to the current `<voucher_type>-<voucher_no>-<series>` style. | Old-format GLE/SLE names persist (cosmetic — no functional impact). |
| `45 0 * * *` | _(empty)_ | — | Reserved slot at [hooks.py:446](../../erpnext/hooks.py:446) with no entries. Open for downstream apps to register a daily job offset by 45 minutes from midnight. | n/a |

## 2. `hourly` band

Declared at [hooks.py:448-450](../../erpnext/hooks.py:448).

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.projects.doctype.project.project.hourly_reminder`](../../erpnext/hooks.py:449) | Projects | `Project` rows with daily/hourly reminder cadence; sends update emails to assigned users. | Project status reminders silently drop. |

## 3. `hourly_long` band

Declared at [hooks.py:451](../../erpnext/hooks.py:451). **Empty in this commit.**

## 4. `hourly_maintenance` band

Declared at [hooks.py:452-459](../../erpnext/hooks.py:452).

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.stock.doctype.repost_item_valuation.repost_item_valuation.repost_entries`](../../erpnext/hooks.py:453) | Stock | `Repost Item Valuation` queue; sequential reposting (single-threaded fallback to the cron parallel runner). Rebuilds SLE / Bin / valuation / GL for the affected items + warehouses. | Backlog grows; UI shows pending reposts. See [flows/stock-flow.md](../flows/stock-flow.md). |
| [`erpnext.utilities.bulk_transaction.retry`](../../erpnext/hooks.py:454) | Utilities | `Bulk Transaction Log` + `Bulk Transaction Log Detail`; retries failed bulk operations (mass print, mass status change, mass cancel) up to a configured retry count. | Failed bulk ops are not retried automatically. |
| [`erpnext.projects.doctype.project.project.collect_project_status`](../../erpnext/hooks.py:455) | Projects | `Project` + `Task` rollups; aggregates task status into the project's progress %. | Project progress bar drifts from underlying task state. |
| [`erpnext.projects.doctype.project.project.project_status_update_reminder`](../../erpnext/hooks.py:456) | Projects | `Project` rows past their due date without recent status update; emails the assigned user. | Stale projects no longer prompt the assignee. |
| [`erpnext.erpnext_integrations.doctype.plaid_settings.plaid_settings.automatic_synchronization`](../../erpnext/hooks.py:457) | ERPNext Integrations | `Bank Transaction` rows; pulls new transactions via the Plaid API for every linked Bank Account where Plaid sync is enabled. | New bank transactions stop appearing automatically. |
| [`erpnext.utilities.doctype.video.video.update_youtube_data`](../../erpnext/hooks.py:458) | Utilities | `Video` rows; refreshes YouTube view counts / publication date via the YouTube Data API. | YouTube stats freeze. |

## 5. `daily` band

Declared at [hooks.py:460](../../erpnext/hooks.py:460). **Empty in this commit.** All daily work runs in `daily_maintenance`.

## 6. `daily_long` band

Declared at [hooks.py:461](../../erpnext/hooks.py:461). **Empty in this commit.**

## 7. `daily_maintenance` band — the big nightly batch

Declared at [hooks.py:462-492](../../erpnext/hooks.py:462). 30 entries.

### 7.1 Support / CRM auto-close + reminders

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.support.doctype.issue.issue.auto_close_tickets`](../../erpnext/hooks.py:463) | Support | `Issue` rows in `Replied` status untouched for `Support Settings.close_issue_after_days`; flips to `Closed`. | Stale tickets stay `Replied` indefinitely. |
| [`erpnext.crm.doctype.opportunity.opportunity.auto_close_opportunity`](../../erpnext/hooks.py:464) | CRM | `Opportunity` rows in `Open` past `CRM Settings.close_opportunity_after_days`; flips to `Closed - Lost`. | Stale opportunities stay `Open`. |
| [`erpnext.crm.doctype.contract.contract.update_status_for_contracts`](../../erpnext/hooks.py:473) | CRM | `Contract` rows; flips `Active` → `Inactive` past end date. | Expired contracts keep showing as `Active`. |
| [`erpnext.crm.doctype.email_campaign.email_campaign.send_email_to_leads_or_contacts`](../../erpnext/hooks.py:478) | CRM | `Email Campaign` rows in `In Progress`; sends today's batch of campaign emails. | Campaign cadence stalls. |
| [`erpnext.crm.doctype.email_campaign.email_campaign.set_email_campaign_status`](../../erpnext/hooks.py:479) | CRM | `Email Campaign` status transitions (`Scheduled` → `In Progress` → `Completed`). | Campaign status freezes. |
| [`erpnext.crm.utils.open_leads_opportunities_based_on_todays_event`](../../erpnext/hooks.py:490) | CRM | `Lead` / `Opportunity` rows linked to today's `Event`; reopens those that were `Replied` or auto-closed. | Calendar-driven re-engagement breaks. |

### 7.2 Accounts core

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.controllers.accounts_controller.update_invoice_status`](../../erpnext/hooks.py:465) | Accounts (controller) | `Sales Invoice` and `Purchase Invoice`: recalculates `status` (`Overdue`, `Partially Paid`, `Paid`) and outstanding amount snapshots. | Invoice status badges drift; aging reports show stale `Unpaid` for paid invoices. See [flows/accounting-flow.md](../flows/accounting-flow.md) and [modules/accounts-doctypes.md](../modules/accounts-doctypes.md). |
| [`erpnext.accounts.doctype.fiscal_year.fiscal_year.auto_create_fiscal_year`](../../erpnext/hooks.py:466) | Accounts | `Fiscal Year` master; if today's date is within 30 days of the latest year's end, creates the next year by cloning the date pattern. | First posting in the new fiscal year throws "No Fiscal Year defined". See [modules/accounts.md](../modules/accounts.md). |
| [`erpnext.accounts.doctype.process_statement_of_accounts.process_statement_of_accounts.send_auto_email`](../../erpnext/hooks.py:482) | Accounts | `Process Statement of Accounts` rows scheduled for today; emails customer statements as PDF. | Customer statements are not auto-emailed. |
| [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_daily`](../../erpnext/hooks.py:483) | Accounts | `Exchange Rate Revaluation` for FX accounts where `Accounts Settings.auto_reconcile_payments` is enabled and frequency is `Daily`. Creates a draft revaluation doc. | Daily FX revaluation draft is not created. See [modules/accounts.md](../modules/accounts.md). |
| [`erpnext.accounts.utils.run_ledger_health_checks`](../../erpnext/hooks.py:484) | Accounts | `Ledger Health Monitor` (Single) — runs Voucher-wise Balance + General Ledger checks per company; logs mismatches. | Silent ledger drift goes unnoticed. Code path: [accounts/utils.py:2605](../../erpnext/accounts/utils.py:2605). |
| [`erpnext.accounts.doctype.process_subscription.process_subscription.create_subscription_process`](../../erpnext/hooks.py:487) | Accounts | `Subscription` rows due today; generates `Sales Invoice` (or `Purchase Invoice`) per subscription cycle. | Recurring billing stalls. |

### 7.3 Selling / Buying

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.selling.doctype.quotation.quotation.set_expired_status`](../../erpnext/hooks.py:480) | Selling | `Quotation` rows past `valid_till`; flips `status` to `Expired`. | Old quotations keep showing as open. See [modules/selling.md](../modules/selling.md). |
| [`erpnext.buying.doctype.supplier_quotation.supplier_quotation.set_expired_status`](../../erpnext/hooks.py:481) | Buying | `Supplier Quotation` rows past `valid_till`; flips to `Expired`. | Old supplier quotations keep showing as open. See [modules/buying.md](../modules/buying.md). |
| [`erpnext.buying.doctype.supplier_scorecard.supplier_scorecard.refresh_scorecards`](../../erpnext/hooks.py:469) | Buying | `Supplier Scorecard` + `Supplier Scorecard Period` + `Supplier Scorecard Scoring Standing` / `Variable` / `Criteria`; recomputes the period score per supplier. | Scorecards freeze; supplier gating flags driven by score don't update. See [modules/buying.md](../modules/buying.md). |
| [`erpnext.stock.reorder_item.reorder_item`](../../erpnext/hooks.py:486) | Stock / Buying | `Bin` levels per `Item Reorder` rule; auto-creates `Material Request` (and optionally `Purchase Order`) when projected stock falls below the reorder level. | Auto-replenishment stops; manual MR creation required. See [modules/stock.md](../modules/stock.md). |

### 7.4 Stock / Manufacturing maintenance

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.stock.doctype.serial_no.serial_no.update_maintenance_status`](../../erpnext/hooks.py:468) | Stock | `Serial No` rows linked to `Maintenance Schedule`; flips `maintenance_status` (`Out of AMC`, `Under AMC`, `Under Warranty`, `Out of Warranty`). | AMC/warranty status displayed on serial number records goes stale. |
| [`erpnext.manufacturing.doctype.bom_update_tool.bom_update_tool.auto_update_latest_price_in_all_boms`](../../erpnext/hooks.py:489) | Manufacturing | `BOM` rows; if `Manufacturing Settings.update_bom_costs_automatically=1`, refreshes `rate` from latest valuation rates and re-roll-ups operating cost. | BOM cost goes stale; new WO/SO using `rate_of_materials_based_on=Valuation Rate` reads outdated costs. See [modules/manufacturing.md](../modules/manufacturing.md). |

### 7.5 Assets

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.assets.doctype.asset.asset.update_maintenance_status`](../../erpnext/hooks.py:471) | Assets | `Asset` rows with `maintenance_required=1`; flips `maintenance_status` based on next-due-date. | Asset maintenance dashboards drift. See [modules/assets.md](../modules/assets.md). |
| [`erpnext.assets.doctype.asset.asset.make_post_gl_entry`](../../erpnext/hooks.py:472) | Assets | `Asset` rows that were submitted with `available_for_use_date` in the future and are now ready for capitalization GL; posts the deferred GL entries. | Capitalization GL for future-dated assets sits pending. See [flows/assets-flow.md](../flows/assets-flow.md). |
| [`erpnext.assets.doctype.asset_maintenance_log.asset_maintenance_log.update_asset_maintenance_log_status`](../../erpnext/hooks.py:485) | Assets | `Asset Maintenance Log` rows past due date in `Planned`; flips to `Overdue`. | Maintenance logs stay `Planned` past due. |
| [`erpnext.assets.doctype.asset.depreciation.post_depreciation_entries`](../../erpnext/hooks.py:491) | Assets | `Asset Depreciation Schedule` active rows due today; posts the `Journal Entry` per row (Dr Depreciation Expense / Cr Accumulated Depreciation), stamps the schedule row's `journal_entry`. **The single most-impactful daily job for accounting correctness.** | Depreciation expense is not booked daily; month-end reports under-state expense. See [flows/assets-flow.md](../flows/assets-flow.md). |

### 7.6 Setup / Reports / misc

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.setup.doctype.company.company.cache_companies_monthly_sales_history`](../../erpnext/hooks.py:470) | Setup | `Company.total_monthly_sales`; precomputes the leaderboard target field (consumed by `notification_config.targets.Company` — see [boot-session.md](boot-session.md)). | `Company` notification target widget shows stale numbers. |
| [`erpnext.projects.doctype.task.task.set_tasks_as_overdue`](../../erpnext/hooks.py:467) | Projects | `Task` rows past `exp_end_date` in `Open` / `Working`; flips to `Overdue`. | Overdue tasks no longer flagged. |
| [`erpnext.projects.doctype.project.project.update_project_sales_billing`](../../erpnext/hooks.py:474) | Projects | `Project.total_sales_amount` + `Project.total_billable_amount` + `total_billed_amount`; rolls up linked Sales Order / Sales Invoice / Timesheet sums. | Project P&L widget stale. |
| [`erpnext.projects.doctype.project.project.send_project_status_email_to_users`](../../erpnext/hooks.py:475) | Projects | Project owners; sends a daily project digest. | Daily project email stops. |
| [`erpnext.quality_management.doctype.quality_review.quality_review.review`](../../erpnext/hooks.py:476) | Quality Management | `Quality Review` rows due today; auto-creates the next review based on `Quality Goal.frequency`. | Periodic quality reviews not auto-generated. |
| [`erpnext.support.doctype.service_level_agreement.service_level_agreement.check_agreement_status`](../../erpnext/hooks.py:477) | Support | `Service Level Agreement` rows; flips `Active` → `Disabled` past `end_date`. | Expired SLAs continue to apply. |
| [`erpnext.setup.doctype.email_digest.email_digest.send`](../../erpnext/hooks.py:488) | Setup | `Email Digest` rows scheduled for today; renders + emails the configured digest tiles. | Daily/weekly/monthly Email Digest stops sending. See [modules/setup.md](../modules/setup.md). |

## 8. `weekly` band

Declared at [hooks.py:493-495](../../erpnext/hooks.py:493).

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_weekly`](../../erpnext/hooks.py:494) | Accounts | `Exchange Rate Revaluation` for FX accounts where revaluation frequency is `Weekly`. Creates a draft revaluation doc. | Weekly FX revaluation draft not created. |

## 9. `monthly_long` band

Declared at [hooks.py:496-499](../../erpnext/hooks.py:496).

| Function | Module | What it touches | If it stops |
|----------|--------|-----------------|-------------|
| [`erpnext.accounts.deferred_revenue.process_deferred_accounting`](../../erpnext/hooks.py:497) | Accounts | `Process Deferred Accounting` + `Deferred Revenue` / `Deferred Expense` schedules; books the period's recognition entries (Dr Deferred / Cr Income or Dr Expense / Cr Deferred). | Monthly deferred-revenue / deferred-expense recognition stops. |
| [`erpnext.accounts.utils.auto_create_exchange_rate_revaluation_monthly`](../../erpnext/hooks.py:498) | Accounts | `Exchange Rate Revaluation` for FX accounts where revaluation frequency is `Monthly`. Creates a draft revaluation doc. | Monthly FX revaluation draft not created. |

## 10. Cross-link map

| Job | Documented in flow / module |
|-----|------------------------------|
| `repost_entries`, `run_parallel_reposting` | [flows/stock-flow.md](../flows/stock-flow.md), [modules/stock-doctypes.md](../modules/stock-doctypes.md) |
| `post_depreciation_entries`, `make_post_gl_entry`, `update_maintenance_status` (Asset), `update_asset_maintenance_log_status` | [flows/assets-flow.md](../flows/assets-flow.md), [modules/assets.md](../modules/assets.md) |
| `update_invoice_status` | [flows/accounting-flow.md](../flows/accounting-flow.md), [modules/accounts.md](../modules/accounts.md) |
| `auto_create_exchange_rate_revaluation_*`, `process_deferred_accounting`, `run_ledger_health_checks`, `auto_create_fiscal_year`, `create_subscription_process` | [modules/accounts.md](../modules/accounts.md) |
| `set_expired_status` (Quotation) | [modules/selling.md](../modules/selling.md), [flows/selling-flow.md](../flows/selling-flow.md) |
| `set_expired_status` (Supplier Quotation), `refresh_scorecards`, `reorder_item` | [modules/buying.md](../modules/buying.md), [flows/buying-flow.md](../flows/buying-flow.md) |
| `resume_bom_cost_update_jobs`, `auto_update_latest_price_in_all_boms` | [modules/manufacturing.md](../modules/manufacturing.md), [flows/manufacturing-flow.md](../flows/manufacturing-flow.md) |
| `cache_companies_monthly_sales_history`, `email_digest.send` | [modules/setup.md](../modules/setup.md) |

## Tracing entry points

### Find a job's source from its function path

```bash
# given the dotted path from hooks.py
grep -rn "def post_depreciation_entries" erpnext/
# or with ripgrep + path filter
rg -n "def post_depreciation_entries" erpnext/
```

The dotted path in `hooks.py` is the import path: `erpnext.assets.doctype.asset.depreciation.post_depreciation_entries` lives at `erpnext/assets/doctype/asset/depreciation.py:post_depreciation_entries`.

### Trigger a job manually

```bash
# Run a single function as the bench user (uses the site's frappe context)
bench --site <site-name> execute erpnext.assets.doctype.asset.depreciation.post_depreciation_entries

# Trigger an entire frequency band (Frappe core)
bench --site <site-name> trigger-scheduler-event daily_maintenance

# Force a single Scheduled Job Type row to fire now (Frappe core)
bench --site <site-name> trigger-scheduler-event \
  "erpnext.assets.doctype.asset.depreciation.post_depreciation_entries"
```

### Monitor scheduler activity

- **`Scheduled Job Type` (DocType, Frappe core)** — one row per registered hooks entry. Columns: `method`, `cron_format` / `frequency`, `next_execution`, `last_execution`, `stopped`, `server_script`. Toggle `stopped=1` to disable a single job without changing `hooks.py`.
- **`Scheduled Job Log` (DocType, Frappe core)** — execution history per job. Filter by `scheduled_job_type` to see runs of one job; columns `status` (`Complete` / `Failed`), `details` (traceback on failure), `creation`.
- **`Error Log` (DocType, Frappe core)** — captures uncaught exceptions from scheduler runs. Filter by `error LIKE '%<function-name>%'` to find recent failures.
- **Bench logs** — `frappe-bench/logs/scheduler.log` and `frappe-bench/logs/worker.log` show per-process scheduler activity at the OS level (the `schedule` and `worker` Procfile entries).

### Adding a new scheduled job (workflow)

1. Add the dotted path to the right band in [`scheduler_events`](../../erpnext/hooks.py:433) in `hooks.py`.
2. Run `bench --site <site> migrate` — Frappe creates / updates the corresponding `Scheduled Job Type` row.
3. Verify with `bench --site <site> trigger-scheduler-event <method>` that the function runs without exception against the site's data.
4. Add an entry to the table above and to the cross-link map; cite the new line in `hooks.py`.

## Open questions

- **TODO(verify)** — exact dispatch order within `daily_maintenance`. Frappe runs the list serially but the order is alphabetical-by-function-name in some Frappe versions and registration-order in others. If two jobs depend on each other (e.g., `cache_companies_monthly_sales_history` before reading `Company.total_monthly_sales` elsewhere), the order matters.
- **TODO(verify)** — the empty `45 0 * * *` cron slot at [hooks.py:446](../../erpnext/hooks.py:446) is intentional; no in-tree comment explains why. Possibly a downstream-app extension point.

## Related

- [Hooks and overrides](hooks-and-overrides.md) — high-level tour of `hooks.py`; this doc is the depth read for `scheduler_events`.
- [Hooks catalogue](hooks-catalogue.md) — the per-DocType list registries (no scheduler entries).
- [Boot session](boot-session.md) — what runs on every login (vs every interval).
- [Operations](../getting-started/operations.md) — `bench` cheatsheet (`trigger-scheduler-event`, `Scheduled Job Type`, `Scheduled Job Log`).

## Changelog

- `2026-04-18` — initial version. Covers all 32 entries in `hooks.py:434-499` (3 cron, 1 hourly, 0 hourly_long, 6 hourly_maintenance, 0 daily, 0 daily_long, 30 daily_maintenance, 1 weekly, 2 monthly_long).
