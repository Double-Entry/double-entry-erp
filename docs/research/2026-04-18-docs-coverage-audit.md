---
date: 2026-04-18
researcher: codebase-researcher
commit: f26f8bc3b6
branch: feat/setting-claude
question: "Analyze the /docs folder and identify which application areas are NOT covered by documentation"
status: complete
affected_doctypes: []
affected_modules:
  - Assets
  - CRM
  - Projects
  - Support
  - Setup
  - Maintenance
  - Quality Management
  - EDI
  - ERPNext Integrations
  - Communication
  - Telephony
  - Bulk Transaction
  - Portal
  - Utilities
related_docs:
  - docs/README.md
  - docs/architecture/hooks-and-overrides.md
---

# Research: Documentation Coverage Audit (`docs/` vs `erpnext/`)

## Summary

`docs/` covers the **transactional accounting backbone** in depth — Accounts, Stock, Selling, Buying, Subcontracting, Manufacturing, Regional, plus seven cross-cutting flow documents and the full Getting Started + Architecture + Patterns sections. Every file in [docs/README.md](../README.md) is real and has line-level citations back into the source.

What is **missing** is everything else: of 21 modules listed in [erpnext/modules.txt](../../erpnext/modules.txt), 7 are documented and 14 are not. The undocumented set includes GL-impacting code paths (Assets depreciation / capitalization), the entire customer-facing surface (Portal, Shopping Cart, `www/`, customer-portal `templates/`), the integration layer (ERPNext Integrations / Plaid, EDI, Telephony, Communication), the planning / operational modules (CRM, Projects, Support, Maintenance, Quality Management), and almost all cross-cutting infrastructure (`startup/boot.py`, `startup/notifications.py`, `setup/install.py` `after_install` walkthrough beyond the install page, `utilities/`, fixtures, scheduler-job consolidated index, `extend_bootinfo`, `naming_series_variables`, `accounting_dimension_doctypes`, `period_closing_doctypes`, `auto_cancel_exempted_doctypes`, `repost_allowed_doctypes`, `bank_reconciliation_doctypes`, `subscription_doctypes`).

The [docs/adr/](../adr/) directory exists but is empty; [docs/research/](.) likewise only contains this file. There are 14 outstanding `TODO(verify)` markers across the existing docs. **Gap headline:** 14 uncovered modules, 0 partial modules (every documented module has both an overview and a `-doctypes.md` reference card), 9 cross-cutting infrastructure gaps, 6 candidate ADRs unwritten.

## Detailed Findings

### 1. Inventory of what `docs/` covers today

Counted from a directory listing of `docs/` and verified against [docs/README.md](../README.md):

- **Getting Started (6 files):** [README](../getting-started/README.md), [prerequisites](../getting-started/prerequisites.md), [installation](../getting-started/installation.md), [development](../getting-started/development.md), [testing-and-quality](../getting-started/testing-and-quality.md), [operations](../getting-started/operations.md).
- **Architecture (5 files):** [overview](../architecture/overview.md), [controllers](../architecture/controllers.md), [doctype-pattern](../architecture/doctype-pattern.md), [doctype-lifecycle](../architecture/doctype-lifecycle.md), [hooks-and-overrides](../architecture/hooks-and-overrides.md).
- **Patterns (2 files):** [regional-overrides](../patterns/regional-overrides.md), [patches](../patterns/patches.md).
- **Flows (8 files):** [accounting-flow](../flows/accounting-flow.md), [taxes-and-totals](../flows/taxes-and-totals.md), [payments-flow](../flows/payments-flow.md), [stock-flow](../flows/stock-flow.md), [selling-flow](../flows/selling-flow.md), [buying-flow](../flows/buying-flow.md), [subcontracting-flow](../flows/subcontracting-flow.md), [manufacturing-flow](../flows/manufacturing-flow.md).
- **Modules (14 files = 7 modules × {overview, doctypes}):** Accounts, Stock, Selling, Buying, Subcontracting, Manufacturing, Regional. Each has both `<module>.md` (overview) and `<module>-doctypes.md` (per-DocType reference cards). No coverage gaps within these 7.
- **ADRs:** [docs/adr/](../adr/) directory exists but is empty (`ls /docs/adr/` returns nothing). [docs/README.md:59](../README.md:59) explicitly states *"No Architecture Decision Records yet."*
- **Research:** [docs/research/](.) contains only this audit document.

