---
name: skill-template-example
description: TEMPLATE — DO NOT INVOKE. Reference skeleton for building new skills (knowledge bases) for Claude Code. A skill is a self-contained reference document the model loads when a matching context arises — or when an agent Reads it by explicit path. This file is an inert reference; description begins with "TEMPLATE — DO NOT INVOKE" so the harness skip-matches normal requests.
---

# Skill Template: How to build a skill

<!--
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HOW TO USE THIS TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Decide the deployment shape (see "File layout" below):
   • Auto-registered skill  → `.claude/skills/<skill-name>/SKILL.md`
   • Reference-only skill   → `.claude/skills/<topic>/skill-<name>.md` (any filename)
2. Copy this file to the chosen path.
3. Update frontmatter: `name`, `description` (TRIGGER + SKIP).
4. Fill the 12 canonical sections with domain-specific detail.
5. Keep the skill **self-contained** — a reader should be able to operate in your
   domain with this file alone.
6. Remove all `<!-- -->` guidance comments before shipping.
7. Russian mirror at `.claude/skills/example/ru/skill-template.md`.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WHAT IS A SKILL (AND WHAT IT IS NOT)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A skill is a **self-contained knowledge base** in markdown form. It:
  • Captures expert domain knowledge the model can rely on during a task.
  • Lives in `.claude/skills/` so Claude Code (and your agents) can find it.
  • Is either *auto-registered* (strict filename) or *reference-only* (custom filename).

A skill is NOT:
  • An agent. Skills are PASSIVE references; agents are ACTIVE workers.
  • A command. Commands are thin delegation wrappers.
  • A one-off instruction. Skills should be reusable across sessions.
  • An opinion piece. Skills codify facts, canonical sources, and frameworks.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FILE LAYOUT — TWO DEPLOYMENT SHAPES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHAPE A — AUTO-REGISTERED (Claude Code convention)
  Path:     .claude/skills/<skill-name>/SKILL.md
  Filename: strictly "SKILL.md" (uppercase).
  Effect:   Harness scans and registers as skill `<skill-name>`; auto-matches by
            description in appropriate sessions; invocable via Skill tool.

