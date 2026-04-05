---
description: "Initialize project context → CLAUDE.md (greenfield + brownfield)"
---

# Init

Persona: Principal Engineer, day one. Read-only analysis — output is a project-root `CLAUDE.md` (and optional `rules/` files).

Parse `$ARGUMENTS`: Path → focus area · Text → concern · None → full scan

## 0. Worktree
Read `## Project Config` from project CLAUDE.md (if exists) for branch convention and default branch.
If missing: detect from `git branch -a`, use sensible defaults (`task/`, `main`).

Create a worktree for the discovery work:
```
git worktree add ../<repo>-refresh-claude-md -b <convention>/refresh-claude-md <default-branch>
```
Switch to the worktree directory for all subsequent work.

## 1. Scope
Glob top-level (ignore: `.git node_modules .venv __pycache__ dist build .next coverage tmp`).
≤5 dirs and none >200 files → scan all. Else → show list, ask.

**Detect mode:**
- **Greenfield** — repo contains only docs/specs/notes (`.md`, `.txt`, `.pdf`, diagrams) and no source code → follow §2a
- **Brownfield** — source code present → follow §2b

## 2a. Greenfield scan (silent)
Parse all docs: extract product intent, goals, constraints, tech choices mentioned, open questions.
Ask up to 3 clarifying questions to fill gaps (stack not decided, deployment target unclear, etc.).
Then extract:
- What needs to be built (features / components)
- Dependencies and sequencing between them
- Unknowns that block starting

## 2b. Brownfield scan (silent)
Extract: directory structure, languages/frameworks, entry points, data layer, architecture/cross-references, common commands (from Makefile/Justfile/package.json), key design decisions, deployment, testing, issue tracker (from `.github/`/CI), branch convention (from `git branch -a`).

## 3. Present
**Greenfield:**
- 5-bullet summary of what's being built
- Key open questions / gaps identified
- Proposed task list (ordered by dependency)
- Proposed CLAUDE.md sections

**Brownfield:**
- 5-bullet summary
- Top 3 architectural observations
- Proposed CLAUDE.md sections

If tracker not detected: ask. If branch convention not detected: ask.
Confirm before writing.

## 4. Write CLAUDE.md
**Hard limit: CLAUDE.md must be ≤200 lines.** This is the global context loaded every session — keep it lean.

**Brownfield structure** (adapt to project):
```
## Project Config
| Key | Value |
| Tracker | <type>:<id> |
| Branch convention | <prefix>/<slug> |
| Default branch | main/master |
| Branching mode | branch/worktree |

## Directory Map
| Directory | What lives here | Read when... |
(top-level directories only — no nested paths)

## Common Commands
| Task | Command |
| Build | <canonical build tool and command> |
| Lint | <linter + command> |
| Type check | <checker + command> |
| Test | <test runner + command> |
| Deploy | <deploy command if detected> |
(detect from Makefile/Justfile/package.json/pyproject.toml — be specific, not generic)

## Project Overview · ## Architecture · ## Key Design Decisions · ## Working Conventions
```

**Greenfield structure** (omit sections not yet decided):
```
## Project Config
| Key | Value |
| Tracker | <type>:<id> |
| Branch convention | <prefix>/<slug> |
| Default branch | main |
| Branching mode | branch/worktree |

## Project Overview
<what's being built and why — 2-3 sentences>

## Goals & Constraints
<key goals, non-goals, known constraints>

## Architecture Decisions
<decided stack / deployment / patterns — leave blank if not yet decided>

## Open Questions
<unresolved decisions that affect where to start>

## Task List
Ordered by dependency — use these as starting point for /br-plan or /br-impl:
1. <first task>
2. <second task>
…
```

**If content exceeds 200 lines:** split directory-specific detail into `.claude/rules/` files:
- Identify CLAUDE.md sections tied to a specific directory
- Move each to `.claude/rules/<topic>.md` with frontmatter: `paths: ["<directory>/**"]`
- These load only when working in matching directories — zero cost otherwise
- CLAUDE.md stays as the quick-reference map; rules files hold the deep detail
- Never use `br-` prefix for these files — that namespace is reserved for harness rules

**If subdirectory CLAUDE.md files exist:** respect the team's pattern, but flag if overkill relative to project/team size:
- More CLAUDE.md files than people can reasonably maintain → suggest consolidating into `.claude/rules/` with `paths:`
- Files with <10 lines → content belongs in root CLAUDE.md, not its own file
- Stale content (references removed code/dirs) → flag for cleanup

## 5. Git hooks audit (always run)
Check: does `.pre-commit-config.yaml`, `.husky/`, or `lefthook.yml` exist? Are hooks active in `.git/hooks/`?

**Pass:** hooks found and cover lint/format/type-check → note in next steps, no action needed.
**Fail:** linter/formatter/type-checker detected in step 2 AND no hooks found → surface as a finding, propose setup.

Be opinionated — pick one framework based on detected stack:
- Python → `pre-commit`
- Node/JS/TS → `husky` + `lint-staged`
- Polyglot/other → `lefthook`

Show a single ready-to-use config snippet covering:
- pre-commit: lint + type check + format
- pre-push: ask — "Include tests in pre-push hook?" (can slow push; team preference varies)

Ask: "Set up git hooks?" If yes → write config, install hooks, run a test commit to verify, confirm success.

## 6. Next steps
After all files are written, show:

```
Init complete. Files written in worktree:
  <list files created/modified>

Next steps:
  1. Review the changes: git diff
  2. Commit:  git add <files> && git commit -m "docs: init CLAUDE.md"
  3. Push + PR: git push -u origin <branch> && gh pr create --title "docs: init CLAUDE.md" --body "..."
  4. After merge, clean up: git worktree remove ../<worktree-dir>

Or I can do steps 2-3 for you — just say "commit and PR".
```

**Greenfield only — after merge:**
```
Ready to build. Suggested next command:
  /br-plan <first task from Task List>
```
