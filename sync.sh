#!/usr/bin/env bash
# build-rite sync — copies harness into a project's .claude/
#
# Run:   curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash
# Alias: curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s -- --install-alias
#
# Harness owns (synced every run):  br-* commands, br-* rules, hooks, CLAUDE.md, statusline
# Project owns (never touched):     non-br-* commands/rules, settings.json, settings.local.json
# Generated (never touched):        project-root CLAUDE.md (from /br-discover)

set -euo pipefail

REPO="${BUILD_RITE_REPO:-https://github.com/abhishekvm/build-rite.git}"
RAW_URL="${BUILD_RITE_RAW:-https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/build-rite"

# ── install-alias ────────────────────────────────────────────────────────────
if [ "${1:-}" = "--install-alias" ]; then
  RC="$HOME/.zshrc"
  [ -n "${BASH_VERSION:-}" ] && [ ! -f "$HOME/.zshrc" ] && RC="$HOME/.bashrc"
  if grep -qF "br-sync" "$RC" 2>/dev/null; then
    echo "Alias 'br-sync' already in $RC"
  else
    printf '\n# build-rite sync\nalias br-sync='\''curl -sSf %s | bash'\''\n' "$RAW_URL" >> "$RC"
    echo "Added 'br-sync' to $RC — restart shell or: source $RC"
  fi
  echo "Usage: cd your-project/ && br-sync"
  exit 0
fi

# ── setup ────────────────────────────────────────────────────────────────────
PROJECT_DIR="${1:-$(pwd)}"
[ -d "$PROJECT_DIR/.git" ] || { echo "Error: '$PROJECT_DIR' is not a git repo."; exit 1; }

TARGET="$PROJECT_DIR/.claude"

if [ -d "$CACHE_DIR/.git" ]; then
  echo "Updating cache..."
  git -C "$CACHE_DIR" pull --quiet 2>/dev/null || { echo "  pull failed — re-cloning"; rm -rf "$CACHE_DIR"; git clone --quiet "$REPO" "$CACHE_DIR"; }
else
  echo "Cloning build-rite..."
  git clone --quiet "$REPO" "$CACHE_DIR"
fi

SRC="$CACHE_DIR/.claude"
VERSION=$(git -C "$CACHE_DIR" log -1 --format='%h %s' 2>/dev/null || echo "unknown")

added=(); updated=(); current=(); removed=()

# ── helpers ──────────────────────────────────────────────────────────────────

# Copy src→tgt, track result. Pass --conflict to prompt instead of overwriting on diff.
sync_file() {
  local conflict=0
  [ "${1:-}" = "--conflict" ] && { conflict=1; shift; }
  local src="$1" tgt="$2" label="${3:-$2}"

  [ -f "$src" ] || return 0

  if [ ! -f "$tgt" ]; then
    mkdir -p "$(dirname "$tgt")"
    cp "$src" "$tgt"
    added+=("$label"); return 0
  fi

  diff -q "$src" "$tgt" >/dev/null 2>&1 && { current+=("$label"); return 0; }

  if [ "$conflict" -eq 0 ]; then
    cp "$src" "$tgt"
    updated+=("$label"); return 0
  fi

  echo ""
  echo "  Conflict: $tgt"
  diff --unified=3 "$src" "$tgt" | head -40 | sed 's/^/    /'
  echo ""

  local choice="k"
  [ -t 0 ] && { printf "  (h)arness / (k)eep local / (s)kip [k]: "; read -r choice </dev/tty; }

  case "${choice:-k}" in
    h|H) cp "$src" "$tgt"; updated+=("$label (took harness)") ;;
    s|S) current+=("$label (skipped)") ;;
      *) current+=("$label (kept local)") ;;
  esac
}

# Sync br-* files in a subdir, remove stale ones from target.
sync_br() {
  local subdir="$1" glob="$2"
  local src_dir="$SRC/$subdir" tgt_dir="$TARGET/$subdir"
  mkdir -p "$tgt_dir"
  for f in "$src_dir"/$glob; do
    [ -f "$f" ] || continue
    local name; name=$(basename "$f")
    sync_file "$f" "$tgt_dir/$name" "$subdir/$name"
  done
  for f in "$tgt_dir"/br-*; do
    [ -f "$f" ] || continue
    local name; name=$(basename "$f")
    [ -f "$src_dir/$name" ] && continue
    rm "$f"; removed+=("$subdir/$name")
  done
}

# Copy only if target doesn't exist yet (project-owned).
sync_once() {
  local rel="$1"
  [ -f "$TARGET/$rel" ] && { current+=("$rel (project-owned)"); return 0; }
  [ -f "$SRC/$rel" ] || return 0
  mkdir -p "$(dirname "$TARGET/$rel")"
  cp "$SRC/$rel" "$TARGET/$rel"
  added+=("$rel")
}

# ── .gitignore ───────────────────────────────────────────────────────────────
cat > "$TARGET/.gitignore" <<'EOF'
# managed by br-sync — do not edit
commands/br-*.md
rules/br-*.md
hooks/
CLAUDE.md
settings.local.json
statusline-command.sh
EOF

# ── sync ─────────────────────────────────────────────────────────────────────
sync_br   "commands" "br-*.md"
sync_br   "rules"    "br-*.md"
sync_file "$SRC/hooks/enforce-tools.py"  "$TARGET/hooks/enforce-tools.py"  "hooks/enforce-tools.py"
sync_file "$SRC/CLAUDE.md"               "$TARGET/CLAUDE.md"               "CLAUDE.md"
sync_once "settings.json"
sync_file --conflict "$SRC/statusline-command.sh" "$TARGET/statusline-command.sh"          "statusline-command.sh"
sync_file --conflict "$SRC/statusline-command.sh" "$HOME/.claude/statusline-command.sh"    "~/.claude/statusline-command.sh"

# ── report ───────────────────────────────────────────────────────────────────
echo ""
echo "build-rite → $(basename "$PROJECT_DIR")/.claude/  ($VERSION)"
echo ""
[ ${#added[@]}   -gt 0 ] && { echo "  Added:";   printf '    + %s\n' "${added[@]}"; }
[ ${#updated[@]} -gt 0 ] && { echo "  Updated:"; printf '    ~ %s\n' "${updated[@]}"; }
[ ${#removed[@]} -gt 0 ] && { echo "  Removed:"; printf '    - %s\n' "${removed[@]}"; }
[ ${#current[@]} -gt 0 ] && { echo "  Current:"; printf '    · %s\n' "${current[@]}"; }
[ ${#added[@]} -eq 0 ] && [ ${#updated[@]} -eq 0 ] && [ ${#removed[@]} -eq 0 ] && echo "  Everything up to date."
echo ""
echo "  Not managed: non-br-* commands/rules, settings.json"
[ ! -f "$PROJECT_DIR/CLAUDE.md" ] && echo "  Next: /br-discover to generate project CLAUDE.md"
echo ""
