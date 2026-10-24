# Unattended runs and parallel workers

For work that runs while the user is away (overnight, "keep going while I sleep") and for fan-outs across worktrees. Commands point here — don't restate it.

## Before the user leaves
- Agree the deliverable's size: one slice, one PR (**Scope** in `.claude/CLAUDE.md`). A bigger goal → the slice list, each its own PR.
- Collect every input the run needs now: credentials, data paths, other repos (export them — **Worktrees**), open design questions.
- List the commands and directories it will touch and hand the user `/add-dir` plus scoped allow rules — a permission prompt or classifier denial stalls the run, and Claude can't edit its own settings.

## During the run
- **Stay awake and wake yourself** — first action: `caffeinate -dimsu` (re-check it at every wake; the laptop stays plugged in, lid open). Schedule a heartbeat every 20 minutes (`CronCreate` or `ScheduleWakeup`); each wake resumes from the report file, never restarts. Never end a turn waiting without a wakeup scheduled. A gap over 30 minutes in the timesheet is a bug: report it.
- **No unbounded waits** — wrap `git push`, `gh` and network calls in `timeout 120`. One prompt-blocked command stalled a run for 6 hours.
- **Report file** in the worktree (gitignored or scratchpad): a timestamped timesheet line per stage, decisions made, and a needs-you list. A classifier denial or blocked item goes on the needs-you list and work continues on the rest — never work around it.
- A background agent or job that stops without the user's say-so → resume it (`SendMessage` or relaunch, checking `git status` first) and say so in one line.
- **Never end a turn on a promise** — launch the next background job in the same turn that announces it. At each completion, update the report and post a one-line status (back · pending · next).
- **Per story** — its **Proof** (`.claude/reference/checks.md`), full suite counts, before/after output from the user-visible path, and the requirements still unproven.
- Outward actions follow **Confirmation before posting** — they wait for the user; local commits continue.

## Parallel workers
- The orchestrator stays in the main checkout (no `EnterWorktree`) and owns commits, pushes, deletions, reads of user-provided sensitive files, and the user's instructions.
- Each worker gets its own worktree (the agent's `isolation: worktree`, from the base branch; its first step copies the harness in with the `rsync` from `/br-impl` worktree mode), branch and file set — and its own local services: compose project name and ports derived from the worktree path. No DDL or data deletion on a shared database without asking. Errors seen during concurrent runs are unconfirmed until a solo re-run.
- Each worker prompt names its absolute worktree path and pastes **Shell** from `.claude/CLAUDE.md` verbatim, plus: no `git checkout`/`restore`. After each worker, check `git status` in every other repo it could reach.
- Run full test suites one at a time: parallel suites contend for CPU and look hung. Read pass/fail counts from a junit XML file, not the console; an empty or truncated result is re-run once with `rtk proxy` — never read as success.
- Workers run on Sonnet; Opus only for the one heavy review. A worker that re-sends the same report, or has no commit in 40 minutes, gets one nudge, then a replacement (`TaskStop` the old one).
- Send one small probe worker before a whole wave; size waves to the host's CPU and memory; stop a worktree's services when its stage ends, and stop finished agents (`TaskStop`) so the list shows only live work.

## Morning report
What shipped (with proofs and the review **State** table), what's blocked on the user, idle gaps on the timesheet, what wasn't verified.
