#!/usr/bin/env bash
# build-rite sync — copies harness into a project's .claude/
#
# Run:   curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash
# Alias: curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s -- --install-alias
#
# Harness owns (synced every run):  br-* commands, br-* rules, hooks, CLAUDE.md, statusline, settings.json
# Project owns (never touched):     non-br-* commands/rules, settings.local.json
# Generated (never touched):        project-root CLAUDE.md (from /br-init)

set -euo pipefail

REPO="${BUILD_RITE_REPO:-https://github.com/abhishekvm/build-rite.git}"
RAW_URL="${BUILD_RITE_RAW:-https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/build-rite"

# ── parse args ───────────────────────────────────────────────────────────────
MODE=sync
PROJECT_DIR=""
ARG_REF=""
UNPIN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --install-alias) MODE=install-alias; shift ;;
    --unpin) UNPIN=1; shift ;;
    --ref) ARG_REF="${2:-}"; shift 2 ;;
    --ref=*) ARG_REF="${1#--ref=}"; shift ;;
    -h|--help)
      echo "Usage: br-sync [<version>] [<project-dir>]"
      echo "       br-sync --unpin           # remove pin, follow main"
      echo "       br-sync --install-alias"
      echo ""
      echo "  br-sync 0.1.0      # pin this project to v0.1.0"
      echo "  br-sync v0.1.0     # same (v prefix optional)"
      echo "  br-sync main       # remove pin, follow main"
      echo "  br-sync            # use existing pin if set, else main"
      echo ""
      echo "Env: BUILD_RITE_REF (overrides pin), BUILD_RITE_REPO, BUILD_RITE_RAW"
      exit 0 ;;
    -*) echo "Unknown flag: $1" >&2; exit 1 ;;
    main|HEAD|latest) ARG_REF="main"; shift ;;
    v[0-9]*) ARG_REF="$1"; shift ;;
    [0-9]*) ARG_REF="v$1"; shift ;;
    *)
      if [ -d "$1" ] && [ -d "$1/.git" ]; then
        PROJECT_DIR="$1"
      else
        ARG_REF="$1"
      fi
      shift ;;
  esac
done

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

# ── install-alias ────────────────────────────────────────────────────────────
if [ "$MODE" = "install-alias" ]; then
  RC="$HOME/.zshrc"
  [ -n "${BASH_VERSION:-}" ] && [ ! -f "$HOME/.zshrc" ] && RC="$HOME/.bashrc"
  EXPECTED="alias br-sync='curl -sSf $RAW_URL | bash -s --'"
  if grep -qF "alias br-sync=" "$RC" 2>/dev/null; then
    if grep -qF "bash -s --" "$RC" 2>/dev/null; then
      echo "Alias 'br-sync' already in $RC (current version)"
    else
      echo "Alias 'br-sync' found in $RC but using old form (no positional version support)."
      echo "  Update it manually to:"
      echo "  $EXPECTED"
    fi
  else
    printf '\n# build-rite sync\n%s\n' "$EXPECTED" >> "$RC"
    echo "Added 'br-sync' to $RC — restart shell or: source $RC"
  fi
  echo ""
  echo "Usage:"
  echo "  cd your-project/ && br-sync                 # track main (or saved pin)"
  echo "  br-sync 0.1.0                               # pin this project to v0.1.0"
  exit 0
fi

# ── setup ────────────────────────────────────────────────────────────────────
[ -d "$PROJECT_DIR/.git" ] || { echo "Error: '$PROJECT_DIR' is not a git repo."; exit 1; }

TARGET="$PROJECT_DIR/.claude"
CHECKSUMS="$TARGET/.harness-checksums"
PIN_FILE="$TARGET/.br-pin"

# ── resolve ref ──────────────────────────────────────────────────────────────
# Precedence: --unpin > positional/--ref > pin file > BUILD_RITE_REF > main
PIN_CHANGED=""
if [ "$UNPIN" -eq 1 ]; then
  [ -f "$PIN_FILE" ] && { rm "$PIN_FILE"; PIN_CHANGED="removed"; }
  REF="main"
elif [ -n "$ARG_REF" ]; then
  REF="$ARG_REF"
  if [ "$REF" = "main" ]; then
    [ -f "$PIN_FILE" ] && { rm "$PIN_FILE"; PIN_CHANGED="removed"; }
  else
    mkdir -p "$TARGET"
    PREV=""
    [ -f "$PIN_FILE" ] && PREV=$(tr -d '[:space:]' < "$PIN_FILE")
    echo "$REF" > "$PIN_FILE"
    if [ "$PREV" != "$REF" ]; then
      [ -n "$PREV" ] && PIN_CHANGED="changed from $PREV → $REF" || PIN_CHANGED="set to $REF"
    fi
  fi
elif [ -f "$PIN_FILE" ]; then
  REF=$(tr -d '[:space:]' < "$PIN_FILE")
  [ -z "$REF" ] && REF="main"
elif [ -n "${BUILD_RITE_REF:-}" ]; then
  REF="$BUILD_RITE_REF"
else
  REF="main"
fi

# ── fetch + checkout ─────────────────────────────────────────────────────────
if [ -d "$CACHE_DIR/.git" ]; then
  echo "Updating cache..."
  git -C "$CACHE_DIR" fetch --tags --prune --quiet 2>/dev/null || { echo "  fetch failed — re-cloning"; rm -rf "$CACHE_DIR"; git clone --quiet "$REPO" "$CACHE_DIR"; }
else
  echo "Cloning build-rite..."
  git clone --quiet "$REPO" "$CACHE_DIR"
fi

