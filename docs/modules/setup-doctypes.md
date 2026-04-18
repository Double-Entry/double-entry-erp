---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: setup
status: complete
related_docs:
  - modules/setup.md
  - getting-started/after-install-seed.md
  - architecture/hooks-and-overrides.md
---

# Setup DocType reference cards

> **TL;DR:** Per-DocType reference cards for the 41 files under `erpnext/setup/doctype/`. Grouped by purpose: **Company & multi-company** (Company, Global Defaults, Branch), **Master groups & NestedSet trees** (Item / Customer / Supplier Group, Sales Person, Territory, Department), **HR-adjacent** (Employee + 3 work-history children, Employee Group + child, Designation, Holiday List + Holiday child), **Marketing & sales** (Brand, Sales Partner, Quotation Lost Reason + child, Target Detail), **Logistics & vehicles** (Vehicle, Driver, Driving License Category, Incoterm), **Finance & ops** (Currency Exchange, Authorization Rule, Authorization Control, Email Digest + recipient child, Transaction Deletion Record + 2 children, Terms and Conditions), **Reference data** (UOM, UOM Conversion Factor, Party Type, Website Item Group). Each card lists file path, controller class + base, hooks implemented, and tree status.

## Key files

- [erpnext/setup/doctype/](../../erpnext/setup/doctype) — 41 DocType subdirectories (full enumeration in [modules/setup.md](setup.md) → Directory layout).
- Controller class scan: see [modules/setup.md § Directory layout](setup.md) for the full grep used to populate this page.

## Cards — Company & multi-company

### Company

- **Files:** [company.json](../../erpnext/setup/doctype/company/company.json:1), [company.py](../../erpnext/setup/doctype/company/company.py:1) (1096 lines), `company.js`, `company_dashboard.py`, `company_tree.js`.
- **Controller:** `class Company(NestedSet)` ([company.py:33](../../erpnext/setup/doctype/company/company.py:33)). `nsm_parent_field = "parent_company"` ([line 136](../../erpnext/setup/doctype/company/company.py:136)).
- **Hooks:** `validate` ([164](../../erpnext/setup/doctype/company/company.py:164)), `on_update` ([335](../../erpnext/setup/doctype/company/company.py:335)), `on_trash` ([752](../../erpnext/setup/doctype/company/company.py:752)), `after_rename` ([738](../../erpnext/setup/doctype/company/company.py:738)), `onload` ([138](../../erpnext/setup/doctype/company/company.py:138)).
- **Whitelisted methods:** `check_if_transactions_exist` ([142](../../erpnext/setup/doctype/company/company.py:142)), `create_default_tax_template` ([240](../../erpnext/setup/doctype/company/company.py:240)), `get_children` (treeview, [928](../../erpnext/setup/doctype/company/company.py:928)), `add_node` ([947](../../erpnext/setup/doctype/company/company.py:947)), `get_default_company_address` ([1035](../../erpnext/setup/doctype/company/company.py:1035)), `get_billing_shipping_address` ([1063](../../erpnext/setup/doctype/company/company.py:1063)), `create_transaction_deletion_request` ([1073](../../erpnext/setup/doctype/company/company.py:1073)).
- **Module-level helpers:** `install_country_fixtures(company, country)` ([846](../../erpnext/setup/doctype/company/company.py:846)) — silently swallows `ImportError` (regional module not present); `update_company_current_month_sales` ([861](../../erpnext/setup/doctype/company/company.py:861)), `update_company_monthly_sales` ([898](../../erpnext/setup/doctype/company/company.py:898)), `update_transactions_annual_history` ([910](../../erpnext/setup/doctype/company/company.py:910)), `cache_companies_monthly_sales_history` ([918](../../erpnext/setup/doctype/company/company.py:918)) — daily scheduler.
- **Tree:** Yes (`treeviews` at [hooks.py:77](../../erpnext/hooks.py:77)).
- **NestedSet:** Yes.
- **Cross-doc:** see [modules/setup.md § Company DocType](setup.md) for the full validate/on_update/on_trash walkthrough and the cross-module touchpoint matrix.

### Global Defaults

