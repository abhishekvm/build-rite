---
description: "Severity-tiered code review (yours or others')"
---

# Review

No file edits until explicitly asked. If clean, say so briefly.

Parse `$ARGUMENTS`: PR number → `gh pr diff` + fetch linked tickets · Branch → `git diff <default-branch>...<branch>` · File → recent changes · None → uncommitted or branch diff

Read `## Project Config` for default branch name.

## Step 0 — route by effect
After fetching the diff, judge by signals — not line count. Suggest `/br-swarm-review` when any fire:
- **Blast radius** — touches auth, payments, billing, data layer, migrations, IAM, secrets, or anything called from many sites
- **Reversibility** — destructive migrations, schema changes, infra deletes, public-API breaks, anything hard to roll back
- **Cross-cutting risk** — security surface (input validation, authz), perf hot path, shared utility with many callers
- **Mixed concerns** — infra + app code in the same PR where one reviewing lens misses half the failure modes
- **Unfamiliar territory** — modifying code the author hasn't touched before (`git log --author=<author> <files>` returns little), since blind-spots compound

If any fire, name the specific signal and ask:
"This PR is [signal]. `/br-swarm-review`'s parallel lanes are better suited. Switch, or proceed with `/br-review`?"

Otherwise proceed silently. A formatter sweep or type-annotation pass stays single-lane regardless of line count.

## Review gate
After step 2 (business logic confirmed), quick first pass across the diff. If too many blocking issues to review productively → reject early with top 3 issues, ask to fix first. Otherwise proceed to full analysis.

## Steps
1. **Context** — get diff, read changed files in full, read project CLAUDE.md, fetch linked tickets (Linear/GH/Jira from PR body), read PR description and any docs/READMEs included in the diff. No ticket? Ask business context.
   **Prior comments** — fetch existing review comments: `gh api repos/{owner}/{repo}/pulls/<n>/comments` (inline) and `gh api repos/{owner}/{repo}/issues/<n>/comments` (PR-level). If any exist, note "Re-review — N prior comments" at the top of output and carry the list into analysis.
2. **Business logic** — before reviewing code quality, understand *what* the change is trying to do:
   - Read the code to form your own understanding of the business logic being implemented
   - Compare your understanding against the PR description / ticket / README checked in with the PR
   - If they diverge: flag it — either the code doesn't match intent or the docs are wrong
   - If PR description is vague or missing: state what you believe the business logic is and ask the author to confirm

   **⏸ Checkpoint:** Present your understanding of the business logic and scope. Wait for user to confirm before proceeding to code analysis.

