export const meta = {
  name: 'codebase-audit',
  description: 'Independent read-only audit: code-area + cross-cutting finders, adversarial verify of every P0/P1',
  phases: [
    { title: 'Find', detail: 'code-area reviewers + cross-cutting lenses' },
    { title: 'Verify', detail: 'skeptics try to refute every P0/P1 (2 for P0 security/tenancy)' },
  ],
}

// args (all strings unless noted) — run from /br-health step 3:
//   repo, ref, workdir, brief, summary, houseRules
//   datadog: { env, services: [] } | null      aws: { profile, account } | null      github: 'owner/repo' | null
//   areas: [{ key, p }]                         lenses: ['appsec', ...] (optional subset; default all)
const A = args
const DD = A.datadog
  ? `Datadog (claude.ai Datadog MCP tools, load via ToolSearch; load the relevant datadog skill first): env:${A.datadog.env}; services ${A.datadog.services.join(', ')}. Windows: 30d trends, 7d top-N.`
  : 'Datadog: not available for this project — skip runtime evidence and say so in coverage.skipped.'
const AWS = A.aws
  ? `AWS CLI: always --profile ${A.aws.profile} (account ${A.aws.account}, read-only). If credentials expire, stop that track and say so in coverage.skipped.`
  : 'AWS: not in scope for this project.'
const GH = A.github ? `GitHub repo: ${A.github} (gh CLI, read-only calls only).` : ''

const PREAMBLE = `You are one reviewer in an independent audit.
Codebase: ${A.repo} — a detached checkout of ${A.ref}. Audit THIS checkout only.
FIRST read the audit brief ${A.brief} (taxonomy, severity, ROI, standards, known issues not to re-report) and the metrics ${A.summary}.
Hard rules:
- Read-only. Never edit, create or delete files in the repo; never commit; never write to AWS, Datadog, GitHub or any other service. Scratch files only under ${A.workdir}/work/.
- 12-month git history is exported at ${A.workdir}/metrics/churn.txt (git commands may be refused by a session guard).
- Use rg/grep/Read for code search.
- ${DD}
- ${AWS}
- ${GH}
- Do not run integration tests that need real databases or services. Unit tests only if your track needs coverage.
- House conventions (do not flag these as bugs): ${A.houseRules || 'none given'}
- Every finding needs concrete evidence (file:line snippet, query+numbers, resource config). P0/P1 code-only claims must name the reachable path (URL or job → function → line).
- Report a repeated pattern ONCE with count + 2-3 example sites. Aim for the 5-25 findings that matter in your area, plus dead-code/LOC-reduction candidates.
- Fill value.* scores 1-5, change_risk (1, 1.5 or 2), effort, loc_delta (negative = lines removed). Security/tenancy findings: cwe, cvss (v4 base estimate), soc2_control. standard_ref: e.g. "ASVS 5.0 V8.2.1", "API1:2023", "WA REL09", "Scorecard Pinned-Dependencies", "ISO25010 Maintainability".
Your assignment:
`

const FINDINGS = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'object', properties: {
      title: { type: 'string' },
      category: { type: 'string', enum: ['security','tenancy','data-integrity','reliability','performance','cost','observability','ci-cd','test-gap','dead-code','hygiene','clean-code'] },
      severity: { type: 'string', enum: ['P0','P1','P2','P3'] },
      effort: { type: 'string', enum: ['S','M','L'] },
      confidence: { type: 'string', enum: ['high','medium','low'] },
      evidence_type: { type: 'string', enum: ['code','runtime','both'] },
      location: { type: 'string', description: 'file:line(s) or cloud/observability resource; multiple separated by ;' },
      evidence: { type: 'string' },
      failure_scenario: { type: 'string' },
      blast_radius: { type: 'string' },
      fix: { type: 'string' },
      loc_delta: { type: 'integer' },
      value: { type: 'object', properties: { risk: {type:'integer'}, user_impact: {type:'integer'}, cost_saving: {type:'integer'}, maintainability: {type:'integer'}, unblocks: {type:'integer'} }, required: ['risk','user_impact','cost_saving','maintainability','unblocks'] },
      change_risk: { type: 'number' },
      standard_ref: { type: 'string' },
      cwe: { type: 'string' },
      cvss: { type: 'string' },
      soc2_control: { type: 'string' },
    }, required: ['title','category','severity','effort','confidence','evidence_type','location','evidence','failure_scenario','fix','loc_delta','value','change_risk'] } },
    deletion_candidates: { type: 'array', items: { type: 'object', properties: {
      unit: { type: 'string' }, loc: { type: 'integer' }, static_proof: { type: 'string' }, runtime_proof: { type: 'string' }, removal_risk: { type: 'string' },
    }, required: ['unit','loc','static_proof','removal_risk'] } },
    themes: { type: 'array', items: { type: 'string' } },
    coverage: { type: 'object', properties: { audited: {type:'string'}, sampled: {type:'string'}, skipped: {type:'string'} }, required: ['audited','skipped'] },
  },
  required: ['findings','coverage'],
}

