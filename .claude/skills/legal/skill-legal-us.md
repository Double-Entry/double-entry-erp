---
name: legal-us
description: United States FOSS-licensing legal knowledge base — detailed. Applicable federal copyright law, DMCA, patent regime, contract formation framework, state-law interactions, case law, authoritative bodies, and canonical sources for analyzing open-source license questions under US jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇺🇸 US section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under US law. SKIP for non-licensing US legal questions (employment, tax, trademark disputes beyond IP/licensing, pure consumer-protection matters).
---

# Skill: legal-us — United States FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified attorney admitted in the relevant US jurisdiction.

## 1. Jurisdictional Structure and Legal Tradition

### 1.1 Status and structure

**The United States of America** is a federal republic comprising 50 states, the District of Columbia, and several territories (Puerto Rico, Guam, US Virgin Islands, American Samoa, Northern Mariana Islands). **Copyright is exclusively federal** per the Copyright Clause (U.S. Const. art. I, § 8, cl. 8). **Patent law** is likewise exclusively federal. **Contract law**, trade secret law, and most commercial regulation are **state law**.

Treaties relevant to US FOSS analysis:
- **Berne Convention** (accession 01.03.1989 via Berne Convention Implementation Act).
- **TRIPS Agreement** (1995, via Uruguay Round Agreements Act — URAA).
- **WIPO Copyright Treaty (WCT)** and **WPPT** (1998 implementation via DMCA).
- **Universal Copyright Convention** (historically relevant, largely superseded by Berne accession).

### 1.2 Legal tradition

**Common-law system** with heavy reliance on case precedent (*stare decisis*). Federal case law on copyright is binding within its circuit; persuasive elsewhere. Supreme Court of the United States (SCOTUS) decisions are binding nationwide. State contract-law decisions bind state courts within their jurisdiction.

A central doctrinal feature for FOSS: **federal copyright preempts state-law claims** duplicating federal copyright rights (17 U.S.C. § 301). A FOSS-license violation is generally framed as **copyright infringement** (for scope-excess) AND/OR **contract breach** (for covenant violations), with the distinction drawn by *MDY Industries v. Blizzard Entertainment*.

### 1.3 Language

Official language of federal legal texts — **English**. Statutes published in the United States Code (U.S.C.) and Statutes at Large. Case citations follow the **Bluebook** or **ALWD Guide**.

## 2. Core Statutes

### 2.1 17 U.S.C. — Copyright Act of 1976

Canonical text: https://www.copyright.gov/title17/ (authoritative PDF) or https://www.law.cornell.edu/uscode/text/17 (browsable annotated). Amended multiple times; major updates include DMCA (1998), NET Act (1997), Family Entertainment and Copyright Act (2005), Music Modernization Act (2018).

Structure: Chapters 1–9 (substantive copyright), Chapter 10 (audio home recording), Chapter 11 (unauthorized recording), Chapter 12 (copyright management / anti-circumvention — DMCA §§ 1201-1205), Chapter 13 (vessel hulls).

**Sections most material to FOSS:**

