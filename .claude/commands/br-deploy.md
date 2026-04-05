---
description: "Pre-flight validate → deploy → health check"
---

# Deploy

Parse `$ARGUMENTS`: environment name → deploy to that env · None → ask which environment.

Read `## Common Commands` and `## Project Config` from project CLAUDE.md for deploy command, env config, and health check URL.

## 1. Pre-flight
Run all checks before touching deployment. Stop and report if any fail — do not deploy with known issues.

**Environment config:**
- Check required env vars are set (no placeholders like `<YOUR_KEY>`, `changeme`, `TODO`)
- Verify `.env` / secrets file exists for target environment
- Flag any var present in code but missing from env file

**Dependencies:**
- Lock file present and in sync with dependency manifest (`uv.lock` / `package-lock.json` / `poetry.lock`)
- No known vulnerable packages — run `pip-audit` (Python) or `npm audit --audit-level=high` (Node) if available

**Config files:**
- No syntax errors in key config files (YAML, TOML, JSON) — parse and validate
- No references to localhost or dev URLs in production config

**Git state:**
- On a branch (not default branch) or confirm intentional deploy from main
- No uncommitted changes that should be part of this deploy

Show pre-flight summary before proceeding:
```
Pre-flight
  Env vars     ✓ all set       (or ✗ missing: KEY1, KEY2)
  Lock file    ✓ in sync       (or ✗ out of sync — run install first)
  Audit        ✓ clean         (or ✗ 2 high severity vulns)
  Config       ✓ valid         (or ✗ syntax error in config.yaml:12)
  Git state    ✓ clean         (or ✗ 3 uncommitted files)
```

If any check fails: stop. List what needs fixing. Do not proceed.

## 2. Deploy
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
- Never auto-update

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
