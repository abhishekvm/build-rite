---
description: "Read-only analysis → delivery stories with demo steps + engineering sub-issues (can file tickets)"
argument-hint: "[ticket-id | description | path]"
disable-model-invocation: true
---

# Plan

Read-only. No code edits. Plans are disposable — never committed; requirements and ADRs are records and go through PRs.

Parse `$ARGUMENTS`: Ticket ID (`#123`, `PROJECT-43`, `ENG-100`) → fetch from tracker · Text → brainstorm · Path → plan changes · None → ask

## Tracker
Read `## Project Config` from project CLAUDE.md. If not configured, ask once.
Fetch: `gh:` → `gh issue view` · `linear:` → its CLI or API · Other → ask user to paste.

## Steps
1. **Understand** — fetch the ticket or parse the statement; read the relevant code and `docs/requirements.md` / `docs/adrs/` if present; palace recall per **Memory** in `.claude/CLAUDE.md`. 1-2 clarifying questions max.
2. **Plan** — open with the problem: current state, expected state, why the gap matters. Then cut the work per **Chain** in `.claude/reference/delivery.md`: delivery stories (vertical, `R-` ids, acceptance criteria, demo steps) and the engineering stories under each. Every story gets concrete steps — What (`src/auth.py:validate_token`, not "update auth"), Why, Depends on, Verify.
3. **Decisions** — per **Decisions** in the reference: small ones go in the story; a hard-to-reverse one becomes the story's thinking step, ending in an ADR (name the existing ADR to update, or "new ADR: <topic>").
4. **Risks** — shared or critical code, rollback needs, meaningful alternatives.
5. **Order and sizing** — stages by dependency, grouped by stream, sized per the reference.
6. **Persist** — invoked from an existing ticket → show the plan as a comment (scope in/out, stories, decisions, risks), post on "yes", before hand-off, so the plan survives the session.
7. **Hand off:**

   ```
   Plan complete. What next?
   A) File tickets + implement first   (delivery story as parent, engineering stories as sub-issues; then branch + impl)
   B) File tickets only
   C) Implement now                    (no new tickets)
   D) Just the plan
   ```
   Filing: show every ticket's text first and file on "go" — delivery story as the parent issue, engineering stories as sub-issues (or "blocks" links when one serves several). From an existing ticket, it becomes the delivery story.
   A or C: read `.claude/commands/br-impl.md` and follow it with this plan as input (you can't invoke `/br-impl` yourself) — a branch is always created before any code is written.
