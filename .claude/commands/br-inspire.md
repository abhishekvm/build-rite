---
description: "Find reference apps → extract patterns worth stealing for your project"
---

# Inspire

Read-only. No code edits. Output is a curated reference list + actionable patterns.

Parse `$ARGUMENTS`: Area → narrow to that surface (e.g. `UI`, `onboarding`, `data table`) · None → derive from project CLAUDE.md

Read project CLAUDE.md — extract: what's being built, who uses it, key interactions, tech stack.

## 1. Identify the space

Derive the product category from CLAUDE.md. Be specific — not "productivity app" but "keyboard-first task manager for engineers."

## 2. Find references

Two tiers:

**Core space** — leaders in the exact domain. These set user expectations.
- Pick 3-5. Include the gold standard even if obvious.
- For each: one-line why it's relevant + 2-3 specific things to steal (UI pattern, interaction model, information architecture)

**Adjacent** — apps from different domains with transferable patterns.
- Pick 2-3. Must solve a specific problem your project shares (latency, density, bulk actions, etc.)
- For each: name the transferable pattern explicitly — not "good UX" but "optimistic updates for async operations"

Be opinionated. Pick the best reference per pattern, don't list alternatives.

## 3. Non-obvious insight

One pattern the user probably hasn't considered — from an unexpected source. Explain why it applies.

## 4. Output format

```
## Reference Apps — <product area>

### Core Space
| App | Why relevant | What to steal |
|-----|-------------|---------------|
| <App> | <one line> | <2-3 specific patterns> |

### Adjacent
| App | Why relevant | Transferable pattern |
|-----|-------------|----------------------|
| <App> | <one line> | <named pattern> |

### Non-obvious pick
**<App>** — <why unexpected> → <what applies and why>

### Recommended starting point
<Single recommendation: which app to study first and what specifically to look at>
```

## 5. Follow-up

Ask: "Want to dig into any of these?" or "Ready to translate this into `/br-plan`?"
