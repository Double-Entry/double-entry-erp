---
description: TEMPLATE — DO NOT INVOKE. Reference skeleton for building new slash-commands in Claude Code projects. A command is a thin delegation layer — it accepts user arguments, validates them, and routes the work to a specialized sub-agent. This file is an inert reference; its description begins with "TEMPLATE — DO NOT INVOKE" so the harness skip-matches normal user requests. Copy to .claude/commands/<your-command>.md to create a real command.
argument-hint: <arguments passed by user via /command-name>
---

<!--
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HOW TO USE THIS TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Copy to `.claude/commands/<your-command>.md`.
2. Replace frontmatter:
   - `description`: one-line, keyword-rich, includes TRIGGER + SKIP clauses.
   - `argument-hint`: describes what the user types after `/command-name`.
3. Fill the Goal, How to execute, Constraints sections.
4. Remove all `<!-- -->` annotations before shipping.
5. Russian mirror at `.claude/commands/example/ru/command-template.md`.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WHAT IS A COMMAND (AND WHAT IT IS NOT)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A command is a **thin delegation layer** invoked as `/<command-name>`. Its job is to:
  1. Accept and validate user arguments (`$ARGUMENTS`).
  2. Route the work to the right specialized sub-agent.
  3. Relay the sub-agent's report verbatim to the user.

A command is NOT:
  • A place to do the work yourself. If the work is substantive — delegate.
  • A place to bypass the agent's rules. Never "shortcut" the agent's sign-off.
  • A place to editorialize. Do not wrap the agent's report in commentary.
  • A place for multiple parallel agents. Let the agent decompose internally.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CLAUDE CODE COMMAND BEST PRACTICES — QUICK REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FRONTMATTER
  • `description` — 1 line, keyword-rich, TRIGGER + SKIP clauses for harness matching.
  • `argument-hint` — shown in slash-command autocomplete; describes expected input.
  • Subfolder `ru/<name>.md` produces `/ru:<name>` Russian variant.

THREE REQUIRED SECTIONS
  1. Goal — what the command accomplishes in 1-2 sentences; include `$ARGUMENTS`.
  2. How to execute — numbered steps, starting with input validation.
  3. Constraints — explicit prohibitions.

INPUT VALIDATION (FIRST STEP)
  • If `$ARGUMENTS` empty → do NOT invoke agent; ask user for concrete input; wait.
  • If user wants a one-shot answer without a persisted artifact → decline and tell them
    to ask directly instead of invoking command.
  • If question clearly out-of-scope → redirect without invoking agent.

DELEGATION TO SUB-AGENT
  • Use Agent tool with explicit `subagent_type: "<agent-name>"`.
  • Pass verbatim the user's question. No rewriting.
  • Include starting files/paths if user mentioned them.
  • Include scope boundaries if user set them.
  • Language policy: match user's question language; default English for mixed/code.

AFTER-AGENT BEHAVIOR
  • Relay agent's final report verbatim (path, summary, open questions).
  • Do not duplicate findings inline.
  • Do not editorialize.
  • Do not add interpretation (especially for legal / compliance / security).

GLOBAL DON'TS
  • Don't perform the work yourself.
  • Don't invoke other specialized agents in parallel (let primary agent decompose).
  • Don't bypass or modify the agent's sign-off steps.
  • Don't claim authority beyond what the agent's output legitimately provides.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-->

# Goal

{{One-to-two sentences describing what this command accomplishes. Must reference `$ARGUMENTS`.}}

**{{Argument-label}}:** `$ARGUMENTS`

<!--
Example Goal:
  Answer a research question about the codebase and save a reproducible findings document in `docs/research/`.

  **Question:** `$ARGUMENTS`
-->

# How to execute

<!--
STRUCTURE
  Numbered steps, starting with input validation. The last step is always "relay the
  agent's report verbatim". Keep each step short — commands are not programs; they
  are instructions for the model.
-->

1. If `$ARGUMENTS` is empty — do **not** invoke the agent. Ask the user for a concrete {{input-kind}} and wait.

2. If the user's intent is a quick one-shot answer with no need for a persistent artifact — tell them to ask directly instead of invoking this command. Proceed only when the persisted artifact is genuinely desired.

3. If the question is clearly {{out-of-scope-condition}} — do **not** invoke the agent. Redirect the user to {{alternative-path}}.

4. Delegate to the `{{agent-name}}` sub-agent via the Agent tool with `subagent_type: "{{agent-name}}"`.

5. The prompt passed to the agent must include:
   - The exact {{input-kind}} verbatim.
   - Starting files/paths if the user mentioned any.
   - Explicit scope boundaries if the user set them.
   - Language of the output: match the language of the user's question; for mixed or code-only questions, default to English. Ask only if truly ambiguous.

6. **Follow-up on the same topic:** re-invoke the agent. The agent detects existing artifacts and will extend/correct in place rather than create a duplicate.

7. After the agent returns, relay its final report to the user **verbatim** (path, summary, open questions). Do not duplicate findings inline. Do not editorialize. Do not add your own interpretation.

# Constraints

<!--
EXPLICIT PROHIBITIONS
  List what the command must never do. These mirror the agent's own rules to ensure
  the command layer doesn't accidentally undercut them.
-->

- Do **not** perform {{the-work-domain}} or write {{artifact-kind}} directly in this command — all substantive work goes through the agent.
- Do **not** invoke other specialized agents in parallel with `{{agent-name}}`. The agent is free to spawn generic sub-agents (e.g. `Explore`) internally.
- Do **not** bypass or modify the agent's mandatory steps (disclaimer, structure, sign-off).
- Do **not** interpret the agent's findings as {{higher-authority}} when relaying them — the disclaimer inside each artifact is authoritative.