const VERDICT = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['confirmed','downgraded','refuted'] },
    severity: { type: 'string', enum: ['P0','P1','P2','P3','none'] },
    reasoning: { type: 'string' },
    evidence: { type: 'string' },
  },
  required: ['verdict','severity','reasoning'],
}

const AREA_RULES = `Review this code area across ALL categories (security, tenancy, data-integrity, reliability, performance, dead-code, clean-code, test-gap...). Start from the hotspot/complex files listed in the metrics summary for your area. Use runtime data for your area's endpoints/jobs when judging performance or dead code (0 traffic in 30d + no static callers = dead).`

const LENSES = {
  appsec: `Application security across the whole codebase, walking OWASP ASVS 5.0 Level 2: authentication & token/session handling (alg pinning, expiry, revocation, refresh), OIDC/OAuth flows (state, redirect URI validation, issuer/tenant pinning, token storage), credential/secret storage (incl. integration tokens at rest), crypto & TLS, input validation/injection (raw SQL, eval, template injection, unsafe deserialization, subprocess), file upload/download, SSRF, security headers/CORS/CSRF/cookie flags, error-message leakage, PII and secrets in logs, security-event logging, secrets committed in the repo.`,
  api: `OWASP API Security Top 10 (2023) across all HTTP endpoints and webhooks. Build the API inventory: endpoints per version, auth/permission per endpoint, anonymous endpoints, admin endpoints, exposed API docs in prod. Check API1 BOLA, API3 property-level authz / mass assignment, API4 unbounded resource use (pagination, throttling), API5 function-level authz (role checks), API6 sensitive business flows (signup, invites, email sending), API7 SSRF, API8 misconfig, API9 inventory (use runtime traffic to find endpoints with 0 hits in 30d), API10 unsafe consumption of third-party/LLM responses. Webhooks: is the signature check mandatory?`,
  tenancy: `Tenant/customer isolation (skip if the product is single-tenant and say so). Understand how tenant scoping is enforced (managers, middleware, row-level security, query helpers). Respect the house conventions in the preamble. Hunt every bypass: unscoped managers or raw SQL, background jobs that run without or with a stale tenant context, principals that authenticate with no tenant (guests, service tokens, webhooks) and whether scoping then fails open, cache keys and storage paths without tenant, signed URLs/cookies scoped too broadly, analytics embeds, realtime channel names, global tables writable by tenant admins. For each, show whether cross-tenant read/write is actually reachable.`,
  async: `Background jobs / async reliability (Celery, Sidekiq, queues, cron, etc.). Check: ack semantics vs timeouts, idempotency, retries with backoff vs none, time limits, lock/singleton correctness, context cleanup between jobs (including on retry), unbounded fan-out, exception swallowing, queue routing vs worker pools, graceful shutdown on deploy (PID 1, SIGTERM, stop timeout), outbound HTTP calls without timeouts anywhere. Use runtime data: job failure rates, durations p95/max, queue latency, retries per job over 30d.`,
  db: `Database & data integrity. Use database monitoring (Datadog DBM if available) for top queries by total time, missing indexes, lock waits, connection usage; map them back to code (N+1, unbounded queries, missing eager loading, app-side aggregation). Data integrity: missing transactions around multi-write ops, races (get-then-create without unique constraint, read-modify-write without locking), soft-delete leaks, events published before commit, risky migrations in the last 12 months. Connection pooling actually in effect? Cloud DB config: size vs load, backups/PITR, multi-AZ, deletion protection, encryption, engine version support dates.`,
  perf: `Performance, runtime-first. From APM (30d/7d): web endpoints ranked by total time (count×avg), p95/p99, error rate; background jobs ranked by total worker time; profiling if available. For the top ~10 offenders, open sample traces, find the dominant spans, locate the responsible code and explain the root cause. Quantify the win (ms saved × requests/day, or worker-hours/day). Do not re-report known items from the brief.`,
  errors: `Errors, runtime-first. Error tracking and error logs (30d): rank error issues by volume and affected customers. For the top ~15, locate the code, decide the root cause, classify (bug, missing validation, unhandled third-party failure, expected condition logged as error). Find jobs failing on every run. Find silent-failure patterns: bare except / swallow-and-continue in data-writing paths.`,
  infra: `Cloud infrastructure review, read-only, against the AWS Well-Architected pillars (adapt if another cloud). Compute (task/instance sizing vs utilisation, secrets in plaintext env vars, task roles, mutable image tags, root containers, health checks, exec/shell access and its logging), load balancers/CDN/WAF (TLS policy, origin bypass), security groups, databases and caches (public access, encryption, AUTH, backups), object storage (public access block, encryption, versioning), IAM (admin roles, OIDC trust conditions, stale keys/roles), secret rotation, CloudTrail/GuardDuty/Config and open findings, log retention, cost (billing data if permitted; idle or oversized resources, DR spend). Map findings to Well-Architected pillar IDs.`,
  cicd: `CI/CD and supply chain against SLSA v1.0 build track + OpenSSF Scorecard. Read CI workflow files, Dockerfiles, deploy scripts: actions pinned by SHA, default token permissions, pull_request_target / script injection, secrets in logs, OIDC vs long-lived keys and how tightly cloud roles trust the CI identity, deploy gating (tests required, protected environments, approvals), deploy order vs migrations, rollback path, image provenance/signing/scanning, base image pinning, lockfile enforcement, dependency audit. Read repo settings via gh api: branch protection/rulesets (may need admin — record if denied), required checks, bypass actors, Actions permissions, secret scanning, Dependabot/code-scanning alert counts. DORA / CI telemetry if available.`,
  obs: `Observability and test gaps. Monitors and SLOs: which critical flows (login, core integrations, background queues and scheduler liveness, webhooks, DB) have no monitor; monitors that notify nobody, are muted, no-data or always alerting; log volume and noise. Tests: measure unit-test coverage if feasible in one honest attempt (else map test files to modules); cross coverage with the hotspot list and security-critical modules (auth, permissions, tenancy, webhooks). Is coverage measured/gated in CI? Flag skipped tests, tests without assertions, over-mocked tests.`,
  deadcode: `Dead code and LOC reduction across the whole codebase. Static: for each endpoint, background job, scheduled entry, CLI command, model, service function, template — is anything referencing it (routing config, scheduler config, string-based dispatch — beware dynamic dispatch)? Runtime: 30d traffic per endpoint and per job; zero hits + no static refs = dead. Verify each unused-dependency candidate from the metrics summary by hand (package name ≠ import name, settings/plugin-only use). Then LOC reduction beyond dead code: duplicated blocks (run a duplicate detector, output under ${A.workdir}/work/), parallel implementations of the same feature, single-caller wrappers, hand-rolled code replaceable by stdlib/installed deps. Produce a ranked deletion plan in deletion_candidates with LOC counts and proof.`,
}

