---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: getting-started
status: complete
related_docs:
  - getting-started/installation.md
  - getting-started/development.md
  - getting-started/testing-and-quality.md
  - architecture/overview.md
  - patterns/patches.md
  - patterns/regional-overrides.md
---

# Operations

> **TL;DR:** Day-to-day ERPNext ops are `bench` commands plus `site_config.json` edits. This page is the single cheatsheet: CLI, config keys, production pointers, troubleshooting checklist, debugging tools, and a "where to next" into the architecture docs.

## CLI cheatsheet

All commands assume `cwd = ~/frappe-bench`.

| Command | Purpose | Notes |
|---|---|---|
| `bench start` | Launch all Procfile processes for dev. | See [development.md](development.md). Reference: [.github/helper/install.sh:76](../../.github/helper/install.sh:76). |
| `bench restart` | Restart web + workers in-place. | Needed after Python-source edits. |
| `bench --site <site> console` | Python REPL with `frappe` and a live DB connection. | Auto-commits at exit unless you `frappe.db.rollback()`. |
| `bench --site <site> mariadb` | Interactive MariaDB shell for the site's DB. | Reads `site_config.json`. |
| `bench --site <site> postgres` | Interactive psql shell. | Reads `site_config.json`. |
| `bench --site <site> migrate` | Apply patches + sync DocType schema + refresh fixtures. | See [patterns/patches.md](../patterns/patches.md). |
| `bench --site <site> clear-cache` | Drop meta, permission, boot caches for that site. | Routine after custom-field / workflow edits. |
| `bench --site <site> clear-website-cache` | Portal/website cache only. | Faster than full cache clear. |
| `bench build [--app <app>]` | Rebuild JS/CSS assets into `sites/assets/`. | Production deploys must run this. |
| `bench backup [--site <site>] [--with-files]` | Dump DB + optional public/private files to `sites/<site>/private/backups/`. | `--with-files` adds the asset archive. |
| `bench --site <site> restore <sql.gz>` | Restore a site from a dump. | Drops and recreates the DB. |
| `bench --site <site> reinstall --yes` | Drop + recreate + reinstall all apps. | CI uses this — [.github/helper/install.sh:78](../../.github/helper/install.sh:78). Destructive. |
| `bench --site <site> drop-site` | Delete site and DB. | Destructive. |
| `bench --site <site> install-app <app>` | Install an additional app onto an existing site. | Runs the app's `after_install`. |
| `bench --site <site> uninstall-app <app>` | Remove an app from a site. | Keeps DocTypes by default. |
| `bench --site <site> set-config <key> <value>` | Edit `site_config.json` safely. | Append `-g` for global (`common_site_config.json`). |
| `bench --site <site> add-system-manager <email>` | Create a System Manager user. | Useful after restoring a DB with stale admin. |
| `bench update` | Pull all apps + migrate + build. | Production upgrade command. |
| `bench setup requirements [--dev]` | Reinstall Python requirements for all apps. | CI uses `--dev` — [.github/helper/install.sh:72](../../.github/helper/install.sh:72). |

## `site_config.json` / `common_site_config.json`

Two layers:

- `sites/common_site_config.json` — bench-wide defaults (DB host/port, workers, shared Redis URLs).
- `sites/<site>/site_config.json` — per-site overrides (per-site DB creds, admin password, mail, feature flags).

The per-site file wins key-by-key. The CI reference configs are the most reliable contract.

**MariaDB reference** — [.github/helper/site_config_mariadb.json](../../.github/helper/site_config_mariadb.json:1):

```json
{
 "db_host": "127.0.0.1",
 "db_port": 3306,
 "db_name": "test_frappe",
 "db_password": "test_frappe",
 "auto_email_id": "test@example.com",
 "mail_server": "smtp.example.com",
 "mail_login": "test@example.com",
 "mail_password": "test",
 "admin_password": "admin",
 "use_mysqlclient": 1,
 "root_login": "root",
 "root_password": "root",
 "host_name": "http://test_site:8000",
 "install_apps": ["payments", "erpnext"],
 "throttle_user_limit": 100
}
```

**Postgres reference** — [.github/helper/site_config_postgres.json](../../.github/helper/site_config_postgres.json:1):

```json
{
 "db_host": "127.0.0.1",
 "db_port": 5432,
 "db_name": "test_frappe",
 "db_password": "test_frappe",
 "db_type": "postgres",
 "allow_tests": true,
 "auto_email_id": "test@example.com",
 "mail_server": "smtp.example.com",
 "mail_login": "test@example.com",
 "mail_password": "test",
 "admin_password": "admin",
 "root_login": "postgres",
 "root_password": "travis",
 "host_name": "http://test_site:8000",
 "install_apps": ["erpnext"],
 "throttle_user_limit": 100
}
```

