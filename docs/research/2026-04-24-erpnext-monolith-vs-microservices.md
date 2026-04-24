---
date: 2026-04-24
researcher: codebase-researcher
commit: 93aa0d8cfa
branch: feat/setting-claude
question: "ERPNext этот проект, какая архитектура приобладает монолитная или микросервесная?"
status: complete
affected_doctypes: []
affected_modules:
  - Accounts
  - Stock
  - Selling
  - Buying
  - Manufacturing
  - Regional
  - ERPNext Integrations
related_docs:
  - ../architecture/overview.md
  - ../getting-started/development.md
  - ../architecture/hooks-and-overrides.md
  - ../architecture/scheduler-jobs.md
---

# Исследование: Монолитная vs микросервисная архитектура ERPNext

## Резюме

**ERPNext — это классический модульный монолит (modular monolith) поверх Frappe Framework, а не микросервисная система.** Весь код проекта распространяется как один Python-пакет `erpnext` ([pyproject.toml:1-9](pyproject.toml:1)), устанавливаемый внутрь единого `bench`-окружения как один Frappe-app ([hooks.py:1-11](erpnext/hooks.py:1)). Все бизнес-модули — Accounts, Stock, Selling, Buying, Manufacturing, CRM, Projects, Assets, Regional, EDI и т. д. ([modules.txt:1-21](erpnext/modules.txt:1)) — лежат в одном дереве исходников `erpnext/<module>/`, работают с **одной общей базой данных** (MariaDB/Postgres, по таблице `tab<DocType>` на каждый DocType — [development.md:93-94](docs/getting-started/development.md:93)) и исполняются в рамках **одних и тех же процессов**, запускаемых `bench start` через общий `Procfile` ([development.md:26-52](docs/getting-started/development.md:26)).

Разделение на «модули» в ERPNext — **логическое**, а не сервисное: это просто поддиректории внутри одного пакета. Межмодульные вызовы — это обычный Python `import` и вызовы контроллеров вверх по иерархии наследования (`StatusUpdater → AccountsController → StockController → SellingController/BuyingController` — [overview.md:17](docs/architecture/overview.md:17)), а не HTTP/gRPC/очереди между отдельными сервисами. Cross-cutting поведение (валидации, lifecycle hooks, фоновые джобы, региональные оверрайды) зарегистрировано в **одном** центральном файле [erpnext/hooks.py](erpnext/hooks.py:1) и выполняется в адресном пространстве того же процесса.

Внешние сервисы, от которых зависит проект (Redis × 3, MariaDB/Postgres, Node SocketIO, опционально frankfurter.dev, Plaid, Google Maps) — это **инфраструктурные** компоненты (кэш, очередь, БД, pub/sub, внешние API-провайдеры), а не домены ERPNext, выделенные в отдельные сервисы. Доменный код (учёт, склад, продажи, закупки, производство) остаётся внутри монолита.

## Подробные находки

### 1. Один пакет, один app, одна инсталляция

- **Один Python-проект.** `pyproject.toml` объявляет один дистрибутив `erpnext` с единым набором зависимостей ([pyproject.toml:1-27](pyproject.toml:1)). Нет под-пакетов, собираемых отдельно, нет monorepo-инструментария типа nx/turbo.
- **Один Frappe-app.** Имя и метаданные приложения заданы в [hooks.py:1-11](erpnext/hooks.py:1): `app_name = "erpnext"`, один `app_home = "/desk"`, единый app-level JS/CSS bundle ([hooks.py:25-28](erpnext/hooks.py:25)).
- **Зависимость от Frappe как от платформы, а не как от сервиса.** [pyproject.toml:40-41](pyproject.toml:40): `frappe = ">=17.0.0-dev,<18.0.0"` — Frappe подключается как in-process библиотека/фреймворк; ERPNext не вызывает Frappe по сети.
- **Модули — просто папки.** [erpnext/modules.txt:1-21](erpnext/modules.txt:1) перечисляет 21 модуль; каждый — это поддиректория `erpnext/<module>/`, не отдельный репозиторий и не отдельный сервис. Это явно названо «логическим разделением» в [overview.md:81-88](docs/architecture/overview.md:81).

