---
description: "Guided git hooks setup — pre-commit lint/format/typecheck"
---

# Setup Git Hooks

Optional.

## 1. Check existing setup

Look for: `.pre-commit-config.yaml`, `.husky/`, `lefthook.yml`, active hooks in `.git/hooks/`.
- Found and covers lint/format/typecheck → note it, no action needed.
- Found but incomplete → show gaps, ask if user wants to fill them.
- Not found → proceed to step 2.

## 2. Tool selection

Pick one based on detected stack — do not offer all three:
- Python → `pre-commit`
- Node/JS/TS → `husky` + `lint-staged`
- Polyglot → `lefthook`

## 3. Setup

Show a single ready-to-use config covering:
- pre-commit: lint + format + type check (commands from CLAUDE.md `## Common Commands`)
- pre-push: ask — "Include tests in pre-push?" (can slow push; team preference)

Ask: "Set up hooks with this config?"
After writing: install hooks, run a test commit to verify, confirm success.
