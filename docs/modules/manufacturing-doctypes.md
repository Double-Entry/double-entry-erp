---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: manufacturing
status: complete
related_docs:
  - ./manufacturing.md
  - ../flows/manufacturing-flow.md
  - ../flows/stock-flow.md
  - ../flows/accounting-flow.md
  - ./stock-doctypes.md
  - ./selling-doctypes.md
  - ./buying-doctypes.md
  - ./subcontracting-doctypes.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
---

# Manufacturing DocType reference cards

> **TL;DR:** Per-DocType reference cards for the Manufacturing module. Each card lists the path, controller inheritance, key fields, hooks implemented (`validate` / `before_save` / `before_submit` / `on_submit` / `on_cancel` / `on_update_after_submit`), entry points into stock / GL (almost always routed through `Stock Entry`), and the SE purpose / field names that cite the DocType. All manufacturing DocTypes except `Stock Entry` itself inherit `Document` directly — they do not participate in the transaction controller chain. The carrier of inventory movement and GL is **always** `Stock Entry` (owned by the Stock module; see [modules/stock-doctypes.md](./stock-doctypes.md)).

## Scope of this document

- **Covered here:** reference cards for every manufacturing DocType shipped in `erpnext/manufacturing/doctype/` plus the manufacturing-specific purposes of `Stock Entry`.
- **Covered by [manufacturing.md](./manufacturing.md):** module overview, directory layout, scheduler jobs, settings knobs.
- **Covered by [flows/manufacturing-flow.md](../flows/manufacturing-flow.md):** end-to-end lifecycle with Mermaid sequence diagrams.

## Index

