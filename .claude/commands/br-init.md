---
description: "Initialize project context → CLAUDE.md with Project Config (greenfield + brownfield)"
argument-hint: "[path | focus-area]"
disable-model-invocation: true
---

# Init

Output: a project-root `CLAUDE.md` with `## Project Config` (read by every br-* command), plus optional `.claude/rules/` files.

Parse `$ARGUMENTS`: Path → focus area · Text → concern · None → full scan

## 0. Branch
Read `## Project Config` from project CLAUDE.md (if exists) for branch convention and default branch.
If missing: detect from `git branch -a`, use sensible defaults (`task/`, `main`).
```
git checkout -b <convention>/refresh-claude-md --no-track origin/<default-branch>
```
No remote yet (`git rev-parse --verify -q origin/<default-branch>` fails) → branch from `HEAD` instead.

## 1. Generate
- **Brownfield** (source code present) → run the `init` skill. It scans the repo and writes or improves `CLAUDE.md` (overview, commands, architecture, conventions).
- **Greenfield** (only docs/specs/notes) → parse the docs for intent, constraints, tech choices and open questions; ask up to 3 clarifying questions. Write only the decided sections, plus `## Task List` ordered by dependency.

## 2. Project Config
Detect what you can (`git branch -a`, `.github/`, remotes, tracker references), ask for the rest, and put this at the top of `CLAUDE.md`:
```
## Project Config
| Key | Value |
| Tracker | <type>:<id> |
| Branch convention | <prefix>/<slug> |
| Default branch | main/master |
| Hotfix branch | <branch> (optional — base for production fixes) |
| Branching mode | branch/worktree |
```
Then tighten the file:
- **Common Commands** — Justfile > Makefile > package.json scripts > raw commands. Point at `just <recipe>` / `make <target>`; never enumerate every recipe. No task runner → offer a Justfile with lint/test recipes.
- **≤200 lines** — move directory-specific detail to `.claude/rules/<topic>.md` with `paths: ["<dir>/**"]` (never the `br-` prefix — reserved for the harness). Flag subdirectory CLAUDE.md files under 10 lines or with stale content.

## 3. Stack file
Ask, then write `.claude/rules/stack.md` (project-owned) with only the sections that exist: Backend / Frontend (runtime + package manager, framework, test, lint), Data (DB, migrations), Editor, and **Do NOT Use** (forbidden library or tool — with reason).

## 4. Gaps
Surface what's missing; the user picks. Skip silently if already configured.

| Gap | Detection | Action |
|-----|-----------|--------|
| No linter config | Python: no `ruff.toml`/`[tool.ruff]` · JS/TS: no `eslint.config.*` | Generate config for the stack |
| No git hooks | No `.pre-commit-config.yaml`, `.husky/`, `lefthook.yml` | Scaffold pre-commit lint/format/typecheck |
| No dependency alerts | GitHub repo with Dependabot alerts off | Offer to enable them and to add the **Deps** audit to CI |
| No API docs | REST API, no `## API Docs` in CLAUDE.md | Set up Scalar/Swagger, then add `## API Docs` (docs URL + tool) |
| README missing/empty | Missing or ≤5 lines | Scaffold from the project overview (≤50 lines) |

## 5. Next steps
```
Init complete. Files written:
  <list files created/modified>

Next: "commit and PR" or review with git diff first.
```
Greenfield, after merge: `/br-plan <first task from Task List>`.
