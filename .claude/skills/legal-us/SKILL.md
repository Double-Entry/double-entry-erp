---
name: legal-us
description: United States FOSS-licensing legal knowledge base. Applicable federal copyright law, statute sections, case law, authoritative bodies, and canonical sources for analyzing open-source license questions under US jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇺🇸 US section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under US law. SKIP for non-licensing US legal questions (employment, tax, corporate, trademark disputes beyond IP/licensing).
---

# Skill: legal-us — United States FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified attorney admitted in the relevant US jurisdiction.

## 1. Legal Tradition

Common-law system. Federal copyright law **preempts** state-law copyright claims (17 U.S.C. § 301). Extensive case law — binding within its circuit, persuasive elsewhere. OSS licenses are enforceable as **conditions on copyright grants**, not just contracts (key distinction established in *Jacobsen v. Katzer*).

## 2. Core Statutes

### 2.1 17 U.S.C. — Copyright Act of 1976

Canonical text: https://www.copyright.gov/title17/ or https://www.law.cornell.edu/uscode/text/17

Sections most relevant to FOSS-licensing:

| Section | Subject | Notes |
|---------|---------|-------|
| § 101 | Definitions | "Computer program", "derivative work", "literary works" (programs fall here) |
| § 102 | Subject matter of copyright | Protection attaches on fixation; programs protected as literary works |
| § 103 | Compilations and derivative works | Foundational for copyleft-scope analysis |
| § 106 | Exclusive rights in copyrighted works | Reproduction, preparation of derivative works, distribution, public performance, public display |
| § 107 | Limitations: fair use | Four-factor test; narrow application to FOSS |
| § 109 | First sale doctrine | Distribution right exhaustion — interacts with GPL §10 / Apache §4 distribution |
| § 117 | Computer programs: limitations | Owner's right to make archival copy, essential-step adaptation, machine-maintenance — similar scope to EU Software Directive art. 5 |
| § 201 | Ownership of copyright | Work-made-for-hire; crucial for contributor licensing |
| § 203 | Termination of transfers | 35-year termination right — potential future disruption for very old license grants |
| § 301 | Preemption | Federal preemption of equivalent state-law rights |
| § 501–506 | Infringement and remedies | Statutory damages, injunction, attorneys' fees |

### 2.2 DMCA — 17 U.S.C. §§ 1201–1205

Anti-circumvention regime. Directly interacts with **GPL-3.0 §3 ("Protecting Users' Legal Rights From Anti-Circumvention Law")** — GPL-3.0 disclaims any power to restrict circumvention rights, and requires that conveyed works not be treated as "effective technological measures". Rarely litigated in FOSS context; concept-level relevance only.

### 2.3 Patent Act — 35 U.S.C.

Relevant to **patent-grant clauses** in FOSS licenses (Apache-2.0 §3, GPL-3.0 §11, MPL-2.0 §2.1):
- 35 U.S.C. § 271 — infringement.
- 35 U.S.C. § 287 — notice and marking.
- Defensive-termination clauses are contractual; their enforceability under US law is generally accepted but fact-specific.

## 3. Key Case Law

### 3.1 License Enforceability and Conditions vs Covenants

- ***Jacobsen v. Katzer***, 535 F.3d 1373 (Fed. Cir. 2008). **Foundational.** The Artistic License's attribution requirements are **conditions** on the copyright grant, not mere contractual covenants. Breach permits copyright-infringement remedies (statutory damages, injunction), not just contract damages. Applies to GPL-family licenses by clear extension.

- ***MDY Industries v. Blizzard Entertainment***, 629 F.3d 928 (9th Cir. 2010). Refined the condition-vs-covenant distinction: not every license restriction is a condition; a term is a condition only if it has a sufficient nexus to the licensor's exclusive rights under § 106. Impacts analysis of whether a specific FOSS-license clause can support a copyright claim.

### 3.2 GPL Enforcement

- ***SFLC / BusyBox cases*** (E.D.N.Y., 2007–2012). Multiple consent decrees; no contested final judgment. Established that GPL termination for non-compliance is practically enforceable via injunction.

- ***Versata Software v. Ameriprise***, No. 1:14-cv-12 (W.D. Tex. 2014). Live dispute over whether XimpleWare's GPL-licensed code in Versata's product forced GPL-3.0 on the combined work. Settled; no merits decision.

- ***Artifex Software v. Hancom***, No. 16-cv-1254 (N.D. Cal. 2017). Held that breach of GPL is actionable both in contract and copyright; Ghostscript dual-licensing context. Important precedent for dual-licensing commercial enforcement.

- ***Software Freedom Conservancy v. Vizio***, Super. Ct. Cal. 2021 (state court, remand from federal court 2022). Consumer third-party-beneficiary claim under GPL/LGPL for source-code access. Ongoing as of last check — watch for first-in-nation ruling on consumer standing.

### 3.3 Upstream Case Law — Historical

- ***SCO Group v. IBM***, N.D. Utah 2003–2021. SCO's UNIX/Linux derivative claims, ultimately dismissed/settled after nearly two decades. Not GPL-specific but shaped industry caution around derivative-work scope.

- ***Galoob v. Nintendo***, 964 F.2d 965 (9th Cir. 1992). Derivative-work definition: modification that "recasts, transforms, or adapts". Cited in FOSS-scope arguments.

