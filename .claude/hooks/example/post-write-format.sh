#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hook: post-write-format.sh
# Event: PostToolUse
# Matcher: Write|Edit
# Purpose: Auto-format the file just written/edited using an appropriate
#          formatter based on file extension.
#
# Exit semantics:
#   0 — always; formatting failures are logged but do not block flow.
#
# Stdin payload shape (Write):
#   {
#     "tool_name": "Write",
#     "tool_input": { "file_path": "...", "content": "..." },
#     "tool_response": { ... }
#   }
# Stdin payload shape (Edit):
#   {
#     "tool_name": "Edit",
#     "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
#     "tool_response": { ... }
#   }
#
# Dependencies: jq + per-language formatters installed (prettier, ruff, etc.).
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

payload="$(cat)"
file_path="$(echo "$payload" | jq -r '.tool_input.file_path // ""')"

# Nothing to format?
if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  exit 0
fi

# Extract extension.
ext="${file_path##*.}"

log() {
  echo "[post-write-format] $*" >&2
}

# ─── Dispatch by extension ──────────────────────────────────────────────────
case "$ext" in
  py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file_path" >/dev/null 2>&1 || log "ruff format failed on $file_path"
      ruff check --fix "$file_path" >/dev/null 2>&1 || log "ruff check --fix failed on $file_path"
    fi
    ;;
  js|jsx|ts|tsx|json|css|scss|md|yml|yaml)
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$file_path" >/dev/null 2>&1 || log "prettier failed on $file_path"
    fi
    ;;
  go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$file_path" >/dev/null 2>&1 || log "gofmt failed on $file_path"
    fi
    ;;
  rs)
    if command -v rustfmt >/dev/null 2>&1; then
      rustfmt "$file_path" >/dev/null 2>&1 || log "rustfmt failed on $file_path"
    fi
    ;;
  sh|bash)
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -w "$file_path" >/dev/null 2>&1 || log "shfmt failed on $file_path"
    fi
    ;;
  *)
    # Unknown extension — skip silently.
    ;;
esac

# Always succeed — formatting is advisory.
exit 0
