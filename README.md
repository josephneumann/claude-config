# Claude Config

Custom skills, agents, and hooks for Claude Code, designed for the **beads** task management workflow.

## Quick Install

```bash
git clone https://github.com/josephneumann/claude-config.git ~/Code/claude-config
cd ~/Code/claude-config
./install.sh
```

This creates symlinks from `~/.claude/` to this repo:
- `CLAUDE.md` - Global workflow guidance (read by all projects)
- `skills/` - Slash commands for the full workflow lifecycle
- `hooks/` - Event hooks for Claude Code
- `agents/` - Specialized agent definitions for research, review, and workflow
- `docs/` - Global learnings and solutions (shared across projects)

Also adds `bin/` utilities to your PATH.

---

## The Workflow

```
brainstorm → plan → deepen-plan → orient → dispatch → start-task → finish-task → compound
└─────────── Plan ───────────┘   └────────────── Execute ──────────────────────┘   └ Learn ┘
```

**Plan phase**: Start with `/brainstorm` to explore ideas through interactive Q&A. Feed the result into `/plan`, which researches the codebase, analyzes feasibility with parallel agents, and decomposes into beads tasks with dependencies. Use `/deepen-plan` to enhance any section with targeted research.

**Execute phase**: Run `/orient` to survey the project and identify parallel work streams. Use `/dispatch` to spawn multiple Claude Code workers in terminal tabs/windows — each gets a task via the automated handoff queue. Workers run `/start-task` (creates a git worktree, claims the task, gathers context) and `/finish-task` (tests, commit, PR, code review, session summary) autonomously. Use `/handoff-task` when context grows too large.

**Learn phase**: After solving problems, run `/compound` to capture the solution in `docs/solutions/` for future sessions. `/multi-review` provides parallel specialized code review. The orchestrator runs `/reconcile-summary` to sync worker output with the task board.

---

## Philosophy: Parallel Agentic Development

1. **Parallel by default** — Multiple Claude sessions work simultaneously in isolated git worktrees. No waiting; use `/dispatch` to spawn workers.

2. **Orchestrator + Workers** — One session orients (`/orient`) and coordinates; workers execute discrete tasks (`/start-task`) and report back with session summaries. The orchestrator sees the big picture, workers focus deeply.

3. **Task-sized work** — Break work into chunks that fit comfortably in context. Big enough to be a meaningful atomic change, small enough to complete without exhausting the context window. If you're compacting mid-task, the task was too big.

4. **Bounded autonomy** — Clarify requirements and define acceptance criteria before coding. Then execute autonomously within those bounds. Autonomy with guardrails.

5. **Tests as the contract** — "Done" means tests pass. No subjective completion criteria. The code proves itself.

6. **Human in the loop** — Humans approve PRs, prioritize tasks, and make architectural decisions. AI executes, human directs.

7. **Handoffs over context bloat** — When context grows large, hand off to a fresh session with `/handoff-task` rather than degrading quality. Fresh context beats exhausted context.

8. **Session summaries** — Every completed task outputs a detailed summary enabling asynchronous coordination. Each session leaves breadcrumbs for the next.

9. **Compound your learnings** — After solving problems, document solutions with `/compound` in `docs/solutions/`. Knowledge compounds across sessions and projects.

10. **Codify the routine** — Repeated patterns become skills. If you do something twice, automate it. The skills in this repo exist because the workflow is routine.

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

Workflow guidance (skills, philosophy) comes automatically from the global config.

---

## Skills Reference

All workflow capabilities are implemented as skills in `skills/`. Full documentation lives in each `SKILL.md` file.

| Skill | Phase | Purpose |
|-------|-------|---------|
| `/brainstorm` | Plan | Explore what to build via interactive Q&A |
| `/plan` | Plan | Research, design, decompose into beads tasks |
| `/deepen-plan` | Plan | Enhance plan with parallel research |
| `/orient` | Execute | Survey project, identify parallel work streams |
| `/dispatch` | Execute | Spawn parallel workers in terminal tabs/windows |
| `/start-task <id>` | Execute | Claim task, create worktree, gather context |
| `/finish-task <id>` | Execute | Tests, PR, code review, cleanup, close |
| `/handoff-task <id>` | Execute | Pass work to fresh session |
| `/summarize-session <id>` | Execute | Progress checkpoint (read-only) |
| `/reconcile-summary` | Execute | Sync worker output with task board |
| `/compound` | Learn | Capture learnings in `docs/solutions/` |
| `/multi-review` | Learn | Parallel code review with specialized agents |
| `/last30days` | Research | Ad-hoc research across recent activity and changes |

