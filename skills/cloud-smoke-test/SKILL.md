---
name: cloud-smoke-test
description: "Read-only pre-flight check that verifies the current Claude Code session can actually do dev work — repo access, gh issue/PR ops, and each configured MCP server. Designed for claude.ai cloud sessions where degradation is invisible until something fails mid-task. Triggers on 'cloud smoke test', 'verify my environment', 'is cloud working', 'check claude.ai env', 'pre-flight check', 'is everything wired up'."
---

# Cloud Smoke Test

A read-only sweep that confirms the current session can do dev work. Designed for claude.ai cloud sessions where you don't know whether MCPs are wired, auth is fresh, or the repo is accessible until something fails mid-task.

**Target: ≤1 minute. No writes. No installs. No side effects.**

## How to run

Run all checks **in parallel** — every one is independent. Pack them into a single message with many Bash and MCP tool calls. Then aggregate the results into the table below.

For MCP tools that are deferred in the current session: use ToolSearch first (e.g. `select:mcp__supabase__execute_sql,mcp__sentry__whoami,...`) to load schemas, then call them. If a tool name doesn't resolve via ToolSearch, that MCP isn't configured in this session — mark it `n/a` (not a failure).

## What to verify

### 1. Repo & git (Bash)

- `pwd && git rev-parse --show-toplevel 2>&1` — confirm cwd is a git repo
- `git remote get-url origin 2>&1` — confirm upstream exists
- `git ls-remote --heads origin main 2>&1 | head -1` — network + auth to remote

### 2. GitHub via gh (Bash)

- `gh auth status 2>&1` — gh CLI authed
- `gh issue list --limit 1 --json number,title 2>&1` — read access to issues
- `gh pr list --limit 1 --json number,title 2>&1` — read access to PRs

### 3. MCP servers — one cheap read each

| MCP | Tool name | Call |
|---|---|---|
| Supabase | `mcp__supabase__execute_sql` | `SELECT 1 AS ok` |
| Sentry | `mcp__sentry__whoami` | no args |
| Vercel | `mcp__claude_ai_Vercel__list_teams` | no args |
| Resend | `mcp__resend__list-domains` | no args |
| Plural Pulse | `mcp__claude_ai_Plural_Pulse_remote__pulse_priorities` | no args |
| Slack | `mcp__claude_ai_Slack__slack_search_channels` | `query="dev"`, limit 1 |
| Seik | `mcp__claude_ai_Seik_remote__wiki_status` | no args |
| Granola | `mcp__claude_ai_Granola__get_account_info` | no args |
| Gmail | `mcp__claude_ai_Gmail__list_labels` | no args |
| Google Calendar | `mcp__claude_ai_Google_Calendar__list_calendars` | no args |
| Google Drive | `mcp__claude_ai_Google_Drive__list_recent_files` | limit 1 |
| Readwise | `mcp__claude_ai_Readwise__reader_list_tags` | no args |
| Monologue | `mcp__claude_ai_Monologue__list_recent_notes` | limit 1 |

If an MCP needs a required argument the cheap call above doesn't cover, pick the most minimal read-only variant in its schema. Never call write tools (no `send_message`, no `create_*`, no `update_*`, no `INSERT/UPDATE/DELETE`).

### 4. Toolchain (Bash)

- `bun --version 2>&1` — bun on PATH
- `node --version 2>&1`

## How to report

After all calls return, render this table in a single message:

```
| Capability         | Status | Detail                          |
|--------------------|--------|---------------------------------|
| git repo           | ✅     | /Users/.../plural-pulse         |
| origin remote      | ✅     | github.com/plural-platform/...  |
| network → origin   | ✅     | main @ abc1234                  |
| gh auth            | ✅     | logged in as stamkivi           |
| gh issue read      | ✅     | #951 returned                   |
| gh pr read         | ✅     | #952 returned                   |
| Supabase MCP       | ✅     | SELECT 1 → 1                    |
| Sentry MCP         | ❌     | 401 unauthorized                |
| ...                | ...    | ...                             |
| bun                | ✅     | 1.x.y                           |
| node               | ✅     | v20.x.x                         |
```

Use `✅` for pass, `❌` for fail, `–` for `n/a` (MCP not configured in this session).

End with a single line:
- `ALL GREEN (N checks passed, M n/a)` — or —
- `N FAILED out of M: <list>` — followed by a one-sentence diagnosis for each failure when obvious (e.g. "Sentry MCP → 401 means OAuth not completed; visit any sentry.dev URL in your browser to authenticate this session").

## What NOT to do

- Do **not** clone, install, or modify anything.
- Do **not** call any write MCP tool (no `send_message`, `create_*`, `update_*`, `delete_*`).
- Do **not** run `bun install`, `bun tsc`, tests, or any build command.
- Do **not** edit, create, or delete files.
- Do **not** attempt to fix failures — just report. The user decides what to do.

## Maintenance

When a new MCP is added to `.mcp.json` or to the claude.ai connector list, add a row to the table in section 3. When an MCP is removed, remove its row. Keep the cheap-read column to a single read-only call that confirms auth + network without enumerating large result sets.
