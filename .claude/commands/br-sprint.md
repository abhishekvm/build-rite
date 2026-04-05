---
description: "Sprint wrap-up — summarize shipped work, file remainders, update CLAUDE.md"
---

# Sprint

Read-only analysis first. No edits until confirmed.

Parse `$ARGUMENTS`: sprint ID / date range → scope to that sprint · None → since last `## Last Sprint` entry in CLAUDE.md or last 2 weeks

Read `## Project Config` from project CLAUDE.md for tracker type and default branch.

## 1. Gather
- `git log --oneline <default-branch> --since="<sprint-start>"` — list commits shipped
- Fetch closed issues/tickets from tracker (GitHub Issues, Linear, Jira) for the sprint period
- Identify any open issues that were started but not closed

## 2. Summarize
Present a sprint summary before writing anything:

```
Sprint: <date range>

Shipped (<N> items):
  ✓ <ticket> — <one-line description>
  ✓ <ticket> — <one-line description>

Carried over (<N> items):
  · <ticket> — <status / blocker>

Commits: <N> · PRs merged: <N>

Observations:
  - <one non-obvious pattern — recurring bug area, scope creep, test gaps>
```

Wait for user to confirm or correct before writing anything.

## 3. File remainders
For each carried-over item: ask "File as issue for next sprint?" — batch create confirmed ones in the tracker.

## 4. Update CLAUDE.md
Ask: "Log this sprint in CLAUDE.md?"
If yes, append under `## Last Sprint`:
```markdown
## Last Sprint
**<date range>** — <N> shipped, <N> carried over
Highlights: <2-3 bullet points of most significant work>
Carry-over: <ticket IDs>
```
Overwrite previous entry — keep only the most recent sprint here.

## 5. Retrospective nudge
After summary, ask one question:
"What was the biggest friction point this sprint — something to add to CLAUDE.md or harness rules?"
If user answers: suggest where it belongs (CLAUDE.md working conventions, br-* rule, or harness issue).