<details>
<summary><strong>/brainstorm</strong> — Collaborative idea exploration</summary>

Interactive Q&A dialogue to move from a vague idea to a clear concept. Writes output to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`. Suggests `/plan` as next step.

</details>

<details>
<summary><strong>/plan</strong> — Research, design, and task decomposition</summary>

Replaces `/init-prd`. Checks for brainstorm files, runs parallel research agents (repo-research-analyst, learnings-researcher, spec-flow-analyzer, and conditionally best-practices-researcher and framework-docs-researcher). Writes plan to `docs/plans/`, then decomposes into beads tasks with dependencies via `bd create` and `bd dep add`.

</details>

<details>
<summary><strong>/deepen-plan</strong> — Enhance existing plans</summary>

Finds the most recent plan in `docs/plans/`, identifies sections needing more detail, runs parallel research agents per-section, updates the plan document and beads tasks.

</details>

<details>
<summary><strong>/orient</strong> — Project orientation and parallel work identification</summary>

Discovers project structure, reads CLAUDE.md/README/PROJECT_SPEC, analyzes beads task state, checks git health, and outputs a structured orientation report with recommended parallel work streams. Always offers `/dispatch` as the primary next action.

</details>

<details>
<summary><strong>/dispatch</strong> — Spawn parallel workers</summary>

Identifies ready tasks from `bd ready`, generates handoff context, writes to `docs/pending_handoffs/`, and spawns workers via `mp-spawn` in terminal tabs (iTerm2) or windows (Ghostty). Workers automatically receive task context via the SessionStart hook.

**Automated handoff flow:**
1. `/dispatch` writes handoff context to `docs/pending_handoffs/<task-id>.txt`
2. `/dispatch` appends task ID to `docs/pending_handoffs/.queue`
3. `mp-spawn` creates signal file `docs/pending_handoffs/.spawn-<timestamp>-<pid>`
4. SessionStart hook claims signal (atomic delete) — no signal = manual session, exit silently
5. Hook pops task from `.queue` (mkdir-based locking) and displays handoff
6. Claude sees the instruction to execute `/start-task`

This signal + queue mechanism ensures each worker gets exactly one task (FIFO order), manual sessions never grab queued tasks, and interrupted dispatch leaves no stale state.

All handoff files are stored in `docs/pending_handoffs/`.

**Usage:**
```bash
/dispatch --count 3                    # Auto-select 3 ready tasks
/dispatch task-id1 task-id2 task-id3   # Specific tasks
/dispatch task-id:"Use PriceCache"     # With custom handoff context
```

Use `Cmd+1/2/3` (iTerm2 tabs) or `Cmd+\`` (Ghostty windows) to navigate between workers.

</details>

<details>
<summary><strong>/start-task</strong> — Begin work on a task</summary>

1. Validates the task exists (`bd show`)
2. Claims the task (`bd update --status in_progress`)
3. Creates a **git worktree** for isolation
4. Disables beads daemon (`BEADS_NO_DAEMON=1`)
5. Gathers project context (CLAUDE.md, README, etc.)
6. Optionally runs research agents for complex tasks
7. Defines acceptance criteria with the user
8. Confirms before implementation begins

Supports `--handoff "<context>"` for session continuations from `/handoff-task`.

**Examples:**
```bash
/start-task MoneyPrinter-46j.1
/start-task MoneyPrinter-46j.1 --handoff "Use 3% tolerance for price matching"
```

After starting, you'll be in a separate worktree — all changes are isolated from the main branch.

</details>

<details>
<summary><strong>/finish-task</strong> — Complete a task with full quality checks</summary>

