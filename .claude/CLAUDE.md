# build-rite

Claude Code harness, synced into project repos as `.claude/` by `sync.sh`. Project context lives in the project-root `CLAUDE.md` (from `/br-init`). Requires the ponytail and mempalace plugins.

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
- "How does it work" / "show me" → explain; ask before benchmarks, data seeding, network probes or long jobs.
- Unattended runs (user away, overnight) and parallel workers follow `.claude/reference/unattended.md`.

## Enforcement
- **Lean code** — follow ponytail: smallest complete change; reuse the codebase, native features and popular libraries first. If ponytail isn't installed, say so once. Lean means less code, not less structure: interchangeable backends get one interface and a class each, not `if` on a type string; use a client library's typed models, and fetch what it already serves instead of hardcoding it. Never copy code from a library you could depend on — if scope blocks the dependency, ask.
- **Memory** — mempalace, via its CLI (not MCP). **Recall** before planning, implementing or reviewing: `mempalace search "<ticket, topic or files>"` for earlier attempts, rejected options and corrections. It holds conversations and decisions, not code — code questions go to the repo. A memory is a lead, not truth — it may come from another project, and CLAUDE.md, ADRs, issues and the code win; say when one is stale. The user's own statement of a current fact beats all of these: use it, mention the stale file once, don't re-raise it. Its hooks save each session; never use its task logstream (issues are the task system). `mempalace` not on PATH → say so once.
- **Scope** — only what was asked. State in/out in one line and proceed; ask only when genuinely ambiguous. A constraint the user states applies at its full scope — ask before reading it narrowly. One PR = one slice the user can turn on by itself; past ~500 changed lines or 15 files, stop and propose the slice list before writing more, even unattended.
- **Confirmation before posting** — PR/issue comments, new issues, edits to existing tickets (state, labels, parent, milestone), pushes to shared, default or others' branches (your own feature branch needs no "go"), `terraform apply`: show the exact content or command, wait for "go", then run it yourself. "Work autonomously" and unattended runs don't lift this. The user's own external accounts (social, blog, profile pages): hand over the final text, never apply it, even once it's approved. Hand back only what you can't run (SSO/MFA, interactive TUI, missing credential or token scope — `gh auth refresh -s <scope>`, network the sandbox can't reach — never retry with the sandbox off, a settings edit auto mode denies as Self-Modification — print the exact scoped allow rule): say why and suggest `! <command>`. An action denied by permissions or a hook → report and stop; never reroute it through another tool, clone or API.
- **Git** — `git add <explicit files>` only; the project's package manager only; update a stale branch by merging its base, never rebase. No build-rite attribution (`br-`, `build-rite`, harness internals) in commits, PRs or ticket comments; `/br-*` in conversation is fine.
- **Shell** — no `cd`: use `git -C <abs>`, tool flags (`make -C`, `uv --directory`, `terraform -chdir`); `(cd <abs> && cmd)` only when no flag exists. One line per command, chained with `&&`: wrappers, permission rules and the worktree guard match single commands — no subshells, heredocs, loops, `$(…)`, or variables holding a path or command (zsh won't word-split them); spell absolute paths out (`git rev-parse --show-toplevel`). Files → Write/Edit; commit messages → a scratchpad file and `git commit -F <file>`.
- **Worktrees** — another branch while the main checkout is busy → create it as `/br-impl` worktree mode does (under the main checkout's `.claude/worktrees/`, never the scratchpad or a sibling dir, harness copy included) and `EnterWorktree` it before editing, so the status line, commands, hooks and permissions follow; never edit a worktree by path from the main checkout. Before each commit or push, check `git branch --show-current` still matches your branch — another session can switch a shared checkout; on a mismatch, stop and move your work to a worktree. A session can't commit in another repo (hooks are repo-scoped, even from a scratchpad clone): export what you'll read first (`git -C <other> archive <ref> | tar -x -C <scratchpad>`), decide up front who commits in each repo, and for the other repo write the commit message and PR body to files and hand back the commands.
- **Dependencies** — manifest or lockfile changed → run the Deps audit in `.claude/reference/checks.md`.
- **Numbers carry provenance** — source, filter, time window, aggregate (min/max/p95/mean — never mean by default) and exclusions. Separate observed from derived; estimates get a range; when sources disagree, report both and say which you trust.

## Auto mode does NOT override
- `⏸ Checkpoint` markers — stop and wait.
- Externally visible actions — per **Confirmation before posting**.
- A branch with someone else's open PR (`gh pr view --json author -q .author.login` vs `gh api user -q .login`): review only, no writes. No PR yet → your branch.

## Verify before reporting
Re-fetch ground truth before claiming done: issue/PR state via `gh … view`; applied or deployed → re-run plan/build, expect zero diff; behaviour fixed → exercise the user-visible path; exported doc → open it and check every embed survived. Report what you verified, using the template in `.claude/reference/checks.md`.
- A subagent's or review's claim is a lead: re-check it in the code or data before it reaches a doc or a needs-you list, or label it unverified.
- A recommendation resting on an environment fact (schema, version, deployed topology, config) → check the fact or call it an assumption in the same sentence.
- Run any command before handing it to the user, or say plainly it's untested.
- A report from a turn that also made edits gets the **State** column from `.claude/reference/checks.md` and a one-line "still open" list.

## Human-facing output
Anything leaving the session (Slack, tickets, PRs, docs, artifacts) is for a reader who wasn't here:
- **Plain language** — "The flag is set, so this user won't be synced", not "Flagged poison row 9423 via SQL → flag-setter unblocked."
- **No compressed notation** — no `→` chains, `A/B/C` shorthand or stacked qualifiers.
- **No invented vocabulary** — use the team's names; agree before coining a concept.
- **Text before artifact** — plain text in conversation first; artifacts, Notion pages and Slack drafts only after it's accepted.
- **Match the audience** — a Slack update is ~5 lines in Slack's markup (`*bold*`, no `**` or tables), detail in a thread reply; a handoff doc is complete. Ask if unclear.
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
