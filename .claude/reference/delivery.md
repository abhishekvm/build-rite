# Delivery model

How work is cut and how decisions are recorded. Commands point here — don't restate it.

## Chain
Requirement → delivery story → engineering stories, with an ADR only when a decision needs one.
- **Requirement** (`R-n`) — one plain sentence of business need, listed in `docs/requirements.md` and changed through PRs.
- **Delivery story** — a vertical slice: backend, frontend and deployment together. Carries the `R-` ids it serves, 3–5 acceptance criteria and 3–6 **demo steps** someone can run on the deployed environment. Done = deployed and the demo steps pass. This is the unit you demo.
- **Engineering story** — backend-only, frontend-only or infra: a sub-issue of one delivery story, or "blocks" each one it serves. Has a verify step, no demo.
- **No orphans** — every engineering story has a parent or blocks one; every delivery story lists `R-` ids; every requirement has at least one delivery story.
- **Order and sizing** — stages from dependencies (same stage = can run in parallel), grouped by stream; no per-person lanes. Size as a range at a third of your first estimate (measured), and say the sizing is yours.

## Decisions
- Small decision → write it in the story. Hard to reverse, surprising to a later reader, or a real trade-off → an ADR. Never only in a tracker comment or document row.
- A story's thinking step ends by writing or updating its ADR; the story and the ADR link each other.

## ADRs
`docs/adrs/NNN-slug.md` (keep a repo's existing numbering), listed in `docs/adrs/index.md`.
- **Living record** — an ADR always states the current decision. Change it in place through a PR and add one `## History` line: date, what changed and why, PR, tracker id. Typo and link fixes need no line. Full trail: `git log --follow -p docs/adrs/NNN-*.md`.
- **Supersede only on reversal after shipping** — write a new ADR, set the old one to `Superseded by ADR-NNN`, and leave its body as it was.
- **Index** — current decisions in the main table; superseded ones in a short table below it.
- **Status** — `Proposed` (open, not decided yet) · `Accepted` · `Deprecated` · `Superseded by ADR-NNN`. `Implemented` says whether the code matches yet, so an ADR can state the target while the code catches up.

```markdown
# ADR-NNN: <the decision, as a short statement>

- **Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN
- **Date:** YYYY-MM-DD · **Last reviewed:** YYYY-MM-DD
- **Implemented:** yes | partial (<what's missing>) | no
- **Links:** <tracker ids> · <RFD or design doc>

## Context
## Decision
## Options considered
## Consequences

## History
- YYYY-MM-DD Proposed. <tracker id>
```
Add sections a project needs (for example Compliance notes) after Consequences.
