---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: subcontracting
status: complete
related_docs:
  - ./subcontracting-doctypes.md
  - ../flows/subcontracting-flow.md
  - ./buying.md
  - ./stock.md
  - ../flows/buying-flow.md
  - ../flows/stock-flow.md
  - ../flows/accounting-flow.md
  - ../architecture/controllers.md
  - ../architecture/doctype-lifecycle.md
---

# Subcontracting module

> **TL;DR:** The Subcontracting module (`erpnext/subcontracting/`) owns the DocTypes for the new-flow outward cascade (`Subcontracting Order` → `Subcontracting Receipt`), the service-item/FG-item binding (`Subcontracting BOM`), and the inward customer-provided flow (`Subcontracting Inward Order`). The module **does not** own a controller of its own — its transactional DocTypes plug into [SubcontractingController](../../erpnext/controllers/subcontracting_controller.py:26) and [SubcontractingInwardController](../../erpnext/controllers/subcontracting_inward_controller.py:1), both living under `erpnext/controllers/`. The legacy flow's supplied-items child tables (`Purchase Order Item Supplied`, `Purchase Receipt Item Supplied`) are still in the `erpnext/buying/` module (cross-linked from [modules/buying-doctypes.md](./buying-doctypes.md)). This page describes what `SubcontractingController` contributes to the controller chain and how each method participates in the two coexisting flows.

## Scope of this document

- **Covered here:** module layout, `SubcontractingController` responsibilities, `SubcontractingInwardController` responsibilities, Buying Settings knobs that touch subcontracting, reports, regional hooks (none), scheduler jobs (none).
- **Covered by [subcontracting-doctypes.md](./subcontracting-doctypes.md):** per-DocType reference cards (`Subcontracting Order`, `Subcontracting Receipt`, `Subcontracting BOM`, `Subcontracting Inward Order`, all child tables, cross-linked legacy supplied-item child tables).
- **Covered by [flows/subcontracting-flow.md](../flows/subcontracting-flow.md):** end-to-end lifecycle diagrams for legacy and new flows, submit / cancel cascades, backflush modes, Stock-Entry purposes.

## Key files

- [erpnext/controllers/subcontracting_controller.py](../../erpnext/controllers/subcontracting_controller.py:26) — `SubcontractingController(StockController)`, 1,589 lines. Owns supplied-items build (BOM explosion + transferred-qty backflush), available-materials tracking, supplier-warehouse SLE, shared `make_rm_stock_entry`.
- [erpnext/controllers/subcontracting_inward_controller.py](../../erpnext/controllers/subcontracting_inward_controller.py:1) — `SubcontractingInwardController`, 1,136 lines. Parallel controller for customer-provided inward subcontracting.
- [erpnext/subcontracting/](../../erpnext/subcontracting/) — module root. `modules.txt` entry: `Subcontracting` ([erpnext/modules.txt](../../erpnext/modules.txt)).
- [erpnext/subcontracting/doctype/subcontracting_order/](../../erpnext/subcontracting/doctype/subcontracting_order/) — execution order (new flow outward).
- [erpnext/subcontracting/doctype/subcontracting_receipt/](../../erpnext/subcontracting/doctype/subcontracting_receipt/) — FG receipt (new flow outward).
- [erpnext/subcontracting/doctype/subcontracting_bom/](../../erpnext/subcontracting/doctype/subcontracting_bom/) — FG ↔ service-item binding.
- [erpnext/subcontracting/doctype/subcontracting_inward_order/](../../erpnext/subcontracting/doctype/subcontracting_inward_order/) — customer-provided inward order.
- [erpnext/buying/doctype/buying_settings/buying_settings.json](../../erpnext/buying/doctype/buying_settings/buying_settings.json:92) — "Subcontracting" tab settings.
- [erpnext/buying/doctype/purchase_order_item_supplied/](../../erpnext/buying/doctype/purchase_order_item_supplied/) — legacy-flow supplied-items on Purchase Order (still in buying module).
- [erpnext/buying/doctype/purchase_receipt_item_supplied/](../../erpnext/buying/doctype/purchase_receipt_item_supplied/) — legacy-flow supplied-items on Purchase Receipt.

## Directory layout

