---
description: "Scan codebase → project CLAUDE.md"
---

# Discover

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

## 2. Scan (silent)
Extract: directory structure, languages/frameworks, entry points, data layer, architecture/cross-references, common commands (from Makefile/Justfile/package.json), key design decisions, deployment, testing, issue tracker (from `.github/`/CI), branch convention (from `git branch -a`).

## 3. Present
- 5-bullet summary
- Top 3 architectural observations
- Proposed CLAUDE.md sections

If tracker not detected: ask. If branch convention not detected: ask.
Confirm before writing.

## 4. Write CLAUDE.md
**Hard limit: CLAUDE.md must be ≤200 lines.** This is the global context loaded every session — keep it lean.

Proven structure (adapt to project):
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

## 5. Suggest git hooks (optional)
If linter/type checker/formatter detected, suggest **git hooks** (not Claude hooks) for enforcement.
Be opinionated — pick one framework based on the detected stack:
- Python → `pre-commit`
- Node/JS/TS → `husky` + `lint-staged`
- Polyglot/other → `lefthook`

Show a single ready-to-use config snippet for pre-commit (lint + type check + format) and pre-push (test) if applicable. Don't write it.

## 6. Next steps
After all files are written, show:

```
Discovery complete. Files written in worktree:
  <list files created/modified>

Next steps:
  1. Review the changes: git diff
  2. Commit:  git add <files> && git commit -m "docs: refresh CLAUDE.md"
  3. Push + PR: git push -u origin <branch> && gh pr create --title "docs: refresh CLAUDE.md" --body "..."
  4. After merge, clean up: git worktree remove ../<worktree-dir>

Or I can do steps 2-3 for you — just say "commit and PR".
```
