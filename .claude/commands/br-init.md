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
git worktree add .worktrees/refresh-claude-md -b <convention>/refresh-claude-md <default-branch>
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

## 6. Editor config
Detect editor from existing config dirs. If none found: ask once — "Which editor? A) Zed B) VS Code C) Cursor D) Skip"

Write configs alongside any lint/test configs generated in this init. If editor already configured: skip silently.

**Zed** — ask: "Generate Zed config?"
- `.zed/settings.json` — formatter (ruff/eslint), linter, format-on-save
- `.zed/tasks.json` — one entry per Common Command (lint, test, typecheck, build) using detected task runner

**VS Code / Cursor** — ask: "Generate VS Code/Cursor config?"
- `.vscode/settings.json` or `.cursor/settings.json` — formatter, linter, format-on-save
- `.vscode/extensions.json` or `.cursor/extensions.json` — recommend extensions matching detected stack (ruff, eslint, etc.)
- `.cursor/rules/conventions.md` (Cursor only) — mirror `## Working Conventions` and `## Do NOT Use` from CLAUDE.md so Cursor's AI context matches

**IntelliJ/IDEA** — skip config generation, surface as a finding: "IDEA detected — configure formatter and linter manually."

Add detected editor to `stack.md` under a `### Editor` row.

## 7. Linter config (Python projects)
If Python is detected and no `ruff.toml` or `[tool.ruff]` in `pyproject.toml` exists:
- Copy `.claude/templates/ruff.toml` to project root
- Set `known-first-party` in `[lint.isort]` to the project package name
- Ask: "Install ruff config?" — write only on confirmation

## 8. Git hooks audit (always run)

Check for `.pre-commit-config.yaml`, `.husky/`, `lefthook.yml`, or active hooks in `.git/hooks/`.
- Found and covers lint/format/typecheck → note in next steps, no action needed.
- Not found → surface as a finding: "No git hooks detected — run `/br-setup-hooks` to configure."

## 8a. API docs
If project has a REST API and `## API Docs` is NOT in project CLAUDE.md:
- Ask: "Set up API docs?"
- If yes: detect stack and apply the matching setup — ask before writing anything:

  | Stack | Tool | Setup |
  |-------|------|-------|
  | FastAPI | `scalar-fastapi` | Add dependency → patch `/docs` route |
  | Express / Fastify | `@scalar/express-api-reference` or `@scalar/fastify-api-reference` | Add middleware → serve at `/docs` |
  | NestJS | `@nestjs/swagger` | Add `SwaggerModule.setup()` in `main.ts` |
  | Zod-based (any Node) | `zod-to-openapi` → Scalar | Register schemas → generate spec → serve via Scalar middleware |
  | GraphQL | GraphiQL (built-in) or Apollo Sandbox | Already embedded — note the URL |
  | Other | Ask user to confirm tool | Do not guess |

  For all non-GraphQL stacks: goal is OpenAPI spec auto-generated from code (types/schemas/decorators) — no hand-written YAML.

  After setup: add to CLAUDE.md:
  ```
  ## API Docs
  UI: http://localhost:<port>/docs
  Tool: <tool name>
  ```
- If no or no REST API → skip silently

## 8b. README check
Check `README.md` at project root:
- Missing → ask: "No README found — generate one from the project overview?"
- Present but empty or ≤5 lines → ask: "README is empty — scaffold it from CLAUDE.md content?"
- If yes: generate a README with: project name + one-line description, what it does, quick start (from Common Commands), and key links. Keep it ≤50 lines. Ask before writing.
- Non-trivial README → skip silently.

## 9. Next steps
After all files are written, show:

```
Init complete. Files written in worktree:
  <list files created/modified>

Next steps:
  1. Review the changes: git diff
  2. Commit:  git add <files> && git commit -m "docs: init CLAUDE.md"
  3. Push + PR: git push -u origin <branch> && gh pr create --title "docs: init CLAUDE.md" --body "..."
  4. After merge, clean up: git worktree remove .worktrees/refresh-claude-md

Or I can do steps 2-3 for you — just say "commit and PR".
```

**Greenfield only — after merge:**
```
Ready to build. Suggested next command:
  /br-plan <first task from Task List>
```
