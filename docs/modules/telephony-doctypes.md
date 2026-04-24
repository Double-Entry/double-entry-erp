---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: telephony
status: complete
related_docs:
  - modules/telephony.md
---

# Telephony — DocType reference cards

> **TL;DR:** Five DocTypes: `Call Log` (the workhorse), `Incoming Call Settings` (Single, with `Incoming Call Handling Schedule` child), `Voice Call Settings` (per-User), `Telephony Call Type` (label, submittable). Only `Call Log` carries lifecycle hooks; the rest are configuration.

## Module summary

| DocType | File | Type | Hooks |
|---------|------|------|-------|
| Call Log | [erpnext/telephony/doctype/call_log/](../../erpnext/telephony/doctype/call_log/) | regular | `validate`, `before_insert`, `after_insert`, `on_update` |
| Incoming Call Settings | [erpnext/telephony/doctype/incoming_call_settings/](../../erpnext/telephony/doctype/incoming_call_settings/) | Single | `validate` |
| Incoming Call Handling Schedule | [erpnext/telephony/doctype/incoming_call_handling_schedule/](../../erpnext/telephony/doctype/incoming_call_handling_schedule/) | child (`istable=1`) | none |
| Voice Call Settings | [erpnext/telephony/doctype/voice_call_settings/](../../erpnext/telephony/doctype/voice_call_settings/) | regular (per-User) | none |
| Telephony Call Type | [erpnext/telephony/doctype/telephony_call_type/](../../erpnext/telephony/doctype/telephony_call_type/) | submittable | none |

## Call Log

- **File:** [erpnext/telephony/doctype/call_log/call_log.py](../../erpnext/telephony/doctype/call_log/call_log.py:1) (228 lines).
- **Schema:** [erpnext/telephony/doctype/call_log/call_log.json](../../erpnext/telephony/doctype/call_log/call_log.json:1).
- **Fields (auto-generated types at [call_log.py:22-45](../../erpnext/telephony/doctype/call_log/call_log.py:22)):**
  - `id` — `DF.Data` (provider call ID).
  - `from`, `to` — `DF.Data`.
  - `medium` — `DF.Data` (incoming line / DID).
  - `start_time`, `end_time` — `DF.Datetime | None`.
  - `duration` — `DF.Duration | None`.
  - `recording_url` — `DF.Data | None`.
  - `summary` — `DF.SmallText | None`.
  - `status` — `DF.Literal["Ringing", "In Progress", "Completed", "Failed", "Busy", "No Answer", "Queued", "Cancelled"]`.
  - `type` — `DF.Literal["Incoming", "Outgoing"]`.
  - `type_of_call` — `DF.Link | None` to `Telephony Call Type`.
  - `call_received_by`, `employee_user_id`, `customer` — `DF.Link | None`.
  - `links` — `DF.Table[DynamicLink]` (auto-populated by `before_insert`).
- **Lifecycle:**
  - `validate` ([line 47](../../erpnext/telephony/doctype/call_log/call_log.py:47)) — `deduplicate_dynamic_links(self)`.
  - `before_insert` ([line 50](../../erpnext/telephony/doctype/call_log/call_log.py:50)) — auto-link Contact + Lead by phone; for incoming, set `call_received_by` from Employee.
  - `after_insert` ([line 65](../../erpnext/telephony/doctype/call_log/call_log.py:65)) — for incoming, fire desk popup via `frappe.publish_realtime("show_call_popup", self, user=email)` to scheduled employees.
  - `on_update` ([line 68](../../erpnext/telephony/doctype/call_log/call_log.py:68)) — emit `call_<id>_missed` / `call_<id>_ended` realtime events on status transitions.
- **Module-level helpers:**
  - `link_existing_conversations(doc, state)` ([line 156](../../erpnext/telephony/doctype/call_log/call_log.py:156)) — Contact `after_insert` hook target ([hooks.py:400](../../erpnext/hooks.py:400)).
  - `get_linked_call_logs(doctype, docname)` ([line 200](../../erpnext/telephony/doctype/call_log/call_log.py:200)) — universal timeline content hook target ([hooks.py:684](../../erpnext/hooks.py:684)).
  - `get_employees_with_number(number)` ([line 136](../../erpnext/telephony/doctype/call_log/call_log.py:136)) — cached lookup of `Employee.cell_number LIKE %number%`.
  - `add_call_summary_and_call_type(call_log, summary, call_type)` ([line 128](../../erpnext/telephony/doctype/call_log/call_log.py:128)) — `@frappe.whitelist()`.
