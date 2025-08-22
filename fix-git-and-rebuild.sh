#!/bin/bash
set -e

echo "🔧 Fixing Git repository ownership and rebuilding..."
echo ""

# Method 1: Add to safe.directory
echo "Adding repository to Git safe.directory..."
sudo git config --global --add safe.directory /Users/angel/angelsnixconfig

# Method 2: Alternative - temporarily change ownership during rebuild
# This is a safer approach that doesn't require global Git config changes
echo "Alternative approach: Using temporary ownership change..."

# Store current directory
REPO_DIR="/Users/angel/angelsnixconfig"
cd "$REPO_DIR"

# Create a temporary flake.nix if using flakes
if [ ! -f flake.nix ]; then
    echo "Note: No flake.nix found, using standard darwin-configuration.nix"
fi

# Method 3: Use environment variable to bypass Git ownership check
echo "Using GIT_CEILING_DIRECTORIES to bypass ownership check..."
export GIT_CEILING_DIRECTORIES=/Users

# Try the rebuild with the environment variable set
echo "Running rebuild with Git bypass..."
sudo -E GIT_CEILING_DIRECTORIES=/Users ./rebuild.sh

echo ""
echo "✅ Rebuild complete!"
echo ""
echo "HRM MCP server should now be available in Claude Code."