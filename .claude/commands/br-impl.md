---
description: "Branch → implement → verify → draft PR"
argument-hint: "[ticket-id | instructions]"
disable-model-invocation: true
---

# Implement

Parse `$ARGUMENTS`: ticket ID → fetch it (any tracker or format — extract intent and acceptance criteria) plus any plan in its comments · text → direct instructions · none → the plan from this session. Too vague to act on → offer: plan first (read `.claude/commands/br-plan.md` and follow it inline — you can't invoke `/br-plan`), or take a description and go.

## 0. Recall
`mempalace search "<ticket or topic>"` per **Memory** in `.claude/CLAUDE.md`, then read `## Project Config` (tracker, branch convention, default/hotfix branch, branching mode) and the project CLAUDE.md, and the current state of affected files before editing.

**Session contract** — one issue at a time; done = acceptance criteria met, suite green, committed, and for a delivery story its demo steps pass (see `.claude/reference/delivery.md`). After each: brief summary (changed, checks, PR link), then wait for "next" or "stop". Blocked → draft a comment saying why, show it, post only on approval, stop. Unattended or fanned out → `.claude/reference/unattended.md`'s needs-you list replaces the wait and the stop.

## 1. Branch
- **Base** — the default branch; production fixes from `Hotfix branch` when configured; ask if the convention is unclear. An open PR already covers this (`gh pr list --search "<keywords>" --state open`) → stack on it. IaC repo → also stack on open PRs already applied to the target environment, or the plan will revert them.
- **Dirty tree** (`git status --short`) → offer `git stash push -m "<slug>"`, or stop.
- `git fetch origin <base>`, then:
  - `branch` mode → `git checkout -b <convention>/<slug> --no-track origin/<base>`
  - `worktree` mode → `git worktree add "<root>/.claude/worktrees/<slug>" -b <convention>/<slug> --no-track origin/<base>` (`<root>` = the main checkout: `git rev-parse --path-format=absolute --git-common-dir` minus its trailing `/.git`, spelled out — so a second worktree doesn't nest inside the first). Copy the gitignored harness in without overwriting: `rsync -a --ignore-existing --exclude worktrees/ "<root>/.claude/" "<root>/.claude/worktrees/<slug>/.claude/"`. Then `EnterWorktree` with that absolute `path` (`name:` would ignore `<base>`) and run the install command from `## Common Commands`.
- Never work on the default branch. `--no-track` keeps a bare `git push` off `<base>`.

## 2. Implement
State the files you'll touch in one line, then start; ask before touching others; never delete a file unless asked. Commit at natural boundaries (`wip:` is fine) and run lint/test after each — diagnose failures, don't blindly retry. Keep to one slice per PR (**Scope** in `.claude/CLAUDE.md`).
- **Several independent stories** → parallel workers per `.claude/reference/unattended.md`; only the story that unblocks the others runs inline.
- **Design checkpoint** — an item that fits no existing ADR or architecture → stop on that item, propose the ADR with a recommended option, and keep building the items that don't depend on the answer.
- **Porting or replacing a component** — carry over only what callers and deploy config use (grep first) and list what was dropped.
- **Performance changes** — measure the slow path's end-to-end cost in the real request or job before opening the PR.
- **Dependencies** — only via the package manager CLI (`uv add`, `npm install <pkg>`); never hand-edit `pyproject.toml` / `package.json`.

## 3. Verify
- Checks from `## Common Commands` (lint, types, tests), plus the Deps audit when a manifest or lockfile changed. Failing → fix and re-run, up to 3 attempts, then stop and show what's broken. Report with the template in `.claude/reference/checks.md`; raw output only for failures.
- **Smoke test** — `## Smoke Test` in project CLAUDE.md wins; else the matching signal in `.claude/reference/smoke-tests.md`; no match → skip with a note.
- **Self-review** — read `.claude/commands/br-review.md` and follow its **Loop mode** on the branch (you can't invoke `/br-review`): review → fix → re-review until clean, closing with `ponytail-audit`. List each finding with its State in the wrap-up.
- **Proof** — per **Proof** in `.claude/reference/checks.md`.
- **Demo** — delivery story: run its demo steps against what's running locally and report each one; they're run again on the deployed environment before the story is done.

## 4. Wrap up
- Base moved? `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` and `git fetch origin <base>` — if the default changed or the base advanced, merge it in and re-run the checks.
- Push with `git push -u origin <branch>` — no local squash; `/br-cleanup` squash-merges with the PR title/body. Then say "Pushed `<branch>` at `<short-sha>`".
- **Pre-PR checklist** (skip silently if N/A): ticket referenced in the tracker's syntax (`gh:` → `Closes #<n>` / `Fixes #<n>`; others → the ticket ID) · README or CHANGELOG (`## Unreleased`) for user-visible changes · `## API Docs` annotations for new routes · CLAUDE.md if the architecture changed · a hard-to-reverse decision made or changed → the ADR is written or updated in this PR, with a History line (`.claude/reference/delivery.md`).
- "Open draft PR?" → show the title (≤72 chars, imperative) and body (**Commit message format** in `.claude/CLAUDE.md`) in full; on approval `gh pr create --draft --base <base>`. The user flips it ready.
- Next: after merge, `/br-cleanup` (`/br-review <PR#>` only if commits landed after the self-review). Batch done → summary of shipped and carried-over items.
