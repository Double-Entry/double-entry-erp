# Claude Code Hooks — Reference Template

<!--
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WHAT THIS DIRECTORY IS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reference material and example scripts for Claude Code hooks. Hooks are
shell-command automations the harness runs on well-defined lifecycle events
(before/after tool use, on user prompt, on session start, etc.).

This README is *descriptive*: it explains the hook system end-to-end so a
developer can wire new hooks without reading scattered docs.

Example scripts live alongside in this same folder — see bottom of file.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-->

## What hooks are (and what they are not)

A **hook** is a shell command the Claude Code harness executes in response to a lifecycle event. Hooks are the mechanism for **deterministic automated behavior** — things the model alone cannot reliably provide because they must happen consistently and outside the model's control:

- Pre-check a `Bash` command before the model runs it.
- Auto-format a file after the model writes it.
- Append to an audit log every time the user submits a prompt.
- Display a custom summary when the model finishes a turn.
- Block permission-sensitive operations.

Hooks are NOT:
- A place to put model-reasoning logic — if the decision is "should I do X", the model should decide, not a hook.
- A substitute for agent rules — hooks are blunt pre/post filters, not structured reasoning.
- Part of the conversation — hooks run silently (unless they write to stdout/stderr), they are not seen by the model except in specific event-output contracts.

## Where hooks are configured

Hooks are configured in **`.claude/settings.json`** (project-wide) or **`.claude/settings.local.json`** (local, typically git-ignored), under the `hooks` top-level key:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/example/pre-bash-guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [ /* ... */ ],
    "UserPromptSubmit": [ /* ... */ ],
    "Stop": [ /* ... */ ]
  }
}
```

Structure:
- Top-level `hooks` object.
- Inside, each key is an **event name** (see catalog below).
- Each event maps to an **array of matchers**.
- Each matcher has a `matcher` string (regex or tool name) and a `hooks` array of commands.
- Each command entry has `type: "command"` and a `command` string (shell command).
- You can also add `timeout` (seconds) to individual command entries.

## Lifecycle events — full catalog

| Event | When it fires | Stdin JSON payload | Exit code semantics |
|-------|---------------|--------------------|--------------------|
| **`PreToolUse`** | Before a tool is executed. | `{"tool_name": ..., "tool_input": ..., "session_id": ..., "cwd": ...}` | `0` allow; `2` block + send stderr to model; other non-zero = block with error. |
| **`PostToolUse`** | After a tool returns. | `{"tool_name": ..., "tool_input": ..., "tool_response": ...}` | `0` continue; other codes may warn but not block. |
| **`UserPromptSubmit`** | When the user submits a prompt. | `{"prompt": ..., "session_id": ...}` | `0` allow; `2` block submission + stderr to model. |
| **`Notification`** | When Claude needs user attention (waiting for input, permission needed). | `{"message": ...}` | Informational only. |
| **`Stop`** | When the main agent finishes its turn. | `{"stop_hook_active": ...}` | `0` continue; `2` tells model it should keep working (rare). |
| **`SubagentStop`** | When a sub-agent (Agent tool) finishes. | `{"stop_hook_active": ...}` | Same as Stop. |
| **`PreCompact`** | Before the harness compacts older messages. | `{"trigger": "manual" or "auto"}` | Informational. |
| **`SessionStart`** | At the start of a new session. | `{"session_id": ..., "cwd": ...}` | Informational. |
| **`SessionEnd`** | When a session ends. | `{"session_id": ...}` | Informational. |

### Matcher patterns

- For `PreToolUse` / `PostToolUse`, `matcher` is a **tool-name pattern**. Exact names: `Bash`, `Edit`, `Write`, `Read`, `Grep`, `Glob`, `WebFetch`, `Agent`, etc. Also supports regex (`.*` matches any tool).
- For other events, `matcher` is typically `""` (empty — matches all) or omitted.
- Multiple matchers in an event array all get their chance; each independent.

## The stdin / stdout contract

Each hook script:
1. Receives a **JSON payload on stdin** describing the event.
2. Runs its logic.
3. Writes to **stdout** (typically ignored unless the event has an output contract).
4. Writes to **stderr** (shown to user — or to model for blocking events).
5. Exits with a status code determining whether the action is allowed.

Key rule: **stderr + exit code 2 is the model-blocking channel.** For `PreToolUse`, exiting 2 blocks the tool AND sends stderr to the model so it can adapt. Use this to enforce project policy ("don't run `rm -rf`"; "don't commit to main directly"; etc.).

For events without a blocking channel (`PostToolUse`, `Notification`, `Stop`, etc.), exit codes other than 0 may produce warnings but won't rewind the event.

## Writing hook scripts — operational rules

1. **Keep them fast (<1 second typical, <5 seconds hard ceiling).** Hooks are in the critical path of every tool call / prompt / session event — slow hooks noticeably degrade UX.
2. **Use absolute paths.** Don't rely on `$PATH` or relative paths. Start with `#!/usr/bin/env bash` or `#!/usr/bin/env python3` shebangs.
3. **Don't rely on shell environment for values.** If you need project path, use `$CLAUDE_PROJECT_DIR` (provided by the harness).
4. **Parse the stdin JSON robustly.** Use `jq`, `python -c`, or a small script language — don't grep raw JSON.
5. **Log to a file if debugging.** stdout/stderr are user-facing for many events; use a log file for hook-internal traces (`${CLAUDE_PROJECT_DIR}/.claude/hooks/log.txt`).
6. **Make hooks idempotent.** A hook may be re-run (e.g., after retries). Side effects should be safe to repeat.
7. **Fail open for advisory hooks.** If an auto-format hook errors, prefer `exit 0` + stderr warning over blocking. Reserve `exit 2` for true policy violations.
8. **Test hooks without the harness.** Each script should be testable via `echo '{"tool_name": "Bash", ...}' | ./pre-bash-guard.sh`.
9. **Version-control the scripts.** Keep them under `.claude/hooks/` and check in.
10. **Document each hook** at the top of the script: event, what it does, expected payload fields, exit semantics.

