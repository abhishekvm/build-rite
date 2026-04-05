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

**Session contract:**
- One issue at a time — never start the next until the current is committed
- Task is DONE only when acceptance criteria is met, suite is green, and commit is in
- If blocked: comment on the issue, skip to next, document before ending the session

## 2. Branch
From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.
- `branch` mode → `git checkout -b <convention>/<slug>` from default branch
- `worktree` mode → `git worktree add .worktrees/<slug> -b <convention>/<slug>`
Never work on the default branch.

## 3. Implement
Step by step. Only touch files listed in the plan — if you need to modify something unplanned, flag it and get approval first.
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
Check `## Smoke Test` / `## Common Commands` in project CLAUDE.md first — explicit commands win. Otherwise detect shape and run:

| Signal | What to run |
|--------|-------------|
| `*.tf` files | `terraform validate && terraform plan` — flag unexpected destroys, no apply |
| `cdk.json` | `cdk synth && cdk diff` — flag unexpected removals |
| Monorepo (`pnpm-workspace`, `nx.json`, `packages/`, `apps/`) | Start only affected packages → E2E flow from acceptance criteria → tear down |
| `docker-compose*.yml` | `docker compose up -d <affected>` → smoke → `docker compose down` |
| HTTP server | Start server → curl changed endpoints → check status + shape → stop |
| Frontend | Run `build` — confirm zero errors |
| Library / CLI | `node -e "require('./dist')"` or equivalent |

No signal + no CLAUDE.md guidance → skip with a note. On failure: show output, one obvious fix attempt, then stop — do not proceed to wrap-up.

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