- **Files:** [global_defaults.json](../../erpnext/setup/doctype/global_defaults/global_defaults.json:1), [global_defaults.py](../../erpnext/setup/doctype/global_defaults/global_defaults.py:1) (Single).
- **Controller:** `class GlobalDefaults(Document)` ([global_defaults.py:38](../../erpnext/setup/doctype/global_defaults/global_defaults.py:38)).
- **Purpose:** holds `default_company`, `default_currency`, `country`, `demo_company`, `use_posting_datetime_for_naming_documents` (consumed by `parse_naming_series_variable` — [accounts/utils.py:1627](../../erpnext/accounts/utils.py:1627)).
- **Hooks:** `get_translated_dict` registered for it ([hooks.py:513](../../erpnext/hooks.py:513)).

### Branch

- **Files:** [branch.json](../../erpnext/setup/doctype/branch/branch.json:1), [branch.py](../../erpnext/setup/doctype/branch/branch.py:1).
- **Controller:** `class Branch(Document)` ([branch.py:8](../../erpnext/setup/doctype/branch/branch.py:8)).
- **Purpose:** physical branch / location label; consumed by Employee.
- **Global search:** included ([hooks.py:671](../../erpnext/hooks.py:671)).

## Cards — Master groups & NestedSet trees

All the following sit in `treeviews` ([hooks.py:77-87](../../erpnext/hooks.py:77)) and ship a `*_tree.js` companion file.

### Item Group

- **Files:** [item_group.json](../../erpnext/setup/doctype/item_group/item_group.json:1), [item_group.py](../../erpnext/setup/doctype/item_group/item_group.py:1).
- **Controller:** `class ItemGroup(NestedSet)` ([item_group.py:10](../../erpnext/setup/doctype/item_group/item_group.py:10)).
- **NestedSet field:** `parent_item_group`.
- **Demo seeds:** `All Item Groups`, `Products`, `Raw Material`, `Services`, `Sub Assemblies`, `Consumable` ([install_fixtures.py:31-67](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:31)).

### Customer Group

- **Files:** [customer_group.py](../../erpnext/setup/doctype/customer_group/customer_group.py:1).
- **Controller:** `class CustomerGroup(NestedSet)` ([customer_group.py:10](../../erpnext/setup/doctype/customer_group/customer_group.py:10)).
- **NestedSet field:** `parent_customer_group`.
- **Demo seeds:** `All Customer Groups`, `Individual`, `Commercial`, `Non Profit`, `Government` ([install_fixtures.py:163-193](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:163)).

### Supplier Group

- **Files:** [supplier_group.py](../../erpnext/setup/doctype/supplier_group/supplier_group.py:1).
- **Controller:** `class SupplierGroup(NestedSet)` ([supplier_group.py:10](../../erpnext/setup/doctype/supplier_group/supplier_group.py:10)).
- **NestedSet field:** `parent_supplier_group`.
- **Demo seeds:** `All Supplier Groups`, `Services`, `Local`, `Raw Material`, `Electrical`, `Hardware`, `Pharmaceutical`, `Distributor` ([install_fixtures.py:194-243](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:194)).

### Sales Person

- **Files:** [sales_person.py](../../erpnext/setup/doctype/sales_person/sales_person.py:1), [sales_person_dashboard.py](../../erpnext/setup/doctype/sales_person/sales_person_dashboard.py:1).
- **Controller:** `class SalesPerson(NestedSet)` ([sales_person.py:19](../../erpnext/setup/doctype/sales_person/sales_person.py:19)).
- **NestedSet field:** `parent_sales_person`.
- **Demo seeds:** `Sales Team` (group root only) ([install_fixtures.py:244-250](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:244)).

### Territory

- **Files:** [territory.py](../../erpnext/setup/doctype/territory/territory.py:1).
- **Controller:** `class Territory(NestedSet)` ([territory.py:11](../../erpnext/setup/doctype/territory/territory.py:11)).
- **NestedSet field:** `parent_territory`.
- **Demo seeds:** `All Territories`, `<country>`, `Rest Of The World` ([install_fixtures.py:142-161](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:142)).

### Department

- **Files:** [department.py](../../erpnext/setup/doctype/department/department.py:1).
- **Controller:** `class Department(NestedSet)` ([department.py:13](../../erpnext/setup/doctype/department/department.py:13)).
- **NestedSet field:** `parent_department`.
- **Auto-seeded by Company:** 14-entry tree under `All Departments` (Accounts / Marketing / Sales / Purchase / Operations / Production / Dispatch / Customer Service / Human Resources / Management / Quality Management / Research & Development / Legal) — [company.py:432-528](../../erpnext/setup/doctype/company/company.py:432).
- **Global search:** included ([hooks.py:672](../../erpnext/hooks.py:672)).

## Cards — HR-adjacent

