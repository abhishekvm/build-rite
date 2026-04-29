---
description: "Read-only analysis → implementation plan (can generate tickets)"
---

# Plan

Read-only. No code edits. Plans are disposable — never committed.

Parse `$ARGUMENTS`: Ticket ID (`#123`, `PROJECT-43`, `ENG-100`) → fetch from tracker · Text → brainstorm · Path → plan changes · None → ask

## Tracker
Read `## Project Config` from project CLAUDE.md. If not configured, ask once.
Fetch: `gh:` → `gh issue view` · `linear:` → API/curl · Other → ask user to paste.

## Steps
1. **Understand** — fetch ticket or parse statement. Read relevant code. 1-2 clarifying questions max.
   If ticket involves UI/UX and `## Reference Apps` is NOT in project CLAUDE.md: suggest running `/br-inspire` first — skip this nudge if already locked.
2. **Plan** — 5-15 numbered steps. Each: What (file:function), Why, Depends on, Verify.
   Concrete: "Modify `src/auth.py:validate_token`" not "Update auth."
3. **Risks** — shared/critical code, rollback needs, meaningful alternatives.
4. **Split** — if plan has independent pieces: "File as separate tickets?" Each gets title, steps, acceptance criteria.
5. **Persist** — if invoked from an existing ticket, post the plan as a comment on that ticket *before* hand-off (`gh issue comment <N>` or tracker equivalent). Include: scope (in/out), files to change, alternatives considered, risks. Show the comment text and ask "Post to #N?" — wait for explicit "yes". This way the plan survives session end regardless of which hand-off option the user picks next.
6. **Hand off** — present options based on how the plan was invoked:

   **If invoked from an existing ticket** (argument was a ticket ID — `#123`, `PROJECT-43`, etc.):
   ```
   Plan complete. What next?
   A) Implement now   (creates branch, starts impl)
   B) Just the plan   (stops here)
   ```

   **If invoked from text / path / no argument** (no pre-existing ticket):
   ```
   Plan complete. What next?
   A) Create issue + implement now   (files ticket, creates branch, starts impl)
   B) Create issue only              (files ticket, stops here)
   C) Implement now                  (no ticket, creates branch, starts impl)
   D) Just the plan                  (nothing filed, stops here)
   ```

   If A or C: pass plan directly to `/br-impl` — a branch is always created before any code is written.
   If A or B: file the issue first, then proceed.
   If plan was split into sub-tickets (step 4): default A becomes "File all tickets + implement first one".
