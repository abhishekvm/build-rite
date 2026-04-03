---
name: block-dangerous-rm
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: rm\s+-rf\s+(/|~|\$HOME)
---

Blocked: destructive rm targeting root/home. Be explicit with the path.
