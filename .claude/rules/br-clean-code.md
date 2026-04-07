---
description: Code quality rules Claude tends to drift on
paths: ["src/**", "lib/**", "app/**", "tests/**", "test/**", "**/*.py", "**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "**/*.go", "**/*.rs"]
---

# Clean Code — Drift Guard

Rules Claude follows naturally (SOLID, DRY, KISS, guard clauses) are omitted. These are the ones it drifts on.

## Naming
- Booleans: `is/has/should/can/will` prefix — no bare adjectives (`valid` → `isValid`)
- One word per concept — don't mix `fetch`/`retrieve`/`get` for the same operation

## Functions
- ≤3 params — group beyond that into an options object
- No boolean params — split into two functions or use options object

## Error handling
- Never swallow exceptions silently — log or propagate
- Error messages include context: what was attempted, what failed, why

## Security
- Parameterized queries — never string-concat SQL
- Never hardcode secrets — use env vars or vaults
- Never log sensitive data (passwords, tokens, PII)
