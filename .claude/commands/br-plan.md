---
description: "Read-only analysis → implementation plan (can generate tickets)"
---

# Plan

Read-only. No code edits. Plans are disposable — never committed.

Parse `$ARGUMENTS`: Ticket ID (`#123`, `PROJECT-43`, `ENG-100`) → fetch from tracker · Text → brainstorm · Path → plan changes · None → ask

## Tracker
Read `## Project Config` from project CLAUDE.md. If not configured, ask once.
Fetch: `gh:` → `gh issue view` · `linear:` → API/curl · Other → ask user to paste.

## Batch mode (no argument)
When called with no argument, suggest the next batch to work on:
1. Fetch all open issues from the tracker
2. Build a dependency graph — issues that block others rank higher
3. Sort remaining by: explicit priority label → milestone → creation date
4. Filter out: blocked issues (waiting on external), issues labeled `blocked`/`wontfix`/`icebox`
5. Suggest 5-10 issues as the next batch:
   ```
   Suggested batch (8 issues):

   Must do first (blockers):
     #31 — Fix auth token expiry (blocks #34, #35)

   High priority:
     #28 — Add pagination to /users
     #29 — Rate limiting on public endpoints

   Good to batch:
     #33 — Update error messages
     #36 — Add request ID to logs
     ...

   Skipped (blocked): #41 (waiting on #31), #44 (external dep)
   ```
6. Ask: "Work this batch?" — if yes, pass the ordered issue list directly to `/br-impl` and start immediately with issue #1. No need to re-invoke anything — br-impl will work through them sequentially, pausing between issues for your review before moving to the next.

## Steps
1. **Understand** — fetch ticket or parse statement. Read relevant code. 1-2 clarifying questions max.
   If ticket involves UI/UX and `## Reference Apps` is NOT in project CLAUDE.md: suggest running `/br-inspire` first — skip this nudge if already locked.
2. **Plan** — 5-15 numbered steps. Each: What (file:function), Why, Depends on, Verify.
   Concrete: "Modify `src/auth.py:validate_token`" not "Update auth."
3. **Risks** — shared/critical code, rollback needs, meaningful alternatives.
4. **Split** — if plan has independent pieces: "File as separate tickets?" Each gets title, steps, acceptance criteria.
5. **Hand off** — "Comment plan on ticket?" · "Run `/br-impl`?"
