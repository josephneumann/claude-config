---
description: Initialize a project with beads tasks from a PROJECT_SPEC.md or PRD document
allowed-tools: Read, Bash, Glob, Grep, Write, AskUserQuestion, TodoWrite
---

# Initialize Project from PRD: $ARGUMENTS

You are initializing a project with beads tasks from a PRD document. Follow this process precisely.

## Phase 0: Parse Arguments

Parse `$ARGUMENTS` to extract:
- `path`: Path to PRD document (optional - will search if not provided)
- `dry_run`: boolean (true if `--dry-run` present)
- `append_mode`: boolean (true if `--append` present)
- `skip_setup`: boolean (true if `--skip-setup` present)

Examples:
- `/init-prd` → search for PRD, full setup
- `/init-prd docs/SPEC.md` → use specific path
- `/init-prd --dry-run` → preview only
- `/init-prd --append` → add to existing tasks
- `/init-prd --skip-setup` → skip CLAUDE.md and bd init checks

## Phase 1: Project Setup (unless `--skip-setup`)

### 1.1 Check for CLAUDE.md

```bash
ls -la CLAUDE.md 2>/dev/null || echo "NOT_FOUND"
```

If CLAUDE.md is missing:
1. Inform the user: "No CLAUDE.md found in project root."
2. Use AskUserQuestion to ask:
   - "Copy CLAUDE.md template from ~/Code/claude-config/CLAUDE.template.md?"
   - Options: "Yes, copy template" / "No, continue without"
3. If yes: `cp ~/Code/claude-config/CLAUDE.template.md ./CLAUDE.md`
4. Remind user to fill in project-specific sections later

### 1.2 Check Beads Initialization

```bash
bd status 2>/dev/null || echo "NOT_INITIALIZED"
```

If beads is not initialized:
1. Use AskUserQuestion to ask:
   - "Beads is not initialized. Run `bd init`?"
   - Options: "Yes, initialize beads" / "No, continue without"
2. If yes: `bd init`

### 1.3 Check for Existing Tasks

```bash
bd list 2>/dev/null | head -20
```

If tasks exist and `--append` is NOT set:
1. Warn the user: "Existing beads tasks found."
2. Use AskUserQuestion:
   - "How should I proceed?"
   - Options: "Add to existing tasks (--append behavior)" / "Cancel and review first"
3. If cancel: Stop and let user review

## Phase 2: Find PRD Document

If a path was provided in arguments, use it directly.

Otherwise, search in this order:
```bash
# Check each location
ls PROJECT_SPEC.md 2>/dev/null
ls docs/PROJECT_SPEC.md 2>/dev/null
ls PRD.md 2>/dev/null
ls docs/PRD.md 2>/dev/null
```

If no PRD found:
```
===============================================
ERROR: No PRD document found
===============================================

Searched for:
  - PROJECT_SPEC.md
  - docs/PROJECT_SPEC.md
  - PRD.md
  - docs/PRD.md

To get started:
1. Create a PROJECT_SPEC.md in your project root
2. Document features, tasks, and acceptance criteria
3. Run /init-prd again

Example structure:
## Features
### Feature 1: User Authentication
- Task 1: Set up database schema
- Task 2: Implement login endpoint
- Research: Evaluate OAuth providers
===============================================
```

## Phase 3: PRD Analysis & Clarification

### 3.1 Read and Understand the PRD

Read the entire PRD document:
```bash
# Read the PRD (use the path found/provided)
```

Build a mental model:
- What is this project trying to accomplish?
- What are the major feature areas?
- What are the concrete deliverables?
- What technical decisions are specified vs. left open?

### 3.2 Interview User for Clarification (CRITICAL)

**Before proposing any tasks**, use AskUserQuestion to resolve ambiguities. Look for:

1. **Ambiguous requirements**
   - "What does 'fast' mean here - specific latency target?"
   - "When you say 'secure', which specific threats should we consider?"

2. **Missing acceptance criteria**
   - "How will we know X is complete?"
   - "What's the expected output format for Y?"

3. **Unclear scope**
   - "Should feature A include behavior B, or is that separate?"
   - "Does 'user management' include admin users?"

4. **Priority conflicts**
   - "Both A and B are marked critical - which should be tackled first?"
   - "Are these truly P1 or should some be P2?"

5. **Technical decisions left open**
   - "PRD mentions caching - Redis or in-memory?"
   - "Database: SQLite for dev, Postgres for prod?"

**Goal**: Every task should have clear, actionable requirements. Don't guess - ask.

Ask multiple questions if needed. It's better to clarify now than to create ambiguous tasks.

### 3.3 Extract Task Structure

Use these as **guidelines, not strict rules** - adapt to the PRD's actual structure:

| Common Pattern | Likely Mapping | Consider Also |
|----------------|----------------|---------------|
| `## Major Heading` | Epic | Could be single feature if small |
| `### Subsection` | Feature | Could be epic if many sub-items |
| Numbered list items | Tasks | Could be features if complex |
| "Research:", "TBD", questions | Research task | Could be blocking dependency |
| Requirements table | Acceptance criteria | Could be task list |
| `- [ ]` checkboxes | Individual tasks | Could be acceptance criteria |
| Prose paragraphs | Context/description | May contain implicit tasks |

**Key principle**: Extract what the user *intends* to accomplish, not what the formatting suggests.

### 3.4 Infer Dependencies

Look for:
1. **Explicit**: "Requires X", "After Y", "Depends on Z", "Blocked by"
2. **Structural**: Child tasks logically depend on parent setup
3. **Semantic**: Research → Implementation, Config → Feature, Schema → Code

