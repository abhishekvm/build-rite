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
[MADR 4.0](https://adr.github.io/madr/) format, in `docs/adrs/NNNN-title.md` (keep a repo's existing folder and numbering), listed in `docs/adrs/index.md`.
- **Living record** — an ADR always states the current decision; MADR's `date` is "when the decision was last updated". Change it in place through a PR, update `date`, and add one History line under More Information: date, what changed and why, PR, tracker id. Typo and link fixes need neither. Full trail: `git log --follow -p docs/adrs/<file>`.
- **Supersede only on reversal after shipping** — write a new ADR, set the old one to `superseded by ADR-NNNN`, and leave its body as it was.
- **Index** — current decisions in the main table; superseded and rejected ones in a short table below it.
- **Status** — `proposed` (open, not decided yet) · `accepted` · `rejected` · `deprecated` · `superseded by ADR-NNNN`. **Confirmation** says whether the code matches yet, so an ADR can state the target while the code catches up.

```markdown
---
status: proposed | accepted | rejected | deprecated | superseded by ADR-NNNN
date: YYYY-MM-DD
decision-makers: <roles or people>
---

# <short title naming the problem and the chosen solution>

## Context and Problem Statement
<2-3 sentences; the question being decided; links to the tracker ticket and RFD>

## Considered Options
* <option 1>
* <option 2>

## Decision Outcome
Chosen option: "<option>", because <justification>.

### Consequences
* Good, because <…>
* Bad, because <…>

### Confirmation
Implemented: yes | partial (<what's missing>) | no. Checked by <test, review or fitness function>.

## More Information
<links to related ADRs and docs; when to revisit>

### History
* YYYY-MM-DD proposed. <tracker id>
```
Optional MADR sections — Decision Drivers, Pros and Cons of the Options, `consulted` / `informed` — when the decision needs them.
