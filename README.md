# Claude Config

Custom commands and hooks for Claude Code, designed for the **beads** task management workflow.

## Quick Install

```bash
git clone https://github.com/josephneumann/claude-config.git ~/Code/claude-config
cd ~/Code/claude-config
./install.sh
```

This creates symlinks from `~/.claude/` to this repo:
- `CLAUDE.md` - Global workflow guidance (read by all projects)
- `commands/` - Slash commands for the beads workflow
- `hooks/` - Event hooks for Claude Code
- `agents/` - Specialized agent definitions for research and review
- `skills/` - Auto-invocable skills (compound learning, multi-review)
- `docs/` - Global learnings and solutions (shared across projects)

Also adds `bin/` utilities to your PATH.

---

## Philosophy: Parallel Agentic Development

This setup enables a specific approach to AI-assisted development:

1. **Parallel by default** — Multiple Claude sessions work simultaneously in isolated git worktrees. No waiting; use `/dispatch` to spawn workers.

2. **Orchestrator + Workers** — One session orients (`/orient`) and coordinates; workers execute discrete tasks (`/start-task`) and report back with session summaries. The orchestrator sees the big picture, workers focus deeply.

3. **Task-sized work** — Break work into chunks that fit comfortably in context. Big enough to be a meaningful atomic change, small enough to complete without exhausting the context window. If you're compacting mid-task, the task was too big.

4. **Bounded autonomy** — Clarify requirements and define acceptance criteria before coding. Then execute autonomously within those bounds. Autonomy with guardrails.

5. **Tests as the contract** — "Done" means tests pass. No subjective completion criteria. The code proves itself.

6. **Human in the loop** — Humans approve PRs, prioritize tasks, and make architectural decisions. AI executes, human directs.

7. **Handoffs over context bloat** — When context grows large, hand off to a fresh session with `/handoff-task` rather than degrading quality. Fresh context beats exhausted context.

8. **Session summaries** — Every completed task outputs a detailed summary enabling asynchronous coordination. Each session leaves breadcrumbs for the next.

9. **Compound your learnings** — After solving problems, document solutions with `/compound` in `docs/solutions/`. Knowledge compounds across sessions and projects.

10. **Codify the routine** — Repeated patterns become skills and commands. If you do something twice, automate it. The commands in this repo exist because the workflow is routine.

> **Compound Engineering**: Principles 9 and 10 work together — capture *knowledge* (learnings) and *process* (skills) so each session builds on the last. This is how AI-assisted development improves over time.

---

## Setting Up a New Project

Workflow docs are loaded globally from `~/.claude/CLAUDE.md`. Projects only need their own `CLAUDE.md` for project-specific details.

1. **Create project CLAUDE.md** with just:
   - Project summary (what it does)
   - Development commands (`uv run pytest`, `pnpm dev`, etc.)
   - Critical rules (project-specific constraints)
   - Architecture overview

2. **Initialize beads:**
   ```bash
   cd /path/to/your/project
   bd init
   ```

3. **Start using the workflow:**
   ```
   /orient
   /start-task <task-id>
   ```

Workflow guidance (commands, skills, philosophy) comes automatically from the global config.

---

## Commands Reference

> **Full documentation:** Command and skill definitions in `commands/` and `skills/` are the canonical source. See [CLAUDE.md](./CLAUDE.md) for the global workflow reference.

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
- Asks whether to use `--skip-permissions` (recommended for autonomous workers)

