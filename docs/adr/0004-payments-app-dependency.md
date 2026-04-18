---
title: payments app installed before erpnext
status: Accepted
date: 2026-04-18
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
---

# ADR 0004: `payments` app installed before `erpnext`

## Context

Historically, gateway integrations (Stripe, Razorpay, GoCardless, Braintree, PayPal, etc.) lived inside ERPNext's `accounts/` and `erpnext_integrations/` modules. As other Frappe apps (Frappe LMS, Frappe HR's expense reimbursement, Frappe Insights paid plans, custom storefronts, the now-out-of-tree `webshop`) needed the same gateway plumbing, keeping it inside ERPNext meant pulling in the entire ERP just for "take a card payment." That coupling was untenable.

The gateway code was therefore extracted into a standalone Frappe app, [`payments`](https://github.com/frappe/payments), which any Frappe app can consume.

ERPNext still needs gateway functionality for Payment Request, the Shopping Cart shell, subscription billing, and any storefront-style integration. So the dependency runs the other way: **ERPNext now depends on `payments`**.

## Decision

The install order is fixed: `payments` must be retrieved and installed before `erpnext`.

The CI install script encodes this:

```bash
bench get-app payments --branch develop          # install.sh:69
bench get-app erpnext "${GITHUB_WORKSPACE}"      # install.sh:70
```

— see [`.github/helper/install.sh:69-70`](../../.github/helper/install.sh:69). The same order applies to `bench install-app payments && bench install-app erpnext` on a target site.

The cross-app contract is one hook: `payments` (or any consumer) calls the function registered at [`hooks.py:521`](../../erpnext/hooks.py:521) — `payment_gateway_enabled = "erpnext.accounts.utils.create_payment_gateway_account"` — to get ERPNext to materialise a GL Account when a Payment Gateway is enabled. The receiver lives at [`erpnext/accounts/utils.py:1489`](../../erpnext/accounts/utils.py:1489).

## Rationale

- **Reusability.** Gateway code is genuinely cross-app: LMS, HR reimbursement, Insights, third-party storefronts all need it without inheriting ERPNext's accounting mass.
- **Cleaner ownership.** Gateway provider logic (per-provider OAuth, webhook handling, signature verification) is its own concern; mixing it into ERPNext's `accounts/` blurred the seam.
- **One-way dependency.** ERPNext consumes `payments` (account-creation hook listener); `payments` does not depend on ERPNext. A site can install `payments` for LMS without ERPNext at all.
- **Documented in install path.** [docs/getting-started/installation.md](../getting-started/installation.md) and the after-install seed walkthrough call out the order so a fresh-bench attempt doesn't fail at `install-app erpnext` with a missing dependency.

## Consequences

- **Install order is mandatory.** `bench install-app erpnext` without `payments` installed first raises a missing-app error at install time. This is now a routine first-week hurdle for new contributors and is called out in [docs/getting-started/installation.md](../getting-started/installation.md).
- **CI scripts must encode the order.** [`install.sh:69-70`](../../.github/helper/install.sh:69) does. Any new automation (Docker image build, Ansible playbook, internal deploy pipeline) must follow.
- **`payment_gateway_enabled` hook lives in `payments`** and is consumed by ERPNext. The function `create_payment_gateway_account` at [`accounts/utils.py:1489`](../../erpnext/accounts/utils.py:1489) is therefore part of ERPNext's public API surface for the `payments` app — its signature must not break without coordination.
- **Shopping Cart in-tree is a shell.** As documented in [docs/modules/shopping-cart.md](../modules/shopping-cart.md), the cart proper has moved to the out-of-tree `webshop` app and likewise depends on `payments`. The only live in-tree wiring is the `payment_gateway_enabled` hook.
- **No code coupling beyond the hook.** ERPNext does not import from `payments` directly; the boundary is the hook + the GL-account materialisation contract.

## Alternatives considered

- **Keep gateway code in ERPNext** — rejected: forces every consumer (LMS, HR, etc.) to install all of ERPNext just for card processing. Hostile to the broader Frappe ecosystem.
- **Vendor `payments` into ERPNext as a sub-package** — rejected: still couples release cycles; bug fixes in `payments` would block on an ERPNext release.
- **Make ERPNext the producer and `payments` the consumer (other direction)** — rejected: inverts the actual semantic dependency. Gateway plumbing is the lower-level capability; accounting consumes it.
- **Optional dependency with feature flag** — rejected: the cart / Payment Request paths assume the gateway accounts exist; making it optional would require parallel code paths everywhere a gateway is referenced.

## Citations

- [`.github/helper/install.sh:69-70`](../../.github/helper/install.sh:69) — `bench get-app payments` before `bench get-app erpnext`.
- [`erpnext/hooks.py:521`](../../erpnext/hooks.py:521) — `payment_gateway_enabled` hook registration.
- [`erpnext/accounts/utils.py:1489`](../../erpnext/accounts/utils.py:1489) — `create_payment_gateway_account` consumer.

## Related docs

- [Installation](../getting-started/installation.md) — `bench get-app payments && bench get-app erpnext` step-by-step.
- [`after_install` seed catalogue](../getting-started/after-install-seed.md) — what ERPNext's install path does (and does not) seed.
- [Shopping Cart module](../modules/shopping-cart.md) — confirms the in-tree shell + the live `payment_gateway_enabled` wire.
