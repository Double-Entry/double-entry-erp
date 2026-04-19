---
name: legal-ru
description: Russian Federation FOSS-licensing legal knowledge base — detailed. Applicable copyright law, civil contract framework, IP-related statutes, Supreme Court Plenum guidance, case law, authoritative bodies, and canonical sources for analyzing open-source license questions under RU jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇷🇺 RU section of every quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under Russian law. SKIP for non-licensing RU legal questions (employment, tax, criminal piracy beyond civil license enforcement, trademark disputes beyond IP/licensing).
---

# Skill: legal-ru — Russian Federation FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified lawyer (адвокат) admitted in the Russian Federation.

## 1. Jurisdictional Status and Legal Tradition

### 1.1 Status

**The Russian Federation** (Российская Федерация) is a sovereign state with a **unitary codified civil-law system**. IP is federally regulated — no regional copyright variation. Russia is a party to:
- **Berne Convention** for the Protection of Literary and Artistic Works (since 13.03.1995).
- **WIPO Copyright Treaty (WCT)** (since 05.02.2009).
- **WIPO Performances and Phonograms Treaty (WPPT)** (since 05.02.2009).
- **TRIPS Agreement** (since WTO accession 22.08.2012).
- **Rome Convention** on neighbouring rights (since 26.05.2003).

Russia is **not a party** to any OSS-specific treaty (none exist). The Paris Convention, PCT, and Madrid System cover patents/trademarks, not copyright — rarely material for pure FOSS analysis.

### 1.2 Legal tradition

Continental civil-law, codified tradition. Statutes are primary and comprehensive — the **Civil Code (ГК РФ)** is split into four parts, and all IP sits in **Part IV**. Case law is persuasive, not formally binding (no stare decisis). However, three kinds of judicial authority have de facto binding effect on lower courts:
- **Постановления Пленума Верховного Суда РФ** (Plenum Resolutions of the Supreme Court) — explicitly meant to ensure uniform application of law.
- **Обзоры судебной практики** (Reviews of Judicial Practice) approved by the Supreme Court Presidium.
- **Информационные письма Президиума ВАС РФ** — pre-2014 but still cited; VAS was liquidated and its functions absorbed by the Supreme Court.

### 1.3 Language and script

Official language — **Russian**, Cyrillic script. Statute texts published in "Собрание законодательства Российской Федерации" (Sobranie zakonodatelstva RF) and on **pravo.gov.ru** (official internet portal of legal information). When citing, keep Cyrillic article forms ("ст. 1286.1 ГК РФ", "п. 88 Постановления Пленума ВС РФ № 10/2019"). English transliteration is acceptable in mixed-script output but less precise.

## 2. Core Copyright Statute

### 2.1 Гражданский кодекс РФ — Часть IV

**Civil Code of the Russian Federation, Part IV** ("Об интеллектуальных правах"). Enacted by Federal Law № 230-ФЗ of 18.12.2006, in force since 01.01.2008. Consolidated current text available at:
- Canonical state portal: http://pravo.gov.ru/proxy/ips/?docbody=&nd=102110716
- КонсультантПлюс (commercial, most practitioner-used): http://www.consultant.ru/document/cons_doc_LAW_64629/
- Гарант (commercial alternative): https://base.garant.ru/10164072/

The statute has a four-level structure: Раздел VII — Главы 69–77 — Параграфы — Статьи. For FOSS analysis, the relevant map:

- **Глава 69** (ст. 1225–1254) — Общие положения об интеллектуальных правах.
- **Глава 70** (ст. 1255–1302) — Авторское право. **Primary chapter for FOSS.**
- **Глава 71** (ст. 1303–1344) — Права, смежные с авторскими (neighbouring rights).
- **Глава 72** (ст. 1345–1407) — Патентное право. Relevant only for patent-grant clause analysis.
- **Глава 76** (ст. 1473–1541) — Средства индивидуализации (trademarks, commercial designations). Out of scope for license analysis.
- **Глава 77** (ст. 1542–1551) — Единая технология. Rare.

### 2.2 Most FOSS-relevant articles with operational detail

