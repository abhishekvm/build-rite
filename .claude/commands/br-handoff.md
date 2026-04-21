---
description: "Package work for transfer to another tool, person, or format"
---

# Handoff

Packages current conversation work into a portable artifact. No code edits — only produces or copies `.md` files.

Parse `$ARGUMENTS`: target hint (`code`, `desktop`, `internal`, `external`, `clipboard`) · file path → hand off that specific file · None → ask

## 1. What and where

Ask two things:

**What to hand off:**
- A specific file (path given as argument, or ask)
- Current conversation findings (summarize what was discussed/decided)
- A combination (document + context about what was discussed around it)

**Target — who or what receives this:**

| Target | Keyword | What it means |
|---|---|---|
| Claude Code | `code` | Continue this work in a new Claude Code session |
| Claude Desktop | `desktop` | Continue in Claude Desktop (no file access, no CLI) |
| Internal team | `internal` | Share with colleagues — candid, includes team context |
| External party | `external` | Share with vendors/partners — sanitized |
| Clipboard | `clipboard` | Quick copy/paste into Slack, email, Notion, etc. |

If unclear from argument, ask: "Who's receiving this?"

## 2. Generate

Each target produces a different markdown flavor:

### → Claude Code (`code`)

Write a `.md` file to the repo (default: `docs/handoff-<slug>.md`). Include:

```markdown
# Context: <topic>

## Background
<What was discussed, decided, and why. Key constraints and preferences.>

## Current State
<What exists — file paths, what's been implemented/drafted, what's pending.>

## Key Decisions
<Bullets: decisions made during the conversation and reasoning.>

## Open Items
<What still needs to be done. Be specific — file paths, line numbers where relevant.>

## Files to Read First
<Ordered list of files that give the receiving session full context.>
```

This file is the first thing a new Claude Code session should read. All file paths must be absolute or repo-relative.

### → Claude Desktop (`desktop`)

Write a self-contained `.md` file (default: `docs/handoff-<slug>.md`). Key difference from Code target: **embed all context inline** — Desktop cannot read files from disk.

- Inline relevant code snippets (don't just reference paths)
- Inline relevant config/data (don't say "see terraform.tfvars")
- Include the full text of any document being discussed
- State constraints and preferences explicitly (Desktop has no CLAUDE.md)
- Keep under ~4000 words — Desktop context is more constrained

End with:
```markdown
## How to Continue
<Specific instructions for what to do next in Desktop.>
<If work needs to come back to Code: "When implementation is needed, hand this document back to Claude Code.">
```

### → Internal team (`internal`)

Clean document, team-readable. From the source file or conversation:

- Keep internal references (team names, project names, account details)
- Remove conversation artifacts (checkpoint markers, refinement history)
- Add a "TL;DR" section at the top (3–5 bullets)
- Ensure every acronym is spelled out on first use
- Write to `docs/<slug>.md`

### → External party (`external`)

Sanitized document. From the source file:

- Strip AWS account IDs, internal URLs, team member names, org-specific identifiers
- Replace specific account references with generic labels ("production account", "development account")
- Remove any cost data the user hasn't explicitly approved for sharing (ask if unsure)
- Remove internal process details (CI/CD specifics, Git workflow, Terraform structure)
- Keep technical requirements, volumes, evaluation criteria, architecture description
- Add a header: `Prepared by: <company> Infrastructure Team` (ask company name if not in CLAUDE.md)
- Write to `docs/<slug>-external.md`

### → Clipboard (`clipboard`)

Minimal, portable. Show directly in conversation output (don't write to file):

- If handing off a document: TL;DR (5–8 bullets) + link/path to full doc
- If handing off conversation findings: structured summary under 500 words
- Formatted for paste into Slack/email (no complex tables — use bullet lists)

## 3. Confirm

Show what was generated (path + size). For `external` target, always show the sanitized output for review — never assume sanitization caught everything.
