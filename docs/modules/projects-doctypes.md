---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: projects
status: complete
related_docs:
  - docs/modules/projects.md
---

# Projects — DocType reference cards

> **TL;DR:** Fifteen DocTypes — one aggregator (`Project`), one NestedSet (`Task`), one submittable workflow doc (`Timesheet`), templates (`Project Template`), masters (`Project Type`, `Activity Type`, `Activity Cost`, `Task Type`), one Single (`Projects Settings`), one snapshot (`Project Update`), and four child tables. See [projects.md](projects.md) for the module-level narrative.

## Project

- **File:** [erpnext/projects/doctype/project/project.py](../../erpnext/projects/doctype/project/project.py).
- **Class:** [Project](../../erpnext/projects/doctype/project/project.py:20) extends `Document`.
- **Submittable:** No.
- **Naming:** `naming_series` `PROJ-.####` ([project.py:52](../../erpnext/projects/doctype/project/project.py:52)).
- **Status options:** `Open / Completed / Cancelled` ([project.py:63](../../erpnext/projects/doctype/project/project.py:63)).
- **Key fields:** `project_name` (required), `project_template` (Link → Project Template), `project_type` (Link → Project Type), `customer`, `sales_order`, `cost_center`, `department`, `holiday_list`, `expected_start_date` / `expected_end_date` / `actual_start_date` / `actual_end_date`, `is_active` (Yes/No), `priority` (Low/Medium/High), `percent_complete_method` (Manual / Task Completion / Task Progress / Task Weight), `percent_complete`, `collect_progress`, `frequency` (Hourly / Twice Daily / Daily / Weekly), and the cost roll-up triple `total_costing_amount` + `total_billable_amount` + `total_billed_amount` + `total_purchase_cost` + `total_sales_amount` + `gross_margin` + `per_gross_margin`.
- **Lifecycle:**
  - `validate` → `copy_from_template` (only on resave) + `send_welcome_email` + `update_costing` + `update_percent_complete` + dual `validate_from_to_dates` ([project.py:92-99](../../erpnext/projects/doctype/project/project.py:92)).
  - `after_insert` → `copy_from_template` again + back-link `Sales Order.project = self.name` if `sales_order` set ([project.py:203-206](../../erpnext/projects/doctype/project/project.py:203)).
  - `on_trash` → clears `Sales Order.project` FK ([project.py:208-209](../../erpnext/projects/doctype/project/project.py:208)).
  - `after_rename` → propagates `copied_from` self-reference ([project.py:353-355](../../erpnext/projects/doctype/project/project.py:353)).
- **Whitelisted:**
  - `get_users_for_project(doctype, txt, searchfield, start, page_len, filters)` — User picker for Project User child rows.
  - `get_cost_center_name(project)` — utility for client scripts.
  - `create_kanban_board_if_not_exists(project)` — auto-create Kanban view of Tasks.
  - `set_project_status(project, status)` — bulk-flips Project + all child Tasks to `Completed` / `Cancelled`.
  - `create_duplicate_project(prev_doc, project_name)` — clone Project + all Tasks.
  - `update_costing_and_billing(project)` — refresh totals from outside.
- **Hook callbacks:**
  - `hourly_reminder` (hourly).
  - `collect_project_status` (hourly_maintenance).
  - `project_status_update_reminder` (hourly_maintenance) → fans out daily / twice-daily / weekly.
  - `update_project_sales_billing` (daily_maintenance).
  - `send_project_status_email_to_users` (daily_maintenance).
- **Cross-links:** `Sales Order` (1:1 reverse FK), `Sales Invoice`, `Purchase Invoice Item`, `Customer`, `Cost Center`, `Department`, `Holiday List`. Listed in `global_search_doctypes` ([hooks.py:665](../../erpnext/hooks.py:665)).

## Project Type

- **File:** [erpnext/projects/doctype/project_type/](../../erpnext/projects/doctype/project_type/).
- **Purpose:** Flat master, link target for `Project.project_type` and `Project Template.project_type`.

## Project Update

