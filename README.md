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
| `/br-discover` | Scan codebase → generate project `CLAUDE.md` |
| `/br-plan` | Fetch ticket → analyze → implementation plan |
| `/br-impl` | Branch → implement → verify → PR |
| `/br-review` | Severity-tiered code review (yours or others') |
| `/br-health` | Third-person project review → findings → roadmap |

Sonnet works for discover/plan/impl. Opus recommended for review/health.

## Workflow

```
/br-discover          ← first time on a repo
/br-plan PROJECT-43   ← plan from a ticket or problem statement
/br-impl              ← implement, verify, PR
/br-review 52         ← review any PR
/br-health            ← periodic health check
```

## How it works

`/br-discover` generates a project `CLAUDE.md` with a `Project Config` section — tracker, branch convention, default branch, branching mode. Asked once, reused by all other commands.

If the generated `CLAUDE.md` exceeds 200 lines, heavy sections are auto-split into `.claude/rules/` files that load only when you work in matching directories.

`br-sync` copies `br-*` commands and hooks into your project's `.claude/`. It never touches your project's `CLAUDE.md`, `.claude/rules/`, `settings.local.json`, or custom commands.
