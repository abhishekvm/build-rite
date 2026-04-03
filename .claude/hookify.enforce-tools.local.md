---
name: enforce-package-manager
enabled: true
event: bash
action: block
conditions:
  - field: command
    operator: regex_match
    pattern: (^|\s)(pip install|pip3 install|npm install|npm i |yarn add|yarn install)
---

Wrong package manager.

- Python: use `uv add` or `poetry add`
- Node: use `pnpm install` / `pnpm add <package>`
