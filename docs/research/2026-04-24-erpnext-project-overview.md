---
date: 2026-04-24
researcher: codebase-researcher
commit: 93aa0d8cfa
branch: feat/setting-claude
question: "Расскажи что это за проект и какова его структура"
status: complete
affected_doctypes: []
affected_modules:
  - Accounts
  - CRM
  - Buying
  - Projects
  - Selling
  - Setup
  - Manufacturing
  - Stock
  - Support
  - Utilities
  - Assets
  - Portal
  - Maintenance
  - Regional
  - ERPNext Integrations
  - Quality Management
  - Communication
  - Telephony
  - Bulk Transaction
  - Subcontracting
  - EDI
related_docs:
  - ../architecture/overview.md
  - ../architecture/controllers.md
  - ../architecture/doctype-pattern.md
  - ../architecture/hooks-and-overrides.md
  - ../getting-started/README.md
  - ../getting-started/development.md
  - ../README.md
  - 2026-04-24-erpnext-monolith-vs-microservices.md
---

# Исследование: Что такое ERPNext и какова его структура

## Резюме

**ERPNext — это open-source ERP-система**, построенная как **Frappe-приложение** поверх Frappe Framework. Это единый Python-пакет (`name = "erpnext"`, `description = "Open Source ERP"`, [pyproject.toml:1-8](pyproject.toml:1)) под лицензией **GPL-3.0** ([package.json:10](package.json:10)), установленный внутрь `bench`-окружения и зависящий от Frappe как от in-process платформы (`frappe = ">=17.0.0-dev,<18.0.0"` — [pyproject.toml:40-41](pyproject.toml:40)). Стек: **Python ≥3.14** ([pyproject.toml:7](pyproject.toml:7)), JavaScript/Vue для фронтенда, **MariaDB или PostgreSQL** под данными, Redis для кеша/очередей/pub-sub. Авторы — Frappe Technologies Pvt Ltd ([pyproject.toml:3-5](pyproject.toml:3)).

Архитектурно ERPNext — **модульный монолит** (см. [2026-04-24-erpnext-monolith-vs-microservices.md](2026-04-24-erpnext-monolith-vs-microservices.md) для полного обоснования): 21 логический модуль внутри одного дерева `erpnext/<module>/` ([modules.txt:1-21](erpnext/modules.txt:1)), общая БД, общий процесс. Базовая идиома — **DocType-паттерн**: каждая бизнес-сущность описывается четырьмя файлами (`<name>.json` схема, `<name>.py` серверный контроллер, `<name>.js` клиентский скрипт, `test_<name>.py` тесты) в каталоге `erpnext/<module>/doctype/<name>/` ([docs/architecture/doctype-pattern.md](docs/architecture/doctype-pattern.md), [docs/architecture/overview.md:26](docs/architecture/overview.md:26)).

Транзакционные DocType наследуют фиксированную **иерархию контроллеров**: `StatusUpdater → AccountsController → StockController → SellingController` (сторона продаж) или `StockController → SubcontractingController → BuyingController` (сторона закупок), все из `erpnext/controllers/` ([docs/architecture/overview.md:17](docs/architecture/overview.md:17), [docs/architecture/controllers.md](docs/architecture/controllers.md)). Всё кросс-модульное поведение (жизненный цикл `doc_events`, фоновые джобы `scheduler_events`, региональные оверрайды `regional_overrides`, меню портала, данные boot-сессии, миграции) зарегистрировано в **одном** центральном файле [erpnext/hooks.py](erpnext/hooks.py:1) (713 строк). Страновая логика живёт под `erpnext/regional/<country>/` и подключается через `regional_overrides`; миграции БД — под `erpnext/patches/` и перечислены в `erpnext/patches.txt`.

## Подробные находки

### 1. Что это за проект

