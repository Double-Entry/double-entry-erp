---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: assets
status: complete
related_docs:
  - modules/assets.md
  - flows/assets-flow.md
  - flows/accounting-flow.md
  - flows/stock-flow.md
---

# Assets DocType Reference Cards

> **TL;DR:** Per-DocType reference for everything under `erpnext/assets/doctype/`. Each card lists the file path, the controller base class, the lifecycle hooks the controller implements, the GL/SLE entry points, key fields, and child tables. For module-level orientation read [docs/modules/assets.md](assets.md) first.

The cards are grouped: **core asset** → **depreciation schedule + methods** → **lifecycle operations** → **maintenance** → **shift / value adjustment** → **masters and children**.

---

## Asset

- **Path:** [erpnext/assets/doctype/asset/asset.py](../../erpnext/assets/doctype/asset/asset.py)
- **Controller:** `Asset(AccountsController)` ([asset.py:42](../../erpnext/assets/doctype/asset/asset.py:42))
- **Submittable:** Yes
- **Naming series:** `ACC-ASS-.YYYY.-`
- **Status set:** Draft, Submitted, Cancelled, Partially Depreciated, Fully Depreciated, Sold, Scrapped, In Maintenance, Out of Order, Issue, Receipt, Capitalized, Work In Progress ([asset.py:102-116](../../erpnext/assets/doctype/asset/asset.py:102))

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset.py:123-134](../../erpnext/assets/doctype/asset/asset.py:123) | Validates category, precision, linked PR/PI documents, asset values, item is fixed-asset + non-stock, cost center, and finance books. |
| `before_save` | [asset.py:136-138](../../erpnext/assets/doctype/asset/asset.py:136) | Recomputes `total_asset_cost = net_purchase_amount + additional_asset_cost`; refreshes status. |
| `on_update` | [asset.py:241-244](../../erpnext/assets/doctype/asset/asset.py:241) | Creates/updates `Asset Depreciation Schedule` per finance book; recomputes `total_number_of_booked_depreciations`. |
| `before_submit` | [asset.py:246-250](../../erpnext/assets/doctype/asset/asset.py:246) | For Composite Asset: requires an active Asset Capitalization. |
| `on_submit` | [asset.py:252-265](../../erpnext/assets/doctype/asset/asset.py:252) | Validates available-for-use date, creates initial Asset Movement (Receipt), posts CWIP→Fixed Asset GL via `make_gl_entries` if `validate_make_gl_entry` passes, converts Draft schedules → Active. |
| `on_cancel` | [asset.py:267-278](../../erpnext/assets/doctype/asset/asset.py:267) | Validates cancellation, cancels Asset Movements, deletes/cancels depreciation JEs, cancels schedules, calls `make_reverse_gl_entries(voucher_type='Asset', voucher_no=self.name)`. |
| `after_insert` | [asset.py:280-287](../../erpnext/assets/doctype/asset/asset.py:280) | Logs `Asset created` in Asset Activity. |
| `after_delete` | [asset.py:289-290](../../erpnext/assets/doctype/asset/asset.py:289) | Logs `Asset deleted` in Asset Activity. |

### GL entry points

- `make_gl_entries` ([asset.py:923-969](../../erpnext/assets/doctype/asset/asset.py:923)) — Dr Fixed Asset / Cr CWIP, posted only when `validate_make_gl_entry` ([asset.py:850-885](../../erpnext/assets/doctype/asset/asset.py:850)) determines the originating PR/PI booked CWIP and not the fixed asset directly.
- `validate_make_gl_entry` decides which side of the CWIP-vs-direct purchase pattern applies.
- Reverse on cancel: `make_reverse_gl_entries(voucher_type='Asset', voucher_no=self.name)` ([asset.py:276](../../erpnext/assets/doctype/asset/asset.py:276)).
- Disposal/scrap GL is built externally by `get_gl_entries_on_asset_disposal` and `get_gl_entries_on_asset_regain` in [depreciation.py:580-708](../../erpnext/assets/doctype/asset/depreciation.py:580).

### Whitelisted endpoints

- `make_sales_invoice(asset, item_code, company, sell_qty, serial_no=None)` ([asset.py:1095-1125](../../erpnext/assets/doctype/asset/asset.py:1095)) — builds a SI to dispose of the asset.
- `create_asset_maintenance` / `create_asset_repair` / `create_asset_capitalization` / `create_asset_value_adjustment` ([asset.py:1128-1187](../../erpnext/assets/doctype/asset/asset.py:1128)) — pre-fill new docs.
- `split_asset(asset_name, split_qty)` ([asset.py:1367-1395](../../erpnext/assets/doctype/asset/asset.py:1367)) — splits a multi-quantity asset into two records.
- `get_asset_value_after_depreciation(asset_name, finance_book=None)` ([asset.py:1321-1330](../../erpnext/assets/doctype/asset/asset.py:1321)).
- `has_active_capitalization(asset)` ([asset.py:1333-1338](../../erpnext/assets/doctype/asset/asset.py:1333)).

