---
description: Orient to a project - review structure, docs, and beads tasks to identify parallelizable work
allowed-tools: Read, Bash, Glob, Grep, Task
---

# Project Orientation

You are an orchestrating agent orienting to this project. Your goal is to build comprehensive context and identify parallelizable work streams.

**IMPORTANT**: Use extended thinking (ultrathink) throughout this process. Take your time to deeply analyze the project state.

## Phase 1: Project Discovery

### 1.1 Identify Project Root and Type

```bash
pwd
ls -la
git remote -v 2>/dev/null || echo "Not a git repo"
```

Determine:
- Project name
- Primary language/framework
- Monorepo vs single project

### 1.2 Read Core Documentation

Read these files IN ORDER (skip if not found):

1. **CLAUDE.md** - AI assistant guidelines (HIGHEST PRIORITY)
2. **AGENTS.md** - Multi-agent workflow documentation
3. **PROJECT_SPEC.md** - Project specification and requirements
4. **README.md** - Project overview and setup

For each file found, extract:
- Project purpose and goals
- Key architectural decisions
- Development workflow and commands
- Patterns and conventions to follow

### 1.3 Understand Project Structure

```bash
# Get directory structure (2 levels deep)
find . -type d -maxdepth 2 -not -path '*/\.*' -not -path './node_modules/*' -not -path './.venv/*' -not -path './venv/*' | head -50

# Identify key source directories
ls -la src/ app/ lib/ moneyprinter/ fastapi_backend/ nextjs-frontend/ 2>/dev/null | head -30
```

Map out:
- Source code locations
- Test locations
- Configuration files
- Build/deployment setup

## Phase 2: Task State Analysis

### 2.1 Beads Overview

```bash
bd status 2>/dev/null || echo "Beads not configured"
bd version 2>/dev/null
```

### 2.2 Recently Completed Work

```bash
# Recent git activity
git log --oneline -15

# Recently closed tasks
bd list --all 2>/dev/null | grep -i closed | head -10
```

Understand:
- What was just completed
- Patterns in recent work
- Momentum and direction

### 2.3 Current Task State

```bash
# All open tasks by priority
bd list 2>/dev/null

# Ready work (no blockers)
bd ready 2>/dev/null
```

### 2.4 Dependency Analysis

For each ready task, check what it blocks:

```bash
bd show <task-id>
```

Identify:
- Critical path tasks (block the most downstream work)
- Independent tasks (can run in parallel)
- Research vs implementation tasks

## Phase 3: Codebase Health Check

### 3.1 Test Status

```bash
# Quick test run to verify health
uv run pytest --tb=no -q 2>&1 | tail -10  # Python
pnpm test 2>&1 | tail -10                  # Node
```

### 3.2 Git State

```bash
git status
git branch -a | head -20
git worktree list
git stash list
```

Check for:
- Uncommitted changes
- Active worktrees (parallel work in progress)
- Stashed work that needs attention

## Phase 4: Synthesis & Recommendations

After gathering all information, provide a structured orientation report:

```
===============================================
PROJECT ORIENTATION REPORT
===============================================

PROJECT IDENTITY
----------------
Name: <project name>
Purpose: <1-2 sentence description>
Stack: <key technologies>
Repo: <git remote URL>

DOCUMENTATION STATUS
--------------------
<List docs found and key takeaways from each>

CURRENT STATE
-------------
Git branch: <current branch>
Working tree: <clean/dirty>
Active worktrees: <count and purpose>
Test health: <passing/failing count>

TASK OVERVIEW
-------------
Total open: <count>
Ready (no blockers): <count>
In progress: <count>
Recently completed: <list last 3-5>

CRITICAL PATH ANALYSIS
----------------------
<Identify which tasks block the most downstream work>

RECOMMENDED PARALLEL WORK STREAMS
---------------------------------
The following tasks can be executed simultaneously in separate Claude sessions:

Stream 1: <task-id> - <title>
  Priority: <P1/P2/P3>
  Type: <feature/task/research>
  Rationale: <why this should be worked on>
  Blocks: <what this unblocks when done>
  Start command: /start-task <task-id>

Stream 2: <task-id> - <title>
  Priority: <P1/P2/P3>
  Type: <feature/task/research>
  Rationale: <why this should be worked on>
  Blocks: <what this unblocks when done>
  Start command: /start-task <task-id>

Stream 3: <task-id> - <title>
  Priority: <P1/P2/P3>
  Type: <feature/task/research>
  Rationale: <why this should be worked on>
  Blocks: <what this unblocks when done>
  Start command: /start-task <task-id>

BLOCKERS & RISKS
----------------
<Any issues that could impede progress>
- <blocker 1>
- <blocker 2>

CONTEXT FOR NEW SESSIONS
------------------------
Key things any agent working on this project should know:
- <important pattern or convention>
- <gotcha or common mistake>
- <architectural constraint>

===============================================
END ORIENTATION REPORT
===============================================
```

## Phase 5: Ready for Action

After presenting the orientation report, summarize the actionable next steps:

"Orientation complete. To start parallel work, open new Claude sessions and run:

```
/start-task <task-id-1>   # <brief description>
/start-task <task-id-2>   # <brief description>
/start-task <task-id-3>   # <brief description>
```

Each session will:
1. Create a git worktree for isolation
2. Disable beads daemon mode
3. Claim the task
4. Begin implementation

When a task is complete, run `/finish-task <task-id>` to close out properly.

---

What would you like to do in THIS session?

1. **Deep dive** - Explore a specific task or area in more detail
2. **Start working** - Pick one of the recommended tasks with `/start-task <id>`
3. **Review** - Look at specific code, tests, or documentation
4. **Coordinate** - Help manage the parallel work as tasks complete"

Await user direction before taking action.
