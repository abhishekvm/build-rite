---
description: "Pre-flight validate → deploy → health check"
---

# Deploy

Parse `$ARGUMENTS`: environment name → deploy to that env · None → ask which environment.

Read `## Common Commands` and `## Project Config` from project CLAUDE.md for deploy command, env config, and health check URL.

## 1. Pre-flight
Check before deploying — stop if any fail:
- **Env vars** — required keys set, no placeholders (`<YOUR_KEY>`, `changeme`, `TODO`); `.env` / secrets file exists for target env
- **Lock file** — in sync with manifest (`uv.lock` / `package-lock.json` / `poetry.lock`)
- **Audit** — run `pip-audit` (Python) or `npm audit --audit-level=high` (Node) if available
- **Config** — YAML/TOML/JSON parse clean; no localhost / dev URLs in prod config
- **Git state** — on a branch (not default) or confirm intentional; no uncommitted changes that belong in this deploy

Show a single summary line per check. On any fail: list what needs fixing, stop.

## 2. Deploy

Show this block and wait for explicit "go":
```
Ready to deploy
  Command      <deploy command from CLAUDE.md>
  Environment  <env>    ← verify this is what you intended (dev / int / prod)
  Branch       <current branch>
  Commit       <short sha> — <last commit subject>
```
If the user corrects the env, re-resolve the command and re-confirm. For Terraform: include workspace/var-file in the Command line so the target is visible.

Run the deploy command from `## Common Commands` in CLAUDE.md.
Stream output — do not suppress.
If deploy command exits non-zero: capture last 30 lines of output, diagnose root cause, suggest one fix. Do not retry automatically — ask first.

## 3. Health check
After deploy completes, verify the service is healthy:
- Check `## Smoke Test` or `## Common Commands` in CLAUDE.md for health check command/URL
- If configured: run it, wait up to 60s for healthy response
- If not configured: detect from stack (FastAPI → `GET /health` or `/docs`, Node → `GET /health`, etc.)
- On failure: show response, diagnose, stop — do not redeploy automatically

Show final status:
```
Deploy
  Status       ✓ healthy       (or ✗ unhealthy — <response>)
  Environment  <name>
  Endpoint     <URL if known>
```

## 4. Post-deploy
- Note any follow-up: migrations to run, cache to warm, feature flags to flip
- Ask: "Update deployment notes in CLAUDE.md?"

## 5. Release (production deploys only)
Skip for dev/staging environments.

If deploying to production and `git-cliff` is installed (`git cliff --version`):
- Ask: "Tag a release and publish changelog?"
- If yes:
  1. Preview: `git cliff --unreleased` — show what will be in the release notes
  2. Ask for version tag: suggest next semver based on commit types (`feat:` → minor, `fix:` → patch, breaking → major)
  3. Generate and commit: `git cliff --tag <vX.Y.Z> -o CHANGELOG.md`
  4. Stage and commit: `git add CHANGELOG.md && git commit -m "chore: release <vX.Y.Z>"`
  5. Publish: `gh release create <vX.Y.Z> --title "<vX.Y.Z>" --notes-file <(git cliff --latest)`
  6. Confirm: show the GitHub Release URL

If `git-cliff` not installed: skip silently — do not suggest installing mid-deploy.
