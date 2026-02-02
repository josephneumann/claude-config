#!/bin/bash
# Guard against committing to main/master branches.
# Used as a PreToolUse hook on Bash to catch git commit attempts.
#
# Exit 0 = allow, Exit 2 = block with message on stderr

# Only inspect Bash tool calls
[ "$TOOL_NAME" = "Bash" ] || exit 0

# Extract the command from the tool input JSON
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
[ -n "$COMMAND" ] || exit 0

# Only care about git commit commands
echo "$COMMAND" | grep -qE '\bgit\s+commit\b' || exit 0

# Check current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "BLOCKED: Refusing to commit on '$BRANCH'. Workers must use a worktree branch." >&2
  echo "Run /start-task to create a proper worktree, or manually create a feature branch." >&2
  exit 2
fi

exit 0
