---
description: "Post-merge cleanup — close issues, delete local branch, pull default"
---

# Cleanup

Run after a PR has been merged to close any issues that GitHub didn't auto-close and tidy up the local branch.

Parse `$ARGUMENTS`: PR number → use directly · None → detect from current branch

## 1. Detect merged PR

If no argument supplied:
- Run `gh pr status --json number,state,headRefName,body` to find a merged PR whose `headRefName` matches the current branch
- If current branch is the default branch, run `gh pr list --state merged --limit 5` and ask the user which one to clean up
- If no merged PR found: stop and say so

## 2. Close linked issues

Parse the PR body for issue references:
- Patterns: `Closes #N`, `Fixes #N`, `Resolves #N` (case-insensitive)
- For each matched issue number:
  - Check current state: `gh issue view <N> --json state --jq '.state'`
  - If `OPEN`: close it with `gh issue close <N> --comment "Closed via merged PR #<PR>."`
  - If already `CLOSED`: skip silently

Show a one-line result per issue:
```
Issues
  #42  ✓ closed
  #43  ✓ already closed — skipped
```

If no issue references found in PR body: note it and continue.

## 3. Local branch cleanup

Determine the merged branch name from the PR (`headRefName`).

**If currently on the merged branch:**
- Switch to default branch: `git checkout <default-branch>`
- Pull latest: `git pull origin <default-branch>`
- Delete local branch: `git branch -d <merged-branch>`
- If `-d` fails (diverged history): show a warning and ask before using `-D`

**If on a different branch (e.g., already switched):**
- Check if the merged branch exists locally: `git branch --list <merged-branch>`
- If yes: delete with `git branch -d <merged-branch>`
- Pull latest on default branch: `git pull origin <default-branch>`

**Worktree mode** — if `## Project Config` in CLAUDE.md sets `Branching mode: worktree`:
- Check for worktree at `.worktrees/<slug>`: `git worktree list`
- If found: `git worktree remove .worktrees/<slug> --force` then `git branch -d <merged-branch>`

Show result:
```
Branch
  ✓ switched to main
  ✓ pulled latest (3 new commits)
  ✓ deleted feature/my-branch
```

## 4. Summary

```
Cleanup complete
  PR      #<N> merged
  Issues  <X> closed, <Y> skipped
  Branch  <branch> deleted · now on <default>
```

Then ask: "Start next issue? → `/br-impl`"
