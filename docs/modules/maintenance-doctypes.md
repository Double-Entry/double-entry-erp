---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: maintenance
status: complete
related_docs:
  - docs/modules/maintenance.md
---

# Maintenance — DocType reference cards

> **TL;DR:** Five DocTypes — two submittable parents (`Maintenance Schedule`, `Maintenance Visit`), three child tables (`Maintenance Schedule Item`, `Maintenance Schedule Detail`, `Maintenance Visit Purpose`). Both parents extend `TransactionBase`. See [maintenance.md](maintenance.md) for the module-level narrative.

## Maintenance Schedule

- **File:** [erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py).
- **Class:** [MaintenanceSchedule(TransactionBase)](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:13).
- **Submittable:** Yes (`amended_from` field).
- **Naming:** `naming_series` `MAT-MSH-.YYYY.-` ([maintenance_schedule.py:41](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:41)).
- **Status options:** `Draft / Submitted / Cancelled` ([maintenance_schedule.py:43](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:43)).
- **Key fields:** `customer` (required), `customer_name`, `customer_address` / `address_display`, `contact_person` / `contact_display` / `contact_email` / `contact_mobile`, `customer_group`, `territory`, `transaction_date`, `company` (required), `items` (Table → Maintenance Schedule Item), `schedules` (Table → Maintenance Schedule Detail).
- **Lifecycle:**
  - `on_submit` ([maintenance_schedule.py:102-158](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:102)) — refuse if `schedules` empty; `check_serial_no_added`; `validate_schedule`; per item: validate serial nos + `update_amc_date(end_date)`; per scheduled date: insert a private `frappe.Event` at 10:00 owned by the Sales Person's User (or self if missing).
  - `on_cancel` (inherited / via `delete_events` import from `transaction_base`) — wipes the calendar Events.
- **Whitelisted:**
  - `generate_schedule()` ([maintenance_schedule.py:48-69](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:48)) — fan out per-item per-visit Detail rows. Refuses if `docstatus != 0`.
  - `validate_end_date_visits()` ([maintenance_schedule.py:71-100](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:71)) — back-fill `end_date` from `start_date + no_of_visits × periodicity_days` (Weekly=7 / Monthly=30 / Quarterly=91 / Half Yearly=182 / Yearly=365).
- **Helpers:**
  - `create_schedule_list(start_date, end_date, no_of_visits, sales_person)` ([maintenance_schedule.py:160-177](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:160)) — float-day stride distribution; clamps last visit to end_date.
  - `validate_schedule_date_for_holiday_list(schedule_date, sales_person)` ([maintenance_schedule.py:179-200](../../erpnext/maintenance/doctype/maintenance_schedule/maintenance_schedule.py:179)) — pulls schedule_date *backward* one day per holiday, capped by `len(holidays)` iterations.
- **Cross-links:** Customer + Customer Address + Contact + Sales Person + Item + Serial No + Serial and Batch Bundle (per item row). Listed in `global_search_doctypes` ([hooks.py:674](../../erpnext/hooks.py:674)).

## Maintenance Schedule Item

- **File:** [erpnext/maintenance/doctype/maintenance_schedule_item/maintenance_schedule_item.json](../../erpnext/maintenance/doctype/maintenance_schedule_item/maintenance_schedule_item.json).
- **Parent:** `Maintenance Schedule.items`.
- **Naming:** `hash` (random).
- **Key fields:** `item_code` (Link → Item, required), `item_name` (fetch), `description` (TextEditor, fetch), `start_date` (Date, required), `end_date` (Date, required), `periodicity` (`Weekly / Monthly / Quarterly / Half Yearly / Yearly / Random`), `no_of_visits` (Int, required), `sales_person` (Link → Sales Person), `serial_no` (Small Text, read-only), `sales_order` (Link → Sales Order, read-only), `serial_and_batch_bundle` (Link → Serial and Batch Bundle).
- **Drives:** `generate_schedule` reads each row to build the per-visit `Maintenance Schedule Detail` rows.

## Maintenance Schedule Detail