### 2. Modules with ZERO documentation

Cross-referenced [erpnext/modules.txt](../../erpnext/modules.txt) (21 modules) against `docs/modules/`. Documented: Accounts, Stock, Selling, Buying, Manufacturing, Subcontracting, Regional. **Undocumented (14):**

| Module (modules.txt) | Source dir | Visible artefacts | Notes on impact |
|----------------------|------------|-------------------|-----------------|
| **Assets** | [erpnext/assets/](../../erpnext/assets/) | ~25 DocTypes incl. Asset, Asset Capitalization, Asset Repair, Asset Maintenance, Asset Depreciation Schedule, Asset Movement, Asset Shift Allocation | **GL-impacting.** Referenced 4× in `scheduler_events.daily` ([hooks.py:471-491](../../erpnext/hooks.py:471)): `asset.update_maintenance_status`, `asset.make_post_gl_entry`, `asset_maintenance_log.update_asset_maintenance_log_status`, `depreciation.post_depreciation_entries`. Asset is in `period_closing_doctypes` ([hooks.py:333](../../erpnext/hooks.py:333)) and in `accounting_dimension_doctypes` ([hooks.py:543](../../erpnext/hooks.py:543)). |
| **CRM** | [erpnext/crm/](../../erpnext/crm/) | Lead, Opportunity, Prospect, Contract, Email Campaign, Appointment, plus `frappe_crm_api.py`, `utils.py` | Referenced 5× in `scheduler_events.daily` and 3× in `doc_events` (Communication / Event after_insert wiring at [hooks.py:362-374](../../erpnext/hooks.py:362)). `user_privacy_documents` references Lead + Opportunity ([hooks.py:622-633](../../erpnext/hooks.py:622)). |
| **Projects** | [erpnext/projects/](../../erpnext/projects/) | Project, Task, Timesheet, Activity Cost, Project Update, web_form/ | Referenced 5× in `scheduler_events` (hourly_reminder, collect_project_status, project_status_update_reminder, set_tasks_as_overdue, update_project_sales_billing, send_project_status_email_to_users) at [hooks.py:449-475](../../erpnext/hooks.py:449). `calendars` includes Task ([hooks.py:111](../../erpnext/hooks.py:111)). |
| **Support** | [erpnext/support/](../../erpnext/support/) | Issue, Service Level Agreement, Warranty Claim, Maintenance Visit/Schedule overlap, web_form/ | Wired via `doc_events["*"].validate` for SLA ([hooks.py:344-348](../../erpnext/hooks.py:344)) — runs on **every doc save in the system**. Communication on_update + Contact on_trash dispatch into `support.doctype.issue.issue` ([hooks.py:362-402](../../erpnext/hooks.py:362)). `extend_bootinfo` calls `add_sla_doctypes` ([hooks.py:687](../../erpnext/hooks.py:687)). `auto_close_tickets` daily scheduler. |
| **Setup** | [erpnext/setup/](../../erpnext/setup/) | Company, Employee, Email Digest, Naming Series, Authorization Rule, Brand, Currency Exchange, Holiday List, Item Group, Customer Group, Supplier Group, Sales Person, Territory, Department, Transaction Deletion Record, plus `install.py`, `setup_wizard/`, `demo.py`, `demo_data/` | The most important undocumented module. `after_install` ([hooks.py:66](../../erpnext/hooks.py:66)) runs `erpnext.setup.install.after_install` — partially covered by [installation.md](../getting-started/installation.md) but the actual seed catalogue (CoA templates, default warehouses, default tax templates, demo data) is undocumented. `setup_wizard_stages` ([hooks.py:64](../../erpnext/hooks.py:64)). `transaction_deletion_record.check_for_running_deletion_job` runs on every doc validate ([hooks.py:347](../../erpnext/hooks.py:347)). `cache_companies_monthly_sales_history`, `auto_create_fiscal_year`, `email_digest.send` daily. `validate_employee_role` on User. `has_upload_permission` for Employee ([hooks.py:305](../../erpnext/hooks.py:305)). |
| **Maintenance** | [erpnext/maintenance/](../../erpnext/maintenance/) | Maintenance Schedule, Maintenance Visit | Cited in `global_search_doctypes` ([hooks.py:674-676](../../erpnext/hooks.py:674)). No scheduler / doc_event coverage. |
| **Quality Management** | [erpnext/quality_management/](../../erpnext/quality_management/) | Quality Goal, Quality Procedure, Quality Action, Quality Meeting, Quality Review, Non Conformance, Quality Feedback, Quality Inspection (cross-listed in Stock) | `quality_review.review` daily ([hooks.py:476](../../erpnext/hooks.py:476)). |
| **EDI** | [erpnext/edi/](../../erpnext/edi/) | Code List, Common Code (and import JS hook) | Referenced in `doctype_list_js` ([hooks.py:46-52](../../erpnext/hooks.py:46)). New module — no module overview anywhere. |
| **ERPNext Integrations** | [erpnext/erpnext_integrations/](../../erpnext/erpnext_integrations/) | Plaid Settings, plus `custom/`, `utils.py` | `plaid_settings.automatic_synchronization` runs `hourly_maintenance` ([hooks.py:457](../../erpnext/hooks.py:457)). The integration surface area is thin in this tree but completely undocumented. |
| **Communication** | [erpnext/communication/](../../erpnext/communication/) | (DocType list not enumerated in this audit — `doctype/` subdir only) | Distinct from Frappe core Communication; ERPNext side wires `doc_events["Communication"]` ([hooks.py:362](../../erpnext/hooks.py:362)) for SLA + issue first-response + CRM linking. |
| **Telephony** | [erpnext/telephony/](../../erpnext/telephony/) | Call Log | `additional_timeline_content["*"]` injects `call_log.get_linked_call_logs` into every doc timeline ([hooks.py:684](../../erpnext/hooks.py:684)). Contact `after_insert` calls `link_existing_conversations` ([hooks.py:400](../../erpnext/hooks.py:400)). |
| **Bulk Transaction** | [erpnext/bulk_transaction/](../../erpnext/bulk_transaction/) | Bulk Transaction Log + Detail | `utilities.bulk_transaction.retry` runs `hourly_maintenance` ([hooks.py:454](../../erpnext/hooks.py:454)) — note the helper lives in `utilities/`, not `bulk_transaction/`. |
| **Portal** | [erpnext/portal/](../../erpnext/portal/) | Portal-side DocTypes + `utils.py` | `on_session_creation = "erpnext.portal.utils.create_customer_or_supplier"` ([hooks.py:75](../../erpnext/hooks.py:75)) — runs on **every login**. `set_default_role` on User on_update ([hooks.py:360](../../erpnext/hooks.py:360)). All `standard_portal_menu_items` ([hooks.py:231-297](../../erpnext/hooks.py:231)) and `website_route_rules` ([hooks.py:121-218](../../erpnext/hooks.py:121)) are portal-facing. |
| **Utilities** | [erpnext/utilities/](../../erpnext/utilities/) | Video, Rename Tool, SMS Center; modules `activation.py`, `bulk_transaction.py`, `naming.py`, `product.py`, `regional.py`, `transaction_base.py` | `get_help_messages = erpnext.utilities.activation.get_help_messages` ([hooks.py:70](../../erpnext/hooks.py:70)), `bot_parsers = [erpnext.utilities.bot.FindItemBot]` ([hooks.py:516](../../erpnext/hooks.py:516)), `get_site_info = erpnext.utilities.get_site_info` ([hooks.py:519](../../erpnext/hooks.py:519)), `video.update_youtube_data` hourly maintenance ([hooks.py:458](../../erpnext/hooks.py:458)). `transaction_base.py` is a base referenced by [docs/architecture/controllers.md](../architecture/controllers.md) but the module itself isn't documented. |

