---
last_updated: 2026-04-17
commit: fbe976fb3b
branch: feat/setting-claude
scope: modules/regional
status: complete
related_docs:
  - modules/regional.md
  - patterns/regional-overrides.md
  - patterns/patches.md
---

# Regional DocType reference cards

> **TL;DR:** Reference cards for DocTypes shipped under [erpnext/regional/doctype/](../../erpnext/regional/doctype) plus a condensed per-country list of non-regional DocTypes the localization owns. For the module overview and per-country setup details, see [modules/regional.md](./regional.md); for the dispatch mechanism, see [patterns/regional-overrides.md](../patterns/regional-overrides.md).

## Card format

Each card lists:
- **Key fields** — mandatory and linked fields from the `.json` schema (+ line reference for the full schema).
- **Controller** — `validate` / `autoname` / whitelisted methods on the Python class.
- **Consumers** — where in core the DocType is read or written.
- **Hooks** — relevant `doc_events` / `regional_overrides` / patches.
- **Country scope** — which company country activates the DocType (where applicable).

---

## Country-agnostic regional DocTypes

### Lower Deduction Certificate

- **File**: [regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py)
- **Schema**: [lower_deduction_certificate.json](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.json)
- **Module**: Regional
- **Naming rule**: `field:certificate_no` ([.json:3](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.json:3)) — `certificate_no` is unique.
- **Key fields**:
  - `certificate_no` (Data, reqd, unique) — the government-issued number.
  - `supplier` (Link→Supplier, reqd) — deductee.
  - `pan_no` (Data, reqd, `fetch_from=supplier.pan`, `fetch_if_empty=1`) — party PAN/TIN.
  - `tax_withholding_category` (Link→Tax Withholding Category, reqd).
  - `fiscal_year` (Link→Fiscal Year, reqd).
  - `company` (Link→Company, reqd).
  - `valid_from`, `valid_upto` (Date, reqd).
  - `rate` (Percent, reqd) — reduced withholding rate.
  - `certificate_limit` (Currency, reqd) — amount cap under the certificate.
- **Controller** ([lower_deduction_certificate.py:13](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py:13)):
  - `validate()` → `validate_dates()` + `validate_supplier_against_tax_category()`.
  - `validate_dates()` ([:38](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py:38)): throws if `valid_upto < valid_from`; asserts both dates fall inside the linked `fiscal_year`'s `year_start_date`/`year_end_date` via `get_fiscal_year`.
  - `validate_supplier_against_tax_category()` ([:50](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py:50)): blocks overlap — if another LDC exists for the same `(supplier, tax_withholding_category, company)` tuple and its date range overlaps this one, throws with a link to the clashing certificate.
  - `are_dates_overlapping()` ([:72](../../erpnext/regional/doctype/lower_deduction_certificate/lower_deduction_certificate.py:72)) — inclusive-range overlap helper.
- **Consumers**: Tax Withholding Category lookup paths in [tax_withholding_category.py](../../erpnext/accounts/doctype/tax_withholding_category/tax_withholding_category.py) use LDC records to reduce `tds_rate` within the certificate window up to `certificate_limit`.
- **Country scope**: none — historically Indian TDS, retained after India decoupling for other jurisdictions that use similar reduced-withholding certificates. No `company.country` guard in the controller.
- **Patches**:
  - [v12_0/add_permission_in_lower_deduction.py](../../erpnext/patches/v12_0/add_permission_in_lower_deduction.py).
  - [v13_0/update_category_in_ltds_certificate.py](../../erpnext/patches/v13_0/update_category_in_ltds_certificate.py) — rename/migration cleanup.

### Import Supplier Invoice

