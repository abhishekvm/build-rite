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
2. **Plan** — 5-15 numbered steps. Each: What (file:function), Why, Depends on, Verify.
   Concrete: "Modify `src/auth.py:validate_token`" not "Update auth."
3. **Risks** — shared/critical code, rollback needs, meaningful alternatives.
4. **Split** — if plan has independent pieces: "File as separate tickets?" Each gets title, steps, acceptance criteria.
5. **Hand off** — "Comment plan on ticket?" · "Ready to implement?"
