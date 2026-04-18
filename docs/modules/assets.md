---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: assets
status: complete
related_docs:
  - modules/assets-doctypes.md
  - flows/assets-flow.md
  - flows/accounting-flow.md
  - flows/buying-flow.md
  - flows/selling-flow.md
  - flows/stock-flow.md
  - patterns/regional-overrides.md
---

# Assets Module

> **TL;DR:** The Assets module manages the full lifecycle of fixed assets: creation (manual or auto-created from Purchase Invoice / Purchase Receipt), depreciation (Straight Line, Double Declining Balance, Written Down Value, Manual; multi-finance-book; shift-based), capitalization (Asset Capitalization rolls Stock + Asset + Service costs into a new asset), repairs (with optional cost-capitalization branch), value adjustments, movements (Receipt / Issue / Transfer), and disposal (Sales Invoice sale, Scrap). The depreciation engine is a daily scheduler (`post_depreciation_entries` at [hooks.py:491](../../erpnext/hooks.py:491)) that walks every active `Asset Depreciation Schedule` and posts `Journal Entry` per due row. Asset itself extends `AccountsController`; Asset Capitalization extends `StockController` (so it writes both SLE and GL); Asset Repair extends `AccountsController`; Asset Movement / Asset Value Adjustment / Asset Maintenance / Asset Shift Allocation sit directly on `Document`.

## Directory layout

```
erpnext/assets/
├── __init__.py
├── dashboard_fixtures.py
├── assets_dashboard/
├── dashboard_chart/
├── number_card/
├── module_onboarding/
├── onboarding_step/
├── workspace/
├── report/
└── doctype/
    ├── asset/                                    — main Asset DocType + depreciation engine
    │   ├── asset.py                              — Asset(AccountsController), 1577 lines
    │   ├── depreciation.py                       — scheduler + JE posting + disposal GL, 839 lines
    │   ├── asset_dashboard.py
    │   └── asset_list.js
    ├── asset_activity/                           — append-only audit log (insert via add_asset_activity)
    ├── asset_capitalization/                     — AssetCapitalization(StockController), 876 lines
    ├── asset_capitalization_asset_item/          — child: Asset Capitalization Asset Item
    ├── asset_capitalization_service_item/        — child: Asset Capitalization Service Item
    ├── asset_capitalization_stock_item/          — child: Asset Capitalization Stock Item
    ├── asset_category/                           — Asset Category (master) + finance_books defaults
    ├── asset_category_account/                   — child: Asset Category Account (per-company GL accounts)
    ├── asset_depreciation_schedule/              — schedule submittable; children = depreciation_schedule rows
    │   ├── asset_depreciation_schedule.py
    │   ├── deppreciation_schedule_controller.py  — DepreciationScheduleController(StraightLineMethod, WDVMethod)
    │   └── depreciation_methods.py               — StraightLineMethod + WDVMethod (with @allow_regional)
    ├── asset_finance_book/                       — child of Asset and Asset Category
    ├── asset_maintenance/                        — Asset Maintenance schedule (Document)
    ├── asset_maintenance_log/                    — Asset Maintenance Log (submittable)
    ├── asset_maintenance_task/                   — child: per-task periodicity
    ├── asset_maintenance_team/                   — Maintenance Team (master)
    ├── maintenance_team_member/                  — child of Asset Maintenance Team
    ├── asset_movement/                           — Asset Movement (Document); receipt/issue/transfer
    ├── asset_movement_item/                      — child: per-asset row in movement
    ├── asset_repair/                             — AssetRepair(AccountsController); optional capitalize_repair_cost
    ├── asset_repair_consumed_item/               — child: stock items consumed during repair
    ├── asset_repair_purchase_invoice/            — child: linked PI rows for service repair-cost lines
    ├── asset_shift_allocation/                   — Asset Shift Allocation (Document, submittable)
    ├── asset_shift_factor/                       — Asset Shift Factor (per-shift multiplier master)
    ├── asset_value_adjustment/                   — Asset Value Adjustment (Document, submittable)
    ├── depreciation_schedule/                    — child: row in Asset Depreciation Schedule
    ├── linked_location/                          — child: Linked Location (used by Warehouse → Location)
    └── location/                                 — Location (NestedSet, geo-aware)
```