- **Назначение.** Open Source ERP: учёт (Accounts), склад (Stock), продажи (Selling), закупки (Buying), производство (Manufacturing), проекты (Projects), основные средства (Assets), CRM, поддержка (Support), качество (Quality Management) и др. ([modules.txt:1-21](erpnext/modules.txt:1)).
- **Базовый фреймворк.** Frappe Framework. ERPNext не запускается сам по себе — это `bench`-app: `Document`, ORM, форма, права, фоновый раннер, вебсервер — всё предоставляется Frappe ([docs/architecture/overview.md:81-88](docs/architecture/overview.md:81)).
- **Стек.**
  - Python `>=3.14` ([pyproject.toml:7](pyproject.toml:7)); Ruff как линтер/форматтер, `line-length = 110`, tab-indent ([pyproject.toml:43-78](pyproject.toml:43)).
  - JS-зависимость — только `onscan.js` на уровне app ([package.json:15-17](package.json:15)); остальной фронт приходит из Frappe.
  - БД — MariaDB 10.6 либо PostgreSQL; Redis × 3 (cache / queue / socketio); Node SocketIO ([docs/getting-started/development.md](docs/getting-started/development.md)).
  - Интеграционные Python-зависимости: `googlemaps`, `plaid-python`, `python-youtube`, `mt-940` (парсер банковских выписок), `holidays`, `barcodenumber`, `rapidfuzz`, `Unidecode`, `pypng` ([pyproject.toml:10-26](pyproject.toml:10)).
