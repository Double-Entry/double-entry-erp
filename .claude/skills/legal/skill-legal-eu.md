---
name: legal-eu
description: European Union FOSS-licensing legal knowledge base — detailed. Applicable EU directives and regulations, CJEU case law, Member-State transpositions (DE, FR, IT, ES, NL, PL, SE), EUPL, authoritative bodies, and canonical sources for analyzing open-source license questions under EU jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇪🇺 EU section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under EU law and Member-State transpositions. SKIP for non-licensing EU legal questions (GDPR/privacy beyond license clauses, competition law beyond FRAND/OSS intersections, tax, labor).
---

# Skill: legal-eu — European Union FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified lawyer admitted in the relevant EU Member State.

## 1. Jurisdictional Structure and Legal Tradition

### 1.1 Status and structure

The **European Union** is a supranational legal order of **27 Member States** (post-Brexit). EU law has two operative instruments for copyright:

- **Regulations** — directly applicable, binding as-is across all MS without transposition.
- **Directives** — binding as to result; each MS must **transpose** into national law within a specified period. Implementation can diverge across MS within the directive's margin.

**Copyright law is primarily governed by Directives, not Regulations** — hence national variation is a structural feature. This is fundamentally different from US (unitary federal) or RS (unitary national) systems.

Two supranational courts matter:
- **Court of Justice of the EU (CJEU)** — authoritative interpretation of EU law, binding across all MS when ruling on EU instruments. Accessible via national-court preliminary references (art. 267 TFEU).
- **General Court (former CFI)** — mostly annulment actions against EU institutions; not primary for copyright.

### 1.2 Legal tradition

Mixed. Most MS are civil-law (DE, FR, IT, ES, NL, BE, AT, LU, PT, DK, SE, FI, PL, CZ, SK, HU, SI, HR, BG, RO, EE, LV, LT, CY, GR, MT). **Ireland** is common-law (post-Brexit the only common-law MS). Copyright rules are harmonized at directive level, but enforcement, contract interpretation, and moral-rights regimes retain national character.

**Post-Brexit UK note.** The United Kingdom is **no longer an EU Member State** (exit 31.01.2020, transition ended 31.12.2020). Post-01.01.2021 CJEU case law is **not binding** in UK; retained EU law governs under the European Union (Withdrawal) Act 2018 as amended. Pre-Brexit CJEU jurisprudence remains persuasive. **This skill does NOT cover UK** — treat UK as a separate jurisdiction needing dedicated analysis.

### 1.3 Languages and citation