### Frequently-edited keys

| Key | Type | Purpose |
|---|---|---|
| `db_type` | `"mariadb"` (default) / `"postgres"` | Postgres config includes it — [site_config_postgres.json:6](../../.github/helper/site_config_postgres.json:6). |
| `developer_mode` | `1` / `0` | Lets UI DocType edits write back to JSON. Off by default. |
| `allow_tests` | `true` / `false` | Gate for `bench run-tests`. See [testing-and-quality.md](testing-and-quality.md). |
| `maintenance_mode` | `1` / `0` | Puts the site in read-only / 503 mode. |
| `pause_scheduler` | `1` / `0` | Stops `scheduler_events` from firing on this site. |
| `disable_async` | `1` / `0` | Make all `frappe.enqueue` calls synchronous — debug-only. |
| `throttle_user_limit` | int | Concurrent request cap per user. |
| `mail_server`, `mail_port`, `mail_login`, `mail_password` | SMTP | Outbound email. |
| `default_country`, `country` | str | Influences regional hooks loaded at boot — see [patterns/regional-overrides.md](../patterns/regional-overrides.md). |
| `host_name` | str | External URL used in email templates, webhooks. |
| `webserver_port` | int | Override the default `:8000` for multi-site benches. |

`bench set-config -s <site> <key> <value>` is the safe way to edit — it handles JSON types (`--as-dict`, `-p` for passwords) and file locking.

## Production overview

The repo does not ship production deployment tooling (`bench setup production` lives in the Frappe framework). The canonical production stack provisioned by Frappe's bench is:

- **nginx** as the edge proxy — serves static assets directly, proxies `/api/*` and `/desk/*` to gunicorn.
- **gunicorn** as the WSGI server for `frappe.app` (the Werkzeug app). Workers configured via `bench config dns_multitenant <on|off>` + env settings.
- **supervisor** (or systemd units generated by `bench setup systemd`) running `web`, `schedule`, `worker-default`, `worker-long`, `worker-short`, `redis-*`, `socketio`.
- **Redis** — three instances (cache / queue / socketio) started by supervisor.
- **MariaDB or Postgres** — typically on a separate host in real deployments.

Frappe's upstream docs describe the full production setup; this repo does not fork it. `TODO(verify)` — no in-tree file asserts these exact process names for production; the list mirrors the dev Procfile (see [development.md](development.md)) plus standard Frappe community guidance.

## Troubleshooting

### Port 8000 already in use

```
OSError: [Errno 48] Address already in use
```

- Another `bench start` is running — `lsof -i :8000` and kill the owner.
- Or change port: edit `sites/common_site_config.json` → `"webserver_port": 8001`.

### Redis connection refused

```
redis.exceptions.ConnectionError: Error 111 connecting to localhost:11000
```

- Verify `redis-server` is installed ([.github/helper/install.sh:9](../../.github/helper/install.sh:9)).
- `bench start` manages Redis itself — another shell's `bench start` may hold the port. One bench per machine unless you remap ports.
- Check `logs/redis-cache.log`, `logs/redis-queue.log`.

### MariaDB: `Specified key was too long`

```
1071: Specified key was too long; max key length is 767 bytes
```

Root cause: the site was created without `utf8mb4` + `utf8mb4_unicode_ci`. CI forces these before creating the test DB — [.github/helper/install.sh:37-38](../../.github/helper/install.sh:37):

```bash
mariadb ... -e "SET GLOBAL character_set_server = 'utf8mb4'"
mariadb ... -e "SET GLOBAL collation_server = 'utf8mb4_unicode_ci'"
```

Add equivalent to `/etc/mysql/mariadb.conf.d/50-server.cnf`:

```
[mysqld]
character-set-server = utf8mb4
collation-server     = utf8mb4_unicode_ci
```

Restart MariaDB and drop-and-recreate the site.

### `wkhtmltopdf: cannot connect to X server`

- The patched-Qt build is mandatory — see [prerequisites.md](prerequisites.md) and [.github/helper/install.sh:54](../../.github/helper/install.sh:54).
- Using `apt install wkhtmltopdf` from distro repos is **not enough** on most distros; install the `.deb` from the upstream packaging release linked from the install script.

### Scheduler not firing

- Check `site_config.json` → `"pause_scheduler": 0`.
- Check the `schedule` Procfile line is not commented out (CI disables it — [.github/helper/install.sh:65](../../.github/helper/install.sh:65)).
- `bench --site <site> enable-scheduler`.
- `scheduler_events` dict is declared in [erpnext/hooks.py:433](../../erpnext/hooks.py:433).