| Article | Heading | Operational meaning for FOSS |
|---------|---------|------------------------------|
| ст. 1225 | Охраняемые результаты интеллектуальной деятельности | п. 2 — programs for EVM (computer programs) listed as protected RID. Foundation of all subsequent copyright analysis. |
| ст. 1226 | Интеллектуальные права | Personal non-property rights (paternity, integrity, inviolability) + exclusive (economic) rights. Only the latter is transferable via license. |
| ст. 1228 | Автор результата интеллектуальной деятельности | Authorship vests in the natural person who creates. Only natural persons are original authors; legal entities can only be rightholders by transfer. |
| ст. 1229 | Исключительное право | The rightholder's monopoly right to use the RID and authorize/prohibit others' use. This is what a license grants access to. |
| ст. 1233 | Распоряжение исключительным правом | Two mechanisms: уступка (assignment — full transfer) and лицензионный договор (license — permission). FOSS is always licensing, never assignment. |
| ст. 1235 | Лицензионный договор | General rules. п. 2 — written form is the default; exceptions exist (see ст. 1286 п. 5 for boxed-software, ст. 1286.1 for open licenses). п. 5 — remuneration is a material term for non-gratuitous licenses; gratuity must be explicit. п. 6 — term defaults to 5 years if unspecified and territory defaults to RF if unspecified. |
| ст. 1236 | Виды лицензионных договоров | простая (неисключительная) licence (default, multiple licensees allowed) vs исключительная (only one licensee, rightholder barred from granting further). FOSS is always non-exclusive. |
| ст. 1237 | Исполнение лицензионного договора | Licensee's obligations. п. 4 — licensee reports on use when required by the license. п. 3 — use beyond license limits triggers responsibility for copyright infringement, not contract breach. **Key distinction for copyleft enforcement: exceed license scope → infringement remedies (compensation under ст. 1301) available on top of contract remedies.** |
| ст. 1238 | Сублицензионный договор | Sub-licensing requires licensor's written consent. Most FOSS licenses grant this automatically. |
| ст. 1240 | Использование результата интеллектуальной деятельности в составе сложного объекта | Rules for composite objects (software suites). License to composite RID extends to constituent RIDs on explicit terms. |
| ст. 1253.1 | Ответственность информационного посредника | Safe-harbour rules for information intermediaries (hosts, transmitters). Relevant to distribution platforms hosting FOSS. |
| ст. 1256 | Действие исключительного права на территории Российской Федерации | Foreign authors' works protected under Berne Convention. Applies FOSS authored abroad. |
| ст. 1259 | Объекты авторских прав | List of protected works. п. 1 — программы для ЭВМ protected as literary works (same regime as books). |
| ст. 1260 | Переводы, иные производные произведения | **Derivative works.** Translator/adapter has rights only over their own contribution, not the underlying work. Using a derivative requires **both** original author's and derivative author's permission. Foundation for copyleft/derivative-work analysis. |
| ст. 1261 | Программы для ЭВМ | Specific regime: both source and object code protected; preparatory materials and interfaces protected if they reflect the author's creativity. Display screens are NOT protected as such. |
| ст. 1262 | Государственная регистрация программ для ЭВМ и баз данных | **Voluntary** registration at Rospatent. Does not create the right — right arises on creation. Creates evidentiary presumption of authorship (п. 6). Rarely used by international FOSS projects. |
| ст. 1265 | Право авторства и право автора на имя | **Inalienable moral rights.** Paternity (right to be recognized as author) + right to name (real name / pseudonym / anonymous). CANNOT be waived by contract. **Practical meaning for FOSS:** attribution cannot be stripped by a license clause, even one agreeing to anonymity. Contributors always retain this right. |
| ст. 1266 | Право на неприкосновенность произведения и защита произведения от искажений | Right of integrity. Protects against distortions that damage honour and dignity. **Does not prevent** adaptation/modification as such — the right interacts with moral harm, not technical change. |
| ст. 1267 | Охрана авторства, имени автора и неприкосновенности произведения после смерти автора | Post-mortem protection of moral rights. |
| ст. 1268 | Право на обнародование произведения | Right of first publication. Usually exercised when the work is committed to a public repository. |
| ст. 1269 | Право на отзыв | Right of withdrawal — author can revoke publication (with compensation). **Explicitly excluded** for programs for EVM (п. 1 in fine). Relevant because this means a Russian contributor who later regrets contributing to a GPL project CANNOT invoke ст. 1269 to claw back. |
| ст. 1270 | Исключительное право на произведение | The enumerated acts of exploitation: reproduction, distribution, public display, import, rental, public performance, translation/adaptation, making available to the public. |
| ст. 1272 | Распространение оригинала или экземпляров опубликованного произведения | **Exhaustion (first-sale) doctrine.** Once lawfully distributed by sale within RF, further distribution requires no permission — **except** for rental. Does not reach online/digital distribution in the UsedSoft sense; CJEU *UsedSoft* is NOT applied by Russian courts. |
| ст. 1273 | Свободное воспроизведение произведения в личных целях | Personal-use reproduction exception. **Does NOT apply to programs for EVM** (п. 1, подп. 4) — separate regime in ст. 1280. |
| ст. 1274 | Свободное использование произведения в информационных, научных, учебных или культурных целях | Quotation and educational-use exceptions. **Does NOT apply to programs for EVM.** |
| ст. 1280 | Право пользователя программы для ЭВМ и базы данных | **Foundational for FOSS under RU law.** Lawful user's mandatory rights — analogous to Software Directive art. 5 EU: (a) necessary use for intended purpose including error correction unless contractually provided otherwise; (b) backup copy; (c) decompilation for interoperability of independently created program; (d) observation, study, testing. п. 4 — contract terms **cannot restrict** decompilation for interoperability beyond statutory limits. |
| ст. 1286 | Лицензионный договор о предоставлении права использования произведения | Specific rules for licenses on works. п. 3 — contract with end-user of program for EVM can be concluded in **simplified form** through a written agreement accompanying a copy (box-license / click-wrap / shrink-wrap — all recognized). п. 5 — gratuity must be expressly agreed (contrast ст. 1235 п. 5 general rule). |
| **ст. 1286.1** | **Открытая лицензия на использование произведения науки, литературы или искусства** | **THE key FOSS provision.** Introduced by ФЗ № 35-ФЗ of 12.03.2014. п. 1 — open license is a **договор присоединения** (adhesion contract) on terms available to any person; all conditions must be accessible before use; acceptance is performed by starting to use the work on the specified terms. п. 2 — may be **gratuitous** unless a different rule is explicitly set. п. 3 — simple (non-exclusive) by default. п. 4 — if license does not specify territory, it is valid worldwide. п. 5 — term: for programs for EVM and databases, the whole term of exclusive right; for other works, 5 years unless otherwise stated. п. 6 — author retains right to grant permissions to others for similar use. **The statutory scaffold for recognizing GPL, MIT, Apache, and all major FOSS licenses in RU.** |
| ст. 1287 | Особые условия издательского лицензионного договора | Publication license. Rarely material for FOSS. |
| ст. 1295 | Служебное произведение | Work-for-hire. Exclusive right vests in employer absent contrary agreement, but author retains moral rights and a remuneration right for use. **Affects Russian contributors** on salaried development of FOSS — employer is the rightholder unless the work falls outside the employment scope. |
| ст. 1296 | Программы для ЭВМ и базы данных, созданные по заказу | Commissioned software. Exclusive right vests in the **customer** (заказчик) by default unless contract says otherwise. |
| ст. 1301 | Ответственность за нарушение исключительного права на произведение | **Statutory compensation** (компенсация) as alternative to damages — 10,000 to 5,000,000 RUB per violation, OR 2x cost of lawful use, OR 2x cost of pirated copies. Plaintiff need not prove actual damage. Key remedy for copyleft enforcement: if GPL condition breached → license terminated → further use = infringement → ст. 1301 compensation. |
| ст. 1302 | Обеспечение иска по делам о нарушении авторских прав | Preliminary injunctions specific to copyright actions. Seizure of infringing copies, accounts receivable from sale, etc. |

