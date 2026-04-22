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

From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.

**Step 0 — Resolve base branch:**
Default to the Project Config default branch. If the project uses a different convention (e.g., features from `develop`, hotfixes from `main`), ask if unclear.

**Step 1 — Check working directory:**
- Run `git status --short`
- If uncommitted changes exist: stop and ask:
  ```
  Uncommitted changes detected:
    <list of files>
  A) Named stash and continue  →  git stash push -m "<task-slug>"
  B) Abort — let me handle them first
  ```

**Step 2 — Sync base branch:**
```
git fetch origin <base-branch>
```

**Step 3 — Branch or worktree:**
- `branch` mode → `git checkout -b <convention>/<slug> origin/<base-branch>`
- `worktree` mode → call `EnterWorktree` with `name: <convention>/<slug>`. After entering, run the install command from `## Common Commands` using the worktree path — never `cd && cmd`:
  - uv: `uv sync --project "$WPATH"`
  - npm/pnpm/yarn: `npm --prefix "$WPATH" install`
  - pip: `pip install -r "$WPATH/requirements.txt"`
  - Skip if no install command defined.

Never work on the default branch.

## 3. Implement
Before starting: list the exact files you will touch and confirm with the user.
Only touch files on that list. Do not modify, delete, or refactor anything outside it — if a related change seems needed, surface it and ask first.
Never delete a file unless explicitly requested.
Commit at natural boundaries — small, focused checkpoints make rollback easy. These are working commits, not final history; `wip: <what changed>` message style is fine here.
Run lint/test from CLAUDE.md after each commit. Diagnose failures, don't blindly retry.

**Adding dependencies — always use the package manager CLI, never edit the manifest directly:**
- uv: `uv add --project "$WPATH" <package>`
- npm/pnpm/yarn: `npm --prefix "$WPATH" install <package>`
- pip: `pip install <package>` then `pip freeze` — but prefer uv/poetry if configured
Editing `pyproject.toml`, `package.json`, or `requirements.txt` by hand to add deps is not allowed — the lockfile won't update and installs will be inconsistent.

**Worktree mode:** resolve `WPATH=$(git rev-parse --show-toplevel)/.worktrees/<slug>` once, then pass it to every command via the tool's project/prefix flag (`git -C`, `uv --project`, `npm --prefix`, `PYTHONPATH=`). Never `cd <path> && cmd`.

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

## 4c. Simplify
After checks pass, run `/simplify` on the changed files. Fix findings before proceeding.

## 5. Wrap up
Before pushing, squash all branch commits into one:
- **Guard:** confirm you are NOT on the default branch — never squash on main/master
- `git rebase -i <default-branch>` → squash to a single commit
- Write the commit message using the **Commit message format** from `.claude/CLAUDE.md`, scaled to change size.

**Pre-PR checklist** — surface relevant items, skip silently if N/A.
- PR body includes `Closes #<issue>` (or `Fixes` for bugs)
- README affected by user-visible change? → ask to update
- CHANGELOG exists + user-visible change? → ask for entry under `## Unreleased`
- New route + `## API Docs` configured? → remind about annotations
- New UI screen + `## Visual Testing` configured? → remind about flow file
- Architecture changed? → ask to update CLAUDE.md
- User-facing behaviour? → offer guided demo

Then ask: "Create a PR?" — if yes, draft the PR title and body and **show them in full before running `gh pr create`**. Wait for explicit approval (edits welcome). Then offer: "Deploy? → `/br-deploy <env>`" (if configured) · "After the PR merges, run `/br-cleanup` to close issues and delete the local branch."

**Session wrap-up** — more issues in batch? → next. Batch complete? → brief summary of shipped/carried-over, ask about filing carried-over items.