**Usage:**
```bash
# Auto-select 3 ready tasks (default)
/dispatch --count 3

# Specific tasks
/dispatch MoneyPrinter-ajq MoneyPrinter-4b3 MoneyPrinter-235

# With custom handoff context
/dispatch MoneyPrinter-ajq:"Use PriceCache pattern"
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

### `/init-prd [path]`

**Purpose:** Initialize a project with beads tasks from a PROJECT_SPEC.md or PRD document.

**What it does:**
1. Sets up project if needed (CLAUDE.md, bd init)
2. Finds and reads PROJECT_SPEC.md (or specified path)
3. Asks clarifying questions to resolve ambiguities
4. Extracts epics, features, tasks, and research items
5. Infers dependencies from document structure
6. Shows proposed tasks for approval
7. Creates tasks via beads CLI

**Options:**
- `--dry-run` — Preview tasks without creating
- `--append` — Add to existing beads state
- `--skip-setup` — Skip CLAUDE.md and bd init checks

**Examples:**
```bash
/init-prd                    # Full setup + parse PROJECT_SPEC.md
/init-prd docs/SPEC.md       # Custom path
/init-prd --dry-run          # Preview only
/init-prd --skip-setup       # Skip project setup, just parse PRD
```

**When to use:** At the start of a new project to bootstrap tasks from a PRD or specification document.

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
- `--handoff "<context>"` - Inline context from a previous session

**Examples:**
```bash
# Standard start
/start-task MoneyPrinter-46j.1

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
9. Runs automated code review (`/multi-review`) and auto-fixes issues
10. Optionally merges PR and cleans up worktree (using absolute paths)
11. Outputs a detailed **Session Summary**

**Code Review:** After PR creation, runs `/multi-review` which launches parallel specialized reviewers. High-confidence issues (≥80%) are automatically fixed, committed, and pushed. Maximum 3 review cycles before asking user for guidance.

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

## Session Summaries (Persistent Output)

Both `/summarize-session` and `/finish-task` write their session summaries to disk, enabling orchestrators to read completed work context asynchronously.

### Storage Location

Summaries are stored in the project root:

```
project-root/
├── session_summaries/          # Created automatically, gitignored
│   ├── MoneyPrinter-ajq_260117-143052.txt
│   ├── MoneyPrinter-4b3_260117-151230.txt
│   └── ...
├── .gitignore                  # Contains session_summaries/
└── ...
```

### Filename Format

```
<taskid>_YYMMDD-HHMMSS.txt
```

- `taskid`: The beads task ID (e.g., `MoneyPrinter-ajq`)
- `YYMMDD`: Date in year-month-day format
- `HHMMSS`: Time in hour-minute-second format

Example: `MoneyPrinter-ajq_260117-143052.txt` (task ajq, Jan 17 2026, 2:30:52 PM)

### Orchestrator Usage

Orchestrators can discover and read completed work:

```bash
# List recent summaries (sorted by modification time)
ls -lt session_summaries/

# Read a specific summary
cat session_summaries/MoneyPrinter-ajq_260117-143052.txt

# Find summaries for a specific task
ls session_summaries/*ajq*

# Find summaries from today
ls session_summaries/*$(date +%y%m%d)*
```

### Automatic Gitignore

The commands automatically add `session_summaries/` to `.gitignore` if not present. This ensures:
- Summaries don't clutter git history
- Each machine maintains its own local summary archive
- No conflicts between parallel workers writing summaries

---

## Skills Reference

Skills are auto-invocable capabilities that Claude can use proactively based on context.

### `/compound`

**Purpose:** Capture learnings after solving a problem, creating institutional knowledge.

**Triggers:**
- Explicit invocation with `/compound`
- Phrases like "that worked", "fixed it", "figured it out"
- After successful debugging sessions

**What it does:**
1. Asks clarifying questions about the problem and solution
2. Searches for existing similar solutions in `docs/solutions/`
3. Creates a documented solution with proper schema
4. Offers to add reminders to CLAUDE.md or create follow-up tasks

**Output:** Creates a markdown file in `docs/solutions/[category]/` with:
- YAML frontmatter (module, problem_type, root_cause, severity)
- Symptom description
- Investigation notes
- Root cause analysis
- Solution details
- Prevention recommendations

---

### `/multi-review`

**Purpose:** Comprehensive code review using multiple specialized agents in parallel.

**Triggers:**
- Explicit invocation with `/multi-review`
- Requests for "thorough review" or "full code review"

**What it does:**
1. Identifies changed files from git
2. Selects appropriate review agents based on change types
3. Launches 3-5 parallel review agents
4. Aggregates findings by severity (Critical > Important > Suggestion)
5. Filters to high-confidence (≥80%) issues
6. Offers auto-fix for fixable issues