### Employee

- **Files:** [employee.json](../../erpnext/setup/doctype/employee/employee.json:1), [employee.py](../../erpnext/setup/doctype/employee/employee.py:1) (614 lines).
- **Controller:** `class Employee(NestedSet)` ([employee.py:25](../../erpnext/setup/doctype/employee/employee.py:25)).
- **NestedSet field:** `reports_to` (implicit — see `Employee.json`).
- **Custom errors:** `EmployeeUserDisabledError`, `InactiveEmployeeStatusError` ([employee.py:17-22](../../erpnext/setup/doctype/employee/employee.py:17)).
- **Module-level helpers:** `validate_employee_role(doc, method=None, ignore_emp_check=False)` ([line 344](../../erpnext/setup/doctype/employee/employee.py:344)) — wired to `User.validate` at [hooks.py:359](../../erpnext/hooks.py:359); strips `Employee` and `Employee Self Service` roles when no Employee row links to that user. `has_upload_permission` ([553](../../erpnext/setup/doctype/employee/employee.py:553)) registered at [hooks.py:305](../../erpnext/hooks.py:305). `get_holiday_list_for_employee` ([368](../../erpnext/setup/doctype/employee/employee.py:368)) — falls back to `Company.default_holiday_list`. `is_holiday` ([390](../../erpnext/setup/doctype/employee/employee.py:390)).
- **Note:** Setup-side scope only — full HR functionality (Leave, Attendance, Salary) lives in the separate HRMS app.
- **Children inside Setup module:**
  - [employee_education.py:8](../../erpnext/setup/doctype/employee_education/employee_education.py:8) — `EmployeeEducation(Document)` (child).
  - [employee_external_work_history.py:8](../../erpnext/setup/doctype/employee_external_work_history/employee_external_work_history.py:8) — child.
  - [employee_internal_work_history.py:8](../../erpnext/setup/doctype/employee_internal_work_history/employee_internal_work_history.py:8) — child.
- **Global search:** included ([hooks.py:644](../../erpnext/hooks.py:644)).

### Employee Group + Employee Group Table

- [employee_group.py:8](../../erpnext/setup/doctype/employee_group/employee_group.py:8) — `class EmployeeGroup(Document)`.
- [employee_group_table.py:8](../../erpnext/setup/doctype/employee_group_table/employee_group_table.py:8) — child table.

### Designation

- [designation.py:8](../../erpnext/setup/doctype/designation/designation.py:8) — `class Designation(Document)`.
- **Demo seeds:** loaded from `setup_wizard/data/designation.txt` via `install_fixtures.install` ([install_fixtures.py:325-332](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:325)).
- **Global search:** included ([hooks.py:673](../../erpnext/hooks.py:673)).

### Holiday List + Holiday

- **Files:** [holiday_list.py](../../erpnext/setup/doctype/holiday_list/holiday_list.py:1), [holiday.py](../../erpnext/setup/doctype/holiday/holiday.py:1).
- **Controllers:** `class HolidayList(Document)` ([holiday_list.py:18](../../erpnext/setup/doctype/holiday_list/holiday_list.py:18)) — flat (not NestedSet); `class Holiday(Document)` ([holiday.py:8](../../erpnext/setup/doctype/holiday/holiday.py:8)) — child table.
- **Hooks:** `validate` runs `validate_days` + `validate_duplicate_date` + `sort_holidays` ([holiday_list.py:43-47](../../erpnext/setup/doctype/holiday_list/holiday_list.py:43)).
- **Custom errors:** `OverlapError` ([holiday_list.py:14](../../erpnext/setup/doctype/holiday_list/holiday_list.py:14)).
- **Whitelisted:** `get_weekly_off_dates` ([holiday_list.py:49](../../erpnext/setup/doctype/holiday_list/holiday_list.py:49)).
- **Calendars hook:** registered at [hooks.py:111](../../erpnext/hooks.py:111).

## Cards — Marketing & sales support

### Brand

- [brand.py:9](../../erpnext/setup/doctype/brand/brand.py:9) — `class Brand(Document)`. Plain master.

### Sales Partner

- **Files:** [sales_partner.py](../../erpnext/setup/doctype/sales_partner/sales_partner.py:1).
- **Note:** Listed in `website_generators = ["BOM", "Sales Partner"]` ([hooks.py:113](../../erpnext/hooks.py:113)) — the doc has a public web view (partners directory).

### Quotation Lost Reason + Quotation Lost Reason Detail

