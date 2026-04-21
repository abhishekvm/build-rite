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
**Summary** — assessment, maturity (`early`/`mid`/`production-ready`), strengths, weaknesses
**Findings** — by concern. Each: What · Where · Why · Impact (Critical/High/Medium/Low) · Approach (no code). Include quick wins and prod risks inline.
**Actions** — prioritized: Critical fixes → Stabilize → Scale

## Follow-up
1. "Update READMEs and CLAUDE.md?" → edit docs
2. "File as issues?" → configured tracker
3. Log: `## Last Health Review` in project CLAUDE.md — date, focus, maturity, finding count
4. If issues were filed: "Ready to pick the next batch? → `/br-plan`"
