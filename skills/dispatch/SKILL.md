---
name: dispatch
description: "Dispatch parallel Agent Teams teammates for beads tasks"
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion, TeamCreate, TaskCreate, TaskUpdate, TaskList, SendMessage, Task
---

# Dispatch Teammates: $ARGUMENTS

You are an orchestrator dispatching parallel Agent Teams teammates for beads tasks.

## Parse Arguments

Arguments: `$ARGUMENTS`

Parse the following patterns:
- `--count N` — Auto-select N ready tasks from `bd ready`
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

## Step 2: Generate Context

For each task without explicit context:

1. Read the task details from `bd show <task-id>`
2. Look for related patterns in the codebase:
   - Check if similar files exist that the worker should follow
   - Look for recently completed dependencies
3. Generate a brief (1-2 sentence) context that helps the teammate start faster

Example contexts:
- "Use sector_etfs.txt format from existing tickers/ directory"
- "Follow the pattern in backtesting/cache.py for data storage"
- "Depends on completed MoneyPrinter-xyz, can use its output"

## Step 3: Confirm Dispatch

Present a summary to the user:

```
Ready to dispatch N teammates:

1. <task-id> (P2 <type>): <title>
   Context: "<generated or provided context>"

2. <task-id> (P1 <type>): <title>
   Context: "<generated or provided context>"

...
```

**Use AskUserQuestion to confirm:**

Ask: "Confirm dispatch of N teammates?"
- Options: "Yes, dispatch" / "No, cancel"
- multiSelect: false

**Wait for explicit user confirmation before proceeding.**

If user selects "No, cancel", abort dispatch.

## Step 4: Create Team and Spawn Teammates

1. **Create the team** using TeamCreate with a descriptive name based on the project/tasks.

2. **Create tasks** in the Agent Teams task list using TaskCreate — one per beads task. Include in each task description:
   - The beads task ID
   - Task title and description from `bd show`
   - The generated context
   - Clear instruction: "Run `/start-task <task-id>` to begin. Run `/finish-task <task-id>` when done."

3. **Set up dependencies** between tasks using TaskUpdate if the beads tasks have dependencies.

4. **Spawn teammates** using the Task tool with `team_name` parameter, `isolation: "worktree"`, and `mode: "bypassPermissions"` — one per task. Each teammate should be a `general-purpose` subagent type. Give each teammate a descriptive name based on the task (e.g., the task short ID).

   The spawn prompt for each teammate should include:
   ```
   You are a worker on team "<team-name>". Your task:

   <task title and description from bd show>

   Context: <generated context>

   Instructions:
   1. Run `/start-task <task-id>` to claim the task and verify your environment
      (You're already in an isolated worktree with .env files set up)
   2. Implement the task according to the acceptance criteria
   3. Run `/finish-task <task-id>` when tests pass and implementation is complete
   4. Report back to the team lead when done
   ```

5. **Assign tasks** using TaskUpdate to set the owner of each task to the corresponding teammate name.

## Step 5: Post-Dispatch Summary

After all teammates are spawned, provide a summary:

```
Dispatch complete: N teammates spawned

Team: <team-name>
Teammates:
1. <name>: <task-id> — <title>
2. <name>: <task-id> — <title>
...

Each teammate runs in an isolated worktree (via isolation: "worktree") and will:
1. Run /start-task to claim the task and verify environment
2. Implement the task
3. Run /finish-task when tests pass

Use Shift+Up/Down to switch between teammates (in-process mode).
The team lead will receive notifications as teammates complete work.

IMPORTANT: Before ending this session, run /reconcile-summary to sync
all teammate work back to beads.
```

## Error Handling

- **No ready tasks**: Suggest running `/orient` first to identify work
- **Task doesn't exist**: Skip it, warn the user, continue with valid tasks
- **All tasks invalid**: Abort with clear error message
- **Teammate spawn fails**: Report the error, continue with remaining tasks

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
