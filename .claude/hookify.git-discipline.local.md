---
name: enforce-git-add
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: git add\s+(-A|\.)(\s|$)
---

Blocked: `git add -A` / `git add .`

Use `git add <explicit file list>` only.
