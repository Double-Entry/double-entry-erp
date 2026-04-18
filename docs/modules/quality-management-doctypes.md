---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: quality_management
status: complete
related_docs:
  - docs/modules/quality-management.md
---

# Quality Management — DocType reference cards

> **TL;DR:** Sixteen DocTypes — seven primaries (Quality Goal, Quality Procedure, Quality Action, Quality Meeting, Quality Review, Non Conformance, Quality Feedback), one template (Quality Feedback Template), and eight child tables. All extend plain `Document` (or `NestedSet` for Quality Procedure). None are submittable. None produce GL/SLE rows. See [quality-management.md](quality-management.md) for the module-level narrative.

## Quality Goal

- **File:** [erpnext/quality_management/doctype/quality_goal/quality_goal.py](../../erpnext/quality_management/doctype/quality_goal/quality_goal.py).
- **Class:** [QualityGoal(Document)](../../erpnext/quality_management/doctype/quality_goal/quality_goal.py:8).
- **Submittable:** No.
- **Key fields:** `goal` (Data, primary descriptor), `procedure` (Link → Quality Procedure), `frequency` (`None / Daily / Weekly / Monthly / Quarterly`), `weekday` (`Monday`-`Saturday`, used when `frequency=Weekly`), `date` (`"1"`-`"30"`, used when `frequency=Monthly`), `objectives` (Table → Quality Goal Objective).
- **Lifecycle:** `validate` is a `pass` — schema-only. The frequency knob drives the daily `quality_review.review` scheduler ([quality_review.py:48-72](../../erpnext/quality_management/doctype/quality_review/quality_review.py:48)) which creates a Quality Review whenever today matches the goal's cadence.

## Quality Goal Objective

- **File:** [erpnext/quality_management/doctype/quality_goal_objective/](../../erpnext/quality_management/doctype/quality_goal_objective/).
- **Parent:** `Quality Goal.objectives`.
- **Fields:** `objective` (text), `target` (Data — target value), `uom` (Link → UOM). Auto-cloned into `Quality Review Objective` rows when a Review is created from the Goal ([quality_review.py:30-34](../../erpnext/quality_management/doctype/quality_review/quality_review.py:30)).

## Quality Procedure

- **File:** [erpnext/quality_management/doctype/quality_procedure/quality_procedure.py](../../erpnext/quality_management/doctype/quality_procedure/quality_procedure.py).
- **Class:** [QualityProcedure(NestedSet)](../../erpnext/quality_management/doctype/quality_procedure/quality_procedure.py:10) — `nsm_parent_field = "parent_quality_procedure"`. The only NestedSet in the module.
- **Submittable:** No.
- **Key fields:** `quality_procedure_name` (Data), `process_owner` (Link → User), `process_owner_full_name`, `parent_quality_procedure` (Link, NestedSet parent), `is_group` (Check, auto-set), `lft` / `rgt`, `processes` (Table → Quality Procedure Process).
- **Lifecycle:**
  - `before_save` → `check_for_incorrect_child` ([quality_procedure.py:59-73](../../erpnext/quality_management/doctype/quality_procedure/quality_procedure.py:59)) — auto-sets `is_group=1` when any process row references another procedure; refuses to nest a procedure that has a different parent.
  - `on_update` → `NestedSet.on_update` + four parent-child sync methods (`set_parent`, `remove_parent_from_old_child`, `add_child_to_parent`, `remove_child_from_old_parent`).
  - `after_insert` → `set_parent` + `add_child_to_parent`.
  - `on_trash` → wipe back-link from `Quality Procedure Process.procedure`, then `NestedSet.on_trash(allow_root_deletion=True)`.

## Quality Procedure Process

- **File:** [erpnext/quality_management/doctype/quality_procedure_process/](../../erpnext/quality_management/doctype/quality_procedure_process/).
- **Parent:** `Quality Procedure.processes`.
- **Fields:** `process_description`, `procedure` (Link → Quality Procedure — sub-procedure reference). When `procedure` is set, the parent is auto-flagged `is_group=1`.

