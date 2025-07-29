#!/usr/bin/env bash
# Script to update nix flake inputs and rebuild with latest packages

set -euo pipefail

echo "🔄 Updating all package managers and nix flake..."
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
echo ""
echo "💡 To commit the updates, run:"
echo "   git add flake.lock"
echo "   git commit -m 'Update flake inputs to latest versions'"