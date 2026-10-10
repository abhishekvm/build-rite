---
description: "Read-only investigation → evidence, ranked causes, shareable summary (no code change)"
argument-hint: "[symptom | ticket-id | path | dashboard/log URL]"
disable-model-invocation: true
---

# Diagnose

Read-only, hard — no code edits, writes, `apply`, or posting, even to "test a theory". If a write is the only way forward, stop and ask. Ends in an **answer**, not a PR.

Use when the question is *what is happening / why / how much* — incidents, capacity, cost, data quality,
performance, "is this safe to change". If the answer is already known and the work is the change itself,
use `/br-plan` → `/br-impl` instead.

Parse `$ARGUMENTS`: Symptom text → investigate directly · Ticket ID → fetch from tracker · Path → read as context · URL (dashboard, log, PR) → fetch first · None → ask what's wrong

Read `## Project Config` from project CLAUDE.md for tracker, accounts/profiles, environments, cluster names.

## Steps

1. **Frame** — restate in one line: the symptom, the blast radius, and what a good answer looks like
   (a number? a root cause? a go/no-go?). Name what's in and out of scope.

   **⏸ Checkpoint:** Confirm the framing before spending queries. A wrong frame wastes the whole investigation.

2. **Inventory the evidence** — before querying, list what sources can answer this and what each can't:
   metrics, logs, traces, the database, the code, config/IaC, recent deploys, tickets. Say which you'll use.
   Prefer the cheapest source that settles the question. Do not guess when a source is available.

3. **Gather** — run read-only queries. For every source, record the exact query, the time window, and the filters.
   Cross-check any load-bearing number against a second source before it enters the summary. Every figure follows
   **Numbers carry provenance** in `.claude/CLAUDE.md`.

4. **Rank hypotheses** — 2-4 candidate explanations, most-likely first. For each: the evidence for it,
   the evidence against, and the one query or check that would settle it. Say plainly when the data can't distinguish them.
   Check the boring cause first: when one environment works and another doesn't, confirm the failing one points at the
   right target (region, endpoint, account, config copied from the working one) before chasing policies or code.

5. **Text summary first** — per **Human-facing output** in `.claude/CLAUDE.md`:

   ```
   Problem    <what's happening, in plain language>
   Cause      <ranked, with confidence>
   Evidence   <the numbers, each with its source>
   Options    <a, b, c — with trade-offs>
   Next steps <ordered, actionable, owner-able>
   Unknowns   <what we could not determine, and what would settle it>
   ```

   **⏸ Checkpoint:** Wait for the text to be accepted before any formatted deliverable.

6. **Hand off** — offer, don't assume:
   ```
   Diagnosis complete. What next?
   A) Fix it now          (follow .claude/commands/br-impl.md with the findings as the brief)
   B) Plan the fix        (follow .claude/commands/br-plan.md)
   C) Write it up         (artifact / Notion / doc — asks where)
   D) File it             (ticket with evidence attached)
   E) Stop here
   ```

## Constraints

- **Production caution** — prefer read-only roles/profiles. Bounded queries: always a time window, always a limit.