- **File:** [erpnext/projects/doctype/project_update/](../../erpnext/projects/doctype/project_update/).
- **Purpose:** Snapshot DocType created automatically by `send_project_update_email_to_users`. Holds `project`, `date`, `time`, `sent` (Check), `naming_series` `UPDATE-.project.-.YY.MM.DD.-.####`, and a `users` child table populated by `collect_project_status` from inbound Communication replies.
- **Lifecycle:** Created from scheduler ticks; updated by Communication polling.

## Project Template

- **File:** [erpnext/projects/doctype/project_template/project_template.py](../../erpnext/projects/doctype/project_template/project_template.py).
- **Class:** [ProjectTemplate](../../erpnext/projects/doctype/project_template/project_template.py:11) extends `Document`.
- **Key fields:** `project_type` (Link → Project Type), `disabled` (Check), `tasks` (Table → Project Template Task).
- **Validate** ([project_template.py:32-44](../../erpnext/projects/doctype/project_template/project_template.py:32)): every Task referenced in the template must include all of its `Task Depends On` parents, otherwise a throw with a `bold(get_link_to_form)` message.

## Project Template Task

- **File:** [erpnext/projects/doctype/project_template_task/](../../erpnext/projects/doctype/project_template_task/).
- **Parent:** `Project Template.tasks`.
- **Purpose:** References a `Task` that is `is_template=1`, plus a `start` (days offset from project expected_start_date) and `duration` (days). Used by [Project.create_task_from_template](../../erpnext/projects/doctype/project/project.py:127-143) to clone non-template Tasks per Project.

## Task

- **File:** [erpnext/projects/doctype/task/task.py](../../erpnext/projects/doctype/task/task.py).
- **Class:** [Task](../../erpnext/projects/doctype/task/task.py:25) extends `NestedSet` (`nsm_parent_field = "parent_task"`).
- **Submittable:** No (status-driven).
- **Status options:** `Open / Working / Pending Review / Overdue / Template / Completed / Cancelled` ([task.py:65-67](../../erpnext/projects/doctype/task/task.py:65)).
- **Key fields:** `subject` (required), `project`, `parent_task`, `is_group`, `is_template`, `is_milestone`, `priority` (Low/Medium/High/Urgent), `progress`, `task_weight`, `expected_time`, `actual_time`, `exp_start_date` / `exp_end_date` / `act_start_date` / `act_end_date`, `closing_date`, `review_date`, `completed_by`, `completed_on`, `template_task`, `issue` (Link → Issue), `depends_on` (Table → Task Depends On), plus NestedSet `lft` / `rgt`.
- **Custom errors:** `CircularReferenceError` (depends_on cycle), `ParentIsGroupError` (parent_task must be a group).
- **Lifecycle:**
  - `validate` → `validate_dates`, `validate_progress`, `validate_status` (rejects Completed if dependant tasks not Completed/Cancelled), `update_depends_on`, `validate_dependencies_for_template_task`, `validate_completed_on`, `set_default_end_date_if_missing`, `validate_parent_is_group` ([task.py:84-92](../../erpnext/projects/doctype/task/task.py:84)).
  - `on_update` → `update_nsm_model`, `check_recursion`, `reschedule_dependent_tasks`, `update_project`, `unassign_todo`, `populate_depends_on` ([task.py:209-215](../../erpnext/projects/doctype/task/task.py:209)).
  - `on_trash` → refuse if a child Task references this as `parent_task`.
  - `after_delete` → `update_project`.
- **Whitelisted:**
  - `check_if_child_exists(name)`.
  - `get_project(...)` — Project search picker for Task form.
  - `set_multiple_status(names, status)` — bulk status flip.
  - `make_timesheet(source_name, target_doc, ignore_permissions)` — mapper Task → Timesheet.
  - `get_children(...)`, `add_node(...)`, `add_multiple_tasks(...)` — tree-view helpers.
