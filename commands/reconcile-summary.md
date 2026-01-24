---
description: Review a worker session summary and reconcile beads tasks with implementation reality
allowed-tools: Read, Bash, Glob, Grep, Edit, Write
---

# Reconcile Session Summary

You are an orchestrating agent reviewing a completed worker session. Your job is to ensure the beads task board accurately reflects what was actually built, not just what was originally specified.

## 1. Receive the Session Summary

The user will paste a session summary from a completed worker session. Parse it to extract:

- **Task ID** from the TASK OVERVIEW section
- **SPEC DIVERGENCES** section (critical - this tells you what changed)
- **FOLLOW-UP ISSUES CREATED** section
- **DEPENDENCIES UNBLOCKED** section
- **ARCHITECTURAL NOTES** section

If no summary is pasted, ask the user to paste it or provide a path to the summary file.

## 2. Review the Original Task

```bash
bd show <task-id>
```

Compare the original task description against what the worker reported in:
- IMPLEMENTATION SUMMARY
- SPEC DIVERGENCES

## 3. Analyze Divergences

For each divergence documented by the worker, determine:

1. **Scope**: Does this affect only this task, or does it ripple to other tasks?
2. **Downstream impact**: Which blocked/dependent tasks need their descriptions updated?
3. **New work**: Does this divergence create new tasks that weren't anticipated?
4. **Invalidated work**: Does this make any existing tasks obsolete or redundant?

## 4. Review Related Tasks

```bash
# Show tasks that were blocked by the completed task
bd show <task-id> | grep -A 10 "BLOCKS"

# List all open tasks to check for ripple effects
bd list --status=open
```

For each potentially affected task:

```bash
bd show <affected-task-id>
```

Ask yourself:
- Does this task's description assume something that's no longer true?
- Does the implementation change how this task should be approached?
- Are there new dependencies or constraints to document?

## 5. Update Beads Tasks

For each task that needs updating, use `bd update` to modify the description:

```bash
# Update task description to reflect new reality
bd update <task-id> --description "$(cat <<'EOF'
<updated description that reflects the actual implementation>

## Updated Context
This task was updated based on implementation of <completed-task-id>.

Changes from original spec:
- <change 1>
- <change 2>

New constraints/dependencies:
- <constraint 1>
EOF
)"
```

### Common Updates

**If a task is now obsolete:**
```bash
bd close <task-id> --reason="Obsoleted by implementation of <task-id>. <brief explanation>"
```

**If a task needs new dependencies:**
```bash
bd dep add <task-id> <new-dependency-id>
```

**If scope expanded and needs splitting:**
```bash
bd create --title="<split-off work>" --type=task --priority=2
bd dep add <new-task-id> <original-task-id>
```

**If implementation discovered new required work:**
```bash
bd create --title="<discovered work>" --type=task --priority=2
# Add appropriate dependencies
```

## 6. Sync Changes

```bash
bd sync
```

## 7. Report Reconciliation

Output a reconciliation report:

```
===============================================
RECONCILIATION REPORT
===============================================

REVIEWED TASK
-------------
ID: <task-id>
Title: <title>
Status: Closed

DIVERGENCES PROCESSED
---------------------
<For each divergence from the session summary>

1. <Divergence title>
   Action taken: <what you did - updated task X, created task Y, closed task Z>

TASKS UPDATED
-------------
<List each task that was modified>

- <task-id>: <brief description of change>
- <task-id>: <brief description of change>

TASKS CREATED
-------------
<List any new tasks created>

- <task-id>: <title>

TASKS CLOSED
------------
<List any tasks closed as obsolete>

- <task-id>: <reason>

REMAINING CONCERNS
------------------
<Any issues that couldn't be automatically resolved, need human decision, or require discussion>

TASK BOARD STATUS
-----------------
Ready tasks: <count from bd ready>
Blocked tasks: <count>
Total open: <count>

===============================================
END RECONCILIATION REPORT
===============================================
```

## 8. Update Architectural Documentation (If Needed)

If divergences represent significant architectural changes (not just implementation details), consider updating project-level documentation:

**PROJECT_SPEC.md** - Update if:
- Core architecture changed (different services, data flow, etc.)
- Technology choices changed (different libraries, frameworks)
- API contracts changed significantly
- Data models changed

**Project CLAUDE.md** - Update if:
- New patterns or conventions were established
- New commands or workflows were added
- Critical rules changed (e.g., "never do X")

```bash
# Check if these files exist
ls -la PROJECT_SPEC.md CLAUDE.md 2>/dev/null
```

Use AskUserQuestion to confirm before modifying these files:

**Question:** "Divergence '<title>' represents an architectural change. Update PROJECT_SPEC.md or CLAUDE.md?"
- **Options:** "Yes, update docs" / "No, beads only" / "Ask me about each file"

## 9. Copy Reconciliation Report (Optional)

Use AskUserQuestion to offer copying the report to clipboard:

**Question:** "Copy reconciliation report to clipboard?"
- **Options:** "Yes, copy to clipboard" / "No, skip"
- **Header:** "Clipboard"

If the user selects "Yes, copy to clipboard", copy the full reconciliation report.

## 10. Prompt for Next Action

After reconciliation, ask the user:

"Reconciliation complete. What would you like to do next?"
- **Review changes** - Show the updated tasks in detail
- **Continue orchestrating** - Return to normal orchestration
- **Dispatch more workers** - Spin up workers for newly unblocked tasks

## Important Guidelines

1. **Be thorough** - A divergence in one task often ripples to many others
2. **Preserve intent** - When updating task descriptions, keep the original goal clear
3. **Document reasoning** - Future agents need to understand why specs changed
4. **Don't over-correct** - Only update tasks that are actually affected
5. **Ask when uncertain** - If a divergence has unclear implications, ask the user