### Module functions (called by scheduler)

- `update_maintenance_status()` ([asset.py:1058-1070](../../erpnext/assets/doctype/asset/asset.py:1058)) — daily ([hooks.py:471](../../erpnext/hooks.py:471)).
- `make_post_gl_entry()` ([asset.py:1073-1087](../../erpnext/assets/doctype/asset/asset.py:1073)) — daily ([hooks.py:472](../../erpnext/hooks.py:472)).

### Key fields (selected)

- `item_code` (Link → Item, mandatory; must be `is_fixed_asset=1` and `is_stock_item=0`).
- `asset_category` (Link → Asset Category) — drives GL accounts.
- `calculate_depreciation` (Check) — gates schedule creation.
- `finance_books` (Table → Asset Finance Book) — multi-book depreciation parameters.
- `purchase_invoice` / `purchase_receipt` + `_item` (links back to source PI / PR).
- `value_after_depreciation` / `opening_accumulated_depreciation` / `total_asset_cost` / `additional_asset_cost`.
- `asset_type` ∈ `''`, `Existing Asset`, `Composite Asset`, `Composite Component`.
- `depr_entry_posting_status` ∈ `''`, `Successful`, `Failed` — set by the daily scheduler.

### Child tables

- `finance_books`: `Asset Finance Book` (see card below).

---

## Depreciation engine module (asset/depreciation.py)

- **Path:** [erpnext/assets/doctype/asset/depreciation.py](../../erpnext/assets/doctype/asset/depreciation.py)
- **Not a DocType.** This module hosts the daily scheduler, JE posting, and disposal GL composition.

### Public functions (called from elsewhere)

| Function | Source | Used by |
|---|---|---|
| `post_depreciation_entries(date=None)` | [depreciation.py:37](../../erpnext/assets/doctype/asset/depreciation.py:37) | `daily_maintenance` scheduler ([hooks.py:491](../../erpnext/hooks.py:491)). |
| `make_depreciation_entry(...)` | [depreciation.py:166](../../erpnext/assets/doctype/asset/depreciation.py:166) | `book_depreciation_entries`, `make_depreciation_entry_on_disposal`. Whitelisted. |
| `scrap_asset(asset_name, scrap_date=None)` | [depreciation.py:362](../../erpnext/assets/doctype/asset/depreciation.py:362) | UI button on Asset form. Whitelisted. |
| `restore_asset(asset_name)` | [depreciation.py:451](../../erpnext/assets/doctype/asset/depreciation.py:451) | Inverse of `scrap_asset`. Whitelisted. |
| `depreciate_asset(asset_doc, date, notes)` | [depreciation.py:475](../../erpnext/assets/doctype/asset/depreciation.py:475) | Asset Capitalization ([asset_capitalization.py:481](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:481)) and SI disposal ([sales_invoice.py:1467](../../erpnext/accounts/doctype/sales_invoice/sales_invoice.py:1467)). |
| `cancel_depreciation_entries(asset_doc, date)` | [depreciation.py:489](../../erpnext/assets/doctype/asset/depreciation.py:489) | `@erpnext.allow_regional` open slot — see [docs/modules/assets.md#regional-overrides](assets.md#regional-overrides). |
| `reverse_depreciation_entry_made_on_disposal(asset)` | [depreciation.py:502](../../erpnext/assets/doctype/asset/depreciation.py:502) | Used by SI cancel/restore and Asset Capitalization cancel. |
| `get_gl_entries_on_asset_disposal(...)` | [depreciation.py:633](../../erpnext/assets/doctype/asset/depreciation.py:633) | Builds disposal GL: Cr Fixed Asset / Dr Accumulated Depreciation / +/- Disposal Gain-Loss. |
| `get_gl_entries_on_asset_regain(...)` | [depreciation.py:580](../../erpnext/assets/doctype/asset/depreciation.py:580) | Inverse of disposal: Dr Fixed Asset / Cr Accumulated Depreciation. |
| `get_disposal_account_and_cost_center(company)` | [depreciation.py:778](../../erpnext/assets/doctype/asset/depreciation.py:778) | Used by SI `make_sales_invoice` and disposal GL builders. Whitelisted. |
| `get_value_after_depreciation_on_disposal_date(asset, disposal_date, finance_book=None)` | [depreciation.py:792](../../erpnext/assets/doctype/asset/depreciation.py:792) | Used by Asset Capitalization to compute the target asset value at disposal. Whitelisted. |
| `get_depreciation_accounts(asset_category, company)` | [depreciation.py:711-754](../../erpnext/assets/doctype/asset/depreciation.py:711) | Resolves Fixed Asset / Accumulated Depreciation / Depreciation Expense accounts. |

---

## Asset Depreciation Schedule

- **Path:** [erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py)
- **Controller:** `AssetDepreciationSchedule(DepreciationScheduleController)` ([asset_depreciation_schedule.py:18](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:18))
- **Submittable:** Yes (`Draft` → `Active` → `Cancelled`)
- **Naming series:** `ACC-ADS-.YYYY.-`
- **One submittable schedule per (asset, finance_book)** — enforced by `validate_another_asset_depr_schedule_does_not_exist` ([asset_depreciation_schedule.py:59-85](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:59)).

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_depreciation_schedule.py:53-57](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:53) | Uniqueness guard; on first save calls `create_depreciation_schedule()` (inherited); reapplies shift schedule if `shift_based`. |
| `on_submit` | [asset_depreciation_schedule.py:87-89](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:87) | Validates parent asset is depreciable + submitted; flips status to `Active`. |
| `on_cancel` | [asset_depreciation_schedule.py:106-109](../../erpnext/assets/doctype/asset_depreciation_schedule/asset_depreciation_schedule.py:106) | Flips status to `Cancelled`; unless `flags.should_not_cancel_depreciation_entries` is set, cancels every linked JE. |

