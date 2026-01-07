#!/bin/bash
# Beads-Ralph Stop Hook
# Outputs handoff context when ralph-loop hits max iterations
# Works alongside the ralph-loop plugin without modifying it

set -euo pipefail

BEADS_STATE=".claude/beads-ralph.local.md"
RALPH_STATE=".claude/ralph-loop.local.md"

# Only run if beads-ralph state exists
if [[ ! -f "$BEADS_STATE" ]]; then
  exit 0
fi

# Check if ralph-loop just stopped (state file was removed)
# This indicates loop ended - either success or max iterations
if [[ ! -f "$RALPH_STATE" ]]; then
  # Ralph loop has ended - output handoff context

  # Parse beads state
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$BEADS_STATE")
  TASK_ID=$(echo "$FRONTMATTER" | grep '^beads_task_id:' | sed 's/beads_task_id: *//' | tr -d '"')
  TASK_TITLE=$(echo "$FRONTMATTER" | grep '^task_title:' | sed 's/task_title: *//' | tr -d '"')

  # Check last assistant message for success promise
  HOOK_INPUT=$(cat)
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' 2>/dev/null || echo "")

  SUCCESS=false
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | \
      jq -r '.message.content | map(select(.type == "text")) | map(.text) | join("\n")' 2>/dev/null || echo "")
    if echo "$LAST_OUTPUT" | grep -q "<promise>ALL TESTS PASSING</promise>"; then
      SUCCESS=true
    fi
  fi

  if [[ "$SUCCESS" == "true" ]]; then
    echo ""
    echo "=============================================="
    echo "RALPH-LOOP COMPLETE: Tests passing!"
    echo "=============================================="
    echo ""
    echo "Task: $TASK_ID - $TASK_TITLE"
    echo ""
    echo "Next step: Run /finish-task $TASK_ID"
    echo "=============================================="
  else
    echo ""
    echo "=============================================="
    echo "AUTO-HANDOFF: Ralph loop stopped"
    echo "=============================================="
    echo ""
    echo "Task: $TASK_ID - $TASK_TITLE"
    echo "Status: Task remains in_progress (tests not yet passing)"
    echo ""
    echo "To continue in a new session:"
    echo ""
    echo "/start-task $TASK_ID --ralph --handoff \"Continued from ralph-loop. Check git log and test output.\""
    echo ""
    echo "=============================================="
  fi

  # Clean up beads state
  rm -f "$BEADS_STATE"
fi

# Allow exit (don't block)
exit 0
