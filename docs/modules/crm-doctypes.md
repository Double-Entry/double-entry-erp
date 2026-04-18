---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: crm
status: complete
related_docs:
  - docs/modules/crm.md
---

# CRM — DocType reference cards

> **TL;DR:** Twenty-five DocTypes spanning the full pre-sales funnel: leads/opportunities/prospects with their child tables and lost-reason masters, the campaign/email pipeline (`Campaign`, `Email Campaign`, `Campaign Email Schedule`), the appointment booking surface (`Appointment` + 3 settings DocTypes), the `Contract` cluster (4 DocTypes), and the CRM Single. See [crm.md](crm.md) for the module-level narrative.

## Lead

- **File:** [erpnext/crm/doctype/lead/lead.py](../../erpnext/crm/doctype/lead/lead.py).
- **Class:** [Lead(SellingController, CRMNote)](../../erpnext/crm/doctype/lead/lead.py:24) — the **only CRM DocType in the SellingController chain**. See [crm.md](crm.md#why-lead-extends-sellingcontroller-and-opportunity-does-not).
- **Submittable:** No.
- **Naming:** `naming_series` `CRM-LEAD-.YYYY.-` ([lead.py:57](../../erpnext/crm/doctype/lead/lead.py:57)).
- **Status options:** `Lead / Open / Replied / Opportunity / Quotation / Lost Quotation / Interested / Converted / Do Not Contact` ([lead.py:68-78](../../erpnext/crm/doctype/lead/lead.py:68)).
- **Key fields:** `first_name / middle_name / last_name`, `salutation`, `lead_name` (computed), `company_name`, `email_id`, `phone`, `mobile_no`, `whatsapp_no`, `phone_ext`, `gender`, `job_title`, `image` (gravatar-derived), `industry`, `market_segment`, `no_of_employees`, `annual_revenue`, `qualification_status` (`Unqualified / In Process / Qualified`), `qualified_by`, `qualified_on`, `request_type`, `lead_owner`, `customer` (back-link after conversion), `territory`, `country`, `city`, `state`, `language`, `disabled`, `unsubscribed`, `blog_subscriber`, `type` (`Client / Channel Partner / Consultant`), UTM block (`utm_source / utm_medium / utm_campaign / utm_content`), `notes` (Table → CRM Note via `CRMNote` mixin).
- **Lifecycle:**
  - `validate` ([lead.py:97-103](../../erpnext/crm/doctype/lead/lead.py:97)) → `set_full_name`, `set_lead_name`, `set_title`, `set_status`, `check_email_id_is_unique`, `validate_email_id`.
  - `before_insert` ([lead.py:105-122](../../erpnext/crm/doctype/lead/lead.py:105)) → optional Contact auto-creation (gated by `CRM Settings.auto_creation_of_contact`); `parse_full_name` from `lead_name` for inbox-created Leads.
  - `after_insert` → `link_to_contact` (appends `Lead` row to `Contact.links`).
  - `on_update` → `update_prospect` (mirror or create `Prospect Lead`).
  - `on_trash` → clears `Issue.lead`, deletes Contact + Address links, removes from Prospect.
- **Whitelisted:**
  - `make_customer(source_name, target_doc)` — Lead → Customer ([lead.py:319-362](../../erpnext/crm/doctype/lead/lead.py:319)).
  - `make_opportunity(source_name, target_doc)` — Lead → Opportunity, sets `opportunity_from = "Lead"` ([lead.py:366-392](../../erpnext/crm/doctype/lead/lead.py:366)).
  - `make_quotation(source_name, target_doc)` — Lead → Quotation, sets `quotation_to = "Lead"` ([lead.py:396-413](../../erpnext/crm/doctype/lead/lead.py:396)).
  - `get_lead_details(lead, posting_date, company, doctype)` — feeds Selling defaults.
  - `add_note / edit_note / delete_note` from CRMNote mixin.
- **Privacy:** Listed in `user_privacy_documents` ([hooks.py:622-627](../../erpnext/hooks.py:622)) — match field `email_id`, scrubs `phone / mobile_no / fax / website / lead_name`.
- **Cross-links:** Customer (forward), Issue (reverse via `Issue.lead`), Prospect (via Prospect Lead child), Quotation (via `quotation_to=Lead`).

## Lead Source

- **File:** [erpnext/crm/doctype/lead_source/](../../erpnext/crm/doctype/lead_source/).
- **Purpose:** Flat master, link target for `Lead.source` (legacy field; mostly superseded by UTM block).

## Opportunity

- **File:** [erpnext/crm/doctype/opportunity/opportunity.py](../../erpnext/crm/doctype/opportunity/opportunity.py).
- **Class:** [Opportunity(TransactionBase, CRMNote)](../../erpnext/crm/doctype/opportunity/opportunity.py:28) — **TransactionBase, not full SellingController**.
- **Submittable:** Yes (`amended_from` field present).
- **Naming:** `naming_series` `CRM-OPP-.YYYY.-` ([opportunity.py:70](../../erpnext/crm/doctype/opportunity/opportunity.py:70)).
- **Status options:** `Open / Quotation / Converted / Lost / Replied / Closed` ([opportunity.py:84](../../erpnext/crm/doctype/opportunity/opportunity.py:84)).
- **Key fields:** `opportunity_from` (Link → DocType, restricted to Lead / Customer / Prospect), `party_name` (DynamicLink), `customer_name`, `contact_person`, `contact_email`, `contact_mobile`, `transaction_date`, `expected_closing`, `probability` (Percent), `sales_stage` (Link → Sales Stage), `opportunity_owner`, `opportunity_type` (defaults to `Sales`), `currency`, `conversion_rate` (FX to company currency), `opportunity_amount` (manual), `total` / `base_total` (computed from items), `competitors` (TableMultiSelect → Competitor Detail), `lost_reasons` (TableMultiSelect → Opportunity Lost Reason Detail), `order_lost_reason` (free text), `items` (Table → Opportunity Item), `notes` (CRMNote table), UTM block, `first_response_time` (Duration).
- **Lifecycle:**
  - `validate` ([opportunity.py:131-143](../../erpnext/crm/doctype/opportunity/opportunity.py:131)) → `set_opportunity_type`, `make_new_lead_if_required`, `validate_item_details`, `validate_uom_is_integer`, `validate_cust_name`, `map_fields` (auto-fill from `opportunity_from` party), `set_exchange_rate`, `calculate_totals`.
  - `after_insert` ([opportunity.py:121-129](../../erpnext/crm/doctype/opportunity/opportunity.py:121)) → flip Lead status if `opportunity_from = "Lead"`; `link_open_tasks / link_open_events`; optional `copy_comments / link_communications` (gated by `CRM Settings.carry_forward_communication_and_comments`).
  - `on_update` → `update_prospect` (mirror or create `Prospect Opportunity`).
- **Whitelisted:** `set_multiple_status(names, status)`, `make_quotation`, `make_request_for_quotation`, `make_supplier_quotation`, `make_opportunity_from_communication(communication, company, …)` ([opportunity.py:530-554](../../erpnext/crm/doctype/opportunity/opportunity.py:530)), `add_note / edit_note / delete_note`.
- **Hook callbacks:** `auto_close_opportunity` (daily_maintenance) ([opportunity.py:508](../../erpnext/crm/doctype/opportunity/opportunity.py:508)).
- **Privacy:** Listed in `user_privacy_documents` ([hooks.py:628-633](../../erpnext/hooks.py:628)) — match field `contact_email`, scrubs `contact_mobile / contact_display / customer_name`.

## Opportunity Item

- **File:** [erpnext/crm/doctype/opportunity_item/](../../erpnext/crm/doctype/opportunity_item/).
- **Parent:** `Opportunity.items`.
- **Key fields:** `item_code`, `item_name`, `qty`, `uom`, `rate` / `amount` / `base_rate` / `base_amount`, `description`. Computed by [Opportunity.calculate_totals](../../erpnext/crm/doctype/opportunity/opportunity.py:170-180).

## Opportunity Type

- **File:** [erpnext/crm/doctype/opportunity_type/](../../erpnext/crm/doctype/opportunity_type/).
- **Purpose:** Flat master. Default value `Sales` written by `Opportunity.set_opportunity_type` on insert.

## Opportunity Lost Reason

- **File:** [erpnext/crm/doctype/opportunity_lost_reason/](../../erpnext/crm/doctype/opportunity_lost_reason/).
- **Purpose:** Flat master. Referenced by `Opportunity Lost Reason Detail.lost_reason` and by Quotation lost-reason flow.

## Lost Reason Detail

- **File:** [erpnext/crm/doctype/lost_reason_detail/](../../erpnext/crm/doctype/lost_reason_detail/).
- **Parent:** `Quotation.lost_reasons` (TableMultiSelect).
- **Purpose:** Per-quotation reason rows; multi-select wrapping of `Opportunity Lost Reason`.

## Opportunity Lost Reason Detail

- **File:** [erpnext/crm/doctype/opportunity_lost_reason_detail/](../../erpnext/crm/doctype/opportunity_lost_reason_detail/).
- **Parent:** `Opportunity.lost_reasons` (TableMultiSelect).

## Prospect

- **File:** [erpnext/crm/doctype/prospect/prospect.py](../../erpnext/crm/doctype/prospect/prospect.py).
- **Class:** [Prospect(CRMNote)](../../erpnext/crm/doctype/prospect/prospect.py:15) — extends the CRMNote mixin (which extends Document).
- **Submittable:** No.
- **Key fields:** `company_name` (Data), `company` (Link → Company, required), `industry`, `market_segment`, `customer_group`, `territory`, `prospect_owner`, `website`, `fax`, `annual_revenue`, `no_of_employees`, `notes` (CRMNote table), and the two child aggregates `leads` (Table → Prospect Lead) and `opportunities` (Table → Prospect Opportunity).
- **Lifecycle:**
  - `after_insert` ([prospect.py:53-68](../../erpnext/crm/doctype/prospect/prospect.py:53)) — for each leads/opportunities row: optional `copy_comments` + `link_communications` (gated by `carry_forward_communication_and_comments`); always `link_open_events`.
  - `on_update` → `link_with_lead_contact_and_address` — propagates the Prospect link into every Address / Contact whose Dynamic Link points at any of the rolled-up Leads.
  - `on_trash` → `delete_contact_and_address`.
- **Whitelisted:**
  - `make_customer(source_name, target_doc)` — Prospect → Customer ([prospect.py:91-111](../../erpnext/crm/doctype/prospect/prospect.py:91)).
  - `make_opportunity(source_name, target_doc)` — Prospect → Opportunity, sets `opportunity_from = "Prospect"` ([prospect.py:115](../../erpnext/crm/doctype/prospect/prospect.py:115)).

## Prospect Lead / Prospect Opportunity (children)

- **Files:** [erpnext/crm/doctype/prospect_lead/](../../erpnext/crm/doctype/prospect_lead/) and [erpnext/crm/doctype/prospect_opportunity/](../../erpnext/crm/doctype/prospect_opportunity/).
- **Parents:** `Prospect.leads` and `Prospect.opportunities` respectively.
- **Maintained by:** [Lead.update_prospect](../../erpnext/crm/doctype/lead/lead.py:191) and [Opportunity.update_prospect](../../erpnext/crm/doctype/opportunity/opportunity.py:182). The reverse lookup `get_linked_prospect` ([utils.py:101-115](../../erpnext/crm/utils.py:101)) walks these tables.

## Email Campaign

- **File:** [erpnext/crm/doctype/email_campaign/email_campaign.py](../../erpnext/crm/doctype/email_campaign/email_campaign.py).
- **Class:** `EmailCampaign(Document)`.
- **Status options:** `Scheduled / In Progress / Completed / Unsubscribed` ([email_campaign.py:27](../../erpnext/crm/doctype/email_campaign/email_campaign.py:27)).
- **Key fields:** `campaign_name` (Link → Campaign, required), `email_campaign_for` (`Lead / Contact / Email Group`), `recipient` (DynamicLink), `sender` (Link → User), `start_date` (required), `end_date` (computed from start + max `send_after_days`).
- **Lifecycle:** `validate` → `set_date` (back-fills `end_date`, refuses past `start_date`), `validate_lead`, `validate_email_campaign_already_exists`, `update_status`.
- **Hook callbacks:** `send_email_to_leads_or_contacts` (daily_maintenance), `set_email_campaign_status` (daily_maintenance), `unsubscribe_recipient` (Email Unsubscribe `after_insert` hook).

## Campaign

- **File:** [erpnext/crm/doctype/campaign/](../../erpnext/crm/doctype/campaign/).
- **Purpose:** Reusable schedule template for `Email Campaign`. Holds the `campaign_schedules` child table (rows of (Email Template, send_after_days)). Naming honours `CRM Settings.campaign_naming_by`.

## Campaign Email Schedule

- **File:** [erpnext/crm/doctype/campaign_email_schedule/](../../erpnext/crm/doctype/campaign_email_schedule/).
- **Parent:** `Campaign.campaign_schedules`.
- **Fields:** `email_template` (Link → Email Template), `send_after_days` (Int).

## Competitor

- **File:** [erpnext/crm/doctype/competitor/](../../erpnext/crm/doctype/competitor/).
- **Purpose:** Master, link target for `Competitor Detail.competitor`.

## Competitor Detail

- **File:** [erpnext/crm/doctype/competitor_detail/](../../erpnext/crm/doctype/competitor_detail/).
- **Parent:** `Opportunity.competitors` (TableMultiSelect).

## Sales Stage

- **File:** [erpnext/crm/doctype/sales_stage/](../../erpnext/crm/doctype/sales_stage/).
- **Purpose:** Master, link target for `Opportunity.sales_stage`.

## Market Segment

- **File:** [erpnext/crm/doctype/market_segment/](../../erpnext/crm/doctype/market_segment/).
- **Purpose:** Master, link target for `Lead.market_segment`, `Opportunity.market_segment`, `Prospect.market_segment`.

## CRM Note

- **File:** [erpnext/crm/doctype/crm_note/](../../erpnext/crm/doctype/crm_note/).
- **Parent:** `Lead.notes`, `Opportunity.notes`, `Prospect.notes`.
- **Class mixin:** [CRMNote(Document)](../../erpnext/crm/utils.py:243-263) — exposes whitelisted `add_note / edit_note / delete_note` and dispatches `notify_mentions` on add. Inherited by Lead, Opportunity, and Prospect.

## CRM Settings (Single)

- **File:** [erpnext/crm/doctype/crm_settings/crm_settings.json](../../erpnext/crm/doctype/crm_settings/crm_settings.json).
- **Single:** Yes. Owned by System Manager / Sales Manager / Sales Master Manager.
- **Knobs:** `campaign_naming_by`, `allow_lead_duplication_based_on_emails` (default 0), `auto_creation_of_contact` (default 1), `close_opportunity_after_days` (default 15), `default_valid_till` (default Quotation validity days), `carry_forward_communication_and_comments` (default 0), `update_timestamp_on_new_communication` (default 0). See the table in [crm.md](crm.md#crm-settings-the-module-wide-knob-set).

## Appointment

- **File:** [erpnext/crm/doctype/appointment/appointment.py](../../erpnext/crm/doctype/appointment/appointment.py).
- **Class:** `Appointment(Document)`.
- **Status options:** `Open / Unverified / Closed`.
- **Key fields:** `scheduled_time` (Datetime, required), `customer_name` (required), `customer_email` (required), `customer_phone_number`, `customer_skype`, `customer_details`, `appointment_with` (`Lead / Customer`), `party` (DynamicLink), `calendar_event` (Link → Event).
- **Lifecycle:**
  - `before_insert` ([appointment.py:53-70](../../erpnext/crm/doctype/appointment/appointment.py:53)) — refuses if `Appointment Booking Settings.number_of_agents` quota for that slot is exhausted; auto-resolves `party` from existing Customer or Lead by email match.
  - `after_insert` ([appointment.py:72-81](../../erpnext/crm/doctype/appointment/appointment.py:72)) — for verified `party`: `auto_assign` + `create_calendar_event`; otherwise `status = "Unverified"` + `send_confirmation_email`.
  - `on_change` → keep linked `Event.starts_on` in sync with `scheduled_time`.
- **Verify flow:** `set_verified(email)` checks the signed verify URL, calls `create_lead_and_link` (Lead `lead_name + email_id + phone + notes`), then `auto_assign + create_calendar_event`.
- **Auto-assign:** `auto_assign` ([appointment.py:155-168](../../erpnext/crm/doctype/appointment/appointment.py:155)) prefers the assignee of the latest Opportunity for the party; otherwise picks the agent with the lowest workload from `Appointment Booking Settings.agent_list`.

## Appointment Booking Settings (Single)

- **File:** [erpnext/crm/doctype/appointment_booking_settings/](../../erpnext/crm/doctype/appointment_booking_settings/).
- **Single:** Yes.
- **Key fields:** `number_of_agents`, `email_reminders`, `agent_list` (child table), `availability_of_slots` (Table → Availability Of Slots), `appointment_booking_slots` (Table → Appointment Booking Slots).
- **Consumers:** `Appointment.before_insert`, `Appointment.create_calendar_event`, the `/book_appointment` portal page.

## Appointment Booking Slots

- **File:** [erpnext/crm/doctype/appointment_booking_slots/](../../erpnext/crm/doctype/appointment_booking_slots/).
- **Parent:** `Appointment Booking Settings.appointment_booking_slots`.

## Availability Of Slots

- **File:** [erpnext/crm/doctype/availability_of_slots/](../../erpnext/crm/doctype/availability_of_slots/).
- **Parent:** `Appointment Booking Settings.availability_of_slots`.

## Contract

- **File:** [erpnext/crm/doctype/contract/contract.py](../../erpnext/crm/doctype/contract/contract.py).
- **Class:** [Contract(Document)](../../erpnext/crm/doctype/contract/contract.py:11). Submittable.
- **Key fields:** `party_type` (`Customer / Supplier / Employee`), `party_name` (DynamicLink), `party_full_name`, `party_user`, `document_type` (`Quotation / Project / Sales Order / Purchase Order / Sales Invoice / Purchase Invoice`), `document_name` (DynamicLink), `start_date`, `end_date`, `is_signed`, `signed_by_company` (User, stamped on submit), `signed_on`, `signee`, `ip_address`, `contract_template`, `contract_terms` (TextEditor), `requires_fulfilment`, `fulfilment_deadline`, `fulfilment_terms` (Table → Contract Fulfilment Checklist), `fulfilment_status` (`N/A / Unfulfilled / Partially Fulfilled / Fulfilled / Lapsed`).
- **Status options:** `Unsigned / Active / Inactive / Cancelled`.
- **Lifecycle:**
  - `validate` → `set_missing_values`, `validate_dates`, `update_contract_status`, `update_fulfilment_status`.
  - `before_submit` → stamp `signed_by_company = frappe.session.user`.
  - `on_discard` → `db_set("status", "Cancelled")`.
  - `before_update_after_submit` → recompute status + fulfilment.
- **Hook callbacks:** `update_status_for_contracts` (daily_maintenance) — see [contract.py:129](../../erpnext/crm/doctype/contract/contract.py:129).

## Contract Fulfilment Checklist

- **File:** [erpnext/crm/doctype/contract_fulfilment_checklist/](../../erpnext/crm/doctype/contract_fulfilment_checklist/).
- **Parent:** `Contract.fulfilment_terms`.
- **Fields:** `requirement`, `fulfilled` (Check). Drives `Contract.get_fulfilment_progress` and the fulfilment-status state machine.

## Contract Template

- **File:** [erpnext/crm/doctype/contract_template/](../../erpnext/crm/doctype/contract_template/).
- **Purpose:** Reusable Contract template — supplies `contract_terms` plus a list of `Contract Template Fulfilment Terms`.

## Contract Template Fulfilment Terms

- **File:** [erpnext/crm/doctype/contract_template_fulfilment_terms/](../../erpnext/crm/doctype/contract_template_fulfilment_terms/).
- **Parent:** `Contract Template.fulfilment_terms`.

## Related

- [CRM module overview](crm.md)
- [Selling flow](../flows/selling-flow.md)
- [Selling DocTypes](selling-doctypes.md) — Quotation / Sales Order / Customer.
- [Support DocTypes](support-doctypes.md) — Issue.lead reverse FK.
- [Hooks catalogue](../architecture/hooks-catalogue.md)

## Changelog

- `2026-04-18` — initial version. Reference cards for Lead, Lead Source, Opportunity + 5 children/lost-reason DocTypes, Prospect + 2 child tables, Email Campaign + Campaign + Campaign Email Schedule, Competitor + Competitor Detail, Sales Stage, Market Segment, CRM Note, CRM Settings (Single), Appointment + 3 booking-settings DocTypes, Contract + 3 fulfilment DocTypes.
