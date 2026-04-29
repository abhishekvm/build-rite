---
description: "Merge if ready, close issues, delete local branch, pull default"
---

# Cleanup

Wraps up PR work: merges if open + ready, closes linked issues, tidies the local branch.

Parse `$ARGUMENTS`: PR number → use directly · None → detect from current branch

## 1. Detect PR state

If no argument supplied:
- Run `gh pr status --json number,state,headRefName,body` to find a PR whose `headRefName` matches the current branch
- If current branch is the default branch, run `gh pr list --limit 5` and ask which one to clean up
- If no PR found: stop and say so

Branch on state: `MERGED` → skip to step 3 · `OPEN` → step 2 · `CLOSED` (not merged) → ask whether to delete branch and stop · other → stop.

## 2. Merge if ready

For an `OPEN` PR, fetch readiness signals:
```
gh pr view <N> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,isDraft
```

Show a readiness block:
```
PR #<N> readiness
  Approval     ✓ APPROVED        (or ✗ REVIEW_REQUIRED / CHANGES_REQUESTED)
  Checks       ✓ all green       (or ✗ N failing — <names>)
  Mergeable    ✓ MERGEABLE       (or ✗ CONFLICTING / UNKNOWN)
  Draft        ✓ no              (or ✗ yes)
```

**All green** (approved + checks pass + mergeable + not draft) → run `gh pr merge <N> --squash --delete-branch=false` and proceed. The user invoking `/br-cleanup` on a green PR is authorization to merge.

**Any signal not green** → stop and ask: "Merge anyway? Wait? Abort?" Do not auto-proceed.

After a successful merge, continue to step 3.

## 3. Close linked issues

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

## 4. Local branch cleanup

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

## 5. Summary

```
Cleanup complete
  PR      #<N> merged
  Issues  <X> closed, <Y> skipped
  Branch  <branch> deleted · now on <default>
```

Then ask: "Start next issue? → `/br-impl`"
