---
name: legal-rs
description: Republic of Serbia FOSS-licensing legal knowledge base — detailed. Applicable copyright law, civil contract framework, IP-related statutes, case law, EU-acquis harmonization status, authoritative bodies, and canonical sources for analyzing open-source license questions under RS jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇷🇸 RS section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under Serbian law; especially relevant when the project is distributed, hosted, or developed in Serbia. SKIP for non-licensing RS legal questions (labor, tax, criminal piracy beyond civil license enforcement).
---

# Skill: legal-rs — Republic of Serbia FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified attorney admitted in the Republic of Serbia (адвокат уписан у Адвокатску комору Србиje).

## 1. Jurisdictional Status and Legal Tradition

### 1.1 Status

The **Republic of Serbia** (Република Србиja / Republika Srbija) is a **sovereign jurisdiction**, **EU candidate country since March 2012**, formal accession negotiations opened January 2014. It is **not an EU Member State**. Negotiation chapter governing IP (Chapter 7 — Intellectual, Industrial and Commercial Property) requires progressive alignment with the EU acquis communautaire. The **Stabilisation and Association Agreement (SAA) Serbia–EU** (in force 01.09.2013) obligates Serbia to approximate its IP legislation to EU standards; SAA arts. 72–75 explicitly address IP protection levels equivalent to those in the Union.

**Consequence for FOSS analysis.** Serbian substantive IP law is **visibly EU-aligned** but is **enacted and interpreted as independent national law**. **CJEU case law is not directly binding** in Serbian courts; it is increasingly cited as persuasive authority, especially by higher courts and academic commentary, but has no automatic effect. A Serbian court is bound by its own Supreme Court of Cassation (Врховни касациони суд) and Constitutional Court jurisprudence.

### 1.2 Legal tradition

Continental / civil-law system (successor to the SFRY codified tradition). Statutes are the primary source; case law is persuasive and uniformity is pursued through the **Supreme Court of Cassation's legal positions** (правни ставови). IP protection sits in a specialised statute (Закон о ауторском и сродним правима) rather than a single civil code.

### 1.3 Language and script

Official language is **Serbian**, constitutionally usable in **both Cyrillic and Latin scripts**. Statute texts are published in "Службени гласник Републике Србиje" (Official Gazette) primarily in Cyrillic. When citing, keep the original script form; when referring in English, use the accepted transliterated form.

## 2. Core Copyright Statute

### 2.1 Закон о ауторском и сродним правима (ЗАСП)

**Law on Copyright and Related Rights.** Published in "Службени гласник РС" br. 104/2009, subsequently amended: 99/2011, 119/2012, 29/2016 — decision of the Constitutional Court, 66/2019, 125/2023. The 2023 amendment is the current consolidated operative text as of this skill's last revision.

Canonical text:
- Paragraf.rs (current consolidated): https://www.paragraf.rs/propisi/zakon_o_autorskom_i_srodnim_pravima.html
- Pravno-informacioni-sistem.rs (official): http://www.pravno-informacioni-sistem.rs/
- EU-published version of pre-2019 text (for reference on harmonisation): https://wipolex-res.wipo.int/edocs/lexdocs/laws/en/rs/rs110en.pdf

#### Most FOSS-relevant provisions