- [quotation_lost_reason.py:8](../../erpnext/setup/doctype/quotation_lost_reason/quotation_lost_reason.py:8) — `class QuotationLostReason(Document)`.
- [quotation_lost_reason_detail.py:9](../../erpnext/setup/doctype/quotation_lost_reason_detail/quotation_lost_reason_detail.py:9) — child table.

### Target Detail

- [target_detail.py:8](../../erpnext/setup/doctype/target_detail/target_detail.py:8) — `class TargetDetail(Document)`. Child table used by Sales Person / Territory / Item Group for target setting.

### Website Item Group

- [website_item_group.py:10](../../erpnext/setup/doctype/website_item_group/website_item_group.py:10) — `class WebsiteItemGroup(Document)`. Child table on Website Item linking to Item Group.

## Cards — Logistics & vehicles

### Vehicle + Vehicle Dashboard

- [vehicle.py:11](../../erpnext/setup/doctype/vehicle/vehicle.py:11) — `class Vehicle(Document)`.
- [vehicle_dashboard.py](../../erpnext/setup/doctype/vehicle/vehicle_dashboard.py:1) — desk dashboard.

### Driver

- [driver.py:8](../../erpnext/setup/doctype/driver/driver.py:8) — `class Driver(Document)`.

### Driving License Category

- [driving_license_category.py:8](../../erpnext/setup/doctype/driving_license_category/driving_license_category.py:8) — `class DrivingLicenseCategory(Document)`.

### Incoterm

- [incoterm.py:8](../../erpnext/setup/doctype/incoterm/incoterm.py:8) — `class Incoterm(Document)`.
- **Seed source:** [incoterms.csv](../../erpnext/setup/doctype/incoterm/incoterms.csv:1).
- **Loader:** `create_incoterms()` is invoked from [install.py:31](../../erpnext/setup/install.py:31).

## Cards — Finance & ops

### Currency Exchange

- [currency_exchange.py:12](../../erpnext/setup/doctype/currency_exchange/currency_exchange.py:12) — `class CurrencyExchange(Document)`.
- **Hooks:** `autoname` ([line 29](../../erpnext/setup/doctype/currency_exchange/currency_exchange.py:29)) — composite name `<yyyy-MM-dd>-<from>-<to>[-<purpose>]`. `validate` ([line 48](../../erpnext/setup/doctype/currency_exchange/currency_exchange.py:48)) — `exchange_rate > 0`, distinct currencies, at least one of `for_buying` / `for_selling`.
- **Seeded provider:** `frankfurter.dev` via `setup_currency_exchange()` in `after_install` ([install.py:85](../../erpnext/setup/install.py:85)).

### Authorization Rule

- [authorization_rule.py:11](../../erpnext/setup/doctype/authorization_rule/authorization_rule.py:11) — `class AuthorizationRule(Document)`.
- **Hooks:** `validate` runs `check_duplicate_entry` + `validate_rule` ([line 97](../../erpnext/setup/doctype/authorization_rule/authorization_rule.py:97)).
- **Field shape:** `transaction` Literal of 7 values ([line 38](../../erpnext/setup/doctype/authorization_rule/authorization_rule.py:38)); `based_on` Literal of 6 values ([line 22](../../erpnext/setup/doctype/authorization_rule/authorization_rule.py:22)); `customer_or_item` Literal of 3 values ([line 32](../../erpnext/setup/doctype/authorization_rule/authorization_rule.py:32)).

### Authorization Control

- [authorization_control.py:12](../../erpnext/setup/doctype/authorization_control/authorization_control.py:12) — `class AuthorizationControl(TransactionBase)`.
- **Method:** `get_appr_user_role(det, doctype_name, total, based_on, condition, master_name, company)` ([line 23](../../erpnext/setup/doctype/authorization_control/authorization_control.py:23)) — loads matching `Authorization Rule` rows by `(transaction, value, based_on, company)` and throws if neither user nor role matches.
- **Note:** `class AuthorizationControl(TransactionBase)` is the only Setup-module DocType that extends `TransactionBase` (rather than `Document` or `NestedSet`).

### Email Digest + Email Digest Recipient