The `asset/` DocType folder is unusual: it carries both the controller (`asset.py`) and the depreciation engine (`depreciation.py`) that the daily scheduler invokes. All disposal/scrap/restore/regain GL helpers also live in `depreciation.py`.

## Controller posture

| DocType | Base class | File | Notes |
|---|---|---|---|
| Asset | `AccountsController` | [asset.py:42](../../erpnext/assets/doctype/asset/asset.py:42) | Posts CWIP → Fixed Asset GL on submit when CWIP is enabled and PR/PI didn't already book the fixed-asset GL. |
| Asset Capitalization | `StockController` | [asset_capitalization.py:47](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:47) | Writes both SLE (consumed stock) and GL (consumed assets, services, stock); reposts future SLE/GL on submit/cancel. |
| Asset Repair | `AccountsController` | [asset_repair.py:23](../../erpnext/assets/doctype/asset_repair/asset_repair.py:23) | Posts GL only when `capitalize_repair_cost=1` ([asset_repair.py:202](../../erpnext/assets/doctype/asset_repair/asset_repair.py:202)). Stock-item consumption goes through a child Stock Entry submitted by the repair (`decrease_stock_quantity` at [asset_repair.py:255](../../erpnext/assets/doctype/asset_repair/asset_repair.py:255)). |
| Asset Movement | `Document` | [asset_movement.py:13](../../erpnext/assets/doctype/asset_movement/asset_movement.py:13) | Pure metadata: updates `Asset.location` / `Asset.custodian`; no GL/SLE. |
| Asset Value Adjustment | `Document` | [asset_value_adjustment.py:21](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:21) | Posts a Journal Entry directly via `make_asset_revaluation_entry` ([asset_value_adjustment.py:86](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:86)) — does not go through `make_gl_entries` / `process_gl_map`. |
| Asset Depreciation Schedule | `DepreciationScheduleController(StraightLineMethod, WDVMethod)` | [asset_depreciation_schedule.py:18](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:18) | Submittable schedule (`Draft` → `Active` → `Cancelled`). One per (asset, finance_book). |
| Asset Maintenance | `Document` | [asset_maintenance.py:14](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:14) | Generates `Asset Maintenance Log` rows per task; status updates feed Asset status (`In Maintenance` / `Out of Order`). |
| Asset Maintenance Log | `Document` (submittable) | [asset_maintenance_log.py:14](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:14) | Recomputes next due date back into `Asset Maintenance Task` on Completed. |
| Asset Shift Allocation | `Document` (submittable) | [asset_shift_allocation.py:23](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:23) | Mutates the active `Asset Depreciation Schedule` by replacing it with a recomputed copy that reflects new shift rows. |
| Location | `NestedSet` | [location.py:15](../../erpnext/assets/doctype/location/location.py:15) | Tree DocType; calculates geodesic area from GeoJSON features. |

The Stock-vs-Accounts split is intentional: only Asset Capitalization needs to consume inventory, so it's the only one promoted to `StockController`. Cross-link controllers in [docs/architecture/controllers.md](../architecture/controllers.md).

## Depreciation engine

### The daily scheduler

`erpnext.assets.doctype.asset.depreciation.post_depreciation_entries` is registered in `daily_maintenance` at [hooks.py:491](../../erpnext/hooks.py:491). It is a thin wrapper:

1. Bails out early if `Accounts Settings.book_asset_depreciation_entry_automatically` is off ([depreciation.py:38-43](../../erpnext/assets/doctype/asset/depreciation.py:38)).
2. Calls `book_depreciation_entries(date)` which iterates rows from `get_depreciable_assets_data` ([depreciation.py:81-108](../../erpnext/assets/doctype/asset/depreciation.py:81)).
3. For each (`Asset Depreciation Schedule`, asset, sch_start_idx, sch_end_idx) tuple, calls `make_depreciation_entry` ([depreciation.py:166](../../erpnext/assets/doctype/asset/depreciation.py:166)).

