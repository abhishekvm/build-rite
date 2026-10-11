# build-rite

Claude Code harness, synced into project repos as `.claude/` by `sync.sh`. Project context lives in the project-root `CLAUDE.md` (from `/br-init`). Requires the ponytail plugin.

## Working style
- Bullets over prose; show progress between phases. Local edits need no confirmation — posting does (below).
- `$ARGUMENTS`: path → read as context · text → scope/problem · none → auto-scope or ask.
- Analysis commands: understand → `⏸ Checkpoint` → analyze → output.
- CLAUDE.md is the knowledge container; issues are the task system; refactor in chains of small commits.
- Commands: `/br-init` → `/br-plan` → `/br-impl` → `/br-review` → `/br-cleanup`; `/br-health` periodically; `/br-rfd` for decisions.
- Work is cut and decisions recorded per `.claude/reference/delivery.md`: requirement → delivery story (demoable) → engineering stories, with an ADR only for hard-to-reverse choices.
- Unfamiliar or recently changed APIs: read the official docs first. Prefer an installed CLI/API over browser automation — check `command -v <tool>` before concluding there isn't one.
- PDFs: `markitdown '<f>.pdf' -o "${TMPDIR:-/tmp}/<name>.md"` when installed (never next to the PDF); scanned PDFs → read directly and say so.
- Ask before exhaustive lists. Long plans or docs: a one-screen outline first (what one item is — feature, story, task; scope areas; exclusions), draft on OK. Don't duplicate content across files — reference the canonical source.

## Enforcement
- **Lean code** — follow ponytail: smallest complete change; reuse the codebase, native features and popular libraries first. If ponytail isn't installed, say so once.
- **Scope** — only what was asked. State in/out in one line and proceed; ask only when genuinely ambiguous.
- **Confirmation before posting** — PR/issue comments, new issues, pushes, `terraform apply`: show the exact content or command, wait for "go", then run it yourself. Hand back only what you can't run (SSO/MFA, interactive TUI, missing credential): say why and suggest `! <command>`. A push denied by permissions → report and stop.
- **Git** — `git add <explicit files>` only; the project's package manager only; update a stale branch by merging its base, never rebase. No build-rite attribution (`br-`, `build-rite`, harness internals) in commits, PRs or ticket comments; `/br-*` in conversation is fine.
- **Shell** — no `cd`: use `git -C <abs>`, tool flags (`make -C`, `uv --directory`, `terraform -chdir`) or `(cd <abs> && cmd)`. Absolute paths (`git rev-parse --show-toplevel`) in worktrees and hooks.
- **Worktrees** — another branch while the main checkout is busy → create it as `/br-impl` worktree mode does (under the main checkout's `.claude/worktrees/`, never the scratchpad or a sibling dir) and `EnterWorktree` it before editing, so the status line, hooks and permissions follow; never edit a worktree by path from the main checkout. **Parallel workers**: one worktree, branch and file set each; the orchestrator stays put and owns commits, pushes and the user's instructions.
- **Dependencies** — manifest or lockfile changed → run the Deps audit in `.claude/reference/checks.md`.
- **Numbers carry provenance** — source, filter, time window, aggregate (min/max/p95/mean — never mean by default) and exclusions. Separate observed from derived; estimates get a range; when sources disagree, report both and say which you trust.

## Auto mode does NOT override
- `⏸ Checkpoint` markers — stop and wait.
- Externally visible actions — per **Confirmation before posting**.
- A branch with someone else's open PR (`gh pr view --json author -q .author.login` vs `gh api user -q .login`): review only, no writes. No PR yet → your branch.

## Verify before reporting
Re-fetch ground truth before claiming done: issue/PR state via `gh … view`; applied or deployed → re-run plan/build, expect zero diff; behaviour fixed → exercise the user-visible path. Report what you verified, using the template in `.claude/reference/checks.md`.

## Human-facing output
Anything leaving the session (Slack, tickets, PRs, docs, artifacts) is for a reader who wasn't here:
- **Plain language** — "The flag is set, so this user won't be synced", not "Flagged poison row 9423 via SQL → flag-setter unblocked."
- **No compressed notation** — no `→` chains, `A/B/C` shorthand or stacked qualifiers.
- **No invented vocabulary** — use the team's names; agree before coining a concept.
- **Text before artifact** — plain text in conversation first; artifacts, Notion pages and Slack drafts only after it's accepted.
- **Match the audience** — a Slack update is ~5 lines; a handoff doc is complete. Ask if unclear.
- **Conservative claims** — never overstate a fix or finding; say what isn't verified.

## Plugin guardrails
pr-review-toolkit: never invoke its agents proactively or `/review-pr all` unprompted; avoid `code-simplifier` (it edits without asking).

## References
**Secret patterns** — refuse to stage or commit when the diff matches `sk-`, `-----BEGIN`, `ghp_`, `AKIA`, `xox`, or `password|secret|token|api_key =` with a literal value.

**Commit message format** — scale to the change:
```
<type>: <imperative summary>  (≤72 chars)

Problem:   <what was broken or missing>
Solution:  <what changed and why>
Testing:   <how to verify>
```
Trivial → subject only. Large → add `Ticket:`, `Assumptions:`, `Follow-up:`.
