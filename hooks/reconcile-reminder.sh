#!/bin/bash
# Reminds the orchestrator to run /reconcile-summary before ending.
# Used as a Stop hook — fires when the lead is about to stop.
#
# Checks if unreconciled session summaries exist (top-level .txt files in
# docs/session_summaries/, not in reconciled/ subdirectory).
#
# Exit 0 = allow stop, Exit 2 = block with reminder on stderr

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loop: if stop hook already fired, allow stop
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

# Find main repo root
MAIN_REPO=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
[ -n "$MAIN_REPO" ] || exit 0

# If no session_summaries dir, nothing to reconcile
[ -d "$MAIN_REPO/docs/session_summaries" ] || exit 0

# Count unreconciled summaries (top-level .txt files, not in reconciled/)
UNRECONCILED=$(find "$MAIN_REPO/docs/session_summaries" -maxdepth 1 -name "*.txt" -type f 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNRECONCILED" -gt 0 ]; then
  echo "Found $UNRECONCILED unreconciled session summary file(s)." >&2
  echo "Run /reconcile-summary before ending this session." >&2
  exit 2
fi

exit 0