```
erpnext/subcontracting/
├── __init__.py
├── dashboard_chart/               — dashboard widgets
├── doctype/
│   ├── subcontracting_order/
│   ├── subcontracting_order_item/
│   ├── subcontracting_order_service_item/
│   ├── subcontracting_order_supplied_item/
│   ├── subcontracting_receipt/
│   ├── subcontracting_receipt_item/
│   ├── subcontracting_receipt_supplied_item/
│   ├── subcontracting_bom/
│   ├── subcontracting_inward_order/
│   ├── subcontracting_inward_order_item/
│   ├── subcontracting_inward_order_service_item/
│   ├── subcontracting_inward_order_received_item/
│   └── subcontracting_inward_order_secondary_item/
├── module_onboarding/             — onboarding config
├── number_card/                   — KPI cards
├── onboarding_step/               — individual onboarding steps
└── workspace/                     — workspace definition
```

Note: the **controllers** for these DocTypes live outside the module at [erpnext/controllers/subcontracting_controller.py](../../erpnext/controllers/subcontracting_controller.py:26) and [erpnext/controllers/subcontracting_inward_controller.py](../../erpnext/controllers/subcontracting_inward_controller.py:1). The legacy **supplied-items child tables** live at [erpnext/buying/doctype/purchase_order_item_supplied/](../../erpnext/buying/doctype/purchase_order_item_supplied/) and [erpnext/buying/doctype/purchase_receipt_item_supplied/](../../erpnext/buying/doctype/purchase_receipt_item_supplied/).

## Controller chain context

```
Document → StatusUpdater → TransactionBase → AccountsController → StockController
                                                                        ├─→ SellingController
                                                                        └─→ SubcontractingController
                                                                                    └─→ BuyingController
                                                                                    └─→ (Subcontracting Order / Receipt / Inward Order — direct)
```

See [architecture/controllers.md](../architecture/controllers.md) for the full hierarchy. The important points:

- `SubcontractingController` sits **above** `BuyingController`, not beside it. Every PO / PR / PI goes through `SubcontractingController.__init__` (which branches on `is_old_subcontracting_flow`) before reaching `BuyingController.__init__`.
- `Subcontracting Order`, `Subcontracting Receipt`, `Subcontracting Inward Order` inherit **directly** from `SubcontractingController`, skipping `BuyingController`. Their `validate` branch at [subcontracting_controller.py:67](../../erpnext/controllers/subcontracting_controller.py:67) takes the subcontracting-doctype path; non-subcontracting DocTypes fall through to `super().validate()` (`StockController.validate`).
- `SubcontractingInwardController` is a parallel branch (not derived from `SubcontractingController`) — it re-implements the supplied-items machinery for the customer-provided inward pattern.

## `SubcontractingController` — method-level reference

### `__init__` — flow dispatcher

[subcontracting_controller.py:27](../../erpnext/controllers/subcontracting_controller.py:27). Binds `self.subcontract_data` to a `frappe._dict` that carries field-name constants, branching on:

1. `self.is_old_subcontracting_flow` → `Purchase Order` + `po_detail` + legacy child tables.
2. `self.doctype == "Subcontracting Inward Order"` → `Subcontracting Inward Order` + `scio_detail` (no `_supplied_items_field` pair — inward has `received_items`).
3. Default (new outward flow) → `Subcontracting Order` + `sco_rm_detail` + new child tables.

Every downstream method reads `self.subcontract_data.order_doctype`, `order_field`, `rm_detail_field`, `receipt_supplied_items_field`, `order_supplied_items_field` — so the same code services both flows.

### `before_validate` + `validate`

[:58](../../erpnext/controllers/subcontracting_controller.py:58) + [:67](../../erpnext/controllers/subcontracting_controller.py:67). `before_validate` only runs for the three subcontracting DocTypes (SCO, SCR, SCIO); it removes empty rows in `service_items`, `items`, `supplied_items`, `received_items` and defaults `conversion_factor=1`.

`validate` has two branches:

- **Subcontracting DocTypes** (SCO, SCR, SCIO) → runs `validate_items` + `create_raw_materials_supplied_or_received` (with `raw_material_table="supplied_items"` or `"received_items"` for inward) + `set_valuation_rate_for_rm`.
- **Everything else** (PO, PR, PI) → `super().validate()` → falls through to `StockController.validate`, then `BuyingController.validate` is the one that explicitly calls `create_raw_materials_supplied` when `is_old_subcontracting_flow` ([buying_controller.py:62](../../erpnext/controllers/buying_controller.py:62)).

### `validate_items` and BOM gating

[:144](../../erpnext/controllers/subcontracting_controller.py:144). Per-row checks:

- `Item.is_stock_item=1` on every row.
- For non-secondary items: `Item.is_sub_contracted_item=1`; must link to a parent order row (PO Item / SO Item); `qty ≤ pending_qty` from `get_pending_subcontracted_quantity` ([:1371](../../erpnext/controllers/subcontracting_controller.py:1371)); `BOM.is_active=1`; `BOM.item == item.item_code`.
- Secondary items (scrap / by-product) on SCR clear their `bom`.

### `validate_rejected_warehouse`

[:111](../../erpnext/controllers/subcontracting_controller.py:111). Auto-fills `item.rejected_warehouse` from the header default; throws if any rejected row has no rejected warehouse or if the rejected warehouse equals the accepted warehouse.

### `set_valuation_rate_for_rm`

[:79](../../erpnext/controllers/subcontracting_controller.py:79). Only SCR. For each supplied-item, re-queries `get_incoming_rate` against `supplier_warehouse` with `qty = -consumed_qty` and, if the rate differs from `row.rate`, rewrites `row.rate` and `row.amount = consumed_qty * rate`. Triggers `calculate_items_qty_and_amount` when any rate changed. This is how SCR picks up the **current** valuation of RM at the supplier warehouse at posting time.

### Supplied-items build pipeline

Entry point: `create_raw_materials_supplied_or_received(raw_material_table)` at [:1112](../../erpnext/controllers/subcontracting_controller.py:1112) → `set_materials_for_subcontracted_items` at [:1103](../../erpnext/controllers/subcontracting_controller.py:1103) → `__prepare_supplied_or_received_items` at [:1052](../../erpnext/controllers/subcontracting_controller.py:1052).

`__prepare_supplied_or_received_items` is the orchestrator:

1. `initialized_fields` — zero `available_materials`, `__transferred_items`, `alternative_item_details`; read `backflush_based_on` from Buying Settings ([:286](../../erpnext/controllers/subcontracting_controller.py:286)).
2. `__get_subcontract_orders` — gather `order_field` references from `items` rows ([:292](../../erpnext/controllers/subcontracting_controller.py:292)).
3. `__get_pending_qty_to_receive` — query `<order_doctype> Item` for `qty - received_qty` per `(item_code, parent, bom)` ([:304](../../erpnext/controllers/subcontracting_controller.py:304)).
4. `get_available_materials` ([:472](../../erpnext/controllers/subcontracting_controller.py:472)) — build the `available_materials[(rm_item_code, main_item_code, order_name)] = {qty, serial_no[], batch_no{}, item_details, <rm_detail_field>s[]}` dict by:
   - `__get_transferred_items` ([:321](../../erpnext/controllers/subcontracting_controller.py:321)) — SUM `Stock Entry Detail.qty` where `purpose="Send to Subcontractor"` or `purpose="Material Transfer"` + `is_return=1` (negated).
   - `__update_consumed_materials` ([:407](../../erpnext/controllers/subcontracting_controller.py:407)) — subtract already-consumed qty from prior PRs (legacy) or SCRs (new flow) linked to the same order.
5. `__remove_changed_rows` ([:550](../../erpnext/controllers/subcontracting_controller.py:550)) — for non-order DocTypes (SCR, PR, PI): preserve supplied-item rows whose parent FG row is unchanged; drop the rest. Frees serial/batch bundles for dropped rows.
6. `__set_supplied_or_received_items` ([:945](../../erpnext/controllers/subcontracting_controller.py:945)) — the actual allocator. For each FG `items` row:
   - **SCO / SCIO / BOM-mode / return** → explode BOM via `_get_materials_from_bom` ([:573](../../erpnext/controllers/subcontracting_controller.py:573)) with `qty = qty_consumed_per_unit × received_qty × conversion_factor`, append supplied-item row, set serial/batch from available.
   - **Material-Transferred mode (non-order)** → iterate `available_materials` keys matching `(item_code, order_name)`, prorate via `__get_qty_based_on_material_transfer` ([:924](../../erpnext/controllers/subcontracting_controller.py:924)), append one row per transferred RM.
7. `__modify_serial_and_batch_bundle` ([:1003](../../erpnext/controllers/subcontracting_controller.py:1003)) — SCR-only. Reconciles existing `serial_and_batch_bundle` rows when `consumed_qty` changed.
8. `__set_rate_for_serial_and_batch_bundle` ([:991](../../erpnext/controllers/subcontracting_controller.py:991)) — SCR-only. Reads `Serial and Batch Bundle.avg_rate` into the supplied row's `rate`.