### Timezone drift

Frappe stamps timestamps in the DB in UTC and converts on render using `System Settings → Time Zone`. Mismatched server clock or missing `tz` setting produces confusing audit logs.

- Keep the OS clock in UTC.
- Set `System Settings → Time Zone` per the operating jurisdiction.

### Patch failed mid-migrate

```
Failed to apply patch erpnext.patches.v15_0.xyz
```

- Read `logs/web.log` / `logs/frappe.log` for the traceback.
- Fix the underlying cause (often a null field the patch did not expect).
- `bench --site <site> migrate --skip-failing` skips and records — use only in known-safe conditions.
- For patch mechanics: [patterns/patches.md](../patterns/patches.md).

### Tests silently exit with 0

- `site_config.json` missing `allow_tests: true` — see [testing-and-quality.md](testing-and-quality.md) and the Postgres reference [site_config_postgres.json:7](../../.github/helper/site_config_postgres.json:7).
- `bench set-config -s <site> allow_tests true`.

### Stale fixtures after DocType edit

- `bench --site <site> migrate` re-syncs DocType JSON → DB schema.
- Follow with `bench --site <site> clear-cache`.
- If a Custom Field disappears, check `sites/<site>/site_config.json` → `"developer_mode": 1` is set before editing in the UI.

## Debugging

### `bench console`

```bash
bench --site mysite.localhost console
```

A Python shell bound to the site. Pre-imported: `frappe`. Useful commands:

```python
frappe.get_doc("Sales Invoice", "SI-00001").as_dict()
frappe.db.sql("SELECT name FROM `tabGL Entry` WHERE docstatus=1 LIMIT 5", as_dict=True)
frappe.get_all("Error Log", order_by="creation desc", limit=10)
frappe.clear_cache()
```

All DB writes auto-commit at REPL exit unless you call `frappe.db.rollback()`.

### Logs

Inside the bench directory:

- `logs/web.log` — web process.
- `logs/worker.log` — RQ worker (long-running jobs).
- `logs/scheduler.log` — scheduler dispatcher.
- `logs/frappe.log` — application-level `frappe.logger()` output.
- `logs/redis-*.log` — per-Redis-instance logs.

Start a tail before reproducing a bug:

```bash
tail -F logs/web.log logs/worker.log logs/frappe.log
```

### `frappe.logger`

For debug output from a controller:

```python
frappe.logger("erpnext", allow_site=True).info("…")
```

The first argument is the logger name; output routes to `logs/<name>.log`.

### Error Log UI

Every unhandled exception writes an `Error Log` DocType with stack trace. Navigate to `/app/error-log` or query:

```python
frappe.get_all("Error Log", fields=["creation", "method", "error"], order_by="creation desc", limit=10)
```

Auto-pruned by a scheduled job.

### Interactive breakpoints

Drop `breakpoint()` in any controller method; the `web` (or `worker`) process drops into PDB on the next request that hits that line. You must be tailing the `bench start` terminal to interact with the REPL.

`debug-statements` pre-commit hook ([.pre-commit-config.yaml:21](../../.pre-commit-config.yaml:21)) will refuse to commit with leftover `breakpoint()` or `pdb` imports.

## Where to next

Now that the bench is up and you can run, test, and debug, the architecture docs are the right next layer.

- [docs/architecture/overview.md](../architecture/overview.md) — module map and where-to-start-tracing cheatsheet; orientation for anyone new to the codebase.
- [docs/architecture/controllers.md](../architecture/controllers.md) — the controller inheritance chain that every transaction DocType sits on.
- [docs/architecture/doctype-pattern.md](../architecture/doctype-pattern.md) — four-file DocType layout.
- [docs/architecture/doctype-lifecycle.md](../architecture/doctype-lifecycle.md) — `validate → on_submit → on_cancel` through the chain.
- [docs/architecture/hooks-and-overrides.md](../architecture/hooks-and-overrides.md) — exhaustive tour of `erpnext/hooks.py`.
- [docs/patterns/patches.md](../patterns/patches.md) — migration machinery, what `bench migrate` really does.
- [docs/patterns/regional-overrides.md](../patterns/regional-overrides.md) — country-specific code injection.
- [docs/README.md](../README.md) — full documentation index.

## Related

- [Installation](installation.md) — how the bench and site got built in the first place.
- [Development](development.md) — Procfile processes, hot reload, DB access.
- [Testing and quality](testing-and-quality.md) — test runner, pre-commit, commitlint.

## Changelog

- `2026-04-18` — initial version.
