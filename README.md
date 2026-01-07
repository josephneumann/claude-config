# Claude Config

Custom commands and hooks for Claude Code, designed for the **beads** task management workflow.

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-config.git ~/Code/claude-config
cd ~/Code/claude-config
./install.sh
```

This creates symlinks from `~/.claude/commands` and `~/.claude/hooks` to this repo.

---

## Commands Reference

### `/orient`

**Purpose:** Orient to a project and identify parallelizable work streams.

**What it does:**
1. Discovers project structure (README, CLAUDE.md, PROJECT_SPEC.md)
2. Analyzes beads task state (`bd list`, `bd ready`)
3. Checks git status and recent commits
4. Runs tests to verify project health
5. Outputs a structured **Orientation Report** with recommended parallel work streams

**When to use:** At the start of a session to understand what work is available.

**Example:**
```
/orient
```

**Output includes:**
- Project identity and stack
- Task overview (open, ready, in-progress)
- Critical path analysis
- Recommended parallel work streams with `/start-task` commands

---

### `/start-task <task-id>`

**Purpose:** Start working on a beads task with proper isolation and context.

**What it does:**
1. Validates the task exists (`bd show`)
2. Renames the conversation to the task ID
3. Gathers project context (CLAUDE.md, README, etc.)
4. Creates a **git worktree** for isolation
5. Disables beads daemon (`BEADS_NO_DAEMON=1`)
6. Claims the task (`bd update --status in_progress`)
7. Asks clarifying questions before implementation

**Options:**
- `--ralph` - Enable autonomous implementation with ralph-loop
- `--max-iterations N` - Max ralph-loop iterations (default: 10)
- `--handoff "<context>"` - Inline context from a previous session

**Examples:**
```bash
# Standard start
/start-task MoneyPrinter-46j.1

# With ralph-loop for autonomous implementation
/start-task MoneyPrinter-46j.1 --ralph

# With handoff context from another session
/start-task MoneyPrinter-46j.1 --handoff "Use 3% tolerance for price matching"
```

**Important:** After starting, you'll be in a separate worktree. All changes are isolated from the main branch.

---

### `/finish-task <task-id>`

**Purpose:** Complete a task with full quality checks and cleanup.

**What it does:**
1. Verifies current state (correct worktree, task in-progress)
2. Runs quality gates (tests must pass)
3. Reviews and updates documentation
4. Creates follow-up issues for discovered work
5. Commits all changes with proper format
6. Syncs beads and pushes to remote
7. Closes the task (`bd close`)
8. Creates a pull request
9. Optionally merges PR and cleans up worktree
10. Outputs a detailed **Session Summary**

**Example:**
```
/finish-task MoneyPrinter-46j.1
```

**Critical:** Tests must pass before the task can be finished. The command will stop if tests fail.

---

### `/handoff-task <task-id>`

**Purpose:** Generate context for passing a task to another Claude session.

**What it does:**
1. Validates the task
2. Gathers session-specific context (decisions made, gotchas discovered)
3. Outputs a copy-pasteable `/start-task` command with handoff context

**When to use:**
- Ending a session but work isn't complete
- Passing work to a parallel session
- Context is too large for current session

**Example:**
```
/handoff-task MoneyPrinter-46j.1
```

**Output:**
```
/start-task MoneyPrinter-46j.1 --handoff "Used pytest fixtures for DB setup. Watch for timezone issues in date parsing."
```

---

### `/summarize-session <task-id>`

**Purpose:** Generate a detailed session summary without closing the task.

**What it does:**
1. Gathers context (git status, recent commits, changed files)
2. Checks test status
3. Outputs a structured **Session Summary**

**When to use:**
- Mid-session checkpoint
- Before a handoff
- When you need to document progress without finishing

**Example:**
```
/summarize-session MoneyPrinter-46j.1
```

**Difference from `/finish-task`:** This command is read-only. It doesn't commit, push, close the task, or make any changes.

---

## Hooks Reference

### `beads-ralph-stop.sh`

**Purpose:** Auto-handoff when ralph-loop reaches max iterations.

**When it runs:** Automatically triggered when a ralph-loop session ends.

**Behavior:**
- If tests are passing: Outputs "Run `/finish-task <id>`"
- If tests not passing: Outputs a `/start-task --ralph --handoff` command for continuation

**You don't invoke this directly** - it runs automatically as part of the ralph-loop workflow.

---

## Workflow Examples

### 1. Single-Session Workflow

Standard workflow for completing one task in a single session:

```bash
# 1. Orient to the project
/orient

