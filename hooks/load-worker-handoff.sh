#!/bin/bash
# ============================================
# SessionStart hook: Load pending worker handoff
#
# This hook runs at the start of every Claude Code session.
# It uses a signal + queue mechanism to reliably assign tasks to workers:
#
# 1. /dispatch writes task IDs to docs/pending_handoffs/.queue (one per line)
# 2. /dispatch writes full handoff to docs/pending_handoffs/<task-id>.txt
# 3. mp-spawn creates a signal file (.spawn-<timestamp>) just before starting Claude
# 4. This hook claims one signal file (atomic delete), then pops task from queue
# 5. Each worker gets exactly one task in FIFO order
#
# Manual sessions are unaffected - no signal file means exit silently.
# Uses mkdir for locking (portable - works on macOS and Linux).
# ============================================

# Find the project directory
if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    PROJECT_DIR="$CLAUDE_PROJECT_DIR"
elif [ -n "$PWD" ]; then
    PROJECT_DIR="$PWD"
else
    exit 0
fi

HANDOFF_DIR="$PROJECT_DIR/docs/pending_handoffs"
QUEUE_FILE="$HANDOFF_DIR/.queue"
LOCK_DIR="$HANDOFF_DIR/.queue.lock"

# Exit silently if no docs/pending_handoffs directory
if [ ! -d "$HANDOFF_DIR" ]; then
    exit 0
fi

# Look for a spawn signal file (created by mp-spawn)
# If no signal exists, this is a manual session - exit silently
SPAWN_SIGNAL=$(ls -1t "$HANDOFF_DIR"/.spawn-* 2>/dev/null | head -1)
if [ -z "$SPAWN_SIGNAL" ]; then
    exit 0
fi

# Try to claim the signal by deleting it (atomic operation)
# If another process already deleted it, we exit silently
if ! rm "$SPAWN_SIGNAL" 2>/dev/null; then
    exit 0
fi

# We have claimed a signal - now we MUST process a task from the queue
# If queue is empty/missing, that's an error state (signal without task)

# Exit if no queue file
if [ ! -f "$QUEUE_FILE" ]; then
    echo ""
    echo "=============================================="
    echo "ERROR: Worker signal claimed but no queue file found"
    echo "Expected: $QUEUE_FILE"
    echo "=============================================="
    echo ""
    exit 0
fi

# Acquire lock using mkdir (atomic and portable)
LOCK_ACQUIRED=false
for i in $(seq 1 50); do  # Try for ~5 seconds
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        LOCK_ACQUIRED=true
        break
    fi
    sleep 0.1
done

if [ "$LOCK_ACQUIRED" != "true" ]; then
    echo ""
    echo "=============================================="
    echo "ERROR: Could not acquire queue lock"
    echo "=============================================="
    echo ""
    exit 0
fi

# Cleanup lock on exit (normal or error)
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# Read first line (next task)
TASK_ID=$(head -1 "$QUEUE_FILE" 2>/dev/null)

if [ -n "$TASK_ID" ]; then
    # Remove first line from queue
    tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp" 2>/dev/null
    mv "$QUEUE_FILE.tmp" "$QUEUE_FILE" 2>/dev/null

    # Clean up empty queue file
    if [ ! -s "$QUEUE_FILE" ]; then
        rm -f "$QUEUE_FILE"
    fi
fi

# Release lock
rmdir "$LOCK_DIR" 2>/dev/null
trap - EXIT

# Exit if no task was claimed (queue was empty)
if [ -z "$TASK_ID" ]; then
    echo ""
    echo "=============================================="
    echo "ERROR: Worker signal claimed but queue was empty"
    echo "=============================================="
    echo ""
    exit 0
fi

# Find the handoff file for this task
HANDOFF_FILE="$HANDOFF_DIR/$TASK_ID.txt"

if [ ! -f "$HANDOFF_FILE" ]; then
    echo ""
    echo "=============================================="
    echo "ERROR: Worker assigned task $TASK_ID but handoff file not found"
    echo "Expected: $HANDOFF_FILE"
    echo "=============================================="
    echo ""
    exit 0
fi

# Output handoff context for Claude to see
echo ""
echo "=============================================="
echo "AUTOMATED WORKER SESSION"
echo "Task: $TASK_ID"
echo "=============================================="
echo ""
cat "$HANDOFF_FILE"
echo ""
echo "=============================================="
echo "INSTRUCTION: Execute /start-task $TASK_ID now"
echo "=============================================="
echo ""

# Move handoff file to processed directory
mkdir -p "$HANDOFF_DIR/processed"
mv "$HANDOFF_FILE" "$HANDOFF_DIR/processed/"

exit 0