**Master data**
- [BOM](#bom) · [BOM Item](#bom-item) · [BOM Explosion Item](#bom-explosion-item) · [BOM Operation](#bom-operation) · [BOM Secondary Item](#bom-secondary-item) · [BOM Website Item / Operation](#bom-website-item--bom-website-operation) · [BOM Creator](#bom-creator) · [BOM Creator Item](#bom-creator-item)
- [BOM Update Log](#bom-update-log) · [BOM Update Batch](#bom-update-batch) · [BOM Update Tool](#bom-update-tool)
- [Routing](#routing) · [Operation](#operation) · [Sub Operation](#sub-operation)
- [Workstation](#workstation) · [Workstation Type](#workstation-type) · [Workstation Cost](#workstation-cost) · [Workstation Operating Component](#workstation-operating-component) · [Workstation Operating Component Account](#workstation-operating-component-account) · [Workstation Working Hour](#workstation-working-hour)
- [Plant Floor](#plant-floor)

**Planning**
- [Production Plan](#production-plan) · [Production Plan Item](#production-plan-item) · [Production Plan Sales Order](#production-plan-sales-order) · [Production Plan Sub Assembly Item](#production-plan-sub-assembly-item) · [Production Plan Material Request](#production-plan-material-request) · [Production Plan Material Request Warehouse](#production-plan-material-request-warehouse) · [Production Plan Item Reference](#production-plan-item-reference) · [Material Request Plan Item](#material-request-plan-item)
- [Master Production Schedule](#master-production-schedule) · [Master Production Schedule Item](#master-production-schedule-item)
- [Sales Forecast](#sales-forecast) · [Sales Forecast Item](#sales-forecast-item)

**Execution**
- [Work Order](#work-order) · [Work Order Item](#work-order-item) · [Work Order Operation](#work-order-operation)
- [Job Card](#job-card) · [Job Card Item](#job-card-item) · [Job Card Operation](#job-card-operation) · [Job Card Scheduled Time](#job-card-scheduled-time) · [Job Card Secondary Item](#job-card-secondary-item) · [Job Card Time Log](#job-card-time-log)

**Operational**
- [Downtime Entry](#downtime-entry)

**Single**
- [Manufacturing Settings](#manufacturing-settings)

**Cross-module**
- [Blanket Order](#blanket-order) · [Blanket Order Item](#blanket-order-item)

**Inventory carrier (cross-link)**
- [Stock Entry — manufacturing purposes](#stock-entry--manufacturing-purposes)

---

## BOM

- **Path**: [erpnext/manufacturing/doctype/bom/bom.py:105](../../erpnext/manufacturing/doctype/bom/bom.py:105).
- **Inherits**: `frappe.website.website_generator.WebsiteGenerator`. Publishes at `/boms/<name>` via `website_generators` at [hooks.py:113](../../erpnext/hooks.py:113) and `template="templates/generators/bom.html"` at [bom.py:177](../../erpnext/manufacturing/doctype/bom/bom.py:177).
- **Submittable**: Yes.
- **Child tables**: `items: Table[BOMItem]`, `exploded_items: Table[BOMExplosionItem]`, `operations: Table[BOMOperation]`, `secondary_items: Table[BOMSecondaryItem]`.
- **Key fields**: `item` (FG), `quantity`, `is_active`, `is_default`, `with_operations`, `routing`, `rm_cost_as_per: "Valuation Rate" | "Last Purchase Rate" | "Price List"`, `transfer_material_against: "Work Order" | "Job Card"`, `track_semi_finished_goods`, `inspection_required`, `quality_inspection_template`, `process_loss_percentage`, `show_in_website`.
- **Hooks implemented**:
  - `autoname` at [:183](../../erpnext/manufacturing/doctype/bom/bom.py:183) — `BOM-<item>-<NNN>`, 140-char safe.
  - `onload` at [:226](../../erpnext/manufacturing/doctype/bom/bom.py:226) — injects `use_multi_level_bom` Property Setter.
  - `before_validate` at [:263](../../erpnext/manufacturing/doctype/bom/bom.py:263) — populates UOM conversion factors.
  - `validate` at [:275](../../erpnext/manufacturing/doctype/bom/bom.py:275).
  - `on_update` at [:393](../../erpnext/manufacturing/doctype/bom/bom.py:393) — clears bom-children cache, `check_recursion`.
  - `on_submit` at [:397](../../erpnext/manufacturing/doctype/bom/bom.py:397) — `manage_default_bom`, `update_bom_creator_status`.
  - `on_cancel` at [:401](../../erpnext/manufacturing/doctype/bom/bom.py:401) — clears `is_active` + `is_default`, `validate_bom_links` (refuses cancel if used elsewhere), `manage_default_bom`.
  - `on_update_after_submit` at [:444](../../erpnext/manufacturing/doctype/bom/bom.py:444).
- **Key methods**: `update_cost` at [:618](../../erpnext/manufacturing/doctype/bom/bom.py:618) (self + parent propagation), `calculate_cost` at [:935](../../erpnext/manufacturing/doctype/bom/bom.py:935), `calculate_rm_cost` / `calculate_op_cost` / `calculate_exploded_cost`, `update_exploded_items` at [:1099](../../erpnext/manufacturing/doctype/bom/bom.py:1099), `manage_default_bom` at [:676](../../erpnext/manufacturing/doctype/bom/bom.py:676), `check_recursion` at [:792](../../erpnext/manufacturing/doctype/bom/bom.py:792), `traverse_tree` at [:908](../../erpnext/manufacturing/doctype/bom/bom.py:908), `validate_bom_links` (links to WO / PP / child BOMs).
- **Module-level helpers**: `get_bom_items_as_dict` at [:1385](../../erpnext/manufacturing/doctype/bom/bom.py:1385), `get_bom_item_rate` at [:1290](../../erpnext/manufacturing/doctype/bom/bom.py:1290), `add_additional_cost`, `validate_bom_no`, `get_children` (tree drill-down for client).
- **Tree helper**: `BOMTree` at [:31](../../erpnext/manufacturing/doctype/bom/bom.py:31), `BOMRecursionError` at [:27](../../erpnext/manufacturing/doctype/bom/bom.py:27).
- **Stock / GL**: None. Costs are projection-only.

## BOM Item

- **Path**: [erpnext/manufacturing/doctype/bom_item/bom_item.py](../../erpnext/manufacturing/doctype/bom_item/).
- **Inherits**: `Document` (child table, `istable=1`).
- **Parent**: `BOM.items`.
- **Key fields**: `item_code`, `qty`, `uom`, `stock_qty`, `stock_uom`, `conversion_factor`, `rate`, `base_rate`, `amount`, `bom_no` (nullable — if set, this row is a sub-assembly), `source_warehouse`, `operation`, `operation_row_id`, `sourced_by_supplier`, `do_not_explode`, `is_stock_item`, `is_phantom_item`, `include_item_in_manufacturing`.
- **Hooks implemented**: None (child).
- **Stock / GL**: None.

## BOM Explosion Item

- **Path**: [erpnext/manufacturing/doctype/bom_explosion_item/bom_explosion_item.py](../../erpnext/manufacturing/doctype/bom_explosion_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `BOM.exploded_items`. Rebuilt every `validate` via `update_exploded_items` at [bom.py:1099](../../erpnext/manufacturing/doctype/bom/bom.py:1099).
- **Key fields**: `item_code`, `qty` (normalized per parent `bom.quantity`), `stock_qty`, `rate`, `amount`, `operation`, `source_warehouse`, `sourced_by_supplier`.
- **Hooks implemented**: None.
- **Stock / GL**: None. Read by `get_bom_items_as_dict(fetch_exploded=1)` to build Work Order required-items and Stock Entry Manufacture items.

## BOM Operation

- **Path**: [erpnext/manufacturing/doctype/bom_operation/bom_operation.py](../../erpnext/manufacturing/doctype/bom_operation/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `BOM.operations`, `Routing.operations`.
- **Key fields**: `operation`, `workstation`, `workstation_type`, `time_in_mins`, `hour_rate`, `base_hour_rate`, `operating_cost`, `base_operating_cost`, `batch_size`, `set_cost_based_on_bom_qty`, `sequence_id`, `description`, `fixed_time`, `cost_per_unit`, `is_subcontracted`, `is_final_finished_good`, `finished_good`, `bom_no` (for track-semi-finished-goods BOMs).
- **Hooks implemented**: None.
- **Stock / GL**: None.

## BOM Secondary Item

- **Path**: [erpnext/manufacturing/doctype/bom_secondary_item/bom_secondary_item.py](../../erpnext/manufacturing/doctype/bom_secondary_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `BOM.secondary_items`.
- **Key fields**: `item_code`, `qty`, `type: "Scrap" | "By-Product" | ...`, `cost_allocation_per` (split of parent cost into this row), `process_loss_per`, `is_legacy`.
- **Hooks implemented**: None. Validated by parent `BOM.validate_secondary_items` at [:335](../../erpnext/manufacturing/doctype/bom/bom.py:335).
- **Stock / GL**: None.

## BOM Website Item / BOM Website Operation

- **Paths**: [erpnext/manufacturing/doctype/bom_website_item/](../../erpnext/manufacturing/doctype/bom_website_item/), [erpnext/manufacturing/doctype/bom_website_operation/](../../erpnext/manufacturing/doctype/bom_website_operation/).
- **Inherits**: `Document` (child, `istable=1`).
- **Role**: Read-only projections of `BOM Item` / `BOM Operation` used by the `/boms/<name>` WebsiteGenerator template. Populated as derived data; not directly edited.
- **Stock / GL**: None.

## BOM Creator

- **Path**: [erpnext/manufacturing/doctype/bom_creator/bom_creator.py:37](../../erpnext/manufacturing/doctype/bom_creator/bom_creator.py:37).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Role**: Hierarchical scratchpad for building a BOM tree in one document. On submit, recursively emits `BOM` documents one per sub-assembly.
- **Child tables**: `items: Table[BOMCreatorItem]`.
- **Key fields**: `item_code`, `company`, `qty`, `rm_cost_as_per`, `routing`, `currency`, `conversion_rate`, `raw_material_cost`, `is_phantom`, `set_rate_based_on_warehouse`, `default_warehouse`, `status: "Draft" | "Submitted" | "In Progress" | "Completed" | "Failed" | "Cancelled"`, `error_log`.
- **Hooks implemented**: `before_save` at [:73](../../erpnext/manufacturing/doctype/bom_creator/bom_creator.py:73) (sets status, expandable flag, conversion factor, reference ID, rates), `validate`.
- **Writeback target**: `BOM.bom_creator` / `bom_creator_item` fields are set on emitted BOMs. `BOM.update_bom_creator_status` ([bom.py:410](../../erpnext/manufacturing/doctype/bom/bom.py:410)) writes back `bom_created` on the matching `BOM Creator Item` row.
- **Stock / GL**: None.

## BOM Creator Item

- **Path**: [erpnext/manufacturing/doctype/bom_creator_item/bom_creator_item.py](../../erpnext/manufacturing/doctype/bom_creator_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `BOM Creator.items`.
- **Key fields**: `item_code`, `qty`, `uom`, `stock_qty`, `rate`, `amount`, `fg_item`, `is_expandable`, `parent_row_no`, `bom_created`, `operation`.

## BOM Update Log

- **Path**: [erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:26](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:26).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `bom_batches: Table[BOMUpdateBatch]`.
- **Key fields**: `update_type: "Replace BOM" | "Update Cost"`, `current_bom`, `new_bom`, `current_level`, `processed_boms` (JSON LongText), `status: "Queued" | "In Progress" | "Completed" | "Failed" | "Cancelled"`, `error_log`.
- **Hooks implemented**:
  - `validate` at [:57](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:57) — for Replace: validates both BOMs for same item; for Update Cost: refuses new if another is in progress.
  - `on_submit` at [:106](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:106) — enqueues `run_replace_bom_job` or `process_boms_cost_level_wise`.
  - `on_discard` at [:67](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:67).
  - `clear_old_logs` static at [:48](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:48) — 90-day retention for Update Cost logs.
- **Module-level**: `run_replace_bom_job` at [:127](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:127), `process_boms_cost_level_wise` at [:151](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:151), `queue_bom_cost_jobs` at [:186](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:186), `resume_bom_cost_update_jobs` at [:213](../../erpnext/manufacturing/doctype/bom_update_log/bom_update_log.py:213) — registered as scheduler cron at [hooks.py:436](../../erpnext/hooks.py:436).
- **Helper module**: [bom_updation_utils.py](../../erpnext/manufacturing/doctype/bom_update_log/bom_updation_utils.py) — `get_leaf_boms`, `get_next_higher_level_boms`, `replace_bom`, `update_cost_in_level`, `set_values_in_log`, `handle_exception`.
- **Stock / GL**: None. Updates cost columns in `BOM` and `BOM Item` rows.

## BOM Update Batch

- **Path**: [erpnext/manufacturing/doctype/bom_update_batch/bom_update_batch.py](../../erpnext/manufacturing/doctype/bom_update_batch/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `BOM Update Log.bom_batches`.
- **Key fields**: `level`, `batch_no`, `boms_updated` (JSON), `status: "Pending" | "Completed"`, `error_log`.

## BOM Update Tool

- **Path**: [erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:15](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:15).
- **Inherits**: `Document`.
- **Submittable**: No (virtual / Single-like entry-point form).
- **Key fields**: `current_bom`, `new_bom`.
- **Module-level entry points**:
  - `enqueue_replace_bom` at [:32](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:32) — creates a `BOM Update Log (Replace BOM)`.
  - `enqueue_update_cost` at [:43](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:43) — creates a `BOM Update Log (Update Cost)`.
  - `auto_update_latest_price_in_all_boms` at [:49](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:49) — registered as `daily_maintenance` at [hooks.py:489](../../erpnext/hooks.py:489).
  - `is_older_log` at [:64](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:64), `create_bom_update_log` at [:69](../../erpnext/manufacturing/doctype/bom_update_tool/bom_update_tool.py:69).
- **Stock / GL**: None.

## Routing

- **Path**: [erpnext/manufacturing/doctype/routing/routing.py:11](../../erpnext/manufacturing/doctype/routing/routing.py:11).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Child tables**: `operations: Table[BOMOperation]`.
- **Key fields**: `routing_name`, `disabled`.
- **Hooks implemented**:
  - `validate` at [:27](../../erpnext/manufacturing/doctype/routing/routing.py:27) — `calculate_operating_cost` + `set_routing_id` (enforces monotone `sequence_id`).
  - `on_update` at [:31](../../erpnext/manufacturing/doctype/routing/routing.py:31).
- **Reused by**: `BOM.set_routing_operations` at validate; on selecting a routing, operations are copied into BOM's operations table.
- **Stock / GL**: None.

## Operation

- **Path**: [erpnext/manufacturing/doctype/operation/operation.py:10](../../erpnext/manufacturing/doctype/operation/operation.py:10).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Child tables**: `sub_operations: Table[SubOperation]`.
- **Key fields**: `batch_size`, `create_job_card_based_on_batch_size`, `workstation`, `description`, `is_corrective_operation`, `quality_inspection_template`, `total_operation_time`.
- **Hooks implemented**:
  - `validate` at [:31](../../erpnext/manufacturing/doctype/operation/operation.py:31) — defaults description, `duplicate_sub_operation`, `set_total_time`.
- **Impact**: `create_job_card_based_on_batch_size` drives `WorkOrder.create_job_card` at [:1016](../../erpnext/manufacturing/doctype/work_order/work_order.py:1016) → `split_qty_based_on_batch_size` at [:2579](../../erpnext/manufacturing/doctype/work_order/work_order.py:2579): when set, creates multiple Job Cards sliced by `batch_size`; when unset, one JC per operation.
- **Stock / GL**: None.

## Sub Operation

- **Path**: [erpnext/manufacturing/doctype/sub_operation/sub_operation.py](../../erpnext/manufacturing/doctype/sub_operation/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Operation.sub_operations`, also referenced by `Job Card Operation`.
- **Key fields**: `operation`, `time_in_mins`, `description`.

## Workstation

- **Path**: [erpnext/manufacturing/doctype/workstation/workstation.py:39](../../erpnext/manufacturing/doctype/workstation/workstation.py:39).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Child tables**: `workstation_costs: Table[WorkstationCost]`, `working_hours: Table[WorkstationWorkingHour]`.
- **Key fields**: `workstation_name`, `workstation_type`, `plant_floor`, `warehouse`, `hour_rate`, `production_capacity`, `status: "Production" | "Off" | "Idle" | "Problem" | "Maintenance" | "Setup"`, `holiday_list`, `total_working_hours`, `disabled`.
- **Hooks implemented**:
  - `validate` at [:70](../../erpnext/manufacturing/doctype/workstation/workstation.py:70) — `validate_duplicate_operating_component`.
  - `before_save` at [:85](../../erpnext/manufacturing/doctype/workstation/workstation.py:85) — `set_data_based_on_workstation_type` / `set_hour_rate` (sum of `workstation_costs.operating_cost`) / `set_total_working_hours` / `disabled_workstation`.
- **Exception classes**: `WorkstationHolidayError`, `NotInWorkingHoursError`, `OverlapError`.
- **Stock / GL**: None. `warehouse` may be used by Stock Entry as a default source when the workstation holds WIP inventory.

## Workstation Type

- **Path**: [erpnext/manufacturing/doctype/workstation_type/workstation_type.py:10](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:10).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Child tables**: `workstation_costs: Table[WorkstationCost]`.
- **Key fields**: `workstation_type`, `description`, `hour_rate` (sum of costs).
- **Hooks implemented**:
  - `validate` at [:27](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:27).
  - `before_save` at [:42](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:42) — `set_hour_rate`.
- **Module-level**: `get_workstations` at [:53](../../erpnext/manufacturing/doctype/workstation_type/workstation_type.py:53) — members of a type.
- **Role**: BOM / Routing rows may reference `workstation_type` instead of `workstation`; capacity planning picks a concrete workstation at Job Card creation.

## Workstation Cost

- **Path**: [erpnext/manufacturing/doctype/workstation_cost/workstation_cost.py](../../erpnext/manufacturing/doctype/workstation_cost/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Workstation.workstation_costs`, `Workstation Type.workstation_costs`.
- **Key fields**: `operating_component`, `operating_cost`.

## Workstation Operating Component

- **Path**: [erpnext/manufacturing/doctype/workstation_operating_component/workstation_operating_component.py](../../erpnext/manufacturing/doctype/workstation_operating_component/).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Child tables**: `accounts: Table[WorkstationOperatingComponentAccount]`.
- **Key fields**: `component_name`, `description`.

## Workstation Operating Component Account

- **Path**: [erpnext/manufacturing/doctype/workstation_operating_component_account/](../../erpnext/manufacturing/doctype/workstation_operating_component_account/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Workstation Operating Component.accounts`.
- **Key fields**: `company`, `account`.

## Workstation Working Hour

- **Path**: [erpnext/manufacturing/doctype/workstation_working_hour/](../../erpnext/manufacturing/doctype/workstation_working_hour/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Workstation.working_hours`.
- **Key fields**: `start_time`, `end_time`, `enabled`.

## Plant Floor

- **Path**: [erpnext/manufacturing/doctype/plant_floor/plant_floor.py:10](../../erpnext/manufacturing/doctype/plant_floor/plant_floor.py:10).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Key fields**: `floor_name`, `company`, `warehouse`.
- **Methods**: `make_stock_entry` at [:24](../../erpnext/manufacturing/doctype/plant_floor/plant_floor.py:24) — builds a Stock Entry with items from the floor's warehouse.
- **Role**: Logical grouping of workstations. `Workstation.plant_floor` field links upward.

## Production Plan

- **Path**: [erpnext/manufacturing/doctype/production_plan/production_plan.py:39](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `po_items: Table[ProductionPlanItem]`, `sub_assembly_items: Table[ProductionPlanSubAssemblyItem]`, `mr_items: Table[MaterialRequestPlanItem]`, `material_requests: Table[ProductionPlanMaterialRequest]`, `sales_orders: Table[ProductionPlanSalesOrder]`, `warehouses: TableMultiSelect[ProductionPlanMaterialRequestWarehouse]`, `prod_plan_references: Table[ProductionPlanItemReference]`.
- **Key fields**: `get_items_from: "" | "Sales Order" | "Material Request"`, `company`, `posting_date`, `from_date`, `to_date`, `customer`, `warehouse`, `sub_assembly_warehouse`, `skip_available_sub_assembly_item`, `combine_items`, `combine_sub_items`, `include_non_stock_items`, `include_safety_stock`, `include_subcontracted_items`, `consider_minimum_order_qty`, `ignore_existing_ordered_qty`, `reserve_stock`, `total_planned_qty`, `total_produced_qty`, `status: "" | "Draft" | "Submitted" | "Not Started" | "In Process" | "Completed" | "Closed" | "Cancelled" | "Material Requested"`.
- **Hooks implemented**:
  - `onload` at [:115](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:115).
  - `on_discard` at [:121](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:121).
  - `validate` at [:124](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:124).
  - `on_submit` at [:588](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:588) — `update_bin_qty`, `update_sales_order`, `add_reference_to_raw_materials`, `update_stock_reservation`.
  - `on_cancel` at [:594](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:594) — same reversed plus `delete_draft_work_order`.
- **Whitelisted actions**: `make_work_order` at [:774](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:774), `make_material_request` at [:963](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:963), `get_sub_assembly_items` at [:1043](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1043), `get_open_sales_orders_to_plan_against`, `set_status` at [:687](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:687), `validate_sales_orders` at [:144](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:144).
- **Module-level helpers**: `get_items_for_material_requests` at [:1648](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1648), `get_sub_assembly_items` at [:1917](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1917), `download_raw_materials` at [:1207](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1207), `get_exploded_items` at [:1285](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1285), `get_reserved_qty_for_sub_assembly`, `make_stock_reservation_entries`, `sales_order_query`, `set_default_warehouses`, `get_sales_orders`.
- **Stock / GL**: None directly. Writes `reserved_qty_for_production_plan` / `reserved_qty_for_sub_assembly` on `Bin` rows; creates `Stock Reservation Entry` when `reserve_stock=1`. Creates `Work Order`, `Material Request`, `Purchase Order (is_subcontracted=1)` as downstream docs.

## Production Plan Item

- **Path**: [erpnext/manufacturing/doctype/production_plan_item/](../../erpnext/manufacturing/doctype/production_plan_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.po_items`.
- **Key fields**: `item_code`, `bom_no`, `planned_qty`, `stock_qty`, `pending_qty`, `produced_qty`, `ordered_qty`, `warehouse`, `sales_order`, `sales_order_item`, `material_request`, `material_request_item`, `include_exploded_items`, `product_bundle_item`, `planned_start_date`, `description`, `stock_uom`.

## Production Plan Sales Order

- **Path**: [erpnext/manufacturing/doctype/production_plan_sales_order/](../../erpnext/manufacturing/doctype/production_plan_sales_order/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.sales_orders`.
- **Key fields**: `sales_order`, `sales_order_date`, `customer`, `grand_total`.

## Production Plan Sub Assembly Item

- **Path**: [erpnext/manufacturing/doctype/production_plan_sub_assembly_item/](../../erpnext/manufacturing/doctype/production_plan_sub_assembly_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.sub_assembly_items`.
- **Key fields**: `production_item`, `bom_no`, `qty`, `stock_qty`, `ordered_qty`, `received_qty`, `fg_warehouse`, `bom_level`, `schedule_date`, `type_of_manufacturing: "In House" | "Subcontract" | "Material Request"`, `supplier`, `production_plan_item` (back-ref), `sales_order`, `sales_order_item`, `is_sub_contracted_item`.
- **Populated by**: `Production Plan.get_sub_assembly_items` at [production_plan.py:1043](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:1043).
- **Consumed by**: `make_work_order_for_subassembly_items` at [:805](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:805) and `make_subcontracted_purchase_order` at [:861](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:861).

## Production Plan Material Request

- **Path**: [erpnext/manufacturing/doctype/production_plan_material_request/](../../erpnext/manufacturing/doctype/production_plan_material_request/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.material_requests`.
- **Key fields**: `material_request`, `material_request_date`, `schedule_date`.
- **Role**: Staging for `make_material_request` output tracking.

## Production Plan Material Request Warehouse

- **Path**: [erpnext/manufacturing/doctype/production_plan_material_request_warehouse/](../../erpnext/manufacturing/doctype/production_plan_material_request_warehouse/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.warehouses` (TableMultiSelect).
- **Role**: Fan-out — get MR rows for each warehouse in the list.

## Production Plan Item Reference

- **Path**: [erpnext/manufacturing/doctype/production_plan_item_reference/](../../erpnext/manufacturing/doctype/production_plan_item_reference/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.prod_plan_references`.
- **Role**: Cross-reference for combined Sales Orders (tracks which SO contributed which planned qty when `combine_items=1`). Used by `WorkOrder.update_work_order_qty_in_combined_so` at [:1219](../../erpnext/manufacturing/doctype/work_order/work_order.py:1219).

## Material Request Plan Item

- **Path**: [erpnext/manufacturing/doctype/material_request_plan_item/](../../erpnext/manufacturing/doctype/material_request_plan_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Production Plan.mr_items`.
- **Key fields**: `item_code`, `warehouse`, `from_warehouse`, `quantity`, `required_bom_qty`, `requested_qty`, `min_order_qty`, `safety_stock`, `projected_qty`, `actual_qty`, `ordered_qty`, `schedule_date`, `material_request_type: "Purchase" | "Material Transfer" | "Subcontracting" | ...`, `material_request`, `main_item_code`, `from_bom`, `sub_assembly_item_reference`.

## Master Production Schedule

- **Path**: [erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:12](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:12).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `items: Table[MasterProductionScheduleItem]`, `sales_orders: Table[ProductionPlanSalesOrder]` (reused from PP), `material_requests: Table[ProductionPlanMaterialRequest]` (reused), `select_items: TableMultiSelect[MasterProductionScheduleItem]`.
- **Key fields**: `company`, `posting_date`, `from_date`, `to_date`, `parent_warehouse`, `sales_forecast`.
- **Hooks implemented**:
  - `validate` at [:62](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:62) — `set_to_date`, `validate_company`.
  - `on_submit` at [:438](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:438) — `enqueue_mrp_creation` (background `make_mrp`).
- **Whitelisted**: `get_actual_demand` at [:45](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:45), `fetch_materials_requests` at [:311](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:311), `fetch_sales_orders` at [:367](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:367).
- **Module-level**: `get_item_lead_time` at [:450](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:450), `get_mps_details` at [:470](../../erpnext/manufacturing/doctype/master_production_schedule/master_production_schedule.py:470).
- **Stock / GL**: None. Produces MRP Log (not yet documented — `TODO(verify)` whether `make_mrp` still writes to `MRP Log` or to Production Plan).
- **Reference on Work Order**: `mps: DF.Link | None` at [work_order.py:106](../../erpnext/manufacturing/doctype/work_order/work_order.py:106).

## Master Production Schedule Item

- **Path**: [erpnext/manufacturing/doctype/master_production_schedule_item/](../../erpnext/manufacturing/doctype/master_production_schedule_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Master Production Schedule.items` and `.select_items`.
- **Key fields**: `item_code`, `warehouse`, `delivery_date`, `order_release_date`, `qty`, `planned_qty`, `stock_uom`, `uom`, `cumulative_lead_time`.

## Sales Forecast

- **Path**: [erpnext/manufacturing/doctype/sales_forecast/sales_forecast.py:10](../../erpnext/manufacturing/doctype/sales_forecast/sales_forecast.py:10).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `items: Table[SalesForecastItem]`.
- **Role**: Combines historical sales with manually-entered forecast quantities. Feeds MPS.

## Sales Forecast Item

- **Path**: [erpnext/manufacturing/doctype/sales_forecast_item/](../../erpnext/manufacturing/doctype/sales_forecast_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Sales Forecast.items`.
- **Key fields**: `item_code`, `warehouse`, `delivery_date`, `qty`, `historical_qty`.

## Work Order

- **Path**: [erpnext/manufacturing/doctype/work_order/work_order.py:69](../../erpnext/manufacturing/doctype/work_order/work_order.py:69).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `required_items: Table[WorkOrderItem]`, `operations: Table[WorkOrderOperation]`.
- **Key fields**: `production_item`, `bom_no`, `qty`, `stock_uom`, `use_multi_level_bom`, `source_warehouse`, `wip_warehouse`, `fg_warehouse`, `scrap_warehouse`, `skip_transfer`, `from_wip_warehouse`, `transfer_material_against: "Work Order" | "Job Card"`, `sales_order`, `sales_order_item`, `material_request`, `material_request_item`, `production_plan`, `production_plan_item`, `production_plan_sub_assembly_item`, `subcontracting_inward_order`, `subcontracting_inward_order_item`, `project`, `allow_alternative_item`, `mps`, `product_bundle_item`, `planned_start_date`, `planned_end_date`, `actual_start_date`, `actual_end_date`, `planned_operating_cost`, `actual_operating_cost`, `additional_operating_cost`, `corrective_operation_cost`, `total_operating_cost`, `expected_delivery_date`, `lead_time`, `produced_qty`, `material_transferred_for_manufacturing`, `additional_transferred_qty`, `process_loss_qty`, `disassembled_qty`, `max_producible_qty`, `has_batch_no`, `has_serial_no`, `batch_size`, `reserve_stock`, `update_consumed_material_cost_in_project`, `track_semi_finished_goods`, `status`.
- **Status literal**: `"" | "Draft" | "Submitted" | "Not Started" | "In Process" | "Stock Reserved" | "Stock Partially Reserved" | "Completed" | "Stopped" | "Closed" | "Cancelled"` ([:128](../../erpnext/manufacturing/doctype/work_order/work_order.py:128)).
- **Hooks implemented**:
  - `onload` at [:152](../../erpnext/manufacturing/doctype/work_order/work_order.py:152).
  - `on_discard` at [:183](../../erpnext/manufacturing/doctype/work_order/work_order.py:183).
  - `validate` at [:186](../../erpnext/manufacturing/doctype/work_order/work_order.py:186).
  - `before_save` at [:256](../../erpnext/manufacturing/doctype/work_order/work_order.py:256) — `set_skip_transfer_for_operations` (track-semi-finished-goods mode).
  - `before_submit` at [:779](../../erpnext/manufacturing/doctype/work_order/work_order.py:779) — `create_serial_no_batch_no`.
  - `on_submit` at [:782](../../erpnext/manufacturing/doctype/work_order/work_order.py:782).
  - `on_cancel` at [:802](../../erpnext/manufacturing/doctype/work_order/work_order.py:802).
- **Key methods**:
  - `validate_production_item`, `validate_sales_order`, `validate_warehouse`, `validate_production_order_against_so` at [:520](../../erpnext/manufacturing/doctype/work_order/work_order.py:520), `validate_cancel` at [:1087](../../erpnext/manufacturing/doctype/work_order/work_order.py:1087), `validate_operation_time`, `validate_operations_sequence` at [:266](../../erpnext/manufacturing/doctype/work_order/work_order.py:266), `validate_dates` at [:222](../../erpnext/manufacturing/doctype/work_order/work_order.py:222), `validate_subcontracting_inward_order` at [:290](../../erpnext/manufacturing/doctype/work_order/work_order.py:290), `validate_additional_transferred_qty` at [:682](../../erpnext/manufacturing/doctype/work_order/work_order.py:682).
  - `set_default_warehouse`, `set_warehouses`, `set_required_items` at [:1532](../../erpnext/manufacturing/doctype/work_order/work_order.py:1532), `set_work_order_operations` at [:1252](../../erpnext/manufacturing/doctype/work_order/work_order.py:1252), `set_actual_dates`.
  - `update_status` / `get_status` at [:569](../../erpnext/manufacturing/doctype/work_order/work_order.py:569) / [:582](../../erpnext/manufacturing/doctype/work_order/work_order.py:582), `update_work_order_qty` at [:626](../../erpnext/manufacturing/doctype/work_order/work_order.py:626), `get_transferred_or_manufactured_qty` at [:715](../../erpnext/manufacturing/doctype/work_order/work_order.py:715), `set_process_loss_qty` at [:738](../../erpnext/manufacturing/doctype/work_order/work_order.py:738), `update_production_plan_status` at [:750](../../erpnext/manufacturing/doctype/work_order/work_order.py:750), `update_planned_qty` at [:1104](../../erpnext/manufacturing/doctype/work_order/work_order.py:1104), `update_ordered_qty` at [:1151](../../erpnext/manufacturing/doctype/work_order/work_order.py:1151), `update_reserved_qty_for_production`, `update_completed_qty_in_material_request`, `update_operation_status` at [:1356](../../erpnext/manufacturing/doctype/work_order/work_order.py:1356), `update_work_order_qty_in_so` at [:1185](../../erpnext/manufacturing/doctype/work_order/work_order.py:1185), `update_work_order_qty_in_combined_so` at [:1219](../../erpnext/manufacturing/doctype/work_order/work_order.py:1219), `update_stock_reservation` at [:826](../../erpnext/manufacturing/doctype/work_order/work_order.py:826), `update_subcontracting_inward_order_received_items` at [:858](../../erpnext/manufacturing/doctype/work_order/work_order.py:858), `update_disassembled_qty` at [:703](../../erpnext/manufacturing/doctype/work_order/work_order.py:703), `on_close_or_cancel` at [:808](../../erpnext/manufacturing/doctype/work_order/work_order.py:808).
  - `create_job_card` at [:1016](../../erpnext/manufacturing/doctype/work_order/work_order.py:1016), `prepare_data_for_job_card` at [:1033](../../erpnext/manufacturing/doctype/work_order/work_order.py:1033), `set_operation_start_end_time` at [:1059](../../erpnext/manufacturing/doctype/work_order/work_order.py:1059).
  - `create_serial_no_batch_no` at [:893](../../erpnext/manufacturing/doctype/work_order/work_order.py:893), `create_batch_for_finished_good` at [:913](../../erpnext/manufacturing/doctype/work_order/work_order.py:913), `make_serial_nos` at [:951](../../erpnext/manufacturing/doctype/work_order/work_order.py:951).
- **Module-level entry points**: `make_stock_entry` at [:2387](../../erpnext/manufacturing/doctype/work_order/work_order.py:2387), `stop_unstop` at [:2481](../../erpnext/manufacturing/doctype/work_order/work_order.py:2481), `close_work_order` at [:2552](../../erpnext/manufacturing/doctype/work_order/work_order.py:2552), `make_job_card` at [:2519](../../erpnext/manufacturing/doctype/work_order/work_order.py:2519), `get_default_warehouse` at [:2469](../../erpnext/manufacturing/doctype/work_order/work_order.py:2469), `make_stock_return_entry` at [:2803](../../erpnext/manufacturing/doctype/work_order/work_order.py:2803), `create_pick_list` at [:2690](../../erpnext/manufacturing/doctype/work_order/work_order.py:2690), `create_job_card` at [:2645](../../erpnext/manufacturing/doctype/work_order/work_order.py:2645), `check_if_scrap_warehouse_mandatory` at [:2368](../../erpnext/manufacturing/doctype/work_order/work_order.py:2368), `get_disassembly_available_qty` at [:2449](../../erpnext/manufacturing/doctype/work_order/work_order.py:2449), `get_reserved_qty_for_production` at [:2753](../../erpnext/manufacturing/doctype/work_order/work_order.py:2753), `split_qty_based_on_batch_size` at [:2579](../../erpnext/manufacturing/doctype/work_order/work_order.py:2579), `get_row_wise_serial_batch` at [:2824](../../erpnext/manufacturing/doctype/work_order/work_order.py:2824), `query_sales_order` at [:2502](../../erpnext/manufacturing/doctype/work_order/work_order.py:2502), `get_item_details` (used by PP), `get_operation_details` at [:2536](../../erpnext/manufacturing/doctype/work_order/work_order.py:2536).
- **Exception classes**: `OverProductionError`, `CapacityError`, `StockOverProductionError`, `OperationTooLongError`, `ItemHasVariantError`, `SerialNoQtyError`.
- **Stock / GL**: Work Order itself writes nothing to SLE / GL. Every SE citing the WO calls back `WorkOrder.update_work_order_qty` via `StockEntry.update_work_order` at [stock_entry.py:2089](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2089). Writebacks also hit: Sales Order Item (`work_order_qty`, `produced_qty`), Material Request Item (`ordered_qty`), Production Plan Item / Sub Assembly Item (`ordered_qty` → `produced_qty`), Bin (`ordered_qty`, `planned_qty`, `reserved_qty_for_production`).

## Work Order Item

- **Path**: [erpnext/manufacturing/doctype/work_order_item/](../../erpnext/manufacturing/doctype/work_order_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Work Order.required_items`.
- **Key fields**: `item_code`, `required_qty`, `transferred_qty`, `consumed_qty`, `returned_qty`, `available_qty_at_source_warehouse`, `available_qty_at_wip_warehouse`, `source_warehouse`, `rate`, `amount`, `description`, `allow_alternative_item`, `include_item_in_manufacturing`, `operation`, `stock_reserved_qty`, `reserve_stock`.
- **Populated by**: `WorkOrder.set_required_items` at [work_order.py:1532](../../erpnext/manufacturing/doctype/work_order/work_order.py:1532) reading `get_bom_items_as_dict`.

## Work Order Operation

- **Path**: [erpnext/manufacturing/doctype/work_order_operation/](../../erpnext/manufacturing/doctype/work_order_operation/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Work Order.operations`.
- **Key fields**: `operation`, `workstation`, `workstation_type`, `time_in_mins`, `hour_rate`, `operating_cost`, `base_operating_cost`, `completed_qty`, `process_loss_qty`, `actual_operation_time`, `planned_start_time`, `planned_end_time`, `actual_start_time`, `actual_end_time`, `status: "Pending" | "Work In Progress" | "Completed"`, `sequence_id`, `batch_size`, `bom_no`, `finished_good`, `is_final_finished_good`, `is_subcontracted`, `quality_inspection_required`.
- **Populated by**: `WorkOrder.set_work_order_operations` at [work_order.py:1252](../../erpnext/manufacturing/doctype/work_order/work_order.py:1252).
- **Written by**: `JobCard.update_work_order_data` at [job_card.py:1008](../../erpnext/manufacturing/doctype/job_card/job_card.py:1008) on JC submit/cancel — sets `completed_qty`, `process_loss_qty`, `actual_operation_time`, `actual_start_time`, `actual_end_time`, sometimes `workstation`.

## Job Card

- **Path**: [erpnext/manufacturing/doctype/job_card/job_card.py:61](../../erpnext/manufacturing/doctype/job_card/job_card.py:61).
- **Inherits**: `Document`.
- **Submittable**: Yes.
- **Child tables**: `items: Table[JobCardItem]`, `time_logs: Table[JobCardTimeLog]`, `employee: TableMultiSelect[JobCardTimeLog]`, `scheduled_time_logs: Table[JobCardScheduledTime]`, `sub_operations: Table[JobCardOperation]`, `secondary_items: Table[JobCardSecondaryItem]`.
- **Key fields**: `work_order`, `operation`, `operation_id`, `operation_row_id`, `operation_row_number`, `workstation`, `workstation_type`, `bom_no`, `semi_fg_bom`, `finished_good`, `for_quantity`, `total_completed_qty`, `manufactured_qty`, `transferred_qty`, `requested_qty`, `process_loss_qty`, `time_required`, `total_time_in_mins`, `hour_rate`, `sequence_id`, `for_job_card`, `for_operation`, `is_corrective_job_card`, `is_paused`, `is_subcontracted`, `track_semi_finished_goods`, `skip_material_transfer`, `backflush_from_wip_warehouse`, `source_warehouse`, `wip_warehouse`, `target_warehouse`, `barcode`, `batch_no`, `serial_no`, `serial_and_batch_bundle`, `quality_inspection`, `quality_inspection_template`, `expected_start_date`, `expected_end_date`, `actual_start_date`, `actual_end_date`, `posting_date`, `project`, `status`.
- **Status literal**: `"Open" | "Work In Progress" | "Material Transferred" | "On Hold" | "Submitted" | "Cancelled" | "Completed"` ([:123](../../erpnext/manufacturing/doctype/job_card/job_card.py:123)).
- **Hooks implemented**:
  - `onload` at [:146](../../erpnext/manufacturing/doctype/job_card/job_card.py:146).
  - `on_discard` at [:152](../../erpnext/manufacturing/doctype/job_card/job_card.py:152).
  - `before_validate` at [:158](../../erpnext/manufacturing/doctype/job_card/job_card.py:158) — `set_wip_warehouse`.
  - `validate` at [:161](../../erpnext/manufacturing/doctype/job_card/job_card.py:161).
  - `on_update` at [:196](../../erpnext/manufacturing/doctype/job_card/job_card.py:196) — `validate_job_card_qty`.
  - `before_save` at [:771](../../erpnext/manufacturing/doctype/job_card/job_card.py:771) — `set_expected_and_actual_time`, `set_process_loss`.
  - `on_submit` at [:775](../../erpnext/manufacturing/doctype/job_card/job_card.py:775) — `validate_inspection`, `validate_transfer_qty`, `validate_job_card`, `update_work_order`, `set_transferred_qty`.
  - `on_cancel` at [:782](../../erpnext/manufacturing/doctype/job_card/job_card.py:782) — `update_work_order`, `set_transferred_qty`.
- **Key methods**:
  - `validate_time_logs`, `validate_on_hold`, `set_status` at [:1200](../../erpnext/manufacturing/doctype/job_card/job_card.py:1200), `validate_operation_id`, `validate_sequence_id`, `set_sub_operations`, `update_sub_operation_status`, `set_total_completed_qty_from_sub_operations`, `validate_work_order`, `set_employees`, `validate_semi_finished_goods` at [:178](../../erpnext/manufacturing/doctype/job_card/job_card.py:178), `validate_inspection` at [:786](../../erpnext/manufacturing/doctype/job_card/job_card.py:786), `validate_transfer_qty` at [:846](../../erpnext/manufacturing/doctype/job_card/job_card.py:846), `validate_job_card` at [:859](../../erpnext/manufacturing/doctype/job_card/job_card.py:859).
  - `set_manufactured_qty` at [:203](../../erpnext/manufacturing/doctype/job_card/job_card.py:203), `set_consumed_qty_in_job_card_item`, `set_transferred_qty` at [:1151](../../erpnext/manufacturing/doctype/job_card/job_card.py:1151), `set_transferred_qty_in_job_card_item` at [:1094](../../erpnext/manufacturing/doctype/job_card/job_card.py:1094), `set_transferred_qty_in_work_order` at [:1181](../../erpnext/manufacturing/doctype/job_card/job_card.py:1181).
  - `update_work_order` at [:936](../../erpnext/manufacturing/doctype/job_card/job_card.py:936), `update_work_order_data` at [:1008](../../erpnext/manufacturing/doctype/job_card/job_card.py:1008), `update_corrective_in_work_order` at [:978](../../erpnext/manufacturing/doctype/job_card/job_card.py:978), `validate_produced_quantity` at [:991](../../erpnext/manufacturing/doctype/job_card/job_card.py:991), `get_current_operation_data` at [:1048](../../erpnext/manufacturing/doctype/job_card/job_card.py:1048), `update_semi_finished_good_details` at [:964](../../erpnext/manufacturing/doctype/job_card/job_card.py:964).
  - `add_time_log`, `set_expected_and_actual_time` at [:901](../../erpnext/manufacturing/doctype/job_card/job_card.py:901), `set_process_loss` at [:927](../../erpnext/manufacturing/doctype/job_card/job_card.py:927).
- **Module-level entry points**: `make_time_log` at [:1577](../../erpnext/manufacturing/doctype/job_card/job_card.py:1577), `make_material_request` at [:1620](../../erpnext/manufacturing/doctype/job_card/job_card.py:1620), `make_stock_entry` at [:1651](../../erpnext/manufacturing/doctype/job_card/job_card.py:1651), `make_corrective_job_card` at [:1771](../../erpnext/manufacturing/doctype/job_card/job_card.py:1771), `get_operation_details` at [:1589](../../erpnext/manufacturing/doctype/job_card/job_card.py:1589), `get_operations` at [:1599](../../erpnext/manufacturing/doctype/job_card/job_card.py:1599), `get_job_details` at [:1722](../../erpnext/manufacturing/doctype/job_card/job_card.py:1722).
- **Exception classes**: `OverlapError`, `OperationMismatchError`, `OperationSequenceError`, `JobCardCancelError`, `JobCardOverTransferError`.
- **Stock / GL**: None. JC writebacks target `Work Order Operation` row (completed_qty, times, workstation) and Job Card Item (`transferred_qty`). Stock Entry citing the JC (`job_card` field) carries the real movement.

## Job Card Item

- **Path**: [erpnext/manufacturing/doctype/job_card_item/](../../erpnext/manufacturing/doctype/job_card_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Job Card.items`.
- **Key fields**: `item_code`, `source_warehouse`, `required_qty`, `transferred_qty`, `consumed_qty`, `uom`, `item_name`, `description`, `rate`, `amount`.

## Job Card Operation

- **Path**: [erpnext/manufacturing/doctype/job_card_operation/](../../erpnext/manufacturing/doctype/job_card_operation/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Job Card.sub_operations`.
- **Key fields**: `operation`, `sub_operation`, `time_in_mins`, `status`, `completed_time`, `completed_qty`.

## Job Card Scheduled Time

- **Path**: [erpnext/manufacturing/doctype/job_card_scheduled_time/](../../erpnext/manufacturing/doctype/job_card_scheduled_time/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Job Card.scheduled_time_logs`.
- **Key fields**: `from_time`, `to_time`, `time_in_mins`.
- **Populated by**: `WorkOrder.prepare_data_for_job_card` at [:1033](../../erpnext/manufacturing/doctype/work_order/work_order.py:1033) during capacity planning.

## Job Card Secondary Item

- **Path**: [erpnext/manufacturing/doctype/job_card_secondary_item/](../../erpnext/manufacturing/doctype/job_card_secondary_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Job Card.secondary_items`.
- **Key fields**: `item_code`, `qty`, `type`, `target_warehouse`.
- **Role**: For track-semi-finished-goods BOMs, records co-products produced by this Job Card.

## Job Card Time Log

- **Path**: [erpnext/manufacturing/doctype/job_card_time_log/](../../erpnext/manufacturing/doctype/job_card_time_log/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Job Card.time_logs` and `.employee` (TableMultiSelect).
- **Key fields**: `employee`, `from_time`, `to_time`, `time_in_mins`, `completed_qty`.
- **Entry point**: `make_time_log` at [job_card.py:1577](../../erpnext/manufacturing/doctype/job_card/job_card.py:1577) is the Start/Pause/Resume API.

## Downtime Entry

- **Path**: [erpnext/manufacturing/doctype/downtime_entry/downtime_entry.py:9](../../erpnext/manufacturing/doctype/downtime_entry/downtime_entry.py:9).
- **Inherits**: `Document`.
- **Submittable**: No.
- **Key fields**: `workstation`, `operator`, `from_time`, `to_time`, `downtime` (mins, auto-computed), `stop_reason: "" | "Excessive machine set up time" | "Unplanned machine maintenance" | "On-machine press checks" | "Machine operator errors" | "Machine malfunction" | "Electricity down" | "Other"`, `remarks`.
- **Hooks implemented**: `validate` at [:37](../../erpnext/manufacturing/doctype/downtime_entry/downtime_entry.py:37) — computes `downtime = (to_time - from_time) * 60`.
- **Role**: Input for Downtime Analysis / OEE reports. Not linked to Work Order / Job Card.
- **Stock / GL**: None.

## Manufacturing Settings

- **Path**: [erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:11](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:11).
- **Inherits**: `Document`.
- **Single**: Yes.
- **Key fields**: See [modules/manufacturing.md#settings-single](./manufacturing.md) for the full knob-vs-reader table.
- **Hooks implemented**: `before_save` at [:41](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:41) — `reset_values` (enforces mutually exclusive flags).
- **Module-level**: `get_mins_between_operations` at [:49](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:49), `is_material_consumption_enabled` at [:55](../../erpnext/manufacturing/doctype/manufacturing_settings/manufacturing_settings.py:55) (caches on `frappe.local`).

## Blanket Order

- **Path**: [erpnext/manufacturing/doctype/blanket_order/blanket_order.py:15](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:15).
- **Inherits**: `Document`. Located in the manufacturing module for historical reasons; functionally a cross-module DocType used by **both selling and buying**.
- **Submittable**: Yes.
- **Child tables**: `items: Table[BlanketOrderItem]`.
- **Key fields**: `blanket_order_type: "" | "Selling" | "Purchasing"`, `customer`, `supplier`, `from_date`, `to_date`, `order_no`, `tc_name`.
- **Hooks implemented**: `validate` at [:43](../../erpnext/manufacturing/doctype/blanket_order/blanket_order.py:43) — `validate_dates`, `validate_duplicate_items`, `validate_item_qty`, `set_party_item_code`.
- **Used by**: Sales Order (`Selling` type) and Purchase Order / Material Request (`Purchasing` type) — cross-link to [modules/selling-doctypes.md](./selling-doctypes.md) and [modules/buying-doctypes.md](./buying-doctypes.md).
- **Stock / GL**: None.

## Blanket Order Item

- **Path**: [erpnext/manufacturing/doctype/blanket_order_item/](../../erpnext/manufacturing/doctype/blanket_order_item/).
- **Inherits**: `Document` (child, `istable=1`).
- **Parent**: `Blanket Order.items`.
- **Key fields**: `item_code`, `qty`, `rate`, `uom`, `ordered_qty`, `party_item_code`, `description`.

## Stock Entry — manufacturing purposes

Stock Entry itself lives in the Stock module — see [modules/stock-doctypes.md#stock-entry](./stock-doctypes.md) for the full card. The manufacturing cascade uses four specific `purpose` values (defined in [stock_entry.py:564](../../erpnext/stock/doctype/stock_entry/stock_entry.py:564) and [stock_entry_type.json:20](../../erpnext/stock/doctype/stock_entry_type/stock_entry_type.json:20)):

| Purpose | Creator | Source → Target | Writeback |
|---|---|---|---|
| `Material Transfer for Manufacture` | `WorkOrder.make_stock_entry` ([work_order.py:2387](../../erpnext/manufacturing/doctype/work_order/work_order.py:2387)) or `JobCard.make_stock_entry` ([job_card.py:1651](../../erpnext/manufacturing/doctype/job_card/job_card.py:1651)) | source warehouse / `Work Order.source_warehouse` → `wip_warehouse` | `WorkOrder.material_transferred_for_manufacturing`, `additional_transferred_qty` if `is_additional_transfer_entry=1`; `JobCard.transferred_qty` + `JobCardItem.transferred_qty` when `job_card` set |
| `Manufacture` | `WorkOrder.make_stock_entry(purpose="Manufacture")` | `wip_warehouse` (or `source_warehouse` if `skip_transfer=1`) → `fg_warehouse`; scrap rows → `scrap_warehouse` | `WorkOrder.produced_qty` (from `is_finished_item=1` row's `transfer_qty`); triggers `update_planned_qty` + `update_production_plan_status` |
| `Material Consumption for Manufacture` | WO or direct | `wip_warehouse` → (none, consumption only) | `WorkOrder.required_items.consumed_qty` increments via `pro_doc.add_additional_items(self)` ([stock_entry.py:2117](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2117)); gated by `Manufacturing Settings.material_consumption` |
| `Disassemble` | `WorkOrder.make_stock_entry(purpose="Disassemble", source_stock_entry=<id>)` ([work_order.py:2431](../../erpnext/manufacturing/doctype/work_order/work_order.py:2431)) | `fg_warehouse` → `target_warehouse` (or `source_warehouse`); RMs come back | `WorkOrder.disassembled_qty` via `update_disassembled_order` at [stock_entry.py:2129](../../erpnext/stock/doctype/stock_entry/stock_entry.py:2129) |

Additional WO-related SE paths:

- `make_stock_return_entry` at [work_order.py:2803](../../erpnext/manufacturing/doctype/work_order/work_order.py:2803) — `Material Transfer for Manufacture` with `is_return=1`, returns unconsumed WIP back to source warehouse.
- `create_pick_list` at [work_order.py:2690](../../erpnext/manufacturing/doctype/work_order/work_order.py:2690) — creates a `Pick List` which eventually emits SE rows for material transfer.

`Send to Subcontractor` / `Subcontracting Delivery` / `Subcontracting Return` / `Receive from Customer` / `Return Raw Material to Customer` — listed for completeness of the literal, but covered in [flows/subcontracting-flow.md](../flows/subcontracting-flow.md).

GL on submit is composed in `StockController.make_gl_entries` — see [flows/accounting-flow.md](../flows/accounting-flow.md) for account-level detail and [flows/stock-flow.md](../flows/stock-flow.md) for the SLE write path.

## Related

- [modules/manufacturing.md](./manufacturing.md) — module overview.
- [flows/manufacturing-flow.md](../flows/manufacturing-flow.md) — end-to-end flow with Mermaid diagrams.
- [modules/stock-doctypes.md](./stock-doctypes.md) — Stock Entry reference card.
- [flows/stock-flow.md](../flows/stock-flow.md) — SLE write path.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL composition.
- [flows/selling-flow.md](../flows/selling-flow.md) — Sales Order → Production Plan.
- [flows/buying-flow.md](../flows/buying-flow.md) — Production Plan → PO (subcontract branch).
- [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) — subcontract sub-assembly execution.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy.
- [architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — event order reference.

## Changelog

- `2026-04-17` — initial version.
