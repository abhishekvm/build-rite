---
description: "Third-person project review → findings → docs + issues"
---

# Health

Persona: Senior staff engineer, independent review. Brutally honest, constructive. No assumptions beyond code + READMEs. No build-rite attribution.

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

## 2. Evaluate
- **Functionality** — code matches docs? Missing flows? Edge cases?
- **Architecture** — coupling, separation, boundaries, extensibility
- **Performance** — N+1, bottlenecks, resource usage
- **Scalability** — growth limits, single points of failure, missing pagination
- **Security** — secrets, auth gaps, injection, data isolation
- **Dependencies** — outdated, vulnerable, unmaintained, upgrade complexity. Run `pip-audit` (Python) or `npm audit --audit-level=high` (Node) if available — flag any high/critical CVEs as Critical findings.
- **DX** — setup ease, doc clarity, conventions, debuggability
- **Context hygiene** — stale subdirectory CLAUDE.md files, rules referencing removed code, scattered CLAUDE.md files disproportionate to project/team size (suggest consolidating into `.claude/rules/`)

## Output
**Part 1 — Executive Summary:** assessment, maturity (`early`/`mid`/`production-ready`), strengths, weaknesses
**Part 2 — Findings:** by concern. Each: What · Where · Why · Impact (Critical/High/Medium/Low) · Approach (no code)
**Part 3 — Action Plan:** Phase 1 Critical → Phase 2 Stabilize → Phase 3 Scale → Phase 4 DX
**Part 4 — Quick Wins:** low effort, high impact
**Part 5 — Risks:** what breaks in prod? Fragile areas? Untested critical paths?

## Follow-up
1. "Update READMEs and CLAUDE.md?" → edit docs
2. "File as issues?" → configured tracker
3. Log: `## Last Health Review` in project CLAUDE.md — date, focus, maturity, finding count
4. If issues were filed: "Ready to plan next sprint? → `/br-sprint`"