## Common hook patterns

**Policy enforcement (blocking):**
- Block `Bash` commands matching destructive patterns (`rm -rf`, `DROP TABLE`, `git push --force`).
- Block commits/pushes to protected branches.
- Block writes to secret / config directories.

**Auto-maintenance (non-blocking):**
- Run `prettier`/`ruff`/`eslint --fix` after `Edit` or `Write` on relevant files.
- Run `go mod tidy` after edits to `go.mod`.
- Regenerate typed API schemas after proto / openapi changes.

**Audit & observability:**
- Append every user prompt + model response to an audit log.
- Emit metrics (hook-run count, tool-use histogram).
- Notify external systems (Slack on Stop event if session ended in error).

**Safety rails:**
- On `SessionStart`, verify git working tree matches expected baseline.
- On `Stop`, check no uncommitted changes remain in a protected path.

## Security considerations

- **Hooks run with your user's privileges.** A malicious project could ship hooks that exfiltrate data. **Review hooks in any cloned project before trusting them.**
- **Hooks inherit environment variables.** Redact sensitive env vars in hook scripts (`unset AWS_SECRET_ACCESS_KEY` at top).
- **Don't put secrets in hook scripts.** Hooks are checked into the repo.
- **Beware of shell injection.** If a hook constructs a command using untrusted input (e.g. a file path from tool_input), quote it properly or use array invocation.

## Example scripts in this directory

<!--
The examples intentionally cover the three most common event types:
  PreToolUse (blocking), PostToolUse (non-blocking), Stop (end-of-turn).
Each is a self-contained, well-commented bash script showing the stdin contract.
-->

- [pre-bash-guard.sh](pre-bash-guard.sh) — `PreToolUse` matcher `Bash`. Blocks destructive bash patterns (rm -rf, force-push to main, etc.) via exit code 2. Template for policy enforcement.
- [post-write-format.sh](post-write-format.sh) — `PostToolUse` matcher `Write|Edit`. Auto-runs Prettier/Ruff on modified files. Template for auto-maintenance.
- [stop-summary.sh](stop-summary.sh) — `Stop` event. Emits a 2-line summary of what changed in the turn (git diff stats). Template for observability.

## Example `settings.json` snippet

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/example/pre-bash-guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/example/post-write-format.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/example/stop-summary.sh"
          }
        ]
      }
    ]
  }
}
```

## Common best-practices summary

- **Fast. Deterministic. Idempotent.**
- **Exit 0 unless you are enforcing a policy.**
- **Use stderr for model-visible messages on blocking events; stdout is usually ignored.**
- **`$CLAUDE_PROJECT_DIR` is your friend — always use it for path anchors.**
- **Parse stdin JSON with `jq`, not regex.**
- **Keep hooks under version control and review them during code review.**
- **Never put secrets in hook scripts — they are checked into the repo.**
- **Document each hook's event, matcher, and exit semantics at the top of the script.**

## Further reading

- Claude Code documentation on hooks (look up via official docs — this file is a local reference).
- The three example scripts in this directory are annotated starting points.
- Russian mirror of this README: `.claude/hooks/example/ru/README.md`.
