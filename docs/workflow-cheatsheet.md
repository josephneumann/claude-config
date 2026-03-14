# Workflow Cheatsheet

```bash
# Plan a new project
/spec → /spec --deepen (optional) → /orient → /dispatch

# Plan a new project (with UX)
/product-review DESIGN → /spec → /orient → /dispatch

# Single session
/orient → /start-task <id> → implement → /finish-task <id>

# Parallel sessions (orchestrator via Agent Teams)
/orient → /dispatch --count 3
# Teammates auto-spawn, run /start-task, implement, run /finish-task

# Worker completes → orchestrator reconciles
/reconcile-summary → update beads → dispatch next batch

# Fully autonomous
/auto-run --through <target-task>
# Or unattended: ~/.claude/scripts/auto-run.sh --max-hours 8
# Auto-run includes milestone review after tasks complete (skip with --skip-milestone-review)

# Milestone review (standalone — on any branch with accumulated changes)
/milestone-review --base-branch main
/milestone-review --dry-run              # report findings without fixing
/milestone-review --max-iterations 3     # limit review-fix cycles

# IMPORTANT: Before ending an orchestrator session, always run:
/reconcile-summary
```

## Beads Task Management

Tasks are managed with `bd` (beads CLI):

```bash
bd ready                    # Show tasks ready to work
bd list                     # All open tasks
bd show <id>                # Task details
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id>
bd sync --flush-only        # Export to JSONL
```

Quality gate hooks enforce workflow discipline. See `hooks/` for implementation.