Note: 21 modules in `modules.txt`, 7 documented, 14 undocumented = 100% module gap closure would require 28 new files (overview + doctypes per module).

### 3. Modules with PARTIAL documentation

**None.** Every module that has a `docs/modules/<name>.md` overview also has a matching `<name>-doctypes.md` reference card. Coverage symmetry is consistent for all 7 documented modules. (Verified by comparing the file list under `docs/modules/` against itself.)

### 4. Cross-cutting infrastructure gaps

These are not modules; they are repo-wide concerns scattered across multiple files. Each is referenced by one or more entries in `hooks.py` and has no dedicated documentation page.

#### 4.1. Boot session and bootinfo extension

- [erpnext/startup/boot.py](../../erpnext/startup/boot.py) registered as `boot_session` ([hooks.py:68](../../erpnext/hooks.py:68)) and `extend_bootinfo` ([hooks.py:687-690](../../erpnext/hooks.py:687)).
- What it injects into the desk client (sysdefaults, demo flags, defaults) is undocumented.
- [docs/architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) lists the registration but does not trace the function body.

#### 4.2. Startup notifications, leaderboards, filters

- [erpnext/startup/notifications.py](../../erpnext/startup/notifications.py) — `notification_config = "erpnext.startup.notifications.get_notification_config"` ([hooks.py:69](../../erpnext/hooks.py:69)). Drives the per-DocType notification badges in the desk navbar — entirely undocumented.
- [erpnext/startup/leaderboard.py](../../erpnext/startup/leaderboard.py) — `leaderboards` ([hooks.py:71](../../erpnext/hooks.py:71)).
- [erpnext/startup/filters.py](../../erpnext/startup/filters.py) — `filters_config` ([hooks.py:72](../../erpnext/hooks.py:72)).

