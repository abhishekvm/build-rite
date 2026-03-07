#!/usr/bin/env python3
"""Pre-tool-use hook: enforce package manager + git discipline."""

import json
import sys

BLOCKED = [
    ("pip install", "Use the project's Python package manager (uv/poetry)"),
    ("pip3 install", "Use the project's Python package manager (uv/poetry)"),
    ("npm install", "Use pnpm install or pnpm add <package>"),
    ("npm i ", "Use pnpm add <package>"),
    ("yarn add", "Use pnpm add <package>"),
    ("yarn install", "Use pnpm install"),
    ("git add -A", "Use git add <explicit file list>"),
    ("git add .", "Use git add <explicit file list>"),
]


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    command = payload.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    for pattern, fix in BLOCKED:
        if pattern in command:
            print(f"Blocked: `{pattern}` → {fix}")
            sys.exit(1)


if __name__ == "__main__":
    main()