### Key fields

- `asset` (Link → Asset, mandatory).
- `finance_book` (Link → Finance Book).
- `depreciation_method` ∈ `Straight Line`, `Double Declining Balance`, `Written Down Value`, `Manual`.
- `total_number_of_depreciations`, `frequency_of_depreciation`, `expected_value_after_useful_life`, `rate_of_depreciation`.
- `daily_prorata_based`, `shift_based` — enable sub-modes inside Straight Line.
- `depreciation_schedule` (Table → Depreciation Schedule).

### DepreciationScheduleController (mixin behaviour)

- **Path:** [erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py)
- Inherits `StraightLineMethod` + `WDVMethod` ([deppreciation_schedule_controller.py:24](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:24)).
- `create_depreciation_schedule(fb_row, disposal_date)` ([deppreciation_schedule_controller.py:28](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:28)) — entry point that recomputes the rows.
- Module-level helpers: `make_draft_asset_depr_schedule`, `convert_draft_asset_depr_schedules_into_active`, `cancel_asset_depr_schedules`, `reschedule_depreciation`, `set_modified_depreciation_rate`, `get_temp_depr_schedule_doc`, `get_asset_shift_factors_map`, `get_depr_schedule`, `get_asset_depr_schedule_doc`, `get_asset_depr_schedule_name`.

### Depreciation method mixins

- **Path:** [erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py)
- `StraightLineMethod.get_straight_line_depr_amount` ([depreciation_methods.py:16-31](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:16)) — dispatch to fixed / daily-prorata / shift sub-modes.
- `StraightLineMethod.get_shift_depr_amount` ([depreciation_methods.py:47-70](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:47)) — `(depreciable_value / sum_remaining_shift_factors) * row_factor`.
- `WDVMethod.get_wdv_or_dd_depr_amount` ([depreciation_methods.py:77-79](../../erpnext/assets/doctype/asset_depreciation_schedule/depreciation_methods.py:77)) — decorated `@erpnext.allow_regional`. Default delegates to `WDVMethod.calculate_wdv_or_dd_based_depreciation_amount` (rest of the file).

---

## Depreciation Schedule (child table)

- **Path:** [erpnext/assets/doctype/depreciation_schedule/depreciation_schedule.py](../../erpnext/assets/doctype/depreciation_schedule/depreciation_schedule.py)
- **Controller:** `DepreciationSchedule(Document)` — empty class.
- **Child of:** `Asset Depreciation Schedule` (`depreciation_schedule` field) and `Asset Shift Allocation`.
- **Key fields:** `schedule_date`, `depreciation_amount`, `accumulated_depreciation_amount`, `journal_entry` (Link → Journal Entry — set by `make_depreciation_entry`), `shift` (Link → Asset Shift Factor).

The presence/absence of `journal_entry` on a row is the gate the daily scheduler uses to decide whether to post.

---

## Asset Capitalization

- **Path:** [erpnext/assets/doctype/asset_capitalization/asset_capitalization.py](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py)
- **Controller:** `AssetCapitalization(StockController)` ([asset_capitalization.py:47](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:47))
- **Submittable:** Yes
- **Naming series:** `ACC-ASC-.YYYY.-`

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_capitalization.py:90-101](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:90) | Posting time, target item / target asset checks, consumed stock / asset / service validation, warehouse details, asset values, totals. |
| `on_update` | [asset_capitalization.py:103-105](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:103) | Builds Serial and Batch Bundles for stock items. |
| `before_submit` | [asset_capitalization.py:107-109](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:107) | Asserts at least one consumed source (stock / asset / service) is present. |
| `on_submit` | [asset_capitalization.py:111-116](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:111) | `update_stock_ledger`, `make_gl_entries`, `repost_future_sle_and_gle`, `update_target_asset` (bumps target Asset values). |
| `on_cancel` | [asset_capitalization.py:118-131](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:118) | Reverses SLE + GL, restores consumed asset items via `restore_consumed_asset_items` (re-rebuilds their depreciation schedule). |

