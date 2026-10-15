---
description: "Merge if ready, close issues, delete local branch, pull default"
argument-hint: "[pr-number]"
disable-model-invocation: true
---

# Cleanup

Wraps up PR work: merges if open + ready, closes linked issues, tidies the local branch.

Parse `$ARGUMENTS`: PR number → use directly · None → detect from current branch

## 1. Detect PR state

If no argument supplied:
- Run `gh pr status --json number,state,headRefName,body` to find a PR whose `headRefName` matches the current branch
- If current branch is the default branch, run `gh pr list --state all --limit 5` and ask which one to clean up
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
  Approval     ✓ APPROVED / not required   (or ✗ REVIEW_REQUIRED / CHANGES_REQUESTED)
  Checks       ✓ all green       (or ✗ N failing — <names>)
  Mergeable    ✓ MERGEABLE       (or ✗ CONFLICTING / UNKNOWN)
  Draft        ✓ no              (or ✗ yes)
```
An empty `reviewDecision` means no review is required (you can't approve your own PR) — that's green.

**All green** → write the body to a file and merge from it, so backticks and quotes in it are never run by the shell: `gh pr view <N> --json body -q .body > <scratchpad>/pr-<N>-body.md`, then `gh pr merge <N> --squash --delete-branch=false --subject "<PR title> (#<N>)" --body-file <scratchpad>/pr-<N>-body.md` (the squash commit carries the PR's Problem/Solution/Testing, not the wip messages). The user invoking `/br-cleanup` on a green PR is authorization to merge.

**Any signal not green** → stop and ask: "Merge anyway? Wait? Abort?" Do not auto-proceed.

After a successful merge, continue to step 3.

## 3. Close linked issues

Read `Tracker` from `## Project Config`, then handle the PR body's references:
- `gh:` → `Closes|Fixes|Resolves #N` (case-insensitive). Per N: `gh issue view <N> --json state --jq '.state'`; `OPEN` (a non-default base doesn't auto-close) → `gh issue close <N>` — no comment, so nothing is posted; `CLOSED` → skip silently
- Other trackers → ticket IDs (e.g. `ENG-123`); close with the tracker's CLI if installed, else list them for the user to close

Show a one-line result per issue:
```
Issues
  #42  ✓ closed
  #43  ✓ already closed — skipped
```

If no issue references found in PR body: note it and continue.

## 4. Local branch cleanup

Determine the merged branch name from the PR (`headRefName`).

**Worktree mode first** — if `## Project Config` sets `Branching mode: worktree`, find the merged branch's worktree in `git worktree list --porcelain` (the `worktree <path>` line above `branch refs/heads/<merged-branch>`). If found: when this session is inside it, call `ExitWorktree` with `action: keep` first; then `git worktree remove <path>` (no `--force`). If git refuses because of uncommitted changes, show them and ask before forcing.

**If currently on the merged branch:**
- Switch to default branch: `git checkout <default-branch>`
- Pull latest, dropping merged remote branches: `git pull --prune origin <default-branch>`
- Delete local branch: `git branch -d <merged-branch>`
- If `-d` fails (diverged history): show a warning and ask before using `-D`

**If on any other branch:** delete the merged branch if it exists locally (`git branch -d <merged-branch>`), then update the default branch — on it: `git pull --prune origin <default-branch>`; elsewhere: `git fetch --prune origin <default-branch>:<default-branch>`.

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
