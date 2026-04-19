---
name: legal-eu
description: European Union FOSS-licensing legal knowledge base. Applicable EU directives, CJEU case law, national transpositions, authoritative bodies, and canonical sources for analyzing open-source license questions under EU jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇪🇺 EU section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under EU law and Member-State transpositions. SKIP for non-licensing EU legal questions (GDPR/privacy beyond license clauses, competition, tax, labor).
---

# Skill: legal-eu — European Union FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified lawyer admitted in the relevant EU Member State.

## 1. Legal Tradition

Mixed system. Copyright is governed by **EU directives** that Member States transpose into national law — so there is no single "EU Copyright Code". Directives set harmonized minimum standards; national implementations can differ (especially Germany, France). **CJEU (Court of Justice of the EU)** case law is **binding across all Member States** for interpreting directives — this is the strongest source of authority for cross-border FOSS questions.

## 2. Core Directives

### 2.1 Directive 2009/24/EC — Software Directive (codified)

Successor to Directive 91/250/EEC. Canonical text: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32009L0024

| Article | Subject | Notes |
|---------|---------|-------|
| Art. 1 | Object of protection | Programs protected as literary works per Berne Convention; expression only, not ideas/principles |
| Art. 2 | Authorship | Natural person or group; legal-person authorship permitted where national law allows |
| Art. 3 | Beneficiaries | Standard Berne protection + MS-national extensions |
| **Art. 4** | **Restricted acts** | Reproduction, translation/adaptation, distribution. Foundation of "what requires a license" |
| **Art. 5** | **Exceptions** | Lawful acquirer's rights: necessary use, backup copy, observation/study/testing of functioning |
| **Art. 6** | **Decompilation** | For interoperability — strict conditions; cannot be contractually waived (art. 8) |
| Art. 7 | Special protection measures | Against knowing circulation of infringing copies; anti-circumvention of TPMs |
| Art. 8 | Continued application of other legal provisions | And **non-waivability of arts. 5(2), 5(3), 6** — mandatory user rights |

### 2.2 Directive 2001/29/EC — InfoSoc Directive

General copyright harmonization. Canonical: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32001L0029

- Art. 2 — reproduction right.
- Art. 3 — communication to the public / making available right. **Key for SaaS/network-use analysis** (AGPL territory).
- Art. 4 — distribution right and its exhaustion.
- Art. 5 — exhaustive list of permitted exceptions.
- Art. 6 — TPM anti-circumvention.

### 2.3 Directive (EU) 2019/790 — DSM Directive

Digital Single Market copyright reform. Canonical: https://eur-lex.europa.eu/eli/dir/2019/790/oj

- Art. 3, 4 — text-and-data-mining exceptions. Relevant to training-data licensing debates (peripheral to core FOSS).
- Art. 15 — press-publisher right.
- Art. 17 — online content-sharing services (upload filters).

### 2.4 Directive 2004/48/EC — IP Enforcement Directive

Procedural rules: injunctions, evidence, damages, corrective measures. Relevant when FOSS enforcement is contemplated in any Member State.

### 2.5 Directive (EU) 2019/770 — Digital Content Directive

Consumer-contract rules for digital content and services. Generally carves out **free-of-charge software licensed under open-source terms** (recital 32) — important when arguing that FOSS distribution is not a "consumer contract" in the directive's sense.

## 3. National Transpositions — Notable Differences

### 3.1 Germany (DE)

- **UrhG §§ 69a–69g** — special regime for computer programs (transposing 2009/24/EC).
  - §69c — restricted acts.
  - §69d — mandatory exceptions (backup, observation, interoperability decompilation).
  - §69e — decompilation strict conditions.
  - **§69g(2)** — anti-waiver: §§69d(2), 69d(3), 69e are mandatory and contract clauses to the contrary are void.
- UrhG §31 — license agreements (general).
- UrhG §32 — equitable remuneration (mandatory for paid licenses; interacts oddly with gratuitous FOSS grants).
- **BGH jurisprudence:** *Half-Life 2*, *Welte v. Sitecom* (LG Frankfurt 2006) — first German decision enforcing GPL. Germany is historically the **most active GPL-enforcement jurisdiction** in the EU.

