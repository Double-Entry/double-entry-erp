---
last_updated: 2026-04-18
commit: f26f8bc3b6
branch: feat/setting-claude
scope: erpnext_integrations
status: complete
related_docs:
  - modules/erpnext-integrations.md
---

# ERPNext Integrations — DocType reference cards

> **TL;DR:** One DocType: `Plaid Settings`. Single (`issingle=1`). All other Plaid logic lives in module-level functions inside the same file. The module's only other code asset is `plaid_connector.py` (a thin wrapper class around the `plaid-python` SDK; no DocType representation).

## Module summary

| DocType | File | Single | Purpose |
|---------|------|--------|---------|
| Plaid Settings | [erpnext/erpnext_integrations/doctype/plaid_settings/](../../erpnext/erpnext_integrations/doctype/plaid_settings/) | yes | Holds Plaid API credentials and toggles |

## Plaid Settings

- **File:** [erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:1) (363 lines).
- **Schema:** [erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.json](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.json:1) — `issingle=1`.
- **Connector helper:** [plaid_connector.py](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_connector.py) — wraps `plaid.Client` for token exchange, link-token issuance, and transaction fetching.
- **Fields (auto-generated types at [plaid_settings.py:18-31](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:18)):**
  - `enabled` — `DF.Check`. Master switch.
  - `automatic_sync` — `DF.Check`. Gates the hourly scheduler.
  - `enable_european_access` — `DF.Check`.
  - `plaid_client_id` — `DF.Data | None`.
  - `plaid_secret` — `DF.Password | None`.
  - `plaid_env` — `DF.Literal["sandbox", "development", "production"]`.
- **Lifecycle hooks:** none beyond `Document` base.
- **Whitelisted methods:**
  - `PlaidSettings.get_link_token` ([static method, line 33](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:33)) — returns a Plaid Link token for the front-end Link UI.
- **Module-level whitelisted helpers (called from JS):**
  - `get_plaid_configuration()` ([line 41](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:41)) — returns `{plaid_env, link_token, client_name=site}` when enabled, else `"disabled"`.
  - `add_institution(token, response)` ([line 54](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:54)) — creates / updates a `Bank` record after Plaid Link.
  - `add_bank_accounts(response, bank, company)` ([line 82](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:82)) — creates Bank Account + child GL Account for each Plaid account.
  - `enqueue_synchronization()` ([line 323](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:323)) — manually trigger sync of all linked accounts.
  - `get_link_token_for_update(access_token)` ([line 337](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:337)) — returns an update-mode link token (for re-auth).
  - `update_bank_account_ids(response)` ([line 357](../../erpnext/erpnext_integrations/doctype/plaid_settings/plaid_settings.py:357)) — re-syncs `integration_id` on existing Bank Accounts.
- **Cross-references in `hooks.py`:**
  - [hooks.py:457](../../erpnext/hooks.py:457) — `hourly_maintenance: erpnext.erpnext_integrations.doctype.plaid_settings.plaid_settings.automatic_synchronization`.

## Related

- [ERPNext Integrations module](erpnext-integrations.md)
- [Accounts DocTypes](accounts-doctypes.md) — Bank Account, Bank Transaction (the consumer endpoints).

## Changelog

- `2026-04-18` — initial version. Card for Plaid Settings (Single).
