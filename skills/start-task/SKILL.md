---
name: start-task
description: "Start working on a beads task with proper setup (worktree, context, daemon disabled)"
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

## 1. Validate and Claim Task (FIRST!)

**CRITICAL: Claim the task immediately to prevent race conditions with parallel workers.**

```bash
# Validate task exists
bd show <task_id>
```

If the task doesn't exist, stop and report the error.

If the task is already `in_progress` or `closed`, warn the user:
- If `in_progress`: "This task is already claimed. Another worker may be on it. Proceed anyway?"
- If `closed`: "This task is already closed. Did you mean a different task?"

**Claim it immediately:**

```bash
bd update <task_id> --status in_progress
bd sync
```

This must happen BEFORE any other setup (worktree creation, context gathering, etc.) to minimize the window where two workers might claim the same task.

## 2. Display Handoff Context (if provided)

If handoff context was provided, display it prominently:

```
==============================================
HANDOFF CONTEXT FROM PREVIOUS SESSION
==============================================
<handoff_context>
==============================================
```

**Note**: This is supplementary guidance from an orchestrating session. Still gather full project context and read the task directly — the handoff supplements but doesn't replace normal setup.

## 3. Rename Conversation

Rename this conversation to the task ID and title for easy reference later:

```
/rename <task_id>: <task title>
```

For example: `/rename frq: Implement backtest engine`

## 4. Gather Project Context

Read these files to understand the project:
- `CLAUDE.md` - Development guidelines
- `PROJECT_SPEC.md` - Project specification (if exists)
- `AGENTS.md` - Agent workflow documentation (if exists)
- `README.md` - Project overview

## 5. Check Recent Work

```bash
bd list --all | head -20
git log --oneline -10
```

Understand what's been done recently and what state the project is in.

## 6. Check Task Dependencies

```bash
bd show <task_id>
```

Look at the "Blocked by" section. If this task has unmet dependencies, warn the user and ask if they want to proceed anyway.

## 6.5 Research Phase (Conditional)

Before implementation, determine if research is needed based on task characteristics.

### High-Risk Indicators (Research First)

Research is recommended when the task involves:
- **Security**: authentication, authorization, encryption, secrets
- **Payments**: billing, subscriptions, transactions, financial data
- **External APIs**: third-party integrations, webhooks, OAuth
- **Data migrations**: schema changes, data transformations
- **New frameworks/libraries**: unfamiliar dependencies

### Research Agents to Consider

1. **framework-docs-researcher**
   - Read: `~/.claude/agents/research/framework-docs-researcher.md`
   - Use when: Task involves libraries or frameworks
   - Checks: Documentation, deprecation warnings, best practices

2. **learnings-researcher**
   - Read: `~/.claude/agents/research/learnings-researcher.md`
   - Use when: `docs/solutions/` exists in the project
   - Searches: Prior solutions, gotchas, patterns from past work

3. **best-practices-researcher**
   - Read: `~/.claude/agents/research/best-practices-researcher.md`
   - Use when: Architectural decisions needed
   - Provides: Industry best practices, pattern recommendations

### Launch Research (if needed)

```
Use Task tool with subagent_type=general-purpose:

Task: [appropriate-researcher]
- Read agent definition from ~/.claude/agents/research/
- Provide task context and requirements
- Return: Relevant findings, recommendations, warnings
```

### Skip Research If

- Internal refactoring only (no new patterns)
- Strong patterns already documented in CLAUDE.md
- Established team conventions for this type of work
- Simple bug fix with clear scope

### Document Research Findings

If research was conducted, update the task:
```bash
bd update <task_id> --notes "Research: <brief summary of findings>"
```

---

## 7. Create Git Worktree

Determine the project directory name (e.g., `MoneyPrinter`). Create a worktree:

```bash
# Get current directory name
PROJECT_NAME=$(basename $(git rev-parse --show-toplevel))

# Create worktree with task ID as suffix
git worktree add ../${PROJECT_NAME}-<task_id> -b <task_id>-work
```

## 8. Switch to Worktree and Disable Daemon

```bash
cd ../${PROJECT_NAME}-<task_id>
export BEADS_NO_DAEMON=1
```

**CRITICAL**: Remind the user that this terminal session now has `BEADS_NO_DAEMON=1` set, which prevents beads from auto-committing to the wrong branch.

## 8.5. Copy Claude Settings to Worktree

Copy the `.claude` directory from the main repo to preserve permission allowlists:

```bash
# Copy .claude settings (if they exist in main repo)
if [ -d "../${PROJECT_NAME}/.claude" ]; then
  cp -r ../${PROJECT_NAME}/.claude ./.claude
  echo "Copied .claude settings to worktree"
fi
```

