---
description: Research the ERPNext/Frappe codebase and produce a dated findings document via the codebase-researcher agent.
argument-hint: [research question or area — e.g. "how GL entries are created on Sales Invoice submit"]
---

# Goal

Answer a research question about the codebase and save a reproducible findings document in `docs/research/`.

**Question:** `$ARGUMENTS`

# How to execute

1. If `$ARGUMENTS` is empty — do **not** invoke the agent yet. Ask the user for their research question or area of interest and wait for a concrete input.

2. Once the question is known, delegate the work to the `codebase-researcher` subagent via the Agent tool with `subagent_type: "codebase-researcher"`.

3. The prompt passed to the agent must include:
   - The exact research question verbatim.
   - Starting files/paths if the user mentioned any.
   - Explicit scope boundaries if the user mentioned them.
   - Language of the output document: match the language of the user's question; if mixed or unclear, ask before invoking.

4. After the agent returns, relay its final report to the user verbatim (the path of the created file, the summary, open questions). Do not duplicate the findings in-line, do not editorialize.

# Constraints for this command

- Do **not** perform research or write documentation directly in this command — it is the agent's job.
- Do **not** bypass or modify the agent's sign-off steps.
- Do **not** invoke any other agent for this work.