### 3.5 Assign Types and Priorities

**Task types:**
- `epic` - Major feature area or milestone
- `feature` - Distinct deliverable within an area
- `task` - Concrete implementation step
- `research` - Investigation, TBD, or exploration

**Priorities (infer from PRD language):**
- `P1` - Critical, must-have, core functionality
- `P2` - Important, should-have
- `P3` - Nice-to-have, can defer

### 3.6 Validate Task Sizing

**Philosophy: Task-sized work** — Each task should fit comfortably in a single Claude session's context window.

For each proposed task, verify it meets these criteria:

**Right-sized tasks:**
- Can be completed in one session without handoff
- Touch a focused set of files (typically <10)
- Have a clear, testable outcome
- Represent a meaningful atomic change (worth a PR)

**Signs a task is too large — break it down:**
- "Implement entire X system" → Split into: schema, core logic, API, tests
- "Refactor Y" without boundaries → Define specific refactoring goals
- Multiple independent features bundled → One task per feature
- Vague scope → Clarify or add research task first

**Signs a task is too small — consider combining:**
- "Add field X to model" + "Add field Y to model" → Single schema task
- Trivial changes that don't warrant a full PR
- Multiple tightly-coupled changes that must ship together

**When in doubt:**
- Err on the side of smaller tasks — easier to combine than split
- Add research tasks to clarify scope before implementation
- Ask the user: "Task X seems large. Should I break it into subtasks?"

## Phase 4: Task Proposal

Display the proposed tasks in a structured format:

```
===============================================
PROPOSED TASKS FROM: <prd_filename>
===============================================

OVERVIEW
--------
Project: <inferred project name>
Total tasks: N (Epics: X, Features: Y, Tasks: Z, Research: R)

EPIC 1: <title> [P1]
--------------------
  1. [feature P1] <title>
     Description: <desc>
     Acceptance: <criteria>

     1.1 [task P1] <title>
         Description: <desc>
         Blocked by: 1

     1.2 [task P2] <title>
         Description: <desc>
         Blocked by: 1.1

  2. [research P1] <title>
     Description: <desc>
     Question: <what needs to be answered>

EPIC 2: <title> [P2]
--------------------
  ...

STANDALONE TASKS (no epic)
--------------------------
  S1. [task P2] <title>
      Description: <desc>

===============================================
```

If `--dry-run` is set:
```
===============================================
DRY RUN COMPLETE
===============================================
The above tasks would be created.
Run without --dry-run to create them.
===============================================
```
Then STOP - do not proceed to Phase 5.

## Phase 5: User Approval

Use AskUserQuestion:
- "Create these N tasks?"
- Options:
  - "Yes, create all tasks"
  - "Modify first - show me editable markdown"
  - "Cancel"

If "Modify first":
1. Output the tasks in beads-compatible markdown format
2. Tell user: "Edit this markdown and paste it back, or save to a file and provide the path"
3. Wait for user to provide modified version
4. Re-parse and show updated proposal
5. Ask for approval again

## Phase 6: Task Creation

### 6.1 Generate Bulk Markdown File

Create a temporary file with all tasks in beads format:

```bash
cat > /tmp/init-prd-tasks.md << 'EOF'
# Tasks from PRD

## Epic: <title>
type: epic
priority: P1
description: |
  <description>

### Feature: <title>
type: feature
priority: P1
blocked_by: <parent-id>
description: |
  <description>
acceptance:
  - <criterion 1>
  - <criterion 2>

#### Task: <title>
type: task
priority: P1
blocked_by: <parent-id>
description: |
  <description>

...
EOF
```

### 6.2 Create Tasks

```bash
bd create -f /tmp/init-prd-tasks.md
```

If beads doesn't support bulk file creation, create tasks individually:
```bash
bd create "<title>" --type <type> --priority <priority> --description "<desc>"
```

### 6.3 Establish Dependencies

For each dependency relationship:
```bash
bd dep add <child-id> <parent-id>
```

### 6.4 Sync

```bash
bd sync
```

## Phase 7: Summary Report

```
===============================================
TASK INITIALIZATION COMPLETE
===============================================

Created: N tasks
  - Epics: X
  - Features: Y
  - Tasks: Z
  - Research: R

Ready to work (no blockers): M tasks
  - <task-id>: <title>
  - <task-id>: <title>
  - ...

Blocked tasks: B tasks
  - <task-id>: <title> (waiting on: <blocker>)
  - ...

DEPENDENCY GRAPH
----------------
<visual tree showing epic → feature → task relationships>

NEXT STEPS
----------
  /orient          # See full project state and recommendations
  /dispatch        # Start parallel workers on ready tasks
  /start-task <id> # Begin work on a specific task

===============================================
```

## Error Handling

### No PRD Found
Already covered in Phase 2 - show helpful error with search paths.

### Empty PRD
```
===============================================
WARNING: PRD appears to be empty or has no extractable tasks
===============================================

The document was found but no features, tasks, or work items
could be identified.

Would you like to:
1. Create a placeholder epic to get started
2. Cancel and add content to the PRD first
===============================================
```

### Very Large PRD (50+ tasks)

If more than 50 tasks would be created:
1. Show first 20 tasks in proposal
2. Ask: "This PRD would create N tasks. Show all, or create in batches?"
3. Options: "Show all tasks" / "Create first batch (20)" / "Cancel"

### Beads Command Failures

If any `bd` command fails:
1. Show the error
2. Ask user how to proceed
3. Options: "Retry" / "Skip this step" / "Cancel"
