---
description: Produce structured architecture documentation of the ERPNext/Frappe project via the architecture-researcher agent.
argument-hint: [scope — e.g. "accounts", "stock", "controllers", or "all"]
---

# Goal

Produce or extend architecture documentation in `docs/` for the requested scope.

**Scope:** `$ARGUMENTS`

# How to execute

1. If `$ARGUMENTS` is empty — do **not** invoke the agent yet. First ask the user which area to start with. Offer 3–4 prioritized options:
   - `architecture` — foundational docs (controllers, hooks, lifecycle). Recommended first.
   - `accounts` — accounting flow (GL, taxes, payments).
   - `stock` — stock flow (SL entries, batch/serial, warehouse).
   - `all` — walk through every area sequentially.

2. Once the scope is known, delegate the work to the `architecture-researcher` subagent via the Agent tool with `subagent_type: "architecture-researcher"`.

3. The prompt passed to the agent must include:
   - The exact scope.
   - An instruction to present a plan before writing more than 3 files and wait for user sign-off.
   - An instruction to update `CLAUDE.md` with pointers into `docs/` at the end.
   - Any additional constraints the user mentioned in this invocation.

4. After the agent returns, relay its final report to the user verbatim (created files, updated files, suggested next areas). Do not editorialize.

# Constraints for this command

- Do **not** write code or documentation directly in this command — it is the agent's job.
- Do **not** bypass or modify the agent's sign-off steps.
- Do **not** invoke any other agent for this work.
