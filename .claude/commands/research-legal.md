---
description: Research a FOSS-licensing question about the ERPNext project and save a quad-jurisdictional (🇷🇺 RU / 🇺🇸 US / 🇪🇺 EU / 🇷🇸 RS) findings document to docs/legal/, maintaining the index in docs/legal/README.md. TRIGGER on "is license X compatible with GPL-3.0", "what obligations does dependency Y impose", "license audit of ...", "can we ship ERPNext with library Z". SKIP for quick one-off questions without a need for a persistent document, non-FOSS-licensing legal questions (employment, corporate, tax, trademark disputes, app-store review, general privacy/GDPR), refactoring, code changes, or enforcement/litigation advice.
argument-hint: <FOSS licensing question>
---

# Goal

Answer a FOSS-licensing question about the ERPNext project and save a reproducible quad-jurisdictional findings document in `docs/legal/`. Jurisdictional legal knowledge is sourced from four dedicated skills under `.claude/skills/` ([legal-ru](.claude/skills/legal-ru/SKILL.md), [legal-us](.claude/skills/legal-us/SKILL.md), [legal-eu](.claude/skills/legal-eu/SKILL.md), [legal-rs](.claude/skills/legal-rs/SKILL.md)) — the agent reads them before writing each jurisdiction section.

**Question:** `$ARGUMENTS`

# How to execute

1. If `$ARGUMENTS` is empty — do **not** invoke the agent. Ask the user for a concrete FOSS-licensing question and wait.

2. If the user's intent is a quick one-shot answer with no need for a persistent document — tell them to ask directly instead of invoking this command. Proceed only when a saved quad-jurisdictional document is genuinely desired.

3. If the question is clearly outside FOSS licensing (employment, corporate, tax, trademark disputes, app-store review, enforcement/litigation advice, general privacy/GDPR not tied to a specific license clause) — do **not** invoke the agent. Redirect the user to a qualified lawyer in the relevant jurisdiction.

4. Delegate to the `legal-licensing-researcher` subagent via the Agent tool with `subagent_type: "legal-licensing-researcher"`.

5. The prompt passed to the agent must include:
   - The exact FOSS-licensing question verbatim.
   - Starting files/paths if the user mentioned any (`LICENSE`, `pyproject.toml`, `package.json`, a specific dependency directory, `license_texts/`).
   - Explicit scope boundaries if the user mentioned them (e.g. "only Python deps", "only the core app, not regional modules").
   - Language of the output document: match the language of the user's question; for mixed or code-only questions, default to English. Ask only if truly ambiguous.

6. **Follow-up questions on the same topic:** re-invoke the agent. The agent detects existing documents in `docs/legal/` and will extend/correct the relevant one rather than create a duplicate.

7. After the agent returns, relay its final report to the user verbatim (path, summary, open questions). Do not duplicate findings inline, do not editorialize, do not add your own legal interpretation.

# Constraints

- Do **not** perform the legal research or write the document directly in this command — all analysis goes through the agent.
- Do **not** invoke other specialized agents in parallel with `legal-licensing-researcher`. The agent is free to spawn `Explore` subagents internally.
- Do **not** bypass or modify the agent's mandatory disclaimer, tri-jurisdictional structure, or sign-off steps.
- Do **not** interpret the agent's findings as legal advice when relaying them to the user — the disclaimer in every document is authoritative.
