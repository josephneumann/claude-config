# Claude Config

Custom commands and hooks for Claude Code, designed for the **beads** task management workflow.

## Quick Install

```bash
git clone https://github.com/josephneumann/claude-config.git ~/Code/claude-config
cd ~/Code/claude-config
./install.sh
```

This creates symlinks from `~/.claude/commands` and `~/.claude/hooks` to this repo, and adds `bin/` utilities to your PATH.

---

## Philosophy: Parallel Agentic Development

This setup enables a specific approach to AI-assisted development:

1. **Parallel by default** — Multiple Claude sessions work simultaneously on independent tasks, each in isolated git worktrees. No waiting for one task to finish before starting another.

2. **Orchestrator + Workers** — One session orients and identifies parallelizable work; worker sessions execute discrete tasks. The orchestrator sees the big picture, workers focus deeply.

3. **Task isolation** — Each task gets its own branch/worktree, preventing conflicts and enabling clean PRs. No merge hell, no stepping on each other's work.

4. **Bounded autonomy** — Claude can work autonomously (ralph mode) but within bounds: clear acceptance criteria, test-driven completion, iteration limits. Autonomy with guardrails.

5. **Handoffs over context bloat** — When context grows large, hand off to a fresh session rather than degrading quality. Fresh context beats exhausted context.

6. **Tests as the contract** — "Done" means tests pass. No subjective completion criteria. The code proves itself.

7. **Human remains in control** — Clarifying questions before implementation, PR approval, task prioritization stays with human. AI executes, human directs.

8. **Session summaries for coordination** — Detailed output enables asynchronous coordination between sessions. Each session leaves breadcrumbs for the next.

9. **Context window discipline** — No single task should exhaust the context window. If you're compacting, something is wrong. Best results come when <50% of context is used. Break big tasks into smaller ones.

10. **Routine tasks become skills** — Anything you do repeatedly should be codified as a skill or automation. The commands in this repo exist because the workflow is routine. Your project-specific routines deserve the same treatment.

---

## Setting Up a New Project

To enable the beads workflow in a new project:

1. **Copy the CLAUDE.md template:**
   ```bash
   cp ~/Code/claude-config/CLAUDE.template.md /path/to/your/project/CLAUDE.md
   ```

2. **Fill in project-specific sections:**
   - Project Summary
   - Development commands
   - Critical Rules
   - CLI Commands
   - Architecture
   - Key Design Decisions

3. **Initialize beads:**
   ```bash
   cd /path/to/your/project
   bd init
   ```

4. **Start using the workflow:**
   ```
   /orient
   /start-task <task-id>
   ```

The template includes the full Agent Workflow Skills documentation, so Claude will understand the beads workflow in any project that uses it.

---

## Commands Reference

> **Full documentation:** See [CLAUDE.template.md](./CLAUDE.template.md) for comprehensive command docs, ralph-loop best practices, and workflow examples.

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

### `/dispatch`

**Purpose:** Spawn parallel Claude Code workers for multiple beads tasks.

**What it does:**
1. Identifies tasks to dispatch (from args or `bd ready`)
2. Generates handoff context for each task
3. Shows summary and asks for confirmation (including skip-permissions option)
4. Runs `mp-spawn` for each task (spawns workers in iTerm2 tabs)
5. Provides guidance on attaching to workers

**Note:** Worktrees are created by `/start-task`, not by `mp-spawn` or `/dispatch`.

**Confirmation flow:**
- Confirms dispatch of N workers
- Asks whether to use `--skip-permissions` (recommended for ralph mode autonomous workers)

**Usage:**
```bash
# Auto-select 3 ready tasks (default)
/dispatch --count 3

# Specific tasks
/dispatch MoneyPrinter-ajq MoneyPrinter-4b3 MoneyPrinter-235

# With custom handoff context
/dispatch MoneyPrinter-ajq:"Use PriceCache pattern"

# Manual mode (no ralph-loop)
/dispatch MoneyPrinter-ajq --no-ralph
```

