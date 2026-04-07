---
description: "Branch → implement → verify → PR"
---

# Implement

Parse `$ARGUMENTS`: Ticket ID → fetch + look for plan in comments · Text → direct instructions · None → use `/br-plan` from this session

Read `## Project Config` from project CLAUDE.md for tracker, branch convention, default branch, branching mode.

## 1. Context
Resolve what to implement:
- **Ticket** → fetch content. Tickets may come from any source and format — extract intent, acceptance criteria, and relevant detail regardless of structure. Don't expect `/br-plan` output format.
- **Session plan** (from earlier `/br-plan`) → use it
- **Direct instructions** (text argument with clear steps) → use as-is
- **Insufficient info** (ticket too vague, no actionable steps, no argument) → ask:
  ```
  Not enough detail to start implementing. Options:
  1. Plan first (read-only analysis → concrete steps)
  2. Describe what you want and I'll implement ad-hoc

  Which approach?
  ```
  If user picks 1: run `/br-plan` inline (same logic, same output), then continue to step 2 after user confirms the plan.
  If user picks 2: get their description, confirm understanding, proceed.

Read project CLAUDE.md for architecture, conventions, commands.
Before writing any code, read the current state of affected files — do not assume structure from session history or prior context.

**Session contract:**
- One issue at a time — never start the next until the current is committed
- Task is DONE only when acceptance criteria is met, suite is green, and commit is in
- After each issue: show a brief summary (what changed, checks result, PR link) and wait for explicit "next" or "stop" from the user before proceeding — never auto-advance
- If blocked: comment on the issue with what's blocking, skip to next, document before ending the session

## 2. Branch

**This step is mandatory. Never write code before completing it.**

From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.

**Step 0 — Resolve base branch:**
Default: branch from the default branch in Project Config (`main` / `master`).
If the project uses a different convention (e.g., features from `develop`, hotfixes from `main`), the user will specify at task time. Don't assume — ask if unclear.

**Step 1 — Check working directory:**
- Run `git status --short`
- If uncommitted changes exist: stop and ask:
  ```
  Uncommitted changes detected:
    <list of files>
  A) Named stash and continue  →  git stash push -m "<task-slug>"
  B) Abort — let me handle them first
  ```
  Never proceed with a dirty working directory without confirmation.

**Step 2 — Sync base branch:**
```
git fetch origin <base-branch>
git branch -f <base-branch> origin/<base-branch>
```

**Step 3 — Branch or worktree:**
- `branch` mode → `git checkout -b <convention>/<slug> origin/<base-branch>`
- `worktree` mode — check for existing worktree at `.worktrees/<slug>` first:
  - **Not found** → `git worktree add .worktrees/<slug> -b <convention>/<slug> origin/<base-branch>`
  - **Found, branch already merged** → clean up automatically:
    ```
    git worktree remove .worktrees/<slug> --force
    git branch -d <convention>/<slug>
    ```
    Then recreate fresh.
  - **Found, branch not merged** → ask:
    ```
    Worktree .worktrees/<slug> already exists with unmerged changes.
    A) Remove and recreate (you'll lose unmerged work)
    B) Resume working in the existing worktree
    C) Abort
    ```
  After creating worktree:
  - Symlink gitignored config from main tree: `for f in .env .env.* *.local secrets.*; do [ -f "$f" ] && ln -s "$(pwd)/$f" .worktrees/<slug>/$f; done`
  - Run install command from `## Common Commands` (e.g. `cd .worktrees/<slug> && uv sync`). Skip if none defined.

Never work on the default branch.

## 3. Implement
Before starting: list the exact files you will touch and confirm with the user.
Only touch files on that list. Do not modify, delete, or refactor anything outside it — if a related change seems needed, surface it and ask first.
Never delete a file unless explicitly requested.
Commit at natural boundaries — small, focused checkpoints make rollback easy. These are working commits, not final history; `wip: <what changed>` message style is fine here.
Run lint/test from CLAUDE.md after each commit. Diagnose failures, don't blindly retry.

**Worktree git ops — always use `git -C <worktree-path>` instead of `cd <path> && git`:**
```
git -C /path/to/worktree add <files>
git -C /path/to/worktree commit -m "..."
git -C /path/to/worktree status
```
Compound `cd && git` commands trigger a security prompt regardless of permission settings.

## 4. Verify
Run automated checks from CLAUDE.md `## Common Commands` (lint, type check, test).
If checks fail: fix → re-run → up to 3 attempts. If still failing, stop and show the user what's broken.

After all checks complete, show a single summary block — never dump raw tool output:
```
Checks
  Lint    ✓ clean          (or ✗ 3 errors — <first error>)
  Types   ✓ clean          (or ✗ skipped — no type check configured)
  Tests   ✓ 42 passed      (or ✗ 2 failed — <test name>)
```
Raw output only on failure, and only the failing lines — not the full log.

## 4b. Smoke Test
Check `## Smoke Test` / `## Common Commands` in project CLAUDE.md first — explicit commands win.
If none configured: detect project shape and run the matching signal from `.claude/reference/smoke-tests.md`.
No signal match → skip with a note. On failure: show output, one obvious fix attempt, then stop.

## 5. Wrap up
Before pushing, squash all branch commits into one:
- **Guard:** confirm you are NOT on the default branch — never squash on main/master
- `git rebase -i <default-branch>` → squash to a single commit
- Write the commit message using the format below, scaled to change size

**Commit message format:**
```
<type>: <imperative summary>  (≤72 chars)

Problem:   <what was broken or missing>
Solution:  <what changed and why>
Testing:   <how to verify>
```

For large/multi-area changes, add: `Ticket:`, `Assumptions:`, `Follow-up:` as needed.
No `br-`, `build-rite`, or harness internals. Explicit staging, user approval before commit.

**Pre-PR checklist** — surface relevant items, skip silently if N/A. Never auto-update.
- PR body includes `Closes #<issue>` (or `Fixes` for bugs)
- README affected by user-visible change? → ask to update
- CHANGELOG exists + user-visible change? → ask for entry under `## Unreleased`
- New route + `## API Docs` configured? → remind about annotations
- New UI screen + `## Visual Testing` configured? → remind about flow file
- Architecture changed? → ask to update CLAUDE.md
- User-facing behaviour? → offer guided demo

Then ask: "Create a PR?" · "Deploy? → `/br-deploy <env>`" (if configured)

**Session wrap-up** — more issues in batch? → next. Batch complete? → brief summary of shipped/carried-over, ask about filing carried-over items.
