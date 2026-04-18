---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: support
status: complete
related_docs:
  - docs/modules/support.md
---

# Support — DocType reference cards

> **TL;DR:** Eleven DocTypes — one ticket (`Issue`), one warranty entry (`Warranty Claim`), one Single (`Support Settings`), the SLA driver (`Service Level Agreement`) plus its five child tables, and two flat masters (`Issue Type`, `Issue Priority`). See [support.md](support.md) for the module-level narrative.

## Issue

- **File:** [erpnext/support/doctype/issue/issue.py](../../erpnext/support/doctype/issue/issue.py), [erpnext/support/doctype/issue/issue.json](../../erpnext/support/doctype/issue/issue.json).
- **Class:** [Issue](../../erpnext/support/doctype/issue/issue.py:20) extends `Document` directly (no transaction-controller chain).
- **Submittable:** No (status-driven).
- **Naming:** `naming_series` `ISS-.YYYY.-` ([issue.py:44](../../erpnext/support/doctype/issue/issue.py:44)).
- **Status options:** `Open / Replied / On Hold / Resolved / Closed` ([issue.json:120](../../erpnext/support/doctype/issue/issue.json:120)).
- **SLA columns native to schema:** `service_level_agreement`, `response_by`, `agreement_status`, `sla_resolution_by`, `sla_resolution_date`, `service_level_agreement_creation`, `on_hold_since`, `total_hold_time`, `first_responded_on`, `first_response_time`, `resolution_time`, `user_resolution_time`, `avg_response_time` ([issue.json:24-46](../../erpnext/support/doctype/issue/issue.json:24)). Issue is the only SLA-tracked DocType where these are not injected at SLA-creation time.
- **Lifecycle hooks:**
  - `validate` ([issue.py:65-72](../../erpnext/support/doctype/issue/issue.py:65)) — sets `flags.create_communication` on portal-raised insert; defaults `raised_by` to session user; calls `set_lead_contact`.
  - `on_update` ([issue.py:74-78](../../erpnext/support/doctype/issue/issue.py:74)) — emits the initial Communication if portal-raised.
- **Whitelisted:** `split_issue` ([issue.py:121-172](../../erpnext/support/doctype/issue/issue.py:121)) — clones the Issue, resets SLA fields, and re-points later Communications.
- **Mappers:** `make_task` ([issue.py:270-271](../../erpnext/support/doctype/issue/issue.py:270)).
- **Portal:** `get_list_context` ([issue.py:179-187](../../erpnext/support/doctype/issue/issue.py:179)) for `/issues`; `has_website_permission` ([issue.py:256-261](../../erpnext/support/doctype/issue/issue.py:256)) overrides core check to also allow `raised_by == user`.
- **Hook callbacks:**
  - `auto_close_tickets` (daily_maintenance) — [issue.py:229-253](../../erpnext/support/doctype/issue/issue.py:229).
  - `set_first_response_time` (Communication on_update) — [issue.py:301-306](../../erpnext/support/doctype/issue/issue.py:301).
  - `update_issue` (Contact on_trash) — [issue.py:264-266](../../erpnext/support/doctype/issue/issue.py:264).
- **Cross-links:** Customer / Lead / Contact / Project / Email Account / Issue Type / Issue Priority / Service Level Agreement.

## Issue Type

- **File:** [erpnext/support/doctype/issue_type/issue_type.json](../../erpnext/support/doctype/issue_type/issue_type.json).
- **Purpose:** Flat master, one field (`description`). Used as `Issue.issue_type` link.
- **Submittable:** No.

## Issue Priority

- **File:** [erpnext/support/doctype/issue_priority/issue_priority.json](../../erpnext/support/doctype/issue_priority/issue_priority.json).
- **Purpose:** Flat master, one field (`description`). Referenced by `Issue.priority` and `Service Level Priority.priority`.
- **Permissions:** `System Manager` only ([issue_priority.json:23-35](../../erpnext/support/doctype/issue_priority/issue_priority.json:23)).
- **Quick entry:** yes.

## Service Level Agreement

