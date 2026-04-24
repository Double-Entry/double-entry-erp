---
title: status_updater[] for cross-doc cascades; doc_events for cross-cutting concerns
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0005: Declarative `status_updater[]` for cross-doc status propagation

## Context

ERPNext's transaction graph is a cascade: Quotation → Sales Order → Delivery Note → Sales Invoice on the sell side, and Material Request → Purchase Order → Purchase Receipt → Purchase Invoice on the buy side. Each downstream document needs to update the parent's percent-complete, billed amount, delivered quantity, ordered quantity, etc. — and on cancel, undo the same writeback.

There are two structurally different places this could live:

1. In `hooks.py` as `doc_events` registrations (`"Delivery Note": {"on_submit": "...update_so_delivered_qty"}`).
2. As a declarative class attribute on the doctype controller (`status_updater = [{...}]`), consumed by a generic `update_prevdoc_status` walker.

Both work; the choice has long-term consequences for discoverability, cancel-symmetry, and module ownership.

## Decision

Cross-document status / qty / amount cascades use a **declarative `status_updater = [...]` list-of-dicts class attribute** on the source-side transaction controller. The base [`StatusUpdater.update_prevdoc_status`](../../erpnext/controllers/status_updater.py:191) consumes the list, walks each entry's `source_dt → target_dt` mapping, and updates the linked parent rows accordingly.

Examples in the codebase:

- [`SalesOrder.status_updater = [...]`](../../erpnext/selling/doctype/sales_order/sales_order.py:202) — updates Quotation Item.
- Same pattern on Delivery Note, Sales Invoice, Purchase Order, Purchase Receipt, Purchase Invoice, Material Request, Pick List, Packing Slip, Installation Note, Subcontracting Receipt — the full set is enumerated by grep against `status_updater = [` in [erpnext/](../../erpnext/) and lives in 12 source files.

`doc_events` in [`hooks.py`](../../erpnext/hooks.py) is reserved for **cross-cutting concerns** that are not semantically a parent/child status cascade:

- The wildcard SLA hook (`doc_events["*"]["validate"]` for Service Level Agreement, see [docs/modules/support.md](../modules/support.md)).
- Communication-side wiring into Issue / Prospect ([hooks.py:362-371](../../erpnext/hooks.py:362)).
- Contact / Lead post-processing ([hooks.py:399-401](../../erpnext/hooks.py:399)).
- Integration Request validation for Payment Request ([hooks.py:406-408](../../erpnext/hooks.py:406)).

## Rationale

- **Colocation.** The `status_updater` list lives next to the controller it describes; a developer reading [sales_order.py](../../erpnext/selling/doctype/sales_order/sales_order.py:202) sees what it updates without leaving the file. A `hooks.py` edit would scatter that knowledge.
- **Schema-typed.** Each dict has a known shape (`source_dt`, `target_dt`, `source_field`, `target_field`, `target_parent_dt`, `target_parent_field`, `join_field`, `target_ref_field`, `condition`, etc.). Misspellings are caught by the consuming walker, not silently dropped like a missing hook would be.
- **Survives subclassing.** Subclasses can extend the parent's list with extra entries — impossible with `hooks.py` registrations, which are global and singleton.
- **Cancel is symmetric.** The same dict drives both submit and cancel paths in `update_prevdoc_status`; debit + credit, plus + minus, are computed from the same source-of-truth. With `doc_events`, every submit handler needs a paired cancel handler, and divergence is a recurring bug class.
- **Single walker.** All cascades go through one tested code path — `update_prevdoc_status` and its helpers — instead of N hand-written submit handlers, each free to do its own thing.

## Consequences

- **`doc_events` is reserved for cross-cutting wildcards / cross-module wiring.** New cascades MUST follow the `status_updater[]` pattern. Adding a new entry to a controller is a one-line, in-file change; the cancel path is automatically covered.
- **The walker contract is sticky.** `update_prevdoc_status` is consumed by every transaction controller; changing its signature is a breaking change for the entire cascade graph and requires coordinated updates.
- **Discovery.** New engineers should grep `status_updater = [` to see every cross-doc cascade in the system. The 12 hits map exactly onto the selling and buying flows (see [docs/flows/selling-flow.md](../flows/selling-flow.md) and [docs/flows/buying-flow.md](../flows/buying-flow.md)).
- **Performance.** A submit triggers an UPDATE per `status_updater[]` entry against the parent. For the typical 1–3 entries this is cheap; for hand-written `doc_events` chains it is the same cost.
- **Custom apps that extend ERPNext should follow the pattern** — append to `status_updater[]` in a subclass via `override_doctype_class`, not register a parallel `doc_events` handler.

## Alternatives considered

- **All-`doc_events` registration in `hooks.py`** — rejected: scatters cascade knowledge away from the doctype it concerns, doubles the surface area (separate submit + cancel handlers), and is invisible to subclasses.
- **Imperative inline calls in `on_submit` / `on_cancel`** — rejected: every controller would re-implement the parent-walking logic; cancel symmetry would have to be hand-maintained per controller.
- **Database triggers / SQL constraints** — rejected: ERPNext deliberately keeps business logic in Python (testability, cross-database portability between MariaDB and Postgres, audit visibility).

## Citations

- [`erpnext/controllers/status_updater.py:191`](../../erpnext/controllers/status_updater.py:191) — `update_prevdoc_status` walker entry point.
- [`erpnext/selling/doctype/sales_order/sales_order.py:202`](../../erpnext/selling/doctype/sales_order/sales_order.py:202) — canonical `status_updater = [...]` example.
- [`erpnext/hooks.py:362-371`](../../erpnext/hooks.py:362) — `doc_events` for cross-cutting Communication wiring (counter-example: not a cascade).

## Related docs

- [Controller hierarchy](../architecture/controllers.md) — `StatusUpdater` is the bottom of the chain.
- [Selling flow](../flows/selling-flow.md) — `status_updater[]` contract end-to-end through Quotation → SO → DN → SI.
- [Buying flow](../flows/buying-flow.md) — same contract through MR → PO → PR → PI.
- [Hooks and overrides](../architecture/hooks-and-overrides.md) — the legitimate `doc_events` use cases.
