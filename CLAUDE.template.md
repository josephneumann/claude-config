# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!--
  HOW TO USE THIS TEMPLATE:
  1. Copy this file to your project root as CLAUDE.md
  2. Fill in the [PLACEHOLDER] sections with project-specific info
  3. Keep the "Agent Workflow Skills" section as-is (or remove if not using beads)
  4. Delete this comment block
-->

## Project Summary

[PLACEHOLDER: 2-3 sentences describing your project. What does it do? What problem does it solve?]

See `docs/PROJECT_SPEC.md` for the complete specification and implementation plan.

## Development

```bash
[PLACEHOLDER: Your development commands]
# Examples:
# uv sync                    # Install dependencies
# uv run pytest              # Run tests
# pnpm install && pnpm dev   # Node.js project
# cargo build                # Rust project
```

## Critical Rules

[PLACEHOLDER: Project-specific rules that Claude must always follow]

<!-- Examples:
- **NEVER edit pyproject.toml directly** — Always use `uv add <package>`
- **Always run tests before committing** — `uv run pytest`
- **Follow conventional commits** — `feat:`, `fix:`, `docs:`, etc.
-->

## Commands

```bash
[PLACEHOLDER: Main CLI commands for your project]
# Examples:
# uv run python -m myapp serve     # Start server
# uv run python -m myapp migrate   # Run migrations
```

## Architecture

```
[PLACEHOLDER: Directory structure]
# Example:
# myapp/
# ├── cli.py          # CLI entry point
# ├── config.py       # Configuration
# ├── db/             # Database layer
# ├── api/            # API endpoints
# └── utils/          # Utilities
```

**Stack**: [PLACEHOLDER: Python 3.12+, FastAPI, SQLite, etc.]

## Key Design Decisions

[PLACEHOLDER: Important architectural decisions]

<!-- Examples:
- **Highly selective**: Quality over quantity in recommendations
- **Paper trade first**: All recommendations logged before real money
- **LLM suggestions require approval**: Human confirms before activation
-->

---

## Philosophy: Parallel Agentic Development

This project uses a specific approach to AI-assisted development:

1. **Parallel by default** — Multiple Claude sessions work simultaneously on independent tasks, each in isolated git worktrees.

2. **Orchestrator + Workers** — One session orients and identifies parallelizable work; worker sessions execute discrete tasks. The orchestrator sees the big picture, workers focus deeply.

3. **Task isolation** — Each task gets its own branch/worktree, preventing conflicts and enabling clean PRs.

4. **Bounded autonomy** — Claude works autonomously but within bounds: clear acceptance criteria, test-driven completion.

5. **Handoffs over context bloat** — When context grows large, hand off to a fresh session rather than degrading quality.

6. **Tests as the contract** — "Done" means tests pass. No subjective completion criteria.

7. **Human remains in control** — Clarifying questions before implementation, PR approval, task prioritization stays with human.

8. **Session summaries for coordination** — Detailed output enables asynchronous coordination between sessions.

9. **Context window discipline** — No single task should exhaust the context window. Break big tasks into smaller ones.

10. **Routine tasks become skills** — Anything you do repeatedly should be codified as a skill or automation.

---

## Agent Workflow Skills

This project uses custom Claude Code skills for multi-agent task management with beads (`bd`).

---

### `/orient` — Project Orientation

Builds project context and identifies parallelizable work. Use at session start.

1. Reads core docs (CLAUDE.md, AGENTS.md, PROJECT_SPEC.md)
2. Reviews beads task state (`bd list`, `bd ready`, dependencies)
3. Outputs orientation report with recommended parallel work streams

---

### `/dispatch` — Spawn Parallel Workers

Spawns multiple Claude Code workers for parallel task execution. Use from an orchestrator session.

**Usage:**
```bash
/dispatch --count 3                              # Auto-select 3 ready tasks
/dispatch MoneyPrinter-ajq MoneyPrinter-4b3      # Specific tasks
/dispatch MoneyPrinter-ajq:"Use PriceCache"      # With custom handoff context
```

**What it does:**
1. Identifies tasks (from args or `bd ready`)
2. Generates handoff context for each task
3. Shows summary and asks for confirmation (including skip-permissions option)
4. Runs `mp-spawn` for each task (spawns workers in iTerm2 tabs)
5. Provides guidance on attaching to workers

**Note:** Worktrees are created by `/start-task`, not by `mp-spawn` or `/dispatch`.

**Confirmation flow:**
- Confirms dispatch of N workers
- Asks whether to use `--skip-permissions` (recommended for autonomous workers)