| Article | Serbian heading | Subject | Notes |
|---------|-----------------|---------|-------|
| Чл. 2 | Ауторско дело | Work protected | Original intellectual creation of an author, expressed in any form |
| Чл. 4 | Делови ауторског дела | Parts of a work | Named parts also protected |
| Чл. 5(1)(2) | Аутоска дела — примери | List of examples | Includes "компјутерски програми" (computer programs) |
| Чл. 9 | Производе (изведена) дела | Derivative works | Translations, adaptations, arrangements — require original author's consent |
| Чл. 10 | Зборник | Compilations | Protection of arrangement |
| Чл. 14–18 | Моралска права | Moral rights | **Inalienable**; include right of paternity (attribution), integrity, publication |
| Чл. 19–27 | Имовинска права | Economic (patrimonial) rights | Reproduction, adaptation, distribution, public communication |
| Чл. 26 | Право дистрибуције | Distribution right | Art. 26(3) — **exhaustion** on first authorized sale within RS territory (national exhaustion; contrast EU-wide exhaustion under Directive 2009/24) |
| Чл. 41 | Ограничења имовинских права | Limitations generally | Statutory list |
| Чл. 46 | Привремено умножавање | Transient copies | Harmonised with InfoSoc art. 5(1) |
| **Чл. 72** | **Компјутерски програм као ауторско дело** | **Programs as works** | Protected as literary works; expression of idea, not idea itself |
| **Чл. 73** | **Имовинска права на компјутерским програмима** | **Economic rights on programs** | Reproduction (permanent/transient), translation/adaptation/transformation, distribution |
| **Чл. 74** | **Права законитог корисника** | **Lawful-user rights** | **Non-waivable by contract.** Necessary use for intended purpose, error correction (unless contractually reserved), backup copy, observation/study/testing of functioning. Mirrors Directive 2009/24/EC art. 5 |
| **Чл. 75** | **Декомпилација** | **Decompilation for interoperability** | Strict conditions mirroring Directive 2009/24/EC art. 6; **non-waivable** |
| Чл. 76 | Општа ограничења — нема примене | General limitations not applicable | Specific program-limitations regime supersedes general chapter for programs |
| Чл. 59–71 | Ауторски уговор | Authorial contract | General license-agreement framework |
| Чл. 61 | Форма уговора | Form of contract | **Written form required as a rule** (чл. 61 ст. 1); non-compliance leads to interpretation in author's favor (in dubio pro auctore) |
| Чл. 62 | Садржина | Content of contract | Mandatory particulars; scope of use |
| Чл. 63 | Накнада | Remuneration | Gratuitous licenses permitted if expressly agreed |
| Чл. 66 | Неискључива / искључива лиценца | Non-exclusive / exclusive license | Non-exclusive is default |
| Чл. 67 | Сублиценца | Sub-license | Requires licensor's consent |
| Чл. 163–174 | Грађанскоправна заштита | Civil protection | Injunction, damages, destruction of infringing copies, publication of judgment |
| Чл. 175 | Казнене одредбе | Criminal provisions | Copyright infringement criminalised |
| Чл. 208 | Мере техничке заштите | Technical protection measures | Anti-circumvention regime; analogue to InfoSoc art. 6 |

### 2.2 Implications for open-source licenses under ЗАСП

Serbia does **not have** a dedicated "open license" provision analogous to ст. 1286.1 of the Russian Civil Code. FOSS licenses operate through the **general authorial-contract framework (чл. 59–71 ЗАСП)** combined with general contract law. The specific legal treatment:

- **Formation.** Click-through / installation-as-acceptance: the statutory written-form requirement of чл. 61 ст. 1 is **tempered** by чл. 72а Закона о облигационим односима (electronic form equivalent to written) and by the Закон о електронском документу, електронској идентификацији и услугама од поверења у електронском пословању ("Сл. гласник РС" 94/2017, 52/2021). Machine-readable electronic acceptance is generally sufficient for ordinary commercial software licensing, though academic commentary notes this is not explicitly confirmed for gratuitous FOSS by the Supreme Court of Cassation.
- **Gratuity.** чл. 63 ст. 3 ЗАСП permits a license to be gratuitous if the parties expressly so agree. FOSS licenses satisfy this via their explicit "without fee" language.
- **Non-exclusive nature.** Aligns with чл. 66 default (неискључива лиценца).
- **Mandatory user rights.** чл. 74–75 ЗАСП are **non-waivable** — any FOSS-license clause that purports to restrict backup copy, error correction, observation of functioning, or decompilation for interoperability would be **unenforceable to that extent** in Serbia. This rarely conflicts with FOSS licenses, which typically grant broader permissions than the statutory minimum.
- **Copyleft.** Analysed through чл. 9 (derivative works require original-author consent) + the specific license's copyleft clause. The GPL family's conveyance-triggered source-disclosure obligations are **treated as contractual conditions** on the authorial-contract grant. Breach creates both contractual and copyright-infringement remedies under чл. 163–174.
- **Patent grants** (Apache-2.0 §3, GPL-3.0 §11). Enforceable as contractual covenants. Defensive-termination clauses have **no dedicated Serbian case law**; general contract-law principles (Закон о облигационим односима) govern. Mark as `TODO(verify)` when the specific question turns on patent-termination scope.
- **Anti-Tivoization** (GPL-3.0 §6, "Installation Information"). No specific Serbian case law. Enforceable as contract condition.
- **Moral rights** (чл. 14–18 ЗАСП). **Inalienable.** A "no warranty / no liability" license clause does **not** waive the moral right of paternity; contributors always retain attribution right. Usually non-disruptive for FOSS but worth noting for contributor agreements.

