---
description: "Severity-tiered code review (yours or others')"
---

# Review

No file edits until explicitly asked. If clean, say so briefly.

Parse `$ARGUMENTS`: PR number → `gh pr diff` + fetch linked tickets · Branch → `git diff <default-branch>...<branch>` · File → recent changes · None → uncommitted or branch diff

Read `## Project Config` for default branch name.

## Review gate
After step 2 (business logic confirmed), do a quick first pass across the diff before deep analysis:
- Count `Must fix` and `Should fix` issues visible at a glance
- **Hard reject** (≥3 Must fix OR ≥5 Should fix) → stop, do not continue to deep analysis. Post:
  ```
  Too many blocking issues to review thoroughly.

  Blockers: <N> Must fix, <N> Should fix
  Top issues:
  - <issue> (<concern>)
  - <issue> (<concern>)
  - <issue> (<concern>)

  Fix these first, then re-request review.
  ```
  If PR number given: post as `gh pr review --request-changes`. Then stop.
- **Warning** (2 Must fix OR 3–4 Should fix) → note the count at the top of the review, then continue full analysis
- Below thresholds → full review, no preamble

## Steps
1. **Context** — get diff, read changed files in full, read project CLAUDE.md, fetch linked tickets (Linear/GH/Jira from PR body), read PR description and any docs/READMEs included in the diff. No ticket? Ask business context.
2. **Business logic** — before reviewing code quality, understand *what* the change is trying to do:
   - Read the code to form your own understanding of the business logic being implemented
   - Compare your understanding against the PR description / ticket / README checked in with the PR
   - If they diverge: flag it — either the code doesn't match intent or the docs are wrong
   - If PR description is vague or missing: state what you believe the business logic is and ask the author to confirm

   **⏸ Checkpoint:** Present your understanding of the business logic and scope. Wait for user to confirm before proceeding to code analysis.

3. **Patterns** — check how existing codebase handles similar concerns (naming, tests, monitoring, security). Compare PR against established patterns, not generic best practices.
4. **Analyze by concern** (not by file): naming, security, business logic, data/queries, error handling, performance, test coverage, config/deployment.
   Each finding: What's wrong · Where (file:line) · Why it matters · Suggested fix (code snippet). Use comparison tables for pattern divergence. Ask questions for ambiguous items.
   If `## API Docs` is in project CLAUDE.md and diff touches route handlers: check each new endpoint for stack-appropriate annotation (FastAPI: `response_model` + docstring · NestJS: `@ApiOperation`+`@ApiResponse` · Express/Fastify+Zod: schema registered · Express/Fastify+JSDoc: `@openapi` block) — missing → `Should fix`.
5. **Business coverage** — does the implementation fully satisfy the intent? Edge cases? Missing requirements? Scope creep?
6. **Summary table:**

| # | Item | Severity |
|---|------|----------|
Must fix · Should fix · Open question · Nice to have

Approve fixes → apply one severity tier at a time, Must fix first.

## Output target
- PR number given → post findings via `gh pr review` with inline comments. Don't just show in conversation.
- Branch/file/uncommitted → show in conversation (no PR to post to).

## Tone and length
- Lead with business impact, not code mechanics
- Each finding ≤2 sentences — what's wrong and why it matters
- No preamble, no praise, no filler
- Max 5 findings per severity tier — if more exist, list them briefly without full analysis