### 2. Общая БД и общий слой DocType

- **Одна БД на весь app.** Каждому DocType соответствует одна таблица `tab<DocType Name>` в той же MariaDB/Postgres ([development.md:93-94](docs/getting-started/development.md:93)). Нет per-module баз, нет schema-per-service, нет eventual consistency между модулями.
- **Прямые JOIN'ы между доменами.** Поскольку БД одна, код свободно ссылается на таблицы других модулей и делает JOIN'ы через Frappe ORM — в микросервисной архитектуре это было бы невозможно.
- **Единый слой DocType.** Все DocType регистрируются в одной и той же метасистеме Frappe через JSON-файлы ([overview.md:26](docs/architecture/overview.md:26)); контроллеры наследуются из одного набора базовых классов `erpnext/controllers/` ([overview.md:32](docs/architecture/overview.md:32), [controllers.md](docs/architecture/controllers.md)).

### 3. Один процесс исполнения (Procfile и bench start)

`bench start` запускает весь набор процессов под одним супервизором ([development.md:26-52](docs/getting-started/development.md:26)):

| Процесс | Роль |
|---|---|
| `web` | Gunicorn/werkzeug, единый HTTP-сервер на `:8000` — обслуживает **все** модули ERPNext. |
| `worker` | RQ-воркер, исполняющий **все** фоновые задачи всех модулей из одной очереди. |
| `schedule` | Единый планировщик, диспатчит `scheduler_events` из [hooks.py:433-500](erpnext/hooks.py:433). |
| `socketio` | Node-сервер real-time уведомлений. |
| `redis_cache`, `redis_queue`, `redis_socketio` | Три Redis-инстанса: кэш / очередь RQ / pub/sub SocketIO. |
| `watch` | Сборка фронтенда (esbuild/rollup). |

Это **инфраструктурное** разделение (веб-сервер, воркер, брокер, кэш), типичное для любого монолитного Django/Rails-проекта, а **не** разделение по бизнес-доменам. Sales Invoice и Stock Entry обрабатываются **одним и тем же** `web`-процессом и **одним и тем же** `worker`-процессом.

### 4. Scheduler jobs живут внутри того же приложения

Все фоновые задачи зарегистрированы в **одном** словаре `scheduler_events` в [hooks.py:433-500](erpnext/hooks.py:433) и исполняются в общем `worker`-процессе через Frappe RQ:

- `cron`: `bom_update_log.resume_bom_cost_update_jobs`, `repost_item_valuation.run_parallel_reposting`, `gl_entry.rename_gle_sle_docs` ([hooks.py:434-446](erpnext/hooks.py:434)).
- `hourly_maintenance`: `repost_item_valuation.repost_entries`, `bulk_transaction.retry`, `plaid_settings.automatic_synchronization`, `project.collect_project_status`, и др. ([hooks.py:452-459](erpnext/hooks.py:452)).
- `daily_maintenance`: 29 задач из разных модулей (Accounts, Stock, Assets, CRM, Projects, Support, Manufacturing, Buying, Selling) — все через одну точку ([hooks.py:462-492](erpnext/hooks.py:462)).

Каждая джоба — это обычный Python-путь вида `erpnext.<module>.<...>.<function>`, импортируемый и исполняемый in-process. **Нет** ни одного вызова внешнему сервису через message bus/HTTP для исполнения бизнес-логики.

### 5. Межмодульная коммуникация — Python-вызовы, не сеть