- **Hook callbacks:** `set_tasks_as_overdue` (daily_maintenance).
- **Indexing:** `on_doctype_update` adds index on `(lft, rgt)` ([task.py:474-475](../../erpnext/projects/doctype/task/task.py:474)).
- **Calendar:** Listed in `calendars` ([hooks.py:111](../../erpnext/hooks.py:111)).

## Task Type

- **File:** [erpnext/projects/doctype/task_type/](../../erpnext/projects/doctype/task_type/).
- **Purpose:** Flat master, link target for `Task.type`.

## Task Depends On

- **File:** [erpnext/projects/doctype/task_depends_on/](../../erpnext/projects/doctype/task_depends_on/).
- **Parent:** `Task.depends_on`.
- **Fields:** `task` (Link → Task), `project`, `subject`. Drives `Task.reschedule_dependent_tasks` cascading and `Task.validate_status` completion gating.

## Dependent Task

- **File:** [erpnext/projects/doctype/dependent_task/](../../erpnext/projects/doctype/dependent_task/).
- **Purpose:** Child table used inside `Project Template Task` to record template-time dependency edges. Distinct from `Task Depends On` (which is the runtime version).

## Timesheet

- **File:** [erpnext/projects/doctype/timesheet/timesheet.py](../../erpnext/projects/doctype/timesheet/timesheet.py).
- **Class:** [Timesheet](../../erpnext/projects/doctype/timesheet/timesheet.py:25) extends `Document`. Submittable.
- **Naming:** `naming_series` `TS-.YYYY.-` ([timesheet.py:48](../../erpnext/projects/doctype/timesheet/timesheet.py:48)).
- **Status options:** `Draft / Submitted / Partially Billed / Billed / Payslip / Completed / Cancelled` ([timesheet.py:54-56](../../erpnext/projects/doctype/timesheet/timesheet.py:54)).
- **Key fields:** `employee`, `user`, `customer`, `parent_project` (Link → Project), `company`, `currency`, `exchange_rate`, `start_date` / `end_date`, `note`, `time_logs` (Table → Timesheet Detail), `sales_invoice` (back-link), and the totals: `total_hours`, `total_billable_hours`, `total_billed_hours`, `total_billable_amount`, `total_billed_amount`, `total_costing_amount`, plus `base_*` company-currency mirrors, `per_billed`.
- **Custom errors:** `OverlapError` (time-log overlap), `OverWorkLoggedError`.
- **Lifecycle:**
  - `validate` → `set_status`, `validate_dates`, `calculate_hours`, `validate_time_logs` (with overlap checks honouring `Projects Settings.ignore_*_time_overlap` flags), `update_cost`, `calculate_total_amounts`, `calculate_percentage_billed`, `set_dates` ([timesheet.py:68-76](../../erpnext/projects/doctype/timesheet/timesheet.py:68)).
  - `on_submit` / `on_cancel` → `update_task_and_project` (rolls hours and costs back to Task and Project).
  - `on_update_after_submit` → revalidates mandatory fields + repeats `update_task_and_project` (so `sales_invoice` stamping at line level reflows to status).
  - `on_discard` → `db_set("status", "Cancelled")`.
  - `before_cancel` → `set_status`.
