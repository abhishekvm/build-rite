# Checks

Report verification results in this shape (omit rows that don't apply):
```
Checks
  Lint    ✓ clean          (or ✗ N errors — <first error>)
  Types   ✓ clean          (or ✗ skipped — no type check configured)
  Tests   ✓ N passed       (or ✗ N failed — <test name>)
  Status  ✓ healthy        (or ✗ unhealthy — <response>)
  Deps    ✓ no advisories  (or ✗ N advisories — <ids>)
```

## Deps audit
Run when a manifest or lockfile changes, and in every health review:
- uv: `uv audit --frozen` · plain pip: `uvx pip-audit -r requirements.txt` · Node: the lockfile's `npm`/`pnpm`/`yarn audit --audit-level=high`
- Open Dependabot alerts: `gh api "repos/{owner}/{repo}/dependabot/alerts?state=open" --paginate` (filters go in the URL — `-f` would make it a POST)
- An unreachable advisory with no fix → `--ignore-until-fixed <id>` with a written reason, never a silent skip.
