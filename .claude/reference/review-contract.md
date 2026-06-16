# Review Contract

Mechanics shared by `/br-review` and `/br-swarm-review`. Both reference this — don't restate it inline. Each command adds only its own analysis flow on top.

## Context gathering
- Get the diff: `gh pr diff <n>` for a PR · `git diff <default-branch>...<branch>` for a branch · recent changes for a file · uncommitted/branch diff for none.
- Read changed files in full, read project CLAUDE.md, fetch linked tickets (Linear/GH/Jira from the PR body), read the PR description and any docs/READMEs in the diff.
- No ticket? Ask for business context.

## Author detection
```
PR_AUTHOR=$(gh pr view <n> --json author -q .author.login)
ME=$(gh api user -q .login)
```
`OWN_PR` if equal, else `OTHERS_PR`. Drafts still count as own.

## Prior comments
Before analysis, fetch existing review comments:
- inline: `gh api repos/{owner}/{repo}/pulls/<n>/comments`
- PR-level: `gh api repos/{owner}/{repo}/issues/<n>/comments`

If any exist, note "Re-review — N prior comments" at the top of output and carry the list into analysis.

## Dedup against prior comments
Drop findings whose (file, line ±5, concern) match an existing comment. Keep a near-miss only if it adds new information — annotate `(already raised — refining)` and drop it otherwise.

## Finding shape
Each finding: **What's wrong** · **Where** (file:line) · **Impact** (concrete failure mode or cost — not "bad practice") · **Value if fixed** · **Suggested fix** · **Severity**. If you can't name a concrete impact, downgrade the severity or drop the finding. `Nice to have` must say "no functional impact" so the reader knows it's optional.

## Posting flow (by author)
- **Own PR** (including drafts) → show findings in conversation, never auto-post. Apply fixes only after the user picks which. After fixes land and checks pass, if the PR is draft, offer to flip ready — never flip it yourself.
- **Others' PR** → preview before posting. Show the full numbered list (file:line · severity · one-line message · proposed comment body), wait for an explicit selection ("all", "1,3,5", "skip"), then post via **individual per-line calls** — `gh api repos/{owner}/{repo}/pulls/{n}/comments`, one API call per finding. Never bundle into a single `gh pr review --comment` / `pulls/reviews` submission.
- **Branch / file / uncommitted** → show in conversation; there's no PR to post to.
