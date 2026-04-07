---
description: "Initialize project context → CLAUDE.md (greenfield + brownfield)"
---

# Init

Persona: Principal Engineer, day one. Read-only analysis — output is a project-root `CLAUDE.md` (and optional `rules/` files).

Parse `$ARGUMENTS`: Path → focus area · Text → concern · None → full scan

## 0. Branch
Read `## Project Config` from project CLAUDE.md (if exists) for branch convention and default branch.
If missing: detect from `git branch -a`, use sensible defaults (`task/`, `main`).

Create a branch for the discovery work:
```
git checkout -b <convention>/refresh-claude-md origin/<default-branch>
```

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
Extract in phases — emit a one-line status after each so progress is visible and work survives interruption:

1. **Structure** — top-level dirs, languages, entry points → emit: `Structure scanned.`
2. **Data layer** — ORM, DB, migrations, schemas → emit: `Data layer scanned.`
3. **Commands** — Justfile/Makefile/package.json/pyproject.toml → emit: `Commands scanned.`
4. **Architecture** — cross-references, key design decisions, deployment, CI → emit: `Architecture scanned.`
5. **Conventions** — issue tracker (`.github/`), branch convention (`git branch -a`), hooks → emit: `Conventions scanned.`
6. **Editor** — detect `.zed/`, `.vscode/`, `.cursor/`, `.idea/` → emit: `Editor scanned.`

If interrupted after any phase: the emitted status lines show exactly where to resume. On restart, skip completed phases.

## 3. Present
**Greenfield:**
- 5-bullet summary of what's being built
- Key open questions / gaps identified
- Proposed task list (ordered by dependency)
- Proposed CLAUDE.md sections
- If project has a user-facing UI and `## Reference Apps` is NOT in CLAUDE.md: ask "Want reference apps for inspiration before planning? (`/br-inspire`)" — once only, never repeat after it's locked.

**Brownfield:**
- 5-bullet summary
- Top 3 architectural observations
- Proposed CLAUDE.md sections

If tracker not detected: ask. If branch convention not detected: ask.

**Before confirming — surface file gaps:**
- `README.md` missing or ≤5 lines → flag: "README is empty — scaffold it alongside CLAUDE.md?"
- `CHANGELOG.md` missing and `git-cliff` installed → flag: "No changelog — generate one?"
- No git hooks → flag: "No hooks detected — run `/br-setup-hooks`?"
- No API docs lock → flag: "No API docs configured — set up Scalar?"

Show all gaps together, let user decide which to address before writing.

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
**Task runner priority:** Justfile > Makefile > package.json scripts > raw commands.
If a Justfile or Makefile exists: write `just <recipe>` or `make <target>` — do NOT enumerate the underlying commands.
If neither exists: propose creating a Justfile at the project root (ask first) with recipes for lint, test, and the most common tasks detected. Only fall back to raw commands if the user declines.

| Task | Command |
| Build | `just build` (or detected equivalent) |
| Lint | `just lint` |
| Type check | `just typecheck` |
| Test | `just test` |
| Deploy | `just deploy` (if applicable) |

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
| Branching model | simple |

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

## 5. Stack file
Write `.claude/rules/stack.md` with the detected stack. This is project-owned — never overwritten by `br-sync`.

Template (fill in what's detected; remove rows that don't apply):
```markdown
## Stack

### Backend
- Runtime: <runtime + package manager — e.g. uv, pnpm, go mod>
- Framework: <framework>
- Test: <test command from Common Commands>
- Lint: <lint command from Common Commands>

### Frontend
- Runtime: <runtime + package manager>
- Framework: <framework>
- Test: <test command>
- Lint: <lint command>

### Data
- DB: <database + driver>
- Migrations: <tool + command>

### Editor
- <Zed / VS Code / Cursor — with config paths generated>

### Do NOT Use
- <forbidden library or tool — with reason>
```

Only include sections that exist. Ask before writing: "Generate stack.md from detected stack?"

## 6. Post-scan checklist
Surface any detected gaps — user picks what to address. Ask before writing anything.

| Gap | Detection | Action |
|-----|-----------|--------|
| No editor config | Missing `.zed/`, `.vscode/`, `.cursor/` | Ask which editor → generate formatter/linter/tasks config |
| No linter config | Python: no `ruff.toml`/`[tool.ruff]` · JS/TS: no `eslint.config.*` | Ask → generate config tailored to detected stack |
| No git hooks | No `.pre-commit-config.yaml`, `.husky/`, `lefthook.yml` | Suggest `/br-setup-hooks` |
| No changelog | `git-cliff` installed but no `CHANGELOG.md` | Ask → `git cliff -o CHANGELOG.md` |
| No API docs | REST API detected, no `## API Docs` in CLAUDE.md | Ask → detect stack, set up Scalar/Swagger |
| README missing/empty | Missing or ≤5 lines | Ask → scaffold from project overview (≤50 lines) |

Skip silently if already configured. Never auto-write.

## 9. Next steps
After all files are written, show:

```
Init complete. Files written:
  <list files created/modified>

Next: "commit and PR" or review with git diff first.
```

**Greenfield only — after merge:**
```
Ready to build. Suggested next command:
  /br-plan <first task from Task List>
```