- [email_digest.py:32](../../erpnext/setup/doctype/email_digest/email_digest.py:32) — `class EmailDigest(Document)` (952 lines).
- [email_digest_recipient.py:9](../../erpnext/setup/doctype/email_digest_recipient/email_digest_recipient.py:9) — child table (TableMultiSelect).
- **Hooks:** `__init__` resolves company currency + date window ([email_digest.py:77-83](../../erpnext/setup/doctype/email_digest/email_digest.py:77)).
- **Whitelisted:** `get_users` ([85](../../erpnext/setup/doctype/email_digest/email_digest.py:85)), `send` ([107](../../erpnext/setup/doctype/email_digest/email_digest.py:107)).
- **Daily scheduler:** [hooks.py:488](../../erpnext/hooks.py:488).
- **Frequency:** Literal `Daily / Weekly / Monthly` ([line 53](../../erpnext/setup/doctype/email_digest/email_digest.py:53)).

### Transaction Deletion Record + 2 children

- [transaction_deletion_record.py:113](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:113) — `class TransactionDeletionRecord(Document)` (1126 lines).
- **Children:**
  - [transaction_deletion_record_item.py:9](../../erpnext/setup/doctype/transaction_deletion_record_item/transaction_deletion_record_item.py:9) — `TransactionDeletionRecordItem(Document)` (`doctypes_to_be_ignored`).
  - [transaction_deletion_record_to_delete.py:8](../../erpnext/setup/doctype/transaction_deletion_record_to_delete/transaction_deletion_record_to_delete.py:8) — `TransactionDeletionRecordToDelete(Document)` (`doctypes_to_delete`).
  - Plus a third child from the Accounts module: `Transaction Deletion Record Details` ([accounts/doctype/transaction_deletion_record_details/transaction_deletion_record_details.py:1](../../erpnext/accounts/doctype/transaction_deletion_record_details/transaction_deletion_record_details.py:1)) (`doctypes`).
- **Hooks:** `validate` ([166](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:166)) — System Manager only; populates ignore-list; validates `to_delete`. `before_save` ([285](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:285)) — clears doctypes table, resets task flags. `before_submit` ([259](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:259)) — blocks if another TDR is Queued/Running. `on_submit` ([290](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:290)) — `db_set("status", "Queued")` + `start_deletion_tasks()`. `on_cancel` ([294](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:294)) — flips status + clears Redis cache. `on_discard` ([163](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:163)).
- **Module-level functions:**
  - `get_protected_doctypes()` ([line 70](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:70)) — whitelisted; lists everything in `PROTECTED_CORE_DOCTYPES` ([line 25](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:25)) plus all Singles.
  - `get_company_link_fields(doctype_name)` ([78](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:78)) — whitelisted helper for the form.
  - `is_deletion_doc_running(company)` (declared near line 1080) — used by `Company.create_transaction_deletion_request`.
  - `check_for_running_deletion_job(doc, method=None)` ([1108](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:1108)) — wired to `doc_events["*"].validate` at [hooks.py:347](../../erpnext/hooks.py:347). Reads Redis cache `deletion_running_doctype:{doctype}` and throws if a deletion is currently in flight for that DocType. Skips ledger doctypes (`GL Entry`, `Payment Ledger Entry`, `Stock Ledger Entry`) and protected core DocTypes.
- **Constants:** `LEDGER_ENTRY_DOCTYPES` ([line 15](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:15)), `DELETION_CACHE_TTL = 4h` ([line 23](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:23)), `PROTECTED_CORE_DOCTYPES` ([line 25-67](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:25)).
- **Ordered tasks** ([line 152](../../erpnext/setup/doctype/transaction_deletion_record/transaction_deletion_record.py:152)): `Delete Bins → Delete Leads and Addresses → Reset Company Values → Clear Notifications → Initialize Summary Table → Delete Transactions`.

### Terms and Conditions

- [terms_and_conditions.py:14](../../erpnext/setup/doctype/terms_and_conditions/terms_and_conditions.py:14) — `class TermsandConditions(Document)`. Master used by transaction DocTypes via `tc_name` Link.

## Cards — Reference data

### UOM

- [uom.py:8](../../erpnext/setup/doctype/uom/uom.py:8) — `class UOM(Document)`.
- **Bootstrap data:** [setup_wizard/data/uom_data.json](../../erpnext/setup/setup_wizard/data/uom_data.json) loaded by `add_uom_data` ([install_fixtures.py:387](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:387)).

### UOM Conversion Factor

- [uom_conversion_factor.py:8](../../erpnext/setup/doctype/uom_conversion_factor/uom_conversion_factor.py:8) — `class UOMConversionFactor(Document)`.
- **Bootstrap data:** [setup_wizard/data/uom_conversion_data.json](../../erpnext/setup/setup_wizard/data/uom_conversion_data.json) loaded at [install_fixtures.py:402](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:402).