1. Verifies current state (correct worktree, task in-progress)
2. Runs quality gates (tests must pass)
3. Reviews and updates documentation
4. Creates follow-up issues for discovered work
5. Commits all changes with proper format
6. Syncs beads and pushes to remote
7. Closes the task (`bd close`)
8. Creates a pull request
9. Runs `/multi-review` with auto-fix (high-confidence issues ≥80% fixed automatically, max 3 cycles)
10. Optionally merges PR and cleans up worktree (using absolute paths)
11. Outputs a detailed **Session Summary** to `docs/session_summaries/`

**Critical:** Tests must pass before the task can be finished. The command will stop if tests fail.

</details>

<details>
<summary><strong>/handoff-task</strong> — Generate handoff context</summary>

Gathers session-specific context (decisions, gotchas, approach) and outputs a copy-pasteable `/start-task` command with handoff context. Use when context grows too large or passing work between sessions.

**Output example:**
```
/start-task MoneyPrinter-46j.1 --handoff "Used pytest fixtures for DB setup. Watch for timezone issues in date parsing."
```

</details>

<details>
<summary><strong>/summarize-session</strong> — Read-only progress summary</summary>

Generates a structured session summary without committing, pushing, or closing the task. Use for mid-session checkpoints or before handoffs.

**Difference from `/finish-task`:** This command is read-only. It doesn't commit, push, close the task, or make any changes.

</details>

<details>
<summary><strong>/reconcile-summary</strong> — Sync worker output with task board</summary>

Auto-discovers unreconciled summaries in `docs/session_summaries/`, analyzes spec divergences, updates affected beads tasks, creates new tasks for discovered work, and closes obsoleted tasks. Moves processed summaries to `docs/session_summaries/reconciled/`.

</details>

<details>
<summary><strong>/compound</strong> — Capture learnings</summary>

Triggers on "that worked", "fixed it", or explicit invocation. Routes to project-specific (`docs/solutions/`) or global (`~/.claude/docs/solutions/`) storage. Creates structured solution documents with YAML frontmatter for searchability.

</details>

<details>
<summary><strong>/multi-review</strong> — Parallel specialized code review</summary>

Identifies changed files, selects 3-5 appropriate review agents based on change types, launches them in parallel, aggregates findings by severity, and offers auto-fix for high-confidence (≥80%) issues. Maximum 3 review cycles.

</details>

---

## Agents Reference

Agent definitions live in `agents/` and are used by skills for specialized tasks.

### Research Agents

Used by `/orient` and `/start-task` to gather context before implementation.

| Agent | Purpose | Used By |
|-------|---------|---------|
| `repo-research-analyst` | Map architecture, conventions | `/orient` Phase 1.5 |
| `git-history-analyzer` | Historical context, contributors | `/orient` Phase 1.5 |
| `framework-docs-researcher` | Library docs, deprecation checks | `/start-task` Step 6.5 |
| `learnings-researcher` | Search docs/solutions/ | `/start-task` Step 6.5 |
| `best-practices-researcher` | External best practices | `/start-task` Step 6.5 |

### Review Agents

Used by `/multi-review` for specialized code review.

| Agent | Focus |
|-------|-------|
| `code-simplicity-reviewer` | YAGNI, minimize complexity |
| `security-sentinel` | OWASP Top 10, vulnerabilities |
| `performance-oracle` | N+1 queries, memory, caching |
| `pattern-recognition-specialist` | Anti-patterns, conventions |
| `architecture-strategist` | SOLID, design alignment |
| `agent-native-reviewer` | Action/context parity for agents |
| `data-integrity-guardian` | Migration safety, ACID, GDPR/CCPA |
| `data-migration-expert` | Validates mappings against production |

### Workflow Agents

| Agent | Purpose | Used By |
|-------|---------|---------|
| `spec-flow-analyzer` | Analyze specs for dependencies, gaps, feasibility | `/plan` Phase 2 |

---

## Session Summaries & Handoffs (Persistent I/O)

Workers use two directories for persistent input and output:

- **`docs/pending_handoffs/`** — Input: Handoff context written by `/dispatch`, read by SessionStart hook
- **`docs/session_summaries/`** — Output: Session summaries written by `/finish-task`

### Storage Location