git -C "$CACHE_DIR" checkout --quiet "$REF" 2>/dev/null || { echo "Error: ref '$REF' not found in $REPO"; exit 1; }
# Branches fast-forward; tags/commits stay at the pinned revision.
if git -C "$CACHE_DIR" symbolic-ref -q HEAD >/dev/null 2>&1; then
  git -C "$CACHE_DIR" pull --ff-only --quiet 2>/dev/null || true
fi

# ── newer-tag check ──────────────────────────────────────────────────────────
NEWER_TAGS=""
if [ "$REF" != "main" ]; then
  ALL_TAGS=$(git -C "$CACHE_DIR" tag -l "v*" | sort -V)
  # Strip leading v from REF if present, then compare normalized
  if echo "$ALL_TAGS" | grep -qx "$REF"; then
    NEWER_TAGS=$(echo "$ALL_TAGS" | awk -v cur="$REF" '$0 == cur {found=1; next} found && NF')
  fi
fi

SRC="$CACHE_DIR/.claude"
VERSION=$(git -C "$CACHE_DIR" log -1 --format='%h %s' 2>/dev/null || echo "unknown")
[ "$REF" != "main" ] && VERSION="$REF · $VERSION"

added=(); updated=(); current=(); removed=()

# ── helpers ──────────────────────────────────────────────────────────────────

checksum() { md5 -q "$1" 2>/dev/null || md5sum "$1" 2>/dev/null | awk '{print $1}'; }

# Return the last harness-written checksum for a target path, or empty string.
stored_checksum() {
  local tgt="$1"
  [ -f "$CHECKSUMS" ] || { echo ""; return; }
  grep -F "$tgt" "$CHECKSUMS" 2>/dev/null | awk '{print $1}' | tail -1 || echo ""
}

# Record that harness wrote src's checksum for tgt.
record_checksum() {
  local src="$1" tgt="$2"
  local sum; sum=$(checksum "$src")
  mkdir -p "$(dirname "$CHECKSUMS")"
  # Remove old entry for this tgt, append new one.
  local tmp; tmp=$(mktemp)
  grep -vF "$tgt" "$CHECKSUMS" 2>/dev/null > "$tmp" || true
  echo "$sum $tgt" >> "$tmp"
  mv "$tmp" "$CHECKSUMS"
}

# Copy src→tgt, track result.
# Pass --guard to auto-update if unmodified since last sync, prompt only if user-edited.
sync_file() {
  local guard=0
  [ "${1:-}" = "--guard" ] && { guard=1; shift; }
  local src="$1" tgt="$2" label="${3:-$2}"

  [ -f "$src" ] || return 0

  if [ ! -f "$tgt" ]; then
    mkdir -p "$(dirname "$tgt")"
    cp "$src" "$tgt"
    record_checksum "$src" "$tgt"
    added+=("$label"); return 0
  fi

  diff -q "$src" "$tgt" >/dev/null 2>&1 && { current+=("$label"); return 0; }

  if [ "$guard" -eq 0 ]; then
    cp "$src" "$tgt"
    record_checksum "$src" "$tgt"
    updated+=("$label"); return 0
  fi

  # Guard mode: check if local file is unmodified since last harness sync.
  local local_sum stored
  local_sum=$(checksum "$tgt")
  stored=$(stored_checksum "$tgt")

  if [ "$local_sum" = "$stored" ]; then
    # Unmodified — just update silently.
    cp "$src" "$tgt"
    record_checksum "$src" "$tgt"
    updated+=("$label"); return 0
  fi

  # User has edited the file — ask.
  printf "\n  Modified locally: %s\n" "$label" >/dev/tty
  printf "  (h)arness=overwrite / (k)eep local=skip [k]: " >/dev/tty
  local choice="k"
  read -r choice </dev/tty

  case "${choice:-k}" in
    h|H) cp "$src" "$tgt"; record_checksum "$src" "$tgt"; updated+=("$label (took harness)") ;;
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
mkdir -p "$TARGET"
cat > "$TARGET/.gitignore" <<'EOF'
# managed by br-sync — do not edit
commands/br-*.md
rules/br-*.md
reference/
hooks/
CLAUDE.md
settings.json
settings.local.json
statusline-command.sh
.harness-checksums
EOF

# ── sync ─────────────────────────────────────────────────────────────────────
sync_br   "commands"  "br-*.md"
sync_br   "rules"     "br-*.md"
sync_br   "reference" "*.md"
sync_file "$SRC/CLAUDE.md"               "$TARGET/CLAUDE.md"               "CLAUDE.md"
sync_file --guard "$SRC/settings.json" "$TARGET/settings.json" "settings.json"
sync_file --guard "$SRC/statusline-command.sh" "$TARGET/statusline-command.sh"          "statusline-command.sh"
sync_file --guard "$SRC/statusline-command.sh" "$HOME/.claude/statusline-command.sh"    "~/.claude/statusline-command.sh"

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

# Pin status
if [ "$REF" = "main" ]; then
  echo "  Tracking: main"
  [ "$PIN_CHANGED" = "removed" ] && echo "  Pin:      removed"
else
  echo "  Pinned:   $REF  (.claude/.br-pin)"
  [ -n "$PIN_CHANGED" ] && echo "  Pin:      $PIN_CHANGED"
  if [ -n "$NEWER_TAGS" ]; then
    LATEST=$(echo "$NEWER_TAGS" | tail -1)
    NEWER_INLINE=$(echo "$NEWER_TAGS" | tr '\n' ' ' | sed 's/ $//')
    echo "  Newer:    $NEWER_INLINE"
    echo "  Upgrade:  br-sync $LATEST"
  fi
fi

echo ""
echo "  Not managed: non-br-* commands/rules, settings.local.json"
[ ! -f "$PROJECT_DIR/CLAUDE.md" ] && echo "  Next: /br-init to generate project CLAUDE.md"
echo ""