## 3. Civil Contract Framework

### 3.1 Закон о облигационим односима (ЗОО)

**Law on Obligations.** Originally "Службени лист СФРЈ" br. 29/78, with subsequent federal and republican amendments; applied in Serbia as **retained legislation** per Уставни закон for implementation of the 2006 Constitution. Despite its age and federal-Yugoslav origin, ЗОО is the operative general civil-obligations statute.

Canonical text:
- Paragraf.rs: https://www.paragraf.rs/propisi/zakon_o_obligacionim_odnosima.html

Relevant provisions for FOSS contract formation:

| Article | Subject |
|---------|---------|
| Чл. 26 | General principle of consent |
| Чл. 32–39 | Offer and acceptance |
| Чл. 38 | Public offer (relevant for FOSS license posted on a project website) |
| Чл. 72а | Electronic form equivalent to written form |
| Чл. 99 | Standard contract terms — interpretation contra proferentem |
| Чл. 143 | Adhesion-contract (уговор по приступу) interpretation |
| Чл. 140 | Content validity — impossibility, illegality |
| Чл. 262 | Non-performance remedies |
| Чл. 563–578 | Licencni уговор (general license, non-IP-specific) |

### 3.2 Interaction with ЗАСП

Where ЗАСП is silent, ЗОО applies subsidiarily (lex generalis). ЗАСП's **ауторски уговор** (authorial contract, чл. 59–71) is a specialised subtype and takes precedence for copyright-specific questions (lex specialis derogat legi generali). The typical reasoning chain for a FOSS-license question: ЗАСП чл. 72–76 (program-specific) → ЗАСП чл. 59–71 (authorial contract) → ЗОО general principles.

### 3.3 Закон о заштити података о личности

**Law on Personal Data Protection**, "Сл. гласник РС" br. 87/2018, in force from 21.08.2019. **Substantially GDPR-aligned** — Serbia transposed the EU GDPR near-verbatim into national law. Relevant only where a FOSS-license clause materially interacts with personal-data processing (rare — most FOSS licenses are silent on data). Regulator: Повереник за информације од јавног значаја и заштиту података о личности (поверник.рс).

## 4. Related IP and Adjacent Statutes

| Statute | Scope |
|---------|-------|
| Закон о патентима ("Сл. гласник РС" 99/2011, 113/2017, 95/2018, 66/2019, 123/2021) | Patent law — relevant to patent-grant clauses (Apache §3, GPL-3.0 §11) |
| Закон о жиговима ("Сл. гласник РС" 6/2020) | Trademark — mostly out of scope for pure FOSS licensing |
| Закон о правној заштити топографија полупроводничких производа | Semiconductor-topography right |
| Закон о електронском документу, електронској идентификацији и услугама од поверења у електронском пословању ("Сл. гласник РС" 94/2017, 52/2021) | Electronic documents and signatures |
| Закон о електронској трговини ("Сл. гласник РС" 41/2009, 95/2013, 52/2019) | E-commerce, including "conclusion of contract by electronic means" |
| Закон о заштити потрошача ("Сл. гласник РС" 88/2021) | Consumer protection — largely carves out gratuitous B2B software; analysis needed for consumer-facing FOSS distribution |

## 5. EU Acquis Harmonization — What Is and Is Not Transposed

Serbia has progressively transposed key EU copyright directives as part of Chapter 7 screening:

| EU Directive | RS transposition status |
|--------------|------------------------|
| 2009/24/EC (Software Directive) | **Transposed** via ЗАСП чл. 72–76; mandatory user rights aligned |
| 2001/29/EC (InfoSoc) | **Largely transposed** via 2019 and 2023 ЗАСП amendments; art. 3 "communication to the public" reflected in ЗАСП чл. 28 |
| 2004/48/EC (IP Enforcement) | **Transposed** via ЗАСП чл. 163–174 enforcement mechanisms |
| 2019/790 (DSM) | **Partially transposed** in 2023 amendment; some aspects still pending |
| 2019/770 (Digital Content) | Partial transposition via consumer-protection law |

**Caveat.** Transposition is statutory, not jurisprudential. CJEU case law interpreting these directives (*UsedSoft*, *Top System*, *SAS Institute*, etc.) is **persuasive** but **not directly binding** on Serbian courts. A Serbian court **may** cite CJEU case law in its reasoning — and higher courts increasingly do — but **is not obligated**. When making EU-to-RS comparative arguments, phrase them as: "The position under RS law, consistent with CJEU interpretation of the analogous EU directive art., is likely to be X" — and mark as `TODO(verify)` where the Serbian judiciary has not yet engaged.

## 6. Case Law

### 6.1 General observation

Serbian case law on **FOSS licenses specifically** is **very sparse to non-existent**. Copyright case law broadly exists at significant volume (software piracy, music/film infringement), but published decisions engaging with GPL, Apache, MIT, or similar licenses are not readily available in public databases as of this skill's last revision. This reflects the generally low volume of contested FOSS litigation outside DE/US and the high rate of informal/out-of-court resolution.

### 6.2 Court hierarchy

- **Основни судови** — courts of first instance for copyright matters involving natural persons (absent commercial-court jurisdiction).
- **Привредни судови** (Commercial Courts, Belgrade, Novi Sad, Niš, Kragujevac, Užice, Pančevo, Zrenjanin, Subotica, Sombor, Leskovac, Čačak, Valjevo, Požarevac, Zaječar) — first-instance jurisdiction where **both parties are enterprises/sole proprietors**. Most B2B FOSS-licensing disputes would land here.
- **Виши судови** (Higher Courts) — appellate function; **Vищи суд у Београду** has specialised IP jurisdiction under чл. 22 Закона о уређењу судова.
- **Апелациони судови** (Appellate Courts — Belgrade, Novi Sad, Kragujevac, Niš) — second-instance appeals from основни and виши судови.
- **Привредни апелациони суд** (Commercial Appellate Court, Belgrade) — single central appellate court for commercial-court appeals.
- **Врховни касациони суд Србиje (ВКС)** — Supreme Court of Cassation. Extraordinary review. Issues **правни ставови** (legal positions) that bind lower courts for uniformity.
- **Уставни суд Србиje** — Constitutional Court. Decision **29/2016** partially invalidated an earlier version of ЗАСП and is cited in the consolidated statute gazette.

### 6.3 Search sources

| Source | URL | Coverage |
|--------|-----|----------|
| Врховни касациони суд — base odluka | https://www.vks.sud.rs/sr/odluke | Supreme Court decisions |
| Privredni sudovi — case search | https://pa.sud.rs/tr/index.html | Commercial court decisions |
| Привредни апелациони суд bilten | https://pa.sud.rs/publikacije | Bulletin of legal positions |
| Paragraf.rs judicial practice | https://www.paragraf.rs/sudska_praksa/ | Commercial DB, most comprehensive |

**Default framing for the (b) "What is unsettled" subsection on any FOSS question in the RS section:** "Serbian judicial practice on open-source license enforcement is not established at publication-quality level. Analysis proceeds from statutory text (ЗАСП + ЗОО) and academic commentary. Mark any assertion of specific Serbian precedent as `TODO(verify)`."

## 7. Authoritative Bodies

