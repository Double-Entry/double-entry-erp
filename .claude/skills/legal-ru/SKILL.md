---
name: legal-ru
description: Russian Federation FOSS-licensing legal knowledge base. Applicable law, statute articles, case law, authoritative bodies, and canonical sources for analyzing open-source license questions under RU jurisdiction. Used by the legal-licensing-researcher agent to populate the 🇷🇺 RU section of every tri/quad-jurisdictional legal finding. TRIGGER when analyzing OSS-license compliance, copyleft obligations, patent grants, attribution, or redistribution under Russian law. SKIP for non-licensing RU legal questions (employment, tax, corporate, trademark disputes beyond IP/licensing).
---

# Skill: legal-ru — Russian Federation FOSS-Licensing Knowledge Base

> **Disclaimer.** This skill provides informational reference material for automated FOSS-licensing analysis. It is not legal advice. Binding decisions require review by a qualified lawyer admitted in the Russian Federation.

## 1. Legal Tradition

Continental (civil-law) system. Intellectual property is codified in **Part IV of the Civil Code** (ГК РФ) — a single integrated statute covering all forms of IP. Case law is persuasive, not formally binding, but **Plenum Resolutions of the Supreme Court** have de-facto binding force on lower courts.

## 2. Core Statutes

### 2.1 ГК РФ Часть IV — Civil Code, Part IV

Enacted by ФЗ № 230-ФЗ of 18.12.2006, in force since 01.01.2008. Canonical text: http://pravo.gov.ru/ or http://www.consultant.ru/document/cons_doc_LAW_64629/

Articles most relevant to FOSS-licensing:

| Article | Subject | Notes |
|---------|---------|-------|
| ст. 1225 | List of protected results of intellectual activity | п. 2 — программы для ЭВМ |
| ст. 1229 | Exclusive right | Basis for licensor authority |
| ст. 1233 | Disposition of exclusive right | Framework for license agreements |
| ст. 1235 | License agreement — general provisions | Written form by default; simple/exclusive split |
| ст. 1236 | Types of licenses | Simple (non-exclusive) vs exclusive |
| ст. 1237 | Performance of license agreement | Obligations of licensee |
| ст. 1238 | Sub-license agreement | Requires licensor's written consent |
| ст. 1260 | Derivative and composite works | Foundation for copyleft/derivative-work analysis |
| ст. 1261 | Computer programs | Protected as literary works |
| ст. 1262 | State registration (optional) | Rospatent, not required for protection |
| ст. 1270 | Exclusive right to a work | Reproduction, distribution, etc. |
| ст. 1280 | Free use of a computer program | Backup copy, adaptation for own machine, decompilation for interoperability — roughly mirrors EU Software Directive art. 5–6 |
| **ст. 1286.1** | **Open license on a work** | **The key FOSS provision.** Introduced by ФЗ № 35-ФЗ of 12.03.2014. Recognizes open licenses as a form of adhesion contract (договор присоединения). Allows gratuitous licensing (п. 1). Written form **not required** — installation/use constitutes acceptance (п. 3). Simple (non-exclusive) by default (п. 2). |

### 2.2 152-ФЗ «О персональных данных» (27.07.2006)

Only relevant where a license clause materially interacts with personal-data processing (e.g. telemetry clauses). Most FOSS licenses are silent on data, so this statute is usually **out of scope** for pure license analysis.

### 2.3 ФЗ № 149-ФЗ «Об информации, информационных технологиях и о защите информации»

Peripherally relevant for software-distribution regulations. Rarely the primary basis for license analysis.

## 3. Key Authoritative Guidance

### 3.1 Постановление Пленума ВС РФ № 10 от 23.04.2019

«О применении части четвёртой Гражданского кодекса Российской Федерации». The single most important post-2008 authority on IP. Source: http://www.supcourt.ru/documents/own/27773/

Paragraphs relevant to OSS:

- **п. 37–39** — лицензионный договор: форма, существенные условия.
- **п. 40** — открытая лицензия (ст. 1286.1) признаётся как разновидность договора присоединения.
- **п. 48** — нарушение условий лицензионного договора; соотношение договорной и деликтной ответственности.
- **п. 88–91** — программы для ЭВМ: особенности охраны, декомпиляция, правомерное использование.

### 3.2 Pre-2019 Plenum Resolutions (superseded but historically cited)

- Постановление Пленумов ВС РФ и ВАС РФ № 5/29 от 26.03.2009 (superseded by 10/2019).
- Постановление Пленума ВАС РФ № 51 от 18.07.2014 (commercial court practice, superseded with VAS liquidation).

## 4. Case Law

Russian case law on **open-source licenses specifically** is **sparse**. The following patterns exist:

