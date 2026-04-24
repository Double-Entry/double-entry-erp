---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: edi
status: complete
related_docs:
  - modules/edi.md
---

# EDI — DocType reference cards

> **TL;DR:** Two DocTypes. `Code List` is the parent vocabulary; `Common Code` is the per-code record with Dynamic Link references to arbitrary documents. Both ship a `from_genericode` extractor and the module-level `import_genericode` consumer that drives the list-view import button.

## Module summary

| DocType | File | Hooks |
|---------|------|-------|
| Code List | [erpnext/edi/doctype/code_list/](../../erpnext/edi/doctype/code_list/) | `on_trash` |
| Common Code | [erpnext/edi/doctype/common_code/](../../erpnext/edi/doctype/common_code/) | `validate` + `on_doctype_update` (DDL) |

## Code List

- **File:** [erpnext/edi/doctype/code_list/code_list.py](../../erpnext/edi/doctype/code_list/code_list.py:1) (129 lines).
- **Schema:** [erpnext/edi/doctype/code_list/code_list.json](../../erpnext/edi/doctype/code_list/code_list.json:1).
- **Fields (auto-generated types at [code_list.py:18-31](../../erpnext/edi/doctype/code_list/code_list.py:18)):**
  - `title` — `DF.Data | None`.
  - `version` — `DF.Data | None`.
  - `canonical_uri` — `DF.Data | None`.
  - `description` — `DF.SmallText | None`.
  - `publisher` — `DF.Data | None`.
  - `publisher_id` — `DF.Data | None`.
  - `url` — `DF.Data | None`.
  - `default_common_code` — `DF.Link | None` (to `Common Code`).
- **Lifecycle:**
  - `on_trash` ([line 33](../../erpnext/edi/doctype/code_list/code_list.py:33)) — cascade-deletes all `Common Code` rows of this list (skipped if `frappe.flags.in_bulk_delete`).
- **Methods:**
  - `get_codes_for(doctype, name)` ([line 49](../../erpnext/edi/doctype/code_list/code_list.py:49)).
  - `get_docnames_for(doctype, code)` ([line 53](../../erpnext/edi/doctype/code_list/code_list.py:53)).
  - `get_default_code()` ([line 57](../../erpnext/edi/doctype/code_list/code_list.py:57)).
  - `from_genericode(root)` ([line 65](../../erpnext/edi/doctype/code_list/code_list.py:65)) — populates list-level metadata from a genericode XML root.
- **Module-level helpers:** `get_codes_for(code_list, doctype, name)`, `get_docnames_for(code_list, doctype, code)`, `get_default_code(code_list)` ([code_list.py:81-128](../../erpnext/edi/doctype/code_list/code_list.py:81)).
- **Cross-references in `hooks.py`:**
  - [hooks.py:46-48](../../erpnext/hooks.py:46) — `doctype_list_js["Code List"]`.

## Common Code

- **File:** [erpnext/edi/doctype/common_code/common_code.py](../../erpnext/edi/doctype/common_code/common_code.py:1) (118 lines).
- **Schema:** [erpnext/edi/doctype/common_code/common_code.json](../../erpnext/edi/doctype/common_code/common_code.json:1).
- **Fields (auto-generated types at [common_code.py:19-32](../../erpnext/edi/doctype/common_code/common_code.py:19)):**
  - `code_list` — `DF.Link` to `Code List`. Required.
  - `common_code` — `DF.Data`. Required.
  - `title` — `DF.Data`. Required.
  - `description` — `DF.SmallText | None`.
  - `canonical_uri` — `DF.Data | None`.
  - `additional_data` — `DF.Code | None` (raw XML element, pretty-printed).
  - `applies_to` — `DF.Table[DynamicLink]`.
- **Lifecycle:**
  - `validate` ([line 34](../../erpnext/edi/doctype/common_code/common_code.py:34)) → `validate_distinct_references` ([line 37](../../erpnext/edi/doctype/common_code/common_code.py:37)) — refuses two Common Codes of the same Code List linking to the same `(link_doctype, link_name)`.
- **Methods:**
  - `from_genericode(column_map, xml_element)` ([line 61](../../erpnext/edi/doctype/common_code/common_code.py:61)) — extracts `common_code`, `title`, `description` from XML.
- **Module-level helpers:**
  - `import_genericode(code_list, file_name, column_map, filters=None)` ([line 89](../../erpnext/edi/doctype/common_code/common_code.py:89)) — bulk import driver.
  - `simple_hash(input_string, length=6)` ([line 85](../../erpnext/edi/doctype/common_code/common_code.py:85)).
  - `on_doctype_update()` ([line 116](../../erpnext/edi/doctype/common_code/common_code.py:116)) — adds composite DB index on `(code_list, common_code)`.
- **Cross-references in `hooks.py`:**
  - [hooks.py:49-51](../../erpnext/hooks.py:49) — `doctype_list_js["Common Code"]`.

## Related

- [EDI module](edi.md)

## Changelog

- `2026-04-18` — initial version. Cards for Code List (with cascade `on_trash`) and Common Code (with `validate_distinct_references` and DDL index).
