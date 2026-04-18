---
description: Research a specific question about the ERPNext/Frappe codebase and save findings to docs/research/. TRIGGER on "how does X work", "trace flow Y", "where is Z implemented", "investigate behavior of...". SKIP for quick factual questions, refactoring, code changes, or general coding help.
argument-hint: <research question>
---

# Goal

Answer a research question about the codebase and save a reproducible findings document in `docs/research/`.

**Question:** `$ARGUMENTS`

# How to execute

1. If `$ARGUMENTS` is empty — do **not** invoke the agent. Ask the user for a concrete research question and wait.

2. If the user's intent is a quick one-shot answer with no need for a persistent document — tell them to ask directly instead of invoking this command. Proceed only when a saved document is genuinely desired.

3. Delegate to the `codebase-researcher` subagent via the Agent tool with `subagent_type: "codebase-researcher"`.

4. The prompt passed to the agent must include:
   - The exact research question verbatim.
   - Starting files/paths if the user mentioned any.
   - Explicit scope boundaries if the user mentioned them.
   - Language of the output document: match the language of the user's question; for mixed or code-only questions, default to English. Ask only if truly ambiguous.

5. **Follow-up questions on the same topic:** re-invoke the agent. The agent detects existing documents in `docs/research/` and will extend/correct the relevant one rather than create a duplicate.

6. After the agent returns, relay its final report to the user verbatim (path, summary, open questions). Do not duplicate findings inline, do not editorialize.

# Constraints

- Do **not** perform research or write documentation directly in this command.
- Do **not** invoke other specialized agents in parallel with `codebase-researcher`. The agent is free to spawn `Explore` subagents internally.
- Do **not** bypass or modify the agent's sign-off steps.