### 2.3 Treatment of open-source licenses under ст. 1286.1

ст. 1286.1 is the **statutory home of FOSS** in the Russian legal system. Its 2014 drafting deliberately tracked the international OSS model. Key legal effects:

**Formation.** An open license is a **договор присоединения** — the licensee does not negotiate individual terms, but accepts the pre-published license in toto. Acceptance is by **conduct** (use of the work on the stated terms, п. 1 абз. 2). No written signature, no click, no acknowledgement is required beyond the factual commencement of licensed use. This directly enables GPL's "You indicate your acceptance of this License to do so by modifying or propagating" (GPL-3.0 §9) and Apache-2.0's "You accept the License by using the Work".

**Gratuity.** п. 2 explicitly permits gratuitous licensing. This was the legislative response to the prior problem that ст. 1235 п. 5 treated remuneration as a material term — without ст. 1286.1 п. 2, gratuitous OSS licenses risked being characterised as unformed (несложившийся) contracts.

**Scope.** п. 3 — default simple (non-exclusive). п. 4 — territorial default is worldwide (contrast ст. 1235 п. 6's RF default). п. 5 — durational default for programs is the full term of exclusive right (life + 70 years per ст. 1281).

**Disclosure of terms.** п. 1 requires that "all conditions ... be accessible indefinitely". A license incorporated by URL reference, a LICENSE file in the distribution, or a notice embedded in source headers — all satisfy this.

**Author's retained rights.** п. 6 — author can grant the same or similar permissions to others. Preserves the foundational FOSS premise that the same code can be licensed under multiple open licenses simultaneously (dual licensing).

**Revocation.** п. 7 — the license may be **unilaterally revoked** by the author/rightholder by giving 30 days' notice **unless** the license expressly prohibits revocation for its stated term. GPL and major FOSS licenses do contain terms that operate as irrevocability for the term of copyright (GPL-3.0 §2 "all rights reserved or licensed" plus the §8 termination-for-breach structure). Russian commentary (Гаврилов, Калятин) treats this as a valid contractual waiver of ст. 1286.1 п. 7. But this **has not been tested in Russian courts** for a major FOSS license — mark `TODO(verify)` if the revocation question is central.

**Copyleft under ст. 1286.1.** Copyleft operates as a contractual condition: using the work in a derivative obligates downstream distribution under compatible terms. Breach = scope excess → ст. 1237 п. 3 → infringement → ст. 1301 remedies. Theory is clean; **no Russian court has enforced copyleft against a violating distributor** as of this skill's last revision.

### 2.4 Other IP-adjacent articles

| Article | Subject |
|---------|---------|
| ст. 1281 | Срок действия исключительного права на произведение | Life + 70 years. |
| ст. 1295 п. 2 | Servant works (работник/служебное) — employer as default rightholder |
| ст. 1357–1407 | Patent law. Relevant only if analyzing patent-grant clauses in FOSS (Apache-2.0 §3, GPL-3.0 §11). |
| ст. 1466 | Ноу-хау (secret of production) — separate regime, rarely material for FOSS. |

## 3. Contract Formation Framework — ГК РФ Parts I and II

### 3.1 ГК РФ Часть первая — общие положения о договоре

Relevant general articles that fill in where Part IV is silent:

| Article | Subject | Relevance |
|---------|---------|-----------|
| ст. 8 | Основания возникновения гражданских прав и обязанностей | Contract as a ground for rights/obligations. |
| ст. 160 | Письменная форма сделки | Written form rules. Exchange of electronic documents satisfies written form (п. 2). |
| ст. 162 | Последствия несоблюдения простой письменной формы сделки | Non-compliance with written form typically does not void the transaction but bars oral evidence. |
| ст. 421 | Свобода договора | Freedom of contract; parties may enter any agreement not contrary to law. Foundation of the recognition of novel contract types like ст. 1286.1 adhesion licenses. |
| ст. 422 | Договор и закон | Contract must conform to mandatory rules existing at conclusion. |
| **ст. 428** | **Договор присоединения** | **Adhesion contract — the general form** that ст. 1286.1 specialises. Terms are drafted by one party; other party either accepts in toto or declines. Protections: adhering party may demand contract revision/termination if terms are objectively unfair. GPL, Apache, MIT are all договоры присоединения in this sense. |
| ст. 432 | Основные положения о заключении договора | Essential terms; a contract is formed when parties agree on all essential terms. |
| ст. 433 | Момент заключения договора | Contract is formed when acceptance is received by offeror. For adhesion contracts (ст. 428), formed when adherent performs conforming conduct. |
| ст. 434 | Форма договора | Forms: written (including electronic), oral, by conduct. |
| ст. 438 | Акцепт | Acceptance can be by conduct satisfying the contract's terms (п. 3). This is the general-law basis for GPL "acceptance by use". |
| ст. 450 | Основания изменения и расторжения договора | Grounds for modification/termination. GPL-3.0 §8 "terminates automatically on breach" operates through ст. 450 п. 2 (termination on material breach) read alongside ст. 1286.1. |

### 3.2 ГК РФ Часть вторая — обязательства

For license agreements:

| Article | Subject |
|---------|---------|
| ст. 702 et seq. | Подряд — out of scope for pure license. |
| ст. 769 et seq. | Договоры на НИОКР — R&D contracts; may bear on commissioned FOSS contributions. |
| ст. 779 | Договор возмездного оказания услуг | Services contract — not directly applicable to FOSS unless the question involves support/maintenance arrangements. |

### 3.3 Electronic documents

**Federal Law № 63-ФЗ of 06.04.2011 "Об электронной подписи"** — regulates electronic signatures; simple, enhanced unqualified, and enhanced qualified variants. For FOSS-license formation, acceptance by use obviates the need for a signature entirely — but for CLA-like corporate attestations, enhanced signature may be needed.

**Federal Law № 149-ФЗ of 27.07.2006 "Об информации, информационных технологиях и о защите информации"** — governs information technology generally. Regulates information intermediaries and hosting providers; peripheral to pure FOSS license analysis.

## 4. Related IP and Adjacent Statutes

| Statute | Core relevance |
|---------|-----------------|
| **Federal Law № 152-ФЗ of 27.07.2006 "О персональных данных"** | Russian personal-data regulation, substantially post-2016 amended. Stricter than GDPR in some respects (data-localisation requirement for Russian residents' data per ст. 18 п. 5). Material **only** where a specific FOSS license clause interacts with data processing — rare. Regulator: Роскомнадзор. |
| ФЗ № 187-ФЗ of 02.07.2013 "О внесении изменений..." (Anti-Piracy Law) | Procedures for blocking pirated content. Not OSS-specific but referenced when online enforcement is discussed. |
| Уголовный кодекс РФ, ст. 146 | Criminal offence: willful infringement of authorship/related rights at large scale. Thresholds: свыше 100 000 ₽ (крупный), 1 000 000 ₽ (особо крупный). Rarely invoked for FOSS but theoretically available against wilful copyleft violators causing large-scale harm. |
| Кодекс об административных правонарушениях, ст. 7.12 | Administrative liability for copyright infringement below criminal thresholds. Fines for individuals / officials / legal persons. |

## 5. International Obligations Affecting RU FOSS Analysis

- **Berne Convention arts. 5, 6bis** — national treatment for foreign-authored works; moral rights at minimum for paternity and integrity. Russia applies this to all FOSS authored by Berne-country nationals (essentially all of them).
- **TRIPS art. 10** — computer programs protected as literary works under Berne. Russia complied via ст. 1261.
- **WCT arts. 4, 7, 8** — protection for computer programs; reproduction right; right of communication to the public. Implemented via ст. 1261 + ст. 1270.
- **No direct effect.** None of these treaties are self-executing in Russian courts; rights are vindicated through domestic law that transposes them. A Russian court will not award a remedy citing "Berne art. 6bis" directly; it will cite ст. 1265 ГК РФ which implements the same principle.

## 6. Case Law and Authoritative Guidance

### 6.1 Court hierarchy

- **Суды общей юрисдикции** — general-jurisdiction courts. IP disputes between **individuals** (natural-person-on-natural-person). Rare for B2B FOSS matters.
- **Арбитражные суды** — commercial courts (confusingly named — these are state courts, not private arbitration). **First-instance jurisdiction for IP disputes between legal persons and individual entrepreneurs.** Most B2B FOSS-licensing disputes would land here.
- **Арбитражные апелляционные суды** — appellate layer; 21 courts nationwide.
- **Арбитражные суды округов (кассация)** — 10 circuit cassation courts.
- **Суд по интеллектуальным правам (СИП)** — specialised IP court. Primary jurisdiction over:
  - Challenges to normative acts in IP (ст. 43.4 Закона "Об арбитражных судах").
  - Cassation review of IP cases decided by arbitration courts and СИП itself sitting as first instance.
  - First-instance over Rospatent decisions and patent-validity issues.
  - **Not** generally first-instance for contractual license disputes — those go to ordinary arbitration courts first.
- **Верховный Суд РФ (ВС РФ)** — supreme court. Extraordinary cassation, supervisory review, issues binding Plenum Resolutions and Reviews.
- **Конституционный Суд РФ** — constitutional review. Rare to intersect with FOSS.

### 6.2 Плановые постановления и обзоры (authoritative guidance)

**Постановление Пленума ВС РФ № 10 от 23.04.2019** «О применении части четвертой Гражданского кодекса Российской Федерации». The single most important post-2008 authority on IP. Source: http://www.supcourt.ru/documents/own/27773/ (official PDF). Paragraphs material to FOSS:

| Paragraph | Subject |
|-----------|---------|
| п. 37–39 | License agreement — form, essential terms, effect of written-form non-compliance. |
| п. 40 | **Open license (ст. 1286.1) — recognised as a form of adhesion contract (ст. 428).** States that acceptance by use is sufficient, and the license is enforceable against the user who commenced use on the published terms. **Primary authority for FOSS recognition.** |
| п. 43 | Sublicensing under ст. 1238 — written consent requirement. |
| п. 48 | **Scope excess (пользование за пределами лицензии).** Use beyond license scope triggers infringement liability under ст. 1229 + ст. 1301 — NOT just contract damages. **Primary authority for copyleft-breach → infringement chain.** |
| п. 57–58 | Remedies for infringement — compensation under ст. 1301, preliminary injunction. |
| п. 79 | Personal non-property rights — paternity, integrity; inalienability. |
| п. 88 | **Programs for EVM — protection scope.** Source code, object code, preparatory materials, audiovisual display if creatively original. |
| п. 89 | Lawful user's rights under ст. 1280 — mandatory; cannot be restricted beyond statutory limits. |
| п. 90 | Decompilation for interoperability. |
| п. 91 | Modification of a program — requires rightholder's permission absent statutory exception. |
| п. 109 | Compensation under ст. 1301 — per violation; court-assessed within statutory range. |

**Other relevant authorities:**

- **Обзор судебной практики Верховного Суда РФ № 3 (2018)**, вопрос № 8 — on authorship of programs for EVM. Clarifies that programmer's contribution, not just project-level direction, is the basis for authorship.
- **Постановление Пленума ВС РФ № 25 от 23.06.2015** — on ГК РФ Part I; includes interpretation of ст. 428 (adhesion contracts) that applies analogically to ст. 1286.1.
- **Постановление Пленума ВАС РФ № 51 от 18.07.2014** (pre-VAS-liquidation) — on commercial court practice in IP; cited for historical continuity.

Pre-2019 authorities largely superseded: Постановление Пленумов ВС РФ и ВАС РФ № 5/29 of 26.03.2009 (superseded by 10/2019), though specific paragraphs may still be cited where 10/2019 is silent.

### 6.3 Case law on OSS-adjacent matters

Russian case law directly on **FOSS license enforcement** is **sparse to non-existent**. The following patterns appear:

- **B2B license-scope disputes (proprietary).** Extensive. Use beyond license terms → compensation under ст. 1301 routinely awarded. These cases establish the analytical framework that would apply to FOSS copyleft breach by analogy, but the licenses analyzed are proprietary.
- **ПО-контрафакт (software counterfeit).** Criminal and civil actions against piracy. Numerous (e.g. Microsoft, Adobe, Autodesk v. Russian distributors). Not on-point for FOSS copyleft but relevant for general remedies jurisprudence.
- **Open-license-specific decisions.** No reported published decisions at appellate level squarely enforcing GPL, MIT, Apache, or any major FOSS license as of this skill's last revision. **Mark any assertion of specific Russian FOSS precedent as `TODO(verify)`.**
- **Case search:**
  - **Картотека арбитражных дел (kad.arbitr.ru)** — arbitration case search.
  - **Base ВС РФ (vsrf.ru/search)** — Supreme Court decisions.
  - **СИП (ipc.arbitr.ru)** — IP court decisions.
  - **sudact.ru** — aggregator; useful but not authoritative.
  - **consultant.ru** practice bank — paid; most comprehensive.

**Default framing for the (b) "What is unsettled" subsection on any FOSS question in the RU section:**
> "Russian judicial practice on open-source license enforcement is not established at published-appellate level. Analysis proceeds from statutory text (ст. 1286.1 + ст. 1235–1238 + ст. 1260/1270 ГК РФ) and Постановление Пленума ВС РФ № 10/2019 para. 40, 48, 88–91. Mark any assertion of specific FOSS precedent as `TODO(verify)`."

## 7. Authoritative Bodies

| Body | Role | URL |
|------|------|-----|
| **Верховный Суд РФ** | Plenum resolutions, Reviews of judicial practice, extraordinary cassation | http://www.supcourt.ru/ |
| **Конституционный Суд РФ** | Constitutional review | http://www.ksrf.ru/ |
| **Суд по интеллектуальным правам (СИП)** | Specialised IP court | http://ipc.arbitr.ru/ |
| **Роспатент** (Федеральная служба по интеллектуальной собственности) | Voluntary registration of programs for EVM and databases per ст. 1262; patents; trademarks | https://rospatent.gov.ru/ |
| **Роскомнадзор** | Data-protection regulator (152-ФЗ); anti-piracy content blocking | https://rkn.gov.ru/ |
| **Минэкономразвития / Минцифры** | Policy formation in digital economy and IP modernisation | https://www.economy.gov.ru/, https://digital.gov.ru/ |
| **Ассоциация разработчиков программного обеспечения (АРПО) / АПКИТ** | Industry trade associations — not regulators, but produce commentary cited in court | https://apkit.ru/ |

**Note on Роспатент registration.** Voluntary deposit of a program under ст. 1262 does not create the right. Its evidentiary function (п. 6) is a rebuttable presumption that the named person is the author. For international FOSS projects relying on git commit history, registration is rarely material. If a Russian contributor is uncertain about provenance (e.g. disputed work-for-hire with employer), registration can pre-empt some evidentiary disputes.

## 8. Canonical Sources (for WebFetch verification)

| Resource | URL | Use |
|----------|-----|-----|
| **Официальный интернет-портал правовой информации** | http://pravo.gov.ru/ | Primary — official publication of federal laws. |
| **Собрание законодательства РФ (архив)** | http://szrf.ru/ | Archive of SZ RF Gazette. |
| **КонсультантПлюс** | http://www.consultant.ru/ | Most-used commercial legal database — consolidated statute + annotated practice. |
| **Гарант** | https://www.garant.ru/ | Alternative commercial legal database. |
| **Верховный Суд РФ** | http://www.supcourt.ru/ | Plenum resolutions + Reviews. |
| **СИП** | http://ipc.arbitr.ru/ | IP-court decisions. |
| **Картотека арбитражных дел (КАД)** | https://kad.arbitr.ru/ | Arbitration-court case search. |
| **Sudact.ru** | https://sudact.ru/ | General case-law aggregator. |
| **Rospatent реестр** | https://rupto.ru/ru/registers | Program and database registrations. |
| **Pravo.ru** | https://pravo.ru/ | Legal news and practice commentary (not authoritative but useful). |

## 9. Applying This Skill to the (a)/(b)/(c) Structure

Canonical reasoning chain for the 🇷🇺 RU section of a legal finding:

**(a) What holds.**

Anchor by license type:
- For any FOSS license question: cite **ст. 1286.1 ГК РФ** for statutory recognition of open licenses + **Постановление Пленума ВС РФ № 10/2019 п. 40** for authoritative interpretation.
- For derivative-work / copyleft scope: cite **ст. 1260 + ст. 1270 + ст. 1261 п. 1 ГК РФ**.
- For scope-excess → infringement path: cite **ст. 1237 п. 3 + Постановление Пленума ВС РФ № 10/2019 п. 48**.
- For lawful-user mandatory rights: cite **ст. 1280 ГК РФ + Постановление Пленума ВС РФ № 10/2019 п. 89–90** (backup, error correction, decompilation for interoperability).
- For remedies on breach: cite **ст. 1301 ГК РФ + Пленум 10/2019 п. 109** — compensation 10,000 – 5,000,000 RUB per violation.
- For attribution/moral rights: cite **ст. 1265 ГК РФ + Пленум 10/2019 п. 79** — inalienable, cannot be waived.

**(b) What is unsettled.**

Default clause: "Russian case law on open-source license enforcement at published-appellate level is not established. Analysis proceeds from statutory text and Постановление Пленума ВС РФ № 10/2019." Add any of the following specific gaps as applicable:
- Copyleft enforcement against a violating distributor (no reported case).
- Patent-termination clause enforcement (Apache-2.0 §3, GPL-3.0 §11) — no Russian case law on the substantive patent-retaliation mechanism.
- Anti-Tivoization / installation-information (GPL-3.0 §6) — no Russian interpretation; intersection with Russian consumer-protection law of embedded devices is untested.
- ст. 1286.1 п. 7 revocation — open question whether GPL's irrevocability provisions are enforceable as a waiver of the 30-day revocation right.
- Cross-border enforcement (a Russian distributor of code authored abroad) — standard conflict-of-laws analysis under Part VI of ГК РФ applies, untested for FOSS.

Mark each with `TODO(verify)`.

**(c) Practical obligation for ERPNext.**

Phrase as concrete acts under Russian law:
- «Сохранить атрибуцию авторов в исходном коде — ст. 1265 ГК РФ делает право на имя неотчуждаемым.»
- «Включить полный текст GPL-3.0 или ссылку на каноничный источник в дистрибутив — п. 1 ст. 1286.1 требует доступности всех условий.»
- «При распространении производного произведения — соблюсти условия copyleft, иначе использование считается выходящим за пределы лицензии (ст. 1237 п. 3) и влечёт ответственность по ст. 1301.»
- «Для корпоративных разработчиков, создающих вклад в рабочем порядке, — проверить служебный статус произведения (ст. 1295) и наличие передачи прав работодателем.»
- «Регистрация в Роспатенте (ст. 1262) — опционально; может быть полезна при спорах о провенанс-цепочке, но не обязательна.»

## 10. Common Pitfalls

1. **Не путать уступку и лицензию.** ст. 1234 (уступка — полная передача исключительного права) ≠ ст. 1235 (лицензия — предоставление права пользования). FOSS — всегда лицензия.
2. **Не путать** гражданско-правовую ответственность (ст. 1301 — компенсация как альтернатива убыткам) с **уголовной** (ст. 146 УК РФ — только при крупном ущербе и умысле).
3. **Не путать** государственную регистрацию программы (ст. 1262) с возникновением права: право возникает с момента создания; регистрация факультативна и создаёт лишь доказательственную презумпцию.
4. **Не ссылаться на практику CJEU** как на обязательную. В российских судах CJEU-решения не имеют прямой силы. Может цитироваться как доктринальный источник, но не как связывающая норма.
5. **Не переносить** US fair-use логику на ст. 1273–1275 ГК РФ. Это свободное использование в строго перечисленных целях (личное пользование — не для программ; информационное/научное/учебное — не для программ); объём уже, четырёхфакторный тест не применяется.
6. **Моральные права автора (ст. 1265–1269 ГК РФ) неотчуждаемы.** Клауза «No warranty» или «Disclaimer of liability» НЕ отменяет право на имя. Атрибуция — не то, что можно выключить лицензионным пунктом.
7. **Не применять ст. 1272 (исчерпание) к цифровой дистрибуции.** Российская доктрина исчерпания привязана к материальному носителю, лавная проданному на территории РФ. CJEU *UsedSoft* не применяется.
8. **ст. 1286.1 п. 7 — revocation в 30 дней.** Академически считается, что лицензии типа GPL содержат эффективный отказ от этого права на срок действия исключительного права, но судебно это не подтверждено. При вопросах по отзыву — `TODO(verify)`.
9. **Не смешивать** «открытую лицензию» (ст. 1286.1) с «общественным достоянием» (ст. 1282). Ст. 1286.1 — контрактный механизм; общественное достояние — истечение срока охраны.
10. **Работа по служебному заданию (ст. 1295).** Если российский разработчик в штате компании пишет вклад в GPL-проект в рабочее время и на тему работодателя — по дефолту исключительное право у работодателя. Контрибуция без CLA или явной передачи может быть оспорена работодателем позднее.
11. **Не использовать устаревшие акты.** Закон РФ от 09.07.1993 № 5351-1 «Об авторском праве и смежных правах» и ФЗ от 23.09.1992 № 3523-1 «О правовой охране программ для ЭВМ» **утратили силу** 01.01.2008; встречаются в старой литературе. Любая ссылка на них — ошибка.
12. **Двойная ответственность.** Нарушитель может быть одновременно обязан по договору (контрактные убытки) и вне договора (компенсация по ст. 1301) — см. Пленум 10/2019 п. 48.
13. **Коммерческие суды ≠ third-party arbitration.** «Арбитражный суд» в российском контексте — государственный коммерческий суд. Третейское разбирательство (international arbitration) — отдельно.

## 11. Output Constraints

- Statute citations: Cyrillic canonical form — «ст. 1286.1 ГК РФ», «п. 3 ст. 1235 ГК РФ», «п. 40 Постановления Пленума ВС РФ № 10/2019».
- Case citations: arbitration-court style — «Дело № А40-XXXXX/YYYY», «Определение ВС РФ № XXX-ЭС-XX-XXXXX от DD.MM.YYYY», «Постановление СИП от DD.MM.YYYY по делу № СИП-XXXX/YYYY».
- Gazette references: «СЗ РФ, YYYY, № NN, ст. NNNN» или «Российская газета» для первичной публикации.
- Do not quote non-redistributable commercial DB content (КонсультантПлюс full texts) verbatim — cite article number and public source via pravo.gov.ru.
- Never predict court outcome. Describe what statute/Plenum says; flag gaps as `TODO(verify)`.
- Use English translations of Russian statute names only in parenthetical clarification, not as primary citation — "ст. 1286.1 ГК РФ (open license on a work)".
- When mixing Cyrillic and Latin output, keep statute citations Cyrillic; license identifiers (SPDX) Latin.

## 12. Consequential Notes for ERPNext Context

- **Self-hosted Russian customer.** A Russian customer deploying ERPNext on-premise on RF territory is a "lawful user" under ст. 1280. Their **mandatory** rights — error correction, backup, observation, decompilation for interoperability — attach **regardless** of any license clause to the contrary. Applies automatically; no license action needed.
- **Distribution of ERPNext to Russia by a third party.** The distributor (Russian reseller, VAR, SaaS-provider with on-premise delivery of copies) is bound by GPL-3.0-or-later as an adhesion license under ст. 1286.1. Breach of GPL conditions → license scope exceeded → ст. 1237 п. 3 + ст. 1301 compensation remedies available.
- **SaaS deployment serving Russian users** (no copy conveyed to users). **GPL-family copyleft is not triggered** under the text of GPL-3.0 §0 — "conveying" means transferring a copy, not running the software for others. This mirrors US/EU position and is robust under Russian statutory reading; AGPL-3.0 would be required to trigger network-use copyleft.
- **Russian contributor creates a contribution in employment capacity.** If the work is служебное (ст. 1295), employer is the default rightholder. Contribution to the GPL project without explicit employer permission may be later challenged by the employer as invalid delivery of rights. **Practical mitigation:** employer-issued written authorisation (a lightweight CLA equivalent) before contribution.
- **Rospatent registration.** Optional but may be strategically useful when a Russian rightholder anticipates contention over provenance. For international FOSS maintained by a foreign entity, generally not registered.
- **Data-processing intersection.** If ERPNext deployed in RF processes personal data of Russian residents, 152-ФЗ applies — including **data-localisation requirement** (ст. 18 п. 5) that primary data storage occur on servers within RF. This is independent of FOSS licensing but is a routine accompaniment of any software-distribution question involving RF operations. **Out of scope for pure license analysis.**
- **Import/export controls.** Russian export-control framework (ФЗ № 183-ФЗ "Об экспортном контроле") rarely touches mass-market civilian FOSS. Encryption-containing software may be subject to notification under Regulation 29.07.2024 № 1034; analyze specifically if encryption-heavy dependencies are in scope.
- **Sanctions environment.** Post-2022 sanctions regime (EU, US, UK) restricts certain categories of technology transfer TO Russia and availability of certain platforms FOR Russia. This is **not a copyright-licensing matter** but may affect whether distribution to RF is commercially/legally viable. Flag as context but not as license analysis. **Out of scope for pure FOSS license analysis.**
- **Currency of citations.** ГК РФ Part IV is amended frequently. Last major amendments affecting programs for EVM: ФЗ № 35-ФЗ of 12.03.2014 (introduced ст. 1286.1); ФЗ № 166-ФЗ of 01.07.2017 (amendments to ст. 1235, 1286); ФЗ № 149-ФЗ of 11.06.2021 (further clarifications). Always verify the current consolidated text via pravo.gov.ru or КонсультантПлюс.
