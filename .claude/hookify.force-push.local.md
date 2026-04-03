---
name: block-force-push
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: git push.*(--force|-f)(\s|$)
---

Blocked: force push. If you need this, do it manually.
