---
last_updated: 2026-04-18
commit: fbe976fb3b
branch: feat/setting-claude
scope: getting-started
status: complete
related_docs:
  - getting-started/prerequisites.md
  - getting-started/development.md
  - getting-started/operations.md
---

# Testing and quality

> **TL;DR:** Tests run via `bench run-tests` (one module) or `bench run-parallel-tests` (full matrix). Test classes extend [`ERPNextTestSuite`](../../erpnext/tests/utils.py:2966), whose `tearDown` runs `frappe.db.rollback()` — every test is independent. Sites must opt in with `allow_tests: true` in `site_config.json`. Lint/format/commit rules are gated by pre-commit + commitlint; direct commits to `develop` are blocked.

## Key files

- [erpnext/tests/utils.py:2966](../../erpnext/tests/utils.py:2966) — `class ERPNextTestSuite(unittest.TestCase)`.
- [erpnext/tests/utils.py:2979-2980](../../erpnext/tests/utils.py:2979) — `tearDown` rollback contract.
- [erpnext/tests/utils.py:2997-3020](../../erpnext/tests/utils.py:2997) — `change_settings` context manager.
- [.github/workflows/server-tests-mariadb.yml:132](../../.github/workflows/server-tests-mariadb.yml:132) — CI command: `bench --site test_site run-parallel-tests --lightmode --app erpnext --total-builds 4 --build-number <n> --with-coverage`.
- [.github/helper/site_config_postgres.json:7](../../.github/helper/site_config_postgres.json:7) — `allow_tests: true` opt-in.
- [.pre-commit-config.yaml](../../.pre-commit-config.yaml:1) — hook manifest.
- [pyproject.toml:43-78](../../pyproject.toml:43) — Ruff config (line-length 110, tab indent, `py310` target, rule set).
- [commitlint.config.js](../../commitlint.config.js:1) — commit-message rules.
- [CLAUDE.md:22-34](../../CLAUDE.md:22) — project-level summary of the test commands.

## Running tests

### Full suite (CI-equivalent)

```bash
bench --site <site> run-parallel-tests --lightmode --app erpnext
```

CI runs this sharded across 4 containers — [.github/workflows/server-tests-mariadb.yml:132](../../.github/workflows/server-tests-mariadb.yml:132):

```bash
bench --site test_site run-parallel-tests \
      --lightmode \
      --app erpnext \
      --total-builds 4 \
      --build-number ${{ matrix.container }} \
      --with-coverage
```

Locally `--lightmode --app erpnext` is enough; the splitter flags are only useful if you shard manually.

### Single module

```bash
bench --site <site> run-tests --module erpnext.accounts.doctype.sales_invoice.test_sales_invoice
```

The `--module` argument is the full dotted Python path, not a filename.

### Single test

```bash
bench --site <site> run-tests \
      --module erpnext.accounts.doctype.sales_invoice.test_sales_invoice \
      --test   test_sales_invoice_change_naming_series
```

Method-level granularity. Combine with `breakpoint()` inside the test for interactive debugging.

### Test file location

Every test lives alongside its DocType controller, named `test_<doctype>.py` — e.g. `erpnext/accounts/doctype/sales_invoice/test_sales_invoice.py`. See [CLAUDE.md:34](../../CLAUDE.md:34).

## `allow_tests` opt-in

Tests **will not execute** on a site whose `site_config.json` does not contain `allow_tests: true`. The Postgres CI config sets it — [.github/helper/site_config_postgres.json:7](../../.github/helper/site_config_postgres.json:7):

```json
"allow_tests": true,
```

For the MariaDB CI config the flag is **not** present in [.github/helper/site_config_mariadb.json](../../.github/helper/site_config_mariadb.json:1) — meaning the framework-level default on a fresh `new-site` is assumed permissive enough for the MariaDB matrix. `TODO(verify)` — the authoritative gate lives in Frappe core, not in ERPNext; if your local `run-tests` silently exits, `bench set-config -s <site> allow_tests true` is the canonical fix.

## `ERPNextTestSuite`

