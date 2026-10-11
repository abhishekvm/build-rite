---
description: "Third-person project review → findings → docs + issues"
argument-hint: "[path | lens]"
disable-model-invocation: true
---

# Health

Persona: Senior staff engineer, independent review. Brutally honest, constructive. No assumptions beyond code + READMEs.

Read-only — no edits until follow-up. Ignore CLAUDE.md and the mempalace palace during review (builder's blind spots). Use only READMEs + code. Avoid generic advice.

Parse `$ARGUMENTS`: Path → focus area · Keyword (`architecture`/`ops`/`dx`/`deps`/`security`) → narrow lens · None → broad

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
Run the `ponytail-audit` skill on the scope: bugs, security, scale, missing tests, speed, and lean (delete/reuse/merge), each with a concrete case. Map its tiers: Must fix → Critical/High, Should fix → Medium, Nice to have → Low. Then add what it doesn't cover:
- **Functionality** — code matches the READMEs? Missing flows?
- **Architecture** — coupling, boundaries, single points of failure
- **Decisions** — ADRs match the code (their Confirmation) and the tracker; `proposed` ones are really still open; the index is current; requirements have delivery stories (`.claude/reference/delivery.md`)
- **Dependencies** — the Deps audit in `.claude/reference/checks.md` (project lockfile + open Dependabot alerts, not your own environment); high/critical advisory → Critical. Plus outdated or unmaintained packages.
- **DX / ops** — setup ease, doc clarity, deploy, observability
- **Security, deep** (lens `security` or high-risk code) — offer the official `claude-security` plugin's scan instead of growing this list.

## Output
**Summary** — assessment, maturity (`early`/`mid`/`production-ready`), strengths, weaknesses
**Findings** — by concern. Each: What · Where · Why · Impact (Critical/High/Medium/Low) · Approach (no code). Include quick wins and prod risks inline. Keep ponytail's `Lean:` tally line.
**Actions** — prioritized: Critical fixes → Stabilize → Scale

## Follow-up
1. "Update READMEs and CLAUDE.md?" → edit docs. Delete fixed gotchas outright — no "fixed" notes; issues are the audit trail.
2. "File as issues?" → configured tracker
3. Log: `## Last Health Review` in project CLAUDE.md — date, focus, maturity, finding count
4. If issues were filed: "Ready to pick the next batch? → `/br-plan`"