### GL entry points

- `make_gl_entries(gl_entries=None, from_repost=False)` ([asset_capitalization.py:384-394](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:384)) — calls core `make_gl_entries`. On cancel, `make_reverse_gl_entries(voucher_type=self.doctype, voucher_no=self.name)`.
- `get_gl_entries(...)` ([asset_capitalization.py:396-422](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:396)) composes:
  - `get_gl_entries_for_consumed_stock_items` ([asset_capitalization.py:438-466](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:438)) — Cr stock account / against target asset (or default expense in periodic mode).
  - `get_gl_entries_for_consumed_asset_items` ([asset_capitalization.py:468-499](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:468)) — for each consumed asset: depreciate to disposal date, then call `get_gl_entries_on_asset_disposal`.
  - `get_gl_entries_for_consumed_service_items` ([asset_capitalization.py:501-521](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:501)) — Cr service-expense account.
  - `get_gl_entries_for_target_item` ([asset_capitalization.py:531-548](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:531)) — Dr target Fixed Asset (or CWIP if `enable_cwip_accounting` for the target category) for the total minus composite-component value.

### SLE entry points

- `update_stock_ledger()` ([asset_capitalization.py:367-382](../../erpnext/assets/doctype/asset_capitalization/asset_capitalization.py:367)) — emits Outward SLE per consumed stock item (`-actual_qty`), with `serial_and_batch_bundle` reference. SLE list is reversed on cancel.

### Key fields

- `target_item_code` (Link → Item), `target_asset` (Link → Asset; Composite Asset).
- `target_fixed_asset_account` (Link → Account).
- `stock_items` / `asset_items` / `service_items` (Tables — see child cards below).
- `total_value`, `target_incoming_rate`.

### Child tables

- `Asset Capitalization Stock Item` — [asset_capitalization_stock_item.py](../../erpnext/assets/doctype/asset_capitalization_stock_item/asset_capitalization_stock_item.py); fields include `item_code`, `warehouse`, `stock_qty`, `valuation_rate`, `serial_and_batch_bundle`.
- `Asset Capitalization Asset Item` — [asset_capitalization_asset_item.py](../../erpnext/assets/doctype/asset_capitalization_asset_item/asset_capitalization_asset_item.py); fields include `asset`, `current_asset_value`, `asset_value`, `finance_book`.
- `Asset Capitalization Service Item` — [asset_capitalization_service_item.py](../../erpnext/assets/doctype/asset_capitalization_service_item/asset_capitalization_service_item.py); fields include `item_code`, `qty`, `rate`, `expense_account`, `cost_center`.

---

## Asset Repair

- **Path:** [erpnext/assets/doctype/asset_repair/asset_repair.py](../../erpnext/assets/doctype/asset_repair/asset_repair.py)
- **Controller:** `AssetRepair(AccountsController)` ([asset_repair.py:23](../../erpnext/assets/doctype/asset_repair/asset_repair.py:23))
- **Submittable:** Yes
- **Naming series:** `ACC-ASR-.YYYY.-`
- **Status set:** Pending, Completed, Cancelled.

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_repair.py:61-70](../../erpnext/assets/doctype/asset_repair/asset_repair.py:61) | Ensures asset is not Sold/Fully Depreciated/Scrapped, dates ordered, linked PIs valid, recomputes consumed-items cost, repair cost, total cost. |
| `on_submit` | [asset_repair.py:199-210](../../erpnext/assets/doctype/asset_repair/asset_repair.py:199) | Issues consumed stock through a child Stock Entry (Material Issue). If `capitalize_repair_cost=1`: bumps Asset value, sets `increase_in_asset_life`, reschedules depreciation, posts GL. |
| `on_cancel` | [asset_repair.py:219-230](../../erpnext/assets/doctype/asset_repair/asset_repair.py:219) | Inverse: drops `increase_in_asset_life`, reverses asset value bump, posts reverse GL, reschedules, cancels the Serial and Batch Bundles. |
| `after_delete` | [asset_repair.py:232-233](../../erpnext/assets/doctype/asset_repair/asset_repair.py:232) | Recomputes Asset status. |

### GL entry points

