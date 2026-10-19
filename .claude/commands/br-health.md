---
description: "Independent audit: code + runtime + cloud + CI/CD → verified, ranked findings → report + docs + issues"
argument-hint: "[path | lens | quick]"
disable-model-invocation: true
---

# Health

Persona: independent principal-engineer consultant. Brutally honest, constructive. Every claim carries evidence.

Read-only: no edits, no writes to any service, until the follow-up. CLAUDE.md and the mempalace palace are the builder's view. Read CLAUDE.md only for house conventions (patterns that look like bugs but aren't) and known or decided issues. Never use it as evidence that something works.

Parse `$ARGUMENTS`:
- `quick` → single-pass review (see **Quick mode**)
- path → focus area
- lens (`security`/`tenancy`/`perf`/`reliability`/`infra`/`cicd`/`deadcode`/`deps`/`dx`) → only the matching reviewers
- none → full audit

Full mode runs a multi-agent Workflow (≈20 finders plus verifiers; a 140k-line repo took about 75 agents and 90 minutes). Invoking `/br-health` is the opt-in. Say the expected scale at the Checkpoint.

Supporting files: `.claude/reference/health/` (brief template, `workflow.js`, `metrics.py`, `postprocess.py`, report template, narrative skeleton). Scratch work goes in the session scratchpad as `<wd>`.

## Pre-check
- Project CLAUDE.md `## Last Health Review`: skip recently covered areas unless they changed significantly.
- REST API without `## API Docs` in project CLAUDE.md → **Medium**: "API docs not configured — run `/br-init`."
- `README.md` missing or ≤5 lines → **High**: "README is empty — no entry point for new contributors or users."

## 1. Read cold
As a new hire: READMEs → directory structure → entry points → trace one data flow. Where you get confused is a finding. Then discover the inputs:
- **Target**: the production branch (ask if unclear). Audit a detached worktree of it under `.claude/worktrees/health-<ref>` (Worktrees rule), never the working branch.
- **Runtime**: observability MCP or CLI available? For Datadog, find env and service names (spans grouped by service and env, 7 days).
- **Cloud**: read-only profile + account (`aws sts get-caller-identity --profile <p>`). Expired → hand back `! aws sso login --profile <p>`.
- **Repo settings**: `gh auth status`, owner/repo.
- **House conventions and known issues**: from CLAUDE.md, ADRs, mempalace recall.

**⏸ Checkpoint:** present project purpose, key flows, stack, areas of confusion, plus target ref, runtime/cloud/GitHub access found, proposed code areas (~8, similar size, hotspot module alone), lenses to run or skip and why, expected scale. Wait for confirmation.

## 2. Metrics (no agents)
One plain command each:
- `uvx lizard --csv <src> > <wd>/metrics/lizard.csv` (exclude generated/migrations with `-x`)
- `git -C <checkout> log --since=12.months --no-merges --name-only --format=COMMIT:%s -- <src> > <wd>/metrics/churn.txt`
- dead code → `<wd>/metrics/deadcode.txt` (Python `uvx vulture <src> --min-confidence 80`, TS/JS `npx knip`, Go `deadcode ./...`)
- dependencies → `<wd>/metrics/deps.txt` (Python `uvx deptry .`, JS `npx depcheck`) plus the Deps audit in `.claude/reference/checks.md`
- `python3 .claude/reference/health/metrics.py <wd> <src> [module_depth]` → `<wd>/metrics/SUMMARY.md`; append runtime span counts per service

## 3. Audit
- Fill `.claude/reference/health/brief-template.md` → `<wd>/brief.md`.
- `Workflow({scriptPath: "<abs project root>/.claude/reference/health/workflow.js", args: {...}})`. The args are documented at the top of `workflow.js`: repo, ref, workdir, brief, summary, houseRules, datadog, aws, github, areas, lenses.
- Each P0/P1 gets an adversarial verifier (two for P0 security/tenancy). P2/P3 findings are not verified, so label them that way.
- While it runs, interim findings are in the workflow's `journal.jsonl`. Anything you share from there is unverified, so say so.

## 4. Merge and rank (you, not an agent)
- `python3 .claude/reference/health/postprocess.py merge <workflow .output> <wd>` → `findings.json`, `groups.txt`.
- The auto-merge is conservative. Read `groups.txt`, then force missed duplicates and split wrong merges with `<wd>/overrides.json` (`{"<raw id>": "<group>"}`) and re-run with it as the 4th argument.
- Read every verifier's reasoning on P0/P1 findings. Re-check the top findings in code yourself (Verify before reporting). Report a verifier split, such as one P0 and one P2, as a split.
- Order: P0, then ROI = value ÷ (effort days × change risk).

## Output
1. **In conversation first** (Human-facing output):
   - assessment and maturity (`early`/`mid`/`production-ready`)
   - counts per severity
   - every P0/P1 in plain language
   - 5–7 systemic causes, each with the findings it retires
   - deletion plan total
   - what was not covered
2. **Report**:
   - copy `narrative-skeleton.html` to `<wd>/narrative.html` and fill it
   - `python3 .claude/reference/health/postprocess.py build <wd> <wd>/narrative.html ~/br-reports/<project>-health-<date>.html "<Project> Health" "<ref, SHA, date>"`
   - `node --check` the inline script, then `open` the file
   - the report stays local; publishing or sharing it is a posting action

## Quick mode
One pass, no Workflow: run the `ponytail-audit` skill on the scope (bugs, security, scale, missing tests, speed, lean). Map tiers: Must fix → Critical/High, Should fix → Medium, Nice to have → Low. Add functionality (code vs READMEs), architecture, decisions (ADRs vs code, per `.claude/reference/delivery.md`), dependencies (Deps audit), DX/ops. Output: Summary, Findings (What · Where · Why · Impact · Approach, plus ponytail's `Lean:` tally), Actions.

## Follow-up
1. "Update READMEs and CLAUDE.md?" → edit docs. Delete fixed gotchas outright; issues are the audit trail.
2. "File as issues?" → configured tracker, one issue per P0/P1 and per systemic cause (Confirmation before posting).
3. Log `## Last Health Review` in project CLAUDE.md: date, mode, ref and SHA, maturity, counts per severity, report path.
4. If issues were filed: "Ready to pick the next batch? → `/br-plan`"
