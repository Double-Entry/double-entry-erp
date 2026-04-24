---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: shopping_cart
status: complete
related_docs:
  - modules/shopping-cart.md
  - modules/portal-doctypes.md
  - modules/selling-doctypes.md
---

# Shopping Cart — DocType reference cards

> **TL;DR:** **No DocTypes ship in `erpnext/shopping_cart/doctype/` at this commit.** The directory contains only `__init__.py`. Cart-style flows materialise into DocTypes owned by other modules: Quotation / Sales Order / Customer (Selling), Address (Setup), Payment Request / Payment Entry (Accounts). Storefront-side cart doctypes (E Commerce Settings, Item Cart) live in the out-of-tree `webshop` app.

## Module summary

| DocType | File | Status |
|---------|------|--------|
| _(none)_ | [erpnext/shopping_cart/doctype/](../../erpnext/shopping_cart/doctype/) | Empty subpackage marker only |

## Where cart-related DocTypes actually live

For traceability when a cart-flow DocType seems "missing from this module":

| DocType | Owning module | Reference card |
|---------|--------------|----------------|
| Quotation (`order_type = "Shopping Cart"`) | Selling | [selling-doctypes.md](selling-doctypes.md) |
| Quotation Item | Selling | [selling-doctypes.md](selling-doctypes.md) |
| Sales Order | Selling | [selling-doctypes.md](selling-doctypes.md) |
| Sales Order Item | Selling | [selling-doctypes.md](selling-doctypes.md) |
| Customer | Selling | [selling-doctypes.md](selling-doctypes.md) |
| Address | Setup (Frappe core for the base; ERPNext-side customisations in [accounts/custom/address.py](../../erpnext/accounts/custom/address.py)) | [setup-doctypes.md](setup-doctypes.md) |
| Item / Item Price / Pricing Rule | Stock (Item) + Accounts (Pricing Rule) | [stock-doctypes.md](stock-doctypes.md), [accounts-doctypes.md](accounts-doctypes.md) |
| Payment Request | Accounts | [accounts-doctypes.md](accounts-doctypes.md) |
| Payment Entry | Accounts | [accounts-doctypes.md](accounts-doctypes.md) |
| Bank Account / Bank Transaction | Accounts | [accounts-doctypes.md](accounts-doctypes.md) |
| Portal User (per-Customer/Supplier child row) | Utilities | [utilities-doctypes.md](utilities-doctypes.md) |
| Website Attribute / Website Filter Field (storefront facets) | Portal | [portal-doctypes.md](portal-doctypes.md) |

## Out-of-tree DocTypes

The following DocTypes that historically lived under shopping_cart now ship in the [`webshop`](https://github.com/frappe/webshop) app:

- E Commerce Settings (Single).
- Website Item.
- Item Cart.
- Wishlist + Wishlist Item.

ERPNext does not import these and does not depend on `webshop`.

## Related

- [Shopping Cart module](shopping-cart.md) — explains the empty-module state and the `payment_gateway_enabled` hook.
- [Portal DocTypes](portal-doctypes.md)
- [Selling DocTypes](selling-doctypes.md)

## Changelog

- `2026-04-18` — initial version. Documented the empty doctype directory and the cross-module pointer table.
