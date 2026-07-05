---
description: "Notes → publish-ready technical blog post in the author's voice (browser review loop)"
argument-hint: "[notes-path | topic | --new <slug>]"
disable-model-invocation: true
---

# Blog

Authoring + revision harness, not a one-shot generator. Output lives in `drafts/`.
The job is **protecting the author's voice** — keep their judgment in the loop,
don't optimize for finishing fast. Stateful and multi-turn.

Detail for every phase lives in `.claude/reference/blog-authoring.md` (tone-spec
shape, style do/don't, comment contract, link discipline, diagram sub-flow,
Substack cheat sheet). Read it before drafting.

Parse `$ARGUMENTS`: Path → read as raw source · `--new <slug>` → scaffold only (see below) · Text → topic/brief · None → ask for the source.

**Hard gates** — finish each phase and get sign-off before the next. Don't batch ahead.

## Phase 0 — Discovery & voice calibration (READ-ONLY)

Collect: raw material, **target audience**, **desired length/depth**, **angle/thesis**,
and whether it's for **personal branding** (changes everything about voice).

**Analyze the author's existing writing — don't guess the voice, derive it.** Ask
for 1–3 URLs of their published posts; `WebFetch` each and extract pronoun stance,
sentence rhythm, formatting habits (bold, blockquotes, lists, em-dashes),
section-header style, any coined terms.

Produce the **tone spec** (table shape in the reference) and get explicit sign-off.

Use `AskUserQuestion` for genuinely branching choices (audience, length, angle,
voice register) — 2–4 options, `preview` for title/voice options.

## Phase 1 — Outline (READ-ONLY)

Propose a section outline as a table: section → job it does → key content.
Identify the **thesis** and a candidate **coined term** (the one idea readers quote).
Get approval before any prose.

## Phase 2 — Draft (section by section)

Default to **one section at a time**, then checkpoint. Offer a full draft only if
the author asks. Apply the tone spec and the style rules in the reference.
After each section, show it and wait. Treat the author's reactions as voice
calibration, not just edits.

Source of truth is `drafts/<slug>.md` — the author edits it between turns, so
**Read it before every edit**. Never overwrite their changes.

## Phase 3 — Review loop (the core value)

First time: **scaffold the review tooling into `drafts/`** (see Setup below).

1. Render the **review build**:
   ```
   cd "$(git rev-parse --show-toplevel)/drafts" && BLOG_REVIEW=1 python render.py <slug>
   ```
2. Tell the author to open `drafts/<slug>-review.html` in a browser, turn on
   **💬 Comment mode**, annotate, click **Export for Claude**, and paste the block back.
3. Apply each `[n]` as a **discrete edit** per the comment contract in the reference.
   Resolve all, then re-render once.
4. Roll the **revision-notes banner** forward one round (`drafts/revision-notes.md`).
5. Re-render. Repeat until the author stops.

Keep responses tight: show the changed text, name what changed and why, ask the
next question. No walls of prose.

## Phase 4 — Finalize

- Fill `「…」` placeholders (real numbers/diagrams the author supplies); list any
  that remain.
- Produce the **clean build** (the Substack paste source):
  ```
  cd "$(git rev-parse --show-toplevel)/drafts" && python render.py <slug>
  ```
- Offer (don't impose) a closing CTA line.
- Point the author at the Substack cheat sheet in the reference for paste quirks.

## Setup (scaffold `drafts/`)

Run on first render, or up front with `--new <slug>`. Use absolute paths.
```
ROOT="$(git rev-parse --show-toplevel)"
mkdir -p "$ROOT/drafts"
cp "$ROOT/.claude/assets/render.py"           "$ROOT/drafts/render.py"
cp "$ROOT/.claude/assets/review-snippet.html" "$ROOT/drafts/review-snippet.html"
[ -f "$ROOT/drafts/revision-notes.md" ] || cp "$ROOT/.claude/assets/revision-notes.md" "$ROOT/drafts/revision-notes.md"
```
`render.py` needs `python-markdown`. If `python -c "import markdown"` fails, ask
before installing (`pip install markdown` or `uv pip install markdown`).

For `--new <slug>`: scaffold the files above, create an empty `drafts/<slug>.md`
with a `# <title>` H1, and stop — report what was created.

## Guardrails

- **Clean/review separation is a hard invariant.** Review tooling (banner +
  comment layer) must never reach `<slug>.html`. `render.py` asserts this; after a
  clean build, verify yourself: `grep -c cmt-bar drafts/<slug>.html` must be `0`.
- **Verify before reporting done** — re-render and grep for the thing you claim to
  have fixed/removed; don't trust prior output.
- **Preserve author edits** — Read `drafts/<slug>.md` before every edit.
- **No fabricated data** — `「PLACEHOLDER」` only, surfaced in a list.
- **No business-sensitive specifics** unless the author explicitly green-lights.
- Keep the harness rules: `git add <explicit files>` only, no build-rite
  attribution in any committed artifact, confirmation before any external posting.