- `make_gl_entries(cancel=False)` ([asset_repair.py:309-315](../../erpnext/assets/doctype/asset_repair/asset_repair.py:309)) — invoked only when `total_repair_cost > 0` and `capitalize_repair_cost=1`.
- `get_gl_entries()` ([asset_repair.py:317-324](../../erpnext/assets/doctype/asset_repair/asset_repair.py:317)) composes:
  - `get_gl_entries_for_repair_cost` ([asset_repair.py:326-368](../../erpnext/assets/doctype/asset_repair/asset_repair.py:326)) — for each linked PI row: Cr `expense_account` / Dr Fixed Asset (with `against_voucher_type='Asset'`).
  - `get_gl_entries_for_consumed_items` ([asset_repair.py:370-424](../../erpnext/assets/doctype/asset_repair/asset_repair.py:370)) — reads back the child Stock Entry and posts: Cr stock-expense account / Dr Fixed Asset, with `against_voucher_type='Stock Entry'`.

### SLE entry points

- Indirectly: `decrease_stock_quantity()` ([asset_repair.py:255-290](../../erpnext/assets/doctype/asset_repair/asset_repair.py:255)) creates and submits a **separate** Stock Entry (purpose `Material Issue`, `asset_repair=<name>`) — that Stock Entry produces the SLE rows.

### Whitelisted endpoints

- `get_downtime(failure_date, completion_date)` ([asset_repair.py:451-453](../../erpnext/assets/doctype/asset_repair/asset_repair.py:451)).
- `get_purchase_invoice(...)` and `get_expense_accounts(...)` ([asset_repair.py:457-518](../../erpnext/assets/doctype/asset_repair/asset_repair.py:457)) — link-field queries that surface only PIs/accounts with eligible non-stock items.
- `get_unallocated_repair_cost(purchase_invoice, expense_account, exclude_asset_repair=None)` ([asset_repair.py:562-577](../../erpnext/assets/doctype/asset_repair/asset_repair.py:562)).

### Key fields

- `asset` (Link → Asset, mandatory), `failure_date`, `completion_date`, `repair_status`.
- `capitalize_repair_cost` (Check) — gates the GL + asset-value-bump branch.
- `increase_in_asset_life` (Int, months) — extends finance-book life on capitalisation.
- `stock_items` (Table → Asset Repair Consumed Item), `invoices` (Table → Asset Repair Purchase Invoice).

### Child tables

- `Asset Repair Consumed Item` — [asset_repair_consumed_item.py](../../erpnext/assets/doctype/asset_repair_consumed_item/asset_repair_consumed_item.py); fields include `item_code`, `warehouse`, `consumed_quantity`, `valuation_rate`, `total_value`, `serial_and_batch_bundle`.
- `Asset Repair Purchase Invoice` — [asset_repair_purchase_invoice.py](../../erpnext/assets/doctype/asset_repair_purchase_invoice/asset_repair_purchase_invoice.py); fields include `purchase_invoice` (Link), `expense_account` (Link), `repair_cost`. Used to slice Purchase Invoice service-cost lines into the repair voucher.

---

## Asset Movement

- **Path:** [erpnext/assets/doctype/asset_movement/asset_movement.py](../../erpnext/assets/doctype/asset_movement/asset_movement.py)
- **Controller:** `AssetMovement(Document)` ([asset_movement.py:13](../../erpnext/assets/doctype/asset_movement/asset_movement.py:13))
- **Submittable:** Yes
- **Posts GL/SLE:** No — pure metadata move.

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_movement.py:33-37](../../erpnext/assets/doctype/asset_movement/asset_movement.py:33) | Per row: validates asset belongs to company, validates source/target location and employee per `purpose`, validates monotonic transaction date. |
| `on_submit` | [asset_movement.py:116-117](../../erpnext/assets/doctype/asset_movement/asset_movement.py:116) | Recomputes `Asset.location` and `Asset.custodian` from latest movement. |
| `on_cancel` | [asset_movement.py:119-120](../../erpnext/assets/doctype/asset_movement/asset_movement.py:119) | Same — replays from previous movement after cancellation. |

### Key fields

- `purpose` ∈ `Issue`, `Receipt`, `Transfer`, `Transfer and Issue`.
- `transaction_date` (Datetime) — rejected if before the previous movement for an asset.
- `reference_doctype` / `reference_name` — link back to PR / PI / etc.
- `assets` (Table → Asset Movement Item).

### Child tables

- `Asset Movement Item` — [asset_movement_item.py](../../erpnext/assets/doctype/asset_movement_item/asset_movement_item.py); fields include `asset`, `asset_name`, `source_location`, `target_location`, `from_employee`, `to_employee`, `company`. Member of `accounting_dimension_doctypes` ([hooks.py:587](../../erpnext/hooks.py:587)).

---

## Asset Value Adjustment