| Body | Serbian name | Role | URL |
|------|--------------|------|-----|
| Serbian IP Office | **Завод за интелектуалну својину** (ЗИС) | Patent, trademark, design registration; voluntary deposit of computer programs | https://www.zis.gov.rs/ |
| Ministry of Culture | **Министарство културе** | Policy oversight for copyright | https://www.kultura.gov.rs/ |
| Personal Data Commissioner | **Повереник за информације од јавног значаја и заштиту података о личности** | Data-protection regulator (GDPR-aligned) | https://www.poverenik.rs/ |
| Collective Management Organisations | SOKOJ (music), OFPS (phonogram), OFA (audiovisual) | Collective copyright management — not typically relevant to FOSS |
| Bar Association | **Адвокатска комора Србиje (АКС)** | Attorney admission | https://www.aks.org.rs/ |

**Note on ЗИС deposit.** Voluntary registration/deposit of computer programs at ЗИС (under чл. 202 ЗАСП) is **optional** — it does not create the right (which arises on creation) but provides an evidentiary presumption of authorship under чл. 205 ст. 1. Rarely material for FOSS projects whose provenance is established via git history and public contribution records.

## 8. Canonical Sources (for WebFetch verification)

| Source | URL | Use |
|--------|-----|-----|
| Pravno-informacioni-sistem.rs | http://www.pravno-informacioni-sistem.rs/ | Official government legal information system — primary for statute lookup |
| Paragraf.rs | https://www.paragraf.rs/ | Most comprehensive commercial legal DB (consolidated statutes + judicial practice) |
| Propisi.net | https://www.propisi.net/ | Alternative commercial legal DB |
| Службени гласник РС | http://www.slglasnik.com/ | Official Gazette — canonical publication source |
| ЗИС (IP Office) | https://www.zis.gov.rs/ | IP Office guidance; registration data |
| ВКС | https://www.vks.sud.rs/ | Supreme Court decisions and legal positions |
| WIPO Lex — Serbia | https://wipolex.wipo.int/en/legislation/profile/RS | English-language IP-statute summaries |
| Delegation of the EU to Serbia | https://europa.rs/ | Acquis harmonisation progress |

**Scripts.** When WebFetching paragraf.rs or pravno-informacioni-sistem.rs, expect Cyrillic primary text with selective Latin-script content. Keep citations in the script as found; transliterate only when producing English-language output.

## 9. Applying This Skill to the (a)/(b)/(c) Structure

When drafting the 🇷🇸 RS section of a legal finding:

- **(a) What holds.** Anchor to the exact ЗАСП article + ЗОО where relevant. Typical chain for a license-compatibility question: "Under чл. 72–73 ЗАСП, computer programs are protected as literary works with exclusive economic rights enumerated. Under чл. 66 ЗАСП, the default license is non-exclusive. Gratuitous licensing is permitted under чл. 63 ст. 3 ЗАСП. Mandatory user rights under чл. 74–75 ЗАСП are non-waivable. The license operates as an ауторски уговор under чл. 59–71 ЗАСП, subsidiarily governed by ЗОО general contract principles." Add EU-acquis alignment note where it strengthens the reading.

- **(b) What is unsettled.** Default to: "Serbian case law on open-source license enforcement is not established at publication-quality level. CJEU case law interpreting the analogous EU directive is persuasive but not directly binding; its adoption by Serbian courts is plausible but not confirmed for this specific question. Mark as `TODO(verify)`." Add any known specific gap (e.g. patent-termination scope, anti-Tivoization interpretation).

- **(c) Practical obligation for ERPNext.** Phrase as concrete action: "Preserve Cyrillic/Latin attribution notices in the distributed package", "retain COPYING/LICENSE file alongside binary distribution", "if distributing to Serbian consumers via a commercial channel, review Закон о заштити потрошача applicability", "register contributor copyright via ЗИС deposit **optionally** if evidentiary presumption is strategically valuable — not mandatory", "ensure contributors understand moral rights (чл. 14–18 ЗАСП) are inalienable regardless of CLA".

## 10. Common Pitfalls