- **File**: [regional/doctype/import_supplier_invoice/import_supplier_invoice.py](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py)
- **Schema**: [import_supplier_invoice.json](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.json)
- **Module**: Regional
- **Autoname**: custom — `"Import Invoice on " + format_datetime(creation)` ([.py:42](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:42)).
- **Key fields**:
  - `company` (Link→Company, reqd).
  - `invoice_series` (Select, options: `ACC-PINV-.YYYY.-`, reqd) — naming series for created PIs.
  - `item_code` (Link→Item, reqd) — single catch-all Item Code (XML line items all map to this Item; descriptions are preserved per row but the Item link is shared).
  - `supplier_group` (Link→Supplier Group, reqd) — default for newly created Suppliers.
  - `tax_account` (Link→Account, reqd) — the Account used for every `taxes` row the parser emits. Must be `account_type=Tax` under this Company (enforced via JS set_query at [import_supplier_invoice.js:13](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.js:13)).
  - `default_buying_price_list` (Link→Price List, reqd).
  - `zip_file` (Attach) — ZIP containing FatturaPA XML files.
  - `import_invoices` (Button, `options=process_file_data`) — triggers the whitelisted method.
  - `status` (Data, read-only) — `Processing File Data` / `File Import Completed` / `Partially Completed - Check Error Log` / `Error`.
- **Controller** ([import_supplier_invoice.py:19](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:19)):
  - `validate()` ([:38](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:38)) — requires `Stock Settings.stock_uom` default.
  - `process_file_data()` ([:158](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:158), `@frappe.whitelist`) — sets status to `Processing File Data`, enqueues `import_xml_data` on the `long` queue (timeout 3600 s).
  - `import_xml_data()` ([:46](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:46)) — opens ZIP, loops files, calls `prepare_data_for_import` per file, maintains `file_count` + `purchase_invoices_count`, publishes realtime progress (`import_invoice_update`), writes final status.
  - `prepare_data_for_import(file_content, file_name, encoded_content)` ([:74](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:74)) — per-invoice dispatch: `get_supplier_details` → `create_supplier` → `create_address` → `prepare_items_for_invoice` → `get_taxes_from_file` → `get_payment_terms_from_file` → `create_purchase_invoice` → attach original XML as File.
  - `prepare_items_for_invoice` ([:113](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:113)) — parses `DettaglioLinee`; extracts `PrezzoUnitario` (rate), `PrezzoTotale` (line total, derives qty when total/rate ≠ 1), `UnitaMisura` (creates UOM on demand via [:422](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:422)), `AliquotaIVA` (tax_rate), `Descrizione` (item name/description); flips to return-invoice mode when rate and total are both negative; accumulates percent discounts into `total_discount`.
  - `publish(title, message, count, total)` ([:163](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:163)) — realtime bus.
- **Module-level helpers** (all in the same file):
  - `get_file_content` ([:171](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:171)) — UTF-8 with UTF-16 fallback.
  - `get_supplier_details` ([:186](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:186)) — `CedentePrestatore` → `tax_id` (IdPaese + IdCodice), `fiscal_code`, `fiscal_regime`, `supplier` name (Denominazione or Nome+Cognome), address + country.
  - `get_taxes_from_file` ([:215](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:215)) — `DatiRiepilogo` → one `Purchase Taxes and Charges` row per distinct VAT rate, `charge_type=Actual`.
  - `get_payment_terms_from_file` ([:237](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:237)) — `DettaglioPagamento` → Mode-of-Payment-code-decorated rows, IBAN, `due_date`, `payment_amount`.
  - `get_destination_code_from_file` ([:262](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:262)) — `DatiTrasmissione` → `CodiceDestinatario` (7-char recipient code mandatory on FatturaPA).
  - `create_supplier` ([:270](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:270)) — upsert by `tax_id` first, then by name; appends Contact if none.
  - `create_address` ([:315](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:315)) — `Billing` address, dedup by `(address_line1, pincode)`.
  - `create_purchase_invoice` ([:355](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:355)) — constructs a `Purchase Invoice` in draft with `disable_rounded_total=1`, applies grand-total-level discount when the XML carried line discounts, rewrites `payment_schedule` with parsed terms, sets `imported_grand_total = sum(payment_amount)`. Swallows exceptions: logs via `pi.log_error`, flips ISI status to `Error`, returns `None`.
  - `get_country` ([:414](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:414)) — throws if the XML Country code isn't in `tabCountry`.
  - `create_uom` ([:422](../../erpnext/regional/doctype/import_supplier_invoice/import_supplier_invoice.py:422)) — creates missing UOMs on the fly.
