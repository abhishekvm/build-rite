# Smoke Test Signals

Used by `br-impl` §4b when no explicit smoke test is configured in project CLAUDE.md.

| Signal | What to run |
|--------|-------------|
| `*.tf` files | `terraform validate && terraform plan` — flag unexpected destroys, no apply |
| `cdk.json` | `cdk synth && cdk diff` — flag unexpected removals |
| Monorepo (`pnpm-workspace`, `nx.json`, `packages/`, `apps/`) | Start only affected packages → E2E flow from acceptance criteria → tear down |
| `docker-compose*.yml` | `docker compose up -d <affected>` → smoke → `docker compose down` |
| HTTP server | Start server → curl changed endpoints → check status + shape → stop |
| Frontend | Run `build` — confirm zero errors |
| Library / CLI | `node -e "require('./dist')"` or equivalent |

No signal match → skip with a note.