### 3.2 France (FR)

- **Code de la propriété intellectuelle:**
  - L.122-6 — droits patrimoniaux on software.
  - L.122-6-1 — lawful-user exceptions.
  - L.122-6-2 — decompilation.
- **CeCILL** licenses (CeCILL, CeCILL-B, CeCILL-C) — FR-drafted FOSS licenses designed for French-law compatibility; CeCILL is GPL-compatible.
- Cour de cassation / Paris Court of Appeal practice exists but sparse.

### 3.3 Netherlands (NL), Italy (IT), Spain (ES), Sweden (SE), Poland (PL)

Each transposes the Software Directive via its national copyright statute (Auteurswet, Legge sul diritto d'autore, LPI, Upphovsrättslagen, Prawo autorskie). Patterns are similar — MS-specific research needed only when jurisdiction-specific case law or statutory deviation matters.

### 3.4 Post-Brexit UK (for context)

UK is **no longer bound** by new CJEU case law (since 01.01.2021). Retained EU law governs under the European Union (Withdrawal) Act 2018 as amended. Pre-Brexit CJEU jurisprudence (*UsedSoft* etc.) remains persuasive. **Do not treat UK as EU in post-2020 analysis** — it is a separate jurisdiction with significant but diverging law. This skill **does not cover UK**.

## 4. Key CJEU Case Law

### 4.1 Software-Specific

- ***UsedSoft GmbH v. Oracle International Corp.***, C-128/11 (3 July 2012). **Foundational.** The distribution right under 2009/24/EC art. 4(2) is **exhausted** by the first authorised distribution, including **downloaded copies** — not only tangible media. Licensor cannot use copyright to block resale of "used" software licenses. Massive implication for FOSS distribution chain, though FOSS licenses typically permit redistribution anyway.

- ***Nintendo Co. v. PC Box Srl***, C-355/12 (23 Jan 2014). TPM (technical protection measure) circumvention is unlawful unless the measure disproportionately restricts lawful use. Relevant for GPL-3.0 §3 / DMCA-equivalent analysis under EU law.

- ***Top System SA v. État belge***, C-13/20 (6 Oct 2021). A lawful acquirer has the right to decompile under 2009/24/EC art. 5(1) to correct errors, even without the licensor's authorization. Strengthens mandatory-exception character of user rights.

- ***SAS Institute v. World Programming***, C-406/10 (2 May 2012). Functionality, programming language, and file formats are **not protected** by copyright; only expression of the program is. Limits the reach of "derivative work" claims to actual code copying.

### 4.2 Communication to the Public / Distribution

- ***Stichting Brein v. Ziggo (The Pirate Bay)***, C-610/15 (14 June 2017). Operating an indexing/torrent platform constitutes "communication to the public". Peripheral to pure license analysis.

- ***VG Bild-Kunst v. SPK***, C-392/19 (9 March 2021). Framing of copyright-protected content can constitute communication to the public if circumventing protective measures.

- ***Tom Kabinet***, C-263/18 (19 Dec 2019). UsedSoft doctrine of exhaustion does **not** extend to e-books — applies to software specifically. Limits cross-medium analogies.

### 4.3 Open Licenses — Direct CJEU Engagement

CJEU has **not yet ruled directly** on FOSS-license compatibility, copyleft enforcement, or GPL-specific questions. National-court decisions (esp. German) are the best EU-level proxy. Flag as `TODO(verify)` any claim that CJEU has settled a specific FOSS-license question.

## 5. Authoritative Bodies

| Body | Role | URL |
|------|------|-----|
| European Commission — DG CNECT | Copyright policy formulation | https://digital-strategy.ec.europa.eu/ |
| CJEU | Interpretation of directives; binding across MS | https://curia.europa.eu/ |
| EUIPO | EU trademark/design; **not copyright** | https://euipo.europa.eu/ |
| **FSFE** (Free Software Foundation Europe) | Advocacy, REUSE compliance initiative | https://fsfe.org/ |
| OpenForum Europe | Policy think-tank on open technology | https://openforumeurope.org/ |
| Per-MS: Deutscher Bundesgerichtshof (BGH), Cour de cassation (FR), etc. | National supreme-court IP interpretation | |

## 6. Canonical Sources (for WebFetch verification)

| Source | URL | Use |
|--------|-----|-----|
| EUR-Lex | https://eur-lex.europa.eu/ | Directive and regulation texts |
| CJEU curia | https://curia.europa.eu/ | Case-law search |
| FSFE REUSE | https://reuse.software/ | Practical compliance tooling (SPDX headers, dep5) |
| DE: gesetze-im-internet.de | https://www.gesetze-im-internet.de/urhg/ | UrhG full text |
| FR: Légifrance | https://www.legifrance.gouv.fr/ | Code de la propriété intellectuelle |
| SPDX | https://spdx.org/licenses/ | License identifier source of truth (shared with US skill) |

## 7. Applying This Skill to the (a)/(b)/(c) Structure

When drafting the 🇪🇺 EU section of a legal finding:

- **(a) What holds.** Anchor to Directive 2009/24/EC arts. 4–6 and the specific MS transposition if the question has a national flavor (often DE for GPL enforcement, FR for CeCILL questions). Cite CJEU: *UsedSoft* for distribution-exhaustion, *Top System* for decompilation rights, *SAS Institute* for functional-element non-protection. State which arts. are **non-waivable** (5(2), 5(3), 6 per art. 8).

- **(b) What is unsettled.** CJEU has not ruled on FOSS-specific copyleft enforcement — mark `TODO(verify)` for any claim of settled EU-wide position. National divergences (esp. DE vs FR vs NL) for specific clauses — flag with the MS name. Post-Brexit UK explicitly out of scope.

- **(c) Practical obligation for ERPNext.** Concrete actions: preserve license notices as required by each applicable license; include NOTICE/COPYING files in distributions; when distributing in the EU, respect MS consumer-law carve-outs (Directive 2019/770 recital 32 exemption for gratuitous OSS); for DE distribution, be aware that BGH treats GPL violations as both copyright and contract claims. For SaaS-only delivery (no conveyance of copies), GPL-family copyleft is **not** triggered — AGPL is needed if the concern is network use.

## 8. Common Pitfalls

- **Do not treat CJEU case law as covering everything** — many FOSS-specific questions are decided (if at all) at national level. When writing EU analysis, check if the position is uniform EU-wide or fragmented by MS.
- **UsedSoft applies to software only** (*Tom Kabinet* clarified this) — do not extend to e-books, music, or other digital content.
- **SaaS/network use ≠ distribution** in the Software Directive sense — communication to the public (InfoSoc art. 3) is a separate right; GPL copyleft does not trigger, but Directive 2019/770 and 2022/2065 (DSA) may apply contextually.
- **Mandatory user rights (Software Directive arts. 5(2), 5(3), 6)** — contract clauses that waive them are void under art. 8. FOSS licenses do not attempt this, but proprietary EULAs sometimes do.
- **Droit moral** (France) / **Urheberpersönlichkeitsrecht** (Germany) — inalienable moral rights interact with "no warranty" clauses; usually non-disruptive for FOSS but worth noting.
- **GDPR is separate** from copyright/licensing. Do not conflate license clauses with GDPR obligations unless a specific clause materially interacts (rare).

## 9. Output Constraints

- Directive citations: "Directive 2009/24/EC art. 5(3)" — keep the directive number and article form.
- CJEU case citations: "*UsedSoft*, C-128/11 (3 July 2012)" — italic short name, case number, date.
- National statute citations: "UrhG §69d(2)" (DE), "L.122-6-1 CPI" (FR).
- SPDX identifiers in canonical form.
- Do not predict CJEU outcomes on untested questions. Mark as `TODO(verify)` with the specific open question.
- When MS-level divergence matters, explicitly list which MS takes which position; do not flatten into a pan-EU generalization.
