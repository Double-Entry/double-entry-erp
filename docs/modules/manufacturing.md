---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: manufacturing
status: complete
related_docs:
  - ./manufacturing-doctypes.md
  - ../flows/manufacturing-flow.md
  - ./stock.md
  - ./stock-doctypes.md
  - ../flows/stock-flow.md
  - ../flows/accounting-flow.md
  - ../flows/selling-flow.md
  - ../flows/buying-flow.md
  - ../flows/subcontracting-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
---

# Manufacturing module

> **TL;DR:** The Manufacturing module (`erpnext/manufacturing/`) owns the master data (`BOM`, `Routing`, `Operation`, `Workstation`, `Workstation Type`), the planning layer (`Production Plan`, `Master Production Schedule`), the execution trackers (`Work Order`, `Job Card`), and the Manufacturing Settings Single. **None of its transaction DocTypes inherit from `AccountsController` / `StockController`** — they sit directly on `Document`. The actual SLE / GL effect of production happens through `Stock Entry` (living in the Stock module) using the manufacturing purposes `Material Transfer for Manufacture`, `Manufacture`, `Material Consumption for Manufacture`, `Disassemble`. The module publishes `BOM` as a website-generator page at `/boms/`, registers two scheduler jobs around BOM cost propagation, and has no regional overrides.

## Scope of this document

- **Covered here:** module layout, controller posture (no custom controller), master / planning / execution DocType families, Manufacturing Settings knobs, scheduler jobs, hooks.py touchpoints, reports, workspace, regional overrides (none).
- **Covered by [manufacturing-doctypes.md](./manufacturing-doctypes.md):** per-DocType reference cards for BOM + children, Routing, Operation, Workstation / Workstation Type, Production Plan + children, Work Order + children, Job Card + children, Downtime Entry, Manufacturing Settings, BOM Update Log / Tool / Batch, BOM Creator.
- **Covered by [flows/manufacturing-flow.md](../flows/manufacturing-flow.md):** end-to-end Production Plan → Work Order → Job Card → Stock Entry cascade, Mermaid sequence diagrams, sub-assembly explosion, subcontract branch, disassemble, Work Order close/stop, BOM cost update scheduler.

## Key files

- [erpnext/manufacturing/](../../erpnext/manufacturing/) — module root. `modules.txt` entry: `Manufacturing` ([erpnext/modules.txt:7](../../erpnext/modules.txt:7)).
- [erpnext/manufacturing/doctype/bom/bom.py](../../erpnext/manufacturing/doctype/bom/bom.py:105) — `BOM(WebsiteGenerator)`, 2001 lines. Cost roll-up, tree explosion, parent propagation.
- [erpnext/manufacturing/doctype/production_plan/production_plan.py](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39) — `ProductionPlan(Document)`, 2275 lines. Demand aggregation, sub-assembly explosion, downstream creation (WO / MR / PO).
- [erpnext/manufacturing/doctype/work_order/work_order.py](../../erpnext/manufacturing/doctype/work_order/work_order.py:69) — `WorkOrder(Document)`, 2880 lines. Per-FG execution tracker, operations, job card creation, stock-entry creation, status lifecycle.
- [erpnext/manufacturing/doctype/job_card/job_card.py](../../erpnext/manufacturing/doctype/job_card/job_card.py:61) — `JobCard(Document)`, 1804 lines. Shop-floor per-operation record, time logs, transfer / complete writeback.
- [erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:26) — `BOMUpdateLog(Document)`. Bulk BOM Replace + level-wise Update Cost orchestrator.
- [erpnext/manufacturing/doctype/bom_update_log/bom_updation_utils.py](../../erpnext/manufacturing/doctype/bom_update_log/bom_updation_utils.py) — `get_leaf_boms`, `get_next_higher_level_boms`, `replace_bom`, `update_cost_in_level`, `set_values_in_log`, `handle_exception`.
- [erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:15) — `BOMUpdateTool(Document)` and its whitelisted entry points `enqueue_replace_bom`, `enqueue_update_cost`, `auto_update_latest_price_in_all_boms`, `create_bom_update_log`.
- [erpnext/manufacturing/doctype/bom_creator/bom_creator.py](../../erpnext/manufacturing/doctype/bom_creator/bom_creator.py:37) — `BOMCreator(Document)`. Hierarchical draft of many BOMs (multi-level item tree), creates submittable `BOM` rows once finalized.
- [erpnext/manufacturing/doctype/routing/routing.py](../../erpnext/manufacturing/doctype/routing/routing.py:11) — reusable operation sequence master.
- [erpnext/manufacturing/doctype/operation/operation.py](../../erpnext/manufacturing/doctype/operation/operation.py:10) — operation master; `batch_size` + `create_job_card_based_on_batch_size` drive Job Card splitting.
- [erpnext/manufacturing/doctype/workstation/workstation.py](../../erpnext/manufacturing/doctype/workstation/workstation.py:39) — physical workstation; `hour_rate`, `working_hours`, `holiday_list`, `production_capacity`.
- [erpnext/manufacturing/doctype/workstation_type/workstation_type.py](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:10) — abstraction for fungible workstations.
- [erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:11) — Single DocType; governs backflush mode, overproduction tolerance, capacity planning, auto BOM cost update.
- [erpnext/manufacturing/doctype/downtime_entry/downtime_entry.py](../../erpnext/manufacturing/doctype/downtime_entry/downtime_entry.py:9) — standalone downtime log for OEE reporting.
- [erpnext/manufacturing/doctype/plant_floor/plant_floor.py](../../erpnext/manufacturing/doctype/plant_floor/plant_floor.py:10) — logical grouping of workstations.
- [erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:12) — MPS driver (Single-ish companion to forecasts).
- [erpnext/manufacturing/doctype/sales_forecast/sales_forecast.py](../../erpnext/manufacturing/doctype/sales_forecast/sales_forecast.py:10) — historical + projected demand, feeds MPS.
- [erpnext/manufacturing/doctype/blanket_order/blanket_order.py](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:15) — umbrella Selling/Purchasing quantity frame. Lives in the manufacturing module historically, used by both selling and buying flows (`Blanket Order Type: "Selling" | "Purchasing"`); cross-linked from [modules/selling-doctypes.md](./selling-doctypes.md) and [modules/buying-doctypes.md](./buying-doctypes.md).