This ensures the agent has the same permission allowlist in the worktree as the main repo.

## 8.6. Symlink Environment Files to Worktree

Worktrees only contain tracked files — `.env` files are gitignored and won't exist in new worktrees. Symlink them so tests and local services work:

```bash
# Symlink .env files from main repo (if they exist)
for envfile in ../${PROJECT_NAME}/.env ../${PROJECT_NAME}/.env.*; do
  if [ -f "$envfile" ]; then
    filename=$(basename "$envfile")
    ln -sf "$(cd "$(dirname "$envfile")" && pwd)/$filename" "./$filename"
    echo "Symlinked $filename to worktree"
  fi
done
```

**Why symlink instead of copy?** One source of truth — when secrets rotate, all worktrees pick up the change automatically. No stale copies.

## 9. Assess Task Size

**Philosophy: Task-sized work** — Tasks should fit comfortably in context.

Now that you can see the codebase, evaluate whether this task is appropriately sized:

**Signs the task is too large:**
- Multiple independent features bundled together
- Requires changes across 10+ files
- Has vague scope like "refactor the entire X system"
- You anticipate needing a handoff mid-task

**If too large**, present options to the user:

```
This task seems large for a single session. Options:

1. **Break it down** — I'll create subtasks and we pick one to start
2. **Proceed anyway** — Work on it knowing we may need a handoff
3. **Scope it down** — Redefine acceptance criteria to a smaller slice

Which approach?
```

**If user chooses "Break it down":**
```bash
# Create subtasks
bd create --title="Subtask: <part 1>" --type=task --priority=<same>
bd create --title="Subtask: <part 2>" --type=task --priority=<same>

# Link to parent
bd dep add <subtask-id> <parent-task-id>

# Unclaim the parent (it's now a container)
bd update <parent-task-id> --status open
```

Then ask: "Which subtask should we work on? I'll switch to that task."

If they pick a subtask, **start over from step 1** with the subtask ID. The current worktree can be reused or removed.

**If appropriately sized**, continue to step 10.

## 10. Define Acceptance Criteria

**Philosophy: Bounded autonomy** — Define "done" before coding.

Work with the user to establish clear acceptance criteria. Use `AskUserQuestion` to confirm:

```
Before I start, let me confirm the acceptance criteria:

1. [ ] <functional requirement 1>
2. [ ] <functional requirement 2>
3. [ ] <edge case or constraint>
4. [ ] Tests pass
5. [ ] /finish-task run (creates PR, session summary, closes task)

Is this complete? Anything to add or change?
```

**IMPORTANT**: Items 4 and 5 are ALWAYS required and non-negotiable:
- **Tests pass** — Code must be verified working
- **`/finish-task` run** — The session is not complete without this. It creates the PR, generates a session summary for the orchestrator, and closes the task. Skipping this breaks the coordination workflow.

**Good acceptance criteria are:**
- **Specific** — "User can log in with email/password" not "authentication works"
- **Testable** — Can be verified with a test or clear manual check
- **Bounded** — Clear what's in scope and what's not

Record the agreed criteria:
```bash
bd update <task_id> --notes "Acceptance: <brief summary of criteria>"
```

## 11. Clarify Ambiguities

**CRITICAL**: Before writing any code, use `AskUserQuestion` to resolve any remaining ambiguities:

- Implementation approach if multiple valid options exist
- Edge cases not covered by acceptance criteria
- Integration points with existing code
- Testing strategy

Keep asking until you have a clear picture. Do NOT proceed with assumptions.

Example questions:
- "The task mentions X but doesn't specify Y - which approach do you prefer?"
- "Should this handle edge case Z, or is that out of scope?"
- "I see two ways to implement this: A or B. Do you have a preference?"

## 12. Begin Implementation

Once:
- Task is appropriately sized (or user approved proceeding)
- Acceptance criteria are defined
- Ambiguities are resolved

Ask: "Ready to begin implementation?"

Only start coding after the user confirms.

---

## 13. CRITICAL: Task Completion Contract

**YOUR WORK IS NOT DONE UNTIL YOU RUN `/finish-task <task-id>`**

When implementation is complete (tests pass, code works), you MUST run:

```
/finish-task <task-id>
```

This command handles everything required to properly close out:
- Creates the PR
- Runs automated code review
- Generates session summary for orchestrator
- Closes the task in beads
- Cleans up the worktree

**DO NOT**:
- Stop the session without running `/finish-task`
- Tell the user "done!" without running `/finish-task`
- Consider the task complete just because tests pass
- Hand off without `/finish-task` (notify the team lead if work is incomplete)

The orchestrator depends on your session summary to coordinate parallel work. A task without a session summary is invisible to coordination.
