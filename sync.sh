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
VERSION=$(git -C "$CACHE_DIR" log -1 --format='%h %s' 2>/dev/null || echo "unknown")

# ── sync helpers ─────────────────────────────────────────────────
added=()
updated=()
current=()
removed=()

# Compare and copy a single file. Returns status via the arrays above.
sync_one() {
  local src_file="$1" tgt_file="$2" label="$3"

  if [ ! -f "$tgt_file" ]; then
    mkdir -p "$(dirname "$tgt_file")"
    cp "$src_file" "$tgt_file"
    added+=("$label")
  elif ! diff -q "$src_file" "$tgt_file" >/dev/null 2>&1; then
    cp "$src_file" "$tgt_file"
    updated+=("$label")
  else
    current+=("$label")
  fi
}

# Sync br-* files in a subdirectory, clean stale ones
sync_br() {
  local subdir="$1" glob="$2"
  local src_dir="$SRC/$subdir" tgt_dir="$TARGET/$subdir"

  mkdir -p "$tgt_dir"

  for f in "$src_dir"/$glob; do
    [ -f "$f" ] || continue
    local name=$(basename "$f")
    sync_one "$f" "$tgt_dir/$name" "$subdir/$name"
  done

  # remove stale br-* not in source
  for f in "$tgt_dir"/br-*; do
    [ -f "$f" ] || continue
    local name=$(basename "$f")
    [ -f "$src_dir/$name" ] && continue
    rm "$f"
    removed+=("$subdir/$name")
  done
}

# Sync a single file by relative path
sync_file() {
  local rel="$1"
  [ -f "$SRC/$rel" ] || return 0
  sync_one "$SRC/$rel" "$TARGET/$rel" "$rel"
}

# Sync only if target doesn't exist yet
sync_file_once() {
  local rel="$1"
  if [ -f "$TARGET/$rel" ]; then
    current+=("$rel (project-owned)")
    return 0
  fi
  [ -f "$SRC/$rel" ] || return 0
  mkdir -p "$(dirname "$TARGET/$rel")"
  cp "$SRC/$rel" "$TARGET/$rel"
  added+=("$rel")
}

# ── .gitignore (harness files excluded from project repo) ────────
GITIGNORE="$TARGET/.gitignore"
cat > "$GITIGNORE" <<'IGNORE'
# managed by br-sync — do not edit
# harness files (synced on every br-sync, not committed to project)
commands/br-*.md
rules/br-*.md
hooks/
CLAUDE.md
settings.local.json
IGNORE

# ── sync ─────────────────────────────────���───────────────────────
sync_br    "commands"  "br-*.md"
sync_br    "rules"     "br-*.md"
sync_file  "hooks/enforce-tools.py"
sync_file  "CLAUDE.md"
sync_file_once "settings.json"

# ── report ───────────────────────────────────────────────────────
echo ""
echo "build-rite → $(basename "$PROJECT_DIR")/.claude/"
echo "  version: $VERSION"
echo ""

[ ${#added[@]} -gt 0 ]   && { echo "  Added:";   printf '    + %s\n' "${added[@]}"; }
[ ${#updated[@]} -gt 0 ] && { echo "  Updated:"; printf '    ~ %s\n' "${updated[@]}"; }
[ ${#removed[@]} -gt 0 ] && { echo "  Removed:"; printf '    - %s\n' "${removed[@]}"; }
[ ${#current[@]} -gt 0 ] && { echo "  Current:"; printf '    · %s\n' "${current[@]}"; }

if [ ${#added[@]} -eq 0 ] && [ ${#updated[@]} -eq 0 ] && [ ${#removed[@]} -eq 0 ]; then
  echo "  Everything up to date."
fi

echo ""
echo "  Not managed: non-br-* commands, non-br-* rules, settings.json, settings.local.json"

if [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
  echo ""
  echo "  Next: run /br-discover to generate project CLAUDE.md"
fi
echo ""