- **ПО-контрафакт cases** — criminal/civil cases under ст. 146 УК РФ / ст. 1301 ГК РФ against piracy of proprietary software. Numerous but not directly on-point for FOSS.
- **B2B licensing disputes** — enforcement of paid EULAs; general contract-law logic applies.
- **Copyleft enforcement** — no reported cases of GPL copyleft being enforced in Russian courts as of the last check. Mark any claim of established practice as `TODO(verify)`.
- **Дело ООО «Пексофт»** и аналогичные — споры о модульной архитектуре и производных произведениях (общие положения, не GPL-специфичные).

**When writing the RU section, default to:** «практика по принудительному исполнению copyleft в российских судах отсутствует; enforcement theoretically available через общий механизм нарушения лицензионного договора (ст. 1235, 1237 ГК РФ) + взыскание компенсации (ст. 1301 ГК РФ)».

## 5. Authoritative Bodies

- **Верховный Суд РФ** (supcourt.ru) — Пленумы, Обзоры судебной практики.
- **Роспатент** (rospatent.gov.ru) — добровольная государственная регистрация программ для ЭВМ (ст. 1262). Регистрация **не создаёт** и **не подтверждает** право — она лишь фиксирует факт депонирования.
- **Судебная система:** суды общей юрисдикции (бытовые споры граждан) + арбитражные суды (предпринимательские споры). IP-споры между юрлицами — арбитражные суды. **Суд по интеллектуальным правам (СИП)** — специализированный кассационный суд для IP-дел (ipc.arbitr.ru).

## 6. Canonical Sources (for WebFetch verification)

| Resource | URL | Use |
|----------|-----|-----|
| Pravo.gov.ru | http://pravo.gov.ru/ | Official statute text |
| КонсультантПлюс | http://www.consultant.ru/ | Consolidated commercial legal DB (most-used in practice) |
| Гарант | https://www.garant.ru/ | Alternative commercial legal DB |
| Верховный Суд РФ | http://www.supcourt.ru/ | Plenum resolutions, judicial reviews |
| СИП | http://ipc.arbitr.ru/ | IP-court decisions |
| Картотека арбитражных дел | https://kad.arbitr.ru/ | Arbitration-court case search |
| Sudact.ru | https://sudact.ru/ | General case-law search |

## 7. Applying This Skill to the (a)/(b)/(c) Structure

When drafting the 🇷🇺 RU section of a legal finding:

- **(a) What holds.** Cite ст. 1286.1 ГК РФ for open-license recognition, ст. 1235–1238 for license-agreement framework, ст. 1260/1270 for derivative works, Пленум ВС № 10/2019 para. 37–40/88–91 for authoritative interpretation.
- **(b) What is unsettled.** State explicitly the absence of dedicated copyleft-enforcement case law. Flag as `TODO(verify)` if the question touches patent-grant termination (e.g. Apache-2.0 §3 or GPL-3.0 §11), anti-Tivoization (GPL-3.0 §6), or cross-border enforcement — none of these have Russian precedent.
- **(c) Practical obligation for ERPNext.** Phrase as a concrete action: «включить в дистрибутив текст GPL-3.0 и файл COPYING», «сохранить атрибуцию в исходниках», «при публикации производного произведения — раскрыть исходный код в том же объёме, что и оригинал (ст. 1260 + условия GPL-3.0 §5)», и т. д.

## 8. Common Pitfalls

- **Не путать** гражданско-правовую ответственность (ст. 1301 — компенсация) с уголовной (ст. 146 УК РФ — контрафакт в крупном размере).
- **Не путать** государственную регистрацию ПО (ст. 1262) с возникновением права: право возникает с момента создания, регистрация факультативна.
- **Не ссылаться** на CJEU-практику как обязательную — в российских судах она не имеет прямой силы (хотя может цитироваться как доктринальный источник).
- **Не переносить** US fair-use логику на ст. 1274 ГК РФ (свободное использование в научных/информационных целях) — это разные институты с разным охватом.
- **Помнить:** моральные права автора (ст. 1265–1269 ГК РФ) неотчуждаемы, что может взаимодействовать с «no warranty» и «disclaimer of liability» клаузами FOSS-лицензий.

## 9. Output Constraints

- Statute citations: keep in original form — «ст. 1286.1 ГК РФ», «п. 40 Постановления Пленума ВС РФ № 10/2019».
- Case names: original transliteration or Cyrillic as in the source.
- Do not quote non-redistributable commercial DB content (КонсультантПлюс full texts) verbatim — cite article number and public source.
- Never predict court outcome. Describe what statute/Plenum says; flag gaps as `TODO(verify)`.
