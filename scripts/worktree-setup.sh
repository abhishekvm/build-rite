#!/usr/bin/env bash
# worktree-setup.sh — prepare a git worktree for development
#
# Usage: worktree-setup.sh <worktree-path> <main-tree-path> [install-command]
#
# What it does:
#   1. Symlinks gitignored runtime config files (.env*, *.local, secrets.*)
#      from the main tree into the worktree so the app can run
#   2. Runs the install command (if provided) to recreate .venv / node_modules

set -euo pipefail

WORKTREE="${1:?Usage: worktree-setup.sh <worktree-path> <main-tree-path> [install-command]}"
MAIN_TREE="${2:?Usage: worktree-setup.sh <worktree-path> <main-tree-path> [install-command]}"
INSTALL_CMD="${3:-}"

# Resolve absolute paths
WORKTREE=$(cd "$WORKTREE" && pwd)
MAIN_TREE=$(cd "$MAIN_TREE" && pwd)

echo "Setting up worktree: $WORKTREE"

# ── 1. Symlink gitignored config files ───────────────────────────────────────
CONFIG_PATTERNS=(".env" ".env.*" "*.local" "secrets.*" ".secrets")
linked=()
skipped=()

for pattern in "${CONFIG_PATTERNS[@]}"; do
  for file in "$MAIN_TREE"/$pattern; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    target="$WORKTREE/$name"

    if [ -e "$target" ] || [ -L "$target" ]; then
      skipped+=("$name (already exists)")
      continue
    fi

    ln -s "$file" "$target"
    linked+=("$name")
  done
done

if [ ${#linked[@]} -gt 0 ]; then
  echo "  Symlinked config:"
  printf '    + %s\n' "${linked[@]}"
fi
if [ ${#skipped[@]} -gt 0 ]; then
  echo "  Skipped:"
  printf '    · %s\n' "${skipped[@]}"
fi
if [ ${#linked[@]} -eq 0 ] && [ ${#skipped[@]} -eq 0 ]; then
  echo "  No gitignored config files found in main tree."
fi

# ── 2. Install dependencies ───────────────────────────────────────────────────
if [ -n "$INSTALL_CMD" ]; then
  echo "  Running: $INSTALL_CMD"
  (cd "$WORKTREE" && eval "$INSTALL_CMD")
  echo "  Install complete."
else
  echo "  No install command provided — skipping dependency install."
fi

echo "Done."