**After dispatch (with skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Paste the command (`Cmd+V`) and press Enter
3. Use `Cmd+1/2/3` to navigate between worker tabs

**After dispatch (without skip-permissions):**
1. Switch to iTerm2 (`Cmd+Tab`)
2. Answer the trust prompt for each worktree
3. Paste the command (`Cmd+V`) and press Enter
4. Use `Cmd+1/2/3` to navigate between worker tabs

---

### `/init-prd [path]` — Initialize Project from PRD

Sets up a new project and bootstraps beads tasks from a PROJECT_SPEC.md document.

**Usage:**
```bash
/init-prd                    # Full setup + parse PROJECT_SPEC.md
/init-prd docs/SPEC.md       # Custom PRD path
/init-prd --dry-run          # Preview tasks without creating
/init-prd --append           # Add to existing beads tasks
/init-prd --skip-setup       # Skip CLAUDE.md and bd init checks
```

**What it does:**
1. Checks for CLAUDE.md (offers to copy template if missing)
2. Checks beads initialization (offers to run `bd init` if needed)
3. Finds and reads the PRD document
4. Asks clarifying questions to resolve ambiguities in the PRD
5. Extracts epics, features, tasks, and research items
6. Infers dependencies from document structure and language
7. Shows proposed tasks for user approval
8. Creates tasks via beads CLI (`bd create`)
9. Establishes dependency relationships (`bd dep add`)

**New project workflow:**
1. Create PROJECT_SPEC.md with features/tasks/research items
2. Run `/init-prd` — sets up CLAUDE.md, bd init, parses PRD, creates tasks
3. Run `/orient` to see ready work
4. Run `/dispatch` to start parallel workers

---

### `/start-task <task-id> [flags]` — Start Working on a Task

Sets up isolated environment for a beads task.

**Setup:**
1. Validates task, creates git worktree, sets `BEADS_NO_DAEMON=1`
2. Claims task (`bd update --status in_progress`)
3. Asks clarifying questions before implementation
4. Waits for "Ready to begin?" confirmation

**Flags:**
| Flag | Description |
|------|-------------|
| `--handoff "<text>"` | Context from previous session |

**Examples:**
```bash
/start-task 46j.1                                       # Standard start
/start-task 46j.1 --handoff "Use PriceCache for OHLCV"  # With handoff context
```

---

### `/finish-task <task-id>` — Complete a Task

Closes out a task with full verification. **Work is NOT complete until git push succeeds.**

1. Verifies task state and worktree location
2. Runs tests — **must pass to continue**
3. Reviews/updates documentation if needed
4. Creates follow-up issues for any remaining work (`bd create`)
5. Commits with conventional format + `Closes: <task-id>`
6. Syncs beads (`bd sync`), pushes to remote
7. Closes task (`bd close <task-id>`)
8. Creates PR (`gh pr create`)
9. Offers to merge PR (squash) and cleanup worktree (using absolute paths)
10. Outputs detailed session summary for orchestrating agents
11. Persists summary to `session_summaries/<taskid>_YYMMDD-HHMMSS.txt`

**Critical:** Tests must pass before closing. Never close a task with failing tests.

**Worktree Cleanup:** Uses absolute paths to safely change to main repo before removing worktree, preventing "Path does not exist" errors.

**Persistent Output:** Summary is written to `session_summaries/` in project root (gitignored). Orchestrators can read completed work context directly from disk.

---

### `/handoff-task <task-id>` — Generate Handoff Context

Generates session-specific context to pass to another agent session.

1. Validates task exists
2. Reads task scope (title, dependencies, priority)
3. Summarizes decisions, gotchas, and recommendations from current session
4. Outputs copy-pasteable `/start-task` command with `--handoff` context

**Output format:**
```
==============================================
HANDOFF: <task-id>
==============================================
Task: <title>
Priority: <priority>

To start this task in a new session, run:
/start-task <task-id> --handoff "<context>"
==============================================
```

**Use case:** When an orchestrating session identifies work for a parallel worker, or when handing off incomplete work to a new session.

---

### `/summarize-session <task-id>` — Session Summary (Read-only)

Generates detailed summary without committing, pushing, or closing. Useful for progress check-ins.

1. Gathers context (task state, git status, recent commits)
2. Identifies files created/modified
3. Checks test status
4. Outputs structured summary for orchestrating agents
5. Persists summary to `session_summaries/<taskid>_YYMMDD-HHMMSS.txt`

**Output includes:** Task overview, implementation summary, files changed, tests, git activity, dependencies unblocked, architectural notes, handoff context.

**Persistent Output:** Summary is written to `session_summaries/` in project root (gitignored). Orchestrators can read completed work context directly from disk.

---

### Workflow Examples

**Parallel workflow:**
```
Session A (Orchestrator):   /orient → identifies 46j.1, 46j.2, 46j.3
Session B (Worker):         /start-task 46j.1 → implement → /finish-task 46j.1
Session C (Worker):         /start-task 46j.2 → implement → /finish-task 46j.2
```

**Orchestrator dispatch workflow:**
```
Session A (Orchestrator):
  /orient                           # Identify ready work
  /dispatch --count 3               # Spawn 3 workers
  → Workers spawn in iTerm2 tabs
  → Switch to iTerm2, paste commands, answer trust prompts
  → Use Cmd+1/2/3 to switch between worker tabs
```

**Handoff workflow:**
```
Session B (context full):
  /handoff-task 46j.1               # Generate handoff context
  → Outputs: /start-task 46j.1 --handoff "..."

Session C (fresh session):
  /start-task 46j.1 --handoff "..." # Continue with context
  → Continues work with previous context
```

---

## Shell Utilities

These shell utilities support the multi-agent workflow. They are installed via the `claude-config` repo's `install.sh`.

### `mp-spawn` — Spawn a Worker

Spawns a Claude Code worker in a new iTerm2 tab (via AppleScript).

**Note:** `mp-spawn` does NOT create worktrees. It launches Claude in the main project directory, and `/start-task` handles worktree creation for task isolation.

```bash
mp-spawn <task-id> [options]

Options:
  --dir /path/to/project  Project directory (default: current directory)
  --handoff "text"        Handoff context from previous session
  --skip-permissions      Skip all permission prompts (uses --dangerously-skip-permissions)

Note: --chrome is always enabled by default for all workers.
```

**Examples:**
```bash
mp-spawn MoneyPrinter-ajq
mp-spawn MoneyPrinter-ajq --dir "$(pwd)" --handoff "Use PriceCache pattern"
mp-spawn MoneyPrinter-ajq --skip-permissions  # Fully autonomous
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

### iTerm2 Integration

- Uses AppleScript to create new iTerm2 tabs directly
- Copies `/start-task` command to clipboard (paste after worker starts)
- Switch between workers with `Cmd+1/2/3` or `Cmd+Shift+[/]`
- Each tab is named with the task short ID (e.g., "ajq")
