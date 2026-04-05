---
description: Clean code rules — language-agnostic principles applied during review, simplify, and impl
---

# Clean Code Rules

## Naming
- Names reveal intent — if a name needs a comment, rename it
- Booleans: prefix `is/has/should/can/will` (`isValid`, `hasItems`)
- Functions: verb-noun (`calculateTotal`, `validateEmail`)
- Classes: nouns (`UserRepository`, `PaymentProcessor`) — never vague (`Manager`, `Handler`)
- No abbreviations, no type encoding (`strName` → `name`)
- One word per concept — don't mix `fetch`/`retrieve`/`get` for the same operation

## Functions
- Do one thing — if you need "and" to describe it, split it
- ≤3 params — group beyond that into an object
- No boolean params — split into two functions or use options object
- No output params — return values, don't modify inputs
- Early return / guard clause over nested conditions
- Pure functions preferred — push side effects to the edges

## Classes & Modules
- SRP: one reason to change
- High cohesion: methods operate on the same data; if they don't, split the class
- Composition over inheritance — inheritance only for true "is-a"
- Tell, don't ask: `order.isShippableToUS()` not `order.customer.address.country == "US"`
- Immutability by default — mutability requires justification
- Make illegal states unrepresentable — use types/constructors to enforce invariants

## Error Handling
- Exceptions for unexpected conditions; Result/Optional types for expected failures
- Never swallow exceptions silently — log or propagate
- Never return null — use Optional, empty collection, or meaningful default
- Error messages include context: what was attempted, what failed, why
- Catch specific exceptions, never bare `Exception`/`Throwable`

## Comments
- Explain *why*, not *what* — code shows what; comments explain intent
- Comment business rules, non-obvious decisions, warnings ("must be <100ms")
- Never comment obvious code — refactor instead
- Outdated comments are worse than no comments

## Testing
- Isolated, fast, repeatable, self-documenting
- Arrange-Act-Assert structure
- One logical assertion per test
- Test names: `givenX_whenY_thenZ` or `shouldDoX_whenY`
- Cover error paths and boundaries as thoroughly as happy paths
- Don't mock the thing under test

## SOLID
- **S** — one reason to change
- **O** — extend via abstraction, don't modify existing code
- **L** — subtypes substitutable for base types without breaking behavior
- **I** — many focused interfaces > one fat interface
- **D** — depend on abstractions, not concretions

## Other Principles
- **DRY** — duplicate logic is a maintenance liability; extract it
- **YAGNI** — don't build what isn't needed yet
- **KISS** — simplest solution that works; complexity needs justification
- **Law of Demeter** — talk to neighbors, not strangers (`a.b.c.do()` is a smell)
- **Fail fast** — validate at boundaries, report errors immediately
- **Proximity** — related code lives close together
- **Separation of concerns** — business logic, persistence, UI in separate layers

## Security
- Validate all external input at system boundaries (type, format, length, range)
- Parameterized queries — never string-concat SQL
- Never hardcode secrets — use env vars or vaults
- Least privilege — grant only what's necessary
- Never log sensitive data (passwords, tokens, PII)
- Generic error messages to users; detailed logs internally

## API Design
- Consistent naming, param ordering, error handling across all endpoints
- Symmetry: `create` → `delete`, `open` → `close`
- Minimal surface area — expose only what's necessary
- Document all public APIs with examples, params, exceptions, perf characteristics
- Deprecate gradually with migration guide before removing