- **Whitelisted (module-level):**
  - `make_sales_invoice(source_name, item_code, customer, currency)` — see [projects.md](projects.md#timesheet--sales-invoice-flow).
  - `get_activity_cost(employee, activity_type, currency)` — picks the most-specific rate (Activity Cost row > Activity Type default), with FX conversion for non-base currencies.
  - `get_events(start, end, filters)` — calendar feed.
- **`unlink_sales_invoice(sales_invoice)`** ([timesheet.py:293-297](../../erpnext/projects/doctype/timesheet/timesheet.py:293)) — clears `Timesheet Detail.sales_invoice` columns when the SI is cancelled.

## Timesheet Detail

- **File:** [erpnext/projects/doctype/timesheet_detail/timesheet_detail.json](../../erpnext/projects/doctype/timesheet_detail/timesheet_detail.json).
- **Parent:** `Timesheet.time_logs`.
- **Key fields:** `activity_type` (Link → Activity Type), `from_time` / `to_time` (Datetime), `hours`, `expected_hours`, `description`, `project` (Link → Project), `task` (Link → Task), `is_billable` (Check), `billing_hours`, `sales_invoice` (Link, back-stamped on SI submit), `billing_rate` / `billing_amount`, `costing_rate` / `costing_amount`, plus `base_*` company-currency mirrors. `permlevel=1` on rate/amount fields restricts who can override them.
- **Method:** `validate_dates`, `set_to_time`, `calculate_hours`, `update_billing_hours`, `validate_billing_hours` — all instance methods invoked from `Timesheet.validate`.

## Activity Type

- **File:** [erpnext/projects/doctype/activity_type/activity_type.json](../../erpnext/projects/doctype/activity_type/activity_type.json).
- **Naming:** `field:activity_type`. **Unique** ([activity_type.json:24](../../erpnext/projects/doctype/activity_type/activity_type.json:24)).
- **Key fields:** `activity_type` (Data, required, unique), `costing_rate` (Currency), `billing_rate` (Currency), `disabled`.
- **Permissions:** `System Manager` full; `Projects User` no delete; `Employee` read.
- **Consumed by:** `Timesheet Detail.activity_type`, `Activity Cost.activity_type`, `Task` template flows. `get_activity_cost` falls back here when no `Activity Cost` row matches the (employee, activity_type) tuple.

## Activity Cost

- **File:** [erpnext/projects/doctype/activity_cost/activity_cost.json](../../erpnext/projects/doctype/activity_cost/activity_cost.json).
- **Naming:** `PROJ-ACC-.#####`.
- **Key fields:** `activity_type` (Link, required), `employee` (Link → Employee), `employee_name` (read-only fetch), `department` (read-only fetch from `employee.department`), `billing_rate` (per hour), `costing_rate` (per hour), `title` (hidden no-copy).
- **Purpose:** Per-employee × activity-type rate override. Looked up first by `get_activity_cost` ([timesheet.py:471-493](../../erpnext/projects/doctype/timesheet/timesheet.py:471)); falls through to `Activity Type` if no match.
- **Permissions:** `Projects User` only.

## Project User (child)

- **File:** [erpnext/projects/doctype/project_user/](../../erpnext/projects/doctype/project_user/).
- **Parent:** `Project.users`.
- **Purpose:** Links Users to a Project for collaboration. Drives `send_welcome_email` ([project.py:357-372](../../erpnext/projects/doctype/project/project.py:357)) — first save with `welcome_email_sent=0` triggers the invitation email; the row is then updated to `welcome_email_sent=1`. Also gates `Task.has_webform_permission` ([task.py:296-301](../../erpnext/projects/doctype/task/task.py:296)).

## Projects Settings (Single)

- **File:** [erpnext/projects/doctype/projects_settings/projects_settings.json](../../erpnext/projects/doctype/projects_settings/projects_settings.json).
- **Single:** Yes ([projects_settings.json:47](../../erpnext/projects/doctype/projects_settings/projects_settings.json:47)).
- **Key fields:**
  - `ignore_workstation_time_overlap` (Check) — disables Workstation overlap check on Timesheet validate.
  - `ignore_user_time_overlap` (Check) — disables User overlap check.
  - `ignore_employee_time_overlap` (Check) — disables Employee overlap check.
  - `fetch_timesheet_in_sales_invoice` (Check) — when set, picking a Project on a Sales Invoice auto-pulls open billable Timesheets.

## Related

- [Projects module overview](projects.md)
- [Selling flow](../flows/selling-flow.md)
- [Selling DocTypes — Sales Invoice](selling-doctypes.md)
- [Support DocTypes — Issue.project](support-doctypes.md)

## Changelog

- `2026-04-18` — initial version. Reference cards for Project, Project Type, Project Update, Project Template + Project Template Task, Task + Task Type + Task Depends On + Dependent Task, Timesheet + Timesheet Detail, Activity Type + Activity Cost, Project User, Projects Settings (Single).
