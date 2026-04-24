---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: communication
status: complete
related_docs:
  - modules/communication.md
---

# Communication — DocType reference cards

> **TL;DR:** Two configuration DocTypes. `Communication Medium` is the parent; `Communication Medium Timeslot` is its child table. Both are pure schema (no `validate`, no `on_update`). Distinct from Frappe core's `Communication` DocType.

## Module summary

| DocType | File | istable | Hooks |
|---------|------|---------|-------|
| Communication Medium | [erpnext/communication/doctype/communication_medium/](../../erpnext/communication/doctype/communication_medium/) | 0 | none |
| Communication Medium Timeslot | [erpnext/communication/doctype/communication_medium_timeslot/](../../erpnext/communication/doctype/communication_medium_timeslot/) | 1 | none |

## Communication Medium

- **File:** [erpnext/communication/doctype/communication_medium/communication_medium.py](../../erpnext/communication/doctype/communication_medium/communication_medium.py:1) (30 lines, plain `Document`).
- **Schema:** [erpnext/communication/doctype/communication_medium/communication_medium.json](../../erpnext/communication/doctype/communication_medium/communication_medium.json:1).
- **Fields (auto-generated types at [communication_medium.py:14-27](../../erpnext/communication/doctype/communication_medium/communication_medium.py:14)):**
  - `communication_medium_type` — `DF.Literal["Voice", "Email", "Chat"]`.
  - `communication_channel` — `DF.Literal` (options in JSON only).
  - `provider` — `DF.Link | None`.
  - `catch_all` — `DF.Link | None`.
  - `disabled` — `DF.Check`.
  - `timeslots` — `DF.Table[CommunicationMediumTimeslot]`.
- **Lifecycle:** **none** (`pass` at [line 30](../../erpnext/communication/doctype/communication_medium/communication_medium.py:30)).
- **Consumers:**
  - Telephony's `Call Log.medium` field (`DF.Data` label, [call_log.py:35](../../erpnext/telephony/doctype/call_log/call_log.py:35)).
  - CRM's `crm.utils.get_scheduled_employees_for_popup` reads the medium's `timeslots` table.

## Communication Medium Timeslot

- **File:** [erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.py](../../erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.py:1) (28 lines, plain `Document`).
- **Schema:** [erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.json](../../erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.json:1) — `istable=1`.
- **Fields (auto-generated types at [communication_medium_timeslot.py:13-25](../../erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.py:13)):**
  - `day_of_week` — `DF.Literal["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]`.
  - `from_time`, `to_time` — `DF.Time`.
  - `employee_group` — `DF.Link` to Employee Group. Required.
  - Standard child-table linkage fields.
- **Lifecycle:** **none** (`pass` at [line 27](../../erpnext/communication/doctype/communication_medium_timeslot/communication_medium_timeslot.py:27)).

## Related

- [Communication module](communication.md)

## Changelog

- `2026-04-18` — initial version. Cards for Communication Medium + child Timeslot.
