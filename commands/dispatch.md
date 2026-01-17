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
- `--ralph` — Enable ralph-loop for autonomous work (prompted, default: enabled)
- `--no-ralph` — Disable ralph-loop (manual mode)
- `--chrome` — Enable Chrome browser tools (prompted, default: enabled)
- `--no-chrome` — Disable Chrome browser tools
- `--skip-permissions` — Skip permission prompts (prompted, default: enabled)
- `--no-skip-permissions` — Require manual approval for operations
- `<task-id>` — Specific task to dispatch
- `<task-id>:"context"` — Task with custom handoff context (e.g., `MoneyPrinter-ajq:"Use PriceCache"`)

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

## Step 3: Confirm Dispatch and Options

Present a summary to the user:

```
Ready to dispatch N workers:

1. <task-id> (P2 <type>): <title>
   Handoff: "<generated or provided context>"

2. <task-id> (P1 <type>): <title>
   Handoff: "<generated or provided context>"

...
```

**Then use AskUserQuestion to confirm dispatch and configure options:**

Ask the user with these questions:

1. "Confirm dispatch of N workers?"
   - Options: "Yes, dispatch" / "No, cancel"
   - multiSelect: false

2. "Select worker options (all recommended for autonomous work):"
   - Options:
     - "Ralph mode (Recommended)" - "Autonomous iteration until tests pass"
     - "Chrome tools (Recommended)" - "Enable browser automation capabilities"
     - "Skip permissions (Recommended)" - "No manual approval prompts during execution"
   - multiSelect: true
   - NOTE: All three should be pre-selected/recommended by default

**Wait for explicit user confirmation before proceeding.**

If user selects "No, cancel" for question 1, abort dispatch.

## Step 4: Spawn Workers ONE AT A TIME

**CRITICAL: Spawn workers sequentially, waiting for user confirmation between each.**

For each task:

1. **Spawn the worker** using mp-spawn:
```bash
source ~/.zshrc && mp-spawn <task-id> --dir "$(pwd)" [--ralph] [--chrome] [--skip-permissions] --handoff "<context>"
```

Include flags based on user's selections from Step 3:
- Include `--ralph` if "Ralph mode" was selected
- Include `--chrome` if "Chrome tools" was selected
- Include `--skip-permissions` if "Skip permissions" was selected

2. **Output the command** that was copied to clipboard:
```
Worker 1/N spawned: <task-id>
Command on clipboard: /start-task <task-id> --ralph --handoff "..."

→ Switch to iTerm2 and paste (Cmd+V) when Claude Code is ready
```

3. **Use AskUserQuestion to confirm before spawning next worker:**

Ask: "Pasted command for <task-id>. Ready for next worker?"
- Options: "Yes, spawn next" / "Retry this worker" / "Stop dispatching"
- multiSelect: false

4. **Handle response:**
   - "Yes, spawn next" → Continue to next task
   - "Retry this worker" → Re-run mp-spawn for this task
   - "Stop dispatching" → End dispatch early, report which workers were spawned

5. **Repeat for each remaining task**

## Step 5: Post-Spawn Summary

After all workers are spawned (or dispatch stopped early), provide a summary:

```
Dispatch complete: N/M workers spawned

Active workers:
1. <task-id>: <title> — Tab 1
2. <task-id>: <title> — Tab 2
...

Worker tabs are named by task short ID (e.g., "6iw", "wpn").
Use Cmd+1/2/3 to navigate between worker tabs.

Each worker will:
1. Set up the task environment (git worktree)
2. Ask clarifying questions (if any)
3. Begin implementation [ralph mode if enabled]
4. Output "/finish-task <id>" when tests pass

You can continue working in this orchestrator session while workers execute.
```

## Error Handling

- **mp-spawn not found**: Tell user to run `source ~/.zshrc` or check installation
- **No ready tasks**: Suggest running `/orient` first to identify work
- **Task doesn't exist**: Skip it, warn the user, continue with valid tasks
- **iTerm2 not available**: Tell user mp-spawn requires iTerm2 on macOS
- **All tasks invalid**: Abort with clear error message
- **User stops early**: Report which workers were successfully spawned

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

**With custom handoff:**
```
/dispatch MoneyPrinter-ajq:"Use existing ticker format"
```

**Explicit manual mode (no ralph):**
```
/dispatch MoneyPrinter-ajq --no-ralph
```

**Explicit no chrome:**
```
/dispatch --count 2 --no-chrome
```