Both directories are stored in `docs/`:

```
project-root/
├── docs/
│   ├── pending_handoffs/           # Worker inputs (created by /dispatch)
│   │   ├── MoneyPrinter-ajq.txt    # Consumed by SessionStart hook
│   │   └── processed/              # Moved here after consumption
│   ├── session_summaries/          # Worker outputs (created by /finish-task)
│   │   ├── MoneyPrinter-ajq_260117-143052.txt
│   │   ├── MoneyPrinter-4b3_260117-151230.txt
│   │   └── reconciled/             # Moved here after reconciliation
│   └── solutions/                  # Learnings from /compound
├── .gitignore                      # Contains both directories
└── ...
```

### Filename Format

```
<taskid>_YYMMDD-HHMMSS.txt
```

Example: `MoneyPrinter-ajq_260117-143052.txt` (task ajq, Jan 17 2026, 2:30:52 PM)

### Orchestrator Usage

Orchestrators can discover and read completed work:

```bash
# List recent summaries (sorted by modification time)
ls -lt docs/session_summaries/

# Read a specific summary
cat docs/session_summaries/MoneyPrinter-ajq_260117-143052.txt

# Find summaries for a specific task
ls docs/session_summaries/*ajq*

# Find summaries from today
ls docs/session_summaries/*$(date +%y%m%d)*
```

### Automatic Gitignore

The skills automatically add `docs/session_summaries/` and `docs/pending_handoffs/` to `.gitignore` if not present. This ensures:
- Handoffs and summaries don't clutter git history
- Each machine maintains its own local archive
- No conflicts between parallel workers

---

## Bin Utilities Reference

Shell utilities for orchestrating parallel Claude workers.

### `mp-spawn`

**Purpose:** Spawn a Claude Code worker in a new iTerm2 tab or Ghostty window.

**What it does:**
1. Detects terminal emulator (iTerm2 or Ghostty)
2. Opens a new tab (iTerm2) or window (Ghostty)
3. Creates signal file `docs/pending_handoffs/.spawn-<timestamp>-<pid>`
4. Starts Claude Code (with `--chrome` enabled by default)
5. SessionStart hook claims signal and loads handoff context from queue

**Note:** `mp-spawn` does NOT create worktrees. Worktree creation is handled entirely by `/start-task` for simplicity and to avoid duplication issues.

**Automated handoff mechanism:**
- `/dispatch` writes handoff files AND appends task IDs to `docs/pending_handoffs/.queue`
- `mp-spawn` creates signal file, then spawns Claude
- SessionStart hook claims signal (atomic delete) — no signal = manual session
- Hook pops task from `.queue` (mkdir-based locking) and displays handoff
- Claude sees the handoff + instruction to execute `/start-task`

This signal + queue approach ensures:
- Reliable task assignment even if workers spawn simultaneously
- Manual sessions never grab queued tasks
- Interrupted dispatch leaves no stale state

**Usage:**
```bash
mp-spawn <task-id> [options]

Options:
  --dir /path/to/project  Project directory (default: current directory)
  --terminal <terminal>   Force terminal: "iterm2" or "ghostty"
  --skip-permissions      Skip all permission prompts (uses --dangerously-skip-permissions)
```

**Examples:**
```bash
# From within a project directory
mp-spawn MoneyPrinter-ajq

# Fully autonomous workers (no permission prompts)
mp-spawn MoneyPrinter-ajq --skip-permissions

# Orchestrator passing explicit directory
mp-spawn MoneyPrinter-ajq --dir "$(pwd)" --skip-permissions

# Force Ghostty even when running from iTerm2
mp-spawn MoneyPrinter-ajq --terminal ghostty
```

**Terminal support:**
- **iTerm2**: Creates new tabs via AppleScript. Switch with `Cmd+1/2/3` or `Cmd+Shift+[/]`
- **Ghostty**: Creates new windows via `open -na`. Switch with `Cmd+\``
- Each tab/window is named with the task short ID (e.g., "ajq")
- Auto-detects terminal, or override with `--terminal ghostty` or `CLAUDE_SPAWN_TERMINAL=ghostty`

---

## Workflow Examples

