#!/usr/bin/env bash
# Script to update nix flake inputs and rebuild with latest packages

set -euo pipefail

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "🔄 Updating all package managers and nix flake..."
echo ""

# Check for Claude Code updates first
echo "🤖 Checking for Claude Code updates..."
CLAUDE_UPDATE_SCRIPT="./pkgs/claude-code/update-version.sh"
CLAUDE_UPDATED=false
CLAUDE_VERSION_INFO=""

if [ -f "$CLAUDE_UPDATE_SCRIPT" ]; then
    # Capture the output to check if an update occurred
    CLAUDE_OUTPUT=$(bash "$CLAUDE_UPDATE_SCRIPT" 2>&1)
    echo "$CLAUDE_OUTPUT"
    
    # Check if an update was performed (look for the version change arrow)
    if echo "$CLAUDE_OUTPUT" | grep -q "→"; then
        CLAUDE_UPDATED=true
        # Extract version info from the output
        CLAUDE_VERSION_INFO=$(echo "$CLAUDE_OUTPUT" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+ → [0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo ""
        # Calculate box width based on content
        BOX_CONTENT=" 📌 Claude Code was updated: $CLAUDE_VERSION_INFO "
        BOX_WIDTH=${#BOX_CONTENT}
        TOP_BOTTOM=$(printf '═%.0s' $(seq 1 $BOX_WIDTH))
        
        echo -e "${CYAN}╔${TOP_BOTTOM}╗${NC}"
        echo -e "${CYAN}║${BOX_CONTENT}║${NC}"
        echo -e "${CYAN}╚${TOP_BOTTOM}╝${NC}"
    fi
else
    echo "⚠️  Claude Code update script not found at $CLAUDE_UPDATE_SCRIPT"
fi

echo ""

# Update nix flake inputs
echo "📦 Updating nix flake inputs..."
nix flake update
echo "✅ Flake inputs updated"

# Show what was updated
echo "📋 Updated flake inputs:"
git diff flake.lock | grep -E '^\+.*"lastModified"' || echo "No updates found"

echo ""
echo "🔨 Rebuilding Darwin configuration with latest packages..."
sudo darwin-rebuild switch --flake .#angel

echo ""
echo "🔄 Running comprehensive package updates..."

# Run the update-all-packages script if available
if command -v update-all-packages &> /dev/null; then
    update-all-packages
else
    echo "ℹ️  update-all-packages not found. It will be available after rebuild."
fi

echo ""
echo "✅ System updated with latest packages!"

# Show clear summary of what was updated
if [ "$CLAUDE_UPDATED" = true ]; then
    echo -e "${YELLOW}🎉 Claude Code package was updated: $CLAUDE_VERSION_INFO${NC}"
fi

echo ""
echo "💡 To commit the updates, run:"

# Build appropriate git commands based on what was updated
if [ "$CLAUDE_UPDATED" = true ]; then
    echo "   git add flake.lock pkgs/claude-code/default.nix"
    echo "   git commit -m 'Update flake inputs and Claude Code ($CLAUDE_VERSION_INFO)'"
else
    echo "   git add flake.lock"
    echo "   git commit -m 'Update flake inputs to latest versions'"
fi