`get_depreciable_assets_data` is the gating query. It returns one row **per active depreciation schedule** with the index range of unposted, due rows:

- Joins `Asset` × `Asset Depreciation Schedule` × `Depreciation Schedule` (the child).
- `Asset.calculate_depreciation == 1`, `Asset.docstatus == 1`, `Asset Depreciation Schedule.docstatus == 1`, `Asset.status IN ('Submitted', 'Partially Depreciated')`.
- `Depreciation Schedule.journal_entry IS NULL` (skip already-posted rows).
- `Depreciation Schedule.schedule_date <= date`.
- Companies frozen via `accounts_frozen_till_date` are filtered out unless the running user has the configured role ([depreciation.py:111-124](../../erpnext/assets/doctype/asset/depreciation.py:111)).

### Per-row Journal Entry build

Inside `make_depreciation_entry` ([depreciation.py:166-213](../../erpnext/assets/doctype/asset/depreciation.py:166)), for each due row:

- `setup_journal_entry_metadata` sets `voucher_type = 'Depreciation Entry'`, naming series from `Company.series_for_depreciation_entry`, posting date from the schedule row, and `je.finance_book = depr_schedule_doc.finance_book`.
- `get_credit_and_debit_accounts` ([depreciation.py:296-308](../../erpnext/assets/doctype/asset/depreciation.py:296)) inverts the dr/cr depending on `Account.root_type` of the depreciation expense account (Income vs Expense).
- `get_credit_and_debit_entry` ([depreciation.py:264-293](../../erpnext/assets/doctype/asset/depreciation.py:264)) emits two rows: depreciation expense (Dr) and accumulated depreciation (Cr) in the standard Expense case. Both rows carry `reference_type='Asset'`, `reference_name=<asset>`, and inherit accounting dimensions from the asset where mandatory or set.

The resulting Journal Entry is submitted unless a workflow is attached to JE ([depreciation.py:247](../../erpnext/assets/doctype/asset/depreciation.py:247)). On success the `Depreciation Schedule.journal_entry` field is filled, so the next scheduler tick won't re-pick the row.

Failures are caught per-asset; failed assets get `Asset.depr_entry_posting_status='Failed'` and the Accounts Manager (or System Manager) is emailed via `notify_depr_entry_posting_error` ([depreciation.py:316-330](../../erpnext/assets/doctype/asset/depreciation.py:316)).

### GL impact (Expense root_type, the typical case)

| Account | Dr | Cr | Source |
|---|---|---|---|
| Depreciation Expense (Expense) | depreciation_amount | — | [depreciation.py:275-281](../../erpnext/assets/doctype/asset/depreciation.py:275) |
| Accumulated Depreciation (Liability/Asset, contra) | — | depreciation_amount | [depreciation.py:267-273](../../erpnext/assets/doctype/asset/depreciation.py:267) |

When the depreciation expense account has `root_type='Income'` (rare; e.g. recovered depreciation), the dr/cr swap inside `get_credit_and_debit_accounts`.

### Schedules and methods

`DepreciationScheduleController` ([deppreciation_schedule_controller.py:24](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:24)) inherits from `StraightLineMethod` and `WDVMethod` ([depreciation_methods.py:15, 76](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:15)). Method dispatch:

- **Straight Line** — default. `get_straight_line_depr_amount` divides `(value_after_depreciation - expected_value_after_useful_life)` by remaining periods ([depreciation_methods.py:16-31](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:16)). Two sub-modes: **daily prorata** (`fb_row.daily_prorata_based`) and **shift-based** (`fb_row.shift_based`).
- **Double Declining Balance** — rate = `200 / (total_depreciations × frequency / 12)` ([asset.py:1001-1012](../../erpnext/assets/doctype/asset/asset.py:1001)).
- **Written Down Value** — rate computed so that `value_after_useful_life` is reached after `pending_years`; closed-form `100 * (1 - (salvage / value)^(1/years))` ([asset.py:1014-1039](../../erpnext/assets/doctype/asset/asset.py:1014)). Both DDB and WDV route through `WDVMethod.get_wdv_or_dd_depr_amount`, which is decorated `@erpnext.allow_regional` ([depreciation_methods.py:77-79](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:77)) — open slot for country apps (notably India Compliance) to override.
- **Manual** — no automatic schedule; user posts depreciation by hand. Tracked via `get_manual_depreciation_entries` ([asset.py:831-848](../../erpnext/assets/doctype/asset/asset.py:831)).

