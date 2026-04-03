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

## 2. Branch
From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.
- `branch` mode → `git checkout -b <convention>/<slug>` from default branch
- `worktree` mode → `git worktree add ../<repo>-<slug> -b <convention>/<slug>`
Never work on the default branch.

## 3. Implement
Step by step. Only touch files listed in the plan — if you need to modify something unplanned, flag it and get approval first.
Commit at natural boundaries. Run lint/test from CLAUDE.md after each commit. Diagnose failures, don't blindly retry.

## 4. Verify
Run automated checks from CLAUDE.md `## Common Commands` (lint, type check, test).
If checks fail: fix → re-run → up to 3 attempts. If still failing, stop and show the user what's broken.
User-facing changes: suggest concrete verification steps (console commands, curl examples, UI steps).

## 5. Wrap up
- "Create a PR?" · "Mark <ticket> as done?" · "Update CLAUDE.md?" (if architecture changed)
Never auto-update — always ask.
