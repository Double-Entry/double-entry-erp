#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hook: stop-summary.sh
# Event: Stop
# Matcher: (empty — fires on every main-agent turn completion)
# Purpose: Show a concise end-of-turn summary of git-tracked changes, so the
#          user knows what the model touched this turn.
#
# Exit semantics:
#   0 — normal completion.
#   2 — tell model to keep working (rare, typically not useful from Stop).
#
# Stdin payload shape:
#   { "stop_hook_active": true|false, "session_id": "..." }
#
# Dependencies: git (optional — hook no-ops if not a git repo).
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Read and ignore stdin (payload not needed for this hook).
cat >/dev/null

# Anchor to the project dir (harness-provided).
cd "${CLAUDE_PROJECT_DIR:-.}"

# Only run in git repos.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Compute diff stats.
unstaged=$(git diff --shortstat 2>/dev/null || echo "")
staged=$(git diff --cached --shortstat 2>/dev/null || echo "")
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

# Emit to stderr so user sees it (stdout is typically ignored for Stop).
{
  echo "── Turn summary ──"
  [[ -n "$unstaged" ]] && echo "Unstaged: ${unstaged# }"
  [[ -n "$staged" ]] && echo "Staged:   ${staged# }"
  [[ "$untracked" -gt 0 ]] && echo "Untracked files: $untracked"
  [[ -z "$unstaged" && -z "$staged" && "$untracked" -eq 0 ]] && echo "No git-tracked changes."
} >&2

exit 0