- **Cross-references in `hooks.py`:**
  - [hooks.py:400](../../erpnext/hooks.py:400) — `doc_events["Contact"].after_insert`.
  - [hooks.py:684](../../erpnext/hooks.py:684) — `additional_timeline_content["*"]`.

## Incoming Call Settings

- **File:** [erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.py](../../erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.py:1) (85 lines).
- **Schema:** [erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.json](../../erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.json:1) — `issingle=1`.
- **Fields (auto-generated types at [incoming_call_settings.py:18-30](../../erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.py:18)):**
  - `greeting_message`, `agent_busy_message`, `agent_unavailable_message` — `DF.Data | None`.
  - `call_routing` — `DF.Literal["Sequential", "Simultaneous"]`.
  - `call_handling_schedule` — `DF.Table[IncomingCallHandlingSchedule]`.
- **Lifecycle:**
  - `validate` ([line 32-38](../../erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.py:32)) → `validate_call_schedule_timeslot` + `validate_call_schedule_overlaps`. The overlap check ([line 56-72](../../erpnext/telephony/doctype/incoming_call_settings/incoming_call_settings.py:56)) sorts per-day timeslots and rejects any pair where `ts1.end > ts2.start`.

## Incoming Call Handling Schedule

- **File:** [erpnext/telephony/doctype/incoming_call_handling_schedule/incoming_call_handling_schedule.py](../../erpnext/telephony/doctype/incoming_call_handling_schedule/incoming_call_handling_schedule.py:1) (28 lines, plain `Document`).
- **Fields (auto-generated types at [incoming_call_handling_schedule.py:13-24](../../erpnext/telephony/doctype/incoming_call_handling_schedule/incoming_call_handling_schedule.py:13)):**
  - `agent_group` — `DF.Link` to Employee Group.
  - `day_of_week` — `DF.Literal["Monday", ..., "Sunday"]`.
  - `from_time`, `to_time` — `DF.Time`.
  - Standard child-table linkage fields.
- **Lifecycle:** none.

## Voice Call Settings

- **File:** [erpnext/telephony/doctype/voice_call_settings/voice_call_settings.py](../../erpnext/telephony/doctype/voice_call_settings/voice_call_settings.py:1) (26 lines, plain `Document`).
- **Fields (auto-generated types at [voice_call_settings.py:14-22](../../erpnext/telephony/doctype/voice_call_settings/voice_call_settings.py:14)):**
  - `user` — `DF.Link` (per-User configuration).
  - `call_receiving_device` — `DF.Literal["Computer", "Phone"]`.
  - `greeting_message`, `agent_busy_message`, `agent_unavailable_message` — `DF.Data | None`.
- **Lifecycle:** none.

## Telephony Call Type

- **File:** [erpnext/telephony/doctype/telephony_call_type/telephony_call_type.py](../../erpnext/telephony/doctype/telephony_call_type/telephony_call_type.py:1) (22 lines, plain `Document`).
- **Schema:** [erpnext/telephony/doctype/telephony_call_type/telephony_call_type.json](../../erpnext/telephony/doctype/telephony_call_type/telephony_call_type.json:1) — submittable (carries `amended_from` field).
- **Fields (auto-generated types at [telephony_call_type.py:13-19](../../erpnext/telephony/doctype/telephony_call_type/telephony_call_type.py:13)):**
  - `call_type` — `DF.Data`.
  - `amended_from` — `DF.Link | None` (submittable amend chain).
- **Lifecycle:** none.
- **Consumed by:** `Call Log.type_of_call`.

## Related

- [Telephony module](telephony.md)
- [CRM module](crm.md) — `crm.utils.strip_number`, `get_scheduled_employees_for_popup`, `lead.get_lead_with_phone_number`.

## Changelog

- `2026-04-18` — initial version. Cards for Call Log, Incoming Call Settings, Incoming Call Handling Schedule, Voice Call Settings, Telephony Call Type.