## Quality Action

- **File:** [erpnext/quality_management/doctype/quality_action/quality_action.py](../../erpnext/quality_management/doctype/quality_action/quality_action.py).
- **Class:** [QualityAction(Document)](../../erpnext/quality_management/doctype/quality_action/quality_action.py:8).
- **Submittable:** No.
- **Key fields:** `corrective_preventive` (`Corrective / Preventive`), `date`, `feedback` (Link → Quality Feedback), `goal` (Link → Quality Goal), `procedure` (Link → Quality Procedure), `review` (Link → Quality Review), `status` (`Open / Completed`), `resolutions` (Table → Quality Action Resolution).
- **Lifecycle:** `validate` ([quality_action.py:31-32](../../erpnext/quality_management/doctype/quality_action/quality_action.py:31)) auto-derives parent status — any `resolutions[].status == "Open"` keeps the parent `Open`; otherwise `Completed`.

## Quality Action Resolution

- **File:** [erpnext/quality_management/doctype/quality_action_resolution/](../../erpnext/quality_management/doctype/quality_action_resolution/).
- **Parent:** `Quality Action.resolutions`.
- **Fields:** `problem`, `responsible`, `completion_by`, `status` (per-row Open/Completed). Drives the parent's auto-status rollup.

## Quality Meeting

- **File:** [erpnext/quality_management/doctype/quality_meeting/quality_meeting.py](../../erpnext/quality_management/doctype/quality_meeting/quality_meeting.py).
- **Class:** [QualityMeeting(Document)](../../erpnext/quality_management/doctype/quality_meeting/quality_meeting.py:8) — empty `pass` body.
- **Submittable:** No.
- **Key fields:** `agenda` (Table → Quality Meeting Agenda), `minutes` (Table → Quality Meeting Minutes), `status` (`Open / Closed`).

## Quality Meeting Agenda

- **File:** [erpnext/quality_management/doctype/quality_meeting_agenda/](../../erpnext/quality_management/doctype/quality_meeting_agenda/).
- **Parent:** `Quality Meeting.agenda`.
- **Fields:** Agenda item description + ordering.

## Quality Meeting Minutes

- **File:** [erpnext/quality_management/doctype/quality_meeting_minutes/](../../erpnext/quality_management/doctype/quality_meeting_minutes/).
- **Parent:** `Quality Meeting.minutes`.
- **Fields:** Minute item — captured note + responsible party.

## Quality Review