#### 4.3. Consolidated scheduler-jobs index

`scheduler_events` at [hooks.py:433-500](../../erpnext/hooks.py:433) registers ~30 background jobs across cron / hourly / hourly_long / hourly_maintenance / daily / daily_long / daily_maintenance / weekly / monthly_long. Each documented module mentions its own subset, but **there is no single page that lists every job, its frequency, what it touches, and what fails if it stops**. [docs/architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) describes the registry mechanism but not the job catalogue.

Notable orphans (referenced in `scheduler_events` but in undocumented modules):
- `erpnext.assets.doctype.asset.depreciation.post_depreciation_entries` ([hooks.py:491](../../erpnext/hooks.py:491))
- `erpnext.projects.doctype.project.project.collect_project_status` ([hooks.py:455](../../erpnext/hooks.py:455))
- `erpnext.support.doctype.issue.issue.auto_close_tickets` ([hooks.py:463](../../erpnext/hooks.py:463))
- `erpnext.crm.doctype.opportunity.opportunity.auto_close_opportunity` ([hooks.py:464](../../erpnext/hooks.py:464))
- `erpnext.erpnext_integrations.doctype.plaid_settings.plaid_settings.automatic_synchronization` ([hooks.py:457](../../erpnext/hooks.py:457))
- `erpnext.utilities.bulk_transaction.retry` ([hooks.py:454](../../erpnext/hooks.py:454))
- `erpnext.utilities.doctype.video.video.update_youtube_data` ([hooks.py:458](../../erpnext/hooks.py:458))

#### 4.4. Portal, Shopping Cart, `www/`, customer-facing templates

- [erpnext/portal/](../../erpnext/portal/), [erpnext/shopping_cart/](../../erpnext/shopping_cart/), [erpnext/www/](../../erpnext/www/) (incl. `all-products`, `book-appointment`, `book_appointment`, `lms`, `shop-by-category`, `support`, `payment_setup_certification.py`).
- `templates/` subdirs: [emails/](../../erpnext/templates/emails/), [form_grid/](../../erpnext/templates/form_grid/), [generators/](../../erpnext/templates/generators/), [includes/](../../erpnext/templates/includes/), [pages/](../../erpnext/templates/pages/), [print_formats/](../../erpnext/templates/print_formats/), plus [templates/utils.py](../../erpnext/templates/utils.py) which is wired into `override_whitelisted_methods` for the public contact form ([hooks.py:58](../../erpnext/hooks.py:58)) and into `webform_list_context` ([hooks.py:109](../../erpnext/hooks.py:109)).
- `website_route_rules` ([hooks.py:121-218](../../erpnext/hooks.py:121)) and `standard_portal_menu_items` ([hooks.py:231-297](../../erpnext/hooks.py:231)) — together these define the entire customer + supplier self-service surface, undocumented.

#### 4.5. `setup/install.py` and `after_install` seed catalogue

- [erpnext/setup/install.py](../../erpnext/setup/install.py) referenced by [installation.md](../getting-started/installation.md) but no detailed page enumerates: the CoA standard templates loaded, default warehouses (Stores / WIP / Finished Goods), default tax templates per country, default UoMs, default Item Groups / Customer Groups / Supplier Groups, default territories, the country fixtures hook (`install_country_fixtures`).

