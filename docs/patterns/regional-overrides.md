---
last_updated: 2026-04-17
commit: fbe976fb3b
scope: patterns/regional
status: complete
related_docs:
  - architecture/hooks-and-overrides.md
  - architecture/controllers.md
---

# Regional overrides

> **TL;DR:** Country-specific behaviour is injected by marking a core function with `@erpnext.allow_regional` (it becomes a no-op or default in the generic case), then registering a replacement implementation in `regional_overrides` in [erpnext/hooks.py:608](../../erpnext/hooks.py:608). At call time the `allow_regional` decorator resolves the active company's country via `get_region()` and dispatches to the country's implementation in `erpnext/regional/<country>/utils.py`. Additional country wiring — `doc_events`, setup, custom fields — goes through the normal `hooks.py` machinery.

## The mechanism in three artefacts

1. The decorator — [erpnext/__init__.py:135](../../erpnext/__init__.py:135):
    ```python
    def allow_regional(fn):
        @functools.wraps(fn)
        def caller(*args, **kwargs):
            overrides = frappe.get_hooks("regional_overrides", {}).get(get_region())
            function_path = f"{inspect.getmodule(fn).__name__}.{fn.__name__}"
            if not overrides or function_path not in overrides:
                return fn(*args, **kwargs)
            # Priority given to last installed app
            return frappe.get_attr(overrides[function_path][-1])(*args, **kwargs)
        return caller
    ```

2. The region resolver — [erpnext/__init__.py:120](../../erpnext/__init__.py:120):
    ```python
    def get_region(company=None):
        if not company:
            company = frappe.local.flags.company
        if company:
            return frappe.get_cached_value("Company", company, "country")
        return frappe.flags.country or frappe.get_system_settings("country")
    ```

3. The registry — [erpnext/hooks.py:608](../../erpnext/hooks.py:608):
    ```python
    regional_overrides = {
        "France": {...},
        "United Arab Emirates": {
            "erpnext.controllers.taxes_and_totals.update_itemised_tax_data": "erpnext.regional.united_arab_emirates.utils.update_itemised_tax_data",
            "erpnext.accounts.doctype.purchase_invoice.purchase_invoice.make_regional_gl_entries": "erpnext.regional.united_arab_emirates.utils.make_regional_gl_entries",
        },
        "Saudi Arabia": {...},
        "Italy": {...},
    }
    ```

## Resolution flow

```mermaid
sequenceDiagram
  participant Caller
  participant Decorated as decorated fn<br/>(@erpnext.allow_regional)
  participant GetRegion as get_region()
  participant Hooks as frappe.get_hooks("regional_overrides")
  participant Replacement as erpnext/regional/&lt;country&gt;/utils.py

  Caller->>Decorated: call fn(doc)
  Decorated->>GetRegion: resolve country
  GetRegion-->>Decorated: "Italy"
  Decorated->>Hooks: overrides for "Italy"
  Hooks-->>Decorated: {function_path: replacement_path}
  alt override present
    Decorated->>Replacement: frappe.get_attr(last)(*args)
    Replacement-->>Caller: result
  else no override
    Decorated-->>Caller: fn(*args)
  end
```

Important details:
- **Company flag takes precedence** over the system-wide country, via `frappe.local.flags.company`. Set through `erpnext.utilities.regional.temporary_flag("company", self.company)` — see its usage in [erpnext/controllers/accounts_controller.py:301](../../erpnext/controllers/accounts_controller.py:301):
    ```python
    with temporary_flag("company", self.company):
        validate_regional(self)
        validate_einvoice_fields(self)
    ```
- **Last installed app wins**: `overrides[function_path][-1]` takes the last-registered replacement. If both ERPNext and a sibling app register an override for the same function under the same region, the sibling app's registration wins if it loads after ERPNext.
- **Key by dotted path**, not by function object. Module name + function name must exactly match.

## Directory layout per country

```
erpnext/regional/
  __init__.py
  address_template/          — non-Python address-format XML
  doctype/                   — shared regional DocTypes
  print_format/              — regional print formats
  report/                    — regional reports
  italy/
    __init__.py
    e-invoice.xml
    setup.py
    utils.py                 — regional function bodies referenced in regional_overrides
  united_arab_emirates/
    __init__.py
    setup.py
    utils.py
  united_states/
  australia/
  turkey/
  south_africa/
```

Listed from [erpnext/regional/](../../erpnext/regional). Not every country has an override registered; some only ship setup, print formats, or reports.

## Example: Italy