EU law is authentic in all 24 official languages simultaneously. Directive texts on EUR-Lex (https://eur-lex.europa.eu/) can be pulled in any official language. Case citations follow CJEU format: "*Case Name*, C-number/year, ECLI:EU:C:year:number".

## 2. Core EU Directives — Detail

### 2.1 Directive 2009/24/EC — Software Directive (codified)

Successor to Directive 91/250/EEC (original 1991 legal-protection-of-computer-programs directive). Canonical text: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32009L0024

**Structure and operative articles:**

| Article | Heading | Operational meaning for FOSS |
|---------|---------|------------------------------|
| Art. 1 | Object of protection | Programs protected as literary works per Berne Convention. Protection extends to expression, not ideas/principles. |
| Art. 2 | Authorship | Natural person or group of natural persons. Where national law allows, legal persons may be recognized as authors of collective works. |
| Art. 3 | Beneficiaries | National treatment for foreign authors per Berne. |
| **Art. 4** | **Restricted acts** | (1)(a) permanent or temporary reproduction — including loading, displaying, running, transmission, storage; (1)(b) translation, adaptation, arrangement, any other alteration (and reproduction of the result thereof); (1)(c) any form of distribution to the public, including rental. **Foundation of what requires a license.** (2) exhaustion: first sale in Community by rightholder exhausts distribution right within Community — but NOT rental right. |
| **Art. 5** | **Exceptions to restricted acts** | (1) In the absence of specific contractual provisions, the acts in Art. 4(1)(a)–(b) do NOT require authorization where necessary for use by the lawful acquirer (including error correction). (2) **Backup copy** right — cannot be prevented by contract. (3) **Observation, study, testing** of functioning to determine underlying ideas and principles — cannot be prevented by contract. |
| **Art. 6** | **Decompilation** | Strict conditions: (1) purpose must be interoperability with independently created program; only indispensable parts may be decompiled; only accessible to lawful user. (2) Information obtained must not be (a) used for other purposes, (b) given to third parties except where interoperability requires, (c) used to develop a program substantially similar in expression — essentially, no code-reuse laundering. (3) Decompilation provisions cannot be contracted away. |
| Art. 7 | Special protection measures | Criminalisation of unauthorised distribution + circumvention of technical means. |
| **Art. 8** | **Continued application of other legal provisions** | Arts. 5(2), 5(3), and 6 are **mandatory** — contract clauses to the contrary are void. |
| Art. 9 | Computer programs developed before 1 January 1993 | Transitional provision, historical only. |

**Implications for FOSS under Software Directive.**

Mandatory user rights under arts. 5(2), 5(3), 6 are a **floor** that FOSS licenses sit comfortably above. FOSS typically grants broader permissions than statutory minimum, so no conflict. Where a FOSS license is **silent** on a mandatory right, the statute fills the gap. Where a FOSS license purports to **restrict** a mandatory right, the clause is void per art. 8 — but FOSS licenses virtually never do this.

**Exhaustion under art. 4(2)** is territorial to the EEA (Community) and applies to distribution of copies. Does NOT apply to rental. CJEU *UsedSoft* extended exhaustion to downloaded copies (see §3).

### 2.2 Directive 2001/29/EC — InfoSoc Directive

General copyright harmonization. Canonical: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32001L0029

**Most FOSS-relevant articles:**

| Article | Heading | Operational meaning |
|---------|---------|---------------------|
| Art. 2 | Reproduction right | Exclusive right to reproduction of whole or part, direct or indirect, temporary or permanent, by any means. Very broad. |
| **Art. 3** | **Right of communication to the public + making available right** | Exclusive right of making available by wire or wireless such that members of the public may access from place and time of their choosing. **Key for SaaS/network-use analysis** — this is the right that AGPL triggers on. |
| Art. 4 | Distribution right and exhaustion | Distribution right; exhausted only by first sale in Community by rightholder or with consent. Tom Kabinet ruling (C-263/18) clarifies exhaustion does NOT extend to e-books — software exhaustion per Software Directive / *UsedSoft* is a special case. |
| Art. 5 | Exceptions and limitations | **Exhaustive list** — MS cannot invent new exceptions. Includes quotation, teaching/research, temporary technical copies, etc. |
| Art. 6 | Anti-circumvention of TPMs | Parallel to DMCA §1201. Obligates MS to prohibit circumvention. Interacts with GPL-3.0 §3 — GPL licensor disclaims any power to treat GPL work as effective TPM. |
| Art. 7 | Protection of rights management information | Prohibits removal/alteration of electronic rights-management metadata. |

### 2.3 Directive (EU) 2019/790 — DSM Directive

Digital Single Market copyright reform. Canonical: https://eur-lex.europa.eu/eli/dir/2019/790/oj

| Article | Subject | FOSS relevance |
|---------|---------|----------------|
| Art. 3 | Text-and-data-mining for scientific research | Mandatory exception for research organizations. Relevant to AI training debates, not to core FOSS. |
| Art. 4 | TDM for other purposes | General TDM exception subject to rightholders' opt-out. Peripheral. |
| Art. 14 | Works of visual art in the public domain | Prevents new copyright on faithful reproductions. Not material for FOSS. |
| Art. 15 | Press-publisher right | New neighbouring right for press publishers. Not material for FOSS. |
| Art. 17 | Online content-sharing service providers ("upload filters") | Platform obligations for user-uploaded content. Intersects with FOSS code-sharing only tangentially (code-hosting platforms largely exempt). |

### 2.4 Directive 2004/48/EC — IP Enforcement Directive

Harmonized procedures: injunctions, evidence collection, damages, corrective measures, right of information. Canonical: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32004L0048R(01)

Relevant when FOSS enforcement is contemplated in any MS — provides common floor of remedies. National transposition governs actual procedure.

### 2.5 Directive (EU) 2019/770 — Digital Content Directive

Consumer-contract rules for digital content and services. Canonical: https://eur-lex.europa.eu/eli/dir/2019/770/oj

**Recital 32** and **art. 3** carve out **software supplied under free and open-source licenses** where the consumer pays no price and does not provide personal data as payment. Important argument that FOSS distribution is not a "consumer contract" in the directive's sense, shielding FOSS from consumer-protection obligations aimed at paid digital content.

### 2.6 Directive (EU) 2022/2065 — Digital Services Act (DSA)

Applies as Regulation 2022/2065 directly. Platform obligations (content moderation, transparency, trusted flaggers). Peripheral to license substance; relevant to how GitHub/GitLab et al. moderate FOSS repositories.

### 2.7 Regulation (EU) 2016/679 — GDPR

Not a copyright matter. Out of scope for pure FOSS license analysis EXCEPT where a specific license clause interacts with personal-data processing (rare). Mention only if the question expressly couples the two.

### 2.8 Directive 96/9/EC — Database Directive

Protects databases via (a) copyright on original structure, (b) **sui generis right** for substantial investment in obtaining/verifying/presenting contents. Relevant to FOSS distributions containing databases (e.g. ERPNext fixture data, seed CSVs, geographic data). CDLA-Permissive, CDLA-Sharing, ODbL, CC-BY-4.0 are the main FOSS-adjacent database licenses addressing this right.

### 2.9 Directive (EU) 2019/771 — Sale of Goods Directive

Relevant when software is sold as embedded in goods (IoT, appliances). Interacts with GPL-3.0 §6 anti-Tivoization context.

### 2.10 EUPL — European Union Public Licence

Not a directive but a FOSS license **drafted by the European Commission** (latest v1.2, January 2017). Official at https://joinup.ec.europa.eu/collection/eupl. Features:

- Designed for EU-law enforceability (copyleft + patent grant + multilingual equal authenticity in 22 EU languages).
- GPL-2.0 / GPL-3.0 / AGPL-3.0 / LGPL-2.1+ / Mozilla-2.0 compatible via explicit compatibility clause.
- Specifies Belgian law as governing law if not otherwise agreed.
- Jurisdiction: CJEU where parties are in EU (when at least one is an EU institution); courts of Brussels otherwise.

Not commonly used outside EU public-sector software.

## 3. Key CJEU Case Law

### 3.1 Software-specific

- ***UsedSoft GmbH v. Oracle International Corp.***, C-128/11 (3 July 2012), ECLI:EU:C:2012:407. **Foundational.** Interpreting Directive 2009/24/EC art. 4(2): distribution right is exhausted by first authorized distribution **including downloaded copies** — not only tangible media. Licensor cannot use copyright to block resale of "used" software licenses even where license purports to forbid resale. Massive implication for FOSS distribution chain (though most FOSS licenses permit redistribution anyway, making this effectively confirmatory).

- ***Nintendo Co. v. PC Box Srl***, C-355/12 (23 January 2014), ECLI:EU:C:2014:25. TPM (technological protection measure) circumvention is unlawful unless the measure **disproportionately restricts** lawful uses. Proportionality test — relevant to GPL-3.0 §3 / DMCA-equivalent analysis and to any anti-circumvention claim against FOSS tinkering.

- ***Top System SA v. État belge***, C-13/20 (6 October 2021), ECLI:EU:C:2021:811. Lawful acquirer's right to decompile under Software Directive art. 5(1) extends to correcting errors — not only art. 6's narrower interoperability exception. Strengthens mandatory-exception character of user rights.

- ***SAS Institute Inc. v. World Programming Ltd.***, C-406/10 (2 May 2012), ECLI:EU:C:2012:259. Programming languages, file formats, and functionality **are not protected** by copyright on the program; only expression of the program is. Limits reach of "derivative work" / "combined work" claims to actual code copying.

- ***BSA — Bezpečnostní softwarová asociace***, C-393/09 (22 December 2010), ECLI:EU:C:2010:816. GUI is NOT part of the program as such for Software Directive protection — may be independently protected under InfoSoc if it meets originality.

### 3.2 Communication to the public / distribution

- ***Tom Kabinet***, C-263/18 (19 December 2019), ECLI:EU:C:2019:1111. UsedSoft doctrine of exhaustion does **NOT extend** to e-books. Software exhaustion under Software Directive is species-specific. Limits cross-medium analogies in FOSS redistribution analysis.

- ***Stichting Brein v. Ziggo (The Pirate Bay)***, C-610/15 (14 June 2017), ECLI:EU:C:2017:456. Operating indexing/torrent platform constitutes communication to the public under InfoSoc art. 3. Peripheral to pure license analysis but informs platform-liability framing.

- ***VG Bild-Kunst v. Stiftung Preußischer Kulturbesitz***, C-392/19 (9 March 2021), ECLI:EU:C:2021:181. Framing of copyright-protected content can constitute communication to the public if circumventing protection measures.

- ***Svensson v. Retriever Sverige***, C-466/12 (13 February 2014), ECLI:EU:C:2014:76. Hyperlinking to freely-available content is not communication to new public. Relevant for FOSS-project websites linking to distributions.

- ***GS Media v. Sanoma Media Netherlands***, C-160/15 (8 September 2016), ECLI:EU:C:2016:644. Linking to infringing content is communication to the public if done for profit and with knowledge of infringement.

### 3.3 Concept of originality

- ***Infopaq International v. Danske Dagblades Forening***, C-5/08 (16 July 2009), ECLI:EU:C:2009:465. Originality: "author's own intellectual creation". Harmonized standard across EU — a higher bar than UK's "skill, labour, judgement" pre-Infopaq but lower than Germany's pre-EU "Schöpfungshöhe".

- ***Football Dataco v. Yahoo! UK***, C-604/10 (1 March 2012). Selection/arrangement of facts protected only if it reflects author's own intellectual creation, not merely labour. Limits thin-copyright claims on fact compilations.

### 3.4 Open-license-specific CJEU engagement

**CJEU has NOT yet ruled directly on FOSS-license compatibility, copyleft enforcement, or GPL-specific questions.** National-court decisions (esp. German) are the best EU-level proxy. **Mark as `TODO(verify)` any claim that CJEU has settled a specific FOSS-license question** — it hasn't as of this skill's last revision.

### 3.5 Exhaustion / CDSM / AI training (emerging)

- Developments post-2023 on art. 4 DSM Directive (TDM opt-out) and interaction with AI training — fast-moving, check CJEU for current position.

## 4. Member-State Transpositions — Notable Differences

### 4.1 Germany (DE)

- **Gesetz über Urheberrecht und verwandte Schutzrechte (UrhG)** — last major reform 2021 for DSM transposition.
  - **§§ 69a–69g** — special regime for computer programs (transposing 2009/24/EC).
    - §69a — protected subject-matter.
    - §69b — works made in service (employer gets rights).
    - §69c — restricted acts (reproduction, modification, distribution, communication to the public).
    - §69d — mandatory exceptions (use, backup, observation — non-waivable).
    - §69e — decompilation strict conditions.
    - §69f — infringement remedies.
    - **§69g(2)** — **anti-waiver:** §§69d(2), 69d(3), 69e are mandatory; contrary contract clauses void.
  - §§31–38 — general license framework (Urhebervertragsrecht).
  - §32 — equitable remuneration (unwaivable minimum for author; interacts oddly with gratuitous FOSS — academic debate, not commonly litigated).
  - §32a — "bestseller" clause — author can claim additional compensation if work becomes disproportionately successful.
  - §39 — alteration of the work — prohibited beyond what contract allows.
- **Key German case law:**
  - ***Welte v. Sitecom***, Landgericht München I, Urt. v. 19.05.2004, 21 O 6123/04 — first German GPL-enforcement decision; injunction issued against Sitecom's WLAN router violating GPL.
  - ***Welte v. D-Link***, LG Frankfurt, 06.09.2006, 2-6 O 224/06 — GPL enforcement against router firmware.
  - ***Welte v. Fantec***, LG Berlin, 2013 — continued GPL-enforcement pattern.
  - ***BGH — Half-Life 2***, BGH, 11.02.2010, I ZR 178/08 — Steam's online-activation upheld; indirectly relevant to platform models.
  - ***BGH — Videospielkonsole II***, BGH, 27.11.2014, I ZR 124/11 — TPM and circumvention tools.
- Germany is historically the **most active GPL-enforcement jurisdiction in the EU** (gpl-violations.org led by Welte / Coughlan). A Germany-specific question should look for German case law first.

### 4.2 France (FR)

- **Code de la propriété intellectuelle (CPI)** — main IP statute, integrates all IP rights.
  - L.112-2 — programs for EVM as works of the mind.
  - L.122-6 — droits patrimoniaux on software: reproduction, translation/adaptation, distribution including rental.
  - **L.122-6-1** — exceptions for lawful user: necessary use, backup, observation, decompilation for interoperability. Mandatory; contract clauses to the contrary void (L.122-6-1 IV).
  - L.122-6-2 — (formerly decompilation details; absorbed into L.122-6-1 III).
  - L.331-1 et seq. — enforcement, injunction, damages.
  - L.335-2 et seq. — criminal copyright offenses.
- **Droit moral** (L.121-1 to L.121-9) — very strong, inalienable moral rights: right of paternity, integrity, first-disclosure, withdrawal. Extends to software works. Cannot be waived by contract — a FOSS contributor retains paternity right even under very permissive license.
- **CeCILL family** — French-drafted FOSS licenses (CeCILL, CeCILL-B, CeCILL-C) designed for French-law compatibility. CeCILL v2.1 declared GPL-compatible. Used primarily by French public-sector projects.
- **Notable FR case law:** *Edu4 v. AFPA*, Cour d'appel de Paris, 16.09.2009, No. 04/24298 — GPL enforcement; AFPA required to provide source of modified OpenOffice.org.

### 4.3 Italy (IT)

- **Legge 22 aprile 1941, n. 633 — Legge sul diritto d'autore (LDA)** — with multiple updates.
  - Artt. 1, 2 — protected works (software expressly included since 1992).
  - Artt. 64-bis to 64-quater — programs for EVM special regime (transposing Software Directive).
    - Art. 64-bis — exclusive rights.
    - Art. 64-ter — lawful-user rights (backup, observation, error correction).
    - Art. 64-quater — decompilation.
  - Art. 171-bis — criminal provisions for software piracy.
- Relatively limited OSS-specific case law.

### 4.4 Spain (ES)

- **Real Decreto Legislativo 1/1996 — Ley de Propiedad Intelectual (LPI)**.
  - Arts. 95-104 — programs for EVM.
    - Art. 100 — mandatory user rights.
    - Art. 100.5 — decompilation.
- Tribunal Supremo has ruled on software contract issues but rarely on OSS specifically.

### 4.5 Netherlands (NL)

- **Auteurswet** — updated repeatedly.
- **Art. 45a–45n** — programs for EVM regime.
- NL courts relatively active in EU IP matters; one of the preferred forums for cross-EU IP litigation.

### 4.6 Poland (PL)

- **Ustawa z dnia 4 lutego 1994 r. o prawie autorskim i prawach pokrewnych** — updated multiple times.
- **Rozdział 7 (arts. 74-77⁵)** — programs for EVM.
- Poland has seen GPL-adjacent disputes but few that establish novel precedent.

### 4.7 Sweden (SE)

- **Upphovsrättslagen (1960:729)**.
- §§26g–26i — programs for EVM.
- Sweden hosts Pirate Bay-related and platform-liability case law; less FOSS-specific.

### 4.8 Smaller / other MS

- Austria, Belgium, Netherlands — generally align with German/French doctrine with local variations.
- CEE MS (Czech Republic, Slovakia, Hungary, Slovenia, Croatia, Bulgaria, Romania, Baltic states) — post-accession harmonisation generally complete; local case law sparse on OSS.
- Cyprus, Greece, Malta — small jurisdictions; local OSS case law minimal.
- **Ireland** — common-law tradition within the EU; Supreme Court + Court of Appeal + High Court; copyright governed by Copyright and Related Rights Act 2000 (as amended). Increasingly important post-Brexit.

## 5. Related EU Instruments Affecting FOSS

### 5.1 Brussels I Regulation (recast) — 1215/2012

**Jurisdiction** in civil and commercial matters. Governs which MS court hears a cross-EU FOSS dispute.
- Art. 4 — general jurisdiction at defendant's domicile.
- Art. 7(2) — special jurisdiction for tort/delict: where harmful event occurred. In copyright infringement context, *Pinckney v. KDG Mediatech* (C-170/12) and *Hejduk v. EnergieAgentur* (C-441/13) establish accessibility-based jurisdiction.
- Art. 24(4) — exclusive jurisdiction for registered IP validity/registration matters. Does not apply to copyright (unregistered).
- Art. 25 — jurisdiction by agreement. Many FOSS licenses silent on forum; some (EUPL) designate.

### 5.2 Rome I Regulation — 593/2008

**Law applicable to contractual obligations.** For FOSS license characterized as contract:
- Art. 3 — freedom of choice.
- Art. 4 — absence of choice: law of characteristic performer's habitual residence.
- Art. 6 — consumer contracts — protective regime; may not apply to FOSS per Digital Content Directive carve-out.

### 5.3 Rome II Regulation — 864/2007

**Law applicable to non-contractual obligations.** For copyright infringement as tort:
- Art. 8(1) — law of country for which protection is claimed (*lex loci protectionis*) for IP infringement. Mandatory — cannot be chosen by parties.

### 5.4 EU AI Act — Regulation 2024/1689 (in phased entry-into-force)

Horizontal AI regulation. Art. 2(12) carves out AI models released under free and open-source license from certain obligations (narrow; model-weights + architecture + use; general-purpose AI models above 10^25 FLOPs still subject). Relevant if ERPNext dependencies include open-weight AI/ML components.

### 5.5 Regulation (EU) 2022/1925 — Digital Markets Act (DMA)

Gatekeeper regulation; not directly a copyright matter. May obligate gatekeepers to interoperability, which intersects with FOSS re-use.

## 6. International Obligations

- **Berne Convention** — universal; all EU MS parties.
- **TRIPS art. 10** — programs as literary works.
- **WCT art. 4** — programs expressly protected.
- **WCT art. 8** — making-available right.

EU is party to Berne via MS participation + EU's own accession to WCT/WPPT. Treaties implemented via directives; no direct effect in national courts as a routine matter.

## 7. Court Hierarchy

### 7.1 EU-level

- **Court of Justice of the EU (CJEU)** — Luxembourg. Grand Chamber (15 judges), regular chambers (3 or 5 judges).
- **General Court** — EU annulment actions; not primary for copyright substance.
- **Advocates-General** — deliver non-binding Opinions before CJEU judgment; highly influential.

### 7.2 Preliminary reference procedure (art. 267 TFEU)

National courts can (and final-instance courts must) refer EU-law interpretation questions to CJEU. Most FOSS-related CJEU cases reach it this way.

### 7.3 National hierarchies (FOSS-relevant)

| MS | Supreme / Highest Court | Typical IP Court of first instance |
|----|-------------------------|-----------------------------------|
| DE | Bundesgerichtshof (BGH), Karlsruhe | Landgericht + Oberlandesgericht; specialised IP chambers in Munich, Düsseldorf, Mannheim, Hamburg |
| FR | Cour de cassation, Paris | Tribunal judiciaire; Cour d'appel de Paris has specialised chamber |
| IT | Corte di Cassazione, Rome | Tribunali delle imprese (specialised enterprise courts) |
| ES | Tribunal Supremo, Madrid | Juzgados de lo Mercantil |
| NL | Hoge Raad, The Hague | Rechtbank Den Haag has exclusive jurisdiction over patents; general courts for copyright |

### 7.4 Unified Patent Court (UPC) — active since 01.06.2023

First truly pan-EU court. Competence: European patents with unitary effect + classical European patents opted-in. **Not competent for copyright.** Irrelevant to pure FOSS license analysis; may matter for patent-grant-clause analysis for patents with unitary effect.

## 8. Authoritative Bodies

| Body | Role | URL |
|------|------|-----|
| **European Commission — DG CNECT** | Copyright and digital policy | https://digital-strategy.ec.europa.eu/ |
| **CJEU** | Authoritative interpretation of EU law | https://curia.europa.eu/ |
| **EUIPO** | EU trademark/design registration — **not copyright** | https://euipo.europa.eu/ |
| **European Patent Office (EPO)** | Patent grant under European Patent Convention — not a copyright body | https://www.epo.org/ |
| **Unified Patent Court (UPC)** | Patent disputes with unitary effect | https://www.unified-patent-court.org/ |
| **FSFE** (Free Software Foundation Europe) | Advocacy, REUSE compliance initiative | https://fsfe.org/ |
| **OpenForum Europe** | Policy think-tank | https://openforumeurope.org/ |
| **EDRi** — European Digital Rights | Digital rights advocacy | https://edri.org/ |
| **Per-MS national copyright offices** | Registration where available; policy | Various |
| **FSF Europe — REUSE compliance** | Machine-readable FOSS compliance standard | https://reuse.software/ |
| **OpenChain Europe** | Regional branch of OpenChain | https://www.openchainproject.org/community/regions |

## 9. Canonical Sources (for WebFetch verification)

| Resource | URL | Use |
|----------|-----|-----|
| **EUR-Lex** | https://eur-lex.europa.eu/ | Official EU-law gateway: directives, regulations, treaties. |
| **CJEU curia** | https://curia.europa.eu/ | Case-law search. |
| **ECLI — European Case Law Identifier** | https://e-justice.europa.eu/content_ecli_search_engine-430-en.do | Cross-jurisdictional case search. |
| **EUIPO EuroClass** | https://euipo.europa.eu/euroclass/ | Trademarks — not copyright, peripheral. |
| **FSFE REUSE** | https://reuse.software/ | Practical compliance tooling. |
| **DE: gesetze-im-internet.de** | https://www.gesetze-im-internet.de/urhg/ | UrhG full consolidated text. |
| **DE: BGH** | https://www.bundesgerichtshof.de/ | BGH decisions. |
| **FR: Légifrance** | https://www.legifrance.gouv.fr/ | CPI + case law. |
| **IT: Normattiva** | https://www.normattiva.it/ | LDA + updates. |
| **ES: BOE** | https://www.boe.es/ | LPI + gazette. |
| **NL: Overheid.nl** | https://wetten.overheid.nl/ | Auteurswet. |
| **PL: ISAP** | https://isap.sejm.gov.pl/ | Polish legal database. |
| **OSI / SPDX / FSF** — shared with US skill | https://opensource.org/ etc. | License identifiers + interpretations. |
| **EUPL** | https://joinup.ec.europa.eu/collection/eupl | EU public license. |

## 10. Applying This Skill to the (a)/(b)/(c) Structure

Canonical reasoning chain for the 🇪🇺 EU section of a legal finding:

**(a) What holds.**

Anchor by issue:
- **FOSS license enforceability across EU.** "Under Directive 2009/24/EC arts. 4-6, programs are protected as literary works with exclusive economic rights subject to mandatory user exceptions (arts. 5(2), 5(3), 6 non-waivable per art. 8). A FOSS license granting broader permissions than the statutory floor is enforceable per MS national law implementing the directive; German *Welte* line of cases confirms enforceability in DE."
- **Distribution and exhaustion.** "CJEU *UsedSoft*, C-128/11, held distribution right exhausted by first authorized distribution including downloaded copies. Exhaustion is EEA-wide. *Tom Kabinet*, C-263/18, confirms the exhaustion rule is specific to software, not extended to e-books."
- **SaaS / network use.** "Directive 2001/29/EC art. 3 'making available to the public' is a separate right from distribution. SaaS does not constitute 'distribution' in the Software Directive sense, so GPL-family copyleft does not trigger — AGPL-3.0 required for network-use copyleft."
- **Decompilation and lawful-user rights.** "Software Directive arts. 5, 6 are non-waivable per art. 8. *Top System* C-13/20 confirms lawful acquirer may decompile for error correction. National transpositions (DE §§69d-69e UrhG, FR L.122-6-1 CPI) are substantially aligned."
- **Originality / derivative scope.** "*SAS Institute* C-406/10 — functionality, programming language, file formats not protected. *Infopaq* C-5/08 — originality means 'author's own intellectual creation'. These limit the reach of derivative-work claims."

**(b) What is unsettled.**

Standard gap-set:
- **CJEU has not ruled directly on FOSS license-specific questions** — copyleft enforcement, patent-termination clauses, anti-Tivoization. Mark as `TODO(verify)`.
- **MS divergence.** For specific clauses (e.g. GPL §32 interaction with author's equitable-remuneration right under German §32 UrhG), outcome varies by MS. Flag with MS name if jurisdiction-specific.
- **AGPL-3.0 §13 network use** — no CJEU or major national ruling.
- **GPL-3.0 §6 anti-Tivoization** — intersection with EU Radio Equipment Directive and IoT regulations is untested.
- **UK position post-Brexit** — explicitly not covered by this skill; note separately.

**(c) Practical obligation for ERPNext.**

Phrase as concrete acts:
- "Preserve license notices and NOTICE files as each applicable license requires — Directive 2004/48/EC enforcement remedies available across EU."
- "For EU distribution: respect MS consumer-law carve-outs — Digital Content Directive 2019/770 recital 32 exempts gratuitous OSS from consumer-contract obligations."
- "For DE distribution particularly: expect enforcement activity — GPL breaches have been litigated to injunction in German courts since 2004 (*Welte* cases)."
- "For SaaS-only delivery: GPL-family copyleft not triggered; AGPL-3.0 required if network-use triggering is intended."
- "Data-protection: GDPR applies to personal data processing within EU regardless of FOSS license; not a license matter but a routine accompaniment."

## 11. Common Pitfalls

1. **Do not treat CJEU case law as settling everything.** Many FOSS-specific questions have only national-level treatment (esp. German). When writing EU analysis, distinguish between EU-wide uniformity and MS-level divergence.
2. **UsedSoft applies to software only** (*Tom Kabinet* C-263/18 clarified). Do not extend exhaustion to e-books, music, games — in software it is a special regime per Software Directive.
3. **SaaS / network use ≠ distribution.** Under Software Directive, communication-to-the-public (InfoSoc art. 3) is a separate right; GPL-family copyleft does not trigger.
4. **Mandatory user rights** (Software Directive arts. 5(2), 5(3), 6) — contract clauses waiving them are void under art. 8. FOSS licenses don't attempt to; proprietary EULAs sometimes do.
5. **Moral rights** — strong in civil-law MS (FR, DE, IT). Inalienable. "No-warranty" clauses do not waive paternity. For US-centric FOSS projects this may surprise.
6. **GDPR is separate** from copyright/licensing. Flag the distinction explicitly when users conflate.
7. **UK is NOT covered** — post-Brexit. Pre-Brexit CJEU case law remains persuasive in UK but not binding. Do not extrapolate EU conclusions to UK.
8. **Directives require transposition.** A directive provision is not directly applicable against private parties unless (a) transposition deadline has passed and MS has failed to transpose, AND (b) the provision meets direct-effect requirements (clear, precise, unconditional). Between private parties, national implementing law governs.
9. **Territorial exhaustion** under Software Directive is **EEA** — Iceland, Liechtenstein, Norway included; Switzerland NOT included (separate EEA-association framework).
10. **Art. 4(2) vs art. 3.** Distribution right can be exhausted; making-available right **cannot be exhausted** (CJEU *VG Wort*, *Tom Kabinet*). Every new online "communication" needs permission.
11. **Database rights are separate** — sui generis database right under Directive 96/9/EC is independent of copyright. Applies to substantial investment in compilation regardless of originality. ERPNext fixture data may trigger this analysis.
12. **Swiss law, Norwegian law** — not EU but EEA-adjacent; often follow EU pattern with local variations. Not covered here; treat separately if question is Switzerland- or Norway-specific.
13. **Ireland specificity** — common-law MS; Irish cases may diverge from civil-law MS case law on contract-interpretation questions even where directive text is identical.
14. **EU Software Directive ≠ US Copyright Act.** Restricted acts under art. 4 are close but not identical to US § 106. "Adaptation" and "arrangement" in EU have specific Berne meanings not always mirrored in US "derivative work" analysis.

## 12. Output Constraints

- Directive/regulation citations: "Directive 2009/24/EC art. 5(3)"; "Regulation (EU) 2016/679 art. 2(1)". Always include directive number and article; never paraphrase.
- CJEU case citations: "*UsedSoft*, C-128/11 (3 July 2012), ECLI:EU:C:2012:407". Italic short name, case number, date, ECLI identifier.
- National statute citations: "UrhG §69d(2)" (DE); "L.122-6-1 CPI" (FR); "art. 64-ter LDA" (IT); "LPI art. 100" (ES); "Auteurswet art. 45j" (NL).
- SPDX identifiers in canonical form.
- Do not predict CJEU outcomes on untested questions. Mark as `TODO(verify)` with the specific open question.
- When MS-level divergence is material, explicitly list which MS takes which position — do not flatten to a pan-EU generalization.
- When writing in English, keep original-language directive/statute titles available in parentheses for precision — "Directive 2009/24/EC (Software Directive)".

## 13. Consequential Notes for ERPNext Context

- **EU end-user running ERPNext on-premise in any MS.** Mandatory user rights under Software Directive arts. 5(2), 5(3), 6 attach — backup copy, observation/study/testing of functioning, decompilation for interoperability of independently-created programs. These operate regardless of license language to the contrary, which is irrelevant because FOSS licenses typically grant more permissively than the statutory floor.
- **EU distributor of ERPNext** (reseller, SaaS provider conveying copies, Docker image publisher). Bound by GPL-3.0-or-later as license condition + contract under national law implementing Software + InfoSoc + Enforcement Directives. Breach → scope excess → infringement remedies under art. 8 Enforcement Directive (injunction, damages, corrective measures) + contract remedies.
- **SaaS-only EU deployment** (no copy conveyed to users). InfoSoc art. 3 making-available right is exercised, but Software Directive distribution right / GPL-family §5 "conveying" is not triggered. AGPL-3.0 required if network-use copyleft is intended. Mirrors US / RS / RU position.
- **German distribution.** Expect the highest-intensity enforcement environment. GPL-compliance processes should be audited before distributing to DE market. Regional representatives (cf. gpl-violations.org) historically active.
- **French distribution.** Droit moral considerations — contributors retain paternity and integrity rights regardless of license. Unlikely to block FOSS operations but relevant for attribution practice.
- **Consumer-facing distribution within EU.** Directive 2019/770 (Digital Content) recital 32 exempts gratuitous OSS from consumer-contract obligations. For paid bundles (ERPNext + support), consumer-protection law may apply; partition licensing from support.
- **GDPR context.** ERPNext processing EU personal data → GDPR applies independently of license. Distribute freely under GPL; data-processing agreements with customers handle GDPR. **Out of scope for pure license analysis, flag if relevant.**
- **Database rights.** ERPNext fixture data (country data, tax tables, CSV seeds) may attract database sui generis right under Directive 96/9/EC if substantial investment was made in obtaining/verifying/presenting. Any distribution of such data under GPL works because GPL's "Source Code" definition includes data the program needs.
- **EU AI Act exposure.** If ERPNext gains AI/ML features using open-weight models, Regulation 2024/1689 may apply. Art. 2(12) carve-out for FOSS AI models is narrow — analyze specifically if triggered.
- **UPC and patent-grant clauses.** If ERPNext uses patented algorithms covered by European patents with unitary effect, Apache-2.0 §3 / GPL-3.0 §11 defensive-termination clauses are enforced through UPC in addition to national patent courts. Doctrinally novel; no UPC case law yet on FOSS patent-grant enforcement.
- **Post-Brexit UK distribution.** UK jurisdiction separate; analyze under UK Copyright, Designs and Patents Act 1988 as amended and retained EU law. **Not covered by this skill.** If ERPNext distributed to UK, flag as needing separate UK analysis.