- **Path:** [erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py)
- **Controller:** `AssetValueAdjustment(Document)` ([asset_value_adjustment.py:21](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:21))
- **Submittable:** Yes

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_value_adjustment.py:44-47](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:44) | Date is on/after asset purchase; `current_asset_value` defaults from `get_asset_value_after_depreciation`; computes `difference_amount = new_asset_value - current_asset_value`. |
| `on_submit` | [asset_value_adjustment.py:66-74](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:66) | Posts the revaluation Journal Entry (direct submit, **does not** go through `make_gl_entries`); updates Asset value + reschedules depreciation. |
| `on_cancel` | [asset_value_adjustment.py:76-84](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:76) | Cancels the linked Journal Entry; recomputes Asset value (sign flipped); reschedules. |

### GL entry points

- `make_asset_revaluation_entry()` ([asset_value_adjustment.py:86-129](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:86)) — builds and submits a Journal Entry (`voucher_type='Journal Entry'`, naming series from `Company.series_for_depreciation_entry`):
  - **Increase:** Dr Fixed Asset / Cr `difference_account`.
  - **Decrease:** Cr Fixed Asset / Dr `difference_account`.
- The JE sets `reference_type='Asset'`, `reference_name=<asset>` on both rows. Accounting dimensions are mirrored from the adjustment ([asset_value_adjustment.py:159-168](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:159)).

### Key fields

- `asset` (Link → Asset, mandatory).
- `finance_book` (Link → Finance Book) — only the matching finance-book row in Asset is updated.
- `current_asset_value` / `new_asset_value` / `difference_amount`.
- `difference_account` (Link → Account) — counter-account (gain/loss).
- `journal_entry` (Link → Journal Entry, set on submit).

### Whitelisted endpoint

- `get_value_of_accounting_dimensions(asset_name)` ([asset_value_adjustment.py:229-232](../../erpnext/assets/doctype/asset_value_adjustment/asset_value_adjustment.py:229)).

---

## Asset Shift Allocation

- **Path:** [erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py)
- **Controller:** `AssetShiftAllocation(Document)` ([asset_shift_allocation.py:23](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:23))
- **Submittable:** Yes
- **Naming series:** `ACC-ASA-.YYYY.-`

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_shift_allocation.py:41-45](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:41) | Loads active schedule; rejects shift changes on rows already booked; recomputes the schedule via `update_depr_schedule`. |
| `after_insert` | [asset_shift_allocation.py:47-48](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:47) | Mirrors the active schedule into the form so the user can edit shifts. |
| `on_submit` | [asset_shift_allocation.py:50-51](../../erpnext/assets/doctype/asset_shift_allocation/asset_shift_allocation.py:50) | Cancels the active `Asset Depreciation Schedule` (preserving JEs via `should_not_cancel_depreciation_entries`) and submits the rebuilt copy. |

### Key fields

- `asset` (Link → Asset, mandatory).
- `finance_book` (Link → Finance Book).
- `depreciation_schedule` (Table → Depreciation Schedule) — editable shifts.

### Helpers

- `get_asset_shift_factors_map()` ([deppreciation_schedule_controller.py:269-270](../../erpnext/assets/doctype/asset_depreciation_schedule/deppreciation_schedule_controller.py:269)) — `dict(shift_name → shift_factor)`.

---

## Asset Maintenance

- **Path:** [erpnext/assets/doctype/asset_maintenance/asset_maintenance.py](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py)
- **Controller:** `AssetMaintenance(Document)` ([asset_maintenance.py:14](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:14))
- **Submittable:** No (not a submittable DocType).
- **Posts GL/SLE:** No.

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_maintenance.py:36-43](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:36) | Enforces start_date < end_date per task; flips overdue tasks to `Overdue`; requires `assign_to`. |
| `on_update` | [asset_maintenance.py:45-48](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:45) | Pushes per-task ToDos; calls `sync_maintenance_tasks` which (de-)materialises `Asset Maintenance Log` rows. |
| `after_delete` | [asset_maintenance.py:50-53](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:50) | Recomputes Asset status if it was `In Maintenance`. |

### Whitelisted endpoints

- `calculate_next_due_date(periodicity, start_date=None, end_date=None, last_completion_date=None, next_due_date=None)` ([asset_maintenance.py:93-128](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:93)).
- `get_team_members(...)` ([asset_maintenance.py:171-185](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:171)).
- `get_maintenance_log(asset_name)` ([asset_maintenance.py:188-199](../../erpnext/assets/doctype/asset_maintenance/asset_maintenance.py:188)).

### Key fields

- `asset_name` (Link → Asset, mandatory).
- `maintenance_team` (Link → Asset Maintenance Team).
- `asset_maintenance_tasks` (Table → Asset Maintenance Task).

### Child tables