3. **Patterns** — check how existing codebase handles similar concerns (naming, tests, monitoring, security). Compare PR against established patterns, not generic best practices.
4. **Analyze by concern** (not by file): naming, security, business logic, data/queries, error handling, performance, simplicity, test meaningfulness, config/deployment.
   **Secret scan** — flag matches against the **Secret patterns** in `.claude/CLAUDE.md` as `Must fix`.
   **Migration safety** — if diff includes DB migrations (Alembic, dbt, raw SQL, Prisma): check for destructive ops without rollback (`DROP COLUMN`, `NOT NULL` without default, bulk `UPDATE` without batching) → `Must fix`; missing data backfill for non-nullable columns → `Must fix`; no `downgrade()` / rollback path → `Should fix`.
   **Performance** — concrete failure modes, not micro-optimizations:
   - *N+1 / per-row query in a loop* — where a batched/joined fetch is idiomatic in this stack
   - *Repeated work in hot path* — re-computed on every call when a sensible cache scope exists (request, instance, module)
   - *Sync I/O on async runtime* — or CPU-bound work in async without offload
   - *Allocation in hot path* — string concat in loops, list rebuilds, deep copies of unchanged data
   - *Missing index / sequential scan* — on a query the diff adds, when the schema/migration sits in the same PR
   Severity: data-volume / migration-touching → `Must fix` · unbounded loop-over-IO → `Should fix` · ergonomic only → `Nice to have`.
   **Simplicity / bloat** — flag code that's heavier than the problem. Patterns, not scenarios:
   - *Wrong weight class* — a heavier tool/library used where a lighter built-in or native idiom in the same stack does the job (dependency pulled in for something the stdlib already provides; full framework where a primitive fits)
   - *Declarative fit / code-first default* — procedural setup where the stack has an idiomatic declarative form (config object, decorator, schema, manifest) that's shorter and more discoverable
   - *Premature abstraction* — base class, strategy, registry, or indirection introduced before the second concrete implementation exists
   - *Speculative defense* — error handling, validation, or branches for states the call sites can't produce (trusts should flow from the system boundary inward, not everywhere)
   - *Ceremony without value* — wrappers, helpers, or one-line indirections that don't add behavior or clarity
   When flagging, name the pattern and point at the lighter idiom in this stack — don't prescribe a specific library. Severity: usually `Should fix` or `Nice to have`; `Must fix` only if bloat hides a bug or blocks review. Suggested fix for simplicity findings: `/simplify <file>` — name the file(s) so the user can run it directly.
   **Test meaningfulness** — coverage ≠ verification:
   - Assertions check structure only (keys exist, attribute set) without verifying outcome
   - Mocks stacked so deep the test verifies the mock wiring, not the SUT behavior
   - PR introduces a business rule / new branch with no test that actually exercises it
   - Happy-path-only tests for code whose value is in the edge/error paths
   Flag as `Should fix` with the specific rule or branch that needs a real assertion.
   Each finding: What's wrong · Where (file:line) · **Impact** (concrete failure mode or cost — not "bad practice") · **Value if fixed** (what improves) · Suggested fix. If you can't name a concrete impact, downgrade severity or drop the finding. `Nice to have` must say "no functional impact" so the reader knows it's optional.
   If `## API Docs` is in project CLAUDE.md and diff touches route handlers: check each new endpoint for stack-appropriate annotation (FastAPI: `response_model` + docstring · NestJS: `@ApiOperation`+`@ApiResponse` · Express/Fastify+Zod: schema registered · Express/Fastify+JSDoc: `@openapi` block) — missing → `Should fix`.
5. **Business coverage** — does the implementation fully satisfy the intent? Edge cases? Missing requirements? Scope creep?
6. **Dedup against prior comments** — drop findings whose (file, line ±5, concern) match an existing comment from step 1. Mark near-misses `(already raised — refining)` and keep only if you're adding new info, not restating.
7. **Summary table:**

| # | Item | Severity |
|---|------|----------|
Must fix · Should fix · Open question · Nice to have

Approve fixes → apply one severity tier at a time, Must fix first.

## Output target
Detect author: `gh pr view <num> --json author -q .author.login` vs `gh api user -q .login`.
- **Own PR** (including drafts) → show findings in conversation. Split by trigger:
  - Trivial (naming, wording, dead import, minor refactor, obvious simplicity wins) → offer to fix in place, no in-conversation back-and-forth needed.
  - Architectural / judgment-call → discuss first, decide, then fix.
  - Too large to fold into this PR (major refactor, new module, scope expansion, fresh design) → suggest follow-up issue via `gh issue create`.
  - Simplicity-tier findings → suggest `/simplify <file>` with the specific file(s) named, rather than batch-fixing inline; it's more focused for this class of change.

  **After fixes are applied** — if PR is draft (`gh pr view <n> --json isDraft -q .isDraft`), prompt: "Fixes in, checks green — flip to ready with `gh pr ready <n>`?" Do not flip draft status yourself — that's the user's call.
- **Someone else's PR** → preview first, then post.
  1. Show the full set of findings in conversation as a numbered list (file:line · severity · one-line message · proposed comment body).
  2. Wait for user to pick which to post (e.g., "all", "1,3,5", "skip").
  3. Only after explicit selection, post via **individual per-line calls** (`gh api repos/{owner}/{repo}/pulls/{n}/comments`), one API call per finding. Don't bundle into a single `gh pr review --comment` / `pulls/reviews` submission.
- **Branch/file/uncommitted** → show in conversation (no PR to post to).

## Tone and length
- Lead with business impact, not code mechanics
- Each finding ≤2 sentences — what's wrong and why it matters
- No preamble, no praise, no filler
- Max 5 findings per severity tier — if more exist, list them briefly without full analysis