- **Лицензия.** `GPL-3.0` ([package.json:10](package.json:10)); юридические документы в корне — [license.txt](license.txt), [TRADEMARK_POLICY.md](TRADEMARK_POLICY.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [SECURITY.md](SECURITY.md).
- **Связь с Frappe.** ERPNext — это **один Frappe-app**: метаданные приложения заданы в [erpnext/hooks.py:1-11](erpnext/hooks.py:1) (`app_name = "erpnext"`, `app_title`, `app_publisher`, `app_home = "/desk"`), единый app-level JS/CSS bundle подключается там же. Устанавливается командой `bench get-app erpnext` после `bench get-app payments` (см. ADR 0004 — [docs/adr/0004-payments-app-dependency.md](docs/adr/0004-payments-app-dependency.md)).

### 2. Высокоуровневая архитектура

- **Модульный монолит.** Один пакет, одна БД, один процесс; 21 модуль — это подкаталоги, а не сервисы. Подробное обоснование и цитаты — в [2026-04-24-erpnext-monolith-vs-microservices.md](2026-04-24-erpnext-monolith-vs-microservices.md).
- **DocType-паттерн.** Бизнес-сущность = 4 файла в `erpnext/<module>/doctype/<name>/`:
  - `<name>.json` — схема, права, workflow, дочерние таблицы (источник истины);
  - `<name>.py` — контроллер, наследующий `Document` или класс из `erpnext/controllers/`;
  - `<name>.js` — клиентский скрипт формы;
  - `test_<name>.py` — тесты (расширяют `ERPNextTestSuite` из [erpnext/tests/utils.py](erpnext/tests/utils.py)).
  Детали — [docs/architecture/doctype-pattern.md](docs/architecture/doctype-pattern.md).
- **Иерархия контроллеров** ([docs/architecture/controllers.md](docs/architecture/controllers.md)):

  ```
  StatusUpdater (Document)                  erpnext/controllers/status_updater.py
    └── AccountsController (TransactionBase) erpnext/controllers/accounts_controller.py
          └── StockController                 erpnext/controllers/stock_controller.py
                ├── SellingController          erpnext/controllers/selling_controller.py
                │     → Quotation, Sales Order, Delivery Note, Sales Invoice
                └── SubcontractingController   erpnext/controllers/subcontracting_controller.py
                      └── BuyingController     erpnext/controllers/buying_controller.py
                            → Material Request, RFQ, Purchase Order / Receipt / Invoice
  ```

  Ответственности: `StatusUpdater` — каскад статусов между связанными документами; `AccountsController` — GL, налоги, расписание платежей; `StockController` — SLE, QC, batch/serial; `SellingController`/`BuyingController` — специфические валидации. Дисциплина `super()`-вызовов описана в [docs/architecture/controllers.md](docs/architecture/controllers.md) и [docs/architecture/doctype-lifecycle.md](docs/architecture/doctype-lifecycle.md).
- **Жизненный цикл документа.** `validate → before_save → before_submit → on_submit → on_update_after_submit → on_cancel → on_trash`; вклад каждого слоя контроллера — в [docs/architecture/doctype-lifecycle.md](docs/architecture/doctype-lifecycle.md).
- **`hooks.py` как центральная точка регистрации.** [erpnext/hooks.py](erpnext/hooks.py:1) (713 строк) содержит: `doc_events` (кросс-срезы по DocType), `scheduler_events` (cron/hourly/daily/weekly/monthly джобы), `regional_overrides` (страновые оверрайды), `override_whitelisted_methods`, `extend_doctype_class`, `website_route_rules`, `standard_portal_menu_items`, `boot_session`, `notification_config`, `accounting_dimension_doctypes`, `auto_cancel_exempted_doctypes` (политика неизменяемого журнала) и др. Полный каталог — [docs/architecture/hooks-and-overrides.md](docs/architecture/hooks-and-overrides.md) + [docs/architecture/hooks-catalogue.md](docs/architecture/hooks-catalogue.md).
- **Региональные оверрайды.** Паттерн `@erpnext.allow_regional` + реестр `regional_overrides` в `hooks.py` позволяет подменять тело функции per-country без правки ядра. Определение декоратора — [erpnext/__init__.py:135](erpnext/__init__.py:135); страновой код — `erpnext/regional/<country>/`. См. ADR 0002 — [docs/adr/0002-regional-overrides-pattern.md](docs/adr/0002-regional-overrides-pattern.md) и [docs/patterns/regional-overrides.md](docs/patterns/regional-overrides.md).
- **Патчи (миграции БД).** `erpnext/patches/` + манифест `erpnext/patches.txt` (секции `[pre_model_sync]` / `[post_model_sync]`). Запускаются автоматически при `bench migrate`. См. [docs/patterns/patches.md](docs/patterns/patches.md).
- **Неизменяемый журнал.** GL Entry / SLE / PLE / Account Closing Balance исключены из auto-cancel; отмена пишет reverse-строки с `is_cancelled=1` вместо мутации оригиналов (`auto_cancel_exempted_doctypes` в [erpnext/hooks.py:418](erpnext/hooks.py:418); ADR 0001 — [docs/adr/0001-immutable-ledger.md](docs/adr/0001-immutable-ledger.md)).

### 3. Структура репозитория

#### 3.1 Верхний уровень

- [pyproject.toml](pyproject.toml:1) — Python-метаданные, Ruff-конфиг, зависимости.
- [package.json](package.json:1) — JS-зависимости и лицензия.
- [erpnext/hooks.py](erpnext/hooks.py:1) — центральная карта регистраций (см. §2).
- [CLAUDE.md](CLAUDE.md) — инструкции для LLM-агентов по навигации по репозиторию.
- [README.md](README.md) — пользовательское описание.
- [codecov.yml](codecov.yml), [commitlint.config.js](commitlint.config.js), [crowdin.yml](crowdin.yml), [sider.yml](sider.yml), [yarn.lock](yarn.lock), [semgrep/](semgrep) — инфра-конфиги (покрытие, commit-линт, i18n, статический анализ).
- [CODEOWNERS](CODEOWNERS), [SECURITY.md](SECURITY.md), [license.txt](license.txt), [TRADEMARK_POLICY.md](TRADEMARK_POLICY.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [sponsors.md](sponsors.md), [attributions.md](attributions.md), [babel_extractors.csv](babel_extractors.csv) — юр/орг/i18n.
- [docs/](docs) — архитектурная документация с line-level цитатами (полный индекс — [docs/README.md](docs/README.md)).

#### 3.2 Пакет `erpnext/`

Наблюдается через `ls erpnext/`. Подкаталоги делятся на 3 группы:

- **Бизнес-модули** (перечислены в [erpnext/modules.txt:1-21](erpnext/modules.txt:1); порядок из файла): `accounts/`, `crm/`, `buying/`, `projects/`, `selling/`, `setup/`, `manufacturing/`, `stock/`, `support/`, `utilities/`, `assets/`, `portal/`, `maintenance/`, `regional/`, `erpnext_integrations/`, `quality_management/`, `communication/`, `telephony/`, `bulk_transaction/`, `subcontracting/`, `edi/`. Внутри каждого — `doctype/<name>/`, а также типично `report/`, `dashboard/`, `workspace/`, `page/`, `web_form/`, `print_format/`, `notification/`.
- **Кросс-модульные артефакты:**
  - [erpnext/controllers/](erpnext/controllers) — базовые классы контроллеров (`accounts_controller.py`, `stock_controller.py`, `selling_controller.py`, `buying_controller.py`, `subcontracting_controller.py`, `subcontracting_inward_controller.py`, `status_updater.py`, `taxes_and_totals.py`, `sales_and_purchase_return.py`, `website_list_for_contact.py`, `budget_controller.py`, `item_variant.py`, `print_settings.py`, `queries.py`, `trends.py`).
  - [erpnext/patches/](erpnext/patches) + [erpnext/patches.txt](erpnext/patches.txt) — миграции БД.
  - [erpnext/hooks.py](erpnext/hooks.py) — центральный реестр (см. §2).
  - [erpnext/modules.txt](erpnext/modules.txt) — перечень модулей.
  - [erpnext/startup/](erpnext/startup) — `boot.py` (инъекция `bootinfo` при каждом логине — см. [docs/architecture/boot-session.md](docs/architecture/boot-session.md)), leaderboards, notifications.
  - [erpnext/setup/](erpnext/setup) — Company, Setup Wizard, `install.py:after_install` (18-шаговый сид при установке app — см. [docs/getting-started/after-install-seed.md](docs/getting-started/after-install-seed.md) и [docs/modules/setup.md](docs/modules/setup.md)).
  - [erpnext/public/](erpnext/public) — статика (JS/CSS/images) для desk-бандла.
  - [erpnext/templates/](erpnext/templates) — Jinja-шаблоны (emails / generators / includes / pages / print_formats) + `templates/utils.py` (override публичной формы контакта — [erpnext/hooks.py:58](erpnext/hooks.py:58)).
  - [erpnext/www/](erpnext/www) — публичные страницы (`book_appointment/`, `support/`, `payment_setup_certification`); см. [docs/modules/www-and-templates.md](docs/modules/www-and-templates.md).
  - [erpnext/tests/](erpnext/tests) — `ERPNextTestSuite` и общие утилиты тестов.
  - [erpnext/locale/](erpnext/locale), [erpnext/gettext/](erpnext/gettext) — интернационализация.
  - [erpnext/config/](erpnext/config), [erpnext/domains/](erpnext/domains), [erpnext/desktop_icon/](erpnext/desktop_icon), [erpnext/workspace_sidebar/](erpnext/workspace_sidebar), [erpnext/report_center/](erpnext/report_center) — конфигурация desk.
  - [erpnext/commands/](erpnext/commands) — CLI-подкоманды `bench`.
  - [erpnext/change_log/](erpnext/change_log) — журнал изменений по версиям.
  - [erpnext/exceptions.py](erpnext/exceptions.py) — доменные исключения.
  - [erpnext/deprecation_dumpster.py](erpnext/deprecation_dumpster.py) — карантин устаревших символов.
- **Специальный шелл:** [erpnext/shopping_cart/](erpnext/shopping_cart) — в текущем коммите **пустая оболочка**; DocType корзины вынесены в сторонний app `webshop`. Единственная живая связь — `payment_gateway_enabled` хук в [erpnext/hooks.py:521](erpnext/hooks.py:521). См. [docs/modules/shopping-cart.md](docs/modules/shopping-cart.md).

#### 3.3 Модули (21) с краткой характеристикой

Взяты из [erpnext/modules.txt:1-21](erpnext/modules.txt:1); одна строка + ссылка на подробный модульный док.

| # | Модуль | Одной строкой | Документ |
|---|--------|---------------|----------|
| 1 | Accounts | GL, налоги, платежи, фискальный период, CoA, Sales/Purchase Invoice, Journal/Payment Entry, Period Closing Voucher | [docs/modules/accounts.md](docs/modules/accounts.md) |
| 2 | CRM | Lead → Opportunity → Quotation; Prospect, Contract, Email Campaign, Appointment | [docs/modules/crm.md](docs/modules/crm.md) |
| 3 | Buying | MR → RFQ → Supplier Quotation → PO → PR → PI; Supplier + Scorecard, LCV | [docs/modules/buying.md](docs/modules/buying.md) |
| 4 | Projects | Project, Task (NestedSet), Timesheet, Project Update; учёт затрат и % выполнения | [docs/modules/projects.md](docs/modules/projects.md) |
| 5 | Selling | Quotation → SO → DN → SI; Customer, Pricing Rule, Promotional Scheme, POS, Stock Reservation | [docs/modules/selling.md](docs/modules/selling.md) |
| 6 | Setup | Company (NestedSet + mass bootstrap), Setup Wizard, Holiday List, Currency Exchange, Authorization Rule, Email Digest, 6 NestedSet-групп мастер-данных | [docs/modules/setup.md](docs/modules/setup.md) |
| 7 | Manufacturing | BOM + Routing + Workstation, Production Plan, Work Order, Job Card (контроллеров **нет** — всё через Stock Entry) | [docs/modules/manufacturing.md](docs/modules/manufacturing.md) |
| 8 | Stock | SLE + Bin, Serial/Batch Bundle, Warehouse (tree), Delivery Note, Purchase Receipt, Stock Entry, Stock Reconciliation, Quality Inspection, Repost Item Valuation | [docs/modules/stock.md](docs/modules/stock.md) |
| 9 | Support | Issue + SLA (wildcard `doc_events["*"].validate`), Warranty Claim, Support Settings | [docs/modules/support.md](docs/modules/support.md) |
| 10 | Utilities | `TransactionBase`, Bulk Transaction engine, activation scoring, storefront pricing, publication-helpers, Video/Video Settings, Rename Tool, Portal User | [docs/modules/utilities.md](docs/modules/utilities.md) |
| 11 | Assets | Asset + Depreciation Schedule (движок амортизации в daily scheduler), Capitalization, Repair, Movement, Value Adjustment, Maintenance, Shift Allocation, Location | [docs/modules/assets.md](docs/modules/assets.md) |
| 12 | Portal | `on_session_creation` auto-provision Customer/Supplier, `website_route_rules`, `standard_portal_menu_items`, 2 child DocType (Website Attribute/Filter) | [docs/modules/portal.md](docs/modules/portal.md) |
| 13 | Maintenance | Maintenance Schedule, Maintenance Visit; мост к Warranty Claim и Serial No `amc_expiry_date` | [docs/modules/maintenance.md](docs/modules/maintenance.md) |
| 14 | Regional | Каталог `regional_overrides`, UAE VAT, Italy FatturaPA, South Africa VAT, Lower Deduction Certificate, Import Supplier Invoice | [docs/modules/regional.md](docs/modules/regional.md) |
| 15 | ERPNext Integrations | Плейд-синхронизация банковских фидов (`automatic_synchronization` hourly_maintenance) + Plaid Settings | [docs/modules/erpnext-integrations.md](docs/modules/erpnext-integrations.md) |
| 16 | Quality Management | Quality Goal / Procedure (NestedSet) / Review / Action / Meeting / Feedback, Non Conformance; `Document` без GL/SLE | [docs/modules/quality-management.md](docs/modules/quality-management.md) |
| 17 | Communication | Пара DocType Communication Medium + Timeslot (роспись дежурств); `doc_events["Communication"]` диспатчится в Support/CRM | [docs/modules/communication.md](docs/modules/communication.md) |
| 18 | Telephony | Call Log + Incoming Call Settings/Schedule + Voice Call Settings + Call Type; универсальный `additional_timeline_content["*"]` | [docs/modules/telephony.md](docs/modules/telephony.md) |
| 19 | Bulk Transaction | 2 лог-DocType (`Bulk Transaction Log` virtual + Detail); движок в `utilities/bulk_transaction.py` + `hourly_maintenance` retry | [docs/modules/bulk-transaction.md](docs/modules/bulk-transaction.md) |
| 20 | Subcontracting | `SubcontractingController`, Subcontracting Order / Receipt / BOM / Inward Order; сосуществует с legacy PO/PR-embedded flow (ADR 0006) | [docs/modules/subcontracting.md](docs/modules/subcontracting.md) |
| 21 | EDI | Code List + Common Code; genericode-XML импорт через `doctype_list_js` | [docs/modules/edi.md](docs/modules/edi.md) |

### 4. Ключевые кросс-модульные артефакты (быстрый индекс)

- [erpnext/hooks.py](erpnext/hooks.py:1) — **первый файл, который открывают при трассировке кросс-срезов**: `doc_events`, `scheduler_events`, `regional_overrides`, `override_doctype_class`, `override_whitelisted_methods`, `website_route_rules`, `standard_portal_menu_items`, `boot_session`, `notification_config`, регистри политик (`auto_cancel_exempted_doctypes`, `accounting_dimension_doctypes`, `period_closing_doctypes` и ещё 14 — см. [docs/architecture/hooks-catalogue.md](docs/architecture/hooks-catalogue.md)).
- [erpnext/controllers/](erpnext/controllers) — иерархия классов транзакционных DocType.
- [erpnext/startup/boot.py](erpnext/startup/boot.py) — инъекция `bootinfo` на каждом логине (companies, fiscal year, sysdefaults, party account types, repost-doctypes) — [docs/architecture/boot-session.md](docs/architecture/boot-session.md).
- [erpnext/setup/install.py](erpnext/setup/install.py) — `after_install` из 18 шагов сида при установке app — [docs/getting-started/after-install-seed.md](docs/getting-started/after-install-seed.md).
- [erpnext/patches/](erpnext/patches) + [erpnext/patches.txt](erpnext/patches.txt) — одноразовые DB-миграции.
- [erpnext/tests/](erpnext/tests) — общая тест-инфра (`ERPNextTestSuite`).
- [erpnext/public/](erpnext/public), [erpnext/templates/](erpnext/templates), [erpnext/www/](erpnext/www) — статика, Jinja-шаблоны, публичные страницы.

### 5. Dev-инфраструктура

- **`bench` CLI.** Все команды разработки выполняются из `frappe-bench/` (родительский каталог ERPNext), а не из самого репозитория. `bench start` поднимает web/worker/schedule/socketio/redis и фронт-воркеры на `:8000` (полный каталог процессов из `Procfile` — [docs/getting-started/development.md:26-52](docs/getting-started/development.md:26)).
- **Миграции/тесты/линт.**
  - Миграции: `bench --site <site-name> migrate` (читает `patches.txt`).
  - Параллельные тесты: `bench --site <site-name> run-parallel-tests --lightmode --app erpnext`; по модулю/тесту: `run-tests --module ... [--test ...]` ([CLAUDE.md](CLAUDE.md), [docs/getting-started/testing-and-quality.md](docs/getting-started/testing-and-quality.md)).
  - Тестовые классы наследуют `ERPNextTestSuite` ([erpnext/tests/utils.py](erpnext/tests/utils.py)); `tearDown` откатывает транзакции.
- **Pre-commit.** `pre-commit run --all-files` прогоняет: Python — Ruff (lint + format, `line-length = 110`, tab indent, target `py310`+, [pyproject.toml:43-78](pyproject.toml:43)); JS/Vue/SCSS — Prettier + ESLint; JSON — 1-space indent (`.editorconfig`).
- **Коммиты.** Enforced Conventional Commits (`feat|fix|docs|test|refactor|style|chore|ci|perf|revert|build`) через [commitlint.config.js](commitlint.config.js). Прямые коммиты в `develop` блокируются pre-commit хуком ([CLAUDE.md](CLAUDE.md), [docs/getting-started/testing-and-quality.md](docs/getting-started/testing-and-quality.md)).
- **Установка.** `bench init` → `bench get-app payments` → `bench get-app erpnext` → `bench new-site` → `bench --site ... install-app erpnext`. Шаги, `site_config.json`, что сидит `after_install` — [docs/getting-started/installation.md](docs/getting-started/installation.md) + [docs/getting-started/after-install-seed.md](docs/getting-started/after-install-seed.md). Почему `payments` — отдельный app (ADR 0004): [docs/adr/0004-payments-app-dependency.md](docs/adr/0004-payments-app-dependency.md).
- **Требования к окружению.** Python 3.14, Node 24, MariaDB 10.6 / PostgreSQL, Redis, `wkhtmltopdf` 0.12.6 — [docs/getting-started/prerequisites.md](docs/getting-started/prerequisites.md).

### 6. Куда идти дальше (навигация по `docs/`)

Полный индекс — [docs/README.md](docs/README.md). Короткие указатели:

- **Архитектура:** [docs/architecture/overview.md](docs/architecture/overview.md), [controllers.md](docs/architecture/controllers.md), [doctype-pattern.md](docs/architecture/doctype-pattern.md), [doctype-lifecycle.md](docs/architecture/doctype-lifecycle.md), [hooks-and-overrides.md](docs/architecture/hooks-and-overrides.md), [hooks-catalogue.md](docs/architecture/hooks-catalogue.md), [scheduler-jobs.md](docs/architecture/scheduler-jobs.md), [boot-session.md](docs/architecture/boot-session.md).
- **Паттерны:** [regional-overrides.md](docs/patterns/regional-overrides.md), [patches.md](docs/patterns/patches.md).
- **Сквозные потоки:** accounting, taxes-and-totals, payments, stock, selling, buying, subcontracting, manufacturing, assets, customer-portal — в [docs/flows/](docs/flows).
- **Модульные обзоры и DocType-карточки:** [docs/modules/](docs/modules) — по одному доку «overview» + «-doctypes» на модуль.
- **Принятые архитектурные решения:** [docs/adr/README.md](docs/adr/README.md) — 6 ADR (неизменяемый журнал, региональные оверрайды, отсутствие контроллера в Manufacturing, зависимость от `payments`, `status_updater[]` vs `doc_events`, сосуществование v15 subcontracting).
- **Сопутствующее исследование:** [2026-04-24-erpnext-monolith-vs-microservices.md](2026-04-24-erpnext-monolith-vs-microservices.md) — обоснование, что ERPNext — модульный монолит.

## Code References

- [pyproject.toml:1-27](pyproject.toml:1) — метаданные проекта, Python 3.14, зависимости.
- [pyproject.toml:40-41](pyproject.toml:40) — `frappe >=17.0.0-dev,<18.0.0`.
- [package.json:1-18](package.json:1) — лицензия GPL-3.0, JS-зависимость `onscan.js`.
- [erpnext/modules.txt:1-21](erpnext/modules.txt:1) — 21 модуль.
- [erpnext/hooks.py:1-11](erpnext/hooks.py:1) — метаданные app.
- [erpnext/hooks.py](erpnext/hooks.py:1) — 713 строк; центральный реестр.
- [erpnext/controllers/](erpnext/controllers) — иерархия контроллеров.
- [erpnext/__init__.py:135](erpnext/__init__.py:135) — декоратор `allow_regional`.
- [CLAUDE.md](CLAUDE.md) — дев-инструкции и карта `docs/`.

## Architecture Insights

- **Паттерн:** модульный монолит + DocType-идиома + фиксированная иерархия контроллеров + централизованный `hooks.py` + «регионализация через реестр функций».
- **Data flow (типовой submit транзакции):** `<DocType>.py.on_submit` → `super().on_submit()` вверх по цепочке контроллеров → `make_gl_entries` / `make_sl_entries` → запись в `tabGL Entry` / `tabStock Ledger Entry`. На каждом шаге могут срабатывать `doc_events` из `hooks.py` и `regional_overrides` для страны компании.
- **Ключевые зависимости:** Frappe Framework (in-process), MariaDB/Postgres (одна БД на инсталляцию), Redis (cache/queue/socketio), Node SocketIO, `payments` app (отдельный Frappe-app, обязательный).

## Open Questions

- Нет. Ответ обзорный; для углублений в каждый модуль — ссылки из §3.3 и §6.

## Changelog

- `2026-04-24` — initial version.
