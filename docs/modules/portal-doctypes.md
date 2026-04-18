---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: portal
status: complete
related_docs:
  - modules/portal.md
  - flows/customer-portal-flow.md
---

# Portal — DocType reference cards

> **TL;DR:** The `Portal` module ships only **two** DocTypes, both child tables (`istable=1`) used by Products Settings on the storefront filter UI. Both are plain `Document` subclasses with no methods — pure schema. The user-visible portal-management surface (Portal Settings, Web Form, Communication, default-role gating) lives in Frappe core; the per-Customer/Supplier `Portal User` row lives in [utilities-doctypes.md](utilities-doctypes.md).

## Module summary

| DocType | File | istable | Purpose |
|---------|------|---------|---------|
| Website Attribute | [erpnext/portal/doctype/website_attribute/](../../erpnext/portal/doctype/website_attribute/) | 1 | Item Attribute facet for storefront filtering |
| Website Filter Field | [erpnext/portal/doctype/website_filter_field/](../../erpnext/portal/doctype/website_filter_field/) | 1 | Item field facet for storefront filtering |

## Website Attribute

- **File:** [erpnext/portal/doctype/website_attribute/website_attribute.py](../../erpnext/portal/doctype/website_attribute/website_attribute.py:1) (24 lines, plain `Document`).
- **Schema:** [erpnext/portal/doctype/website_attribute/website_attribute.json](../../erpnext/portal/doctype/website_attribute/website_attribute.json:1).
- **Fields (auto-generated types at [website_attribute.py:9-21](../../erpnext/portal/doctype/website_attribute/website_attribute.py:9)):**
  - `attribute` — `DF.Link` to Item Attribute. Required.
  - `parent`, `parentfield`, `parenttype` — standard child-table linkage.
- **Lifecycle hooks:** none beyond `Document` base.
- **Consumers:** Products Settings child table (`filter_attributes` field); the storefront filter sidebar reads this list to render attribute facets (e.g. "Color", "Size").
- **Cross-references in `hooks.py`:** none directly.

## Website Filter Field

- **File:** [erpnext/portal/doctype/website_filter_field/website_filter_field.py](../../erpnext/portal/doctype/website_filter_field/website_filter_field.py:1) (24 lines, plain `Document`).
- **Schema:** [erpnext/portal/doctype/website_filter_field/website_filter_field.json](../../erpnext/portal/doctype/website_filter_field/website_filter_field.json:1).
- **Fields (auto-generated types at [website_filter_field.py:9-21](../../erpnext/portal/doctype/website_filter_field/website_filter_field.py:9)):**
  - `fieldname` — `DF.Autocomplete` (autocompletes from Item DocType field list). Optional.
  - `parent`, `parentfield`, `parenttype` — standard child-table linkage.
- **Lifecycle hooks:** none beyond `Document` base.
- **Consumers:** Products Settings child table (`filter_fields` field); selects which Item fields participate as facetable filters in the storefront.
- **Cross-references in `hooks.py`:** none directly.

## Related

- [Portal module overview](portal.md)
- [Customer-portal flow](../flows/customer-portal-flow.md)
- [Utilities DocTypes](utilities-doctypes.md) — `Portal User` (Customer/Supplier child table) lives in `utilities/`, not here.

## Changelog

- `2026-04-18` — initial version. Cards for Website Attribute, Website Filter Field. Both are plain `Document` child tables with no methods.