### `__add_supplied_or_received_item` — the row writer

[:708](../../erpnext/controllers/subcontracting_controller.py:708). Decides field composition per doctype:

- **Order doctype (SCO / SCIO / PO)** → sets `required_qty` + `amount = required_qty × rate` (inward skips `amount`).
- **Receipt doctype (SCR / PR / PI)** → sets `consumed_qty`, `required_qty = bom_item.required_qty or qty`, nulls `serial_and_batch_bundle`, links `order_field`. If `use_serial_batch_fields=1`, calls `__set_batch_nos` to stamp batches from available materials. If SCR and not `use_serial_batch_fields`, calls `__set_serial_and_batch_bundle` to create a fresh outward bundle at `supplier_warehouse` and then `set_rate_for_supplied_items` → `get_incoming_rate`.

### `set_rate_for_supplied_items`

[:836](../../erpnext/controllers/subcontracting_controller.py:836). For SCR supplied rows: calls `get_incoming_rate` with `qty = -consumed_qty` against the `supplier_warehouse`. Writes `rm_obj.rate`. `allow_zero_valuation=1` is set, so a zero rate is acceptable.

### `set_consumed_qty_in_subcontract_order`

[:1137](../../erpnext/controllers/subcontracting_controller.py:1137). Runs on SCR submit / PR submit (legacy) / PO validate. For each order-supplied-items row under the current `subcontract_orders`, re-SUM `consumed_qty` across downstream receipts and `frappe.db.set_value(self.subcontract_data.order_supplied_items_field, ..., 'consumed_qty', ...)` — writing back to `Subcontracting Order Supplied Item` or `Purchase Order Item Supplied`.

### `update_ordered_and_reserved_qty`

[:1160](../../erpnext/controllers/subcontracting_controller.py:1160). SCR-only. Walks `items.subcontracting_order` set; calls `SubcontractingOrder.update_ordered_qty_for_subcontracting(sco_item_rows)` + `update_reserved_qty_for_subcontracting(sco_item_rows)` — these refresh `Bin.ordered_qty` and `Bin.reserved_qty_for_sub_contracting` for the affected warehouses.

### `make_sl_entries_for_supplier_warehouse`

[:1179](../../erpnext/controllers/subcontracting_controller.py:1179). Appends one negative SLE per supplied-item row at `supplier_warehouse`:

```
actual_qty = -1 * consumed_qty
incoming_rate = item.rate if is_return else 0
dependant_sle_voucher_detail_no = item.reference_name  # links to parent FG item row
```

Called from SCR `update_stock_ledger` ([:1232](../../erpnext/controllers/subcontracting_controller.py:1232)) and from legacy PR `update_stock_ledger` ([buying_controller.py:872](../../erpnext/controllers/buying_controller.py:872)).

### `update_stock_ledger` (SCR)

[:1197](../../erpnext/controllers/subcontracting_controller.py:1197). SCR's override:

1. `update_ordered_and_reserved_qty` (see above).
2. For each FG `items` row (stock-item check): inward SLE at `warehouse` with `incoming_rate=item.rate`, `recalculate_rate=1`.
3. Rejected SLE at `rejected_warehouse` if `rejected_qty`.
4. `make_sl_entries_for_supplier_warehouse` — negative at `supplier_warehouse`.
5. `make_sl_entries` — persists everything through the SLE writer (see [flows/stock-flow.md](../flows/stock-flow.md)).

### `get_supplied_items_cost`

[:1239](../../erpnext/controllers/subcontracting_controller.py:1239). Legacy flow only. Called from [BuyingController.update_valuation_rate](../../erpnext/controllers/buying_controller.py:478):

- Iterates `supplied_items` rows matching `reference_name == item_row_id`.
- If `is_old_subcontracting_flow` and `reset_outgoing_rate=True` and RM is a stock item: recalls `get_incoming_rate` against `supplier_warehouse` for each consumed RM; updates `row.rate` if non-zero.
- Returns `sum(item.amount)` = total supplied-items cost for this FG row; the caller folds it into `item.valuation_rate`.

### `set_subcontracting_order_status`

[:1270](../../erpnext/controllers/subcontracting_controller.py:1270). SCR calls this during `on_submit` / `on_cancel` to cascade FG-receipt status to each linked SCO. SCO calls `update_status` itself.

### `calculate_additional_costs`

