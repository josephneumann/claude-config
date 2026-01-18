---
description: Start working on a beads task with proper setup (worktree, context, daemon disabled)
allowed-tools: Read, Bash, Glob, Grep, Edit, Write, AskUserQuestion
---

# Start Beads Task: $ARGUMENTS

You are starting work on a beads task. Follow this checklist precisely.

## 0. Parse Arguments

The command format is: `/start-task <task-id> [--handoff "<context>"]`

Parse `$ARGUMENTS` to extract:
- `task_id`: The beads task ID (everything before any flags)
- `handoff_context`: Optional inline handoff text (content in quotes after `--handoff` flag)

Examples:
- `/start-task MoneyPrinter-46j.1` → task_id = `MoneyPrinter-46j.1`
- `/start-task MoneyPrinter-46j.1 --handoff "Use 3% tolerance"` → with handoff context

## 0.5 Display Handoff Context (if provided)

If handoff context was provided, display it prominently:

```
==============================================
HANDOFF CONTEXT FROM PREVIOUS SESSION
==============================================
<handoff_context>
==============================================
```

**Note**: This is supplementary guidance from an orchestrating session. Still gather full project context and read the task directly — the handoff supplements but doesn't replace normal setup.

## 1. Validate and Show Task

```bash
bd show <task_id>
```

Use the parsed `task_id` (not the full `$ARGUMENTS` which may contain `--handoff`).

If the task doesn't exist, stop and report the error.

## 2. Rename Conversation

Rename this conversation to the task ID and title for easy reference later:

```
/rename <task_id>: <task title>
```

For example: `/rename frq: Implement backtest engine`

## 3. Gather Project Context

Read these files to understand the project:
- `CLAUDE.md` - Development guidelines
- `PROJECT_SPEC.md` - Project specification (if exists)
- `AGENTS.md` - Agent workflow documentation (if exists)
- `README.md` - Project overview

## 4. Check Recent Work

```bash
bd list --all | head -20
git log --oneline -10
```

Understand what's been done recently and what state the project is in.

## 5. Check Task Dependencies

```bash
bd show <task_id>
```

Look at the "Blocked by" section. If this task has unmet dependencies, warn the user and ask if they want to proceed anyway.

## 6. Create Git Worktree

Determine the project directory name (e.g., `MoneyPrinter`). Create a worktree:

```bash
# Get current directory name
PROJECT_NAME=$(basename $(git rev-parse --show-toplevel))

# Create worktree with task ID as suffix
git worktree add ../${PROJECT_NAME}-<task_id> -b <task_id>-work
```

## 7. Switch to Worktree and Disable Daemon

```bash
cd ../${PROJECT_NAME}-<task_id>
export BEADS_NO_DAEMON=1
```

**CRITICAL**: Remind the user that this terminal session now has `BEADS_NO_DAEMON=1` set, which prevents beads from auto-committing to the wrong branch.

## 7.5. Copy Claude Settings to Worktree

Copy the `.claude` directory from the main repo to preserve permission allowlists:

```bash
# Copy .claude settings (if they exist in main repo)
if [ -d "../${PROJECT_NAME}/.claude" ]; then
  cp -r ../${PROJECT_NAME}/.claude ./.claude
  echo "Copied .claude settings to worktree"
fi
```

This ensures the agent has the same permission allowlist in the worktree as the main repo.

## 8. Claim the Task

```bash
bd update <task_id> --status in_progress
bd sync
```

## 9. Summarize the Task

Provide a summary:
- Task title and description
- Key acceptance criteria
- Files likely to be created/modified
- Suggested approach

## 10. Clarify Before Starting

**CRITICAL**: Before writing any code, use the `AskUserQuestion` tool to resolve ambiguities. Ask as many follow-up questions as needed to reach clarity on:

- Unclear requirements or acceptance criteria
- Implementation approach if multiple valid options exist
- Edge cases or error handling expectations
- Integration points with existing code
- Testing expectations

Keep asking until you have a clear picture of what "done" looks like. Do NOT proceed with assumptions - get explicit confirmation.

Example questions to consider:
- "The task mentions X but doesn't specify Y - which approach do you prefer?"
- "Should this handle edge case Z, or is that out of scope?"
- "I see two ways to implement this: A or B. Do you have a preference?"

## 11. Begin Implementation

Once all ambiguities are resolved and you have clear requirements, ask: "Ready to begin implementation?"

Only start coding after the user confirms.
