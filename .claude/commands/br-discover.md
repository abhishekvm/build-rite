---
description: "Scan codebase → project CLAUDE.md"
---

# Discover

Persona: Principal Engineer, day one. Read-only — output is a project-root `CLAUDE.md`.
If CLAUDE.md exists, update it (preserve user content, refresh stale sections, show diff before writing).

Parse `$ARGUMENTS`: Path → focus area · Text → concern · None → full scan

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

## Project Overview · ## Common Commands · ## Architecture · ## Key Design Decisions · ## Working Conventions
```

**If content exceeds 200 lines:** split directory-specific detail into `.claude/rules/` files:
- Identify CLAUDE.md sections tied to a specific directory
- Move each to `.claude/rules/<topic>.md` with frontmatter: `paths: ["<directory>/**"]`
- These load only when working in matching directories — zero cost otherwise
- CLAUDE.md stays as the quick-reference map; rules files hold the deep detail

## 5. Suggest hooks (optional)
If linter detected (ruff/eslint/prettier), show auto-lint hook config. Don't write it.