[:1281](../../erpnext/controllers/subcontracting_controller.py:1281). Distributes `additional_costs` rows (freight, duty, insurance) across FG-item rows:

- By `Amount`: proportional to `item.amount`.
- By `Qty`: equal `additional_cost_per_qty` per FG row.

Secondary items (`type` / `is_legacy_scrap_item`) are excluded from the base. The result lives in `item.additional_cost_per_qty` and is folded into `item.rate` by `calculate_items_qty_and_amount` on the SCO / SCR.

### `update_requested_qty`

[:1336](../../erpnext/controllers/subcontracting_controller.py:1336). SCO / SCR only. For each `items` row with a Material Request link, calls `MaterialRequest.update_requested_qty(mr_item_rows)` to refresh `Material Request Item.ordered_qty / received_qty` on the upstream MR (when the SCO was cut against an MR).

## Module-level module helpers

Outside the class body of `SubcontractingController` but in the same file:

- [get_item_details(items)](../../erpnext/controllers/subcontracting_controller.py:1355) — bulk `Item` lookup used by `make_rm_stock_entry`.
- [get_pending_subcontracted_quantity(doctype, name)](../../erpnext/controllers/subcontracting_controller.py:1371) — returns `{name: stock_qty - subcontracted_qty}` for each child row of a PO / SO.
- [make_rm_stock_entry(subcontract_order, rm_items=None, order_doctype="Subcontracting Order", target_doc=None)](../../erpnext/controllers/subcontracting_controller.py:1381) — whitelisted entry point. Builds a `Send to Subcontractor` Stock Entry from the order's `supplied_items`. Handles `over_transfer_allowance` (skips rows where `per_transferred >= 100 + allowance`).
- [add_items_in_ste(ste_doc, row, qty, rm_details, rm_detail_field, batch_no)](../../erpnext/controllers/subcontracting_controller.py:1505) — appends a reversed-direction Stock Entry Detail row (for returns).
- [make_return_stock_entry_for_subcontract(available_materials, order_doc, rm_details, order_doctype)](../../erpnext/controllers/subcontracting_controller.py:1525) — maps from order → Stock Entry with `purpose="Material Transfer"` + `is_return=1`, reversing `s_warehouse ↔ t_warehouse`.
- [get_materials_from_supplier(subcontract_order, rm_details, order_doctype)](../../erpnext/controllers/subcontracting_controller.py:1572) — whitelisted. Loads the order, rebuilds `available_materials`, then calls the return-SE mapper.

## `SubcontractingInwardController` summary

[erpnext/controllers/subcontracting_inward_controller.py](../../erpnext/controllers/subcontracting_inward_controller.py:1) is a **parallel** controller, not a subclass of `SubcontractingController`. It handles the customer-provided inward subcontracting pattern where the customer is the source of raw material. Its primary consumer is `Subcontracting Inward Order`.

Key differences from `SubcontractingController`:

- RM table is `received_items` (`Subcontracting Inward Order Received Item`), not `supplied_items`.
- Stock Entry purposes: `Receive from Customer`, `Return Raw Material to Customer`, `Subcontracting Delivery`, `Subcontracting Return`.
- Parent document is `Sales Order`; `service_items` link to `Sales Order Item`.
- Manufacturing happens through `Work Order` (created via `make_work_order` on the SCIO); no Subcontracting Receipt equivalent.
- Six percentage fields track progress: `per_raw_material_received`, `per_raw_material_returned`, `per_produced`, `per_process_loss`, `per_delivered`, `per_returned`.