- `Asset Maintenance Task` — [asset_maintenance_task.py](../../erpnext/assets/doctype/asset_maintenance_task/asset_maintenance_task.py); fields include `maintenance_task`, `start_date`, `end_date`, `next_due_date`, `last_completion_date`, `periodicity`, `maintenance_type`, `maintenance_status`, `assign_to`, `assign_to_name`, `certificate_required`.

---

## Asset Maintenance Log

- **Path:** [erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py)
- **Controller:** `AssetMaintenanceLog(Document)` ([asset_maintenance_log.py:14](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:14))
- **Submittable:** Yes
- **Naming series:** `ACC-AML-.YYYY.-`

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_maintenance_log.py:44-55](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:44) | Past-due → `Overdue`; require completion date for `Completed`; reject completion date if status is not Completed. |
| `on_submit` | [asset_maintenance_log.py:57-60](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:57) | Allowed only when status is `Completed` or `Cancelled`. Calls `update_maintenance_task` to advance `next_due_date` on the parent task. |

### Module functions

- `update_asset_maintenance_log_status()` ([asset_maintenance_log.py:80-88](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:80)) — bulk Planned → Overdue sweep. Daily ([hooks.py:485](../../erpnext/hooks.py:485)).
- `get_maintenance_tasks(...)` ([asset_maintenance_log.py:91-97](../../erpnext/assets/doctype/asset_maintenance_log/asset_maintenance_log.py:91)).

### Key fields

- `asset_maintenance` (Link → Asset Maintenance), `asset_name`, `task` (Link → Asset Maintenance Task).
- `maintenance_status` ∈ `Planned`, `Completed`, `Cancelled`, `Overdue`.
- `due_date`, `completion_date`, `periodicity`.

---

## Asset Maintenance Team

- **Path:** [erpnext/assets/doctype/asset_maintenance_team/asset_maintenance_team.py](../../erpnext/assets/doctype/asset_maintenance_team/asset_maintenance_team.py)
- **Controller:** `Document` (lightweight master).
- **Children:** `Maintenance Team Member` (`maintenance_team_member`).

### Maintenance Team Member (child)

- **Path:** [erpnext/assets/doctype/maintenance_team_member/maintenance_team_member.py](../../erpnext/assets/doctype/maintenance_team_member/maintenance_team_member.py)
- Fields: `team_member` (Link → User), `full_name`, `maintenance_role`.

---

## Asset Category

- **Path:** [erpnext/assets/doctype/asset_category/asset_category.py](../../erpnext/assets/doctype/asset_category/asset_category.py)
- **Controller:** `AssetCategory(Document)` ([asset_category.py:11](../../erpnext/assets/doctype/asset_category/asset_category.py:11))
- **Submittable:** No (master).

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_category.py:30-34](../../erpnext/assets/doctype/asset_category/asset_category.py:30) | Validates finance-book defaults, account types and currency, no duplicate company rows, CWIP gating, depreciation accounts present where required. |

### Key fields

- `asset_category_name` (Data, mandatory).
- `enable_cwip_accounting` (Check) — when set, the Fixed Asset GL is held in CWIP until Asset submission flips it to Fixed Asset (see `make_post_gl_entry` daily job).
- `non_depreciable_category` (Check) — disables `calculate_depreciation` on assets in this category.
- `accounts` (Table → Asset Category Account) — per-company GL account mapping.
- `finance_books` (Table → Asset Finance Book) — default depreciation parameters per finance book; copied onto the Asset on creation.

### Module function

- `get_asset_category_account(fieldname, item=None, asset=None, account=None, asset_category=None, company=None)` ([asset_category.py:194-215](../../erpnext/assets/doctype/asset_category/asset_category.py:194)) — central account-lookup helper used across the module.

### Asset Category Account (child)

- **Path:** [erpnext/assets/doctype/asset_category_account/asset_category_account.py](../../erpnext/assets/doctype/asset_category_account/asset_category_account.py)
- Fields: `company_name` (Link → Company), `fixed_asset_account`, `accumulated_depreciation_account`, `depreciation_expense_account`, `capital_work_in_progress_account`. Account type validated against `Fixed Asset` / `Accumulated Depreciation` / `Depreciation` / `Capital Work in Progress` ([asset_category.py:72-98](../../erpnext/assets/doctype/asset_category/asset_category.py:72)).

---

## Asset Finance Book (child)

- **Path:** [erpnext/assets/doctype/asset_finance_book/asset_finance_book.py](../../erpnext/assets/doctype/asset_finance_book/asset_finance_book.py)
- **Controller:** `AssetFinanceBook(Document)` — empty pass-through.
- **Parent of:** Asset (`finance_books` field) and Asset Category (`finance_books` field).
- Fields: `finance_book` (Link → Finance Book), `depreciation_method`, `total_number_of_depreciations`, `frequency_of_depreciation`, `depreciation_start_date`, `expected_value_after_useful_life`, `salvage_value_percentage`, `value_after_depreciation`, `rate_of_depreciation`, `total_number_of_booked_depreciations`, `daily_prorata_based`, `shift_based`, `increase_in_asset_life`.

