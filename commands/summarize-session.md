---
description: Generate a detailed session summary for orchestrating agents (standalone, no git/close operations)
allowed-tools: Read, Bash, Glob, Grep
---

# Summarize Session: $ARGUMENTS

Generate a comprehensive session summary for task `$ARGUMENTS`. This is a standalone command that ONLY generates the summary - it does NOT commit, push, close the task, or make any changes.

## 1. Gather Context

```bash
bd show $ARGUMENTS
git status
git log --oneline -10
git diff --stat HEAD~5 2>/dev/null || git diff --stat
pwd
```

## 2. Identify Changed Files

```bash
# Files changed in recent commits
git diff --name-only HEAD~5 2>/dev/null || git diff --name-only

# New files created
git diff --name-only --diff-filter=A HEAD~5 2>/dev/null

# Files modified
git diff --name-only --diff-filter=M HEAD~5 2>/dev/null
```

Read key files to understand what was implemented.

## 3. Check Test Status

```bash
# Get test counts
uv run pytest --collect-only -q 2>/dev/null | tail -5
# Or
pnpm test 2>/dev/null | tail -10
```

## 4. Check Unblocked Tasks

```bash
bd dep tree $ARGUMENTS 2>/dev/null || echo "No dependency info"
```

## 5. Generate Session Summary

**IMPORTANT**: Output a detailed session summary for orchestrating agents. This summary will be consumed by a coordinating agent to track progress across multiple parallel work sessions. Be verbose and thorough.

Use this exact format:

```
===============================================
SESSION SUMMARY: <Task Title>
===============================================

TASK OVERVIEW
-------------
ID: $ARGUMENTS
Title: <title from bd show>
Status: <current status>
Priority: <P1/P2/P3 from bd show>
Type: <feature/task/bug from bd show>

INTENT & SCOPE
--------------
What this task set out to accomplish:
<2-3 sentences explaining the goal of this task in plain language. What problem does it solve? Why was it needed?>

IMPLEMENTATION SUMMARY
----------------------
<Narrative description of what was built. Write 3-5 sentences explaining the approach taken, key design decisions, and how the pieces fit together. An orchestrating agent should be able to understand the work without reading the code.>

FILES CREATED
-------------
<For each new file, include path and brief description>

1. <path/to/file.py>
   Purpose: <what this file does>
   Key components: <main classes/functions>
   Lines: <approximate line count>

2. <path/to/file.py>
   ...

FILES MODIFIED
--------------
<For each modified file, explain what changed and why>

1. <path/to/file.py>
   Changes: <what was added/changed>
   Reason: <why this change was needed>

2. <path/to/file.py>
   ...

TESTS
-----
New tests added: <count>
Total tests now passing: <count>
Test file(s): <path(s)>

Key test coverage:
- <what scenarios are tested>
- <what edge cases are covered>

DOCUMENTATION UPDATED
---------------------
<List each doc file updated with a brief note on what changed, or "None required">

GIT ACTIVITY
------------
Branch: <branch-name>
Commits: <count in this session>
PR: <URL or "Not created">
Merged to: <target branch or "Not merged">

BEADS STATUS
------------
Task closed: <Yes/No>
Reason: <close reason or "Still in progress">
Synced to remote: <Yes/No>

FOLLOW-UP ISSUES CREATED
------------------------
<List any new beads issues created during this session, or "None">

DEPENDENCIES UNBLOCKED
----------------------
The following tasks were blocked by this task and can now proceed:
<List each task ID and title, or "None">

ARCHITECTURAL NOTES
-------------------
<Any important technical decisions, patterns established, or constraints discovered that future work should be aware of. This helps maintain consistency across parallel agent sessions.>

HANDOFF CONTEXT
---------------
<What should the next agent or session know? Include:
- Any gotchas or things that didn't work as expected
- Assumptions made that might need revisiting
- Suggested next steps if continuing related work
- Dependencies on external systems or APIs
- Performance considerations if any>

===============================================
END SESSION SUMMARY
===============================================
```

This format ensures orchestrating agents have full context to coordinate parallel work and make informed decisions about task assignment.
