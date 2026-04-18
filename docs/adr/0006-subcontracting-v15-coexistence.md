---
title: is_old_subcontracting_flow=1 preserves legacy PO/PR-embedded flow alongside new SCO/SCR
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0006: `is_old_subcontracting_flow=1` flag preserves legacy PO/PR subcontracting alongside new Subcontracting Order / Receipt

## Context

Through ERPNext v14, subcontracting was modelled as a flag on the regular buy-side transactions: Purchase Order with subcontracting enabled, supplied raw materials carried in `Purchase Order Item Supplied`, receipt against `Purchase Receipt` with `Purchase Receipt Item Supplied`, and the `rm_supp_cost` value folded into the finished item's valuation rate. The semantics were workable but conflated two different supplier relationships ("buy a finished good" vs "send out raw materials, get back a converted good") into the same DocTypes.

v15 introduced dedicated DocTypes — `Subcontracting Order` and `Subcontracting Receipt` — with cleaner separation: explicit BOM linkage, a `Subcontracting BOM` master, separate supplier-warehouse SLE accounting, and a backflush model based on either BOM or material-transferred quantity rather than receipt-time supplied-item rows.

Switching every existing customer to the new flow on upgrade was not viable: production batches in flight, custom reports keyed on the legacy DocTypes, integrations posting to PO/PR, and operator muscle memory all argued against a hard cutover.

## Decision

Both flows are kept live indefinitely. The chosen flow per transaction is captured by the boolean `is_old_subcontracting_flow` on the parent document. A single controller — [`SubcontractingController`](../../erpnext/controllers/subcontracting_controller.py:26) — branches on the flag inside `__init__` to populate `self.subcontract_data` with the per-flow doctype names and field mappings:

```python
class SubcontractingController(StockController):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.get("is_old_subcontracting_flow"):
            self.subcontract_data = frappe._dict({
                "order_doctype": "Purchase Order",
                "order_field": "purchase_order",
                "rm_detail_field": "po_detail",
                "receipt_supplied_items_field": "Purchase Receipt Item Supplied",
                "order_supplied_items_field": "Purchase Order Item Supplied",
            })
        elif self.doctype == "Subcontracting Inward Order":
            ...
        else:
            self.subcontract_data = frappe._dict({
                "order_doctype": "Subcontracting Order",
                "order_field": "subcontracting_order",
                ...
            })
```

— see [`subcontracting_controller.py:26-56`](../../erpnext/controllers/subcontracting_controller.py:26).

Every method that needs to dispatch by flow re-checks `self.get("is_old_subcontracting_flow")` (e.g. [`set_consumed_qty_in_subcontract_order`](../../erpnext/controllers/subcontracting_controller.py:1144), and the qty-update path at [line 1244](../../erpnext/controllers/subcontracting_controller.py:1244)).

## Rationale

- **No data migration risk.** Existing PO/PR records remain valid; their controllers continue to behave as v14 did. No migrate-time data rewrite, no risk of breaking running production.
- **Cleaner new flow available immediately.** New installs (and customers willing to migrate manually) get the better-separated SCO/SCR flow without waiting for a deprecation cycle.
- **Single controller, one extension surface.** Custom apps and regional overrides target `SubcontractingController` once and get both flows for free, instead of having to subclass two parallel hierarchies.
- **Per-document flag, not per-site setting.** Two transactions in the same Buying module may use different flows; the controller dispatches per row.

## Consequences

- **Sticky-flag design.** Once set on a PO (or once a transaction is created from one), the flag persists. There is no supported mid-flight switch — converting an in-flight PO-based subcontracting batch to SCO is not modelled.
- **Divergent GL composition.** The two flows post different GL shapes:
  - **Legacy:** `rm_supp_cost` is folded into the finished item's valuation rate; the supplied raw materials are valued against the supplier warehouse on `make_rm_stock_entry` and consumed on PR submit.
  - **New:** `Subcontracting Receipt` posts a separate supplier-warehouse SLE leg, with `rm_supp_cost` and `service_cost` itemised on the SCR rather than absorbed into PR's valuation.
  Both flows are documented side-by-side in [docs/flows/subcontracting-flow.md](../flows/subcontracting-flow.md).
- **Documentation must always cover both.** Module overview ([docs/modules/subcontracting.md](../modules/subcontracting.md)) and DocType reference cards ([docs/modules/subcontracting-doctypes.md](../modules/subcontracting-doctypes.md)) carry sections for each branch.
- **Regional overrides target both flows.** Any country-specific subcontracting tax logic must be aware that the entry point can be PR submit or SCR submit.
- **Reports and queries that filter "is this subcontracting?" must check the flag *and* the doctype.** A query that only looks at SCO will miss legacy data; a query that only looks at PR will miss SCR-based receipts.
- **Backflush dispatch differs.** The legacy flow uses receipt-time supplied-item rows (`Purchase Receipt Item Supplied`) for consumption; the new flow uses [Buying Settings `backflush_raw_materials_of_subcontract_based_on`](../modules/subcontracting.md) (BOM vs Material Transferred). Same setting, two reading paths.
- **No deprecation timeline is committed.** The legacy flow is supported as a permanent coexistence, not a transitional bridge.

## Alternatives considered

- **Hard cutover at v15** — rejected: too risky for production data; would have required a data-migration patch that touched every PO/PR with subcontracting enabled.
- **Two parallel controller class hierarchies** — rejected: doubles the maintenance surface for future fixes (a regression in supplied-item handling would have to be patched in two places).
- **Per-site feature flag** — rejected: removes per-document choice; a site that needed both flows for different supplier relationships would be stuck.
- **Auto-migrate on cancel/recreate** — rejected: would silently rewrite operator intent; cancel + recreate already exists as a manual escape hatch.

## Citations

- [`erpnext/controllers/subcontracting_controller.py:26-56`](../../erpnext/controllers/subcontracting_controller.py:26) — `SubcontractingController.__init__` flag-driven dispatch into `subcontract_data`.
- [`erpnext/controllers/subcontracting_controller.py:1140-1158`](../../erpnext/controllers/subcontracting_controller.py:1140) — `set_consumed_qty_in_subcontract_order` per-flow doctype list (`["Purchase Receipt", "Purchase Invoice"]` vs `["Subcontracting Receipt"]`).
- [`erpnext/controllers/subcontracting_controller.py:1244`](../../erpnext/controllers/subcontracting_controller.py:1244) — flag check in qty-update path.

## Related docs

- [Subcontracting flow](../flows/subcontracting-flow.md) — both branches with sequence diagrams.
- [Subcontracting module](../modules/subcontracting.md) — `SubcontractingController` method reference and Buying Settings knobs.
- [Subcontracting DocType reference cards](../modules/subcontracting-doctypes.md) — per-DocType cards for SCO / SCR / SCBOM / SCIO + legacy `Purchase Order Item Supplied` / `Purchase Receipt Item Supplied`.
- [ADR 0001 — Immutable ledger](0001-immutable-ledger.md) — applies to both subcontracting flows on cancel.
