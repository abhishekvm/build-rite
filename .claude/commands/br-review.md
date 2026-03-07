---
description: "Severity-tiered code review (yours or others')"
---

# Review

No file edits until explicitly asked. If clean, say so briefly.

Parse `$ARGUMENTS`: PR number → `gh pr diff` + fetch linked tickets · Branch → `git diff <default-branch>...<branch>` · File → recent changes · None → uncommitted or branch diff

Read `## Project Config` for default branch name.

## Steps
1. **Context** — get diff, read changed files in full, read project CLAUDE.md, fetch linked tickets (Linear/GH/Jira from PR body). No ticket? Ask business context.
2. **Patterns** — check how existing codebase handles similar concerns (naming, tests, monitoring, security). Compare PR against established patterns, not generic best practices.
3. **Analyze by concern** (not by file): naming, security, business logic, data/queries, error handling, performance, test coverage, config/deployment.
   Each finding: What's wrong · Where (file:line) · Why it matters · Suggested fix (code snippet). Use comparison tables for pattern divergence. Ask questions for ambiguous items.
4. **Business coverage** — if ticket linked: implemented? Edge cases? Missing requirements? Scope creep?
5. **Summary table:**

| # | Item | Severity |
|---|------|----------|
Must fix · Should fix · Open question · Nice to have

Approve fixes → apply one severity tier at a time, Must fix first.