| Section | Heading | Operational meaning for FOSS |
|---------|---------|------------------------------|
| § 101 | Definitions | Defines "computer program", "derivative work", "literary works" (programs fall here), "compilation", "transfer of ownership". Foundation for all terminology. |
| § 102(a) | Subject matter of copyright — in general | Original works of authorship fixed in any tangible medium. Protection automatic on fixation; no registration required. |
| § 102(b) | Exclusion | Ideas, procedures, processes, systems, methods of operation not protected. Basis for *SAS Institute v. WPL* — functionality unprotected. |
| § 103 | Subject matter: compilations and derivative works | Protection extends only to material contributed by author of compilation/derivative, not to preexisting material. |
| § 105 | Subject matter: United States Government works | US federal government works are NOT subject to copyright in the United States. Some FOSS contributions by federal employees fall here. |
| § 106 | Exclusive rights in copyrighted works | **Five exclusive rights:** (1) reproduction; (2) preparation of derivative works; (3) distribution; (4) public performance; (5) public display. License authorises acts within these rights. Scope excess → infringement. |
| § 106A | Visual Artists Rights Act (VARA) moral rights | Limited moral rights for visual art — narrow, **does not apply to software**. Contrast civil-law moral rights (broad, inalienable). |
| § 107 | Limitations: fair use | **Four-factor test:** (1) purpose and character; (2) nature of copyrighted work; (3) amount used; (4) effect on market. Courts assess holistically. Rarely protects commercial redistribution of FOSS; may apply to reverse engineering for interoperability (*Sega v. Accolade*). |
| § 108 | Libraries and archives | Narrow exceptions; largely irrelevant to FOSS. |
| § 109 | Limitations: effect of transfer of copy (first sale) | **First sale doctrine.** Owner of a lawfully made copy may sell/dispose of that copy without further permission. Subject to licensed-copy exception (*Vernor v. Autodesk*): software distributed under license rather than sold may evade first sale. |
| § 110 | Performance / display exemptions | Classroom, religious services, etc. Out of scope for FOSS. |
| § 111–122 | Various cable/satellite/broadcasting | Out of scope for FOSS. |
| § 117 | **Computer programs: limitations on exclusive rights** | **Owner-of-copy permissions:** (a)(1) copies essential to using the program with a machine; (a)(2) archival/backup copies; (b) maintenance/repair copies; (c) adaptations necessary for maintenance. Narrower than EU Software Directive art. 5 but similar purpose. Does NOT include decompilation for interoperability — that sits under fair use (§ 107). |
| § 201(a) | Ownership of copyright — initial | Vests in the author — the person who creates the work. Multiple contributors → joint work if intended to merge into inseparable whole; else derivative. |
| § 201(b) | Work made for hire | Employer is the author of WMFH unless contrary written agreement. **Default for employees creating within scope of employment.** For independent contractors, WMFH requires express written agreement AND the work must fit one of nine enumerated categories (commissioned audiovisual work, compilation, etc.) — software as such is NOT in the list, so ICs retain copyright absent assignment. |
| § 203 | Termination of transfers | **35-year termination right** — author can reclaim rights 35 years after grant, within a specific 5-year window. Cannot be contracted away. **Relevant for very old contributor grants** to FOSS projects — potential disruption on decades-long horizon. |
| § 204 | Execution of transfers of copyright ownership | Transfer of ownership must be in writing, signed by owner or agent. Non-exclusive licenses (most FOSS) are exempt from writing requirement (§ 204(a) in fine + case law). |
| § 301 | Preemption with respect to other laws | Federal copyright preempts equivalent state-law claims. State-law breach-of-contract claims not preempted if they include an "extra element" (e.g., promise of specific attribution), per *ProCD v. Zeidenberg* and subsequent cases. |
| § 408–412 | Registration | Registration optional for protection but **required to file infringement suit** (§ 411) and affects remedies (§ 412 — statutory damages and attorneys' fees unavailable for pre-registration infringement of published works not timely registered). |
| § 501 | Infringement of copyright | Any violation of § 106 or § 106A. |
| § 502 | Remedies — injunctions | Permanent and preliminary injunctions available. **Key remedy for FOSS enforcement** — can stop distribution of non-compliant work. |
| § 503 | Remedies — impounding and disposition of infringing articles | Seizure and destruction. |
| § 504 | Remedies — damages | (a) actual damages + profits OR (b) statutory damages. Statutory: $750–$30,000 per work; up to $150,000 for willful infringement. Timely registration required (§ 412). |
| § 505 | Remedies — costs and attorney's fees | Discretionary to court. |
| § 506 | Criminal offenses | Willful infringement for commercial advantage. Rarely invoked for civil licensing disputes. |
| § 512 | DMCA safe harbour for online intermediaries | Platform protection for hosting / transmission / caching / linking. Relevant to GitHub et al. when DMCA notices arrive against FOSS distributions. |
| § 1201–1205 | **Anti-circumvention (DMCA)** | Prohibits circumventing TPMs and trafficking in circumvention tools. **Interacts directly with GPL-3.0 §3** ("No Denying Users' Rights from Anti-Circumvention Law") — GPL-3.0 licensees cannot invoke DMCA against downstream users' tinkering. Triennial rulemaking exemptions by Librarian of Congress. |

### 2.2 Patent Act — 35 U.S.C.

Canonical text: https://www.uspto.gov/web/offices/pac/mpep/consolidated_laws.pdf or https://www.law.cornell.edu/uscode/text/35

Relevant for **patent-grant clauses** in FOSS licenses (Apache-2.0 §3, GPL-3.0 §11, MPL-2.0 §2.1):

| Section | Subject |
|---------|---------|
| § 101 | Patentable subject matter. Software patents exist despite *Alice Corp. v. CLS Bank* (2014) narrowing; abstract-idea doctrine. |
| § 154 | Term — 20 years from filing. |
| § 261 | Ownership; assignments. |
| § 271(a) | Infringement — making, using, selling, offering to sell, importing. |
| § 271(b) | Inducement to infringe. |
| § 271(c) | Contributory infringement. |
| § 287 | Limitation on damages — marking requirement. |
| § 284 | Damages — "reasonable royalty" floor. Enhanced (up to treble) for willfulness. |
| § 285 | Attorneys' fees in exceptional cases. |
| § 299 | Joinder of accused infringers (AIA). |

**Defensive-termination clauses** (Apache-2.0 §3 in fine, GPL-3.0 §11 ¶ 6) operate as contractual covenants. Their US enforceability is generally accepted but scope-specific and has been litigated more in patent-pool contexts than pure OSS contexts.

### 2.3 Lanham Act — 15 U.S.C. §§ 1051 et seq.

**Trademark** — peripheral to pure FOSS-license analysis but relevant where:
- FOSS project names (Linux®, Firefox®, Django®) are trademarks.
- Apache-2.0 §6 and similar clauses preserve trademark rights independent of copyright grant.
- Distribution of modified code under same project name may be trademark infringement even if copyright is compliant.

### 2.4 Uniform Computer Information Transactions Act (UCITA) — historical footnote

Proposed uniform law for software transactions, withdrawn by NCCUSL in 2003. **Adopted only in Virginia and Maryland; rejected by most states.** Not operative law elsewhere. Encountered in older literature; modern FOSS analysis ignores it.

### 2.5 Defend Trade Secrets Act — 18 U.S.C. § 1836

Federal trade-secret protection. Rarely material for FOSS (which is by definition disclosed), but relevant if a mixed proprietary/FOSS product is distributed.

## 3. Contract Formation Framework — state law, mostly common-law

### 3.1 General structure

Contract formation is **state law**. All 50 states largely follow common-law principles for service/license contracts (UCC Article 2 for "goods" — software's treatment oscillates; for pure software licenses most courts apply common law or UCC by analogy). Key doctrines:

- **Offer, acceptance, consideration.** Classic triad. Mutual assent objective test (not subjective).
- **Unilateral contract by performance.** FOSS licenses operate as unilateral offers accepted by performance (using the software on the license terms). Parallel to GPL-3.0 §9: "You are not required to accept this License in order to receive or run a copy ... by modifying or propagating ... you indicate your acceptance."
- **Consideration.** FOSS licenses lack monetary consideration; consideration is found either in (a) the act of using the software (*Jacobsen v. Katzer* approach treating license as condition on copyright grant, where consideration is less material), or (b) the mutual obligations under the license (attribution, source disclosure on redistribution).
- **Writing requirement.** Statute of Frauds in most states requires writing for contracts not performable within 1 year. FOSS licenses arguably performable indefinitely — Statute of Frauds issues mostly inapplicable because software-license acceptance rarely raises SoF concerns.

### 3.2 Browsewrap / Clickwrap / Shrinkwrap doctrines

For end-user license formation:
- **Clickwrap** (affirmative click on "I accept") — broadly enforceable (*Feldman v. Google*, *Nguyen v. Barnes & Noble*).
- **Shrinkwrap** (opening package) — enforceable per *ProCD v. Zeidenberg* (7th Cir. 1996) and *Hill v. Gateway 2000* (7th Cir. 1997).
- **Browsewrap** (continued use without affirmative click, notice via link) — enforceable only if conspicuous notice of terms AND user reasonable opportunity to see (*Specht v. Netscape*, 2d Cir. 2002, found insufficient notice).

FOSS licenses don't typically use any of these interfaces directly; they rely on the *Jacobsen v. Katzer* framework — license as condition on copyright grant, not consumer-contract formation.

### 3.3 Choice-of-law and forum

US state contract law offers parties broad freedom to designate governing law and forum, subject to Restatement (Second) § 187 rules on reasonable relationship. FOSS licenses rarely specify; absent clause, lex loci contractus or significant-relationship tests apply. For multi-state online distribution the outcome varies.

Federal copyright preempts state claims duplicating copyright rights; federal-question jurisdiction exists under 28 U.S.C. § 1338.

### 3.4 Unconscionability

Contract-of-adhesion issues under state law — FOSS licenses are adhesion contracts. Procedural unconscionability (form of presentation) and substantive unconscionability (one-sided terms) can void or limit provisions. Rarely applied to free-of-charge FOSS because absence of consideration from licensee undercuts oppression arguments.

### 3.5 Standard-Essential Patents and FRAND (contextual)

Not directly an FOSS matter, but relevant where an OSS project uses patent-encumbered standards. Antitrust / Sherman Act issues; decided by court rather than statute.

## 4. Related IP and Adjacent Statutes

| Statute | Core relevance |
|---------|-----------------|
| **Visual Artists Rights Act of 1990 (VARA)** — 17 U.S.C. § 106A | Limited moral rights. Does NOT apply to software; moral rights in the civil-law sense do not exist in US copyright for programs. |
| **Digital Millennium Copyright Act (DMCA)** — Public Law 105-304 | Title I: anti-circumvention (§§ 1201-1205). Title II: safe harbour (§ 512). GPL-3.0 §3 expressly disclaims any power to treat distributed work as "effective technological measure". |
| **Music Modernization Act 2018** | Irrelevant to FOSS. |
| **Section 230 Communications Decency Act** — 47 U.S.C. § 230 | Platform immunity for user content. Relevant to hosting FOSS repositories but not to license substance. |
| **Export Administration Regulations (EAR)** — 15 C.F.R. Parts 730-774 | Export controls. Publicly available FOSS generally EAR99 or License Exception TSU/ENC; cryptographic software may require notification (§ 742.15). Briefly relevant if an ERPNext dependency is encryption-heavy. |
| **International Traffic in Arms Regulations (ITAR)** — 22 C.F.R. Parts 120-130 | Very narrow; essentially only defense-articles software. Rarely intersects with commercial FOSS. |
| **Children's Online Privacy Protection Act (COPPA)** — 15 U.S.C. § 6501 | Privacy; not a licensing matter. |
| **California Consumer Privacy Act (CCPA) / CPRA** | Privacy, state-level; not a licensing matter. |
| **Uniform Trade Secrets Act** (adopted by most states) + **DTSA** (federal) | Trade secrets. Tangential to FOSS. |

## 5. International Obligations Affecting US FOSS Analysis

- **Berne Convention** — protects foreign-authored FOSS within the US on national-treatment basis; moral-rights minimum *does not* override US non-extension of moral rights to software (US scholars debate this; courts have not extended VARA).
- **TRIPS art. 10** — computer programs as literary works. Implemented via § 102.
- **WCT art. 8** — right of making available to the public (online distribution). Implemented via § 106(3) reproduction/distribution / § 106(5) public display, though courts continue to disagree on whether US has fully implemented the "making available" right as a standalone.
- **US–EU, US–UK bilateral agreements** — standard national-treatment and mutual recognition provisions.

## 6. Case Law and Authoritative Guidance

### 6.1 Court hierarchy

- **Federal district courts** (94 districts) — first-instance federal jurisdiction over copyright and patent actions.
- **Courts of appeals for the 12 regional circuits** — appellate; decisions binding within their circuit only. Notable circuits for IP:
  - **2d Circuit (NY)** — entertainment / publishing.
  - **9th Circuit (CA)** — tech hub; many FOSS-relevant decisions.
  - **Federal Circuit** — **exclusive appellate jurisdiction over patent appeals** AND appeals from ITC. Hears some copyright issues when bundled with patent. Decided *Jacobsen v. Katzer*.
- **Supreme Court of the United States (SCOTUS)** — discretionary review via writ of certiorari.
- **Court of Federal Claims** / **Court of International Trade** — peripheral.

### 6.2 Foundational FOSS case law

**License enforceability and conditions-vs-covenants:**

- ***Jacobsen v. Katzer***, 535 F.3d 1373 (Fed. Cir. 2008). **Foundational.** The Artistic License's attribution requirements were conditions on the copyright grant, not mere contractual covenants. Breach supports copyright-infringement remedies (injunction, statutory damages), not just contract damages. The Federal Circuit held: "Copyright holders who engage in open source licensing have the right to control the modification and distribution of copyrighted material." Applies by clear extension to all OSS licenses with attribution / notice / source-disclosure requirements.
- ***MDY Industries v. Blizzard Entertainment***, 629 F.3d 928 (9th Cir. 2010). Refined the doctrine: not every license restriction is a condition; a term supports a copyright claim only when it has "sufficient nexus to licensor's exclusive rights under § 106". Terms that are "separate covenants" (e.g. "do not charge a fee to distribute", but where fee-charging doesn't touch a § 106 right) support only breach-of-contract claims, not copyright. Impacts how each GPL clause is analyzed — attribution (§5) has clear § 106 nexus; some peripheral obligations may not.

**GPL enforcement:**

- ***SFLC / BusyBox cases*** (E.D.N.Y., 2007–2012). Multiple consent decrees against Verizon, Supermicro, Westinghouse Digital, and others. No contested final judgment, but practical effect: GPL termination for non-compliance is enforceable via preliminary injunction and settlement. Templates for GPL compliance programs trace to these cases.
- ***Versata Software v. Ameriprise***, No. 1:14-cv-12 (W.D. Tex. 2014). Dispute over whether XimpleWare's GPL-licensed XML parser in Versata's proprietary product forced Versata's product to GPL. Settled without merits decision.
- ***Artifex Software v. Hancom***, No. 16-cv-1254 (N.D. Cal. 2017). Held GPL breach actionable in BOTH contract and copyright. Ghostscript dual-licensing case — Hancom used Ghostscript under GPL without complying; Artifex pursued both tracks. Summary judgment denying dismissal of contract claim; case settled. Important precedent confirming dual tracking of GPL violations.
- ***Software Freedom Conservancy v. Vizio***, Super. Ct. Cal. (filed 2021; remanded from federal court 2022; ongoing as of last skill revision). Consumer third-party-beneficiary claim for access to GPL source code in a smart-TV firmware. First major attempt to establish consumer standing under GPL in the US. Key to watch: if successful, vastly expands the enforcer pool beyond copyright holders.

**Historical and doctrinal anchors:**

- ***SCO Group v. IBM***, N.D. Utah 2003–2021. SCO's long-running claims over UNIX-derived code in Linux, ultimately dismissed/settled after almost two decades. Not GPL-specific but shaped industry caution around derivative-work scope and provenance.
- ***Sega Enterprises v. Accolade***, 977 F.2d 1510 (9th Cir. 1992). Reverse engineering (disassembly) for interoperability is fair use under § 107. Foundation for the US fair-use basis for decompilation where the goal is interoperability with unprotected functional elements.
- ***Sony Computer Entertainment v. Connectix Corp.***, 203 F.3d 596 (9th Cir. 2000). Extended *Sega* — reverse engineering of PlayStation BIOS was fair use.
- ***Oracle America v. Google***, 141 S. Ct. 1183 (2021). **SCOTUS held Google's reimplementation of Java SE APIs in Android was fair use.** Narrow holding (specific to APIs, specific facts), but broadly reinforces that functional elements of software receive thin copyright protection and that transformative use weighs in favour of fair use. Important for FOSS clean-room reimplementations.
- ***Feist Publications v. Rural Telephone Service***, 499 U.S. 340 (1991). "Originality" as the touchstone of copyrightability. Mere compilation of facts (white pages) not protected. Impacts what can be copyrighted in a software project.
- ***Galoob v. Nintendo***, 964 F.2d 965 (9th Cir. 1992). Derivative-work definition: "recasts, transforms, or adapts". Game Genie that modified memory values of Nintendo games NOT a derivative work because the modification was ephemeral and not "fixed". Cited in FOSS-derivative-scope arguments.
- ***Vernor v. Autodesk***, 621 F.3d 1102 (9th Cir. 2010). Licensee-vs-owner distinction for first sale. Three factors: (1) licensor specifies transfer is license; (2) significant use/transfer restrictions; (3) further restrictions on copying. Typical FOSS licenses do not fit this framework since they grant broad permissions — less likely to foreclose first sale.
- ***ProCD v. Zeidenberg***, 86 F.3d 1447 (7th Cir. 1996). Shrinkwrap license enforceability; contract-not-preempted because of "extra element" (promise not to redistribute database). Foundational for software-license contract framework.
- ***Specht v. Netscape Communications***, 306 F.3d 17 (2d Cir. 2002). Browsewrap unenforceable absent conspicuous notice. Limits passive-acceptance theories.
- ***SAS Institute v. World Programming***, 64 F. Supp. 3d 755 (E.D.N.C. 2014), aff'd in part 874 F.3d 370 (4th Cir. 2017). Functional elements not protected; limits derivative-work reach to actual code copying. US parallel to CJEU *SAS Institute* (unrelated case, same name).

### 6.3 Ongoing / unsettled areas

- **Consumer standing to enforce GPL** — *SFC v. Vizio* outcome pending. Will dramatically affect enforcement landscape if plaintiff prevails.
- **Scope of "derivative work" for dynamic linking** — no controlling circuit decision directly addresses GPL's "combined work" theory. FSF interpretation (dynamic linking = combined work) vs industry practice (only static linking) divides commentators.
- **Software-as-a-service and AGPL** — AGPL §13 "network use" clause has not been contested in US courts. Scope and enforceability in cloud deployments untested.
- **Copyleft and API reimplementation** — *Oracle v. Google* answered fair-use question for API reimplementation but did not reach the underlying question whether an API is copyrightable at all. Unresolved at SCOTUS level.

**Default framing for the (b) "What is unsettled" subsection on any FOSS question in the US section:**
> "US case law establishes license enforceability as conditions on copyright grants (*Jacobsen v. Katzer*) and the condition-vs-covenant distinction (*MDY v. Blizzard*). Specific FOSS-license clauses not yet squarely adjudicated — notably consumer standing (*Vizio* pending), dynamic-linking scope of combined work, and AGPL §13 network-use enforcement — remain open."

## 7. Authoritative Bodies and Stewards

| Body | Role | URL |
|------|------|-----|
| **US Copyright Office** | Registration, Circulars, administrative rulemaking | https://www.copyright.gov/ |
| **US Patent and Trademark Office (USPTO)** | Patent/trademark registration, MPEP | https://www.uspto.gov/ |
| **Library of Congress — Register of Copyrights** | Oversees Copyright Office | https://www.copyright.gov/about/leadership.html |
| **SCOTUS** | Constitutional / statutory supremacy | https://www.supremecourt.gov/ |
| **Federal Circuit (CAFC)** | Exclusive appellate over patents | https://cafc.uscourts.gov/ |
| **Free Software Foundation (FSF)** | Author/steward of GPL/LGPL/AGPL/FDL; authoritative GPL FAQ | https://www.gnu.org/licenses/gpl-faq.html |
| **Open Source Initiative (OSI)** | Maintains Open Source Definition; approves licenses as "OSI Approved" | https://opensource.org/licenses |
| **SPDX Workgroup (Linux Foundation)** | Canonical machine-readable license identifiers | https://spdx.org/licenses/ |
| **Software Freedom Law Center (SFLC)** | Legal representation; compliance guides | https://www.softwarefreedom.org/ |
| **Software Freedom Conservancy** | GPL-enforcement practice; stewards BusyBox, Git, Samba and others; currently lead in *Vizio* | https://sfconservancy.org/ |
| **Linux Foundation — OpenChain Project** | Compliance standard ISO/IEC 5230:2020 | https://www.openchainproject.org/ |
| **Electronic Frontier Foundation (EFF)** | Advocacy on DMCA, user rights | https://www.eff.org/ |
| **Apache Software Foundation (ASF)** | Author of Apache License 2.0; ASF Legal FAQ | https://www.apache.org/legal/ |

## 8. Canonical Sources (for WebFetch verification)

| Resource | URL | Use |
|----------|-----|-----|
| **Copyright.gov Title 17** | https://www.copyright.gov/title17/ | Official statute text. |
| **Cornell LII — 17 U.S.C.** | https://www.law.cornell.edu/uscode/text/17 | Annotated statute browser. |
| **Cornell LII — 35 U.S.C.** | https://www.law.cornell.edu/uscode/text/35 | Annotated Patent Act. |
| **SPDX License List** | https://spdx.org/licenses/ | Canonical license IDs + full texts. |
| **GNU Licenses** | https://www.gnu.org/licenses/ | GPL/LGPL/AGPL/FDL + official FAQ. |
| **OSI Approved Licenses** | https://opensource.org/licenses | OSI-approved license list. |
| **Apache Legal FAQ** | https://www.apache.org/legal/ | Apache License interpretation. |
| **SFLC Resources** | https://www.softwarefreedom.org/resources/ | Compliance guides (e.g. A Practical Guide to GPL Compliance). |
| **Conservancy Compliance** | https://sfconservancy.org/copyleft-compliance/ | Community-standard GPL-compliance practices. |
| **CourtListener** | https://www.courtlistener.com/ | Free federal case-law search. |
| **PACER** | https://pacer.uscourts.gov/ | Authoritative federal docket access (paid). |
| **Justia US Law** | https://law.justia.com/ | Case-law with annotations (free). |
| **Westlaw / Lexis** | | Commercial primary authority databases (paid). |

## 9. Applying This Skill to the (a)/(b)/(c) Structure

Canonical reasoning chain for the 🇺🇸 US section of a legal finding:

**(a) What holds.**

Anchor by issue type:
- **FOSS license enforceability**: "Under *Jacobsen v. Katzer*, 535 F.3d 1373 (Fed. Cir. 2008), open-source license conditions with nexus to 17 U.S.C. § 106 rights are enforceable as copyright-infringement conditions."
- **Condition vs covenant distinction**: "*MDY Industries v. Blizzard*, 629 F.3d 928 (9th Cir. 2010) — a license term supports a copyright claim only when it has sufficient nexus to licensor's § 106 exclusive rights."
- **Copyleft / conveyance triggers**: "Conveyance invokes § 106(3) distribution + § 106(2) derivative-work rights. Scope-excess supports infringement remedies under §§ 502-505. *Artifex v. Hancom* confirms dual tracking of contract and copyright."
- **Patent grants (Apache §3, GPL-3.0 §11)**: "Enforceable as contractual covenants under applicable state law. Defensive-termination clauses generally accepted but scope-specific; no SCOTUS on point."
- **Attribution / notice**: "*Jacobsen* held attribution a condition on the grant, enforceable via copyright remedies."
- **First sale / resale of FOSS copies**: "§ 109 first sale may be foreclosed by license characterisation per *Vernor v. Autodesk*; FOSS typically grants broad redistribution, so doctrine rarely material."
- **Fair use / reverse engineering**: "§ 107 four-factor test; *Sega v. Accolade* and *Sony v. Connectix* support reverse engineering for interoperability. *Oracle v. Google* (SCOTUS 2021) reinforces fair use for API reimplementation."

**(b) What is unsettled.**

Standard gap-set to mention where applicable:
- Consumer third-party-beneficiary standing (*SFC v. Vizio* pending).
- Dynamic-linking scope of "derivative work" / "combined work" — no controlling decision.
- AGPL-3.0 §13 network-use enforcement — never adjudicated.
- Interaction of GPL-3.0 §6 (anti-Tivoization / installation information) with US consumer-electronics practice — novel, not tested.
- Federal preemption scope for state-law FOSS contract claims in cross-state distribution.

**(c) Practical obligation for ERPNext.**

Phrase as concrete acts under US law:
- "Preserve copyright notices (17 U.S.C. § 401) and NOTICE files on all distributions (Apache-2.0 §4.4)."
- "For conveyed binaries: provide corresponding source or written offer per GPL-3.0 §6 (a)–(e)."
- "For User Products under GPL-3.0 §6: provide Installation Information (anti-Tivoization) when firmware is conveyed with hardware."
- "Register copyright with the US Copyright Office per 17 U.S.C. § 411 before filing infringement suit — and per § 412 before three months of first publication or before infringement begins for statutory damages and attorneys' fees."
- "For contributors under §§ 201(b), 204: obtain written CLA or explicit work-made-for-hire arrangements where ambiguity could threaten provenance."
- "Preserve attribution where license requires — enforceable as copyright condition per *Jacobsen*."

## 10. Common Pitfalls

1. **Do not conflate** statutory "derivative work" (§ 101) with FSF's "combined work" — courts define derivative work; FSF definition is interpretive guidance, influential but not binding.
2. **Do not assume** fair use protects commercial redistribution of FOSS — *Oracle v. Google* is narrow; four-factor balance rarely favors unlicensed redistribution.
3. **Distinguish** distribution (§ 106(3)) from public display (§ 106(5)); SaaS generally not distribution, hence GPL §5 does not trigger — AGPL needed for network-use copyleft.
4. **State-law contract claims are largely preempted** under § 301 if they duplicate copyright rights; plead copyright infringement for grant-violation. Preservation of state-law tort/fraud claims requires an "extra element" beyond the exclusive-rights duplication.
5. **First sale (§ 109) does not apply** to licensed (not sold) copies — *Vernor*. Relevant when user speaks of "reselling" FOSS installations.
6. **Work-made-for-hire for independent contractors** requires BOTH written agreement AND the work fit one of 9 enumerated categories — software is NOT among them. Absent assignment or proper WMFH, contractor retains copyright.
7. **Moral rights** (VARA § 106A) do not extend to software in the US. Do not import civil-law moral-rights reasoning without flagging the US exception.
8. **Registration is necessary to sue** (§ 411) and timely registration affects statutory damages and fees (§ 412). A FOSS project contemplating US enforcement should have copyright registrations in place for major releases.
9. **No stare decisis across circuits** — a 9th Circuit holding on GPL does not bind 2d Circuit. Watch for circuit splits.
10. **Choice of law for FOSS licenses** is often silent — default rules under Restatement (Second) of Conflicts apply; outcome-dependent on connection of parties/transaction. For international users, this adds unpredictability.
11. **DMCA § 1201 interactions with GPL-3.0 §3** — GPL-3.0 §3 disclaims any power to treat GPL-distributed work as effective TPM; this is a licensor's promise, not a limit on DMCA generally. Downstream users tinkering with GPL-3.0 code are generally safe from DMCA claims by the licensor, but not necessarily from a third party's DMCA claim.
12. **UCITA is not law** almost everywhere; ignore citations to it outside VA and MD.
13. **Termination right under § 203** is non-waivable. For old FOSS projects (>35 years), inbound contributor grants may face termination windows. Rarely material in 2020s, but becomes relevant mid-2030s for projects started in 2000s.

## 11. Output Constraints

- Statute citations: "17 U.S.C. § 106(3)"; "35 U.S.C. § 271". Never paraphrase.
- Case citations: Bluebook-adjacent — "*Jacobsen v. Katzer*, 535 F.3d 1373 (Fed. Cir. 2008)"; "*Oracle Am., Inc. v. Google LLC*, 141 S. Ct. 1183 (2021)". Italicize case names; include reporter, page, and court/year.
- Regulation citations: "37 C.F.R. § 201.10" (Copyright Office rules); "15 C.F.R. Part 742" (EAR).
- SPDX identifiers in canonical form (`GPL-3.0-or-later`, `Apache-2.0`, `MIT`). Never "GPL3", "GPLv3+", "Apache2".
- Do not predict court outcomes. State what the statute and controlling case law say. Flag unsettled issues as `TODO(verify)`.
- When a decision is within a single circuit, always include the circuit identifier — "(9th Cir. 2010)".
- Italicize case names; do not italicize statute titles.

## 12. Consequential Notes for ERPNext Context

- **US end-user running ERPNext on-premise.** Under § 117, owner of a lawfully-acquired copy may: (a)(1) make copies essential to running with a machine; (a)(2) make archival copies; (c) adapt as necessary to use. These rights attach **regardless** of any license clause purporting to restrict them — § 117 is non-waivable to some extent per case law (*Krause v. Titleserv*).
- **US distributor (reseller, SaaS provider bundling conveyed copies).** Bound by GPL-3.0-or-later. Conveyance triggers § 6 source-provision obligations and § 4 verbatim-distribution rules. Breach = license-scope excess → infringement under *Jacobsen* framework → §§ 502-505 remedies plus state-law contract remedies per *Artifex*.
- **SaaS-only US deployment.** No "conveyance" per GPL-3.0 §0; copyleft not triggered. Public-performance/display rights under § 106 do not activate GPL-family copyleft; AGPL-3.0 required for network-use triggering.
- **US contributor.** Under § 201(a), copyright vests in the individual author. If salaried employee and contribution within scope of employment — § 201(b) work-made-for-hire → employer owns. If independent contractor — without a proper WMFH agreement (nine-category requirement) and absent written assignment, the contractor retains copyright. **Practical mitigation:** Developer Certificate of Origin (DCO) or explicit CLA for substantial contributors.
- **Copyright registration.** For an ERPNext distribution originating from a US-based entity: register each major release with the US Copyright Office. Pre-registration (or timely registration within 3 months of publication) preserves statutory damages and attorneys' fees under § 412 — otherwise only actual damages/profits are recoverable in any subsequent enforcement action.
- **DMCA safe harbour for hosting.** A US-based host (e.g. GitHub, GitLab.com) operating under § 512 safe harbour is protected from contributory liability if they comply with takedown procedures. Not directly a license matter but relevant to how counterclaims / DMCA misuse against FOSS distributions are handled.
- **Export control.** An ERPNext distribution that includes encryption above specified thresholds may require EAR § 742.15 notification when exported from the US. Standard TLS/crypto libraries often qualify for TSU License Exception; blockchain/heavy-crypto dependencies may need separate analysis. **Out of scope for pure license analysis, flag if relevant.**
- **Anti-Tivoization (GPL-3.0 §6).** If ERPNext is bundled as firmware with "User Products" (consumer electronics), § 6 obligates the conveyor to provide Installation Information. US consumer-protection and § 1201 circumvention law intersect — untested in this specific configuration; mark `TODO(verify)` if scope of such a bundling is in question.
- **Terminations under § 203.** Not currently material for most FOSS projects (<35 years old). Relevant for very long-lived projects in the 2030s onward; plan to identify affected contributor grants.
- **State-law interactions.** California's preemption and consumer-protection variations, New York's contract doctrines, Washington's tech-focused jurisprudence, Texas's enforcement patterns — all vary subtly. When the question involves a specific US state, flag the state and consult state-specific authority. For general FOSS analysis assume federal-law-dominant framework per § 301.
