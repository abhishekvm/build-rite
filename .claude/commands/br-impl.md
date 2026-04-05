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
If task involves UI/UX and `## Reference Apps` is NOT in project CLAUDE.md: ask once — "No reference apps locked yet — run `/br-inspire` first?" If user declines, proceed and never ask again this session.

**Session contract:**
- One issue at a time — never start the next until the current is committed
- Task is DONE only when acceptance criteria is met, suite is green, and commit is in
- If blocked: comment on the issue, skip to next, document before ending the session

## 2. Branch
From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.
- `branch` mode → `git checkout -b <convention>/<slug>` from default branch
- `worktree` mode → `git worktree add .worktrees/<slug> -b <convention>/<slug>`, then run:
  ```
  bash scripts/worktree-setup.sh .worktrees/<slug> . "<install-command>"
  ```
  where `<install-command>` is the install command from `## Common Commands` in CLAUDE.md (e.g. `uv sync`, `npm install`). Omit it if none is defined.

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

Ticket/Bug:        <ID> — <one-line description>
Business context:  <user impact, ROI, or outcome — skip for pure refactors>
Problem:           <what was broken or missing, engineering perspective>
Solution:          <what changed and why this approach>
Assumptions:       <non-obvious decisions>
Testing:           <commands, curl, UI steps to verify>
Follow-up:         <known gaps, todos, deferred work>
```

- Wrap body lines at 80 chars · blank line between title and body
- For small/single-file changes: title + problem + solution is enough
- For large/multi-area changes: full format; follow-up especially valuable
- No `br-`, `build-rite`, or harness internals anywhere
- Follow commit discipline in `br-commits.md` (explicit staging, approval gate)

**README check** — before raising a PR, check if `README.md` exists and if the implementation affects anything user-visible (new endpoint, new command, new config, changed behaviour, new dependency). If yes: ask "Update README?" — never auto-update. Skip for refactors, test-only changes, and internal-only changes.

**Changelog** — if `CHANGELOG.md` exists and the change is user-visible: ask "Add changelog entry?" Format: `- <type>: <one-line description>` under a `## Unreleased` section. Never auto-update.

Then ask: "Create a PR?" · "Mark <ticket> as done?" · "Update CLAUDE.md?" (if architecture changed)
Never auto-update — always ask.

**Demo offer** — after any task that touches user-facing behaviour (new endpoint, UI screen, state change, CLI command), ask:
```
Want a guided demo?
```
If yes: derive steps from `## Common Commands` in CLAUDE.md + the acceptance criteria just implemented.
Format: start command → what to run → what to observe → one edge case worth trying.

Trigger: new route, new screen, new CLI command, new WebSocket event, or user-visible state change.
Skip for: refactors, migrations, config changes, test-only commits.

**API docs nudge** — if a new route was added and `## API Docs` is in project CLAUDE.md: remind "Verify the new endpoint appears correctly in `/docs` — check the stack-appropriate annotation (response model, decorator, or schema) is present."

**Flow capture nudge** — for new UI screens only:
Check `## Visual Testing` in project CLAUDE.md.
- Configured → remind: "Add a flow file to `flows/` for this screen."
- Not configured → ask once: "No visual testing set up yet — want to? (`/br-init` can guide you.)"
  If user declines: stay silent for the rest of the session, never ask again.
  If `## Visual Testing` absent from CLAUDE.md entirely: skip — don't add friction to non-UI projects.
