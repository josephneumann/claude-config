#!/bin/bash
# ============================================
# SessionStart hook: Load pending worker handoff
#
# This hook runs at the start of every Claude Code session.
# If WORKER_TASK_ID is set (by mp-spawn), it loads the
# corresponding handoff context from pending_handoffs/.
# ============================================

# Exit early if not a worker session
if [ -z "$WORKER_TASK_ID" ]; then
    exit 0
fi

# Find the project directory - try CLAUDE_PROJECT_DIR first, then pwd
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    PROJECT_DIR="$CLAUDE_PROJECT_DIR"
elif [ -n "$PWD" ]; then
    PROJECT_DIR="$PWD"
else
    exit 0
fi

HANDOFF_FILE="$PROJECT_DIR/pending_handoffs/$WORKER_TASK_ID.txt"

# Exit if no handoff file exists
if [ ! -f "$HANDOFF_FILE" ]; then
    exit 0
fi

# Output handoff context as system message for Claude to see
echo ""
echo "=============================================="
echo "AUTOMATED WORKER SESSION"
echo "=============================================="
echo ""
cat "$HANDOFF_FILE"
echo ""
echo "=============================================="
echo "INSTRUCTION: Execute /start-task $WORKER_TASK_ID now"
echo "=============================================="
echo ""

# Move to processed directory to prevent re-processing
mkdir -p "$PROJECT_DIR/pending_handoffs/processed"
mv "$HANDOFF_FILE" "$PROJECT_DIR/pending_handoffs/processed/"

exit 0
