---
description: TDD flow — applied to every implementation task, no exceptions
---

# TDD Flow

1. Read the task from your tracker (GitHub Issues, Linear, Jira, or local task file)
2. Write a failing test first — confirm it fails for the right reason
3. Implement minimum code to pass
4. Full suite green — use test command from `## Common Commands` in CLAUDE.md
5. Lint clean — use lint command from `## Common Commands` in CLAUDE.md
6. Commit — follow `br-commits.md` (approval gate, explicit staging)

NEVER skip step 2. NEVER delete a test to make the suite green.
NEVER proceed to the next task without completing this full cycle.

## What to Test (defaults — override in project CLAUDE.md)

- Every endpoint: happy path + error cases
- WebSocket messages and service layer
- Component renders, store transitions, API calls (mocked at boundary)
- Error paths and edge cases as thoroughly as happy paths

## Visual Testing (optional — only if configured in project)

Three tiers — adopt incrementally, none are required:

| Tier | What | When to add |
|------|------|-------------|
| **Flow** | Maestro (RN/Expo) or Playwright (web) flow files in `flows/` | First UI screen built |
| **Pixel diff** | Baseline screenshots in `baselines/`, diff on every PR | Once flows are stable |
| **Claude review** | On-demand only — not in automated loop | New screen or visual bug |

Check `## Visual Testing` in project CLAUDE.md for configured tools and commands.
If not configured: skip silently — do not block the TDD cycle.
