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

2. "Select worker options (recommended for autonomous work):"
   - Options:
     - "Chrome tools (Recommended)" - "Enable browser automation capabilities"
     - "Skip permissions (Recommended)" - "No manual approval prompts during execution"
   - multiSelect: true
   - NOTE: Both should be pre-selected/recommended by default

**Wait for explicit user confirmation before proceeding.**

If user selects "No, cancel" for question 1, abort dispatch.

## Step 4: Spawn Workers ONE AT A TIME

**CRITICAL: Spawn workers sequentially, waiting for user confirmation between each.**

For each task:

1. **Write the handoff file** to `pending_handoffs/`:
```bash
# Ensure directory exists
mkdir -p "$(pwd)/pending_handoffs"

# Write handoff file with context
cat > "$(pwd)/pending_handoffs/<task-id>.txt" << 'HANDOFF_EOF'
TASK_ID: <task-id>
TIMESTAMP: <iso-timestamp>
---
<handoff context text>
HANDOFF_EOF
```

Also ensure `pending_handoffs/` is in `.gitignore`:
```bash
if ! grep -q "^pending_handoffs/$" .gitignore 2>/dev/null; then
  echo "pending_handoffs/" >> .gitignore
fi
```

2. **Spawn the worker** using mp-spawn:
```bash
source ~/.zshrc && mp-spawn <task-id> --dir "$(pwd)" [--chrome] [--skip-permissions]
```

Include flags based on user's selections from Step 3:
- Include `--chrome` if "Chrome tools" was selected
- Include `--skip-permissions` if "Skip permissions" was selected

Note: The `--handoff` flag is no longer needed as handoff context is now passed via the file.

3. **Output status**:
```
Worker 1/N spawned: <task-id>
Handoff written to: pending_handoffs/<task-id>.txt

The worker will automatically receive handoff context via SessionStart hook.
```

4. **Use AskUserQuestion to confirm before spawning next worker:**

Ask: "Worker for <task-id> spawned. Ready for next worker?"
- Options: "Yes, spawn next" / "Retry this worker" / "Stop dispatching"
- multiSelect: false

5. **Handle response:**
   - "Yes, spawn next" → Continue to next task
   - "Retry this worker" → Re-write handoff file and re-run mp-spawn for this task
   - "Stop dispatching" → End dispatch early, report which workers were spawned

6. **Repeat for each remaining task**

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

Each worker will automatically:
1. Receive handoff context via SessionStart hook
2. Execute /start-task to set up the task environment (git worktree)
3. Ask clarifying questions (if any)
4. Begin implementation
5. Run /finish-task when tests pass

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

**Explicit no chrome:**
```
/dispatch --count 2 --no-chrome
```
