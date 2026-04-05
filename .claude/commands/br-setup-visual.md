---
description: "Guided visual testing setup — Maestro (RN/Expo) or Playwright (web)"
---

# Setup Visual Testing

Optional. Ask before every write. Never configure automatically.

Read project CLAUDE.md stack to determine platform.

## 1. Check existing setup

Look for: `flows/`, `baselines/`, `maestro/`, `.maestro/`, `playwright.config.*`, `e2e/`, `## Visual Testing` in CLAUDE.md.
- Found → show what's configured, ask if anything needs updating.
- Not found → proceed to step 2.

## 2. Tool selection

```
Recommended:
  React Native / Expo → Maestro  (YAML flows, no Xcode/Android Studio needed)
  Web only            → Playwright (JS/TS, full browser automation)
  Both                → Maestro for mobile + Playwright for web
```

Confirm choice before proceeding.

## 3. Setup

1. Show install command — confirm before running:
   - Maestro: `brew install maestro`
   - Playwright: `pnpm add -D @playwright/test`
2. Create `flows/` with one example flow scaffold based on the project's first detectable screen
3. Create `baselines/` with `.gitkeep` and a short note explaining approval process
4. Add `## Visual Testing` to project CLAUDE.md:
   ```markdown
   ## Visual Testing
   - Tool: <Maestro|Playwright>
   - Flows: `flows/` — run with `<command>`
   - Baselines: `baselines/` — approve with `<command>`
   - Pixel diff: <configured|not yet>
   ```
5. Show a sample flow run output so the user knows what to expect

Ask before each write. Stop if user declines any step.