#### 4.6. Per-DocType registries (cross-cutting lists in `hooks.py`)

These are referenced only inline by [docs/architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) but not given a dedicated semantics page:

- `period_closing_doctypes` ([hooks.py:322-341](../../erpnext/hooks.py:322)) — 18 DocTypes blocked by Accounting Period.
- `auto_cancel_exempted_doctypes` ([hooks.py:418-431](../../erpnext/hooks.py:418)) — Payment Entry / GL Entry / SLE / Payment Ledger / Advance Payment Ledger / Account Closing Balance.
- `accounting_dimension_doctypes` ([hooks.py:537-590](../../erpnext/hooks.py:537)) — 50+ DocTypes carrying cost-center / project / dimension fields.
- `repost_allowed_doctypes` ([hooks.py:707-713](../../erpnext/hooks.py:707)) — which docs Repost Item Valuation can rebuild from.
- `bank_reconciliation_doctypes` ([hooks.py:530-535](../../erpnext/hooks.py:530)).
- `subscription_doctypes` ([hooks.py:592](../../erpnext/hooks.py:592)).
- `invoice_doctypes` ([hooks.py:528](../../erpnext/hooks.py:528)).
- `advance_payment_receivable_doctypes` / `advance_payment_payable_doctypes` ([hooks.py:525-526](../../erpnext/hooks.py:525)).
- `communication_doctypes` ([hooks.py:523](../../erpnext/hooks.py:523)).
- `treeviews` ([hooks.py:77-87](../../erpnext/hooks.py:77)).
- `calendars` ([hooks.py:111](../../erpnext/hooks.py:111)).
- `website_generators` ([hooks.py:113](../../erpnext/hooks.py:113)).
- `naming_series_variables` ([hooks.py:412-416](../../erpnext/hooks.py:412)) and the 9 variable handlers parsed by [accounts/utils.py](../../erpnext/accounts/utils.py).
- `default_log_clearing_doctypes` ([hooks.py:693-695](../../erpnext/hooks.py:693)).
- `ignore_links_on_delete` ([hooks.py:680-682](../../erpnext/hooks.py:680)).
- `additional_timeline_content` ([hooks.py:684](../../erpnext/hooks.py:684)).

#### 4.7. Custom bench commands

- [erpnext/commands/__init__.py](../../erpnext/commands/__init__.py) declares `commands = []` — the registration slot exists but ERPNext currently ships **zero custom bench commands**. This is itself a documentable fact (and a candidate ADR or note in operations.md). Currently unmentioned anywhere in `docs/`.

#### 4.8. Domains, Desktop Icons, Workspace Sidebar, Report Center

- [erpnext/domains/](../../erpnext/domains/) — `distribution.py`, `manufacturing.py`, `retail.py`, `services.py`. Domain selection in setup wizard switches default modules. Undocumented.
- [erpnext/desktop_icon/](../../erpnext/desktop_icon/) and [erpnext/workspace_sidebar/](../../erpnext/workspace_sidebar/) — 24 JSON descriptors each, defining the desk navigation. Undocumented.
- [erpnext/report_center/accounting.json](../../erpnext/report_center/accounting.json) — Report Center registry. Undocumented.

#### 4.9. i18n / gettext

- [erpnext/locale/](../../erpnext/locale/) — 33 `.po` translation files plus `main.pot`.
- [erpnext/gettext/extractors/](../../erpnext/gettext/extractors/) — custom extractors for translatable strings (referenced by `ignore_translatable_strings_from = ["frappe"]` at [hooks.py:704](../../erpnext/hooks.py:704)).
- No documentation describes the translation contribution workflow.

### 5. ADR backlog (candidate ADRs, none written)

[docs/adr/](../adr/) is empty. The following architectural decisions are visible in code but not formalized:

