---
name: dispatch
description: "Use when multiple tasks are ready and you want to assign them to parallel workers"
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion, Agent
---

# Dispatch Workers: $ARGUMENTS

You are an orchestrator dispatching parallel workers for beads tasks. Each worker runs in its own git worktree for true filesystem isolation.

## Parse Arguments

Arguments: `$ARGUMENTS`

Parse the following patterns:
- `--count N` — Auto-select N ready tasks from `bd ready`
- `--plan-first` — Force all workers into plan approval mode
- `--no-plan` — Disable auto risk detection, all use bypassPermissions
- `--yes` — Skip dispatch confirmation (used by /auto-run for autonomous operation)
- `--model opus|sonnet` — Override model selection for all tasks
- `<task-id>` — Specific task to dispatch
- `<task-id>:"context"` — Task with custom context (e.g., `MoneyPrinter-ajq:"Use PriceCache"`)

If no arguments provided, default to `--count 3`.

## Step 1: Identify Tasks

**If `--count N` was specified (or defaulted):**

Run `bd ready` to get available tasks:
```bash
bd ready
```

Select the first N tasks that are:
- **Not epics** — Prefer concrete tasks (type: task, feature, bug) over epics
- **High priority first** — P0 > P1 > P2 > P3 > P4
- **Not already in_progress** — Only ready tasks

**If specific tasks were provided:**

Validate each task exists:
```bash
bd show <task-id>
```

## Step 2: Worktree Cleanup

Prune any orphaned worktrees before spawning new workers:

```bash
git worktree prune
git worktree list
```

## Step 2.5: Risk Assessment (Plan Mode Detection + Risk Tiers)

**Skip if `--no-plan` was specified.** If `--plan-first` was specified, mark ALL tasks `[PLAN]`.

### Risk Tier Configuration

First, check for a project-level review config:

```bash
cat .claude/review.json 2>/dev/null || cat .claude/risk-tiers.json 2>/dev/null || echo "No review config found"
```

**With review config:** Match task file paths (from `bd show` description or related files) against tier patterns. The highest matching tier determines the task's risk level:

| Risk Tier | Dispatch Mode |
|-----------|---------------|
| critical | `[PLAN]` |
| high | `[PLAN]` |
| medium | `[AUTO]` |
| low | `[AUTO]` |

**Without review config (keyword fallback):** For each task, check its title + description (from `bd show`) for high-risk keywords (case-insensitive):

- **Security**: `auth`, `authentication`, `authorization`, `encrypt`, `secret`, `password`, `token`, `credential`
- **Data**: `migration`, `migrate`, `schema change`, `drop table`, `delete data`
- **Financial**: `payment`, `billing`, `subscription`, `transaction`
- **Architectural**: `architecture`, `redesign`, `rewrite`, `refactor core`

Mark matching tasks `[PLAN]`, others `[AUTO]`.

## Step 2.7: Model Selection

**If `--model` flag was specified:** Use that model for ALL tasks (overrides all other logic).

**With review config:**

| Risk Tier | Model |
|-----------|-------|
| critical | opus |
| high | opus |
| medium | sonnet |
| low | sonnet |

**Without review config (keyword fallback):**
- Keywords `architecture`, `security`, `auth`, `migration`, `rewrite`, `redesign` in task title/description → `opus`
- Everything else → `sonnet`

Display the model in the dispatch summary: `[AUTO/sonnet]` or `[PLAN/opus]`.

## Step 3: Generate Context

For each task without explicit context:

1. Read the task details from `bd show <task-id>`
2. Check what other tasks are currently in progress for situational awareness:
   ```bash
   bd list --status=in_progress 2>/dev/null
   ```
3. Look for related patterns in the codebase:
   - Check if similar files exist that the worker should follow
   - Look for recently completed dependencies
4. Generate a brief (1-2 sentence) context that helps the worker start faster

Example contexts:
- "Use sector_etfs.txt format from existing tickers/ directory"
- "Follow the pattern in backtesting/cache.py for data storage"
- "Depends on completed MoneyPrinter-xyz, can use its output"

## Step 4: Confirm Dispatch

Present a summary to the user:

```
Ready to dispatch N workers (worktree-isolated):

1. <task-id> (P1 <type>) [PLAN/opus]: <title>
   Context: "<generated or provided context>"

2. <task-id> (P2 <type>) [AUTO/sonnet]: <title>
   Context: "<generated or provided context>"

...
```

The `[PLAN/AUTO]` tags indicate dispatch mode. The `[opus/sonnet]` tags indicate the model selection from Step 2.7.

**If `--yes` was specified:**
Skip the AskUserQuestion confirmation and proceed directly to Step 5.

**Otherwise, use AskUserQuestion to confirm:**

Ask: "Confirm dispatch of N workers?"
- Options: "Yes, dispatch" / "No, cancel"
- multiSelect: false

**Wait for explicit user confirmation before proceeding.**

If user selects "No, cancel", abort dispatch.

## Step 5: Spawn Workers

Spawn each worker as a subagent with worktree isolation using the **Agent** tool. Launch all workers in a **single message** with multiple Agent tool calls for maximum parallelism.

For each task, use the Agent tool with:
- `isolation: "worktree"` — Each worker gets its own git worktree
- `run_in_background: true` — Workers run concurrently
- `mode: "bypassPermissions"` for `[AUTO]` tasks, `mode: "plan"` for `[PLAN]` tasks
- `model: "<selected>"` from Step 2.7
- `name: "<task-id>"` — Addressable by task ID

**Spawn prompt for `[AUTO]` tasks:**
```
You are an autonomous worker in your own isolated git worktree. Your task:

<task title and description from bd show>

Context: <generated context>

Currently in progress (other workers): <list from bd list --status=in_progress, if any>

Instructions:
1. Run `/start-task <task-id>` to claim the task and verify your environment
2. Implement the task according to the acceptance criteria
3. Run `/finish-task <task-id>` when tests pass and implementation is complete

CRITICAL CONTRACT:
- You MUST run /finish-task before completing. A task without a session summary is invisible to coordination.
- If you cannot complete the task, write a partial session summary explaining why before exiting.
- Your worktree will be cleaned up automatically after you finish.
```

**Spawn prompt for `[PLAN]` tasks:**
```
You are an autonomous worker in your own isolated git worktree, spawned in PLAN MODE. Your task:

<task title and description from bd show>

Context: <generated context>

Currently in progress (other workers): <list from bd list --status=in_progress, if any>

Instructions:
1. Run `/start-task <task-id>` to claim the task and gather context
2. Create a detailed implementation plan
3. Your plan will be reviewed before you can proceed to implementation
4. After approval, implement the task
5. Run `/finish-task <task-id>` when tests pass and implementation is complete

CRITICAL CONTRACT:
- You MUST run /finish-task before completing. A task without a session summary is invisible to coordination.
- If you cannot complete the task, write a partial session summary explaining why before exiting.
- Your worktree will be cleaned up automatically after you finish.
```

## Step 6: Post-Dispatch Summary

After all workers are spawned, provide a summary:

```
Dispatch complete: N workers spawned (worktree-isolated)

Workers:
1. <task-id> [AUTO/sonnet]: <title>
2. <task-id> [PLAN/opus]: <title>
...

Each worker has its own git worktree — no filesystem conflicts possible.

Workers will:
1. Run /start-task to claim the task
2. Implement the task
3. Run /finish-task when tests pass (creates PR, session summary)

Workers are running in the background. You will be notified as each completes.
After all workers finish, run /reconcile-summary to process their results.

IMPORTANT: Before ending this session, run /reconcile-summary to sync
all worker results back to beads.
```

## Error Handling

- **No ready tasks**: Suggest running `/orient` first to identify work
- **Task doesn't exist**: Skip it, warn the user, continue with valid tasks
- **All tasks invalid**: Abort with clear error message
- **Worker spawn fails**: Report the error, continue with remaining tasks

## Examples

**Auto-select 3 tasks (default):**
```
/dispatch
```

**Auto-select specific count:**
```
/dispatch --count 5
```

**Specific tasks:**
```
/dispatch MoneyPrinter-ajq MoneyPrinter-4b3
```

**With custom context:**
```
/dispatch MoneyPrinter-ajq:"Use existing ticker format"
```

**Force all tasks to use Opus:**
```
/dispatch --count 3 --model opus
```
