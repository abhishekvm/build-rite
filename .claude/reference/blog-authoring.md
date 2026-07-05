# Blog authoring reference

Detail for `/br-blog`. The command drives the phase flow; this file holds the
rules that protect the author's voice and the contracts the command relies on.
The biggest failure mode is **drifting from the author's voice** — front-load
voice calibration, keep the review loop cheap to repeat.

## Tone spec shape

Phase 0 produces this table and gets explicit sign-off. Fill every row from the
author's *own* published writing (fetched + analyzed), not from defaults.

| Element | What to capture |
|---|---|
| Voice | Pronoun stance (I / we / impersonal), confidence, how they own work |
| Headers | Plain descriptive phrases vs. slogans; sentence case vs. title case |
| Openers | How sections start — concrete statement vs. suspense vs. question |
| Bold | Where and how often; the "skim layer" — one load-bearing claim per beat |
| Blockquotes | Plain takeaway lines vs. labeled callouts |
| Jargon | Glossed in plain terms + a verified reference link |
| Coined term | One named concept that carries the thesis (the author's signature idea) |
| Numbers | Real stats only; never expose business-sensitive figures |

## Style rules — do / don't

**DO**
- Lead sections with a **plain, concrete, factual** header ("The first version",
  "Where it started to crack") — not an abstract slogan.
- Open sections by **stating the point directly** and moving forward (linear).
- Make **parallel subsections uniform**: same shape (bold lead → short
  explanation → one stressed fact). Uniformity beats clever variety.
- **Gloss every jargon term** in plain language and link a verified reference.
  Add an analogy to something familiar ("Snowpark is Spark's DataFrame idea,
  minus the cluster").
- **Stress the facts** — bold the load-bearing number/claim; reserve bold for those.
- **Coin one named concept** and thread it through (intro → body → results → close).
- Vary sentence length; use em-dashes; let short punchy lines land.
- Echo the **title** in the closing line for a full-circle ending.

**DON'T**
- No **suspense-then-reveal** openers ("X didn't announce itself… It wasn't…").
  Linear, not teasing.
- No **"it's not X, it's Y"** construction — reads cliché. State Y directly.
- No **defensiveness / proving**: cut "wasn't a mistake", "the correct first
  system", "the discipline nobody teaches", "most write-ups skip", "to be explicit".
- No **lack of confidence**: don't imply the idea was unproven ("whether it would
  work at all") when the author was confident — frame choices as deliberate sequencing.
- Don't **over-explain stable concepts**. If something "just works for years",
  name it and link it; don't stress it.
- Don't **bold mid-sentence everywhere** — one stress point per beat.
- Don't **repeat a fiddly formatting device** many times (three "The cost:" blocks
  → one consolidated block) — Substack makes these painful.
- Don't **expose business-sensitive numbers** (tenant/customer counts, revenue).
  Generalize ("a growing roster").
- Don't **fabricate stats**. Use `「PLACEHOLDER」` markers; list them for the author.
- Don't introduce a metaphor-y register if the author's voice is plain.

**When the author rejects a phrasing twice:** stop guessing. Offer 3–4 concrete
options and let them pick. Voice is theirs — converge by selection, not more guesses.

## Comment round-trip contract

The browser export (from `review-snippet.html`) looks like:

```
Blog review comments (N total)
==================================

[1] On: "exact quoted passage"
    → instruction

[2] General note:
    → instruction
```

Apply rules:
- **`On: "…"`** → find that exact text in the `<slug>.md` source and revise **in
  place**. If the quote spans inline markup, find the underlying source text.
- **`General note`** → apply at judgment; **report where** you made the change.
- Treat each `[n]` as **independent**. Resolve all, then re-render once.
- After applying, **flag downstream consistency**: if an edit changes a framing,
  grep for and surface other passages that still assume the old framing.
- **Stale comments**: comments persist in `localStorage` keyed to the page path.
  If a `[n]` was already resolved in a prior round, say so instead of re-editing,
  and remind the author they can **Clear all** in the toolbar.

## External link discipline

- **Always verify a URL (WebFetch) before inserting it.** Report load status +
  page title. Dead/redirecting links (old vendor blog PDFs) are common.
- Prefer **authoritative** sources (e.g. Kimball for dimensional modeling,
  official vendor docs, primary sources) over SEO blogs.
- Gloss the term, *then* link it — for readers outside the author's domain.

## Diagram sub-flow

When a section benefits from a visual, offer two paths:

1. **Local paste-ready PNG** (fast, self-contained) — author an SVG by hand, then
   render with macOS Quick Look (no extra deps; cairosvg/rsvg are often absent):
   ```
   qlmanage -t -s 2480 -o . diagram.svg   # → diagram.svg.png
   sips -c <height> <width> diagram.svg.png   # crop padding
   ```
2. **Handoff to a design tool** — produce a structured diagram spec: layout, a
   nodes table (labels + sublabels), connections, styling matched to existing
   diagrams, a do-NOT list, and a one-line prompt. The author drives the tool.

Keep diagram styling consistent across the post (shared palette, fonts, conventions).

## Substack paste cheat sheet

| Element | Survives paste? |
|---|---|
| H1/H2, bold, italic, inline code, blockquotes, lists, links | ✅ |
| Tables | ⚠️ often need rebuild in Substack's table block |
| Code blocks | ✅ |
| Images via `![]()` | ⚠️ upload in-editor instead |
| Footnotes | ⚠️ use Substack's footnote button |
| Raw HTML / admonitions | ❌ stripped |

Implication baked into the style rules: avoid repeating fiddly structures (many
tables, many identical labeled blocks); consolidate.
