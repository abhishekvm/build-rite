# Checks

Report verification results in this shape (omit rows that don't apply):
```
Checks
  Lint    ✓ clean          (or ✗ N errors — <first error>)
  Types   ✓ clean          (or ✗ skipped — no type check configured)
  Tests   ✓ N passed       (or ✗ N failed — <test name>)
  Status  ✓ healthy        (or ✗ unhealthy — <response>)
  Deps    ✓ no advisories  (or ✗ N advisories — <ids>)
  Proof   ✓ N new tests red on base, green on branch  (or ✗ <test> passes on base)
```

## Proof
Behavior change (per **TDD Flow** in `.claude/rules/br-standards.md`): run the new tests against the base in one proof worktree per branch (not stash) — created once at the base, reused across fixes and review rounds, removed at wrap-up; run only the new tests there. They must fail on behavior, not on import or collection; a test that already passes on the base proves nothing — flag it.

## State
A findings table from a turn that also made edits carries a State per row: fixed · partly fixed · not fixed · new · skipped (+ reason).

## Deps audit
Run when a manifest or lockfile changes, and in every health review:
- uv: `uv audit --frozen` · plain pip: `uvx pip-audit -r requirements.txt` · Node: the lockfile's `npm`/`pnpm`/`yarn audit --audit-level=high`
- Open Dependabot alerts: `gh api "repos/{owner}/{repo}/dependabot/alerts?state=open" --paginate` (filters go in the URL — `-f` would make it a POST)
- Lockfile created, re-resolved or moved to another package manager → a frozen install with an empty cache and `CI=true` before pushing; a warm cache skips policies CI enforces.
- An unreachable advisory with no fix → `--ignore-until-fixed <id>` with a written reason, never a silent skip.
