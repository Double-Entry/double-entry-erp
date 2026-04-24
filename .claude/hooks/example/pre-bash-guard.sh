#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Hook: pre-bash-guard.sh
# Event: PreToolUse
# Matcher: Bash
# Purpose: Block destructive Bash commands before the harness runs them.
#
# Exit semantics:
#   0  — allow the Bash command to run.
#   2  — block; stderr is shown to the model so it can adjust.
#   1  — generic error (blocks, but less informative).
#
# Stdin payload shape:
#   {
#     "tool_name": "Bash",
#     "tool_input": { "command": "...", "description": "..." },
#     "session_id": "...",
#     "cwd": "..."
#   }
#
# Dependencies: jq (brew install jq / apt install jq).
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Read stdin JSON payload.
payload="$(cat)"

# Extract the command string being proposed.
cmd="$(echo "$payload" | jq -r '.tool_input.command // ""')"

# Nothing to check?
if [[ -z "$cmd" ]]; then
  exit 0
fi

# ─── Policy: destructive filesystem commands ────────────────────────────────
# Block `rm -rf /` and variations.
if echo "$cmd" | grep -Eq '\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+/+(\s|$)'; then
  echo "POLICY: 'rm -rf /' and filesystem-root variants are forbidden." >&2
  exit 2
fi

# Block `rm -rf ~` — wipes home directory.
if echo "$cmd" | grep -Eq '\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+\$HOME\b|~'; then
  echo "POLICY: 'rm -rf ~' is forbidden." >&2
  exit 2
fi

# ─── Policy: git push --force to protected branches ─────────────────────────
if echo "$cmd" | grep -Eq 'git\s+push\s+.*(--force(-with-lease)?|-f)\b.*\b(main|master|develop|release)\b'; then
  echo "POLICY: force-push to main/master/develop/release is forbidden." >&2
  echo "If you truly need this, run the command outside Claude Code and confirm with a human reviewer." >&2
  exit 2
fi

# ─── Policy: destructive git commands on uncommitted work ───────────────────
# Warn (not block) on git reset --hard and git clean -f; these are dangerous but legitimate.
# Model should confirm with user; we provide stderr advisory, not a block.
if echo "$cmd" | grep -Eq 'git\s+(reset\s+--hard|clean\s+-f[dx]*|checkout\s+--\s*\.)'; then
  # Not blocking — just advisory via stderr on exit 0. Model sees this only if blocking;
  # since we exit 0, the model does NOT see stderr. For true visibility use exit 2.
  # Choose behavior based on project policy; this example is permissive.
  true
fi

# ─── Policy: writes to protected paths ──────────────────────────────────────
# Block any command touching /etc, /System, or arbitrary root paths.
if echo "$cmd" | grep -Eq '(^|[^a-zA-Z0-9_])(sudo|doas)\s+'; then
  echo "POLICY: sudo/doas commands are blocked in this environment." >&2
  exit 2
fi

# ─── Policy: dangerous pipes to shell ───────────────────────────────────────
# e.g. `curl ... | sh` or `wget ... | bash` — remote code execution.
if echo "$cmd" | grep -Eq '(curl|wget)\s+[^|]*\|\s*(bash|sh|zsh|ksh)(\s|$)'; then
  echo "POLICY: piping remote content directly to a shell is forbidden." >&2
  echo "Download the file, inspect it, then run it deliberately." >&2
  exit 2
fi

# Allow by default.
exit 0
