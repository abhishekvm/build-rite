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
1. **Context & prior comments** — gather context and fetch existing review comments per **Context gathering** + **Prior comments** in `.claude/reference/review-contract.md`.
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
   When flagging, name the pattern and point at the lighter idiom in this stack — don't prescribe a specific library. Severity: usually `Should fix` or `Nice to have`; `Must fix` only if bloat hides a bug or blocks review.
   **Test meaningfulness** — coverage ≠ verification:
   - Assertions check structure only (keys exist, attribute set) without verifying outcome
   - Mocks stacked so deep the test verifies the mock wiring, not the SUT behavior
   - PR introduces a business rule / new branch with no test that actually exercises it
   - Happy-path-only tests for code whose value is in the edge/error paths
   Flag as `Should fix` with the specific rule or branch that needs a real assertion.
   Use the **Finding shape** from `.claude/reference/review-contract.md` for every finding.
   If `## API Docs` is in project CLAUDE.md and diff touches route handlers: check each new endpoint for stack-appropriate annotation (FastAPI: `response_model` + docstring · NestJS: `@ApiOperation`+`@ApiResponse` · Express/Fastify+Zod: schema registered · Express/Fastify+JSDoc: `@openapi` block) — missing → `Should fix`.
5. **Business coverage** — does the implementation fully satisfy the intent? Edge cases? Missing requirements? Scope creep?
6. **Dedup against prior comments** — apply **Dedup against prior comments** from `.claude/reference/review-contract.md`.
7. **Summary table:**

| # | Item | Severity |
|---|------|----------|
Must fix · Should fix · Open question · Nice to have

Approve fixes → apply one severity tier at a time, Must fix first.

## Output target
Detect author and route per **Posting flow** in `.claude/reference/review-contract.md`. The own-PR path has extra routing specific to this command:
- **Own PR** (including drafts) → show findings in conversation. Split by trigger:
  - Trivial (naming, wording, dead import, minor refactor, obvious simplicity wins) → offer to fix in place, no in-conversation back-and-forth needed.
  - Architectural / judgment-call → discuss first, decide, then fix.
  - Too large to fold into this PR (major refactor, new module, scope expansion, fresh design) → suggest follow-up issue via `gh issue create`.
  - Simplicity-tier findings → propose the specific change inline (name file:line and the lighter idiom), apply only after user picks which to take.

  **After fixes are applied** — if PR is draft (`gh pr view <n> --json isDraft -q .isDraft`), prompt: "Fixes in, checks green — flip to ready with `gh pr ready <n>`?" Do not flip draft status yourself — that's the user's call.
- **Someone else's PR** / **branch / file / uncommitted** → follow **Posting flow** in the review contract.

## Tone and length
- Lead with business impact, not code mechanics
- Each finding ≤2 sentences — what's wrong and why it matters
- No preamble, no praise, no filler
- Max 5 findings per severity tier — if more exist, list them briefly without full analysis
