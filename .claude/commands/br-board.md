---
description: "Director-style board health across current + next release: slip risk, hygiene, flow, load, drift"
---

# Board

Read-only health report for the **current and next release** on your ticket board. No ticket edits.

Parse `$ARGUMENTS`: `--mode daily|weekly|full` (default `full`) · `--release current|next|both` (default `both`)

## 1. Config

Read `## Project Config` from project CLAUDE.md:
- `Tracker:` — `gh` / `linear` / `jira` / `other` (required)
- `Release marker:` — how a ticket's release scope is bounded (label prefix like `release:`, milestone name pattern, fix version, etc.)
- `Planning doc:` — where the SP→hours convention + per-person allocations live (path in repo, doc title, URL, …)

Any missing → ask once, offer to write to CLAUDE.md.

If the tracker requires tooling that isn't configured (e.g. `linear` with no Linear MCP, `jira` with no API token), **stop and tell the user what to set up**. Do not fall back silently or fake data.

## 2. Identify current + next release

Per tracker:
- `gh`: list milestones by due date · current = soonest future · next = one after
- `linear`: list issue labels matching `Release marker:` prefix · sort by date · pick two earliest future
- `jira`: list unreleased fix versions · sort by release date · pick two earliest
- `other`: ask user to paste the two release identifiers

Only one future release exists → report it as `current`, note "no `next` defined — grooming gap" in the readiness section, continue.

## 3. Conventions + allocations

Read planning doc per `Planning doc:` config. Parse:
- **SP→hours** — default `1 SP = 2 h · 6.5 productive h/day · 3.25 SP/day at 100%`. Doc overrides win.
- **Allocations table** — `name | % this week | notes`. Missing person → assume 100%, flag.

## 4. Fetch

For each of (current, next):
- **In-release tickets**: filter by release marker, all states, limit 250
- **Deltas**: tickets updated in window — `-P1D` (daily) / `-P7D` (weekly)

Plus once:
- **Groomed-but-unlabeled** sample: tickets without any release marker but with priority + estimate + assignee already set — used for next-after-next readiness

## 5. Compute

For each release independently:

**Slip risk** (anchored on release end date → `workdays_left`):
- `remaining_SP = Σ estimate where statusType != completed`. Missing estimate → 3 SP, flag in hygiene.
- `capacity = Σ alloc% × 3.25 SP × workdays_left`
- `slip% = remaining / capacity` · 🔴 >100% · 🟡 90–100% · 🟢 <90%

**Hygiene** (strict for both releases):
- Missing priority / estimate / assignee per ticket → any gap = 🔴 at the release level
- List the top offender tickets in drill-down

**Load** per assignee in that release: `assigned_SP / (alloc% × 3.25 × workdays_left)`

**Drift** (current release only): tickets carrying the release marker whose `updatedAt` is after the most recent Monday — "added after freeze"

Cross-release:

**Flow** (whole board): in-progress count · aging > 2 workdays (by `startedAt`) · blocked-label count

**Next-after-next readiness**: count of groomed-but-unlabeled tickets · target ≥ 12 for a full week

**Deltas**: created / started / completed / status-moves in the window

## 6. Render

`full` (default) — side-by-side current + next, then board-wide rows:
```
BOARD HEALTH — 2026-XX-XX

                          CURRENT (release-A, 5d)      NEXT (release-B, 10d)
▶ SLIP RISK               🔴 118%  84/71 SP            🟢  45%  18/40 SP
▶ HYGIENE                 🔴 4 gaps                    🟡  6 gaps
▶ DRIFT                   🟡 2 added post-freeze       n/a
▶ LOAD top offender       alice 140%                   bob 92%

▶ FLOW (board)            🟢   in-progress: 3 · aging >2d: 0 · blocked: 0
▶ READINESS (after next)  🟡   4 groomed candidates (target ≥ 12)
▶ DELTAS (24h)            +3 created · 0 started · 0 done · 0 moves

LOAD (current release, weighted by allocation)
  alice        [████████████████░]  140%   8 tix
  bob          [████████████░░░░░]  105%   5 tix
  carol        [██████░░░░░░░░░░░]   45%   2 tix
  dave         [██░░░░░░░░░░░░░░░]   18%   1 tix   ← headroom

Drill-down (red/amber only):
  Hygiene current  TIX-12 (no est) · TIX-19 (no prio) · TIX-23 (no est, no prio)
  Hygiene next     TIX-30 (no assignee) · TIX-31 (no est)
  Drift            TIX-43 added 2026-XX-XX 14:22 by alice
  Next-after-next  18 unlabeled tickets on the board, only 4 fully groomed
```

`daily` — top-line two-column table + DELTAS only. No load bars, no drill-down.

`weekly` — `full` + per-person narrative paragraph (one line each) + WoW deltas using `-P7D` window.

## 7. Footer

```
Inputs
  Tracker          <gh|linear|jira|other>
  Planning doc     ✓ read · N people configured
  Estimate default ✓ 1 SP = 2 h (from doc)
  Current release  <id> · ends YYYY-MM-DD
  Next release     <id> · ends YYYY-MM-DD
```

Never post the report to the tracker, Slack, or anywhere else without explicit user request — scheduling is phase 2 (`/schedule`).