1. **Why Manufacturing has no controller class.** All four manufacturing lifecycle DocTypes (Production Plan, Work Order, Job Card, BOM) extend `Document` directly instead of joining the `StockController` chain. The decision rationale is implicit (Stock Entry carries the GL/SLE) but worth recording. Mentioned in passing in [docs/modules/manufacturing.md](../modules/manufacturing.md) but not as a standalone ADR.
2. **Immutable ledger policy.** `auto_cancel_exempted_doctypes` ([hooks.py:418-431](../../erpnext/hooks.py:418)) keeps GL Entry, SLE, Payment Ledger Entry, Advance Payment Ledger Entry, Account Closing Balance from being auto-cancelled — instead a reverse entry is posted. Comment in `hooks.py` says *"Reverse ledger entries are created instead to ensure ledger immutability."* This is a load-bearing accounting-correctness decision.
3. **Regional overrides via decorator + registry instead of subclassing.** The `@erpnext.allow_regional` + `regional_overrides` registry pattern ([hooks.py:608-621](../../erpnext/hooks.py:608)) is used in preference to country-specific subclasses. Documented in [docs/patterns/regional-overrides.md](../patterns/regional-overrides.md) but not as an ADR.
4. **`status_updater[]` declarative status propagation vs `doc_events`.** The Selling / Buying flows rely on a class-level `status_updater = [...]` declaration consumed by `StatusUpdater` rather than per-event hooks. Architectural choice not formalized.
5. **`payments` app installed before `erpnext`.** [installation.md](../getting-started/installation.md) documents the install order (`bench get-app payments && bench get-app erpnext`) but the *why* (payments was extracted as a separate app and erpnext now declares a dependency on it) is not recorded as an ADR.
6. **Subcontracting v15 split — coexistence of legacy and new flows.** `is_old_subcontracting_flow=1` flag preserves PO/PR-embedded subcontracting; new SCO/SCR flow is the default. The coexistence and migration story are documented in [docs/flows/subcontracting-flow.md](../flows/subcontracting-flow.md) but not as an ADR.
7. **No custom bench commands.** [erpnext/commands/__init__.py](../../erpnext/commands/__init__.py) is an empty registration. Worth noting that ERPNext deliberately operates entirely through Frappe's bench surface.
8. **Stock and accounting dimensions consolidated at 50+ DocTypes.** `accounting_dimension_doctypes` ([hooks.py:537-590](../../erpnext/hooks.py:537)) is one of the largest cross-cutting lists; the policy of "every transaction carries dimensions" is implicit.

### 6. Outstanding `TODO(verify)` markers in `docs/`

Sweep of `grep -rn "TODO(verify)" docs/` returned 14 hits across 8 files. All are flagged honestly in the source documents — none are blockers, but they represent open follow-up items:

| File | Line | Context |
|------|------|---------|
| [docs/architecture/doctype-pattern.md](../architecture/doctype-pattern.md) | 137 | Only Sales Invoice and Purchase Invoice were directly verified for the controller chain mapping; the rest derive from CLAUDE.md. |
| [docs/getting-started/operations.md](../getting-started/operations.md) | 128 | Production Procfile process names mirror dev Procfile + Frappe community guidance; no in-tree authoritative source. |
| [docs/getting-started/prerequisites.md](../getting-started/prerequisites.md) | 67 | Brew/macOS package list derived from apt equivalents in `.github/helper/install.sh`. |
| [docs/getting-started/prerequisites.md](../getting-started/prerequisites.md) | 138 | Minimum RAM for dev bench not asserted by any in-tree file. |
| [docs/getting-started/testing-and-quality.md](../getting-started/testing-and-quality.md) | 80 | `allow_tests` gate lives in Frappe core, not ERPNext — exact default behaviour on a fresh `new-site` is not verified. |
| [docs/getting-started/testing-and-quality.md](../getting-started/testing-and-quality.md) | 194 | ESLint exclude for `erpnext/public/js/controllers/` is historical — not verified as intentional. |
| [docs/getting-started/development.md](../getting-started/development.md) | 52 | Procfile catalogue reconstructed from `install.sh` sed edits + scheduler_events registration; no in-tree Procfile to inspect. |
| [docs/modules/manufacturing-doctypes.md](../modules/manufacturing-doctypes.md) | 358 | `make_mrp` writeback target (MRP Log vs Production Plan) not verified. |
| [docs/modules/buying.md](../modules/buying.md) | 246 | `auto_create_purchase_receipt` Buying Settings flag — consumer code path not located. |
| [docs/modules/regional.md](../modules/regional.md) | 434, 436, 514 | FEC (Fichier des Ecritures Comptables) French report — not present at `erpnext/regional/report/`; v10 patch is idempotent. |
| [docs/flows/subcontracting-flow.md](../flows/subcontracting-flow.md) | 418 | No subcontracting scheduler jobs — confirm none added in future. |
| [docs/flows/manufacturing-flow.md](../flows/manufacturing-flow.md) | 87 | Confirm no manufacturing entries in `override_doctype_class`. |

