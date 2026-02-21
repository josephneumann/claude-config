#!/bin/bash
# Claude Config Installation Script
# Creates symlinks from ~/.claude/ to this repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude config from: $SCRIPT_DIR"
echo "Target directory: $CLAUDE_DIR"
echo ""

# Create ~/.claude if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$(basename "$target")"

    if [ -L "$target" ]; then
        # Already a symlink - check if it points to the right place
        current_target="$(readlink "$target")"
        if [ "$current_target" = "$source" ]; then
            echo "✓ $name already linked correctly"
            return 0
        else
            echo "→ $name symlink exists but points elsewhere, updating..."
            rm "$target"
        fi
    elif [ -d "$target" ]; then
        # Directory exists - back it up
        backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
        echo "→ Backing up existing $name to $backup"
        mv "$target" "$backup"
    elif [ -e "$target" ]; then
        # Something else exists
        echo "✗ $target exists and is not a directory or symlink"
        return 1
    fi

    ln -s "$source" "$target"
    echo "✓ Linked $name → $source"
}

# Create symlinks
create_symlink "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
create_symlink "$SCRIPT_DIR/hooks" "$CLAUDE_DIR/hooks"
create_symlink "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents"
create_symlink "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills"
create_symlink "$SCRIPT_DIR/docs" "$CLAUDE_DIR/docs"

# Clean up legacy commands symlink if present
if [ -L "$CLAUDE_DIR/commands" ]; then
    rm "$CLAUDE_DIR/commands"
    echo "✓ Removed legacy commands symlink (migrated to skills)"
fi

# Register hooks in settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # Check if WorktreeCreate hook is already registered
    if ! jq -e '.hooks.WorktreeCreate' "$SETTINGS_FILE" > /dev/null 2>&1; then
        # Add WorktreeCreate hook
        jq '.hooks.WorktreeCreate = [{"matcher": "", "hooks": [{"type": "command", "command": "~/.claude/hooks/worktree-setup.sh", "statusMessage": "Setting up worktree environment..."}]}]' \
            "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        echo "✓ Registered WorktreeCreate hook"
    else
        echo "✓ WorktreeCreate hook already registered"
    fi

    # Check if BEADS_NO_DAEMON SessionStart hook is already registered
    if ! jq -e '.hooks.SessionStart[] | select(.hooks[].command | test("BEADS_NO_DAEMON"))' "$SETTINGS_FILE" > /dev/null 2>&1; then
        # Add SessionStart hook for BEADS_NO_DAEMON
        DAEMON_HOOK='{"matcher": "", "hooks": [{"type": "command", "command": "TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null); MAIN=$(git worktree list 2>/dev/null | head -1 | awk '"'"'{print $1}'"'"'); if [ \"$TOPLEVEL\" != \"$MAIN\" ] && [ -n \"$MAIN\" ]; then echo '"'"'export BEADS_NO_DAEMON=1'"'"' >> \"$CLAUDE_ENV_FILE\"; fi"}]}'
        jq --argjson hook "$DAEMON_HOOK" '.hooks.SessionStart += [$hook]' \
            "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        echo "✓ Registered SessionStart BEADS_NO_DAEMON hook"
    else
        echo "✓ SessionStart BEADS_NO_DAEMON hook already registered"
    fi
else
    echo "⚠ No settings.json found at $SETTINGS_FILE — skipping hook registration"
    echo "  Create settings.json manually or run Claude Code to generate it"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Verify with:"
echo "  ls -la ~/.claude/CLAUDE.md"
echo "  ls -la ~/.claude/hooks"
echo "  ls -la ~/.claude/agents"
echo "  ls -la ~/.claude/skills"
echo "  ls -la ~/.claude/docs"
