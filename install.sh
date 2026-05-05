#!/bin/bash
# Symlink Claude Code skills and commands from this repo into ~/.claude/.
# Run from the repo root. Idempotent.
#
# Usage:
#   ./install.sh          # Create/update all symlinks
#   ./install.sh --check  # Verify symlinks without changing anything

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CHECK_ONLY=false
ERRORS=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

verify_link() {
  local target="$1" link="$2" label="$3"
  if [ -L "$link" ]; then
    local actual
    actual=$(readlink "$link")
    if [ "$actual" = "$target" ]; then
      echo "  OK  $label"
    else
      echo "  !!  $label → $actual (expected $target)"
      ERRORS=$((ERRORS + 1))
    fi
  elif [ -e "$link" ]; then
    echo "  !!  $label exists but is NOT a symlink"
    ERRORS=$((ERRORS + 1))
  else
    echo "  --  $label missing"
    ERRORS=$((ERRORS + 1))
  fi
}

if $CHECK_ONLY; then
  echo "Checking claude-skills links..."
  echo ""
  for cmd in "$REPO/commands/"*.md; do
    [ -f "$cmd" ] || continue
    name=$(basename "$cmd")
    verify_link "$cmd" "$CLAUDE_DIR/commands/$name" "commands/$name"
  done
  for skill_dir in "$REPO/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    verify_link "$skill_dir" "$CLAUDE_DIR/skills/$name" "skills/$name"
  done
  echo ""
  if [ $ERRORS -eq 0 ]; then
    echo "All links OK."
  else
    echo "$ERRORS issue(s) found. Run ./install.sh to fix."
  fi
  exit $ERRORS
fi

# --- Install mode ---
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

for cmd in "$REPO/commands/"*.md; do
  [ -f "$cmd" ] && ln -sf "$cmd" "$CLAUDE_DIR/commands/$(basename "$cmd")"
done

for skill_dir in "$REPO/skills/"*/; do
  [ -d "$skill_dir" ] && ln -sfn "$skill_dir" "$CLAUDE_DIR/skills/$(basename "$skill_dir")"
done

echo "claude-skills linked from $REPO"
echo "Run ./install.sh --check to verify."