- **Controller inheritance chain** ([overview.md:17](docs/architecture/overview.md:17), [controllers.md](docs/architecture/controllers.md)): `StatusUpdater → AccountsController → StockController → SellingController/BuyingController`. Межмодульное поведение реализовано через `super().method()` в одном процессе.
- **`doc_events` в `hooks.py`** ([hooks.py:1](erpnext/hooks.py:1), раздел `doc_events`, см. [hooks-and-overrides.md](docs/architecture/hooks-and-overrides.md)) — cross-cutting подписки на lifecycle события DocType, выполняемые в том же процессе, что и сам save/submit.
- **`regional_overrides`** в [hooks.py:608-621](erpnext/hooks.py:608) — карта замен методов для конкретных стран (France / UAE / Saudi Arabia / Italy). Это **in-process** подмена функции через декоратор `@erpnext.allow_regional` ([overview.md:95](docs/architecture/overview.md:95), [__init__.py:135](erpnext/__init__.py:135)), а не роутинг на отдельный региональный сервис.
- **`extend_doctype_class`** и **`override_whitelisted_methods`** ([hooks.py:56-58](erpnext/hooks.py:56)) — тоже механизмы подмены классов/функций внутри одного процесса.

**Внутренних HTTP/gRPC-вызовов между модулями ERPNext нет.** Shopping Cart-подобные сценарии, которые могли бы требовать межсервисной коммуникации, делегированы во **внешний** app `webshop` (out-of-tree): в текущем коммите сам модуль Shopping Cart в `erpnext/` — это пустая оболочка, см. заметку в CLAUDE.md по [docs/modules/shopping-cart.md](docs/modules/shopping-cart.md) — единственное взаимодействие — это hook `payment_gateway_enabled` → `accounts/utils.create_payment_gateway_account`, снова in-process.

### 6. Внешние сервисы — инфраструктура и интеграции, не домены

Все «внешние» зависимости играют роль **инфраструктуры** или **внешних API-провайдеров**, а не выделенных доменных микросервисов:

| Внешний сервис | Роль | Ссылка |
|---|---|---|
| MariaDB / PostgreSQL | Единая БД приложения | [development.md:85-94](docs/getting-started/development.md:85) |
| Redis × 3 | Кэш / очередь RQ / SocketIO pub/sub | [development.md:41-52](docs/getting-started/development.md:41) |
| Node SocketIO | Real-time push в браузер | [development.md:41-52](docs/getting-started/development.md:41) |
| frankfurter.dev | Внешний API курсов валют | CLAUDE.md → Currency Exchange Settings |
| Plaid | Внешний API банковских фидов — `plaid-python~=7.2.1` в [pyproject.toml:19](pyproject.toml:19); sync через [hooks.py:457](erpnext/hooks.py:457) `plaid_settings.automatic_synchronization` | [hooks.py:457](erpnext/hooks.py:457) |
| Google Maps | Геокодирование — `googlemaps~=4.10.0` ([pyproject.toml:18](pyproject.toml:18)) | [pyproject.toml:18](pyproject.toml:18) |
| YouTube | `python-youtube~=0.9.8` ([pyproject.toml:20](pyproject.toml:20)); hourly_maintenance `video.update_youtube_data` ([hooks.py:458](erpnext/hooks.py:458)) | [hooks.py:458](erpnext/hooks.py:458) |

Ни один из них не является «сервисом ERPNext»: это либо платформенная инфраструктура (БД, кэш, брокер), либо сторонние SaaS, к которым ERPNext обращается как клиент по HTTPS. Доменной декомпозиции ERPNext на самостоятельно деплоящиеся сервисы **нет**.

### 7. Единая миграция и единый lifecycle

- Все миграции БД живут в [erpnext/patches.txt](erpnext/patches.txt:1) и применяются одним `bench --site <site> migrate` ко всем модулям сразу ([development.md:110-127](docs/getting-started/development.md:110)). У каждого модуля **нет** своей независимой схемы-миграции.
- `after_install = "erpnext.setup.install.after_install"` ([hooks.py:66](erpnext/hooks.py:66)) — одна точка инициализации всего app-а.
- `boot_session`, `notification_config`, `on_session_creation`, `setup_wizard_*` — тоже централизованы в [hooks.py:60-75](erpnext/hooks.py:60).