### 1. Planning a New Project

```bash
# Explore the idea
/brainstorm "real-time price alerts for crypto"

# Research and decompose into tasks
/plan

# Optionally add more detail
/deepen-plan

# Orient and dispatch workers
/orient
/dispatch
```

### 2. Single-Session Workflow

```bash
/orient
/start-task beads-abc123
# Do the work...
/finish-task beads-abc123
```

### 3. Multi-Session Parallel Workflow

```bash
# Orchestrator session
/orient
/dispatch --count 3
# Workers auto-spawn in terminal tabs/windows
# Wait for workers to complete, then:
/reconcile-summary
```

### 4. Handoff Workflow

```bash
# Session 1 (hitting context limits)
/start-task beads-abc123
# Work for a while...
/handoff-task beads-abc123
# Outputs: /start-task beads-abc123 --handoff "..."

# Session 2 (fresh context)
/start-task beads-abc123 --handoff "Used pytest fixtures for DB setup..."
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
   ls -la ~/.claude/hooks     # Should show symlink
   ls -la ~/.claude/agents    # Should show symlink
   ls -la ~/.claude/skills    # Should show symlink
   ls -la ~/.claude/docs      # Should show symlink
   which mp-spawn             # Should show path to bin/mp-spawn
   ```

The installer:
- Creates `~/.claude/` if needed
- Backs up existing directories (if any)
- Creates symlinks to the repo
- Removes legacy `commands/` symlink if present
- Adds `bin/` to PATH in `~/.zshrc`
- Is idempotent (safe to run multiple times)

---

## Adding New Skills and Hooks

### Adding a Skill

1. Create a new directory in `skills/`:
   ```bash
   mkdir ~/Code/claude-config/skills/my-skill
   ```

2. Create `SKILL.md` with frontmatter:
   ```markdown
   ---
   name: my-skill
   description: "This skill should be used when..."
   allowed-tools: Read, Bash, Glob, Grep
   ---

   # My Skill: $ARGUMENTS

   Instructions for Claude...
   ```

3. Commit and push — available as `/my-skill`

**Frontmatter options:**
- `name` (required): Skill name, used as the slash command
- `description` (required): When to invoke this skill
- `allowed-tools`: Comma-separated list of tools the skill can use
- `disable-model-invocation: true`: Prevent auto-invocation (for heavyweight workflows)

### Adding a Hook

1. Create a new script in `hooks/`:
   ```bash
   vim ~/Code/claude-config/hooks/my-hook.sh
   chmod +x ~/Code/claude-config/hooks/my-hook.sh
   ```

2. Commit and push

---

## Prerequisites

### Required

- **[beads](https://github.com/josephneumann/beads)** (`bd`) - Task management CLI
  - All skills use `bd` for task tracking, dependencies, and sync
  - Run `bd init` in your project to set up beads

- **git** - With worktree support (standard in modern git)
  - `/start-task` creates isolated worktrees for each task
  - `/finish-task` handles commits, pushes, and worktree cleanup

- **gh** - [GitHub CLI](https://cli.github.com/)
  - Used by `/finish-task` to create pull requests
  - Install: `brew install gh` (macOS) or see [installation docs](https://github.com/cli/cli#installation)
  - Authenticate: `gh auth login`

- **iTerm2 or Ghostty** - Terminal emulator for macOS (for `mp-spawn`)
  - **iTerm2**: Creates worker tabs via AppleScript. Download: [iterm2.com](https://iterm2.com/). Must grant Accessibility permissions for AppleScript automation
  - **Ghostty**: Creates worker windows via `open -na`. Download: [ghostty.org](https://ghostty.org/)
  - `mp-spawn` auto-detects the active terminal, or set `CLAUDE_SPAWN_TERMINAL=iterm2|ghostty`

### Claude Code Setup

1. **Install Claude Code**
2. **Run the installer** - `./install.sh`
3. **Verify** - In Claude Code, type `/orient` to test

### Without These Prerequisites

- **Without beads:** Skills will fail on `bd` calls. You'd need to remove/replace beads references.
- **Without gh:** `/finish-task` won't create PRs. You can create them manually.

---

## License

MIT