- **Consumers**: produces `Purchase Invoice` (draft). The resulting PIs are standalone — no link back to the ISI record beyond the attached XML File.
- **Country scope**: Italy — the XML schema is FatturaPA-specific. There is no `company.country` guard in the controller itself; the permission wiring and custom fields (`document_type`, `destination_code`, `imported_grand_total`) are installed only by Italy's [setup.py](../../erpnext/regional/italy/setup.py) and the v12 Italian permissions patch.
- **Hooks / patches**:
  - Permissions added by [italy/setup.py:479](../../erpnext/regional/italy/setup.py:479) via `add_permissions()`.
  - [v12_0/set_italian_import_supplier_invoice_permissions.py](../../erpnext/patches/v12_0/set_italian_import_supplier_invoice_permissions.py) re-runs permissions if any Italian Company exists.
- **Print format**: `Purchase eInvoice` ([regional/print_format/purchase_einvoice/](../../erpnext/regional/print_format/purchase_einvoice/)) — Jinja tables for supplier/cedente, customer/cessionario, items, taxes, payments, mirroring the FatturaPA UI layout.

### UAE VAT Settings

- **File**: [regional/doctype/uae_vat_settings/uae_vat_settings.py](../../erpnext/regional/doctype/uae_vat_settings/uae_vat_settings.py)
- **Schema**: [uae_vat_settings.json](../../erpnext/regional/doctype/uae_vat_settings/uae_vat_settings.json)
- **Module**: Regional
- **Autoname**: `field:company` ([.json:3](../../erpnext/regional/doctype/uae_vat_settings/uae_vat_settings.json:3)) — single per Company.
- **Key fields**:
  - `company` (Link→Company, reqd, unique).
  - `uae_vat_accounts` (Table→UAE VAT Account, reqd).
- **Controller**: empty — pure container ([.py:9](../../erpnext/regional/doctype/uae_vat_settings/uae_vat_settings.py:9)).
- **Consumers**:
  - `get_tax_accounts(company)` in [uae/utils.py:77](../../erpnext/regional/united_arab_emirates/utils.py:77) selects `UAE VAT Account` rows filtered by `parent == company`. Used by `update_grand_total_for_rcm` (PI validate) and `make_regional_gl_entries` (PI submit GL).
  - `UAE VAT 201` report: per-Emirate standard-rated split and reverse-charge summary; reads the same account map.
- **Country scope**: UAE (and Saudi Arabia indirectly — but the RCM override only binds to UAE).
- **Permissions**: granted at `setup.py` time for Accounts Manager / Accounts User / System Manager via `add_permissions()` ([uae/setup.py:270](../../erpnext/regional/united_arab_emirates/setup.py:270)).

### UAE VAT Account

- **File**: [regional/doctype/uae_vat_account/uae_vat_account.py](../../erpnext/regional/doctype/uae_vat_account/uae_vat_account.py)
- **Schema**: [uae_vat_account.json](../../erpnext/regional/doctype/uae_vat_account/uae_vat_account.json)
- **Module**: Regional
- **Istable**: `1` ([.json:23](../../erpnext/regional/doctype/uae_vat_account/uae_vat_account.json:23)) — child of UAE VAT Settings.
- **Autoname**: `account` ([.json:3](../../erpnext/regional/doctype/uae_vat_account/uae_vat_account.json:3)) — row name is the Account link itself.
- **Key fields**:
  - `account` (Link→Account, `in_list_view`, `in_preview`).