- **File:** [erpnext/maintenance/doctype/maintenance_schedule_detail/](../../erpnext/maintenance/doctype/maintenance_schedule_detail/).
- **Parent:** `Maintenance Schedule.schedules`.
- **Key fields:** `item_code`, `item_name`, `serial_no`, `scheduled_date` (Date), `actual_date` (Date — written by Maintenance Visit submit), `sales_person`, `completion_status` (`Pending / Partially Completed / Fully Completed` — written by Maintenance Visit submit), `item_reference` (back-link to the parent's `Maintenance Schedule Item.name`), `idx` (visit ordinal).
- **Updated by:** [MaintenanceVisit.update_status_and_actual_date](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:102-130) — `db_set` of `completion_status` and `actual_date` on submit (status + date) or cancel (`Pending` + None).

## Maintenance Visit

- **File:** [erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py).
- **Class:** [MaintenanceVisit(TransactionBase)](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:12).
- **Submittable:** Yes (`amended_from` field).
- **Naming:** `naming_series` `MAT-MVS-.YYYY.-` ([maintenance_visit.py:43](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:43)).
- **Status options:** `Draft / Cancelled / Submitted` ([maintenance_visit.py:45](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:45)).
- **Key fields:** `customer` (required), `customer_name`, `customer_address` / `address_display`, `contact_person` / `contact_display` / `contact_email` / `contact_mobile`, `customer_group`, `territory`, `company` (required), `mntc_date` (Date, required), `mntc_time` (Time), `maintenance_type` (`Scheduled / Unscheduled / Breakdown`), `maintenance_schedule` (Link → Maintenance Schedule), `maintenance_schedule_detail` (Link → Maintenance Schedule Detail), `completion_status` (`Partially Completed / Fully Completed`), `customer_feedback` (Small Text), `purposes` (Table → Maintenance Visit Purpose).
- **Lifecycle:**
  - `validate` ([maintenance_visit.py:97-100](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:97)) — `validate_serial_no` (every purpose's `serial_no` must exist), `validate_maintenance_date` (must fall within the `Maintenance Schedule Item.start_date`/`end_date` window when `maintenance_type=Scheduled`), `validate_purpose_table` (non-empty).
  - `on_submit` ([maintenance_visit.py:198-201](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:198)) — `update_customer_issue(1)` (write to Warranty Claim), `db_set status='Submitted'`, `update_status_and_actual_date()` (write to Maintenance Schedule Detail).
  - `on_cancel` ([maintenance_visit.py:203-206](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:203)) — `check_if_last_visit` (refuse if a later non-cancelled Maintenance Visit references the same `prevdoc_docname`), `db_set status='Cancelled'`, `update_status_and_actual_date(cancel=True)`.
  - `on_update` — no-op.
- **Helpers:**
  - `update_status_and_actual_date(cancel=False)` ([maintenance_visit.py:102-130](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:102)) — propagates to `Maintenance Schedule Detail`. On cancel writes `completion_status='Pending'` and `actual_date=None`.
  - `update_customer_issue(flag)` ([maintenance_visit.py:132-172](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:132)) — when a Visit Purpose's `prevdoc_doctype = "Warranty Claim"`, writes back `resolution_date / resolved_by / resolution_details / status`. Cancel path queries the next-most-recent `Partially Completed` visit to revert.
  - `check_if_last_visit()` ([maintenance_visit.py:174-196](../../erpnext/maintenance/doctype/maintenance_visit/maintenance_visit.py:174)) — guards cancel.
- **Cross-links:** Customer + Customer Address + Contact + Maintenance Schedule + Warranty Claim (via per-purpose `prevdoc_doctype`/`prevdoc_docname`) + Sales Order (via Maintenance Visit Purpose). Listed in `global_search_doctypes` ([hooks.py:675](../../erpnext/hooks.py:675)).

## Maintenance Visit Purpose

- **File:** [erpnext/maintenance/doctype/maintenance_visit_purpose/maintenance_visit_purpose.json](../../erpnext/maintenance/doctype/maintenance_visit_purpose/maintenance_visit_purpose.json).
- **Parent:** `Maintenance Visit.purposes`.
- **Naming:** `hash` (random).
- **Key fields:** `item_code` (Link → Item), `item_name` (fetch), `serial_no` (Link → Serial No), `description` (TextEditor, fetch), `service_person` (Link → Sales Person, required), `work_done` (Small Text, required), `prevdoc_doctype` (Link → DocType, hidden — typically `Warranty Claim` or `Sales Order`), `prevdoc_docname` (DynamicLink, hidden — the linked source), `maintenance_schedule_detail` (Data hidden — back-link to a specific Detail row).
- **Cross-links:** This is the per-line bridge to Warranty Claim. The `update_customer_issue` writeback path follows `prevdoc_doctype/prevdoc_docname` to find the claim, and the `WarrantyClaim.on_cancel` ([warranty_claim.py:64-75](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:64)) refuses the claim cancel while a non-cancelled Visit Purpose row references it.

## Related

- [Maintenance module overview](maintenance.md)
- [Support DocTypes — Warranty Claim](support-doctypes.md)
- [Stock DocTypes — Serial No, Serial and Batch Bundle](stock-doctypes.md)
- [Hooks catalogue](../architecture/hooks-catalogue.md)

## Changelog

- `2026-04-18` — initial version. Reference cards for Maintenance Schedule + Maintenance Schedule Item + Maintenance Schedule Detail, Maintenance Visit + Maintenance Visit Purpose.