SHAPE B — REFERENCE-ONLY (flat or hierarchical custom names)
  Path:     .claude/skills/<anything>/skill-<name>.md (any filename)
  Effect:   NOT auto-registered by the harness. Functions only when an agent
            Reads it via explicit path (e.g. Rule: "Read .claude/skills/legal/skill-legal-ru.md
            before writing the RU section").
  Pros:     Custom hierarchies possible; human-readable filenames; no accidental
            auto-matching on unrelated tasks.
  Cons:     No harness auto-trigger; no Skill tool invocation; no discovery by
            description-matching in fresh sessions.

WHICH TO CHOOSE
  • Auto-register (Shape A) when: skill is broadly applicable and the user benefits
    from it surfacing unprompted in relevant sessions.
  • Reference-only (Shape B) when: skill is load-bearing for a specific agent,
    agent's rules prescribe exact path reads, and you want to avoid the skill
    auto-firing on unrelated sessions.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CLAUDE CODE SKILL BEST PRACTICES — QUICK REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FRONTMATTER
  • `name`        — kebab-case; matches directory (Shape A) or chosen identifier (Shape B).
  • `description` — 1 paragraph, dense with keywords; starts with TRIGGER clauses and
                   ends with SKIP clauses. Determines auto-matching in Shape A.
  • Custom fields (optional): `version`, `updated`, `authoritative-sources`.

CANONICAL 12-SECTION STRUCTURE
  1. Jurisdictional/Domain Status and Legal/Conceptual Tradition.
  2. Core Statutes / Standards / Specs — with operational meaning per item.
  3. Contract / Interaction / Formation Framework (if applicable).
  4. Related / Adjacent Regulations or Standards.
  5. International / Cross-Domain Obligations.
  6. Case Law / Precedent / Reference Implementations + Court/Body Hierarchy.
  7. Authoritative Bodies — who publishes, who interprets.
  8. Canonical Sources (for WebFetch verification).
  9. Applying This Skill to a Standard Output Structure (the "how-to" section).
 10. Common Pitfalls — explicit list of mistakes to avoid.
 11. Output Constraints — citation style, identifier formats.
 12. Consequential Notes for {{Primary Project Context}} — what this skill means
     specifically for the project you are embedded in.

Not every skill needs all 12 — prune to the minimum useful set for your domain.
Legal skills typically use all 12. Technical skills may use 7-8. Reference ADR
(architecture decision record) skills may use 4-5.

SELF-CONTAINMENT RULE
  A skill file must be readable and operable with NO external context. A reader
  opens it, understands what it covers, and knows how to apply it. External
  references must be clearly marked — "(canonical source: URL)" or "see also
  .claude/skills/<other-skill>/SKILL.md".

TABLE USAGE
  Use markdown tables heavily for:
    • Statute/standard articles with one-line operational meanings.
    • Case citations with holding summaries.
    • Comparison matrices (e.g., compatibility, jurisdictions).
    • Canonical source URLs.

DISCLAIMER
  If the skill is advisory (legal / medical / safety), open section 1 with a
  disclaimer paragraph blockquote:
    > **Disclaimer.** This skill provides informational reference material ...

CITATION STYLE
  • Canonical identifier first, human description second.
    Good: "§ 106(3) US Copyright Act — right of distribution".
    Bad:  "right of distribution (§ 106(3))".
  • Preserve original scripts and canonical forms (Cyrillic statute names,
    italicized case names, SPDX IDs).
  • Mark uncertainty as `TODO(verify)` with the specific open question.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-->

> **Disclaimer.** {{domain-specific-disclaimer-if-applicable}}. Remove this block for non-advisory skills (e.g., purely technical references).

## 1. {{Domain}} Status and Tradition

<!--
OPEN WITH IDENTITY OF THE DOMAIN AND ITS TRADITION
  • Who/what is being covered? (Jurisdiction, standard body, protocol, etc.)
  • What tradition? (Civil law / common law / RFC / W3C / codified spec / etc.)
  • What treaties / parent standards does it participate in?
  • Language / canonical script considerations.
-->

### 1.1 Status

The **{{entity-name}}** is a {{type-of-entity}}. {{Key status facts — membership, ratification, applicable scope.}}

{{Parties to treaties / supersession relationships / coverage bounds.}}

### 1.2 Tradition

{{Which legal / technical / conceptual tradition does this domain operate under?}} {{How binding is precedent / convention here?}}

### 1.3 Language and citation

{{Official language(s) and script(s).}} {{Where canonical text lives.}} {{Preferred citation style.}}

## 2. Core Statutes / Standards / Specs

<!--
MOST IMPORTANT SECTION
  List the normative sources, then decompose each into a per-article table
  with one-line operational meanings for the primary project context.
-->

### 2.1 {{Primary normative source}}

Canonical text: {{URL-1}}, {{URL-2}}

**Structure:** {{brief structural note}}.

**Most-relevant provisions:**

| Reference | Heading | Operational meaning for {{primary-context}} |
|-----------|---------|---------------------------------------------|
| {{§/art/sec N}} | {{heading}} | {{what it practically means}} |
| {{§/art/sec N}} | {{heading}} | {{what it practically means}} |
| ... | ... | ... |

### 2.2 {{Secondary normative source — if applicable}}

{{Same pattern.}}

## 3. Contract / Interaction / Formation Framework

<!--
FOR DOMAINS WHERE AGENTS INTERACT OR AGREE
  Describe how interactions are constituted (contract formation, protocol
  handshake, standardization process, etc.).
-->

### 3.1 {{Framework name}}

{{Relevant articles / sections / specs.}} {{How formation / interaction works.}}

### 3.2 Interaction with {{primary-framework}}

{{Where this framework fills in / supersedes the primary one.}}

## 4. Related / Adjacent Regulations or Standards

| Instrument | Scope | Core relevance |
|------------|-------|----------------|
| {{name}} | {{short description}} | {{why it matters for this domain}} |
| {{name}} | {{short description}} | {{why it matters for this domain}} |

## 5. International / Cross-Domain Obligations

- **{{Treaty / standard 1}}** — {{what it imposes}}.
- **{{Treaty / standard 2}}** — {{what it imposes}}.

## 6. Case Law / Reference Implementations + Hierarchy

### 6.1 {{Forum / court / standards-body}} hierarchy

- **{{Top-level body}}** — {{what it does, binding scope}}.
- **{{Mid-level body}}** — {{what it does}}.
- **{{Local / first-instance body}}** — {{what it does}}.

### 6.2 Key {{cases / implementations / prior art}}

- ***{{Case / impl name}}***, {{canonical citation}}. **{{Significance in one sentence.}}** {{Holding / key point.}}

- ***{{Case / impl name}}***, {{canonical citation}}. {{Holding / key point.}}

### 6.3 Open / contested issues

{{What hasn't been settled.}} Mark `TODO(verify)` anywhere the skill asserts a settled position without supporting authority.

**Default framing for unsettled areas in downstream output:**
> "{{Template sentence for writing the (b) What-is-unsettled subsection}}"

## 7. Authoritative Bodies

| Body | Role | URL |
|------|------|-----|
| **{{Body-1 name}}** | {{what they do}} | {{URL}} |
| **{{Body-2 name}}** | {{what they do}} | {{URL}} |

## 8. Canonical Sources (for WebFetch verification)

| Source | URL | Use |
|--------|-----|-----|
| **{{Primary source}}** | {{URL}} | {{what to verify against it}} |
| **{{Commercial DB}}** | {{URL}} | {{when this is preferred over primary}} |
| **{{Case law search}}** | {{URL}} | {{how to find precedents}} |

## 9. Applying This Skill to {{Standard Output Structure}}

<!--
THE "HOW-TO" SECTION
  Gives the downstream agent a cookbook for producing its output using this skill.
  The most useful pattern from the legal skills is (a) / (b) / (c):
    (a) What holds — settled position.
    (b) What is unsettled — gaps, TODO(verify).
    (c) Practical obligation for {{primary-context}} — concrete action.

ADAPT THE TRIPLET TO YOUR DOMAIN:
  For technical: (a) What the spec requires. (b) What the spec leaves implementation-defined. (c) What the project must do.
  For legal:     (a) What statute/precedent holds. (b) What's unsettled. (c) Practical obligation.
  For operational: (a) Standard process. (b) Known-failure scenarios. (c) Project-specific mitigation.
-->

Canonical reasoning chain for the {{domain}} section of {{downstream-artifact}}:

**(a) {{What-holds-label}}.**

Anchor by issue:
- **{{Issue-type-1}}:** cite {{canonical-source-for-this-type}}.
- **{{Issue-type-2}}:** cite {{canonical-source-for-this-type}}.
- **{{Issue-type-3}}:** cite {{canonical-source-for-this-type}}.

**(b) {{What-is-unsettled-label}}.**

Standard gap-set to mention where applicable:
- {{gap-1}} — reference {{authority-that-would-resolve-it}}.
- {{gap-2}} — mark `TODO(verify)`.
- {{gap-3}}.

**(c) {{Practical-obligation-label}}.**

Phrase as concrete acts:
- "{{action-1}}"
- "{{action-2}}"
- "{{action-3}}"

## 10. Common Pitfalls

<!--
EXPLICIT LIST OF EASY-TO-MAKE ERRORS
  Each pitfall: one line, "Do not confuse X with Y" or "Do not extend rule A to
  domain B" or "Do not rely on source C which has been superseded".
  Keep to 10-20 items.
-->

1. **{{Do-not-confuse-statement-1}}.** {{Why it matters.}}
2. **{{Do-not-confuse-statement-2}}.** {{Why it matters.}}
3. **{{Do-not-extend-rule-statement}}.** {{Why.}}
4. **{{Superseded-source-warning}}.** {{Current reference.}}
5. **{{Jurisdictional / scope misunderstanding}}.** {{Correct framing.}}
6. ...

## 11. Output Constraints

- **Citations:** use canonical form — "{{canonical format 1}}", "{{canonical format 2}}".
- **Case names:** italicise; include reporter + page + court + year.
- **Identifiers:** SPDX in canonical form; {{other-identifier-types}} in canonical form.
- **Original script:** preserve Cyrillic / non-Latin where source is canonical in that form.
- **Never predict** outcomes; describe what source says.
- **Mark `TODO(verify)`** for any unsettled point; state the specific open question.
- {{Any-domain-specific-output-rule}}.

## 12. Consequential Notes for {{Primary Project Context}}

<!--
PROJECT-SPECIFIC SHIM SECTION
  Translates general domain knowledge into concrete implications for the project
  this skill lives in. For legal skills, this is "What this means for ERPNext
  deployed in this jurisdiction". For technical skills, "What this spec means
  for our codebase specifically".
-->

- **{{Scenario-1}}:** {{what this skill says applies here}}.
- **{{Scenario-2}}:** {{what this skill says applies here}}.
- **{{Edge-case-1}}:** {{how the domain treats it}}, mark `TODO(verify)` if uncertain.
- **{{Intersection-with-adjacent-domain}}:** {{where this skill ends and another begins}}. Out of scope for this skill; cross-reference `.claude/skills/<other-skill>/SKILL.md` if relevant.
- **{{Operational-action-item}}:** {{what the project team actually needs to do as a consequence}}.