## Directory layout

```
erpnext/manufacturing/
├── __init__.py
├── README.md
├── dashboard_chart/                     — dashboard widgets
├── dashboard_fixtures.py                — default dashboards bootstrap
├── doctype/                             — DocType folder (see manufacturing-doctypes.md for full table)
│   ├── bom/                             — BOM (+ dashboard, list, tree, item_preview template)
│   ├── bom_creator/                     — hierarchical BOM builder
│   ├── bom_creator_item/                — child
│   ├── bom_explosion_item/              — child; flattened tree
│   ├── bom_item/                        — child; direct RMs
│   ├── bom_operation/                   — child; operation row on BOM / Routing
│   ├── bom_secondary_item/              — child; co-products / by-products
│   ├── bom_update_batch/                — child of BOM Update Log
│   ├── bom_update_log/                  — bulk BOM Replace / Update Cost orchestrator
│   ├── bom_update_tool/                 — action stub; emits BOM Update Log
│   ├── bom_website_item/                — child used for BOM website page
│   ├── bom_website_operation/           — child used for BOM website page
│   ├── downtime_entry/                  — workstation downtime log
│   ├── job_card/                        — shop-floor operation record
│   ├── job_card_item/                   — child; required materials
│   ├── job_card_operation/              — child; sub-operation status
│   ├── job_card_scheduled_time/         — child; planned slot
│   ├── job_card_secondary_item/         — child; secondary FG
│   ├── job_card_time_log/               — child; one row per Start/Pause
│   ├── manufacturing_settings/          — Single
│   ├── master_production_schedule/
│   ├── master_production_schedule_item/ — child
│   ├── material_request_plan_item/      — child of Production Plan
│   ├── operation/                       — operation master
│   ├── plant_floor/                     — workstation grouping
│   ├── production_plan/
│   ├── production_plan_item/            — child; main FG demand
│   ├── production_plan_item_reference/  — child; cross-links SOs when combining
│   ├── production_plan_material_request/— child; MR creation staging
│   ├── production_plan_material_request_warehouse/ — child; warehouse fan-out
│   ├── production_plan_sales_order/     — child; linked SOs
│   ├── production_plan_sub_assembly_item/ — child; exploded sub-assemblies
│   ├── routing/                         — operation sequence master
│   ├── sales_forecast/                  — feeds MPS
│   ├── sales_forecast_item/             — child
│   ├── sub_operation/                   — child of Operation
│   ├── work_order/
│   ├── work_order_item/                 — child; required items (from BOM)
│   ├── work_order_operation/            — child; operations (from BOM / Routing)
│   ├── workstation/
│   ├── workstation_cost/                — child; operating-component cost row
│   ├── workstation_operating_component/ — child; component definition
│   ├── workstation_operating_component_account/ — child; GL account per component
│   ├── workstation_type/
│   └── workstation_working_hour/        — child; working-hours row
│   └── blanket_order/                   — cross-module (selling + buying reference)
│   └── blanket_order_item/              — child
├── manufacturing_dashboard/             — dashboard definition
├── module_onboarding/                   — onboarding bundle
├── notification/                        — default email notifications
├── number_card/                         — KPI cards (WO status, etc.)
├── onboarding_step/                     — onboarding steps
├── page/                                — legacy pages (none transactional)
├── report/                              — reports (list below)
└── workspace/                           — workspace definition
```