- **File:** [erpnext/support/doctype/service_level_agreement/service_level_agreement.py](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py).
- **Class:** [ServiceLevelAgreement](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:31) extends `Document`.
- **Submittable:** No.
- **Key fields:**
  - `enabled` (toggle) and `default_service_level_agreement` (one-default-per-DocType, enforced in `validate_doc`).
  - `document_type` (Link → DocType) — what target gets the SLA; validated against a whitelist that excludes `Cost Center / Company`, core / email / event_streaming / desk modules ([service_level_agreement.py:181-200](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:181)).
  - `entity_type` ∈ `Customer / Customer Group / Territory` + `entity` (DynamicLink) — scopes the SLA.
  - `apply_sla_for_resolution` — if 0, only first-response is timed.
  - `condition` (Code) — `safe_eval`'d at apply time against the doc.
  - `holiday_list` — drives the working-hours math.
  - `start_date` / `end_date` — `check_agreement_status` (daily) flips `enabled=0` when end_date passes.
  - Child tables: `support_and_resolution → Service Day`, `priorities → Service Level Priority`, `pause_sla_on → Pause SLA On Status`, `sla_fulfilled_on → SLA Fulfilled On Status`.
- **Lifecycle:**
  - `validate` ([service_level_agreement.py:67-73](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:67)) — runs five sub-validators (selected_doctype, doc, status_field, priorities, support_and_resolution, condition).
  - `before_insert` ([service_level_agreement.py:230-241](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:230)) — for non-Issue document_types, injects `service_level_agreement` field set as DocFields (custom DocType) or Custom Fields (standard DocType).
  - `after_insert` / `on_update` / `on_trash` — call `set_documents_with_active_service_level_agreement()` to refresh the redis cache (`doctypes_with_active_sla`).
  - `clear_cache` — invalidates `get_sla_doctypes` redis_cache.
- **Whitelisted:**
  - `get_service_level_agreement_filters(doctype, name, customer)` — filter helper for client-side SLA picker.
  - `reset_service_level_agreement(doctype, docname, reason, user)` — gated by `Support Settings.allow_resetting_service_level_agreement`.
  - `get_user_time(user, to_string)` — timezone-correct `now()` for client display.
  - `get_sla_doctypes()` — the cached list used by `add_sla_doctypes(bootinfo)`.

## SLA child tables

### Service Day

- **File:** [erpnext/support/doctype/service_day/service_day.json](../../erpnext/support/doctype/service_day/service_day.json).
- **Parent:** `Service Level Agreement.support_and_resolution`.
- **Fields:** `workday` (Mon-Sun, required), `start_time`, `end_time`. `validate` on the parent rejects equal/inverted times and duplicate workdays ([service_level_agreement.py:117-137](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:117)).

### Service Level Priority

- **File:** [erpnext/support/doctype/service_level_priority/service_level_priority.json](../../erpnext/support/doctype/service_level_priority/service_level_priority.json).
- **Parent:** `Service Level Agreement.priorities`.
- **Fields:** `priority` (Link → Issue Priority), `response_time` (Duration, required), `resolution_time` (Duration, required if `apply_sla_for_resolution=1`), `default_priority` (Check, exactly one allowed). The default priority is back-filled into `Service Level Agreement.default_priority` ([service_level_agreement.py:111-115](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:111)).

### SLA Fulfilled On Status

- **File:** [erpnext/support/doctype/sla_fulfilled_on_status/sla_fulfilled_on_status.json](../../erpnext/support/doctype/sla_fulfilled_on_status/sla_fulfilled_on_status.json).
- **Parent:** `Service Level Agreement.sla_fulfilled_on`.
- **Fields:** `status` (Select, free-text). Drives the *fulfillment* set of [handle_status_change](../../erpnext/support/doctype/service_level_agreement/service_level_agreement.py:542) — typically `Resolved` and `Closed` for Issue.

### Pause SLA On Status

- **File:** [erpnext/support/doctype/pause_sla_on_status/pause_sla_on_status.json](../../erpnext/support/doctype/pause_sla_on_status/pause_sla_on_status.json).
- **Parent:** `Service Level Agreement.pause_sla_on`.
- **Fields:** `status` (Select, free-text). Drives the *hold* set — typically `Replied` and `On Hold` for Issue.

## Support Settings (Single)

