---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: getting-started
status: complete
related_docs:
  - getting-started/installation.md
  - getting-started/testing-and-quality.md
---

# Prerequisites

> **TL;DR:** You need Python 3.14, Node.js 24, MariaDB 10.6 (or PostgreSQL), Redis, `wkhtmltopdf` 0.12.6, and a working `pip`. Pre-commit (with Ruff + Prettier + ESLint) is required for any code contributions. All versions below are pinned by the repo's own CI and `pyproject.toml`.

## Key files

- [pyproject.toml](../../pyproject.toml:7) — `requires-python = ">=3.14"`, dependencies, Ruff config.
- [pyproject.toml](../../pyproject.toml:40) — `[tool.bench.frappe-dependencies]` pins `frappe = ">=17.0.0-dev,<18.0.0"`.
- [.github/helper/install.sh](../../.github/helper/install.sh:9) — apt packages (`libcups2-dev redis-server mariadb-client libmariadb-dev`).
- [.github/helper/install.sh](../../.github/helper/install.sh:54) — `wkhtmltopdf` 0.12.6.1-2 URL.
- [.github/workflows/server-tests-mariadb.yml](../../.github/workflows/server-tests-mariadb.yml:57) — MariaDB 10.6 service image.
- [.github/workflows/server-tests-mariadb.yml](../../.github/workflows/server-tests-mariadb.yml:71) — Python 3.14.
- [.github/workflows/server-tests-mariadb.yml](../../.github/workflows/server-tests-mariadb.yml:84) — Node 24.
- [.github/workflows/linters.yml](../../.github/workflows/linters.yml:20) — Python 3.14 for linters job.
- [.pre-commit-config.yaml](../../.pre-commit-config.yaml:1) — pre-commit hooks manifest.
- [commitlint.config.js](../../commitlint.config.js:1) — conventional-commit types enforced.
- [package.json](../../package.json:15) — JS runtime deps (`onscan.js`).

## Runtime versions

| Component | Version | Source of truth |
|---|---|---|
| Python | **3.14+** | [pyproject.toml:7](../../pyproject.toml:7), confirmed in CI [linters.yml:20](../../.github/workflows/linters.yml:20) and [server-tests-mariadb.yml:71](../../.github/workflows/server-tests-mariadb.yml:71) |
| Node.js | **24** | [server-tests-mariadb.yml:84](../../.github/workflows/server-tests-mariadb.yml:84) |
| MariaDB | **10.6** | [server-tests-mariadb.yml:57](../../.github/workflows/server-tests-mariadb.yml:57) |
| PostgreSQL | any recent 13+ | [.github/helper/install.sh:47-50](../../.github/helper/install.sh:47) provisions via `psql` with no pinned version; the repo supports both via `db_type` in `site_config.json` (see [site_config_postgres.json:6](../../.github/helper/site_config_postgres.json:6)) |
| Redis | stock `redis-server` package | [.github/helper/install.sh:9](../../.github/helper/install.sh:9) |
| `wkhtmltopdf` | **0.12.6.1-2** (patched Qt, jammy amd64 build) | [.github/helper/install.sh:54](../../.github/helper/install.sh:54) |
| Frappe framework | `>=17.0.0-dev,<18.0.0` | [pyproject.toml:40-41](../../pyproject.toml:40) |

Ruff targets `py310` for linting even though `requires-python` is `3.14`; this is intentional and the syntax level is lower than the runtime — see [pyproject.toml:45](../../pyproject.toml:45).

## System packages (Debian/Ubuntu)

The CI installer uses exactly these apt packages, in this order — see [.github/helper/install.sh:9](../../.github/helper/install.sh:9):

```bash
sudo apt remove  mysql-server mysql-client
sudo apt install libcups2-dev redis-server mariadb-client libmariadb-dev
```

Notes:

- `libcups2-dev` — required by Python bindings used for printing.
- `libmariadb-dev` + `mariadb-client` — the bench defaults to `mysqlclient`, which wants the MariaDB dev headers.
- Remove the default `mysql-*` packages first — the MariaDB client conflicts with them on Ubuntu images.

