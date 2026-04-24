---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: utilities
status: complete
related_docs:
  - modules/utilities.md
  - modules/portal.md
---

# Utilities — DocType reference cards

> **TL;DR:** The Utilities module ships **four** DocTypes: `Video`, `Video Settings`, `Rename Tool`, `Portal User`. Three are operational helpers (Video tracking, bulk rename); `Portal User` is the child table embedded on Customer / Supplier forms that links Website Users to a party. None of these doctypes are transactional and none post GL or SLE.

## Module summary

| DocType | File | Type | Hooks |
|---------|------|------|-------|
| Video | [erpnext/utilities/doctype/video/](../../erpnext/utilities/doctype/video/) | Single? No (regular) | `validate` (when tracking enabled) |
| Video Settings | [erpnext/utilities/doctype/video_settings/](../../erpnext/utilities/doctype/video_settings/) | Single | `validate` |
| Rename Tool | [erpnext/utilities/doctype/rename_tool/](../../erpnext/utilities/doctype/rename_tool/) | Single | none |
| Portal User | [erpnext/utilities/doctype/portal_user/](../../erpnext/utilities/doctype/portal_user/) | child (`istable=1`) | none |

## Video

- **File:** [erpnext/utilities/doctype/video/video.py](../../erpnext/utilities/doctype/video/video.py:1) (161 lines, plain `Document`).
- **Schema:** [erpnext/utilities/doctype/video/video.json](../../erpnext/utilities/doctype/video/video.json:1).
- **Fields (auto-generated types at [video.py:17-37](../../erpnext/utilities/doctype/video/video.py:17)):**
  - `title` — `DF.Data` (required).
  - `url` — `DF.Data`.
  - `provider` — `DF.Literal["YouTube", "Vimeo"]`.
  - `youtube_video_id` — `DF.Data | None`.
  - `publish_date` — `DF.Date | None`.
  - `description` — `DF.TextEditor`.
  - `image` — `DF.AttachImage | None`.
  - `duration` — `DF.Duration | None`.
  - `like_count` / `view_count` / `dislike_count` / `comment_count` — `DF.Float`.
- **Lifecycle:**
  - `validate` ([video.py:39-42](../../erpnext/utilities/doctype/video/video.py:39)) — only when provider is YouTube AND `Video Settings.enable_youtube_tracking` is on: extracts `youtube_video_id` from URL via `set_video_id`, then calls `set_youtube_statistics` to fetch stats from `pyyoutube` API.
- **Module-level helpers:**
  - `update_youtube_data()` ([video.py:78-95](../../erpnext/utilities/doctype/video/video.py:78)) — `hourly_maintenance` scheduler ([hooks.py:458](../../erpnext/hooks.py:458)). Reads `Video Settings.frequency` (`"30 mins" / "1 hr" / "6 hrs" / "Daily"`), runs the batch update only when current time is on the configured cadence (`site_time.hour % frequency == 0` and within the first 15 minutes of the hour). The 30-min cadence runs on every invocation.
  - `batch_update_youtube_data()` ([video.py:121-160](../../erpnext/utilities/doctype/video/video.py:121)) — paginated update in batches of 50 video IDs per API call.
  - `get_id_from_url(url)` ([video.py:107-118](../../erpnext/utilities/doctype/video/video.py:107)) — `@frappe.whitelist()`. Regex parses YouTube ID from any of `watch?v=`, `embed/`, or `youtu.be/` URLs.
- **Cross-references in `hooks.py`:**
  - [hooks.py:458](../../erpnext/hooks.py:458) — `hourly_maintenance: erpnext.utilities.doctype.video.video.update_youtube_data`.

## Video Settings

- **File:** [erpnext/utilities/doctype/video_settings/video_settings.py](../../erpnext/utilities/doctype/video_settings/video_settings.py:1) (35 lines, **Single** DocType).
- **Fields (auto-generated types at [video_settings.py:14-23](../../erpnext/utilities/doctype/video_settings/video_settings.py:14)):**
  - `enable_youtube_tracking` — `DF.Check`.
  - `api_key` — `DF.Data | None` (YouTube Data API v3 key).
  - `frequency` — `DF.Literal["30 mins", "1 hr", "6 hrs", "Daily"]`.
- **Lifecycle:**
  - `validate` ([video_settings.py:25-26](../../erpnext/utilities/doctype/video_settings/video_settings.py:25)) → `validate_youtube_api_key` ([line 28](../../erpnext/utilities/doctype/video_settings/video_settings.py:28)) — when tracking is enabled, calls `apiclient.discovery.build("youtube", "v3", developerKey=api_key)`; on any exception throws `Invalid Credentials`.

## Rename Tool

- **File:** [erpnext/utilities/doctype/rename_tool/rename_tool.py](../../erpnext/utilities/doctype/rename_tool/rename_tool.py:1) (58 lines, **Single** DocType).
- **Fields (auto-generated types at [rename_tool.py:17-24](../../erpnext/utilities/doctype/rename_tool/rename_tool.py:17)):**
  - `select_doctype` — `DF.Link | None` (DocType to rename within).
  - `file_to_rename` — `DF.Attach | None` (CSV upload).
- **Lifecycle:** none.
- **Module-level helpers:**
  - `get_doctypes()` ([rename_tool.py:29-35](../../erpnext/utilities/doctype/rename_tool/rename_tool.py:29)) — `@frappe.whitelist()` `@deprecated`. Returns names of DocTypes with `allow_rename=1` outside the Core module.
  - `upload(select_doctype=None)` ([rename_tool.py:38-57](../../erpnext/utilities/doctype/rename_tool/rename_tool.py:38)) — `@frappe.whitelist()`. Reads the attached CSV via `frappe.utils.csvutils.read_csv_content_from_attached_file`, then enqueues `frappe.model.rename_doc.bulk_rename` in 500-row chunks on the `long` queue. Permission gate: `frappe.has_permission(select_doctype, "write")`.

## Portal User

- **File:** [erpnext/utilities/doctype/portal_user/portal_user.py](../../erpnext/utilities/doctype/portal_user/portal_user.py:1) (24 lines, plain `Document`).
- **Schema:** [erpnext/utilities/doctype/portal_user/portal_user.json](../../erpnext/utilities/doctype/portal_user/portal_user.json:1) — `istable=1`.
- **Fields (auto-generated types at [portal_user.py:13-21](../../erpnext/utilities/doctype/portal_user/portal_user.py:13)):**
  - `user` — `DF.Link` to User. Required.
  - `parent`, `parentfield`, `parenttype` — child-table linkage.
- **Lifecycle:** none.
- **Consumers:** rendered as a child table on Customer and Supplier forms ("Portal Users" section). Lets a sales/purchase admin attach multiple Website Users to a single party — a many-to-one mirror of the Contact `links` table.

## Related

- [Utilities module](utilities.md) — explains the in-tree `bulk_transaction`, `activation`, `product`, `transaction_base` modules that have no DocType representation.
- [Portal module](portal.md) — `Portal User` complements the `on_session_creation` Customer/Supplier auto-provision.

## Changelog

- `2026-04-18` — initial version. Cards for Video, Video Settings, Rename Tool, Portal User.
