---
name: handoff-to-mac-mini
description: "Move an in-progress coding project from the laptop to uv-mac-mini so work continues there and is steerable from the Claude desktop and mobile apps. Sets up the GitHub repo, syncs the working tree and secrets, registers a Remote Control server, and seeds the session with a written brief. TRIGGERS: 'move this to the mac mini', 'continue this on the mini', 'hand this off to the mac mini', 'run this on uv-mac-mini', 'set this up to run remotely', 'I'm heading out, keep building', 'make this visible in my Claude app'. Use whenever work should outlive the laptop session or run unattended."
---

# Hand a project off to uv-mac-mini

Move an in-progress project to the mac mini so it keeps building while the laptop is closed,
and so Sten can steer it from the Claude app.

**The single thing that makes this work: use Remote Control *server* mode, not `claude -p`.**
A `-p` run is a one-shot print job. It never appears in the app, and it cannot be steered even
if it did — there is no prompt to type into. Server mode publishes an environment the app can
spawn sessions into, which is the entire point of a machine nobody sits in front of.

The mini's own setup repo (`~/git/mac-mini-setup`) documents this well. Read
`rc-projects.txt` and `claude-remote-control.sh` there rather than inventing a parallel
mechanism; a cron watchdog already restarts these every 15 minutes and after reboot.

## Steps

### 1. Repo on GitHub, over HTTPS

```sh
gh repo create <name> --private --source=. --remote=origin --description "..."
# gh defaults to SSH even when told otherwise — always correct it:
git remote set-url origin "$(git remote get-url origin | sed 's|git@github.com:|https://github.com/|')"
SSH_AUTH_SOCK= git push --dry-run origin master   # proves the no-agent case works
git push -u origin master
```

Private first; make it public at release. Before pushing, confirm no secrets or large data are
tracked: `git ls-files | grep -E '^(data/|\.env$)'` should return only keepfiles.

### 2. Clone on the mini, correct the remote again

```sh
ssh uv-mac-mini 'cd ~/git && gh repo clone stamkivi/<name> && cd <name> &&
  git remote set-url origin "$(git remote get-url origin | sed "s|git@github.com:|https://github.com/|")"'
```

### 3. Secrets

`.env` is gitignored, so it does not travel with the repo. Pipe it over; never commit it.

```sh
cat .env | ssh uv-mac-mini 'cat > ~/git/<name>/.env && chmod 600 ~/git/<name>/.env'
```

Verify it loads with the shell environment unset, so you are testing the file and not a stale
export: `env -u SOME_KEY uv run python -c '...'`.

### 4. Environment and a green test run

```sh
ssh uv-mac-mini 'cd ~/git/<name> && uv sync --extra dev && uv run pytest -q'
```

### 5. Trust the directory — skip this and the server hangs silently

**A fresh clone has not accepted Claude Code's trust dialog, and the Remote Control server will
wait at that prompt forever while still looking connected.** It also blocks headless runs.

```sh
ssh uv-mac-mini 'cp ~/.claude.json ~/.claude.json.bak.$(date +%s) && python3 - <<PY
import json, os
p = os.path.expanduser("~/.claude.json")
d = json.load(open(p))
proj = d.setdefault("projects", {}).setdefault("/Users/stentamkivi/git/<name>", {})
proj["hasTrustDialogAccepted"] = True
proj["hasCompletedProjectOnboarding"] = True
json.dump(d, open(p, "w"), indent=2)
PY'
```

### 6. Register the Remote Control server

One server per project — a server's sessions are fixed to its cwd, and the project's
`CLAUDE.md`, `.mcp.json` and `.claude/settings` only load when that directory is the cwd.

```sh
ssh uv-mac-mini 'grep -q "<name>" ~/git/mac-mini-setup/rc-projects.txt ||
  printf "<key>  mini-<key>  /Users/stentamkivi/git/<name>\n" >> ~/git/mac-mini-setup/rc-projects.txt'

ssh uv-mac-mini 'tmux new-session -d -s claude-rc-<key> \
  "~/git/mac-mini-setup/claude-remote-control.sh mini-<key> /Users/stentamkivi/git/<name>"'

# Confirm it actually connected, do not assume:
ssh uv-mac-mini 'tmux capture-pane -pt claude-rc-<key> | tail -6'   # expect "Connected · <name>"
```

Then `ListAgents` from the laptop session: the project should appear as `mini-<key> · Remote
Control · idle`. If it does not, the pane will say why.

### 7. Long data setup runs separately

Anything gitignored and large — a dataset, a rate-limited API harvest — does not travel with the
repo. Write a `bootstrap.sh` in the project that fetches and caches it, make every step
resumable, and start it detached *before* the Claude session needs it:

```sh
ssh uv-mac-mini 'cd ~/git/<name> && nohup ./bootstrap.sh > bootstrap.log 2>&1 &'
```

Check the mini's free disk first — it runs tight. `df -h ~`.

### 8. Seed the session with a written brief

Put the brief in the repo as `HANDOFF.md` and commit it, so it is version-controlled and the
session can re-read it rather than depending on a chat message surviving. Then start it:

```
SendMessage to: mini-<key>
```

The message should name the task, point at `HANDOFF.md`, state what is already running, bound
the scope, and list the dead ends already ruled out so they are not re-litigated. Delivery is
not confirmed and nothing reports back — check the app.

A good `HANDOFF.md` states the one question the work exists to answer, and says explicitly that
a negative answer is acceptable. Otherwise an eager session polishes past the finding.

## Do not

- **Do not run `claude -p` and a Remote Control session in the same repo at once.** Two agents
  will fight over the working tree and the git index.
- Do not use `--remote-control` (the flag). It publishes only the one interactive session it is
  attached to. The bare `claude remote-control` subcommand is the server.
- Do not append to `.env` without checking it ends in a newline — otherwise the new key is
  concatenated onto the previous line and neither parses. Rewrite the file instead.
- Do not commit `.env`, `data/`, or anything the project gitignores.

## Known noise, safe to ignore

`failed to store: -25308` on every git operation over SSH is macOS keychain refusing to *cache*
credentials in a non-interactive session. Auth still works through `gh auth git-credential`;
pushes succeed. Confirm with `git push` exit status rather than the warning text.

## Checking in later

```sh
ssh uv-mac-mini 'cd ~/git/<name> && tail -20 bootstrap.log && git log --oneline -5'
```

Or just read the GitHub repo — a well-briefed session pushes as it goes.
