#!/usr/bin/env bash
# build-rite: sync AI harness into any project.
#
# Run:    curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash
# Alias:  curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s -- --install-alias
#
# Harness owns (synced every run):     br-* commands, br-* rules, hooks, CLAUDE.md
# Project owns (never touched):        non-br-* commands, non-br-* rules, settings.json, settings.local.json
# Generated (never touched):           project-root CLAUDE.md (from /br-discover)

set -euo pipefail

REPO="${BUILD_RITE_REPO:-https://github.com/abhishekvm/build-rite.git}"
RAW_URL="${BUILD_RITE_RAW:-https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/build-rite"
ALIAS_NAME="br-sync"

# ── install-alias ────────────────────────────────────────────────
if [ "${1:-}" = "--install-alias" ]; then
  SHELL_RC="$HOME/.zshrc"
  [ -n "${BASH_VERSION:-}" ] && [ ! -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.bashrc"

  if grep -qF "$ALIAS_NAME" "$SHELL_RC" 2>/dev/null; then
    echo "Alias '$ALIAS_NAME' already in $SHELL_RC"
  else
    printf '\n# build-rite sync\nalias %s='\''curl -sSf %s | bash'\''\n' "$ALIAS_NAME" "$RAW_URL" >> "$SHELL_RC"
    echo "Added '$ALIAS_NAME' to $SHELL_RC — restart shell or: source $SHELL_RC"
  fi
  echo "Usage: cd your-project/ && $ALIAS_NAME"
  exit 0
fi

# ── resolve project ──────────────────────────────────────────────
PROJECT_DIR="${1:-$(pwd)}"
[ -d "$PROJECT_DIR/.git" ] || { echo "Error: '$PROJECT_DIR' is not a git repo."; exit 1; }

TARGET="$PROJECT_DIR/.claude"

# ── resolve harness source ───────────────────────────────────────
if [ -d "$CACHE_DIR/.git" ]; then
  echo "Updating cache..."
  if ! git -C "$CACHE_DIR" pull --quiet 2>/dev/null; then
    echo "  pull failed — re-cloning"
    rm -rf "$CACHE_DIR"
    git clone --quiet "$REPO" "$CACHE_DIR"
  fi
else
  echo "Cloning build-rite..."
  git clone --quiet "$REPO" "$CACHE_DIR"
fi
SRC="$CACHE_DIR/.claude"

# ── sync helpers ─────────────────────────────────────────────────
synced=()

# Sync a category: sync_br <subdir> <glob> <label>
#   - copies matching files from source
#   - removes stale br-* files not present in source
sync_br() {
  local subdir="$1" glob="$2" label="$3"
  local src_dir="$SRC/$subdir" tgt_dir="$TARGET/$subdir"

  mkdir -p "$tgt_dir"

  # copy from source
  for f in "$src_dir"/$glob; do
    [ -f "$f" ] || continue
    cp "$f" "$tgt_dir/"
    synced+=("$label/$(basename "$f")")
  done

  # remove stale br-* not in source
  for f in "$tgt_dir"/br-*; do
    [ -f "$f" ] || continue
    [ -f "$src_dir/$(basename "$f")" ] && continue
    rm "$f"
    synced+=("$label/$(basename "$f") (removed)")
  done
}

# Sync a single file
sync_file() {
  local rel="$1"
  local src_file="$SRC/$rel" tgt_file="$TARGET/$rel"

  mkdir -p "$(dirname "$tgt_file")"
  [ -f "$src_file" ] || return 0
  cp "$src_file" "$tgt_file"
  synced+=("$rel")
}

# Sync a file only if it doesn't exist yet
sync_file_once() {
  local rel="$1"
  local tgt_file="$TARGET/$rel"

  [ -f "$tgt_file" ] && { echo "  ~ $rel (kept existing)"; return 0; }
  sync_file "$rel"
}

# ── sync ─────────────────────────────────────────────────────────
echo "Syncing → $TARGET/"

sync_br    "commands"  "br-*.md"  "commands"    # br-* commands
sync_br    "rules"     "br-*.md"  "rules"       # br-* rules
sync_file  "hooks/enforce-tools.py"              # hooks
sync_file  "CLAUDE.md"                           # harness instructions
sync_file_once "settings.json"                   # settings (first run only)

# ── report ───────────────────────────────────────────────────────
echo ""
echo "Synced:"
printf '  %s\n' "${synced[@]}"
echo ""
echo "Untouched: non-br-* rules, non-br-* commands, settings.json (after first run), settings.local.json"
echo ""

if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
  echo "Next: run /br-discover to generate project CLAUDE.md"
fi
