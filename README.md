# build-rite

Opinionated Claude Code harness. Syncs into any project's `.claude/` directory.

Every command earns its place through real usage — if it doesn't get used, it gets removed.

## Why build-rite

The AI agent is the new IDE — but the raw CLI is verbose, cautious, and inconsistent. The harness is what makes it usable for real engineering work.

- **Workflow-first** — every command maps to a phase you actually do (scope → plan → implement → review → ship). No exhaustive coverage; if it isn't used, it's deleted.
- **Brownfield-first** — built for taking over inherited repos, not just greenfield demos. `/br-init` reads what's there; `/br-health` gives you a real read on the codebase.
- **Opinionated defaults** — confirm before writing, explicit staging, no auto-fixes, secret scanning. Project specifics live in your `CLAUDE.md`; the harness stays generic.

Background: [The AI harness is the new IDE](https://abhishekvm.substack.com/p/the-ai-harness-is-the-new-ide)

## Install

**Prerequisite:** the [ponytail](https://github.com/DietrichGebert/ponytail) plugin — build-rite leans on it for lean-code rules and `/br-health`'s audit instead of keeping its own copy:
```bash
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
```

**Prerequisite:** the [mempalace](https://github.com/MemPalace/mempalace) plugin — memory across sessions. `/br-rfd`, `/br-plan`, `/br-impl` and `/br-review` search it for earlier attempts, rejected options and dismissed review findings:
```bash
claude plugin marketplace add MemPalace/mempalace
claude plugin install --scope user mempalace
```
Then `uv tool install mempalace` (the commands call its CLI, not the MCP server) and restart Claude Code. Its hooks save each session to the palace in the background, which also creates the palace on first use. build-rite needs only the hooks and the CLI, so you can disable the plugin's MCP server in `/mcp`. The palace is recall only: CLAUDE.md, ADRs and issues stay the source of truth.

Install `br-sync`:
```bash
curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s -- --install-alias
```

That writes an executable to `~/.local/bin/br-sync` — no shell reload needed, and
it works from Makefiles, npm scripts and agent shells, which a shell alias does
not. If `~/.local/bin` isn't on your `PATH`, the installer says so. Override the
location with `BUILD_RITE_BIN`.

## Usage

Sync the harness into any project:
```bash
cd your-project/
br-sync
```

Run `br-sync` again anytime to update — see [How it works](#how-it-works) for what it touches.

**Pinning to a version** — pass the version directly:

```bash
br-sync 0.1.0      # pins this project to v0.1.0 (writes .claude/.br-pin)
br-sync            # next run: uses the pin automatically
br-sync 0.2.0      # bump the pin
br-sync main       # remove the pin, back to following main
```

The pin lives at `.claude/.br-pin` — commit it to lock the version for the team, or `.gitignore` it for per-developer pins. Each sync reports the active version and any newer tags so you know when to upgrade.

`br-sync` accepts any tag (`0.1.0`, `v0.1.0`), branch (`main`), or commit SHA. `BUILD_RITE_REF` sets the ref for projects with no pin (full name, e.g. `v0.1.0`) — useful in CI.

**Two things get versioned separately:**

| What | Where | How it's versioned |
|---|---|---|
| `sync.sh` (the runner) | Re-fetched from `main` on every alias invocation | Always latest — runner fixes flow automatically |
| Commands + rules (the content) | Cached clone, checked out at the pinned ref | Pinned per project via `br-sync <version>` |

This is the rustup/nvm pattern: runner stays current; teams pin the content.

> **Trust boundary:** a pin fixes the *content* (commands + rules), not the *runner*. `sync.sh` is always fetched from `main` — its behavior, and the fact that `curl … | bash` executes it, is not pinned. Pin the content for reproducible harness behavior; trust `main` for the runner. To pin the runner too, point your alias at a tagged `sync.sh` URL instead of `main`.

If your alias predates `v0.1.0` and `br-sync 0.1.0` errors with "no such file", re-run `--install-alias` or edit the alias to add ` -s --` after `bash`:

```bash
alias br-sync='curl -sSf https://raw.githubusercontent.com/abhishekvm/build-rite/main/sync.sh | bash -s --'
```

## Commands

| Command | What it does |
|---|---|
| `/br-init` | Scan codebase → generate project `CLAUDE.md` + `stack.md` |
| `/br-rfd` | Requirements discovery → research → shareable decision document → ADR |
| `/br-plan` | Ticket or need → delivery stories with demo steps + engineering sub-issues |
| `/br-impl` | Branch → implement → verify → draft PR |
| `/br-review` | Built-in `/code-review` + intent check, dedup, and author-aware fixing/posting |
| `/br-health` | `/ponytail-audit` + architecture/DX/deps lenses → findings → docs + issues |
| `/br-cleanup` | Merge if ready → close issues → delete branch → pull default |

A fast model handles init/plan/impl well. Use your strongest reasoning model for review/health — the analysis commands benefit most from capability. (As of writing: Sonnet for the former, Opus for the latter; adjust as model tiers shift.)

## Workflow

```
/br-init              ← first time on a repo (generates CLAUDE.md + stack.md)
/br-rfd               ← scope a fuzzy problem before planning
/br-plan PROJECT-43   ← plan from a ticket or problem statement
/br-impl              ← branch, implement, verify, draft PR
/br-review 52         ← review a PR before merge (add `max` for high-risk PRs)
/br-cleanup           ← after merge — close issues, delete branch
```

## When to run what

| Situation | Action |
|---|---|
| First time on a repo | `br-sync` → `/br-init` |
| Harness update only | `br-sync`, done |
| Harness adds new artifacts | `br-sync` → `/br-init` to refresh |
| Fuzzy problem needs scoping | `/br-rfd` before `/br-plan` |
| Taking over a brownfield repo | `/br-init` → `/br-health` |
| Reviewing a risky PR | `/br-review <N> max` |
| Project code changed significantly | `/br-health` |
| CLAUDE.md drifted from reality | `/br-health` → "Update CLAUDE.md?" → `/br-init` |
| PR merged | `/br-cleanup` |

## Rules

Synced automatically — loaded by Claude every session:

| Rule | What it enforces |
|---|---|
| `br-standards` | TDD flow (behavior changes) + clean-code drift guards — naming, functions, error handling, security |

## Permissions (iterating)

`.claude/settings.json` ships a minimal permission set in three buckets:

- **Deny** — destructive: `git push --force`, `git add -A`, `rm -rf /`, etc.
- **Ask** — state-changing: pushes, destructive git (`reset --hard`, `clean`, `restore`, `checkout .`), dep installs/removals, PR merges, `terraform apply`, `gh api` writes (`-X`, `--method`, `-f`, `-F`, `--input`)
- **Allow** — broad read/build: git (non-destructive), `gh api` reads, package managers, file ops

The list is **incomplete by design**. The starting point was blocking the most destructive patterns and asking before externally-visible actions. Sister commands get added as they're first hit in real use — `uv add` landed when adopting uv, `uv remove` followed once the asymmetry showed up. Expect this to keep evolving; corrections welcome.

## How it works

`/br-init` generates a project `CLAUDE.md` with a `## Project Config` section — tracker, branch convention, default branch, branching mode. Asked once, reused by all other commands. Also generates `.claude/rules/stack.md` for project-specific tooling constraints.

If the generated `CLAUDE.md` exceeds 200 lines, heavy sections are auto-split into `.claude/rules/` files that load only when you work in matching directories.

`br-sync` copies `br-*` commands and rules, `reference/`, `CLAUDE.md`, `settings.json`, and the status line into your project's `.claude/`, and asks before replacing a `CLAUDE.md`, `settings.json`, or status line you edited. It never touches your project-root `CLAUDE.md`, non-`br-*` rules or commands, `settings.local.json`, or files you added to `reference/` (that folder is gitignored, so keep shared project docs elsewhere). Keep project-only permissions in `.claude/settings.local.json` — Claude Code merges it with `settings.json`.

---

Issues, ideas, and corrections welcome: [github.com/abhishekvm/build-rite/issues](https://github.com/abhishekvm/build-rite/issues)
