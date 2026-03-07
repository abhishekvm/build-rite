---
description: "Branch → implement → verify → PR"
---

# Implement

Parse `$ARGUMENTS`: Ticket ID → fetch + look for plan in comments · Text → ad-hoc · None → use `/br-plan` from this session

Read `## Project Config` from project CLAUDE.md for tracker, branch convention, default branch, branching mode.

## 1. Context
Ticket → fetch + use plan if commented. Session plan → use it. Ad-hoc → form 3-5 step plan, confirm.
Read project CLAUDE.md for architecture, conventions, commands.

## 2. Branch
From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.
- `branch` mode → `git checkout -b <convention>/<slug>` from default branch
- `worktree` mode → `git worktree add ../<repo>-<slug> -b <convention>/<slug>`
Never work on the default branch.

## 3. Implement
Step by step. Verify each step. Commit at natural boundaries. Run lint/test from CLAUDE.md. Diagnose failures, don't blindly retry.

## 4. Verify
```
**What to try:**
- <concrete command/URL>

**Automated checks:**
- <lint/test commands from CLAUDE.md>

Run checks for you, or verify manually first?
```
User-facing changes: suggest console commands, curl examples, or UI steps for E2E verification.

## 5. Wrap up
- "Create a PR?" · "Mark <ticket> as done?" · "Update CLAUDE.md?" (if architecture changed)
Never auto-update — always ask.
