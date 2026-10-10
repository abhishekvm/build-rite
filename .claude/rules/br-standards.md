---
description: Code standards — TDD flow + quality drift guards
paths: ["src/**", "lib/**", "app/**", "tests/**", "test/**", "**/*.py", "**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.go", "**/*.rs"]
---

# Code Standards

## TDD Flow

**Applies to behavior changes** — new features, bug fixes, any change to what the code *does*. For work that changes structure without changing behavior (refactors, renames, formatting), config-only edits, or throwaway spikes, test-first doesn't apply: keep the existing suite green instead and skip step 2. When unsure whether a change is behavioral, treat it as behavioral.

1. Read the task from your tracker (GitHub Issues, Linear, Jira, or local task file)
2. Write a failing test first — confirm it fails for the right reason
3. Implement minimum code to pass
4. Full suite green — use test command from `## Common Commands` in CLAUDE.md
5. Lint clean — use lint command from `## Common Commands` in CLAUDE.md
6. Commit — explicit staging (`git add <files>`)

For a behavior change: NEVER skip step 2. ALWAYS: NEVER delete a test to make the suite green, and NEVER proceed to the next task on a red suite.

### What to Test (defaults — override in project CLAUDE.md)

- Every endpoint: happy path + error cases
- WebSocket messages and service layer
- Component renders, store transitions, API calls (mocked at boundary)
- Error paths and edge cases as thoroughly as happy paths

## Clean Code — Drift Guard

Rules Claude follows naturally (SOLID, DRY, KISS, guard clauses) are omitted. These are the ones it drifts on.

### Naming
- Booleans: `is/has/should/can/will` prefix — no bare adjectives (`valid` → `isValid`)
- One word per concept — don't mix `fetch`/`retrieve`/`get` for the same operation

### Functions
- ≤3 params — group beyond that into an options object
- No boolean params — split into two functions or use options object

### Error handling
- Never swallow exceptions silently — log or propagate
- Error messages include context: what was attempted, what failed, why

### Security
- Parameterized queries — never string-concat SQL
- Never hardcode secrets — use env vars or vaults
- Never log sensitive data (passwords, tokens, PII)