### Multi-finance-book

Each `Asset.finance_books` row produces its own `Asset Depreciation Schedule` — one (asset, finance_book) pair per submittable schedule. `validate_another_asset_depr_schedule_does_not_exist` ([asset_depreciation_schedule.py:59-85](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:59)) enforces the uniqueness. The default finance book is read from `Company` ([asset.py:822-829](../../erpnext/assets/doctype/asset/asset.py:822)).

### Mid-period changes and rescheduling

When the depreciation parameters change after submission (asset value, opening accumulated depreciation, method, frequency, salvage value, start date), `should_regenerate_depreciation_schedule` ([asset.py:201-214](../../erpnext/assets/doctype/asset/asset.py:201)) decides whether to rebuild via `evaluate_and_recreate_depreciation_schedule` ([asset.py:166-175](../../erpnext/assets/doctype/asset/asset.py:166)).

`reschedule_depreciation` ([deppreciation_schedule_controller.py:193-215](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:193)) is the central rebuild helper used by Asset Value Adjustment, Asset Repair (when capitalising), Asset Capitalization, and Sales Invoice asset-disposal paths. It:

1. Loads the current `Asset Depreciation Schedule` (Active or Draft).
2. Copies it (if Active) and recomputes the rate (`set_modified_depreciation_rate` for WDV / DDB).
3. Cancels the old schedule with `flags.should_not_cancel_depreciation_entries = True` so booked JEs survive.
4. Submits the rebuilt schedule.

### Fully-depreciated transition

`get_status` ([asset.py:776-807](../../erpnext/assets/doctype/asset/asset.py:776)) sets `Asset.status = 'Fully Depreciated'` when `value_after_depreciation <= expected_value_after_useful_life` (per the default finance book), and `'Partially Depreciated'` while there's still gap. `'Sold'` is set by `Sales Invoice.update_asset` after disposal ([sales_invoice.py:1505-1527](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1505)). `'Scrapped'` is set by `scrap_asset` ([depreciation.py:362-372](../../erpnext/assets/doctype/asset/depreciation.py:362)).

## Capitalization vs Repair vs Movement vs Adjustment