- **File:** [erpnext/support/doctype/support_settings/support_settings.json](../../erpnext/support/doctype/support_settings/support_settings.json).
- **Single:** Yes ([support_settings.json:160](../../erpnext/support/doctype/support_settings/support_settings.json:160)).
- **Key fields:**
  - `track_service_level_agreement` (Check, default 0) — master switch read by `apply` short-circuit and by `validate_doc`/`reset_service_level_agreement` ([support_settings.json:124-128](../../erpnext/support/doctype/support_settings/support_settings.json:124)).
  - `allow_resetting_service_level_agreement` (Check, depends on `track_service_level_agreement`) — gates the `reset_service_level_agreement` whitelisted method.
  - `close_issue_after_days` (Int, default 7) — input for `auto_close_tickets`. `0` disables.
  - `forum_url`, `get_latest_query`, `response_key_list`, `post_title_key`, `post_description_key`, `post_route_key`, `post_route_string` — portal forum-feed integration. `TODO(verify)` consumer not located.
  - `search_apis` (Table → Support Search Source) — pluggable portal search backends.
  - `greeting_title` (default *"We're here to help"*), `greeting_subtitle` — portal landing copy.

## Support Search Source

- **File:** [erpnext/support/doctype/support_search_source/](../../erpnext/support/doctype/support_search_source/).
- **Parent:** `Support Settings.search_apis`.
- **Purpose:** Plug-in search backends for the support portal (each row supplies an API endpoint and field-mapping keys). `TODO(verify)` — consumer code path on the portal side not located in this pass.

## Warranty Claim

- **File:** [erpnext/support/doctype/warranty_claim/warranty_claim.py](../../erpnext/support/doctype/warranty_claim/warranty_claim.py).
- **Class:** [WarrantyClaim](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:13) extends `TransactionBase` (from `erpnext.utilities.transaction_base`) — the only Support DocType outside the plain `Document` base.
- **Submittable:** Yes (`amended_from` field present on schema, `Cancelled` is a status option).
- **Naming:** `naming_series` `SER-WRN-.YYYY.-` ([warranty_claim.py:41](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:41)).
- **Status options:** `Open / Closed / Work In Progress / Cancelled` ([warranty_claim.py:47](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:47)).
- **Key fields:** `customer` (required), `serial_no` (Link → Serial No), `item_code` (Link → Item), `warranty_amc_status` (`Under Warranty / Out of Warranty / Under AMC / Out of AMC`), `warranty_expiry_date`, `amc_expiry_date`, `complaint`, `complaint_date`, `complaint_raised_by`, `resolution_details`, `resolved_by`, `resolution_date`, `service_address`, `from_company`, `customer_group`, `territory`.
- **Lifecycle:**
  - `validate` ([warranty_claim.py:53-62](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:53)) — Customer required (unless raised by Guest); stamp `resolution_date = now()` on first transition to `Closed`.
  - `on_cancel` ([warranty_claim.py:64-75](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:64)) — refuse cancel while non-cancelled `Maintenance Visit Purpose.prevdoc_docname` references this claim; otherwise `db_set("status", "Cancelled")`.
  - `on_update` — no-op.
- **Mappers:** `make_maintenance_visit` ([warranty_claim.py:82-110](../../erpnext/support/doctype/warranty_claim/warranty_claim.py:82)) — refuses if a Fully-Completed Maintenance Visit already exists.
- **Cross-links:** Customer + Customer Address + Contact + Item + [Serial No](stock-doctypes.md) + Maintenance Visit (downstream). Listed in `global_search_doctypes` ([hooks.py:676](../../erpnext/hooks.py:676)).

## Related

- [Support module overview](support.md)
- [Maintenance module](maintenance.md) — Warranty Claim → Maintenance Visit handoff.
- [Stock DocTypes](stock-doctypes.md) — Serial No is the warranty target.
- [Boot session](../architecture/boot-session.md) — `add_sla_doctypes` injects `service_level_agreement_doctypes` into bootinfo.

## Changelog

- `2026-04-18` — initial version. Reference cards for Issue, Issue Type, Issue Priority, Service Level Agreement + 4 child tables, Support Settings (Single), Support Search Source, Warranty Claim.
