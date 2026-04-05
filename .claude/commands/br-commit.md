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
Never auto-stage — wait for confirmation.

## 2. Verify

Run lint and tests from `## Common Commands` in CLAUDE.md.

Show result as a summary block:
```
Checks
  Lint    ✓ clean          (or ✗ N errors — <first error>)
  Tests   ✓ N passed       (or ✗ N failed — <test name>)
```

If lint fails: fix, re-run, show updated summary.
If tests fail: stop — do not proceed to commit. Show failing test names and ask how to proceed.
If no test command configured: note it, continue.

## 3. Commit

Stage only the files specified (or confirmed in step 1).
Write commit message using format from `br-impl.md` §5, scaled to change size:
- Single file / small fix → `type(scope): summary` only
- Multi-file / meaningful change → add Problem + Solution lines

Get explicit user approval on the message before committing.