const lensKeys = A.lenses && A.lenses.length ? A.lenses : Object.keys(LENSES)
const items = [
  ...A.areas.map(a => ({ key: a.key, prompt: PREAMBLE + AREA_RULES + '\nArea: ' + a.p })),
  ...lensKeys.map(k => ({ key: 'lens:' + k, prompt: PREAMBLE + LENSES[k] })),
]
log(`${items.length} finders: ${A.areas.length} areas + ${lensKeys.length} lenses`)

const verifyPrompt = (f, n) => `You are an adversarial verifier (#${n}) in an audit of ${A.repo} (${A.ref}, read-only; never edit files or write to any service).
${DD}
${AWS}
House conventions (not bugs): ${A.houseRules || 'none given'}
Your job is to REFUTE this finding. Read the actual code/config/data yourself. Is the path really reachable? Is there a guard elsewhere (middleware, permission, decorator, settings, infra layer) that neutralises it? Is the runtime evidence real and correctly interpreted? Is the severity inflated?
Return verdict: confirmed (as stated), downgraded (real but lower severity — give the right one), or refuted (not real). If you cannot establish it is real, return refuted.

FINDING:
${JSON.stringify(f, null, 2)}`

const results = await pipeline(
  items,
  it => agent(it.prompt, { label: it.key, phase: 'Find', schema: FINDINGS }),
  async (res, it) => {
    if (!res) return null
    const hi = res.findings.filter(f => f.severity === 'P0' || f.severity === 'P1')
    const checked = await parallel(hi.map(f => async () => {
      const n = f.severity === 'P0' && (f.category === 'security' || f.category === 'tenancy') ? 2 : 1
      const votes = (await parallel(Array.from({ length: n }, (_, i) => () =>
        agent(verifyPrompt(f, i + 1), { label: `verify:${it.key}:${f.title.slice(0, 40)}`, phase: 'Verify', schema: VERDICT })))).filter(Boolean)
      return { ...f, verification: votes }
    }))
    const lo = res.findings.filter(f => f.severity !== 'P0' && f.severity !== 'P1')
    log(`${it.key}: ${res.findings.length} findings, ${hi.length} P0/P1 verified`)
    return { source: it.key, ...res, findings: [...checked.filter(Boolean), ...lo] }
  },
)

return results.filter(Boolean)
