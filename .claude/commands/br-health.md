---
description: "Third-person project review → findings → docs + issues"
---

# Health

Persona: Senior staff engineer, independent review. Brutally honest, constructive. No assumptions beyond code + READMEs.

Read-only — no edits until follow-up. Ignore CLAUDE.md during review (builder's blind spots). Use only READMEs + code. Avoid generic advice.

Parse `$ARGUMENTS`: Path → focus area · Keyword (`security`/`performance`/`architecture`/`scalability`/`ops`/`dx`) → narrow lens · None → broad

## Pre-check
Read project CLAUDE.md `## Last Health Review` — skip recently covered areas unless significant changes since.

If project has a REST API and `## API Docs` not in project CLAUDE.md → flag as **Medium**: "API docs not configured — run `/br-init` to set up auto-generated docs (Scalar for Python/Node, built-in for NestJS/GraphQL)."

Check `README.md` at project root:
- Missing or empty (≤5 lines) → flag as **High** finding: "README is empty — project has no public entry point for new contributors or users."
- Present and non-trivial → continue silently.

## 1. Read cold
As a new hire: READMEs → directory structure → entry points → trace a data flow. Where you get confused = finding.

**⏸ Checkpoint:** Present what you understood — project purpose, key data flows, tech stack, areas of confusion. Wait for user to confirm or correct before deep evaluation.

## 2. Scope
Before fan-out, pick targets — don't review every file. Cost-bound the deep-dive.

- **Graph available?** Use `code-review-graph` MCP: `build_or_update_graph_tool` if stale/missing → `get_hub_nodes_tool` + `list_communities_tool` to pick the 5–10 modules carrying the most risk (high fan-in, central to flows, large communities).
- **No graph?** Fall back to: entry points + `git log --format= --name-only | sort | uniq -c | sort -rn | head -20` (churn) + any directory the user flagged.
- Ask: "Quick (top 5 modules), Standard (top 10), or Deep (all hubs + churn top 20)?" Default Standard.
- Echo the scope list before fan-out.

## 3. Evaluate — parallel specialist lanes
Fan out via the Agent tool. One agent per lane, each gets: the scoped file list, READMEs, and a focused system prompt for its lane only. Each returns findings in standard shape (What · Where · Why · Impact · Approach).

Lanes (drop any that don't apply):
- **security** — secrets, auth gaps, injection, data isolation, IAM/permissions
- **correctness** — functionality vs docs, missing flows, edge cases, error handling
- **architecture** — coupling, separation, boundaries, extensibility, premature abstraction
- **performance** — N+1, hot paths, allocations, sync I/O on async, missing indexes
- **scalability** — growth limits, SPOFs, missing pagination, unbounded queues
- **dependencies** — outdated, vulnerable, unmaintained. Run `pip-audit` / `npm audit --audit-level=high` if available — high/critical CVEs → Critical.
- **dx** — setup ease, doc clarity, conventions, debuggability

Run lanes in parallel (single message, multiple Agent calls). Each agent is read-only.

## 4. Consolidate
Merge lane findings. Dedupe (same file:line + same root cause across lanes → one row, note the lanes that flagged it). Rank by Impact. Drop findings without a concrete impact statement.

## Output
**Summary** — assessment, maturity (`early`/`mid`/`production-ready`), strengths, weaknesses, scope reviewed (modules + lanes).
**Findings** — by concern. Each: What · Where · Why · Impact (Critical/High/Medium/Low) · Lane(s) · Approach (no code). Include quick wins and prod risks inline.
**Actions** — prioritized: Critical fixes → Stabilize → Scale

## Follow-up
1. "Update READMEs and CLAUDE.md?" → edit docs
2. "File as issues?" → configured tracker
3. Log: `## Last Health Review` in project CLAUDE.md — date, focus, maturity, finding count, scope (modules + lanes covered)
4. If issues were filed: "Ready to pick the next batch? → `/br-plan`"
