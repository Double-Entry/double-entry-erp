---
title: Regional overrides via @erpnext.allow_regional + hooks registry
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0002: `@erpnext.allow_regional` + `regional_overrides` registry over country subclasses

## Context

ERPNext is deployed across many tax regimes. Country-specific behaviour shows up in several places:

- Tax row → GL line composition (UAE Reverse Charge, Italy IVA, India GST splits, etc.).
- Validation (NIF / VAT / TIN format checks).
- Document templating (Italy FatturaPA XML, Saudi ZATCA QR, Australia BAS reports).
- Depreciation and asset life policies.

A naive design would subclass per country (e.g. `UAEAccountsController`, `ItalianSalesInvoice`) or monkey-patch core methods at app-install time. Both approaches break under the realistic constraint that **third-party apps** (`india_compliance`, `erpnext_gst`, `erpnext_zatca`, etc.) need to inject their own country logic *without* forking core, and a single bench may host companies in different countries simultaneously.

## Decision

Regionalization uses two cooperating mechanisms:

1. **`@erpnext.allow_regional` decorator** on every overridable function. The decorator at [`erpnext/__init__.py:135`](../../erpnext/__init__.py:135) wraps the call so that at runtime it consults `frappe.get_hooks("regional_overrides")` keyed by the active company's country and dispatches to the registered replacement if one exists.
2. **`regional_overrides` dict** in [`erpnext/hooks.py:608`](../../erpnext/hooks.py:608) (and in any installed app's `hooks.py`) maps `"<Country>" → { "<dotted.fn.path>": ["<replacement.dotted.path>"] }`. Last-installed-app wins ([`__init__.py:152`](../../erpnext/__init__.py:152) — `overrides[function_path][-1]`).

Country routing comes from the per-company `country` field, resolved at call time ([`__init__.py:130`](../../erpnext/__init__.py:130) — `frappe.get_cached_value("Company", company, "country")`), so a multi-company bench transparently dispatches per-document.

The full mechanism is documented in [docs/patterns/regional-overrides.md](../patterns/regional-overrides.md).

## Rationale

- **Third-party extensibility.** External apps register overrides by adding to their own `hooks.py` `regional_overrides` dict; no core fork required. India compliance, GST, ZATCA, and similar ecosystems all rely on this.
- **No subclass explosion.** Avoids combinatorial growth (`SalesInvoice × N countries × M lifecycle methods`) that would emerge from per-country subclasses.
- **Per-company routing.** A single bench with companies in UAE, Italy, and Australia routes each invoice to the correct override based on the document's company field — impossible with class-level subclassing without runtime metaclass tricks.
- **No fragility.** Monkey-patching `SalesInvoice.set_taxes` from an installed app's `after_install` is order-dependent and silently breaks if two apps patch the same method. The hooks dict makes overrides **declarative** and discoverable.
- **Last-installed-wins** gives a deterministic priority for multi-app stacks ([`__init__.py:152`](../../erpnext/__init__.py:152)).

## Consequences

- **Open slots may be unfilled.** The decorator is applied to many functions that have no country override registered; the wrapped function falls through to the original. Of 19 `@erpnext.allow_regional` stub slots inventoried in [docs/modules/regional.md](../modules/regional.md), 15 are unused at this commit. That is by design — the slot is opened pre-emptively so an external app can target it later without a core change.
- **Discoverability is via grep, not class hierarchy.** A new engineer cannot find country-specific behaviour by reading a class tree; they must search for `regional_overrides` and `@allow_regional`. The [regional module overview](../modules/regional.md) and [pattern doc](../patterns/regional-overrides.md) consolidate the catalogue.
- **No static type checking.** Override functions are addressed by string path; a typo or rename in the target function is only caught at the first dispatching call (and only for the configured country).
- **Performance is per-call dict lookup.** Not measurable at transaction granularity; not a concern.
- **Override authoring contract.** Replacement functions must accept the same signature as the original; there is no formal interface, only convention.

## Alternatives considered

- **`override_doctype_class` per country** — rejected: produces an explosion of subclasses (one per country per overrideable DocType), still cannot do per-company routing inside a single bench, and would require coordinated multi-app subclassing for stacked overrides.
- **Monkey-patching from external app `after_install`** — rejected: order-dependent, silent collision between apps, hostile to debugging.
- **Strategy pattern with a country registry of policy objects** — rejected: would require every overridable surface to be refactored into a policy interface; the decorator approach delivers the same outcome with one-line opt-in per function.

## Citations

- [`erpnext/__init__.py:135-153`](../../erpnext/__init__.py:135) — `allow_regional` decorator implementation.
- [`erpnext/__init__.py:130-132`](../../erpnext/__init__.py:130) — country resolution from active company.
- [`erpnext/hooks.py:608`](../../erpnext/hooks.py:608) — core `regional_overrides` registry.

## Related docs

- [Regional overrides pattern](../patterns/regional-overrides.md) — mechanism deep-dive with worked examples.
- [Regional module](../modules/regional.md) — per-country override catalogue and unused-slot inventory.
- [Regional DocType reference cards](../modules/regional-doctypes.md) — country-specific DocTypes shipped in core.
