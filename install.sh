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
create_symlink "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands"
create_symlink "$SCRIPT_DIR/hooks" "$CLAUDE_DIR/hooks"
create_symlink "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents"
create_symlink "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills"
create_symlink "$SCRIPT_DIR/docs" "$CLAUDE_DIR/docs"

# Add bin/ to PATH via .zshrc
BIN_DIR="$SCRIPT_DIR/bin"
ZSHRC="$HOME/.zshrc"

if [ -d "$BIN_DIR" ]; then
    if ! grep -q "claude-config/bin" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "# Claude config bin utilities" >> "$ZSHRC"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$ZSHRC"
        echo "✓ Added bin/ to PATH in ~/.zshrc"
    else
        echo "✓ bin/ already in PATH"
    fi
fi

echo ""
echo "Installation complete!"
echo ""
echo "Verify with:"
echo "  ls -la ~/.claude/CLAUDE.md"
echo "  ls -la ~/.claude/commands"
echo "  ls -la ~/.claude/hooks"
echo "  ls -la ~/.claude/agents"
echo "  ls -la ~/.claude/skills"
echo "  ls -la ~/.claude/docs"
echo "  which mp-spawn  # (after sourcing ~/.zshrc)"
