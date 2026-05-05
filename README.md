# Claude Code skills & commands

Portable [Claude Code](https://docs.claude.com/claude-code) skills and slash
commands. Borrow what you find useful.

## What's in here

### Skills

| Skill | What it does |
|------|---------------|
| [`gstack-ceo`](skills/gstack-ceo/SKILL.md) | CEO/founder-mode spec reviewer. Challenges premises, finds the 10-star version hiding inside a 6-star spec, presents expansion opportunities for cherry-picking. Modes: expansion, selective, hold, reduction. |
| [`gstack-designer`](skills/gstack-designer/SKILL.md) | Senior product designer. Reviews specs for design completeness *before* implementation, creates design systems from scratch, or runs visual exploration. Opinionated about typography, color, spacing. |
| [`gstack-engineer`](skills/gstack-engineer/SKILL.md) | Engineering plan reviewer. Locks in architecture, data flow, edge cases, and test coverage *before* code is written. Catches landmines, ensures observability, maps every failure mode. |
| [`premortem`](skills/premortem/SKILL.md) | Run a Gary-Klein premortem on any plan, launch, hire, or strategy. Assumes it already failed 6 months from now and works backward to find every reason why. Fans out to sub-agents for diverse failure modes, then produces a revised plan with blind spots exposed. |

The three `gstack-*` skills are distilled from
[garrytan/gstack](https://github.com/garrytan/gstack) — adapted into the
SKILL.md format and tuned to my own workflow. All credit for the underlying
review frameworks goes there; go read the original.

### Slash commands

| Command | What it does |
|--------|---------------|
| [`/md-to-pdf`](commands/md-to-pdf.md) | Convert a markdown file to a clean PDF. |
| [`/rams`](commands/rams.md) | Run accessibility and visual design review. |
| [`/web-interface-guidelines`](commands/web-interface-guidelines.md) | Review UI code for Vercel Web Interface Guidelines compliance. |

## Install everything

If you want all of it:

```bash
git clone https://github.com/stamkivi/claude-skills.git ~/git/claude-skills
cd ~/git/claude-skills && ./install.sh
```

The install script symlinks each `commands/*.md` into `~/.claude/commands/`
and each `skills/*/` into `~/.claude/skills/`. Re-run after `git pull` to pick
up new ones — existing ones are live via symlink, no re-install needed.

Verify with `./install.sh --check`.

## Borrow just one

If you only want a single skill or command, you don't need to clone the whole
thing. Two options:

**Copy** (decoupled — your version, edit at will):

```bash
mkdir -p ~/.claude/skills/premortem
curl -fsSL https://raw.githubusercontent.com/stamkivi/claude-skills/master/skills/premortem/SKILL.md \
  -o ~/.claude/skills/premortem/SKILL.md
```

**Symlink** (stay in sync with upstream):

```bash
git clone https://github.com/stamkivi/claude-skills.git ~/git/claude-skills
ln -sfn ~/git/claude-skills/skills/premortem ~/.claude/skills/premortem
```

Slash commands work the same way — they're single `.md` files in
`~/.claude/commands/`.

## Don't use Claude Code? (Claude.ai web or Claude Desktop)

The `install.sh` flow is for [Claude Code](https://docs.claude.com/claude-code)
(the CLI/IDE tool). If you only use Claude on the web or in the desktop app,
you can still use these skills — just copy the prompt content directly. No
shell required.

**For repeated use (recommended): Project custom instructions**

1. Open the skill's `SKILL.md` on GitHub (e.g.
   [premortem/SKILL.md](skills/premortem/SKILL.md)).
2. Click *Raw* and copy the full text.
3. In Claude Desktop or claude.ai, create a new **Project**.
4. Paste the SKILL.md content into the Project's *Custom instructions* field.
5. Any chat in that Project will now follow the skill's instructions. Use the
   skill by saying e.g. *"premortem this plan: …"* or just by sharing the
   thing you want reviewed.

**For one-off use: paste at the start of a chat**

Copy the SKILL.md content, paste it as your first message, then add your
actual question/plan/spec underneath. The skill's instructions stay in
context for the rest of the conversation.

These skills are written as plain English instructions — they work anywhere
Claude does. Claude Code just gives you the ergonomic wrapper (slash commands,
auto-loading via `~/.claude/skills/`).

## Adding a skill

If you fork this and want to add your own:

1. Create `skills/<skill-name>/SKILL.md` (plus any supporting files).
2. Run `./install.sh` — it auto-detects new directories.
3. Commit and push. Other machines pick it up on `git pull`.

A skill is just a directory with a `SKILL.md` file. Claude Code reads the
SKILL.md when the skill is invoked. Multi-file skills work too — see
[Claude Code skills docs](https://docs.claude.com/claude-code/skills).

## License

MIT. Use, modify, redistribute freely. The gstack-derived skills follow
upstream conventions — check
[garrytan/gstack](https://github.com/garrytan/gstack) for the original.