Every ERPNext test class should extend `ERPNextTestSuite` — [erpnext/tests/utils.py:2966](../../erpnext/tests/utils.py:2966):

```python
class ERPNextTestSuite(unittest.TestCase):
	@classmethod
	def setUpClass(cls):
		cls.globalTestRecords = {}

	def tearDown(self):
		frappe.db.rollback()

	def load_test_records(self, doctype):
		if doctype not in self.globalTestRecords:
			records = load_test_records_for(doctype)
			self.globalTestRecords[doctype] = records[doctype]

	@contextmanager
	def set_user(self, user: str):
		...
```

Contracts:

1. **Rollback in `tearDown`** — [erpnext/tests/utils.py:2979](../../erpnext/tests/utils.py:2979). Every test runs inside an open transaction; `tearDown` always rolls back so tests are independent regardless of order or failures. You do **not** need to clean up after yourself in the test body.
2. **`globalTestRecords` cache** — [erpnext/tests/utils.py:2977](../../erpnext/tests/utils.py:2977). Fixtures loaded via `self.load_test_records("DocType")` are memoised per class.
3. **`set_user` helper** — [erpnext/tests/utils.py:2987-2994](../../erpnext/tests/utils.py:2987). Temporarily flips `frappe.session.user` for permission-aware assertions, restores on exit.

### Bootstrap test data

The module also instantiates `BootStrapTestData()` at import — [erpnext/tests/utils.py:2963](../../erpnext/tests/utils.py:2963). That constructor runs `make_presets()` + `make_master_data()`, which seed genders, salutations, UOMs, item groups, territories, customer groups, supplier groups, and other preset masters so test bodies can assume they exist. See [erpnext/tests/utils.py:125](../../erpnext/tests/utils.py:125) for the full sequence.

### `change_settings` context manager

[erpnext/tests/utils.py:2997-3020](../../erpnext/tests/utils.py:2997) registers `change_settings` on the suite as a staticmethod:

```python
@ERPNextTestSuite.registerAs(staticmethod)
@contextmanager
def change_settings(doctype, settings_dict=None, /, **settings) -> None:
	"""Temporarily: change settings in a settings doctype."""
	...
```

Use inside a test to flip a Single (e.g., `Stock Settings`, `Accounts Settings`) for one block:

```python
with self.change_settings("Accounts Settings", allow_multi_currency_invoices_against_single_party_account=1):
	# test body — reverted automatically after the block exits
	...
```

## Pre-commit hooks

The repo's quality gate is pre-commit. Install it once:

```bash
pip install pre-commit
pre-commit install
```

Run against all files manually:

```bash
pre-commit run --all-files
```

Hook breakdown — see [.pre-commit-config.yaml:7-71](../../.pre-commit-config.yaml:7):

| Hook | What it does |
|---|---|
| `trailing-whitespace` | Trim trailing whitespace from Python sources (excludes JSON/TXT/CSV/MD). |
| `check-yaml` / `check-json` / `check-toml` | Parse-level sanity. |
| `no-commit-to-branch --branch develop` | **Blocks direct commits to `develop`** — [.pre-commit-config.yaml:14](../../.pre-commit-config.yaml:14). |
| `check-merge-conflict` | Fail if any file contains `<<<<<<<`. |
| `check-ast` | Parse every Python file — catches syntax errors before Ruff runs. |
| `debug-statements` | Fail on leftover `breakpoint()` / `pdb` imports. |
| `prettier` (v2.7.1) | Format `javascript, vue, scss` — [.pre-commit-config.yaml:23](../../.pre-commit-config.yaml:23). |
| `eslint` (v8.44.0) | Lint `.js` — [.pre-commit-config.yaml:38](../../.pre-commit-config.yaml:38). |
| `ruff` (import sorter) | Sort imports (I-rule set) — [.pre-commit-config.yaml:60](../../.pre-commit-config.yaml:60). |
| `ruff` (linter) | Full Ruff lint pass — [.pre-commit-config.yaml:63](../../.pre-commit-config.yaml:63). |
| `ruff-format` | Format to 110-col, tab indent — [.pre-commit-config.yaml:66](../../.pre-commit-config.yaml:66). |

