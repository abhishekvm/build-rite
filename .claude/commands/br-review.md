---
description: "Severity-tiered code review (yours or others') — built-in /code-review engine + author-aware fixing and posting"
argument-hint: "[pr-number | branch | file] [low|medium|high|max]"
disable-model-invocation: true
---

# Review

The bug hunt runs on the built-in `code-review` skill. This command adds what it lacks: the intent check, dedup against prior comments, and author-aware fixing/posting. No file edits until explicitly asked. If clean, say so briefly.

Parse `$ARGUMENTS`: PR number → `gh pr diff` + linked tickets · Branch → `git diff <default-branch>...<branch>` · File → recent changes · None → uncommitted or branch diff. Optional level (default `medium`).

## Steps
1. **Context & prior comments** — per **Context gathering** + **Prior comments** in `.claude/reference/review-contract.md`.
2. **⏸ Checkpoint: business logic** — state what the change is trying to do and compare it with the PR description / ticket. Flag a divergence or a vague description. Wait for confirmation.
3. **Run the `code-review` skill** with an explicit target — the PR number, or the branch name for a branch diff (with no target it reviews only commits ahead of upstream, which is empty after a push) — at the user's level or `medium`. Use `max` when the diff touches auth, payments, the data layer, migrations, IAM, secrets, or a widely called utility, and suggest `/code-review ultra` for the riskiest (cloud, billed — only the user can launch it). Never pass `--comment` or `--fix`: posting and fixing go through step 6.
4. **Add what it doesn't check** (skip silently when N/A):
   - **Secret scan** — matches against **Secret patterns** in `.claude/CLAUDE.md` → `Must fix`
   - **Dependencies** — manifest or lockfile touched → the Deps audit in `.claude/reference/checks.md`; new advisory → `Must fix`
   - **Migration safety** — destructive op without rollback, `NOT NULL` without default or backfill → `Must fix`; no rollback path → `Should fix`
   - **Removed fallbacks** — a default replaced by a refusal: list the callers and what the default was quietly handling; one that now breaks → `Must fix`
   - **API docs** — `## API Docs` configured and a new endpoint lacks the stack's annotation → `Should fix`
   - **Business coverage** — intent fully met? Missing requirements? Scope creep?
5. **Merge and dedup** — tier each `code-review` finding by impact: wrong result, security, data loss → `Must fix`; other correctness → `Should fix`; reuse/simplification/efficiency cleanups → `Should fix` or `Nice to have`. Write each in the **Finding shape**, then apply **Dedup against prior comments** from the review contract.

   | # | Item | Severity |
   |---|------|----------|

   Must fix · Should fix · Open question · Nice to have
6. **Route by author** per **Posting flow** in `.claude/reference/review-contract.md`. Own PR: trivial fixes → offer to apply in place; judgment calls → discuss first; too large for this PR → suggest a follow-up issue in the configured tracker (`Tracker` in `## Project Config`). Approved fixes go one tier at a time, Must fix first.

## Tone
Lead with business impact. Each finding ≤2 sentences. No preamble, praise, or filler. Max 5 per tier; list the rest briefly.
