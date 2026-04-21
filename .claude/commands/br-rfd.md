---
description: "Requirements discovery → research → shareable decision document"
---

# RFD (Request for Decision)

Produces a shareable requirements document for decisions like "build vs buy", "which tool", "which approach". Output is a `.md` file in `docs/` — no code edits.

Parse `$ARGUMENTS`: GH issue / ticket ID → fetch as seed · Text → topic · Path → read as context · None → ask

## 1. Scope

Ask up to 3 questions to establish:
- **What decision** needs to be made (tool selection, architecture choice, build vs buy)
- **Who reads this** (internal team, external vendor, leadership, self)
- **What do you already know** (existing research, constraints, preferences, tools already in use)

Don't proceed without understanding audience. The audience determines tone: internal = candid with team context, external = sanitized with no account IDs or internal URLs.

## 2. Gather

Pull context from every available source. Run these in parallel where possible:

- **Codebase** — read project CLAUDE.md, relevant `.tf` / config / code files for current state
- **GH issues** — `gh issue list` with relevant labels or keywords. Read related issues for requirements already captured.
- **CLI / billing data** — run `aws`, `terraform`, `gh`, or other CLI tools to get real numbers. Don't estimate when you can measure.
- **Web research** — search for tools, vendors, pricing, comparisons when external options are being evaluated
- **Existing docs** — check `docs/` for prior art

**⏸ Checkpoint:** Present what you found — current state, known constraints, and any surprises. Ask: "Anything I'm missing or getting wrong?" Fix before drafting.

## 3. Draft

Write to `docs/<slug>.md`. Structure depends on the decision type, but follow these principles:

**Voice:**
- Problems in plain English first. Stats support the narrative, don't replace it.
- Write for someone who hasn't been in the room. Every section should make sense standalone.
- No jargon without explanation on first use (spell out acronyms).

**Content rules:**
- Don't list gaps that can be fixed in minutes with current tooling — focus on structural problems.
- Include people cost (implementation time, ongoing maintenance, opportunity cost), not just tooling cost.
- Evaluation criteria should be high-level dimensions, not 50-item weighted matrices.
- If comparing options: use a single comparison table, not per-option deep dives that force the reader to cross-reference.
- Real numbers from step 2. Never estimate what you measured.

**Typical sections** (adapt to the decision — not every RFD needs all of these):
1. Who we are — team, infra shape, scale, constraints
2. Current state — what works, what doesn't (plain English problems)
3. Current spend — real billing data, include people cost
4. What we need — numbered capability list
5. Options analysis — build vs buy, or tool comparison
6. Evaluation criteria — high-level dimensions for scoring
7. Recommendation / next steps

**⏸ Checkpoint:** "Draft ready at `docs/<slug>.md`. Read it and tell me what to fix." Wait for feedback.

## 4. Refine

Enter refinement loop. For each round of feedback:
- Apply corrections immediately
- Don't regenerate the whole document — edit in place
- Track factual corrections (these often indicate wrong assumptions worth questioning)
- If user says "too many numbers" → add narrative. If "not enough detail" → add supporting data.
- If user corrects a fact → check if the same wrong assumption appears elsewhere in the doc

Loop until user says it's good. Typical: 2–4 rounds.

## 5. Wrap up

```
Document ready: docs/<slug>.md

Options:
A) Commit to branch     (creates branch if needed)
B) Hand off             (→ /br-handoff for format conversion or context transfer)
C) Done                 (leave as uncommitted file)
```

If A: stage only the doc file, commit with `docs: add <topic> requirements document`.
If B: chain to `/br-handoff` with the file path.
