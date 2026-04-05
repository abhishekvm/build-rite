# build-rite

Opinionated Claude Code harness. Syncs into any project's `.claude/` directory.

Every command earns its place through real usage — if it doesn't get used, it gets removed.

## Install

Add `br-sync` to your shell:
```bash
curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s -- --install-alias
```

```bash
source ~/.zshrc
```

## Usage

Sync the harness into any project:
```bash
cd your-project/
br-sync
```

Run `br-sync` again anytime to update. It only overwrites `br-*` commands and hooks — your project files are never touched.

## Commands

| Command | What it does |
|---|---|
| `/br-init` | Scan codebase → generate project `CLAUDE.md` + `stack.md` |
| `/br-inspire` | Find reference apps → extract patterns worth stealing |
| `/br-plan` | Fetch ticket → analyze → implementation plan |
| `/br-impl` | Branch → implement → verify → PR |
| `/br-commit` | Stage → verify → commit (ad-hoc changes, enforces best practices) |
| `/br-review` | Severity-tiered code review (yours or others') |
| `/br-health` | Third-person project review → findings → docs + issues |
| `/br-setup-hooks` | Guided git hooks setup — pre-commit lint/format/typecheck |
| `/br-setup-visual` | Guided visual testing setup — Maestro or Playwright |

Sonnet works for init/plan/impl/commit. Opus recommended for review/health.

## Workflow

```
/br-init              ← first time on a repo (generates CLAUDE.md + stack.md)
/br-inspire           ← before UI work — find reference apps + patterns to steal
/br-plan PROJECT-43   ← plan from a ticket or problem statement
/br-impl              ← implement, verify, PR
/br-commit            ← ad-hoc commit outside impl flow
/br-review 52         ← review any PR
/br-health            ← periodic health check
```

## When to run what

| Situation | Action |
|---|---|
| First time on a repo | `br-sync` → `/br-init` |
| Harness update only | `br-sync`, done |
| Harness adds new artifacts | `br-sync` → `/br-init` to generate them |
| Project code changed significantly | `/br-health` |
| CLAUDE.md drifted from reality | `/br-health` → "Update CLAUDE.md?" → `/br-init` |

## Rules

Synced automatically — loaded by Claude every session:

| Rule | What it enforces |
|---|---|
| `br-commits` | Explicit staging, approval gate, one commit per task |
| `br-tdd` | TDD flow — failing test first, suite green before commit |
| `br-clean-code` | Naming, functions, SOLID, error handling, security |
| `br-design-patterns` | GoF, architectural, distributed, and AI/LLM patterns reference |

## How it works

`/br-init` generates a project `CLAUDE.md` with a `## Project Config` section — tracker, branch convention, default branch, branching mode. Asked once, reused by all other commands. Also generates `.claude/rules/stack.md` for project-specific tooling constraints.

If the generated `CLAUDE.md` exceeds 200 lines, heavy sections are auto-split into `.claude/rules/` files that load only when you work in matching directories.

`br-sync` copies `br-*` commands, rules, and hooks into your project's `.claude/`. It never touches your project's `CLAUDE.md`, `.claude/rules/`, `settings.local.json`, or custom commands.