See [flows/subcontracting-flow.md](../flows/subcontracting-flow.md#subcontracting-inward-order-customer-provided-inward) for the full inward cascade.

## Buying Settings relevant to subcontracting

From [buying_settings.json](../../erpnext/buying/doctype/buying_settings/buying_settings.json:92) (Subcontracting tab):

| Setting | Effect |
|---|---|
| `backflush_raw_materials_of_subcontract_based_on` | `BOM` (default) vs `Material Transferred for Subcontract`. Drives the backflush mode at SCR time. Legacy flow ignores this (forced to Material-Transferred semantics — see [subcontracting_controller.py:282](../../erpnext/controllers/subcontracting_controller.py:282)). |
| `over_transfer_allowance` | `%` cap for excess RM transfer vs BOM-required. Applied in `make_rm_stock_entry` ([:1422](../../erpnext/controllers/subcontracting_controller.py:1422)). |
| `validate_consumed_qty` | When backflush is `Material Transferred for Subcontract`, still re-enforce the BOM-required check on SCR submit ([subcontracting_receipt.py:605](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:605)). |
| `auto_create_subcontracting_order` | Auto-cuts an SCO at PO submit (new flow). See [purchase_order.py:648](../../erpnext/buying/doctype/purchase_order/purchase_order.py:648). |
| `auto_create_purchase_receipt` | Auto-cuts a PR at SCR submit so PO `per_received` stays in sync. See [subcontracting_receipt.py:955](../../erpnext/subcontracting/doctype/subcontracting_receipt/subcontracting_receipt.py:955). |

The Buying-Settings "Subcontracting" tab block starts at [buying_settings.json:92](../../erpnext/buying/doctype/buying_settings/buying_settings.json:92). The Stock-Settings `over_delivery_receipt_allowance` also applies — surfaced by the SCO / SCR `onload` handlers.

## Scheduler jobs touching subcontracting

**None.** A full scan of [erpnext/hooks.py](../../erpnext/hooks.py:1) shows no scheduler-event entries that target subcontracting DocTypes. The only cross-cutting tick that affects subcontracting indirectly is `erpnext.stock.reorder_item.reorder_item` ([hooks.py:486](../../erpnext/hooks.py:486)) which may create Material Requests with `material_request_type="Subcontracting"` — see [modules/stock.md](./stock.md#scheduler-jobs).

## Regional overrides

**None.** A full scan of [hooks.py:608-621](../../erpnext/hooks.py:608) (`regional_overrides`) shows no subcontracting method overrides. `@erpnext.allow_regional` is not used anywhere in `subcontracting_controller.py`, `subcontracting_inward_controller.py`, or the four top-level subcontracting DocTypes. Country-specific tax treatments still apply to the PO / PR / SCR via the generic [taxes-and-totals.md](../flows/taxes-and-totals.md) regional hook, but no subcontracting-specific override exists.

## Reports

The module ships dashboards / number cards under [erpnext/subcontracting/dashboard_chart/](../../erpnext/subcontracting/dashboard_chart/), [erpnext/subcontracting/number_card/](../../erpnext/subcontracting/number_card/). No standalone Frappe Reports live under the subcontracting module in core — reports touching subcontracting numbers (supplier scorecard, stock-to-receive) live under `erpnext/buying/report/` and `erpnext/stock/report/`.

## Portal / website integration

No portal routes in [hooks.py](../../erpnext/hooks.py:1) resolve to subcontracting DocTypes. Supplier-facing interactions go through the Purchase Order portal (see [flows/buying-flow.md](../flows/buying-flow.md)); Subcontracting Orders are not directly exposed to the supplier portal.

## Metadata registries

- `period_closing_doctypes` ([hooks.py:340](../../erpnext/hooks.py:340)) — includes `Subcontracting Receipt`, so PCV guards block SCR posting during the closed period.
- `accounting_dimension_doctypes` ([hooks.py:574-580](../../erpnext/hooks.py:574)) — includes `Subcontracting Order`, `Subcontracting Order Item`, `Subcontracting Receipt`, `Subcontracting Receipt Item` for dimension propagation.
- `auto_cancel_exempted_doctypes` ([hooks.py:418](../../erpnext/hooks.py:418)) — standard auto-cancel block applies (GL Entry, SLE, etc.); no subcontracting-specific exemption.

## Related

- [modules/subcontracting-doctypes.md](./subcontracting-doctypes.md) — per-DocType reference cards.
- [flows/subcontracting-flow.md](../flows/subcontracting-flow.md) — end-to-end flow with Mermaid diagrams.
- [modules/buying.md](./buying.md) — `BuyingController` and how it composes with `SubcontractingController` in the PR / PI valuation rate.
- [modules/buying-doctypes.md](./buying-doctypes.md) — legacy `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied` cards.
- [modules/stock.md](./stock.md) — SLE writer + `Bin.reserved_qty_for_sub_contracting`.
- [modules/stock-doctypes.md](./stock-doctypes.md) — Stock Entry reference card (subcontracting purposes).
- [flows/buying-flow.md](../flows/buying-flow.md) — Purchase Order cascade including the subcontracting branch at PO submit.
- [flows/accounting-flow.md](../flows/accounting-flow.md) — GL composition for SCR / legacy PR.
- [architecture/controllers.md](../architecture/controllers.md) — controller hierarchy placement.

## Changelog

- `2026-04-17` — initial version.