| Operation | DocType | Posts SLE? | Posts GL? | Touches `Asset.value_after_depreciation` |
|---|---|---|---|---|
| Capitalization | Asset Capitalization | Yes (consumed stock items) | Yes (own `make_gl_entries` + `repost_future_sle_and_gle`) | Yes — bumps `net_purchase_amount`, `purchase_amount`, `total_asset_cost` of the target asset ([asset_capitalization.py:550-575](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:550)). |
| Repair (capitalising) | Asset Repair | Yes (via child Stock Entry, `decrease_stock_quantity`) | Yes (own `make_gl_entries`, `Asset Repair` GL voucher) | Yes — bumps `total_asset_cost`, `additional_asset_cost`, and each finance-book `value_after_depreciation` ([asset_repair.py:239-250](../../erpnext/assets/doctype/asset_repair/asset_repair.py:239)). |
| Repair (not capitalising) | Asset Repair | Yes (via child Stock Entry) | No (skipped — repair cost stays as expense in the originating PI / Stock Entry) | No |
| Movement | Asset Movement | No | No | No (only `Asset.location` and `Asset.custodian`) |
| Value Adjustment | Asset Value Adjustment | No | Yes (direct `Journal Entry` submission, `voucher_type='Journal Entry'`, not via `make_gl_entries`) | Yes — adjusts `value_after_depreciation` and salvage value, then `reschedule_depreciation` ([asset_value_adjustment.py:181-203](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:181)). |
| Shift Allocation | Asset Shift Allocation | No | No (mutates schedule only) | Indirect — recomputed depreciation amounts post differently next scheduler tick. |
| Disposal (Scrap) | Asset (via `scrap_asset` whitelisted) | No | Yes (`voucher_type='Asset Disposal'`, JE built from `get_gl_entries_on_asset_disposal`) | Implicit — asset moves to `Scrapped` status. |
| Disposal (Sale) | Sales Invoice with `is_fixed_asset=1` item | No | Yes (SI's normal GL extended via `process_asset_depreciation` → `depreciate_asset_on_sale`) | Yes — updates disposal date and status. |

For full GL mechanics (`make_gl_entries`, `process_gl_map`, `make_reverse_gl_entries`) cross-link [docs/flows/accounting-flow.md](../flows/accounting-flow.md). For SLE mechanics (`make_sl_entries`) cross-link [docs/flows/stock-flow.md](../flows/stock-flow.md).

## Asset lifecycle

```
                         ┌─────────────┐
                         │   Draft     │
                         └──────┬──────┘
                                │ submit (on_submit posts CWIP→Asset GL when applicable)
                                ▼
                         ┌─────────────┐
                         │  Submitted  │ ◄────┐
                         └──┬───────┬──┘      │ restore_asset
                            │       │         │ (reverses disposal)
            depreciation    │       │ value_after_depreciation
            posts JE        │       │ < net_purchase_amount
                            ▼       ▼
                ┌─────────────────────────────┐
                │   Partially Depreciated      │
                └────────────┬─────────────────┘
                             │ value_after_depreciation
                             │ <= expected_value_after_useful_life
                             ▼
                ┌─────────────────────────────┐
                │     Fully Depreciated        │
                └─────────────────────────────┘

  Side-channel statuses:
   • Sold        — Sales Invoice with is_fixed_asset item submitted
   • Scrapped    — scrap_asset() called
   • Capitalized — consumed by Asset Capitalization (asset_items table)
   • In Maintenance / Out of Order — set by Asset Repair / Maintenance Log activity
   • Work In Progress — Composite Asset still being built
```

The status transitions are computed in `Asset.get_status` ([asset.py:776-807](../../erpnext/assets/doctype/asset/asset.py:776)) and can also be set directly via `Asset.set_status(status)` ([asset.py:770-774](../../erpnext/assets/doctype/asset/asset.py:770)).

`Asset.validate_cancellation` ([asset.py:728-736](../../erpnext/assets/doctype/asset/asset.py:728)) blocks cancellation while status is `In Maintenance` or `Out of Order`. `on_cancel` ([asset.py:267-278](../../erpnext/assets/doctype/asset/asset.py:267)) cancels Asset Movements, deletes depreciation JEs (`delete_depreciation_entries` at [asset.py:751-768](../../erpnext/assets/doctype/asset/asset.py:751)), cancels all schedules (`cancel_asset_depr_schedules`), and reverses the asset's own GL via `make_reverse_gl_entries` (skipped for Composite Component sub-assets).

## Asset Maintenance

`Asset Maintenance` ([asset_maintenance.py:14](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:14)) groups maintenance tasks per asset. On `validate` it forces overdue tasks into `Overdue` status and validates assignment ([asset_maintenance.py:36-43](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:36)). On `on_update` it pushes assignments into `tabToDo` via `frappe.desk.form.assign_to.add` ([asset_maintenance.py:73-90](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:73)) and synchronises the `Asset Maintenance Log` table.

`Asset Maintenance Log` is submittable. On `on_submit` (Completed) it advances `next_due_date` on the parent task by computing the next periodicity tick ([asset_maintenance_log.py:57-77](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:57)).

The daily scheduler `update_asset_maintenance_log_status` ([hooks.py:485](../../erpnext/hooks.py:485), [asset_maintenance_log.py:80-88](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:80)) sweeps Planned logs whose `due_date < today` and bumps their status to `Overdue`.

The complementary daily scheduler `update_maintenance_status` ([hooks.py:471](../../erpnext/hooks.py:471), [asset.py:1058-1070](../../erpnext/assets/doctype/asset/asset.py:1058)) inspects assets with `maintenance_required=1` and sets `Asset.status` to `Out of Order` (if there's a Pending Asset Repair), `In Maintenance` (if there's a Maintenance Task due today), or recomputes via `set_status()`.

> **Phase scope note:** maintenance is intentionally summarised here. A standalone, deeper write-up is reserved for a later phase per the gap-fill plan.

## Asset Shift Allocation

`Asset Shift Allocation` ([asset_shift_allocation.py:23](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:23)) modulates the depreciation amount per period when shift-based depreciation is in use. The factor lookup is `Asset Shift Factor` ([asset_shift_factor.py:9](../../erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py:9)), where `shift_factor` is a multiplier (e.g. Single = 1.0, Double = 1.5, Triple = 2.0). On submit, the allocation cancels the active `Asset Depreciation Schedule` and submits a copy reflecting the new shifts ([asset_shift_allocation.py:189-225](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:189)). The legacy schedule's `flags.should_not_cancel_depreciation_entries = True` preserves already-posted JEs.

The actual maths happens inside `StraightLineMethod.get_shift_depr_amount` ([depreciation_methods.py:47-70](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:47)): for each row, `depreciation_amount = (depreciable_value / sum_of_remaining_shift_factors) * row_shift_factor`.

## Scheduler jobs

All four Assets-related entries live in `daily_maintenance` ([hooks.py:462-492](../../erpnext/hooks.py:462)):

| Line | Function | Source | Purpose |
|---|---|---|---|
| [hooks.py:471](../../erpnext/hooks.py:471) | `update_maintenance_status` | [asset.py:1058](../../erpnext/assets/doctype/asset/asset.py:1058) | Sets `Asset.status` to `In Maintenance` / `Out of Order` based on pending Asset Repairs and Maintenance Tasks. |
| [hooks.py:472](../../erpnext/hooks.py:472) | `make_post_gl_entry` | [asset.py:1073](../../erpnext/assets/doctype/asset/asset.py:1073) | For CWIP-enabled categories, posts the CWIP → Fixed Asset GL today for assets whose `available_for_use_date == today` and `booked_fixed_asset == 0`. |
| [hooks.py:485](../../erpnext/hooks.py:485) | `update_asset_maintenance_log_status` | [asset_maintenance_log.py:80](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:80) | Bulk-updates Planned logs past their due date to `Overdue`. |
| [hooks.py:491](../../erpnext/hooks.py:491) | `post_depreciation_entries` | [depreciation.py:37](../../erpnext/assets/doctype/asset/depreciation.py:37) | The depreciation engine — see above. |

There are no `hourly`, `weekly`, or `monthly` Asset jobs. See [docs/architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) for the full scheduler tour.

## Regional overrides

The Assets module currently has **two `@erpnext.allow_regional` open slots** but **no entry in `regional_overrides`** (verified against [hooks.py:608-621](../../erpnext/hooks.py:608)):

| Slot | Source | Default behaviour | Override case |
|---|---|---|---|
| `cancel_depreciation_entries(asset_doc, date)` | [depreciation.py:488-493](../../erpnext/assets/doctype/asset/depreciation.py:488) | No-op (`pass`). | Comment at [depreciation.py:492](../../erpnext/assets/doctype/asset/depreciation.py:492) explicitly notes "Overwritten via India Compliance app" — Indian Income Tax Act forbids depreciating an asset in the financial year it was sold/scrapped, so India Compliance reverses the in-year postings. |
| `WDVMethod.get_wdv_or_dd_depr_amount(self, row_idx)` | [depreciation_methods.py:77-79](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:77) | Calls the standard `WDVMethod.calculate_wdv_or_dd_based_depreciation_amount`. | Open slot — countries that need a different WDV/DDB amortisation curve (again typically India) replace the per-row computation. |

Cross-link [docs/patterns/regional-overrides.md](../patterns/regional-overrides.md) and the per-country survey in [docs/modules/regional.md](regional.md). No country in the in-tree `erpnext/regional/<country>/` packages overrides either slot — the overrides ship in third-party country apps (e.g. India Compliance) installed alongside ERPNext.

## Cross-module interactions

### Buying → Assets (auto-creation)

`BuyingController.process_fixed_asset` ([buying_controller.py:990-995](../../erpnext/controllers/buying_controller.py:990)) is invoked from PR `on_submit` and from PI `on_submit` only when `update_stock=1` (otherwise PI never touches stock so it does not need to spawn assets). It collects items where `is_fixed_asset=1` and dispatches to `auto_make_assets` ([buying_controller.py:997-1059](../../erpnext/controllers/buying_controller.py:997)), which calls `make_asset` per row ([buying_controller.py:1061-1109](../../erpnext/controllers/buying_controller.py:1061)). The asset is inserted in `Draft` status, linked back to PR/PI via `purchase_receipt[_item]` / `purchase_invoice[_item]`, gated by `Item.auto_create_assets` and `Item.asset_naming_series`.

The **CWIP bridge** lives on Asset itself: `Asset.validate_make_gl_entry` ([asset.py:850-885](../../erpnext/assets/doctype/asset/asset.py:850)) inspects whether the originating PI/PR has already posted the fixed-asset GL. If CWIP is enabled and the PR posted CWIP, then on Asset submit the asset's own GL flips CWIP into the Fixed Asset account ([asset.py:923-969](../../erpnext/assets/doctype/asset/asset.py:923)).

For the upstream side, cross-link [docs/flows/buying-flow.md](../flows/buying-flow.md) and the PR/PI cards in [docs/modules/buying-doctypes.md](buying-doctypes.md).

### Selling → Assets (disposal on sale)

`Sales Invoice.process_asset_depreciation` ([sales_invoice.py:1450-1459](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1450)) is invoked from SI `on_submit` ([sales_invoice.py:488](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:488)) and `on_cancel` ([sales_invoice.py:611](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:611)). For non-internal-transfer SIs:

- On submit (or on cancel of a return SI) — `depreciate_asset_on_sale` calls `depreciate_asset` ([depreciation.py:475-485](../../erpnext/assets/doctype/asset/depreciation.py:475)) → `reschedule_depreciation` + `make_depreciation_entry_on_disposal` + `cancel_depreciation_entries` (regional no-op).
- On cancel (or on submit of a return SI) — `restore_asset` reverses the disposal-date depreciation entries via `reverse_depreciation_entry_made_on_disposal` ([depreciation.py:502-514](../../erpnext/assets/doctype/asset/depreciation.py:502)) and rebuilds the schedule.
- `update_asset` ([sales_invoice.py:1505-1527](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1505)) sets `Asset.disposal_date` and `Asset.status='Sold'` (or clears them on return / cancel).

The disposal GL itself is composed by `get_gl_entries_on_asset_disposal` ([depreciation.py:633-687](../../erpnext/assets/doctype/asset/depreciation.py:633)) and merged into the Sales Invoice's own GL stream by `Sales Invoice Item.set_income_account_for_fixed_asset` (on the SI side) plus the SI controller. Cross-link [docs/flows/selling-flow.md](../flows/selling-flow.md).

### Accounts → Assets (period closing)

`Asset` is in `period_closing_doctypes` ([hooks.py:333](../../erpnext/hooks.py:333)) along with `Asset Capitalization` and `Asset Repair` ([hooks.py:334-335](../../erpnext/hooks.py:334)). This means:

- The `*` `validate` hook bound to `tuple(period_closing_doctypes)` runs `validate_accounting_period_on_doc_save` ([hooks.py:350-352](../../erpnext/hooks.py:350)) — saving an Asset during a closed accounting period throws.
- Period Closing Voucher considers Asset / Asset Capitalization / Asset Repair vouchers when sealing the period.

Cross-link the GL mechanics in [docs/flows/accounting-flow.md](../flows/accounting-flow.md) (PCV section).

### Stock → Assets (consumption)

Asset Capitalization writes SLE for consumed stock items via `update_stock_ledger` ([asset_capitalization.py:367-382](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:367)) using the standard `StockController.make_sl_entries` path. Asset Repair issues consumed stock through a child Stock Entry (purpose: `Material Issue`, `asset_repair=<name>`) submitted at `on_submit` ([asset_repair.py:255-290](../../erpnext/assets/doctype/asset_repair/asset_repair.py:255)). Cross-link [docs/flows/stock-flow.md](../flows/stock-flow.md) and [docs/modules/stock-doctypes.md](stock-doctypes.md).

## Membership in metadata registries

| Registry (`erpnext/hooks.py`) | Asset DocType inclusion |
|---|---|
| `period_closing_doctypes` ([hooks.py:333-335](../../erpnext/hooks.py:333)) | Asset, Asset Capitalization, Asset Repair |
| `accounting_dimension_doctypes` ([hooks.py:543, 562-564, 587-588](../../erpnext/hooks.py:543)) | Asset, Asset Value Adjustment, Asset Repair, Asset Capitalization, Asset Movement Item, Asset Depreciation Schedule |
| `global_search_doctypes` ([hooks.py:664](../../erpnext/hooks.py:664)) | Asset (index 28) |
| `regional_overrides` ([hooks.py:608-621](../../erpnext/hooks.py:608)) | _none — see [Regional overrides](#regional-overrides)_ |
| `bank_reconciliation_doctypes` | _none_ |
| `subscription_doctypes` | _none_ |

## Reports

Asset module reports live under `erpnext/assets/report/`. Notable ones (audit via `ls erpnext/assets/report/` to expand):

- `fixed_asset_register` — point-in-time asset listing with cost, accumulated depreciation, NBV.
- `pending_asset_maintenance` — overdue / due maintenance tasks.

> **TODO(verify):** enumerate the full report directory in a follow-up if a complete report inventory is required (per phase scope this overview is sufficient).

## Where to start tracing

| Question | Open this first |
|---|---|
| "Where does daily depreciation come from?" | [depreciation.py:37](../../erpnext/assets/doctype/asset/depreciation.py:37) → [hooks.py:491](../../erpnext/hooks.py:491). |
| "Why does my Asset show CWIP balance after PR submit?" | [asset.py:850](../../erpnext/assets/doctype/asset/asset.py:850) (`validate_make_gl_entry`) and [asset.py:923](../../erpnext/assets/doctype/asset/asset.py:923) (`make_gl_entries`); CWIP toggle at [asset_category.py:110-126](../../erpnext/assets/doctype/asset_category/asset_category.py:110). |
| "Why isn't my asset auto-created from PI?" | `update_stock` flag — [buying_controller.py:990-991](../../erpnext/controllers/buying_controller.py:990); `Item.auto_create_assets` and `Item.asset_naming_series` checked at [buying_controller.py:1007-1010](../../erpnext/controllers/buying_controller.py:1007). |
| "How does selling a fixed asset post the disposal GL?" | [sales_invoice.py:488](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:488) → [sales_invoice.py:1450](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1450) → [depreciation.py:633](../../erpnext/assets/doctype/asset/depreciation.py:633). |
| "How is the depreciation amount per row computed?" | `DepreciationScheduleController.create` ([deppreciation_schedule_controller.py:54](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:54)) and method classes at [depreciation_methods.py:15-79](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:15). |
| "How do I add country-specific depreciation rules?" | [docs/patterns/regional-overrides.md](../patterns/regional-overrides.md) + the `@erpnext.allow_regional` slots listed above. |

## Related

- [Assets DocType reference cards](assets-doctypes.md)
- [Assets flow](../flows/assets-flow.md)
- [Accounting flow](../flows/accounting-flow.md)
- [Stock flow](../flows/stock-flow.md)
- [Selling flow](../flows/selling-flow.md)
- [Buying flow](../flows/buying-flow.md)
- [Regional overrides](../patterns/regional-overrides.md)
- [Hooks and overrides](../architecture/hooks-and-overrides.md)
- [Controller hierarchy](../architecture/controllers.md)

## Changelog

- `2026-04-18` — initial version (Phase 1 of Assets gap-fill).
