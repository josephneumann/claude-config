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

4. **Bounded autonomy** — Claude can work autonomously (ralph mode) but within bounds: clear acceptance criteria, test-driven completion, iteration limits.

5. **Handoffs over context bloat** — When context grows large, hand off to a fresh session rather than degrading quality.

6. **Tests as the contract** — "Done" means tests pass. No subjective completion criteria.

7. **Human remains in control** — Clarifying questions before implementation, PR approval, task prioritization stays with human.

8. **Session summaries for coordination** — Detailed output enables asynchronous coordination between sessions.

9. **Context window discipline** — No single task should exhaust the context window. Break big tasks into smaller ones.

10. **Routine tasks become skills** — Anything you do repeatedly should be codified as a skill or automation.

---

## Agent Workflow Skills

This project uses custom Claude Code skills for multi-agent task management with beads (`bd`). Tasks can run in **manual mode** (interactive) or **ralph mode** (autonomous iteration until tests pass).

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
/dispatch MoneyPrinter-ajq --no-ralph            # Manual mode (no ralph-loop)
```

**What it does:**
1. Identifies tasks (from args or `bd ready`)
2. Generates handoff context for each task
3. Shows summary and asks for confirmation
4. Runs `mp-spawn` for each task (creates worktrees, spawns workers in iTerm2 tabs)
5. Provides guidance on attaching to workers

**After dispatch:**
```bash
mp-attach   # Attach to worker session (Cmd+1/2/3 to switch tabs)
mp-list     # List active workers
mp-kill ajq # Kill a worker by short ID
```

---

### `/start-task <task-id> [flags]` — Start Working on a Task

Sets up isolated environment for a beads task. Two modes available:

| Mode | Command | Behavior |
|------|---------|----------|
| **Manual** | `/start-task <id>` | Interactive implementation with human guidance |
| **Ralph** | `/start-task <id> --ralph` | Autonomous loop until tests pass |

**Setup (both modes):**
1. Validates task, creates git worktree, sets `BEADS_NO_DAEMON=1`
2. Claims task (`bd update --status in_progress`)
3. Asks clarifying questions before implementation
4. Waits for "Ready to begin?" confirmation

**Flags:**
| Flag | Description |
|------|-------------|
| `--handoff "<text>"` | Context from previous session |
| `--ralph` | Enable autonomous ralph-loop mode |
| `--max-iterations N` | Ralph iteration limit (default: 10) |

**Examples:**
```bash
/start-task 46j.1                                       # Manual mode
/start-task 46j.1 --handoff "Use PriceCache for OHLCV"  # Manual + handoff context
/start-task 46j.1 --ralph                               # Ralph mode (10 iterations max)
/start-task 46j.1 --ralph --max-iterations 50           # Ralph mode (50 iterations)
/start-task 46j.1 --ralph --handoff "Use 3% tolerance"  # Ralph + handoff context
```

---

### Ralph-Loop Mode (Autonomous Implementation)

When `--ralph` is used, after setup and Q&A confirmation:

1. **Loop activates** — Claude implements iteratively, running tests frequently
2. **Success** — When all tests pass, outputs `<promise>ALL TESTS PASSING</promise>`
3. **Exit** — Loop ends, prompts "Run `/finish-task <id>`"
4. **Max iterations** — If limit reached, outputs handoff command for new session

**Best Practices for Ralph Mode:**

| Do | Don't |
|----|-------|
| Use for well-defined implementation tasks | Use for research or exploration |
| Ensure task has clear acceptance criteria | Use for tasks requiring design decisions |
| Start with existing test patterns to follow | Use for greenfield without test examples |
| Set realistic `--max-iterations` (10-30) | Set unlimited iterations |
| Answer clarifying questions thoroughly | Rush through the Q&A step |

**Good ralph candidates:**
- Adding a new module following existing patterns
- Implementing a feature with clear spec
- Bug fixes with reproducible test cases
- Database schema additions with defined fields

**Poor ralph candidates:**
- Research tasks (no clear "done" state)
- UI/UX work (subjective success criteria)
- Architecture decisions (need human judgment)
- Tasks requiring external API exploration

**Completion signal:**
```
<promise>ALL TESTS PASSING</promise>
```
Only output when tests show 0 failures. Never output false promises to escape the loop.

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
9. Offers to merge PR (squash) and cleanup worktree
10. Outputs detailed session summary for orchestrating agents

**Critical:** Tests must pass before closing. Never close a task with failing tests.

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

**Output includes:** Task overview, implementation summary, files changed, tests, git activity, dependencies unblocked, architectural notes, handoff context.

---

### Workflow Examples

**Manual parallel workflow:**
```
Session A (Orchestrator):   /orient → identifies 46j.1, 46j.2, 46j.3
Session B (Worker):         /start-task 46j.1 → implement → /finish-task 46j.1
Session C (Worker):         /start-task 46j.2 → implement → /finish-task 46j.2
```

**Ralph autonomous workflow:**
```
Session B (Worker):
  /start-task 46j.1 --ralph
  → Setup completes, Q&A answered
  → "Ready to begin?" confirmed
  → Ralph loop runs autonomously
  → Tests pass → "Run /finish-task 46j.1"
  /finish-task 46j.1
```

**Ralph with handoff (max iterations reached):**
```
Session B:
  /start-task 46j.1 --ralph --max-iterations 20
  → Loop hits 20 iterations without tests passing
  → Outputs: /start-task 46j.1 --ralph --handoff "Continued from ralph-loop..."

Session C (new session):
  /start-task 46j.1 --ralph --handoff "Continued from ralph-loop..."
  → Continues work with previous context
```

**Orchestrator dispatch workflow:**
```
Session A (Orchestrator):
  /orient                           # Identify ready work
  /dispatch --count 3 --ralph       # Spawn 3 workers
  → Workers spawn in iTerm2 tabs
  → Orchestrator continues other work

  mp-attach                         # Check on workers
  → Cmd+1/2/3 to switch between worker tabs
```

---

## Shell Utilities

These shell utilities support the multi-agent workflow. They are installed via the `claude-config` repo's `install.sh`.

### `mp-spawn` — Spawn a Worker

Spawns a Claude Code worker in a new iTerm2 tab (via AppleScript).

```bash
mp-spawn <task-id> [options]

Options:
  --dir /path/to/project  Project directory (default: current directory)
  --handoff "text"        Handoff context from previous session
  --ralph                 Enable autonomous ralph-loop mode
  --max-iterations N      Max ralph iterations (default: 10)
```

**Examples:**
```bash
mp-spawn MoneyPrinter-ajq --ralph
mp-spawn MoneyPrinter-ajq --dir "$(pwd)" --handoff "Use PriceCache pattern"
```

### iTerm2 Integration

- Uses AppleScript to create new iTerm2 tabs directly
- Works from within Claude Code (non-interactive terminal)
- Switch between workers with `Cmd+1/2/3` or `Cmd+Shift+[/]`
- Each tab is named with the task short ID (e.g., "ajq")