- **Controller**: empty.
- **Consumers**: `get_tax_accounts(company)` — see [UAE VAT Settings](#uae-vat-settings).

### South Africa VAT Settings

- **File**: [regional/doctype/south_africa_vat_settings/south_africa_vat_settings.py](../../erpnext/regional/doctype/south_africa_vat_settings/south_africa_vat_settings.py)
- **Schema**: [south_africa_vat_settings.json](../../erpnext/regional/doctype/south_africa_vat_settings/south_africa_vat_settings.json)
- **Module**: Regional
- **Autoname**: `field:company` — single per Company.
- **Key fields**:
  - `company` (Link→Company, reqd, unique).
  - `vat_accounts` (Table→South Africa VAT Account, reqd).
- **Controller**: empty ([.py:8](../../erpnext/regional/doctype/south_africa_vat_settings/south_africa_vat_settings.py:8)).
- **Permissions**: baked in the DocType JSON for Accounts Manager / Accounts User / Auditor ([.json:37](../../erpnext/regional/doctype/south_africa_vat_settings/south_africa_vat_settings.json:37)) — not added dynamically via setup.
- **Consumers**:
  - `VAT Audit Report` ([report/vat_audit_report/vat_audit_report.py:46](../../erpnext/regional/report/vat_audit_report/vat_audit_report.py:46)) — `get_sa_vat_accounts` pulls `South Africa VAT Account` rows with `parent == company`.
- **Note**: the child DocType `South Africa VAT Account` is **not** under `regional/doctype/` — it ships at `erpnext/accounts/doctype/south_africa_vat_account/` (type-hinted in the controller at [south_africa_vat_settings.py:17](../../erpnext/regional/doctype/south_africa_vat_settings/south_africa_vat_settings.py:17)).

---

## Per-country DocType shipping summary

Condensed index. Fully documented in [modules/regional.md](./regional.md). DocTypes here are the **regional-module** DocTypes attributable to each country; custom fields attached via `make_custom_fields` are not DocTypes — see the country deep dives for custom field lists.

### United Arab Emirates

- `UAE VAT Settings` — see [card above](#uae-vat-settings).
- `UAE VAT Account` (child) — see [card above](#uae-vat-account).

### Italy

- `Import Supplier Invoice` — FatturaPA inbound, see [card above](#import-supplier-invoice).
- *(no dedicated outbound e-invoice DocType — Italy's outbound engine writes `File` rows against `Sales Invoice` instead of modelling e-invoices as a DocType; see [Italy flow](./regional.md#italy) in the main module doc.)*

### South Africa

- `South Africa VAT Settings` — see [card above](#south-africa-vat-settings).
- `South Africa VAT Account` (lives outside `regional/doctype/`, in [accounts/doctype/south_africa_vat_account/](../../erpnext/accounts/doctype/south_africa_vat_account/)).

### United States

- *(no DocTypes under `regional/doctype/` — US contributes only custom fields on existing DocTypes via [united_states/setup.py:19](../../erpnext/regional/united_states/setup.py:19).)*

### Australia / Turkey / Saudi Arabia / France / Nepal

- *(no DocTypes under `regional/doctype/` — see [modules/regional.md](./regional.md) for their non-DocType contributions.)*

## Related

- [modules/regional.md](./regional.md) — module overview, per-country deep dives, `regional_overrides` catalogue, flow diagrams.
- [patterns/regional-overrides.md](../patterns/regional-overrides.md) — `@erpnext.allow_regional` dispatch mechanism.
- [patterns/patches.md](../patterns/patches.md) — `patches.txt` manifest.
- [modules/accounts-doctypes.md](./accounts-doctypes.md) — Sales Invoice + Purchase Invoice cards (the host DocTypes that regional custom fields extend).

## Changelog

- `2026-04-17` — initial version.
