---
name: warn-commit-on-main
enabled: true
event: bash
action: warn
conditions:
  - field: command
    operator: regex_match
    pattern: git commit
---

Check you're not on main before committing. Use a branch.