### 7. Tests-folder gap

[erpnext/tests/](../../erpnext/tests/) ships repo-wide test infrastructure: `utils.py` (the `ERPNextTestSuite` base class referenced in [docs/getting-started/testing-and-quality.md](../getting-started/testing-and-quality.md)), `test_init.py`, `test_perf.py`, `test_regional.py`, `test_point_of_sale.py`, `test_notifications.py`, `test_activation.py`, `test_webform.py`, `test_zform_loads.py`. The testing-and-quality doc covers the *runner* but not what these top-level test files actually exercise (`test_perf.py` sets performance baselines; `test_zform_loads.py` is the doctype-form smoke test naming-sorted to run last). Worth a short page or expansion of testing-and-quality.md.

## Code References

- [erpnext/modules.txt](../../erpnext/modules.txt:1) — canonical module list (21 entries).
- [erpnext/hooks.py:343-409](../../erpnext/hooks.py:343) — `doc_events` registry, dispatches into all 14 undocumented modules.
- [erpnext/hooks.py:433-500](../../erpnext/hooks.py:433) — `scheduler_events`, the orphan-job catalogue.
- [erpnext/hooks.py:608-621](../../erpnext/hooks.py:608) — `regional_overrides` (covered).
- [erpnext/hooks.py:121-297](../../erpnext/hooks.py:121) — `website_route_rules` + `standard_portal_menu_items`, the entire customer/supplier portal surface (uncovered).
- [erpnext/startup/boot.py](../../erpnext/startup/boot.py) — boot_session injection (uncovered).
- [erpnext/startup/notifications.py](../../erpnext/startup/notifications.py) — notification badges (uncovered).
- [erpnext/setup/install.py](../../erpnext/setup/install.py) — after_install seed (mentioned briefly, not detailed).
- [erpnext/utilities/](../../erpnext/utilities/) — get_site_info, FindItemBot, naming, transaction_base (uncovered).
- [erpnext/portal/utils.py](../../erpnext/portal/utils.py) — on_session_creation (uncovered).
- [erpnext/commands/__init__.py](../../erpnext/commands/__init__.py) — empty stub, worth noting.

## Architecture Insights

**Coverage profile.** `docs/` is structured as a "transactional accounting first" tree: anything that produces GL or SLE rows is documented exhaustively (Accounts, Stock, Selling, Buying, Subcontracting, Manufacturing — six of the seven documented modules). Regional is the seventh and is documented because it overlays on top of those six. Everything else — masters, planning, support, integrations, customer-portal, infrastructure — is currently undocumented.

**Cross-cutting blind spots are concentrated at the `hooks.py` level.** Every undocumented module is reachable through one of: `doc_events`, `scheduler_events`, `boot_session`, `extend_bootinfo`, `on_session_creation`, `additional_timeline_content`, `override_whitelisted_methods`, `website_route_rules`, `standard_portal_menu_items`, `has_website_permission`. A single "Hooks Catalogue" page (deeper than the existing [hooks-and-overrides.md](../architecture/hooks-and-overrides.md)) plus per-undocumented-module pages would close most of the cross-cutting gap.

**ADR slot is empty by design choice.** [docs/README.md:59](../README.md:59) explicitly says no ADRs yet. There are at least six well-formed candidate decisions visible in code that have no formal record.

## Open Questions

- `TODO(verify)` — [erpnext/communication/doctype/](../../erpnext/communication/doctype/) DocType list not enumerated; the ERPNext-side Communication module has only one or two DocTypes layered onto Frappe core's Communication. Direct read needed before writing a module page.
- `TODO(verify)` — Whether [erpnext/edi/](../../erpnext/edi/) is a v17-stage module under active expansion or a stable narrow scope. Only Code List + Common Code visible at this commit.
- `TODO(verify)` — Whether `erpnext.utilities.bot.FindItemBot` is still wired to a live chat / bot framework or vestigial ([hooks.py:516](../../erpnext/hooks.py:516)).
- `TODO(verify)` — `payment_gateway_enabled` ([hooks.py:521](../../erpnext/hooks.py:521)) points into Accounts utils but the consumer side (which calls it) lives in the `payments` app, not in this tree.

