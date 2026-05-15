---
description: "Multi-agent parallel PR review with consolidated findings"
---

# Swarm Review

Fan out specialist review agents in parallel, consolidate findings into one ranked table. No file edits or external posting until explicitly approved.

Parse `$ARGUMENTS`: PR number → target that PR · None → current branch's PR (`gh pr view --json number -q .number`) or branch diff vs default branch.

Read `## Project Config` in project CLAUDE.md for default branch and stack hints.

## Steps

1. **Context** — fetch diff, PR description, linked tickets. Same context-gathering as `/br-review` step 1. Detect author:
   ```
   PR_AUTHOR=$(gh pr view <num> --json author -q .author.login)
   ME=$(gh api user -q .login)
   ```
   `OWN_PR` if equal, else `OTHERS_PR`.

   **Prior comments** — fetch inline + PR-level comments (`gh api repos/{owner}/{repo}/pulls/<n>/comments` and `.../issues/<n>/comments`) before fan-out. Pass the list into each agent's context so they don't re-raise. Note "Re-review — N prior comments" up front if any exist.

2. **Business logic checkpoint** — same as `/br-review` step 2. State your understanding, wait for confirmation before fanning out.

3. **Fan out** — launch parallel agents via the Agent tool. Default lanes (drop any that don't apply to the diff):
   - **security** — auth, secrets, injection, authorization, data exposure
   - **correctness** — business logic, edge cases, data/query correctness, migration safety
   - **performance** — N+1, hot paths, allocations, query plans, async/await misuse
   - **style** — naming, simplicity (`Wrong weight class`, `Premature abstraction`, etc. from `/br-review`), test meaningfulness

   Each agent gets: the diff, the PR description, the project CLAUDE.md, and a focused system prompt naming its lane only. Each returns findings in the standard shape (What · Where · Impact · Value · Suggested fix · Severity).

4. **Consolidate** — first drop rows whose (file, line ±5, concern) match an existing comment from step 1; keep a row only if it adds new info, annotating `(refines #<comment-id>)` when it does. Then dedupe findings that overlap across lanes (same file:line, same root cause). Merge into one severity-ranked table:

   | # | Lane | File:Line | Severity | Finding | Trivial? |
   |---|------|-----------|----------|---------|----------|

   `Trivial?` = Y for naming, dead imports, wording, obvious simplicity wins, type annotation gaps. N for anything that needs judgment, design discussion, or new tests.

5. **Branch on author**:

   ### Own PR
   - Show the table.
   - Offer: "Apply trivial fixes (rows N, M, ...) in place? Architectural ones (P, Q, ...) we'll discuss." Wait for go-ahead.
   - On approval: apply trivial fixes, run `lint/typecheck/test` per project conventions, report using the **Check output template** from `.claude/CLAUDE.md`.
   - For architectural findings: discuss one at a time, decide, then fix.
   - For findings too large for this PR: suggest follow-up issue (don't auto-create — `gh issue create` is in `ask`).
   - If PR is draft and checks pass: prompt to flip ready (don't flip yourself).

   ### Others' PR
   - Show the table — no auto-fix, ever.
   - For each finding, render the proposed inline comment body underneath the row.
   - Wait for selection ("all", "1,3,5", "skip").
   - On selection, post via **individual per-line calls**: `gh api repos/{owner}/{repo}/pulls/{n}/comments` per finding. One API call per finding (not a bundled review).

## Tone
- Lead with the consolidated table. No per-agent narratives.
- Each finding ≤2 sentences.
- Cap at 5 per severity tier; list overflow briefly.
- No preamble or summary of what the agents did.