Ruff is pinned to **v0.2.0** via `astral-sh/ruff-pre-commit` — [.pre-commit-config.yaml:56-57](../../.pre-commit-config.yaml:56).

### Ruff config

[pyproject.toml:43-78](../../pyproject.toml:43):

- `line-length = 110`.
- `indent-style = "tab"`, `quote-style = "double"`.
- `target-version = "py310"` — even though runtime is 3.14; this keeps the syntax subset writable by older consumers.
- Selected rule set: `F, E, W, I, UP, B, RUF` — pyflakes, pycodestyle, isort, pyupgrade, flake8-bugbear, Ruff-specific.
- Ignored rules include `E501` (line-too-long — the 110 limit is enforced by the formatter, not the linter), `W191` (tab indent), `F401`/`F403`/`F405` (star imports — heavily used in controllers).

### Prettier scope

[.pre-commit-config.yaml:23-36](../../.pre-commit-config.yaml:23) applies Prettier to `javascript, vue, scss` and **excludes**:

```
erpnext/public/dist/.*
cypress/.*
.*node_modules.*
.*boilerplate.*
erpnext/templates/includes/.*
```

Generated bundles, Cypress fixtures, and Jinja-rich templates are hand-formatted.

### ESLint scope

[.pre-commit-config.yaml:38-54](../../.pre-commit-config.yaml:38) applies ESLint with `--quiet` and **excludes** additionally `erpnext/public/js/controllers/.*` and `erpnext/templates/pages/order.js` on top of the Prettier exclude list. `TODO(verify)` — the exclude for `erpnext/public/js/controllers/` preserves the legacy controller shape while the rest of the code migrates; this is historical, not intentional behaviour.

## Commitlint

Conventional Commits are enforced — [commitlint.config.js:1](../../commitlint.config.js:1):

```
<type>(<scope>): <subject>
```

Allowed `<type>` values — [commitlint.config.js:10](../../commitlint.config.js:10):

```
build  chore  ci  docs  feat  fix  perf  refactor  revert  style  test
```

Hard rules:

- `type-empty: [2, "never"]` — type required.
- `type-case: [2, "always", "lower-case"]` — lowercase only.
- `subject-empty: [2, "never"]` — subject required.

Example valid subjects:

```
feat(accounts): add multi-currency support to Payment Entry
fix(stock): correct SLE rounding diff on internal transfer
docs(getting-started): document bench Procfile
```

## Commits to `develop` are blocked

[.pre-commit-config.yaml:14](../../.pre-commit-config.yaml:14) pins `no-commit-to-branch --branch develop` — a pre-commit-level block. Create a topic branch per feature/fix. For CI-level check, [linters.yml:1](../../.github/workflows/linters.yml:1) runs pre-commit on every PR.

## Semgrep

In addition to pre-commit, a Semgrep job runs on every PR — [.github/workflows/linters.yml:26](../../.github/workflows/linters.yml:26):

```bash
semgrep ci --config ./frappe-semgrep-rules/rules --config r/python.lang.correctness
semgrep ci --include=**/test_*.py --config ./semgrep/test-correctness.yml
```

Two rule sets: Frappe's public rules + the repo-local [`semgrep/test-correctness.yml`](../../semgrep/) pack for test-file correctness.

## Coverage

The MariaDB test workflow uploads coverage to Codecov — [.github/workflows/server-tests-mariadb.yml:141-164](../../.github/workflows/server-tests-mariadb.yml:141). The `--with-coverage` flag on `run-parallel-tests` writes `coverage.xml` into `sites/`. Postgres runs the same test matrix without a public coverage upload.

## Related

- [Prerequisites](prerequisites.md) — what to install before any of this runs.
- [Development](development.md) — `bench start` and the dev feedback loop.
- [Operations](operations.md) — debugging and troubleshooting catalogue.

## Changelog

- `2026-04-18` — initial version.