- **File:** [erpnext/quality_management/doctype/quality_review/quality_review.py](../../erpnext/quality_management/doctype/quality_review/quality_review.py).
- **Class:** [QualityReview(Document)](../../erpnext/quality_management/doctype/quality_review/quality_review.py:9).
- **Submittable:** No.
- **Key fields:** `goal` (Link → Quality Goal, required), `date`, `procedure` (Link → Quality Procedure), `additional_information`, `status` (`Open / Passed / Failed`), `reviews` (Table → Quality Review Objective).
- **Lifecycle:**
  - `validate` ([quality_review.py:30-36](../../erpnext/quality_management/doctype/quality_review/quality_review.py:30)) — if `reviews` is empty, copy from `Quality Goal.objectives` (objective + target + uom). Then `set_status`.
  - `set_status` ([quality_review.py:38-45](../../erpnext/quality_management/doctype/quality_review/quality_review.py:38)) — three-way state machine driven by child statuses (see [quality-management.md](quality-management.md#quality-goal--quality-review-the-daily-scheduler)).
- **Hook callbacks:** `review` (daily_maintenance) — module-level function, *not* an instance method.
- **Created automatically by:** [`quality_review.review()`](../../erpnext/quality_management/doctype/quality_review/quality_review.py:48) per Goal cadence.

## Quality Review Objective

- **File:** [erpnext/quality_management/doctype/quality_review_objective/](../../erpnext/quality_management/doctype/quality_review_objective/).
- **Parent:** `Quality Review.reviews`.
- **Fields:** `objective`, `target`, `actual`, `uom`, `status` (`Open / Passed / Failed`). Drives `Quality Review.set_status` rollup.

## Non Conformance

- **File:** [erpnext/quality_management/doctype/non_conformance/non_conformance.py](../../erpnext/quality_management/doctype/non_conformance/non_conformance.py).
- **Class:** [NonConformance(Document)](../../erpnext/quality_management/doctype/non_conformance/non_conformance.py:9) — empty `pass` body, schema-driven.
- **Submittable:** No.
- **Key fields:** `subject` (required), `procedure` (Link → Quality Procedure, required), `process_owner`, `full_name`, `details` (TextEditor), `corrective_action` (TextEditor), `preventive_action` (TextEditor), `status` (`Open / Resolved / Cancelled`).
- **Lifecycle:** No automation. Captured for audit trail and for downstream `Quality Action` creation.

## Quality Feedback

- **File:** [erpnext/quality_management/doctype/quality_feedback/quality_feedback.py](../../erpnext/quality_management/doctype/quality_feedback/quality_feedback.py).
- **Class:** [QualityFeedback(Document)](../../erpnext/quality_management/doctype/quality_feedback/quality_feedback.py:9).
- **Submittable:** No.
- **Key fields:** `template` (Link → Quality Feedback Template, required), `document_type` (`User / Customer`), `document_name` (DynamicLink), `parameters` (Table → Quality Feedback Parameter).
- **Lifecycle:** `validate` ([quality_feedback.py:34-38](../../erpnext/quality_management/doctype/quality_feedback/quality_feedback.py:34)) — defaults to self-rating (`document_type='User'`, `document_name=session.user`) if `document_name` empty; calls `set_parameters`.
- **Whitelisted:** `set_parameters()` ([quality_feedback.py:28-32](../../erpnext/quality_management/doctype/quality_feedback/quality_feedback.py:28)) — clones the template's parameters into local rows (default rating=1).

## Quality Feedback Parameter

- **File:** [erpnext/quality_management/doctype/quality_feedback_parameter/](../../erpnext/quality_management/doctype/quality_feedback_parameter/).
- **Parent:** `Quality Feedback.parameters`.
- **Fields:** `parameter` (Data), `rating` (Int 1-5).

## Quality Feedback Template

- **File:** [erpnext/quality_management/doctype/quality_feedback_template/quality_feedback_template.py](../../erpnext/quality_management/doctype/quality_feedback_template/quality_feedback_template.py).
- **Class:** [QualityFeedbackTemplate(Document)](../../erpnext/quality_management/doctype/quality_feedback_template/quality_feedback_template.py:9) — empty `pass` body.
- **Key fields:** `template` (Data), `parameters` (Table → Quality Feedback Template Parameter).

## Quality Feedback Template Parameter

- **File:** [erpnext/quality_management/doctype/quality_feedback_template_parameter/](../../erpnext/quality_management/doctype/quality_feedback_template_parameter/).
- **Parent:** `Quality Feedback Template.parameters`.
- **Fields:** `parameter` (Data) — the parameter label that will be cloned into each new `Quality Feedback`.

## Related

- [Quality Management module overview](quality-management.md)
- [Stock DocTypes — Quality Inspection](stock-doctypes.md) — the per-item runtime check (lives in Stock module).
- [Scheduler jobs](../architecture/scheduler-jobs.md)

## Changelog

- `2026-04-18` — initial version. Reference cards for Quality Goal + Quality Goal Objective, Quality Procedure (NestedSet) + Quality Procedure Process, Quality Action + Quality Action Resolution, Quality Meeting + Agenda + Minutes, Quality Review + Quality Review Objective, Non Conformance, Quality Feedback + Parameter, Quality Feedback Template + Parameter.
