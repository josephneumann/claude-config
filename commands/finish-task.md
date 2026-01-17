---
description: Complete a beads task - run checks, commit, push, close issue, cleanup worktree, generate session summary
allowed-tools: Read, Bash, Glob, Grep, Edit, Write
---

# Finish Beads Task: $ARGUMENTS

You are completing work on beads task `$ARGUMENTS`. Follow this checklist precisely. **Work is NOT complete until git push succeeds.**

## 1. Verify Current State

```bash
bd show $ARGUMENTS
git status
git log --oneline -5
pwd
```

Confirm:
- Task is `in_progress`
- You're in the correct worktree
- All changes are visible

## 2. Run Quality Gates

Run appropriate tests for the project:

```bash
# Python projects
uv run pytest

# Node projects
pnpm test

# Or project-specific
make run-checks
```

**If tests fail, STOP.** Fix the issues before proceeding. Do NOT close a task with failing tests.

## 3. Review and Update Documentation

Before committing, review whether documentation needs updates:

1. **README.md** - Does it reflect new features, commands, or setup steps?
2. **CLAUDE.md** - Any new patterns, commands, or guidelines for AI assistants?
3. **PROJECT_SPEC.md** - Implementation status, new decisions, or architecture changes?
4. **Inline docs** - Are new functions/classes documented?

Update any documentation that is now stale or incomplete due to your changes. Keep updates minimal and focused - only document what changed.

## 4. File Follow-up Issues

If there's remaining work, TODOs, or improvements discovered during implementation:

```bash
bd create "Follow-up: <description>"
```

Do this BEFORE closing the main task so nothing is lost.

## 5. Commit All Changes

```bash
git add -A
git status
```

Create a well-formatted commit:

```bash
git commit -m "$(cat <<'EOF'
feat(<scope>): <description>

<detailed explanation if needed>

Closes: $ARGUMENTS

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## 6. Sync Beads (Pre-Push)

Sync beads before pushing to pull any remote changes:

```bash
bd sync
```

## 7. Push to Remote

```bash
git push -u origin $(git branch --show-current)
```

**If push fails, resolve and retry.** Do NOT proceed until push succeeds.

## 8. Close the Task and Final Sync

```bash
bd close $ARGUMENTS --reason="Completed. See branch $(git branch --show-current)."
bd sync
```

**CRITICAL**: The final `bd sync` ensures the task closure is pushed to the remote. Without this, other agents won't see the task is complete.

## 9. Verify Everything is Synced

```bash
git status
bd show $ARGUMENTS
bd sync  # Run again to confirm no pending changes
```

Confirm:
- Git shows "Your branch is up to date with origin"
- Task status is `closed`
- `bd sync` shows "no changes" or "already up to date"

## 10. Create Pull Request

Create a PR for the completed work:

```bash
gh pr create --title "feat(<scope>): <description>" --body "$(cat <<'EOF'
## Summary

<2-3 sentences describing what this PR accomplishes>

## Changes

- <bullet list of key changes>

## Task

Closes beads task `$ARGUMENTS`

## Test Plan

- [x] All tests passing (<count> tests)
- [ ] Manual verification (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

After the PR is created, **ask the user**:

"PR created: <URL>. Would you like me to merge it and clean up the worktree?"

If user approves, proceed to step 11. If user declines, leave the PR open for manual review and skip to step 12.

## 11. Merge PR and Cleanup Worktree

**IMPORTANT**: Must use absolute paths and cd to main repo BEFORE removing worktree.

```bash
# Store paths using absolute references BEFORE any directory changes
WORKTREE_PATH=$(pwd)
BRANCH_NAME=$(git branch --show-current)
MAIN_REPO=$(git worktree list | grep '\[main\]' | awk '{print $1}')
PROJECT_NAME=$(basename "$MAIN_REPO")

echo "Worktree: $WORKTREE_PATH"
echo "Main repo: $MAIN_REPO"
echo "Branch: $BRANCH_NAME"
```

**CRITICAL**: Change to main repo FIRST, then remove worktree:

```bash
# FIRST: Change to main repo (must succeed before removing worktree)
cd "$MAIN_REPO"

# Verify we're in main repo
pwd
git branch --show-current  # Should show 'main'

# NOW safe to remove the worktree
git worktree remove "$WORKTREE_PATH" --force

# Merge the PR (use --repo flag to be explicit)
gh pr merge --squash --delete-branch

# Pull the merged changes
git pull

# Verify cleanup
git worktree list
```

If `gh pr merge` fails with "already merged", just delete the branch manually:
```bash
git branch -d "$BRANCH_NAME" 2>/dev/null || true
git push origin --delete "$BRANCH_NAME" 2>/dev/null || true
```

**If you get "Path does not exist" errors**: Your shell's CWD was deleted. Run:
```bash
cd "$MAIN_REPO"  # or: cd /Users/jneumann/Code/<project>
```

## 12. Session Summary

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
Status: Closed
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
Commits: <count>
PR: <URL or "Not created">
Merged to: <target branch>

BEADS STATUS
------------
Task closed: Yes
Reason: <close reason>
Synced to remote: Yes

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

## 13. Persist Summary to Disk

Write the summary to a file so orchestrating agents can read it directly from disk.

```bash
# Get project root (handles worktrees correctly - use main repo if in worktree)
PROJECT_ROOT=$(git worktree list | grep '\[main\]' | awk '{print $1}')
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT=$(git rev-parse --show-toplevel)
fi

# Create directory if needed
mkdir -p "$PROJECT_ROOT/session_summaries"

# Add to .gitignore if not present
if ! grep -q "^session_summaries/$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
  echo "session_summaries/" >> "$PROJECT_ROOT/.gitignore"
fi

# Generate filename with timestamp
TIMESTAMP=$(date +%y%m%d-%H%M%S)
SUMMARY_FILE="$PROJECT_ROOT/session_summaries/$ARGUMENTS_${TIMESTAMP}.txt"
```

Write the summary content using a heredoc:

```bash
cat > "$SUMMARY_FILE" <<'SUMMARY_EOF'
<paste the full session summary content here>
SUMMARY_EOF

echo "Summary written to: $SUMMARY_FILE"
```

**Important:** The summary file allows orchestrators to asynchronously review completed work without needing the worker session to remain active.
