---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: bulk_transaction
status: complete
related_docs:
  - modules/bulk-transaction.md
---

# Bulk Transaction — DocType reference cards

> **TL;DR:** Two DocTypes. `Bulk Transaction Log` is a **virtual DocType** — it has no underlying table; reads aggregate `Bulk Transaction Log Detail` rows by date. `Bulk Transaction Log Detail` is the real per-row log with status, retry flag, error, and from/to doctype.

## Module summary

| DocType | File | istable | virtual | Purpose |
|---------|------|---------|---------|---------|
| Bulk Transaction Log | [erpnext/bulk_transaction/doctype/bulk_transaction_log/](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/) | 0 | **yes** | Per-date aggregate (succeeded / failed counts) |
| Bulk Transaction Log Detail | [erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/](../../erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/) | 0 | no | Real per-row log entry |

## Bulk Transaction Log

- **File:** [erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:1) (127 lines).
- **Schema:** [erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.json](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.json:1) — `is_virtual=1`, no own table.
- **Fields (auto-generated types at [bulk_transaction_log.py:13-25](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:13)):**
  - `date` — `DF.Date | None`.
  - `log_entries` — `DF.Int` (total rows).
  - `succeeded` — `DF.Int`.
  - `failed` — `DF.Int`.
- **Lifecycle (virtual contract):**
  - `db_insert` ([line 27](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:27)) — **no-op**.
  - `db_update` ([line 101](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:101)) — **no-op**.
  - `delete` ([line 104](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:104)) — **no-op**.
  - `load_from_db` ([lines 30-60](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:30)) — given `self.name` (a date), counts `Bulk Transaction Log Detail` rows by `transaction_status` for that date. Raises `frappe.DoesNotExistError` if no detail rows exist for the date.
  - `get_list` ([lines 62-91](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:62)) — `@staticmethod`. Returns distinct dates (most recent first, capped by `page_length` or 20) with per-date count. Honours an optional date filter parsed by `parse_list_filters` ([line 118](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:118)).
  - `get_count` ([line 93](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:93)) — **no-op**.
  - `get_stats` ([line 97](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:97)) — **no-op**.
- **Helper:** `serialize_transaction_log(data)` ([line 108](../../erpnext/bulk_transaction/doctype/bulk_transaction_log/bulk_transaction_log.py:108)) — `frappe._dict({name=date, date, log_entries=count, succeeded, failed})`.
- **Cross-references in `hooks.py`:** none directly.

## Bulk Transaction Log Detail

- **File:** [erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/bulk_transaction_log_detail.py](../../erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/bulk_transaction_log_detail.py:1) (28 lines, plain `Document`).
- **Schema:** [erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/bulk_transaction_log_detail.json](../../erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/bulk_transaction_log_detail.json:1).
- **Fields (auto-generated types at [bulk_transaction_log_detail.py:13-25](../../erpnext/bulk_transaction/doctype/bulk_transaction_log_detail/bulk_transaction_log_detail.py:13)):**
  - `transaction_name` — `DF.DynamicLink | None` (source doc name; doctype dynamic).
  - `from_doctype` — `DF.Link | None`.
  - `to_doctype` — `DF.Link | None`.
  - `transaction_status` — `DF.Data | None` (`"Success"` or `"Failed"`).
  - `date` — `DF.Date | None`.
  - `time` — `DF.Time | None`.
  - `error_description` — `DF.LongText | None` (full traceback when failed).
  - `retried` — `DF.Int` (`0` or `1`).
- **Lifecycle:** none beyond `Document`.
- **Producers:** `create_log` at [utilities/bulk_transaction.py:195-206](../../erpnext/utilities/bulk_transaction.py:195) (initial insert) and `update_log` at [utilities/bulk_transaction.py:95-99](../../erpnext/utilities/bulk_transaction.py:95) (retry-status update).
- **Consumers:**
  - `Bulk Transaction Log.load_from_db` / `.get_list` (the virtual aggregator).
  - `utilities.bulk_transaction.retry` ([utilities/bulk_transaction.py:57](../../erpnext/utilities/bulk_transaction.py:57)) — scans `transaction_status='Failed' AND retried=0`.

## Related

- [Bulk Transaction module](bulk-transaction.md)
- [Utilities module](utilities.md) — `bulk_transaction.py` engine.

## Changelog

- `2026-04-18` — initial version. Cards for Bulk Transaction Log (virtual) + Bulk Transaction Log Detail.
