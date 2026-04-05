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

## 2. Secret scan
Before staging, scan diff for secret patterns — stop and warn if found:
- Hardcoded keys/tokens: `sk-`, `-----BEGIN`, `ghp_`, `AKIA` (AWS), `xox` (Slack)
- Assignments: `password =`, `secret =`, `token =`, `api_key =` with a literal string value
- If found: show the line, refuse to stage, ask user to move to env var

## 3. Verify

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

Follow `br-commits.md` — explicit file staging, approval gate, one commit per task.
Write commit message using format from `br-impl.md` §5, scaled to change size:
- Single file / small fix → `type(scope): summary` only
- Multi-file / meaningful change → add Problem + Solution lines