# 2. Start a task (creates worktree, claims task)
/start-task beads-abc123

# 3. Do the work...
#    - Read code
#    - Implement changes
#    - Run tests

# 4. Finish (commit, PR, cleanup)
/finish-task beads-abc123
```

### 2. Multi-Session Parallel Workflow

Run multiple tasks simultaneously in separate Claude sessions:

**Terminal 1:**
```bash
/orient
# See recommended streams, then:
/start-task beads-feature-1
# Work on feature 1...
/finish-task beads-feature-1
```

**Terminal 2:**
```bash
/start-task beads-feature-2
# Work on feature 2...
/finish-task beads-feature-2
```

**Terminal 3:**
```bash
/start-task beads-feature-3
# Work on feature 3...
/finish-task beads-feature-3
```

Each session works in its own git worktree - no conflicts.

### 3. Ralph Loop Workflow

Autonomous implementation with automatic test-driven iteration:

```bash
# Start with ralph-loop enabled
/start-task beads-abc123 --ralph

# Claude will:
# 1. Understand the task
# 2. Ask clarifying questions
# 3. Start ralph-loop when ready
# 4. Iterate until tests pass (or max iterations)

# On success: "Run /finish-task beads-abc123"
# On max iterations: Outputs handoff command for continuation
```

**With custom iteration limit:**
```bash
/start-task beads-abc123 --ralph --max-iterations 50
```

### 4. Handoff Workflow

Pass work between sessions when context grows too large:

**Session 1 (hitting context limits):**
```bash
/start-task beads-abc123
# Work for a while...
# Context getting large, need to hand off

/handoff-task beads-abc123
# Outputs: /start-task beads-abc123 --handoff "..."
```

**Session 2 (fresh context):**
```bash
# Paste the handoff command from session 1
/start-task beads-abc123 --handoff "Used pytest fixtures for DB setup..."

# Continue where session 1 left off
/finish-task beads-abc123
```

---

## Installation on a New Machine

1. **Clone the repo:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-config.git ~/Code/claude-config
   ```

2. **Run the installer:**
   ```bash
   cd ~/Code/claude-config
   ./install.sh
   ```

3. **Verify:**
   ```bash
   ls -la ~/.claude/commands  # Should show symlink
   ls -la ~/.claude/hooks     # Should show symlink
   ```

The installer:
- Creates `~/.claude/` if needed
- Backs up existing directories (if any)
- Creates symlinks to the repo
- Is idempotent (safe to run multiple times)

---

## Adding New Commands or Hooks

### Adding a Command

1. Create a new `.md` file in `commands/`:
   ```bash
   vim ~/Code/claude-config/commands/my-new-command.md
   ```

2. Use the frontmatter format:
   ```markdown
   ---
   description: Short description of what this command does
   allowed-tools: Read, Bash, Glob, Grep, Edit, Write
   ---

   # My New Command: $ARGUMENTS

   Instructions for Claude...
   ```

3. Commit and push:
   ```bash
   cd ~/Code/claude-config
   git add commands/my-new-command.md
   git commit -m "Add my-new-command"
   git push
   ```

4. Use immediately:
   ```
   /my-new-command arg1 arg2
   ```

### Adding a Hook

1. Create a new script in `hooks/`:
   ```bash
   vim ~/Code/claude-config/hooks/my-hook.sh
   chmod +x ~/Code/claude-config/hooks/my-hook.sh
   ```

2. Commit and push:
   ```bash
   git add hooks/my-hook.sh
   git commit -m "Add my-hook"
   git push
   ```

---

## Prerequisites

These commands assume you have:
- **beads** (`bd`) - Task management CLI
- **git** - With worktree support
- **gh** - GitHub CLI (for PR creation)

---

## License

MIT