## 4. Authoritative Bodies and Stewards

| Body | Role | URL |
|------|------|-----|
| US Copyright Office | Registration (optional), Copyright Office circulars | https://www.copyright.gov/ |
| **Free Software Foundation (FSF)** | Author/steward of GPL/LGPL/AGPL/FDL; authoritative interpretation via the **GPL FAQ** | https://www.gnu.org/licenses/gpl-faq.html |
| **Open Source Initiative (OSI)** | Maintains the **Open Source Definition**; approves licenses as "OSI Approved" | https://opensource.org/licenses |
| **SPDX Workgroup** (Linux Foundation) | Canonical license identifiers; source of truth for machine-readable license names | https://spdx.org/licenses/ |
| Software Freedom Law Center (SFLC) | Legal representation and guidance for FOSS projects | https://www.softwarefreedom.org/ |
| **Software Freedom Conservancy** | GPL-enforcement practice; stewards BusyBox/others | https://sfconservancy.org/ |
| Linux Foundation — OpenChain Project | Compliance standard (ISO/IEC 5230) | https://www.openchainproject.org/ |

## 5. Canonical Sources (for WebFetch verification)

| Source | URL | Use |
|--------|-----|-----|
| Copyright.gov | https://www.copyright.gov/title17/ | Official statute text |
| Cornell LII | https://www.law.cornell.edu/uscode/text/17 | Annotated statute browser |
| SPDX | https://spdx.org/licenses/ | Canonical license identifiers and full texts |
| GNU Licenses | https://www.gnu.org/licenses/ | GPL/LGPL/AGPL/FDL text + official FAQ |
| OSI | https://opensource.org/licenses | Approved-license list |
| SFLC | https://www.softwarefreedom.org/resources/ | Compliance guides |
| CourtListener | https://www.courtlistener.com/ | Free case-law search |
| PACER | https://pacer.uscourts.gov/ | Authoritative federal docket access |

## 6. Applying This Skill to the (a)/(b)/(c) Structure

When drafting the 🇺🇸 US section of a legal finding:

- **(a) What holds.** Anchor to § 106 exclusive rights + § 103 derivative-work scope. Cite *Jacobsen v. Katzer* for the license-as-condition doctrine. For specific clauses:
  - Attribution (e.g. Apache-2.0 §4.4, BSD §2): enforceable condition (*Jacobsen*).
  - Copyleft (GPL-family): conveyance triggers source-disclosure obligations; *Artifex* confirms both contract and copyright remedies.
  - Patent grants (Apache-2.0 §3, GPL-3.0 §11): generally enforceable under US contract law; scope of defensive-termination clauses is fact-specific but broadly accepted.
  - DMCA §3 GPL-3.0 interaction: doctrinally present but rarely litigated.

- **(b) What is unsettled.** Consumer third-party-beneficiary standing (*SFC v. Vizio* pending); interaction between arbitration clauses and GPL's §12 "No Surrender of Others' Freedom"; full scope of "derivative work" for dynamically-linked libraries (FSF and industry interpretations diverge, no controlling precedent). Mark these as `TODO(verify)` with the specific open question.

- **(c) Practical obligation for ERPNext.** Concrete actions: preserve copyright notices and NOTICE files on all distributions (Apache-2.0 §4); provide corresponding source or written offer when conveying binaries (GPL-3.0 §6); ensure Installation Information is provided for User Products (GPL-3.0 §6, anti-Tivoization) — relevant if ERPNext is bundled with embedded/appliance hardware; register copyright with US Copyright Office **before filing** an infringement suit (§ 411) if enforcement anticipated.

## 7. Common Pitfalls

- **Do not conflate** "derivative work" under § 101 with FSF's "combined work" concept. Courts define derivative work; FSF's definition is interpretive guidance, influential but not binding.
- **Do not assume** fair use protects modification and redistribution of GPL code — the four-factor test rarely favors commercial redistribution.
- **Distinguish** "distribution" (§ 106(3)) from "public display" (§ 106(5)); SaaS/network use generally does **not** trigger GPL §5 distribution obligations, which is why AGPL-3.0 exists.
- **State-law contract claims** are largely preempted by § 301 if they duplicate copyright rights; plead copyright infringement when the underlying grant-violation is at issue.
- **First sale (§ 109)** does not apply to licensed copies (*Vernor v. Autodesk*, 621 F.3d 1102 (9th Cir. 2010)) — relevant when user mentions "reselling" FOSS binaries.
- **Work-made-for-hire** — contributor copyright assignment under § 201(b) needs written instrument; oral understandings fail, which creates provenance risk for un-CLA'd FOSS contributions.

## 8. Output Constraints

- Citations in Bluebook-adjacent form: *Case Name*, volume Reporter page (Court Year) — e.g. "*Jacobsen v. Katzer*, 535 F.3d 1373 (Fed. Cir. 2008)".
- Statute citations: "17 U.S.C. § 106", never paraphrase the number.
- SPDX identifiers in canonical form (`GPL-3.0-or-later`, not "GPL3" or "GPLv3+").
- Do not predict how a court would rule. Describe what the statute and controlling case law say.
- Flag genuinely unsettled questions as `TODO(verify)` with the specific doctrinal gap named.
