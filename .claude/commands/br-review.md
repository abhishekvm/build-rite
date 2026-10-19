---
description: "Severity-tiered code review (yours or others') — built-in /code-review engine + author-aware fixing and posting"
argument-hint: "[pr-number | branch | file] [low|medium|high|max] [loop]"
disable-model-invocation: true
---

# Review

The bug hunt runs on the built-in `code-review` skill. This command adds what it lacks: the intent check, dedup against prior comments, and author-aware fixing/posting. No file edits until explicitly asked (`loop` is that ask). If clean, say so briefly.

Parse `$ARGUMENTS`: PR number → `gh pr diff` + linked tickets · Branch → `git diff <default-branch>...<branch>` · File → recent changes · None → uncommitted or branch diff. Optional level (default `medium`). `loop` → **Loop mode** below (own work only).

## Steps
1. **Context & prior comments** — per **Context gathering** + **Prior comments** in `.claude/reference/review-contract.md`.
2. **⏸ Checkpoint: business logic** — state what the change is trying to do and compare it with the PR description / ticket. Flag a divergence or a vague description. Wait for confirmation. Unattended → write the intent statement into the run report marked unconfirmed and continue.
3. **Run the `code-review` skill** with an explicit target — the PR number, or the branch name for a branch diff (with no target it reviews only commits ahead of upstream, which is empty after a push) — at the user's level or `medium`. Use `max` when the diff touches auth, payments, the data layer, migrations, IAM, secrets, or a widely called utility, and suggest `/code-review ultra` for the riskiest (cloud, billed — only the user can launch it). Never pass `--comment` or `--fix`: posting and fixing go through step 6.
4. **Add what it doesn't check** (skip silently when N/A):
   - **Secret scan** — matches against **Secret patterns** in `.claude/CLAUDE.md` → `Must fix`
   - **Dependencies** — manifest or lockfile touched → the Deps audit in `.claude/reference/checks.md`; new advisory → `Must fix`
   - **Migration safety** — destructive op without rollback, `NOT NULL` without default or backfill → `Must fix`; new code reads a column, table or view the deploy path doesn't create before the code serves (existing databases, objects built by older code) → `Must fix`; no rollback path → `Should fix`
   - **Phantom code** — code nothing reaches; tests that assert nothing, repeat another, test only a stand-in, or are skipped for a stale reason → `Should fix` (confirm with a repo-wide search first)
   - **Removed fallbacks** — a default replaced by a refusal: list the callers and what the default was quietly handling; one that now breaks → `Must fix`
   - **Decisions** — contradicts an `accepted` ADR without updating it → `Must fix`; makes or reverses a hard-to-reverse choice with no ADR change → `Should fix` (`.claude/reference/delivery.md`)
   - **API docs** — `## API Docs` configured and a new endpoint lacks the stack's annotation → `Should fix`
   - **Business coverage** — intent fully met? Missing requirements? Scope creep?
5. **Merge and dedup** — tier each `code-review` finding by impact: wrong result, security, data loss → `Must fix`; other correctness → `Should fix`; reuse/simplification/efficiency cleanups → `Should fix` or `Nice to have`. Write each in the **Finding shape**, then apply **Dedup against prior comments** from the review contract.

   | # | Item | Severity | State |
   |---|------|----------|-------|

   State once any fix has landed — **State** in `.claude/reference/checks.md`.

   Must fix · Should fix · Open question · Nice to have
6. **Route by author** per **Posting flow** in `.claude/reference/review-contract.md`. Own PR: trivial fixes → offer to apply in place; judgment calls → discuss first; too large for this PR → suggest a follow-up issue in the configured tracker (`Tracker` in `## Project Config`). Approved fixes go one tier at a time, Must fix first.

## Loop mode
Review → fix → re-review until clean, for your own branch or PR (others' PRs: refuse `loop`, review once). `/br-impl` runs this as its self-review; the user can run `/br-review <target> loop` any time.
1. **Round 1** — steps 1–5 at the given level (`high` default; `max` for the risk areas in step 3).
2. **Fix** every confirmed `Must fix` and `Should fix` — `loop` is the user's pick, so no per-tier approval. Confirm each claimed bug in the code first (**Verify before reporting** in `.claude/CLAUDE.md`); a refuted one is dropped with a one-line reason. Each behavior fix gets a **Proof** test (`.claude/reference/checks.md`). Too large for this PR → follow-up issue draft, not a fix. `Nice to have` and `Open question` are listed, not applied. Commit the round (`fix: review round <n>`), re-run the checks.
3. **Re-review** — steps 3–5 on this round's fix diff only (`git diff <previous-round-sha>..HEAD`), and mark every earlier finding's State against HEAD. New `Must fix` / `Should fix` → back to 2. The final clean round reviews the full branch diff once.
4. **Close** — once a round finds none, run the `ponytail-audit` skill on the changed files once; its Must/Should fix starts one more round.
5. **Stop** when a round is clean, or after 3 rounds → show what's still open and stop. Report: rounds run, the findings table with State, checks.

## Tone
Lead with business impact. Each finding ≤2 sentences. No preamble, praise, or filler. Max 5 per tier; list the rest briefly.