- **Do not treat Serbia as an EU Member State.** EU regulations (not directives) that are directly applicable in MS — e.g. GDPR Regulation 2016/679 — are **not directly applicable** in Serbia. Serbia has its own GDPR-aligned Закон о заштити података о личности, but the legal basis is national.
- **Do not cite CJEU case law as binding.** It is persuasive. Always phrase "CJEU held X; Serbian courts have not yet ruled on the analogous question".
- **Do not confuse** Serbia (Србиja) with **Croatia** (EU Member since 2013, directly bound by Software Directive and CJEU), **Montenegro** (EU candidate, separate legal system), **North Macedonia** (EU candidate, separate), or **Bosnia and Herzegovina** (multi-entity federal structure, significantly different). These jurisdictions are **not interchangeable**.
- **Do not confuse** the **Serbian Civil Code** (in drafting for years, not yet enacted as of last skill revision) with the operative **ЗОО** (Закон о облигационим односима). Any citation like "Civil Code of Serbia art. X" is almost certainly wrong — cite ЗОО or specialised statutes.
- **Written-form requirement** (чл. 61 ст. 1 ЗАСП) is not fatal to FOSS. Electronic form is equivalent per чл. 72а ЗОО and the Закон о електронском документу. But the question of whether click-through acceptance of a GPL notice on GitHub qualifies as formal acceptance has no direct Serbian case law — mark `TODO(verify)` if this is the crux of the analysis.
- **Moral rights are inalienable** (чл. 14–18 ЗАСП). FOSS-license warranty disclaimers and liability limitations do **not** extinguish the right of paternity. Usually non-disruptive but worth stating.
- **National exhaustion** (чл. 26(3) ЗАСП) is narrower than EU-wide exhaustion. Relevant for cross-border distribution analysis involving Serbia.
- **Old statute numbering** from pre-2019 amendments may appear in academic literature. Always check against the current consolidated text on paragraf.rs or pravno-informacioni-sistem.rs.
- **Serbian is primary language.** Do not rely on English-language WIPO Lex summaries alone — they can lag amendments. Always verify against Serbian-language original.
- **Commercial court jurisdiction** (Привредни судови) is the first-instance forum for B2B FOSS disputes — not general basic courts. This matters when the user asks about procedural path for enforcement.

## 11. Output Constraints

- Statute citations: keep in Cyrillic form as found in the official text — "чл. 74 ЗАСП", "чл. 72а ЗОО". In mixed-script output, romanised form ("čl. 74 ZASP") is acceptable but less precise.
- Case citations: when available, use the court's own reference style — "ВКС, Рев. бр. XX/YYYY", "Привредни суд у Београду, XX Пл. бр. YY/YYYY".
- Gazette references: "'Сл. гласник РС', бр. 104/2009".
- Do not predict Serbian court outcomes. Describe what the statute says and mark gaps as `TODO(verify)`.
- Flag **any** reliance on CJEU case law as persuasive-not-binding.
- When the question involves cross-border elements (RS-EU or RS-US distribution), explicitly state where jurisdictional conflict rules (Хашка конвенција / Рим I Регулатива equivalents in RS practice) may shift the analysis.

## 12. Consequential Notes for ERPNext Context

- If ERPNext is **self-hosted by a Serbian customer on Serbian territory**, чл. 74 ЗАСП mandatory user rights attach to that customer — they may make a backup copy, correct errors necessary to use, observe functioning, and decompile for interoperability regardless of any license clause to the contrary.
- If ERPNext is **distributed to Serbia** by a third-party reseller, the distributor is bound by the project's GPL-3.0-or-later terms as a contractual condition under Serbian civil law — breach gives both contractual and copyright-infringement remedies.
- If ERPNext is **hosted as SaaS serving Serbian users** (no copy conveyed to users), **GPL-family copyleft is not triggered** in the same way it is for conveyed binaries — this mirrors the EU/US position but is not dependent on CJEU case law, simply on the text of "conveying" in GPL-3.0 §0. AGPL-3.0 would be relevant if network-use triggering were intended.
- **Data-protection intersection.** Serbian Закон о заштити података о личности (GDPR-aligned) applies if ERPNext processes personal data of Serbian residents — this is independent of the FOSS license and is **out of scope** for pure license analysis but worth flagging if the question context suggests data-processing concerns.
