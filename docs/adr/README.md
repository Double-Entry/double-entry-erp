---
last_updated: 2026-04-18
commit: fbe976fb3b
scope: adr-index
status: complete
related_docs:
  - ../README.md
---

# Architecture Decision Records

This directory holds the load-bearing architectural decisions surfaced by [`docs/research/`](../research/) and the module / flow documentation. Each ADR records *why* a particular shape was chosen — including which alternatives were rejected and the consequences callers must live with.

## Convention

- **One decision per file.** ADRs are not change logs.
- **Numbered, zero-padded, kebab-slug filename.** `NNNN-<slug>.md` — for example, [`0001-immutable-ledger.md`](0001-immutable-ledger.md).
- **Frontmatter** carries `title`, `status`, `date`, `last_updated`, `commit`, `branch`. `status` is one of `Proposed`, `Accepted`, `Superseded by NNNN`.
- **Immutable once accepted.** A new decision that overrides an existing one creates a new ADR with `supersedes: NNNN` in frontmatter; the old ADR's status flips to `Superseded by MMMM`. Existing text is not edited.
- **Citations are mandatory.** Every architectural claim carries a `[name](path:line)` reference into source. ADRs are short pointers (target 80–150 lines), not restatements of flow / module docs.
- **Cross-link liberally.** ADRs reference flow, module, pattern, and architecture docs to keep the explanation distributed and discoverable.

## Section template

Each ADR uses the same five sections:

1. **Context** — what existed before; what problem this addresses.
2. **Decision** — the chosen approach in 2–4 sentences.
3. **Rationale** — why this over alternatives.
4. **Consequences** — positive + negative; what callers must do.
5. **Alternatives considered** — bullet list with one-line rejection reason each.

Plus **Citations** (`path:line` references) and **Related docs** (cross-links).

## Index

| ADR | Title | Status | Decision summary |
| --- | ----- | ------ | ---------------- |
| [0001](0001-immutable-ledger.md) | Immutable ledger via `auto_cancel_exempted_doctypes` and reverse entries | Accepted | GL Entry, SLE, PLE, Account Closing Balance are exempted from auto-cancel; cancel writes reverse rows with `is_cancelled=1` instead of mutating originals. |
| [0002](0002-regional-overrides-pattern.md) | `@erpnext.allow_regional` + `regional_overrides` registry over country subclasses | Accepted | Regionalization uses a hooks-dict + decorator pattern (per-company country routing, last-installed-app wins) instead of per-country subclasses or monkey-patching. |
| [0003](0003-no-manufacturing-controller.md) | Manufacturing DocTypes extend `Document` directly; Stock Entry carries GL/SLE | Accepted | Production Plan / Work Order / Job Card / BOM stay as orchestration objects; all stock movement and GL impact for manufacturing flows through Stock Entry, which does extend `StockController`. |
| [0004](0004-payments-app-dependency.md) | `payments` app installed before `erpnext` | Accepted | Gateway code was extracted to a standalone `payments` app reusable by other Frappe apps; ERPNext now depends on it (`bench get-app payments && bench get-app erpnext`). |
| [0005](0005-status-updater-vs-doc-events.md) | Declarative `status_updater[]` for cross-doc status propagation | Accepted | Cross-document cascades (qty / billed / delivered) use a class-attribute list-of-dicts consumed by `update_prevdoc_status`; `doc_events` is reserved for cross-cutting wildcards. |
| [0006](0006-subcontracting-v15-coexistence.md) | `is_old_subcontracting_flow=1` flag preserves legacy PO/PR-embedded flow alongside new SCO/SCR | Accepted | v15's Subcontracting Order / Receipt coexist with the legacy PO/PR-embedded flow indefinitely; a single `SubcontractingController` dispatches via `subcontract_data` based on the per-document flag. |

## Adding a new ADR

1. Pick the next free number (zero-padded, four digits).
2. Copy the section template above.
3. Cite at least 2 source files with `[name](path:line)`.
4. Cross-link to the relevant module / flow / pattern doc — do not restate.
5. Register in the index table above and in [`docs/README.md`](../README.md).
6. If superseding an existing ADR, set `supersedes: NNNN` in frontmatter and flip the older ADR's status to `Superseded by MMMM`.
