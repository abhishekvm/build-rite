---
description: "Branch → implement → verify → PR"
argument-hint: "[ticket-id | instructions]"
disable-model-invocation: true
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
  If user picks 1: read `.claude/commands/br-plan.md` and follow it inline (you can't invoke `/br-plan` yourself), then continue to step 2 after user confirms the plan.
  If user picks 2: get their description, confirm understanding, proceed.

Read project CLAUDE.md for architecture, conventions, commands.
Before writing any code, read the current state of affected files — do not assume structure from session history or prior context.

**Session contract:**
- One issue at a time — never start the next until the current is committed
- Task is DONE only when acceptance criteria is met, suite is green, and commit is in
- After each issue: show a brief summary (what changed, checks result, PR link) and wait for explicit "next" or "stop" from the user before proceeding — never auto-advance
- If blocked: draft a comment saying what blocks it, show it, post only on approval, then stop and wait for "next" or "stop"

## 2. Branch

From Project Config. If missing: detect from `git branch -a`, ask, suggest adding to config.

**Step 0 — Resolve base branch:**
Default to the Project Config default branch. Production fixes branch from `Hotfix branch` when configured. If the project uses a different convention (e.g., features from `develop`), ask if unclear.
Check for an open PR already covering this work (`gh pr list --search "<keywords>" --state open`). If one exists, stack on it instead of starting fresh.

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
- `branch` mode → `git checkout -b <convention>/<slug> --no-track origin/<base-branch>`
- `worktree` mode → `git worktree add "<root>/.claude/worktrees/<slug>" -b <convention>/<slug> --no-track origin/<base-branch>` (`<root>` = `git rev-parse --show-toplevel`). The harness files are gitignored, so copy them in without overwriting: `rsync -a --ignore-existing --exclude worktrees/ "<root>/.claude/" "<root>/.claude/worktrees/<slug>/.claude/"`. Then call `EnterWorktree` with that absolute `path` (with `name:` it would branch from the default branch, not `<base-branch>`). The session now runs inside the worktree — run the install command from `## Common Commands` as-is. Skip if none defined.

`--no-track` keeps a bare `git push` from targeting `<base-branch>`; push with `git push -u origin <branch>`.

Never work on the default branch.

## 3. Implement
State the files you'll touch in one line, then start. Touch only those — surface related changes and ask first; never delete a file unless asked.
Commit at natural boundaries (`wip: <what>` is fine — these aren't final history). Run lint/test from CLAUDE.md after each; diagnose failures, don't blindly retry.

**Performance changes** — before opening the PR, measure what the slow path costs end-to-end in the real request or job. A faster loop inside a slow request is a guess until that number says it matters.

**Dependencies** — always via the package manager CLI (`uv add`, `npm install <pkg>`), never by hand-editing `pyproject.toml`/`package.json` — the lockfile won't update.

## 4. Verify
Run automated checks from CLAUDE.md `## Common Commands` (lint, type check, test), plus the **Deps** audit from `.claude/CLAUDE.md` when the diff touches a manifest or lockfile.
If checks fail: fix → re-run → up to 3 attempts. If still failing, stop and show the user what's broken.

After all checks complete, show a single summary block using `## Check output template` from `.claude/CLAUDE.md` (Lint + Types + Tests rows). Never dump raw tool output. Raw output only on failure, and only the failing lines — not the full log.

## 4b. Smoke Test
Check `## Smoke Test` / `## Common Commands` in project CLAUDE.md first — explicit commands win.
If none configured: detect project shape and run the matching signal from `.claude/reference/smoke-tests.md`.
No signal match → skip with a note. On failure: show output, one obvious fix attempt, then stop.

## 4c. Self-review
After checks pass, run the `simplify` skill on the change (reuse, simplification, efficiency, altitude — it applies the fixes), then re-run the checks if it changed anything. Leave judgment calls for the review step.

## 5. Wrap up
Push the feature branch as-is — don't squash locally. `/br-cleanup` uses the PR title/body as the squash commit message, so write the PR body in **Commit message format** from `.claude/CLAUDE.md` (scaled to change size).

**Pre-PR checklist** — surface relevant items, skip silently if N/A.
- PR body references the ticket in the tracker's syntax (`gh:` → `Closes #<issue>`, or `Fixes` for bugs; others → the ticket ID) so `/br-cleanup` can find it
- README affected by user-visible change? → ask to update
- CHANGELOG exists + user-visible change? → ask for entry under `## Unreleased`
- New route + `## API Docs` configured? → remind about annotations
- New UI screen + `## Visual Testing` configured? → remind about flow file
- Architecture changed? → ask to update CLAUDE.md
- User-facing behaviour? → offer guided demo

Then ask: "Open draft PR?" — if yes, draft the PR title (≤72 chars, imperative) and body (Problem / Solution / Testing per **Commit message format**) and **show them in full before running `gh pr create --draft --base <base-branch>`**. Wait for explicit approval (edits welcome). Always draft — the user flips ready manually after self-review.

After the draft PR is up, suggest next steps: "Self-review with `/br-review <PR#>`" · "After PR merges, `/br-cleanup` closes issues and deletes the branch."

**Session wrap-up** — more issues in batch? → next. Batch complete? → brief summary of shipped/carried-over, ask about filing carried-over items.