## Controller posture

The manufacturing module **does not own a transaction controller**. The four lifecycle DocTypes — `BOM`, `Production Plan`, `Work Order`, `Job Card` — all inherit directly from `Document`:

- [BOM](../../erpnext/manufacturing/doctype/bom/bom.py:105) extends `frappe.website.website_generator.WebsiteGenerator`.
- [ProductionPlan](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39) extends `Document`.
- [WorkOrder](../../erpnext/manufacturing/doctype/work_order/work_order.py:69) extends `Document`.
- [JobCard](../../erpnext/manufacturing/doctype/job_card/job_card.py:61) extends `Document`.

None of these hit `AccountsController` / `StockController`. Consequences:

- **No `status_updater[]` contract.** Qty writeback between documents uses direct `frappe.db.set_value` / `db_set` calls. Production Plan writeback to Sales Order uses a hand-rolled `update_sales_order` ([:630](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:630)). Work Order writeback on `on_close_or_cancel` uses `update_work_order_qty_in_so` ([:1185](../../erpnext/manufacturing/doctype/work_order/work_order.py:1185)).
- **No `make_gl_entries` / `make_sl_entries`.** The GL / SLE effect of production lives on `Stock Entry` (which **does** extend `StockController`). See [modules/stock-doctypes.md#stock-entry](./stock-doctypes.md) for the Stock Entry reference card.
- **No tax / payment-schedule machinery** (none of that applies to WO/JC).
- **Inversion of writeback.** Stock Entry calls `WorkOrder.update_work_order_qty` on submit; Job Card calls `WorkOrder.update_work_order_data` → `update_operation_status` → `calculate_operating_cost`. Work Order reads the state, it never pushes.

See [architecture/controllers.md](../architecture/controllers.md) for the full controller hierarchy (manufacturing is a sibling branch, not a participant).

## Master data: BOM, Routing, Operation, Workstation

### BOM family

| DocType | Role | File |
|---|---|---|
| `BOM` | Recipe for an FG: items, operations, exploded items, costs. Submittable. WebsiteGenerator (`/boms/<name>`). | [bom.py:105](../../erpnext/manufacturing/doctype/bom/bom.py:105) |
| `BOM Item` | Direct raw material row; may point to a child `bom_no` making it multi-level. | [bom_item](../../erpnext/manufacturing/doctype/bom_item/) |
| `BOM Explosion Item` | Flattened RM tree; rebuilt on every validate via `BOMTree`. | [bom_explosion_item](../../erpnext/manufacturing/doctype/bom_explosion_item/) |
| `BOM Operation` | Operation row on a BOM (workstation, time, cost). Also used by Routing. | [bom_operation](../../erpnext/manufacturing/doctype/bom_operation/) |
| `BOM Secondary Item` | Co-product / by-product with `cost_allocation_per`. | [bom_secondary_item](../../erpnext/manufacturing/doctype/bom_secondary_item/) |
| `BOM Website Item / Operation` | Read-only projections for the `/boms/<name>` page. | [bom_website_item](../../erpnext/manufacturing/doctype/bom_website_item/) |
| `BOM Update Log` | Bulk Replace + level-wise Update Cost orchestration. Submittable. | [bom_update_log.py:26](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:26) |
| `BOM Update Batch` | Child of Log; one row per slice of 7000 BOMs. | [bom_update_batch](../../erpnext/manufacturing/doctype/bom_update_batch/) |
| `BOM Update Tool` | Thin whitelisted entry-point shim that creates Logs. | [bom_update_tool.py:15](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:15) |
| `BOM Creator` | Hierarchical draft builder that emits multiple BOMs. | [bom_creator.py:37](../../erpnext/manufacturing/doctype/bom_creator/bom_creator.py:37) |

BOM cost flow: `validate` → `calculate_cost` → `update_exploded_items` → `update_cost(from_child_bom=True)`. Persistent recursion through parent BOMs only happens inside `update_cost(update_parent=True, from_child_bom=False)`, which the UI `Update Cost` button and `BOM Update Log (Update Cost)` both invoke. See [flows/manufacturing-flow.md#bom-cost-update-scheduler](../flows/manufacturing-flow.md) for the level-wise queue.

### Routing / Operation / Workstation

- `Routing` at [routing.py:11](../../erpnext/manufacturing/doctype/routing/routing.py:11) — list of `BOM Operation` rows reusable across BOMs. Enforces `sequence_id` monotonicity.
- `Operation` at [operation.py:10](../../erpnext/manufacturing/doctype/operation/operation.py:10) — master with `batch_size` + `create_job_card_based_on_batch_size` controlling JC split. Owns `Sub Operation` child table.
- `Workstation` at [workstation.py:39](../../erpnext/manufacturing/doctype/workstation/workstation.py:39) — physical resource. Owns `Workstation Cost` (per-component cost) and `Workstation Working Hour` child tables. `hour_rate` is computed from `workstation_costs.sum(operating_cost)` via `set_hour_rate` at [:87](../../erpnext/manufacturing/doctype/workstation/workstation.py:87).
- `Workstation Type` at [workstation_type.py:10](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:10) — fungible-workstation abstraction; `get_workstations` at [:53](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:53).

## Planning: Production Plan, Master Production Schedule, Sales Forecast

- `Production Plan` at [production_plan.py:39](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39) — the single-tenant workhorse of bottom-up planning. Takes SO / MR / direct input; explodes BOM trees into `sub_assembly_items`; fans out into Work Orders, Purchase Orders (for subcontract sub-assemblies), and Material Requests. See [flows/manufacturing-flow.md](../flows/manufacturing-flow.md) for the complete flow.
- `Master Production Schedule` at [master_production_schedule.py:12](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:12) — MPS driver. Combines Sales Forecasts with actuals; currently a lightweight aggregator that feeds figures into downstream Production Plan (no auto-push).
- `Sales Forecast` at [sales_forecast.py:10](../../erpnext/manufacturing/doctype/sales_forecast/sales_forecast.py:10) — historical-plus-projected demand per item. Used by MPS and as a data source for planning reports.

## Execution: Work Order, Job Card

- `Work Order` at [work_order.py:69](../../erpnext/manufacturing/doctype/work_order/work_order.py:69) — the authoritative per-FG production doc. Tracks `required_items` (from BOM) + `operations` (from BOM / Routing). Passes `qty` through three stages: `material_transferred_for_manufacturing` → `produced_qty`. Raises `Manufacture` SEs via module-level `make_stock_entry` at [:2387](../../erpnext/manufacturing/doctype/work_order/work_order.py:2387). Spawns Job Cards via `create_job_card` at [:1016](../../erpnext/manufacturing/doctype/work_order/work_order.py:1016).
- `Job Card` at [job_card.py:61](../../erpnext/manufacturing/doctype/job_card/job_card.py:61) — per-(operation × batch_size) shop-floor record. Tracks time logs, employees, transferred RM qty, completed qty. Writes back to `Work Order Operation` row on submit.

## Settings (Single)

`Manufacturing Settings` at [manufacturing_settings.py:11](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:11). Knobs and who reads them:

| Field | Type | Read by | Purpose |
|---|---|---|---|
| `material_consumption` | Check | `Work Order.onload`, `is_material_consumption_enabled()` | Toggles the `Material Consumption for Manufacture` SE purpose. |
| `backflush_raw_materials_based_on` | Literal `"BOM"` / `"Material Transferred for Manufacture"` | `Work Order.onload`, `StockEntry` material-consumption logic | Strategy for computing consumed qty on `Manufacture` SE: BOM-exploded vs actually transferred. |
| `overproduction_percentage_for_work_order` | Percent | `Work Order.update_work_order_qty` ([:633](../../erpnext/manufacturing/doctype/work_order/work_order.py:633)) | Tolerance on `produced_qty > qty`. |
| `overproduction_percentage_for_sales_order` | Percent | `Work Order.validate_production_order_against_so` ([:555](../../erpnext/manufacturing/doctype/work_order/work_order.py:555)) | Tolerance on WO-vs-SO qty. |
| `transfer_extra_materials_percentage` | Percent | `Work Order.validate_additional_transferred_qty` ([:682](../../erpnext/manufacturing/doctype/work_order/work_order.py:682)) | Tolerance on `additional_transferred_qty`. |
| `job_card_excess_transfer` | Check | `StockEntry.validate_job_card_item` ([stock_entry.py:545](../../erpnext/stock/doctype/stock_entry/stock_entry.py:545)), `JobCard.onload` | Allows Job-Card-linked SE rows without a matching JC item. |
| `enforce_time_logs` | Check | `JobCard.validate_job_card` ([:876](../../erpnext/manufacturing/doctype/job_card/job_card.py:876)) | Requires `from_time` + `to_time` on every time log. |
| `make_serial_no_batch_from_work_order` | Check | `WorkOrder.create_serial_no_batch_no` ([:893](../../erpnext/manufacturing/doctype/work_order/work_order.py:893)) | Auto-creates Batch / Serial Nos at `before_submit`. |
| `update_bom_costs_automatically` | Check | `auto_update_latest_price_in_all_boms` ([bom_update_tool.py:51](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:51)) | Daily scheduler gate. |
| `allow_editing_of_items_and_quantities_in_work_order` | Check | `WorkOrder.validate`, `onload` | Permits editing `required_items` / `qty` after submit. |
| `disable_capacity_planning` | Check | `WorkOrder.create_job_card` ([:1019](../../erpnext/manufacturing/doctype/work_order/work_order.py:1019)) | Skips scheduled-time-log computation. |
| `capacity_planning_for_days` | Int | `WorkOrder.create_job_card` ([:1020](../../erpnext/manufacturing/doctype/work_order/work_order.py:1020)) | Horizon for capacity slot search; default 30. |
| `mins_between_operations` | Int | `get_mins_between_operations()` ([manufacturing_settings.py:49](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:49)) | Gap between consecutive operation slots; default 10. |
| `add_corrective_operation_cost_in_finished_good_valuation` | Check | `JobCard.update_work_order` ([:940](../../erpnext/manufacturing/doctype/job_card/job_card.py:940)) | Includes corrective-JC cost in FG valuation. |
| `get_rm_cost_from_consumption_entry` | Check | Stock Entry `Manufacture` valuation path | Prefer last `Material Consumption for Manufacture` rate over BOM rate for FG valuation. |
| `set_op_cost_and_secondary_items_from_sub_assemblies` | Check | `BOM.calculate_cost` path | Roll-up op cost from sub-BOMs instead of recomputing. |
| `validate_components_quantities_per_bom` | Check | Coupled with `backflush_raw_materials_based_on == "BOM"`. Reset automatically at [manufacturing_settings.py:45](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:45) when mode changes. | Enforces exact-qty match against BOM on `Manufacture` SE. |
| `allow_overtime` | Check | capacity-planning scheduling | Ignore workstation working-hour bounds. |
| `allow_production_on_holidays` | Check | capacity-planning scheduling | Ignore workstation holiday list. |

## Scheduler jobs

From [hooks.py](../../erpnext/hooks.py):

| Schedule | Method | Purpose |
|---|---|---|
| `cron 0/15 * * * *` | `erpnext.manufacturing.doctype.bom_update_log.bom_update_log.resume_bom_cost_update_jobs` ([hooks.py:436](../../erpnext/hooks.py:436)) | Drives the level-wise `BOM Update Log (Update Cost)` forward: detects completed batches, enqueues next-level parents. |
| `daily_maintenance` | `erpnext.manufacturing.doctype.bom_update_tool.bom_update_tool.auto_update_latest_price_in_all_boms` ([hooks.py:489](../../erpnext/hooks.py:489)) | When `update_bom_costs_automatically=1` and no recent log, creates a new `BOM Update Log (Update Cost)`. |

No other manufacturing-specific scheduler registrations.

## Hooks.py touchpoints

- `calendars` — includes `"Work Order"` at [hooks.py:111](../../erpnext/hooks.py:111). Feeds the Desk calendar view using `work_order_calendar.js`.
- `website_generators` — includes `"BOM"` at [hooks.py:113](../../erpnext/hooks.py:113).
- `website_route_rules` — `/boms → BOM` at [hooks.py:205](../../erpnext/hooks.py:205).
- `global_search_doctypes["Default"]` — `BOM` at index 6, `Work Order` at index 10 ([hooks.py:645](../../erpnext/hooks.py:645) / [:649](../../erpnext/hooks.py:649)).
- `scheduler_events` — see above.
- `doc_events` — **none** target manufacturing DocTypes.
- `extend_doctype_class` — **none** target manufacturing DocTypes.
- `regional_overrides` — **none** target manufacturing DocTypes.

## Reports

Under [erpnext/manufacturing/report/](../../erpnext/manufacturing/report/):

- **Production Planning Report** — PP / WO demand vs availability.
- **Production Analytics** — period-sliced production throughput.
- **Work Order Summary** — WO status rollup.
- **Downtime Analysis / OEE** — uses `Downtime Entry` + Job Card time logs.
- **BOM Variance Report** — BOM-planned-cost vs actual-SE-consumed cost.
- **BOM Stock Calculated / Report** — BOM-required-qty vs on-hand.
- **Quality Inspection Summary** — cross-links with Stock module QI reports when tied via WO / BOM.
- **Job Card Summary** — JC status / time rollup per workstation.

## Workspace

`erpnext/manufacturing/workspace/manufacturing/` defines the desk workspace. Cards: Production (WO / Job Card / Stock Entry shortcuts), Bill of Materials (BOM / BOM Creator / BOM Update Tool), Tools (Production Plan / MPS / Sales Forecast), Setup (Workstation / Operation / Routing / Manufacturing Settings), Reports.

## Regional overrides

**None.** Verified: no `erpnext/regional/*/` files reference `manufacturing`, `bom`, `work_order`, `production_plan`, `job_card`. No entries in `regional_overrides` at [hooks.py:608](../../erpnext/hooks.py:608) target manufacturing methods.

Manufacturing is the only large transactional module in ERPNext without country-specific logic — production is treated as accounting-neutral (GL hits live on Stock Entry, which uses regular warehouse / expense / WIP account registration with no country-specific tax overlay).

## Cross-module interactions

- **Selling → Manufacturing**: `Production Plan.get_items_from="Sales Order"` pulls SO items into `po_items`. See [flows/selling-flow.md](../flows/selling-flow.md). Work Order writeback to SO Item: `production_plan_qty`, `work_order_qty`, `produced_qty` (via `update_produced_qty_in_so_item` at [work_order.py:670](../../erpnext/manufacturing/doctype/work_order/work_order.py:670)).
- **Buying → Manufacturing**: `Production Plan.make_subcontracted_purchase_order` ([:861](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:861)) emits `Purchase Order(is_subcontracted=1)`, wiring the legacy subcontracting flow. See [flows/buying-flow.md](../flows/buying-flow.md) and [flows/subcontracting-flow.md](../flows/subcontracting-flow.md).
- **Stock → Manufacturing**: `Stock Entry` is the only carrier of manufacturing inventory movement. `StockEntry.update_work_order` at [stock_entry.py:2089](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2089) and `update_disassembled_order` at [:2129](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2129) are the writeback points. Also `Material Request` is the creation target of `Production Plan.make_material_request`; `Material Request` tracks `work_order_qty` via `StockEntry.on_submit` handler `update_completed_and_requested_qty` wired in [hooks.py:354](../../erpnext/hooks.py:354).
- **Subcontracting → Manufacturing**: `Subcontracting Inward Order` can create a `Work Order` citing it via `subcontracting_inward_order` + `subcontracting_inward_order_item` fields on WO. `validate_subcontracting_inward_order` at [work_order.py:290](../../erpnext/manufacturing/doctype/work_order/work_order.py:290) enforces warehouse equivalence.
- **Projects**: Work Order's `project` field gets passed through into every Stock Entry it raises. `update_cost_in_project` at [stock_entry.py:632](../../erpnext/stock/doctype/stock_entry/stock_entry.py:632) aggregates consumed cost on the Project at SE submit.

## Related

- [manufacturing-doctypes.md](./manufacturing-doctypes.md) — per-DocType reference cards.
- [flows/manufacturing-flow.md](../flows/manufacturing-flow.md) — full execution cascade with Mermaid diagrams.
- [flows/stock-flow.md](../flows/stock-flow.md) — SLE write path invoked by every manufacturing Stock Entry.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL composition on Stock Entry.
- [flows/selling-flow.md](../flows/selling-flow.md) — SO → Production Plan entry path.
- [flows/buying-flow.md](../flows/buying-flow.md) — Production Plan → Purchase Order (subcontract) path.
- [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) — subcontract sub-assembly execution.
- [modules/stock.md](./stock.md) — Stock Entry is owned by the Stock module.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy (manufacturing is a sibling branch, not inheriting).
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — event order reference.

## Changelog

- `2026-04-17` — initial version.