### Party Type

- [party_type.py:10](../../erpnext/setup/doctype/party_type/party_type.py:10) — `class PartyType(Document)`.
- **Demo seeds:** Customer (Receivable), Supplier (Payable), Employee (Payable), Shareholder (Payable) ([install_fixtures.py:293-296](../../erpnext/setup/setup_wizard/operations/install_fixtures.py:293)).

## Module summary

| DocType | Class | Base | Tree (NestedSet) | Hooks consumed |
|---|---|---|---|---|
| Company | `Company` | `NestedSet` | Yes | validate, on_update, on_trash, after_rename, onload |
| Global Defaults | `GlobalDefaults` | `Document` (Single) | — | — |
| Branch | `Branch` | `Document` | — | — |
| Item Group | `ItemGroup` | `NestedSet` | Yes | — |
| Customer Group | `CustomerGroup` | `NestedSet` | Yes | — |
| Supplier Group | `SupplierGroup` | `NestedSet` | Yes | — |
| Sales Person | `SalesPerson` | `NestedSet` | Yes | — |
| Territory | `Territory` | `NestedSet` | Yes | — |
| Department | `Department` | `NestedSet` | Yes | — |
| Employee | `Employee` | `NestedSet` | Yes | — (extensive — see HRMS) |
| Employee Education | `EmployeeEducation` | `Document` (child) | — | — |
| Employee External Work History | `EmployeeExternalWorkHistory` | `Document` (child) | — | — |
| Employee Internal Work History | `EmployeeInternalWorkHistory` | `Document` (child) | — | — |
| Employee Group | `EmployeeGroup` | `Document` | — | — |
| Employee Group Table | `EmployeeGroupTable` | `Document` (child) | — | — |
| Designation | `Designation` | `Document` | — | — |
| Holiday List | `HolidayList` | `Document` | — | validate |
| Holiday | `Holiday` | `Document` (child) | — | — |
| Brand | `Brand` | `Document` | — | — |
| Sales Partner | `SalesPartner` | `Document` (web) | — | — |
| Quotation Lost Reason | `QuotationLostReason` | `Document` | — | — |
| Quotation Lost Reason Detail | `QuotationLostReasonDetail` | `Document` (child) | — | — |
| Target Detail | `TargetDetail` | `Document` (child) | — | — |
| Website Item Group | `WebsiteItemGroup` | `Document` (child) | — | — |
| Vehicle | `Vehicle` | `Document` | — | — |
| Driver | `Driver` | `Document` | — | — |
| Driving License Category | `DrivingLicenseCategory` | `Document` | — | — |
| Incoterm | `Incoterm` | `Document` | — | — |
| Currency Exchange | `CurrencyExchange` | `Document` | — | autoname, validate |
| Authorization Rule | `AuthorizationRule` | `Document` | — | validate |
| Authorization Control | `AuthorizationControl` | `TransactionBase` | — | (consumer methods only) |
| Email Digest | `EmailDigest` | `Document` | — | __init__ |
| Email Digest Recipient | `EmailDigestRecipient` | `Document` (child) | — | — |
| Transaction Deletion Record | `TransactionDeletionRecord` | `Document` | — | validate, before_save, before_submit, on_submit, on_cancel, on_discard |
| Transaction Deletion Record Item | `TransactionDeletionRecordItem` | `Document` (child) | — | — |
| Transaction Deletion Record To Delete | `TransactionDeletionRecordToDelete` | `Document` (child) | — | — |
| Terms and Conditions | `TermsandConditions` | `Document` | — | — |
| UOM | `UOM` | `Document` | — | — |
| UOM Conversion Factor | `UOMConversionFactor` | `Document` | — | — |
| Party Type | `PartyType` | `Document` | — | — |

## Related

- [Setup module](setup.md) — module-level overview (Company on_update mass-setup, Setup Wizard stages, Naming Series, scheduler entries, cross-module touchpoints).
- [Getting started — after_install seed catalogue](../getting-started/after-install-seed.md) — what `after_install` seeds at install time.
- [Hooks and overrides](../architecture/hooks-and-overrides.md) — `treeviews`, `naming_series_variables`, `setup_wizard_stages`, `demo_master_doctypes`, `doc_events["User"]`, `doc_events["*"].validate`.

## Changelog

- `2026-04-18` — initial version.
