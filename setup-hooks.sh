#!/bin/bash

# Setup script to install git hooks for SSH key protection

echo "Setting up git hooks for SSH key protection..."

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp hooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed successfully!"
echo "This hook will prevent SSH keys from being committed to the repository."
echo ""
echo "To bypass the hook in emergency situations, use: git commit --no-verify"
