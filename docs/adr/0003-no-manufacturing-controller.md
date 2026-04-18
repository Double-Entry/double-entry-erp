---
title: Manufacturing DocTypes extend Document directly; Stock Entry carries GL/SLE
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0003: Production Plan / Work Order / Job Card / BOM extend `Document`; Stock Entry carries GL/SLE

## Context

ERPNext's transactional DocTypes generally inherit through a controller chain — `StatusUpdater → AccountsController → StockController → SellingController / SubcontractingController / BuyingController` (see [docs/architecture/controllers.md](../architecture/controllers.md)). The chain provides shared behaviour for ledger writes, tax calculations, status propagation, and stock movement.

The Manufacturing module ships four lifecycle DocTypes — Production Plan, Work Order, Job Card, BOM — plus Stock Entry as the actual material-movement carrier. The question at module design time was: should the manufacturing DocTypes participate in the controller chain (and so own GL/SLE writes themselves), or stay pure orchestration objects?

## Decision

Manufacturing's four lifecycle DocTypes extend `Document` directly:

- [`WorkOrder(Document)`](../../erpnext/manufacturing/doctype/work_order/work_order.py:69)
- [`JobCard(Document)`](../../erpnext/manufacturing/doctype/job_card/job_card.py:61)
- [`ProductionPlan(Document)`](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39)
- [`BOM(WebsiteGenerator)`](../../erpnext/manufacturing/doctype/bom/bom.py:105) (`WebsiteGenerator` itself extends `Document`)

None of them inherit from `StockController` or `AccountsController`. All material-movement and GL impact for manufacturing flows through **Stock Entry** — which *does* extend `StockController` — using purpose codes `Material Transfer for Manufacture`, `Manufacture`, `Material Consumption for Manufacture`, and `Disassemble`.

This is documented in [docs/modules/manufacturing.md](../modules/manufacturing.md) (controller-posture section) and [docs/flows/manufacturing-flow.md](../flows/manufacturing-flow.md).

## Rationale

- **Single responsibility.** Manufacturing primitives are orchestration: aggregating demand (Production Plan), tracking commitment and progress (Work Order), recording shop-floor time and operations (Job Card), and modelling assembly structure (BOM). They do not themselves move stock or post to the GL.
- **No duplication of ledger logic.** Centralising GL/SLE in Stock Entry means there is one tested, regional-override-aware code path for valuation, perpetual-vs-periodic GL bridging, batch/serial bundle handling, and reposting. WO/JC/PP do not need to re-implement any of it.
- **Reposting works through SE.** [`Repost Item Valuation`](../modules/stock-doctypes.md) only knows about Stock Entry / DN / PR / SR / SCR — it does not need to understand WO or JC. A backdated cost change propagates through SE rebuilds without touching manufacturing orchestration.
- **Cancel cascade via status propagation, not ledger reversal.** Cancelling a WO does not write reverse SLE/GL because the WO never wrote any. The associated SE is cancelled separately, which in turn triggers the standard SLE/GL reverse path (see [ADR 0001](0001-immutable-ledger.md)). WO status is updated via `status_updater[]` (see [ADR 0005](0005-status-updater-vs-doc-events.md)).

## Consequences

- **Work Order on its own posts no GL.** This is surprising to new engineers expecting a "manufacturing GL entry" on WO submit. There is none — GL only happens when the linked Stock Entry submits. Production cost rolls up via Stock Entry's `additional_costs` and the SE-side `expense_account` mapping.
- **Two-step lifecycle for material consumption.** A WO marked Complete with no SE is a status-only state; the financial reality only changes when SEs are submitted against it.
- **Job Card has no financial side.** It records operation time, employee, workstation, and quantity completed; payroll / cost-of-labour aggregation happens elsewhere (Project / Timesheet). Nothing in JC writes to a ledger.
- **BOM is a pricing/structure master, not a transaction.** BOM cost rollup runs through `BOM Update Log`'s level-wise scheduler ([docs/modules/manufacturing.md](../modules/manufacturing.md)) but never posts directly.
- **Subcontracting overlap is intentional.** When a manufacturing operation is subcontracted, the GL/SLE flow leaves manufacturing entirely and joins the subcontracting flow ([ADR 0006](0006-subcontracting-v15-coexistence.md)).

## Alternatives considered

- **WorkOrder extends `StockController`** — rejected: WO would need to either no-op `make_sl_entries` (confusing) or duplicate Stock Entry's logic for the consumption / production legs. Either way the SE step is still required for actual movement, so the extra layer adds nothing.
- **Synthetic auto-SE on WO submit** — rejected: removes operator control over timing, batching, and warehouse selection; would make backdated production unworkable.
- **Direct GL entries from WO** — rejected: bypasses Stock Entry's valuation logic, breaks reposting, and would require regional overrides to be re-registered against WO methods.

## Citations

- [`erpnext/manufacturing/doctype/work_order/work_order.py:69`](../../erpnext/manufacturing/doctype/work_order/work_order.py:69) — `class WorkOrder(Document)`.
- [`erpnext/manufacturing/doctype/job_card/job_card.py:61`](../../erpnext/manufacturing/doctype/job_card/job_card.py:61) — `class JobCard(Document)`.
- [`erpnext/manufacturing/doctype/production_plan/production_plan.py:39`](../../erpnext/manufacturing/doctype/production_plan/production_plan.py:39) — `class ProductionPlan(Document)`.
- [`erpnext/manufacturing/doctype/bom/bom.py:105`](../../erpnext/manufacturing/doctype/bom/bom.py:105) — `class BOM(WebsiteGenerator)`.

## Related docs

- [Manufacturing module](../modules/manufacturing.md) — controller-posture section and per-DocType notes.
- [Manufacturing flow](../flows/manufacturing-flow.md) — Production Plan → WO → JC → SE cascade.
- [Controller hierarchy](../architecture/controllers.md) — the chain manufacturing intentionally sits outside.
- [ADR 0001 — Immutable ledger](0001-immutable-ledger.md) — why the cancel cascade safely flows through SE.