**Review Agents:**
| Agent | Focus | When Used |
|-------|-------|-----------|
| code-simplicity-reviewer | YAGNI, complexity | Always |
| pattern-recognition-specialist | Anti-patterns, conventions | Always |
| security-sentinel | OWASP Top 10, auth, secrets | Auth/security changes |
| performance-oracle | N+1 queries, caching, memory | Data operations |
| architecture-strategist | SOLID, design patterns | Structural changes |

---

## Agents Reference

Agent definitions live in `agents/` and are used by skills and commands.

### Research Agents

Used by `/orient` and `/start-task` to gather context before implementation.

| Agent | Purpose | Used By |
|-------|---------|---------|
| `repo-research-analyst` | Map architecture, conventions | `/orient` Phase 1.5 |
| `git-history-analyzer` | Historical context, contributors | `/orient` Phase 1.5 |
| `framework-docs-researcher` | Library docs, deprecation checks | `/start-task` Step 5.5 |
| `learnings-researcher` | Search docs/solutions/ | `/start-task` Step 5.5 |
| `best-practices-researcher` | External best practices | `/start-task` Step 5.5 |

### Review Agents

Used by `/multi-review` for specialized code review.

| Agent | Focus |
|-------|-------|
| `code-simplicity-reviewer` | YAGNI, minimize complexity |
| `security-sentinel` | OWASP Top 10, vulnerabilities |
| `performance-oracle` | N+1 queries, memory, caching |
| `pattern-recognition-specialist` | Anti-patterns, conventions |
| `architecture-strategist` | SOLID, design alignment |

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
  --skip-permissions      Skip all permission prompts (uses --dangerously-skip-permissions)

Note: --chrome is always enabled by default for all workers.
```

**Examples:**
```bash
# From within a project directory
mp-spawn MoneyPrinter-ajq

# With handoff context
mp-spawn MoneyPrinter-ajq --handoff "Use PriceCache pattern for OHLCV data"

# Fully autonomous workers (no permission prompts)
mp-spawn MoneyPrinter-ajq --skip-permissions

# Orchestrator passing explicit directory
mp-spawn MoneyPrinter-ajq --dir "$(pwd)" --skip-permissions
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

### 3. Handoff Workflow

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
   ls -la ~/.claude/agents    # Should show symlink
   ls -la ~/.claude/skills    # Should show symlink
   which mp-spawn             # Should show path to bin/mp-spawn
   ```

The installer:
- Creates `~/.claude/` if needed
- Backs up existing directories (if any)
- Creates symlinks to the repo
- Adds `bin/` to PATH in `~/.zshrc`
- Is idempotent (safe to run multiple times)

---

## Adding New Commands, Skills, or Hooks

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

3. Commit and push — available immediately as `/my-new-command`

### Adding a Skill

Skills support auto-invocation based on context (commands require explicit `/invoke`).

1. Create a new directory in `skills/`:
   ```bash
   mkdir ~/Code/claude-config/skills/my-skill
   vim ~/Code/claude-config/skills/my-skill/SKILL.md
   ```

2. Use the SKILL.md format:
   ```markdown
   ---
   name: my-skill
   description: "This skill should be used when..."
   ---

   # My Skill

   Instructions for Claude...
   ```

3. Commit and push — available as `/my-skill` and auto-invoked when description matches

### Adding a Hook

1. Create a new script in `hooks/`:
   ```bash
   vim ~/Code/claude-config/hooks/my-hook.sh
   chmod +x ~/Code/claude-config/hooks/my-hook.sh
   ```

2. Commit and push

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

### Claude Code Setup

1. **Install Claude Code** - These are Claude Code slash commands, not standalone scripts
2. **Run the installer** - `./install.sh` creates symlinks so Claude Code finds the commands
3. **Verify** - In Claude Code, type `/orient` to test

### Without These Prerequisites

- **Without beads:** Commands will fail on `bd` calls. You'd need to remove/replace beads references.
- **Without gh:** `/finish-task` won't create PRs. You can create them manually.

---

## License

MIT
