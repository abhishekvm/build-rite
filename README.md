# build-rite

Opinionated Claude Code harness. Syncs into any project's `.claude/` directory.

Every command earns its place through real usage — if it doesn't get used, it gets removed.

## Why build-rite

The AI agent is the new IDE — but the raw CLI is verbose, cautious, and inconsistent. The harness is what makes it usable for real engineering work.

- **Workflow-first** — every command maps to a phase you actually do (scope → plan → implement → review → ship). No exhaustive coverage; if it isn't used, it's deleted.
- **Brownfield-first** — built for taking over inherited repos, not just greenfield demos. `/br-init` reads what's there; `/br-health` + `/br-swarm-review repo` give you a real read on the codebase.
- **Opinionated defaults** — confirm before writing, explicit staging, no auto-fixes, secret scanning. Project specifics live in your `CLAUDE.md`; the harness stays generic.

Background: [The AI harness is the new IDE](https://abhishekvm.substack.com/p/the-ai-harness-is-the-new-ide)

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
| `/br-rfd` | Requirements discovery → research → shareable decision document |
| `/br-plan` | Fetch ticket → analyze → implementation plan |
| `/br-impl` | Branch → implement → verify → draft PR |
| `/br-review` | Severity-tiered code review (yours or others') |
| `/br-swarm-review` | Multi-agent parallel review — high-risk PRs or brownfield deep-dive |
| `/br-health` | Third-person project review → findings → docs + issues |
| `/br-cleanup` | Merge if ready → close issues → delete branch → pull default |

Sonnet works for init/plan/impl. Opus recommended for review/swarm-review/health.

## Workflow

```
/br-init              ← first time on a repo (generates CLAUDE.md + stack.md)
/br-rfd               ← scope a fuzzy problem before planning
/br-plan PROJECT-43   ← plan from a ticket or problem statement
/br-impl              ← branch, implement, verify, draft PR
/br-review 52         ← review a PR before merge
/br-swarm-review 52   ← deep-dive review for high-risk PRs
/br-swarm-review repo ← brownfield takeover — multi-agent scan of the codebase
/br-cleanup           ← after merge — close issues, delete branch
```

## When to run what

| Situation | Action |
|---|---|
| First time on a repo | `br-sync` → `/br-init` |
| Harness update only | `br-sync`, done |
| Harness adds new artifacts | `br-sync` → `/br-init` to refresh |
| Fuzzy problem needs scoping | `/br-rfd` before `/br-plan` |
| Taking over a brownfield repo | `/br-init` → `/br-health` → `/br-swarm-review repo` |
| Reviewing a risky PR | `/br-swarm-review <N>` instead of `/br-review` |
| Project code changed significantly | `/br-health` |
| CLAUDE.md drifted from reality | `/br-health` → "Update CLAUDE.md?" → `/br-init` |
| PR merged | `/br-cleanup` |

## Rules

Synced automatically — loaded by Claude every session:

| Rule | What it enforces |
|---|---|
| `br-tdd` | TDD flow — failing test first, suite green before commit |
| `br-clean-code` | Naming, functions, SOLID, error handling, security |

## Permissions (iterating)

`.claude/settings.json` ships a minimal permission set in three buckets:

- **Deny** — destructive: `git push --force`, `git add -A`, `rm -rf /`, etc.
- **Ask** — state-changing: pushes, dep installs/removals, PR merges, `terraform apply`, `gh api`
- **Allow** — broad read/build: git read, package managers, file ops

The list is **incomplete by design**. The starting point was blocking the most destructive patterns and asking before externally-visible actions. Sister commands get added as they're first hit in real use — `uv add` landed when adopting uv, `uv remove` followed once the asymmetry showed up. Expect this to keep evolving; corrections welcome.

## How it works

`/br-init` generates a project `CLAUDE.md` with a `## Project Config` section — tracker, branch convention, default branch, branching mode. Asked once, reused by all other commands. Also generates `.claude/rules/stack.md` for project-specific tooling constraints.

If the generated `CLAUDE.md` exceeds 200 lines, heavy sections are auto-split into `.claude/rules/` files that load only when you work in matching directories.

`br-sync` copies `br-*` commands, rules, and hooks into your project's `.claude/`. It never touches your project's `CLAUDE.md`, `.claude/rules/`, `settings.local.json`, or custom commands.
