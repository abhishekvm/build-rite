---
description: "Stage → verify → commit (ad-hoc changes, enforces best practices)"
---

# Commit

Parse `$ARGUMENTS`: file paths → stage those files · message hint → use as commit summary · None → infer from diff

## 1. Guard rails

**Branch check** — refuse if on default branch:
```
⛔ You're on main. Create a branch first:
   git checkout -b <type>/<slug>
```

**Staged diff check** — if nothing staged and no arguments, show what's changed and ask:
```
Nothing staged. Stage these files?
  <list of modified files>
```

## 2. Secret scan
Before staging, scan diff against the **Secret patterns** in `.claude/CLAUDE.md` — if any match, show the line, refuse to stage, and ask the user to move the value to an env var.

## 3. Verify

Run lint and tests from `## Common Commands` in CLAUDE.md.

Show result using `## Check output template` from `.claude/CLAUDE.md` (Lint + Tests rows).

If lint fails: fix, re-run, show updated summary.
If tests fail: stop — do not proceed to commit. Show failing test names and ask how to proceed.
If no test command configured: note it, continue.

## 3. Commit

One commit per logical change. Use the **Commit message format** from `.claude/CLAUDE.md`, scaled to change size.

Show the staged files and full commit message before running `git commit`. Wait for explicit "go".