### macOS

The repo does not ship macOS-specific instructions. The Frappe community convention is Homebrew:

```bash
brew install python@3.14 node@24 mariadb redis wkhtmltopdf
```

Verify `python --version` maps to 3.14 inside your shell before running `bench init`. `TODO(verify)` — the repo has no `brew` manifest; the list above is derived from the apt equivalents in [install.sh](../../.github/helper/install.sh:9).

## Python dependencies

`pyproject.toml` declares ERPNext's runtime Python deps — see [pyproject.toml:10-27](../../pyproject.toml:10):

- `Unidecode`, `barcodenumber`, `rapidfuzz`, `holidays` — core utilities.
- `googlemaps`, `plaid-python`, `python-youtube` — integration clients.
- `pypng` — transitive (PyQRCode PNG backend).
- `mt-940` — MT940 bank-statement parser.

You do **not** install these directly. `bench get-app erpnext` reads `pyproject.toml` and installs them into the bench's virtualenv.

Dev requirements (test tooling etc.) are pulled by `bench setup requirements --dev` — see [.github/helper/install.sh:72](../../.github/helper/install.sh:72).

## JavaScript dependencies

[package.json](../../package.json:14) is intentionally minimal:

- `onscan.js` — runtime dep for barcode scanner support on POS pages.

Everything else (ESLint, Prettier, build pipeline) is provided by the Frappe framework's own `package.json`, which `bench` wires into the asset build.

## `wkhtmltopdf`

PDF print formats require `wkhtmltopdf` 0.12.6 with the patched-Qt build. The CI downloads a specific `.deb` — [.github/helper/install.sh:54](../../.github/helper/install.sh:54):

```
https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```

Using any other build (e.g. distro package, 0.12.5, unpatched-Qt) produces broken PDFs — headers cut off, CSS ignored. If you install via Homebrew or another path, verify:

```bash
wkhtmltopdf --version  # must read: wkhtmltopdf 0.12.6 (with patched qt)
```

## Pre-commit toolchain

All local code changes are gated through [.pre-commit-config.yaml](../../.pre-commit-config.yaml:1). Install it once per clone:

```bash
pip install pre-commit
pre-commit install
```

The hooks will fetch and pin their own tool versions. Relevant pins at the time of this doc — see the config:

- `pre-commit-hooks` v4.3.0 — whitespace/ast/json/toml/yaml checks, merge-conflict guard, `no-commit-to-branch` against `develop` ([.pre-commit-config.yaml:14](../../.pre-commit-config.yaml:14)).
- `mirrors-prettier` v2.7.1 — Prettier for `javascript, vue, scss` ([.pre-commit-config.yaml:23](../../.pre-commit-config.yaml:23)).
- `mirrors-eslint` v8.44.0 — ESLint on `.js` ([.pre-commit-config.yaml:38](../../.pre-commit-config.yaml:38)).
- `ruff-pre-commit` v0.2.0 — Ruff (import sorter + linter + formatter) ([.pre-commit-config.yaml:56](../../.pre-commit-config.yaml:56)).

The `no-commit-to-branch` hook pins `--branch develop` — you cannot commit directly to `develop`, even locally ([.pre-commit-config.yaml:14](../../.pre-commit-config.yaml:14)).

## Commit-message linter

`commitlint` enforces Conventional Commits — see [commitlint.config.js:7-11](../../commitlint.config.js:7). Allowed types:

```
build chore ci docs feat fix perf refactor revert style test
```

Rule set in one line:

- `type-empty: never` — a type is mandatory.
- `type-case: lower-case` — lowercase only.
- `subject-empty: never` — a subject is mandatory.

## Minimum disk, memory

Not pinned in the repo. Frappe's public install docs recommend ≥4 GB RAM for a dev bench with Redis/MariaDB/Node watcher co-located. `TODO(verify)` — no repo-side file asserts a minimum.

## Related

- [Installation](installation.md) — bench init and site creation.
- [Testing and quality](testing-and-quality.md) — how pre-commit and commitlint are actually invoked.

## Changelog

- `2026-04-18` — initial version.
