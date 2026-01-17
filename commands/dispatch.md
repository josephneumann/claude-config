---
description: Dispatch parallel Claude Code workers for beads tasks
allowed-tools: Bash, Read, Glob, Grep
---

# Dispatch Workers: $ARGUMENTS

You are an orchestrator dispatching parallel Claude Code workers using `mp-spawn`.

## Parse Arguments

Arguments: `$ARGUMENTS`

Parse the following patterns:
- `--count N` — Auto-select N ready tasks from `bd ready`
- `--ralph` (default) — Enable ralph-loop for autonomous work
- `--no-ralph` — Disable ralph-loop (manual mode)
- `<task-id>` — Specific task to dispatch
- `<task-id>:"context"` — Task with custom handoff context (e.g., `MoneyPrinter-ajq:"Use PriceCache"`)

If no arguments provided, default to `--count 3 --ralph`.

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

## Step 2: Generate Handoff Context

For each task without explicit handoff context:

1. Read the task details from `bd show <task-id>`
2. Look for related patterns in the codebase:
   - Check if similar files exist that the worker should follow
   - Look for recently completed dependencies
3. Generate a brief (1-2 sentence) handoff context that helps the worker start faster

Example handoff contexts:
- "Use sector_etfs.txt format from existing tickers/ directory"
- "Follow the pattern in backtesting/cache.py for data storage"
- "Depends on completed MoneyPrinter-xyz, can use its output"

## Step 3: Confirm Dispatch

Present a summary to the user:

```
Ready to dispatch N workers:

1. <task-id> (P2 <type>): <title>
   Handoff: "<generated or provided context>"
   Mode: ralph

2. <task-id> (P1 <type>): <title>
   Handoff: "<generated or provided context>"
   Mode: ralph

...
```

**Then use AskUserQuestion to confirm dispatch and permissions:**

Ask the user with these questions:
1. "Confirm dispatch of N workers?" - Options: "Yes, dispatch" / "No, cancel"
2. "Use --skip-permissions for autonomous workers?" - Options: "Yes (recommended for ralph mode)" / "No (require manual approval)"

If the user confirms dispatch AND selects "Yes" for skip-permissions, pass `--skip-permissions` to each `mp-spawn` call.

**Wait for explicit user confirmation before proceeding.**

## Step 4: Spawn Workers

After confirmation, for each task run mp-spawn using the Bash tool:

```bash
source ~/.zshrc && mp-spawn <task-id> --dir "$(pwd)" --ralph --handoff "<context>" --skip-permissions
```

**Flags to include:**
- Always include `--ralph` unless `--no-ralph` was specified
- Include `--skip-permissions` if user confirmed "Yes" for skip-permissions in step 3
- Note: `--chrome` is always enabled by default in mp-spawn

Each mp-spawn call opens a new iTerm2 tab via AppleScript. Run them sequentially.

## Step 5: Post-Spawn Guidance

After all workers are spawned, output the appropriate guidance based on whether skip-permissions was enabled:

**If skip-permissions was enabled:**
```
Dispatched N workers with --skip-permissions (autonomous mode).

For each worker tab:
1. Switch to iTerm2 (Cmd+Tab)
2. Paste the command (Cmd+V) — it's on your clipboard
3. Press Enter to start

Workers will run autonomously without permission prompts.
Use Cmd+1/2/3 to navigate between worker tabs.

Each worker will:
1. Set up the task environment
2. Ask clarifying questions (if any)
3. Begin implementation (ralph mode)
4. Output "/finish-task <id>" when tests pass

You can continue working in this orchestrator session while workers execute.
```

**If skip-permissions was NOT enabled:**
```
Dispatched N workers (manual approval mode).

For each worker tab:
1. Switch to iTerm2 (Cmd+Tab)
2. Answer the trust prompt for the worktree directory
3. Paste the command (Cmd+V) — it's on your clipboard
4. Press Enter to start

Use Cmd+1/2/3 to navigate between worker tabs.

Each worker will:
1. Set up the task environment
2. Ask clarifying questions (if any)
3. Begin implementation (ralph mode)
4. Output "/finish-task <id>" when tests pass

You can continue working in this orchestrator session while workers execute.
```

## Error Handling

- **mp-spawn not found**: Tell user to run `source ~/.zshrc` or check installation
- **No ready tasks**: Suggest running `/orient` first to identify work
- **Task doesn't exist**: Skip it, warn the user, continue with valid tasks
- **iTerm2 not available**: Tell user mp-spawn requires iTerm2 on macOS
- **All tasks invalid**: Abort with clear error message

## Examples

**Auto-select 3 tasks:**
```
/dispatch --count 3
```

**Specific tasks:**
```
/dispatch MoneyPrinter-ajq MoneyPrinter-4b3
```

**With custom handoff:**
```
/dispatch MoneyPrinter-ajq:"Use existing ticker format"
```

**Manual mode (no ralph):**
```
/dispatch MoneyPrinter-ajq --no-ralph
```
