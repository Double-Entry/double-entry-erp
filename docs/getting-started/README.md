---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: getting-started
status: complete
related_docs:
  - getting-started/prerequisites.md
  - getting-started/installation.md
  - getting-started/development.md
  - getting-started/testing-and-quality.md
  - getting-started/operations.md
  - architecture/overview.md
---

# Getting Started

> **TL;DR:** ERPNext is a Frappe **app**. You never run it standalone — you install `bench`, bootstrap a `frappe-bench` working tree, pull the `payments` and `erpnext` apps into it, create a site, and install the app into that site. After that, `bench start` launches the full dev stack (web, worker, scheduler, Redis, file-watcher) on port `:8000`.

## 5-minute quick start

The shortest possible path to a running ERPNext dev instance. Details and rationale live in the linked pages.

```bash
# 1. System packages (Debian/Ubuntu; macOS has its own story — see prerequisites.md)
sudo apt install libcups2-dev redis-server mariadb-client libmariadb-dev

# 2. Install the bench CLI
pip install frappe-bench

# 3. Bootstrap a bench working tree backed by Frappe v17+
bench init --frappe-branch develop frappe-bench
cd frappe-bench

# 4. Pull ERPNext and its hard dependency
bench get-app payments --branch develop
bench get-app erpnext  # or: bench get-app erpnext <path-to-this-repo>

# 5. Create a site and install the app
bench new-site mysite.localhost
bench --site mysite.localhost install-app erpnext

# 6. Launch the dev stack
bench start
```

The CI installer follows exactly this shape — see [`.github/helper/install.sh`](../../.github/helper/install.sh:1) for the canonical reference implementation.

After `bench start` finishes booting, the web UI answers on `http://mysite.localhost:8000`. Login with user `Administrator` and the password you set during `bench new-site`.

## Where to go next

Each page is self-contained; follow them in order if you are new.

- [Prerequisites](prerequisites.md) — versions (Python 3.14, Node 24, MariaDB 10.6 / Postgres 13.3+, Redis, wkhtmltopdf 0.12.6), system packages, pre-commit toolchain.
- [Installation](installation.md) — `bench init`, `bench get-app`, `bench new-site`, `install-app`. Explains what `after_install` does and the `site_config.json` contract.
- [Development](development.md) — `bench start`, the `Procfile` process list (`redis_cache`, `redis_queue`, `redis_socketio`, `socketio`, `watch`, `schedule`, `web`, `worker`), database access, migrations.
- [Testing and quality](testing-and-quality.md) — `run-parallel-tests`, `run-tests --module`, `run-tests --test`, `ERPNextTestSuite`, pre-commit (Ruff + Prettier + ESLint), commitlint, `develop`-commit block.
- [Operations](operations.md) — CLI cheatsheet, `site_config` / `common_site_config` keys, production pointers, troubleshooting, debugging, jump-points into architecture docs.

## Who this section is for

- **New engineers** bringing up a local ERPNext for the first time.
- **LLM agents** needing reliable `path:line` references before answering questions about the install, dev, or test story.

This section is deliberately operational — it describes how to **run** the code, not how the code is **structured**. For the latter, start with [architecture/overview.md](../architecture/overview.md).

## Related

- [Architecture Overview](../architecture/overview.md) — module map and where-to-start-tracing cheatsheet.
- [Patches](../patterns/patches.md) — what `bench migrate` actually does.
- [Regional overrides](../patterns/regional-overrides.md) — how country-specific code is injected at boot.

## Changelog

- `2026-04-18` — initial version.