## Code References

- [pyproject.toml:1-27](pyproject.toml:1) — один Python-дистрибутив `erpnext`, зависимости объявлены единым списком.
- [pyproject.toml:40-41](pyproject.toml:40) — Frappe объявлен как bench-зависимость (in-process фреймворк).
- [erpnext/hooks.py:1-11](erpnext/hooks.py:1) — `app_name = "erpnext"`, единый app.
- [erpnext/hooks.py:25-28](erpnext/hooks.py:25) — один JS/CSS bundle на весь app.
- [erpnext/hooks.py:56-58](erpnext/hooks.py:56) — `extend_doctype_class` / `override_whitelisted_methods` — in-process механизмы.
- [erpnext/hooks.py:66](erpnext/hooks.py:66) — одна точка `after_install`.
- [erpnext/hooks.py:433-500](erpnext/hooks.py:433) — `scheduler_events`, все фоновые задачи всех модулей в одном реестре.
- [erpnext/hooks.py:608-621](erpnext/hooks.py:608) — `regional_overrides`, in-process подмена методов.
- [erpnext/modules.txt:1-21](erpnext/modules.txt:1) — 21 модуль внутри одного пакета.
- [docs/architecture/overview.md:17](docs/architecture/overview.md:17) — иерархия контроллеров через `super()`.
- [docs/architecture/overview.md:81-88](docs/architecture/overview.md:81) — формальное описание «Frappe app» как единицы деплоя.
- [docs/getting-started/development.md:26-52](docs/getting-started/development.md:26) — состав `Procfile` (web, worker, schedule, socketio, redis ×3, watch).
- [docs/getting-started/development.md:110-127](docs/getting-started/development.md:110) — единая миграция `bench migrate`.

## Архитектурные выводы

- **Паттерн:** Modular Monolith (модульный монолит) на Frappe Framework. Домены разделены по директориям и по базовым контроллерам, но исполняются в одном процессе и разделяют одну БД.
- **Единица деплоя:** один Frappe-app `erpnext`, устанавливаемый в один bench. Масштабирование — вертикальное или горизонтальное репликами того же монолита за балансировщиком, а не декомпозицией на сервисы.
- **Поток данных между модулями:** Python import + наследование контроллеров + `doc_events` hooks + общая БД. Сетевых границ между модулями нет.
- **Ключевые зависимости (инфраструктура):** Frappe Framework (in-process), MariaDB/Postgres, Redis × 3, Node SocketIO.
- **Ключевые зависимости (внешние API-клиенты):** Plaid, Google Maps, frankfurter.dev, YouTube — используются как клиентские интеграции, не как собственные сервисы.
- **Что это НЕ:** не микросервисная архитектура; не SOA; не event-driven distributed system. Нет собственного message bus между доменами, нет API Gateway, нет per-service БД, нет независимых циклов деплоя модулей.

## Открытые вопросы

- `TODO(verify)` — фактический `Procfile` генерируется `bench init` в родительской `frappe-bench/` директории и в этом репозитории отсутствует; список процессов реконструирован из `install.sh` sed-правок ([development.md:52](docs/getting-started/development.md:52)). Для прямой верификации нужно прочитать `Procfile` в рабочем bench-окружении.
- Продуктовая экосистема Frappe включает отдельно-устанавливаемые apps (`hrms`, `payments`, `webshop`, `lms` и т. п.). Внутри одного bench они соседствуют и делят процесс/БД/Redis с ERPNext — то есть и на уровне платформы это скорее «монолит с плагинами», чем микросервисы. В данном исследовании рассматривался **только** app `erpnext`.

## Changelog

- `2026-04-24` — первая версия.