**After dispatch (with skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Paste the command (`Cmd+V`) and press Enter
3. Use `Cmd+1/2/3` to navigate between worker tabs

**After dispatch (without skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Answer the trust prompt for each worktree
3. Paste the command (`Cmd+V`) and press Enter
4. Use `Cmd+1/2/3` to navigate between worker tabs

**When to use:** From an orchestrator session to spawn parallel workers for independent tasks.

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
9. Optionally merges PR and cleans up worktree (using absolute paths)
10. Outputs a detailed **Session Summary**

**Example:**
```
/finish-task MoneyPrinter-46j.1
```

**Critical:** Tests must pass before the task can be finished. The command will stop if tests fail.

**Worktree Cleanup:** The command uses absolute paths to safely change to the main repo before removing the worktree, preventing "Path does not exist" errors.

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

## Bin Utilities Reference

Shell utilities for orchestrating parallel Claude workers.

### `mp-spawn`

**Purpose:** Spawn a Claude Code worker in a new iTerm2 tab.

**What it does:**
1. Opens a new iTerm2 tab via AppleScript
2. Starts Claude Code with `--chrome` enabled by default
3. Copies the `/start-task` command to your clipboard
4. You paste the command after the worker starts

**Note:** `mp-spawn` does NOT create worktrees. Worktree creation is handled entirely by `/start-task` for simplicity and to avoid duplication issues.

**Usage:**
```bash
mp-spawn <task-id> [options]

Options:
  --dir /path/to/project  Project directory (default: current directory)
  --handoff "text"        Handoff context from previous session
  --ralph                 Enable autonomous ralph-loop mode
  --max-iterations N      Max ralph iterations (default: 10)
  --skip-permissions      Skip all permission prompts (uses --dangerously-skip-permissions)

Note: --chrome is always enabled by default for all workers.
```

**Examples:**
```bash
# From within a project directory
mp-spawn MoneyPrinter-ajq

# With ralph-loop for autonomous implementation
mp-spawn MoneyPrinter-ajq --ralph

# With handoff context
mp-spawn MoneyPrinter-ajq --ralph --handoff "Use PriceCache pattern for OHLCV data"

# Fully autonomous workers (no permission prompts)
mp-spawn MoneyPrinter-ajq --ralph --skip-permissions

# Orchestrator passing explicit directory
mp-spawn MoneyPrinter-ajq --dir "$(pwd)" --ralph --skip-permissions
```

**After spawn (with --skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Paste the command (`Cmd+V`) — it's already on your clipboard
3. Press Enter — worker starts immediately without trust prompts

**After spawn (without --skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Answer the trust prompt for the project directory
3. Paste the command (`Cmd+V`) — it's already on your clipboard
4. Press Enter — `/start-task` will create the worktree and set up isolation

**iTerm2 Integration:**
- Uses AppleScript to create new iTerm2 tabs directly
- Each tab is named with the task short ID (e.g., "ajq")
- Switch between workers with `Cmd+1/2/3` or `Cmd+Shift+[/]`

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
   git clone https://github.com/josephneumann/claude-config.git ~/Code/claude-config
   ```

2. **Run the installer:**
   ```bash
   cd ~/Code/claude-config
   ./install.sh
   ```

3. **Source your shell config:**
   ```bash
   source ~/.zshrc
   ```

4. **Verify:**
   ```bash
   ls -la ~/.claude/commands  # Should show symlink
   ls -la ~/.claude/hooks     # Should show symlink
   which mp-spawn             # Should show path to bin/mp-spawn
   ```

The installer:
- Creates `~/.claude/` if needed
- Backs up existing directories (if any)
- Creates symlinks to the repo
- Adds `bin/` to PATH in `~/.zshrc`
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

These commands are designed for a specific workflow and require additional tools to be set up.

### Required

- **[beads](https://github.com/josephneumann/beads)** (`bd`) - Task management CLI
  - All commands use `bd` for task tracking, dependencies, and sync
  - Install beads and configure it for your project before using these commands
  - Run `bd init` in your project to set up beads

- **git** - With worktree support (standard in modern git)
  - `/start-task` creates isolated worktrees for each task
  - `/finish-task` handles commits, pushes, and worktree cleanup

- **gh** - [GitHub CLI](https://cli.github.com/)
  - Used by `/finish-task` to create pull requests
  - Install: `brew install gh` (macOS) or see [installation docs](https://github.com/cli/cli#installation)
  - Authenticate: `gh auth login`

- **iTerm2** - Terminal emulator for macOS (for `mp-spawn` worker management)
  - Used by `mp-spawn` to create worker tabs via AppleScript
  - Download: [iterm2.com](https://iterm2.com/)
  - Must grant Accessibility permissions for AppleScript automation

### Optional (for Ralph Loop workflow)

- **ralph-loop plugin** - Claude Code plugin for autonomous implementation loops
  - Required only if using `/start-task --ralph`
  - The plugin iterates until tests pass or max iterations reached
  - Install from the Claude Code plugin marketplace: `ralph-loop`
  - The `beads-ralph-stop.sh` hook works alongside this plugin

### Claude Code Setup

1. **Install Claude Code** - These are Claude Code slash commands, not standalone scripts
2. **Run the installer** - `./install.sh` creates symlinks so Claude Code finds the commands
3. **Verify** - In Claude Code, type `/orient` to test

### Without These Prerequisites

- **Without beads:** Commands will fail on `bd` calls. You'd need to remove/replace beads references.
- **Without gh:** `/finish-task` won't create PRs. You can create them manually.
- **Without ralph-loop plugin:** Don't use the `--ralph` flag. Standard workflow still works.

---

## License

MIT