---

## Asset Shift Factor

- **Path:** [erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py](../../erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py)
- **Controller:** `AssetShiftFactor(Document)` ([asset_shift_factor.py:9](../../erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py:9))
- **Submittable:** No.

### Lifecycle hooks

| Hook | Method | What it does |
|---|---|---|
| `validate` | [asset_shift_factor.py:23-24](../../erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py:23) | Calls `validate_default()`. |
| (helper) `validate_default` | [asset_shift_factor.py:26-35](../../erpnext/assets/doctype/asset_shift_factor/asset_shift_factor.py:26) | Throws if another Shift Factor is already marked default — at most one default. |

### Key fields

- `shift_name` (Data, e.g. `Single`, `Double`, `Triple`), `shift_factor` (Float, the multiplier), `default` (Check).

---

## Asset Activity

- **Path:** [erpnext/assets/doctype/asset_activity/asset_activity.py](../../erpnext/assets/doctype/asset_activity/asset_activity.py)
- **Controller:** `AssetActivity(Document)` ([asset_activity.py:9](../../erpnext/assets/doctype/asset_activity/asset_activity.py:9))
- **Submittable:** No (audit log).
- **Inserts:** Always via the module function `add_asset_activity(asset, subject)` ([asset_activity.py:27-36](../../erpnext/assets/doctype/asset_activity/asset_activity.py:27)) — `ignore_permissions=True, ignore_links=True`.
- Used by Asset, Asset Repair, Asset Capitalization, Asset Value Adjustment, Asset Shift Allocation, Asset Movement, depreciation disposal/scrap/restore — every state-changing operation logs a row.
- Fields: `asset` (Link → Asset), `subject` (SmallText), `user` (Link → User), `date` (Datetime).

---

## Location

- **Path:** [erpnext/assets/doctype/location/location.py](../../erpnext/assets/doctype/location/location.py)
- **Controller:** `Location(NestedSet)` ([location.py:15](../../erpnext/assets/doctype/location/location.py:15))
- **Tree DocType:** Yes (`nsm_parent_field = 'parent_location'`).
- Stores GeoJSON in the `location` field; `calculate_location_area` ([location.py:55-60](../../erpnext/assets/doctype/location/location.py:55)) computes geodesic area on validate using `compute_area` ([location.py:146-169](../../erpnext/assets/doctype/location/location.py:146)).
- `update_ancestor_location_features` / `remove_ancestor_location_features` keep parent locations in sync with child geometry.
- Whitelisted: `get_children` ([location.py:213](../../erpnext/assets/doctype/location/location.py:213)) and `add_node` ([location.py:233](../../erpnext/assets/doctype/location/location.py:233)).

### Key fields

- `location_name` (Data, mandatory).
- `parent_location` (Link → Location).
- `is_group`, `is_container`.
- `latitude`, `longitude`, `area`, `area_uom`.
- `location` (Long Text — GeoJSON FeatureCollection).

---

## Linked Location (child)

- **Path:** [erpnext/assets/doctype/linked_location/linked_location.py](../../erpnext/assets/doctype/linked_location/linked_location.py)
- **Controller:** `LinkedLocation(Document)` — empty pass-through.
- Used as a child of Warehouse (and other DocTypes that need to reference multiple Locations).
- Field: `location` (Link → Location).

---

## Module-level metadata registries

| Registry | Asset DocType inclusion | Source |
|---|---|---|
| `period_closing_doctypes` | Asset, Asset Capitalization, Asset Repair | [hooks.py:333-335](../../erpnext/hooks.py:333) |
| `accounting_dimension_doctypes` | Asset, Asset Value Adjustment, Asset Repair, Asset Capitalization, Asset Movement Item, Asset Depreciation Schedule | [hooks.py:543, 562-564, 587-588](../../erpnext/hooks.py:543) |
| `global_search_doctypes` | Asset (index 28) | [hooks.py:664](../../erpnext/hooks.py:664) |
| `regional_overrides` | (none — see `@erpnext.allow_regional` slots in [docs/modules/assets.md](assets.md#regional-overrides)) | [hooks.py:608-621](../../erpnext/hooks.py:608) |

---

## Related

- [Assets module overview](assets.md)
- [Assets flow](../flows/assets-flow.md)
- [Accounting flow](../flows/accounting-flow.md)
- [Stock flow](../flows/stock-flow.md)
- [Buying flow](../flows/buying-flow.md) — auto-create Asset from PI / PR.
- [Selling flow](../flows/selling-flow.md) — disposal on Sales Invoice submit.

## Changelog

- `2026-04-18` — initial version (Phase 1 of Assets gap-fill).