Registration at [erpnext/hooks.py:617](../../erpnext/hooks.py:617):
```python
"Italy": {
    "erpnext.controllers.taxes_and_totals.update_itemised_tax_data": "erpnext.regional.italy.utils.update_itemised_tax_data",
    "erpnext.controllers.accounts_controller.validate_regional": "erpnext.regional.italy.utils.sales_invoice_validate",
},
```

- Replacement body: `update_itemised_tax_data` at [erpnext/regional/italy/utils.py:14](../../erpnext/regional/italy/utils.py:14). Skips Purchase Invoice, recomputes `tax_rate` / `tax_amount` / `total_amount` from itemised tax.
- The core `validate_regional(doc)` stub: [erpnext/controllers/accounts_controller.py:4314](../../erpnext/controllers/accounts_controller.py:4314):
    ```python
    @erpnext.allow_regional
    def validate_regional(doc):
        pass
    ```
    For Italy this becomes `sales_invoice_validate`.

Italy also uses plain `doc_events` for submit / cancel hooks (not override-based):
- [erpnext/hooks.py:375](../../erpnext/hooks.py:375) — `Sales Invoice.on_submit` adds `erpnext.regional.italy.utils.sales_invoice_on_submit`.
- [erpnext/hooks.py:379](../../erpnext/hooks.py:379) — `Sales Invoice.on_cancel` adds `erpnext.regional.italy.utils.sales_invoice_on_cancel`.
- [erpnext/hooks.py:393](../../erpnext/hooks.py:393) — `Address.validate` adds `erpnext.regional.italy.utils.set_state_code`.

This dual pattern is typical: **`regional_overrides` replaces a function body**, while **`doc_events` adds an extra handler**.

## Example: United Arab Emirates

- [erpnext/hooks.py:610](../../erpnext/hooks.py:610) — overrides `update_itemised_tax_data` and `make_regional_gl_entries`.
- [erpnext/hooks.py:384](../../erpnext/hooks.py:384) — `Purchase Invoice.validate` adds two UAE handlers: `update_grand_total_for_rcm` and `validate_returns`.

The UAE override for `make_regional_gl_entries` replaces a stub declared in the Purchase Invoice module. Verify the stub via:

```python
@erpnext.allow_regional
def make_regional_gl_entries(...):
    pass
```

(typically found in the owning module — search with `@erpnext.allow_regional` in `erpnext/accounts/doctype/purchase_invoice/purchase_invoice.py`).

## How to add a new regional override

1. In the core module, declare the stub:

    ```python
    @erpnext.allow_regional
    def my_regional_fn(doc):
        pass
    ```

    or, for a non-stub default, write a generic implementation and decorate it — the decorator only intervenes when the region has a registration.

2. Create `erpnext/regional/<country>/utils.py` and implement `my_regional_fn(doc)` with the country-specific body.

3. Register in [erpnext/hooks.py](../../erpnext/hooks.py:608):

    ```python
    regional_overrides = {
        "<Country Name>": {
            "erpnext.<module>.<path>.my_regional_fn": "erpnext.regional.<country>.utils.my_regional_fn",
        },
    }
    ```

    Country name must match `Company.country` exactly.

4. At every call site, wrap with `temporary_flag("company", doc.company)` if the company context is not implicit through the current user's default. See [erpnext/controllers/accounts_controller.py:301](../../erpnext/controllers/accounts_controller.py:301).

5. Extend [architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) (Section 3) with the new entry.

## Current regional catalogue (verified)

From [erpnext/hooks.py:608](../../erpnext/hooks.py:608):

| Country | Overridden functions |
|---|---|
| France | `erpnext.tests.test_regional.test_method` (test-only) |
| United Arab Emirates | `update_itemised_tax_data`, `make_regional_gl_entries` |
| Saudi Arabia | `update_itemised_tax_data` (reuses UAE implementation) |
| Italy | `update_itemised_tax_data`, `validate_regional` |

Countries that ship other regional content but do **not** currently register function overrides: United States, Australia, Turkey, South Africa. They may still contribute `doctype/` schemas, reports, print formats, or `doc_events` entries — check `erpnext/regional/<country>/setup.py` and search `hooks.py` for the country's utils module.

## Related

- [Hooks and overrides](../architecture/hooks-and-overrides.md) — complete `hooks.py` catalogue.
- [Controller hierarchy](../architecture/controllers.md) — where `validate_regional` / `validate_einvoice_fields` are called from.

## Changelog

- `2026-04-17` — initial version.
