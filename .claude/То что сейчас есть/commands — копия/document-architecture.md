---
description: Produce or extend structured architecture documentation of the ERPNext/Frappe project in docs/ via the architecture-researcher agent. TRIGGER on "document the architecture", "write docs for module X", "describe the controller hierarchy", "map the flow of Y", "create an ADR for Z". SKIP for research questions without persistent docs (use /research-codebase), code changes, refactoring, or project-management docs (roadmaps, PRDs).
argument-hint: <scope — e.g. "controllers", "accounts", "stock", "all">
---

# Goal

Produce or extend structured architecture documentation in `docs/` for the requested scope.

**Scope:** `$ARGUMENTS`

# How to execute

1. If `$ARGUMENTS` is empty — do **not** invoke the agent. Ask which area to start with. Offer 3–4 prioritized options:
   - `architecture` — foundational docs (controllers, hooks, lifecycle). Recommended first.
   - `accounts` — accounting flow (GL, taxes, payments).
   - `stock` — stock flow (SL entries, batch/serial).
   - `all` — walk through every area sequentially (multiple sessions).

2. If the user's intent is a one-shot research answer with no need for persistent architecture docs — point them at `/research-codebase` instead. Proceed only when structured architecture documentation is genuinely desired.

3. Delegate to the `architecture-researcher` subagent via the Agent tool with `subagent_type: "architecture-researcher"`.

4. The prompt passed to the agent must include:
   - The exact scope.
   - Any additional constraints mentioned by the user.
   - Language of the documentation: match the language of the user's request; for mixed or code-only requests, default to English. Ask only if truly ambiguous.
   - Instruction to present a plan before writing any file and wait for sign-off if the plan creates >1 file.
   - Instruction to update `CLAUDE.md` and `docs/README.md` at the end.

5. **Follow-up requests on the same scope:** re-invoke the agent. The agent detects existing documents in `docs/` and will extend/correct them in place rather than overwrite or duplicate.

6. After the agent returns, relay its final report to the user verbatim (created files, updated files, suggested next areas). Do not duplicate content inline, do not editorialize.

# Constraints

- Do **not** write code or documentation directly in this command.
- Do **not** invoke other specialized agents in parallel with `architecture-researcher`. The agent is free to spawn `Explore` subagents internally.
- Do **not** bypass or modify the agent's sign-off steps.