## Suggested priority order for filling gaps

Highest impact first, judged by GL/SLE blast radius and frequency of cross-references in `hooks.py`:

1. **Assets module** (`docs/modules/assets.md` + `assets-doctypes.md`). GL-impacting (depreciation entries posted daily), in `period_closing_doctypes`, in `accounting_dimension_doctypes`. ~25 DocTypes.
2. **Setup module** (`docs/modules/setup.md` + `setup-doctypes.md`) plus an expanded `docs/getting-started/after-install-seed.md`. Holds Company, Employee, Email Digest, Naming Series, Currency Exchange, Authorization Rule, Holiday List, the four master groups (Item / Customer / Supplier / Sales Person), Territory, Department, Transaction Deletion Record. `after_install` runs from here and seeds CoA + warehouses + tax templates + UoMs.
3. **Consolidated Scheduler Jobs Index** (`docs/architecture/scheduler-jobs.md`). One page enumerating every entry in `scheduler_events` ([hooks.py:433-500](../../erpnext/hooks.py:433)) with frequency, what it does, what fails if it stops, and which module it belongs to.
4. **Portal + Shopping Cart + `www/`** (`docs/modules/portal.md`, possibly `docs/flows/customer-portal-flow.md`). Customer-facing surface is entirely undocumented but shipped: `website_route_rules`, `standard_portal_menu_items`, `on_session_creation`, `has_website_permission`. Includes `templates/`.
5. **Projects module** (`docs/modules/projects.md` + `projects-doctypes.md`). Six scheduler jobs, calendar integration, web_form. Project / Task / Timesheet are routinely linked from Sales Invoice + Sales Order.
6. **CRM module** (`docs/modules/crm.md` + `crm-doctypes.md`). Lead / Opportunity / Prospect / Email Campaign / Contract / Appointment. Five scheduler jobs. Wired into `doc_events["Communication"]` and `doc_events["Event"]`.
7. **Support module** (`docs/modules/support.md` + `support-doctypes.md`). SLA runs on **every doc validate** (`doc_events["*"]`) so anyone tracing a slow save needs this page.
8. **Hooks Catalogue (deep dive)** (`docs/architecture/hooks-catalogue.md`). The existing [hooks-and-overrides.md](../architecture/hooks-and-overrides.md) is more of an overview; a deep catalogue would document each list (`period_closing_doctypes`, `accounting_dimension_doctypes`, `auto_cancel_exempted_doctypes`, `repost_allowed_doctypes`, `subscription_doctypes`, `invoice_doctypes`, `bank_reconciliation_doctypes`, `naming_series_variables`, etc.) with its consumer paths.
9. **Boot session + notifications** (`docs/architecture/boot-session.md`). What `erpnext.startup.boot.boot_session` and `erpnext.startup.boot.bootinfo` inject; what `notification_config` returns.
10. **First batch of ADRs** (`docs/adr/0001-immutable-ledger.md`, `0002-regional-overrides.md`, `0003-no-manufacturing-controller.md`, `0004-payments-app-dependency.md`, `0005-subcontracting-v15-coexistence.md`).
11. **Quality Management, EDI, ERPNext Integrations, Telephony, Communication, Bulk Transaction, Maintenance, Utilities** — short module pages each. Lower blast radius but completes the module table.
12. **Resolve open `TODO(verify)` markers** — 14 small targeted reads, each fixable in one or two file inspections.
13. **i18n contribution workflow** (`docs/getting-started/translation.md`). Optional but useful for community contributors.
14. **Domains, Desktop Icons, Workspace Sidebar** — informational, low priority.

## Changelog

- `2026-04-18` — initial version. Inventoried all `docs/` files vs `erpnext/modules.txt` + top-level `erpnext/` subdirs + every registry in `hooks.py`; produced gap counts (14 modules uncovered, 0 partial, 9 cross-cutting gaps, 6 candidate ADRs, 14 outstanding `TODO(verify)` markers).
